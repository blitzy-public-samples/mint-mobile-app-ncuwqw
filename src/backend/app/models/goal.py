"""
SQLAlchemy Goal model for the Mint Replica Lite application.

Human Tasks:
1. Verify database user has appropriate permissions for goals table operations
2. Set up monitoring for goal progress updates
3. Configure automated goal progress notifications
4. Review and set up backup strategy for goal data
5. Ensure proper database indices are created for query optimization
"""

# SQLAlchemy: ^1.4.0
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
from uuid import uuid4
from decimal import Decimal
from typing import Dict

from ..db.base import Base
from .user import User
from .account import Account

class Goal(Base):
    """
    SQLAlchemy model representing a financial goal in the system.
    
    Requirements addressed:
    - Goal Management (1.2): Implements financial goal setting and progress tracking
    - Database Schema (5.2.1): Defines goal table schema with proper relationships and indices
    """
    
    __tablename__ = 'goals'

    # Primary key and relationships
    id = Column(UUID, primary_key=True, default=uuid4, index=True)
    user_id = Column(UUID, ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    account_id = Column(UUID, ForeignKey('accounts.id', ondelete='CASCADE'), nullable=False, index=True)
    
    # Goal details
    name = Column(String(255), nullable=False)
    description = Column(String(1000), nullable=True)
    goal_type = Column(String(50), nullable=False)
    
    # Financial targets and progress
    target_amount = Column(Numeric(20, 2), nullable=False)
    current_amount = Column(Numeric(20, 2), nullable=False)
    
    # Goal status and timeline
    target_date = Column(DateTime, nullable=False)
    is_completed = Column(Boolean, default=False, nullable=False)
    completed_at = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="goals")
    account = relationship("Account", backref="goals")

    def __init__(
        self,
        user_id: UUID,
        account_id: UUID,
        name: str,
        description: str,
        goal_type: str,
        target_amount: Decimal,
        target_date: datetime
    ):
        """
        Initialize a new Goal instance.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal creation with proper initialization
        
        Args:
            user_id: UUID of the goal owner
            account_id: UUID of the linked account
            name: Goal name
            description: Detailed goal description
            goal_type: Type of financial goal
            target_amount: Target amount to achieve
            target_date: Target date for goal completion
            
        Raises:
            ValueError: If target_amount is negative or target_date is in the past
        """
        if target_amount <= Decimal('0'):
            raise ValueError("Target amount must be positive")
            
        if target_date < datetime.utcnow():
            raise ValueError("Target date cannot be in the past")

        self.id = uuid4()
        self.user_id = user_id
        self.account_id = account_id
        self.name = name.strip()
        self.description = description.strip() if description else None
        self.goal_type = goal_type
        self.target_amount = target_amount
        self.current_amount = Decimal('0')
        self.target_date = target_date
        self.is_completed = False
        self.completed_at = None
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def update_progress(self, amount: Decimal) -> bool:
        """
        Update goal progress and check completion status.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal progress tracking
        
        Args:
            amount: New current amount for the goal
            
        Returns:
            bool: True if goal is completed after update, False otherwise
            
        Raises:
            ValueError: If amount is negative
        """
        if amount < Decimal('0'):
            raise ValueError("Amount cannot be negative")

        self.current_amount = amount
        self.updated_at = datetime.utcnow()

        if not self.is_completed and self.current_amount >= self.target_amount:
            self.is_completed = True
            self.completed_at = datetime.utcnow()
            return True
            
        return False

    def calculate_progress_percentage(self) -> float:
        """
        Calculate goal progress as percentage.
        
        Requirements addressed:
        - Goal Management (1.2): Provides goal progress calculation
        
        Returns:
            float: Progress percentage between 0 and 100
        """
        if self.target_amount == Decimal('0'):
            return 0.0
            
        progress = (self.current_amount / self.target_amount) * 100
        return min(round(float(progress), 2), 100.0)

    def to_dict(self) -> Dict:
        """
        Convert goal model to dictionary representation.
        
        Requirements addressed:
        - Goal Management (1.2): Provides goal data representation
        
        Returns:
            Dict containing goal data
        """
        return {
            'id': str(self.id),
            'user_id': str(self.user_id),
            'account_id': str(self.account_id),
            'name': self.name,
            'description': self.description,
            'goal_type': self.goal_type,
            'target_amount': str(self.target_amount),
            'current_amount': str(self.current_amount),
            'progress_percentage': self.calculate_progress_percentage(),
            'target_date': self.target_date.isoformat(),
            'is_completed': self.is_completed,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }