"""
Service module that manages cross-platform data synchronization, real-time updates, 
and automated transaction imports in the Mint Replica Lite system.

Human Tasks:
1. Configure sync interval limits in production environment
2. Set up monitoring for sync operations and failures
3. Review and adjust sync cursor TTL based on usage patterns
4. Configure alerts for failed sync operations
"""

# Built-in imports
import asyncio
from datetime import datetime
from typing import Dict, List, Any

# Internal imports
from ..core.events import EventManager
from ..core.cache import cache
from .plaid_service import PlaidService

# Global constants
SYNC_CURSOR_PREFIX: str = 'sync_cursor:'
DEFAULT_SYNC_INTERVAL: int = 60  # minutes

class SyncService:
    """
    Service class that manages data synchronization across platforms and automated 
    updates using cursor-based incremental syncing.
    
    Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
    Requirement: Cross-platform Sync - 1.2 Scope/In Scope/Account Management
    """
    
    def __init__(self, plaid_service: PlaidService, event_manager: EventManager):
        """Initialize sync service with required dependencies."""
        self._plaid_service = plaid_service
        self._event_manager = event_manager
        self._sync_cursors: Dict[str, str] = {}
        self._sync_tasks: Dict[str, asyncio.Task] = {}
        
        # Load existing sync states from cache
        self._load_sync_states()
    
    def _load_sync_states(self) -> None:
        """Load existing sync cursors from cache."""
        cursor_keys = cache.get(f"{SYNC_CURSOR_PREFIX}keys") or []
        for key in cursor_keys:
            cursor = cache.get(f"{SYNC_CURSOR_PREFIX}{key}")
            if cursor:
                self._sync_cursors[key] = cursor
    
    def _save_sync_cursor(self, user_id: str, cursor: str) -> None:
        """Save sync cursor to cache."""
        key = f"{user_id}"
        self._sync_cursors[key] = cursor
        cache.set(f"{SYNC_CURSOR_PREFIX}{key}", cursor)
        
        # Update cursor keys set
        cursor_keys = cache.get(f"{SYNC_CURSOR_PREFIX}keys") or []
        if key not in cursor_keys:
            cursor_keys.append(key)
            cache.set(f"{SYNC_CURSOR_PREFIX}keys", cursor_keys)
    
    async def sync_account_data(self, user_id: str, access_token: str) -> Dict[str, Any]:
        """
        Synchronize account data and balances for a user.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Fetch latest account balances
            balances = await self._plaid_service.get_balances(access_token)
            
            # Get cached balances
            cache_key = f"balances:{user_id}"
            cached_balances = cache.get(cache_key)
            
            # Check for changes
            changes_detected = False
            if not cached_balances or balances != cached_balances:
                changes_detected = True
                cache.set(cache_key, balances)
                
                # Publish account update event
                await self._event_manager.publish_event(
                    event_type='account.update',
                    payload={'user_id': user_id, 'balances': balances},
                    user_ids=[user_id]
                )
            
            return {
                'user_id': user_id,
                'balances': balances,
                'changes_detected': changes_detected,
                'sync_time': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            print(f"Account sync error for user {user_id}: {str(e)}")
            raise
    
    async def sync_transactions(self, user_id: str, access_token: str) -> Dict[str, Any]:
        """
        Synchronize new transactions for an account using cursor-based pagination.
        
        Requirement: Transaction Import - 1.2 Scope/In Scope/Financial Tracking
        """
        try:
            # Get last sync cursor
            cursor = self._sync_cursors.get(user_id)
            
            # Sync transactions with cursor
            transactions, next_cursor = await self._plaid_service.sync_transactions(
                access_token=access_token,
                cursor=cursor
            )
            
            # Update sync cursor
            if next_cursor:
                self._save_sync_cursor(user_id, next_cursor)
            
            # Publish events for new transactions
            if transactions:
                await self._event_manager.publish_event(
                    event_type='transaction.create',
                    payload={
                        'user_id': user_id,
                        'transactions': transactions
                    },
                    user_ids=[user_id]
                )
            
            return {
                'user_id': user_id,
                'new_transactions': len(transactions),
                'cursor': next_cursor,
                'sync_time': datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            print(f"Transaction sync error for user {user_id}: {str(e)}")
            raise
    
    async def schedule_sync(
        self,
        user_id: str,
        access_tokens: List[str],
        interval_minutes: int = DEFAULT_SYNC_INTERVAL
    ) -> bool:
        """
        Schedule periodic sync for user accounts.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Validate sync interval
            if interval_minutes < DEFAULT_SYNC_INTERVAL:
                interval_minutes = DEFAULT_SYNC_INTERVAL
            
            # Cancel existing sync task if any
            await self.cancel_sync(user_id)
            
            # Create sync schedule
            schedule = {
                'user_id': user_id,
                'access_tokens': access_tokens,
                'interval': interval_minutes,
                'last_sync': None
            }
            
            # Store schedule in cache
            cache.set(f"sync_schedule:{user_id}", schedule)
            
            # Start sync task
            async def sync_task():
                while True:
                    try:
                        for token in access_tokens:
                            await self.sync_account_data(user_id, token)
                            await self.sync_transactions(user_id, token)
                        
                        schedule['last_sync'] = datetime.utcnow().isoformat()
                        cache.set(f"sync_schedule:{user_id}", schedule)
                        
                        await asyncio.sleep(interval_minutes * 60)
                    except Exception as e:
                        print(f"Periodic sync error for user {user_id}: {str(e)}")
                        await asyncio.sleep(60)  # Retry after 1 minute on error
            
            self._sync_tasks[user_id] = asyncio.create_task(sync_task())
            return True
            
        except Exception as e:
            print(f"Schedule sync error for user {user_id}: {str(e)}")
            return False
    
    async def cancel_sync(self, user_id: str) -> bool:
        """
        Cancel scheduled sync for user accounts.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        try:
            # Cancel sync task if exists
            if user_id in self._sync_tasks:
                self._sync_tasks[user_id].cancel()
                del self._sync_tasks[user_id]
            
            # Remove schedule from cache
            cache.delete(f"sync_schedule:{user_id}")
            
            return True
            
        except Exception as e:
            print(f"Cancel sync error for user {user_id}: {str(e)}")
            return False