"""
Test suite for the Account model validating account creation, balance updates, and data management.

Human Tasks:
1. Verify test database has proper permissions for account table operations
2. Ensure test database is configured with proper isolation level
3. Review test coverage reports and maintain >90% coverage
"""

# pytest: ^7.0.0
import pytest
from decimal import Decimal
from uuid import UUID
from datetime import datetime

from app.models.account import Account
from tests.conftest import get_test_db, test_user

@pytest.mark.asyncio
async def test_create_account(test_db, test_user):
    """
    Test account creation with valid data and verify all properties.
    
    Requirements addressed:
    - Account Management (1.2): Validates financial account creation functionality
    - Data Storage (2.1): Verifies PostgreSQL model implementation
    """
    # Test data
    test_data = {
        "user_id": UUID(test_user["sub"]),
        "institution_id": "test_bank_123",
        "account_type": "checking",
        "account_name": "Test Checking Account",
        "account_number_masked": "****1234",
        "current_balance": Decimal("1000.00"),
        "currency_code": "USD"
    }
    
    # Create account instance
    account = Account(**test_data)
    
    # Verify basic properties
    assert isinstance(account.id, UUID)
    assert account.user_id == test_data["user_id"]
    assert account.institution_id == test_data["institution_id"]
    assert account.account_type == test_data["account_type"]
    assert account.account_name == test_data["account_name"]
    assert account.account_number_masked == test_data["account_number_masked"]
    assert account.current_balance == test_data["current_balance"]
    assert account.currency_code == test_data["currency_code"]
    
    # Verify default values
    assert account.is_active is True
    assert account.institution_data == {}
    assert account.available_balance == account.current_balance
    
    # Verify timestamps
    assert isinstance(account.created_at, datetime)
    assert isinstance(account.updated_at, datetime)
    assert isinstance(account.last_synced_at, datetime)

@pytest.mark.asyncio
async def test_update_balance(test_db, test_user):
    """
    Test account balance update functionality with validation.
    
    Requirements addressed:
    - Account Management (1.2): Validates real-time balance updates
    - Testing Infrastructure (2.5): Implements balance update validation tests
    """
    # Create test account
    account = Account(
        user_id=UUID(test_user["sub"]),
        institution_id="test_bank_123",
        account_type="savings",
        account_name="Test Savings",
        account_number_masked="****5678",
        current_balance=Decimal("2000.00"),
        currency_code="USD"
    )
    
    # Test balance update
    new_balance = Decimal("2500.50")
    new_available = Decimal("2400.00")
    account.update_balance(new_balance, new_available)
    
    # Verify updated values
    assert account.current_balance == new_balance
    assert account.available_balance == new_available
    assert account.last_synced_at > account.created_at
    assert account.updated_at > account.created_at

@pytest.mark.asyncio
async def test_update_institution_data(test_db, test_user):
    """
    Test institution data update functionality with JSONB handling.
    
    Requirements addressed:
    - Account Management (1.2): Validates institution data management
    - Data Storage (2.1): Verifies JSONB data handling
    """
    # Create test account
    account = Account(
        user_id=UUID(test_user["sub"]),
        institution_id="test_bank_123",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="****4321",
        current_balance=Decimal("1500.00"),
        currency_code="USD"
    )
    
    # Initial institution data
    initial_data = {
        "routing_number": "123456789",
        "status": "active"
    }
    account.update_institution_data(initial_data)
    
    # Update with new data
    new_data = {
        "status": "verified",
        "last_sync_status": "success"
    }
    account.update_institution_data(new_data)
    
    # Verify merged data
    expected_data = {
        "routing_number": "123456789",
        "status": "verified",
        "last_sync_status": "success"
    }
    assert account.institution_data == expected_data
    assert account.updated_at > account.created_at

@pytest.mark.asyncio
async def test_account_to_dict(test_db, test_user):
    """
    Test account serialization to dictionary format.
    
    Requirements addressed:
    - Account Management (1.2): Validates account data serialization
    - Data Storage (2.1): Verifies model data representation
    """
    # Create test account with complete data
    account = Account(
        user_id=UUID(test_user["sub"]),
        institution_id="test_bank_123",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="****9876",
        current_balance=Decimal("3000.00"),
        currency_code="USD"
    )
    
    # Add institution data
    account.update_institution_data({"status": "active"})
    
    # Get dictionary representation
    account_dict = account.to_dict()
    
    # Verify all fields
    assert isinstance(account_dict["id"], str)
    assert isinstance(UUID(account_dict["id"]), UUID)
    assert account_dict["user_id"] == str(account.user_id)
    assert account_dict["institution_id"] == account.institution_id
    assert account_dict["account_type"] == account.account_type
    assert account_dict["account_name"] == account.account_name
    assert account_dict["account_number_masked"] == account.account_number_masked
    assert account_dict["current_balance"] == str(account.current_balance)
    assert account_dict["available_balance"] == str(account.available_balance)
    assert account_dict["currency_code"] == account.currency_code
    assert account_dict["institution_data"] == {"status": "active"}
    assert account_dict["is_active"] is True
    
    # Verify timestamp formats
    assert isinstance(datetime.fromisoformat(account_dict["created_at"]), datetime)
    assert isinstance(datetime.fromisoformat(account_dict["updated_at"]), datetime)
    assert isinstance(datetime.fromisoformat(account_dict["last_synced_at"]), datetime)

@pytest.mark.asyncio
async def test_invalid_balance_update(test_db, test_user):
    """
    Test validation handling for invalid balance updates.
    
    Requirements addressed:
    - Account Management (1.2): Validates balance update error handling
    - Testing Infrastructure (2.5): Implements error case testing
    """
    # Create test account
    account = Account(
        user_id=UUID(test_user["sub"]),
        institution_id="test_bank_123",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="****5432",
        current_balance=Decimal("1000.00"),
        currency_code="USD"
    )
    
    initial_balance = account.current_balance
    initial_timestamp = account.updated_at
    
    # Test negative balance
    with pytest.raises(ValueError, match="Current balance cannot be negative"):
        account.update_balance(Decimal("-100.00"))
    
    # Test negative available balance
    with pytest.raises(ValueError, match="Available balance cannot be negative"):
        account.update_balance(Decimal("100.00"), Decimal("-50.00"))
    
    # Test None value
    with pytest.raises(ValueError, match="Current balance cannot be None"):
        account.update_balance(None)
    
    # Test invalid type
    with pytest.raises(ValueError, match="Current balance must be a Decimal value"):
        account.update_balance(100.00)
    
    # Verify account state unchanged
    assert account.current_balance == initial_balance
    assert account.updated_at == initial_timestamp