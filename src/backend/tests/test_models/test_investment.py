# pytest: ^7.0.0
import pytest
from decimal import Decimal
from datetime import datetime
from uuid import uuid4

from app.models.investment import Investment
from tests.conftest import get_test_db

# Human Tasks:
# 1. Ensure test database has appropriate permissions for investment table operations
# 2. Verify test database schema is up to date with latest investment model changes
# 3. Configure test environment variables for database connection

# Test data constants
TEST_INVESTMENT_DATA = {
    'symbol': 'AAPL',
    'name': 'Apple Inc.',
    'investment_type': 'stock',
    'quantity': '10.0',
    'cost_basis': '150.00',
    'current_value': '160.00',
    'currency_code': 'USD'
}

@pytest.mark.parametrize('investment_type', ['stock', 'etf', 'mutual_fund', 'bond'])
async def test_investment_creation(test_db, investment_type):
    """
    Test creating a new investment instance with valid data.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates basic portfolio monitoring functionality
    - Data Model Testing (5.2.1): Verifies investment model schema implementation
    """
    # Generate test account ID
    test_account_id = uuid4()
    
    # Create test investment with parametrized type
    test_data = TEST_INVESTMENT_DATA.copy()
    test_data['investment_type'] = investment_type
    
    investment = Investment(
        account_id=test_account_id,
        symbol=test_data['symbol'],
        name=test_data['name'],
        investment_type=test_data['investment_type'],
        quantity=Decimal(test_data['quantity']),
        cost_basis=Decimal(test_data['cost_basis']),
        current_value=Decimal(test_data['current_value']),
        currency_code=test_data['currency_code']
    )
    
    # Validate UUID fields
    assert isinstance(investment.id, uuid4().__class__)
    assert investment.account_id == test_account_id
    
    # Verify numeric fields use Decimal type
    assert isinstance(investment.quantity, Decimal)
    assert isinstance(investment.cost_basis, Decimal)
    assert isinstance(investment.current_value, Decimal)
    assert isinstance(investment.unrealized_gain_loss, Decimal)
    assert isinstance(investment.return_percentage, Decimal)
    
    # Verify investment type
    assert investment.investment_type == investment_type
    
    # Check performance calculations
    expected_gain_loss = Decimal('160.00') - Decimal('150.00')
    expected_return = (expected_gain_loss / Decimal('150.00')) * Decimal('100')
    
    assert investment.unrealized_gain_loss == expected_gain_loss
    assert investment.return_percentage == expected_return
    
    # Verify timestamps
    assert isinstance(investment.created_at, datetime)
    assert isinstance(investment.updated_at, datetime)
    assert isinstance(investment.last_synced_at, datetime)
    
    # Verify default values
    assert investment.is_active is True
    assert investment.metadata == {}

async def test_investment_update_value(test_db):
    """
    Test updating investment value and recalculating performance metrics.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates value updates and performance calculations
    - Data Model Testing (5.2.1): Verifies data integrity during updates
    """
    # Create test investment
    test_account_id = uuid4()
    investment = Investment(
        account_id=test_account_id,
        symbol=TEST_INVESTMENT_DATA['symbol'],
        name=TEST_INVESTMENT_DATA['name'],
        investment_type=TEST_INVESTMENT_DATA['investment_type'],
        quantity=Decimal(TEST_INVESTMENT_DATA['quantity']),
        cost_basis=Decimal(TEST_INVESTMENT_DATA['cost_basis']),
        current_value=Decimal(TEST_INVESTMENT_DATA['current_value']),
        currency_code=TEST_INVESTMENT_DATA['currency_code']
    )
    
    original_sync_time = investment.last_synced_at
    original_update_time = investment.updated_at
    
    # Update value and quantity
    new_value = Decimal('175.00')
    new_quantity = Decimal('12.0')
    investment.update_value(new_value, new_quantity)
    
    # Verify updates
    assert investment.current_value == new_value
    assert investment.quantity == new_quantity
    
    # Verify recalculated metrics
    expected_gain_loss = new_value - Decimal('150.00')
    expected_return = (expected_gain_loss / Decimal('150.00')) * Decimal('100')
    
    assert investment.unrealized_gain_loss == expected_gain_loss
    assert investment.return_percentage == expected_return
    
    # Verify timestamps updated
    assert investment.last_synced_at > original_sync_time
    assert investment.updated_at > original_update_time
    
    # Test negative value validation
    with pytest.raises(ValueError):
        investment.update_value(Decimal('-100.00'))
    
    with pytest.raises(ValueError):
        investment.update_value(Decimal('100.00'), Decimal('-5.0'))

async def test_investment_metadata(test_db):
    """
    Test updating and retrieving investment metadata.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates metadata handling functionality
    - Data Model Testing (5.2.1): Verifies JSONB data storage
    """
    # Create test investment
    test_account_id = uuid4()
    investment = Investment(
        account_id=test_account_id,
        symbol=TEST_INVESTMENT_DATA['symbol'],
        name=TEST_INVESTMENT_DATA['name'],
        investment_type=TEST_INVESTMENT_DATA['investment_type'],
        quantity=Decimal(TEST_INVESTMENT_DATA['quantity']),
        cost_basis=Decimal(TEST_INVESTMENT_DATA['cost_basis']),
        current_value=Decimal(TEST_INVESTMENT_DATA['current_value']),
        currency_code=TEST_INVESTMENT_DATA['currency_code']
    )
    
    # Test metadata update
    test_metadata = {
        'sector': 'Technology',
        'risk_rating': 'moderate',
        'dividend_yield': '1.5'
    }
    
    original_update_time = investment.updated_at
    investment.update_metadata(test_metadata)
    
    # Verify metadata stored correctly
    assert investment.metadata == test_metadata
    assert investment.updated_at > original_update_time
    
    # Test metadata merging
    additional_metadata = {
        'market_cap': 'large',
        'risk_rating': 'high'  # Should override existing value
    }
    investment.update_metadata(additional_metadata)
    
    expected_metadata = {
        'sector': 'Technology',
        'risk_rating': 'high',
        'dividend_yield': '1.5',
        'market_cap': 'large'
    }
    assert investment.metadata == expected_metadata
    
    # Test invalid metadata
    with pytest.raises(ValueError):
        investment.update_metadata("invalid")

async def test_investment_to_dict(test_db):
    """
    Test converting investment model to dictionary representation.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates data serialization
    - Data Model Testing (5.2.1): Verifies model representation
    """
    # Create test investment
    test_account_id = uuid4()
    investment = Investment(
        account_id=test_account_id,
        symbol=TEST_INVESTMENT_DATA['symbol'],
        name=TEST_INVESTMENT_DATA['name'],
        investment_type=TEST_INVESTMENT_DATA['investment_type'],
        quantity=Decimal(TEST_INVESTMENT_DATA['quantity']),
        cost_basis=Decimal(TEST_INVESTMENT_DATA['cost_basis']),
        current_value=Decimal(TEST_INVESTMENT_DATA['current_value']),
        currency_code=TEST_INVESTMENT_DATA['currency_code']
    )
    
    # Add test metadata
    test_metadata = {'sector': 'Technology'}
    investment.update_metadata(test_metadata)
    
    # Convert to dictionary
    investment_dict = investment.to_dict()
    
    # Verify all fields are included
    expected_fields = {
        'id', 'account_id', 'symbol', 'name', 'investment_type',
        'quantity', 'cost_basis', 'current_value', 'unrealized_gain_loss',
        'return_percentage', 'currency_code', 'metadata', 'is_active',
        'last_synced_at', 'created_at', 'updated_at'
    }
    assert set(investment_dict.keys()) == expected_fields
    
    # Verify field formats
    assert isinstance(investment_dict['id'], str)
    assert isinstance(investment_dict['account_id'], str)
    assert isinstance(investment_dict['quantity'], str)
    assert isinstance(investment_dict['cost_basis'], str)
    assert isinstance(investment_dict['current_value'], str)
    assert isinstance(investment_dict['unrealized_gain_loss'], str)
    assert isinstance(investment_dict['return_percentage'], str)
    
    # Verify timestamps are ISO formatted
    assert isinstance(investment_dict['last_synced_at'], str)
    assert isinstance(investment_dict['created_at'], str)
    assert isinstance(investment_dict['updated_at'], str)
    
    # Verify metadata
    assert investment_dict['metadata'] == test_metadata