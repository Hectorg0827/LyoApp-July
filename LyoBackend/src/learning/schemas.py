"""Pydantic schemas for the learning system API"""
from datetime import datetime
from enum import Enum
from typing import Any, Dict, List, Optional, Union
from uuid import UUID

from pydantic import BaseModel, Field, field_validator


# ============================================================================
# Enums
# ============================================================================

class ALOType(str, Enum):
    """Types of Atomic Learning Objects"""
    EXPLAIN = "explain"
    EXAMPLE = "example"
    EXERCISE = "exercise"
    QUIZ = "quiz"
    PROJECT = "project"


class SessionStatus(str, Enum):
    """Session status"""
    ACTIVE = "active"
    ENDED = "ended"


class CourseStatus(str, Enum):
    """Course status"""
    ACTIVE = "active"
    COMPLETED = "completed"
    PAUSED = "paused"


# ============================================================================
# ALO Content Schemas (type-specific)
# ============================================================================

class ExplainContent(BaseModel):
    """Content for explain-type ALO"""
    markdown: str = Field(..., description="Markdown explanation content")
    asset_urls: Optional[List[str]] = Field(default_factory=list, description="Optional media assets")


class ExampleContent(BaseModel):
    """Content for example-type ALO"""
    markdown: str = Field(..., description="Example description")
    code: Optional[str] = Field(None, description="Code example")
    language: Optional[str] = Field(None, description="Programming language")
    asset_urls: Optional[List[str]] = Field(default_factory=list)


class ExerciseContent(BaseModel):
    """Content for exercise-type ALO"""
    prompt: str = Field(..., description="Exercise prompt")
    starter_code: Optional[str] = Field(None, description="Starter code template")
    language: Optional[str] = Field(None, description="Programming language")
    inputs: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Test inputs")
    hints: Optional[List[str]] = Field(default_factory=list, description="Progressive hints")


class QuizContent(BaseModel):
    """Content for quiz-type ALO"""
    question: str = Field(..., description="Quiz question")
    choices: List[str] = Field(..., min_length=2, description="Answer choices")
    answer_index: int = Field(..., ge=0, description="Index of correct answer")
    explanation: Optional[str] = Field(None, description="Explanation of correct answer")


class ProjectContent(BaseModel):
    """Content for project-type ALO"""
    brief: str = Field(..., description="Project brief/description")
    acceptance_tests: List[str] = Field(..., min_length=1, description="Acceptance criteria")
    rubric: Dict[str, Any] = Field(..., description="Detailed rubric")
    starter_files: Optional[Dict[str, str]] = Field(default_factory=dict, description="Starter file templates")
    resources: Optional[List[str]] = Field(default_factory=list, description="Resource links")


# ============================================================================
# Base Schemas
# ============================================================================

class KnowledgeComponentBase(BaseModel):
    """Base KC schema"""
    slug: str = Field(..., min_length=1, max_length=200)
    title: str = Field(..., min_length=1, max_length=255)
    description: Optional[str] = None
    tags: List[str] = Field(default_factory=list)


class KnowledgeComponentResponse(KnowledgeComponentBase):
    """KC response schema"""
    id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class LearningObjectiveBase(BaseModel):
    """Base LO schema"""
    verb: str = Field(..., min_length=1, max_length=50)
    context: Optional[str] = None
    difficulty: int = Field(0, ge=-2, le=2)
    rubric: Dict[str, Any]


class LearningObjectiveResponse(LearningObjectiveBase):
    """LO response schema"""
    id: UUID
    kc_id: UUID
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class ALOBase(BaseModel):
    """Base ALO schema"""
    alo_type: ALOType
    est_time_sec: int = Field(..., gt=0)
    content: Union[ExplainContent, ExampleContent, ExerciseContent, QuizContent, ProjectContent]
    assessment_spec: Optional[Dict[str, Any]] = None
    difficulty: int = Field(0, ge=-2, le=2)
    tags: List[str] = Field(default_factory=list)


class ALOResponse(BaseModel):
    """ALO response schema"""
    id: UUID
    lo_id: UUID
    alo_type: str
    est_time_sec: int
    content: Dict[str, Any]
    assessment_spec: Optional[Dict[str, Any]]
    difficulty: int
    tags: List[str]
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ============================================================================
# Course Compilation Schemas
# ============================================================================

class CompileCourseRequest(BaseModel):
    """Request to compile a course"""
    goal: str = Field(..., min_length=10, max_length=500, description="Learning goal")
    time_budget_min_per_day: int = Field(20, ge=5, le=180, description="Daily time budget in minutes")
    deadline_iso: Optional[str] = Field(None, description="Target completion date (ISO format)")
    prior_knowledge_ids: List[str] = Field(default_factory=list, description="Known KC slugs")


class SkillGraphNode(BaseModel):
    """Node in skill graph"""
    kc_id: UUID
    kc_slug: str
    kc_title: str
    prerequisite_ids: List[UUID]
    lo_ids: List[UUID]


class SkillGraphResponse(BaseModel):
    """Compiled skill graph"""
    kcs: List[KnowledgeComponentResponse]
    edges: List[Dict[str, UUID]]  # List of {from: kc_id, to: kc_id}
    los: List[LearningObjectiveResponse]
    alos: List[ALOResponse]


class SessionScheduleItem(BaseModel):
    """Single session in schedule"""
    day: int
    session: Dict[str, List[UUID]]  # {alo_ids: [...]}


class CompileCourseResponse(BaseModel):
    """Response from course compilation"""
    course_id: UUID
    skill_graph: SkillGraphResponse
    schedule: List[SessionScheduleItem]
    estimated_total_time_min: int


# ============================================================================
# Progress Schemas
# ============================================================================

class MasteryEstimateResponse(BaseModel):
    """Mastery estimate for a KC"""
    kc_id: UUID
    kc_slug: str
    theta: float = Field(..., ge=0, le=1)
    attempts_count: int
    correct_count: int
    updated_at: datetime


class ReviewQueueItemResponse(BaseModel):
    """Review queue item"""
    alo_id: UUID
    next_due: datetime
    interval_days: int
    reps: int


class ProgressResponse(BaseModel):
    """User progress response"""
    theta_by_kc: Dict[str, float]  # {kc_slug: theta}
    streak: int
    review_queue: List[ReviewQueueItemResponse]


# ============================================================================
# Evidence Submission Schemas
# ============================================================================

class ArtifactInput(BaseModel):
    """Input artifact for evidence submission"""
    type: str = Field(..., description="Artifact type: text|code|file")
    value: str = Field(..., description="Artifact value")
    metadata: Optional[Dict[str, Any]] = Field(default_factory=dict)


class CheckResult(BaseModel):
    """Result of an evidence check"""
    name: str = Field(..., description="Check name")
    passed: bool
    message: Optional[str] = None


class SubmitEvidenceRequest(BaseModel):
    """Request to submit evidence"""
    alo_id: UUID
    artifacts: List[ArtifactInput]
    checks: List[CheckResult]


class SubmitEvidenceResponse(BaseModel):
    """Response from evidence submission"""
    passed: bool
    feedback: str
    theta_updated: Optional[Dict[str, float]] = None  # {kc_id: new_theta}


# ============================================================================
# WebSocket Session Schemas
# ============================================================================

class ALOMessage(BaseModel):
    """Server → Client: ALO to render"""
    type: str = Field("alo", const=True)
    alo: ALOResponse


class SignalMessage(BaseModel):
    """Client → Server: user signal"""
    type: str = Field("signal", const=True)
    alo_id: UUID
    event: str = Field(..., description="Event type: answered|completed|skipped|help_requested")
    correct: Optional[bool] = None
    latency_ms: Optional[int] = None
    hints_used: int = Field(0, ge=0)
    payload: Optional[Dict[str, Any]] = Field(default_factory=dict)


class NextMessage(BaseModel):
    """Server → Client: next ALO"""
    type: str = Field("next", const=True)
    alo: Optional[ALOResponse] = None
    reason: Optional[str] = None  # "advance"|"remediate"|"review"|"complete"


class SessionEndMessage(BaseModel):
    """Server → Client: session complete"""
    type: str = Field("end", const=True)
    summary: Dict[str, Any]


# ============================================================================
# Session Management Schemas
# ============================================================================

class CreateSessionRequest(BaseModel):
    """Request to create a session"""
    course_id: UUID


class CreateSessionResponse(BaseModel):
    """Response from session creation"""
    session_id: UUID
    course_id: UUID
    started_at: datetime
    status: SessionStatus


# ============================================================================
# Internal Service Schemas
# ============================================================================

class PolicyDecision(BaseModel):
    """Policy decision for next ALO"""
    action: str = Field(..., description="advance|remediate|review")
    alo_id: Optional[UUID] = None
    reason: str
    theta_updates: Dict[UUID, float] = Field(default_factory=dict)  # {kc_id: new_theta}


class ThetaUpdate(BaseModel):
    """Theta update input"""
    user_id: UUID
    kc_id: UUID
    correct: bool
    difficulty: int
