"""
Initialization module for the utils package that exports common utility functions and classes.

Human Tasks:
1. Review imported utility functions against security requirements
2. Verify cryptographic configurations in production environment
3. Confirm datetime timezone settings in deployment
4. Validate input validation rules with security policies
"""

# Import cryptographic utilities
from .crypto import (  # type: ignore
    generate_salt,
    hash_password,
    verify_password,
    generate_key,
    KeyDerivation
)

# Import datetime utilities
from .datetime import (  # type: ignore
    parse_datetime,
    format_datetime,
    get_current_datetime,
    get_date_range,
    calculate_goal_progress
)

# Import validation utilities
from .validators import (  # type: ignore
    validate_email,
    validate_password,
    validate_amount,
    validate_pagination_params,
    validate_date_range,
    validate_request
)

# Export all utility functions and classes
__all__ = [
    # Cryptographic utilities
    # Requirement: Data Security - 6.2 Data Security
    # Implement secure cryptographic operations using industry-standard algorithms
    'generate_salt',
    'hash_password',
    'verify_password',
    'generate_key',
    'KeyDerivation',
    
    # Datetime utilities
    # Requirement: Financial Tracking - 1.2 Scope/Financial Tracking
    # Support transaction date handling with standardized UTC timestamps
    'parse_datetime',
    'format_datetime',
    'get_current_datetime',
    'get_date_range',
    'calculate_goal_progress',
    
    # Validation utilities
    # Requirement: Input Validation - 6. Security Considerations/6.3.3 Security Controls
    # Implement comprehensive server-side validation for all user inputs
    'validate_email',
    'validate_password',
    'validate_amount',
    'validate_pagination_params',
    'validate_date_range',
    'validate_request'
]