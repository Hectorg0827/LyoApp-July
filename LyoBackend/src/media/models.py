# Media Upload Models
from datetime import datetime
from enum import Enum
from uuid import UUID, uuid4

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String, Text, func
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID
from sqlalchemy.orm import relationship

from ..core.database import Base


class MediaType(str, Enum):
    """Media type enumeration"""
    IMAGE = "image"
    VIDEO = "video"
    AUDIO = "audio"
    DOCUMENT = "document"


class MediaUpload(Base):
    """Media upload model for profile pictures, content, etc."""
    __tablename__ = "media_uploads"

    id = Column(PostgreSQLUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id = Column(PostgreSQLUUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    
    # File information
    filename = Column(String(255), nullable=False)
    original_filename = Column(String(255), nullable=False)
    content_type = Column(String(100), nullable=False)
    file_size = Column(String(20), nullable=False)  # Store as string to handle large files
    
    # Media type and usage
    media_type = Column(String(20), nullable=False)  # MediaType enum
    usage_type = Column(String(50), nullable=False)  # avatar, cover, post_image, etc.
    
    # Storage information
    storage_path = Column(String(500), nullable=False)  # GCS path
    public_url = Column(String(500), nullable=True)     # Public access URL
    thumbnail_url = Column(String(500), nullable=True)  # Thumbnail for images/videos
    
    # Metadata
    metadata = Column(Text, nullable=True)  # JSON string for additional metadata
    alt_text = Column(String(255), nullable=True)  # For accessibility
    
    # Status
    is_processed = Column(Boolean, default=False)
    is_public = Column(Boolean, default=True)
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="media_uploads")
    
    def __repr__(self):
        return f"<MediaUpload(id={self.id}, filename={self.filename}, user_id={self.user_id})>"
