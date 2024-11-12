"""
Security utility module for Mint Replica Lite system.

Human Tasks:
1. Review and validate JWT secret key configuration in production environment
2. Ensure token expiry settings align with security policies
3. Verify token encryption algorithm meets security standards
4. Confirm token validation rules comply with security requirements
"""

# python-jwt: ^2.6.0
# typing: ^3.9.0
# secrets: ^3.9.0
# datetime: ^3.9.0

import jwt
import secrets
from datetime import datetime, timedelta
from typing import Dict, Any, Union, Optional

from app.utils.crypto import hash_password, verify_password, generate_key
from app.constants import ENCRYPTION_ALGORITHM

# Token type constants
# Requirement: Authentication Flow - 6.1.1 Authentication Flow
TOKEN_TYPE_ACCESS: str = 'access'
TOKEN_TYPE_REFRESH: str = 'refresh'

# Token expiry settings
# Requirement: Security Standards - 6.3.1 Security Standards Compliance
TOKEN_EXPIRY_ACCESS_MINUTES: int = 30
TOKEN_EXPIRY_REFRESH_DAYS: int = 7
SECURE_HASH_ALGORITHM: str = 'HS256'

def generate_secure_token(length: int) -> str:
    """
    Requirement: Security Standards - 6.3.1 Security Standards Compliance
    Generates a cryptographically secure random token.

    Args:
        length: Desired length of the token

    Returns:
        Secure URL-safe token string

    Raises:
        ValueError: If length is not positive
    """
    if length <= 0:
        raise ValueError("Token length must be positive")
    return secrets.token_urlsafe(length)

def create_jwt_token(claims: Dict[str, Any], token_type: str, expires_delta: Optional[timedelta] = None) -> str:
    """
    Requirement: Authentication Flow - 6.1.1 Authentication Flow
    Creates a JWT token with specified claims and expiry.

    Args:
        claims: Dictionary of claims to include in token
        token_type: Type of token (access or refresh)
        expires_delta: Optional custom expiration time

    Returns:
        Encoded JWT token string

    Raises:
        ValueError: If invalid token type provided
    """
    if token_type not in [TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH]:
        raise ValueError("Invalid token type")

    # Calculate expiration time
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        if token_type == TOKEN_TYPE_ACCESS:
            expire = datetime.utcnow() + timedelta(minutes=TOKEN_EXPIRY_ACCESS_MINUTES)
        else:
            expire = datetime.utcnow() + timedelta(days=TOKEN_EXPIRY_REFRESH_DAYS)

    # Add standard claims
    token_claims = claims.copy()
    token_claims.update({
        'exp': expire,
        'iat': datetime.utcnow(),
        'type': token_type
    })

    # Generate token
    return jwt.encode(
        token_claims,
        generate_key(32),  # Generate secure key for signing
        algorithm=SECURE_HASH_ALGORITHM
    )

def verify_jwt_token(token: str) -> Dict[str, Any]:
    """
    Requirement: Authentication Flow - 6.1.1 Authentication Flow
    Verifies and decodes a JWT token.

    Args:
        token: JWT token to verify

    Returns:
        Dictionary of decoded token claims

    Raises:
        jwt.InvalidTokenError: If token is invalid
        jwt.ExpiredSignatureError: If token has expired
    """
    try:
        decoded_token = jwt.decode(
            token,
            generate_key(32),  # Use same key generation for verification
            algorithms=[SECURE_HASH_ALGORITHM]
        )
        
        # Verify required claims
        if 'type' not in decoded_token:
            raise jwt.InvalidTokenError("Token type claim missing")
        if decoded_token['type'] not in [TOKEN_TYPE_ACCESS, TOKEN_TYPE_REFRESH]:
            raise jwt.InvalidTokenError("Invalid token type")
            
        return decoded_token
    except jwt.ExpiredSignatureError:
        raise jwt.ExpiredSignatureError("Token has expired")
    except jwt.InvalidTokenError as e:
        raise jwt.InvalidTokenError(f"Invalid token: {str(e)}")

def hash_data(data: Union[str, bytes]) -> str:
    """
    Requirement: Data Security - 6.2.1 Encryption Implementation
    Creates a secure hash of the provided data.

    Args:
        data: Data to hash (string or bytes)

    Returns:
        Secure hash string
    """
    if isinstance(data, str):
        data = data.encode('utf-8')
    return hash_password(data).hex()

class TokenManager:
    """
    Requirement: Authentication Flow - 6.1.1 Authentication Flow
    Manages JWT token generation and validation with secure key handling.
    """

    def __init__(self, secret_key: str, algorithm: Optional[str] = None):
        """
        Initialize token manager with secret key and algorithm.

        Args:
            secret_key: Secret key for token signing
            algorithm: Optional custom algorithm (defaults to SECURE_HASH_ALGORITHM)
        """
        self._secret_key = secret_key
        self._algorithm = algorithm or SECURE_HASH_ALGORITHM

    def create_access_token(self, user_claims: Dict[str, Any]) -> str:
        """
        Creates an access token for a user.

        Args:
            user_claims: User-specific claims to include in token

        Returns:
            JWT access token
        """
        claims = user_claims.copy()
        claims['token_type'] = TOKEN_TYPE_ACCESS
        return create_jwt_token(
            claims,
            TOKEN_TYPE_ACCESS,
            timedelta(minutes=TOKEN_EXPIRY_ACCESS_MINUTES)
        )

    def create_refresh_token(self, user_claims: Dict[str, Any]) -> str:
        """
        Creates a refresh token for a user.

        Args:
            user_claims: User-specific claims to include in token

        Returns:
            JWT refresh token
        """
        claims = user_claims.copy()
        claims['token_type'] = TOKEN_TYPE_REFRESH
        return create_jwt_token(
            claims,
            TOKEN_TYPE_REFRESH,
            timedelta(days=TOKEN_EXPIRY_REFRESH_DAYS)
        )

    def verify_token(self, token: str) -> Dict[str, Any]:
        """
        Verifies a JWT token and returns claims.

        Args:
            token: Token to verify

        Returns:
            Dictionary of verified token claims

        Raises:
            jwt.InvalidTokenError: If token is invalid
        """
        return verify_jwt_token(token)