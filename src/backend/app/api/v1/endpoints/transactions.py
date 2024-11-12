# FastAPI v0.68.0
from fastapi import APIRouter, Depends, HTTPException, Query, Path
from fastapi.responses import JSONResponse

# Standard library imports
from typing import List, Optional
from uuid import UUID
from datetime import datetime

# Internal imports
from ....models.transaction import Transaction
from ....services.transaction_service import TransactionService
from ....schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionFilter,
    TransactionResponse
)
from ....core.auth import get_current_user

# Human Tasks:
# 1. Configure rate limiting settings for production environment
# 2. Set up monitoring for endpoint performance and error rates
# 3. Review and adjust pagination limits based on load testing
# 4. Configure logging for transaction operations
# 5. Set up alerts for high error rates or latency spikes

# Initialize router with prefix and tags
router = APIRouter(prefix='/transactions', tags=['transactions'])

@router.get('/{transaction_id}', response_model=TransactionResponse)
async def get_transaction(
    transaction_id: UUID = Path(..., description="Transaction UUID"),
    current_user: dict = Depends(get_current_user)
) -> TransactionResponse:
    """
    Get a single transaction by ID.

    Requirements addressed:
    - Financial Tracking (1.2): Enables retrieval of transaction details
    - REST API Services (2.1): Implements RESTful endpoint for transaction retrieval
    - Security Controls (6.3.3): Implements user authentication and validation
    """
    try:
        transaction = TransactionService.get_transaction(transaction_id)
        if not transaction:
            raise HTTPException(
                status_code=404,
                detail="Transaction not found"
            )

        # Verify user has access to transaction's account
        if str(transaction.account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this transaction"
            )

        return TransactionResponse.from_orm(transaction)

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get('/', response_model=List[TransactionResponse])
async def get_transactions(
    filters: TransactionFilter = Depends(),
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(50, ge=1, le=100, description="Items per page"),
    current_user: dict = Depends(get_current_user)
) -> List[TransactionResponse]:
    """
    Get filtered list of transactions with pagination.

    Requirements addressed:
    - Financial Tracking (1.2): Implements transaction filtering and pagination
    - REST API Services (2.1): Implements RESTful endpoint for transaction listing
    - Security Controls (6.3.3): Implements input validation and access control
    """
    try:
        # Verify user has access to requested account
        if filters.account_id and str(filters.account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this account"
            )

        transactions, total_count = TransactionService.get_transactions(
            account_id=filters.account_id,
            start_date=filters.start_date,
            end_date=filters.end_date,
            category_id=filters.category_id,
            page=page,
            page_size=page_size
        )

        return [TransactionResponse.from_orm(t) for t in transactions]

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post('/', response_model=TransactionResponse, status_code=201)
async def create_transaction(
    transaction_data: TransactionCreate,
    current_user: dict = Depends(get_current_user)
) -> TransactionResponse:
    """
    Create a new transaction.

    Requirements addressed:
    - Financial Tracking (1.2): Enables transaction creation
    - REST API Services (2.1): Implements RESTful endpoint for transaction creation
    - Security Controls (6.3.3): Implements input validation and secure error handling
    """
    try:
        # Verify user has access to specified account
        if str(transaction_data.account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this account"
            )

        transaction = TransactionService.create_transaction(transaction_data)
        return TransactionResponse.from_orm(transaction)

    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

@router.patch('/{transaction_id}', response_model=TransactionResponse)
async def update_transaction(
    transaction_id: UUID = Path(..., description="Transaction UUID"),
    update_data: TransactionUpdate = None,
    current_user: dict = Depends(get_current_user)
) -> TransactionResponse:
    """
    Update an existing transaction.

    Requirements addressed:
    - Financial Tracking (1.2): Enables transaction modification
    - REST API Services (2.1): Implements RESTful endpoint for transaction updates
    - Security Controls (6.3.3): Implements secure update operations
    """
    try:
        # Verify transaction exists and user has access
        transaction = TransactionService.get_transaction(transaction_id)
        if not transaction:
            raise HTTPException(
                status_code=404,
                detail="Transaction not found"
            )

        if str(transaction.account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this transaction"
            )

        updated_transaction = TransactionService.update_transaction(
            transaction_id,
            update_data
        )
        return TransactionResponse.from_orm(updated_transaction)

    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

@router.post('/sync', response_model=dict)
async def sync_transactions(
    account_id: UUID = Query(..., description="Account UUID"),
    cursor: Optional[str] = Query(None, description="Sync cursor for pagination"),
    current_user: dict = Depends(get_current_user)
) -> dict:
    """
    Synchronize transactions with Plaid for an account.

    Requirements addressed:
    - Financial Tracking (1.2): Implements automated transaction import
    - REST API Services (2.1): Implements RESTful endpoint for transaction sync
    - Security Controls (6.3.3): Implements secure external API integration
    """
    try:
        # Verify user has access to account
        if str(account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this account"
            )

        new_transactions, updated_cursor = await TransactionService.sync_transactions(
            account_id=account_id,
            cursor=cursor
        )

        return {
            "new_transactions": len(new_transactions),
            "cursor": updated_cursor
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.put('/{transaction_id}/category', response_model=TransactionResponse)
async def categorize_transaction(
    transaction_id: UUID = Path(..., description="Transaction UUID"),
    category_id: int = Query(..., description="Category ID"),
    current_user: dict = Depends(get_current_user)
) -> TransactionResponse:
    """
    Update transaction category.

    Requirements addressed:
    - Financial Tracking (1.2): Implements category management
    - REST API Services (2.1): Implements RESTful endpoint for categorization
    - Security Controls (6.3.3): Implements secure category updates
    """
    try:
        # Verify transaction exists and user has access
        transaction = TransactionService.get_transaction(transaction_id)
        if not transaction:
            raise HTTPException(
                status_code=404,
                detail="Transaction not found"
            )

        if str(transaction.account_id) not in current_user.get('accounts', []):
            raise HTTPException(
                status_code=403,
                detail="Access denied to this transaction"
            )

        updated_transaction = TransactionService.categorize_transaction(
            transaction_id,
            category_id
        )
        return TransactionResponse.from_orm(updated_transaction)

    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))