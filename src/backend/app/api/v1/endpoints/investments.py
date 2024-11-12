# fastapi: ^0.68.0
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID
from decimal import Decimal

from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentResponse
from app.services.investment_service import InvestmentService
from app.core.auth import get_current_user
from app.db.session import get_db

# Human Tasks:
# 1. Configure rate limiting for investment endpoints
# 2. Set up monitoring for investment sync operations
# 3. Review and adjust pagination limits based on load testing
# 4. Configure caching strategy for portfolio metrics
# 5. Set up alerts for failed investment operations

router = APIRouter(prefix='/investments', tags=['investments'])

@router.post('/', response_model=InvestmentResponse, status_code=status.HTTP_201_CREATED)
async def create_investment(
    investment_data: InvestmentCreate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> InvestmentResponse:
    """
    Create a new investment position.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements investment position creation
    - RESTful API Services (2.1): Implements RESTful endpoint for investment creation
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        return investment_service.create_investment(investment_data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get('/{investment_id}', response_model=InvestmentResponse)
async def get_investment(
    investment_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> InvestmentResponse:
    """
    Retrieve investment details by ID.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements investment position lookup
    - RESTful API Services (2.1): Implements RESTful endpoint for investment retrieval
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        return investment_service.get_investment(investment_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.put('/{investment_id}', response_model=InvestmentResponse)
async def update_investment(
    investment_id: UUID,
    investment_data: InvestmentUpdate,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> InvestmentResponse:
    """
    Update existing investment details.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements investment position updates
    - RESTful API Services (2.1): Implements RESTful endpoint for investment updates
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        return investment_service.update_investment(investment_id, investment_data)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.delete('/{investment_id}', status_code=status.HTTP_200_OK)
async def delete_investment(
    investment_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> dict:
    """
    Soft delete investment by ID.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements investment position removal
    - RESTful API Services (2.1): Implements RESTful endpoint for investment deletion
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        investment_service.delete_investment(investment_id)
        return {"message": "Investment deleted successfully"}
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.get('/', response_model=List[InvestmentResponse])
async def list_investments(
    account_id: UUID,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> List[InvestmentResponse]:
    """
    List investments for an account with pagination.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements portfolio listing and monitoring
    - RESTful API Services (2.1): Implements RESTful endpoint for investment listing
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    investment_service = InvestmentService(db)
    return investment_service.list_investments(account_id, skip, limit)

@router.patch('/{investment_id}/sync', response_model=InvestmentResponse)
async def sync_investment_values(
    investment_id: UUID,
    current_value: Decimal,
    quantity: Decimal = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> InvestmentResponse:
    """
    Update investment values and recalculate metrics.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements real-time value updates
    - RESTful API Services (2.1): Implements RESTful endpoint for value synchronization
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        return investment_service.sync_investment_values(
            investment_id,
            current_value,
            quantity
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )

@router.get('/{account_id}/metrics')
async def get_portfolio_metrics(
    account_id: UUID,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
) -> dict:
    """
    Get aggregate portfolio metrics for an account.
    
    Requirements addressed:
    - Investment Tracking (1.2): Implements portfolio performance metrics
    - RESTful API Services (2.1): Implements RESTful endpoint for portfolio analytics
    - Security Standards (6.3.1): Implements secure endpoint with authentication
    """
    try:
        investment_service = InvestmentService(db)
        return investment_service.calculate_portfolio_metrics(account_id)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )