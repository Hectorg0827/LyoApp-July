# Authentication Schemas (Pydantic Models)
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, validator


class UserRole:
    STUDENT = "student"
    TEACHER = "teacher"
    GUARDIAN = "guardian"
    ADMIN = "admin"


class LoginRequest(BaseModel):
    """Login request schema"""
    email: EmailStr
    password: str = Field(..., min_length=6)


class AppleSignInRequest(BaseModel):
    """Apple Sign-In request schema"""
    identity_token: str
    authorization_code: str
    user_identifier: str
    email: Optional[EmailStr] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None


class RegisterRequest(BaseModel):
    """Registration request schema"""
    email: EmailStr
    password: str = Field(..., min_length=8)
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    display_name: Optional[str] = Field(None, max_length=200)
    role: str = Field(default=UserRole.STUDENT)
    
    @validator('role')
    def validate_role(cls, v):
        valid_roles = [UserRole.STUDENT, UserRole.TEACHER, UserRole.GUARDIAN, UserRole.ADMIN]
        if v not in valid_roles:
            raise ValueError(f'Role must be one of: {valid_roles}')
        return v


class TokenResponse(BaseModel):
    """Token response schema"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    user: "UserResponse"


class RefreshTokenRequest(BaseModel):
    """Refresh token request schema"""
    refresh_token: str


class UserResponse(BaseModel):
    """User response schema (safe for API)"""
    id: UUID
    email: EmailStr
    username: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    role: str
    is_verified: bool
    is_private: bool
    created_at: datetime
    last_login: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """User update schema"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    display_name: Optional[str] = Field(None, max_length=200)
    bio: Optional[str] = Field(None, max_length=500)
    is_private: Optional[bool] = None
    
    @validator('username')
    def validate_username(cls, v):
        if v is not None:
            # Username can only contain alphanumeric characters and underscores
            import re
            if not re.match(r'^[a-zA-Z0-9_]+$', v):
                raise ValueError('Username can only contain letters, numbers, and underscores')
        return v


class PasswordChange(BaseModel):
    """Password change schema"""
    current_password: str
    new_password: str = Field(..., min_length=8)


class PasswordReset(BaseModel):
    """Password reset schema"""
    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation schema"""
    token: str
    new_password: str = Field(..., min_length=8)


# Update forward references
TokenResponse.model_rebuild()
