"""
Test suite for the User model, verifying user authentication, profile management, and data integrity.

Human Tasks:
1. Configure test database with appropriate user permissions
2. Set up test environment variables for database connections
3. Review and update test data to match production requirements
4. Ensure test database is properly isolated from production
"""

# pytest: ^7.0.0
import pytest
from datetime import datetime
from uuid import UUID

# Internal imports using relative paths
from ...app.models.user import User
from ...app.core.security import get_password_hash, verify_password_hash

class TestUser:
    """Test suite class for User model verification."""
    
    def setup_method(self, method):
        """
        Setup method run before each test.
        
        Args:
            method: pytest method reference
        """
        self.test_email = "test@example.com"
        self.test_password = "SecurePass123!"
        self.test_first_name = "John"
        self.test_last_name = "Doe"
        
    def teardown_method(self, method):
        """
        Cleanup method run after each test.
        
        Args:
            method: pytest method reference
        """
        pass

    @pytest.mark.unit
    def test_create_user(self):
        """
        Tests user creation with valid data.
        
        Requirement: Account Management (1.2)
        Verifies proper initialization of user attributes and profile data.
        """
        user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        
        # Verify basic attributes
        assert user.email == self.test_email
        assert user.first_name == self.test_first_name
        assert user.last_name == self.test_last_name
        
        # Verify UUID generation
        assert isinstance(user.id, UUID)
        
        # Verify timestamps
        assert isinstance(user.created_at, datetime)
        assert isinstance(user.updated_at, datetime)
        
        # Verify default flags
        assert user.is_active is True
        assert user.is_superuser is False

    @pytest.mark.unit
    def test_user_password_hashing(self):
        """
        Tests password hashing and verification.
        
        Requirement: Data Security (6.2.2)
        Verifies secure storage and handling of user credentials.
        """
        user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        
        # Verify password is hashed
        assert user.password_hash != self.test_password
        assert len(user.password_hash) > 0
        
        # Verify password verification
        assert user.verify_password(self.test_password) is True
        assert user.verify_password("WrongPassword123!") is False
        
        # Verify bcrypt format
        assert user.password_hash.startswith("$2b$")

    @pytest.mark.unit
    def test_user_relationships(self):
        """
        Tests user relationships with financial data.
        
        Requirement: Account Management (1.2)
        Verifies proper initialization of user financial relationships.
        """
        user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        
        # Verify relationship initialization
        assert hasattr(user, 'accounts')
        assert hasattr(user, 'budgets')
        assert hasattr(user, 'goals')
        assert hasattr(user, 'transactions')
        
        # Verify relationships are empty lists by default
        assert len(user.accounts) == 0
        assert len(user.budgets) == 0
        assert len(user.goals) == 0
        assert len(user.transactions) == 0

    @pytest.mark.unit
    def test_user_active_status(self):
        """
        Tests user active status management.
        
        Requirement: Authentication Flow (6.1.1)
        Verifies proper handling of user account status.
        """
        # Test active user
        active_user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name,
            is_active=True
        )
        assert active_user.is_active is True
        
        # Test inactive user
        inactive_user = User(
            email="inactive@example.com",
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name,
            is_active=False
        )
        assert inactive_user.is_active is False

    @pytest.mark.unit
    def test_user_superuser_status(self):
        """
        Tests superuser flag management.
        
        Requirement: Authentication Flow (6.1.1)
        Verifies proper handling of administrative privileges.
        """
        # Test regular user
        regular_user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name,
            is_superuser=False
        )
        assert regular_user.is_superuser is False
        
        # Test superuser
        super_user = User(
            email="admin@example.com",
            password=self.test_password,
            first_name="Admin",
            last_name="User",
            is_superuser=True
        )
        assert super_user.is_superuser is True

    @pytest.mark.unit
    def test_user_email_validation(self):
        """
        Tests email format validation.
        
        Requirement: Data Security (6.2.2)
        Verifies proper handling and validation of user email addresses.
        """
        # Test valid email
        user = User(
            email=self.test_email,
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        assert user.email == self.test_email
        
        # Test email normalization
        user_caps = User(
            email="TEST@EXAMPLE.COM",
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        assert user_caps.email == "test@example.com"
        
        # Test email stripping
        user_spaces = User(
            email="  test@example.com  ",
            password=self.test_password,
            first_name=self.test_first_name,
            last_name=self.test_last_name
        )
        assert user_spaces.email == "test@example.com"