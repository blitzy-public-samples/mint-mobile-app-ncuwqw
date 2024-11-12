# Library versions:
# pytest: ^7.0.0
# pytest-mock: ^3.6.1
# freezegun: ^1.2.0

import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID
from freezegun import freeze_time

from app.services.budget_service import BudgetService
from app.models.budget import Budget
from app.schemas.budget import BudgetCreate, BudgetUpdate, BudgetResponse
from app.core.errors import NotFoundError, ValidationError

# Human Tasks:
# 1. Configure test database with appropriate test data
# 2. Set up test environment variables for database connections
# 3. Review and adjust test coverage thresholds
# 4. Configure CI/CD pipeline for automated test execution

class TestBudgetService:
    """
    Test suite for BudgetService class functionality.
    
    Requirements addressed:
    - Budget Management Testing (1.2 Scope/Budget Management):
      Tests category-based budgeting, progress monitoring, and alerts
    - Data Validation Testing (6.3.3 Security Controls/Input Validation):
      Tests server-side validation for budget operations
    """

    def setup_method(self, method):
        """Setup method run before each test."""
        self.db_session = pytest.fixture(scope='function')
        self.user_id = UUID('12345678-1234-5678-1234-567812345678')
        self.category_id = 1
        self.service = BudgetService(self.db_session)
        
        # Setup test data
        self.valid_budget_data = BudgetCreate(
            name="Test Budget",
            amount=Decimal("1000.00"),
            period="monthly",
            category_id=self.category_id,
            start_date=datetime.utcnow(),
            alert_threshold=80,
            alert_enabled=True,
            rules={"exclude_categories": [2, 3]}
        )

    def teardown_method(self, method):
        """Cleanup method run after each test."""
        self.db_session.rollback()
        self.db_session.close()

    @freeze_time("2024-01-01 12:00:00")
    def test_create_budget_success(self, db_session, mock_user):
        """
        Tests successful budget creation with valid data.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies successful budget creation with alerts
        """
        # Arrange
        budget_data = self.valid_budget_data

        # Act
        result = self.service.create_budget(self.user_id, budget_data)

        # Assert
        assert isinstance(result, BudgetResponse)
        assert result.name == budget_data.name
        assert result.amount == float(budget_data.amount)
        assert result.period == budget_data.period
        assert result.alert_threshold == budget_data.alert_threshold
        assert result.progress is not None
        assert result.progress['percentage'] == 0.0

    def test_create_budget_invalid_category(self, db_session, mock_user):
        """
        Tests budget creation with invalid category ID.
        
        Requirements addressed:
        - Data Validation Testing (6.3.3 Security Controls/Input Validation):
          Verifies validation of category references
        """
        # Arrange
        invalid_budget_data = self.valid_budget_data.copy()
        invalid_budget_data.category_id = 999  # Non-existent category

        # Act & Assert
        with pytest.raises(ValidationError) as exc_info:
            self.service.create_budget(self.user_id, invalid_budget_data)
        assert "Category 999 not found or inactive" in str(exc_info.value)

    @freeze_time("2024-01-01 12:00:00")
    def test_update_budget_success(self, db_session, mock_budget):
        """
        Tests successful budget update with valid data.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies budget update functionality
        """
        # Arrange
        budget_id = 1
        update_data = BudgetUpdate(
            name="Updated Budget",
            amount=Decimal("1500.00"),
            alert_threshold=90
        )

        # Act
        result = self.service.update_budget(budget_id, self.user_id, update_data)

        # Assert
        assert isinstance(result, BudgetResponse)
        assert result.name == update_data.name
        assert result.amount == float(update_data.amount)
        assert result.alert_threshold == update_data.alert_threshold
        assert result.progress is not None

    def test_get_budget_not_found(self, db_session):
        """
        Tests retrieval of non-existent budget.
        
        Requirements addressed:
        - Data Validation Testing (6.3.3 Security Controls/Input Validation):
          Verifies proper error handling for invalid budget IDs
        """
        # Arrange
        non_existent_id = 999

        # Act & Assert
        with pytest.raises(NotFoundError) as exc_info:
            self.service.get_budget(non_existent_id, self.user_id)
        assert f"Budget {non_existent_id} not found" in str(exc_info.value)

    def test_list_budgets_with_filters(self, db_session, mock_budgets):
        """
        Tests budget listing with various filters.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies filtered budget retrieval functionality
        """
        # Arrange
        filters = {
            "category_id": self.category_id,
            "period": "monthly",
            "alert_enabled": True
        }

        # Act
        results = self.service.list_budgets(self.user_id, filters)

        # Assert
        assert isinstance(results, list)
        assert all(isinstance(budget, BudgetResponse) for budget in results)
        assert all(budget.category_id == self.category_id for budget in results)
        assert all(budget.period == "monthly" for budget in results)
        assert all(budget.alert_enabled for budget in results)

    def test_delete_budget_success(self, db_session, mock_budget):
        """
        Tests successful budget deletion.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies soft deletion functionality
        """
        # Arrange
        budget_id = 1

        # Act
        result = self.service.delete_budget(budget_id, self.user_id)

        # Assert
        assert result is True
        deleted_budget = db_session.query(Budget).filter_by(id=budget_id).first()
        assert deleted_budget is not None
        assert deleted_budget.is_active is False

    @freeze_time("2024-01-01 12:00:00")
    def test_check_budget_alerts(self, db_session, mock_budgets_with_alerts):
        """
        Tests budget alert threshold checking.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Verifies alert threshold monitoring functionality
        """
        # Arrange
        # mock_budgets_with_alerts fixture sets up budgets with different progress levels

        # Act
        alerts = self.service.check_budget_alerts(self.user_id)

        # Assert
        assert isinstance(alerts, list)
        for alert in alerts:
            assert alert['progress']['percentage'] >= alert['alert_threshold']
            assert alert['alert_enabled'] is True