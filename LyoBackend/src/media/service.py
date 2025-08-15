# Media Upload Service
import json
import os
import uuid
from typing import Optional
from uuid import UUID

from fastapi import UploadFile
from google.cloud import storage
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from ..core.config import get_settings
from ..core.exceptions import BusinessLogicError, NotFoundError
from .models import MediaType, MediaUpload

settings = get_settings()


class MediaService:
    """Service for handling media uploads to Google Cloud Storage"""
    
    def __init__(self):
        # Initialize GCS client if credentials are available
        self.gcs_client = None
        self.bucket_name = settings.GCS_BUCKET_NAME
        
        if settings.GOOGLE_APPLICATION_CREDENTIALS:
            try:
                self.gcs_client = storage.Client()
                self.bucket = self.gcs_client.bucket(self.bucket_name)
            except Exception as e:
                print(f"Warning: Could not initialize GCS client: {e}")

    async def upload_file(
        self,
        file: UploadFile,
        user_id: UUID,
        usage_type: str,
        alt_text: Optional[str] = None,
        is_public: bool = True,
        db: AsyncSession = None
    ) -> MediaUpload:
        """Upload file to GCS and create database record"""
        
        # Validate file type
        media_type = self._get_media_type(file.content_type)
        if not media_type:
            raise BusinessLogicError("Unsupported file type")
        
        # Validate file size (10MB limit by default)
        max_size = self._get_max_file_size(media_type)
        file_size = 0
        content = await file.read()
        file_size = len(content)
        
        if file_size > max_size:
            raise BusinessLogicError(f"File too large. Maximum size: {max_size / (1024*1024):.1f}MB")
        
        # Generate unique filename
        file_extension = self._get_file_extension(file.filename or "file")
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        
        # Create storage path
        storage_path = f"uploads/{user_id}/{usage_type}/{unique_filename}"
        
        try:
            # Upload to GCS if available, otherwise save locally for development
            public_url = None
            if self.gcs_client:
                public_url = await self._upload_to_gcs(
                    content, storage_path, file.content_type, is_public
                )
            else:
                # Local development storage
                await self._save_locally(content, storage_path)
                public_url = f"{settings.BASE_URL}/media/{storage_path}"
            
            # Create thumbnail for images
            thumbnail_url = None
            if media_type == MediaType.IMAGE:
                thumbnail_url = await self._create_thumbnail(
                    content, storage_path, file.content_type
                )
            
            # Create database record
            media_upload = MediaUpload(
                user_id=user_id,
                filename=unique_filename,
                original_filename=file.filename or "unknown",
                content_type=file.content_type,
                file_size=str(file_size),
                media_type=media_type.value,
                usage_type=usage_type,
                storage_path=storage_path,
                public_url=public_url,
                thumbnail_url=thumbnail_url,
                alt_text=alt_text,
                is_public=is_public,
                is_processed=True  # Set to True for now, False if async processing needed
            )
            
            if db:
                db.add(media_upload)
                await db.commit()
                await db.refresh(media_upload)
            
            return media_upload
            
        except Exception as e:
            raise BusinessLogicError(f"Upload failed: {str(e)}")

    async def get_media(self, media_id: UUID, db: AsyncSession) -> Optional[MediaUpload]:
        """Get media by ID"""
        stmt = select(MediaUpload).where(MediaUpload.id == media_id)
        result = await db.execute(stmt)
        return result.scalar_one_or_none()

    async def delete_media(
        self, media_id: UUID, user_id: UUID, db: AsyncSession
    ) -> bool:
        """Delete media file and database record"""
        media = await self.get_media(media_id, db)
        
        if not media:
            raise NotFoundError("Media not found")
        
        if media.user_id != user_id:
            raise BusinessLogicError("Not authorized to delete this media")
        
        # Delete from storage
        if self.gcs_client:
            await self._delete_from_gcs(media.storage_path)
            if media.thumbnail_url:
                thumbnail_path = media.storage_path.replace(media.filename, f"thumb_{media.filename}")
                await self._delete_from_gcs(thumbnail_path)
        else:
            await self._delete_locally(media.storage_path)
        
        # Delete from database
        await db.delete(media)
        await db.commit()
        return True

    async def update_media(
        self,
        media_id: UUID,
        user_id: UUID,
        alt_text: Optional[str] = None,
        is_public: Optional[bool] = None,
        db: AsyncSession = None
    ) -> MediaUpload:
        """Update media metadata"""
        media = await self.get_media(media_id, db)
        
        if not media:
            raise NotFoundError("Media not found")
        
        if media.user_id != user_id:
            raise BusinessLogicError("Not authorized to update this media")
        
        # Update fields
        if alt_text is not None:
            media.alt_text = alt_text
        if is_public is not None:
            media.is_public = is_public
            # Update GCS permissions if needed
            if self.gcs_client:
                await self._update_gcs_permissions(media.storage_path, is_public)
        
        await db.commit()
        await db.refresh(media)
        return media

    def _get_media_type(self, content_type: str) -> Optional[MediaType]:
        """Determine media type from content type"""
        if content_type.startswith('image/'):
            return MediaType.IMAGE
        elif content_type.startswith('video/'):
            return MediaType.VIDEO
        elif content_type.startswith('audio/'):
            return MediaType.AUDIO
        elif content_type in ['application/pdf', 'text/plain', 'application/msword']:
            return MediaType.DOCUMENT
        return None

    def _get_max_file_size(self, media_type: MediaType) -> int:
        """Get maximum file size for media type"""
        sizes = {
            MediaType.IMAGE: 10 * 1024 * 1024,      # 10MB
            MediaType.VIDEO: 100 * 1024 * 1024,     # 100MB
            MediaType.AUDIO: 50 * 1024 * 1024,      # 50MB
            MediaType.DOCUMENT: 25 * 1024 * 1024,   # 25MB
        }
        return sizes.get(media_type, 10 * 1024 * 1024)

    def _get_file_extension(self, filename: str) -> str:
        """Extract file extension"""
        if '.' in filename:
            return '.' + filename.rsplit('.', 1)[1].lower()
        return ''

    async def _upload_to_gcs(
        self, content: bytes, storage_path: str, content_type: str, is_public: bool
    ) -> str:
        """Upload file to Google Cloud Storage"""
        blob = self.bucket.blob(storage_path)
        blob.upload_from_string(content, content_type=content_type)
        
        if is_public:
            blob.make_public()
        
        return blob.public_url if is_public else f"gs://{self.bucket_name}/{storage_path}"

    async def _save_locally(self, content: bytes, storage_path: str):
        """Save file locally for development"""
        local_path = f"uploads/{storage_path}"
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        
        with open(local_path, 'wb') as f:
            f.write(content)

    async def _create_thumbnail(
        self, content: bytes, storage_path: str, content_type: str
    ) -> Optional[str]:
        """Create thumbnail for images (placeholder implementation)"""
        # In production, you would use PIL or similar to create actual thumbnails
        # For now, return the original image URL
        return None

    async def _delete_from_gcs(self, storage_path: str):
        """Delete file from GCS"""
        blob = self.bucket.blob(storage_path)
        blob.delete()

    async def _delete_locally(self, storage_path: str):
        """Delete local file"""
        local_path = f"uploads/{storage_path}"
        if os.path.exists(local_path):
            os.remove(local_path)

    async def _update_gcs_permissions(self, storage_path: str, is_public: bool):
        """Update GCS file permissions"""
        blob = self.bucket.blob(storage_path)
        if is_public:
            blob.make_public()
        else:
            blob.make_private()


# Global service instance
media_service = MediaService()
