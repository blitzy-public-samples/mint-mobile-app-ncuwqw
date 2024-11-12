# Library versions:
# pydantic: ^1.8.2
# typing: ^3.9.0
# datetime: ^3.9.0

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field, constr

from app.models.category import Category
from app.utils.validators import validate_request

# Human Tasks:
# 1. Review category name length constraints with business team
# 2. Verify hierarchical depth limits for category relationships
# 3. Confirm system category types with product team
# 4. Review category validation rules with security team

class CategoryBase(BaseModel):
    """
    Base Pydantic model for category data validation with common fields.
    
    Requirements addressed:
    - Category Management (1.2 Scope/Financial Tracking):
      Defines base structure for hierarchical categories
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Implements server-side validation for category data
    """
    name: str
    description: Optional[str] = None
    parent_id: Optional[int] = None

    class Config:
        orm_mode = True


class CategoryCreate(CategoryBase):
    """
    Pydantic model for category creation requests with validation.
    
    Requirements addressed:
    - Category Management (1.2 Scope/Financial Tracking):
      Supports creation of system and custom categories
    - Budget Categories (1.2 Scope/Budget Management):
      Enables category-based budget tracking
    """
    name: constr(min_length=1, max_length=100)
    description: Optional[str] = Field(None, max_length=255)
    parent_id: Optional[int] = None
    is_system: bool = False

    async def validate_parent(self, parent_id: int) -> bool:
        """
        Validates parent category existence and hierarchy.
        
        Args:
            parent_id: ID of the parent category to validate
            
        Returns:
            bool: True if parent is valid
            
        Raises:
            ValidationError: If parent validation fails
        """
        if not parent_id:
            return True
            
        # Validate parent exists in database
        parent = await Category.get(parent_id)
        if not parent:
            raise ValueError("Parent category does not exist")
            
        # Check for circular dependencies
        current = parent
        while current and current.parent_id:
            if current.parent_id == parent_id:
                raise ValueError("Circular dependency detected in category hierarchy")
            current = await Category.get(current.parent_id)
            
        return True


class CategoryUpdate(BaseModel):
    """
    Pydantic model for category update requests with partial updates.
    
    Requirements addressed:
    - Category Management (1.2 Scope/Financial Tracking):
      Enables modification of category attributes
    - Data Validation (6.3.3 Security Controls/Input Validation):
      Validates update data
    """
    name: Optional[constr(min_length=1, max_length=100)] = None
    description: Optional[str] = Field(None, max_length=255)
    parent_id: Optional[int] = None
    is_active: Optional[bool] = None

    class Config:
        orm_mode = True


class CategoryResponse(BaseModel):
    """
    Pydantic model for category response data with relationships.
    
    Requirements addressed:
    - Category Management (1.2 Scope/Financial Tracking):
      Provides complete category data with relationships
    - Budget Categories (1.2 Scope/Budget Management):
      Supports budget category hierarchy display
    """
    id: int
    name: str
    description: Optional[str]
    parent_id: Optional[int]
    is_system: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime
    parent: Optional['CategoryResponse'] = None
    subcategories: List['CategoryResponse'] = []

    class Config:
        orm_mode = True

    @classmethod
    def from_orm(cls, db_category: Category) -> 'CategoryResponse':
        """
        Creates response model from ORM model instance.
        
        Args:
            db_category: Database category model instance
            
        Returns:
            CategoryResponse: Response model instance with relationships
        """
        # Create base response without relationships
        response = cls(
            id=db_category.id,
            name=db_category.name,
            description=db_category.description,
            parent_id=db_category.parent_id,
            is_system=db_category.is_system,
            is_active=db_category.is_active,
            created_at=db_category.created_at,
            updated_at=db_category.updated_at,
            subcategories=[]
        )
        
        # Include parent category if exists
        if db_category.parent:
            response.parent = cls(
                id=db_category.parent.id,
                name=db_category.parent.name,
                description=db_category.parent.description,
                parent_id=db_category.parent.parent_id,
                is_system=db_category.parent.is_system,
                is_active=db_category.parent.is_active,
                created_at=db_category.parent.created_at,
                updated_at=db_category.parent.updated_at,
                subcategories=[]
            )
            
        # Include subcategories recursively
        if db_category.subcategories:
            response.subcategories = [
                cls.from_orm(subcategory)
                for subcategory in db_category.subcategories
                if subcategory.id != db_category.id  # Prevent circular references
            ]
            
        return response


# Required for self-referencing models
CategoryResponse.update_forward_refs()