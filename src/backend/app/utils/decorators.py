"""
Utility module providing reusable decorators for authentication, caching, logging, and error handling.

Human Tasks:
1. Review and adjust cache TTL values based on production usage patterns
2. Configure logging levels and retention policies in production
3. Verify error handling and security measures align with compliance requirements
"""

# fastapi: ^0.95.0
# functools: ^3.9.0
# typing: ^3.9.0

import functools
import json
import time
from typing import Any, Callable, Dict, List, Optional

from fastapi import HTTPException, Request
from fastapi.security.utils import get_authorization_scheme_param

from ..core.auth import verify_token
from ..core.cache import cache
from ..core.logging import get_logger

# Initialize structured logger
logger = get_logger(__name__)

def require_auth(required_scopes: List[str]) -> Callable:
    """
    Decorator to enforce JWT authentication and scope validation on API endpoints.
    
    Requirement: Authentication Flow - 6.1 Authentication and Authorization/6.1.1 Authentication Flow
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            # Extract request object from args/kwargs
            request = next((arg for arg in args if isinstance(arg, Request)), None)
            if not request:
                raise HTTPException(status_code=500, detail="Internal server error")

            # Get authorization token from header or cookie
            authorization = request.headers.get("Authorization")
            scheme, token = get_authorization_scheme_param(authorization)
            
            if not token:
                token = request.cookies.get("access_token")
                
            if not token:
                raise HTTPException(
                    status_code=401,
                    detail="Not authenticated",
                    headers={"WWW-Authenticate": "Bearer"}
                )

            # Verify token and scopes
            try:
                payload = verify_token(token, required_scopes)
                # Add user context to request state
                request.state.user = payload
                return await func(*args, **kwargs)
            except HTTPException as e:
                raise e
            except Exception as e:
                logger.error("Authentication error", error=str(e))
                raise HTTPException(status_code=401, detail="Authentication failed")
                
        return wrapper
    return decorator

def cache_response(ttl: int, key_prefix: str) -> Callable:
    """
    Decorator to cache API response data in Redis with TTL.
    
    Requirement: Cache Management - 2.5 Infrastructure Architecture/2.5.3 Scalability Architecture
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            # Generate cache key from prefix and arguments
            cache_key = f"{key_prefix}:"
            
            # Add args to cache key
            if args:
                cache_key += ":".join(str(arg) for arg in args)
                
            # Add kwargs to cache key
            if kwargs:
                sorted_kwargs = sorted(kwargs.items())
                cache_key += ":" + ":".join(f"{k}={v}" for k, v in sorted_kwargs)

            # Try to get cached response
            cached_response = cache.get(cache_key)
            if cached_response is not None:
                return cached_response

            # Execute function if cache miss
            response = await func(*args, **kwargs)
            
            # Cache the response
            try:
                cache.set(cache_key, response, ttl)
            except Exception as e:
                logger.error("Cache error", error=str(e), key=cache_key)
                
            return response
            
        return wrapper
    return decorator

def log_execution(operation_name: str) -> Callable:
    """
    Decorator to log function execution with timing and context.
    
    Requirement: Security Controls - 6.3 Security Protocols/6.3.3 Security Controls
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            # Create context logger with operation
            ctx_logger = logger.bind({
                "operation": operation_name,
                "function": func.__name__
            })
            
            # Log function entry
            ctx_logger.info(
                "Starting operation",
                args=str(args),
                kwargs=str(kwargs)
            )
            
            start_time = time.perf_counter()
            
            try:
                result = await func(*args, **kwargs)
                duration = time.perf_counter() - start_time
                
                # Log successful completion
                ctx_logger.info(
                    "Operation completed",
                    duration=f"{duration:.3f}s",
                    status="success"
                )
                return result
                
            except Exception as e:
                duration = time.perf_counter() - start_time
                
                # Log failure
                ctx_logger.error(
                    "Operation failed",
                    duration=f"{duration:.3f}s",
                    error=str(e),
                    status="error"
                )
                raise
                
        return wrapper
    return decorator

def handle_exceptions() -> Callable:
    """
    Decorator to handle and log exceptions with proper security measures.
    
    Requirement: Security Controls - 6.3 Security Protocols/6.3.3 Security Controls
    """
    def decorator(func: Callable) -> Callable:
        @functools.wraps(func)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            try:
                return await func(*args, **kwargs)
                
            except HTTPException as e:
                # Pass through HTTP exceptions
                logger.warning(
                    "HTTP error",
                    status_code=e.status_code,
                    detail=e.detail
                )
                raise
                
            except ValueError as e:
                # Handle validation errors
                logger.error(
                    "Validation error",
                    error=str(e),
                    function=func.__name__
                )
                raise HTTPException(status_code=400, detail="Invalid request")
                
            except Exception as e:
                # Mask sensitive info in error messages
                logger.error(
                    "Unhandled error",
                    error=str(e),
                    function=func.__name__,
                    traceback=True
                )
                raise HTTPException(
                    status_code=500,
                    detail="An unexpected error occurred"
                )
                
        return wrapper
    return decorator