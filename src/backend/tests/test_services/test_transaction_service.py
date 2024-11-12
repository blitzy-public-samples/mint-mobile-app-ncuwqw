# pytest: ^7.0.0
import pytest
from unittest.mock import Mock, patch
from datetime import datetime, timedelta
from decimal import Decimal
import uuid

# Internal imports
from app.services.transaction_service import TransactionService, TransactionCreate, TransactionUpdate
from app.models.transaction import Transaction
from tests.conftest import get_test_db, get_test_redis

# Human Tasks:
# 1. Configure test database with sample transaction data
# 2. Set up test Redis instance for caching tests
# 3. Configure Plaid sandbox credentials for sync tests
# 4. Review and adjust test timeouts if needed
# 5. Set up monitoring for test coverage metrics

TEST_TRANSACTION_DATA = {
    'account_id': uuid.uuid4(),
    'amount': Decimal('100.00'),
    'description': 'Test Transaction',
    'transaction_type': 'debit',
    'transaction_date': datetime.now()
}

@pytest.fixture
def transaction_service(test_db, test_redis):
    """
    Pytest fixture that provides a configured TransactionService instance for testing.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Provides isolated test environment
    """
    # Mock Plaid service
    mock_plaid = Mock()
    mock_plaid.sync_transactions = Mock(return_value=([], "test_cursor"))
    
    # Create service instance
    service = TransactionService(test_db, mock_plaid)
    service._cache = test_redis
    
    return service

@pytest.mark.asyncio
async def test_get_transaction(transaction_service, test_db):
    """
    Test retrieving a single transaction by ID.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify transaction retrieval
    - Data Security Testing (6.2.1): Validate secure data handling
    """
    # Create test transaction
    transaction = Transaction(**TEST_TRANSACTION_DATA)
    test_db.add(transaction)
    await test_db.commit()
    
    # Test retrieval
    result = await transaction_service.get_transaction(transaction.id)
    assert result is not None
    assert result.id == transaction.id
    assert result.amount == TEST_TRANSACTION_DATA['amount']
    
    # Test cache hit
    cached_result = await transaction_service.get_transaction(transaction.id)
    assert cached_result is not None
    assert cached_result.id == transaction.id
    
    # Test non-existent transaction
    non_existent = await transaction_service.get_transaction(uuid.uuid4())
    assert non_existent is None

@pytest.mark.asyncio
async def test_get_transactions(transaction_service, test_db):
    """
    Test retrieving transactions with filters and pagination.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify transaction filtering
    """
    # Create test transactions
    account_id = uuid.uuid4()
    base_date = datetime.now()
    
    transactions = []
    for i in range(5):
        tx_data = {
            'account_id': account_id,
            'amount': Decimal(f'{100 + i}.00'),
            'description': f'Test Transaction {i}',
            'transaction_type': 'debit',
            'transaction_date': base_date - timedelta(days=i)
        }
        transaction = Transaction(**tx_data)
        transactions.append(transaction)
        test_db.add(transaction)
    
    await test_db.commit()
    
    # Test date range filtering
    start_date = base_date - timedelta(days=3)
    results, count = await transaction_service.get_transactions(
        account_id=account_id,
        start_date=start_date,
        page=1,
        page_size=10
    )
    assert len(results) == 4
    assert count == 4
    
    # Test pagination
    results, count = await transaction_service.get_transactions(
        account_id=account_id,
        page=1,
        page_size=2
    )
    assert len(results) == 2
    assert count == 5

@pytest.mark.asyncio
async def test_create_transaction(transaction_service):
    """
    Test transaction creation functionality.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify transaction creation
    - Data Security Testing (6.2.1): Validate secure data handling
    """
    # Prepare test data
    tx_create = TransactionCreate(
        account_id=TEST_TRANSACTION_DATA['account_id'],
        amount=float(TEST_TRANSACTION_DATA['amount']),
        description=TEST_TRANSACTION_DATA['description'],
        transaction_type=TEST_TRANSACTION_DATA['transaction_type'],
        transaction_date=TEST_TRANSACTION_DATA['transaction_date']
    )
    
    # Test creation
    transaction = await transaction_service.create_transaction(tx_create)
    assert transaction is not None
    assert transaction.account_id == tx_create.account_id
    assert transaction.amount == Decimal(str(tx_create.amount))
    
    # Test validation error
    with pytest.raises(ValueError):
        await transaction_service.create_transaction(
            TransactionCreate(
                account_id=None,
                amount=100.00,
                description="Invalid",
                transaction_type="debit",
                transaction_date=datetime.now()
            )
        )

@pytest.mark.asyncio
async def test_update_transaction(transaction_service, test_db):
    """
    Test transaction update functionality.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify transaction updates
    """
    # Create test transaction
    transaction = Transaction(**TEST_TRANSACTION_DATA)
    test_db.add(transaction)
    await test_db.commit()
    
    # Test update
    update_data = TransactionUpdate(
        amount=200.00,
        description="Updated Transaction"
    )
    
    updated = await transaction_service.update_transaction(
        transaction.id,
        update_data
    )
    assert updated.amount == Decimal('200.00')
    assert updated.description == "Updated Transaction"
    
    # Test invalid update
    with pytest.raises(ValueError):
        await transaction_service.update_transaction(
            uuid.uuid4(),
            update_data
        )

@pytest.mark.asyncio
async def test_sync_transactions(transaction_service):
    """
    Test Plaid transaction synchronization.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify automated transaction import
    """
    # Mock Plaid response
    plaid_transactions = [{
        'id': 'plaid_tx_1',
        'date': datetime.now().isoformat(),
        'amount': 50.00,
        'name': 'Plaid Test Transaction',
        'merchant_name': 'Test Merchant',
        'pending': False
    }]
    
    transaction_service._plaid_service.sync_transactions.return_value = (
        plaid_transactions,
        "updated_cursor"
    )
    
    # Test sync
    transactions, cursor = await transaction_service.sync_transactions(
        account_id=uuid.uuid4(),
        access_token="test_token"
    )
    
    assert len(transactions) == 1
    assert cursor == "updated_cursor"
    assert transactions[0].description == "Plaid Test Transaction"

@pytest.mark.asyncio
async def test_categorize_transaction(transaction_service, test_db):
    """
    Test transaction categorization functionality.
    
    Requirements addressed:
    - Financial Tracking Testing (1.2): Verify category management
    """
    # Create test transaction
    transaction = Transaction(**TEST_TRANSACTION_DATA)
    test_db.add(transaction)
    await test_db.commit()
    
    # Test categorization
    category_id = 1
    updated = await transaction_service.categorize_transaction(
        transaction.id,
        category_id
    )
    assert updated.category_id == category_id
    
    # Test invalid category
    with pytest.raises(ValueError):
        await transaction_service.categorize_transaction(
            transaction.id,
            "invalid_category"
        )