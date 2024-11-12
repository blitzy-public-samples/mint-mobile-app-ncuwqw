"""
SQLAlchemy User model for the Mint Replica Lite application.

Human Tasks:
1. Verify database user has appropriate permissions for user table operations
2. Review password complexity requirements and update validation if needed
3. Configure email verification workflow if required
4. Set up backup strategy for user data
"""

# SQLAlchemy: ^1.4.0
from sqlalchemy import Column, String, Boolean, DateTime, UUID
from sqlalchemy.orm import relationship
from datetime import datetime
from uuid import uuid4

from ..db.base import Base
from ..core.security import get_password_hash, verify_password_hash

class User(Base):
    """
    User model representing application users with secure authentication and profile management.
    
    Requirements addressed:
    - Account Management (1.2): Implements multi-platform user authentication and profile management
    - Data Security (6.2.2): Secure storage of user credentials and personal information
    - Authentication Flow (6.1.1): Supports secure authentication and session management
    """
    
    # Primary key using UUID for enhanced security and scalability
    id = Column(UUID, primary_key=True, default=uuid4, index=True)
    
    # User profile and authentication fields
    email = Column(String(255), unique=True, index=True, nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    password_hash = Column(String(255), nullable=False)
    
    # Account status flags
    is_active = Column(Boolean, default=True, nullable=False)
    is_superuser = Column(Boolean, default=False, nullable=False)
    
    # Timestamps for auditing
    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships with financial data
    accounts = relationship("Account", back_populates="user", cascade="all, delete-orphan")
    budgets = relationship("Budget", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    transactions = relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    
    def __init__(
        self,
        email: str,
        first_name: str,
        last_name: str,
        password: str,
        is_active: bool = True,
        is_superuser: bool = False
    ):
        """
        Initialize a new User instance with secure password handling.
        
        Args:
            email: User's email address
            first_name: User's first name
            last_name: User's last name
            password: Plain text password (will be hashed)
            is_active: Account status flag
            is_superuser: Administrative privileges flag
        """
        self.id = uuid4()
        self.email = email.lower().strip()
        self.first_name = first_name.strip()
        self.last_name = last_name.strip()
        self.password_hash = get_password_hash(password)
        self.is_active = is_active
        self.is_superuser = is_superuser
        self.created_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()
    
    def verify_password(self, password: str) -> bool:
        """
        Verify a password against the stored hash using bcrypt.
        
        Requirement addressed:
        - Data Security (6.2.2): Secure verification of user credentials
        
        Args:
            password: Plain text password to verify
            
        Returns:
            bool: True if password matches hash, False otherwise
        """
        return verify_password_hash(password, self.password_hash)
    
    def set_password(self, password: str) -> None:
        """
        Update the user's password with a new bcrypt hash.
        
        Requirement addressed:
        - Data Security (6.2.2): Secure handling of password updates
        
        Args:
            password: New plain text password to hash and store
        """
        self.password_hash = get_password_hash(password)
        self.updated_at = datetime.utcnow()