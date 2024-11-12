"""
Redis cache implementation for Mint Replica Lite backend application.

Human Tasks:
1. Configure Redis instance and security groups in production environment
2. Set up Redis cluster for high availability in production
3. Configure Redis SSL certificates for secure communication
4. Review and adjust cache TTL values based on production usage patterns
5. Set up Redis monitoring and alerting in production
"""

# Library versions:
# redis: ^4.0.0
# json: built-in
# typing: built-in
# asyncio: built-in

import json
from typing import Any, Optional
import asyncio
from redis import Redis
from redis.exceptions import RedisError, ConnectionError

from core.config import get_redis_settings
from core.errors import ValidationError

class RedisCache:
    """
    Redis cache implementation providing thread-safe caching functionality with 
    configurable TTL, connection pooling, and JSON serialization.
    
    Requirement: Cache Management - Redis for caching and session management
    """
    
    def __init__(self, default_ttl: int = 3600) -> None:
        """
        Initialize Redis cache connection and settings.
        
        Args:
            default_ttl (int): Default time-to-live in seconds for cache entries
        
        Raises:
            ValidationError: If Redis connection parameters are invalid
            ConnectionError: If Redis connection fails
        """
        # Get Redis configuration from settings
        self._redis_settings = get_redis_settings()
        
        # Validate Redis connection parameters
        if not self._redis_settings.get('host') or not self._redis_settings.get('port'):
            raise ValidationError("Invalid Redis connection parameters")
        
        try:
            # Initialize Redis client with connection pooling
            # Requirement: Performance Optimization - Redis cluster for distributed caching
            self._client = Redis(
                host=self._redis_settings['host'],
                port=int(self._redis_settings['port']),
                db=int(self._redis_settings['db']),
                password=self._redis_settings['password'],
                ssl=self._redis_settings['ssl'],
                encoding=self._redis_settings['encoding'],
                decode_responses=True,
                socket_timeout=5,
                socket_connect_timeout=5,
                retry_on_timeout=True,
                max_connections=10,
                health_check_interval=30
            )
            
            # Set default TTL for cache entries
            self.default_ttl = default_ttl
            
            # Test connection to Redis server
            self._client.ping()
            
        except (RedisError, ConnectionError) as e:
            raise ConnectionError(f"Failed to connect to Redis: {str(e)}")

    def get(self, key: str) -> Any:
        """
        Retrieve value from cache by key with JSON deserialization.
        
        Args:
            key (str): Cache key to retrieve
            
        Returns:
            Any: Deserialized cached value or None if not found
            
        Raises:
            ValidationError: If key parameter is invalid
        """
        # Validate key parameter
        if not isinstance(key, str) or not key.strip():
            raise ValidationError("Invalid cache key")
            
        try:
            # Get raw value from Redis
            value = self._client.get(key)
            
            if value is None:
                return None
                
            # Deserialize JSON value with error handling
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                # Return raw value if not JSON
                return value
                
        except RedisError as e:
            # Log error and return None on Redis errors
            print(f"Redis error in get(): {str(e)}")
            return None

    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """
        Store JSON serialized value in cache with optional TTL.
        
        Args:
            key (str): Cache key
            value (Any): Value to cache (will be JSON serialized)
            ttl (Optional[int]): Time-to-live in seconds, defaults to self.default_ttl
            
        Returns:
            bool: Success status of cache operation
            
        Raises:
            ValidationError: If key or value parameters are invalid
        """
        # Validate key and value parameters
        if not isinstance(key, str) or not key.strip():
            raise ValidationError("Invalid cache key")
        
        if value is None:
            raise ValidationError("Cache value cannot be None")
            
        try:
            # Serialize value to JSON with error handling
            if not isinstance(value, (str, bytes)):
                value = json.dumps(value)
                
            # Use default TTL if none provided
            if ttl is None:
                ttl = self.default_ttl
                
            # Store in Redis with TTL
            return bool(self._client.setex(key, ttl, value))
            
        except (RedisError, TypeError, json.JSONDecodeError) as e:
            # Log error and return False on errors
            print(f"Redis error in set(): {str(e)}")
            return False

    def delete(self, key: str) -> bool:
        """
        Remove value from cache by key.
        
        Args:
            key (str): Cache key to delete
            
        Returns:
            bool: Success status of delete operation
            
        Raises:
            ValidationError: If key parameter is invalid
        """
        # Validate key parameter
        if not isinstance(key, str) or not key.strip():
            raise ValidationError("Invalid cache key")
            
        try:
            # Delete key from Redis
            return bool(self._client.delete(key))
            
        except RedisError as e:
            # Log error and return False on Redis errors
            print(f"Redis error in delete(): {str(e)}")
            return False

    def exists(self, key: str) -> bool:
        """
        Check if key exists in cache.
        
        Args:
            key (str): Cache key to check
            
        Returns:
            bool: True if key exists, False otherwise
            
        Raises:
            ValidationError: If key parameter is invalid
        """
        # Validate key parameter
        if not isinstance(key, str) or not key.strip():
            raise ValidationError("Invalid cache key")
            
        try:
            # Check key existence in Redis
            return bool(self._client.exists(key))
            
        except RedisError as e:
            # Log error and return False on Redis errors
            print(f"Redis error in exists(): {str(e)}")
            return False

    def clear(self) -> bool:
        """
        Clear all cache entries.
        
        Returns:
            bool: Success status of clear operation
        """
        try:
            # Flush all keys from Redis database
            return bool(self._client.flushdb())
            
        except RedisError as e:
            # Log error and return False on Redis errors
            print(f"Redis error in clear(): {str(e)}")
            return False

# Global cache instance with 1 hour default TTL
# Requirement: Session Management - Session management using Redis
cache = RedisCache(default_ttl=3600)