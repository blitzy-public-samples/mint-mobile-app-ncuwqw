# SQLAlchemy v1.4.0
from decimal import Decimal
from sqlalchemy import Column, Integer, Numeric, String, Boolean, DateTime, UUID, JSON, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.datetime import get_current_datetime

# Human Tasks:
# 1. Verify PostgreSQL JSON column type support is enabled
# 2. Set up database triggers for updated_at timestamp if needed
# 3. Configure appropriate database indices for query optimization
# 4. Review and adjust numeric precision settings if needed

class Budget(Base):
    """
    SQLAlchemy model representing a budget with category-based tracking and configurable alerts.
    
    Requirements addressed:
    - Budget Management (1.2 Scope/Budget Management): 
      Implements category-based budgeting with progress monitoring and customizable alerts
    - Database Schema (5.2 Database Design/5.2.1 Schema Design):
      Defines budget model with proper relationships to users and categories
    """
    
    # Primary key and relationships
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(UUID, ForeignKey('users.id'), nullable=False, index=True)
    category_id = Column(Integer, ForeignKey('categories.id'), nullable=False, index=True)
    
    # Budget configuration
    name = Column(String(100), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    period = Column(String(20), nullable=False)  # daily, weekly, monthly, yearly
    start_date = Column(DateTime, nullable=False)
    end_date = Column(DateTime, nullable=True)
    
    # Alert settings
    alert_threshold = Column(Integer, nullable=True)  # Percentage threshold for alerts
    alert_enabled = Column(Boolean, default=True, nullable=False)
    
    # Status and custom rules
    is_active = Column(Boolean, default=True, nullable=False)
    rules = Column(JSON, nullable=True)  # Custom budget rules in JSON format
    
    # Audit timestamps
    created_at = Column(DateTime, nullable=False, default=get_current_datetime)
    updated_at = Column(DateTime, nullable=False, default=get_current_datetime, onupdate=get_current_datetime)
    
    # Relationships
    user = relationship('User', back_populates='budgets')
    category = relationship('Category', back_populates='budgets')
    
    def calculate_progress(self) -> dict:
        """
        Calculates current spending progress against budget amount for the configured period.
        
        Returns:
            dict: Contains spent_amount (Decimal), remaining_amount (Decimal), and percentage (float)
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Enables progress monitoring with precise calculations
        """
        # Import here to avoid circular dependencies
        from app.models import Transaction
        from sqlalchemy import func
        from sqlalchemy.sql import and_
        
        # Get current period date range
        from app.utils.datetime import get_date_range
        period_start, period_end = get_date_range(self.period, get_current_datetime())
        
        # Query total spent amount for current period
        spent_amount = db.session.query(
            func.sum(Transaction.amount)
        ).filter(
            and_(
                Transaction.category_id == self.category_id,
                Transaction.user_id == self.user_id,
                Transaction.date >= period_start,
                Transaction.date < period_end,
                Transaction.type == 'expense'
            )
        ).scalar() or Decimal('0.00')
        
        # Calculate remaining amount and percentage
        remaining_amount = max(self.amount - spent_amount, Decimal('0.00'))
        percentage = float(
            (spent_amount / self.amount * 100) if self.amount > 0 else 0
        )
        
        return {
            'spent_amount': spent_amount,
            'remaining_amount': remaining_amount,
            'percentage': min(percentage, 100.0)  # Cap at 100%
        }
    
    def check_alert_threshold(self) -> bool:
        """
        Checks if spending has crossed the configured alert threshold percentage.
        
        Returns:
            bool: True if threshold is crossed and alert should be triggered
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Implements customizable spending alerts
        """
        if not self.alert_enabled or self.alert_threshold is None:
            return False
            
        progress = self.calculate_progress()
        return progress['percentage'] >= self.alert_threshold
    
    def to_dict(self) -> dict:
        """
        Converts budget model instance to dictionary representation with relationships.
        
        Returns:
            dict: Dictionary containing budget attributes, category info, and progress metrics
        
        Requirements addressed:
        - Budget Management (1.2 Scope/Budget Management):
          Provides comprehensive budget status representation
        """
        progress = self.calculate_progress()
        
        return {
            'id': self.id,
            'user_id': self.user_id,
            'category_id': self.category_id,
            'category_name': self.category.name if self.category else None,
            'category_type': self.category.type if self.category else None,
            'name': self.name,
            'amount': float(self.amount),
            'period': self.period,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'alert_threshold': self.alert_threshold,
            'alert_enabled': self.alert_enabled,
            'is_active': self.is_active,
            'rules': self.rules,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat(),
            'progress': progress,
            'alert_triggered': self.check_alert_threshold()
        }