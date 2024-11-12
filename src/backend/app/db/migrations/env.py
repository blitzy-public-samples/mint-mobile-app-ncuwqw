# SQLAlchemy v1.4.0
# Alembic v1.7.0

# Human Tasks:
# 1. Verify PostgreSQL server is running and accessible
# 2. Ensure database user has sufficient privileges for schema migrations
# 3. Review migration scripts before applying to production database
# 4. Configure backup strategy before running migrations in production
# 5. Set up monitoring for migration execution in production environment

from logging.config import fileConfig
import logging
from typing import Optional

from alembic import context
from sqlalchemy import create_engine
from sqlalchemy import pool

from db.base import Base
from core.config import Settings

# Initialize logging for Alembic migrations
logger = logging.getLogger('alembic.env')

# This is the Alembic Config object, which provides access to the values within the .ini file
config = context.config

# Interpret the config file for Python logging unless explicitly disabled
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Set SQLAlchemy MetaData object containing all model definitions
# Requirement: Database Schema Management (5.2.1 Schema Design)
# - Uses SQLAlchemy metadata for schema version control
target_metadata = Base.metadata

# Initialize settings
settings = Settings()

def get_database_url() -> str:
    """
    Constructs database URL from application settings.
    
    Requirement: Database Architecture (2.1 Data Layer)
    - Configures PostgreSQL connection URL for migrations
    
    Returns:
        str: PostgreSQL connection URL
    """
    db_settings = settings.get_database_settings()
    return (
        f"postgresql://{db_settings['username']}:{db_settings['password']}"
        f"@{db_settings['host']}:{db_settings['port']}/{db_settings['database']}"
    )

def run_migrations_offline() -> None:
    """
    Run migrations in 'offline' mode.
    
    Requirement: Database Schema Management (5.2.1 Schema Design)
    - Supports offline migration script generation
    
    This configures the context with just a URL and not an Engine,
    though an Engine is acceptable here as well. By skipping the Engine
    creation we don't even need a DBAPI to be available.
    """
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True
    )

    try:
        with context.begin_transaction():
            logger.info("Running offline migrations...")
            context.run_migrations()
            logger.info("Offline migrations completed successfully")
    except Exception as e:
        logger.error(f"Error during offline migrations: {str(e)}")
        raise

def run_migrations_online() -> None:
    """
    Run migrations in 'online' mode.
    
    Requirement: Database Architecture (2.1 Data Layer)
    - Implements direct database schema updates
    Requirement: Database Schema Management (5.2.1 Schema Design)
    - Manages database schema versions with transaction support
    """
    # Configure SQLAlchemy engine with connection pooling
    engine = create_engine(
        get_database_url(),
        poolclass=pool.NullPool,  # Disable pooling for migrations
        connect_args={
            "sslmode": settings.get_database_settings()["ssl_mode"],
            "connect_timeout": 60  # 60 seconds connection timeout
        }
    )

    # Create a connection for the migration
    connection = engine.connect()

    try:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
            include_schemas=True,
            transaction_per_migration=True,
            render_as_batch=True
        )

        logger.info("Starting online migrations...")
        with context.begin_transaction():
            context.run_migrations()
        logger.info("Online migrations completed successfully")

    except Exception as e:
        logger.error(f"Error during online migrations: {str(e)}")
        raise
    finally:
        connection.close()
        engine.dispose()

if context.is_offline_mode():
    logger.info("Running migrations in offline mode")
    run_migrations_offline()
else:
    logger.info("Running migrations in online mode")
    run_migrations_online()