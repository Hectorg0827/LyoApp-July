# Structured Logging Configuration
import json
import logging
import logging.config
import sys
from contextvars import ContextVar
from typing import Any, Dict, Optional
from uuid import uuid4

import structlog
from structlog import configure, get_logger
from structlog.stdlib import LoggerFactory

from .config import get_settings

# Context variables for request tracking
request_id_var: ContextVar[Optional[str]] = ContextVar('request_id', default=None)
user_id_var: ContextVar[Optional[str]] = ContextVar('user_id', default=None)


def add_request_context(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Add request context to log records"""
    request_id = request_id_var.get()
    user_id = user_id_var.get()
    
    if request_id:
        event_dict['request_id'] = request_id
    if user_id:
        event_dict['user_id'] = user_id
    
    return event_dict


def pii_redactor(logger: Any, method_name: str, event_dict: Dict[str, Any]) -> Dict[str, Any]:
    """Redact PII from log records if enabled"""
    settings = get_settings()
    
    if not settings.redact_pii:
        return event_dict
    
    # List of fields that might contain PII
    pii_fields = ['email', 'password', 'phone', 'ssn', 'credit_card', 'token']
    
    def redact_value(key: str, value: Any) -> Any:
        if isinstance(value, dict):
            return {k: redact_value(k, v) for k, v in value.items()}
        elif isinstance(value, list):
            return [redact_value(key, item) for item in value]
        elif isinstance(key, str) and any(pii_field in key.lower() for pii_field in pii_fields):
            return "[REDACTED]"
        else:
            return value
    
    return {k: redact_value(k, v) for k, v in event_dict.items()}


def setup_logging() -> None:
    """Configure structured logging"""
    settings = get_settings()
    
    # Configure structlog
    if settings.structured_logging:
        configure(
            processors=[
                structlog.contextvars.merge_contextvars,
                structlog.stdlib.filter_by_level,
                structlog.stdlib.add_logger_name,
                structlog.stdlib.add_log_level,
                structlog.stdlib.PositionalArgumentsFormatter(),
                structlog.processors.StackInfoRenderer(),
                structlog.processors.format_exc_info,
                structlog.processors.UnicodeDecoder(),
                add_request_context,
                pii_redactor,
                structlog.dev.ConsoleRenderer() if settings.debug else structlog.processors.JSONRenderer(),
            ],
            wrapper_class=structlog.stdlib.BoundLogger,
            logger_factory=LoggerFactory(),
            cache_logger_on_first_use=True,
        )
    
    # Configure standard library logging
    logging_config = {
        "version": 1,
        "disable_existing_loggers": False,
        "formatters": {
            "standard": {
                "format": "%(asctime)s [%(levelname)s] %(name)s: %(message)s"
            },
            "json": {
                "()": structlog.stdlib.ProcessorFormatter,
                "processor": structlog.processors.JSONRenderer(),
            },
        },
        "handlers": {
            "default": {
                "level": settings.log_level,
                "formatter": "json" if settings.structured_logging else "standard",
                "class": "logging.StreamHandler",
                "stream": "ext://sys.stdout",
            },
        },
        "loggers": {
            "": {
                "handlers": ["default"],
                "level": settings.log_level,
                "propagate": False,
            },
            "uvicorn.error": {
                "handlers": ["default"],
                "level": "INFO",
                "propagate": False,
            },
            "uvicorn.access": {
                "handlers": ["default"],
                "level": "INFO",
                "propagate": False,
            },
        },
    }
    
    logging.config.dictConfig(logging_config)


def get_request_id() -> str:
    """Get or generate request ID"""
    request_id = request_id_var.get()
    if not request_id:
        request_id = str(uuid4())
        request_id_var.set(request_id)
    return request_id


def set_request_context(request_id: str, user_id: Optional[str] = None) -> None:
    """Set request context for logging"""
    request_id_var.set(request_id)
    if user_id:
        user_id_var.set(user_id)


def clear_request_context() -> None:
    """Clear request context"""
    request_id_var.set(None)
    user_id_var.set(None)


# Get structured logger
def get_structured_logger(name: str = None) -> Any:
    """Get structured logger instance"""
    return get_logger(name)


# Log security events
def log_security_event(event_type: str, details: Dict[str, Any], user_id: Optional[str] = None) -> None:
    """Log security-related events"""
    logger = get_structured_logger("security")
    logger.warning(
        "Security event",
        event_type=event_type,
        details=details,
        user_id=user_id or user_id_var.get(),
    )
