"""Policy Service

Implements:
1. Knowledge tracing (theta updates)
2. Next ALO decision logic (advance/remediate/review)
3. Spaced repetition scheduling (SM-2 algorithm)
"""
import logging
import math
from datetime import datetime, timedelta, timezone
from typing import Dict, Optional, Tuple
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.learning.models import (
    MasteryEstimate,
    ReviewQueue,
    ALO,
    LearningObjective,
    Course,
)
from src.learning.schemas import PolicyDecision, ThetaUpdate

logger = logging.getLogger(__name__)


# =============================================================================
# Knowledge Tracing
# =============================================================================

class KnowledgeTracer:
    """Update mastery estimates (theta) based on performance"""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def update_theta(
        self,
        update: ThetaUpdate,
    ) -> float:
        """Update theta for a KC using simple Bayesian update

        Args:
            update: ThetaUpdate with user_id, kc_id, correct, difficulty

        Returns:
            New theta value (0.000 to 1.000)
        """
        # Get or create mastery estimate
        stmt = select(MasteryEstimate).where(
            MasteryEstimate.user_id == update.user_id,
            MasteryEstimate.kc_id == update.kc_id,
        )
        result = await self.session.execute(stmt)
        mastery = result.scalar_one_or_none()

        if not mastery:
            # Create new estimate
            mastery = MasteryEstimate(
                user_id=update.user_id,
                kc_id=update.kc_id,
                theta=0.5,  # Start at 50%
                attempts_count=0,
                correct_count=0,
            )
            self.session.add(mastery)

        # Update counts
        mastery.attempts_count += 1
        if update.correct:
            mastery.correct_count += 1

        # Simple logistic update
        # theta' = theta + learning_rate * (outcome - theta) * difficulty_factor
        old_theta = float(mastery.theta)
        outcome = 1.0 if update.correct else 0.0

        # Learning rate decays with more attempts
        base_learning_rate = 0.3
        learning_rate = base_learning_rate / (1 + 0.1 * mastery.attempts_count)

        # Difficulty factor: harder items have more impact
        difficulty_factor = 1.0 + (update.difficulty * 0.2)  # -2 to +2 → 0.6 to 1.4

        # Update
        delta = learning_rate * (outcome - old_theta) * difficulty_factor
        new_theta = max(0.0, min(1.0, old_theta + delta))

        mastery.theta = new_theta
        mastery.updated_at = datetime.now(timezone.utc)

        await self.session.commit()

        logger.info(
            f"📊 Theta updated: KC={update.kc_id} | {old_theta:.3f} → {new_theta:.3f} | "
            f"correct={update.correct}, difficulty={update.difficulty}"
        )

        return new_theta

    async def get_theta(self, user_id: UUID, kc_id: UUID) -> float:
        """Get current theta for a KC"""
        stmt = select(MasteryEstimate).where(
            MasteryEstimate.user_id == user_id,
            MasteryEstimate.kc_id == kc_id,
        )
        result = await self.session.execute(stmt)
        mastery = result.scalar_one_or_none()

        return float(mastery.theta) if mastery else 0.5

    async def get_all_theta(self, user_id: UUID) -> Dict[UUID, float]:
        """Get all theta values for a user"""
        stmt = select(MasteryEstimate).where(MasteryEstimate.user_id == user_id)
        result = await self.session.execute(stmt)
        masteries = result.scalars().all()

        return {m.kc_id: float(m.theta) for m in masteries}


# =============================================================================
# Policy Engine
# =============================================================================

class PolicyEngine:
    """Decide next ALO based on performance and mastery"""

    def __init__(self, session: AsyncSession):
        self.session = session
        self.tracer = KnowledgeTracer(session)

    async def decide_next_alo(
        self,
        user_id: UUID,
        course_id: UUID,
        last_alo_id: UUID,
        correct: Optional[bool],
        hints_used: int,
        latency_ms: Optional[int],
    ) -> PolicyDecision:
        """Decide next ALO based on policy

        Policy:
        1. If correct AND low hints AND fast → advance
        2. If wrong OR many hints OR slow → remediate
        3. If review is due → review
        4. If no more ALOs → complete

        Returns:
            PolicyDecision with action, alo_id, reason, theta_updates
        """
        # Update theta based on last performance
        last_alo = await self._get_alo(last_alo_id)
        if correct is not None and last_alo:
            # Update theta for the ALO's KC
            lo = await self._get_lo(last_alo.lo_id)
            if lo:
                update = ThetaUpdate(
                    user_id=user_id,
                    kc_id=lo.kc_id,
                    correct=correct,
                    difficulty=last_alo.difficulty,
                )
                new_theta = await self.tracer.update_theta(update)
                theta_updates = {lo.kc_id: new_theta}
            else:
                theta_updates = {}
        else:
            theta_updates = {}

        # Check for due reviews first
        due_review = await self._get_due_review(user_id)
        if due_review:
            logger.info(f"📅 Review due: ALO={due_review.id}")
            return PolicyDecision(
                action="review",
                alo_id=due_review.id,
                reason="Spaced review due",
                theta_updates=theta_updates,
            )

        # Decide based on performance
        should_remediate = self._should_remediate(correct, hints_used, latency_ms)

        if should_remediate:
            # Find remediation ALO (easier difficulty, same KC)
            remediation_alo = await self._find_remediation_alo(last_alo_id)
            if remediation_alo:
                logger.info(f"🔄 Remediating: ALO={remediation_alo.id}")
                return PolicyDecision(
                    action="remediate",
                    alo_id=remediation_alo.id,
                    reason="Performance indicates need for reinforcement",
                    theta_updates=theta_updates,
                )

        # Advance to next ALO in course schedule
        next_alo = await self._get_next_scheduled_alo(user_id, course_id, last_alo_id)
        if next_alo:
            logger.info(f"➡️ Advancing: ALO={next_alo.id}")
            return PolicyDecision(
                action="advance",
                alo_id=next_alo.id,
                reason="Ready for next learning objective",
                theta_updates=theta_updates,
            )

        # No more ALOs - course complete
        logger.info(f"🎉 Course complete!")
        return PolicyDecision(
            action="complete",
            alo_id=None,
            reason="All learning objectives completed",
            theta_updates=theta_updates,
        )

    def _should_remediate(
        self,
        correct: Optional[bool],
        hints_used: int,
        latency_ms: Optional[int],
    ) -> bool:
        """Determine if remediation is needed"""
        # Wrong answer
        if correct is False:
            return True

        # Too many hints
        if hints_used > 2:
            return True

        # Very slow response (> 2 minutes for non-project items)
        if latency_ms and latency_ms > 120000:
            return True

        return False

    async def _get_alo(self, alo_id: UUID) -> Optional[ALO]:
        """Get ALO by ID"""
        stmt = select(ALO).where(ALO.id == alo_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def _get_lo(self, lo_id: UUID) -> Optional[LearningObjective]:
        """Get LO by ID"""
        stmt = select(LearningObjective).where(LearningObjective.id == lo_id)
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def _get_due_review(self, user_id: UUID) -> Optional[ALO]:
        """Get next due review ALO"""
        now = datetime.now(timezone.utc)
        stmt = (
            select(ReviewQueue)
            .where(
                ReviewQueue.user_id == user_id,
                ReviewQueue.next_due <= now,
            )
            .order_by(ReviewQueue.next_due)
            .limit(1)
        )
        result = await self.session.execute(stmt)
        review = result.scalar_one_or_none()

        if review:
            # Load the ALO
            return await self._get_alo(review.alo_id)

        return None

    async def _find_remediation_alo(self, last_alo_id: UUID) -> Optional[ALO]:
        """Find an easier ALO for remediation (same LO, lower difficulty)"""
        last_alo = await self._get_alo(last_alo_id)
        if not last_alo:
            return None

        # Find ALOs from same LO with lower difficulty
        stmt = (
            select(ALO)
            .where(
                ALO.lo_id == last_alo.lo_id,
                ALO.difficulty < last_alo.difficulty,
                ALO.id != last_alo_id,
            )
            .order_by(ALO.difficulty.desc())  # Closest difficulty below
            .limit(1)
        )
        result = await self.session.execute(stmt)
        return result.scalar_one_or_none()

    async def _get_next_scheduled_alo(
        self,
        user_id: UUID,
        course_id: UUID,
        last_alo_id: UUID,
    ) -> Optional[ALO]:
        """Get next ALO from course schedule"""
        # Load course
        stmt = select(Course).where(Course.id == course_id)
        result = await self.session.execute(stmt)
        course = result.scalar_one_or_none()

        if not course:
            return None

        # Extract schedule
        schedule = course.schedule

        # Find last ALO in schedule and get next
        for day_item in schedule:
            session_data = day_item.get("session", {})
            alo_ids = session_data.get("alo_ids", [])

            if str(last_alo_id) in alo_ids:
                idx = alo_ids.index(str(last_alo_id))
                if idx + 1 < len(alo_ids):
                    # Next in same session
                    next_alo_id = UUID(alo_ids[idx + 1])
                    return await self._get_alo(next_alo_id)
                else:
                    # Check next day's session
                    day_idx = schedule.index(day_item)
                    if day_idx + 1 < len(schedule):
                        next_day = schedule[day_idx + 1]
                        next_session = next_day.get("session", {})
                        next_alo_ids = next_session.get("alo_ids", [])
                        if next_alo_ids:
                            next_alo_id = UUID(next_alo_ids[0])
                            return await self._get_alo(next_alo_id)

        return None


# =============================================================================
# Spaced Repetition Scheduler
# =============================================================================

class SpacedRepetitionScheduler:
    """SM-2 algorithm for spaced review scheduling"""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def schedule_review(
        self,
        user_id: UUID,
        alo_id: UUID,
        quality: int,  # 0-5 scale (0=complete blackout, 5=perfect)
    ):
        """Schedule or update review using SM-2 algorithm

        Args:
            user_id: User ID
            alo_id: ALO ID
            quality: Response quality (0-5)
        """
        # Get or create review item
        stmt = select(ReviewQueue).where(
            ReviewQueue.user_id == user_id,
            ReviewQueue.alo_id == alo_id,
        )
        result = await self.session.execute(stmt)
        review = result.scalar_one_or_none()

        if not review:
            # Create new review
            review = ReviewQueue(
                user_id=user_id,
                alo_id=alo_id,
                next_due=datetime.now(timezone.utc) + timedelta(days=1),
                interval_days=1,
                easiness=2.5,
                reps=0,
            )
            self.session.add(review)

        # SM-2 algorithm
        old_easiness = float(review.easiness)
        old_interval = review.interval_days
        old_reps = review.reps

        # Calculate new easiness
        # EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        new_easiness = old_easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
        new_easiness = max(1.3, new_easiness)  # Minimum EF is 1.3

        # Calculate new interval
        if quality < 3:
            # Failed review - reset
            new_interval = 1
            new_reps = 0
        else:
            # Successful review
            new_reps = old_reps + 1
            if new_reps == 1:
                new_interval = 1
            elif new_reps == 2:
                new_interval = 6
            else:
                new_interval = math.ceil(old_interval * new_easiness)

        # Update review
        review.easiness = new_easiness
        review.interval_days = new_interval
        review.reps = new_reps
        review.next_due = datetime.now(timezone.utc) + timedelta(days=new_interval)
        review.updated_at = datetime.now(timezone.utc)

        await self.session.commit()

        logger.info(
            f"📅 Review scheduled: ALO={alo_id} | "
            f"interval: {old_interval}d → {new_interval}d | "
            f"easiness: {old_easiness:.2f} → {new_easiness:.2f} | "
            f"quality={quality}"
        )

    async def get_due_reviews(self, user_id: UUID) -> list[ReviewQueue]:
        """Get all due reviews for a user"""
        now = datetime.now(timezone.utc)
        stmt = (
            select(ReviewQueue)
            .where(
                ReviewQueue.user_id == user_id,
                ReviewQueue.next_due <= now,
            )
            .order_by(ReviewQueue.next_due)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())

    async def get_upcoming_reviews(
        self,
        user_id: UUID,
        days_ahead: int = 7,
    ) -> list[ReviewQueue]:
        """Get upcoming reviews within N days"""
        now = datetime.now(timezone.utc)
        future = now + timedelta(days=days_ahead)
        stmt = (
            select(ReviewQueue)
            .where(
                ReviewQueue.user_id == user_id,
                ReviewQueue.next_due.between(now, future),
            )
            .order_by(ReviewQueue.next_due)
        )
        result = await self.session.execute(stmt)
        return list(result.scalars().all())
