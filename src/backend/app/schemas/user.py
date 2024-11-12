"""
Pydantic schemas for user data validation and serialization in the Mint Replica Lite application.

Human Tasks:
1. Review and update password complexity requirements if business needs change
2. Configure email domain allowlist/blocklist if required
3. Verify email validation service availability and credentials
"""

# pydantic: ^1.9.0
from pydantic import BaseModel, Field, EmailStr, validator
from typing import Optional
from datetime import datetime
from uuid import UUID
import re

from ..models.user import User


class UserBase(BaseModel):
    """
    Base Pydantic model for user data validation.
    
    Requirements addressed:
    - Data Validation (2.2.1): Implements comprehensive data validation for user information
    - Security Standards (6.3.1): Follows OWASP validation guidelines
    """
    email: EmailStr = Field(..., description="User's email address")
    first_name: str = Field(..., min_length=1, max_length=100, description="User's first name")
    last_name: str = Field(..., min_length=1, max_length=100, description="User's last name")
    is_active: bool = Field(default=True, description="Flag indicating if the user account is active")

    @validator('email')
    def validate_email(cls, email: str) -> str:
        """
        Validates email format and normalizes it.
        
        Requirements addressed:
        - Security Standards (6.3.1): Email validation following OWASP guidelines
        """
        # Convert to lowercase for consistency
        email = email.lower().strip()
        
        # Basic format validation is handled by EmailStr
        # Additional domain validation could be added here
        
        return email

    @validator('first_name', 'last_name')
    def validate_names(cls, v: str) -> str:
        """
        Validates and sanitizes name fields.
        
        Requirements addressed:
        - Security Standards (6.3.1): Input sanitization
        """
        v = v.strip()
        if not v:
            raise ValueError("Name fields cannot be empty")
        if not re.match(r'^[a-zA-Z\s\-\']+$', v):
            raise ValueError("Names can only contain letters, spaces, hyphens, and apostrophes")
        return v


class UserCreate(UserBase):
    """
    Schema for user creation requests.
    
    Requirements addressed:
    - Multi-platform Authentication (1.2): Consistent user creation across platforms
    - Security Standards (6.3.1): OWASP-compliant password validation
    """
    password: str = Field(
        ...,
        min_length=8,
        max_length=100,
        description="User's password (must meet complexity requirements)"
    )
    password_confirm: str = Field(..., description="Password confirmation")

    @validator('password')
    def validate_password(cls, v: str, values: dict) -> str:
        """
        Validates password strength according to OWASP standards.
        
        Requirements addressed:
        - Security Standards (6.3.1): OWASP password complexity requirements
        """
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        if not re.search(r'[A-Z]', v):
            raise ValueError("Password must contain at least one uppercase letter")
        
        if not re.search(r'[a-z]', v):
            raise ValueError("Password must contain at least one lowercase letter")
        
        if not re.search(r'\d', v):
            raise ValueError("Password must contain at least one number")
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
            raise ValueError("Password must contain at least one special character")
        
        return v

    @validator('password_confirm')
    def passwords_match(cls, v: str, values: dict) -> str:
        """
        Ensures password confirmation matches password.
        
        Requirements addressed:
        - Security Standards (6.3.1): Password confirmation validation
        """
        if 'password' in values and v != values['password']:
            raise ValueError("Passwords do not match")
        return v


class UserUpdate(BaseModel):
    """
    Schema for user update requests.
    
    Requirements addressed:
    - Data Validation (2.2.1): Validates partial user updates
    """
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    password: Optional[str] = Field(None, min_length=8, max_length=100)

    @validator('password')
    def validate_update_password(cls, v: Optional[str]) -> Optional[str]:
        """
        Validates password if provided in update.
        
        Requirements addressed:
        - Security Standards (6.3.1): Password validation for updates
        """
        if v is not None:
            if len(v) < 8:
                raise ValueError("Password must be at least 8 characters long")
            
            if not re.search(r'[A-Z]', v):
                raise ValueError("Password must contain at least one uppercase letter")
            
            if not re.search(r'[a-z]', v):
                raise ValueError("Password must contain at least one lowercase letter")
            
            if not re.search(r'\d', v):
                raise ValueError("Password must contain at least one number")
            
            if not re.search(r'[!@#$%^&*(),.?":{}|<>]', v):
                raise ValueError("Password must contain at least one special character")
        
        return v


class UserInDB(UserBase):
    """
    Schema for user data stored in database.
    
    Requirements addressed:
    - Data Validation (2.2.1): Database record validation
    """
    id: UUID
    created_at: datetime
    updated_at: datetime
    password_hash: str

    class Config:
        orm_mode = True


class UserResponse(BaseModel):
    """
    Schema for user data in API responses.
    
    Requirements addressed:
    - Multi-platform Authentication (1.2): Consistent user data representation
    - Data Validation (2.2.1): API response validation
    """
    id: UUID
    email: EmailStr
    first_name: str
    last_name: str
    is_active: bool
    created_at: datetime

    class Config:
        orm_mode = True