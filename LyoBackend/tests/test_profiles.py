# Test Profile Module
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.models import User
from src.profiles.models import Interest, UserProfile
from tests.conftest import TestData


@pytest.mark.asyncio
class TestProfileRoutes:
    """Test profile API routes"""

    async def test_get_my_profile_creates_default(
        self, client: AsyncClient, authenticated_user: TestData
    ):
        """Test getting current user profile creates default if none exists"""
        response = await client.get("/api/v1/profiles/me")
        
        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == str(authenticated_user.user.id)
        assert data["difficulty_preference"] == "intermediate"
        assert data["level"] == 1
        assert data["xp_points"] == 0

    async def test_update_profile(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test updating user profile"""
        update_data = {
            "username": "testuser123",
            "bio": "Hello, I'm a test user!",
            "location": "San Francisco, CA",
            "learning_style": "visual",
            "difficulty_preference": "advanced"
        }
        
        response = await client.put("/api/v1/profiles/me", json=update_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "testuser123"
        assert data["bio"] == "Hello, I'm a test user!"
        assert data["learning_style"] == "visual"
        assert data["difficulty_preference"] == "advanced"

    async def test_update_profile_duplicate_username(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test updating profile with existing username fails"""
        # Create another user with a username
        from src.profiles.service import ProfileService
        
        other_user = User(
            email="other@example.com",
            role="student",
            is_active=True,
            is_verified=True
        )
        db.add(other_user)
        await db.commit()
        await db.refresh(other_user)
        
        # Give other user a username
        await ProfileService.update_profile(
            other_user.id, 
            {"username": "existinguser"}, 
            db
        )
        
        # Try to use same username
        update_data = {"username": "existinguser"}
        response = await client.put("/api/v1/profiles/me", json=update_data)
        
        assert response.status_code == 400
        assert "already taken" in response.json()["detail"]

    async def test_get_profile_by_user_id(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test getting profile by user ID"""
        # Update profile first
        from src.profiles.service import ProfileService
        await ProfileService.update_profile(
            authenticated_user.user.id,
            {"username": "publicuser", "bio": "Public profile"},
            db
        )
        
        response = await client.get(f"/api/v1/profiles/{authenticated_user.user.id}")
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "publicuser"
        assert data["bio"] == "Public profile"

    async def test_get_profile_by_username(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test getting profile by username"""
        # Update profile with username
        from src.profiles.service import ProfileService
        await ProfileService.update_profile(
            authenticated_user.user.id,
            {"username": "findableuser"},
            db
        )
        
        response = await client.get("/api/v1/profiles/username/findableuser")
        
        assert response.status_code == 200
        data = response.json()
        assert data["username"] == "findableuser"

    async def test_follow_user(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test following another user"""
        # Create another user
        other_user = User(
            email="followme@example.com",
            role="student",
            is_active=True,
            is_verified=True
        )
        db.add(other_user)
        await db.commit()
        await db.refresh(other_user)
        
        # Follow the user
        response = await client.post(f"/api/v1/profiles/{other_user.id}/follow")
        
        assert response.status_code == 200
        data = response.json()
        assert data["follower_id"] == str(authenticated_user.user.id)
        assert data["following_id"] == str(other_user.id)
        assert data["is_approved"] == True  # Public profile, auto-approved

    async def test_follow_self_fails(
        self, client: AsyncClient, authenticated_user: TestData
    ):
        """Test that following yourself fails"""
        response = await client.post(
            f"/api/v1/profiles/{authenticated_user.user.id}/follow"
        )
        
        assert response.status_code == 400
        assert "Cannot follow yourself" in response.json()["detail"]

    async def test_search_profiles(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test searching profiles"""
        # Create searchable user
        from src.profiles.service import ProfileService
        
        search_user = User(
            email="searchable@example.com",
            first_name="John",
            last_name="Doe",
            role="student",
            is_active=True,
            is_verified=True
        )
        db.add(search_user)
        await db.commit()
        await db.refresh(search_user)
        
        await ProfileService.update_profile(
            search_user.id,
            {"username": "johndoe", "bio": "Searchable profile"},
            db
        )
        
        # Search for user
        response = await client.get("/api/v1/profiles/search?q=john")
        
        assert response.status_code == 200
        data = response.json()
        assert len(data) >= 1
        found_user = next((u for u in data if u["username"] == "johndoe"), None)
        assert found_user is not None

    async def test_get_interests(self, client: AsyncClient):
        """Test getting available interests"""
        response = await client.get("/api/v1/profiles/interests")
        
        assert response.status_code == 200
        data = response.json()
        # Should be empty initially unless seeded
        assert isinstance(data, list)

    async def test_add_interest(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test adding interest to profile"""
        # Create an interest
        interest = Interest(
            name="Python Programming",
            category="Technology",
            description="Learn Python programming",
            is_active=True
        )
        db.add(interest)
        await db.commit()
        await db.refresh(interest)
        
        # Add interest to user profile
        interest_data = {
            "interest_id": str(interest.id),
            "proficiency_level": "beginner",
            "is_learning": True
        }
        
        response = await client.post("/api/v1/profiles/me/interests", json=interest_data)
        
        assert response.status_code == 200
        data = response.json()
        assert data["interest"]["name"] == "Python Programming"
        assert data["proficiency_level"] == "beginner"
        assert data["is_learning"] == True

    async def test_remove_interest(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test removing interest from profile"""
        # Create and add interest first
        from src.profiles.service import ProfileService
        
        interest = Interest(
            name="Web Development",
            category="Technology", 
            is_active=True
        )
        db.add(interest)
        await db.commit()
        await db.refresh(interest)
        
        # Add interest
        await ProfileService.add_interest(
            authenticated_user.user.id,
            {"interest_id": interest.id, "proficiency_level": "intermediate"},
            db
        )
        
        # Remove interest
        response = await client.delete(f"/api/v1/profiles/me/interests/{interest.id}")
        
        assert response.status_code == 200
        assert "removed successfully" in response.json()["message"]

    async def test_private_profile_access(
        self, client: AsyncClient, authenticated_user: TestData, db: AsyncSession
    ):
        """Test that private profiles are not accessible to non-followers"""
        # Create private user
        from src.profiles.service import ProfileService
        
        private_user = User(
            email="private@example.com",
            role="student",
            is_active=True,
            is_verified=True
        )
        db.add(private_user)
        await db.commit()
        await db.refresh(private_user)
        
        # Make profile private
        await ProfileService.update_profile(
            private_user.id,
            {"is_private": True, "username": "privateuser"},
            db
        )
        
        # Try to access private profile
        response = await client.get(f"/api/v1/profiles/{private_user.id}")
        
        assert response.status_code == 403
        assert "private" in response.json()["detail"]
