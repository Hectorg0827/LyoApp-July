#!/usr/bin/env python3
"""
Simple development server start script
"""
import sys
import os
from pathlib import Path

# Add project root to Python path
project_root = Path(__file__).parent
sys.path.append(str(project_root))

# Set environment variables for development
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://lyoapp:lyoapp123@localhost/lyoapp_dev")
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0") 
os.environ.setdefault("SECRET_KEY", "dev-secret-key-change-in-production")
os.environ.setdefault("JWT_SECRET_KEY", "dev-jwt-secret-key-change-in-production")
os.environ.setdefault("DEBUG", "true")
os.environ.setdefault("LOG_LEVEL", "INFO")

def main():
    """Start the development server"""
    print("🚀 Starting LyoApp Backend Development Server...")
    print(f"📁 Project root: {project_root}")
    print("🔧 Environment: DEVELOPMENT")
    print("📱 Features: Authentication, Health Checks, API Documentation")
    print()
    
    try:
        import uvicorn
        uvicorn.run(
            "main:app",
            host="0.0.0.0", 
            port=8000,
            reload=True,
            log_level="info"
        )
    except ImportError:
        print("❌ uvicorn not found. Please install it with:")
        print("pip install uvicorn[standard]")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
