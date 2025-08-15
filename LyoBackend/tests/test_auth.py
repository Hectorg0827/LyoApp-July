# Authentication Tests
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from src.auth.models import User
from src.auth.service import auth_service


class TestAuth:
    """Test authentication endpoints"""
    
    @pytest.mark.asyncio
    async def test_health_check(self, client: AsyncClient):
        """Test health check endpoint"""
        response = await client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data
    
    @pytest.mark.asyncio
    async def test_register_user(self, client: AsyncClient):
        """Test user registration"""
        user_data = {
            "email": "test@example.com",
            "password": "testpassword123",
            "first_name": "Test",
            "last_name": "User",
        }
        
        response = await client.post("/v1/auth/register", json=user_data)
        assert response.status_code == 200
        
        data = response.json()
        assert data["email"] == user_data["email"]
        assert data["first_name"] == user_data["first_name"]
        assert data["role"] == "student"  # Default role
    
    @pytest.mark.asyncio
    async def test_login_user(self, client: AsyncClient, db_session: AsyncSession):
        """Test user login"""
        # First create a user
        user = User(
            email="login@example.com",
            hashed_password=auth_service.hash_password("password123"),
            first_name="Login",
            last_name="Test",
            role="student",
        )
        db_session.add(user)
        await db_session.commit()
        
        # Login
        login_data = {
            "email": "login@example.com",
            "password": "password123",
        }
        
        response = await client.post("/v1/auth/login", json=login_data)
        assert response.status_code == 200
        
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"
        assert data["user"]["email"] == login_data["email"]
    
    @pytest.mark.asyncio
    async def test_login_invalid_credentials(self, client: AsyncClient):
        """Test login with invalid credentials"""
        login_data = {
            "email": "nonexistent@example.com",
            "password": "wrongpassword",
        }
        
        response = await client.post("/v1/auth/login", json=login_data)
        assert response.status_code == 401
        
        data = response.json()
        assert "Invalid email or password" in data["detail"]
    
    @pytest.mark.asyncio
    async def test_get_current_user(self, client: AsyncClient, db_session: AsyncSession):
        """Test getting current user info"""
        # Create and login user
        user = User(
            email="current@example.com",
            hashed_password=auth_service.hash_password("password123"),
            first_name="Current",
            last_name="User",
            role="student",
        )
        db_session.add(user)
        await db_session.commit()
        
        # Login to get token
        login_response = await client.post("/v1/auth/login", json={
            "email": "current@example.com",
            "password": "password123",
        })
        token = login_response.json()["access_token"]
        
        # Get current user
        headers = {"Authorization": f"Bearer {token}"}
        response = await client.get("/v1/auth/me", headers=headers)
        assert response.status_code == 200
        
        data = response.json()
        assert data["email"] == "current@example.com"
        assert data["first_name"] == "Current"
    
    @pytest.mark.asyncio
    async def test_unauthorized_access(self, client: AsyncClient):
        """Test accessing protected endpoint without token"""
        response = await client.get("/v1/auth/me")
        assert response.status_code == 403  # Missing Authorization header
    
    @pytest.mark.asyncio
    async def test_invalid_token(self, client: AsyncClient):
        """Test accessing protected endpoint with invalid token"""
        headers = {"Authorization": "Bearer invalid-token"}
        response = await client.get("/v1/auth/me", headers=headers)
        assert response.status_code == 401
