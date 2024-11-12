"""
Alembic database migrations initialization module for Mint Replica Lite application.

# Human Tasks:
1. Verify PostgreSQL server is running and accessible
2. Ensure database user has sufficient privileges for schema migrations
3. Review migration scripts before applying to production database
4. Configure backup strategy before running migrations in production
5. Set up monitoring for migration execution in production environment
"""

# alembic v1.7.0
from alembic import alembic

# Import migration execution functions from env module
from .env import run_migrations_offline, run_migrations_online

# Package version
__version__ = "1.0.0"

# Requirement: Database Schema Management (5.2.1 Schema Design)
# - Initialize and configure database schema version control system
# - Export migration execution functions for both offline and online modes

# Requirement: Data Storage Architecture (2.1 High-Level Architecture Overview/Data Layer)
# - Configure PostgreSQL schema migration support
# - Enable database schema versioning system for evolution management

__all__ = [
    "run_migrations_offline",
    "run_migrations_online"
]