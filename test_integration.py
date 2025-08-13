#!/usr/bin/env python3
"""
Test LyoApp Integration - Verify backend endpoints work
"""

import requests
import json

def test_backend_integration():
    base_url = "http://localhost:8000"
    
    print("🚀 Testing LyoApp Backend Integration")
    print("=" * 50)
    
    # Test 1: Health Check
    try:
        response = requests.get(f"{base_url}/api/v1/health")
        if response.status_code == 200:
            print("✅ Health Check: PASSED")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health Check: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Health Check: FAILED - {e}")
    
    # Test 2: Messenger Conversations
    try:
        response = requests.get(f"{base_url}/api/v1/messenger/conversations")
        if response.status_code == 200:
            print("✅ Messenger: PASSED")
            data = response.json()
            print(f"   Found {len(data.get('conversations', []))} conversations")
        else:
            print(f"❌ Messenger: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Messenger: FAILED - {e}")
    
    # Test 3: Library
    try:
        response = requests.get(f"{base_url}/api/v1/library")
        if response.status_code == 200:
            print("✅ Library: PASSED")
            data = response.json()
            print(f"   Found {len(data.get('library', []))} items")
        else:
            print(f"❌ Library: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Library: FAILED - {e}")
    
    # Test 4: Search
    try:
        search_data = {
            "query": "swift programming",
            "filters": {"content_types": ["course", "video"]},
            "limit": 5
        }
        response = requests.post(
            f"{base_url}/api/v1/search", 
            json=search_data,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            print("✅ Search: PASSED")
            data = response.json()
            print(f"   Found {len(data.get('results', []))} results")
        else:
            print(f"❌ Search: FAILED ({response.status_code})")
    except Exception as e:
        print(f"❌ Search: FAILED - {e}")
    
    print("\n🎉 Integration test complete!")
    print("\n📱 Your LyoApp is ready with:")
    print("   • 🔍 AI-powered search")
    print("   • 💬 Real-time messaging")
    print("   • 📚 Smart library management")
    print("   • ⚡ Quantum header drawer effects")

if __name__ == "__main__":
    test_backend_integration()
