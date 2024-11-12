# Pydantic: ^1.9.0
from pydantic import BaseModel, Field, validator
from uuid import UUID
from decimal import Decimal
from datetime import datetime
from typing import Optional, Dict

from app.models.investment import Investment

# Human Tasks:
# 1. Review currency codes list for supported currencies
# 2. Configure decimal precision settings in application config
# 3. Set up API response serialization error monitoring
# 4. Verify investment type enumeration matches business requirements

class InvestmentBase(BaseModel):
    """
    Base Pydantic schema for investment data validation.
    
    Requirements addressed:
    - Data Validation (2.2 Component Architecture/2.2.1 Client Applications):
      Implements comprehensive request/response data validation
    - Security Standards (6.3 Security Protocols/6.3.1 Security Standards Compliance):
      Implements OWASP-compliant input validation
    """
    symbol: str = Field(..., min_length=1, max_length=10)
    name: str = Field(..., min_length=1, max_length=255)
    investment_type: str = Field(..., min_length=1, max_length=50)
    quantity: Decimal = Field(..., ge=0)
    cost_basis: Decimal = Field(..., ge=0)
    current_value: Decimal = Field(..., ge=0)
    currency_code: str = Field(..., min_length=3, max_length=3)
    metadata: Dict = Field(default_factory=dict)

    @validator('currency_code')
    def validate_currency(cls, currency_code: str) -> str:
        """
        Validate currency code format.
        
        Requirements addressed:
        - Security Standards (6.3.1): Implements strict currency code validation
        """
        if len(currency_code) != 3:
            raise ValueError("Currency code must be exactly 3 characters")
        return currency_code.upper()

    @validator('cost_basis', 'current_value', 'quantity')
    def validate_amounts(cls, value: Decimal) -> Decimal:
        """
        Validate monetary amounts are positive and properly rounded.
        
        Requirements addressed:
        - Investment Tracking (1.2): Ensures accurate monetary value tracking
        - Security Standards (6.3.1): Implements strict numerical validation
        """
        if value < 0:
            raise ValueError("Amount must be non-negative")
        
        # Round based on field type
        if cls.current_field.name in ('cost_basis', 'current_value'):
            return round(value, 2)
        elif cls.current_field.name == 'quantity':
            return round(value, 8)
        return value

    class Config:
        json_encoders = {
            Decimal: str
        }

class InvestmentCreate(InvestmentBase):
    """
    Schema for creating a new investment.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment creation data
    """
    account_id: UUID = Field(...)

class InvestmentUpdate(BaseModel):
    """
    Schema for updating an existing investment.
    
    Requirements addressed:
    - Investment Tracking (1.2): Supports partial investment updates
    """
    symbol: Optional[str] = Field(None, min_length=1, max_length=10)
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    investment_type: Optional[str] = Field(None, min_length=1, max_length=50)
    quantity: Optional[Decimal] = Field(None, ge=0)
    cost_basis: Optional[Decimal] = Field(None, ge=0)
    current_value: Optional[Decimal] = Field(None, ge=0)
    currency_code: Optional[str] = Field(None, min_length=3, max_length=3)
    metadata: Optional[Dict] = None

    @validator('currency_code')
    def validate_currency(cls, currency_code: Optional[str]) -> Optional[str]:
        if currency_code is not None:
            if len(currency_code) != 3:
                raise ValueError("Currency code must be exactly 3 characters")
            return currency_code.upper()
        return currency_code

class InvestmentInDB(InvestmentBase):
    """
    Schema for investment data as stored in database.
    
    Requirements addressed:
    - Investment Tracking (1.2): Represents complete investment record
    """
    id: UUID
    account_id: UUID
    unrealized_gain_loss: Decimal = Field(..., decimal_places=2)
    return_percentage: Decimal = Field(..., decimal_places=4)
    is_active: bool
    last_synced_at: datetime
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class InvestmentResponse(InvestmentBase):
    """
    Schema for investment data in API responses.
    
    Requirements addressed:
    - Investment Tracking (1.2): Standardizes investment data representation
    - Data Validation (2.2.1): Ensures consistent API response format
    """
    id: UUID
    account_id: UUID
    unrealized_gain_loss: Decimal = Field(..., decimal_places=2)
    return_percentage: Decimal = Field(..., decimal_places=4)
    is_active: bool
    last_synced_at: datetime

    class Config:
        orm_mode = True