#!/usr/bin/env python3

import requests
import json

def test_backend():
    """Test the LyoApp backend connectivity"""
    base_url = "http://localhost:8002"
    
    print("🔍 Testing LyoApp Backend Connection")
    print(f"📡 Base URL: {base_url}")
    print()
    
    # Test health endpoint
    try:
        response = requests.get(f"{base_url}/api/v1/health", timeout=5)
        print(f"✅ Health Check: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"   Response: {json.dumps(data, indent=2)}")
        else:
            print(f"   Error: {response.text}")
    except requests.exceptions.ConnectionError:
        print("❌ Health Check: Connection refused")
        print("   Make sure the backend is running on port 8002")
    except Exception as e:
        print(f"❌ Health Check: {str(e)}")
    
    print()
    
    # Test API documentation endpoint
    try:
        response = requests.get(f"{base_url}/docs", timeout=5)
        print(f"✅ API Docs: {response.status_code}")
        if response.status_code == 200:
            print(f"   Swagger docs available at: {base_url}/docs")
    except Exception as e:
        print(f"❌ API Docs: {str(e)}")
    
    print()
    
    # List available endpoints
    print("📋 Expected API Endpoints:")
    endpoints = [
        "/api/v1/health",
        "/api/v1/auth/apple", 
        "/api/v1/auth/google",
        "/api/v1/auth/meta",
        "/api/v1/auth/refresh",
        "/api/v1/auth/logout",
        "/api/v1/auth/me",
        "/api/v1/feed",
        "/api/v1/posts",
        "/api/v1/courses/featured",
        "/api/v1/courses/search",
        "/api/v1/media/upload"
    ]
    
    for endpoint in endpoints:
        print(f"   • {endpoint}")
    
    print()
    print("🔧 iOS App Configuration:")
    print(f"   Base URL: {base_url}")
    print(f"   Headers: Authorization: Bearer <token>")
    print(f"   Content-Type: application/json")

if __name__ == "__main__":
    test_backend()
