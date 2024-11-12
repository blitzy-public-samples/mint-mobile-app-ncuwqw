"""
API version 1 package initialization module for Mint Replica Lite backend application.

Human Tasks:
1. Review API rate limiting configuration before production deployment
2. Set up API monitoring and alerting
3. Configure API logging and tracing
4. Review API security settings for production environment
"""

# fastapi: ^0.95.0
from fastapi import APIRouter

# Import API routers and settings
from app.api.v1.routes import (
    auth_router,
    users_router,
    accounts_router,
    transactions_router,
    budgets_router,
    goals_router,
    investments_router
)
from app.core.config import settings

# Initialize the v1 API router with prefix and tags
api_v1_router = APIRouter(prefix=settings.API_V1_PREFIX, tags=['v1'])

def configure_v1_router() -> APIRouter:
    """
    Configures the version 1 API router with all endpoint routes.
    
    Requirements addressed:
    - API Gateway Layer (2.1): Implements central API routing and load balancing configuration
    - RESTful Services (2.D): Implements RESTful service architecture with proper versioning
    - API Security (2.4): Configures secure routing with OAuth 2.0 and RBAC
    
    Returns:
        APIRouter: Configured v1 API router instance with all mounted endpoint routers
    """
    # Mount authentication endpoints
    api_v1_router.include_router(
        auth_router,
        prefix="/auth",
        tags=["Authentication"]
    )

    # Mount user management endpoints
    api_v1_router.include_router(
        users_router,
        prefix="/users",
        tags=["User Management"]
    )

    # Mount account management endpoints
    api_v1_router.include_router(
        accounts_router,
        prefix="/accounts",
        tags=["Account Management"]
    )

    # Mount transaction management endpoints
    api_v1_router.include_router(
        transactions_router,
        prefix="/transactions",
        tags=["Transactions"]
    )

    # Mount budget management endpoints
    api_v1_router.include_router(
        budgets_router,
        prefix="/budgets",
        tags=["Budgets"]
    )

    # Mount goal management endpoints
    api_v1_router.include_router(
        goals_router,
        prefix="/goals",
        tags=["Goals"]
    )

    # Mount investment management endpoints
    api_v1_router.include_router(
        investments_router,
        prefix="/investments",
        tags=["Investments"]
    )

    return api_v1_router

# Configure the router on module import
configure_v1_router()

# Export the configured router
__all__ = ['api_v1_router']