"""
Test suite for goals API endpoints in Mint Replica Lite application.

Human Tasks:
1. Configure test database with sample goal data
2. Review test timeouts for async operations
3. Set up test coverage monitoring
4. Configure test reporting pipeline
5. Review test isolation requirements
"""

# pytest: ^7.0.0
# fastapi.testclient: ^0.68.0

import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from uuid import UUID, uuid4
from typing import Dict, Any
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

from tests.conftest import test_db, test_user
from app.api.v1.endpoints.goals import router
from app.schemas.goal import GoalCreate, GoalUpdate, GoalInDB, GoalResponse

class TestGoalsAPI:
    """
    Test class for goals API endpoints.
    
    Requirements addressed:
    - Goal Management (1.2): Validates goal CRUD operations and progress tracking
    - Testing Infrastructure (2.5.2): Implements comprehensive API testing
    """
    
    def setup_method(self):
        """Initialize test client and authentication for each test."""
        self.client = TestClient(router)
        self.headers = {
            "Authorization": f"Bearer test_token",
            "Content-Type": "application/json"
        }
        
        # Test goal data template
        self.test_goal_data = {
            "name": "Test Savings Goal",
            "description": "Test goal for API validation",
            "goal_type": "savings",
            "target_amount": Decimal("1000.00"),
            "target_date": (datetime.utcnow() + timedelta(days=90)).isoformat(),
            "account_id": str(uuid4())
        }

    def teardown_method(self):
        """Cleanup after each test."""
        self.client = None
        self.headers = None

    @pytest.mark.asyncio
    async def test_create_goal(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test creating a new financial goal.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal creation functionality
        """
        # Prepare test data
        goal_data = GoalCreate(**self.test_goal_data, user_id=UUID(test_user["sub"]))
        
        # Send create request
        response = self.client.post(
            "/",
            json=goal_data.dict(),
            headers=self.headers
        )
        
        # Validate response
        assert response.status_code == 201
        created_goal = GoalInDB(**response.json())
        assert created_goal.name == goal_data.name
        assert created_goal.target_amount == goal_data.target_amount
        assert created_goal.user_id == goal_data.user_id

    @pytest.mark.asyncio
    async def test_get_goal(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test retrieving a specific goal.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal retrieval with progress tracking
        """
        # Create test goal
        goal_data = GoalCreate(**self.test_goal_data, user_id=UUID(test_user["sub"]))
        create_response = self.client.post(
            "/",
            json=goal_data.dict(),
            headers=self.headers
        )
        goal_id = create_response.json()["id"]
        
        # Retrieve goal
        response = self.client.get(
            f"/{goal_id}",
            headers=self.headers
        )
        
        # Validate response
        assert response.status_code == 200
        goal = GoalResponse(**response.json())
        assert goal.id == UUID(goal_id)
        assert goal.progress_percentage >= 0
        assert goal.days_remaining > 0

    @pytest.mark.asyncio
    async def test_list_goals(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test listing all goals for a user.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal listing functionality
        """
        # Create multiple test goals
        for i in range(3):
            goal_data = self.test_goal_data.copy()
            goal_data["name"] = f"Test Goal {i}"
            goal = GoalCreate(**goal_data, user_id=UUID(test_user["sub"]))
            self.client.post("/", json=goal.dict(), headers=self.headers)
        
        # List goals
        response = self.client.get("/", headers=self.headers)
        
        # Validate response
        assert response.status_code == 200
        goals = [GoalResponse(**g) for g in response.json()]
        assert len(goals) == 3
        assert all(g.user_id == UUID(test_user["sub"]) for g in goals)

    @pytest.mark.asyncio
    async def test_update_goal(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test updating an existing goal.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal update functionality
        """
        # Create test goal
        goal_data = GoalCreate(**self.test_goal_data, user_id=UUID(test_user["sub"]))
        create_response = self.client.post(
            "/",
            json=goal_data.dict(),
            headers=self.headers
        )
        goal_id = create_response.json()["id"]
        
        # Update goal
        update_data = GoalUpdate(
            name="Updated Goal",
            target_amount=Decimal("2000.00")
        )
        response = self.client.put(
            f"/{goal_id}",
            json=update_data.dict(exclude_unset=True),
            headers=self.headers
        )
        
        # Validate response
        assert response.status_code == 200
        updated_goal = GoalInDB(**response.json())
        assert updated_goal.name == "Updated Goal"
        assert updated_goal.target_amount == Decimal("2000.00")

    @pytest.mark.asyncio
    async def test_delete_goal(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test deleting a goal.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal deletion functionality
        """
        # Create test goal
        goal_data = GoalCreate(**self.test_goal_data, user_id=UUID(test_user["sub"]))
        create_response = self.client.post(
            "/",
            json=goal_data.dict(),
            headers=self.headers
        )
        goal_id = create_response.json()["id"]
        
        # Delete goal
        response = self.client.delete(
            f"/{goal_id}",
            headers=self.headers
        )
        
        # Validate response
        assert response.status_code == 204
        
        # Verify goal is deleted
        get_response = self.client.get(
            f"/{goal_id}",
            headers=self.headers
        )
        assert get_response.status_code == 404

    @pytest.mark.asyncio
    async def test_update_goal_progress(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test updating goal progress amount.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal progress tracking
        """
        # Create test goal
        goal_data = GoalCreate(**self.test_goal_data, user_id=UUID(test_user["sub"]))
        create_response = self.client.post(
            "/",
            json=goal_data.dict(),
            headers=self.headers
        )
        goal_id = create_response.json()["id"]
        
        # Update progress
        progress_amount = Decimal("500.00")
        response = self.client.patch(
            f"/{goal_id}/progress",
            params={"amount": str(progress_amount)},
            headers=self.headers
        )
        
        # Validate response
        assert response.status_code == 200
        updated_goal = GoalResponse(**response.json())
        assert updated_goal.current_amount == progress_amount
        assert updated_goal.progress_percentage == 50.0

    @pytest.mark.asyncio
    async def test_goal_validation(self, test_db: AsyncSession, test_user: Dict[str, Any]):
        """
        Test goal data validation rules.
        
        Requirements addressed:
        - Goal Management (1.2): Validates goal data constraints
        - Testing Infrastructure (2.5.2): Validates error handling
        """
        # Test invalid target amount
        invalid_goal = self.test_goal_data.copy()
        invalid_goal["target_amount"] = "-100.00"
        response = self.client.post(
            "/",
            json=invalid_goal,
            headers=self.headers
        )
        assert response.status_code == 422
        
        # Test invalid target date
        invalid_goal = self.test_goal_data.copy()
        invalid_goal["target_date"] = (datetime.utcnow() - timedelta(days=1)).isoformat()
        response = self.client.post(
            "/",
            json=invalid_goal,
            headers=self.headers
        )
        assert response.status_code == 422
        
        # Test missing required fields
        invalid_goal = {"name": "Test Goal"}
        response = self.client.post(
            "/",
            json=invalid_goal,
            headers=self.headers
        )
        assert response.status_code == 422