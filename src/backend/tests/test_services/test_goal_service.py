"""
Test suite for the GoalService class validating goal management functionality.

Human Tasks:
1. Review test coverage reports and ensure adequate coverage
2. Configure test data cleanup procedures
3. Set up monitoring for test execution times
4. Review test isolation requirements
"""

# pytest: ^7.0.0
import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4

from app.services.goal_service import GoalService
from app.schemas.goal import GoalCreate, GoalUpdate, GoalInDB, GoalResponse
from app.core.errors import DatabaseError
from tests.conftest import get_test_db, test_user

@pytest.fixture
def goal_service(test_db):
    """
    Fixture providing configured GoalService instance.
    
    Requirements addressed:
    - Testing Infrastructure (2.5): Provides isolated test service instance
    """
    return GoalService(test_db)

def test_create_goal(goal_service, test_user):
    """
    Test goal creation functionality.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal creation with proper data
    - Testing Infrastructure (2.5): Comprehensive test coverage for goal creation
    """
    # Test data
    target_date = datetime.utcnow() + timedelta(days=30)
    goal_data = GoalCreate(
        user_id=UUID(test_user["sub"]),
        name="Emergency Fund",
        description="Build emergency savings",
        goal_type="SAVINGS",
        target_amount=Decimal("5000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    
    # Create goal
    created_goal = goal_service.create_goal(goal_data)
    
    # Verify created goal
    assert isinstance(created_goal, GoalInDB)
    assert created_goal.user_id == UUID(test_user["sub"])
    assert created_goal.name == goal_data.name
    assert created_goal.target_amount == goal_data.target_amount
    assert created_goal.current_amount == Decimal("0")
    assert not created_goal.is_completed
    assert created_goal.completed_at is None
    
    # Test validation errors
    with pytest.raises(ValueError):
        invalid_data = GoalCreate(
            user_id=UUID(test_user["sub"]),
            name="Invalid Goal",
            description="Test",
            goal_type="SAVINGS",
            target_amount=Decimal("-100.00"),  # Invalid negative amount
            target_date=target_date,
            account_id=uuid4()
        )
        goal_service.create_goal(invalid_data)

def test_get_goal(goal_service, test_user):
    """
    Test goal retrieval functionality.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal retrieval and progress calculation
    - Testing Infrastructure (2.5): Comprehensive test coverage for goal retrieval
    """
    # Create test goal
    target_date = datetime.utcnow() + timedelta(days=30)
    goal_data = GoalCreate(
        user_id=UUID(test_user["sub"]),
        name="Vacation Fund",
        description="Save for summer vacation",
        goal_type="SAVINGS",
        target_amount=Decimal("2000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    created_goal = goal_service.create_goal(goal_data)
    
    # Retrieve goal
    retrieved_goal = goal_service.get_goal(created_goal.id, UUID(test_user["sub"]))
    
    # Verify retrieved goal
    assert isinstance(retrieved_goal, GoalResponse)
    assert retrieved_goal.id == created_goal.id
    assert retrieved_goal.progress_percentage == 0.0
    assert 0 <= retrieved_goal.days_remaining <= 30
    
    # Test non-existent goal
    assert goal_service.get_goal(uuid4(), UUID(test_user["sub"])) is None
    
    # Test wrong user_id
    assert goal_service.get_goal(created_goal.id, uuid4()) is None

def test_list_goals(goal_service, test_user):
    """
    Test listing of user goals.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal listing functionality
    - Testing Infrastructure (2.5): Comprehensive test coverage for goal listing
    """
    # Create multiple test goals
    target_date = datetime.utcnow() + timedelta(days=30)
    goals_data = [
        GoalCreate(
            user_id=UUID(test_user["sub"]),
            name=f"Goal {i}",
            description=f"Test goal {i}",
            goal_type="SAVINGS",
            target_amount=Decimal(f"{1000 * (i+1)}.00"),
            target_date=target_date,
            account_id=uuid4()
        ) for i in range(3)
    ]
    
    for goal_data in goals_data:
        goal_service.create_goal(goal_data)
    
    # Create goal for different user
    other_goal = GoalCreate(
        user_id=uuid4(),
        name="Other User Goal",
        description="Should not be listed",
        goal_type="SAVINGS",
        target_amount=Decimal("1000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    goal_service.create_goal(other_goal)
    
    # List goals
    user_goals = goal_service.list_goals(UUID(test_user["sub"]))
    
    # Verify goals list
    assert len(user_goals) == 3
    assert all(isinstance(goal, GoalResponse) for goal in user_goals)
    assert all(goal.user_id == UUID(test_user["sub"]) for goal in user_goals)
    
    # Verify empty list for non-existent user
    assert len(goal_service.list_goals(uuid4())) == 0

def test_update_goal(goal_service, test_user):
    """
    Test goal update functionality.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal update operations
    - Testing Infrastructure (2.5): Comprehensive test coverage for goal updates
    """
    # Create test goal
    target_date = datetime.utcnow() + timedelta(days=30)
    goal_data = GoalCreate(
        user_id=UUID(test_user["sub"]),
        name="Original Goal",
        description="Original description",
        goal_type="SAVINGS",
        target_amount=Decimal("1000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    created_goal = goal_service.create_goal(goal_data)
    
    # Update goal
    new_target_date = datetime.utcnow() + timedelta(days=60)
    update_data = GoalUpdate(
        name="Updated Goal",
        description="Updated description",
        target_amount=Decimal("2000.00"),
        target_date=new_target_date
    )
    
    updated_goal = goal_service.update_goal(created_goal.id, UUID(test_user["sub"]), update_data)
    
    # Verify updates
    assert updated_goal.name == "Updated Goal"
    assert updated_goal.description == "Updated description"
    assert updated_goal.target_amount == Decimal("2000.00")
    assert updated_goal.target_date == new_target_date
    
    # Test partial update
    partial_update = GoalUpdate(name="Partially Updated")
    partial_result = goal_service.update_goal(created_goal.id, UUID(test_user["sub"]), partial_update)
    assert partial_result.name == "Partially Updated"
    assert partial_result.target_amount == Decimal("2000.00")  # Unchanged
    
    # Test non-existent goal
    assert goal_service.update_goal(uuid4(), UUID(test_user["sub"]), update_data) is None
    
    # Test wrong user_id
    assert goal_service.update_goal(created_goal.id, uuid4(), update_data) is None

def test_delete_goal(goal_service, test_user):
    """
    Test goal deletion functionality.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal deletion operations
    - Testing Infrastructure (2.5): Comprehensive test coverage for goal deletion
    """
    # Create test goal
    target_date = datetime.utcnow() + timedelta(days=30)
    goal_data = GoalCreate(
        user_id=UUID(test_user["sub"]),
        name="Goal to Delete",
        description="Will be deleted",
        goal_type="SAVINGS",
        target_amount=Decimal("1000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    created_goal = goal_service.create_goal(goal_data)
    
    # Delete goal
    assert goal_service.delete_goal(created_goal.id, UUID(test_user["sub"])) is True
    
    # Verify deletion
    assert goal_service.get_goal(created_goal.id, UUID(test_user["sub"])) is None
    
    # Test deleting non-existent goal
    assert goal_service.delete_goal(uuid4(), UUID(test_user["sub"])) is False
    
    # Test deleting with wrong user_id
    assert goal_service.delete_goal(created_goal.id, uuid4()) is False

def test_update_goal_progress(goal_service, test_user):
    """
    Test goal progress update functionality.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal progress tracking
    - Testing Infrastructure (2.5): Comprehensive test coverage for progress updates
    """
    # Create test goal
    target_date = datetime.utcnow() + timedelta(days=30)
    goal_data = GoalCreate(
        user_id=UUID(test_user["sub"]),
        name="Progress Test Goal",
        description="Testing progress updates",
        goal_type="SAVINGS",
        target_amount=Decimal("1000.00"),
        target_date=target_date,
        account_id=uuid4()
    )
    created_goal = goal_service.create_goal(goal_data)
    
    # Update progress
    updated_goal = goal_service.update_goal_progress(
        created_goal.id,
        UUID(test_user["sub"]),
        Decimal("500.00")
    )
    
    # Verify progress update
    assert updated_goal.current_amount == Decimal("500.00")
    assert updated_goal.progress_percentage == 50.0
    assert not updated_goal.is_completed
    
    # Test goal completion
    completed_goal = goal_service.update_goal_progress(
        created_goal.id,
        UUID(test_user["sub"]),
        Decimal("1000.00")
    )
    
    assert completed_goal.is_completed
    assert completed_goal.completed_at is not None
    assert completed_goal.progress_percentage == 100.0
    
    # Test non-existent goal
    assert goal_service.update_goal_progress(uuid4(), UUID(test_user["sub"]), Decimal("100.00")) is None
    
    # Test wrong user_id
    assert goal_service.update_goal_progress(created_goal.id, uuid4(), Decimal("100.00")) is None

def test_goal_validation(goal_service, test_user):
    """
    Test goal data validation.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal data constraints
    - Testing Infrastructure (2.5): Comprehensive test coverage for data validation
    """
    # Test negative target amount
    with pytest.raises(ValueError):
        GoalCreate(
            user_id=UUID(test_user["sub"]),
            name="Invalid Goal",
            description="Test",
            goal_type="SAVINGS",
            target_amount=Decimal("-100.00"),
            target_date=datetime.utcnow() + timedelta(days=30),
            account_id=uuid4()
        )
    
    # Test past target date
    with pytest.raises(ValueError):
        GoalCreate(
            user_id=UUID(test_user["sub"]),
            name="Invalid Goal",
            description="Test",
            goal_type="SAVINGS",
            target_amount=Decimal("100.00"),
            target_date=datetime.utcnow() - timedelta(days=1),
            account_id=uuid4()
        )
    
    # Test zero target amount
    with pytest.raises(ValueError):
        GoalCreate(
            user_id=UUID(test_user["sub"]),
            name="Invalid Goal",
            description="Test",
            goal_type="SAVINGS",
            target_amount=Decimal("0.00"),
            target_date=datetime.utcnow() + timedelta(days=30),
            account_id=uuid4()
        )