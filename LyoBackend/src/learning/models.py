"""SQLAlchemy models for the learning system"""
import uuid
from datetime import datetime, timezone
from typing import List, Optional

import sqlalchemy as sa
from sqlalchemy import ARRAY, String, Text, SmallInteger, Integer, Numeric, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from src.core.database import Base


class KnowledgeComponent(Base):
    """Knowledge Component (KC) - a unit of knowledge in the skill graph"""
    __tablename__ = "knowledge_components"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    slug: Mapped[str] = mapped_column(String(200), nullable=False, unique=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    tags: Mapped[List[str]] = mapped_column(ARRAY(String), nullable=False, server_default="{}")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    learning_objectives: Mapped[List["LearningObjective"]] = relationship(
        "LearningObjective", back_populates="knowledge_component", cascade="all, delete-orphan"
    )
    prerequisites: Mapped[List["Prerequisite"]] = relationship(
        "Prerequisite", foreign_keys="[Prerequisite.kc_id]", back_populates="kc", cascade="all, delete-orphan"
    )
    required_by: Mapped[List["Prerequisite"]] = relationship(
        "Prerequisite", foreign_keys="[Prerequisite.prereq_kc_id]", back_populates="prereq_kc"
    )
    mastery_estimates: Mapped[List["MasteryEstimate"]] = relationship(
        "MasteryEstimate", back_populates="knowledge_component", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<KnowledgeComponent(slug='{self.slug}', title='{self.title}')>"


class LearningObjective(Base):
    """Learning Objective (LO) - a specific learning goal within a KC"""
    __tablename__ = "learning_objectives"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    kc_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("knowledge_components.id", ondelete="CASCADE"), nullable=False, index=True)
    verb: Mapped[str] = mapped_column(String(50), nullable=False)  # e.g., "explain", "apply", "analyze"
    context: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    difficulty: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default="0")  # -2 to +2
    rubric: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Evidence contract schema
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    knowledge_component: Mapped["KnowledgeComponent"] = relationship("KnowledgeComponent", back_populates="learning_objectives")
    alos: Mapped[List["ALO"]] = relationship("ALO", back_populates="learning_objective", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<LearningObjective(verb='{self.verb}', context='{self.context}', difficulty={self.difficulty})>"


class ALO(Base):
    """Atomic Learning Object (ALO) - smallest unit of learning content"""
    __tablename__ = "alos"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    lo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("learning_objectives.id", ondelete="CASCADE"), nullable=False, index=True)
    alo_type: Mapped[str] = mapped_column(String(50), nullable=False, index=True)  # explain|example|exercise|quiz|project
    est_time_sec: Mapped[int] = mapped_column(Integer, nullable=False)
    content: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Type-specific payload
    assessment_spec: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)  # Auto-checks/unit tests/answer key
    difficulty: Mapped[int] = mapped_column(SmallInteger, nullable=False, server_default="0")
    tags: Mapped[List[str]] = mapped_column(ARRAY(String), nullable=False, server_default="{}")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    learning_objective: Mapped["LearningObjective"] = relationship("LearningObjective", back_populates="alos")
    attempts: Mapped[List["Attempt"]] = relationship("Attempt", back_populates="alo", cascade="all, delete-orphan")
    review_items: Mapped[List["ReviewQueue"]] = relationship("ReviewQueue", back_populates="alo", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<ALO(type='{self.alo_type}', difficulty={self.difficulty}, est_time={self.est_time_sec}s)>"


class Prerequisite(Base):
    """Prerequisite relationship between Knowledge Components"""
    __tablename__ = "prerequisites"
    __table_args__ = (
        sa.UniqueConstraint("kc_id", "prereq_kc_id", name="_kc_prereq_uc"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    kc_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("knowledge_components.id", ondelete="CASCADE"), nullable=False, index=True)
    prereq_kc_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("knowledge_components.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    kc: Mapped["KnowledgeComponent"] = relationship("KnowledgeComponent", foreign_keys=[kc_id], back_populates="prerequisites")
    prereq_kc: Mapped["KnowledgeComponent"] = relationship("KnowledgeComponent", foreign_keys=[prereq_kc_id], back_populates="required_by")

    def __repr__(self) -> str:
        return f"<Prerequisite(kc_id={self.kc_id}, prereq={self.prereq_kc_id})>"


class Course(Base):
    """Compiled course with frozen skill graph and schedule"""
    __tablename__ = "courses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    goal: Mapped[str] = mapped_column(Text, nullable=False)
    skill_graph: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Frozen compile output
    schedule: Mapped[dict] = mapped_column(JSONB, nullable=False)  # Session schedule
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default="active", index=True)  # active|completed|paused
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    sessions: Mapped[List["Session"]] = relationship("Session", back_populates="course", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Course(id={self.id}, goal='{self.goal[:50]}...', status='{self.status}')>"


class Session(Base):
    """Learning session for running ALOs"""
    __tablename__ = "sessions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id", ondelete="CASCADE"), nullable=False, index=True)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default="active", index=True)  # active|ended
    metadata: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)

    # Relationships
    course: Mapped["Course"] = relationship("Course", back_populates="sessions")
    attempts: Mapped[List["Attempt"]] = relationship("Attempt", back_populates="session", cascade="all, delete-orphan")

    def __repr__(self) -> str:
        return f"<Session(id={self.id}, status='{self.status}')>"


class Attempt(Base):
    """User attempt on an ALO with telemetry"""
    __tablename__ = "attempts"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("sessions.id", ondelete="CASCADE"), nullable=False, index=True)
    alo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("alos.id", ondelete="CASCADE"), nullable=False, index=True)
    event_time: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"), index=True)
    correct: Mapped[Optional[bool]] = mapped_column(Boolean, nullable=True)
    latency_ms: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    hints_used: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    payload: Mapped[Optional[dict]] = mapped_column(JSONB, nullable=True)  # Raw client signal

    # Relationships
    session: Mapped["Session"] = relationship("Session", back_populates="attempts")
    alo: Mapped["ALO"] = relationship("ALO", back_populates="attempts")

    def __repr__(self) -> str:
        return f"<Attempt(alo_id={self.alo_id}, correct={self.correct}, latency={self.latency_ms}ms, hints={self.hints_used})>"


class MasteryEstimate(Base):
    """Per-user, per-KC mastery level (theta)"""
    __tablename__ = "mastery_estimates"
    __table_args__ = (
        sa.UniqueConstraint("user_id", "kc_id", name="_user_kc_uc"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    kc_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("knowledge_components.id", ondelete="CASCADE"), nullable=False, index=True)
    theta: Mapped[float] = mapped_column(Numeric(precision=4, scale=3), nullable=False, server_default="0.500")  # 0.000 to 1.000
    attempts_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    correct_count: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    knowledge_component: Mapped["KnowledgeComponent"] = relationship("KnowledgeComponent", back_populates="mastery_estimates")

    def __repr__(self) -> str:
        return f"<MasteryEstimate(user_id={self.user_id}, kc_id={self.kc_id}, theta={self.theta:.3f})>"


class ReviewQueue(Base):
    """Spaced repetition review queue using SM-2 algorithm"""
    __tablename__ = "review_queue"
    __table_args__ = (
        sa.UniqueConstraint("user_id", "alo_id", name="_user_alo_uc"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()"))
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    alo_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("alos.id", ondelete="CASCADE"), nullable=False, index=True)
    next_due: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    interval_days: Mapped[int] = mapped_column(Integer, nullable=False, server_default="1")
    easiness: Mapped[float] = mapped_column(Numeric(precision=3, scale=2), nullable=False, server_default="2.50")  # SM-2 easiness factor
    reps: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=sa.text("now()"))

    # Relationships
    alo: Mapped["ALO"] = relationship("ALO", back_populates="review_items")

    def __repr__(self) -> str:
        return f"<ReviewQueue(user_id={self.user_id}, alo_id={self.alo_id}, next_due={self.next_due}, interval={self.interval_days}d)>"
