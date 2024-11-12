# SQLAlchemy v1.4.0
from sqlalchemy.orm import declarative_base, as_declarative, declared_attr

# Human Tasks:
# 1. Ensure PostgreSQL server is running and accessible
# 2. Configure database connection string in environment variables
# 3. Set up database migration tools (Alembic) for schema management
# 4. Verify PostgreSQL schema permissions for the application user

@as_declarative()
class Base:
    """
    SQLAlchemy declarative base class that provides common functionality for all database models
    including automatic table name generation and metadata configuration.
    
    Requirements addressed:
    - Database Architecture (5.2.1 Schema Design): Implements SQLAlchemy declarative base 
      for PostgreSQL schema management with proper table naming conventions
    - Data Storage (2.1 Data Layer): Configures base class for PostgreSQL data storage 
      with SQLAlchemy ORM integration
    """

    # Shared metadata instance for schema-wide configuration
    metadata = None  # SQLAlchemy assigns MetaData() automatically
    
    # Required in combination with @declared_attr
    __name__: str

    @declared_attr
    def __tablename__(cls) -> str:
        """
        Automatically generates PostgreSQL table name from the model class name.
        Follows PostgreSQL naming convention of lowercase snake_case table names.
        
        Returns:
            str: Lowercase table name derived from the class name
        
        Example:
            UserAccount -> user_account
            TransactionCategory -> transaction_category
        """
        # Convert camel case to snake case and lowercase
        # e.g., UserAccount -> user_account
        name = cls.__name__
        return ''.join(
            ['_' + char.lower() if char.isupper() else char.lower()
             for char in name]
        ).lstrip('_')