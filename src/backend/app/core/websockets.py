"""
WebSocket management module for Mint Replica Lite backend application.

Human Tasks:
1. Configure Redis pub/sub channels in production environment
2. Set up monitoring for WebSocket connections and performance
3. Review and adjust connection limits based on load testing results
4. Configure WebSocket SSL/TLS settings in production
5. Set up alerts for connection pool thresholds
"""

# fastapi: ^0.68.0
# websockets: ^10.0
# json: built-in
# asyncio: built-in

import json
import asyncio
from typing import Dict, Set, List, Optional
from datetime import datetime
from fastapi import WebSocket
from websockets.exceptions import ConnectionClosed

from ..core.auth import AuthManager
from ..core.cache import RedisCache

# Global constants for WebSocket management
PING_INTERVAL = 30  # Seconds between ping messages
PING_TIMEOUT = 10  # Seconds to wait for pong response
MAX_CONNECTIONS_PER_USER = 5  # Maximum concurrent connections per user
CONNECTION_PREFIX = 'ws_conn'  # Redis key prefix for connection state
EVENT_CHANNEL_PREFIX = 'ws_events'  # Redis pub/sub channel prefix

class WebSocketManager:
    """
    Manages WebSocket connections, client sessions, and message broadcasting.
    
    Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows/Distribution
    """
    
    def __init__(self, cache: RedisCache, auth_manager: AuthManager):
        """Initialize WebSocket manager with dependencies."""
        # Connection registry mapping user IDs to sets of WebSocket connections
        self._connections: Dict[str, Set[WebSocket]] = {}
        
        # Redis cache for connection state and pub/sub
        self._cache = cache
        
        # Authentication manager for token verification
        self._auth_manager = auth_manager
        
        # Subscription registry mapping user IDs to event types
        self._subscriptions: Dict[str, Set[str]] = {}
        
        # Start Redis subscriber task
        asyncio.create_task(self._start_redis_subscriber())
        
        # Start connection monitoring task
        asyncio.create_task(self._monitor_connections())

    async def connect(self, websocket: WebSocket, token: str) -> bool:
        """
        Handle new WebSocket connection with authentication.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Verify JWT token
            payload = self._auth_manager.verify_token(token)
            user_id = payload.get('sub')
            
            if not user_id:
                return False
                
            # Check connection limit
            if user_id in self._connections and \
               len(self._connections[user_id]) >= MAX_CONNECTIONS_PER_USER:
                return False
                
            # Generate unique connection ID
            conn_id = create_connection_id(user_id)
            
            # Accept WebSocket connection
            await websocket.accept()
            
            # Register connection
            if user_id not in self._connections:
                self._connections[user_id] = set()
            self._connections[user_id].add(websocket)
            
            # Store connection state in Redis
            await self._cache.set(
                f"{CONNECTION_PREFIX}:{conn_id}",
                {
                    'user_id': user_id,
                    'connected_at': datetime.utcnow().isoformat(),
                    'subscriptions': []
                }
            )
            
            # Start heartbeat monitoring
            asyncio.create_task(self._monitor_heartbeat(websocket, user_id))
            
            return True
            
        except Exception as e:
            print(f"WebSocket connection error: {str(e)}")
            return False

    async def disconnect(self, websocket: WebSocket, user_id: str) -> bool:
        """
        Handle WebSocket disconnection and cleanup.
        
        Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows/Distribution
        """
        try:
            # Remove from connection registry
            if user_id in self._connections:
                self._connections[user_id].remove(websocket)
                if not self._connections[user_id]:
                    del self._connections[user_id]
                    
            # Clean up subscriptions
            if user_id in self._subscriptions:
                del self._subscriptions[user_id]
                
            # Remove connection state from Redis
            conn_id = create_connection_id(user_id)
            await self._cache.delete(f"{CONNECTION_PREFIX}:{conn_id}")
            
            # Close WebSocket connection
            await websocket.close()
            
            return True
            
        except Exception as e:
            print(f"WebSocket disconnection error: {str(e)}")
            return False

    async def broadcast(self, event_type: str, message: dict, user_ids: Optional[List[str]] = None) -> bool:
        """
        Broadcast message to connected clients through Redis.
        
        Requirement: Push Notifications - 2.1 High-Level Architecture Overview/External Services
        """
        try:
            # Format message payload
            payload = {
                'event': event_type,
                'data': message,
                'timestamp': datetime.utcnow().isoformat()
            }
            
            # Add target user IDs if specified
            if user_ids:
                payload['user_ids'] = user_ids
                
            # Publish to Redis event channel
            channel = f"{EVENT_CHANNEL_PREFIX}:{event_type}"
            await self._cache.set(
                channel,
                json.dumps(payload),
                ttl=60  # Event expires after 60 seconds
            )
            
            return True
            
        except Exception as e:
            print(f"Broadcast error: {str(e)}")
            return False

    async def subscribe(self, websocket: WebSocket, user_id: str, event_types: List[str]) -> bool:
        """
        Subscribe client to event types with Redis pub/sub.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Validate event types
            valid_events = {'transaction', 'budget', 'goal', 'notification'}
            if not all(event in valid_events for event in event_types):
                return False
                
            # Register subscriptions
            if user_id not in self._subscriptions:
                self._subscriptions[user_id] = set()
            self._subscriptions[user_id].update(event_types)
            
            # Store subscription state in Redis
            conn_id = create_connection_id(user_id)
            await self._cache.set(
                f"{CONNECTION_PREFIX}:{conn_id}",
                {
                    'user_id': user_id,
                    'subscriptions': list(self._subscriptions[user_id])
                }
            )
            
            return True
            
        except Exception as e:
            print(f"Subscription error: {str(e)}")
            return False

    async def _start_redis_subscriber(self):
        """Initialize Redis pub/sub subscriber for event distribution."""
        while True:
            try:
                # Subscribe to all event channels
                channels = await self._cache.get(f"{EVENT_CHANNEL_PREFIX}:*")
                
                if channels:
                    for channel in channels:
                        message = await self._cache.get(channel)
                        if message:
                            payload = json.loads(message)
                            await self._distribute_message(payload)
                            
                await asyncio.sleep(0.1)  # Small delay between checks
                
            except Exception as e:
                print(f"Redis subscriber error: {str(e)}")
                await asyncio.sleep(5)  # Longer delay on error

    async def _distribute_message(self, payload: dict):
        """Distribute message to subscribed clients."""
        event_type = payload.get('event')
        user_ids = payload.get('user_ids')
        
        if not event_type:
            return
            
        for user_id, connections in self._connections.items():
            # Check if user should receive message
            if user_ids and user_id not in user_ids:
                continue
                
            # Check if user is subscribed to event type
            if user_id in self._subscriptions and \
               event_type in self._subscriptions[user_id]:
                # Send to all user's connections
                for websocket in connections:
                    try:
                        await websocket.send_json(payload)
                    except ConnectionClosed:
                        await self.disconnect(websocket, user_id)

    async def _monitor_heartbeat(self, websocket: WebSocket, user_id: str):
        """Monitor WebSocket connection with ping/pong messages."""
        while True:
            try:
                await asyncio.sleep(PING_INTERVAL)
                await websocket.send_json({'type': 'ping'})
                
                # Wait for pong response
                try:
                    await asyncio.wait_for(
                        websocket.receive_json(),
                        timeout=PING_TIMEOUT
                    )
                except asyncio.TimeoutError:
                    await self.disconnect(websocket, user_id)
                    break
                    
            except ConnectionClosed:
                await self.disconnect(websocket, user_id)
                break
            except Exception as e:
                print(f"Heartbeat error: {str(e)}")
                await self.disconnect(websocket, user_id)
                break

    async def _monitor_connections(self):
        """Monitor and clean up stale connections."""
        while True:
            try:
                await asyncio.sleep(60)  # Check every minute
                
                # Get all connection keys
                conn_keys = await self._cache.get(f"{CONNECTION_PREFIX}:*")
                
                if conn_keys:
                    for key in conn_keys:
                        conn_data = await self._cache.get(key)
                        if conn_data:
                            user_id = conn_data.get('user_id')
                            
                            # Check if user still has active connections
                            if user_id not in self._connections:
                                await self._cache.delete(key)
                                
            except Exception as e:
                print(f"Connection monitoring error: {str(e)}")
                await asyncio.sleep(5)

def create_connection_id(user_id: str) -> str:
    """
    Generate unique connection identifier.
    
    Requirement: Real-time Data Flows - 3.3.3 Real-time Data Flows/Distribution
    """
    timestamp = datetime.utcnow().strftime('%Y%m%d%H%M%S%f')
    return f"{CONNECTION_PREFIX}:{user_id}:{timestamp}"