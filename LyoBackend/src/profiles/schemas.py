# Profile Schemas (Pydantic Models)
from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, validator


class ProfileBase(BaseModel):
    """Base profile schema"""
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    bio: Optional[str] = Field(None, max_length=500)
    location: Optional[str] = Field(None, max_length=100)
    website: Optional[str] = Field(None, max_length=255)
    learning_style: Optional[str] = Field(None, regex=r"^(visual|auditory|kinesthetic|reading)$")
    difficulty_preference: str = Field("intermediate", regex=r"^(beginner|intermediate|advanced)$")
    is_private: bool = True
    allow_messages: bool = True
    show_activity: bool = True

    @validator('username')
    def validate_username(cls, v):
        if v is not None:
            import re
            if not re.match(r'^[a-zA-Z0-9_]+$', v):
                raise ValueError('Username can only contain letters, numbers, and underscores')
        return v

    @validator('website')
    def validate_website(cls, v):
        if v is not None:
            import re
            url_pattern = r'^https?://(?:[-\w.])+(?:\:[0-9]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:\#(?:\w)*)?)?$'
            if not re.match(url_pattern, v):
                raise ValueError('Invalid website URL format')
        return v


class ProfileCreate(ProfileBase):
    """Profile creation schema"""
    pass


class ProfileUpdate(ProfileBase):
    """Profile update schema"""
    pass


class InterestResponse(BaseModel):
    """Interest response schema"""
    id: UUID
    name: str
    category: Optional[str] = None
    description: Optional[str] = None
    icon_url: Optional[str] = None
    
    class Config:
        from_attributes = True


class UserInterestResponse(BaseModel):
    """User interest response schema"""
    interest: InterestResponse
    proficiency_level: str
    is_learning: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class ProfileResponse(BaseModel):
    """Complete profile response schema"""
    id: UUID
    user_id: UUID
    username: Optional[str] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    website: Optional[str] = None
    avatar_url: Optional[str] = None
    cover_url: Optional[str] = None
    
    # Social stats
    followers_count: int
    following_count: int
    posts_count: int
    
    # Privacy
    is_private: bool
    allow_messages: bool
    show_activity: bool
    
    # Learning
    learning_style: Optional[str] = None
    difficulty_preference: str
    
    # Gamification
    level: int
    xp_points: int
    streak_days: int
    
    # Timestamps
    created_at: datetime
    updated_at: datetime
    
    # User info (from related User model)
    email: Optional[str] = None
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    display_name: Optional[str] = None
    role: Optional[str] = None
    
    # Interests
    interests: List[UserInterestResponse] = []
    
    # Relationship status (for viewing other profiles)
    is_following: Optional[bool] = None
    is_followed_by: Optional[bool] = None
    follow_request_pending: Optional[bool] = None
    
    class Config:
        from_attributes = True


class FollowResponse(BaseModel):
    """Follow relationship response"""
    id: UUID
    follower_id: UUID
    following_id: UUID
    is_approved: bool
    requested_at: datetime
    approved_at: Optional[datetime] = None
    
    # Profile info
    follower_profile: Optional[ProfileResponse] = None
    following_profile: Optional[ProfileResponse] = None
    
    class Config:
        from_attributes = True


class FollowRequest(BaseModel):
    """Follow request schema"""
    user_id: UUID


class InterestRequest(BaseModel):
    """Interest addition request"""
    interest_id: UUID
    proficiency_level: str = Field("beginner", regex=r"^(beginner|intermediate|advanced)$")
    is_learning: bool = True


class ProfileSearchResponse(BaseModel):
    """Simplified profile for search results"""
    id: UUID
    user_id: UUID
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    followers_count: int
    is_private: bool
    is_following: Optional[bool] = None
    
    class Config:
        from_attributes = True


class ProfileStats(BaseModel):
    """Profile statistics"""
    total_followers: int
    total_following: int
    total_posts: int
    total_xp: int
    current_level: int
    current_streak: int
    longest_streak: int
    achievements_count: int
