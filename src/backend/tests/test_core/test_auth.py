"""
Test suite for core authentication functionality.

Human Tasks:
1. Review test coverage and add additional test cases if needed
2. Verify test database contains required test user data
3. Ensure Redis test instance is running for cache-related tests
4. Review token expiration times in test environment
"""

# pytest: ^7.0.0
# freezegun: ^1.2.0
# pytest-asyncio: ^0.18.0

import pytest
from datetime import datetime, timedelta
from fastapi import HTTPException, Request
from freezegun import freeze_time

from app.core.auth import (
    create_access_token,
    create_refresh_token,
    verify_token,
    get_current_user,
    OAuth2PasswordBearerWithCookie,
    ACCESS_TOKEN_EXPIRE_MINUTES,
    ALGORITHM
)

# Test constants
TEST_USER_DATA = {
    "email": "test@example.com",
    "password": "test_password123"
}

TEST_TOKEN_DATA = {
    "sub": "test@example.com",
    "scopes": ["user"]
}

@pytest.mark.asyncio
async def test_create_access_token(test_auth_manager):
    """
    Test JWT access token creation with proper claims and expiration.
    
    Requirement: Authentication Flow Testing - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    # Test with default expiration
    token = create_access_token(data=TEST_TOKEN_DATA)
    assert isinstance(token, str)
    
    # Verify token payload
    payload = verify_token(token)
    assert payload["sub"] == TEST_TOKEN_DATA["sub"]
    assert payload["scopes"] == TEST_TOKEN_DATA["scopes"]
    assert payload["type"] == "access"
    
    # Test with custom expiration
    custom_expires = timedelta(minutes=30)
    token_custom = create_access_token(
        data=TEST_TOKEN_DATA,
        expires_delta=custom_expires
    )
    payload_custom = verify_token(token_custom)
    
    # Verify expiration time
    expected_exp = datetime.utcnow() + custom_expires
    assert abs(datetime.fromtimestamp(payload_custom["exp"]) - expected_exp).seconds < 5

@pytest.mark.asyncio
async def test_create_refresh_token(test_auth_manager):
    """
    Test JWT refresh token creation with proper claims and extended expiration.
    
    Requirement: Authentication Flow Testing - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    token = create_refresh_token(data=TEST_TOKEN_DATA)
    assert isinstance(token, str)
    
    # Verify token payload
    payload = verify_token(token)
    assert payload["sub"] == TEST_TOKEN_DATA["sub"]
    assert payload["type"] == "refresh"
    
    # Verify extended expiration (30 days)
    expected_exp = datetime.utcnow() + timedelta(days=30)
    assert abs(datetime.fromtimestamp(payload["exp"]) - expected_exp).seconds < 5

@pytest.mark.asyncio
async def test_verify_token(test_auth_manager):
    """
    Test JWT token verification with various scenarios.
    
    Requirement: Security Controls Testing - 6.3 Security Controls/6.3.3 Security Controls
    """
    # Test valid token
    token = create_access_token(data=TEST_TOKEN_DATA)
    payload = verify_token(token)
    assert payload["sub"] == TEST_TOKEN_DATA["sub"]
    
    # Test invalid token format
    with pytest.raises(HTTPException) as exc_info:
        verify_token("invalid.token.format")
    assert exc_info.value.status_code == 401
    
    # Test expired token
    with freeze_time(datetime.utcnow() + timedelta(days=2)):
        with pytest.raises(HTTPException) as exc_info:
            verify_token(token)
        assert exc_info.value.status_code == 401
        assert "expired" in exc_info.value.detail.lower()
    
    # Test token with invalid signature
    tampered_token = token[:-5] + "12345"
    with pytest.raises(HTTPException) as exc_info:
        verify_token(tampered_token)
    assert exc_info.value.status_code == 401
    
    # Test scope verification
    with pytest.raises(HTTPException) as exc_info:
        verify_token(token, required_scopes=["admin"])
    assert exc_info.value.status_code == 403

@pytest.mark.asyncio
async def test_get_current_user(test_db, test_user):
    """
    Test current user extraction from JWT token.
    
    Requirement: Authentication Flow Testing - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    # Create token with test user data
    token = create_access_token(data=test_user)
    
    # Test valid token and user extraction
    user = await get_current_user(
        security_scopes=None,
        token=token
    )
    assert user["sub"] == test_user["sub"]
    assert user["scopes"] == test_user["scopes"]
    
    # Test with invalid token
    with pytest.raises(HTTPException) as exc_info:
        await get_current_user(None, "invalid.token")
    assert exc_info.value.status_code == 401
    
    # Test with missing user ID
    invalid_data = TEST_TOKEN_DATA.copy()
    del invalid_data["sub"]
    invalid_token = create_access_token(data=invalid_data)
    with pytest.raises(HTTPException) as exc_info:
        await get_current_user(None, invalid_token)
    assert exc_info.value.status_code == 401

@pytest.mark.asyncio
async def test_oauth2_cookie_bearer(test_db, test_user):
    """
    Test OAuth2 bearer implementation with cookie support.
    
    Requirement: Security Controls Testing - 6.3 Security Controls/6.3.3 Security Controls
    """
    oauth2_scheme = OAuth2PasswordBearerWithCookie(
        tokenUrl="api/v1/auth/login",
        scopes=["user"]
    )
    
    # Create test token
    token = create_access_token(data=test_user)
    
    # Test token extraction from header
    mock_request = Request({
        "type": "http",
        "headers": [(b"authorization", f"Bearer {token}".encode())]
    })
    extracted_token = await oauth2_scheme(mock_request)
    assert extracted_token == token
    
    # Test token extraction from cookie
    mock_request = Request({
        "type": "http",
        "headers": [],
        "cookies": {"access_token": token}
    })
    extracted_token = await oauth2_scheme(mock_request)
    assert extracted_token == token
    
    # Test header precedence over cookie
    mock_request = Request({
        "type": "http",
        "headers": [(b"authorization", f"Bearer {token}".encode())],
        "cookies": {"access_token": "cookie_token"}
    })
    extracted_token = await oauth2_scheme(mock_request)
    assert extracted_token == token
    
    # Test missing token
    mock_request = Request({
        "type": "http",
        "headers": [],
        "cookies": {}
    })
    with pytest.raises(HTTPException) as exc_info:
        await oauth2_scheme(mock_request)
    assert exc_info.value.status_code == 401
    
    # Test invalid scheme
    mock_request = Request({
        "type": "http",
        "headers": [(b"authorization", b"Basic invalid_token")]
    })
    with pytest.raises(HTTPException) as exc_info:
        await oauth2_scheme(mock_request)
    assert exc_info.value.status_code == 401