# pytest v6.2.5
import pytest
# pytest-asyncio v0.15.1
import pytest_asyncio
# fastapi.testclient v0.68.0
from fastapi.testclient import TestClient
# unittest.mock v3.9+
from unittest.mock import MagicMock, patch
from datetime import datetime
from decimal import Decimal
from uuid import UUID, uuid4

# Internal imports
from app.api.v1.endpoints.transactions import (
    get_transaction,
    get_transactions,
    create_transaction,
    update_transaction,
    sync_transactions,
    categorize_transaction
)
from app.services.transaction_service import TransactionService
from app.schemas.transaction import (
    TransactionCreate,
    TransactionUpdate,
    TransactionFilter,
    TransactionResponse
)

# Human Tasks:
# 1. Configure test database with appropriate test data
# 2. Set up test authentication tokens and user contexts
# 3. Configure mock Plaid service responses for sync tests
# 4. Set up test categories for categorization tests
# 5. Review rate limiting configurations for tests

class TestTransactionAPI:
    """
    Test class for transaction API endpoints.
    
    Requirements addressed:
    - Financial Tracking (1.2): Test automated transaction import, category management
    - REST API Services (2.1): Verify RESTful API services
    - Security Controls (6.3.3): Test input validation and secure error handling
    """

    @pytest.fixture(autouse=True)
    def setup_method(self):
        """Set up test environment before each test."""
        self.client = TestClient(app)
        self.mock_transaction_service = MagicMock(spec=TransactionService)
        
        # Set up test user authentication
        self.test_user_id = uuid4()
        self.test_account_id = uuid4()
        self.auth_token = "test_auth_token"
        self.headers = {"Authorization": f"Bearer {self.auth_token}"}
        
        # Mock user context with authorized accounts
        self.test_user = {
            "id": str(self.test_user_id),
            "accounts": [str(self.test_account_id)]
        }
        
        # Set up test data
        self.test_transaction = {
            "id": uuid4(),
            "account_id": self.test_account_id,
            "transaction_date": datetime.now(),
            "amount": Decimal("50.25"),
            "description": "Test Transaction",
            "merchant_name": "Test Merchant",
            "transaction_type": "debit",
            "category_id": 1,
            "status": "posted",
            "is_pending": False,
            "metadata": {"test_key": "test_value"}
        }

    def teardown_method(self):
        """Clean up after each test."""
        patch.stopall()

    @pytest.mark.asyncio
    async def test_get_transaction(self):
        """
        Test getting a single transaction by ID.
        
        Requirements addressed:
        - Financial Tracking (1.2): Verify transaction retrieval
        - Security Controls (6.3.3): Test access control
        """
        # Test successful transaction retrieval
        transaction_id = uuid4()
        self.mock_transaction_service.get_transaction.return_value = self.test_transaction
        
        response = self.client.get(
            f"/transactions/{transaction_id}",
            headers=self.headers
        )
        
        assert response.status_code == 200
        assert response.json()["id"] == str(self.test_transaction["id"])
        assert response.json()["amount"] == str(self.test_transaction["amount"])
        
        # Test transaction not found
        self.mock_transaction_service.get_transaction.return_value = None
        
        response = self.client.get(
            f"/transactions/{uuid4()}",
            headers=self.headers
        )
        
        assert response.status_code == 404
        
        # Test unauthorized access
        unauthorized_account_id = uuid4()
        unauthorized_transaction = {**self.test_transaction, "account_id": unauthorized_account_id}
        self.mock_transaction_service.get_transaction.return_value = unauthorized_transaction
        
        response = self.client.get(
            f"/transactions/{transaction_id}",
            headers=self.headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_get_transactions(self):
        """
        Test retrieving filtered list of transactions.
        
        Requirements addressed:
        - Financial Tracking (1.2): Test transaction filtering
        - REST API Services (2.1): Verify list endpoint
        """
        # Test successful transaction list retrieval
        test_transactions = [self.test_transaction for _ in range(3)]
        self.mock_transaction_service.get_transactions.return_value = (test_transactions, 3)
        
        response = self.client.get(
            "/transactions/",
            params={
                "account_id": str(self.test_account_id),
                "page": 1,
                "page_size": 10
            },
            headers=self.headers
        )
        
        assert response.status_code == 200
        assert len(response.json()) == 3
        
        # Test filtering
        start_date = datetime.now().isoformat()
        response = self.client.get(
            "/transactions/",
            params={
                "account_id": str(self.test_account_id),
                "start_date": start_date,
                "category_id": 1
            },
            headers=self.headers
        )
        
        assert response.status_code == 200
        self.mock_transaction_service.get_transactions.assert_called_with(
            account_id=self.test_account_id,
            start_date=start_date,
            category_id=1,
            page=1,
            page_size=50
        )
        
        # Test unauthorized account access
        response = self.client.get(
            "/transactions/",
            params={"account_id": str(uuid4())},
            headers=self.headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_create_transaction(self):
        """
        Test transaction creation endpoint.
        
        Requirements addressed:
        - Financial Tracking (1.2): Test transaction creation
        - Security Controls (6.3.3): Verify input validation
        """
        # Test successful transaction creation
        transaction_data = {
            "account_id": str(self.test_account_id),
            "transaction_date": datetime.now().isoformat(),
            "amount": "50.25",
            "description": "Test Transaction",
            "merchant_name": "Test Merchant",
            "transaction_type": "debit",
            "category_id": 1,
            "status": "posted",
            "is_pending": False
        }
        
        self.mock_transaction_service.create_transaction.return_value = self.test_transaction
        
        response = self.client.post(
            "/transactions/",
            json=transaction_data,
            headers=self.headers
        )
        
        assert response.status_code == 201
        assert response.json()["description"] == transaction_data["description"]
        
        # Test invalid transaction data
        invalid_data = {**transaction_data, "amount": "invalid"}
        response = self.client.post(
            "/transactions/",
            json=invalid_data,
            headers=self.headers
        )
        
        assert response.status_code == 422
        
        # Test unauthorized account
        unauthorized_data = {**transaction_data, "account_id": str(uuid4())}
        response = self.client.post(
            "/transactions/",
            json=unauthorized_data,
            headers=self.headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_update_transaction(self):
        """
        Test transaction update endpoint.
        
        Requirements addressed:
        - Financial Tracking (1.2): Test transaction modification
        - Security Controls (6.3.3): Verify update authorization
        """
        # Test successful transaction update
        transaction_id = uuid4()
        update_data = {
            "description": "Updated Transaction",
            "category_id": 2,
            "metadata": {"updated": True}
        }
        
        self.mock_transaction_service.get_transaction.return_value = self.test_transaction
        self.mock_transaction_service.update_transaction.return_value = {
            **self.test_transaction,
            **update_data
        }
        
        response = self.client.patch(
            f"/transactions/{transaction_id}",
            json=update_data,
            headers=self.headers
        )
        
        assert response.status_code == 200
        assert response.json()["description"] == update_data["description"]
        
        # Test transaction not found
        self.mock_transaction_service.get_transaction.return_value = None
        
        response = self.client.patch(
            f"/transactions/{transaction_id}",
            json=update_data,
            headers=self.headers
        )
        
        assert response.status_code == 404
        
        # Test unauthorized update
        unauthorized_transaction = {
            **self.test_transaction,
            "account_id": uuid4()
        }
        self.mock_transaction_service.get_transaction.return_value = unauthorized_transaction
        
        response = self.client.patch(
            f"/transactions/{transaction_id}",
            json=update_data,
            headers=self.headers
        )
        
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_sync_transactions(self):
        """
        Test transaction synchronization endpoint.
        
        Requirements addressed:
        - Financial Tracking (1.2): Test automated transaction import
        - Security Controls (6.3.3): Verify sync authorization
        """
        # Test successful sync
        sync_result = {
            "new_transactions": 5,
            "cursor": "test_cursor_123"
        }
        self.mock_transaction_service.sync_transactions.return_value = (
            [self.test_transaction for _ in range(5)],
            "test_cursor_123"
        )
        
        response = self.client.post(
            "/transactions/sync",
            params={
                "account_id": str(self.test_account_id),
                "cursor": "previous_cursor"
            },
            headers=self.headers
        )
        
        assert response.status_code == 200
        assert response.json() == sync_result
        
        # Test unauthorized sync
        response = self.client.post(
            "/transactions/sync",
            params={
                "account_id": str(uuid4()),
                "cursor": "previous_cursor"
            },
            headers=self.headers
        )
        
        assert response.status_code == 403
        
        # Test sync error
        self.mock_transaction_service.sync_transactions.side_effect = Exception("Sync failed")
        
        response = self.client.post(
            "/transactions/sync",
            params={
                "account_id": str(self.test_account_id),
                "cursor": "previous_cursor"
            },
            headers=self.headers
        )
        
        assert response.status_code == 400

    @pytest.mark.asyncio
    async def test_categorize_transaction(self):
        """
        Test transaction categorization endpoint.
        
        Requirements addressed:
        - Financial Tracking (1.2): Test category management
        - Security Controls (6.3.3): Verify categorization authorization
        """
        # Test successful categorization
        transaction_id = uuid4()
        category_id = 5
        
        self.mock_transaction_service.get_transaction.return_value = self.test_transaction
        self.mock_transaction_service.categorize_transaction.return_value = {
            **self.test_transaction,
            "category_id": category_id
        }
        
        response = self.client.put(
            f"/transactions/{transaction_id}/category",
            params={"category_id": category_id},
            headers=self.headers
        )
        
        assert response.status_code == 200
        assert response.json()["category_id"] == category_id
        
        # Test transaction not found
        self.mock_transaction_service.get_transaction.return_value = None
        
        response = self.client.put(
            f"/transactions/{transaction_id}/category",
            params={"category_id": category_id},
            headers=self.headers
        )
        
        assert response.status_code == 404
        
        # Test unauthorized categorization
        unauthorized_transaction = {
            **self.test_transaction,
            "account_id": uuid4()
        }
        self.mock_transaction_service.get_transaction.return_value = unauthorized_transaction
        
        response = self.client.put(
            f"/transactions/{transaction_id}/category",
            params={"category_id": category_id},
            headers=self.headers
        )
        
        assert response.status_code == 403
        
        # Test invalid category
        self.mock_transaction_service.get_transaction.return_value = self.test_transaction
        self.mock_transaction_service.categorize_transaction.side_effect = ValueError("Invalid category")
        
        response = self.client.put(
            f"/transactions/{transaction_id}/category",
            params={"category_id": 999},
            headers=self.headers
        )
        
        assert response.status_code == 422