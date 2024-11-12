"""
Pydantic schemas for transaction data validation and serialization in the Mint Replica Lite application.

Human Tasks:
1. Review transaction amount limits with business team
2. Verify transaction type list with product team
3. Configure monitoring for transaction validation performance
4. Review transaction status workflow with operations team
"""

# Library versions:
# pydantic: ^1.9.0
# typing: ^3.9.0
# uuid: ^3.9.0
# decimal: ^3.9.0
# datetime: ^3.9.0

from datetime import datetime
from decimal import Decimal
from typing import Dict, List, Optional
from uuid import UUID

from pydantic import BaseModel, Field, validator, constr

from app.schemas.account import AccountResponse
from app.schemas.category import CategoryResponse

class TransactionBase(BaseModel):
    """
    Base Pydantic model for transaction data validation.
    
    Requirements addressed:
    - Financial Tracking (1.2): Implements core transaction data structure
    - Data Validation (6.3.3): Enforces strict validation rules
    """
    account_id: UUID
    transaction_date: datetime
    amount: Decimal = Field(..., decimal_places=2)
    description: constr(min_length=1, max_length=255)
    merchant_name: Optional[str] = Field(None, max_length=100)
    transaction_type: str
    category_id: Optional[int] = None
    metadata: Optional[Dict] = Field(default_factory=dict)

    @validator('amount')
    def validate_amount(cls, amount: Decimal) -> Decimal:
        """
        Validates transaction amount format and value.
        
        Requirements addressed:
        - Data Validation (6.3.3): Ensures proper decimal handling
        - Transaction Management (2.5.3): Validates financial amounts
        """
        if amount is None:
            raise ValueError('Amount cannot be None')
        
        # Ensure exactly 2 decimal places
        if abs(amount.as_tuple().exponent) != 2:
            raise ValueError('Amount must have exactly 2 decimal places')
        
        if amount == Decimal('0'):
            raise ValueError('Amount cannot be zero')
            
        return amount

    @validator('transaction_type')
    def validate_transaction_type(cls, transaction_type: str) -> str:
        """
        Validates transaction type against allowed values.
        
        Requirements addressed:
        - Financial Tracking (1.2): Enforces valid transaction types
        - Data Validation (6.3.3): Validates enumerated values
        """
        valid_types = ['debit', 'credit', 'transfer']
        type_lower = transaction_type.lower()
        
        if type_lower not in valid_types:
            raise ValueError(f'Invalid transaction type. Must be one of: {", ".join(valid_types)}')
            
        return type_lower

class TransactionCreate(TransactionBase):
    """
    Schema for transaction creation requests.
    
    Requirements addressed:
    - Financial Tracking (1.2): Supports transaction creation
    - Transaction Management (2.5.3): Handles transaction status
    """
    status: str
    is_pending: bool = Field(default=True)

    @validator('status')
    def validate_status(cls, status: str) -> str:
        """
        Validates transaction status.
        
        Requirements addressed:
        - Transaction Management (2.5.3): Enforces valid status values
        - Data Validation (6.3.3): Validates enumerated values
        """
        valid_statuses = ['pending', 'posted', 'cancelled']
        status_lower = status.lower()
        
        if status_lower not in valid_statuses:
            raise ValueError(f'Invalid status. Must be one of: {", ".join(valid_statuses)}')
            
        return status_lower

class TransactionUpdate(BaseModel):
    """
    Schema for transaction update requests.
    
    Requirements addressed:
    - Financial Tracking (1.2): Enables transaction modifications
    - Transaction Management (2.5.3): Supports partial updates
    """
    description: Optional[constr(min_length=1, max_length=255)] = None
    merchant_name: Optional[constr(max_length=100)] = None
    category_id: Optional[int] = None
    status: Optional[str] = None
    is_pending: Optional[bool] = None
    metadata: Optional[Dict] = None

class TransactionFilter(BaseModel):
    """
    Schema for transaction filtering parameters.
    
    Requirements addressed:
    - Financial Tracking (1.2): Implements transaction search/filtering
    - Transaction Management (2.5.3): Enables efficient querying
    """
    account_id: Optional[UUID] = None
    category_id: Optional[int] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    min_amount: Optional[Decimal] = Field(None, decimal_places=2)
    max_amount: Optional[Decimal] = Field(None, decimal_places=2)
    search_query: Optional[str] = Field(None, max_length=100)
    transaction_types: Optional[List[str]] = None
    statuses: Optional[List[str]] = None

class TransactionResponse(BaseModel):
    """
    Schema for transaction response data.
    
    Requirements addressed:
    - Financial Tracking (1.2): Formats transaction data for API responses
    - Transaction Management (2.5.3): Includes related data
    """
    id: UUID
    account_id: UUID
    transaction_date: datetime
    post_date: Optional[datetime]
    amount: Decimal
    description: str
    merchant_name: Optional[str]
    transaction_type: str
    status: str
    is_pending: bool
    metadata: Optional[Dict]
    category: Optional[CategoryResponse]
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

    @classmethod
    def from_orm(cls, db_transaction) -> 'TransactionResponse':
        """
        Creates response model from ORM model instance.
        
        Requirements addressed:
        - Financial Tracking (1.2): Transforms database data to API format
        - Transaction Management (2.5.3): Handles related data
        """
        # Create base response
        response_dict = {
            'id': db_transaction.id,
            'account_id': db_transaction.account_id,
            'transaction_date': db_transaction.transaction_date,
            'post_date': db_transaction.post_date,
            'amount': db_transaction.amount,
            'description': db_transaction.description,
            'merchant_name': db_transaction.merchant_name,
            'transaction_type': db_transaction.transaction_type,
            'status': db_transaction.status,
            'is_pending': db_transaction.is_pending,
            'metadata': db_transaction.metadata,
            'created_at': db_transaction.created_at,
            'updated_at': db_transaction.updated_at,
            'category': None
        }

        # Include category if exists
        if db_transaction.category:
            response_dict['category'] = CategoryResponse(
                id=db_transaction.category.id,
                name=db_transaction.category.name
            )

        return cls(**response_dict)