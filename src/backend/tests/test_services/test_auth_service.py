"""
Test suite for authentication service validating user authentication flows, token management,
session handling, and security compliance.

Human Tasks:
1. Review test coverage requirements with security team
2. Configure test database with appropriate test data
3. Set up monitoring for failed test cases
4. Verify token expiration settings match security requirements
"""

# pytest: ^7.0.0
# freezegun: ^1.2.0
# pytest-asyncio: ^0.18.0

import pytest
from datetime import datetime, timedelta
from fastapi import HTTPException
from freezegun import freeze_time
from uuid import UUID

from app.services.auth_service import AuthService
from app.schemas.auth import TokenPayload, UserLogin, UserRegister
from tests.conftest import get_test_db, test_user

class TestAuthService:
    """
    Test class for AuthService functionality including authentication, token management and session handling.
    
    Requirements addressed:
    - Authentication Flow Testing (6.1.1): Validate secure user authentication with JWT tokens
    - Security Standards Testing (6.3.1): Verify compliance with security standards
    - Session Management Testing (6.3.3): Validate secure session handling
    """

    @pytest.mark.asyncio
    async def test_authenticate_user_success(self, test_db, test_user):
        """
        Test successful user authentication with valid credentials.
        
        Requirement: Authentication Flow Testing (6.1.1)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Extract test credentials
        email = test_user["email"]
        password = test_user["password"]
        
        # Attempt authentication
        authenticated_user = await auth_service.authenticate_user(email, password)
        
        # Verify authentication success
        assert authenticated_user is not None
        assert authenticated_user.email == email

    @pytest.mark.asyncio
    async def test_authenticate_user_invalid_password(self, test_db, test_user):
        """
        Test authentication failure with invalid password.
        
        Requirement: Security Standards Testing (6.3.1)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Extract test email and use invalid password
        email = test_user["email"]
        invalid_password = "WrongPassword123!"
        
        # Attempt authentication
        authenticated_user = await auth_service.authenticate_user(email, invalid_password)
        
        # Verify authentication failure
        assert authenticated_user is None

    @pytest.mark.asyncio
    async def test_create_user_success(self, test_db):
        """
        Test successful user creation with valid registration data.
        
        Requirement: Security Standards Testing (6.3.1)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Prepare test registration data
        user_data = UserRegister(
            email="newuser@example.com",
            password="SecurePass123!",
            first_name="Test",
            last_name="User"
        )
        
        # Create user
        created_user = await auth_service.create_user(user_data)
        
        # Verify user creation
        assert created_user is not None
        assert created_user.email == user_data.email
        assert created_user.first_name == user_data.first_name
        assert created_user.last_name == user_data.last_name
        assert created_user.verify_password(user_data.password)

    @pytest.mark.asyncio
    async def test_login_success(self, test_db, test_user):
        """
        Test successful login with valid credentials.
        
        Requirements:
        - Authentication Flow Testing (6.1.1)
        - Session Management Testing (6.3.3)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Create login credentials
        credentials = UserLogin(
            email=test_user["email"],
            password=test_user["password"]
        )
        
        # Attempt login
        token_response = await auth_service.login(credentials)
        
        # Verify token response
        assert token_response is not None
        assert token_response.access_token
        assert token_response.refresh_token
        assert token_response.token_type == "bearer"
        
        # Verify token payload
        token_payload = TokenPayload.parse_raw(token_response.access_token)
        assert isinstance(token_payload.sub, UUID)
        assert token_payload.exp > datetime.utcnow()

    @pytest.mark.asyncio
    @freeze_time("2024-01-01 12:00:00")
    async def test_refresh_token_success(self, test_db, test_user):
        """
        Test successful token refresh with valid refresh token.
        
        Requirements:
        - Authentication Flow Testing (6.1.1)
        - Session Management Testing (6.3.3)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Get initial tokens through login
        credentials = UserLogin(
            email=test_user["email"],
            password=test_user["password"]
        )
        initial_tokens = await auth_service.login(credentials)
        
        # Refresh tokens
        new_tokens = await auth_service.refresh_token(initial_tokens.refresh_token)
        
        # Verify new tokens
        assert new_tokens is not None
        assert new_tokens.access_token != initial_tokens.access_token
        assert new_tokens.refresh_token != initial_tokens.refresh_token
        assert new_tokens.token_type == "bearer"
        
        # Verify token expiration
        token_payload = TokenPayload.parse_raw(new_tokens.access_token)
        expected_expiry = datetime.utcnow() + timedelta(hours=24)
        assert abs((token_payload.exp - expected_expiry).total_seconds()) < 1

    @pytest.mark.asyncio
    @freeze_time("2024-02-01 12:00:00")
    async def test_refresh_token_expired(self, test_db, test_user):
        """
        Test token refresh failure with expired refresh token.
        
        Requirements:
        - Security Standards Testing (6.3.1)
        - Session Management Testing (6.3.3)
        """
        # Initialize service
        auth_service = AuthService(test_db)
        
        # Get initial tokens
        credentials = UserLogin(
            email=test_user["email"],
            password=test_user["password"]
        )
        initial_tokens = await auth_service.login(credentials)
        
        # Attempt refresh with expired token (30 days passed)
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.refresh_token(initial_tokens.refresh_token)
        
        # Verify error response
        assert exc_info.value.status_code == 401
        assert "token expired" in str(exc_info.value.detail).lower()