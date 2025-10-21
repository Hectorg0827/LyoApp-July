"""Course Compiler Service

Implements the course compilation pipeline:
1. IntentParser - Normalize goal string
2. GoalPlanner - Draft target LOs
3. GraphExpander - Resolve prerequisites, build KC DAG
4. Composer - Select/adapt ALOs from library
5. Validator - Check rubric completeness
6. ScheduleBuilder - Distribute ALOs into sessions
"""
import logging
import re
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Set, Tuple
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.learning.models import (
    KnowledgeComponent,
    LearningObjective,
    ALO,
    Prerequisite,
    Course,
)
from src.learning.schemas import (
    CompileCourseRequest,
    CompileCourseResponse,
    SkillGraphResponse,
    KnowledgeComponentResponse,
    LearningObjectiveResponse,
    ALOResponse,
    SessionScheduleItem,
)

logger = logging.getLogger(__name__)


# =============================================================================
# Intent Parser
# =============================================================================

class IntentParser:
    """Normalize and extract information from user goal"""

    @staticmethod
    def parse(goal: str) -> Dict[str, any]:
        """Extract intent from goal string

        Returns:
            Dict with: normalized_goal, detected_tags, estimated_complexity
        """
        normalized = goal.strip().lower()

        # Detect topics/tags from common keywords
        tag_patterns = {
            "css": r"\bcss\b",
            "flexbox": r"\bflexbox\b|\bflex\b(?! \w+box)",
            "responsive": r"\bresponsive\b|\badaptive\b",
            "layout": r"\blayout\b",
            "web": r"\bweb\b",
            "beginner": r"\bbeginner\b|\bbasic\b|\bintro\b",
            "advanced": r"\badvanced\b|\bexpert\b|\bmaster\b",
        }

        detected_tags = []
        for tag, pattern in tag_patterns.items():
            if re.search(pattern, normalized):
                detected_tags.append(tag)

        # Estimate complexity
        complexity = "beginner"
        if any(tag in detected_tags for tag in ["advanced", "expert", "master"]):
            complexity = "advanced"
        elif len(detected_tags) >= 3 or "intermediate" in normalized:
            complexity = "intermediate"

        logger.info(f"📝 Parsed intent: tags={detected_tags}, complexity={complexity}")

        return {
            "normalized_goal": goal.strip(),
            "detected_tags": detected_tags,
            "estimated_complexity": complexity,
        }


# =============================================================================
# Goal Planner
# =============================================================================

class GoalPlanner:
    """Draft target LOs based on goal and constraints"""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def plan(
        self,
        intent: Dict[str, any],
        time_budget_min: int,
        deadline: Optional[datetime] = None,
    ) -> List[UUID]:
        """Draft target LO IDs

        For MVP, select from existing LOs that match tags
        """
        detected_tags = intent.get("detected_tags", [])

        # Query LOs that match tags
        stmt = (
            select(LearningObjective)
            .join(LearningObjective.knowledge_component)
            .options(selectinload(LearningObjective.knowledge_component))
            .where(
                KnowledgeComponent.tags.overlap(detected_tags)
                if detected_tags
                else True
            )
        )

        result = await self.session.execute(stmt)
        los = result.scalars().all()

        if not los:
            # Fallback: select all LOs (for testing)
            stmt = select(LearningObjective).options(
                selectinload(LearningObjective.knowledge_component)
            )
            result = await self.session.execute(stmt)
            los = result.scalars().all()

        # Sort by difficulty (easiest first for progressive learning)
        los_sorted = sorted(los, key=lambda lo: lo.difficulty)

        # Estimate how many LOs fit in time budget
        # Assume average LO takes 10-15 minutes
        avg_time_per_lo = 12  # minutes
        max_los = max(1, time_budget_min // avg_time_per_lo)

        selected_lo_ids = [lo.id for lo in los_sorted[:max_los]]

        logger.info(f"🎯 Planned {len(selected_lo_ids)} LOs within budget of {time_budget_min}min")

        return selected_lo_ids


# =============================================================================
# Graph Expander
# =============================================================================

class GraphExpander:
    """Resolve prerequisites and build KC DAG"""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def expand(
        self,
        target_lo_ids: List[UUID],
        prior_knowledge_slugs: List[str] = None,
    ) -> Tuple[List[KnowledgeComponent], List[Prerequisite], List[LearningObjective]]:
        """Expand target LOs to include all prerequisites

        Returns:
            (kcs, prerequisites, los)
        """
        if prior_knowledge_slugs is None:
            prior_knowledge_slugs = []

        # Load target LOs with their KCs
        stmt = (
            select(LearningObjective)
            .where(LearningObjective.id.in_(target_lo_ids))
            .options(selectinload(LearningObjective.knowledge_component))
        )
        result = await self.session.execute(stmt)
        target_los = list(result.scalars().all())

        # Extract target KCs
        target_kc_ids = {lo.kc_id for lo in target_los}

        # Load all prerequisites
        stmt = select(Prerequisite)
        result = await self.session.execute(stmt)
        all_prereqs = list(result.scalars().all())

        # Build prerequisite graph
        prereq_map: Dict[UUID, List[UUID]] = {}
        for prereq in all_prereqs:
            if prereq.kc_id not in prereq_map:
                prereq_map[prereq.kc_id] = []
            prereq_map[prereq.kc_id].append(prereq.prereq_kc_id)

        # Expand to include all transitive prerequisites
        required_kc_ids = set(target_kc_ids)
        to_process = list(target_kc_ids)

        while to_process:
            kc_id = to_process.pop()
            if kc_id in prereq_map:
                for prereq_id in prereq_map[kc_id]:
                    if prereq_id not in required_kc_ids:
                        required_kc_ids.add(prereq_id)
                        to_process.append(prereq_id)

        # Remove prior knowledge KCs
        if prior_knowledge_slugs:
            stmt = select(KnowledgeComponent).where(
                KnowledgeComponent.slug.in_(prior_knowledge_slugs)
            )
            result = await self.session.execute(stmt)
            prior_kcs = list(result.scalars().all())
            prior_kc_ids = {kc.id for kc in prior_kcs}
            required_kc_ids -= prior_kc_ids
            logger.info(f"🧠 Removed {len(prior_kc_ids)} known KCs from plan")

        # Load all required KCs
        stmt = (
            select(KnowledgeComponent)
            .where(KnowledgeComponent.id.in_(required_kc_ids))
            .options(selectinload(KnowledgeComponent.learning_objectives))
        )
        result = await self.session.execute(stmt)
        required_kcs = list(result.scalars().all())

        # Collect relevant prerequisites
        relevant_prereqs = [
            p for p in all_prereqs if p.kc_id in required_kc_ids and p.prereq_kc_id in required_kc_ids
        ]

        # Collect all LOs for required KCs
        all_los = []
        for kc in required_kcs:
            all_los.extend(kc.learning_objectives)

        logger.info(
            f"📚 Expanded to {len(required_kcs)} KCs, {len(all_los)} LOs, {len(relevant_prereqs)} prerequisites"
        )

        return required_kcs, relevant_prereqs, all_los


# =============================================================================
# Composer
# =============================================================================

class Composer:
    """Select/adapt ALOs from library"""

    def __init__(self, session: AsyncSession):
        self.session = session

    async def compose(
        self,
        los: List[LearningObjective],
        time_budget_sec: int,
    ) -> List[ALO]:
        """Select best ALOs for each LO

        For MVP: Simply select all ALOs for the given LOs, respecting time budget
        """
        lo_ids = [lo.id for lo in los]

        # Load all ALOs for these LOs
        stmt = (
            select(ALO)
            .where(ALO.lo_id.in_(lo_ids))
            .order_by(ALO.difficulty, ALO.alo_type)  # Order by difficulty, then type
        )
        result = await self.session.execute(stmt)
        candidate_alos = list(result.scalars().all())

        # Select ALOs within time budget
        selected_alos = []
        total_time = 0

        for alo in candidate_alos:
            if total_time + alo.est_time_sec <= time_budget_sec:
                selected_alos.append(alo)
                total_time += alo.est_time_sec
            else:
                logger.warning(f"⏱️ Time budget exceeded, stopping at {len(selected_alos)} ALOs")
                break

        logger.info(
            f"🎼 Composed {len(selected_alos)} ALOs, total time: {total_time}s ({total_time // 60}min)"
        )

        return selected_alos


# =============================================================================
# Validator
# =============================================================================

class Validator:
    """Validate course structure and content"""

    @staticmethod
    def validate(
        kcs: List[KnowledgeComponent],
        los: List[LearningObjective],
        alos: List[ALO],
    ) -> Tuple[bool, List[str]]:
        """Validate compiled course

        Returns:
            (is_valid, errors)
        """
        errors = []

        # Check: At least one KC
        if not kcs:
            errors.append("No knowledge components in course")

        # Check: At least one LO
        if not los:
            errors.append("No learning objectives in course")

        # Check: At least one ALO
        if not alos:
            errors.append("No atomic learning objects in course")

        # Check: Each LO has at least one ALO
        lo_ids = {lo.id for lo in los}
        alo_lo_ids = {alo.lo_id for alo in alos}
        missing_alos = lo_ids - alo_lo_ids

        if missing_alos:
            errors.append(f"{len(missing_alos)} LOs have no ALOs")

        # Check: ALO time estimates are reasonable
        for alo in alos:
            if alo.est_time_sec <= 0:
                errors.append(f"ALO {alo.id} has invalid time estimate")
            if alo.est_time_sec > 3600:  # > 1 hour
                errors.append(f"ALO {alo.id} time estimate too long ({alo.est_time_sec}s)")

        # Check: ALO content is not empty
        for alo in alos:
            if not alo.content:
                errors.append(f"ALO {alo.id} has empty content")

        is_valid = len(errors) == 0

        if is_valid:
            logger.info("✅ Course validation passed")
        else:
            logger.warning(f"❌ Course validation failed: {errors}")

        return is_valid, errors


# =============================================================================
# Schedule Builder
# =============================================================================

class ScheduleBuilder:
    """Build session schedule"""

    @staticmethod
    def build_schedule(
        alos: List[ALO],
        time_budget_min_per_day: int,
    ) -> List[SessionScheduleItem]:
        """Distribute ALOs into daily sessions

        Returns:
            List of SessionScheduleItem
        """
        time_budget_sec_per_day = time_budget_min_per_day * 60
        schedule = []
        day = 1
        current_session_alos = []
        current_session_time = 0

        for alo in alos:
            if current_session_time + alo.est_time_sec > time_budget_sec_per_day:
                # Start new day
                if current_session_alos:
                    schedule.append(
                        SessionScheduleItem(
                            day=day,
                            session={"alo_ids": [str(alo.id) for alo in current_session_alos]}
                        )
                    )
                    day += 1
                    current_session_alos = []
                    current_session_time = 0

            current_session_alos.append(alo)
            current_session_time += alo.est_time_sec

        # Add final session
        if current_session_alos:
            schedule.append(
                SessionScheduleItem(
                    day=day,
                    session={"alo_ids": [str(alo.id) for alo in current_session_alos]}
                )
            )

        logger.info(f"📅 Built schedule: {len(schedule)} days, ~{time_budget_min_per_day}min/day")

        return schedule


# =============================================================================
# Main Compiler Orchestrator
# =============================================================================

class CourseCompiler:
    """Main course compiler orchestrating all stages"""

    def __init__(self, session: AsyncSession):
        self.session = session
        self.parser = IntentParser()
        self.planner = GoalPlanner(session)
        self.expander = GraphExpander(session)
        self.composer = Composer(session)
        self.validator = Validator()
        self.scheduler = ScheduleBuilder()

    async def compile(
        self,
        user_id: UUID,
        request: CompileCourseRequest,
    ) -> CompileCourseResponse:
        """Execute full compilation pipeline

        Returns:
            CompileCourseResponse with course_id, skill_graph, and schedule
        """
        logger.info(f"🚀 Starting course compilation for user {user_id}")
        logger.info(f"   Goal: {request.goal}")
        logger.info(f"   Budget: {request.time_budget_min_per_day} min/day")

        # Stage 1: Parse intent
        intent = self.parser.parse(request.goal)

        # Stage 2: Plan LOs
        target_lo_ids = await self.planner.plan(
            intent,
            request.time_budget_min_per_day * 60,  # Total budget for planning
            None,  # deadline not used in MVP
        )

        # Stage 3: Expand graph
        kcs, prereqs, los = await self.expander.expand(
            target_lo_ids,
            request.prior_knowledge_ids,
        )

        # Stage 4: Compose ALOs
        time_budget_total_sec = request.time_budget_min_per_day * 60 * 30  # 30 days max
        alos = await self.composer.compose(los, time_budget_total_sec)

        # Stage 5: Validate
        is_valid, errors = self.validator.validate(kcs, los, alos)
        if not is_valid:
            raise ValueError(f"Course validation failed: {errors}")

        # Stage 6: Build schedule
        schedule = self.scheduler.build_schedule(alos, request.time_budget_min_per_day)

        # Create skill graph response
        skill_graph = SkillGraphResponse(
            kcs=[KnowledgeComponentResponse.from_orm(kc) for kc in kcs],
            edges=[{"from": p.prereq_kc_id, "to": p.kc_id} for p in prereqs],
            los=[LearningObjectiveResponse.from_orm(lo) for lo in los],
            alos=[ALOResponse.from_orm(alo) for alo in alos],
        )

        # Persist course
        course = Course(
            user_id=user_id,
            goal=request.goal,
            skill_graph=skill_graph.dict(),
            schedule=[s.dict() for s in schedule],
            status="active",
        )
        self.session.add(course)
        await self.session.commit()
        await self.session.refresh(course)

        # Calculate total time
        total_time_sec = sum(alo.est_time_sec for alo in alos)
        estimated_total_time_min = total_time_sec // 60

        logger.info(f"✅ Course compiled: {course.id}")
        logger.info(f"   {len(kcs)} KCs, {len(los)} LOs, {len(alos)} ALOs")
        logger.info(f"   {len(schedule)} days, ~{estimated_total_time_min} minutes total")

        return CompileCourseResponse(
            course_id=course.id,
            skill_graph=skill_graph,
            schedule=schedule,
            estimated_total_time_min=estimated_total_time_min,
        )
