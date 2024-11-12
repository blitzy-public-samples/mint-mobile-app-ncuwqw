"""
Core module initialization file that exports essential components for authentication, caching, and security.

Human Tasks:
1. Review and validate Redis configuration in production environment
2. Verify JWT token expiration settings for production use
3. Ensure security components meet production security standards
4. Configure monitoring for cache and authentication services
"""

# Import authentication components
# Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
from .auth import (
    create_access_token,
    create_refresh_token,
    verify_token,
    get_current_user
)

# Import caching infrastructure
# Requirement: Cache Management - 2. System Architecture/2.1 High-Level Architecture Overview/Data Layer
from .cache import (
    RedisCache,
    cache
)

# Import security components
# Requirement: Security Implementation - 6.2 Data Security/6.2.1 Encryption Implementation
from .security import (
    get_password_hash,
    verify_password_hash
)

# Export all required components
__all__ = [
    # Authentication exports
    'create_access_token',
    'create_refresh_token',
    'verify_token',
    'get_current_user',
    
    # Cache exports
    'RedisCache',
    'cache',
    
    # Security exports
    'get_password_hash',
    'verify_password_hash'
]