# External package versions:
# pydantic==1.9.0
# typing from Python 3.9+
# datetime from Python 3.9+

from datetime import datetime
from typing import Optional, Dict, UUID
from pydantic import BaseModel, Field, validator, EmailStr
from app.models.user import User

# Human Tasks:
# 1. Review password complexity requirements with security team
# 2. Configure email validation service for disposable email check
# 3. Set up monitoring for failed authentication attempts
# 4. Review token expiration policies with security team

class TokenPayload(BaseModel):
    """
    Schema for JWT token payload data.
    
    Requirements addressed:
    - Authentication Flow (6.1.1): Defines secure JWT token payload structure
    - Security Standards (6.3.1): Implements standard JWT claims
    """
    sub: UUID  # subject (user id)
    exp: Optional[datetime] = None  # expiration time
    is_refresh: Optional[bool] = False  # token type flag

class Token(BaseModel):
    """
    Schema for authentication token response.
    
    Requirements addressed:
    - Authentication Flow (6.1.1): Defines token response format
    - Security Standards (6.3.1): Implements secure token delivery
    """
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="JWT refresh token")
    token_type: str = Field(default="bearer", description="Token type")

class UserLogin(BaseModel):
    """
    Schema for user login credentials.
    
    Requirements addressed:
    - Authentication Flow (6.1.1): Defines secure login schema
    - Security Standards (6.3.1): Implements secure credential validation
    """
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password")

    @validator('password')
    def validate_password(cls, password: str) -> str:
        """Validates password length and complexity."""
        if len(password) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        if not any(c.isupper() for c in password):
            raise ValueError("Password must contain at least one uppercase letter")
            
        if not any(c.islower() for c in password):
            raise ValueError("Password must contain at least one lowercase letter")
            
        if not any(c.isdigit() for c in password):
            raise ValueError("Password must contain at least one number")
            
        if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
            raise ValueError("Password must contain at least one special character")
            
        return password

class UserRegister(BaseModel):
    """
    Schema for new user registration.
    
    Requirements addressed:
    - Account Management (1.2): Implements multi-platform user registration
    - Security Standards (6.3.1): Enforces secure registration process
    """
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password")
    first_name: str = Field(..., min_length=1, max_length=100, description="User first name")
    last_name: str = Field(..., min_length=1, max_length=100, description="User last name")

    @validator('password')
    def validate_password(cls, password: str) -> str:
        """Validates password length and complexity."""
        if len(password) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        if not any(c.isupper() for c in password):
            raise ValueError("Password must contain at least one uppercase letter")
            
        if not any(c.islower() for c in password):
            raise ValueError("Password must contain at least one lowercase letter")
            
        if not any(c.isdigit() for c in password):
            raise ValueError("Password must contain at least one number")
            
        if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in password):
            raise ValueError("Password must contain at least one special character")
            
        return password

    @validator('email')
    def validate_email(cls, email: str) -> str:
        """Validates email format and domain."""
        email = email.lower().strip()
        
        # Check for disposable email domains
        disposable_domains = ["tempmail.com", "throwaway.com"]  # Example list
        domain = email.split("@")[1]
        if domain in disposable_domains:
            raise ValueError("Disposable email addresses are not allowed")
            
        return email

class TokenRefresh(BaseModel):
    """
    Schema for token refresh request.
    
    Requirements addressed:
    - Authentication Flow (6.1.1): Implements secure token refresh
    - Security Standards (6.3.1): Maintains secure session management
    """
    refresh_token: str = Field(..., description="JWT refresh token")

class PasswordReset(BaseModel):
    """
    Schema for password reset request.
    
    Requirements addressed:
    - Account Management (1.2): Implements secure password reset
    - Security Standards (6.3.1): Ensures secure password recovery
    """
    email: EmailStr = Field(..., description="User email address")

class PasswordUpdate(BaseModel):
    """
    Schema for password update.
    
    Requirements addressed:
    - Account Management (1.2): Implements secure password update
    - Security Standards (6.3.1): Enforces password security policies
    """
    current_password: str = Field(..., description="Current password")
    new_password: str = Field(..., min_length=8, description="New password")

    @validator('new_password')
    def validate_new_password(cls, new_password: str) -> str:
        """Validates new password requirements."""
        if len(new_password) < 8:
            raise ValueError("Password must be at least 8 characters long")
        
        if not any(c.isupper() for c in new_password):
            raise ValueError("Password must contain at least one uppercase letter")
            
        if not any(c.islower() for c in new_password):
            raise ValueError("Password must contain at least one lowercase letter")
            
        if not any(c.isdigit() for c in new_password):
            raise ValueError("Password must contain at least one number")
            
        if not any(c in "!@#$%^&*()_+-=[]{}|;:,.<>?" for c in new_password):
            raise ValueError("Password must contain at least one special character")
            
        return new_password