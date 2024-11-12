"""
FastAPI router implementation for user management endpoints in Mint Replica Lite application.

Human Tasks:
1. Review rate limiting configuration for production deployment
2. Configure monitoring for failed authentication attempts
3. Set up email verification service integration if required
4. Verify CORS settings for allowed origins in production
"""

# fastapi: ^0.68.0
from fastapi import APIRouter, Depends, HTTPException, status
# sqlalchemy: ^1.4.0
from sqlalchemy.orm import Session
from uuid import UUID

from ....models.user import User
from ....schemas.user import UserCreate, UserUpdate, UserResponse
from ....services.user_service import UserService
from ....core.auth import get_current_user
from ....db.session import get_db

# Initialize router with prefix and tags
router = APIRouter(prefix='/users', tags=['users'])

@router.post('/', 
    status_code=status.HTTP_201_CREATED, 
    response_model=UserResponse,
    description="Register new user account")
async def register_user(
    user_data: UserCreate,
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Endpoint for user registration with email validation and secure password handling.
    
    Requirements addressed:
    - Account Management (1.2): Multi-platform user authentication and profile management
    - Security Standards (6.3.1): Implementation of secure user registration
    """
    try:
        user_service = UserService(db)
        user = user_service.create_user(user_data)
        return UserResponse.from_orm(user)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error creating user account"
        )

@router.get('/me', 
    response_model=UserResponse,
    description="Get current user profile")
async def get_user_profile(
    current_user: User = Depends(get_current_user)
) -> UserResponse:
    """
    Endpoint to get current authenticated user profile.
    
    Requirements addressed:
    - Account Management (1.2): User profile management
    - Authentication Flow (6.1.1): Secure authenticated profile access
    """
    try:
        return UserResponse.from_orm(current_user)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error retrieving user profile"
        )

@router.put('/me', 
    response_model=UserResponse,
    description="Update current user profile")
async def update_user_profile(
    user_data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> UserResponse:
    """
    Endpoint to update authenticated user profile.
    
    Requirements addressed:
    - Account Management (1.2): User profile management
    - Security Standards (6.3.1): Secure profile updates
    """
    try:
        user_service = UserService(db)
        updated_user = user_service.update_user(
            user_id=current_user.id,
            user_data=user_data
        )
        return UserResponse.from_orm(updated_user)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error updating user profile"
        )

@router.delete('/me', 
    status_code=status.HTTP_200_OK,
    description="Deactivate current user account")
async def delete_user_account(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> dict:
    """
    Endpoint to deactivate authenticated user account.
    
    Requirements addressed:
    - Account Management (1.2): Account lifecycle management
    - Security Standards (6.3.1): Secure account deactivation
    """
    try:
        user_service = UserService(db)
        user_service.delete_user(current_user.id)
        return {
            "message": "Account successfully deactivated",
            "user_id": str(current_user.id)
        }
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Error deactivating user account"
        )