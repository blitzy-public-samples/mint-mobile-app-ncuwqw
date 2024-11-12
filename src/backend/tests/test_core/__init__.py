"""
Test core module initialization file that configures shared test utilities and fixtures.

Human Tasks:
1. Verify test_data directory exists at src/backend/tests/test_core/test_data
2. Ensure test database and Redis instances are running with correct configurations
3. Review security test configurations and adjust as needed
"""

# pytest: ^7.0.0
import os
import pytest

# Re-export test fixtures from conftest.py
# Requirement: Testing Infrastructure - Initialize test infrastructure for core backend components
from ..conftest import (
    test_db as get_test_db,
    test_cache as get_test_redis,
    test_auth_headers as test_user,
    test_client as test_auth_manager
)

# Define test directory paths
# Requirement: Testing Infrastructure - Initialize test infrastructure for core backend components
TEST_CORE_DIR = os.path.dirname(os.path.abspath(__file__))
TEST_DATA_DIR = os.path.join(TEST_CORE_DIR, 'test_data')

# Verify test data directory exists
# Requirement: Security Testing - Configure test environment for security and authentication testing
if not os.path.exists(TEST_DATA_DIR):
    os.makedirs(TEST_DATA_DIR)

__all__ = [
    'get_test_db',
    'get_test_redis', 
    'test_auth_manager',
    'test_user',
    'TEST_CORE_DIR',
    'TEST_DATA_DIR'
]