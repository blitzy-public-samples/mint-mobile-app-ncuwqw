"""
Pytest configuration file providing shared test fixtures for Mint Replica Lite backend testing.

Human Tasks:
1. Ensure PostgreSQL test database is created and accessible
2. Configure test database credentials in environment
3. Verify Redis test instance is running on port 6379
4. Set up test user permissions and roles
5. Review and adjust test timeouts if needed
"""

# pytest: ^7.0.0
# fastapi: ^0.95.0
# sqlalchemy: ^1.4.0

import pytest
from typing import Dict, Generator
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db, init_db
from app.core.cache import RedisCache
from app.core.auth import create_access_token

# Test configuration constants
# Requirement: Database Testing - Configure test database fixtures for PostgreSQL testing
TEST_DATABASE_URL: str = 'postgresql+asyncpg://test:test@localhost:5432/test_db'
TEST_REDIS_URL: str = 'redis://localhost:6379/1'

@pytest.fixture
def test_db() -> Generator[AsyncSession, None, None]:
    """
    Provides clean test database session with automatic transaction rollback.
    
    Requirement: Database Testing - Configure test database fixtures for PostgreSQL testing
    with transaction rollback and session cleanup
    
    Yields:
        AsyncSession: Clean database session for test use
    """
    try:
        # Initialize test database schema
        init_db()
        
        # Get clean database session
        session = get_db()
        db = next(session)
        
        yield db
        
        # Rollback changes after test
        db.rollback()
    finally:
        # Cleanup resources
        db.close()

@pytest.fixture
def test_cache() -> Generator[RedisCache, None, None]:
    """
    Provides isolated Redis cache instance for testing.
    
    Requirement: Cache Testing - Set up Redis cache testing fixtures with isolated
    test cache instances
    
    Yields:
        RedisCache: Clean Redis cache instance
    """
    # Initialize test cache with 1 hour TTL
    cache = RedisCache(default_ttl=3600)
    
    # Clear any existing data
    cache.clear()
    
    yield cache
    
    # Cleanup after test
    cache.clear()

@pytest.fixture
def test_client() -> Generator[TestClient, None, None]:
    """
    Provides configured FastAPI test client.
    
    Requirement: Database Testing - Configure test database fixtures for PostgreSQL testing
    
    Yields:
        TestClient: FastAPI test client instance
    """
    # Create test FastAPI application
    app = FastAPI(title="Mint Replica Lite Test API")
    
    # Configure test dependencies
    app.dependency_overrides[get_db] = test_db
    
    # Create test client
    client = TestClient(app)
    
    yield client
    
    # Cleanup application
    app.dependency_overrides.clear()

@pytest.fixture
def test_auth_headers() -> Dict[str, str]:
    """
    Provides authentication headers with valid test JWT token.
    
    Requirement: Authentication Testing - Provide authentication test fixtures with JWT tokens
    following security standards
    
    Returns:
        Dict[str, str]: Headers dictionary with Bearer token
    """
    # Create test user data
    test_user = {
        "sub": "test_user_id",
        "email": "test@example.com",
        "scopes": ["user:read", "user:write"]
    }
    
    # Generate access token
    access_token = create_access_token(data=test_user)
    
    # Create authorization headers
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/json"
    }
    
    return headers