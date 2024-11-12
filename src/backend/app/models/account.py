"""
SQLAlchemy Account model for the Mint Replica Lite application.

Human Tasks:
1. Verify database user has appropriate permissions for account table operations
2. Set up monitoring for balance update operations
3. Configure automated balance sync scheduling
4. Review and set up backup strategy for financial data
5. Ensure proper database indices are created for query optimization
"""

# SQLAlchemy: ^1.4.0
from sqlalchemy import Column, String, Numeric, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from datetime import datetime
from uuid import uuid4
from decimal import Decimal
from typing import Dict, Optional

from ..db.base import Base
from .user import User

class Account(Base):
    """
    SQLAlchemy model representing a financial account in the system.
    
    Requirements addressed:
    - Account Management (1.2): Implements financial account aggregation and real-time balance updates
    - Data Storage (2.1): Implements PostgreSQL database model for financial accounts
    - Database Schema (5.2.1): Defines account table schema with proper relationships and indices
    """
    
    __tablename__ = 'accounts'

    # Primary key and relationships
    id = Column(UUID, primary_key=True, default=uuid4, index=True)
    user_id = Column(UUID, ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    
    # Account identification and type
    institution_id = Column(String(50), nullable=False, index=True)
    account_type = Column(String(50), nullable=False)
    account_name = Column(String(255), nullable=False)
    account_number_masked = Column(String(20), nullable=False)
    
    # Balance information
    current_balance = Column(Numeric(20, 2), nullable=False)
    available_balance = Column(Numeric(20, 2), nullable=False)
    currency_code = Column(String(3), nullable=False)
    
    # Additional metadata
    institution_data = Column(JSONB, nullable=False, default={})
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Timestamps
    last_synced_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="accounts")
    transactions = relationship("Transaction", back_populates="account", cascade="all, delete-orphan")

    def __init__(
        self,
        user_id: UUID,
        institution_id: str,
        account_type: str,
        account_name: str,
        account_number_masked: str,
        current_balance: Decimal,
        currency_code: str
    ):
        """
        Initialize a new Account instance with required fields.
        
        Requirements addressed:
        - Account Management (1.2): Implements account creation with proper initialization
        
        Args:
            user_id: UUID of the account owner
            institution_id: Identifier for the financial institution
            account_type: Type of account (e.g., checking, savings)
            account_name: Display name for the account
            account_number_masked: Masked account number for display
            current_balance: Initial account balance
            currency_code: ISO currency code (e.g., USD)
        """
        self.id = uuid4()
        self.user_id = user_id
        self.institution_id = institution_id
        self.account_type = account_type
        self.account_name = account_name
        self.account_number_masked = account_number_masked
        self.current_balance = current_balance
        self.available_balance = current_balance  # Initially set to current_balance
        self.currency_code = currency_code
        self.institution_data = {}
        self.is_active = True
        self.last_synced_at = datetime.utcnow()
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def update_balance(self, current_balance: Decimal, available_balance: Optional[Decimal] = None) -> None:
        """
        Update account balance with validation.
        
        Requirements addressed:
        - Account Management (1.2): Supports real-time balance updates
        
        Args:
            current_balance: New current balance amount
            available_balance: New available balance amount (defaults to current_balance if None)
            
        Raises:
            ValueError: If balance amounts are negative or invalid
        """
        if current_balance is None:
            raise ValueError("Current balance cannot be None")
        
        if not isinstance(current_balance, Decimal):
            raise ValueError("Current balance must be a Decimal value")
            
        if current_balance < Decimal('0'):
            raise ValueError("Current balance cannot be negative")
            
        self.current_balance = current_balance
        self.available_balance = available_balance if available_balance is not None else current_balance
        
        if self.available_balance < Decimal('0'):
            raise ValueError("Available balance cannot be negative")
            
        self.last_synced_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def update_institution_data(self, institution_data: Dict) -> None:
        """
        Update institution-specific data in JSONB format.
        
        Requirements addressed:
        - Account Management (1.2): Maintains institution-specific metadata
        
        Args:
            institution_data: Dictionary containing institution-specific data
            
        Raises:
            ValueError: If institution_data is not a valid dictionary
        """
        if not isinstance(institution_data, dict):
            raise ValueError("Institution data must be a dictionary")
            
        # Merge new data with existing data, preserving structure
        current_data = dict(self.institution_data)  # Create a copy
        current_data.update(institution_data)
        self.institution_data = current_data
        self.updated_at = datetime.utcnow()

    def to_dict(self) -> Dict:
        """
        Convert account model to dictionary representation.
        
        Requirements addressed:
        - Account Management (1.2): Provides sanitized account data representation
        
        Returns:
            Dict containing account data with sensitive information masked
        """
        return {
            'id': str(self.id),
            'user_id': str(self.user_id),
            'institution_id': self.institution_id,
            'account_type': self.account_type,
            'account_name': self.account_name,
            'account_number_masked': self.account_number_masked,
            'current_balance': str(self.current_balance),
            'available_balance': str(self.available_balance),
            'currency_code': self.currency_code,
            'institution_data': dict(self.institution_data),
            'is_active': self.is_active,
            'last_synced_at': self.last_synced_at.isoformat() if self.last_synced_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }