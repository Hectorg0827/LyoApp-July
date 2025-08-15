# Simplified configuration for immediate testing
import os
from dataclasses import dataclass
from typing import List

@dataclass
class Settings:
    """Simple settings class for development"""
    
    # Core
    app_name: str = "LyoApp Backend"
    version: str = "1.0.0"
    debug: bool = True
    
    # Database
    database_url: str = "postgresql+asyncpg://lyoapp:lyoapp123@localhost/lyoapp_dev"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # JWT
    secret_key: str = "dev-secret-key-change-in-production"
    jwt_secret_key: str = "dev-jwt-secret-key-change-in-production"
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 30
    refresh_token_expire_days: int = 30
    
    # Feature flags
    enable_enhanced_ranking: bool = False
    enable_exploration: bool = False
    enable_gamification: bool = True
    
    # Rate limiting
    rate_limit_auth: int = 60
    rate_limit_ai: int = 30
    rate_limit_posting: int = 20
    
    # CORS
    cors_origins: List[str] = None
    cors_allow_credentials: bool = True
    
    # Logging
    log_level: str = "INFO"
    structured_logging: bool = True
    redact_pii: bool = True
    
    def __post_init__(self):
        """Initialize from environment variables"""
        if self.cors_origins is None:
            self.cors_origins = ["http://localhost:3000", "https://lyoapp.com"]
        
        # Override with environment variables if available
        self.database_url = os.getenv("DATABASE_URL", self.database_url)
        self.redis_url = os.getenv("REDIS_URL", self.redis_url)
        self.secret_key = os.getenv("SECRET_KEY", self.secret_key)
        self.jwt_secret_key = os.getenv("JWT_SECRET_KEY", self.jwt_secret_key)
        self.debug = os.getenv("DEBUG", "true").lower() == "true"
        self.log_level = os.getenv("LOG_LEVEL", self.log_level)


def get_settings() -> Settings:
    """Get application settings"""
    return Settings()


# Feature flag helpers
def is_feature_enabled(feature_name: str) -> bool:
    """Check if a feature flag is enabled"""
    settings = get_settings()
    return getattr(settings, f"enable_{feature_name}", False)
