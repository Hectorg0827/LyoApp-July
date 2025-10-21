"""Create learning system tables

Revision ID: 002_learning_system
Revises: 001_initial_tables
Create Date: 2025-01-12 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '002_learning_system'
down_revision = '001_initial_tables'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create knowledge_components table
    op.create_table('knowledge_components',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('slug', sa.String(length=200), nullable=False),
        sa.Column('title', sa.String(length=255), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=False, server_default='{}'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_knowledge_components_slug'), 'knowledge_components', ['slug'], unique=True)
    op.create_index('ix_knowledge_components_tags', 'knowledge_components', ['tags'], unique=False, postgresql_using='gin')

    # Create learning_objectives table
    op.create_table('learning_objectives',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('kc_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('verb', sa.String(length=50), nullable=False),
        sa.Column('context', sa.Text(), nullable=True),
        sa.Column('difficulty', sa.SmallInteger(), nullable=False, server_default='0'),
        sa.Column('rubric', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['kc_id'], ['knowledge_components.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_learning_objectives_kc_id'), 'learning_objectives', ['kc_id'], unique=False)
    op.create_index('ix_learning_objectives_rubric', 'learning_objectives', ['rubric'], unique=False, postgresql_using='gin')

    # Create alos (Atomic Learning Objects) table
    op.create_table('alos',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('lo_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('alo_type', sa.String(length=50), nullable=False),
        sa.Column('est_time_sec', sa.Integer(), nullable=False),
        sa.Column('content', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('assessment_spec', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('difficulty', sa.SmallInteger(), nullable=False, server_default='0'),
        sa.Column('tags', postgresql.ARRAY(sa.String()), nullable=False, server_default='{}'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['lo_id'], ['learning_objectives.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_alos_lo_id'), 'alos', ['lo_id'], unique=False)
    op.create_index(op.f('ix_alos_alo_type'), 'alos', ['alo_type'], unique=False)
    op.create_index('ix_alos_content', 'alos', ['content'], unique=False, postgresql_using='gin')
    op.create_index('ix_alos_tags', 'alos', ['tags'], unique=False, postgresql_using='gin')

    # Create prerequisites table
    op.create_table('prerequisites',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('kc_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('prereq_kc_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['kc_id'], ['knowledge_components.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['prereq_kc_id'], ['knowledge_components.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('kc_id', 'prereq_kc_id', name='_kc_prereq_uc')
    )
    op.create_index(op.f('ix_prerequisites_kc_id'), 'prerequisites', ['kc_id'], unique=False)
    op.create_index(op.f('ix_prerequisites_prereq_kc_id'), 'prerequisites', ['prereq_kc_id'], unique=False)

    # Create courses table
    op.create_table('courses',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('goal', sa.Text(), nullable=False),
        sa.Column('skill_graph', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('schedule', postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_courses_user_id'), 'courses', ['user_id'], unique=False)
    op.create_index(op.f('ix_courses_status'), 'courses', ['status'], unique=False)

    # Create sessions table
    op.create_table('sessions',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('course_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('ended_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(length=20), nullable=False, server_default='active'),
        sa.Column('metadata', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.ForeignKeyConstraint(['course_id'], ['courses.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_sessions_course_id'), 'sessions', ['course_id'], unique=False)
    op.create_index(op.f('ix_sessions_status'), 'sessions', ['status'], unique=False)

    # Create attempts table
    op.create_table('attempts',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('session_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('alo_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('event_time', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('correct', sa.Boolean(), nullable=True),
        sa.Column('latency_ms', sa.Integer(), nullable=True),
        sa.Column('hints_used', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('payload', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.ForeignKeyConstraint(['session_id'], ['sessions.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['alo_id'], ['alos.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_attempts_session_id'), 'attempts', ['session_id'], unique=False)
    op.create_index(op.f('ix_attempts_alo_id'), 'attempts', ['alo_id'], unique=False)
    op.create_index(op.f('ix_attempts_event_time'), 'attempts', ['event_time'], unique=False)

    # Create mastery_estimates table
    op.create_table('mastery_estimates',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('kc_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('theta', sa.Numeric(precision=4, scale=3), nullable=False, server_default='0.500'),
        sa.Column('attempts_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('correct_count', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['kc_id'], ['knowledge_components.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'kc_id', name='_user_kc_uc')
    )
    op.create_index(op.f('ix_mastery_estimates_user_id'), 'mastery_estimates', ['user_id'], unique=False)
    op.create_index(op.f('ix_mastery_estimates_kc_id'), 'mastery_estimates', ['kc_id'], unique=False)

    # Create review_queue table
    op.create_table('review_queue',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('alo_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('next_due', sa.DateTime(timezone=True), nullable=False),
        sa.Column('interval_days', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('easiness', sa.Numeric(precision=3, scale=2), nullable=False, server_default='2.50'),
        sa.Column('reps', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['alo_id'], ['alos.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'alo_id', name='_user_alo_uc')
    )
    op.create_index(op.f('ix_review_queue_user_id'), 'review_queue', ['user_id'], unique=False)
    op.create_index(op.f('ix_review_queue_alo_id'), 'review_queue', ['alo_id'], unique=False)
    op.create_index(op.f('ix_review_queue_next_due'), 'review_queue', ['next_due'], unique=False)


def downgrade() -> None:
    op.drop_table('review_queue')
    op.drop_table('mastery_estimates')
    op.drop_table('attempts')
    op.drop_table('sessions')
    op.drop_table('courses')
    op.drop_table('prerequisites')
    op.drop_table('alos')
    op.drop_table('learning_objectives')
    op.drop_table('knowledge_components')
