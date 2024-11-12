# SQLAlchemy v1.4.0
from sqlalchemy import and_, or_, desc
from sqlalchemy.orm import Session

# pydantic v1.8.2
from pydantic import BaseModel, UUID4, validator
from datetime import datetime
from typing import List, Optional, Tuple, Dict
import uuid

# Relative imports
from ..models.transaction import Transaction
from ..services.plaid_service import PlaidService
from ..core.cache import cache

# Human Tasks:
# 1. Configure Redis cache settings for transaction data
# 2. Set up monitoring for transaction sync performance
# 3. Review and adjust cache TTL values based on usage patterns
# 4. Configure error alerting for failed transaction syncs
# 5. Set up database indices for transaction queries

class TransactionCreate(BaseModel):
    """Pydantic model for transaction creation validation."""
    account_id: UUID4
    transaction_date: datetime
    amount: float
    description: str
    merchant_name: Optional[str]
    transaction_type: str
    category_id: Optional[int]
    metadata: Optional[Dict] = {}

class TransactionUpdate(BaseModel):
    """Pydantic model for transaction update validation."""
    amount: Optional[float]
    description: Optional[str]
    merchant_name: Optional[str]
    category_id: Optional[int]
    metadata: Optional[Dict]

class TransactionService:
    """
    Service class for managing financial transactions.
    
    Requirements addressed:
    - Financial Tracking (1.2 Scope/Financial Tracking):
      Implements automated transaction import, category management
    - Real-time Updates (2.3 Data Flow Architecture):
      Implements real-time transaction synchronization
    - Data Security (6.2 Data Security/6.2.1 Encryption Implementation):
      Implements secure transaction data handling
    """

    def __init__(self, db_session: Session, plaid_service: PlaidService):
        """Initialize transaction service with database session and dependencies."""
        self._db = db_session
        self._plaid_service = plaid_service
        self._cache = cache

    def get_transaction(self, transaction_id: uuid.UUID) -> Optional[Transaction]:
        """
        Retrieve a single transaction by ID with caching.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements transaction retrieval with caching
        """
        # Check cache first
        cache_key = f"transaction:{str(transaction_id)}"
        cached_data = self._cache.get(cache_key)
        
        if cached_data:
            return Transaction(**cached_data)
            
        # Query database if not in cache
        transaction = self._db.query(Transaction).filter(
            Transaction.id == transaction_id
        ).first()
        
        if transaction:
            # Cache for 1 hour
            self._cache.set(
                cache_key,
                transaction.to_dict(),
                ttl=3600
            )
            
        return transaction

    def get_transactions(
        self,
        account_id: uuid.UUID,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        category_id: Optional[str] = None,
        page: int = 1,
        page_size: int = 50
    ) -> Tuple[List[Transaction], int]:
        """
        Retrieve transactions with filtering and pagination.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements transaction filtering and pagination
        """
        # Build base query
        query = self._db.query(Transaction).filter(
            Transaction.account_id == account_id
        )
        
        # Apply filters
        if start_date:
            query = query.filter(Transaction.transaction_date >= start_date)
        if end_date:
            query = query.filter(Transaction.transaction_date <= end_date)
        if category_id:
            query = query.filter(Transaction.category_id == category_id)
            
        # Get total count
        total_count = query.count()
        
        # Apply pagination
        transactions = query.order_by(desc(Transaction.transaction_date))\
            .offset((page - 1) * page_size)\
            .limit(page_size)\
            .all()
            
        # Cache results
        cache_key = f"transactions:{str(account_id)}:{start_date}:{end_date}:{category_id}:{page}"
        self._cache.set(
            cache_key,
            [t.to_dict() for t in transactions],
            ttl=300  # Cache for 5 minutes
        )
        
        return transactions, total_count

    def create_transaction(self, transaction_data: TransactionCreate) -> Transaction:
        """
        Create a new transaction record.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements transaction creation
        - Data Security (6.2.1): Implements secure data handling
        """
        # Create new transaction
        transaction = Transaction(
            account_id=transaction_data.account_id,
            transaction_date=transaction_data.transaction_date,
            amount=transaction_data.amount,
            description=transaction_data.description,
            transaction_type=transaction_data.transaction_type
        )
        
        if transaction_data.merchant_name:
            transaction.merchant_name = transaction_data.merchant_name
        if transaction_data.category_id:
            transaction.update_category(transaction_data.category_id)
        if transaction_data.metadata:
            transaction.update_metadata(transaction_data.metadata)
            
        # Save to database
        self._db.add(transaction)
        self._db.commit()
        
        # Invalidate relevant cache entries
        self._cache.delete(f"transactions:{str(transaction.account_id)}:*")
        
        return transaction

    def update_transaction(
        self,
        transaction_id: uuid.UUID,
        update_data: TransactionUpdate
    ) -> Transaction:
        """
        Update an existing transaction.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements transaction updates
        """
        transaction = self.get_transaction(transaction_id)
        if not transaction:
            raise ValueError("Transaction not found")
            
        # Update fields if provided
        if update_data.amount is not None:
            transaction.amount = update_data.amount
        if update_data.description is not None:
            transaction.description = update_data.description
        if update_data.merchant_name is not None:
            transaction.merchant_name = update_data.merchant_name
        if update_data.category_id is not None:
            transaction.update_category(update_data.category_id)
        if update_data.metadata is not None:
            transaction.update_metadata(update_data.metadata)
            
        # Save changes
        self._db.commit()
        
        # Invalidate cache entries
        self._cache.delete(f"transaction:{str(transaction_id)}")
        self._cache.delete(f"transactions:{str(transaction.account_id)}:*")
        
        return transaction

    async def sync_transactions(
        self,
        account_id: uuid.UUID,
        access_token: str,
        cursor: Optional[str] = None
    ) -> Tuple[List[Transaction], str]:
        """
        Synchronize transactions with Plaid.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements automated transaction import
        - Real-time Updates (2.3): Implements real-time synchronization
        """
        # Get new transactions from Plaid
        new_transactions, updated_cursor = await self._plaid_service.sync_transactions(
            access_token,
            cursor
        )
        
        processed_transactions = []
        for plaid_transaction in new_transactions:
            # Create or update transaction
            transaction_data = TransactionCreate(
                account_id=account_id,
                transaction_date=datetime.fromisoformat(plaid_transaction['date']),
                amount=plaid_transaction['amount'],
                description=plaid_transaction['name'],
                merchant_name=plaid_transaction.get('merchant_name'),
                transaction_type='debit' if plaid_transaction['amount'] > 0 else 'credit',
                metadata={
                    'plaid_transaction_id': plaid_transaction['id'],
                    'category': plaid_transaction.get('category', []),
                    'pending': plaid_transaction.get('pending', False)
                }
            )
            
            transaction = self.create_transaction(transaction_data)
            processed_transactions.append(transaction)
            
        # Invalidate cache entries
        self._cache.delete(f"transactions:{str(account_id)}:*")
        
        return processed_transactions, updated_cursor

    def categorize_transaction(
        self,
        transaction_id: uuid.UUID,
        category_id: int
    ) -> Transaction:
        """
        Update transaction category.
        
        Requirements addressed:
        - Financial Tracking (1.2): Implements category management
        """
        transaction = self.get_transaction(transaction_id)
        if not transaction:
            raise ValueError("Transaction not found")
            
        # Update category
        transaction.update_category(category_id)
        self._db.commit()
        
        # Invalidate cache entries
        self._cache.delete(f"transaction:{str(transaction_id)}")
        self._cache.delete(f"transactions:{str(transaction.account_id)}:*")
        
        return transaction