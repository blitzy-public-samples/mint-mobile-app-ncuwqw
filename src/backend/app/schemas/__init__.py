"""
Central module for exporting all Pydantic schemas used in the Mint Replica Lite application.

Human Tasks:
1. Review schema exports when adding new models
2. Verify schema version compatibility when updating pydantic
3. Monitor schema validation performance in production
"""

# pydantic: ^1.9.0
from .user import (
    UserBase,
    UserCreate,
    UserUpdate,
    UserInDB,
    UserResponse
)

from .auth import (
    TokenPayload,
    Token,
    UserLogin,
    UserRegister
)

from .account import (
    AccountBase,
    AccountCreate,
    AccountUpdate,
    AccountInDB,
    AccountResponse
)

# Export all schemas for API layer usage
__all__ = [
    # User schemas
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserInDB",
    "UserResponse",
    
    # Authentication schemas
    "TokenPayload",
    "Token",
    "UserLogin",
    "UserRegister",
    
    # Account schemas
    "AccountBase", 
    "AccountCreate",
    "AccountUpdate",
    "AccountInDB",
    "AccountResponse"
]

"""
Requirements addressed:
- Data Validation (2.2.1): Centralizes schema validation for API requests and responses
- Security Standards (6.3.1): Enforces OWASP-compliant data validation through centralized schemas
- Account Management (1.2): Supports data validation for multi-platform account management
"""