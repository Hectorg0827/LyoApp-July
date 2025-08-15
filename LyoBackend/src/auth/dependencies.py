# Authentication Dependencies and Security
from typing import Optional

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db
from ..core.logging import get_structured_logger, set_request_context
from .models import User
from .service import AuthenticationError, auth_service

logger = get_structured_logger(__name__)

# HTTP Bearer token security
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    session: AsyncSession = Depends(get_db)
) -> User:
    """Get current authenticated user"""
    try:
        # Verify token
        payload = auth_service.verify_token(credentials.credentials)
        user_id = payload.get("sub")
        
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload"
            )
        
        # Get user from database
        user_query = await session.execute(
            select(User).where(User.id == user_id)
        )
        user = user_query.scalar_one_or_none()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        # Set user context for logging
        set_request_context(payload.get("jti", ""), str(user.id))
        
        return user
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


async def get_current_user_optional(
    request: Request,
    session: AsyncSession = Depends(get_db)
) -> Optional[User]:
    """Get current user if authenticated, otherwise None"""
    try:
        authorization = request.headers.get("Authorization")
        if not authorization or not authorization.startswith("Bearer "):
            return None
        
        token = authorization.split(" ")[1]
        payload = auth_service.verify_token(token)
        user_id = payload.get("sub")
        
        if not user_id:
            return None
        
        user_query = await session.execute(
            select(User).where(User.id == user_id)
        )
        user = user_query.scalar_one_or_none()
        
        if user and user.is_active:
            set_request_context(payload.get("jti", ""), str(user.id))
            return user
        
        return None
        
    except Exception:
        # Fail silently for optional authentication
        return None


def require_role(required_role: str):
    """Require specific user role"""
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role != required_role:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required role: {required_role}"
            )
        return current_user
    return role_checker


def require_roles(*required_roles: str):
    """Require one of the specified user roles"""
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role not in required_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Required role: one of {required_roles}"
            )
        return current_user
    return role_checker


# Role-specific dependencies
require_student = require_role("student")
require_teacher = require_role("teacher")
require_guardian = require_role("guardian")
require_admin = require_role("admin")

# Multiple role dependencies
require_teacher_or_admin = require_roles("teacher", "admin")
require_guardian_or_admin = require_roles("guardian", "admin")


def get_client_ip(request: Request) -> Optional[str]:
    """Get client IP address"""
    # Check for X-Forwarded-For header (load balancer)
    forwarded_for = request.headers.get("X-Forwarded-For")
    if forwarded_for:
        return forwarded_for.split(",")[0].strip()
    
    # Check for X-Real-IP header (proxy)
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip
    
    # Fall back to direct connection
    return request.client.host if request.client else None


def get_user_agent(request: Request) -> Optional[str]:
    """Get user agent string"""
    return request.headers.get("User-Agent")
