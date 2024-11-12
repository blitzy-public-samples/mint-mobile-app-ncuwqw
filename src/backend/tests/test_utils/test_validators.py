"""
Test suite for validation utility functions used in Mint Replica Lite backend.

Human Tasks:
1. Review test cases with security team to ensure comprehensive coverage
2. Verify test data aligns with production scenarios
3. Confirm error message requirements with UX team
"""

# Library versions:
# pytest: ^6.2.5
# datetime: ^3.9.0
# decimal: ^3.9.0

import pytest
from datetime import datetime, timedelta
from decimal import Decimal

from app.utils.validators import (
    validate_email,
    validate_password,
    validate_amount,
    validate_pagination_params,
    validate_date_range
)
from app.core.errors import ValidationError

# Test case constants
TEST_EMAIL_CASES = [
    # (email, expected_valid)
    ("user@example.com", True),
    ("user.name@domain.co.uk", True),
    ("user+tag@domain.com", True),
    ("", False),
    (None, False),
    ("invalid.email", False),
    ("user@", False),
    ("@domain.com", False),
    ("<script>alert(1)</script>@domain.com", False),
    ("user@domain.com;drop table users", False)
]

TEST_PASSWORD_CASES = [
    # (password, expected_valid)
    ("SecureP@ss123", True),
    ("Abcd123!@#$", True),
    ("", False),
    (None, False),
    ("short1", False),
    ("nocapitals123!", False),
    ("NOSMALLCASE123!", False),
    ("NoSpecialChar123", False),
    ("NoNumbers@abc", False),
    ("   SpacesNotAllowed123!  ", False)
]

TEST_AMOUNT_CASES = [
    # (amount, expected_valid)
    (Decimal("100.00"), True),
    (Decimal("0.01"), True),
    (Decimal("999999999.99"), True),
    (Decimal("0.00"), False),
    (Decimal("-100.00"), False),
    (Decimal("100.999"), False),
    (None, False),
    ("invalid", False),
    (Decimal("1000000000.00"), False)
]

TEST_PAGINATION_CASES = [
    # (page, page_size, expected_valid)
    (1, 10, True),
    (1, 50, True),
    (100, 20, True),
    (0, 10, False),
    (-1, 20, False),
    (1, 0, False),
    (1, -10, False),
    (1, 1001, False),
    ("invalid", 10, False),
    (1, "invalid", False)
]

TEST_DATE_RANGE_CASES = [
    # (start_date, end_date, expected_valid)
    (datetime.now(), datetime.now() + timedelta(days=30), True),
    (datetime.now(), datetime.now() + timedelta(days=365), True),
    (None, datetime.now(), False),
    (datetime.now(), None, False),
    (datetime.now(), datetime.now() - timedelta(days=1), False),
    (datetime.now(), datetime.now() + timedelta(days=731), False),
    ("invalid", datetime.now(), False),
    (datetime.now(), "invalid", False)
]

class TestValidators:
    """Test class containing all validator test cases"""

    def setup_method(self):
        """Setup method run before each test"""
        # Initialize test data if needed
        pass

    @pytest.mark.parametrize('email,expected_valid', TEST_EMAIL_CASES)
    def test_validate_email(self, email, expected_valid):
        """
        Test email validation function.
        
        Requirement: Input Validation Testing - Test server-side validation to prevent injection attacks
        """
        if expected_valid:
            assert validate_email(email) is True
        else:
            with pytest.raises(ValidationError):
                validate_email(email)

    @pytest.mark.parametrize('password,expected_valid', TEST_PASSWORD_CASES)
    def test_validate_password(self, password, expected_valid):
        """
        Test password validation function.
        
        Requirement: Security Validation Testing - Test validation of sensitive financial and personal data
        """
        if expected_valid:
            assert validate_password(password) is True
        else:
            with pytest.raises(ValidationError):
                validate_password(password)

    @pytest.mark.parametrize('amount,expected_valid', TEST_AMOUNT_CASES)
    def test_validate_amount(self, amount, expected_valid):
        """
        Test financial amount validation.
        
        Requirement: Financial Data Validation Testing - Test validation for financial transactions and account data
        """
        if expected_valid:
            assert validate_amount(amount) is True
        else:
            with pytest.raises(ValidationError):
                validate_amount(amount)

    @pytest.mark.parametrize('page,page_size,expected_valid', TEST_PAGINATION_CASES)
    def test_validate_pagination_params(self, page, page_size, expected_valid):
        """
        Test pagination parameter validation.
        
        Requirement: Input Validation Testing - Test server-side validation to prevent injection attacks
        """
        if expected_valid:
            validated_page, validated_size = validate_pagination_params(page, page_size)
            assert isinstance(validated_page, int)
            assert isinstance(validated_size, int)
            assert validated_page > 0
            assert 0 < validated_size <= 1000
        else:
            with pytest.raises(ValidationError):
                validate_pagination_params(page, page_size)

    @pytest.mark.parametrize('start_date,end_date,expected_valid', TEST_DATE_RANGE_CASES)
    def test_validate_date_range(self, start_date, end_date, expected_valid):
        """
        Test date range validation.
        
        Requirement: Financial Data Validation Testing - Test validation for financial transactions and account data
        """
        if expected_valid:
            assert validate_date_range(start_date, end_date) is True
        else:
            with pytest.raises(ValidationError):
                validate_date_range(start_date, end_date)

    def test_validate_email_injection_patterns(self):
        """
        Test email validation against SQL injection patterns.
        
        Requirement: Security Validation Testing - Test validation of sensitive financial and personal data
        """
        injection_patterns = [
            "user@domain.com; DROP TABLE users;",
            "user@domain.com' OR '1'='1",
            "admin'--@domain.com",
            "<script>alert(1)</script>@domain.com"
        ]
        
        for email in injection_patterns:
            with pytest.raises(ValidationError):
                validate_email(email)

    def test_validate_password_strength(self):
        """
        Test password validation strength requirements.
        
        Requirement: Security Validation Testing - Test validation of sensitive financial and personal data
        """
        weak_passwords = [
            "password123",  # No special char, no uppercase
            "PASSWORD123!",  # No lowercase
            "Password!",     # No numbers
            "Pa1!",         # Too short
            "       ",      # Only whitespace
        ]
        
        for password in weak_passwords:
            with pytest.raises(ValidationError):
                validate_password(password)

    def test_validate_amount_precision(self):
        """
        Test financial amount decimal precision validation.
        
        Requirement: Financial Data Validation Testing - Test validation for financial transactions and account data
        """
        invalid_amounts = [
            Decimal("100.999"),    # Too many decimal places
            Decimal("0.001"),      # Too many decimal places
            Decimal("-0.01"),      # Negative amount
            Decimal("1000000000")  # Exceeds maximum
        ]
        
        for amount in invalid_amounts:
            with pytest.raises(ValidationError):
                validate_amount(amount)