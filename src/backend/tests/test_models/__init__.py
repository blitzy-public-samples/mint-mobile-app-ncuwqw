"""
Test models package initialization module providing shared test utilities and fixtures.

Human Tasks:
1. Review and adjust MODEL_TEST_TIMEOUT if needed based on test environment performance
2. Ensure test database and authentication configurations are properly set up
"""

# pytest: ^7.0.0

from typing import Dict
from sqlalchemy.ext.asyncio import AsyncSession
from ..conftest import test_db, test_auth_headers

# Global timeout setting for model tests (in seconds)
# Requirement: Testing Infrastructure - Configure appropriate timeouts for model tests
MODEL_TEST_TIMEOUT: int = 30

# Re-export test fixtures for model testing
__all__ = ['test_db', 'test_auth_headers']

# Requirement: Testing Infrastructure - Implement comprehensive test infrastructure
# for data models with isolated database sessions and authentication contexts
#
# This module provides centralized access to essential test fixtures for model testing:
# - test_db: Provides isolated database sessions with automatic transaction rollback
# - test_auth_headers: Provides authentication context for testing secured model operations
#
# These fixtures ensure that:
# 1. Each test runs in isolation with a clean database state
# 2. All database changes are rolled back after each test
# 3. Authenticated operations can be tested with valid JWT tokens
# 4. Sensitive data handling can be verified in a secure test environment

# Requirement: Data Security - Support testing of secure data handling
# The test_auth_headers fixture provides a secure authentication context
# for testing model operations that involve sensitive data, ensuring that:
# - All authenticated model operations are tested with valid JWT tokens
# - Authorization headers follow security best practices
# - Test user context includes appropriate security scopes