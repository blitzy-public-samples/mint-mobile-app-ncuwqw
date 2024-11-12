# SQLAlchemy v1.4.0
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship

from app.db.base import Base
from app.utils.datetime import get_current_datetime

# Human Tasks:
# 1. Verify PostgreSQL schema permissions for category table creation
# 2. Set up initial system categories during database migration
# 3. Review category hierarchy depth limits for performance optimization
# 4. Configure appropriate database indices for category queries

class Category(Base):
    """
    SQLAlchemy model representing a transaction category in the system.
    Supports hierarchical structure with parent-child relationships.
    
    Requirements addressed:
    - Financial Tracking (1.2 Scope/Financial Tracking):
      Implements hierarchical category structure and system-defined categories
    - Budget Management (1.2 Scope/Budget Management):
      Enables category-based budget tracking with system and custom categories
    """
    
    __tablename__ = 'categories'

    # Primary key and identification
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    
    # Category details
    name = Column(String(100), nullable=False, index=True, unique=True)
    description = Column(String(255), nullable=True)
    
    # Hierarchical relationship
    parent_id = Column(Integer, ForeignKey('categories.id', ondelete='CASCADE'), 
                      nullable=True, index=True)
    
    # Category flags
    is_system = Column(Boolean, default=False, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False, index=True)
    
    # Audit timestamps
    created_at = Column(DateTime, nullable=False, default=get_current_datetime)
    updated_at = Column(DateTime, nullable=False, default=get_current_datetime, 
                       onupdate=get_current_datetime)
    
    # Relationships
    parent = relationship('Category', remote_side=[id], backref='subcategories', 
                         lazy='joined')
    transactions = relationship('Transaction', back_populates='category', 
                              lazy='dynamic')
    budgets = relationship('Budget', back_populates='category', lazy='dynamic')

    def __init__(self, name: str, description: str = None, 
                 parent_id: int = None, is_system: bool = False):
        """
        Initialize a new Category instance.
        
        Args:
            name (str): Category name, must be unique
            description (str, optional): Category description
            parent_id (int, optional): ID of parent category for hierarchical structure
            is_system (bool, optional): Flag indicating if this is a system category
        
        Raises:
            ValueError: If name is empty or invalid
        """
        if not name or not name.strip():
            raise ValueError("Category name cannot be empty")
        
        self.name = name.strip()
        self.description = description.strip() if description else None
        self.parent_id = parent_id
        self.is_system = is_system
        self.is_active = True
        
        # Set audit timestamps
        current_time = get_current_datetime()
        self.created_at = current_time
        self.updated_at = current_time

    def to_dict(self) -> dict:
        """
        Converts category model to dictionary representation.
        
        Returns:
            dict: Dictionary containing category attributes and relationships
        
        Requirements addressed:
        - Financial Tracking (1.2 Scope/Financial Tracking):
          Provides complete category data for UI display and API responses
        """
        result = {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'parent_id': self.parent_id,
            'is_system': self.is_system,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'subcategories_count': len(self.subcategories) if self.subcategories else 0,
            'transactions_count': self.transactions.count() if self.transactions else 0,
            'budgets_count': self.budgets.count() if self.budgets else 0
        }
        
        # Include parent category details if exists
        if self.parent:
            result['parent'] = {
                'id': self.parent.id,
                'name': self.parent.name,
                'is_system': self.parent.is_system
            }
        
        return result