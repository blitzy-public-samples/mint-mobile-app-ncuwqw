"""
Core authentication module for Mint Replica Lite backend application.

Human Tasks:
1. Review and validate JWT token expiration times for production environment
2. Configure secure cookie settings in production (secure, samesite, domain)
3. Verify CORS settings for allowed origins in production
4. Review and update security scopes for role-based access control
"""

# python-jwt: ^2.6.0
# fastapi: ^0.95.0

from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import jwt
from fastapi import HTTPException, Request
from fastapi.security import SecurityScopes, HTTPBearer
from fastapi.security.utils import get_authorization_scheme_param

from ..core.config import get_settings, SECRET_KEY
from ..utils.crypto import hash_password, verify_password

# Global constants for token management
# Requirement: Session Management - 6.3 Security Controls/6.3.3 Security Controls
ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440  # 24 hours
REFRESH_TOKEN_EXPIRE_DAYS: int = 30
ALGORITHM: str = 'HS256'

class OAuth2PasswordBearerWithCookie(HTTPBearer):
    """
    Custom OAuth2 scheme supporting both header and cookie-based authentication.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    
    def __init__(
        self,
        tokenUrl: str,
        scheme_name: Optional[str] = None,
        scopes: Optional[List[str]] = None
    ):
        super().__init__(auto_error=True)
        self.token_type = "bearer"
        self.scheme_name = scheme_name or self.__class__.__name__
        self.scopes = scopes or {}
        self.tokenUrl = tokenUrl

    async def __call__(self, request: Request) -> str:
        """
        Extract and validate bearer token from request.
        
        Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
        """
        # First try to get token from authorization header
        authorization = request.headers.get("Authorization")
        scheme, token = get_authorization_scheme_param(authorization)
        
        # If not in header, try to get from cookies
        if not token:
            token = request.cookies.get("access_token")
        
        if not token:
            raise HTTPException(
                status_code=401,
                detail="Not authenticated",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        # Validate bearer scheme if from header
        if authorization and scheme.lower() != "bearer":
            raise HTTPException(
                status_code=401,
                detail="Invalid authentication scheme",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        return token

# Initialize OAuth2 scheme
oauth2_scheme = OAuth2PasswordBearerWithCookie(tokenUrl='api/v1/auth/login')

def create_access_token(
    data: Dict[str, Any],
    expires_delta: Optional[timedelta] = None
) -> str:
    """
    Create JWT access token with specified payload and expiration.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
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
    
    settings = get_settings()
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=ALGORITHM
    )
    
    return encoded_jwt

def create_refresh_token(data: Dict[str, Any]) -> str:
    """
    Create JWT refresh token for token renewal.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    
    to_encode.update({
        "exp": expire,
        "type": "refresh"
    })
    
    settings = get_settings()
    encoded_jwt = jwt.encode(
        to_encode,
        settings.SECRET_KEY,
        algorithm=ALGORITHM
    )
    
    return encoded_jwt

def verify_token(
    token: str,
    required_scopes: Optional[List[str]] = None
) -> Dict[str, Any]:
    """
    Verify and decode JWT token, optionally checking required scopes.
    
    Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
    """
    try:
        settings = get_settings()
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[ALGORITHM]
        )
        
        # Verify token type
        token_type = payload.get("type")
        if not token_type:
            raise HTTPException(
                status_code=401,
                detail="Invalid token type",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        # Verify scopes if required
        if required_scopes:
            token_scopes = payload.get("scopes", [])
            for scope in required_scopes:
                if scope not in token_scopes:
                    raise HTTPException(
                        status_code=403,
                        detail=f"Missing required scope: {scope}",
                        headers={"WWW-Authenticate": "Bearer"},
                    )
                    
        return payload
        
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=401,
            detail="Token has expired",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=401,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

async def get_current_user(
    security_scopes: SecurityScopes,
    token: str
) -> Dict[str, Any]:
    """
    Dependency function to get current authenticated user from token.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    # Verify token and scopes
    payload = verify_token(token, security_scopes.scopes)
    
    # Extract user information
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
        
    # Additional user validation could be added here
    # For example, checking if user is still active in database
    
    return payload