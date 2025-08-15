#!/usr/bin/env python3
"""
Database seeding script for development and testing
"""
import asyncio
import sys
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent.parent))

from src.auth.models import User
from src.auth.service import auth_service
from src.core.database import get_db_session, init_db
from src.core.logging import get_structured_logger, setup_logging
from src.core.redis import init_redis

setup_logging()
logger = get_structured_logger(__name__)


async def create_demo_users():
    """Create demo users for development"""
    async with get_db_session() as session:
        demo_users = [
            {
                "email": "student@lyoapp.com",
                "password": "student123",
                "first_name": "Demo",
                "last_name": "Student",
                "role": "student",
            },
            {
                "email": "teacher@lyoapp.com", 
                "password": "teacher123",
                "first_name": "Demo",
                "last_name": "Teacher",
                "role": "teacher",
            },
            {
                "email": "guardian@lyoapp.com",
                "password": "guardian123", 
                "first_name": "Demo",
                "last_name": "Guardian",
                "role": "guardian",
            },
            {
                "email": "admin@lyoapp.com",
                "password": "admin123",
                "first_name": "Demo", 
                "last_name": "Admin",
                "role": "admin",
            }
        ]
        
        for user_data in demo_users:
            # Check if user already exists
            from sqlalchemy import select
            existing = await session.execute(
                select(User).where(User.email == user_data["email"])
            )
            if existing.scalar_one_or_none():
                logger.info(f"User {user_data['email']} already exists, skipping...")
                continue
            
            # Create user
            user = User(
                email=user_data["email"],
                hashed_password=auth_service.hash_password(user_data["password"]),
                first_name=user_data["first_name"],
                last_name=user_data["last_name"],
                display_name=f"{user_data['first_name']} {user_data['last_name']}",
                role=user_data["role"],
                is_verified=True,
            )
            
            session.add(user)
            logger.info(f"Created demo user: {user_data['email']} ({user_data['role']})")
        
        await session.commit()


async def main():
    """Main seeding function"""
    logger.info("Starting database seeding...")
    
    try:
        # Initialize services
        await init_db()
        await init_redis()
        
        # Create demo data
        await create_demo_users()
        
        logger.info("✅ Database seeding completed successfully!")
        logger.info("Demo accounts created:")
        logger.info("  Student: student@lyoapp.com / student123")
        logger.info("  Teacher: teacher@lyoapp.com / teacher123")
        logger.info("  Guardian: guardian@lyoapp.com / guardian123")
        logger.info("  Admin: admin@lyoapp.com / admin123")
        
    except Exception as e:
        logger.error(f"❌ Database seeding failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
