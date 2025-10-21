# Database Configuration and Connection Management
import logging
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Optional

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.pool import NullPool
from sqlalchemy import MetaData

from .config import get_settings

logger = logging.getLogger(__name__)

# Base class for all SQLAlchemy models
Base = declarative_base(
    metadata=MetaData(
        naming_convention={
            "ix": "ix_%(column_0_label)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
            "pk": "pk_%(table_name)s",
        }
    )
)

# Global variables for database connection
engine: Optional[sa.ext.asyncio.AsyncEngine] = None
async_session_maker: Optional[async_sessionmaker[AsyncSession]] = None


async def init_db() -> None:
    """Initialize database connection and session factory"""
    global engine, async_session_maker
    
    settings = get_settings()
    
    # Create async engine
    engine = create_async_engine(
        settings.database_url,
        pool_size=settings.db_pool_size,
        max_overflow=settings.db_max_overflow,
        pool_pre_ping=True,
        echo=settings.debug,
        # Use NullPool for Cloud SQL Connector
        poolclass=NullPool if "cloud-sql-proxy" in settings.database_url else None,
    )
    
    # Create session factory
    async_session_maker = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False,
    )
    
    logger.info("Database initialized successfully")


async def close_db() -> None:
    """Close database connections"""
    global engine
    
    if engine:
        await engine.dispose()
        logger.info("Database connections closed")


@asynccontextmanager
async def get_db_session() -> AsyncGenerator[AsyncSession, None]:
    """Get database session with automatic cleanup"""
    if not async_session_maker:
        raise RuntimeError("Database not initialized. Call init_db() first.")
    
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency to get database session"""
    async with get_db_session() as session:
        yield session


# Health check function
async def check_db_health() -> bool:
    """Check database connectivity"""
    try:
        if not engine:
            return False
        
        async with engine.begin() as conn:
            await conn.execute(sa.text("SELECT 1"))
        return True
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        return False


# Transaction decorator
def transactional(func):
    """Decorator to wrap function in database transaction"""
    async def wrapper(*args, **kwargs):
        async with get_db_session() as session:
            kwargs['session'] = session
            return await func(*args, **kwargs)
    
    return wrapper
