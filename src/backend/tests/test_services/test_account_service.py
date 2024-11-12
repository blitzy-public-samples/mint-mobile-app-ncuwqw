"""
Test suite for AccountService class verifying account management functionality.

Human Tasks:
1. Ensure test database is configured and accessible
2. Configure test Redis instance for caching tests
3. Set up test Plaid API credentials if using real Plaid sandbox
4. Review and adjust test timeouts if needed
"""

# pytest: ^7.0.0
import pytest
from decimal import Decimal
from unittest.mock import Mock, patch
# freezegun: ^1.2.0
from freezegun import freeze_time

from app.services.account_service import AccountService
from app.models.account import Account

@pytest.fixture
def account_service(test_db):
    """
    Fixture providing configured AccountService instance for testing.
    
    Requirements addressed:
    - Account Management Testing (1.2): Configure service with test dependencies
    - Data Security Testing (6.2.2): Use isolated test database and mocked services
    """
    # Create mock Plaid service
    mock_plaid_service = Mock()
    
    # Configure mock responses
    mock_plaid_service.get_accounts.return_value = [{
        'id': 'test_plaid_account_id',
        'type': 'depository',
        'name': 'Test Checking Account',
        'mask': '1234',
        'balances': {
            'current': 1000.00,
            'available': 900.00
        }
    }]
    
    mock_plaid_service.get_balances.return_value = [{
        'account_id': 'test_plaid_account_id',
        'current': 1500.00,
        'available': 1400.00
    }]
    
    # Initialize service with test dependencies
    service = AccountService(
        plaid_service=mock_plaid_service,
        db_session=test_db
    )
    
    return service

@pytest.mark.asyncio
async def test_create_account(account_service, test_db):
    """
    Test account creation functionality.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify account creation with Plaid integration
    - Data Security Testing (6.2.2): Validate secure handling of account data
    """
    # Test data
    test_user_id = "test_user_123"
    test_access_token = "test_access_token"
    test_plaid_account_id = "test_plaid_account_id"
    
    # Create account
    account = await account_service.create_account(
        user_id=test_user_id,
        access_token=test_access_token,
        plaid_account_id=test_plaid_account_id
    )
    
    # Verify account properties
    assert account.user_id == test_user_id
    assert account.institution_id == test_plaid_account_id
    assert account.account_type == "depository"
    assert account.account_name == "Test Checking Account"
    assert account.account_number_masked == "1234"
    assert account.current_balance == Decimal("1000.00")
    assert account.is_active is True
    
    # Verify database persistence
    db_account = test_db.query(Account).filter(
        Account.id == account.id
    ).first()
    assert db_account is not None
    assert db_account.current_balance == Decimal("1000.00")
    
    # Verify cache
    cached_account = account_service.get_account(
        account_id=str(account.id),
        use_cache=True
    )
    assert cached_account is not None
    assert cached_account.id == account.id

@pytest.mark.asyncio
async def test_get_account(account_service, test_db):
    """
    Test account retrieval functionality with caching.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify account retrieval with caching
    - Data Security Testing (6.2.2): Validate secure data access
    """
    # Create test account
    test_account = Account(
        user_id="test_user_123",
        institution_id="test_institution",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="5678",
        current_balance=Decimal("2000.00"),
        currency_code="USD"
    )
    test_db.add(test_account)
    test_db.commit()
    
    # Test retrieval with cache
    cached_account = account_service.get_account(
        account_id=str(test_account.id),
        use_cache=True
    )
    assert cached_account is not None
    assert cached_account.id == test_account.id
    assert cached_account.current_balance == Decimal("2000.00")
    
    # Test retrieval without cache
    db_account = account_service.get_account(
        account_id=str(test_account.id),
        use_cache=False
    )
    assert db_account is not None
    assert db_account.id == test_account.id
    
    # Test non-existent account
    non_existent = account_service.get_account(
        account_id="non_existent_id",
        use_cache=True
    )
    assert non_existent is None

@pytest.mark.asyncio
async def test_update_account_balance(account_service, test_db):
    """
    Test account balance update functionality.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify real-time balance updates
    - Data Security Testing (6.2.2): Validate secure balance updates
    """
    # Create test account
    test_account = Account(
        user_id="test_user_123",
        institution_id="test_plaid_account_id",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="5678",
        current_balance=Decimal("1000.00"),
        currency_code="USD"
    )
    test_db.add(test_account)
    test_db.commit()
    
    # Freeze time for consistent timestamps
    with freeze_time("2024-01-01 12:00:00"):
        # Update balance
        success = await account_service.update_account_balance(
            account_id=str(test_account.id)
        )
        
        # Verify update success
        assert success is True
        
        # Verify updated balances
        updated_account = account_service.get_account(
            account_id=str(test_account.id),
            use_cache=False
        )
        assert updated_account.current_balance == Decimal("1500.00")
        assert updated_account.available_balance == Decimal("1400.00")
        assert updated_account.last_synced_at.isoformat() == "2024-01-01T12:00:00"

@pytest.mark.asyncio
async def test_sync_accounts(account_service, test_db):
    """
    Test account synchronization functionality.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify account data synchronization
    - Data Security Testing (6.2.2): Validate secure multi-account updates
    """
    # Create test accounts
    test_user_id = "test_user_123"
    test_accounts = [
        Account(
            user_id=test_user_id,
            institution_id="test_account_1",
            account_type="checking",
            account_name="Test Checking",
            account_number_masked="1234",
            current_balance=Decimal("1000.00"),
            currency_code="USD"
        ),
        Account(
            user_id=test_user_id,
            institution_id="test_account_2",
            account_type="savings",
            account_name="Test Savings",
            account_number_masked="5678",
            current_balance=Decimal("2000.00"),
            currency_code="USD"
        )
    ]
    
    for account in test_accounts:
        test_db.add(account)
    test_db.commit()
    
    # Sync accounts
    with freeze_time("2024-01-01 12:00:00"):
        updated_accounts = await account_service.sync_accounts(
            user_id=test_user_id
        )
        
        # Verify sync results
        assert len(updated_accounts) == 2
        for account in updated_accounts:
            assert account.last_synced_at.isoformat() == "2024-01-01T12:00:00"
            
            # Verify cache updated
            cached_account = account_service.get_account(
                account_id=str(account.id),
                use_cache=True
            )
            assert cached_account is not None
            assert cached_account.last_synced_at.isoformat() == "2024-01-01T12:00:00"

@pytest.mark.asyncio
async def test_deactivate_account(account_service, test_db):
    """
    Test account deactivation functionality.
    
    Requirements addressed:
    - Account Management Testing (1.2): Verify account deactivation
    - Data Security Testing (6.2.2): Validate secure account state changes
    """
    # Create test account
    test_account = Account(
        user_id="test_user_123",
        institution_id="test_institution",
        account_type="checking",
        account_name="Test Account",
        account_number_masked="5678",
        current_balance=Decimal("1000.00"),
        currency_code="USD"
    )
    test_db.add(test_account)
    test_db.commit()
    
    # Deactivate account
    with freeze_time("2024-01-01 12:00:00"):
        success = account_service.deactivate_account(
            account_id=str(test_account.id)
        )
        
        # Verify deactivation
        assert success is True
        
        # Verify account state
        deactivated_account = test_db.query(Account).filter(
            Account.id == test_account.id
        ).first()
        assert deactivated_account is not None
        assert deactivated_account.is_active is False
        assert deactivated_account.updated_at.isoformat() == "2024-01-01T12:00:00"
        
        # Verify account removed from cache
        cached_account = account_service.get_account(
            account_id=str(test_account.id),
            use_cache=True
        )
        assert cached_account is None