#!/usr/bin/env python3
"""
Quick setup verification and self-check script
"""
import asyncio
import sys
import subprocess
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
sys.path.append(str(project_root))


async def check_dependencies():
    """Check if required dependencies are installed"""
    print("🔍 Checking dependencies...")
    
    try:
        import fastapi
        import sqlalchemy
        import redis
        import pydantic
        print("✅ Core dependencies installed")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Run: poetry install")
        return False


def check_environment():
    """Check environment setup"""
    print("🔧 Checking environment...")
    
    env_file = project_root / ".env"
    if not env_file.exists():
        print("⚠️  .env file not found. Copying from .env.sample...")
        sample_env = project_root / ".env.sample"
        if sample_env.exists():
            import shutil
            shutil.copy(sample_env, env_file)
            print("✅ .env file created from sample")
        else:
            print("❌ .env.sample not found")
            return False
    else:
        print("✅ .env file exists")
    
    return True


def run_linting():
    """Run code quality checks"""
    print("🧹 Running linting checks...")
    
    try:
        # Check if we can import ruff and black
        result = subprocess.run(
            ["poetry", "run", "ruff", "check", "--help"], 
            capture_output=True, 
            text=True,
            cwd=project_root
        )
        if result.returncode == 0:
            print("✅ Ruff is available")
        else:
            print("❌ Ruff check failed")
            return False
        
        return True
    except Exception as e:
        print(f"❌ Linting setup issue: {e}")
        return False


async def test_imports():
    """Test critical imports"""
    print("📦 Testing imports...")
    
    try:
        from src.core.config import get_settings
        from src.core.logging import setup_logging, get_structured_logger
        from src.auth.models import User
        from src.auth.service import auth_service
        
        print("✅ All core imports successful")
        return True
    except Exception as e:
        print(f"❌ Import error: {e}")
        return False


async def test_basic_functionality():
    """Test basic functionality"""
    print("🧪 Testing basic functionality...")
    
    try:
        from src.core.config import get_settings
        settings = get_settings()
        print(f"✅ Config loaded: {settings.app_name}")
        
        from src.core.logging import setup_logging, get_structured_logger
        setup_logging()
        logger = get_structured_logger("test")
        logger.info("Test log message")
        print("✅ Logging setup successful")
        
        from src.auth.service import auth_service
        hashed = auth_service.hash_password("test123")
        verified = auth_service.verify_password("test123", hashed)
        if verified:
            print("✅ Password hashing/verification working")
        else:
            print("❌ Password verification failed")
            return False
        
        return True
    except Exception as e:
        print(f"❌ Functionality test failed: {e}")
        return False


def run_quick_syntax_check():
    """Run quick syntax validation"""
    print("📋 Running syntax checks...")
    
    try:
        result = subprocess.run(
            ["python", "-m", "py_compile", "main.py"],
            cwd=project_root,
            capture_output=True,
            text=True
        )
        
        if result.returncode == 0:
            print("✅ main.py syntax is valid")
            return True
        else:
            print(f"❌ Syntax error in main.py: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Syntax check failed: {e}")
        return False


async def main():
    """Main verification function"""
    print("🚀 LyoApp Backend - Self-Check & Setup Verification")
    print("=" * 50)
    
    checks = [
        ("Dependencies", check_dependencies()),
        ("Environment", check_environment()),  
        ("Linting Setup", run_linting()),
        ("Syntax", run_quick_syntax_check()),
        ("Imports", test_imports()),
        ("Basic Functionality", test_basic_functionality()),
    ]
    
    results = []
    for name, check in checks:
        if asyncio.iscoroutine(check):
            result = await check
        else:
            result = check
        results.append((name, result))
        print()
    
    print("=" * 50)
    print("📋 SELF-CHECK SUMMARY:")
    print("=" * 50)
    
    all_passed = True
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{name:<20} {status}")
        if not passed:
            all_passed = False
    
    print("=" * 50)
    
    if all_passed:
        print("🎉 ALL CHECKS PASSED!")
        print("Your LyoApp Backend setup is ready!")
        print()
        print("Next steps:")
        print("1. Review .env configuration")
        print("2. Set up PostgreSQL and Redis")
        print("3. Run: make migrate")
        print("4. Run: make seed")
        print("5. Run: make dev")
        return True
    else:
        print("⚠️  SOME CHECKS FAILED!")
        print("Please fix the issues above before proceeding.")
        return False


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
