#!/usr/bin/env python3
"""
Simple Backend Server for LyoApp
Provides basic API endpoints for testing and development
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import urllib.parse
from datetime import datetime

class LyoAPIHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        # Health check endpoint
        if path == '/api/v1/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "status": "healthy",
                "service": "LyoApp Backend",
                "version": "1.0.0",
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(response).encode())
            
        # Courses endpoint
        elif path == '/api/v1/courses':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            courses = [
                {
                    "id": "cs50",
                    "title": "CS50: Introduction to Computer Science",
                    "instructor": "David J. Malan",
                    "university": "Harvard University",
                    "description": "Harvard's introduction to computer science and programming",
                    "students": 1500000,
                    "rating": 4.8
                },
                {
                    "id": "ml-stanford",
                    "title": "Machine Learning",
                    "instructor": "Andrew Ng",
                    "university": "Stanford University", 
                    "description": "Stanford's comprehensive ML course",
                    "students": 850000,
                    "rating": 4.9
                },
                {
                    "id": "mit-linear-algebra",
                    "title": "Linear Algebra",
                    "instructor": "Gilbert Strang",
                    "university": "MIT",
                    "description": "MIT's foundational linear algebra course",
                    "students": 320000,
                    "rating": 4.9
                }
            ]
            
            self.wfile.write(json.dumps({"courses": courses}).encode())
            
        # AI Chat endpoint
        elif path.startswith('/api/v1/ai/chat'):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "response": "Hello! I'm Lio, your AI learning companion. How can I help you learn today?",
                "confidence": 0.95,
                "timestamp": datetime.now().isoformat()
            }
            self.wfile.write(json.dumps(response).encode())
            
        # Search endpoint
        elif path.startswith('/api/v1/search'):
            query_params = urllib.parse.parse_qs(parsed_path.query)
            search_query = query_params.get('q', [''])[0]
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            results = [
                {
                    "title": f"Search result for: {search_query}",
                    "type": "course",
                    "relevance": 0.9
                }
            ]
            
            self.wfile.write(json.dumps({"results": results, "query": search_query}).encode())
            
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            error = {"error": "Endpoint not found", "path": path}
            self.wfile.write(json.dumps(error).encode())
    
    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urllib.parse.urlparse(self.path)
        path = parsed_path.path
        
        # Read request body
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data.decode()) if content_length > 0 else {}
        except:
            data = {}
        
        # Authentication endpoint
        if path == '/api/v1/auth/login':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            response = {
                "token": "mock_jwt_token_for_testing",
                "user": {
                    "id": "user123",
                    "email": data.get("email", "test@lyo.app"),
                    "name": "Test User"
                },
                "expires_in": 3600
            }
            self.wfile.write(json.dumps(response).encode())
            
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            error = {"error": "Endpoint not found", "path": path}
            self.wfile.write(json.dumps(error).encode())
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
    
    def log_message(self, format, *args):
        """Override to customize logging"""
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

def run_server(port=8000):
    """Start the server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, LyoAPIHandler)
    
    print(f"🚀 LyoApp Backend Server Starting...")
    print(f"📡 Server running on http://localhost:{port}")
    print(f"🔗 Health check: http://localhost:{port}/api/v1/health")
    print(f"📚 Courses API: http://localhost:{port}/api/v1/courses")
    print(f"🤖 AI Chat API: http://localhost:{port}/api/v1/ai/chat")
    print(f"🔍 Search API: http://localhost:{port}/api/v1/search?q=test")
    print(f"🔐 Auth API: http://localhost:{port}/api/v1/auth/login")
    print(f"")
    print(f"✅ Backend ready for LyoApp integration!")
    print(f"Press Ctrl+C to stop the server")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print(f"\n🛑 Server stopped")
        httpd.server_close()

if __name__ == '__main__':
    run_server()
