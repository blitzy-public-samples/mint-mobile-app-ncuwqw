"""
Test suite for SyncService class that handles data synchronization between the backend and 
financial institutions through Plaid integration.

Human Tasks:
1. Configure test environment variables for Plaid API mocking
2. Set up test database with sample financial data
3. Review and adjust test timeouts for async operations
"""

# pytest: ^7.0.0
# pytest-asyncio: ^0.18.0
import pytest
from unittest.mock import Mock, AsyncMock
from datetime import datetime, timedelta

# Internal imports
from app.services.sync_service import SyncService
from app.services.plaid_service import PlaidService
from app.core.events import EventManager

def pytest_configure(config):
    """Configure pytest for the test suite."""
    # Register asyncio marker for async tests
    config.addinivalue_line(
        "markers", "asyncio: mark test as async"
    )

class TestSyncService:
    """
    Test suite for SyncService functionality including account syncing, transaction syncing,
    and sync scheduling.
    
    Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
    """
    
    def setup_method(self, method):
        """Set up test dependencies before each test."""
        # Create mock PlaidService
        self.plaid_service = Mock(spec=PlaidService)
        self.plaid_service.sync_transactions = AsyncMock()
        self.plaid_service.get_balances = AsyncMock()
        
        # Create mock EventManager
        self.event_manager = Mock(spec=EventManager)
        self.event_manager.publish_event = AsyncMock()
        
        # Initialize SyncService with mocked dependencies
        self.sync_service = SyncService(
            plaid_service=self.plaid_service,
            event_manager=self.event_manager
        )

    @pytest.mark.asyncio
    async def test_sync_account_data(self):
        """
        Test account data synchronization with Plaid integration.
        
        Requirement: Cross-platform Sync - 1.2 Scope/In Scope/Account Management
        """
        # Test data
        user_id = "test_user_123"
        access_token = "test_access_token"
        mock_balances = [
            {
                "account_id": "acc_1",
                "current": 1000.00,
                "available": 950.00,
                "limit": None,
                "last_updated": datetime.utcnow().isoformat()
            }
        ]
        
        # Configure mock responses
        self.plaid_service.get_balances.return_value = mock_balances
        
        # Execute sync
        result = await self.sync_service.sync_account_data(user_id, access_token)
        
        # Verify Plaid service called
        self.plaid_service.get_balances.assert_called_once_with(access_token)
        
        # Verify event published
        self.event_manager.publish_event.assert_called_once_with(
            event_type='account.update',
            payload={'user_id': user_id, 'balances': mock_balances},
            user_ids=[user_id]
        )
        
        # Verify result
        assert result['user_id'] == user_id
        assert result['balances'] == mock_balances
        assert result['changes_detected'] is True
        assert 'sync_time' in result

    @pytest.mark.asyncio
    async def test_sync_transactions(self):
        """
        Test transaction synchronization with cursor-based pagination.
        
        Requirement: Transaction Import - 1.2 Scope/In Scope/Financial Tracking
        """
        # Test data
        user_id = "test_user_123"
        access_token = "test_access_token"
        mock_transactions = [
            {
                "id": "tx_1",
                "account_id": "acc_1",
                "amount": 50.00,
                "date": "2023-01-01",
                "name": "Test Transaction",
                "merchant_name": "Test Merchant",
                "category": ["Food", "Restaurants"],
                "pending": False
            }
        ]
        mock_cursor = "mock_cursor_123"
        
        # Configure mock responses
        self.plaid_service.sync_transactions.return_value = (mock_transactions, mock_cursor)
        
        # Execute sync
        result = await self.sync_service.sync_transactions(user_id, access_token)
        
        # Verify Plaid service called
        self.plaid_service.sync_transactions.assert_called_once_with(
            access_token=access_token,
            cursor=None
        )
        
        # Verify event published
        self.event_manager.publish_event.assert_called_once_with(
            event_type='transaction.create',
            payload={
                'user_id': user_id,
                'transactions': mock_transactions
            },
            user_ids=[user_id]
        )
        
        # Verify result
        assert result['user_id'] == user_id
        assert result['new_transactions'] == len(mock_transactions)
        assert result['cursor'] == mock_cursor
        assert 'sync_time' in result

    @pytest.mark.asyncio
    async def test_schedule_sync(self):
        """
        Test sync scheduling functionality with interval validation.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        # Test data
        user_id = "test_user_123"
        access_tokens = ["token_1", "token_2"]
        interval_minutes = 120
        
        # Execute schedule creation
        result = await self.sync_service.schedule_sync(
            user_id=user_id,
            access_tokens=access_tokens,
            interval_minutes=interval_minutes
        )
        
        # Verify schedule created
        assert result is True
        assert user_id in self.sync_service._sync_tasks
        
        # Verify existing schedule cancelled before new one created
        await self.sync_service.cancel_sync(user_id)
        assert user_id not in self.sync_service._sync_tasks

    def test_cancel_sync(self):
        """
        Test sync cancellation functionality.
        
        Requirement: Real-time Synchronization - 1.1 System Overview/Backend Services
        """
        # Test data
        user_id = "test_user_123"
        
        # Create mock sync task
        mock_task = Mock()
        mock_task.cancel = Mock()
        self.sync_service._sync_tasks[user_id] = mock_task
        
        # Execute cancellation
        result = self.sync_service.cancel_sync(user_id)
        
        # Verify task cancelled
        mock_task.cancel.assert_called_once()
        assert user_id not in self.sync_service._sync_tasks
        assert result is True