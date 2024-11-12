"""
Unit test suite for Redis cache implementation in Mint Replica Lite backend.

Human Tasks:
1. Ensure Redis test instance is running on port 6379
2. Configure test Redis instance with appropriate memory limits
3. Verify test environment has proper network access to Redis
4. Review and adjust test timeouts if needed
"""

# pytest: ^7.0.0
# pytest-asyncio: ^0.18.0
# json: built-in

import json
import pytest
from app.core.cache import RedisCache
from conftest import get_test_redis

# Test constants
TEST_KEY = "test_key"
TEST_VALUE = "test_value"
TEST_TTL = 300

@pytest.mark.asyncio
async def test_cache_initialization(test_redis):
    """
    Test Redis cache initialization and connection with proper configuration.
    
    Requirement: Cache Management Testing - Verify Redis caching functionality
    """
    # Initialize cache with test Redis instance
    cache = RedisCache()
    
    # Verify default TTL is set correctly
    assert cache.default_ttl == 3600
    
    # Verify Redis connection is established
    assert cache._client.ping()
    
    # Verify Redis client configuration
    assert cache._client.connection_pool.max_connections == 10
    assert cache._client.connection_pool.encoding == 'utf-8'
    assert cache._client.decode_responses is True

@pytest.mark.asyncio
async def test_cache_set_get(test_redis):
    """
    Test setting and retrieving values from cache with JSON serialization.
    
    Requirement: Cache Management Testing - Validate core caching functionality
    """
    cache = RedisCache()
    
    # Test string value
    assert cache.set(TEST_KEY, TEST_VALUE)
    assert cache.get(TEST_KEY) == TEST_VALUE
    
    # Test dictionary value with JSON serialization
    test_dict = {"key": "value", "number": 123}
    assert cache.set("dict_key", test_dict)
    retrieved_dict = cache.get("dict_key")
    assert retrieved_dict == test_dict
    
    # Test list value with JSON serialization
    test_list = [1, 2, "three", {"four": 4}]
    assert cache.set("list_key", test_list)
    retrieved_list = cache.get("list_key")
    assert retrieved_list == test_list
    
    # Test cache miss
    assert cache.get("nonexistent_key") is None
    
    # Test custom TTL
    assert cache.set(TEST_KEY, TEST_VALUE, ttl=TEST_TTL)
    ttl = cache._client.ttl(TEST_KEY)
    assert TEST_TTL - 1 <= ttl <= TEST_TTL

@pytest.mark.asyncio
async def test_cache_delete(test_redis):
    """
    Test deleting values from cache with proper cleanup.
    
    Requirement: Cache Management Testing - Verify cache deletion operations
    """
    cache = RedisCache()
    
    # Set test value
    assert cache.set(TEST_KEY, TEST_VALUE)
    assert cache.exists(TEST_KEY)
    
    # Delete value and verify
    assert cache.delete(TEST_KEY)
    assert not cache.exists(TEST_KEY)
    
    # Test deleting non-existent key
    assert not cache.delete("nonexistent_key")
    
    # Test deleting multiple values
    cache.set("key1", "value1")
    cache.set("key2", "value2")
    assert cache.delete("key1")
    assert cache.delete("key2")
    assert not cache.exists("key1")
    assert not cache.exists("key2")

@pytest.mark.asyncio
async def test_cache_exists(test_redis):
    """
    Test checking existence of cache keys with proper validation.
    
    Requirement: Cache Management Testing - Validate key existence checks
    """
    cache = RedisCache()
    
    # Test non-existent key
    assert not cache.exists("nonexistent_key")
    
    # Test existing key
    cache.set(TEST_KEY, TEST_VALUE)
    assert cache.exists(TEST_KEY)
    
    # Test after deletion
    cache.delete(TEST_KEY)
    assert not cache.exists(TEST_KEY)
    
    # Test with invalid key types
    with pytest.raises(ValueError):
        cache.exists(None)
    with pytest.raises(ValueError):
        cache.exists("")
    with pytest.raises(ValueError):
        cache.exists(123)

@pytest.mark.asyncio
async def test_cache_clear(test_redis):
    """
    Test clearing all cache entries with proper cleanup.
    
    Requirement: Cache Management Testing - Verify cache clearing functionality
    """
    cache = RedisCache()
    
    # Set multiple test values
    test_data = {
        "key1": "value1",
        "key2": {"nested": "value2"},
        "key3": [1, 2, 3],
        "key4": "value4"
    }
    
    for key, value in test_data.items():
        cache.set(key, value)
        assert cache.exists(key)
    
    # Clear cache and verify
    assert cache.clear()
    
    # Verify all keys are removed
    for key in test_data.keys():
        assert not cache.exists(key)
    
    # Verify clear is idempotent
    assert cache.clear()

@pytest.mark.asyncio
async def test_cache_ttl(test_redis):
    """
    Test TTL functionality of cache entries with expiration.
    
    Requirement: Performance Testing - Validate cache TTL management
    """
    cache = RedisCache()
    
    # Test custom TTL
    cache.set(TEST_KEY, TEST_VALUE, ttl=TEST_TTL)
    ttl = cache._client.ttl(TEST_KEY)
    assert TEST_TTL - 1 <= ttl <= TEST_TTL
    
    # Test default TTL
    cache.set("default_ttl_key", "value")
    ttl = cache._client.ttl("default_ttl_key")
    assert 3599 <= ttl <= 3600
    
    # Test updating existing key TTL
    cache.set(TEST_KEY, "new_value", ttl=600)
    ttl = cache._client.ttl(TEST_KEY)
    assert 599 <= ttl <= 600
    
    # Test zero TTL (no expiration)
    cache.set("no_expiry_key", "value", ttl=0)
    ttl = cache._client.ttl("no_expiry_key")
    assert ttl == -1