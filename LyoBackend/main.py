# Main FastAPI Application
import logging
import time
from contextlib import asynccontextmanager
from uuid import uuid4

from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
import structlog
import os

# Import routers
from src.auth.router import router as auth_router
from src.profiles.router import router as profiles_router
from src.media.router import router as media_router
from src.learning.routes.courses import router as courses_router
from src.learning.routes.progress import router as progress_router
from src.learning.routes.evidence import router as evidence_router
from src.learning.routes.sessions import router as sessions_router
from src.core.config import get_settings
from src.core.database import check_db_health, close_db, init_db
from src.core.logging import (
    clear_request_context,
    get_request_id,
    get_structured_logger,
    set_request_context,
    setup_logging,
)
from src.core.redis import check_redis_health, close_redis, init_redis

# Setup logging first
setup_logging()
logger = get_structured_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan events"""
    # Startup
    logger.info("Starting LyoApp Backend...")
    
    try:
        await init_db()
        await init_redis()
        logger.info("All services initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize services: {e}")
        raise
    
    yield
    
    # Shutdown
    logger.info("Shutting down LyoApp Backend...")
    await close_db()
    await close_redis()
    logger.info("Shutdown complete")


# Create FastAPI app
settings = get_settings()
app = FastAPI(
    title="LyoApp Backend",
    description="Modular Monolith Backend for LyoApp - Educational Social Platform",
    version="1.0.0",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=settings.cors_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request ID middleware
@app.middleware("http")
async def request_id_middleware(request: Request, call_next):
    """Add request ID to all requests"""
    request_id = str(uuid4())
    set_request_context(request_id)
    
    # Add request ID to response headers
    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    
    # Clear context after request
    clear_request_context()
    
    return response


# Logging middleware
@app.middleware("http")
async def logging_middleware(request: Request, call_next):
    """Log all requests"""
    start_time = time.time()
    
    # Log request
    logger.info(
        "Request started",
        method=request.method,
        url=str(request.url),
        headers=dict(request.headers),
    )
    
    response = await call_next(request)
    
    # Log response
    process_time = time.time() - start_time
    logger.info(
        "Request completed",
        method=request.method,
        url=str(request.url),
        status_code=response.status_code,
        process_time=round(process_time * 1000, 2),  # ms
    )
    
    return response


# Security headers middleware
@app.middleware("http")
async def security_headers_middleware(request: Request, call_next):
    """Add security headers"""
    response = await call_next(request)
    
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    
    return response


# Health check endpoints
@app.get("/health")
async def health_check():
    """Basic health check"""
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "service": "lyoapp-backend",
        "version": "1.0.0"
    }


@app.get("/health/ready")
async def readiness_check():
    """Readiness check with dependencies"""
    checks = {
        "database": await check_db_health(),
        "redis": await check_redis_health(),
    }
    
    all_healthy = all(checks.values())
    
    response = {
        "status": "ready" if all_healthy else "not ready",
        "timestamp": time.time(),
        "checks": checks
    }
    
    status_code = status.HTTP_200_OK if all_healthy else status.HTTP_503_SERVICE_UNAVAILABLE
    
    return JSONResponse(content=response, status_code=status_code)


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Handle uncaught exceptions"""
    request_id = get_request_id()
    
    logger.error(
        "Unhandled exception",
        request_id=request_id,
        exception=str(exc),
        exc_info=exc if settings.debug else None
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "Internal server error",
            "request_id": request_id,
            "detail": str(exc) if settings.debug else "An unexpected error occurred"
        }
    )


# Include routers
# Register routers
app.include_router(auth_router, prefix="/api/v1")
app.include_router(profiles_router, prefix="/api/v1")
app.include_router(media_router, prefix="/api/v1")
app.include_router(courses_router, prefix="/api/v1")
app.include_router(progress_router, prefix="/api/v1")
app.include_router(evidence_router, prefix="/api/v1")
app.include_router(sessions_router, prefix="/api/v1")

# Serve uploaded media files in development
if not settings.GOOGLE_APPLICATION_CREDENTIALS:
    uploads_dir = "uploads"
    os.makedirs(uploads_dir, exist_ok=True)
    app.mount("/media", StaticFiles(directory=uploads_dir), name="media")


# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "LyoApp Backend API",
        "version": "1.0.0",
        "docs": "/docs" if settings.debug else "Documentation not available in production",
        "health": "/health"
    }


if __name__ == "__main__":
    import uvicorn
    
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=settings.debug,
        log_config=None,  # Use our custom logging
    )
