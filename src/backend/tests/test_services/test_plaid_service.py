"""
Test suite for Plaid service integration verifying financial account aggregation,
transaction syncing, and real-time balance updates.

Human Tasks:
1. Configure test environment variables for Plaid sandbox credentials
2. Set up mock Plaid responses for testing
3. Review test coverage and add additional test cases if needed
4. Configure CI/CD pipeline to run tests in sandbox environment
"""

# pytest: ^7.0.0
# pytest-asyncio: ^0.18.0
# pytest-mock: ^3.6.1
import pytest
from datetime import datetime, timedelta
import json
from typing import Dict, List

from app.services.plaid_service import PlaidService
from app.core.config import Settings
from app.core.encryption import EncryptionManager

# Test constants
TEST_USER_ID = "test_user_123"
TEST_ACCESS_TOKEN = "test_access_token"
TEST_PUBLIC_TOKEN = "test_public_token"

@pytest.mark.asyncio
class TestPlaidService:
    """
    Test class for PlaidService functionality with mocked Plaid API and encryption.
    
    Requirement: Financial Account Aggregation Testing
    Location: 1.2 Scope/In Scope/Account Management
    """
    
    @pytest.fixture
    async def settings(self) -> Settings:
        """Test settings fixture with Plaid configuration."""
        return Settings(
            PLAID_CLIENT_ID="test_client_id",
            PLAID_SECRET="test_secret",
            PLAID_ENVIRONMENT="sandbox"
        )
    
    @pytest.fixture
    async def encryption_manager(self) -> EncryptionManager:
        """Mock encryption manager fixture."""
        manager = EncryptionManager()
        # Mock encryption/decryption methods
        manager.encrypt_field = lambda x: {
            'ciphertext': b'encrypted',
            'nonce': b'nonce',
            'tag': b'tag'
        }
        manager.decrypt_field = lambda x: TEST_ACCESS_TOKEN.encode()
        return manager
    
    @pytest.fixture
    async def plaid_service(self, settings: Settings, encryption_manager: EncryptionManager) -> PlaidService:
        """Fixture for PlaidService instance with mocked dependencies."""
        return PlaidService(settings, encryption_manager)

    @pytest.mark.asyncio
    async def test_plaid_service_initialization(self, settings: Settings, encryption_manager: EncryptionManager):
        """
        Test proper initialization of PlaidService with configuration.
        
        Requirement: Security Testing
        Location: 6.2 Data Security/6.2.2 Sensitive Data Handling
        """
        service = PlaidService(settings, encryption_manager)
        
        assert service._client is not None
        assert service._encryption_manager == encryption_manager
        assert service._logger is not None
        assert service._http_session is None

    @pytest.mark.asyncio
    async def test_create_link_token(self, plaid_service: PlaidService, mocker):
        """
        Test creation of Plaid Link token for account linking.
        
        Requirement: Financial Account Aggregation Testing
        Location: 1.2 Scope/In Scope/Account Management
        """
        mock_response = mocker.MagicMock()
        mock_response.link_token = "test_link_token"
        mocker.patch.object(plaid_service._client, 'link_token_create', return_value=mock_response)
        
        link_token = await plaid_service.create_link_token(
            TEST_USER_ID,
            ["transactions"]
        )
        
        assert link_token == "test_link_token"
        plaid_service._client.link_token_create.assert_called_once()

    @pytest.mark.asyncio
    async def test_exchange_public_token(self, plaid_service: PlaidService, mocker):
        """
        Test exchange of public token for access token.
        
        Requirement: Security Testing
        Location: 6.2 Data Security/6.2.2 Sensitive Data Handling
        """
        mock_response = mocker.MagicMock()
        mock_response.access_token = TEST_ACCESS_TOKEN
        mock_response.item_id = "test_item_id"
        mocker.patch.object(plaid_service._client, 'item_public_token_exchange', return_value=mock_response)
        
        result = await plaid_service.exchange_public_token(TEST_PUBLIC_TOKEN)
        
        assert "access_token" in result
        assert "item_id" in result
        assert result["item_id"] == "test_item_id"
        plaid_service._client.item_public_token_exchange.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_accounts(self, plaid_service: PlaidService, mocker):
        """
        Test retrieval of account information.
        
        Requirement: Financial Account Aggregation Testing
        Location: 1.2 Scope/In Scope/Account Management
        """
        mock_account = mocker.MagicMock()
        mock_account.account_id = "test_account_id"
        mock_account.name = "Test Account"
        mock_account.type = "depository"
        mock_account.subtype = "checking"
        mock_account.mask = "1234"
        mock_account.balances.current = 1000.0
        mock_account.balances.available = 900.0
        mock_account.balances.limit = None
        
        mock_response = mocker.MagicMock()
        mock_response.accounts = [mock_account]
        mocker.patch.object(plaid_service._client, 'accounts_get', return_value=mock_response)
        
        accounts = await plaid_service.get_accounts(json.dumps({"access_token": TEST_ACCESS_TOKEN}))
        
        assert len(accounts) == 1
        assert accounts[0]["id"] == "test_account_id"
        assert accounts[0]["type"] == "depository"
        assert accounts[0]["balances"]["current"] == 1000.0

    @pytest.mark.asyncio
    async def test_get_transactions(self, plaid_service: PlaidService, mocker):
        """
        Test retrieval of transaction data.
        
        Requirement: Transaction Management Testing
        Location: 1.2 Scope/In Scope/Financial Tracking
        """
        mock_transaction = mocker.MagicMock()
        mock_transaction.transaction_id = "test_tx_id"
        mock_transaction.account_id = "test_account_id"
        mock_transaction.amount = 50.0
        mock_transaction.date = "2023-01-01"
        mock_transaction.name = "Test Transaction"
        mock_transaction.merchant_name = "Test Merchant"
        mock_transaction.category = ["Food", "Restaurants"]
        mock_transaction.pending = False
        
        mock_response = mocker.MagicMock()
        mock_response.transactions = [mock_transaction]
        mocker.patch.object(plaid_service._client, 'transactions_get', return_value=mock_response)
        
        start_date = datetime.now() - timedelta(days=30)
        end_date = datetime.now()
        
        transactions = await plaid_service.get_transactions(
            json.dumps({"access_token": TEST_ACCESS_TOKEN}),
            start_date,
            end_date
        )
        
        assert len(transactions) == 1
        assert transactions[0]["id"] == "test_tx_id"
        assert transactions[0]["amount"] == 50.0
        assert transactions[0]["merchant_name"] == "Test Merchant"

    @pytest.mark.asyncio
    async def test_sync_transactions(self, plaid_service: PlaidService, mocker):
        """
        Test transaction synchronization with cursor.
        
        Requirement: Transaction Management Testing
        Location: 1.2 Scope/In Scope/Financial Tracking
        """
        mock_transaction = mocker.MagicMock()
        mock_transaction.transaction_id = "test_tx_id"
        mock_transaction.account_id = "test_account_id"
        mock_transaction.amount = 75.0
        mock_transaction.date = "2023-01-01"
        mock_transaction.name = "Test Sync Transaction"
        mock_transaction.merchant_name = "Test Sync Merchant"
        mock_transaction.category = ["Shopping"]
        mock_transaction.pending = False
        
        mock_response = mocker.MagicMock()
        mock_response.added = [mock_transaction]
        mock_response.modified = []
        mock_response.removed = []
        mock_response.next_cursor = "test_cursor_next"
        mocker.patch.object(plaid_service._client, 'transactions_sync', return_value=mock_response)
        
        transactions, cursor = await plaid_service.sync_transactions(
            json.dumps({"access_token": TEST_ACCESS_TOKEN}),
            "test_cursor"
        )
        
        assert len(transactions) == 1
        assert transactions[0]["id"] == "test_tx_id"
        assert transactions[0]["amount"] == 75.0
        assert cursor == "test_cursor_next"

    @pytest.mark.asyncio
    async def test_get_balances(self, plaid_service: PlaidService, mocker):
        """
        Test retrieval of real-time balance information.
        
        Requirement: Financial Account Aggregation Testing
        Location: 1.2 Scope/In Scope/Account Management
        """
        mock_account = mocker.MagicMock()
        mock_account.account_id = "test_account_id"
        mock_account.balances.current = 2000.0
        mock_account.balances.available = 1800.0
        mock_account.balances.limit = 5000.0
        
        mock_response = mocker.MagicMock()
        mock_response.accounts = [mock_account]
        mocker.patch.object(plaid_service._client, 'accounts_get', return_value=mock_response)
        
        balances = await plaid_service.get_balances(
            json.dumps({"access_token": TEST_ACCESS_TOKEN})
        )
        
        assert len(balances) == 1
        assert balances[0]["account_id"] == "test_account_id"
        assert balances[0]["current"] == 2000.0
        assert balances[0]["available"] == 1800.0
        assert balances[0]["limit"] == 5000.0