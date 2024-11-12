"""
Core event management module implementing event-driven architecture for Mint Replica Lite backend.

Human Tasks:
1. Configure Redis pub/sub channels in production environment
2. Set up monitoring for event delivery and performance
3. Review and adjust event TTL based on production usage patterns
4. Configure event persistence storage in production
5. Set up alerts for event delivery failures
"""

# asyncio: built-in
# json: built-in
# typing: built-in

import asyncio
import json
from typing import Dict, Set, List, Optional

from .websockets import WebSocketManager
from .cache import RedisCache
from .auth import AuthManager

# Event type constants for system-wide event handling
# Requirement: Event-Driven Architecture - 2.5.3 Scalability Architecture
EVENT_TYPES: Dict[str, str] = {
    'ACCOUNT_UPDATE': 'account.update',
    'TRANSACTION_CREATE': 'transaction.create',
    'BUDGET_UPDATE': 'budget.update',
    'GOAL_UPDATE': 'goal.update',
    'INVESTMENT_UPDATE': 'investment.update'
}

# Time-to-live for events in Redis cache (1 hour)
EVENT_TTL: int = 3600

# Redis channel prefix for event distribution
EVENT_CHANNEL_PREFIX: str = 'events'

def create_event_channel(event_type: str) -> str:
    """
    Generate Redis channel name for event type.
    
    Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows
    """
    if event_type not in EVENT_TYPES.values():
        raise ValueError(f"Invalid event type: {event_type}")
    return f"{EVENT_CHANNEL_PREFIX}:{event_type}"

class EventManager:
    """
    Manages event publishing, subscription, and distribution across the system.
    
    Requirement: Event-Driven Architecture - 2.5.3 Scalability Architecture
    """
    
    def __init__(self, ws_manager: WebSocketManager, cache: RedisCache, auth_manager: AuthManager):
        """Initialize event manager with required dependencies."""
        # WebSocket manager for real-time event broadcasting
        self._ws_manager = ws_manager
        
        # Redis cache for event persistence and pub/sub
        self._cache = cache
        
        # Auth manager for subscription validation
        self._auth_manager = auth_manager
        
        # Subscription registry mapping user IDs to event types
        self._subscriptions: Dict[str, Set[str]] = {}
        
        # Start Redis subscriber task
        asyncio.create_task(self._start_redis_subscriber())

    async def publish_event(self, event_type: str, payload: dict, user_ids: Optional[List[str]] = None) -> bool:
        """
        Publish event to all subscribers through Redis and WebSocket.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Validate event type
            if event_type not in EVENT_TYPES.values():
                raise ValueError(f"Invalid event type: {event_type}")
            
            # Format event message
            event_message = {
                'type': event_type,
                'payload': payload,
                'timestamp': asyncio.get_event_loop().time(),
                'target_users': user_ids
            }
            
            # Store event in Redis cache
            channel = create_event_channel(event_type)
            await self._cache.set(
                key=channel,
                value=json.dumps(event_message),
                ttl=EVENT_TTL
            )
            
            # Broadcast to WebSocket subscribers
            await self._ws_manager.broadcast(
                event_type=event_type,
                message=payload,
                user_ids=user_ids
            )
            
            return True
            
        except Exception as e:
            print(f"Event publish error: {str(e)}")
            return False

    async def subscribe(self, user_id: str, event_types: List[str]) -> bool:
        """
        Subscribe user to specific event types.
        
        Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows
        """
        try:
            # Verify user token
            if not await self._auth_manager.verify_token(user_id):
                return False
            
            # Validate event types
            if not all(event_type in EVENT_TYPES.values() for event_type in event_types):
                raise ValueError("Invalid event type in subscription request")
            
            # Register subscriptions
            if user_id not in self._subscriptions:
                self._subscriptions[user_id] = set()
            self._subscriptions[user_id].update(event_types)
            
            # Subscribe to Redis channels
            for event_type in event_types:
                channel = create_event_channel(event_type)
                await self._cache.set(
                    key=f"sub:{user_id}:{event_type}",
                    value=json.dumps({
                        'user_id': user_id,
                        'event_type': event_type,
                        'subscribed_at': asyncio.get_event_loop().time()
                    }),
                    ttl=EVENT_TTL
                )
            
            return True
            
        except Exception as e:
            print(f"Subscription error: {str(e)}")
            return False

    async def unsubscribe(self, user_id: str, event_types: Optional[List[str]] = None) -> bool:
        """
        Unsubscribe user from event types.
        
        Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows
        """
        try:
            # Verify user token
            if not await self._auth_manager.verify_token(user_id):
                return False
            
            if user_id not in self._subscriptions:
                return True
            
            # If no event types specified, unsubscribe from all
            types_to_remove = event_types if event_types else list(self._subscriptions[user_id])
            
            # Remove subscriptions
            for event_type in types_to_remove:
                self._subscriptions[user_id].discard(event_type)
                # Remove from Redis
                await self._cache.delete(f"sub:{user_id}:{event_type}")
            
            # Clean up user entry if no subscriptions remain
            if not self._subscriptions[user_id]:
                del self._subscriptions[user_id]
            
            return True
            
        except Exception as e:
            print(f"Unsubscribe error: {str(e)}")
            return False

    async def handle_event(self, channel: str, message: str) -> None:
        """
        Process incoming events from Redis.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Parse event message
            event_data = json.loads(message)
            event_type = event_data.get('type')
            target_users = event_data.get('target_users')
            
            if not event_type:
                return
            
            # Get subscribers for this event type
            subscribers = set()
            for user_id, subscribed_types in self._subscriptions.items():
                if event_type in subscribed_types:
                    # Check if event is targeted
                    if not target_users or user_id in target_users:
                        subscribers.add(user_id)
            
            # Distribute to subscribers via WebSocket
            if subscribers:
                await self._ws_manager.broadcast(
                    event_type=event_type,
                    message=event_data['payload'],
                    user_ids=list(subscribers)
                )
                
        except Exception as e:
            print(f"Event handling error: {str(e)}")

    async def _start_redis_subscriber(self):
        """Initialize Redis pub/sub subscriber for event distribution."""
        while True:
            try:
                # Subscribe to all event channels
                for event_type in EVENT_TYPES.values():
                    channel = create_event_channel(event_type)
                    message = await self._cache.get(channel)
                    
                    if message:
                        await self.handle_event(channel, message)
                
                await asyncio.sleep(0.1)  # Small delay between checks
                
            except Exception as e:
                print(f"Redis subscriber error: {str(e)}")
                await asyncio.sleep(5)  # Longer delay on error