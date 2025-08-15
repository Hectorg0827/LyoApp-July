# Media Upload API Routes
from typing import List
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..auth.dependencies import get_current_user
from ..auth.models import User
from ..core.database import get_db
from ..core.exceptions import BusinessLogicError, NotFoundError
from .schemas import MediaUpdateRequest, MediaUploadResponse
from .service import media_service

router = APIRouter(prefix="/media", tags=["media"])


@router.post("/upload", response_model=MediaUploadResponse)
async def upload_media(
    file: UploadFile = File(...),
    usage_type: str = Form(...),
    alt_text: str = Form(None),
    is_public: bool = Form(True),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Upload media file"""
    try:
        media_upload = await media_service.upload_file(
            file=file,
            user_id=current_user.id,
            usage_type=usage_type,
            alt_text=alt_text,
            is_public=is_public,
            db=db
        )
        
        return MediaUploadResponse.from_orm(media_upload)
        
    except BusinessLogicError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )


@router.get("/{media_id}", response_model=MediaUploadResponse)
async def get_media(
    media_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get media by ID"""
    media = await media_service.get_media(media_id, db)
    
    if not media:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Media not found"
        )
    
    # Check permissions
    if not media.is_public and media.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    return MediaUploadResponse.from_orm(media)


@router.put("/{media_id}", response_model=MediaUploadResponse)
async def update_media(
    media_id: UUID,
    update_data: MediaUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Update media metadata"""
    try:
        media = await media_service.update_media(
            media_id=media_id,
            user_id=current_user.id,
            alt_text=update_data.alt_text,
            is_public=update_data.is_public,
            db=db
        )
        
        return MediaUploadResponse.from_orm(media)
        
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except BusinessLogicError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


@router.delete("/{media_id}")
async def delete_media(
    media_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Delete media file"""
    try:
        await media_service.delete_media(media_id, current_user.id, db)
        return {"message": "Media deleted successfully"}
        
    except NotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except BusinessLogicError as e:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(e)
        )


@router.get("/user/{user_id}", response_model=List[MediaUploadResponse])
async def get_user_media(
    user_id: UUID,
    usage_type: str = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get media uploads for a user"""
    # This endpoint would need additional implementation in the service
    # For now, return empty list
    return []
