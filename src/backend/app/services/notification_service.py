"""
Notification service for Mint Replica Lite application.

Human Tasks:
1. Set up Apple Developer account and configure APNS certificates
2. Create Firebase project and obtain FCM credentials
3. Configure VAPID keys for Web Push notifications
4. Set up Redis instance for notification queuing
5. Configure AWS credentials for cloud services
"""

# Library versions:
# aioapns: ^2.1.0
# firebase-admin: ^5.0.0
# pywebpush: ^1.14.0
# aioredis: ^2.0.0

import asyncio
import json
from typing import Dict, List, Any, Optional

import aioapns
import firebase_admin
from firebase_admin import credentials, messaging
from pywebpush import webpush, WebPushException
import aioredis

from app.core.config import Settings, get_aws_settings
from app.core.logging import get_logger
from app.core.events import EventManager

# Global constants for notification types and platforms
NOTIFICATION_TYPES: Dict[str, str] = {
    'BUDGET_ALERT': 'budget.alert',
    'GOAL_MILESTONE': 'goal.milestone',
    'ACCOUNT_SYNC': 'account.sync',
    'SECURITY_ALERT': 'security.alert'
}

PLATFORM_TYPES: Dict[str, str] = {
    'IOS': 'ios',
    'ANDROID': 'android',
    'WEB': 'web'
}

MAX_RETRIES: int = 3

def format_notification(platform: str, notification_type: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Format notification payload for specific platform.
    
    Requirement: Push Notification Integration - Platform-specific formatting
    """
    if platform not in PLATFORM_TYPES.values():
        raise ValueError(f"Invalid platform type: {platform}")
    
    if notification_type not in NOTIFICATION_TYPES.values():
        raise ValueError(f"Invalid notification type: {notification_type}")
    
    formatted_payload = {
        'type': notification_type,
        'timestamp': asyncio.get_event_loop().time()
    }
    
    if platform == PLATFORM_TYPES['IOS']:
        # Format for APNS
        formatted_payload.update({
            'aps': {
                'alert': {
                    'title': payload.get('title', ''),
                    'body': payload.get('message', ''),
                },
                'sound': 'default',
                'badge': payload.get('badge', 1),
                'category': notification_type,
                'content-available': 1
            },
            'data': payload.get('data', {})
        })
    
    elif platform == PLATFORM_TYPES['ANDROID']:
        # Format for FCM
        formatted_payload.update({
            'notification': {
                'title': payload.get('title', ''),
                'body': payload.get('message', ''),
            },
            'data': {
                'type': notification_type,
                **payload.get('data', {})
            },
            'android': {
                'priority': 'high',
                'notification': {
                    'sound': 'default',
                    'click_action': 'FLUTTER_NOTIFICATION_CLICK'
                }
            }
        })
    
    elif platform == PLATFORM_TYPES['WEB']:
        # Format for Web Push
        formatted_payload.update({
            'notification': {
                'title': payload.get('title', ''),
                'body': payload.get('message', ''),
                'icon': payload.get('icon', '/icon.png'),
                'badge': payload.get('badge', '/badge.png'),
                'data': payload.get('data', {})
            }
        })
    
    return formatted_payload

class NotificationService:
    """
    Manages cross-platform notification delivery and preferences.
    
    Requirement: Push Notification Integration - Cross-platform notification management
    """
    
    def __init__(self, settings: Settings, event_manager: EventManager):
        """Initialize notification service with platform-specific clients."""
        self._logger = get_logger(__name__)
        self._event_manager = event_manager
        
        # Initialize Redis client for device token storage
        aws_settings = settings.get_aws_settings()
        self._redis = aioredis.from_url(
            settings.REDIS_URL,
            encoding='utf-8',
            decode_responses=True
        )
        
        # Initialize APNS client
        self._apns_client = aioapns.APNs(
            key=aws_settings['apns_key_path'],
            key_id=aws_settings['apns_key_id'],
            team_id=aws_settings['apns_team_id'],
            topic=aws_settings['apns_topic'],
            use_sandbox=settings.ENVIRONMENT != 'production'
        )
        
        # Initialize Firebase client
        cred = credentials.Certificate(aws_settings['fcm_credentials_path'])
        self._fcm_client = firebase_admin.initialize_app(cred)
        
        # Initialize Web Push client
        self._web_push_client = {
            'vapid_private_key': aws_settings['vapid_private_key'],
            'vapid_claims': {
                'sub': f"mailto:{aws_settings['vapid_contact_email']}"
            }
        }
    
    async def send_notification(
        self,
        user_id: str,
        notification_type: str,
        payload: Dict[str, Any],
        platforms: Optional[List[str]] = None
    ) -> Dict[str, bool]:
        """
        Send notification to specified user across their registered platforms.
        
        Requirement: Real-time Updates - Event-driven notification delivery
        """
        if notification_type not in NOTIFICATION_TYPES.values():
            raise ValueError(f"Invalid notification type: {notification_type}")
        
        delivery_status = {}
        retry_count = 0
        
        while retry_count < MAX_RETRIES:
            try:
                # Get user's device tokens
                device_tokens = await self._get_user_devices(user_id)
                
                if not device_tokens:
                    self._logger.warning(f"No registered devices for user {user_id}")
                    return {}
                
                # Filter platforms if specified
                if platforms:
                    device_tokens = {k: v for k, v in device_tokens.items() if k in platforms}
                
                # Send to each platform
                for platform, tokens in device_tokens.items():
                    formatted_payload = format_notification(platform, notification_type, payload)
                    
                    if platform == PLATFORM_TYPES['IOS']:
                        for token in tokens:
                            try:
                                await self._apns_client.send_notification(token, formatted_payload)
                                delivery_status[platform] = True
                            except Exception as e:
                                self._logger.error(f"APNS delivery failed: {str(e)}")
                                delivery_status[platform] = False
                    
                    elif platform == PLATFORM_TYPES['ANDROID']:
                        message = messaging.MulticastMessage(
                            tokens=tokens,
                            data=formatted_payload['data'],
                            notification=messaging.Notification(
                                title=formatted_payload['notification']['title'],
                                body=formatted_payload['notification']['body']
                            )
                        )
                        response = messaging.send_multicast(message)
                        delivery_status[platform] = response.success_count > 0
                    
                    elif platform == PLATFORM_TYPES['WEB']:
                        for subscription in tokens:
                            try:
                                webpush(
                                    subscription_info=json.loads(subscription),
                                    data=json.dumps(formatted_payload),
                                    vapid_private_key=self._web_push_client['vapid_private_key'],
                                    vapid_claims=self._web_push_client['vapid_claims']
                                )
                                delivery_status[platform] = True
                            except WebPushException as e:
                                self._logger.error(f"Web Push delivery failed: {str(e)}")
                                delivery_status[platform] = False
                
                # Publish notification event
                await self._event_manager.publish_event(
                    'notification.sent',
                    {
                        'user_id': user_id,
                        'type': notification_type,
                        'status': delivery_status
                    }
                )
                
                break
            
            except Exception as e:
                self._logger.error(f"Notification delivery attempt {retry_count + 1} failed: {str(e)}")
                retry_count += 1
                if retry_count < MAX_RETRIES:
                    await asyncio.sleep(1 * retry_count)  # Exponential backoff
        
        return delivery_status
    
    async def send_bulk_notification(
        self,
        user_ids: List[str],
        notification_type: str,
        payload: Dict[str, Any]
    ) -> Dict[str, Dict[str, bool]]:
        """
        Send notification to multiple users.
        
        Requirement: Alert Management - Bulk notification delivery
        """
        if notification_type not in NOTIFICATION_TYPES.values():
            raise ValueError(f"Invalid notification type: {notification_type}")
        
        delivery_results = {}
        
        # Group users by platform for efficient delivery
        platform_groups: Dict[str, List[str]] = {
            PLATFORM_TYPES['IOS']: [],
            PLATFORM_TYPES['ANDROID']: [],
            PLATFORM_TYPES['WEB']: []
        }
        
        for user_id in user_ids:
            devices = await self._get_user_devices(user_id)
            for platform, tokens in devices.items():
                if tokens:
                    platform_groups[platform].append(user_id)
        
        # Send notifications in parallel for each platform
        tasks = []
        for platform, platform_users in platform_groups.items():
            if platform_users:
                formatted_payload = format_notification(platform, notification_type, payload)
                tasks.append(
                    self._send_platform_bulk_notification(
                        platform,
                        platform_users,
                        formatted_payload
                    )
                )
        
        # Wait for all platform deliveries to complete
        platform_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Combine results
        for platform, results in zip(platform_groups.keys(), platform_results):
            if isinstance(results, Exception):
                self._logger.error(f"Bulk notification failed for {platform}: {str(results)}")
                continue
            delivery_results.update(results)
        
        # Publish bulk notification event
        await self._event_manager.publish_event(
            'notification.bulk_sent',
            {
                'user_count': len(user_ids),
                'type': notification_type,
                'status': delivery_results
            }
        )
        
        return delivery_results
    
    async def register_device(self, user_id: str, platform: str, device_token: str) -> bool:
        """
        Register user device for notifications.
        
        Requirement: Push Notification Integration - Device registration
        """
        if platform not in PLATFORM_TYPES.values():
            raise ValueError(f"Invalid platform type: {platform}")
        
        try:
            # Store device token in Redis
            key = f"device_tokens:{user_id}:{platform}"
            tokens = await self._redis.smembers(key) or set()
            
            if device_token not in tokens:
                await self._redis.sadd(key, device_token)
                
                # Log device registration
                self._logger.info(
                    "Device registered",
                    extra={
                        'user_id': user_id,
                        'platform': platform
                    }
                )
                
                # Test device registration
                test_payload = {
                    'title': 'Registration Successful',
                    'message': 'You will now receive notifications',
                    'data': {'type': 'registration'}
                }
                await self.send_notification(
                    user_id,
                    NOTIFICATION_TYPES['SECURITY_ALERT'],
                    test_payload,
                    [platform]
                )
                
                return True
            
            return False
            
        except Exception as e:
            self._logger.error(f"Device registration failed: {str(e)}")
            return False
    
    async def update_preferences(self, user_id: str, preferences: Dict[str, bool]) -> bool:
        """
        Update user notification preferences.
        
        Requirement: Alert Management - Notification preferences
        """
        try:
            # Validate preference settings
            invalid_types = set(preferences.keys()) - set(NOTIFICATION_TYPES.values())
            if invalid_types:
                raise ValueError(f"Invalid notification types: {invalid_types}")
            
            # Store preferences in Redis
            key = f"notification_preferences:{user_id}"
            await self._redis.hset(key, mapping=preferences)
            
            # Log preference update
            self._logger.info(
                "Notification preferences updated",
                extra={
                    'user_id': user_id,
                    'preferences': preferences
                }
            )
            
            return True
            
        except Exception as e:
            self._logger.error(f"Preference update failed: {str(e)}")
            return False
    
    async def _get_user_devices(self, user_id: str) -> Dict[str, List[str]]:
        """Get user's registered devices for each platform."""
        devices = {}
        for platform in PLATFORM_TYPES.values():
            key = f"device_tokens:{user_id}:{platform}"
            tokens = await self._redis.smembers(key)
            if tokens:
                devices[platform] = list(tokens)
        return devices
    
    async def _send_platform_bulk_notification(
        self,
        platform: str,
        user_ids: List[str],
        payload: Dict[str, Any]
    ) -> Dict[str, Dict[str, bool]]:
        """Send bulk notifications for a specific platform."""
        results = {}
        
        if platform == PLATFORM_TYPES['IOS']:
            for user_id in user_ids:
                devices = await self._get_user_devices(user_id)
                if platform in devices:
                    success = False
                    for token in devices[platform]:
                        try:
                            await self._apns_client.send_notification(token, payload)
                            success = True
                        except Exception as e:
                            self._logger.error(f"APNS bulk delivery failed for {user_id}: {str(e)}")
                    results[user_id] = {platform: success}
        
        elif platform == PLATFORM_TYPES['ANDROID']:
            all_tokens = []
            token_to_user = {}
            for user_id in user_ids:
                devices = await self._get_user_devices(user_id)
                if platform in devices:
                    for token in devices[platform]:
                        all_tokens.append(token)
                        token_to_user[token] = user_id
            
            if all_tokens:
                message = messaging.MulticastMessage(
                    tokens=all_tokens,
                    data=payload['data'],
                    notification=messaging.Notification(
                        title=payload['notification']['title'],
                        body=payload['notification']['body']
                    )
                )
                response = messaging.send_multicast(message)
                for idx, result in enumerate(response.responses):
                    user_id = token_to_user[all_tokens[idx]]
                    results[user_id] = {platform: result.success}
        
        elif platform == PLATFORM_TYPES['WEB']:
            for user_id in user_ids:
                devices = await self._get_user_devices(user_id)
                if platform in devices:
                    success = False
                    for subscription in devices[platform]:
                        try:
                            webpush(
                                subscription_info=json.loads(subscription),
                                data=json.dumps(payload),
                                vapid_private_key=self._web_push_client['vapid_private_key'],
                                vapid_claims=self._web_push_client['vapid_claims']
                            )
                            success = True
                        except WebPushException as e:
                            self._logger.error(f"Web Push bulk delivery failed for {user_id}: {str(e)}")
                    results[user_id] = {platform: success}
        
        return results