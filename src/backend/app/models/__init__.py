"""
SQLAlchemy models initialization module for Mint Replica Lite financial management system.

Human Tasks:
1. Verify all model tables are created in correct order during database migrations
2. Ensure proper database user permissions are set for all model operations
3. Review and configure appropriate connection pool settings
4. Set up database monitoring and performance metrics collection
"""

# Import all models to make them available when importing from models package
from .user import User
from .account import Account
from .transaction import Transaction
from .category import Category
from .budget import Budget
from .goal import Goal
from .investment import Investment

# Define models to be imported when using "from models import *"
__all__ = [
    'User',
    'Account', 
    'Transaction',
    'Category',
    'Budget',
    'Goal',
    'Investment'
]

"""
Requirements addressed:
- Data Storage (2.1 High-Level Architecture Overview/Data Layer):
  Centralizes access to all PostgreSQL database models for the application
  
- Database Schema (5.2.1 Schema Design):
  Exposes properly defined models with relationships and indices through a clean interface
"""