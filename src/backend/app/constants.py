"""
Core constants module for Mint Replica Lite backend application.

Human Tasks:
1. Ensure environment variables are properly set in deployment configurations
2. Review and adjust rate limits based on production load testing
3. Verify CORS settings match production domain requirements
4. Confirm encryption algorithm compatibility with security requirements
5. Validate JWT settings align with security policies

Library Versions:
typing: ^3.9.0
"""

from typing import List

# API Configuration
# Requirement: System Configuration - Define system-wide constants for API configuration
API_VERSION: str = 'v1'
API_PREFIX: str = '/api'
API_V1_PREFIX: str = f'{API_PREFIX}/{API_VERSION}'

# Security Settings
# Requirement: Security Standards - Define security-related constants for authentication
JWT_ALGORITHM: str = 'HS256'
ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
REFRESH_TOKEN_EXPIRE_DAYS: int = 7
PASSWORD_MIN_LENGTH: int = 8

# Database Configuration
# Requirement: Database Configuration - Define database connection constants
MAX_CONNECTIONS_COUNT: int = 10
MIN_CONNECTIONS_COUNT: int = 1

# Cache Settings
# Requirement: System Configuration - Define service component configurations
CACHE_TTL_SECONDS: int = 3600
REDIS_TTL_SECONDS: int = 3600

# Pagination Settings
# Requirement: System Configuration - Define API response standards
TRANSACTION_PAGE_SIZE: int = 50
MAX_PAGE_SIZE: int = 100

# Financial Settings
# Requirement: System Configuration - Define system-wide standards
DEFAULT_CURRENCY: str = 'USD'

# Date Format Settings
# Requirement: System Configuration - Define formatting standards
DATETIME_FORMAT: str = '%Y-%m-%dT%H:%M:%S.%fZ'
DATE_FORMAT: str = '%Y-%m-%d'

# Security and Encryption
# Requirement: Data Security - Define encryption standards
ENCRYPTION_ALGORITHM: str = 'AES-256-GCM'

# CORS Settings
# Requirement: Security Standards - Define API access controls
CORS_ORIGINS: List[str] = ['*']
CORS_METHODS: List[str] = ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
CORS_HEADERS: List[str] = ['Content-Type', 'Authorization']

# Logging Configuration
# Requirement: System Configuration - Define logging standards
LOG_LEVEL: str = 'INFO'
LOG_FORMAT: str = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'

# Rate Limiting
# Requirement: Security Standards - Define API rate limiting
RATE_LIMIT_PER_MINUTE: int = 100