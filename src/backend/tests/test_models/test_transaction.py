# pytest: ^7.0.0
import pytest
from decimal import Decimal
from datetime import datetime
from uuid import uuid4
import uuid

from app.models.transaction import Transaction
from app.models.account import Account
from app.models.category import Category
from tests.conftest import test_db

# Human Tasks:
# 1. Verify test database has proper schema and permissions for transaction testing
# 2. Configure appropriate test data volume for performance testing
# 3. Set up monitoring for test execution times
# 4. Review transaction validation rules with business stakeholders

# Test data constants
VALID_TRANSACTION_DATA = {
    'amount': Decimal('100.00'),
    'description': 'Test Transaction',
    'transaction_type': 'debit',
    'merchant_name': 'Test Merchant',
    'status': 'completed',
    'is_pending': False,
    'transaction_date': datetime.utcnow(),
    'metadata': {}
}

INVALID_TEST_CASES = [
    {'data': {'amount': None}, 'error': ValueError},
    {'data': {'transaction_type': 'invalid'}, 'error': ValueError},
    {'data': {'status': 'invalid'}, 'error': ValueError}
]

class TransactionFixture:
    """
    Fixture class providing test transaction data and utilities.
    
    Requirements addressed:
    - Financial Tracking (1.2): Provides test data for transaction validation
    - Data Storage (2.1): Supports database model testing
    """
    
    def __init__(self, test_db):
        self.db = test_db
        self.test_account = None
        self.test_category = None
        self.valid_transaction_data = dict(VALID_TRANSACTION_DATA)
        
    async def setup(self):
        """Initialize test data"""
        # Create test account
        self.test_account = Account(
            user_id=uuid4(),
            institution_id='test_bank',
            account_type='checking',
            account_name='Test Account',
            account_number_masked='****1234',
            current_balance=Decimal('1000.00'),
            currency_code='USD'
        )
        self.db.add(self.test_account)
        
        # Create test category
        self.test_category = Category(
            name='Test Category',
            description='Test category for transactions'
        )
        self.db.add(self.test_category)
        await self.db.commit()
        
        # Update valid data with test account
        self.valid_transaction_data['account_id'] = self.test_account.id
        
    async def create_test_transaction(self, override_data=None):
        """Create a test transaction instance"""
        data = dict(self.valid_transaction_data)
        if override_data:
            data.update(override_data)
            
        transaction = Transaction(
            account_id=data['account_id'],
            transaction_date=data['transaction_date'],
            amount=data['amount'],
            description=data['description'],
            transaction_type=data['transaction_type']
        )
        self.db.add(transaction)
        await self.db.commit()
        return transaction

@pytest.mark.asyncio
@pytest.mark.parametrize('transaction_data', [VALID_TRANSACTION_DATA])
async def test_transaction_create(test_db, transaction_data):
    """
    Test creating a new transaction with valid data.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates transaction creation
    - Data Storage (2.1): Verifies database model implementation
    - Database Schema (5.2.1): Tests transaction schema compliance
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create transaction
    transaction = await fixture.create_test_transaction()
    
    # Verify attributes
    assert isinstance(transaction.id, uuid.UUID)
    assert transaction.account_id == fixture.test_account.id
    assert transaction.amount == transaction_data['amount']
    assert transaction.description == transaction_data['description']
    assert transaction.transaction_type == transaction_data['transaction_type']
    assert transaction.status == 'pending'
    assert transaction.is_pending is True
    assert isinstance(transaction.created_at, datetime)
    assert isinstance(transaction.updated_at, datetime)

@pytest.mark.asyncio
async def test_transaction_update_category(test_db):
    """
    Test updating transaction category.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates category management
    - Database Schema (5.2.1): Tests category relationship
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create transaction
    transaction = await fixture.create_test_transaction()
    
    # Update category
    await transaction.update_category(fixture.test_category.id)
    await test_db.commit()
    
    # Verify update
    assert transaction.category_id == fixture.test_category.id
    assert transaction.category.name == fixture.test_category.name
    
    # Test removing category
    await transaction.update_category(None)
    await test_db.commit()
    assert transaction.category_id is None

@pytest.mark.asyncio
@pytest.mark.parametrize('status,is_pending', [
    ('pending', True),
    ('posted', False),
    ('cancelled', False)
])
async def test_transaction_update_status(test_db, status, is_pending):
    """
    Test updating transaction status and pending flag.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates transaction status management
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create transaction
    transaction = await fixture.create_test_transaction()
    initial_updated_at = transaction.updated_at
    
    # Update status
    await transaction.update_status(status, is_pending)
    await test_db.commit()
    
    # Verify update
    assert transaction.status == status
    assert transaction.is_pending == is_pending
    assert transaction.updated_at > initial_updated_at
    
    # Test invalid status
    with pytest.raises(ValueError):
        await transaction.update_status('invalid', False)

@pytest.mark.asyncio
async def test_transaction_update_metadata(test_db):
    """
    Test updating transaction metadata.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates additional data storage
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create transaction
    transaction = await fixture.create_test_transaction()
    
    # Update metadata
    test_metadata = {'reference': 'TEST123', 'tags': ['test']}
    await transaction.update_metadata(test_metadata)
    await test_db.commit()
    
    # Verify metadata
    assert transaction.metadata == test_metadata
    
    # Test metadata merge
    additional_metadata = {'category_confidence': 0.95}
    await transaction.update_metadata(additional_metadata)
    await test_db.commit()
    
    assert transaction.metadata['reference'] == 'TEST123'
    assert transaction.metadata['category_confidence'] == 0.95

@pytest.mark.asyncio
async def test_transaction_to_dict(test_db):
    """
    Test transaction model serialization to dictionary.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates data representation
    - Database Schema (5.2.1): Tests model serialization
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create transaction with category
    transaction = await fixture.create_test_transaction()
    await transaction.update_category(fixture.test_category.id)
    await test_db.commit()
    
    # Get dictionary representation
    result = transaction.to_dict()
    
    # Verify serialization
    assert isinstance(result['id'], str)
    assert isinstance(result['account_id'], str)
    assert isinstance(result['amount'], str)
    assert isinstance(result['created_at'], str)
    assert isinstance(result['updated_at'], str)
    assert 'category' in result
    assert result['category']['id'] == fixture.test_category.id
    assert result['category']['name'] == fixture.test_category.name

@pytest.mark.asyncio
@pytest.mark.parametrize('invalid_data,expected_error', INVALID_TEST_CASES)
async def test_transaction_validation(test_db, invalid_data, expected_error):
    """
    Test transaction data validation.
    
    Requirements addressed:
    - Financial Tracking (1.2): Validates data integrity
    - Data Storage (2.1): Tests model validation
    """
    fixture = TransactionFixture(test_db)
    await fixture.setup()
    
    # Create invalid test data
    test_data = dict(fixture.valid_transaction_data)
    test_data.update(invalid_data)
    
    # Attempt to create transaction with invalid data
    with pytest.raises(expected_error):
        await fixture.create_test_transaction(test_data)
    
    # Verify transaction was not created
    transactions = await test_db.query(Transaction).all()
    assert len(transactions) == 0