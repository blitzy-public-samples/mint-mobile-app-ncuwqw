"""
Validation utilities for Mint Replica Lite backend application.

Human Tasks:
1. Review email validation patterns with security team
2. Confirm financial amount validation ranges with business requirements
3. Verify date range limits align with data retention policies
4. Test pagination limits under production load
"""

# Library versions:
# re: ^3.9.0
# typing: ^3.9.0
# pydantic: ^1.8.2
# email_validator: ^1.1.3
# decimal: ^3.9.0

import re
from datetime import datetime, timedelta
from decimal import Decimal, InvalidOperation
from functools import wraps
from typing import Tuple, Type, Callable, Any

from email_validator import validate_email as validate_email_format, EmailNotValidError
from pydantic import BaseModel

from ..core.errors import ValidationError
from ..constants import (
    PASSWORD_MIN_LENGTH,
    TRANSACTION_PAGE_SIZE,
    MAX_PAGE_SIZE
)

def validate_email(email: str) -> bool:
    """
    Validates email address format and structure.
    
    Requirement: Input Validation - Server-side validation to prevent injection attacks
    """
    if not email or not isinstance(email, str):
        raise ValidationError("Email address is required")
    
    # Remove leading/trailing whitespace
    email = email.strip()
    
    # Check for common injection patterns
    if re.search(r'[<>{}()/\\]', email):
        raise ValidationError("Email contains invalid characters")
    
    try:
        # Validate email format using email-validator library
        validate_email_format(email, check_deliverability=False)
        return True
    except EmailNotValidError as e:
        raise ValidationError(f"Invalid email format: {str(e)}")

def validate_password(password: str) -> bool:
    """
    Validates password strength and security requirements.
    
    Requirement: Security Validation - Validation of sensitive financial and personal data
    """
    if not password or not isinstance(password, str):
        raise ValidationError("Password is required")
    
    if len(password) < PASSWORD_MIN_LENGTH:
        raise ValidationError(f"Password must be at least {PASSWORD_MIN_LENGTH} characters long")
    
    # Check for required character types
    if not re.search(r'[A-Z]', password):
        raise ValidationError("Password must contain at least one uppercase letter")
    
    if not re.search(r'[a-z]', password):
        raise ValidationError("Password must contain at least one lowercase letter")
    
    if not re.search(r'\d', password):
        raise ValidationError("Password must contain at least one number")
    
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        raise ValidationError("Password must contain at least one special character")
    
    return True

def validate_amount(amount: Decimal) -> bool:
    """
    Validates financial amount format and range.
    
    Requirement: Financial Data Validation - Validation for financial transactions and account data
    """
    if amount is None:
        raise ValidationError("Amount is required")
    
    try:
        # Ensure amount is a valid decimal
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount))
        
        # Check decimal places
        decimal_places = abs(amount.as_tuple().exponent)
        if decimal_places > 2:
            raise ValidationError("Amount cannot have more than 2 decimal places")
        
        # Validate amount range
        if amount < Decimal('0.01'):
            raise ValidationError("Amount must be at least 0.01")
        
        if amount > Decimal('999999999.99'):
            raise ValidationError("Amount exceeds maximum allowed value")
        
        return True
    except InvalidOperation:
        raise ValidationError("Invalid amount format")

def validate_pagination_params(page: int, page_size: int) -> Tuple[int, int]:
    """
    Validates pagination parameters.
    
    Requirement: Input Validation - Server-side validation to prevent injection attacks
    """
    if not isinstance(page, int) or page < 1:
        raise ValidationError("Page number must be a positive integer")
    
    if not isinstance(page_size, int) or page_size < 1:
        page_size = TRANSACTION_PAGE_SIZE
    
    # Enforce maximum page size
    if page_size > MAX_PAGE_SIZE:
        page_size = MAX_PAGE_SIZE
    
    return page, page_size

def validate_date_range(start_date: datetime, end_date: datetime) -> bool:
    """
    Validates date range for financial queries.
    
    Requirement: Financial Data Validation - Validation for financial transactions and account data
    """
    if not start_date or not end_date:
        raise ValidationError("Both start date and end date are required")
    
    if not isinstance(start_date, datetime) or not isinstance(end_date, datetime):
        raise ValidationError("Invalid date format")
    
    if start_date > end_date:
        raise ValidationError("Start date cannot be after end date")
    
    # Validate maximum date range (e.g., 2 years)
    max_range = timedelta(days=730)
    if end_date - start_date > max_range:
        raise ValidationError("Date range cannot exceed 2 years")
    
    return True

def validate_request(model: Type[BaseModel]) -> Callable:
    """
    Decorator for validating API request data using Pydantic models.
    
    Requirement: Input Validation - Server-side validation to prevent injection attacks
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                # Extract request data from kwargs
                request_data = kwargs.get('data') or kwargs.get('request_data')
                if not request_data:
                    raise ValidationError("Request data is required")
                
                # Validate against Pydantic model
                validated_data = model.parse_obj(request_data)
                
                # Update kwargs with validated data
                kwargs['validated_data'] = validated_data
                return await func(*args, **kwargs)
            except Exception as e:
                raise ValidationError(f"Request validation failed: {str(e)}")
        return wrapper
    return decorator