# Seed Initial Data Script
import asyncio
from uuid import uuid4

from sqlalchemy import text

from src.core.database import async_engine, get_db_session
from src.profiles.models import Interest


async def seed_interests():
    """Seed initial interests for the platform"""
    
    interests_data = [
        # Technology
        {"name": "Python Programming", "category": "Technology", "description": "Learn Python programming language"},
        {"name": "Web Development", "category": "Technology", "description": "Frontend and backend web development"},
        {"name": "Mobile App Development", "category": "Technology", "description": "iOS and Android development"},
        {"name": "Data Science", "category": "Technology", "description": "Data analysis, machine learning, AI"},
        {"name": "Cybersecurity", "category": "Technology", "description": "Information security and ethical hacking"},
        {"name": "Cloud Computing", "category": "Technology", "description": "AWS, GCP, Azure cloud platforms"},
        
        # Mathematics
        {"name": "Algebra", "category": "Mathematics", "description": "Elementary and advanced algebra"},
        {"name": "Calculus", "category": "Mathematics", "description": "Differential and integral calculus"},
        {"name": "Statistics", "category": "Mathematics", "description": "Probability and statistical analysis"},
        {"name": "Geometry", "category": "Mathematics", "description": "Plane and solid geometry"},
        
        # Science
        {"name": "Physics", "category": "Science", "description": "Classical and modern physics"},
        {"name": "Chemistry", "category": "Science", "description": "Organic and inorganic chemistry"},
        {"name": "Biology", "category": "Science", "description": "Life sciences and biology"},
        {"name": "Environmental Science", "category": "Science", "description": "Ecology and environmental studies"},
        
        # Languages
        {"name": "Spanish", "category": "Languages", "description": "Spanish language learning"},
        {"name": "French", "category": "Languages", "description": "French language learning"},
        {"name": "Mandarin", "category": "Languages", "description": "Chinese Mandarin language"},
        {"name": "Japanese", "category": "Languages", "description": "Japanese language and culture"},
        {"name": "English", "category": "Languages", "description": "English grammar and literature"},
        
        # Business
        {"name": "Entrepreneurship", "category": "Business", "description": "Starting and running a business"},
        {"name": "Marketing", "category": "Business", "description": "Digital and traditional marketing"},
        {"name": "Finance", "category": "Business", "description": "Personal and corporate finance"},
        {"name": "Project Management", "category": "Business", "description": "Project planning and execution"},
        
        # Arts & Creativity
        {"name": "Digital Art", "category": "Arts", "description": "Digital illustration and design"},
        {"name": "Photography", "category": "Arts", "description": "Digital photography techniques"},
        {"name": "Music Production", "category": "Arts", "description": "Audio production and music creation"},
        {"name": "Creative Writing", "category": "Arts", "description": "Fiction and non-fiction writing"},
        {"name": "Graphic Design", "category": "Arts", "description": "Visual design and branding"},
        
        # Health & Fitness
        {"name": "Nutrition", "category": "Health", "description": "Healthy eating and nutrition science"},
        {"name": "Fitness Training", "category": "Health", "description": "Exercise and physical fitness"},
        {"name": "Mental Health", "category": "Health", "description": "Psychology and mental wellness"},
        {"name": "Yoga", "category": "Health", "description": "Yoga practice and philosophy"},
        
        # Personal Development
        {"name": "Study Skills", "category": "Personal Development", "description": "Effective learning techniques"},
        {"name": "Time Management", "category": "Personal Development", "description": "Productivity and time optimization"},
        {"name": "Public Speaking", "category": "Personal Development", "description": "Communication and presentation skills"},
        {"name": "Leadership", "category": "Personal Development", "description": "Leadership principles and practice"},
    ]
    
    async with async_engine.begin() as conn:
        # Check if interests already exist
        result = await conn.execute(text("SELECT COUNT(*) FROM interests"))
        count = result.scalar()
        
        if count > 0:
            print(f"Interests already exist ({count} records). Skipping seed.")
            return
        
        # Insert interests
        for interest_data in interests_data:
            interest_id = uuid4()
            await conn.execute(
                text("""
                    INSERT INTO interests (id, name, category, description, is_active, created_at)
                    VALUES (:id, :name, :category, :description, :is_active, NOW())
                """),
                {
                    "id": interest_id,
                    "name": interest_data["name"],
                    "category": interest_data["category"],
                    "description": interest_data["description"],
                    "is_active": True
                }
            )
        
        print(f"Successfully seeded {len(interests_data)} interests")


async def main():
    """Main function to run seed scripts"""
    print("Starting database seeding...")
    
    try:
        await seed_interests()
        print("Database seeding completed successfully!")
        
    except Exception as e:
        print(f"Error during seeding: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
