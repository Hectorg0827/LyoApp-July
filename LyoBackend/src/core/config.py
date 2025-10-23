# Core Configuration Module
from functools import lru_cache
from typing import Any, Dict, List, Optional

try:
    from pydantic_settings import BaseSettings
    from pydantic import validator
except ImportError:
    # Fallback for older pydantic versions
    from pydantic import BaseSettings, validator
    
from decouple import config


class Settings(BaseSettings):
    """Application settings with environment variable support"""
    
    # Core
    app_name: str = "LyoApp Backend"
    version: str = "1.0.0"
    debug: bool = config("DEBUG", default=False, cast=bool)
    testing: bool = config("TESTING", default=False, cast=bool)
    secret_key: str = config("SECRET_KEY")
    
    # Database
    database_url: str = config("DATABASE_URL")
    db_pool_size: int = config("DB_POOL_SIZE", default=20, cast=int)
    db_max_overflow: int = config("DB_MAX_OVERFLOW", default=30, cast=int)
    
    # Redis
    redis_url: str = config("REDIS_URL")
    
    # JWT
    jwt_secret_key: str = config("JWT_SECRET_KEY")
    jwt_algorithm: str = config("JWT_ALGORITHM", default="HS256")
    access_token_expire_minutes: int = config("ACCESS_TOKEN_EXPIRE_MINUTES", default=30, cast=int)
    refresh_token_expire_days: int = config("REFRESH_TOKEN_EXPIRE_DAYS", default=30, cast=int)
    
    # Google Cloud
    google_cloud_project: str = config("GOOGLE_CLOUD_PROJECT", default="")
    gcs_bucket_name: str = config("GCS_BUCKET_NAME", default="")
    google_application_credentials: str = config("GOOGLE_APPLICATION_CREDENTIALS", default="")
    
    # Google Cloud Storage
    GCS_BUCKET_NAME: str = "lyoapp-media"
    GOOGLE_APPLICATION_CREDENTIALS: Optional[str] = None
    
    # External APIs
    OPENAI_API_KEY: Optional[str] = None
    openai_model: str = config("OPENAI_MODEL", default="gpt-4-turbo-preview")
    
    # Google Gemini AI
    gemini_api_key: Optional[str] = config("GEMINI_API_KEY", default=None)
    gemini_model: str = config("GEMINI_MODEL", default="gemini-1.5-flash")
    
    # Feature Flags
    enable_enhanced_ranking: bool = config("ENABLE_ENHANCED_RANKING", default=False, cast=bool)
    enable_exploration: bool = config("ENABLE_EXPLORATION", default=False, cast=bool)
    enable_gamification: bool = config("ENABLE_GAMIFICATION", default=True, cast=bool)
    enable_moderation_auto_action: bool = config("ENABLE_MODERATION_AUTO_ACTION", default=False, cast=bool)
    
    # Rate Limiting (requests per minute)
    rate_limit_auth: int = config("RATE_LIMIT_AUTH", default=60, cast=int)
    rate_limit_ai: int = config("RATE_LIMIT_AI", default=30, cast=int)
    rate_limit_posting: int = config("RATE_LIMIT_POSTING", default=20, cast=int)
    rate_limit_messaging: int = config("RATE_LIMIT_MESSAGING", default=100, cast=int)
    rate_limit_search: int = config("RATE_LIMIT_SEARCH", default=60, cast=int)
    
    # Logging
    log_level: str = config("LOG_LEVEL", default="INFO")
    structured_logging: bool = config("STRUCTURED_LOGGING", default=True, cast=bool)
    redact_pii: bool = config("REDACT_PII", default=True, cast=bool)
    
    # Celery
    celery_broker_url: str = config("CELERY_BROKER_URL", default="redis://localhost:6379/1")
    celery_result_backend: str = config("CELERY_RESULT_BACKEND", default="redis://localhost:6379/2")
    
    # CORS
    cors_origins: List[str] = config(
        "CORS_ORIGINS", 
        default="http://localhost:3000,https://lyoapp.com",
        cast=lambda v: [s.strip() for s in v.split(',')]
    )
    cors_allow_credentials: bool = config("CORS_ALLOW_CREDENTIALS", default=True, cast=bool)
    
    # Pagination
    default_page_size: int = config("DEFAULT_PAGE_SIZE", default=20, cast=int)
    max_page_size: int = config("MAX_PAGE_SIZE", default=100, cast=int)
    
    # Media
    max_file_size_mb: int = config("MAX_FILE_SIZE_MB", default=100, cast=int)
    allowed_media_types: List[str] = config(
        "ALLOWED_MEDIA_TYPES",
        default="image/jpeg,image/png,image/webp,video/mp4,video/quicktime",
        cast=lambda v: [s.strip() for s in v.split(',')]
    )
    
    # WebSocket
    ws_max_connections_per_user: int = config("WS_MAX_CONNECTIONS_PER_USER", default=3, cast=int)
    ws_message_rate_limit: int = config("WS_MESSAGE_RATE_LIMIT", default=60, cast=int)
    
    # Push Notifications
    apns_key_id: str = config("APNS_KEY_ID", default="")
    apns_team_id: str = config("APNS_TEAM_ID", default="")
    apns_bundle_id: str = config("APNS_BUNDLE_ID", default="com.lyoapp.ios")
    fcm_project_id: str = config("FCM_PROJECT_ID", default="")
    
    @validator("cors_origins", pre=True)
    def assemble_cors_origins(cls, v: Any) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, (list, str)):
            return v
        raise ValueError(v)
    
    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    """Get cached application settings"""
    return Settings()


# Feature flag helpers
def is_feature_enabled(feature_name: str) -> bool:
    """Check if a feature flag is enabled"""
    settings = get_settings()
    return getattr(settings, f"enable_{feature_name}", False)


def get_rate_limit(endpoint: str) -> int:
    """Get rate limit for specific endpoint"""
    settings = get_settings()
    return getattr(settings, f"rate_limit_{endpoint}", 60)
