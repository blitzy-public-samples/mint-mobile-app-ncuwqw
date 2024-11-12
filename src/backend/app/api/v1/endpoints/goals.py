"""
FastAPI router endpoints for managing financial goals in the Mint Replica Lite application.

Human Tasks:
1. Configure monitoring for goal endpoint performance metrics
2. Set up alerts for goal achievement milestones
3. Review and update API documentation when endpoints change
4. Configure rate limiting for goal endpoints
5. Set up logging for goal operations tracking
"""

# fastapi: ^0.68.0
from fastapi import APIRouter, Depends, HTTPException, status
from uuid import UUID
from typing import List
from decimal import Decimal
from sqlalchemy.orm import Session

from ....models.goal import Goal
from ....schemas.goal import (
    GoalCreate,
    GoalUpdate,
    GoalInDB,
    GoalResponse
)
from ....services.goal_service import GoalService
from ....core.auth import get_current_user
from ....db.session import get_db

# Initialize router with prefix and tags
router = APIRouter(prefix='/goals', tags=['goals'])

@router.post('/', response_model=GoalInDB, status_code=status.HTTP_201_CREATED)
async def create_goal(
    goal_data: GoalCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> GoalInDB:
    """
    Create a new financial goal for authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal creation functionality
    - REST API Services (2.1): Provides RESTful endpoint for goal creation
    """
    goal_service = GoalService(db)
    goal_data.user_id = UUID(current_user['sub'])
    
    try:
        return goal_service.create_goal(goal_data)
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get('/{goal_id}', response_model=GoalResponse)
async def get_goal(
    goal_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> GoalResponse:
    """
    Retrieve a specific goal by ID for authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal retrieval with progress tracking
    - REST API Services (2.1): Provides RESTful endpoint for goal retrieval
    """
    goal_service = GoalService(db)
    goal = goal_service.get_goal(goal_id, UUID(current_user['sub']))
    
    if not goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )
        
    return goal

@router.get('/', response_model=List[GoalResponse])
async def list_goals(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> List[GoalResponse]:
    """
    List all goals for the authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal listing with progress metrics
    - REST API Services (2.1): Provides RESTful endpoint for goal listing
    """
    goal_service = GoalService(db)
    return goal_service.list_goals(UUID(current_user['sub']))

@router.put('/{goal_id}', response_model=GoalInDB)
async def update_goal(
    goal_id: UUID,
    goal_data: GoalUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> GoalInDB:
    """
    Update an existing goal for authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal update functionality
    - REST API Services (2.1): Provides RESTful endpoint for goal updates
    """
    goal_service = GoalService(db)
    updated_goal = goal_service.update_goal(
        goal_id,
        UUID(current_user['sub']),
        goal_data
    )
    
    if not updated_goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )
        
    return updated_goal

@router.delete('/{goal_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_goal(
    goal_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> None:
    """
    Delete a goal for authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal deletion functionality
    - REST API Services (2.1): Provides RESTful endpoint for goal deletion
    """
    goal_service = GoalService(db)
    if not goal_service.delete_goal(goal_id, UUID(current_user['sub'])):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )

@router.patch('/{goal_id}/progress', response_model=GoalResponse)
async def update_goal_progress(
    goal_id: UUID,
    amount: Decimal,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> GoalResponse:
    """
    Update goal progress amount for authenticated user.
    
    Requirements addressed:
    - Goal Management (1.2): Implements goal progress tracking
    - REST API Services (2.1): Provides RESTful endpoint for progress updates
    """
    goal_service = GoalService(db)
    updated_goal = goal_service.update_goal_progress(
        goal_id,
        UUID(current_user['sub']),
        amount
    )
    
    if not updated_goal:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Goal not found"
        )
        
    return updated_goal