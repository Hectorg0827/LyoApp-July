# Media Upload Schemas
from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class MediaUploadResponse(BaseModel):
    """Media upload response schema"""
    id: UUID
    filename: str
    original_filename: str
    content_type: str
    file_size: str
    media_type: str
    usage_type: str
    public_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    alt_text: Optional[str] = None
    is_processed: bool
    is_public: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class MediaUploadRequest(BaseModel):
    """Media upload metadata request"""
    usage_type: str = Field(..., description="Usage type (avatar, cover, post_image, etc.)")
    alt_text: Optional[str] = Field(None, max_length=255, description="Alt text for accessibility")
    is_public: bool = Field(True, description="Whether media should be publicly accessible")


class MediaUpdateRequest(BaseModel):
    """Media update request"""
    alt_text: Optional[str] = Field(None, max_length=255)
    is_public: Optional[bool] = None
