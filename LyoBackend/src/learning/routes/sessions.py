"""Session management and WebSocket runner routes"""
import json
import logging
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.auth.dependencies import get_current_user
from src.auth.models import User
from src.core.database import get_db, get_db_session
from src.learning.models import (
    Course,
    Session as LearningSession,
    Attempt,
    ALO,
)
from src.learning.schemas import (
    CreateSessionRequest,
    CreateSessionResponse,
    ALOMessage,
    SignalMessage,
    NextMessage,
    SessionEndMessage,
    ALOResponse,
)
from src.learning.services.policy import PolicyEngine

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/sessions", tags=["sessions"])


# =============================================================================
# REST Endpoints
# =============================================================================

@router.post("/", response_model=CreateSessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    request: CreateSessionRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Create a new learning session for a course.

    **Returns:**
    - Session ID for WebSocket connection
    - Initial metadata
    """
    # Verify course ownership
    stmt = select(Course).where(
        Course.id == request.course_id,
        Course.user_id == current_user.id,
    )
    result = await session.execute(stmt)
    course = result.scalar_one_or_none()

    if not course:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Course not found",
        )

    # Create session
    learning_session = LearningSession(
        course_id=request.course_id,
        status="active",
        metadata={"user_id": str(current_user.id)},
    )
    session.add(learning_session)
    await session.commit()
    await session.refresh(learning_session)

    logger.info(f"🎬 Session created: {learning_session.id} for course {request.course_id}")

    return CreateSessionResponse(
        session_id=learning_session.id,
        course_id=request.course_id,
        started_at=learning_session.started_at,
        status=learning_session.status,
    )


@router.get("/{session_id}", response_model=dict)
async def get_session(
    session_id: UUID,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
):
    """
    Get session details and progress.

    **Returns:**
    - Session metadata
    - Attempt history
    - Current position
    """
    # Load session with course
    stmt = (
        select(LearningSession, Course)
        .join(Course, LearningSession.course_id == Course.id)
        .where(
            LearningSession.id == session_id,
            Course.user_id == current_user.id,
        )
    )
    result = await session.execute(stmt)
    session_data = result.one_or_none()

    if not session_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Session not found",
        )

    learning_session, course = session_data

    # Get attempts
    stmt = (
        select(Attempt)
        .where(Attempt.session_id == session_id)
        .order_by(Attempt.event_time)
    )
    result = await session.execute(stmt)
    attempts = result.scalars().all()

    return {
        "session_id": str(learning_session.id),
        "course_id": str(course.id),
        "status": learning_session.status,
        "started_at": learning_session.started_at.isoformat(),
        "ended_at": learning_session.ended_at.isoformat() if learning_session.ended_at else None,
        "attempts_count": len(attempts),
        "correct_count": sum(1 for a in attempts if a.correct is True),
    }


# =============================================================================
# WebSocket Runner
# =============================================================================

class SessionRunner:
    """WebSocket session runner orchestrating real-time learning"""

    def __init__(self, session_id: UUID, user_id: UUID):
        self.session_id = session_id
        self.user_id = user_id
        self.course_id: Optional[UUID] = None
        self.current_alo_id: Optional[UUID] = None
        self.start_time = datetime.now(timezone.utc)

    async def run(self, websocket: WebSocket):
        """Main WebSocket session loop"""
        await websocket.accept()
        logger.info(f"🔌 WebSocket connected: session={self.session_id}, user={self.user_id}")

        try:
            # Load session and course
            async with get_db_session() as db_session:
                await self._load_session(db_session)

            # Send first ALO
            await self._send_first_alo(websocket)

            # Main event loop
            while True:
                # Receive signal from client
                try:
                    data = await websocket.receive_json()
                    signal = SignalMessage(**data)

                    # Process signal and decide next ALO
                    next_alo = await self._process_signal(signal)

                    # Send next ALO or end message
                    if next_alo:
                        await self._send_alo(websocket, next_alo)
                    else:
                        await self._send_end(websocket)
                        break

                except json.JSONDecodeError:
                    logger.warning(f"⚠️ Invalid JSON from client")
                    await websocket.send_json({"error": "Invalid message format"})

        except WebSocketDisconnect:
            logger.info(f"🔌 WebSocket disconnected: session={self.session_id}")
            await self._end_session()

        except Exception as e:
            logger.error(f"❌ WebSocket error: {e}", exc_info=True)
            await websocket.close(code=1011, reason="Internal server error")
            await self._end_session()

    async def _load_session(self, db_session: AsyncSession):
        """Load session and validate"""
        stmt = (
            select(LearningSession)
            .where(LearningSession.id == self.session_id)
            .options(selectinload(LearningSession.course))
        )
        result = await db_session.execute(stmt)
        session = result.scalar_one_or_none()

        if not session:
            raise ValueError(f"Session {self.session_id} not found")

        self.course_id = session.course_id
        logger.info(f"📚 Loaded session: course={self.course_id}")

    async def _send_first_alo(self, websocket: WebSocket):
        """Send the first ALO in the course schedule"""
        async with get_db_session() as db_session:
            # Load course schedule
            stmt = select(Course).where(Course.id == self.course_id)
            result = await db_session.execute(stmt)
            course = result.scalar_one()

            # Get first ALO from schedule
            schedule = course.schedule
            if not schedule:
                raise ValueError("Course has no schedule")

            first_day = schedule[0]
            first_session = first_day.get("session", {})
            alo_ids = first_session.get("alo_ids", [])

            if not alo_ids:
                raise ValueError("No ALOs in schedule")

            first_alo_id = UUID(alo_ids[0])
            self.current_alo_id = first_alo_id

            # Load ALO
            alo = await self._load_alo(db_session, first_alo_id)

            # Send to client
            await self._send_alo(websocket, alo)

    async def _send_alo(self, websocket: WebSocket, alo: ALO):
        """Send ALO to client"""
        alo_response = ALOResponse.from_orm(alo)
        message = ALOMessage(type="alo", alo=alo_response)

        await websocket.send_json(message.dict())
        logger.info(f"📤 Sent ALO: {alo.id} (type={alo.alo_type}, difficulty={alo.difficulty})")

    async def _process_signal(self, signal: SignalMessage) -> Optional[ALO]:
        """Process user signal and decide next ALO"""
        async with get_db_session() as db_session:
            # Record attempt
            await self._record_attempt(db_session, signal)

            # Use policy engine to decide next
            engine = PolicyEngine(db_session)
            decision = await engine.decide_next_alo(
                user_id=self.user_id,
                course_id=self.course_id,
                last_alo_id=signal.alo_id,
                correct=signal.correct,
                hints_used=signal.hints_used,
                latency_ms=signal.latency_ms,
            )

            logger.info(f"🎯 Policy decision: {decision.action} | reason: {decision.reason}")

            if decision.alo_id:
                self.current_alo_id = decision.alo_id
                return await self._load_alo(db_session, decision.alo_id)

            return None

    async def _record_attempt(self, db_session: AsyncSession, signal: SignalMessage):
        """Record user attempt"""
        attempt = Attempt(
            session_id=self.session_id,
            alo_id=signal.alo_id,
            event_time=datetime.now(timezone.utc),
            correct=signal.correct,
            latency_ms=signal.latency_ms,
            hints_used=signal.hints_used,
            payload=signal.payload,
        )
        db_session.add(attempt)
        await db_session.commit()

        logger.info(
            f"📝 Attempt recorded: ALO={signal.alo_id}, "
            f"correct={signal.correct}, latency={signal.latency_ms}ms, hints={signal.hints_used}"
        )

    async def _load_alo(self, db_session: AsyncSession, alo_id: UUID) -> ALO:
        """Load ALO from database"""
        stmt = select(ALO).where(ALO.id == alo_id)
        result = await db_session.execute(stmt)
        alo = result.scalar_one_or_none()

        if not alo:
            raise ValueError(f"ALO {alo_id} not found")

        return alo

    async def _send_end(self, websocket: WebSocket):
        """Send session end message"""
        async with get_db_session() as db_session:
            # Calculate summary
            stmt = select(Attempt).where(Attempt.session_id == self.session_id)
            result = await db_session.execute(stmt)
            attempts = result.scalars().all()

            total_attempts = len(attempts)
            correct_count = sum(1 for a in attempts if a.correct is True)
            accuracy = (correct_count / total_attempts * 100) if total_attempts > 0 else 0.0

            elapsed_time = datetime.now(timezone.utc) - self.start_time

            summary = {
                "total_attempts": total_attempts,
                "correct_count": correct_count,
                "accuracy_percent": round(accuracy, 1),
                "time_spent_min": int(elapsed_time.total_seconds() // 60),
            }

            message = SessionEndMessage(type="end", summary=summary)
            await websocket.send_json(message.dict())

            logger.info(f"🏁 Session ended: {self.session_id} | summary={summary}")

        await self._end_session()

    async def _end_session(self):
        """Mark session as ended"""
        async with get_db_session() as db_session:
            stmt = select(LearningSession).where(LearningSession.id == self.session_id)
            result = await db_session.execute(stmt)
            session = result.scalar_one_or_none()

            if session and session.status == "active":
                session.status = "ended"
                session.ended_at = datetime.now(timezone.utc)
                await db_session.commit()

                logger.info(f"✅ Session ended: {self.session_id}")


@router.websocket("/{session_id}/run")
async def run_session_websocket(
    websocket: WebSocket,
    session_id: UUID,
):
    """
    WebSocket endpoint for running a learning session.

    **Protocol:**

    1. **Server → Client** (`alo` message):
       ```json
       {
         "type": "alo",
         "alo": {
           "id": "...",
           "alo_type": "quiz",
           "content": {...},
           "assessment_spec": {...}
         }
       }
       ```

    2. **Client → Server** (`signal` message):
       ```json
       {
         "type": "signal",
         "alo_id": "...",
         "event": "answered",
         "correct": true,
         "latency_ms": 12450,
         "hints_used": 1,
         "payload": {}
       }
       ```

    3. **Server → Client** (`next` or `end` message):
       - If more ALOs: sends next `alo` message
       - If complete: sends `end` message with summary

    **Events:**
    - `answered`: User completed quiz/exercise
    - `completed`: User finished explain/example/project
    - `help_requested`: User asked for hint
    - `skipped`: User skipped (not recommended)

    **Policy:**
    - Correct + low hints + fast → advance
    - Wrong + many hints + slow → remediate (easier ALO)
    - Review due → insert review ALO
    """
    # Note: Authentication via query params or headers for WebSocket
    # For MVP, we extract user_id from session metadata
    # In production, use JWT token validation

    runner = SessionRunner(
        session_id=session_id,
        user_id=UUID("00000000-0000-0000-0000-000000000000"),  # TODO: Get from auth
    )

    await runner.run(websocket)
