#!/usr/bin/env python3

import requests
import json
import sys
from datetime import datetime

# Backend configuration
BASE_URL = "http://localhost:8000"

def test_backend_connection():
    """Test LyoApp backend connection and endpoints"""
    
    print("🔍 Testing LyoApp Backend Connection")
    print("=" * 50)
    
    # Test 1: Root endpoint
    print("\n1. Testing Root Endpoint")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=5)
        if response.status_code == 200:
            print(f"✅ Root: {response.status_code} - {response.text[:100]}")
        else:
            print(f"❌ Root: {response.status_code}")
    except Exception as e:
        print(f"❌ Root: Connection failed - {e}")
    
    # Test 2: Health check
    print("\n2. Testing Health Endpoint")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code == 200:
            print(f"✅ Health: {response.status_code}")
            try:
                data = response.json()
                print(f"   Response: {json.dumps(data, indent=2)}")
            except:
                print(f"   Response: {response.text}")
        else:
            print(f"❌ Health: {response.status_code}")
    except Exception as e:
        print(f"❌ Health: Connection failed - {e}")
    
    # Test 3: API Documentation
    print("\n3. Testing API Documentation")
    try:
        response = requests.get(f"{BASE_URL}/docs", timeout=5)
        if response.status_code == 200:
            print(f"✅ API Docs: {response.status_code} - Available at {BASE_URL}/docs")
        else:
            print(f"❌ API Docs: {response.status_code}")
    except Exception as e:
        print(f"❌ API Docs: Connection failed - {e}")
    
    # Test 4: AI Endpoints
    print("\n4. Testing AI Endpoints")
    
    # Test course generation endpoint
    try:
        course_data = {
            "title": "Test Course",
            "description": "Test description for AI course generation",
            "targetAudience": "Beginners",
            "learningObjectives": ["Learn basics", "Apply concepts"],
            "difficultyLevel": "beginner",
            "estimatedDurationHours": 1
        }
        
        response = requests.post(
            f"{BASE_URL}/api/v1/ai/curriculum/course-outline",
            json=course_data,
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"✅ Course Generation: {response.status_code}")
            try:
                data = response.json()
                print(f"   Generated course: {data.get('title', 'Unknown')}")
            except:
                print(f"   Response received")
        else:
            print(f"❌ Course Generation: {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data}")
            except:
                print(f"   Error: {response.text}")
                
    except Exception as e:
        print(f"❌ Course Generation: Connection failed - {e}")
    
    # Test mentor chat endpoint
    try:
        chat_data = {
            "message": "Hello, I want to learn programming",
            "context": {"topic": "Programming"}
        }
        
        response = requests.post(
            f"{BASE_URL}/api/v1/ai/mentor/conversation",
            json=chat_data,
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"✅ Mentor Chat: {response.status_code}")
            try:
                data = response.json()
                print(f"   Response: {data.get('response', 'No response')[:100]}...")
            except:
                print(f"   Response received")
        else:
            print(f"❌ Mentor Chat: {response.status_code}")
            try:
                error_data = response.json()
                print(f"   Error: {error_data}")
            except:
                print(f"   Error: {response.text}")
                
    except Exception as e:
        print(f"❌ Mentor Chat: Connection failed - {e}")
    
    print("\n" + "=" * 50)
    print("🎉 Backend test completed!")
    print(f"📊 Test performed at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    test_backend_connection()
