# SQLAlchemy: ^1.4.0
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB
from uuid import uuid4
from datetime import datetime
from decimal import Decimal

from ..db.base import Base
from .account import Account

# Human Tasks:
# 1. Verify database user has appropriate permissions for investment table operations
# 2. Set up monitoring for investment value updates
# 3. Configure automated investment sync scheduling
# 4. Review and set up backup strategy for investment data
# 5. Ensure proper database indices are created for performance optimization

class Investment(Base):
    """
    SQLAlchemy model representing an investment holding or position in the system.
    
    Requirements addressed:
    - Investment Tracking (1.2 Scope/Investment Tracking): Implements basic portfolio monitoring
      and investment account integration with performance metrics
    - Data Storage (2.1 High-Level Architecture Overview/Data Layer): Implements PostgreSQL 
      database model for investment tracking
    - Database Schema (5.2.1 Schema Design): Defines investment table schema with proper
      relationships and indices
    """
    
    __tablename__ = 'investments'

    # Primary key and relationships
    id = Column(UUID, primary_key=True, default=uuid4, index=True)
    account_id = Column(UUID, ForeignKey('accounts.id', ondelete='CASCADE'), nullable=False, index=True)
    
    # Investment details
    symbol = Column(String(10), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    investment_type = Column(String(50), nullable=False, index=True)
    
    # Position and value information
    quantity = Column(Numeric(20, 8), nullable=False)
    cost_basis = Column(Numeric(20, 2), nullable=False)
    current_value = Column(Numeric(20, 2), nullable=False)
    unrealized_gain_loss = Column(Numeric(20, 2), nullable=False)
    return_percentage = Column(Numeric(10, 4), nullable=False)
    currency_code = Column(String(3), nullable=False)
    
    # Additional metadata
    metadata = Column(JSONB, nullable=False, default={})
    is_active = Column(Boolean, default=True, nullable=False)
    
    # Timestamps
    last_synced_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    account = relationship("Account", back_populates="investments")

    def __init__(
        self,
        account_id: UUID,
        symbol: str,
        name: str,
        investment_type: str,
        quantity: Decimal,
        cost_basis: Decimal,
        current_value: Decimal,
        currency_code: str
    ):
        """
        Initialize a new Investment instance with required fields.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements investment position creation with proper initialization
        
        Args:
            account_id: UUID of the associated account
            symbol: Investment symbol/ticker
            name: Full name of the investment
            investment_type: Type of investment (e.g., stock, bond, mutual fund)
            quantity: Number of shares/units held
            cost_basis: Total cost basis of the position
            current_value: Current market value of the position
            currency_code: ISO currency code (e.g., USD)
            
        Raises:
            ValueError: If decimal inputs are negative or invalid
        """
        if not isinstance(quantity, Decimal) or quantity < Decimal('0'):
            raise ValueError("Quantity must be a non-negative Decimal value")
            
        if not isinstance(cost_basis, Decimal) or cost_basis < Decimal('0'):
            raise ValueError("Cost basis must be a non-negative Decimal value")
            
        if not isinstance(current_value, Decimal) or current_value < Decimal('0'):
            raise ValueError("Current value must be a non-negative Decimal value")

        self.id = uuid4()
        self.account_id = account_id
        self.symbol = symbol
        self.name = name
        self.investment_type = investment_type
        self.quantity = quantity
        self.cost_basis = cost_basis
        self.current_value = current_value
        self.currency_code = currency_code
        
        # Calculate initial performance metrics
        self.unrealized_gain_loss = current_value - cost_basis
        self.return_percentage = ((current_value - cost_basis) / cost_basis * Decimal('100')
                                if cost_basis > Decimal('0') else Decimal('0'))
        
        self.metadata = {}
        self.is_active = True
        self.last_synced_at = datetime.utcnow()
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def update_value(self, current_value: Decimal, quantity: Decimal = None) -> None:
        """
        Update investment value and recalculate performance metrics.
        
        Requirements addressed:
        - Investment Tracking (1.2): Supports real-time value updates and performance tracking
        
        Args:
            current_value: New current market value
            quantity: New quantity if changed (optional)
            
        Raises:
            ValueError: If value amounts are negative or invalid
        """
        if not isinstance(current_value, Decimal) or current_value < Decimal('0'):
            raise ValueError("Current value must be a non-negative Decimal value")
            
        if quantity is not None:
            if not isinstance(quantity, Decimal) or quantity < Decimal('0'):
                raise ValueError("Quantity must be a non-negative Decimal value")
            self.quantity = quantity
            
        self.current_value = current_value
        self.unrealized_gain_loss = current_value - self.cost_basis
        self.return_percentage = ((current_value - self.cost_basis) / self.cost_basis * Decimal('100')
                                if self.cost_basis > Decimal('0') else Decimal('0'))
        
        self.last_synced_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def update_metadata(self, metadata: dict) -> None:
        """
        Update investment-specific metadata in JSONB format.
        
        Requirements addressed:
        - Investment Tracking (1.2): Maintains investment-specific metadata
        
        Args:
            metadata: Dictionary containing investment-specific data
            
        Raises:
            ValueError: If metadata is not a valid dictionary
        """
        if not isinstance(metadata, dict):
            raise ValueError("Metadata must be a dictionary")
            
        # Merge new data with existing data, preserving structure
        current_data = dict(self.metadata)  # Create a copy
        current_data.update(metadata)
        self.metadata = current_data
        self.updated_at = datetime.utcnow()

    def to_dict(self) -> dict:
        """
        Convert investment model to dictionary representation.
        
        Requirements addressed:
        - Investment Tracking (1.2): Provides standardized investment data representation
        
        Returns:
            Dict containing investment data with proper formatting
        """
        return {
            'id': str(self.id),
            'account_id': str(self.account_id),
            'symbol': self.symbol,
            'name': self.name,
            'investment_type': self.investment_type,
            'quantity': str(self.quantity),
            'cost_basis': str(self.cost_basis),
            'current_value': str(self.current_value),
            'unrealized_gain_loss': str(self.unrealized_gain_loss),
            'return_percentage': str(self.return_percentage),
            'currency_code': self.currency_code,
            'metadata': dict(self.metadata),
            'is_active': self.is_active,
            'last_synced_at': self.last_synced_at.isoformat() if self.last_synced_at else None,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }