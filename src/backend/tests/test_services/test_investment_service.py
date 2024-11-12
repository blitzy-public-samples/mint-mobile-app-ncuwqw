# pytest: ^7.0.0
import pytest
from decimal import Decimal
from uuid import UUID, uuid4
from datetime import datetime

from app.services.investment_service import InvestmentService
from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentResponse

# Human Tasks:
# 1. Configure test database with appropriate permissions for investment operations
# 2. Set up test data fixtures for different investment types
# 3. Configure test environment variables for database connection
# 4. Review and adjust test timeout settings if needed
# 5. Set up monitoring for test execution in CI/CD pipeline

# Test data constants
TEST_INVESTMENT_DATA = {
    'symbol': 'AAPL',
    'name': 'Apple Inc.',
    'investment_type': 'stock',
    'quantity': '10.0',
    'cost_basis': '1500.00',
    'current_value': '1650.00',
    'currency_code': 'USD'
}

@pytest.fixture
def test_investment_service(test_db):
    """
    Provides configured InvestmentService instance for testing.
    
    Requirements addressed:
    - Testing Infrastructure (2.5.2 Deployment Architecture): Implements test fixtures
    """
    return InvestmentService(db=test_db)

@pytest.mark.asyncio
async def test_create_investment(test_investment_service):
    """
    Test investment creation functionality.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment creation with proper data handling
    """
    # Prepare test data
    account_id = uuid4()
    investment_data = InvestmentCreate(
        account_id=account_id,
        **TEST_INVESTMENT_DATA
    )
    
    # Create investment
    result = await test_investment_service.create_investment(investment_data)
    
    # Verify basic fields
    assert isinstance(result, InvestmentResponse)
    assert result.symbol == TEST_INVESTMENT_DATA['symbol']
    assert result.name == TEST_INVESTMENT_DATA['name']
    assert result.investment_type == TEST_INVESTMENT_DATA['investment_type']
    
    # Verify decimal handling
    assert result.quantity == Decimal(TEST_INVESTMENT_DATA['quantity'])
    assert result.cost_basis == Decimal(TEST_INVESTMENT_DATA['cost_basis'])
    assert result.current_value == Decimal(TEST_INVESTMENT_DATA['current_value'])
    
    # Verify currency and calculations
    assert result.currency_code == TEST_INVESTMENT_DATA['currency_code'].upper()
    assert result.unrealized_gain_loss == Decimal('150.00')  # 1650 - 1500
    assert result.return_percentage == Decimal('10.00')  # (150 / 1500) * 100
    
    # Verify status and timestamps
    assert result.is_active is True
    assert isinstance(result.created_at, datetime)
    assert isinstance(result.updated_at, datetime)
    assert isinstance(result.last_synced_at, datetime)

@pytest.mark.asyncio
async def test_get_investment(test_investment_service):
    """
    Test investment retrieval functionality.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment data retrieval
    """
    # Create test investment
    account_id = uuid4()
    investment_data = InvestmentCreate(
        account_id=account_id,
        **TEST_INVESTMENT_DATA
    )
    created = await test_investment_service.create_investment(investment_data)
    
    # Retrieve investment
    result = await test_investment_service.get_investment(created.id)
    
    # Verify retrieved data matches created investment
    assert result.id == created.id
    assert result.symbol == created.symbol
    assert result.quantity == created.quantity
    assert result.cost_basis == created.cost_basis
    assert result.current_value == created.current_value
    
    # Test non-existent investment
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.get_investment(uuid4())

@pytest.mark.asyncio
async def test_update_investment(test_investment_service):
    """
    Test investment update functionality.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment data updates
    """
    # Create test investment
    account_id = uuid4()
    investment_data = InvestmentCreate(
        account_id=account_id,
        **TEST_INVESTMENT_DATA
    )
    created = await test_investment_service.create_investment(investment_data)
    
    # Prepare update data
    update_data = InvestmentUpdate(
        quantity=Decimal('15.0'),
        current_value=Decimal('2250.00'),
        metadata={'note': 'Position increased'}
    )
    
    # Update investment
    result = await test_investment_service.update_investment(created.id, update_data)
    
    # Verify updates
    assert result.quantity == Decimal('15.0')
    assert result.current_value == Decimal('2250.00')
    assert result.metadata == {'note': 'Position increased'}
    assert result.unrealized_gain_loss == Decimal('750.00')  # 2250 - 1500
    assert result.return_percentage == Decimal('50.00')  # (750 / 1500) * 100
    assert result.updated_at > created.updated_at
    
    # Test invalid updates
    with pytest.raises(ValueError):
        await test_investment_service.update_investment(
            created.id,
            InvestmentUpdate(quantity=Decimal('-1.0'))
        )
    
    # Test non-existent investment
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.update_investment(
            uuid4(),
            update_data
        )

@pytest.mark.asyncio
async def test_delete_investment(test_investment_service):
    """
    Test investment deletion functionality.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment deletion handling
    """
    # Create test investment
    account_id = uuid4()
    investment_data = InvestmentCreate(
        account_id=account_id,
        **TEST_INVESTMENT_DATA
    )
    created = await test_investment_service.create_investment(investment_data)
    
    # Delete investment
    result = await test_investment_service.delete_investment(created.id)
    assert result is True
    
    # Verify investment is not retrievable
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.get_investment(created.id)
    
    # Test deleting non-existent investment
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.delete_investment(uuid4())
    
    # Test deleting already deleted investment
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.delete_investment(created.id)

@pytest.mark.asyncio
async def test_list_investments(test_investment_service):
    """
    Test investment listing functionality.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment portfolio listing
    """
    # Create multiple test investments
    account_id = uuid4()
    investments = []
    for i in range(3):
        data = dict(TEST_INVESTMENT_DATA)
        data['symbol'] = f"TEST{i}"
        investment_data = InvestmentCreate(
            account_id=account_id,
            **data
        )
        investment = await test_investment_service.create_investment(investment_data)
        investments.append(investment)
    
    # Test pagination
    result = await test_investment_service.list_investments(account_id, skip=0, limit=2)
    assert len(result) == 2
    assert all(isinstance(inv, InvestmentResponse) for inv in result)
    
    # Test full list
    result = await test_investment_service.list_investments(account_id)
    assert len(result) == 3
    assert all(inv.account_id == account_id for inv in result)
    
    # Test empty account
    result = await test_investment_service.list_investments(uuid4())
    assert len(result) == 0

@pytest.mark.asyncio
async def test_sync_investment_values(test_investment_service):
    """
    Test investment value synchronization.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment value updates and calculations
    """
    # Create test investment
    account_id = uuid4()
    investment_data = InvestmentCreate(
        account_id=account_id,
        **TEST_INVESTMENT_DATA
    )
    created = await test_investment_service.create_investment(investment_data)
    
    # Sync new values
    new_value = Decimal('1800.00')
    new_quantity = Decimal('12.0')
    result = await test_investment_service.sync_investment_values(
        created.id,
        current_value=new_value,
        quantity=new_quantity
    )
    
    # Verify updates
    assert result.current_value == new_value
    assert result.quantity == new_quantity
    assert result.unrealized_gain_loss == Decimal('300.00')  # 1800 - 1500
    assert result.return_percentage == Decimal('20.00')  # (300 / 1500) * 100
    assert result.last_synced_at > created.last_synced_at
    
    # Test invalid values
    with pytest.raises(ValueError):
        await test_investment_service.sync_investment_values(
            created.id,
            current_value=Decimal('-100.00')
        )
    
    # Test non-existent investment
    with pytest.raises(ValueError, match="Investment .* not found or inactive"):
        await test_investment_service.sync_investment_values(
            uuid4(),
            current_value=new_value
        )

@pytest.mark.asyncio
async def test_calculate_portfolio_metrics(test_investment_service):
    """
    Test portfolio metrics calculation.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates portfolio performance calculations
    """
    # Create multiple test investments with known values
    account_id = uuid4()
    investments = []
    test_data = [
        {'cost_basis': '1000.00', 'current_value': '1200.00'},
        {'cost_basis': '2000.00', 'current_value': '2300.00'},
        {'cost_basis': '3000.00', 'current_value': '3300.00'}
    ]
    
    for data in test_data:
        inv_data = dict(TEST_INVESTMENT_DATA)
        inv_data.update(data)
        investment_data = InvestmentCreate(
            account_id=account_id,
            **inv_data
        )
        investment = await test_investment_service.create_investment(investment_data)
        investments.append(investment)
    
    # Calculate metrics
    result = await test_investment_service.calculate_portfolio_metrics(account_id)
    
    # Verify calculations
    assert Decimal(result['total_value']) == Decimal('6800.00')  # 1200 + 2300 + 3300
    assert Decimal(result['total_cost_basis']) == Decimal('6000.00')  # 1000 + 2000 + 3000
    assert Decimal(result['total_gain_loss']) == Decimal('800.00')  # 6800 - 6000
    assert Decimal(result['return_percentage']) == Decimal('13.33')  # (800 / 6000) * 100
    
    # Test empty portfolio
    empty_result = await test_investment_service.calculate_portfolio_metrics(uuid4())
    assert all(Decimal(v) == Decimal('0') for v in empty_result.values())