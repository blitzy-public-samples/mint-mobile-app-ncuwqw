"""
Service layer for managing financial goals in the Mint Replica Lite application.

Human Tasks:
1. Configure monitoring for goal progress updates
2. Set up alerts for goal achievement milestones
3. Review database indices for goal queries optimization
4. Configure backup strategy for goal data
5. Set up logging for goal service operations
"""

# uuid: ^3.9+
from uuid import UUID
# datetime: ^3.9+
from datetime import datetime
# decimal: ^3.9+
from decimal import Decimal
# typing: ^3.9+
from typing import Optional, List

from app.models.goal import Goal
from app.schemas.goal import GoalCreate, GoalUpdate, GoalInDB, GoalResponse
from app.db.session import get_db
from app.core.errors import DatabaseError

class GoalService:
    """
    Service class for managing financial goals with database operations and business logic.
    
    Requirements addressed:
    - Goal Management (1.2): Implements financial goal setting, progress tracking, and achievement monitoring
    - Data Flow Architecture (2.3): Implements goal service for processing goal-related business logic
    """

    def __init__(self, db_session):
        """Initialize goal service with database session."""
        self._db = db_session

    def create_goal(self, goal_data: GoalCreate) -> GoalInDB:
        """
        Create a new financial goal.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal creation functionality
        
        Args:
            goal_data: Validated goal creation data
            
        Returns:
            Created goal data
            
        Raises:
            DatabaseError: If goal creation fails
        """
        try:
            # Create new Goal model instance
            goal = Goal(
                user_id=goal_data.user_id,
                account_id=goal_data.account_id,
                name=goal_data.name,
                description=goal_data.description,
                goal_type=goal_data.goal_type,
                target_amount=goal_data.target_amount,
                target_date=goal_data.target_date
            )
            
            # Add to database and commit
            self._db.add(goal)
            self._db.commit()
            self._db.refresh(goal)
            
            # Convert to schema and return
            return GoalInDB.from_orm(goal)
            
        except Exception as e:
            self._db.rollback()
            raise DatabaseError(f"Failed to create goal: {str(e)}")

    def get_goal(self, goal_id: UUID, user_id: UUID) -> Optional[GoalResponse]:
        """
        Retrieve a goal by ID and user ID.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal retrieval with progress metrics
        
        Args:
            goal_id: UUID of the goal
            user_id: UUID of the goal owner
            
        Returns:
            Goal data with progress metrics if found, None otherwise
        """
        goal = self._db.query(Goal).filter(
            Goal.id == goal_id,
            Goal.user_id == user_id
        ).first()
        
        if not goal:
            return None
            
        return GoalResponse.from_orm(goal)

    def list_goals(self, user_id: UUID) -> List[GoalResponse]:
        """
        List all goals for a user with progress tracking.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal listing with progress metrics
        
        Args:
            user_id: UUID of the user
            
        Returns:
            List of user's goals with progress metrics
        """
        goals = self._db.query(Goal).filter(Goal.user_id == user_id).all()
        return [GoalResponse.from_orm(goal) for goal in goals]

    def update_goal(self, goal_id: UUID, user_id: UUID, goal_data: GoalUpdate) -> Optional[GoalInDB]:
        """
        Update an existing goal.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal update functionality
        
        Args:
            goal_id: UUID of the goal to update
            user_id: UUID of the goal owner
            goal_data: Validated update data
            
        Returns:
            Updated goal data if found, None otherwise
            
        Raises:
            DatabaseError: If goal update fails
        """
        try:
            goal = self._db.query(Goal).filter(
                Goal.id == goal_id,
                Goal.user_id == user_id
            ).first()
            
            if not goal:
                return None
                
            # Update goal attributes if provided
            if goal_data.name is not None:
                goal.name = goal_data.name
            if goal_data.description is not None:
                goal.description = goal_data.description
            if goal_data.target_amount is not None:
                goal.target_amount = goal_data.target_amount
            if goal_data.target_date is not None:
                goal.target_date = goal_data.target_date
            if goal_data.account_id is not None:
                goal.account_id = goal_data.account_id
                
            self._db.commit()
            self._db.refresh(goal)
            
            return GoalInDB.from_orm(goal)
            
        except Exception as e:
            self._db.rollback()
            raise DatabaseError(f"Failed to update goal: {str(e)}")

    def delete_goal(self, goal_id: UUID, user_id: UUID) -> bool:
        """
        Delete a goal by ID and user ID.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal deletion functionality
        
        Args:
            goal_id: UUID of the goal to delete
            user_id: UUID of the goal owner
            
        Returns:
            True if deleted, False if not found
            
        Raises:
            DatabaseError: If goal deletion fails
        """
        try:
            result = self._db.query(Goal).filter(
                Goal.id == goal_id,
                Goal.user_id == user_id
            ).delete()
            
            self._db.commit()
            return result > 0
            
        except Exception as e:
            self._db.rollback()
            raise DatabaseError(f"Failed to delete goal: {str(e)}")

    def update_goal_progress(self, goal_id: UUID, user_id: UUID, amount: Decimal) -> Optional[GoalResponse]:
        """
        Update goal progress amount and check completion.
        
        Requirements addressed:
        - Goal Management (1.2): Implements goal progress tracking and achievement monitoring
        
        Args:
            goal_id: UUID of the goal
            user_id: UUID of the goal owner
            amount: New current amount for the goal
            
        Returns:
            Updated goal data with progress metrics if found, None otherwise
            
        Raises:
            DatabaseError: If progress update fails
        """
        try:
            goal = self._db.query(Goal).filter(
                Goal.id == goal_id,
                Goal.user_id == user_id
            ).first()
            
            if not goal:
                return None
                
            # Update progress and check completion
            goal.update_progress(amount)
            
            self._db.commit()
            self._db.refresh(goal)
            
            return GoalResponse.from_orm(goal)
            
        except Exception as e:
            self._db.rollback()
            raise DatabaseError(f"Failed to update goal progress: {str(e)}")