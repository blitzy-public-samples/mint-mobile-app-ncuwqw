"""
API test package initialization module providing shared test utilities and configuration.

Human Tasks:
1. Verify test database and Redis configurations match your environment
2. Ensure test user permissions are properly configured
3. Review API endpoint prefix configuration for your environment
"""

# pytest: ^7.0.0

from ..conftest import (
    test_db,
    test_cache,
    test_client,
    test_auth_headers
)

# Requirement: API Testing Infrastructure
# Defines the API prefix used across all test cases to construct endpoint URLs
# This should match the prefix configured in the main API router
TEST_API_PREFIX = "/api/v1"

# Re-export fixtures for API test cases
__all__ = [
    "TEST_API_PREFIX",
    "test_db",
    "test_cache", 
    "test_client",
    "test_auth_headers"
]