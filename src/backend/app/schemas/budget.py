# Library versions:
# pydantic: ^1.8.2
# typing: ^3.9.0
# datetime: ^3.9.0

from datetime import datetime
from decimal import Decimal
from typing import Optional, List, Dict, Union, UUID
from pydantic import BaseModel, Field, constr, condecimal

from app.models.budget import Budget
from app.schemas.category import CategoryResponse

# Human Tasks:
# 1. Review budget period constraints with product team
# 2. Verify alert threshold ranges with UX team
# 3. Confirm budget rule schema with backend team
# 4. Review field validation rules with security team

class BudgetBase(BaseModel):
    """
    Base Pydantic model for budget data validation with common fields.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Defines base structure for category-based budgeting
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Implements server-side validation for budget data
    """
    name: constr(min_length=1, max_length=100)
    amount: condecimal(gt=0, max_digits=10, decimal_places=2)
    period: constr(regex='^(monthly|yearly|weekly)$')
    category_id: int
    alert_threshold: Optional[int] = Field(None, ge=1, le=100)
    alert_enabled: Optional[bool] = True
    rules: Optional[Dict] = None

    class Config:
        orm_mode = True


class BudgetCreate(BudgetBase):
    """
    Pydantic model for budget creation requests with date validation.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Supports creation of time-bound budgets with alerts
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Validates budget creation parameters
    """
    start_date: datetime
    end_date: Optional[datetime] = None

    def validate_dates(self) -> bool:
        """
        Validates budget start and end dates.
        
        Returns:
            bool: True if dates are valid
            
        Raises:
            ValueError: If date validation fails
        
        Requirements addressed:
        - Data Validation (6.3.3 Security Controls/Input Validation):
          Ensures date integrity and logical sequence
        """
        current_time = datetime.utcnow()
        
        # Validate start date is not in past
        if self.start_date < current_time:
            raise ValueError("Budget start date cannot be in the past")
            
        # Validate end date if provided
        if self.end_date:
            if self.end_date <= self.start_date:
                raise ValueError("Budget end date must be after start date")
                
            # Validate minimum budget duration (1 day)
            if (self.end_date - self.start_date).days < 1:
                raise ValueError("Budget duration must be at least 1 day")
                
        return True


class BudgetUpdate(BaseModel):
    """
    Pydantic model for budget update requests with optional fields.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Enables modification of budget parameters
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Validates update data
    """
    name: Optional[constr(min_length=1, max_length=100)] = None
    amount: Optional[condecimal(gt=0, max_digits=10, decimal_places=2)] = None
    period: Optional[constr(regex='^(monthly|yearly|weekly)$')] = None
    alert_threshold: Optional[int] = Field(None, ge=1, le=100)
    alert_enabled: Optional[bool] = None
    is_active: Optional[bool] = None
    rules: Optional[Dict] = None

    class Config:
        orm_mode = True


class BudgetResponse(BaseModel):
    """
    Pydantic model for budget response data with relationships and progress metrics.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Provides comprehensive budget status with progress monitoring
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Ensures consistent response format
    """
    id: int
    user_id: UUID
    name: str
    amount: float
    period: str
    category: CategoryResponse
    start_date: datetime
    end_date: Optional[datetime]
    alert_threshold: Optional[int]
    alert_enabled: bool
    is_active: bool
    rules: Optional[Dict]
    progress: Dict[str, Union[float, Decimal]]
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

    @classmethod
    def from_orm(cls, db_budget: Budget) -> 'BudgetResponse':
        """
        Creates response model from ORM model instance.
        
        Args:
            db_budget: Database budget model instance
            
        Returns:
            BudgetResponse: Response model instance with relationships
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Transforms ORM model to API response with progress metrics
        """
        # Convert budget model to dictionary
        budget_dict = db_budget.to_dict()
        
        # Calculate current progress
        progress = db_budget.calculate_progress()
        
        # Create category response
        category_response = CategoryResponse.from_orm(db_budget.category)
        
        # Create response model
        return cls(
            id=budget_dict['id'],
            user_id=budget_dict['user_id'],
            name=budget_dict['name'],
            amount=float(budget_dict['amount']),
            period=budget_dict['period'],
            category=category_response,
            start_date=db_budget.start_date,
            end_date=db_budget.end_date,
            alert_threshold=budget_dict['alert_threshold'],
            alert_enabled=budget_dict['alert_enabled'],
            is_active=budget_dict['is_active'],
            rules=budget_dict['rules'],
            progress=progress,
            created_at=db_budget.created_at,
            updated_at=db_budget.updated_at
        )