# SQLAlchemy: ^1.4.0
# Python: 3.9+
from sqlalchemy.orm import Session
from uuid import UUID
from decimal import Decimal
from datetime import datetime
from typing import List, Optional, Dict

from app.models.investment import Investment
from app.schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentResponse, InvestmentInDB
from app.db.session import get_db

# Human Tasks:
# 1. Configure database connection pool size based on expected load
# 2. Set up monitoring for investment value sync operations
# 3. Configure alerts for significant portfolio value changes
# 4. Review and adjust transaction isolation levels if needed
# 5. Set up automated performance metric calculations schedule

class InvestmentService:
    """
    Service class for managing investment accounts and portfolio operations.
    
    Requirements addressed:
    - Investment Tracking (1.2 Scope/Investment Tracking): Implements portfolio monitoring,
      investment account integration, and performance metrics
    - Data Security (6.2.2 Sensitive Data Handling): Implements secure handling of
      investment account data
    """
    
    def __init__(self, db: Session):
        """
        Initialize investment service with database session.
        
        Args:
            db: SQLAlchemy database session
        """
        self.db = db

    def create_investment(self, investment_data: InvestmentCreate) -> InvestmentResponse:
        """
        Create a new investment position.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements investment position creation and tracking
        
        Args:
            investment_data: Validated investment creation data
            
        Returns:
            InvestmentResponse: Created investment details
            
        Raises:
            ValueError: If investment data is invalid
        """
        investment = Investment(
            account_id=investment_data.account_id,
            symbol=investment_data.symbol,
            name=investment_data.name,
            investment_type=investment_data.investment_type,
            quantity=investment_data.quantity,
            cost_basis=investment_data.cost_basis,
            current_value=investment_data.current_value,
            currency_code=investment_data.currency_code
        )
        
        # Update metadata if provided
        if investment_data.metadata:
            investment.update_metadata(investment_data.metadata)
            
        self.db.add(investment)
        self.db.commit()
        self.db.refresh(investment)
        
        return InvestmentResponse.from_orm(investment)

    def get_investment(self, investment_id: UUID) -> InvestmentResponse:
        """
        Retrieve investment by ID.
        
        Requirements addressed:
        - Investment Tracking (1.2): Supports investment position lookup
        
        Args:
            investment_id: UUID of the investment to retrieve
            
        Returns:
            InvestmentResponse: Investment details
            
        Raises:
            ValueError: If investment not found or inactive
        """
        investment = self.db.query(Investment).filter(
            Investment.id == investment_id,
            Investment.is_active == True
        ).first()
        
        if not investment:
            raise ValueError(f"Investment {investment_id} not found or inactive")
            
        return InvestmentResponse.from_orm(investment)

    def update_investment(
        self,
        investment_id: UUID,
        investment_data: InvestmentUpdate
    ) -> InvestmentResponse:
        """
        Update existing investment details.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements investment position updates
        
        Args:
            investment_id: UUID of investment to update
            investment_data: Validated update data
            
        Returns:
            InvestmentResponse: Updated investment details
            
        Raises:
            ValueError: If investment not found or inactive
        """
        investment = self.db.query(Investment).filter(
            Investment.id == investment_id,
            Investment.is_active == True
        ).first()
        
        if not investment:
            raise ValueError(f"Investment {investment_id} not found or inactive")
            
        # Update basic attributes if provided
        update_data = investment_data.dict(exclude_unset=True)
        
        if 'current_value' in update_data or 'quantity' in update_data:
            investment.update_value(
                current_value=update_data.get('current_value', investment.current_value),
                quantity=update_data.get('quantity', investment.quantity)
            )
            
        if 'metadata' in update_data:
            investment.update_metadata(update_data['metadata'])
            
        # Update other fields
        for field, value in update_data.items():
            if field not in ['current_value', 'quantity', 'metadata']:
                setattr(investment, field, value)
                
        self.db.commit()
        self.db.refresh(investment)
        
        return InvestmentResponse.from_orm(investment)

    def delete_investment(self, investment_id: UUID) -> bool:
        """
        Soft delete investment by setting inactive.
        
        Requirements addressed:
        - Investment Tracking (1.2): Supports investment position removal
        
        Args:
            investment_id: UUID of investment to delete
            
        Returns:
            bool: True if deletion successful
            
        Raises:
            ValueError: If investment not found or already inactive
        """
        investment = self.db.query(Investment).filter(
            Investment.id == investment_id,
            Investment.is_active == True
        ).first()
        
        if not investment:
            raise ValueError(f"Investment {investment_id} not found or inactive")
            
        investment.is_active = False
        investment.updated_at = datetime.utcnow()
        
        self.db.commit()
        return True

    def list_investments(
        self,
        account_id: UUID,
        skip: int = 0,
        limit: int = 100
    ) -> List[InvestmentResponse]:
        """
        List investments for an account with pagination.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements portfolio listing and monitoring
        
        Args:
            account_id: UUID of the account
            skip: Number of records to skip
            limit: Maximum number of records to return
            
        Returns:
            List[InvestmentResponse]: List of investment details
        """
        investments = self.db.query(Investment).filter(
            Investment.account_id == account_id,
            Investment.is_active == True
        ).offset(skip).limit(limit).all()
        
        return [InvestmentResponse.from_orm(inv) for inv in investments]

    def sync_investment_values(
        self,
        investment_id: UUID,
        current_value: Decimal,
        quantity: Optional[Decimal] = None
    ) -> InvestmentResponse:
        """
        Update investment values and performance metrics.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements real-time value updates
        
        Args:
            investment_id: UUID of investment to update
            current_value: New current market value
            quantity: Optional new quantity if changed
            
        Returns:
            InvestmentResponse: Updated investment details
            
        Raises:
            ValueError: If investment not found or inactive
        """
        investment = self.db.query(Investment).filter(
            Investment.id == investment_id,
            Investment.is_active == True
        ).first()
        
        if not investment:
            raise ValueError(f"Investment {investment_id} not found or inactive")
            
        investment.update_value(current_value=current_value, quantity=quantity)
        investment.last_synced_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(investment)
        
        return InvestmentResponse.from_orm(investment)

    def calculate_portfolio_metrics(self, account_id: UUID) -> Dict:
        """
        Calculate aggregate portfolio metrics.
        
        Requirements addressed:
        - Investment Tracking (1.2): Implements portfolio performance metrics
        
        Args:
            account_id: UUID of the account
            
        Returns:
            Dict containing portfolio metrics:
            - total_value: Current portfolio value
            - total_cost_basis: Total investment cost
            - total_gain_loss: Unrealized gain/loss
            - return_percentage: Overall return percentage
        """
        investments = self.db.query(Investment).filter(
            Investment.account_id == account_id,
            Investment.is_active == True
        ).all()
        
        total_value = sum(inv.current_value for inv in investments)
        total_cost_basis = sum(inv.cost_basis for inv in investments)
        total_gain_loss = total_value - total_cost_basis
        
        # Calculate return percentage, handling division by zero
        return_percentage = (
            (total_gain_loss / total_cost_basis * Decimal('100'))
            if total_cost_basis > Decimal('0')
            else Decimal('0')
        )
        
        return {
            "total_value": str(total_value),
            "total_cost_basis": str(total_cost_basis),
            "total_gain_loss": str(total_gain_loss),
            "return_percentage": str(return_percentage)
        }