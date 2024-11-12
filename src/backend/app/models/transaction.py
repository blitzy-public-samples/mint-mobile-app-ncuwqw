# SQLAlchemy v1.4.0
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, Boolean, Index
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from uuid import uuid4
from decimal import Decimal
from datetime import datetime
from typing import Optional, Dict

from ..db.base import Base
from .account import Account
from .category import Category
from ..utils.datetime import get_current_datetime

# Human Tasks:
# 1. Verify PostgreSQL schema permissions for transaction table creation
# 2. Set up appropriate database indices for transaction queries
# 3. Configure monitoring for transaction volume and performance
# 4. Review and set up backup strategy for transaction data
# 5. Set up alerts for failed transaction imports

class Transaction(Base):
    """
    SQLAlchemy model representing a financial transaction in the system.
    
    Requirements addressed:
    - Financial Tracking (1.2 Scope/Financial Tracking):
      Implements automated transaction import and category management
    - Data Storage (2.1 High-Level Architecture Overview/Data Layer):
      Implements PostgreSQL database model for financial transactions
    - Database Schema (5.2.1 Schema Design):
      Defines transaction table schema with proper relationships and indices
    """
    
    __tablename__ = 'transactions'

    # Primary key and relationships
    id = Column(UUID, primary_key=True, default=uuid4)
    account_id = Column(UUID, ForeignKey('accounts.id'), nullable=False, index=True)
    category_id = Column(Integer, ForeignKey('categories.id'), nullable=True, index=True)
    
    # Transaction details
    transaction_date = Column(DateTime, nullable=False, index=True)
    post_date = Column(DateTime, nullable=True)
    amount = Column(Numeric(precision=10, scale=2), nullable=False)
    description = Column(String(255), nullable=False)
    merchant_name = Column(String(100), nullable=True, index=True)
    transaction_type = Column(String(50), nullable=False)
    
    # Status fields
    status = Column(String(20), nullable=False, default='pending')
    is_pending = Column(Boolean, nullable=False, default=True)
    
    # Additional data
    metadata = Column(JSONB, nullable=True)
    
    # Audit timestamps
    created_at = Column(DateTime, nullable=False, default=get_current_datetime)
    updated_at = Column(DateTime, nullable=False, default=get_current_datetime, 
                       onupdate=get_current_datetime)
    
    # Relationships
    account = relationship('Account', back_populates='transactions')
    category = relationship('Category', back_populates='transactions')
    
    # Create indices for common query patterns
    __table_args__ = (
        Index('ix_transactions_account_date', 'account_id', 'transaction_date'),
        Index('ix_transactions_category_date', 'category_id', 'transaction_date'),
        Index('ix_transactions_status_date', 'status', 'transaction_date'),
    )

    def __init__(
        self,
        account_id: UUID,
        transaction_date: datetime,
        amount: Decimal,
        description: str,
        transaction_type: str
    ):
        """
        Initialize a new Transaction instance.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements transaction creation with proper initialization
        
        Args:
            account_id: UUID of the associated account
            transaction_date: Date/time when transaction occurred
            amount: Transaction amount (positive for credits, negative for debits)
            description: Transaction description
            transaction_type: Type of transaction (e.g., purchase, transfer, payment)
        
        Raises:
            ValueError: If required parameters are invalid
        """
        if not account_id:
            raise ValueError("Account ID is required")
        if not transaction_date:
            raise ValueError("Transaction date is required")
        if amount is None:
            raise ValueError("Amount is required")
        if not description or not description.strip():
            raise ValueError("Description is required")
        if not transaction_type or not transaction_type.strip():
            raise ValueError("Transaction type is required")
            
        self.id = uuid4()
        self.account_id = account_id
        self.transaction_date = transaction_date
        self.amount = amount
        self.description = description.strip()
        self.transaction_type = transaction_type.strip()
        self.status = 'pending'
        self.is_pending = True
        self.metadata = {}
        
        # Set audit timestamps
        current_time = get_current_datetime()
        self.created_at = current_time
        self.updated_at = current_time

    def update_category(self, category_id: Optional[int]) -> None:
        """
        Update transaction category with validation.
        
        Requirements addressed:
        - Financial Tracking (1.2): Supports transaction categorization
        
        Args:
            category_id: ID of the category to assign, or None to remove category
            
        Raises:
            ValueError: If category_id is invalid
        """
        if category_id is not None and not isinstance(category_id, int):
            raise ValueError("Category ID must be an integer or None")
            
        self.category_id = category_id
        self.updated_at = get_current_datetime()

    def update_status(self, status: str, is_pending: bool) -> None:
        """
        Update transaction status and pending flag.
        
        Requirements addressed:
        - Financial Tracking (1.2): Supports transaction status management
        
        Args:
            status: New status value (pending, posted, cancelled)
            is_pending: Flag indicating if transaction is pending
            
        Raises:
            ValueError: If status is invalid
        """
        valid_statuses = {'pending', 'posted', 'cancelled'}
        if status not in valid_statuses:
            raise ValueError(f"Status must be one of: {', '.join(valid_statuses)}")
            
        self.status = status
        self.is_pending = is_pending
        self.updated_at = get_current_datetime()

    def update_metadata(self, metadata: Dict) -> None:
        """
        Update transaction metadata.
        
        Requirements addressed:
        - Financial Tracking (1.2): Supports additional transaction data storage
        
        Args:
            metadata: Dictionary containing additional transaction data
            
        Raises:
            ValueError: If metadata is not a valid dictionary
        """
        if not isinstance(metadata, dict):
            raise ValueError("Metadata must be a dictionary")
            
        # Merge with existing metadata
        current_data = dict(self.metadata or {})
        current_data.update(metadata)
        self.metadata = current_data
        self.updated_at = get_current_datetime()

    def to_dict(self) -> Dict:
        """
        Convert transaction model to dictionary representation.
        
        Requirements addressed:
        - Financial Tracking (1.2): Provides transaction data representation
        
        Returns:
            Dict containing transaction data with related entities
        """
        result = {
            'id': str(self.id),
            'account_id': str(self.account_id),
            'category_id': self.category_id,
            'transaction_date': self.transaction_date.isoformat(),
            'post_date': self.post_date.isoformat() if self.post_date else None,
            'amount': str(self.amount),
            'description': self.description,
            'merchant_name': self.merchant_name,
            'transaction_type': self.transaction_type,
            'status': self.status,
            'is_pending': self.is_pending,
            'metadata': dict(self.metadata) if self.metadata else {},
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
        
        # Include category data if exists
        if self.category:
            result['category'] = self.category.to_dict()
            
        return result