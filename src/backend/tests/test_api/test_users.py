"""
Test suite for user management API endpoints in Mint Replica Lite application.

Human Tasks:
1. Verify test database is properly configured and accessible
2. Ensure test environment variables are set correctly
3. Review password complexity requirements match production settings
4. Confirm email validation service is configured for testing
"""

# pytest: ^7.0.0
# fastapi: ^0.95.0
# sqlalchemy: ^1.4.0

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from uuid import UUID

from ..conftest import test_db, test_auth_headers
from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate, UserResponse

# Test data constants
TEST_USER_DATA = {
    "email": "test@example.com",
    "password": "Test123!@#",
    "password_confirm": "Test123!@#",
    "first_name": "Test",
    "last_name": "User"
}

UPDATE_USER_DATA = {
    "first_name": "Updated",
    "last_name": "Name",
    "password": "NewPass123!@#"
}

@pytest.mark.asyncio
async def test_register_user(client: TestClient, test_db: Session):
    """
    Test user registration endpoint validates input and creates user.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify user registration functionality
    - Security Testing (6.3.1): Validate password security measures
    """
    # Prepare test user data
    user_data = TEST_USER_DATA.copy()
    
    # Test user registration
    response = client.post("/users/", json=user_data)
    
    # Verify successful creation
    assert response.status_code == 201
    created_user = response.json()
    
    # Validate response schema
    assert UUID(created_user["id"])
    assert created_user["email"] == user_data["email"].lower()
    assert created_user["first_name"] == user_data["first_name"]
    assert created_user["last_name"] == user_data["last_name"]
    assert created_user["is_active"] is True
    assert "password" not in created_user
    assert "password_hash" not in created_user
    
    # Verify database state
    db_user = test_db.query(User).filter(User.email == user_data["email"].lower()).first()
    assert db_user is not None
    assert db_user.email == user_data["email"].lower()
    assert db_user.first_name == user_data["first_name"]
    assert db_user.last_name == user_data["last_name"]
    assert db_user.verify_password(user_data["password"])
    assert db_user.is_active is True

@pytest.mark.asyncio
async def test_get_user_profile(client: TestClient, test_auth_headers: dict):
    """
    Test authenticated user profile retrieval.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify profile access functionality
    - Security Testing (6.3.1): Validate secure profile data handling
    """
    # Get authenticated user profile
    response = client.get("/users/me", headers=test_auth_headers)
    
    # Verify successful retrieval
    assert response.status_code == 200
    user_profile = response.json()
    
    # Validate response schema
    assert UUID(user_profile["id"])
    assert user_profile["email"] == "test@example.com"
    assert "password" not in user_profile
    assert "password_hash" not in user_profile
    assert user_profile["is_active"] is True
    
    # Verify required fields are present
    required_fields = ["first_name", "last_name", "created_at"]
    for field in required_fields:
        assert field in user_profile

@pytest.mark.asyncio
async def test_update_user_profile(
    client: TestClient,
    test_auth_headers: dict,
    test_db: Session
):
    """
    Test authenticated user profile update.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify profile update functionality
    - Security Testing (6.3.1): Validate secure update handling
    """
    # Prepare update data
    update_data = UPDATE_USER_DATA.copy()
    
    # Update user profile
    response = client.put("/users/me", headers=test_auth_headers, json=update_data)
    
    # Verify successful update
    assert response.status_code == 200
    updated_user = response.json()
    
    # Validate response schema
    assert updated_user["first_name"] == update_data["first_name"]
    assert updated_user["last_name"] == update_data["last_name"]
    assert "password" not in updated_user
    assert "password_hash" not in updated_user
    
    # Verify database state
    db_user = test_db.query(User).filter(User.email == "test@example.com").first()
    assert db_user is not None
    assert db_user.first_name == update_data["first_name"]
    assert db_user.last_name == update_data["last_name"]
    assert db_user.verify_password(update_data["password"])

@pytest.mark.asyncio
async def test_delete_user_account(
    client: TestClient,
    test_auth_headers: dict,
    test_db: Session
):
    """
    Test authenticated user account deletion.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify account deletion functionality
    - Security Testing (6.3.1): Validate secure account deactivation
    """
    # Delete user account
    response = client.delete("/users/me", headers=test_auth_headers)
    
    # Verify successful deletion
    assert response.status_code == 200
    
    # Verify database state
    db_user = test_db.query(User).filter(User.email == "test@example.com").first()
    assert db_user is not None
    assert db_user.is_active is False
    
    # Verify authentication fails for deleted account
    auth_response = client.post(
        "/auth/login",
        json={
            "email": "test@example.com",
            "password": TEST_USER_DATA["password"]
        }
    )
    assert auth_response.status_code == 401