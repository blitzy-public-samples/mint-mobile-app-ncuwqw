"""
Database package initialization module for Mint Replica Lite application.

Human Tasks:
1. Ensure PostgreSQL server is running and accessible
2. Configure database connection parameters in environment variables
3. Set up database user with appropriate permissions
4. Configure connection pool size based on production load requirements
5. Monitor connection pool usage in production
6. Set up database migration tools (Alembic) for schema management
7. Verify PostgreSQL schema permissions for the application user
"""

# Import core database components from their respective modules
from .base import Base
from .session import (
    get_db,
    init_db,
    dispose_engine,
    SessionLocal
)

# Requirement: Database Architecture (2.1 High-Level Architecture Overview/Data Layer)
# Configure PostgreSQL as primary data storage with SQLAlchemy ORM integration
__all__ = [
    'Base',           # SQLAlchemy declarative base for model definitions
    'get_db',         # Database session context manager
    'init_db',        # Database initialization function
    'dispose_engine', # Database cleanup function
    'SessionLocal'    # Session factory for database connections
]

# Requirement: Data Layer Configuration (2.2 Component Architecture/2.2.1 Client Applications/Shared Services)
# Initialize database components and expose core database functionality
# Note: The actual database initialization happens when init_db() is called by the application