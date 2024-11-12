"""
Package initializer for test_services module containing test suites for backend services.

Human Tasks:
1. Verify test database and Redis instances are running before executing service tests
2. Review test isolation settings in conftest.py if tests interfere with each other
3. Ensure proper test user roles and permissions are configured
"""

# pytest: ^7.0.0
# pytest-asyncio: ^0.18.0

import os
from tests.conftest import (
    test_db,
    test_cache,
    test_client,
    test_auth_headers
)

# Requirement: Testing Infrastructure - Implement comprehensive test infrastructure 
# for backend services with proper test organization and isolation
TEST_SERVICES_PATH = os.path.dirname(os.path.abspath(__file__))

# Re-export core test fixtures for service test modules
# Requirement: Service Testing - Support comprehensive testing of all backend services 
# including authentication, financial data handling, and integrations
__all__ = [
    'TEST_SERVICES_PATH',
    'test_db',
    'test_cache', 
    'test_client',
    'test_auth_headers'
]