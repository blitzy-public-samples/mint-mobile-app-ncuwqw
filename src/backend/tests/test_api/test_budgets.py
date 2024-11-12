# Library versions:
# pytest: ^6.2.5
# fastapi.testclient: ^0.68.0
# freezegun: ^1.1.0

import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from typing import List
from fastapi.testclient import TestClient
from freezegun import freeze_time

from app.schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse
from app.models.budget import Budget
from app.models.category import Category

# Human Tasks:
# 1. Configure test database with appropriate permissions
# 2. Set up test environment variables for authentication
# 3. Review test coverage requirements with QA team
# 4. Verify test data matches production constraints

@pytest.mark.asyncio
class TestBudgetAPI:
    """
    Test suite for Budget API endpoints.
    
    Requirements addressed:
    - Budget Management Testing (1.2 Scope/Budget Management)
    - Security Controls Testing (6.3.3 Security Controls)
    """
    
    def setup_method(self, method):
        """Initialize test environment before each test."""
        # Clear test database
        self.db_session.query(Budget).delete()
        self.db_session.query(Category).delete()
        
        # Create test category
        self.test_category = Category(
            name="Test Category",
            description="Test category for budget tests"
        )
        self.db_session.add(self.test_category)
        self.db_session.commit()
        
        # Set up test data
        self.valid_budget_data = {
            "name": "Test Budget",
            "amount": 1000.00,
            "period": "monthly",
            "category_id": self.test_category.id,
            "alert_threshold": 80,
            "alert_enabled": True,
            "start_date": datetime.utcnow() + timedelta(days=1),
            "end_date": datetime.utcnow() + timedelta(days=31)
        }

    def teardown_method(self, method):
        """Cleanup test environment after each test."""
        self.db_session.query(Budget).delete()
        self.db_session.query(Category).delete()
        self.db_session.commit()

    @pytest.mark.asyncio
    async def test_create_budget(self, client: TestClient, db_session, test_user):
        """
        Test budget creation endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Validates budget creation with proper schema
        - Security Controls Testing (6.3.3 Security Controls):
          Tests input validation and user authorization
        """
        # Create budget request data
        budget_create = BudgetCreate(**self.valid_budget_data)
        
        # Validate dates
        assert budget_create.validate_dates() is True
        
        # Send create request
        response = client.post(
            "/api/v1/budgets/",
            json=self.valid_budget_data,
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 201
        data = response.json()
        
        # Validate response schema
        budget_response = BudgetResponse(**data)
        assert budget_response.name == self.valid_budget_data["name"]
        assert float(budget_response.amount) == self.valid_budget_data["amount"]
        
        # Verify database entry
        db_budget = db_session.query(Budget).filter(Budget.id == data["id"]).first()
        assert db_budget is not None
        assert db_budget.category_id == self.test_category.id

    @pytest.mark.asyncio
    async def test_get_budget(self, client: TestClient, db_session, test_user, test_budget):
        """
        Test budget retrieval endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies budget retrieval with progress calculation
        """
        response = client.get(
            f"/api/v1/budgets/{test_budget.id}",
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Validate response schema
        budget_response = BudgetResponse(**data)
        
        # Verify progress calculation
        progress = test_budget.calculate_progress()
        assert budget_response.progress == progress
        
        # Verify budget data
        budget_dict = test_budget.to_dict()
        assert budget_response.id == budget_dict["id"]
        assert budget_response.name == budget_dict["name"]

    @pytest.mark.asyncio
    async def test_list_budgets(self, client: TestClient, db_session, test_user, test_budgets: List[Budget]):
        """
        Test budget listing endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Tests budget listing with filters and pagination
        """
        response = client.get(
            "/api/v1/budgets/",
            params={
                "category_id": self.test_category.id,
                "period": "monthly",
                "page": 1,
                "per_page": 10
            },
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Validate pagination
        assert "items" in data
        assert "total" in data
        assert "page" in data
        
        # Validate response items
        for item in data["items"]:
            budget_response = BudgetResponse(**item)
            assert budget_response.category.id == self.test_category.id
            assert budget_response.period == "monthly"

    @pytest.mark.asyncio
    async def test_update_budget(self, client: TestClient, db_session, test_user, test_budget):
        """
        Test budget update endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Validates budget update functionality
        - Security Controls Testing (6.3.3 Security Controls):
          Tests update authorization and validation
        """
        update_data = {
            "name": "Updated Budget",
            "amount": 1500.00,
            "alert_threshold": 90
        }
        
        response = client.put(
            f"/api/v1/budgets/{test_budget.id}",
            json=update_data,
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Validate response schema
        budget_response = BudgetResponse(**data)
        assert budget_response.name == update_data["name"]
        assert float(budget_response.amount) == update_data["amount"]
        
        # Verify database update
        db_budget = db_session.query(Budget).filter(Budget.id == test_budget.id).first()
        assert db_budget.name == update_data["name"]
        assert float(db_budget.amount) == update_data["amount"]

    @pytest.mark.asyncio
    async def test_delete_budget(self, client: TestClient, db_session, test_user, test_budget):
        """
        Test budget deletion endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies soft deletion functionality
        - Security Controls Testing (6.3.3 Security Controls):
          Tests deletion authorization
        """
        response = client.delete(
            f"/api/v1/budgets/{test_budget.id}",
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 204
        
        # Verify soft deletion
        db_budget = db_session.query(Budget).filter(Budget.id == test_budget.id).first()
        assert db_budget is not None
        assert db_budget.is_active is False
        
        # Verify relationships maintained
        assert db_budget.category_id == test_budget.category_id

    @pytest.mark.asyncio
    async def test_check_budget_alerts(self, client: TestClient, db_session, test_user, test_budgets_with_alerts: List[Budget]):
        """
        Test budget alerts endpoint.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Tests alert threshold monitoring
        """
        response = client.get(
            "/api/v1/budgets/alerts",
            headers={"Authorization": f"Bearer {test_user['access_token']}"}
        )
        
        assert response.status_code == 200
        data = response.json()
        
        # Validate alert response
        assert "alerts" in data
        for alert in data["alerts"]:
            budget = next(b for b in test_budgets_with_alerts if b.id == alert["budget_id"])
            assert budget.check_alert_threshold() is True
            
            progress = budget.calculate_progress()
            assert alert["progress"] == progress
            assert alert["threshold"] == budget.alert_threshold