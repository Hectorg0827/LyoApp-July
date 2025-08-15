# Authentication API Routes
from typing import Dict

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db
from ..core.logging import get_structured_logger
from .dependencies import get_client_ip, get_current_user, get_user_agent
from .models import User
from .schemas import (
    AppleSignInRequest,
    LoginRequest,
    PasswordChange,
    PasswordReset,
    PasswordResetConfirm,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
    UserResponse,
    UserUpdate,
)
from .service import AuthenticationError, RateLimitError, auth_service

logger = get_structured_logger(__name__)

router = APIRouter(prefix="/v1/auth", tags=["Authentication"])


@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    http_request: Request,
    session: AsyncSession = Depends(get_db)
):
    """Authenticate user with email and password"""
    try:
        ip_address = get_client_ip(http_request)
        user_agent = get_user_agent(http_request)
        
        user, access_token, refresh_token = await auth_service.authenticate_user(
            session, request, ip_address, user_agent
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=auth_service.settings.access_token_expire_minutes * 60,
            user=user
        )
        
    except RateLimitError as e:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(e)
        )
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/register", response_model=UserResponse)
async def register(
    request: RegisterRequest,
    http_request: Request,
    session: AsyncSession = Depends(get_db)
):
    """Register new user"""
    try:
        ip_address = get_client_ip(http_request)
        
        return await auth_service.register_user(session, request, ip_address)
        
    except RateLimitError as e:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(e)
        )
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    session: AsyncSession = Depends(get_db)
):
    """Refresh access token using refresh token"""
    try:
        user, access_token, refresh_token = await auth_service.refresh_access_token(
            session, request.refresh_token
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=auth_service.settings.access_token_expire_minutes * 60,
            user=user
        )
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/apple", response_model=TokenResponse)
async def apple_signin(
    request: AppleSignInRequest,
    http_request: Request,
    session: AsyncSession = Depends(get_db)
):
    """Authenticate user with Apple Sign-In"""
    try:
        ip_address = get_client_ip(http_request)
        
        user, access_token, refresh_token = await auth_service.authenticate_apple_signin(
            session, request, ip_address
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=auth_service.settings.access_token_expire_minutes * 60,
            user=user
        )
        
    except RateLimitError as e:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(e)
        )
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )


@router.post("/logout")
async def logout(
    request: RefreshTokenRequest,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Logout user and revoke refresh token"""
    success = await auth_service.revoke_refresh_token(session, request.refresh_token)
    
    return {
        "message": "Logged out successfully" if success else "Token already invalid"
    }


@router.get("/me", response_model=UserResponse)
async def get_current_user_info(current_user: User = Depends(get_current_user)):
    """Get current user information"""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update current user profile"""
    # Update user fields
    update_data = user_update.model_dump(exclude_unset=True)
    
    for field, value in update_data.items():
        setattr(current_user, field, value)
    
    await session.commit()
    await session.refresh(current_user)
    
    logger.info(f"User profile updated: {current_user.email}")
    
    return UserResponse.model_validate(current_user)


@router.post("/change-password")
async def change_password(
    password_change: PasswordChange,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Change user password"""
    # Verify current password
    if not auth_service.verify_password(password_change.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Current password is incorrect"
        )
    
    # Update password
    current_user.hashed_password = auth_service.hash_password(password_change.new_password)
    await session.commit()
    
    logger.info(f"Password changed for user: {current_user.email}")
    
    return {"message": "Password changed successfully"}


@router.post("/password-reset")
async def request_password_reset(
    password_reset: PasswordReset,
    session: AsyncSession = Depends(get_db)
):
    """Request password reset (placeholder)"""
    # TODO: Implement password reset email functionality
    logger.info(f"Password reset requested for: {password_reset.email}")
    
    return {"message": "Password reset email sent (if account exists)"}


@router.post("/password-reset/confirm")
async def confirm_password_reset(
    password_reset_confirm: PasswordResetConfirm,
    session: AsyncSession = Depends(get_db)
):
    """Confirm password reset (placeholder)"""
    # TODO: Implement password reset confirmation
    logger.info("Password reset confirmation attempted")
    
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="Password reset not yet implemented"
    )
