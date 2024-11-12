"""
Pydantic schemas for account data validation and serialization in the Mint Replica Lite application.

Human Tasks:
1. Verify ISO currency codes list is up to date
2. Review and update allowed account types based on supported financial institutions
3. Configure logging for validation errors
4. Set up monitoring for validation performance metrics
"""

# pydantic: ^1.9.0
from pydantic import BaseModel, Field, validator, constr
from uuid import UUID
from decimal import Decimal
from datetime import datetime
from typing import Optional, Dict

from app.models.account import Account

# Allowed account types for validation
ALLOWED_ACCOUNT_TYPES = {'checking', 'savings', 'credit', 'investment'}

# ISO 4217 currency codes (partial list - should be maintained)
VALID_CURRENCY_CODES = {'USD', 'EUR', 'GBP', 'CAD', 'JPY', 'AUD', 'CHF', 'CNY'}

class AccountBase(BaseModel):
    """
    Base Pydantic model for account data validation.
    
    Requirements addressed:
    - Data Validation (2.2.1): Implements core account data validation
    - Security Standards (6.3.1): Enforces data validation for financial information
    """
    institution_id: str = Field(..., min_length=1, max_length=50)
    account_type: str = Field(..., min_length=1, max_length=50)
    account_name: str = Field(..., min_length=1, max_length=255)
    account_number_masked: str = Field(..., min_length=4, max_length=20)
    current_balance: Decimal = Field(..., ge=Decimal('0'), decimal_places=2)
    available_balance: Decimal = Field(..., ge=Decimal('0'), decimal_places=2)
    currency_code: str = Field(..., min_length=3, max_length=3)
    institution_data: Dict = Field(default_factory=dict)
    is_active: bool = Field(default=True)

    @validator('account_type')
    def validate_account_type(cls, account_type: str) -> str:
        """
        Validates account type against allowed values.
        
        Requirements addressed:
        - Data Validation (2.2.1): Enforces valid account types
        """
        account_type_lower = account_type.lower()
        if account_type_lower not in ALLOWED_ACCOUNT_TYPES:
            raise ValueError(f'Invalid account type. Must be one of: {", ".join(ALLOWED_ACCOUNT_TYPES)}')
        return account_type_lower

    @validator('currency_code')
    def validate_currency_code(cls, currency_code: str) -> str:
        """
        Validates currency code format.
        
        Requirements addressed:
        - Data Validation (2.2.1): Ensures valid currency codes
        - Security Standards (6.3.1): Validates financial data formats
        """
        if len(currency_code) != 3:
            raise ValueError('Currency code must be exactly 3 characters')
        
        currency_code_upper = currency_code.upper()
        if currency_code_upper not in VALID_CURRENCY_CODES:
            raise ValueError(f'Invalid currency code. Must be one of: {", ".join(VALID_CURRENCY_CODES)}')
        return currency_code_upper

    @validator('current_balance', 'available_balance')
    def validate_balances(cls, value: Decimal) -> Decimal:
        """
        Validates balance amounts.
        
        Requirements addressed:
        - Data Validation (2.2.1): Validates financial amounts
        - Security Standards (6.3.1): Ensures proper decimal handling
        """
        if value is None:
            raise ValueError('Balance cannot be None')
        
        # Ensure maximum 2 decimal places
        if abs(value.as_tuple().exponent) > 2:
            raise ValueError('Balance must have maximum 2 decimal places')
        
        if value < Decimal('0'):
            raise ValueError('Balance cannot be negative')
            
        return value

class AccountCreate(AccountBase):
    """
    Schema for account creation requests.
    
    Requirements addressed:
    - Account Management (1.2): Supports account creation
    - Data Validation (2.2.1): Validates creation requests
    """
    user_id: UUID

class AccountUpdate(BaseModel):
    """
    Schema for account update requests.
    
    Requirements addressed:
    - Account Management (1.2): Supports account updates
    - Data Validation (2.2.1): Validates update requests
    """
    account_name: Optional[str] = Field(None, min_length=1, max_length=255)
    current_balance: Optional[Decimal] = Field(None, ge=Decimal('0'), decimal_places=2)
    available_balance: Optional[Decimal] = Field(None, ge=Decimal('0'), decimal_places=2)
    institution_data: Optional[Dict] = None
    is_active: Optional[bool] = None

class AccountInDB(AccountBase):
    """
    Schema for account data stored in database.
    
    Requirements addressed:
    - Account Management (1.2): Represents stored account data
    - Security Standards (6.3.1): Ensures data integrity
    """
    id: UUID
    user_id: UUID
    last_synced_at: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class AccountResponse(BaseModel):
    """
    Schema for account data in API responses.
    
    Requirements addressed:
    - Account Management (1.2): Formats account data for API responses
    - Security Standards (6.3.1): Ensures secure data transmission
    """
    id: UUID
    user_id: UUID
    institution_id: str
    account_type: str
    account_name: str
    account_number_masked: str
    current_balance: Decimal
    available_balance: Decimal
    currency_code: str
    institution_data: Dict
    is_active: bool
    last_synced_at: datetime
    created_at: datetime

    class Config:
        orm_mode = True