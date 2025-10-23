#!/usr/bin/env python3
"""
Simplified Lyo Backend - Minimal dependencies version
Provides auth and AI endpoints for testing the iOS app
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import json
import uuid
import re
from datetime import datetime, timedelta

# ============================================================================
# SIMPLE IN-MEMORY DATA STORAGE
# ============================================================================

users_db = {
    "test@lyoapp.com": {
        "id": 1,
        "email": "test@lyoapp.com",
        "password": "password123",
        "name": "Test User",
        "created_at": "2025-10-22T00:00:00Z"
    }
}

sessions_db = {}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def generate_token(prefix):
    """Generate a simple token"""
    return f"{prefix}_{uuid.uuid4().hex[:40]}"

def json_response(handler, data, status=200):
    """Send JSON response"""
    handler.send_response(status)
    handler.send_header('Content-Type', 'application/json')
    handler.send_header('Access-Control-Allow-Origin', '*')
    handler.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    handler.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    handler.end_headers()
    handler.wfile.write(json.dumps(data).encode())

def error_response(handler, message, status=400):
    """Send error response"""
    json_response(handler, {"error": message}, status)

def parse_body(handler):
    """Parse request body"""
    try:
        content_length = int(handler.headers.get('Content-Length', 0))
        body = handler.rfile.read(content_length)
        return json.loads(body) if body else {}
    except:
        return {}

# ============================================================================
# REQUEST HANDLERS
# ============================================================================

class LyoBackendHandler(BaseHTTPRequestHandler):
    
    def do_OPTIONS(self):
        """Handle CORS preflight"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def do_GET(self):
        """Handle GET requests"""
        path = urlparse(self.path).path
        
        # Health check
        if path == "/api/v1/health":
            json_response(self, {
                "status": "healthy",
                "version": "1.0.0",
                "gemini_configured": True
            })
        
        # AI context endpoint
        elif path == "/api/v1/ai/avatar/context":
            json_response(self, {
                "topics_covered": ["Python", "Web Development", "Machine Learning"],
                "learning_goals": ["Build web apps", "Learn AI/ML", "Master Python"],
                "proficiency_level": "intermediate"
            })
        
        else:
            error_response(self, "Not found", 404)
    
    def do_POST(self):
        """Handle POST requests"""
        path = urlparse(self.path).path
        body = parse_body(self)
        
        # Login endpoint
        if path == "/api/v1/auth/login":
            email = body.get("email")
            password = body.get("password")
            
            if email in users_db and users_db[email]["password"] == password:
                user = users_db[email]
                token = generate_token("token")
                sessions_db[token] = {
                    "user_id": user["id"],
                    "email": email,
                    "expires": (datetime.now() + timedelta(hours=24)).isoformat()
                }
                
                json_response(self, {
                    "access_token": token,
                    "refresh_token": generate_token("refresh"),
                    "user": {
                        "id": user["id"],
                        "email": user["email"],
                        "name": user["name"],
                        "created_at": user["created_at"]
                    }
                }, 200)
            else:
                error_response(self, "Invalid credentials", 401)
        
        # Signup endpoint
        elif path == "/api/v1/auth/signup":
            email = body.get("email")
            password = body.get("password")
            name = body.get("name", email.split("@")[0])
            
            if email in users_db:
                error_response(self, "User already exists", 409)
            elif not email or not password:
                error_response(self, "Email and password required", 400)
            else:
                user_id = max([u["id"] for u in users_db.values()] or [0]) + 1
                users_db[email] = {
                    "id": user_id,
                    "email": email,
                    "password": password,
                    "name": name,
                    "created_at": datetime.now().isoformat() + "Z"
                }
                
                token = generate_token("token")
                sessions_db[token] = {
                    "user_id": user_id,
                    "email": email,
                    "expires": (datetime.now() + timedelta(hours=24)).isoformat()
                }
                
                json_response(self, {
                    "access_token": token,
                    "refresh_token": generate_token("refresh"),
                    "user": users_db[email]
                }, 201)
        
        # AI message endpoint (simple mock responses)
        elif path == "/api/v1/ai/avatar/message":
            message = body.get("message", "")
            
            # Simple response logic
            if "hello" in message.lower():
                response = "Hello! 👋 I'm your AI learning assistant. How can I help you learn today?"
            elif "course" in message.lower():
                response = "I can help you create courses! What subject would you like to learn?"
            elif "python" in message.lower():
                response = "Python is great! I can help you learn Python from basics to advanced topics."
            else:
                response = f"Interesting question about '{message}'. I'm here to help you learn. What would you like to explore?"
            
            json_response(self, {
                "response": response,
                "confidence": 0.95
            })
        
        # Course generation endpoint
        elif path == "/api/v1/ai/generate-course":
            topic = body.get("topic", "General Learning")
            
            json_response(self, {
                "course_title": f"Master {topic}",
                "lessons": [
                    {
                        "number": 1,
                        "title": f"Introduction to {topic}",
                        "description": f"Learn the basics of {topic}",
                        "duration_minutes": 15
                    },
                    {
                        "number": 2,
                        "title": f"Core Concepts of {topic}",
                        "description": f"Deep dive into core {topic} concepts",
                        "duration_minutes": 20
                    },
                    {
                        "number": 3,
                        "title": f"Intermediate {topic}",
                        "description": f"Build practical skills in {topic}",
                        "duration_minutes": 25
                    },
                    {
                        "number": 4,
                        "title": f"Advanced {topic}",
                        "description": f"Master advanced {topic} techniques",
                        "duration_minutes": 30
                    },
                    {
                        "number": 5,
                        "title": f"Capstone Project: {topic}",
                        "description": f"Complete a real-world {topic} project",
                        "duration_minutes": 45
                    }
                ]
            })
        
        else:
            error_response(self, "Not found", 404)
    
    def log_message(self, format, *args):
        """Suppress default logging"""
        pass

# ============================================================================
# SERVER START
# ============================================================================

def run_server(port=8000):
    """Start the HTTP server"""
    server = HTTPServer(('localhost', port), LyoBackendHandler)
    print(f"🚀 Lyo Backend running on http://localhost:{port}")
    print(f"📍 Health check: GET http://localhost:{port}/api/v1/health")
    print(f"🔐 Login: POST http://localhost:{port}/api/v1/auth/login")
    print(f"✨ AI Message: POST http://localhost:{port}/api/v1/ai/avatar/message")
    print(f"📚 Generate Course: POST http://localhost:{port}/api/v1/ai/generate-course")
    print(f"\n📝 Test credentials: test@lyoapp.com / password123\n")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n✋ Shutting down...")
        server.shutdown()

if __name__ == "__main__":
    run_server()
