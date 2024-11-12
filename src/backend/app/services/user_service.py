"""
User service implementation for Mint Replica Lite application.

Human Tasks:
1. Verify database connection pool settings for production environment
2. Review password complexity requirements in production
3. Configure JWT token expiration times for production use
4. Set up monitoring for failed authentication attempts
5. Configure rate limiting for authentication endpoints
"""

# SQLAlchemy: ^1.4.0
# FastAPI: ^0.68.0
from sqlalchemy.orm import Session
from fastapi import HTTPException
from typing import Optional, Dict
from uuid import UUID

from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate, UserResponse
from ..core.security import (
    create_access_token,
    create_refresh_token,
    get_password_hash,
    verify_password_hash
)

class UserService:
    """
    Service class implementing user management business logic with secure authentication 
    and profile management.
    
    Requirements addressed:
    - Account Management (1.2): Multi-platform user authentication and profile management
    - Security Implementation (6.2.1): Secure handling of user credentials
    - Authentication Flow (6.1.1): Implementation of secure authentication flow
    """
    
    def __init__(self, db: Session):
        """Initialize user service with database session."""
        self.db = db
    
    def create_user(self, user_data: UserCreate) -> User:
        """
        Creates a new user account with secure password hashing.
        
        Requirement addressed:
        - Security Implementation (6.2.1): Secure password handling
        
        Args:
            user_data: Validated user creation data
            
        Returns:
            Created user instance
            
        Raises:
            HTTPException: If email already exists
        """
        # Check for existing user
        existing_user = self.db.query(User).filter(
            User.email == user_data.email.lower()
        ).first()
        
        if existing_user:
            raise HTTPException(
                status_code=400,
                detail="Email already registered"
            )
        
        # Create new user with hashed password
        user = User(
            email=user_data.email,
            first_name=user_data.first_name,
            last_name=user_data.last_name,
            password=user_data.password  # Model handles hashing
        )
        
        self.db.add(user)
        self.db.commit()
        self.db.refresh(user)
        
        return user
    
    def authenticate_user(self, email: str, password: str) -> Dict:
        """
        Authenticates user and generates JWT tokens.
        
        Requirements addressed:
        - Authentication Flow (6.1.1): Secure authentication implementation
        - Security Implementation (6.2.1): Secure token generation
        
        Args:
            email: User's email address
            password: User's password
            
        Returns:
            Dict containing tokens and user data
            
        Raises:
            HTTPException: If authentication fails
        """
        user = self.db.query(User).filter(
            User.email == email.lower()
        ).first()
        
        if not user or not user.is_active:
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials"
            )
        
        if not user.verify_password(password):
            raise HTTPException(
                status_code=401,
                detail="Invalid credentials"
            )
        
        # Generate tokens
        access_token = create_access_token(
            data={"sub": str(user.id), "email": user.email}
        )
        refresh_token = create_refresh_token(
            data={"sub": str(user.id)}
        )
        
        # Create response with tokens and user data
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "user": UserResponse(
                id=user.id,
                email=user.email,
                first_name=user.first_name,
                last_name=user.last_name,
                is_active=user.is_active,
                created_at=user.created_at
            )
        }
    
    def get_user(self, user_id: UUID) -> Optional[User]:
        """
        Retrieves a user by ID.
        
        Requirement addressed:
        - Account Management (1.2): User profile management
        
        Args:
            user_id: UUID of user to retrieve
            
        Returns:
            User instance if found, None otherwise
        """
        return self.db.query(User).filter(
            User.id == user_id,
            User.is_active == True
        ).first()
    
    def update_user(self, user_id: UUID, user_data: UserUpdate) -> User:
        """
        Updates user profile information.
        
        Requirements addressed:
        - Account Management (1.2): Profile management
        - Security Implementation (6.2.1): Secure password updates
        
        Args:
            user_id: UUID of user to update
            user_data: Validated update data
            
        Returns:
            Updated user instance
            
        Raises:
            HTTPException: If user not found
        """
        user = self.get_user(user_id)
        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )
        
        # Update user attributes
        if user_data.first_name:
            user.first_name = user_data.first_name
        if user_data.last_name:
            user.last_name = user_data.last_name
        if user_data.password:
            user.set_password(user_data.password)
        
        self.db.commit()
        self.db.refresh(user)
        
        return user
    
    def delete_user(self, user_id: UUID) -> bool:
        """
        Deactivates a user account.
        
        Requirement addressed:
        - Account Management (1.2): Account lifecycle management
        
        Args:
            user_id: UUID of user to deactivate
            
        Returns:
            True if successful
            
        Raises:
            HTTPException: If user not found
        """
        user = self.get_user(user_id)
        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )
        
        user.is_active = False
        self.db.commit()
        
        return True
    
    def change_password(self, user_id: UUID, current_password: str, new_password: str) -> bool:
        """
        Changes user password with verification.
        
        Requirements addressed:
        - Security Implementation (6.2.1): Secure password changes
        - Authentication Flow (6.1.1): Password update flow
        
        Args:
            user_id: UUID of user
            current_password: Current password for verification
            new_password: New password to set
            
        Returns:
            True if successful
            
        Raises:
            HTTPException: If verification fails or user not found
        """
        user = self.get_user(user_id)
        if not user:
            raise HTTPException(
                status_code=404,
                detail="User not found"
            )
        
        # Verify current password
        if not user.verify_password(current_password):
            raise HTTPException(
                status_code=401,
                detail="Current password is incorrect"
            )
        
        # Update password
        user.set_password(new_password)
        self.db.commit()
        
        return True