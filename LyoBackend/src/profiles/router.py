# Profile API Routes
from typing import List, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth.dependencies import get_current_user
from ..auth.models import User
from ..core.database import get_db
from ..core.exceptions import BusinessLogicError, NotFoundError
from .schemas import (
    FollowRequest,
    FollowResponse,
    InterestRequest,
    InterestResponse,
    ProfileCreate,
    ProfileResponse,
    ProfileSearchResponse,
    ProfileStats,
    ProfileUpdate,
    UserInterestResponse,
)
from .service import ProfileService

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/me", response_model=ProfileResponse)
async def get_my_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get current user's profile"""
    profile = await ProfileService.get_or_create_profile(current_user.id, db)
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    return ProfileResponse.from_orm(profile)


@router.put("/me", response_model=ProfileResponse)
async def update_my_profile(
    profile_data: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update current user's profile"""
    try:
        profile = await ProfileService.update_profile(
            current_user.id, profile_data, db
        )
        return ProfileResponse.from_orm(profile)
    except BusinessLogicError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{user_id}", response_model=ProfileResponse)
async def get_profile(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user profile by ID"""
    profile = await ProfileService.get_profile_by_user_id(
        user_id, current_user.id, db
    )
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Check privacy settings
    if (profile.is_private and 
        profile.user_id != current_user.id and
        not getattr(profile, 'relationship_status', {}).get('is_following', False)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Profile is private"
        )
    
    return ProfileResponse.from_orm(profile)


@router.get("/username/{username}", response_model=ProfileResponse)
async def get_profile_by_username(
    username: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user profile by username"""
    profile = await ProfileService.get_profile_by_username(
        username, current_user.id, db
    )
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Check privacy settings
    if (profile.is_private and 
        profile.user_id != current_user.id and
        not getattr(profile, 'relationship_status', {}).get('is_following', False)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Profile is private"
        )
    
    return ProfileResponse.from_orm(profile)


@router.post("/{user_id}/follow", response_model=FollowResponse)
async def follow_user(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Follow a user"""
    try:
        follow = await ProfileService.follow_user(
            current_user.id, user_id, db
        )
        return FollowResponse.from_orm(follow)
    except BusinessLogicError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.delete("/{user_id}/follow")
async def unfollow_user(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Unfollow a user"""
    try:
        await ProfileService.unfollow_user(current_user.id, user_id, db)
        return {"message": "Successfully unfollowed user"}
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/{user_id}/followers", response_model=List[ProfileSearchResponse])
async def get_followers(
    user_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get user's followers"""
    followers = await ProfileService.get_followers(
        user_id, current_user.id, skip, limit, db
    )
    return [ProfileSearchResponse.from_orm(profile) for profile in followers]


@router.get("/{user_id}/following", response_model=List[ProfileSearchResponse])
async def get_following(
    user_id: UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get users that user is following"""
    following = await ProfileService.get_following(
        user_id, current_user.id, skip, limit, db
    )
    return [ProfileSearchResponse.from_orm(profile) for profile in following]


@router.get("/me/follow-requests", response_model=List[FollowResponse])
async def get_follow_requests(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get pending follow requests"""
    requests = await ProfileService.get_follow_requests(
        current_user.id, skip, limit, db
    )
    return [FollowResponse.from_orm(request) for request in requests]


@router.post("/follow-requests/{follower_id}/approve", response_model=FollowResponse)
async def approve_follow_request(
    follower_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Approve a follow request"""
    try:
        follow = await ProfileService.approve_follow_request(
            current_user.id, follower_id, db
        )
        return FollowResponse.from_orm(follow)
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.delete("/follow-requests/{follower_id}")
async def reject_follow_request(
    follower_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Reject a follow request"""
    try:
        await ProfileService.reject_follow_request(
            current_user.id, follower_id, db
        )
        return {"message": "Follow request rejected"}
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.post("/me/interests", response_model=UserInterestResponse)
async def add_interest(
    interest_request: InterestRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Add interest to user profile"""
    try:
        user_interest = await ProfileService.add_interest(
            current_user.id, interest_request, db
        )
        return UserInterestResponse.from_orm(user_interest)
    except (BusinessLogicError, NotFoundError) as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.delete("/me/interests/{interest_id}")
async def remove_interest(
    interest_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Remove interest from user profile"""
    try:
        await ProfileService.remove_interest(current_user.id, interest_id, db)
        return {"message": "Interest removed successfully"}
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )


@router.get("/search", response_model=List[ProfileSearchResponse])
async def search_profiles(
    q: str = Query(..., min_length=2, description="Search query"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Search user profiles"""
    profiles = await ProfileService.search_profiles(
        q, current_user.id, skip, limit, db
    )
    return [ProfileSearchResponse.from_orm(profile) for profile in profiles]


@router.get("/interests", response_model=List[InterestResponse])
async def get_interests(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    category: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db)
):
    """Get available interests"""
    interests = await ProfileService.get_interests(skip, limit, category, db)
    return [InterestResponse.from_orm(interest) for interest in interests]


@router.get("/{user_id}/stats", response_model=ProfileStats)
async def get_profile_stats(
    user_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get profile statistics"""
    profile = await ProfileService.get_profile_by_user_id(user_id, current_user.id, db)
    
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Check privacy
    if (profile.is_private and 
        profile.user_id != current_user.id and
        not getattr(profile, 'relationship_status', {}).get('is_following', False)):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Profile is private"
        )
    
    return ProfileStats(
        total_followers=profile.followers_count,
        total_following=profile.following_count,
        total_posts=profile.posts_count,
        total_xp=profile.xp_points,
        current_level=profile.level,
        current_streak=profile.streak_days,
        longest_streak=profile.streak_days,  # TODO: Track longest streak separately
        achievements_count=0  # TODO: Implement achievements
    )


# Internal endpoints for gamification
@router.post("/me/xp", include_in_schema=False)
async def update_xp(
    xp_gained: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update user XP (internal use)"""
    profile = await ProfileService.update_xp_and_level(
        current_user.id, xp_gained, db
    )
    return {
        "level": profile.level,
        "xp_points": profile.xp_points,
        "xp_gained": xp_gained
    }


@router.post("/me/streak", include_in_schema=False)
async def update_streak(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update user streak (internal use)"""
    profile = await ProfileService.update_streak(current_user.id, db)
    return {
        "streak_days": profile.streak_days,
        "level": profile.level,
        "xp_points": profile.xp_points
    }
