"""
Pydantic schema models for goal data validation and serialization.

Human Tasks:
1. Review and configure logging for schema validation errors
2. Set up monitoring for schema validation performance
3. Configure error tracking for validation failures
4. Review and update API documentation when schema changes
"""

# pydantic: ^1.9.0
from pydantic import BaseModel, Field, validator
from uuid import UUID
from datetime import datetime, date
from decimal import Decimal
from typing import Optional
from ..models.goal import Goal

class GoalBase(BaseModel):
    """
    Base Pydantic model for goal data validation.
    
    Requirements addressed:
    - Goal Management (1.2): Defines core goal attributes and validation rules
    - Data Validation (2.2.1): Implements schema validation for goal data
    """
    name: str = Field(..., min_length=1, max_length=255)
    description: str = Field(None, max_length=1000)
    goal_type: str = Field(..., min_length=1, max_length=50)
    target_amount: Decimal = Field(..., ge=Decimal('0.01'))
    target_date: datetime
    account_id: UUID

    @validator('target_amount')
    def validate_target_amount(cls, value: Decimal) -> Decimal:
        """Validate target amount is positive."""
        if value <= Decimal('0'):
            raise ValueError("Target amount must be positive")
        return value

    @validator('target_date')
    def validate_target_date(cls, value: datetime) -> datetime:
        """Validate target date is in the future."""
        if value < datetime.utcnow():
            raise ValueError("Target date must be in the future")
        return value

    class Config:
        json_encoders = {
            Decimal: str,
            UUID: str,
            datetime: lambda v: v.isoformat()
        }

class GoalCreate(GoalBase):
    """
    Schema for creating a new goal.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal creation requests
    - Data Validation (2.2.1): Ensures required fields for goal creation
    """
    user_id: UUID

class GoalUpdate(BaseModel):
    """
    Schema for updating an existing goal.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal update requests
    - Data Validation (2.2.1): Handles partial updates
    """
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    description: Optional[str] = Field(None, max_length=1000)
    target_amount: Optional[Decimal] = Field(None, ge=Decimal('0.01'))
    target_date: Optional[datetime]
    account_id: Optional[UUID]

    @validator('target_amount')
    def validate_target_amount(cls, value: Optional[Decimal]) -> Optional[Decimal]:
        if value is not None and value <= Decimal('0'):
            raise ValueError("Target amount must be positive")
        return value

    @validator('target_date')
    def validate_target_date(cls, value: Optional[datetime]) -> Optional[datetime]:
        if value is not None and value < datetime.utcnow():
            raise ValueError("Target date must be in the future")
        return value

class GoalInDB(GoalBase):
    """
    Schema for goal data as stored in database.
    
    Requirements addressed:
    - Goal Management (1.2): Represents complete goal data model
    - Data Validation (2.2.1): Validates database goal representation
    """
    id: UUID
    current_amount: Decimal = Field(..., ge=Decimal('0'))
    is_completed: bool = False
    completed_at: Optional[datetime]
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

class GoalResponse(GoalInDB):
    """
    Schema for API response with goal data.
    
    Requirements addressed:
    - Goal Management (1.2): Provides goal progress tracking
    - Data Validation (2.2.1): Validates API response data
    """
    progress_percentage: float = Field(..., ge=0.0, le=100.0)
    days_remaining: int = Field(..., ge=0)

    def calculate_days_remaining(self) -> int:
        """Calculate days remaining until target date."""
        remaining = (self.target_date.date() - date.today()).days
        return max(0, remaining)

    @classmethod
    def from_orm(cls, obj: Goal):
        """Convert ORM model to response schema with computed fields."""
        data = super().from_orm(obj)
        data.progress_percentage = obj.calculate_progress_percentage()
        data.days_remaining = data.calculate_days_remaining()
        return data