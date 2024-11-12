"""
Authentication service implementing secure user authentication and token management.

Human Tasks:
1. Configure email service for password reset functionality
2. Set up rate limiting for authentication endpoints
3. Configure monitoring for failed login attempts
4. Review and update password policies periodically
"""

# fastapi: ^0.95.0
# sqlalchemy: ^1.4.0

from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from uuid import UUID
from fastapi import HTTPException
from sqlalchemy.orm import Session

from ..core.auth import create_access_token, create_refresh_token, verify_token
from ..models.user import User
from ..schemas.auth import TokenPayload, Token, UserLogin, UserRegister

class AuthService:
    """
    Service class handling user authentication, token management, and session handling.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    
    def __init__(self, db_session: Session):
        """Initialize auth service with database session."""
        self._db = db_session

    def authenticate_user(self, email: str, password: str) -> Optional[User]:
        """
        Authenticates a user with email and password.
        
        Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
        """
        # Query user by email
        user = self._db.query(User).filter(User.email == email.lower().strip()).first()
        
        if not user:
            return None
            
        # Verify password
        if not user.verify_password(password):
            return None
            
        return user

    def create_user(self, user_data: UserRegister) -> User:
        """
        Creates a new user account with validated registration data.
        
        Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
        """
        # Check if email already exists
        existing_user = self._db.query(User).filter(
            User.email == user_data.email.lower().strip()
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="Email already registered"
            )
            
        # Create new user instance
        user = User(
            email=user_data.email,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            password=user_data.password
        )
        
        # Save to database
        self._db.add(user)
        self._db.commit()
        self._db.refresh(user)
        
        return user

    def login(self, credentials: UserLogin) -> Token:
        """
        Handles user login and generates access/refresh tokens.
        
        Requirements:
        - Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
        - Session Management - 6.3 Security Controls/6.3.3 Security Controls
        """
        # Authenticate user
        user = self.authenticate_user(credentials.email, credentials.password)
        
        if not user:
            raise HTTPException(
                status_code=401,
                detail="Invalid email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        # Generate tokens
        token_data = {"sub": str(user.id)}
        
        access_token = create_access_token(token_data)
        refresh_token = create_refresh_token(token_data)
        
        return Token(
            access_token=access_token,
            refresh_token=refresh_token
        )

    def refresh_token(self, refresh_token: str) -> Token:
        """
        Refreshes access token using valid refresh token.
        
        Requirement: Session Management - 6.3 Security Controls/6.3.3 Security Controls
        """
        try:
            # Verify refresh token
            payload = verify_token(refresh_token)
            
            if not payload.get("type") == "refresh":
                raise HTTPException(
                    status_code=401,
                    detail="Invalid refresh token",
                    headers={"WWW-Authenticate": "Bearer"},
                )
                
            # Extract user ID
            user_id = payload.get("sub")
            if not user_id:
                raise HTTPException(
                    status_code=401,
                    detail="Invalid token payload",
                    headers={"WWW-Authenticate": "Bearer"},
                )
                
            # Generate new tokens
            token_data = {"sub": user_id}
            access_token = create_access_token(token_data)
            new_refresh_token = create_refresh_token(token_data)
            
            return Token(
                access_token=access_token,
                refresh_token=new_refresh_token
            )
            
        except Exception as e:
            raise HTTPException(
                status_code=401,
                detail="Could not refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )

    def reset_password(self, email: str) -> bool:
        """
        Initiates password reset process for user.
        
        Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
        """
        # Find user
        user = self._db.query(User).filter(User.email == email.lower().strip()).first()
        
        if not user:
            # Return True to prevent email enumeration
            return True
            
        # Generate reset token with 1-hour expiry
        token_data = {
            "sub": str(user.id),
            "type": "reset",
            "exp": datetime.utcnow() + timedelta(hours=1)
        }
        reset_token = create_access_token(token_data)
        
        # TODO: Send reset email with token
        # This should be implemented by the email service
        
        return True

    def change_password(self, user_id: UUID, current_password: str, new_password: str) -> bool:
        """
        Changes user password after validation.
        
        Requirement: Security Standards - 6.3 Security Protocols/6.3.1 Security Standards Compliance
        """
        # Find user
        user = self._db.query(User).filter(User.id == user_id).first()
        
        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )
            
        # Verify current password
        if not user.verify_password(current_password):
            raise HTTPException(
                status_code=401,
                detail="Invalid current password"
            )
            
        # Update password
        user.set_password(new_password)
        self._db.commit()
        
        return True