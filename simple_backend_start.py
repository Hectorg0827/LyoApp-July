#!/usr/bin/env python3
"""
Simple backend startup script for LyoApp development
This handles common environment issues and starts the FastAPI server
"""

import os
import sys
import subprocess
import signal
import time
from pathlib import Path

def setup_environment():
    """Setup basic environment variables"""
    os.environ.setdefault("PYTHONPATH", "/Users/republicalatuya/Desktop/LyoBackendJune")
    os.environ.setdefault("DATABASE_URL", "sqlite:///./lyo_app_dev.db")
    os.environ.setdefault("SECRET_KEY", "development-secret-key-not-for-production")
    os.environ.setdefault("ENVIRONMENT", "development")
    os.environ.setdefault("API_V1_PREFIX", "/api/v1")

def check_port_available(port=8000):
    """Check if port is available"""
    import socket
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        result = s.connect_ex(('localhost', port))
        return result != 0

def kill_existing_server(port=8000):
    """Kill any existing server on the port"""
    try:
        result = subprocess.run(["lsof", "-ti", f":{port}"], capture_output=True, text=True)
        if result.stdout.strip():
            pids = result.stdout.strip().split('\n')
            for pid in pids:
                try:
                    os.kill(int(pid), signal.SIGTERM)
                    print(f"Killed existing process {pid}")
                except:
                    pass
        time.sleep(2)
    except:
        pass

def start_server():
    """Start the FastAPI server"""
    backend_dir = Path("/Users/republicalatuya/Desktop/LyoBackendJune")
    if not backend_dir.exists():
        print(f"❌ Backend directory not found: {backend_dir}")
        return False
    
    os.chdir(backend_dir)
    
    # Setup environment
    setup_environment()
    
    # Kill existing server
    kill_existing_server()
    
    # Start server
    print("🚀 Starting LyoApp Backend Server...")
    try:
        # Use a simple uvicorn command
        cmd = [
            sys.executable, "-m", "uvicorn", 
            "lyo_app.main:app", 
            "--host", "0.0.0.0", 
            "--port", "8000", 
            "--reload"
        ]
        
        subprocess.run(cmd)
        
    except KeyboardInterrupt:
        print("\n🛑 Server stopped by user")
        return True
    except Exception as e:
        print(f"❌ Failed to start server: {e}")
        return False

if __name__ == "__main__":
    print("🎯 LyoApp Backend Startup Script")
    print("=" * 40)
    
    if not check_port_available():
        print("⚠️ Port 8000 is in use, attempting to free it...")
        kill_existing_server()
    
    success = start_server()
    sys.exit(0 if success else 1)
