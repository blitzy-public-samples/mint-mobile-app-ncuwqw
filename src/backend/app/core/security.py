"""
Core security module implementing authentication, authorization, encryption, and security protocols.

Human Tasks:
1. Review and validate JWT token expiration times for production environment
2. Ensure SECRET_KEY meets minimum length and complexity requirements
3. Verify ALGORITHM selection meets security requirements
4. Confirm password hashing configuration aligns with security standards
"""

# python-jwt: ^2.6.0
# datetime: ^3.9+
# typing: ^3.9+

from datetime import datetime, timedelta
from typing import Dict, Any, Optional

import jwt

from ..utils.crypto import hash_password, verify_password, generate_token
from .config import SECRET_KEY

# Global constants for token configuration
ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
REFRESH_TOKEN_EXPIRE_DAYS: int = 7
ALGORITHM: str = 'HS256'

def create_access_token(data: Dict[str, Any], expires_delta: Optional[datetime] = None) -> str:
    """
    Creates a JWT access token for authenticated users with configurable expiration.
    
    Requirement: Authentication Flow - 6.1.1 Authentication Flow
    Implementation of secure JWT token generation with expiration handling.
    
    Args:
        data: Payload data to encode in token
        expires_delta: Optional custom expiration time
        
    Returns:
        Encoded JWT access token string
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({
        "exp": expire,
        "type": "access"
    })
    
    # Requirement: Data Security - 6.2.1 Encryption Implementation
    # Encode token with HS256 algorithm and SECRET_KEY
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: Dict[str, Any]) -> str:
    """
    Creates a JWT refresh token for token renewal with fixed expiration.
    
    Requirement: Authentication Flow - 6.1.1 Authentication Flow
    Implementation of refresh token mechanism for token renewal.
    
    Args:
        data: Payload data to encode in token
        
    Returns:
        Encoded JWT refresh token string
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })
    
    # Requirement: Data Security - 6.2.1 Encryption Implementation
    # Encode refresh token with HS256 algorithm and SECRET_KEY
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Dict[str, Any]:
    """
    Verifies and decodes a JWT token, checking signature and expiration.
    
    Requirement: Security Standards - 6.3.1 Security Standards Compliance
    Implementation of secure token validation following OWASP guidelines.
    
    Args:
        token: JWT token string to verify
        
    Returns:
        Decoded token payload if valid
        
    Raises:
        jwt.InvalidTokenError: If token is invalid or expired
    """
    try:
        # Requirement: Data Security - 6.2.1 Encryption Implementation
        # Verify and decode token using SECRET_KEY
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise jwt.InvalidTokenError("Token has expired")
    except jwt.InvalidTokenError:
        raise jwt.InvalidTokenError("Invalid token")

def get_password_hash(password: str) -> str:
    """
    Creates a password hash using bcrypt with configurable rounds.
    
    Requirement: Data Security - 6.2.2 Sensitive Data Handling
    Implementation of secure password hashing using bcrypt.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Bcrypt hashed password string
    """
    return hash_password(password)

def verify_password_hash(plain_password: str, hashed_password: str) -> bool:
    """
    Verifies a password against its bcrypt hash.
    
    Requirement: Data Security - 6.2.2 Sensitive Data Handling
    Implementation of secure password verification.
    
    Args:
        plain_password: Plain text password to verify
        hashed_password: Bcrypt hash to verify against
        
    Returns:
        True if password matches hash, False otherwise
    """
    return verify_password(plain_password, hashed_password)