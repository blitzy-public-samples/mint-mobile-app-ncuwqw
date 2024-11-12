"""
Authentication API endpoint test suite.

Human Tasks:
1. Configure test environment variables for token secrets
2. Verify test database contains required user tables and schemas
3. Ensure Redis is running for session tests
4. Review and adjust token expiry times in test configuration
"""

# pytest: ^7.0.0
# fastapi: 0.95.0
# python-jose: ^3.3.0

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession
from jose import jwt
from datetime import datetime, timedelta

from ..conftest import get_test_db, test_auth_manager, test_user
from app.api.v1.endpoints.auth import router

# Test data constants
VALID_USER_DATA = {
    "email": "newuser@example.com",
    "password": "StrongP@ssw0rd123",
    "confirm_password": "StrongP@ssw0rd123"
}

INVALID_CREDENTIALS = {
    "email": "wrong@example.com",
    "password": "WrongPassword123"
}

@pytest.mark.asyncio
async def test_register_user_success(test_db: AsyncSession, client: TestClient):
    """
    Test successful user registration with valid data.
    
    Requirements addressed:
    - Authentication Flow Testing (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Security Standards Testing (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    response = await client.post(
        "/auth/register",
        json=VALID_USER_DATA
    )
    
    # Verify response status and structure
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert "refresh_token" in data
    
    # Validate JWT token format and claims
    access_token = data["access_token"]
    token_data = jwt.decode(access_token, verify=False)
    assert "sub" in token_data
    assert "exp" in token_data
    
    # Verify user exists in database
    user = await test_db.execute(
        "SELECT * FROM users WHERE email = :email",
        {"email": VALID_USER_DATA["email"]}
    )
    assert user is not None

@pytest.mark.asyncio
async def test_register_user_duplicate_email(
    test_db: AsyncSession,
    client: TestClient,
    test_user: dict
):
    """
    Test registration attempt with already registered email.
    
    Requirements addressed:
    - Security Standards Testing (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    duplicate_data = {
        "email": test_user["email"],
        "password": "NewPassword123!",
        "confirm_password": "NewPassword123!"
    }
    
    response = await client.post(
        "/auth/register",
        json=duplicate_data
    )
    
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data
    assert "email already exists" in data["detail"].lower()

@pytest.mark.asyncio
async def test_login_success(client: TestClient, test_user: dict):
    """
    Test successful login with valid credentials.
    
    Requirements addressed:
    - Authentication Flow Testing (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Session Management Testing (6.3 Security Controls/6.3.3 Security Controls)
    """
    login_data = {
        "email": test_user["email"],
        "password": test_user["password"]
    }
    
    response = await client.post(
        "/auth/login",
        json=login_data
    )
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify token response
    assert "access_token" in data
    access_token = data["access_token"]
    
    # Validate token claims
    token_data = jwt.decode(access_token, verify=False)
    assert token_data["sub"] == str(test_user["id"])
    assert token_data["exp"] > datetime.utcnow().timestamp()
    
    # Verify refresh token cookie
    cookies = response.cookies
    assert "refresh_token" in cookies
    assert cookies["refresh_token"]["httponly"]
    assert cookies["refresh_token"]["secure"]
    assert cookies["refresh_token"]["samesite"].lower() == "lax"

@pytest.mark.asyncio
async def test_login_invalid_credentials(client: TestClient):
    """
    Test login attempt with invalid credentials.
    
    Requirements addressed:
    - Security Standards Testing (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    response = await client.post(
        "/auth/login",
        json=INVALID_CREDENTIALS
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "detail" in data
    assert "invalid credentials" in data["detail"].lower()

@pytest.mark.asyncio
async def test_refresh_token_success(client: TestClient, test_user: dict):
    """
    Test successful access token refresh.
    
    Requirements addressed:
    - Authentication Flow Testing (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Session Management Testing (6.3 Security Controls/6.3.3 Security Controls)
    """
    # First login to get valid refresh token
    login_response = await client.post(
        "/auth/login",
        json={
            "email": test_user["email"],
            "password": test_user["password"]
        }
    )
    
    refresh_token = login_response.cookies["refresh_token"]
    
    # Attempt token refresh
    response = await client.post(
        "/auth/refresh",
        cookies={"refresh_token": refresh_token}
    )
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify new tokens
    assert "access_token" in data
    new_access_token = data["access_token"]
    
    # Validate new token claims
    token_data = jwt.decode(new_access_token, verify=False)
    assert token_data["sub"] == str(test_user["id"])
    assert token_data["exp"] > datetime.utcnow().timestamp()
    
    # Verify new refresh token cookie
    cookies = response.cookies
    assert "refresh_token" in cookies
    assert cookies["refresh_token"]["httponly"]
    assert cookies["refresh_token"]["secure"]

@pytest.mark.asyncio
async def test_refresh_token_invalid(client: TestClient):
    """
    Test refresh attempt with invalid token.
    
    Requirements addressed:
    - Security Standards Testing (6.3 Security Protocols/6.3.1 Security Standards Compliance)
    """
    response = await client.post(
        "/auth/refresh",
        cookies={"refresh_token": "invalid_token"}
    )
    
    assert response.status_code == 401
    data = response.json()
    assert "detail" in data
    assert "invalid token" in data["detail"].lower()

@pytest.mark.asyncio
async def test_logout_success(client: TestClient, test_user: dict):
    """
    Test successful user logout.
    
    Requirements addressed:
    - Authentication Flow Testing (6.1 Authentication and Authorization/6.1.1 Authentication Flow)
    - Session Management Testing (6.3 Security Controls/6.3.3 Security Controls)
    """
    # First login
    login_response = await client.post(
        "/auth/login",
        json={
            "email": test_user["email"],
            "password": test_user["password"]
        }
    )
    
    access_token = login_response.json()["access_token"]
    
    # Perform logout
    response = await client.post(
        "/auth/logout",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "successfully logged out" in data["message"].lower()
    
    # Verify refresh token cookie is cleared
    cookies = response.cookies
    assert "refresh_token" in cookies
    assert not cookies["refresh_token"]["value"]
    
    # Verify old token is invalid
    protected_response = await client.get(
        "/protected-endpoint",
        headers={"Authorization": f"Bearer {access_token}"}
    )
    assert protected_response.status_code == 401