# Library versions:
# sqlalchemy: ^1.4.0
# pydantic: ^1.8.2
# uuid: ^3.9.0
# datetime: ^3.9.0

# Human Tasks:
# 1. Configure database connection pool settings for optimal performance
# 2. Set up monitoring alerts for budget threshold notifications
# 3. Review and adjust database query optimization settings
# 4. Configure logging levels for budget-related operations

from datetime import datetime
from typing import List, Dict, Optional
from uuid import UUID

from sqlalchemy.orm import Session
from sqlalchemy import and_

from app.models.budget import Budget
from app.models.category import Category
from app.schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse
from app.core.errors import NotFoundError, ValidationError

class BudgetService:
    """
    Service class implementing budget management business logic with progress monitoring and alerts.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management):
      Implements category-based budgeting with progress monitoring and customizable alerts
    - Budget Progress Monitoring (1.2 Scope/Budget Management):
      Provides detailed progress tracking and budget vs actual reporting
    - Budget Alerts (1.2 Scope/Budget Management):
      Implements customizable alerts for budget thresholds
    """

    def __init__(self, db: Session):
        """Initialize budget service with database session."""
        self._db = db

    def create_budget(self, user_id: UUID, budget_data: BudgetCreate) -> BudgetResponse:
        """
        Creates a new budget for a user with category validation.
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Enables creation of category-based budgets with alerts
        """
        # Validate budget creation data
        if not budget_data.validate_dates():
            raise ValidationError("Invalid budget dates")

        # Verify category exists and is active
        category = self._db.query(Category).filter(
            and_(
                Category.id == budget_data.category_id,
                Category.is_active == True
            )
        ).first()
        
        if not category:
            raise ValidationError(f"Category {budget_data.category_id} not found or inactive")

        # Create new budget instance
        budget = Budget(
            user_id=user_id,
            category_id=budget_data.category_id,
            name=budget_data.name,
            amount=budget_data.amount,
            period=budget_data.period,
            start_date=budget_data.start_date,
            end_date=budget_data.end_date,
            alert_threshold=budget_data.alert_threshold,
            alert_enabled=budget_data.alert_enabled,
            rules=budget_data.rules
        )

        # Calculate initial progress
        budget.calculate_progress()

        # Save to database
        self._db.add(budget)
        self._db.commit()
        self._db.refresh(budget)

        # Return response
        return BudgetResponse.from_orm(budget)

    def update_budget(self, budget_id: int, user_id: UUID, budget_data: BudgetUpdate) -> BudgetResponse:
        """
        Updates an existing budget with validation.
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Enables modification of budget parameters and alert settings
        """
        # Query existing budget
        budget = self._db.query(Budget).filter(
            and_(
                Budget.id == budget_id,
                Budget.user_id == user_id,
                Budget.is_active == True
            )
        ).first()

        if not budget:
            raise NotFoundError(f"Budget {budget_id} not found")

        # Update budget fields if provided
        if budget_data.name is not None:
            budget.name = budget_data.name
        if budget_data.amount is not None:
            budget.amount = budget_data.amount
        if budget_data.period is not None:
            budget.period = budget_data.period
        if budget_data.alert_threshold is not None:
            budget.alert_threshold = budget_data.alert_threshold
        if budget_data.alert_enabled is not None:
            budget.alert_enabled = budget_data.alert_enabled
        if budget_data.is_active is not None:
            budget.is_active = budget_data.is_active
        if budget_data.rules is not None:
            budget.rules = budget_data.rules

        # Recalculate progress
        budget.calculate_progress()

        # Save changes
        self._db.commit()
        self._db.refresh(budget)

        return BudgetResponse.from_orm(budget)

    def get_budget(self, budget_id: int, user_id: UUID) -> BudgetResponse:
        """
        Retrieves a specific budget by ID with progress.
        
        Requirements addressed:
        - Budget Progress Monitoring (1.2 Scope/Budget Management):
          Provides detailed budget status with progress metrics
        """
        budget = self._db.query(Budget).filter(
            and_(
                Budget.id == budget_id,
                Budget.user_id == user_id,
                Budget.is_active == True
            )
        ).first()

        if not budget:
            raise NotFoundError(f"Budget {budget_id} not found")

        # Calculate current progress
        budget.calculate_progress()

        return BudgetResponse.from_orm(budget)

    def list_budgets(self, user_id: UUID, filters: Optional[Dict] = None) -> List[BudgetResponse]:
        """
        Lists all budgets for a user with optional filters.
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Provides comprehensive budget listing with filtering
        """
        query = self._db.query(Budget).filter(
            and_(
                Budget.user_id == user_id,
                Budget.is_active == True
            )
        )

        # Apply additional filters if provided
        if filters:
            if 'category_id' in filters:
                query = query.filter(Budget.category_id == filters['category_id'])
            if 'period' in filters:
                query = query.filter(Budget.period == filters['period'])
            if 'alert_enabled' in filters:
                query = query.filter(Budget.alert_enabled == filters['alert_enabled'])

        budgets = query.all()

        # Calculate progress for each budget
        for budget in budgets:
            budget.calculate_progress()

        return [BudgetResponse.from_orm(budget) for budget in budgets]

    def delete_budget(self, budget_id: int, user_id: UUID) -> bool:
        """
        Soft deletes a budget by setting is_active to False.
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Enables safe removal of budgets while preserving history
        """
        budget = self._db.query(Budget).filter(
            and_(
                Budget.id == budget_id,
                Budget.user_id == user_id,
                Budget.is_active == True
            )
        ).first()

        if not budget:
            raise NotFoundError(f"Budget {budget_id} not found")

        budget.is_active = False
        self._db.commit()

        return True

    def check_budget_alerts(self, user_id: UUID) -> List[Dict]:
        """
        Checks all active budgets for threshold alerts.
        
        Requirements addressed:
        - Budget Alerts (1.2 Scope/Budget Management):
          Implements threshold-based budget alerts
        """
        budgets = self._db.query(Budget).filter(
            and_(
                Budget.user_id == user_id,
                Budget.is_active == True,
                Budget.alert_enabled == True,
                Budget.alert_threshold.isnot(None)
            )
        ).all()

        alerts = []
        for budget in budgets:
            if budget.check_alert_threshold():
                budget.calculate_progress()
                alerts.append(budget.to_dict())

        return alerts