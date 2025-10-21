"""Course compilation and management routes"""
import logging
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.dependencies import get_current_user
from src.auth.models import User
from src.core.database import get_db
from src.learning.models import Course
from src.learning.schemas import (
    CompileCourseRequest,
    CompileCourseResponse,
    SkillGraphResponse,
)
from src.learning.services.compiler import CourseCompiler

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/courses", tags=["courses"])


@router.post("/compile", response_model=CompileCourseResponse, status_code=status.HTTP_201_CREATED)
async def compile_course(
    request: CompileCourseRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Compile a new course from user goal and constraints.

    **Pipeline:**
    1. Parse intent from goal
    2. Plan target learning objectives
    3. Expand prerequisites into skill graph
    4. Compose ALOs from library
    5. Validate course structure
    6. Build session schedule

    **Returns:**
    - `course_id`: Persistent course ID
    - `skill_graph`: KCs, LOs, ALOs, and dependency edges
    - `schedule`: Daily session plan with ALO IDs
    - `estimated_total_time_min`: Total estimated completion time
    """
    try:
        compiler = CourseCompiler(session)
        result = await compiler.compile(current_user.id, request)

        logger.info(f"✅ Course compiled: {result.course_id} for user {current_user.id}")

        return result

    except ValueError as e:
        logger.error(f"❌ Validation error: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e),
        )
    except Exception as e:
        logger.error(f"❌ Compilation failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Course compilation failed",
        )


@router.get("/{course_id}/plan", response_model=CompileCourseResponse)
async def get_course_plan(
    course_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Retrieve a compiled course plan.

    **Returns:**
    - Frozen skill graph and schedule from compilation
    """
    # Load course
    stmt = select(Course).where(
        Course.id == course_id,
        Course.user_id == current_user.id,
    )
    result = await session.execute(stmt)
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    # Parse stored skill graph and schedule
    skill_graph = SkillGraphResponse(**course.skill_graph)
    schedule = course.schedule

    # Calculate total time
    total_time_sec = sum(
        alo.est_time_sec for alo in skill_graph.alos
    )
    estimated_total_time_min = total_time_sec // 60

    return CompileCourseResponse(
        course_id=course.id,
        skill_graph=skill_graph,
        schedule=schedule,
        estimated_total_time_min=estimated_total_time_min,
    )


@router.get("/", response_model=list[dict])
async def list_courses(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    List all courses for the current user.

    **Query Parameters:**
    - `status_filter`: Filter by status (active, completed, paused)

    **Returns:**
    - List of courses with basic info
    """
    stmt = select(Course).where(Course.user_id == current_user.id)

    if status_filter:
        stmt = stmt.where(Course.status == status_filter)

    stmt = stmt.order_by(Course.created_at.desc())

    result = await session.execute(stmt)
    courses = result.scalars().all()

    return [
        {
            "id": str(course.id),
            "goal": course.goal,
            "status": course.status,
            "created_at": course.created_at.isoformat(),
            "updated_at": course.updated_at.isoformat(),
        }
        for course in courses
    ]


@router.patch("/{course_id}/status")
async def update_course_status(
    course_id: UUID,
    new_status: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Update course status.

    **Allowed statuses:**
    - `active`: Currently learning
    - `paused`: Temporarily stopped
    - `completed`: Finished all objectives

    **Returns:**
    - Updated course info
    """
    if new_status not in ["active", "paused", "completed"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid status. Must be: active, paused, or completed",
        )

    # Load course
    stmt = select(Course).where(
        Course.id == course_id,
        Course.user_id == current_user.id,
    )
    result = await session.execute(stmt)
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    course.status = new_status
    await session.commit()

    logger.info(f"✅ Course {course_id} status updated to: {new_status}")

    return {
        "id": str(course.id),
        "status": course.status,
        "updated_at": course.updated_at.isoformat(),
    }


@router.delete("/{course_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_course(
    course_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Delete a course and all associated sessions.

    **Warning:** This action is irreversible.
    """
    # Load course
    stmt = select(Course).where(
        Course.id == course_id,
        Course.user_id == current_user.id,
    )
    result = await session.execute(stmt)
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    await session.delete(course)
    await session.commit()

    logger.info(f"🗑️ Course {course_id} deleted by user {current_user.id}")

    return None
