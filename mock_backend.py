#!/usr/bin/env python3
"""
Simple mock backend server for testing course generation
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/v1/health")
async def health_check():
    return {"status": "healthy", "message": "Mock backend is running"}

@app.get("/health")
async def health_check_alt():
    return {"status": "healthy", "message": "Mock backend is running"}

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Mock Backend Server on http://localhost:8000")
    print("📡 Health check: http://localhost:8000/api/v1/health")
    uvicorn.run(app, host="0.0.0.0", port=8000)