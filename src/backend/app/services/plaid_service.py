"""
Plaid service module for secure financial account integration and data synchronization.

Human Tasks:
1. Set up Plaid developer account and obtain API credentials
2. Configure environment variables for Plaid API credentials
3. Review and verify Plaid webhook configuration
4. Set up error monitoring for Plaid API integration
5. Configure rate limiting for Plaid API calls
"""

# plaid: ^11.0.0
import plaid
from plaid.api import plaid_api
from plaid.model.link_token_create_request import LinkTokenCreateRequest
from plaid.model.transactions_sync_request import TransactionsSyncRequest
from plaid.model.accounts_get_request import AccountsGetRequest
from plaid.model.transactions_get_request import TransactionsGetRequest

# aiohttp: ^3.8.0
import aiohttp
from aiohttp import ClientSession

# pydantic: ^1.8.2
from pydantic import ValidationError

from datetime import datetime
from typing import Dict, List, Optional, Tuple
import json

# Internal imports
from ..core.config import Settings
from ..core.encryption import EncryptionManager
from ..core.logging import get_logger

class PlaidService:
    """
    Service class for managing Plaid API integration with secure token handling.
    
    Requirement: Financial Account Aggregation - Multi-platform financial account aggregation
    Requirement: Data Security - Secure handling of financial credentials and account data
    """
    
    def __init__(self, settings: Settings, encryption_manager: EncryptionManager):
        """Initialize Plaid service with secure configuration."""
        # Initialize Plaid client with environment-specific configuration
        configuration = plaid.Configuration(
            host=plaid.Environment[settings.PLAID_ENVIRONMENT],
            api_key={
                'clientId': settings.PLAID_CLIENT_ID,
                'secret': settings.PLAID_SECRET,
            }
        )
        
        # Set up API client with secure configuration
        self._client = plaid_api.PlaidApi(configuration)
        
        # Initialize encryption manager for secure token handling
        self._encryption_manager = encryption_manager
        
        # Set up logging
        self._logger = get_logger(__name__)
        
        # Initialize async HTTP client for API calls
        self._http_session = None
    
    async def _get_http_session(self) -> ClientSession:
        """Get or create async HTTP session."""
        if self._http_session is None or self._http_session.closed:
            self._http_session = ClientSession()
        return self._http_session
    
    async def create_link_token(self, user_id: str, products: List[str]) -> str:
        """
        Create a Plaid Link token for client-side account linking.
        
        Requirement: Financial Account Aggregation - Secure account linking process
        """
        try:
            request = LinkTokenCreateRequest(
                user={"client_user_id": user_id},
                client_name="Mint Replica Lite",
                products=products,
                country_codes=["US"],
                language="en"
            )
            
            response = self._client.link_token_create(request)
            link_token = response.link_token
            
            self._logger.info(
                "Created Plaid Link token",
                extra={"user_id": user_id, "products": products}
            )
            
            return link_token
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to create Plaid Link token",
                extra={"error": str(e), "user_id": user_id}
            )
            raise
    
    async def exchange_public_token(self, public_token: str) -> Dict[str, str]:
        """
        Exchange public token for access token with encryption.
        
        Requirement: Data Security - Secure token exchange and storage
        """
        try:
            # Exchange public token for access token
            exchange_response = self._client.item_public_token_exchange(
                {"public_token": public_token}
            )
            
            access_token = exchange_response.access_token
            item_id = exchange_response.item_id
            
            # Encrypt access token before storage
            encrypted_token = self._encryption_manager.encrypt_field(access_token)
            
            self._logger.info(
                "Exchanged public token for access token",
                extra={"item_id": item_id}
            )
            
            return {
                "access_token": json.dumps(encrypted_token),
                "item_id": item_id
            }
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to exchange public token",
                extra={"error": str(e)}
            )
            raise
    
    async def get_accounts(self, access_token: str) -> List[Dict]:
        """
        Retrieve account information with secure token handling.
        
        Requirement: Financial Account Aggregation - Account data retrieval
        """
        try:
            # Decrypt access token
            decrypted_token = self._encryption_manager.decrypt_field(
                json.loads(access_token)
            ).decode()
            
            request = AccountsGetRequest(access_token=decrypted_token)
            response = self._client.accounts_get(request)
            
            accounts = []
            for account in response.accounts:
                accounts.append({
                    "id": account.account_id,
                    "name": account.name,
                    "type": account.type,
                    "subtype": account.subtype,
                    "mask": account.mask,
                    "balances": {
                        "current": account.balances.current,
                        "available": account.balances.available,
                        "limit": account.balances.limit
                    }
                })
            
            self._logger.info(
                "Retrieved account information",
                extra={"account_count": len(accounts)}
            )
            
            return accounts
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to retrieve accounts",
                extra={"error": str(e)}
            )
            raise
    
    async def get_transactions(
        self,
        access_token: str,
        start_date: datetime,
        end_date: datetime
    ) -> List[Dict]:
        """
        Retrieve transactions for specified date range.
        
        Requirement: Transaction Management - Automated transaction import
        """
        try:
            # Decrypt access token
            decrypted_token = self._encryption_manager.decrypt_field(
                json.loads(access_token)
            ).decode()
            
            request = TransactionsGetRequest(
                access_token=decrypted_token,
                start_date=start_date.date(),
                end_date=end_date.date()
            )
            
            response = self._client.transactions_get(request)
            
            transactions = []
            for transaction in response.transactions:
                transactions.append({
                    "id": transaction.transaction_id,
                    "account_id": transaction.account_id,
                    "amount": transaction.amount,
                    "date": transaction.date,
                    "name": transaction.name,
                    "merchant_name": transaction.merchant_name,
                    "category": transaction.category,
                    "pending": transaction.pending
                })
            
            self._logger.info(
                "Retrieved transactions",
                extra={
                    "transaction_count": len(transactions),
                    "start_date": start_date.isoformat(),
                    "end_date": end_date.isoformat()
                }
            )
            
            return transactions
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to retrieve transactions",
                extra={"error": str(e)}
            )
            raise
    
    async def sync_transactions(
        self,
        access_token: str,
        cursor: Optional[str] = None
    ) -> Tuple[List[Dict], str]:
        """
        Sync new transactions using cursor-based pagination.
        
        Requirement: Transaction Management - Real-time transaction syncing
        """
        try:
            # Decrypt access token
            decrypted_token = self._encryption_manager.decrypt_field(
                json.loads(access_token)
            ).decode()
            
            request = TransactionsSyncRequest(
                access_token=decrypted_token,
                cursor=cursor
            )
            
            response = self._client.transactions_sync(request)
            
            transactions = []
            for transaction in response.added:
                transactions.append({
                    "id": transaction.transaction_id,
                    "account_id": transaction.account_id,
                    "amount": transaction.amount,
                    "date": transaction.date,
                    "name": transaction.name,
                    "merchant_name": transaction.merchant_name,
                    "category": transaction.category,
                    "pending": transaction.pending
                })
            
            self._logger.info(
                "Synced transactions",
                extra={
                    "added_count": len(response.added),
                    "modified_count": len(response.modified),
                    "removed_count": len(response.removed)
                }
            )
            
            return transactions, response.next_cursor
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to sync transactions",
                extra={"error": str(e)}
            )
            raise
    
    async def get_balances(self, access_token: str) -> List[Dict]:
        """
        Get real-time balance information for accounts.
        
        Requirement: Financial Account Aggregation - Real-time balance updates
        """
        try:
            # Decrypt access token
            decrypted_token = self._encryption_manager.decrypt_field(
                json.loads(access_token)
            ).decode()
            
            request = AccountsGetRequest(access_token=decrypted_token)
            response = self._client.accounts_get(request)
            
            balances = []
            for account in response.accounts:
                balances.append({
                    "account_id": account.account_id,
                    "current": account.balances.current,
                    "available": account.balances.available,
                    "limit": account.balances.limit,
                    "last_updated": datetime.utcnow().isoformat()
                })
            
            self._logger.info(
                "Retrieved real-time balances",
                extra={"account_count": len(balances)}
            )
            
            return balances
            
        except plaid.ApiException as e:
            self._logger.error(
                "Failed to retrieve balances",
                extra={"error": str(e)}
            )
            raise
    
    async def close(self):
        """Clean up resources."""
        if self._http_session and not self._http_session.closed:
            await self._http_session.close()