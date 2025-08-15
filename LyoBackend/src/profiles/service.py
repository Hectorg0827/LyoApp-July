# Profile Service Layer
from typing import List, Optional, Tuple
from uuid import UUID

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from ..core.database import get_db
from ..core.exceptions import BusinessLogicError, NotFoundError
from .models import Follow, Interest, UserInterest, UserProfile
from .schemas import (
    InterestRequest,
    ProfileCreate,
    ProfileResponse,
    ProfileUpdate,
    UserInterestResponse,
)


class ProfileService:
    """Profile service for managing user profiles and social interactions"""

    @staticmethod
    async def get_or_create_profile(
        user_id: UUID, 
        db: AsyncSession
    ) -> UserProfile:
        """Get existing profile or create a default one"""
        stmt = select(UserProfile).where(UserProfile.user_id == user_id)
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()
        
        if not profile:
            profile = UserProfile(
                user_id=user_id,
                difficulty_preference="intermediate"
            )
            db.add(profile)
            await db.commit()
            await db.refresh(profile)
        
        return profile

    @staticmethod
    async def get_profile_by_user_id(
        user_id: UUID,
        viewer_id: Optional[UUID],
        db: AsyncSession
    ) -> Optional[UserProfile]:
        """Get profile by user ID with relationship context"""
        stmt = (
            select(UserProfile)
            .options(
                selectinload(UserProfile.user),
                selectinload(UserProfile.user_interests).selectinload(UserInterest.interest)
            )
            .where(UserProfile.user_id == user_id)
        )
        
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()
        
        if profile and viewer_id and viewer_id != user_id:
            # Add relationship status
            profile.relationship_status = await ProfileService._get_relationship_status(
                viewer_id, user_id, db
            )
        
        return profile

    @staticmethod
    async def get_profile_by_username(
        username: str,
        viewer_id: Optional[UUID],
        db: AsyncSession
    ) -> Optional[UserProfile]:
        """Get profile by username"""
        stmt = (
            select(UserProfile)
            .options(
                selectinload(UserProfile.user),
                selectinload(UserProfile.user_interests).selectinload(UserInterest.interest)
            )
            .where(UserProfile.username == username)
        )
        
        result = await db.execute(stmt)
        profile = result.scalar_one_or_none()
        
        if profile and viewer_id and viewer_id != profile.user_id:
            profile.relationship_status = await ProfileService._get_relationship_status(
                viewer_id, profile.user_id, db
            )
        
        return profile

    @staticmethod
    async def update_profile(
        user_id: UUID,
        profile_data: ProfileUpdate,
        db: AsyncSession
    ) -> UserProfile:
        """Update user profile"""
        profile = await ProfileService.get_or_create_profile(user_id, db)
        
        # Check username uniqueness
        if profile_data.username and profile_data.username != profile.username:
            existing = await ProfileService.get_profile_by_username(
                profile_data.username, None, db
            )
            if existing:
                raise BusinessLogicError("Username already taken")
        
        # Update profile fields
        for field, value in profile_data.dict(exclude_unset=True).items():
            setattr(profile, field, value)
        
        await db.commit()
        await db.refresh(profile)
        return profile

    @staticmethod
    async def follow_user(
        follower_id: UUID,
        following_id: UUID,
        db: AsyncSession
    ) -> Follow:
        """Follow a user"""
        if follower_id == following_id:
            raise BusinessLogicError("Cannot follow yourself")
        
        # Check if follow relationship already exists
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id
            )
        )
        result = await db.execute(stmt)
        existing_follow = result.scalar_one_or_none()
        
        if existing_follow:
            raise BusinessLogicError("Already following this user")
        
        # Get target profile to check privacy
        target_profile = await ProfileService.get_profile_by_user_id(
            following_id, None, db
        )
        if not target_profile:
            raise NotFoundError("User not found")
        
        # Create follow relationship
        follow = Follow(
            follower_id=follower_id,
            following_id=following_id,
            is_approved=not target_profile.is_private  # Auto-approve if public
        )
        
        db.add(follow)
        await db.commit()
        await db.refresh(follow)
        return follow

    @staticmethod
    async def unfollow_user(
        follower_id: UUID,
        following_id: UUID,
        db: AsyncSession
    ) -> bool:
        """Unfollow a user"""
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == follower_id,
                Follow.following_id == following_id
            )
        )
        result = await db.execute(stmt)
        follow = result.scalar_one_or_none()
        
        if not follow:
            raise NotFoundError("Follow relationship not found")
        
        await db.delete(follow)
        await db.commit()
        return True

    @staticmethod
    async def approve_follow_request(
        user_id: UUID,
        follower_id: UUID,
        db: AsyncSession
    ) -> Follow:
        """Approve a pending follow request"""
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == follower_id,
                Follow.following_id == user_id,
                Follow.is_approved == False
            )
        )
        result = await db.execute(stmt)
        follow = result.scalar_one_or_none()
        
        if not follow:
            raise NotFoundError("Follow request not found")
        
        follow.is_approved = True
        follow.approved_at = func.now()
        
        await db.commit()
        await db.refresh(follow)
        return follow

    @staticmethod
    async def reject_follow_request(
        user_id: UUID,
        follower_id: UUID,
        db: AsyncSession
    ) -> bool:
        """Reject a pending follow request"""
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == follower_id,
                Follow.following_id == user_id,
                Follow.is_approved == False
            )
        )
        result = await db.execute(stmt)
        follow = result.scalar_one_or_none()
        
        if not follow:
            raise NotFoundError("Follow request not found")
        
        await db.delete(follow)
        await db.commit()
        return True

    @staticmethod
    async def get_followers(
        user_id: UUID,
        viewer_id: Optional[UUID],
        skip: int = 0,
        limit: int = 20,
        db: AsyncSession
    ) -> List[UserProfile]:
        """Get user's followers"""
        stmt = (
            select(UserProfile)
            .join(Follow, Follow.follower_id == UserProfile.user_id)
            .where(
                and_(
                    Follow.following_id == user_id,
                    Follow.is_approved == True
                )
            )
            .options(selectinload(UserProfile.user))
            .offset(skip)
            .limit(limit)
        )
        
        result = await db.execute(stmt)
        profiles = result.scalars().all()
        
        # Add relationship status for each profile
        if viewer_id:
            for profile in profiles:
                if viewer_id != profile.user_id:
                    profile.relationship_status = await ProfileService._get_relationship_status(
                        viewer_id, profile.user_id, db
                    )
        
        return profiles

    @staticmethod
    async def get_following(
        user_id: UUID,
        viewer_id: Optional[UUID],
        skip: int = 0,
        limit: int = 20,
        db: AsyncSession
    ) -> List[UserProfile]:
        """Get users that user is following"""
        stmt = (
            select(UserProfile)
            .join(Follow, Follow.following_id == UserProfile.user_id)
            .where(
                and_(
                    Follow.follower_id == user_id,
                    Follow.is_approved == True
                )
            )
            .options(selectinload(UserProfile.user))
            .offset(skip)
            .limit(limit)
        )
        
        result = await db.execute(stmt)
        profiles = result.scalars().all()
        
        # Add relationship status for each profile
        if viewer_id:
            for profile in profiles:
                if viewer_id != profile.user_id:
                    profile.relationship_status = await ProfileService._get_relationship_status(
                        viewer_id, profile.user_id, db
                    )
        
        return profiles

    @staticmethod
    async def get_follow_requests(
        user_id: UUID,
        skip: int = 0,
        limit: int = 20,
        db: AsyncSession
    ) -> List[Follow]:
        """Get pending follow requests"""
        stmt = (
            select(Follow)
            .options(
                selectinload(Follow.follower_profile).selectinload(UserProfile.user)
            )
            .where(
                and_(
                    Follow.following_id == user_id,
                    Follow.is_approved == False
                )
            )
            .offset(skip)
            .limit(limit)
        )
        
        result = await db.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def add_interest(
        user_id: UUID,
        interest_request: InterestRequest,
        db: AsyncSession
    ) -> UserInterest:
        """Add interest to user profile"""
        # Check if interest exists
        stmt = select(Interest).where(Interest.id == interest_request.interest_id)
        result = await db.execute(stmt)
        interest = result.scalar_one_or_none()
        
        if not interest:
            raise NotFoundError("Interest not found")
        
        # Check if user already has this interest
        stmt = select(UserInterest).where(
            and_(
                UserInterest.user_id == user_id,
                UserInterest.interest_id == interest_request.interest_id
            )
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()
        
        if existing:
            raise BusinessLogicError("Interest already added")
        
        user_interest = UserInterest(
            user_id=user_id,
            interest_id=interest_request.interest_id,
            proficiency_level=interest_request.proficiency_level,
            is_learning=interest_request.is_learning
        )
        
        db.add(user_interest)
        await db.commit()
        await db.refresh(user_interest)
        return user_interest

    @staticmethod
    async def remove_interest(
        user_id: UUID,
        interest_id: UUID,
        db: AsyncSession
    ) -> bool:
        """Remove interest from user profile"""
        stmt = select(UserInterest).where(
            and_(
                UserInterest.user_id == user_id,
                UserInterest.interest_id == interest_id
            )
        )
        result = await db.execute(stmt)
        user_interest = result.scalar_one_or_none()
        
        if not user_interest:
            raise NotFoundError("Interest not found in user profile")
        
        await db.delete(user_interest)
        await db.commit()
        return True

    @staticmethod
    async def search_profiles(
        query: str,
        viewer_id: Optional[UUID],
        skip: int = 0,
        limit: int = 20,
        db: AsyncSession
    ) -> List[UserProfile]:
        """Search profiles by username or display name"""
        search_term = f"%{query.lower()}%"
        
        stmt = (
            select(UserProfile)
            .options(selectinload(UserProfile.user))
            .where(
                or_(
                    func.lower(UserProfile.username).contains(search_term),
                    func.lower(UserProfile.user.display_name).contains(search_term),
                    func.lower(UserProfile.user.first_name + ' ' + UserProfile.user.last_name).contains(search_term)
                )
            )
            .offset(skip)
            .limit(limit)
        )
        
        result = await db.execute(stmt)
        profiles = result.scalars().all()
        
        # Add relationship status for each profile
        if viewer_id:
            for profile in profiles:
                if viewer_id != profile.user_id:
                    profile.relationship_status = await ProfileService._get_relationship_status(
                        viewer_id, profile.user_id, db
                    )
        
        return profiles

    @staticmethod
    async def get_interests(
        skip: int = 0,
        limit: int = 50,
        category: Optional[str] = None,
        db: AsyncSession
    ) -> List[Interest]:
        """Get all available interests"""
        stmt = select(Interest)
        
        if category:
            stmt = stmt.where(Interest.category == category)
        
        stmt = stmt.offset(skip).limit(limit)
        result = await db.execute(stmt)
        return result.scalars().all()

    @staticmethod
    async def _get_relationship_status(
        viewer_id: UUID,
        target_id: UUID,
        db: AsyncSession
    ) -> dict:
        """Get relationship status between viewer and target user"""
        # Check if viewer follows target
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == viewer_id,
                Follow.following_id == target_id
            )
        )
        result = await db.execute(stmt)
        following_relationship = result.scalar_one_or_none()
        
        # Check if target follows viewer
        stmt = select(Follow).where(
            and_(
                Follow.follower_id == target_id,
                Follow.following_id == viewer_id
            )
        )
        result = await db.execute(stmt)
        follower_relationship = result.scalar_one_or_none()
        
        return {
            "is_following": following_relationship.is_approved if following_relationship else False,
            "is_followed_by": follower_relationship.is_approved if follower_relationship else False,
            "follow_request_pending": (
                following_relationship and not following_relationship.is_approved
            ) if following_relationship else False
        }

    @staticmethod
    async def update_xp_and_level(
        user_id: UUID,
        xp_gained: int,
        db: AsyncSession
    ) -> UserProfile:
        """Update user XP and level"""
        profile = await ProfileService.get_or_create_profile(user_id, db)
        
        profile.xp_points += xp_gained
        
        # Calculate new level (simple formula: level = sqrt(xp/100))
        import math
        new_level = int(math.sqrt(profile.xp_points / 100)) + 1
        
        if new_level > profile.level:
            profile.level = new_level
            # Could trigger achievement/notification here
        
        await db.commit()
        await db.refresh(profile)
        return profile

    @staticmethod
    async def update_streak(
        user_id: UUID,
        db: AsyncSession
    ) -> UserProfile:
        """Update user's learning streak"""
        profile = await ProfileService.get_or_create_profile(user_id, db)
        
        # Simple streak logic - in production, this would be more sophisticated
        # checking actual learning activity dates
        profile.streak_days += 1
        profile.last_activity = func.now()
        
        await db.commit()
        await db.refresh(profile)
        return profile
