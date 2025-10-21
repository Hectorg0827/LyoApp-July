"""Progress tracking and mastery estimation routes"""
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.dependencies import get_current_user
from src.auth.models import User
from src.core.database import get_db
from src.learning.models import (
    MasteryEstimate,
    ReviewQueue,
    KnowledgeComponent,
    Course,
    Session as LearningSession,
    Attempt,
)
from src.learning.schemas import (
    ProgressResponse,
    MasteryEstimateResponse,
    ReviewQueueItemResponse,
)
from src.learning.services.policy import KnowledgeTracer, SpacedRepetitionScheduler

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/progress", tags=["progress"])


@router.get("/", response_model=ProgressResponse)
async def get_progress(
    course_id: Optional[UUID] = None,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get user progress overview.

    **Query Parameters:**
    - `course_id`: Filter by specific course (optional)

    **Returns:**
    - `theta_by_kc`: Mastery estimates by knowledge component (slug: theta)
    - `streak`: Current learning streak in days
    - `review_queue`: Due and upcoming review items
    """
    # Get mastery estimates
    stmt = (
        select(MasteryEstimate, KnowledgeComponent)
        .join(KnowledgeComponent, MasteryEstimate.kc_id == KnowledgeComponent.id)
        .where(MasteryEstimate.user_id == current_user.id)
    )

    result = await session.execute(stmt)
    mastery_data = result.all()

    theta_by_kc = {
        kc.slug: float(mastery.theta)
        for mastery, kc in mastery_data
    }

    # Calculate streak (days with at least one session)
    # For MVP: simplified streak calculation
    stmt = (
        select(func.date(LearningSession.started_at))
        .join(Course, LearningSession.course_id == Course.id)
        .where(
            Course.user_id == current_user.id,
            LearningSession.status == "ended",
        )
        .distinct()
        .order_by(func.date(LearningSession.started_at).desc())
    )

    result = await session.execute(stmt)
    session_dates = [row[0] for row in result.all()]

    # Calculate consecutive days
    streak = 0
    if session_dates:
        today = datetime.now(timezone.utc).date()
        for i, date in enumerate(session_dates):
            expected_date = today if i == 0 else session_dates[i - 1] - timedelta(days=1)
            if date == expected_date or (i == 0 and (today - date).days <= 1):
                streak += 1
            else:
                break

    # Get review queue
    scheduler = SpacedRepetitionScheduler(session)
    due_reviews = await scheduler.get_due_reviews(current_user.id)
    upcoming_reviews = await scheduler.get_upcoming_reviews(current_user.id, days_ahead=7)

    review_items = due_reviews + [r for r in upcoming_reviews if r not in due_reviews]

    review_queue = [
        ReviewQueueItemResponse(
            alo_id=review.alo_id,
            next_due=review.next_due,
            interval_days=review.interval_days,
            reps=review.reps,
        )
        for review in review_items[:10]  # Limit to 10 items
    ]

    logger.info(f"📊 Progress retrieved for user {current_user.id}: {len(theta_by_kc)} KCs, streak={streak}")

    return ProgressResponse(
        theta_by_kc=theta_by_kc,
        streak=streak,
        review_queue=review_queue,
    )


@router.get("/mastery", response_model=list[MasteryEstimateResponse])
async def get_mastery_estimates(
    kc_slug: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get detailed mastery estimates.

    **Query Parameters:**
    - `kc_slug`: Filter by specific KC slug (optional)

    **Returns:**
    - List of mastery estimates with metadata
    """
    stmt = (
        select(MasteryEstimate, KnowledgeComponent)
        .join(KnowledgeComponent, MasteryEstimate.kc_id == KnowledgeComponent.id)
        .where(MasteryEstimate.user_id == current_user.id)
    )

    if kc_slug:
        stmt = stmt.where(KnowledgeComponent.slug == kc_slug)

    result = await session.execute(stmt)
    mastery_data = result.all()

    return [
        MasteryEstimateResponse(
            kc_id=mastery.kc_id,
            kc_slug=kc.slug,
            theta=float(mastery.theta),
            attempts_count=mastery.attempts_count,
            correct_count=mastery.correct_count,
            updated_at=mastery.updated_at,
        )
        for mastery, kc in mastery_data
    ]


@router.get("/reviews/due", response_model=list[ReviewQueueItemResponse])
async def get_due_reviews(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get all due reviews that need to be completed now.

    **Returns:**
    - List of review items due for immediate practice
    """
    scheduler = SpacedRepetitionScheduler(session)
    due_reviews = await scheduler.get_due_reviews(current_user.id)

    return [
        ReviewQueueItemResponse(
            alo_id=review.alo_id,
            next_due=review.next_due,
            interval_days=review.interval_days,
            reps=review.reps,
        )
        for review in due_reviews
    ]


@router.get("/reviews/upcoming", response_model=list[ReviewQueueItemResponse])
async def get_upcoming_reviews(
    days_ahead: int = 7,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get upcoming reviews within specified days.

    **Query Parameters:**
    - `days_ahead`: Number of days to look ahead (default: 7)

    **Returns:**
    - List of review items scheduled in the near future
    """
    if days_ahead < 1 or days_ahead > 30:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="days_ahead must be between 1 and 30",
        )

    scheduler = SpacedRepetitionScheduler(session)
    upcoming_reviews = await scheduler.get_upcoming_reviews(current_user.id, days_ahead)

    return [
        ReviewQueueItemResponse(
            alo_id=review.alo_id,
            next_due=review.next_due,
            interval_days=review.interval_days,
            reps=review.reps,
        )
        for review in upcoming_reviews
    ]


@router.get("/stats", response_model=dict)
async def get_learning_stats(
    course_id: Optional[UUID] = None,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get comprehensive learning statistics.

    **Query Parameters:**
    - `course_id`: Filter by specific course (optional)

    **Returns:**
    - Total learning time
    - Number of completed ALOs
    - Average accuracy
    - Recent activity
    """
    # Build base query
    stmt = (
        select(LearningSession, Course)
        .join(Course, LearningSession.course_id == Course.id)
        .where(Course.user_id == current_user.id)
    )

    if course_id:
        stmt = stmt.where(Course.id == course_id)

    result = await session.execute(stmt)
    sessions_data = result.all()

    # Calculate total time (ended sessions only)
    total_time_sec = 0
    session_ids = []
    for learning_session, course in sessions_data:
        if learning_session.ended_at and learning_session.started_at:
            duration = (learning_session.ended_at - learning_session.started_at).total_seconds()
            total_time_sec += duration
        session_ids.append(learning_session.id)

    # Get attempt statistics
    if session_ids:
        stmt = select(Attempt).where(Attempt.session_id.in_(session_ids))
        result = await session.execute(stmt)
        attempts = result.scalars().all()

        total_attempts = len(attempts)
        correct_attempts = sum(1 for a in attempts if a.correct is True)
        accuracy = (correct_attempts / total_attempts * 100) if total_attempts > 0 else 0.0

        # Completed ALOs (unique)
        completed_alo_ids = {a.alo_id for a in attempts if a.correct is True}
        completed_alos = len(completed_alo_ids)
    else:
        total_attempts = 0
        accuracy = 0.0
        completed_alos = 0

    return {
        "total_learning_time_min": int(total_time_sec // 60),
        "completed_alos": completed_alos,
        "total_attempts": total_attempts,
        "accuracy_percent": round(accuracy, 1),
        "active_courses": len([s for s, c in sessions_data if c.status == "active"]),
        "completed_courses": len([s for s, c in sessions_data if c.status == "completed"]),
    }


# Import timedelta
from datetime import timedelta
