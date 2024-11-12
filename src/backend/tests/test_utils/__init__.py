"""
Test utilities package initializer for Mint Replica Lite backend test suite.

Human Tasks:
1. Review test marker configuration with test team to ensure all test types are covered
2. Verify marker usage aligns with CI/CD pipeline configuration
3. Ensure test documentation reflects all available markers
"""

# pytest: ^7.0.0

import pytest
from .test_crypto import TestCrypto
from .test_datetime import test_parse_datetime_valid, test_format_datetime
from .test_validators import TestValidators

# Test markers for different test types
TEST_MARKERS = [
    'unit: marks test as a unit test',
    'integration: marks test as an integration test', 
    'security: marks test as a security test',
    'validation: marks test as a validation test',
    'crypto: marks test as a cryptography test',
    'datetime: marks test as a datetime utility test'
]

def pytest_configure(config):
    """
    Configure pytest with custom markers for the test suite.
    
    Requirement: Test Organization - 2.2 Component Architecture
    Configure test markers for clear separation of test types
    
    Requirement: Test Configuration - 6.3.3 Security Controls
    Configure security and validation test markers for comprehensive coverage
    
    Args:
        config: pytest.Config object for test configuration
    """
    # Register unit test marker for component-level tests
    config.addinivalue_line(
        "markers",
        "unit: marks test as a unit test"
    )
    
    # Register integration test marker for cross-component tests
    config.addinivalue_line(
        "markers", 
        "integration: marks test as an integration test"
    )
    
    # Register security test marker for security-focused tests
    config.addinivalue_line(
        "markers",
        "security: marks test as a security test"
    )
    
    # Register validation test marker for input validation tests
    config.addinivalue_line(
        "markers",
        "validation: marks test as a validation test"
    )
    
    # Register crypto test marker for cryptography-related tests
    config.addinivalue_line(
        "markers",
        "crypto: marks test as a cryptography test"
    )
    
    # Register datetime test marker for datetime utility tests
    config.addinivalue_line(
        "markers",
        "datetime: marks test as a datetime utility test"
    )