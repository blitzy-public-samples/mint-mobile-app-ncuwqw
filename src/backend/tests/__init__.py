"""
Mint Replica Lite Backend Test Suite

This package contains comprehensive tests for the backend service components including:
- Unit tests for utilities and core functionality
- Model tests for database entities
- Service layer tests for business logic
- API endpoint integration tests
- Authentication and security tests

Test Categories:
1. Unit Tests
   - Utility functions
   - Helper classes
   - Data models

2. Integration Tests
   - API endpoints
   - Database operations
   - Cache interactions
   - External service integrations

3. Security Tests
   - Authentication flows
   - Authorization checks
   - Data encryption
   - Input validation

4. Performance Tests
   - Response times
   - Concurrent requests
   - Resource usage

Configuration:
- Uses pytest as the test runner
- pytest-cov for code coverage reporting
- pytest-asyncio for async test support
- pytest-mock for mocking dependencies

Usage:
    pytest tests/          # Run all tests
    pytest tests/unit/     # Run unit tests only
    pytest tests/api/      # Run API tests only
    pytest --cov=src/     # Run tests with coverage
"""

# Human Tasks:
# 1. Ensure pytest is installed in the development environment (pytest ^7.0.0)
# 2. Install required pytest plugins:
#    - pytest-cov ^4.0.0 for coverage reporting
#    - pytest-asyncio ^0.21.0 for async test support
#    - pytest-mock ^3.10.0 for mocking capabilities
# 3. Configure IDE test runner to use pytest
# 4. Set up coverage reporting in CI/CD pipeline

# Third-party imports with versions
# pytest ^7.0.0
# pytest-cov ^4.0.0
# pytest-asyncio ^0.21.0
# pytest-mock ^3.10.0

from pathlib import Path

# Provides the absolute path to the tests directory for test file discovery
# and resource loading
# Requirement: Backend Testing Infrastructure
# Location: Technical Specification/2. System Architecture/2.5.2 Deployment Architecture
TEST_DIR = Path(__file__).parent