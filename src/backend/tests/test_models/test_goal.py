"""
Test suite for the Goal model implementing comprehensive test cases for financial goal management.

Human Tasks:
1. Verify test database has goals table created with correct schema
2. Ensure test database user has permissions to create/modify goals
3. Configure test environment variables for database connection
4. Review test timeout settings if needed for async operations
"""

# pytest: ^7.0.0
import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID

from app.models.goal import Goal
from tests.conftest import get_test_db, test_user

class TestGoal:
    """
    Test class containing all goal model test cases.
    
    Requirements addressed:
    - Goal Management Testing (1.2): Verify financial goal setting and progress tracking
    - Data Model Testing (5.2.1): Validate goal model schema and data integrity
    """

    def setup_method(self, method):
        """Setup method run before each test."""
        self.test_goal_data = {
            'name': 'Test Savings Goal',
            'description': 'Test goal for unit tests',
            'goal_type': 'savings',
            'target_amount': Decimal('1000.00'),
            'target_date': datetime.utcnow() + timedelta(days=30)
        }

    @pytest.mark.asyncio
    async def test_create_goal(self, test_db, test_user):
        """
        Test goal creation with valid parameters.
        
        Requirements addressed:
        - Goal Management Testing (1.2): Verify goal creation functionality
        - Data Model Testing (5.2.1): Validate goal model initialization
        """
        # Create new goal instance
        goal = Goal(
            user_id=UUID(test_user['sub']),
            account_id=UUID('12345678-1234-5678-1234-567812345678'),
            **self.test_goal_data
        )

        # Verify goal attributes
        assert isinstance(goal.id, UUID)
        assert goal.user_id == UUID(test_user['sub'])
        assert goal.name == self.test_goal_data['name']
        assert goal.description == self.test_goal_data['description']
        assert goal.goal_type == self.test_goal_data['goal_type']
        assert goal.target_amount == self.test_goal_data['target_amount']
        assert goal.target_date == self.test_goal_data['target_date']
        
        # Verify initial state
        assert goal.current_amount == Decimal('0')
        assert not goal.is_completed
        assert goal.completed_at is None
        assert isinstance(goal.created_at, datetime)
        assert isinstance(goal.updated_at, datetime)

    @pytest.mark.asyncio
    async def test_update_goal_progress(self, test_db, test_user):
        """
        Test goal progress updates and completion status.
        
        Requirements addressed:
        - Goal Management Testing (1.2): Verify progress tracking functionality
        """
        # Create goal with initial progress
        goal = Goal(
            user_id=UUID(test_user['sub']),
            account_id=UUID('12345678-1234-5678-1234-567812345678'),
            **self.test_goal_data
        )
        
        # Test partial progress update
        initial_updated_at = goal.updated_at
        goal.update_progress(Decimal('500.00'))
        assert goal.current_amount == Decimal('500.00')
        assert goal.calculate_progress_percentage() == 50.0
        assert not goal.is_completed
        assert goal.completed_at is None
        assert goal.updated_at > initial_updated_at

        # Test goal completion
        goal.update_progress(Decimal('1000.00'))
        assert goal.current_amount == Decimal('1000.00')
        assert goal.calculate_progress_percentage() == 100.0
        assert goal.is_completed
        assert isinstance(goal.completed_at, datetime)

    @pytest.mark.asyncio
    async def test_goal_progress_percentage(self, test_db, test_user):
        """
        Test goal progress percentage calculation.
        
        Requirements addressed:
        - Goal Management Testing (1.2): Verify progress calculation accuracy
        """
        goal = Goal(
            user_id=UUID(test_user['sub']),
            account_id=UUID('12345678-1234-5678-1234-567812345678'),
            **self.test_goal_data
        )

        # Test various progress scenarios
        assert goal.calculate_progress_percentage() == 0.0
        
        goal.update_progress(Decimal('250.00'))
        assert goal.calculate_progress_percentage() == 25.0
        
        goal.update_progress(Decimal('750.00'))
        assert goal.calculate_progress_percentage() == 75.0
        
        # Test progress capped at 100%
        goal.update_progress(Decimal('1200.00'))
        assert goal.calculate_progress_percentage() == 100.0

    @pytest.mark.asyncio
    async def test_goal_to_dict(self, test_db, test_user):
        """
        Test goal model serialization to dictionary.
        
        Requirements addressed:
        - Data Model Testing (5.2.1): Validate model serialization
        """
        goal = Goal(
            user_id=UUID(test_user['sub']),
            account_id=UUID('12345678-1234-5678-1234-567812345678'),
            **self.test_goal_data
        )
        
        # Update progress to test all fields
        goal.update_progress(Decimal('750.00'))
        goal_dict = goal.to_dict()

        # Verify dictionary representation
        assert isinstance(goal_dict['id'], str)
        assert isinstance(goal_dict['user_id'], str)
        assert isinstance(goal_dict['account_id'], str)
        assert goal_dict['name'] == self.test_goal_data['name']
        assert goal_dict['description'] == self.test_goal_data['description']
        assert goal_dict['goal_type'] == self.test_goal_data['goal_type']
        assert Decimal(goal_dict['target_amount']) == self.test_goal_data['target_amount']
        assert Decimal(goal_dict['current_amount']) == Decimal('750.00')
        assert goal_dict['progress_percentage'] == 75.0
        assert isinstance(goal_dict['target_date'], str)
        assert isinstance(goal_dict['created_at'], str)
        assert isinstance(goal_dict['updated_at'], str)

    @pytest.mark.asyncio
    async def test_goal_validation(self, test_db, test_user):
        """
        Test goal validation rules and constraints.
        
        Requirements addressed:
        - Data Model Testing (5.2.1): Validate data integrity constraints
        """
        # Test negative target amount
        with pytest.raises(ValueError, match="Target amount must be positive"):
            Goal(
                user_id=UUID(test_user['sub']),
                account_id=UUID('12345678-1234-5678-1234-567812345678'),
                **{
                    **self.test_goal_data,
                    'target_amount': Decimal('-100.00')
                }
            )

        # Test past target date
        with pytest.raises(ValueError, match="Target date cannot be in the past"):
            Goal(
                user_id=UUID(test_user['sub']),
                account_id=UUID('12345678-1234-5678-1234-567812345678'),
                **{
                    **self.test_goal_data,
                    'target_date': datetime.utcnow() - timedelta(days=1)
                }
            )

        # Test negative progress update
        goal = Goal(
            user_id=UUID(test_user['sub']),
            account_id=UUID('12345678-1234-5678-1234-567812345678'),
            **self.test_goal_data
        )
        with pytest.raises(ValueError, match="Amount cannot be negative"):
            goal.update_progress(Decimal('-50.00'))