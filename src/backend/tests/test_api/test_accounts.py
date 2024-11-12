"""
Test suite for account management API endpoints.

Human Tasks:
1. Verify test database contains required test data
2. Configure test environment variables for authentication
3. Review and adjust test timeouts if needed
4. Set up monitoring for test coverage metrics
"""

# pytest: ^7.0.0
# fastapi.testclient: 0.95.0
import pytest
from decimal import Decimal  # Python 3.9+
from uuid import UUID  # Python 3.9+
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import test_db, test_auth_headers
from app.api.v1.endpoints.accounts import router
from app.schemas.account import AccountCreate, AccountUpdate, AccountResponse

# Test data constants
TEST_ACCOUNT_DATA = {
    "institution_id": "test_bank",
    "account_type": "checking",
    "account_name": "Test Checking Account",
    "current_balance": "1000.00",
    "available_balance": "1000.00",
    "currency_code": "USD",
    "is_active": True
}

@pytest.mark.asyncio
async def test_create_account(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test successful account creation endpoint.
    
    Requirements addressed:
    - Account Management Testing (1.2): Validates account creation functionality
    - Security Testing (6.3.1): Verifies secure account creation with authentication
    """
    # Prepare test account data
    account_data = AccountCreate(
        institution_id=TEST_ACCOUNT_DATA["institution_id"],
        account_type=TEST_ACCOUNT_DATA["account_type"],
        account_name=TEST_ACCOUNT_DATA["account_name"],
        current_balance=Decimal(TEST_ACCOUNT_DATA["current_balance"]),
        is_active=TEST_ACCOUNT_DATA["is_active"]
    )

    # Send create account request
    response = client.post(
        "/accounts/",
        json=account_data.dict(),
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 201
    created_account = AccountResponse(**response.json())
    assert created_account.institution_id == account_data.institution_id
    assert created_account.account_type == account_data.account_type
    assert created_account.account_name == account_data.account_name
    assert created_account.current_balance == account_data.current_balance
    assert created_account.is_active == account_data.is_active

@pytest.mark.asyncio
async def test_create_account_unauthorized(client: TestClient) -> None:
    """
    Test account creation with invalid authentication.
    
    Requirements addressed:
    - Security Testing (6.3.1): Validates authentication requirements
    """
    # Send request without auth headers
    response = client.post(
        "/accounts/",
        json=TEST_ACCOUNT_DATA
    )

    # Verify unauthorized response
    assert response.status_code == 401
    assert "Not authenticated" in response.json()["detail"]

@pytest.mark.asyncio
async def test_get_account(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test account retrieval endpoint.
    
    Requirements addressed:
    - Account Management Testing (1.2): Validates account retrieval
    - Security Testing (6.3.1): Verifies secure data access
    """
    # Create test account first
    create_response = client.post(
        "/accounts/",
        json=TEST_ACCOUNT_DATA,
        headers=test_auth_headers
    )
    created_account = AccountResponse(**create_response.json())

    # Retrieve created account
    response = client.get(
        f"/accounts/{created_account.id}",
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 200
    retrieved_account = AccountResponse(**response.json())
    assert retrieved_account.id == created_account.id
    assert retrieved_account.institution_id == TEST_ACCOUNT_DATA["institution_id"]
    assert retrieved_account.account_type == TEST_ACCOUNT_DATA["account_type"]
    assert retrieved_account.current_balance == Decimal(TEST_ACCOUNT_DATA["current_balance"])

@pytest.mark.asyncio
async def test_list_accounts(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test accounts listing endpoint.
    
    Requirements addressed:
    - Account Management Testing (1.2): Validates account listing functionality
    - Real-time Updates Testing (1.2): Verifies data synchronization
    """
    # Create multiple test accounts
    accounts = []
    for i in range(3):
        account_data = dict(TEST_ACCOUNT_DATA)
        account_data["account_name"] = f"Test Account {i}"
        response = client.post(
            "/accounts/",
            json=account_data,
            headers=test_auth_headers
        )
        accounts.append(AccountResponse(**response.json()))

    # List all accounts
    response = client.get(
        "/accounts/",
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 200
    account_list = [AccountResponse(**acc) for acc in response.json()]
    assert len(account_list) >= len(accounts)
    for created_account in accounts:
        assert any(acc.id == created_account.id for acc in account_list)

@pytest.mark.asyncio
async def test_update_account(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test account update endpoint.
    
    Requirements addressed:
    - Account Management Testing (1.2): Validates account updates
    - Real-time Updates Testing (1.2): Verifies data synchronization
    """
    # Create test account
    create_response = client.post(
        "/accounts/",
        json=TEST_ACCOUNT_DATA,
        headers=test_auth_headers
    )
    created_account = AccountResponse(**create_response.json())

    # Prepare update data
    update_data = AccountUpdate(
        account_name="Updated Test Account",
        current_balance=Decimal("2000.00")
    )

    # Update account
    response = client.patch(
        f"/accounts/{created_account.id}",
        json=update_data.dict(exclude_unset=True),
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 200
    updated_account = AccountResponse(**response.json())
    assert updated_account.id == created_account.id
    assert updated_account.account_name == update_data.account_name
    assert updated_account.current_balance == update_data.current_balance

@pytest.mark.asyncio
async def test_sync_account(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test account synchronization endpoint.
    
    Requirements addressed:
    - Real-time Updates Testing (1.2): Validates real-time balance updates
    - Security Testing (6.3.1): Verifies secure synchronization
    """
    # Create test account
    create_response = client.post(
        "/accounts/",
        json=TEST_ACCOUNT_DATA,
        headers=test_auth_headers
    )
    created_account = AccountResponse(**create_response.json())

    # Sync account
    response = client.post(
        f"/accounts/{created_account.id}/sync",
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 200
    synced_account = AccountResponse(**response.json())
    assert synced_account.id == created_account.id
    assert synced_account.last_synced_at > created_account.last_synced_at

@pytest.mark.asyncio
async def test_deactivate_account(
    client: TestClient,
    test_db: AsyncSession,
    test_auth_headers: dict
) -> None:
    """
    Test account deactivation endpoint.
    
    Requirements addressed:
    - Account Management Testing (1.2): Validates account lifecycle management
    - Security Testing (6.3.1): Verifies secure deactivation
    """
    # Create test account
    create_response = client.post(
        "/accounts/",
        json=TEST_ACCOUNT_DATA,
        headers=test_auth_headers
    )
    created_account = AccountResponse(**create_response.json())

    # Deactivate account
    response = client.delete(
        f"/accounts/{created_account.id}",
        headers=test_auth_headers
    )

    # Verify response
    assert response.status_code == 200
    assert response.json()["message"] == "Account successfully deactivated"

    # Verify account is deactivated but still retrievable
    get_response = client.get(
        f"/accounts/{created_account.id}",
        headers=test_auth_headers
    )
    deactivated_account = AccountResponse(**get_response.json())
    assert deactivated_account.id == created_account.id
    assert not deactivated_account.is_active