#!/usr/bin/env python3
"""
LyoApp Backend Integration Test
This script tests backend connectivity and maps endpoints for frontend integration.
"""

import requests
import json
import time
import sys

def test_backend_connection():
    """Test if backend is running and accessible"""
    base_url = "http://localhost:8000"
    
    print("🔍 Testing backend connectivity...")
    
    # Test basic connectivity
    try:
        response = requests.get(base_url, timeout=5)
        print(f"✅ Backend is running at {base_url}")
        return True
    except requests.ConnectionError:
        print(f"❌ Backend not accessible at {base_url}")
        return False
    except Exception as e:
        print(f"❌ Error connecting to backend: {e}")
        return False

def get_available_endpoints():
    """Get all available API endpoints from OpenAPI spec"""
    print("\n🔍 Discovering available endpoints...")
    
    try:
        response = requests.get("http://localhost:8000/openapi.json", timeout=5)
        if response.status_code == 200:
            spec = response.json()
            endpoints = []
            
            for path, methods in spec.get('paths', {}).items():
                for method, details in methods.items():
                    summary = details.get('summary', 'No description')
                    endpoints.append({
                        'method': method.upper(),
                        'path': path,
                        'summary': summary
                    })
            
            return endpoints
        else:
            print(f"❌ Failed to get OpenAPI spec: {response.status_code}")
            return []
    except Exception as e:
        print(f"❌ Error getting endpoints: {e}")
        return []

def test_health_endpoints():
    """Test common health check endpoints"""
    print("\n🔍 Testing health check endpoints...")
    
    health_endpoints = [
        "/health",
        "/api/health", 
        "/ai/health",
        "/status",
        "/ping",
        "/api/v1/health"
    ]
    
    working_endpoints = []
    
    for endpoint in health_endpoints:
        try:
            response = requests.get(f"http://localhost:8000{endpoint}", timeout=3)
            if response.status_code == 200:
                print(f"✅ {endpoint}: {response.status_code} - {response.text[:100]}")
                working_endpoints.append(endpoint)
            else:
                print(f"⚠️  {endpoint}: {response.status_code}")
        except:
            print(f"❌ {endpoint}: Not available")
    
    return working_endpoints

def test_ai_endpoints():
    """Test AI-related endpoints that the frontend needs"""
    print("\n🔍 Testing AI endpoints...")
    
    ai_endpoints = [
        ("/ai/curriculum/course-outline", "POST"),
        ("/ai/mentor/conversation", "POST"),
        ("/ai/curriculum/lesson-content", "POST"),
        ("/api/ai/chat", "POST"),
        ("/chat", "POST"),
        ("/api/courses", "GET"),
        ("/api/lessons", "GET"),
    ]
    
    working_endpoints = []
    
    for endpoint, method in ai_endpoints:
        try:
            if method == "GET":
                response = requests.get(f"http://localhost:8000{endpoint}", timeout=3)
            else:
                # For POST endpoints, just check if they exist (may return 422 for missing body)
                response = requests.post(f"http://localhost:8000{endpoint}", json={}, timeout=3)
            
            if response.status_code in [200, 201, 422]:  # 422 = validation error, but endpoint exists
                print(f"✅ {method} {endpoint}: Available")
                working_endpoints.append((endpoint, method))
            else:
                print(f"⚠️  {method} {endpoint}: {response.status_code}")
        except:
            print(f"❌ {method} {endpoint}: Not available")
    
    return working_endpoints

def generate_frontend_config(health_endpoint, ai_endpoints):
    """Generate Swift configuration updates for frontend"""
    print("\n📝 Generating frontend configuration...")
    
    config = f"""
// MARK: - Backend Integration Updates
// Update LyoAPIService.swift with these endpoint mappings:

// Health Check Endpoint
// Change from: "/ai/health"
// Change to: "{health_endpoint}"

// Available AI Endpoints:"""
    
    for endpoint, method in ai_endpoints:
        config += f"\n// {method} {endpoint}"
    
    config += """

// Recommended Frontend Updates:
// 1. Update LyoAPIService.checkConnection() to use the working health endpoint
// 2. Map AI endpoints to match backend structure
// 3. Test each endpoint with proper request/response models
// 4. Add error handling for new endpoint structure
"""
    
    return config

def main():
    """Main integration test"""
    print("🚀 LyoApp Backend Integration Test\n")
    
    # Test backend connectivity
    if not test_backend_connection():
        print("\n❌ Backend is not running. Please start the backend server first.")
        print("Instructions:")
        print("1. Navigate to your lyoBackenJune directory")
        print("2. Start the server (e.g., 'python main.py' or 'uvicorn main:app --reload')")
        print("3. Ensure it's running on http://localhost:8000")
        sys.exit(1)
    
    # Get available endpoints
    endpoints = get_available_endpoints()
    if endpoints:
        print(f"\n✅ Found {len(endpoints)} available endpoints:")
        for ep in endpoints[:10]:  # Show first 10
            print(f"  {ep['method']} {ep['path']} - {ep['summary']}")
        if len(endpoints) > 10:
            print(f"  ... and {len(endpoints) - 10} more")
    
    # Test health endpoints
    health_endpoints = test_health_endpoints()
    working_health = health_endpoints[0] if health_endpoints else "/health"
    
    # Test AI endpoints
    ai_endpoints = test_ai_endpoints()
    
    # Generate configuration
    config = generate_frontend_config(working_health, ai_endpoints)
    
    print("\n✅ Integration test complete!")
    print(config)
    
    # Save results
    with open("backend_integration_results.txt", "w") as f:
        f.write(config)
    
    print(f"\n📄 Results saved to: backend_integration_results.txt")

if __name__ == "__main__":
    main()
