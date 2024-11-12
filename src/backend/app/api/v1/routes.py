"""
Main router configuration file for Mint Replica Lite API v1.

Human Tasks:
1. Review and adjust rate limiting settings for production deployment
2. Configure monitoring for API endpoint performance metrics
3. Set up logging for API request tracking
4. Review CORS settings for production environment
5. Configure API documentation settings
"""

# fastapi: ^0.95.0
from fastapi import APIRouter, status

# Import routers from endpoint modules
from .endpoints.auth import router as auth_router
from .endpoints.users import router as users_router
from .endpoints.accounts import router as accounts_router
from .endpoints.transactions import router as transactions_router
from .endpoints.budgets import router as budgets_router
from .endpoints.goals import router as goals_router
from .endpoints.investments import router as investments_router

# Initialize main API router with version prefix
api_router = APIRouter(prefix='/api/v1', tags=['v1'])

def include_routers() -> None:
    """
    Include all endpoint routers into the main API router with proper prefixes and tags.
    
    Requirements addressed:
    - API Gateway Layer (2.1): Implements central API routing and load balancing
    - RESTful Services (2.D): Implements proper endpoint versioning and routing
    - API Security (2.4): Configures secure routing with proper authentication
    """
    
    # Authentication endpoints
    api_router.include_router(
        auth_router,
        prefix="/auth",
        tags=["Authentication"]
    )
    
    # User management endpoints
    api_router.include_router(
        users_router,
        prefix="/users",
        tags=["User Management"]
    )
    
    # Account management endpoints
    api_router.include_router(
        accounts_router,
        prefix="/accounts",
        tags=["Account Management"]
    )
    
    # Transaction management endpoints
    api_router.include_router(
        transactions_router,
        prefix="/transactions",
        tags=["Transactions"]
    )
    
    # Budget management endpoints
    api_router.include_router(
        budgets_router,
        prefix="/budgets",
        tags=["Budgets"]
    )
    
    # Goal management endpoints
    api_router.include_router(
        goals_router,
        prefix="/goals",
        tags=["Goals"]
    )
    
    # Investment management endpoints
    api_router.include_router(
        investments_router,
        prefix="/investments",
        tags=["Investments"]
    )

# Include all routers on module import
include_routers()