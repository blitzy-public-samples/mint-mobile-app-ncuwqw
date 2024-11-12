"""
Services package initialization module that exports all service classes and provides centralized
service layer access for the Mint Replica Lite backend application.

Requirements addressed:
- System Architecture (2.1 High-Level Architecture Overview/Application Layer):
  Implements service layer components including Authentication, Transaction, Budget, Investment,
  Goal, Notification, and Sync services
- Component Architecture (2.2 Component Architecture/2.2.1 Client Applications/Shared Services):
  Provides unified access to backend services through a well-defined service layer

Human Tasks:
1. Review and verify all service dependencies are properly configured
2. Ensure database connection pools are optimized for service layer usage
3. Configure monitoring for service layer operations
4. Set up logging for cross-service interactions
"""

# Import all service classes
from .auth_service import AuthService
from .account_service import AccountService
from .transaction_service import TransactionService
from .budget_service import BudgetService
from .goal_service import GoalService
from .investment_service import InvestmentService
from .notification_service import NotificationService
from .plaid_service import PlaidService
from .sync_service import SyncService

# Define package exports
__all__ = [
    "AuthService",
    "AccountService", 
    "TransactionService",
    "BudgetService",
    "GoalService",
    "InvestmentService",
    "NotificationService",
    "PlaidService",
    "SyncService"
]