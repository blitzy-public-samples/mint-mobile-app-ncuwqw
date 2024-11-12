"""
Account service module for managing financial accounts in Mint Replica Lite.

Human Tasks:
1. Configure Plaid API credentials in environment variables
2. Set up Redis instance and verify connectivity
3. Configure logging for account operations monitoring
4. Review and adjust cache TTL settings for account data
5. Set up database connection pool parameters
"""

# sqlalchemy: ^1.4.0
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from datetime import datetime
from decimal import Decimal
from typing import List, Optional, Dict
import logging

from app.models.account import Account
from app.services.plaid_service import PlaidService
from app.core.cache import cache

class AccountService:
    """
    Service class for managing financial accounts with Plaid integration and caching.
    
    Requirements addressed:
    - Account Management (1.2): Multi-platform user authentication and financial account aggregation
    - Real-time Updates (1.2): Real-time balance updates and cross-platform data synchronization
    - Data Security (6.2.2): Secure handling of financial account data and credentials
    """

    def __init__(self, plaid_service: PlaidService, db_session: Session):
        """
        Initialize account service with required dependencies.
        
        Args:
            plaid_service: Plaid API service instance
            db_session: SQLAlchemy database session
        """
        self._plaid_service = plaid_service
        self._db_session = db_session
        self._logger = logging.getLogger(__name__)

    async def create_account(self, user_id: str, access_token: str, plaid_account_id: str) -> Account:
        """
        Create a new financial account from Plaid account data.
        
        Requirements addressed:
        - Account Management (1.2): Account creation with Plaid integration
        - Data Security (6.2.2): Secure handling of account data
        """
        try:
            # Fetch account data from Plaid
            plaid_accounts = await self._plaid_service.get_accounts(access_token)
            account_data = next(
                (acc for acc in plaid_accounts if acc['id'] == plaid_account_id),
                None
            )

            if not account_data:
                raise ValueError(f"Account {plaid_account_id} not found in Plaid data")

            # Create new account instance
            account = Account(
                user_id=user_id,
                institution_id=account_data['id'],
                account_type=account_data['type'],
                account_name=account_data['name'],
                account_number_masked=account_data['mask'],
                current_balance=Decimal(str(account_data['balances']['current'])),
                currency_code='USD'  # Default to USD, can be extended for multi-currency
            )

            # Save to database
            self._db_session.add(account)
            self._db_session.commit()

            # Cache account data
            cache_key = f"account:{account.id}"
            cache.set(cache_key, account.to_dict())

            self._logger.info(
                "Created new account",
                extra={"account_id": str(account.id), "user_id": user_id}
            )

            return account

        except SQLAlchemyError as e:
            self._db_session.rollback()
            self._logger.error(
                "Database error creating account",
                extra={"error": str(e), "user_id": user_id}
            )
            raise

    def get_account(self, account_id: str, use_cache: bool = True) -> Optional[Account]:
        """
        Retrieve account by ID with Redis caching.
        
        Requirements addressed:
        - Account Management (1.2): Account data retrieval
        - Data Security (6.2.2): Secure data access
        """
        try:
            cache_key = f"account:{account_id}"

            # Check cache first if enabled
            if use_cache:
                cached_data = cache.get(cache_key)
                if cached_data:
                    self._logger.debug(
                        "Retrieved account from cache",
                        extra={"account_id": account_id}
                    )
                    return Account(**cached_data)

            # Query database if not in cache
            account = self._db_session.query(Account).filter(
                Account.id == account_id,
                Account.is_active == True
            ).first()

            if account and use_cache:
                # Update cache
                cache.set(cache_key, account.to_dict())

            return account

        except SQLAlchemyError as e:
            self._logger.error(
                "Database error retrieving account",
                extra={"error": str(e), "account_id": account_id}
            )
            raise

    async def update_account_balance(self, account_id: str) -> bool:
        """
        Update account balance with real-time data from Plaid.
        
        Requirements addressed:
        - Real-time Updates (1.2): Real-time balance synchronization
        """
        try:
            account = self.get_account(account_id, use_cache=False)
            if not account:
                raise ValueError(f"Account {account_id} not found")

            # Fetch current balance from Plaid
            balances = await self._plaid_service.get_balances(account.access_token)
            account_balance = next(
                (b for b in balances if b['account_id'] == account.plaid_account_id),
                None
            )

            if not account_balance:
                raise ValueError(f"Balance data not found for account {account_id}")

            # Update account balance
            account.update_balance(
                current_balance=Decimal(str(account_balance['current'])),
                available_balance=Decimal(str(account_balance['available']))
            )

            self._db_session.commit()

            # Update cache
            cache_key = f"account:{account_id}"
            cache.set(cache_key, account.to_dict())

            self._logger.info(
                "Updated account balance",
                extra={"account_id": account_id}
            )

            return True

        except (SQLAlchemyError, ValueError) as e:
            self._db_session.rollback()
            self._logger.error(
                "Error updating account balance",
                extra={"error": str(e), "account_id": account_id}
            )
            raise

    async def sync_accounts(self, user_id: str) -> List[Account]:
        """
        Synchronize all accounts for a user with Plaid data.
        
        Requirements addressed:
        - Real-time Updates (1.2): Cross-platform data synchronization
        """
        try:
            accounts = self._db_session.query(Account).filter(
                Account.user_id == user_id,
                Account.is_active == True
            ).all()

            for account in accounts:
                # Fetch latest data from Plaid
                plaid_accounts = await self._plaid_service.get_accounts(account.access_token)
                account_data = next(
                    (acc for acc in plaid_accounts if acc['id'] == account.plaid_account_id),
                    None
                )

                if account_data:
                    # Update account information
                    account.update_institution_data(account_data)
                    
                    # Update cache
                    cache_key = f"account:{account.id}"
                    cache.set(cache_key, account.to_dict())

            self._db_session.commit()

            self._logger.info(
                "Synchronized accounts",
                extra={"user_id": user_id, "account_count": len(accounts)}
            )

            return accounts

        except SQLAlchemyError as e:
            self._db_session.rollback()
            self._logger.error(
                "Database error syncing accounts",
                extra={"error": str(e), "user_id": user_id}
            )
            raise

    def deactivate_account(self, account_id: str) -> bool:
        """
        Deactivate a financial account.
        
        Requirements addressed:
        - Account Management (1.2): Account lifecycle management
        """
        try:
            account = self.get_account(account_id, use_cache=False)
            if not account:
                raise ValueError(f"Account {account_id} not found")

            account.is_active = False
            account.updated_at = datetime.utcnow()
            
            self._db_session.commit()

            # Remove from cache
            cache_key = f"account:{account_id}"
            cache.delete(cache_key)

            self._logger.info(
                "Deactivated account",
                extra={"account_id": account_id}
            )

            return True

        except SQLAlchemyError as e:
            self._db_session.rollback()
            self._logger.error(
                "Database error deactivating account",
                extra={"error": str(e), "account_id": account_id}
            )
            raise