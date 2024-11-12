"""
Test suite for NotificationService functionality.

Human Tasks:
1. Configure test environment variables for notification services
2. Set up mock APNS certificates for testing
3. Create test Firebase project credentials
4. Configure test VAPID keys for Web Push
5. Set up local Redis instance for testing
"""

# Library versions:
# pytest: ^7.0.0
# pytest-asyncio: ^0.18.0
# unittest.mock: built-in

import pytest
from unittest.mock import MagicMock, AsyncMock, patch
from typing import Dict, Any

from app.services.notification_service import (
    NotificationService,
    NOTIFICATION_TYPES,
    PLATFORM_TYPES
)
from app.core.config import Settings
from app.core.events import EventManager

# Test constants
TEST_USER_ID: str = 'test-user-123'
TEST_DEVICE_TOKEN: str = 'test-device-token-456'
TEST_NOTIFICATION_PAYLOAD: Dict[str, Any] = {
    'title': 'Test Notification',
    'body': 'Test message',
    'data': {'type': 'test'}
}

def pytest_configure(config):
    """Configure pytest environment for notification tests."""
    # Requirement: Push Notification Integration - Test environment setup
    config.addinivalue_line(
        "markers",
        "notification: mark test as notification service test"
    )

@pytest.mark.asyncio
class TestNotificationService:
    """Test suite for NotificationService functionality."""
    
    def __init__(self):
        """Set up test environment for notification tests."""
        # Initialize mock clients
        self._mock_apns_client = AsyncMock()
        self._mock_fcm_client = MagicMock()
        self._mock_web_push_client = MagicMock()
        self._mock_redis = AsyncMock()
        self._mock_event_manager = AsyncMock()
        
        # Initialize settings with test configuration
        self._settings = Settings()
        self._settings.ENVIRONMENT = "test"
        
        # Create NotificationService instance with mocks
        with patch('aioapns.APNs', return_value=self._mock_apns_client), \
             patch('firebase_admin.initialize_app', return_value=self._mock_fcm_client), \
             patch('aioredis.from_url', return_value=self._mock_redis):
            self._notification_service = NotificationService(
                settings=self._settings,
                event_manager=self._mock_event_manager
            )
    
    async def test_send_notification(self):
        """Test sending notification to single user."""
        # Requirement: Push Notification Integration - Cross-platform delivery
        
        # Mock device token retrieval
        self._mock_redis.smembers.return_value = {TEST_DEVICE_TOKEN}
        
        # Test iOS notification
        await self._test_platform_notification(PLATFORM_TYPES['IOS'])
        self._mock_apns_client.send_notification.assert_called_once()
        
        # Test Android notification
        await self._test_platform_notification(PLATFORM_TYPES['ANDROID'])
        assert self._mock_fcm_client.messaging.send_multicast.called
        
        # Test Web notification
        await self._test_platform_notification(PLATFORM_TYPES['WEB'])
        assert self._mock_web_push_client.called
        
        # Verify event publication
        self._mock_event_manager.publish_event.assert_called()
    
    async def test_send_bulk_notification(self):
        """Test sending notifications to multiple users."""
        # Requirement: Alert Management - Bulk notification delivery
        
        test_users = ['user1', 'user2', 'user3']
        test_tokens = {user: f'token-{user}' for user in test_users}
        
        # Mock device token retrieval for multiple users
        self._mock_redis.smembers.side_effect = lambda key: {test_tokens[key.split(':')[1]]}
        
        # Send bulk notification
        result = await self._notification_service.send_bulk_notification(
            user_ids=test_users,
            notification_type=NOTIFICATION_TYPES['BUDGET_ALERT'],
            payload=TEST_NOTIFICATION_PAYLOAD
        )
        
        # Verify bulk delivery attempts
        assert len(result) == len(test_users)
        assert all(isinstance(status, dict) for status in result.values())
        
        # Verify event publication for bulk notification
        self._mock_event_manager.publish_event.assert_called_with(
            'notification.bulk_sent',
            {
                'user_count': len(test_users),
                'type': NOTIFICATION_TYPES['BUDGET_ALERT'],
                'status': result
            }
        )
    
    async def test_register_device(self):
        """Test device registration for notifications."""
        # Requirement: Push Notification Integration - Device registration
        
        # Test successful registration
        self._mock_redis.smembers.return_value = set()
        self._mock_redis.sadd.return_value = True
        
        result = await self._notification_service.register_device(
            user_id=TEST_USER_ID,
            platform=PLATFORM_TYPES['IOS'],
            device_token=TEST_DEVICE_TOKEN
        )
        
        assert result is True
        self._mock_redis.sadd.assert_called_once()
        
        # Test duplicate registration
        self._mock_redis.smembers.return_value = {TEST_DEVICE_TOKEN}
        
        result = await self._notification_service.register_device(
            user_id=TEST_USER_ID,
            platform=PLATFORM_TYPES['IOS'],
            device_token=TEST_DEVICE_TOKEN
        )
        
        assert result is False
        
        # Test invalid platform
        with pytest.raises(ValueError):
            await self._notification_service.register_device(
                user_id=TEST_USER_ID,
                platform='invalid_platform',
                device_token=TEST_DEVICE_TOKEN
            )
    
    async def test_update_preferences(self):
        """Test updating notification preferences."""
        # Requirement: Alert Management - Notification preferences
        
        test_preferences = {
            NOTIFICATION_TYPES['BUDGET_ALERT']: True,
            NOTIFICATION_TYPES['GOAL_MILESTONE']: False
        }
        
        # Test successful preference update
        self._mock_redis.hset.return_value = True
        
        result = await self._notification_service.update_preferences(
            user_id=TEST_USER_ID,
            preferences=test_preferences
        )
        
        assert result is True
        self._mock_redis.hset.assert_called_once()
        
        # Test invalid notification type
        invalid_preferences = {
            'invalid_type': True
        }
        
        with pytest.raises(ValueError):
            await self._notification_service.update_preferences(
                user_id=TEST_USER_ID,
                preferences=invalid_preferences
            )
    
    async def _test_platform_notification(self, platform: str):
        """Helper method to test notification delivery for specific platform."""
        result = await self._notification_service.send_notification(
            user_id=TEST_USER_ID,
            notification_type=NOTIFICATION_TYPES['BUDGET_ALERT'],
            payload=TEST_NOTIFICATION_PAYLOAD,
            platforms=[platform]
        )
        
        assert isinstance(result, dict)
        assert platform in result
        assert isinstance(result[platform], bool)