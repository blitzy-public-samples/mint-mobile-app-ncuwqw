"""
Core logging module for Mint Replica Lite backend application.

Human Tasks:
1. Configure ELK Stack (Elasticsearch, Logstash, Kibana) in production environment
2. Set up log rotation directory permissions
3. Verify network access for ELK Stack integration
4. Review and adjust log retention policies based on compliance requirements
"""

# Library versions:
# logging: ^3.9.0
# structlog: ^21.1.0
# typing: ^3.9.0

import json
import logging
import logging.handlers
from typing import Any, Dict, List, Optional

import structlog
from structlog.processors import JSONRenderer, TimeStamper

from ..core.config import ENVIRONMENT

# Global Constants
DEFAULT_LOG_FORMAT = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
JSON_LOG_FORMAT = '%(timestamp)s %(level)s %(name)s %(message)s'
MAX_BYTES = 10485760  # 10MB
BACKUP_COUNT = 5

class ContextLogger:
    """
    Custom logger class that adds context and structured logging capabilities.
    Integrates with ELK Stack in production and provides readable console output in development.

    Requirement: System Monitoring - Implement comprehensive logging with ELK Stack
    """

    def __init__(self) -> None:
        self.context: Dict[str, Any] = {}
        self._logger = structlog.get_logger()
        
        # Configure processors based on environment
        processors = [
            structlog.stdlib.add_log_level,
            structlog.stdlib.add_logger_name,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
        ]

        if ENVIRONMENT == "production":
            # JSON formatting for ELK Stack integration
            processors.extend([
                structlog.processors.format_exc_info,
                structlog.processors.UnicodeDecoder(),
                JSONRenderer(serializer=json.dumps)
            ])
        else:
            # Human-readable format for development
            processors.append(
                structlog.dev.ConsoleRenderer(colors=True)
            )

        structlog.configure(
            processors=processors,
            context_class=dict,
            logger_factory=structlog.stdlib.LoggerFactory(),
            wrapper_class=structlog.stdlib.BoundLogger,
            cache_logger_on_first_use=True,
        )

    def bind(self, context: Dict[str, Any]) -> 'ContextLogger':
        """
        Bind additional context to logger instance for structured logging.
        
        Requirement: Security Logging - Implement audit logging for comprehensive events tracking
        """
        new_logger = ContextLogger()
        new_logger.context = {**self.context, **context}
        
        # Validate context values are JSON serializable
        try:
            json.dumps(new_logger.context)
        except TypeError as e:
            raise ValueError(f"Context values must be JSON serializable: {e}")
            
        return new_logger

    def unbind(self, keys: List[str]) -> 'ContextLogger':
        """
        Remove specified keys from logger context.
        
        Requirement: Security Logging - Implement audit logging for comprehensive events tracking
        """
        new_logger = ContextLogger()
        new_logger.context = self.context.copy()
        for key in keys:
            new_logger.context.pop(key, None)
        return new_logger


def setup_logging(log_level: str, log_file_path: Optional[str] = None) -> None:
    """
    Configure application-wide logging settings with environment-specific handlers.
    
    Requirement: System Monitoring - Implement comprehensive logging with ELK Stack
    Requirement: Error Tracking - Implement error handling with generic error messages
    """
    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    # Clear any existing handlers
    root_logger.handlers = []

    # Configure formatters
    if ENVIRONMENT == "production":
        formatter = logging.Formatter(JSON_LOG_FORMAT)
    else:
        formatter = logging.Formatter(DEFAULT_LOG_FORMAT)

    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    # File handler with rotation if path provided
    if log_file_path:
        file_handler = logging.handlers.RotatingFileHandler(
            filename=log_file_path,
            maxBytes=MAX_BYTES,
            backupCount=BACKUP_COUNT,
            encoding='utf-8'
        )
        file_handler.setFormatter(formatter)
        root_logger.addHandler(file_handler)

    # Configure structlog
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.stdlib.render_to_log_kwargs,
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )


def get_logger(name: str) -> ContextLogger:
    """
    Get a configured logger instance for a specific module with environment-specific settings.
    
    Requirement: System Monitoring - Implement comprehensive logging with ELK Stack
    """
    logger = ContextLogger()
    
    # Add environment-specific context
    context = {
        "module": name,
        "environment": ENVIRONMENT,
    }
    
    if ENVIRONMENT == "production":
        # Add additional context for ELK Stack
        context.update({
            "app": "mint_replica_lite",
            "version": "1.0",
        })
    
    return logger.bind(context)