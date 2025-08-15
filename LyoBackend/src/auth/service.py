# Authentication Service Layer
import hashlib
from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple

from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy import and_, desc, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..core.logging import get_structured_logger, log_security_event
from ..core.redis import get_rate_limiter
from ..core.utils import generate_secure_token, utc_now
from .models import LoginAttempt, RefreshToken, User
from .schemas import AppleSignInRequest, LoginRequest, RegisterRequest, UserResponse

logger = get_structured_logger(__name__)

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthenticationError(Exception):
    """Authentication error"""
    pass


class AuthorizationError(Exception):
    """Authorization error"""
    pass


class RateLimitError(Exception):
    """Rate limit exceeded"""
    pass


class AuthService:
    """Authentication service"""
    
    def __init__(self):
        self.settings = get_settings()
    
    def hash_password(self, password: str) -> str:
        """Hash password using bcrypt"""
        return pwd_context.hash(password)
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash"""
        return pwd_context.verify(plain_password, hashed_password)
    
    def create_access_token(self, user_id: str, role: str) -> str:
        """Create JWT access token"""
        now = utc_now()
        expire = now + timedelta(minutes=self.settings.access_token_expire_minutes)
        
        payload = {
            "sub": user_id,
            "role": role,
            "iat": now.timestamp(),
            "exp": expire.timestamp(),
            "type": "access"
        }
        
        return jwt.encode(
            payload,
            self.settings.jwt_secret_key,
            algorithm=self.settings.jwt_algorithm
        )
    
    def create_refresh_token(self) -> str:
        """Create refresh token"""
        return generate_secure_token(32)
    
    def verify_token(self, token: str) -> dict:
        """Verify JWT token and return payload"""
        try:
            payload = jwt.decode(
                token,
                self.settings.jwt_secret_key,
                algorithms=[self.settings.jwt_algorithm]
            )
            
            # Check expiration
            if payload.get("exp", 0) < utc_now().timestamp():
                raise AuthenticationError("Token expired")
            
            return payload
            
        except JWTError as e:
            raise AuthenticationError(f"Invalid token: {str(e)}")
    
    async def check_rate_limit(self, key: str, limit: int) -> None:
        """Check rate limit and raise error if exceeded"""
        rate_limiter = await get_rate_limiter()
        is_limited, current = await rate_limiter.is_rate_limited(key, limit)
        
        if is_limited:
            log_security_event("rate_limit_exceeded", {"key": key, "count": current})
            raise RateLimitError(f"Rate limit exceeded: {current}/{limit}")
    
    async def log_login_attempt(
        self,
        session: AsyncSession,
        email: str,
        success: bool,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None,
        failure_reason: Optional[str] = None
    ) -> None:
        """Log login attempt"""
        attempt = LoginAttempt(
            email=email.lower(),
            ip_address=ip_address,
            user_agent=user_agent,
            success=success,
            failure_reason=failure_reason
        )
        
        session.add(attempt)
        await session.commit()
        
        if not success:
            log_security_event(
                "login_failed",
                {
                    "email": email,
                    "ip_address": ip_address,
                    "reason": failure_reason
                }
            )
    
    async def register_user(
        self,
        session: AsyncSession,
        request: RegisterRequest,
        ip_address: Optional[str] = None
    ) -> UserResponse:
        """Register new user"""
        # Check rate limit
        await self.check_rate_limit(
            f"register:{ip_address}",
            self.settings.rate_limit_auth
        )
        
        # Check if user already exists
        existing_user = await session.execute(
            select(User).where(User.email == request.email.lower())
        )
        if existing_user.scalar_one_or_none():
            raise AuthenticationError("User with this email already exists")
        
        # Create user
        user = User(
            email=request.email.lower(),
            hashed_password=self.hash_password(request.password),
            first_name=request.first_name,
            last_name=request.last_name,
            display_name=request.display_name or f"{request.first_name} {request.last_name}",
            role=request.role,
        )
        
        session.add(user)
        await session.commit()
        await session.refresh(user)
        
        logger.info(f"User registered: {user.email}")
        
        return UserResponse.model_validate(user)
    
    async def authenticate_user(
        self,
        session: AsyncSession,
        request: LoginRequest,
        ip_address: Optional[str] = None,
        user_agent: Optional[str] = None
    ) -> Tuple[UserResponse, str, str]:
        """Authenticate user and return tokens"""
        # Check rate limit
        await self.check_rate_limit(
            f"login:{ip_address}",
            self.settings.rate_limit_auth
        )
        
        # Get user
        user_query = await session.execute(
            select(User).where(
                and_(
                    User.email == request.email.lower(),
                    User.is_active == True
                )
            )
        )
        user = user_query.scalar_one_or_none()
        
        # Verify password
        if not user or not self.verify_password(request.password, user.hashed_password):
            await self.log_login_attempt(
                session, request.email, False, ip_address, user_agent, "invalid_credentials"
            )
            raise AuthenticationError("Invalid email or password")
        
        # Create tokens
        access_token = self.create_access_token(str(user.id), user.role)
        refresh_token = self.create_refresh_token()
        
        # Store refresh token
        refresh_token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        refresh_token_record = RefreshToken(
            token_hash=refresh_token_hash,
            user_id=user.id,
            expires_at=utc_now() + timedelta(days=self.settings.refresh_token_expire_days)
        )
        
        session.add(refresh_token_record)
        
        # Update last login
        user.last_login = utc_now()
        
        await session.commit()
        
        # Log successful login
        await self.log_login_attempt(
            session, request.email, True, ip_address, user_agent
        )
        
        logger.info(f"User authenticated: {user.email}")
        
        return UserResponse.model_validate(user), access_token, refresh_token
    
    async def refresh_access_token(
        self,
        session: AsyncSession,
        refresh_token: str
    ) -> Tuple[UserResponse, str, str]:
        """Refresh access token using refresh token"""
        refresh_token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        
        # Get refresh token record
        token_query = await session.execute(
            select(RefreshToken)
            .join(User)
            .where(
                and_(
                    RefreshToken.token_hash == refresh_token_hash,
                    RefreshToken.is_blacklisted == False,
                    RefreshToken.expires_at > utc_now(),
                    User.is_active == True
                )
            )
        )
        token_record = token_query.scalar_one_or_none()
        
        if not token_record:
            log_security_event("refresh_token_invalid", {"token_hash": refresh_token_hash})
            raise AuthenticationError("Invalid or expired refresh token")
        
        # Get user
        user = token_record.user
        
        # Create new tokens
        access_token = self.create_access_token(str(user.id), user.role)
        new_refresh_token = self.create_refresh_token()
        
        # Blacklist old refresh token and create new one
        token_record.is_blacklisted = True
        
        new_refresh_token_hash = hashlib.sha256(new_refresh_token.encode()).hexdigest()
        new_token_record = RefreshToken(
            token_hash=new_refresh_token_hash,
            user_id=user.id,
            expires_at=utc_now() + timedelta(days=self.settings.refresh_token_expire_days)
        )
        
        session.add(new_token_record)
        await session.commit()
        
        logger.info(f"Token refreshed for user: {user.email}")
        
        return UserResponse.model_validate(user), access_token, new_refresh_token
    
    async def revoke_refresh_token(
        self,
        session: AsyncSession,
        refresh_token: str
    ) -> bool:
        """Revoke refresh token"""
        refresh_token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        
        token_query = await session.execute(
            select(RefreshToken).where(RefreshToken.token_hash == refresh_token_hash)
        )
        token_record = token_query.scalar_one_or_none()
        
        if token_record:
            token_record.is_blacklisted = True
            await session.commit()
            return True
        
        return False
    
    async def authenticate_apple_signin(
        self,
        session: AsyncSession,
        request: AppleSignInRequest,
        ip_address: Optional[str] = None
    ) -> Tuple[UserResponse, str, str]:
        """Authenticate using Apple Sign-In"""
        # TODO: Verify Apple identity token (requires Apple's public keys)
        # For now, we'll use a simplified approach
        
        # Check rate limit
        await self.check_rate_limit(
            f"apple_signin:{ip_address}",
            self.settings.rate_limit_auth
        )
        
        # Check if user exists by Apple user ID
        user_query = await session.execute(
            select(User).where(User.apple_user_id == request.user_identifier)
        )
        user = user_query.scalar_one_or_none()
        
        if not user and request.email:
            # Check if user exists by email
            email_query = await session.execute(
                select(User).where(User.email == request.email.lower())
            )
            existing_user = email_query.scalar_one_or_none()
            
            if existing_user:
                # Link Apple account to existing user
                existing_user.apple_user_id = request.user_identifier
                user = existing_user
            else:
                # Create new user
                user = User(
                    email=request.email.lower(),
                    hashed_password="",  # No password for Apple Sign-In
                    first_name=request.first_name or "",
                    last_name=request.last_name or "",
                    display_name=f"{request.first_name or ''} {request.last_name or ''}".strip() or None,
                    apple_user_id=request.user_identifier,
                    is_verified=True  # Apple Sign-In users are considered verified
                )
                session.add(user)
        
        if not user:
            raise AuthenticationError("Unable to authenticate with Apple Sign-In")
        
        # Create tokens
        access_token = self.create_access_token(str(user.id), user.role)
        refresh_token = self.create_refresh_token()
        
        # Store refresh token
        refresh_token_hash = hashlib.sha256(refresh_token.encode()).hexdigest()
        refresh_token_record = RefreshToken(
            token_hash=refresh_token_hash,
            user_id=user.id,
            expires_at=utc_now() + timedelta(days=self.settings.refresh_token_expire_days)
        )
        
        session.add(refresh_token_record)
        
        # Update last login
        user.last_login = utc_now()
        
        await session.commit()
        await session.refresh(user)
        
        logger.info(f"Apple Sign-In authentication: {user.email}")
        
        return UserResponse.model_validate(user), access_token, refresh_token
    
    async def get_recent_failed_attempts(
        self,
        session: AsyncSession,
        email: str,
        hours: int = 1
    ) -> int:
        """Get count of recent failed login attempts"""
        since = utc_now() - timedelta(hours=hours)
        
        count_query = await session.execute(
            select(LoginAttempt).where(
                and_(
                    LoginAttempt.email == email.lower(),
                    LoginAttempt.success == False,
                    LoginAttempt.created_at > since
                )
            ).order_by(desc(LoginAttempt.created_at))
        )
        
        return len(count_query.scalars().all())


# Global auth service instance
auth_service = AuthService()
