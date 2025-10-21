"""Evidence submission and assessment routes"""
import logging
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.dependencies import get_current_user
from src.auth.models import User
from src.core.database import get_db
from src.learning.models import ALO, LearningObjective
from src.learning.schemas import (
    SubmitEvidenceRequest,
    SubmitEvidenceResponse,
    ThetaUpdate,
)
from src.learning.services.policy import KnowledgeTracer, SpacedRepetitionScheduler

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/evidence", tags=["evidence"])


@router.post("/submit", response_model=SubmitEvidenceResponse)
async def submit_evidence(
    request: SubmitEvidenceRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Submit evidence for an ALO and get assessment feedback.

    **Process:**
    1. Validate artifacts against ALO assessment_spec
    2. Run auto-checks if available
    3. Update mastery estimate (theta)
    4. Schedule spaced review if passed
    5. Return feedback and updated theta

    **Request:**
    - `alo_id`: ALO being completed
    - `artifacts`: User-submitted work (code, text, files)
    - `checks`: Client-side or server-side check results

    **Returns:**
    - `passed`: Whether evidence met rubric
    - `feedback`: Human-readable feedback
    - `theta_updated`: Updated mastery estimates by KC
    """
    # Load ALO
    stmt = (
        select(ALO)
        .where(ALO.id == request.alo_id)
    )
    result = await session.execute(stmt)
    alo = result.scalar_one_or_none()

    if not alo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ALO not found",
        )

    # Load LO to get KC
    stmt = select(LearningObjective).where(LearningObjective.id == alo.lo_id)
    result = await session.execute(stmt)
    lo = result.scalar_one_or_none()

    if not lo:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Associated learning objective not found",
        )

    # Assess evidence
    passed, feedback = await _assess_evidence(alo, request, session)

    # Update theta
    tracer = KnowledgeTracer(session)
    update = ThetaUpdate(
        user_id=current_user.id,
        kc_id=lo.kc_id,
        correct=passed,
        difficulty=alo.difficulty,
    )
    new_theta = await tracer.update_theta(update)

    theta_updated = {str(lo.kc_id): new_theta}

    # Schedule review if passed
    if passed:
        scheduler = SpacedRepetitionScheduler(session)
        # Quality score: 5 for perfect pass, 3 for marginal
        quality = 5 if len([c for c in request.checks if c.passed]) == len(request.checks) else 3
        await scheduler.schedule_review(current_user.id, request.alo_id, quality)

    logger.info(
        f"📝 Evidence submitted: ALO={request.alo_id}, user={current_user.id}, "
        f"passed={passed}, theta={new_theta:.3f}"
    )

    return SubmitEvidenceResponse(
        passed=passed,
        feedback=feedback,
        theta_updated=theta_updated,
    )


async def _assess_evidence(
    alo: ALO,
    request: SubmitEvidenceRequest,
    session: AsyncSession,
) -> tuple[bool, str]:
    """Assess submitted evidence against ALO assessment spec

    Returns:
        (passed, feedback)
    """
    # For MVP: Simple check-based assessment
    # In production: integrate code execution, LLM grading, etc.

    assessment_spec = alo.assessment_spec or {}
    auto_checks = assessment_spec.get("checks", [])

    # Validate all checks passed
    all_checks_passed = all(check.passed for check in request.checks)

    if not all_checks_passed:
        failed_checks = [check.name for check in request.checks if not check.passed]
        feedback = (
            f"Some checks did not pass: {', '.join(failed_checks)}. "
            f"Review the requirements and try again."
        )
        return False, feedback

    # Type-specific assessment
    if alo.alo_type == "quiz":
        # For quiz: check if correct answer was selected
        if request.checks:
            passed = request.checks[0].passed
            feedback = (
                "Correct! Well done." if passed else
                "Not quite. Review the explanation and try again."
            )
            return passed, feedback

    elif alo.alo_type == "exercise":
        # For exercise: validate code against requirements
        if all_checks_passed:
            feedback = (
                "Excellent! Your solution meets all requirements. "
                f"You've demonstrated mastery of this concept."
            )
            return True, feedback
        else:
            feedback = "Your solution has some issues. Check the feedback above."
            return False, feedback

    elif alo.alo_type == "project":
        # For project: validate against acceptance tests
        acceptance_tests = alo.content.get("acceptance_tests", [])
        passed_count = len([c for c in request.checks if c.passed])
        total_count = len(acceptance_tests)

        if passed_count == total_count:
            feedback = (
                f"🎉 Outstanding! Your project passes all {total_count} acceptance tests. "
                "You've successfully completed this learning objective."
            )
            return True, feedback
        else:
            feedback = (
                f"Your project passes {passed_count}/{total_count} acceptance tests. "
                "Keep working to meet all criteria."
            )
            return False, feedback

    else:
        # For explain/example: basic completion check
        if request.artifacts:
            feedback = "Great! You've engaged with this content."
            return True, feedback
        else:
            feedback = "Please provide your response."
            return False, feedback


@router.get("/{alo_id}/requirements", response_model=dict)
async def get_alo_requirements(
    alo_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get assessment requirements for an ALO.

    **Returns:**
    - Assessment specification
    - Expected checks
    - Rubric details
    """
    stmt = select(ALO).where(ALO.id == alo_id)
    result = await session.execute(stmt)
    alo = result.scalar_one_or_none()

    if not alo:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ALO not found",
        )

    assessment_spec = alo.assessment_spec or {}

    return {
        "alo_id": str(alo.id),
        "alo_type": alo.alo_type,
        "assessment_spec": assessment_spec,
        "difficulty": alo.difficulty,
        "estimated_time_sec": alo.est_time_sec,
    }
