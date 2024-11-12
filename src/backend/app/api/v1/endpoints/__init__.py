"""
FastAPI endpoint routers initialization module for Mint Replica Lite API.

Human Tasks:
1. Review and adjust rate limiting settings for production environment
2. Configure monitoring for API endpoint performance metrics
3. Set up logging for API request tracking
4. Review and update API documentation when endpoints change
"""

# fastapi: ^0.95.0
from fastapi import APIRouter

# Import routers from endpoint modules
from .auth import router as auth_router
from .accounts import router as accounts_router
from .transactions import router as transactions_router
from .budgets import router as budgets_router
from .goals import router as goals_router
from .investments import router as investments_router

# Initialize main API router with prefix and tags
api_router = APIRouter(prefix='/api/v1', tags=['v1'])

def include_routers() -> None:
    """
    Include all endpoint routers into the main API router with proper prefix handling.
    
    Requirements addressed:
    - API Gateway Layer (2.1): Centralizes and exposes API endpoints through a unified gateway
    - RESTful API Services (1.1): Implements RESTful API services for data management
    - API Security (2.4): Implements secure API routing with OAuth 2.0 and role-based access
    """
    # Include authentication endpoints
    api_router.include_router(
        auth_router,
        prefix="/auth",
        tags=["Authentication"]
    )
    
    # Include account management endpoints
    api_router.include_router(
        accounts_router,
        prefix="/accounts",
        tags=["Accounts"]
    )
    
    # Include transaction management endpoints
    api_router.include_router(
        transactions_router,
        prefix="/transactions", 
        tags=["Transactions"]
    )
    
    # Include budget management endpoints
    api_router.include_router(
        budgets_router,
        prefix="/budgets",
        tags=["Budgets"]
    )
    
    # Include financial goals endpoints
    api_router.include_router(
        goals_router,
        prefix="/goals",
        tags=["Goals"]
    )
    
    # Include investment management endpoints
    api_router.include_router(
        investments_router,
        prefix="/investments",
        tags=["Investments"]
    )

# Initialize routers on module import
include_routers()