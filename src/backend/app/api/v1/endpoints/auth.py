"""
Authentication endpoints for Mint Replica Lite API.

Human Tasks:
1. Configure CORS settings for allowed origins in production
2. Review and adjust token expiration times for production
3. Set up rate limiting for authentication endpoints
4. Configure secure cookie settings for production (domain, secure, samesite)
5. Set up monitoring for failed login attempts
"""

# fastapi: ^0.95.0
# sqlalchemy: ^1.4.0

from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status, Response, Cookie
from fastapi.security import SecurityScopes
from sqlalchemy.orm import Session

from ....core.auth import (
    create_access_token,
    create_refresh_token,
    verify_token,
    get_current_user
)
from ....services.auth_service import AuthService
from ....schemas.auth import (
    TokenPayload,
    Token,
    UserLogin,
    UserRegister,
    TokenRefresh,
    PasswordReset,
    PasswordUpdate
)

# Initialize router with prefix and tags
router = APIRouter(prefix='/auth', tags=['Authentication'])

@router.post('/register', response_model=Token, status_code=status.HTTP_201_CREATED)
async def register_user(
    user_data: UserRegister,
    auth_service: AuthService,
    db: Session
) -> Token:
    """
    Register a new user account with email verification.
    
    Requirements addressed:
    - Multi-platform Authentication (1.2 Scope/Account Management)
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    try:
        # Create new user account
        user = auth_service.create_user(user_data)
        
        # Generate tokens for automatic login
        token_data = {"sub": str(user.id)}
        access_token = create_access_token(token_data)
        refresh_token = create_refresh_token(token_data)
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token
        )
        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating user account"
        )

@router.post('/login', response_model=Token)
async def login(
    credentials: UserLogin,
    auth_service: AuthService,
    response: Response
) -> Token:
    """
    Authenticate user and issue JWT tokens.
    
    Requirements addressed:
    - Authentication Flow (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    try:
        # Authenticate user and generate tokens
        tokens = auth_service.login(credentials)
        
        # Set refresh token in HTTP-only cookie
        response.set_cookie(
            key="refresh_token",
            value=tokens.refresh_token,
            httponly=True,
            secure=True,  # Requires HTTPS
            samesite="lax",
            max_age=30 * 24 * 60 * 60  # 30 days
        )
        
        return tokens
        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )

@router.post('/refresh', response_model=Token)
async def refresh_token(
    refresh: TokenRefresh = None,
    refresh_token: str = Cookie(None),
    auth_service: AuthService = None,
    response: Response = None
) -> Token:
    """
    Refresh access token using refresh token from cookie or request body.
    
    Requirements addressed:
    - Authentication Flow (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    # Get refresh token from cookie or request body
    token = refresh_token or (refresh and refresh.refresh_token)
    
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Refresh token required"
        )
    
    try:
        # Generate new token pair
        tokens = auth_service.refresh_token(token)
        
        # Update refresh token cookie
        response.set_cookie(
            key="refresh_token",
            value=tokens.refresh_token,
            httponly=True,
            secure=True,
            samesite="lax",
            max_age=30 * 24 * 60 * 60
        )
        
        return tokens
        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )

@router.post('/logout')
async def logout(
    response: Response,
    _: Dict[str, Any] = Depends(get_current_user)
) -> Dict[str, str]:
    """
    Logout user and invalidate tokens.
    
    Requirements addressed:
    - Authentication Flow (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    """
    # Clear authentication cookies
    response.delete_cookie(
        key="refresh_token",
        httponly=True,
        secure=True,
        samesite="lax"
    )
    
    return {"message": "Successfully logged out"}

@router.post('/password-reset')
async def reset_password(
    reset_data: PasswordReset,
    auth_service: AuthService
) -> Dict[str, str]:
    """
    Initiate password reset process.
    
    Requirements addressed:
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    try:
        auth_service.reset_password(reset_data.email)
        return {"message": "Password reset instructions sent if email exists"}
        
    except Exception as e:
        # Return same message to prevent email enumeration
        return {"message": "Password reset instructions sent if email exists"}

@router.put('/password')
async def update_password(
    password_data: PasswordUpdate,
    auth_service: AuthService,
    current_user: Dict[str, Any] = Depends(get_current_user)
) -> Dict[str, str]:
    """
    Update user password with validation.
    
    Requirements addressed:
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    try:
        auth_service.change_password(
            user_id=current_user["sub"],
            current_password=password_data.current_password,
            new_password=password_data.new_password
        )
        return {"message": "Password updated successfully"}
        
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Password update failed"
        )