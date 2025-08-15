# Test Configuration
import asyncio
import os
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy import event
from sqlalchemy.pool import StaticPool

from src.core.database import Base, get_db
from src.main import app

# Test database URL
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Test engine with in-memory SQLite
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    echo=False,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False},
)

# Test session factory
test_session_factory = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def get_test_db():
    """Override database dependency for tests"""
    async with test_session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def setup_database():
    """Setup test database"""
    # Create tables
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield
    
    # Drop tables
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db_session(setup_database):
    """Get database session for tests"""
    async with test_session_factory() as session:
        yield session


@pytest_asyncio.fixture
async def client(setup_database):
    """Get test client"""
    # Override database dependency
    app.dependency_overrides[get_db] = get_test_db
    
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
    
    # Clean up
    app.dependency_overrides.clear()


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for session scope"""
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()
