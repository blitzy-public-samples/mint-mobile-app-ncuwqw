"""
Utility module for standardized API pagination functionality.

Human Tasks:
1. Review and adjust pagination limits in production environment
2. Monitor query performance with pagination in production
3. Configure appropriate index on sorted fields in database
"""

# Library versions:
# pydantic: ^1.8.2
# typing: ^3.9.0
# sqlalchemy: ^1.4.0

from typing import Dict, List, Optional, Tuple, Any
from pydantic import BaseModel
from sqlalchemy import Query

from ..core.config import get_settings
from ..core.errors import ValidationError

class PaginationParams(BaseModel):
    """
    Pydantic model for validating and standardizing pagination parameters.
    
    Requirement: API Response Standardization
    Location: 2.3 Data Flow Architecture/API Layer/Validation
    """
    page: int
    per_page: int
    sort_by: Optional[str] = None
    sort_order: Optional[str] = None

    def __init__(self, page: int, per_page: int, sort_by: Optional[str] = None, 
                 sort_order: Optional[str] = None) -> None:
        """Initialize pagination parameters with validation."""
        super().__init__(
            page=page,
            per_page=per_page,
            sort_by=sort_by,
            sort_order=sort_order
        )
        
        # Validate page number is positive
        if self.page < 1:
            raise ValidationError(
                message="Page number must be positive",
                details={"page": "Must be greater than 0"}
            )
        
        # Get pagination limits from settings
        settings = get_settings()
        min_per_page = getattr(settings, "MIN_PER_PAGE", 10)
        max_per_page = getattr(settings, "MAX_PER_PAGE", 100)
        
        # Validate per_page is within limits
        if not min_per_page <= self.per_page <= max_per_page:
            raise ValidationError(
                message=f"Items per page must be between {min_per_page} and {max_per_page}",
                details={"per_page": f"Must be between {min_per_page} and {max_per_page}"}
            )
        
        # Validate sort_order if provided
        if self.sort_order and self.sort_order.lower() not in ["asc", "desc"]:
            raise ValidationError(
                message="Sort order must be either 'asc' or 'desc'",
                details={"sort_order": "Must be either 'asc' or 'desc'"}
            )

class PaginatedResponse(BaseModel):
    """
    Class representing a standardized paginated API response.
    
    Requirement: API Response Standardization
    Location: 2.3 Data Flow Architecture/API Layer/Validation
    """
    items: List[Any]
    total: int
    page: int
    per_page: int
    pages: int

    def __init__(self, items: List[Any], total: int, page: int, per_page: int) -> None:
        """Initialize paginated response with metadata."""
        pages = (total + per_page - 1) // per_page if per_page > 0 else 0
        super().__init__(
            items=items,
            total=total,
            page=page,
            per_page=per_page,
            pages=pages
        )

def paginate_query(query: Query, params: PaginationParams) -> Tuple[List[Any], int]:
    """
    Apply pagination and optional sorting to a SQLAlchemy query.
    
    Requirement: Data Query Optimization
    Location: 2.5 Infrastructure Architecture/2.5.3 Scalability Architecture
    """
    # Clone query for total count
    count_query = query.with_entities(Query.func.count())
    
    # Apply sorting if specified
    if params.sort_by and params.sort_order:
        sort_column = getattr(query.column_descriptions[0]['type'], params.sort_by, None)
        if sort_column is None:
            raise ValidationError(
                message=f"Invalid sort column: {params.sort_by}",
                details={"sort_by": "Column does not exist"}
            )
        
        if params.sort_order.lower() == "desc":
            query = query.order_by(sort_column.desc())
        else:
            query = query.order_by(sort_column.asc())
    
    # Calculate offset
    offset = (params.page - 1) * params.per_page
    
    # Apply pagination
    query = query.offset(offset).limit(params.per_page)
    
    # Execute queries
    total = count_query.scalar()
    items = query.all()
    
    return items, total

def create_pagination_params(request_args: Dict[str, Any]) -> PaginationParams:
    """
    Create validated pagination parameters from request arguments.
    
    Requirement: API Response Standardization
    Location: 2.3 Data Flow Architecture/API Layer/Validation
    """
    try:
        # Extract and convert pagination parameters
        page = int(request_args.get("page", 1))
        per_page = int(request_args.get("per_page", 20))
        sort_by = request_args.get("sort_by")
        sort_order = request_args.get("sort_order")
        
        # Create and validate parameters
        return PaginationParams(
            page=page,
            per_page=per_page,
            sort_by=sort_by,
            sort_order=sort_order
        )
    except (ValueError, TypeError) as e:
        raise ValidationError(
            message="Invalid pagination parameters",
            details={"error": str(e)}
        )

def format_paginated_response(items: List[Any], total: int, 
                            params: PaginationParams) -> PaginatedResponse:
    """
    Format query results into a standardized paginated response.
    
    Requirement: API Response Standardization
    Location: 2.3 Data Flow Architecture/API Layer/Validation
    """
    return PaginatedResponse(
        items=items,
        total=total,
        page=params.page,
        per_page=params.per_page
    )