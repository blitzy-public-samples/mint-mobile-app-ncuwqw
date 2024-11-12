# Library versions:
# fastapi: ^0.68.0
# sqlalchemy: ^1.4.0
# uuid: ^3.9.0

# Human Tasks:
# 1. Review and adjust rate limiting settings for budget endpoints
# 2. Configure monitoring for budget alert thresholds
# 3. Set up logging for budget operations
# 4. Review error handling and response formats with frontend team

from typing import List, Dict, Optional
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ....schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse
from ....services.budget_service import BudgetService
from ....db.session import get_db
from ....core.auth import get_current_user

# Initialize router with prefix and tags
router = APIRouter(prefix='/budgets', tags=['budgets'])

@router.post('/', response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
async def create_budget(
    budget_data: BudgetCreate,
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> BudgetResponse:
    """
    Create a new budget for the authenticated user.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Creates category-based budget with customizable alerts
    - Security Controls (6.3.3 Security Controls):
      Implements input validation and role-based access
    """
    try:
        budget_service = BudgetService(db)
        return budget_service.create_budget(
            user_id=current_user['sub'],
            budget_data=budget_data
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get('/{budget_id}', response_model=BudgetResponse)
async def get_budget(
    budget_id: int,
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> BudgetResponse:
    """
    Retrieve a specific budget by ID with progress metrics.
    
    Requirements addressed:
    - Budget Progress Monitoring (1.2 Scope/Budget Management):
      Provides detailed budget status with progress metrics
    - Security Controls (6.3.3 Security Controls):
      Implements role-based access control
    """
    try:
        budget_service = BudgetService(db)
        return budget_service.get_budget(
            budget_id=budget_id,
            user_id=current_user['sub']
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.get('/', response_model=List[BudgetResponse])
async def list_budgets(
    category_id: Optional[int] = None,
    period: Optional[str] = None,
    alert_enabled: Optional[bool] = None,
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[BudgetResponse]:
    """
    List all budgets for the authenticated user with optional filters.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Lists category-based budgets with filtering options
    - Security Controls (6.3.3 Security Controls):
      Implements role-based access control
    """
    filters = {}
    if category_id is not None:
        filters['category_id'] = category_id
    if period is not None:
        filters['period'] = period
    if alert_enabled is not None:
        filters['alert_enabled'] = alert_enabled

    budget_service = BudgetService(db)
    return budget_service.list_budgets(
        user_id=current_user['sub'],
        filters=filters
    )

@router.put('/{budget_id}', response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    budget_data: BudgetUpdate,
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> BudgetResponse:
    """
    Update an existing budget.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Enables modification of budget parameters and alerts
    - Security Controls (6.3.3 Security Controls):
      Implements input validation and role-based access
    """
    try:
        budget_service = BudgetService(db)
        return budget_service.update_budget(
            budget_id=budget_id,
            user_id=current_user['sub'],
            budget_data=budget_data
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.delete('/{budget_id}', status_code=status.HTTP_204_NO_CONTENT)
async def delete_budget(
    budget_id: int,
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> None:
    """
    Soft delete a budget.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Enables safe removal of budgets while preserving history
    - Security Controls (6.3.3 Security Controls):
      Implements role-based access control
    """
    try:
        budget_service = BudgetService(db)
        budget_service.delete_budget(
            budget_id=budget_id,
            user_id=current_user['sub']
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.get('/alerts', response_model=List[Dict])
async def check_budget_alerts(
    current_user: Dict = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> List[Dict]:
    """
    Check budgets for threshold alerts.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Implements customizable budget alerts and monitoring
    - Security Controls (6.3.3 Security Controls):
      Implements role-based access control
    """
    budget_service = BudgetService(db)
    return budget_service.check_budget_alerts(
        user_id=current_user['sub']
    )