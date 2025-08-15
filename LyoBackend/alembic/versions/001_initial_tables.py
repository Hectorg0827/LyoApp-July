# Create database tables migration
"""Create initial tables

Revision ID: 001_initial_tables
Revises: 
Create Date: 2024-01-20 10:00:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers
revision = '001_initial_tables'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create users table
    op.create_table('users',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('hashed_password', sa.String(length=255), nullable=True),
        sa.Column('first_name', sa.String(length=100), nullable=True),
        sa.Column('last_name', sa.String(length=100), nullable=True),
        sa.Column('display_name', sa.String(length=200), nullable=True),
        sa.Column('role', sa.String(length=20), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('is_verified', sa.Boolean(), nullable=False),
        sa.Column('email_verification_token', sa.String(length=255), nullable=True),
        sa.Column('password_reset_token', sa.String(length=255), nullable=True),
        sa.Column('password_reset_expires', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('last_login', sa.DateTime(timezone=True), nullable=True),
        sa.Column('apple_user_id', sa.String(length=255), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_users_apple_user_id'), 'users', ['apple_user_id'], unique=True)
    op.create_index(op.f('ix_users_email'), 'users', ['email'], unique=True)

    # Create refresh tokens table
    op.create_table('refresh_tokens',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('token_hash', sa.String(length=255), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('is_revoked', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_refresh_tokens_token_hash'), 'refresh_tokens', ['token_hash'], unique=True)

    # Create login attempts table
    op.create_table('login_attempts',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('email', sa.String(length=255), nullable=False),
        sa.Column('ip_address', sa.String(length=45), nullable=True),
        sa.Column('user_agent', sa.String(length=500), nullable=True),
        sa.Column('success', sa.Boolean(), nullable=False),
        sa.Column('failure_reason', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )

    # Create interests table
    op.create_table('interests',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('category', sa.String(length=50), nullable=True),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('icon_url', sa.String(length=255), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_interests_category'), 'interests', ['category'], unique=False)
    op.create_index(op.f('ix_interests_name'), 'interests', ['name'], unique=True)

    # Create user profiles table
    op.create_table('user_profiles',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('username', sa.String(length=50), nullable=True),
        sa.Column('bio', sa.Text(), nullable=True),
        sa.Column('location', sa.String(length=100), nullable=True),
        sa.Column('website', sa.String(length=255), nullable=True),
        sa.Column('avatar_url', sa.String(length=255), nullable=True),
        sa.Column('cover_url', sa.String(length=255), nullable=True),
        sa.Column('followers_count', sa.Integer(), nullable=False),
        sa.Column('following_count', sa.Integer(), nullable=False),
        sa.Column('posts_count', sa.Integer(), nullable=False),
        sa.Column('is_private', sa.Boolean(), nullable=False),
        sa.Column('allow_messages', sa.Boolean(), nullable=False),
        sa.Column('show_activity', sa.Boolean(), nullable=False),
        sa.Column('learning_style', sa.String(length=20), nullable=True),
        sa.Column('difficulty_preference', sa.String(length=20), nullable=False),
        sa.Column('level', sa.Integer(), nullable=False),
        sa.Column('xp_points', sa.Integer(), nullable=False),
        sa.Column('streak_days', sa.Integer(), nullable=False),
        sa.Column('last_activity', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_user_profiles_user_id'), 'user_profiles', ['user_id'], unique=True)
    op.create_index(op.f('ix_user_profiles_username'), 'user_profiles', ['username'], unique=True)

    # Create follows table
    op.create_table('follows',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('follower_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('following_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('is_approved', sa.Boolean(), nullable=False),
        sa.Column('requested_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('approved_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['follower_id'], ['users.id'], ),
        sa.ForeignKeyConstraint(['following_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('follower_id', 'following_id', name='_follower_following_uc')
    )

    # Create user interests table
    op.create_table('user_interests',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('interest_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('proficiency_level', sa.String(length=20), nullable=False),
        sa.Column('is_learning', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['interest_id'], ['interests.id'], ),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('user_id', 'interest_id', name='_user_interest_uc')
    )

    # Create media uploads table
    op.create_table('media_uploads',
        sa.Column('id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('filename', sa.String(length=255), nullable=False),
        sa.Column('original_filename', sa.String(length=255), nullable=False),
        sa.Column('content_type', sa.String(length=100), nullable=False),
        sa.Column('file_size', sa.String(length=20), nullable=False),
        sa.Column('media_type', sa.String(length=20), nullable=False),
        sa.Column('usage_type', sa.String(length=50), nullable=False),
        sa.Column('storage_path', sa.String(length=500), nullable=False),
        sa.Column('public_url', sa.String(length=500), nullable=True),
        sa.Column('thumbnail_url', sa.String(length=500), nullable=True),
        sa.Column('metadata', sa.Text(), nullable=True),
        sa.Column('alt_text', sa.String(length=255), nullable=True),
        sa.Column('is_processed', sa.Boolean(), nullable=False),
        sa.Column('is_public', sa.Boolean(), nullable=False),
        sa.Column('is_active', sa.Boolean(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ),
        sa.PrimaryKeyConstraint('id')
    )


def downgrade() -> None:
    op.drop_table('media_uploads')
    op.drop_table('user_interests')
    op.drop_table('follows')
    op.drop_index(op.f('ix_user_profiles_username'), table_name='user_profiles')
    op.drop_index(op.f('ix_user_profiles_user_id'), table_name='user_profiles')
    op.drop_table('user_profiles')
    op.drop_index(op.f('ix_interests_name'), table_name='interests')
    op.drop_index(op.f('ix_interests_category'), table_name='interests')
    op.drop_table('interests')
    op.drop_table('login_attempts')
    op.drop_index(op.f('ix_refresh_tokens_token_hash'), table_name='refresh_tokens')
    op.drop_table('refresh_tokens')
    op.drop_index(op.f('ix_users_email'), table_name='users')
    op.drop_index(op.f('ix_users_apple_user_id'), table_name='users')
    op.drop_table('users')
