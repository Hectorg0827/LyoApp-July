"""Core exception classes for the application"""

from typing import Any, Dict, Optional


class LyoAppException(Exception):
    """Base exception for all LyoApp exceptions"""
    
    def __init__(
        self,
        message: str,
        status_code: int = 500,
        details: Optional[Dict[str, Any]] = None
    ):
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        super().__init__(self.message)


class AuthenticationError(LyoAppException):
    """Raised when authentication fails"""
    
    def __init__(self, message: str = "Authentication failed", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=401, details=details)


class AuthorizationError(LyoAppException):
    """Raised when user lacks permission"""
    
    def __init__(self, message: str = "Permission denied", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=403, details=details)


class NotFoundError(LyoAppException):
    """Raised when a resource is not found"""
    
    def __init__(self, message: str = "Resource not found", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=404, details=details)


class ValidationError(LyoAppException):
    """Raised when validation fails"""
    
    def __init__(self, message: str = "Validation error", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=422, details=details)


class BusinessLogicError(LyoAppException):
    """Raised when business logic rules are violated"""
    
    def __init__(self, message: str = "Business logic error", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=400, details=details)


class ConflictError(LyoAppException):
    """Raised when there's a conflict with existing data"""
    
    def __init__(self, message: str = "Resource conflict", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=409, details=details)


class RateLimitError(LyoAppException):
    """Raised when rate limit is exceeded"""
    
    def __init__(self, message: str = "Rate limit exceeded", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=429, details=details)


class ServiceUnavailableError(LyoAppException):
    """Raised when a required service is unavailable"""
    
    def __init__(self, message: str = "Service temporarily unavailable", details: Optional[Dict[str, Any]] = None):
        super().__init__(message=message, status_code=503, details=details)
