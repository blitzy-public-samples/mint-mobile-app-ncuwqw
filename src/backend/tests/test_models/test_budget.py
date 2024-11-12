# pytest: ^7.0.0
# freezegun: ^1.2.0

import pytest
from decimal import Decimal
from datetime import datetime, timedelta
from freezegun import freeze_time

from app.models.budget import Budget
from tests.conftest import get_test_db, test_user

# Human Tasks:
# 1. Verify test database has appropriate permissions for transaction testing
# 2. Ensure test environment has correct timezone configuration
# 3. Review decimal precision settings in test database

@pytest.mark.asyncio
class TestBudget:
    """
    Test suite for Budget model validating core functionality and relationships.
    
    Requirements addressed:
    - Budget Management Testing (1.2 Scope/Budget Management)
    - Data Model Testing (5.2 Database Design/5.2.1 Schema Design)
    """
    
    async def setup_method(self, method):
        """Setup test environment before each test method."""
        # Initialize test data
        self.test_category_data = {
            "name": "Test Category",
            "type": "expense",
            "description": "Test category for budget testing"
        }
        
        self.test_budget_data = {
            "name": "Monthly Groceries",
            "amount": Decimal("500.00"),
            "period": "monthly",
            "start_date": datetime.now(),
            "alert_threshold": 80,
            "alert_enabled": True
        }

    @pytest.mark.asyncio
    async def test_create_budget(self, test_db, test_user):
        """
        Test budget creation with valid attributes and relationship validation.
        
        Requirements addressed:
        - Data Model Testing (5.2 Database Design/5.2.1 Schema Design):
          Validates budget model relationships and constraints
        """
        # Create test category
        category = Category(**self.test_category_data)
        test_db.add(category)
        await test_db.flush()
        
        # Create budget with test data
        budget_data = {
            **self.test_budget_data,
            "user_id": test_user["id"],
            "category_id": category.id
        }
        budget = Budget(**budget_data)
        test_db.add(budget)
        await test_db.flush()
        
        # Verify budget attributes
        assert budget.id is not None
        assert budget.name == budget_data["name"]
        assert budget.amount == budget_data["amount"]
        assert budget.period == budget_data["period"]
        assert budget.alert_threshold == budget_data["alert_threshold"]
        assert budget.alert_enabled == budget_data["alert_enabled"]
        
        # Verify relationships
        assert budget.user_id == test_user["id"]
        assert budget.category_id == category.id
        assert budget.category.name == self.test_category_data["name"]

    @pytest.mark.asyncio
    @freeze_time("2024-01-15")
    async def test_budget_progress_calculation(self, test_db, test_user):
        """
        Test budget progress calculation with various transaction scenarios.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Validates progress monitoring and calculations
        """
        # Create test budget and category
        category = Category(**self.test_category_data)
        test_db.add(category)
        await test_db.flush()
        
        budget = Budget(
            **self.test_budget_data,
            user_id=test_user["id"],
            category_id=category.id
        )
        test_db.add(budget)
        await test_db.flush()
        
        # Create test transactions
        transactions = [
            Transaction(
                amount=Decimal("100.00"),
                type="expense",
                date=datetime.now(),
                category_id=category.id,
                user_id=test_user["id"]
            ),
            Transaction(
                amount=Decimal("150.00"),
                type="expense",
                date=datetime.now() - timedelta(days=1),
                category_id=category.id,
                user_id=test_user["id"]
            )
        ]
        for transaction in transactions:
            test_db.add(transaction)
        await test_db.flush()
        
        # Calculate and verify progress
        progress = budget.calculate_progress()
        expected_spent = Decimal("250.00")
        expected_remaining = Decimal("250.00")
        expected_percentage = 50.0
        
        assert progress["spent_amount"] == expected_spent
        assert progress["remaining_amount"] == expected_remaining
        assert progress["percentage"] == expected_percentage

    @pytest.mark.asyncio
    async def test_budget_alert_threshold(self, test_db, test_user):
        """
        Test budget alert threshold functionality with different spending levels.
        
        Requirements addressed:
        - Budget Management Testing (1.2 Scope/Budget Management):
          Validates alert threshold calculations and triggers
        """
        # Create test budget with 80% threshold
        category = Category(**self.test_category_data)
        test_db.add(category)
        await test_db.flush()
        
        budget = Budget(
            **self.test_budget_data,
            user_id=test_user["id"],
            category_id=category.id,
            alert_threshold=80
        )
        test_db.add(budget)
        await test_db.flush()
        
        # Test below threshold (70% spent)
        transaction = Transaction(
            amount=Decimal("350.00"),
            type="expense",
            date=datetime.now(),
            category_id=category.id,
            user_id=test_user["id"]
        )
        test_db.add(transaction)
        await test_db.flush()
        
        assert not budget.check_alert_threshold()
        
        # Test above threshold (90% spent)
        transaction = Transaction(
            amount=Decimal("100.00"),
            type="expense",
            date=datetime.now(),
            category_id=category.id,
            user_id=test_user["id"]
        )
        test_db.add(transaction)
        await test_db.flush()
        
        assert budget.check_alert_threshold()
        
        # Test with alerts disabled
        budget.alert_enabled = False
        await test_db.flush()
        assert not budget.check_alert_threshold()

    @pytest.mark.asyncio
    async def test_budget_to_dict(self, test_db, test_user):
        """
        Test budget serialization to dictionary format.
        
        Requirements addressed:
        - Data Model Testing (5.2 Database Design/5.2.1 Schema Design):
          Validates model serialization and data representation
        """
        # Create test budget with relationships
        category = Category(**self.test_category_data)
        test_db.add(category)
        await test_db.flush()
        
        budget = Budget(
            **self.test_budget_data,
            user_id=test_user["id"],
            category_id=category.id
        )
        test_db.add(budget)
        await test_db.flush()
        
        # Create test transaction
        transaction = Transaction(
            amount=Decimal("200.00"),
            type="expense",
            date=datetime.now(),
            category_id=category.id,
            user_id=test_user["id"]
        )
        test_db.add(transaction)
        await test_db.flush()
        
        # Get dictionary representation
        budget_dict = budget.to_dict()
        
        # Verify all attributes are present
        assert budget_dict["id"] == budget.id
        assert budget_dict["user_id"] == test_user["id"]
        assert budget_dict["category_id"] == category.id
        assert budget_dict["category_name"] == category.name
        assert budget_dict["category_type"] == category.type
        assert budget_dict["name"] == budget.name
        assert budget_dict["amount"] == float(budget.amount)
        assert budget_dict["period"] == budget.period
        assert budget_dict["alert_threshold"] == budget.alert_threshold
        assert budget_dict["alert_enabled"] == budget.alert_enabled
        
        # Verify progress metrics
        assert "progress" in budget_dict
        assert budget_dict["progress"]["spent_amount"] == Decimal("200.00")
        assert budget_dict["progress"]["remaining_amount"] == Decimal("300.00")
        assert budget_dict["progress"]["percentage"] == 40.0
        
        # Verify alert status
        assert "alert_triggered" in budget_dict
        assert not budget_dict["alert_triggered"]  # Should be False at 40% spent