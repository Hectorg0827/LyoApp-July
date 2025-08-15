# Profile Models - Extended User Social Features
from datetime import datetime, timezone
from typing import List, Optional
from uuid import uuid4

import sqlalchemy as sa
from sqlalchemy import Boolean, Column, DateTime, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from ..core.database import Base


class UserProfile(Base):
    """Extended user profile with social features"""
    __tablename__ = "user_profiles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False)
    
    # Extended profile info
    username = Column(String(50), unique=True, index=True, nullable=True)
    bio = Column(Text, nullable=True)
    location = Column(String(100), nullable=True)
    website = Column(String(255), nullable=True)
    
    # Profile media
    avatar_url = Column(String(500), nullable=True)
    cover_url = Column(String(500), nullable=True)
    
    # Social stats (updated via triggers/background jobs)
    followers_count = Column(Integer, default=0, nullable=False)
    following_count = Column(Integer, default=0, nullable=False)
    posts_count = Column(Integer, default=0, nullable=False)
    
    # Privacy settings
    is_private = Column(Boolean, default=True, nullable=False)  # Default private for students
    allow_messages = Column(Boolean, default=True, nullable=False)
    show_activity = Column(Boolean, default=True, nullable=False)
    
    # Learning preferences
    learning_style = Column(String(50), nullable=True)  # visual, auditory, kinesthetic, reading
    difficulty_preference = Column(String(20), default="intermediate", nullable=False)
    
    # Gamification
    level = Column(Integer, default=1, nullable=False)
    xp_points = Column(Integer, default=0, nullable=False)
    streak_days = Column(Integer, default=0, nullable=False)
    streak_updated = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relationships
    user = relationship("User", back_populates="profile")
    following = relationship("Follow", foreign_keys="Follow.follower_id", back_populates="follower")
    followers = relationship("Follow", foreign_keys="Follow.following_id", back_populates="following")
    
    def __repr__(self):
        return f"<UserProfile {self.username or self.user_id}>"


class Follow(Base):
    """User following relationships"""
    __tablename__ = "follows"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    follower_id = Column(UUID(as_uuid=True), ForeignKey("user_profiles.user_id"), nullable=False)
    following_id = Column(UUID(as_uuid=True), ForeignKey("user_profiles.user_id"), nullable=False)
    
    # Follow request system for private profiles
    is_approved = Column(Boolean, default=False, nullable=False)
    requested_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    approved_at = Column(DateTime(timezone=True), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relationships
    follower = relationship("UserProfile", foreign_keys=[follower_id], back_populates="following")
    following = relationship("UserProfile", foreign_keys=[following_id], back_populates="followers")
    
    # Unique constraint to prevent duplicate follows
    __table_args__ = (sa.UniqueConstraint('follower_id', 'following_id', name='unique_follow'),)
    
    def __repr__(self):
        return f"<Follow {self.follower_id} -> {self.following_id}>"


class Interest(Base):
    """User interests and subjects"""
    __tablename__ = "interests"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    name = Column(String(100), unique=True, nullable=False)
    category = Column(String(50), nullable=True)  # subject, hobby, career, etc.
    description = Column(Text, nullable=True)
    icon_url = Column(String(500), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    def __repr__(self):
        return f"<Interest {self.name}>"


class UserInterest(Base):
    """User-Interest many-to-many relationship"""
    __tablename__ = "user_interests"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    interest_id = Column(UUID(as_uuid=True), ForeignKey("interests.id"), nullable=False)
    
    # Interest level
    proficiency_level = Column(String(20), default="beginner", nullable=False)  # beginner, intermediate, advanced
    is_learning = Column(Boolean, default=True, nullable=False)  # Currently learning vs already knows
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Unique constraint
    __table_args__ = (sa.UniqueConstraint('user_id', 'interest_id', name='unique_user_interest'),)
    
    def __repr__(self):
        return f"<UserInterest {self.user_id} -> {self.interest_id}>"


# Add relationship to User model
from ..auth.models import User
User.profile = relationship("UserProfile", back_populates="user", uselist=False)
