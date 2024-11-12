# pytest: ^7.0.0
# fastapi.testclient: ^0.68.0

import pytest
from decimal import Decimal
from uuid import uuid4, UUID
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import test_db, test_user
from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentUpdate
from app.api.v1.endpoints.investments import router

# Human Tasks:
# 1. Configure test data fixtures in CI/CD pipeline
# 2. Set up test coverage monitoring
# 3. Review and adjust test timeouts for investment sync tests
# 4. Configure test database with appropriate test data
# 5. Set up monitoring for test execution times

@pytest.fixture
def test_investment_data() -> dict:
    """
    Fixture providing test investment data.
    
    Requirements addressed:
    - Investment Tracking (1.2): Provides test data for investment tracking validation
    """
    return {
        "symbol": "AAPL",
        "name": "Apple Inc.",
        "investment_type": "stock",
        "quantity": Decimal("10.0"),
        "cost_basis": Decimal("1500.00"),
        "current_value": Decimal("1600.00"),
        "currency_code": "USD",
        "metadata": {"sector": "Technology"}
    }

async def create_test_investment(db: AsyncSession, user: dict) -> Investment:
    """
    Helper function to create test investment in database.
    
    Requirements addressed:
    - Investment Tracking (1.2): Creates test investment data
    """
    investment = Investment(
        account_id=UUID(user["account_id"]),
        **test_investment_data()
    )
    db.add(investment)
    await db.commit()
    await db.refresh(investment)
    return investment

@pytest.mark.asyncio
async def test_create_investment(test_db: AsyncSession, test_user: dict):
    """
    Test investment creation endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment creation functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Prepare test data
    investment_data = InvestmentCreate(
        account_id=UUID(test_user["account_id"]),
        **test_investment_data()
    )
    
    # Test successful creation
    response = await client.post(
        "/investments/",
        json=investment_data.dict(),
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["symbol"] == investment_data.symbol
    assert Decimal(data["current_value"]) == investment_data.current_value
    assert UUID(data["account_id"]) == investment_data.account_id

@pytest.mark.asyncio
async def test_get_investment(test_db: AsyncSession, test_user: dict):
    """
    Test investment retrieval endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment lookup functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create test investment
    investment = await create_test_investment(test_db, test_user)
    
    # Test successful retrieval
    response = await client.get(
        f"/investments/{investment.id}",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == str(investment.id)
    assert data["symbol"] == investment.symbol
    
    # Test non-existent investment
    response = await client.get(
        f"/investments/{uuid4()}",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    assert response.status_code == 404

@pytest.mark.asyncio
async def test_update_investment(test_db: AsyncSession, test_user: dict):
    """
    Test investment update endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment update functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create test investment
    investment = await create_test_investment(test_db, test_user)
    
    # Prepare update data
    update_data = InvestmentUpdate(
        quantity=Decimal("15.0"),
        current_value=Decimal("2400.00")
    )
    
    # Test successful update
    response = await client.put(
        f"/investments/{investment.id}",
        json=update_data.dict(exclude_unset=True),
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert Decimal(data["quantity"]) == update_data.quantity
    assert Decimal(data["current_value"]) == update_data.current_value

@pytest.mark.asyncio
async def test_delete_investment(test_db: AsyncSession, test_user: dict):
    """
    Test investment deletion endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment deletion functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create test investment
    investment = await create_test_investment(test_db, test_user)
    
    # Test successful deletion
    response = await client.delete(
        f"/investments/{investment.id}",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    
    # Verify investment is inactive
    response = await client.get(
        f"/investments/{investment.id}",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    data = response.json()
    assert not data["is_active"]

@pytest.mark.asyncio
async def test_list_investments(test_db: AsyncSession, test_user: dict):
    """
    Test investment listing endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates portfolio listing functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create multiple test investments
    investments = []
    for _ in range(3):
        investment = await create_test_investment(test_db, test_user)
        investments.append(investment)
    
    # Test pagination
    response = await client.get(
        f"/investments/?account_id={test_user['account_id']}&skip=0&limit=2",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    
    # Test full list
    response = await client.get(
        f"/investments/?account_id={test_user['account_id']}",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3

@pytest.mark.asyncio
async def test_sync_investment_values(test_db: AsyncSession, test_user: dict):
    """
    Test investment value sync endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates investment value update functionality
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create test investment
    investment = await create_test_investment(test_db, test_user)
    
    # Test value sync
    new_value = Decimal("1800.00")
    new_quantity = Decimal("12.0")
    
    response = await client.patch(
        f"/investments/{investment.id}/sync",
        json={"current_value": str(new_value), "quantity": str(new_quantity)},
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert Decimal(data["current_value"]) == new_value
    assert Decimal(data["quantity"]) == new_quantity

@pytest.mark.asyncio
async def test_get_portfolio_metrics(test_db: AsyncSession, test_user: dict):
    """
    Test portfolio metrics endpoint.
    
    Requirements addressed:
    - Investment Tracking (1.2): Validates portfolio metrics calculation
    - Security Testing (6.3.1): Verifies secure API endpoint behavior
    """
    client = TestClient(router)
    
    # Create multiple investments
    for _ in range(3):
        await create_test_investment(test_db, test_user)
    
    # Test metrics calculation
    response = await client.get(
        f"/investments/{test_user['account_id']}/metrics",
        headers={"Authorization": f"Bearer {test_user['access_token']}"}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "total_value" in data
    assert "total_gain_loss" in data
    assert "total_return_percentage" in data

@pytest.mark.asyncio
async def test_investment_authorization(test_db: AsyncSession):
    """
    Test investment endpoint authorization.
    
    Requirements addressed:
    - Security Testing (6.3.1): Validates API security and authorization
    """
    client = TestClient(router)
    
    # Test unauthorized access
    response = await client.get("/investments/")
    assert response.status_code == 401
    
    # Test invalid token
    response = await client.get(
        "/investments/",
        headers={"Authorization": "Bearer invalid_token"}
    )
    assert response.status_code == 401
    
    # Test expired token
    response = await client.get(
        "/investments/",
        headers={"Authorization": "Bearer expired_token"}
    )
    assert response.status_code == 401