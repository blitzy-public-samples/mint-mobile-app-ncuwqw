"""
Unit tests for core security module, testing JWT token management, password security, 
and secure session management functionality.

Human Tasks:
1. Review test coverage and add additional test cases if needed
2. Verify test data matches production security requirements
3. Ensure test secret keys meet minimum security standards
"""

# pytest: ^7.0.0
# freezegun: ^1.2.0
# python-jwt: 2.6.0
# datetime: ^3.9

import pytest
from datetime import datetime, timedelta
import jwt
from freezegun import freeze_time

from app.core.security import (
    create_access_token,
    create_refresh_token,
    verify_token,
    get_password_hash,
    verify_password_hash,
)
from app.core.config import settings


@pytest.mark.security
class TestSecurityFixtures:
    """Test fixtures for security tests"""
    
    def __init__(self):
        self.test_password = "SecureTestPass123!"
        self.test_wrong_password = "WrongTestPass123!"
        self.test_user_data = {
            "sub": "testuser@example.com",
            "user_id": "123456789",
            "roles": ["user"]
        }

    def setup_method(self, method):
        """Setup method run before each test"""
        # Reset test data to initial state
        self.test_user_data = {
            "sub": "testuser@example.com",
            "user_id": "123456789",
            "roles": ["user"]
        }


@pytest.mark.security
def test_create_access_token():
    """
    Tests the creation of JWT access tokens with configurable expiration.
    
    Requirement: Authentication Flow Testing - 6.1.1 Authentication Flow
    Testing secure JWT token generation and expiration handling.
    """
    fixtures = TestSecurityFixtures()
    
    # Test default expiration
    token = create_access_token(fixtures.test_user_data)
    assert isinstance(token, str)
    
    # Verify token structure and claims
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
    assert payload["sub"] == fixtures.test_user_data["sub"]
    assert payload["user_id"] == fixtures.test_user_data["user_id"]
    assert payload["type"] == "access"
    
    # Test custom expiration
    custom_expiry = timedelta(minutes=15)
    token = create_access_token(fixtures.test_user_data, custom_expiry)
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
    expected_exp = datetime.utcnow() + custom_expiry
    assert abs(datetime.fromtimestamp(payload["exp"]) - expected_exp).seconds < 5


@pytest.mark.security
def test_create_refresh_token():
    """
    Tests the creation of JWT refresh tokens with fixed expiration.
    
    Requirement: Authentication Flow Testing - 6.1.1 Authentication Flow
    Testing refresh token mechanism implementation.
    """
    fixtures = TestSecurityFixtures()
    
    token = create_refresh_token(fixtures.test_user_data)
    assert isinstance(token, str)
    
    # Verify token structure and claims
    payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
    assert payload["sub"] == fixtures.test_user_data["sub"]
    assert payload["user_id"] == fixtures.test_user_data["user_id"]
    assert payload["type"] == "refresh"
    
    # Verify refresh token expiration
    expected_exp = datetime.utcnow() + timedelta(days=7)
    assert abs(datetime.fromtimestamp(payload["exp"]) - expected_exp).seconds < 5


@pytest.mark.security
def test_verify_token():
    """
    Tests JWT token verification functionality.
    
    Requirement: Data Security Testing - 6.2.1 Encryption Implementation
    Testing secure token validation and error handling.
    """
    fixtures = TestSecurityFixtures()
    
    # Test valid token verification
    token = create_access_token(fixtures.test_user_data)
    payload = verify_token(token)
    assert payload["sub"] == fixtures.test_user_data["sub"]
    
    # Test invalid signature
    with pytest.raises(jwt.InvalidTokenError):
        tampered_token = token[:-5] + "12345"  # Tamper with signature
        verify_token(tampered_token)
    
    # Test malformed token
    with pytest.raises(jwt.InvalidTokenError):
        verify_token("not.a.token")
    
    # Test expired token
    with freeze_time(datetime.utcnow() + timedelta(days=1)):
        with pytest.raises(jwt.InvalidTokenError, match="Token has expired"):
            verify_token(token)


@pytest.mark.security
def test_password_hashing():
    """
    Tests password hashing functionality using bcrypt.
    
    Requirement: Data Security Testing - 6.2.1 Encryption Implementation
    Testing secure password hashing implementation.
    """
    fixtures = TestSecurityFixtures()
    
    # Test hash generation
    hashed = get_password_hash(fixtures.test_password)
    assert isinstance(hashed, str)
    assert hashed != fixtures.test_password
    
    # Verify hash format
    assert hashed.startswith("$2b$")  # bcrypt identifier
    assert len(hashed) > 50  # Minimum bcrypt hash length
    
    # Test hash uniqueness
    second_hash = get_password_hash(fixtures.test_password)
    assert hashed != second_hash  # Different salt should produce different hash


@pytest.mark.security
def test_password_verification():
    """
    Tests password hash verification using bcrypt.
    
    Requirement: Security Standards Testing - 6.3.1 Security Standards Compliance
    Testing secure password verification implementation.
    """
    fixtures = TestSecurityFixtures()
    
    hashed = get_password_hash(fixtures.test_password)
    
    # Test correct password verification
    assert verify_password_hash(fixtures.test_password, hashed) is True
    
    # Test incorrect password verification
    assert verify_password_hash(fixtures.test_wrong_password, hashed) is False
    
    # Test empty password handling
    assert verify_password_hash("", hashed) is False
    
    # Test against known test vectors
    test_vectors = [
        ("password123", "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LedYQNB8UHUHzh/Ka"),
        ("testpass456", "$2b$12$WZK.pCd5TMHnqjAX9QR/Me1G8HxMVb3ZGOkII1uUHs9lUXXBzHNfW")
    ]
    for password, hash_value in test_vectors:
        assert verify_password_hash(password, hash_value) is True
        assert verify_password_hash(fixtures.test_wrong_password, hash_value) is False


@pytest.mark.security
@freeze_time("2023-01-01 12:00:00")
def test_token_expiration():
    """
    Tests token expiration handling.
    
    Requirement: Security Standards Testing - 6.3.1 Security Standards Compliance
    Testing token lifecycle and expiration handling.
    """
    fixtures = TestSecurityFixtures()
    
    # Test access token expiration
    token = create_access_token(fixtures.test_user_data, timedelta(minutes=5))
    
    # Token should be valid initially
    payload = verify_token(token)
    assert payload["sub"] == fixtures.test_user_data["sub"]
    
    # Token should be invalid after expiration
    with freeze_time("2023-01-01 12:06:00"):  # Advance 6 minutes
        with pytest.raises(jwt.InvalidTokenError, match="Token has expired"):
            verify_token(token)
    
    # Test refresh token longer expiration
    refresh_token = create_refresh_token(fixtures.test_user_data)
    
    # Should still be valid after 6 days
    with freeze_time("2023-01-07 12:00:00"):
        payload = verify_token(refresh_token)
        assert payload["type"] == "refresh"
    
    # Should expire after 7 days
    with freeze_time("2023-01-08 12:00:01"):
        with pytest.raises(jwt.InvalidTokenError, match="Token has expired"):
            verify_token(refresh_token)