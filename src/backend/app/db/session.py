"""
Database session management module for Mint Replica Lite application.

Human Tasks:
1. Ensure PostgreSQL server is running and accessible
2. Configure database connection parameters in environment variables
3. Set up database user with appropriate permissions
4. Configure connection pool size based on production load requirements
5. Monitor connection pool usage in production
"""

# sqlalchemy: ^1.4.0
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session
from contextlib import contextmanager
import logging

from ..core.config import Settings
from ..core.errors import DatabaseError
from .base import Base

# Initialize logger
logger = logging.getLogger(__name__)

# Create database engine with connection pooling
# Requirement: Database Architecture - Configure PostgreSQL for primary data storage
# with proper session management and connection pooling
engine = create_engine(
    Settings().get_database_settings()['DATABASE_URL'],
    pool_size=5,  # Number of permanent connections
    max_overflow=10,  # Additional connections when pool is full
    pool_timeout=30,  # Seconds to wait for available connection
    pool_pre_ping=True,  # Enable connection health checks
    echo=False  # Set to True for SQL query logging
)

# Create session factory
# Requirement: Database Architecture - Implement proper session management
# and transaction handling
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

@contextmanager
def get_db() -> Session:
    """
    Get database session from the connection pool with automatic transaction management.
    
    Requirement: Data Security - Implement secure database connections and session
    handling with proper resource cleanup
    
    Yields:
        Session: Database session instance with active transaction
        
    Raises:
        DatabaseError: If database operations fail
    """
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception as e:
        session.rollback()
        logger.error(f"Database transaction failed: {str(e)}")
        raise DatabaseError(f"Database operation failed: {str(e)}")
    finally:
        session.close()

def init_db() -> None:
    """
    Initialize database schema and tables using SQLAlchemy Base metadata.
    
    Requirement: Database Architecture - Configure PostgreSQL for primary data storage
    with proper schema management
    
    Raises:
        DatabaseError: If schema creation fails
    """
    try:
        # Import all models to register with Base metadata
        from ..models import (  # noqa: F401
            user,
            account,
            transaction,
            category,
            budget,
            goal
        )
        
        # Create all tables
        Base.metadata.create_all(bind=engine)
        logger.info("Database schema initialized successfully")
    except Exception as e:
        logger.error(f"Database initialization failed: {str(e)}")
        raise DatabaseError(f"Failed to initialize database schema: {str(e)}")

def dispose_engine() -> None:
    """
    Properly dispose database engine connections and cleanup resources.
    
    Requirement: Data Security - Implement proper resource cleanup for database
    connections
    """
    try:
        engine.dispose()
        logger.info("Database engine disposed successfully")
    except Exception as e:
        logger.error(f"Failed to dispose database engine: {str(e)}")
        raise DatabaseError(f"Failed to cleanup database resources: {str(e)}")