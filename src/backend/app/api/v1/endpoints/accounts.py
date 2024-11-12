"""
FastAPI router endpoint module for managing financial accounts in the Mint Replica Lite system.

Human Tasks:
1. Configure rate limiting for account endpoints in production
2. Set up monitoring for account sync performance metrics
3. Review and adjust cache settings for account data
4. Configure logging for account operations monitoring
"""

# fastapi: ^0.95.0
from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional
from uuid import UUID

from app.services.account_service import AccountService
from app.schemas.account import (
    AccountBase, AccountCreate, AccountUpdate, AccountResponse
)
from app.core.auth import get_current_user

# Initialize router with prefix and tags
router = APIRouter(prefix='/accounts', tags=['accounts'])

async def get_account_service(
    db_session = Depends(get_db_session),
    plaid_service = Depends(get_plaid_service)
) -> AccountService:
    """
    Dependency function to get AccountService instance.
    
    Requirements addressed:
    - Account Management (1.2): Service initialization for account operations
    """
    return AccountService(plaid_service=plaid_service, db_session=db_session)

@router.post('/', response_model=AccountResponse, status_code=status.HTTP_201_CREATED)
async def create_account(
    account_data: AccountCreate,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> AccountResponse:
    """
    Create a new financial account with validation.
    
    Requirements addressed:
    - Account Management (1.2): Multi-platform user authentication and financial account aggregation
    - Security Standards (6.3.1): Secure API endpoints following OWASP standards
    """
    try:
        # Verify user matches account data
        if account_data.user_id != current_user['sub']:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User ID mismatch"
            )
            
        account = await account_service.create_account(
            user_id=str(account_data.user_id),
            access_token=account_data.access_token,
            plaid_account_id=account_data.plaid_account_id
        )
        return AccountResponse.from_orm(account)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.get('/{account_id}', response_model=AccountResponse)
async def get_account(
    account_id: UUID,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> AccountResponse:
    """
    Retrieve account by ID with authorization check.
    
    Requirements addressed:
    - Account Management (1.2): Secure account data retrieval
    - Security Standards (6.3.1): Authorization checks
    """
    account = account_service.get_account(str(account_id))
    if not account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
        
    # Verify account ownership
    if str(account.user_id) != current_user['sub']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to access this account"
        )
        
    return AccountResponse.from_orm(account)

@router.get('/', response_model=List[AccountResponse])
async def list_accounts(
    active_only: Optional[bool] = True,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> List[AccountResponse]:
    """
    List all accounts for current user with optional filtering.
    
    Requirements addressed:
    - Account Management (1.2): Account listing and filtering
    - Security Standards (6.3.1): Secure data access
    """
    accounts = await account_service.list_accounts(
        user_id=current_user['sub'],
        active_only=active_only
    )
    return [AccountResponse.from_orm(account) for account in accounts]

@router.patch('/{account_id}', response_model=AccountResponse)
async def update_account(
    account_id: UUID,
    account_data: AccountUpdate,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> AccountResponse:
    """
    Update account information with validation.
    
    Requirements addressed:
    - Account Management (1.2): Account updates
    - Security Standards (6.3.1): Secure update operations
    """
    # Verify account exists and belongs to user
    existing_account = account_service.get_account(str(account_id))
    if not existing_account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
        
    if str(existing_account.user_id) != current_user['sub']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to update this account"
        )
        
    try:
        updated_account = await account_service.update_account_balance(str(account_id))
        return AccountResponse.from_orm(updated_account)
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post('/{account_id}/sync', response_model=AccountResponse)
async def sync_account(
    account_id: UUID,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> AccountResponse:
    """
    Synchronize account with latest data from Plaid.
    
    Requirements addressed:
    - Real-time Updates (1.2): Real-time balance updates and cross-platform data synchronization
    - Security Standards (6.3.1): Secure external API integration
    """
    # Verify account exists and belongs to user
    existing_account = account_service.get_account(str(account_id))
    if not existing_account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
        
    if str(existing_account.user_id) != current_user['sub']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to sync this account"
        )
        
    try:
        synced_account = await account_service.sync_accounts(current_user['sub'])
        return AccountResponse.from_orm(synced_account)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error syncing account: {str(e)}"
        )

@router.delete('/{account_id}', status_code=status.HTTP_200_OK)
async def deactivate_account(
    account_id: UUID,
    current_user: dict = Depends(get_current_user),
    account_service: AccountService = Depends(get_account_service)
) -> dict:
    """
    Deactivate an account with authorization check.
    
    Requirements addressed:
    - Account Management (1.2): Account lifecycle management
    - Security Standards (6.3.1): Secure account deactivation
    """
    # Verify account exists and belongs to user
    existing_account = account_service.get_account(str(account_id))
    if not existing_account:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Account not found"
        )
        
    if str(existing_account.user_id) != current_user['sub']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not authorized to deactivate this account"
        )
        
    try:
        await account_service.deactivate_account(str(account_id))
        return {"message": "Account successfully deactivated"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deactivating account: {str(e)}"
        )