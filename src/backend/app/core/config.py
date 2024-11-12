"""
Core configuration module for Mint Replica Lite backend application.

Human Tasks:
1. Set up environment variables in deployment environments (.env files)
2. Configure AWS IAM roles and permissions for S3 access
3. Set up Plaid developer account and obtain API credentials
4. Configure Redis instance and security groups
5. Set up PostgreSQL database and connection parameters
6. Review and update security settings for production deployment
"""

# Library versions:
# pydantic: ^1.8.2
# typing: ^3.9.0

from functools import lru_cache
import os
import secrets
from typing import Dict, Optional
from urllib.parse import urlparse

from pydantic import BaseSettings

from ..constants import (
    API_VERSION,
    API_PREFIX,
    ENCRYPTION_ALGORITHM,
)

class Settings(BaseSettings):
    """
    Main application settings class using Pydantic BaseSettings for environment
    variable loading and validation.
    
    Requirement: System Configuration - Configure core system components
    """
    # Application Settings
    PROJECT_NAME: str = "Mint Replica Lite"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DEBUG: bool = os.getenv("DEBUG", "False").lower() == "true"
    API_V1_PREFIX: str = f"{API_PREFIX}/{API_VERSION}"

    # Security Settings
    # Requirement: Security Configuration - Configure security parameters
    SECRET_KEY: str = os.getenv("SECRET_KEY", generate_secret_key())

    # Database Settings
    # Requirement: Infrastructure Configuration - Configure database connections
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://postgres:postgres@localhost:5432/mint_replica"
    )

    # Redis Cache Settings
    # Requirement: Infrastructure Configuration - Configure caching
    REDIS_URL: str = os.getenv(
        "REDIS_URL",
        "redis://localhost:6379/0"
    )

    # AWS Settings
    # Requirement: Infrastructure Configuration - Configure storage
    S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "")
    AWS_ACCESS_KEY_ID: str = os.getenv("AWS_ACCESS_KEY_ID", "")
    AWS_SECRET_ACCESS_KEY: str = os.getenv("AWS_SECRET_ACCESS_KEY", "")

    # Plaid Integration Settings
    # Requirement: System Configuration - Configure external service integrations
    PLAID_CLIENT_ID: str = os.getenv("PLAID_CLIENT_ID", "")
    PLAID_SECRET: str = os.getenv("PLAID_SECRET", "")
    PLAID_ENVIRONMENT: str = os.getenv("PLAID_ENVIRONMENT", "sandbox")

    class Config:
        case_sensitive = True
        env_file = ".env"
        env_file_encoding = "utf-8"

    def get_database_settings(self) -> Dict[str, str]:
        """
        Parse DATABASE_URL and return database connection settings.
        
        Requirement: Infrastructure Configuration - Database connection parameters
        """
        parsed = urlparse(self.DATABASE_URL)
        return {
            "host": parsed.hostname or "localhost",
            "port": str(parsed.port or 5432),
            "username": parsed.username or "postgres",
            "password": parsed.password or "postgres",
            "database": parsed.path[1:] if parsed.path else "mint_replica",
            "ssl_mode": "prefer" if self.ENVIRONMENT == "production" else "disable"
        }

    def get_redis_settings(self) -> Dict[str, str]:
        """
        Parse REDIS_URL and return Redis connection settings.
        
        Requirement: Infrastructure Configuration - Cache connection parameters
        """
        parsed = urlparse(self.REDIS_URL)
        return {
            "host": parsed.hostname or "localhost",
            "port": str(parsed.port or 6379),
            "db": parsed.path[1:] if parsed.path else "0",
            "password": parsed.password or None,
            "ssl": self.ENVIRONMENT == "production",
            "encoding": "utf-8"
        }

    def get_aws_settings(self) -> Dict[str, str]:
        """
        Return AWS configuration settings.
        
        Requirement: Infrastructure Configuration - Storage configuration
        """
        return {
            "aws_access_key_id": self.AWS_ACCESS_KEY_ID,
            "aws_secret_access_key": self.AWS_SECRET_ACCESS_KEY,
            "region_name": os.getenv("AWS_REGION", "us-east-1"),
            "s3_bucket": self.S3_BUCKET_NAME,
            "encryption_algorithm": ENCRYPTION_ALGORITHM,
            "endpoint_url": os.getenv("AWS_ENDPOINT_URL"),  # For local testing
            "use_ssl": self.ENVIRONMENT == "production"
        }


def generate_secret_key() -> str:
    """
    Generate a secure secret key for application encryption.
    
    Requirement: Security Configuration - Secure key generation
    """
    return secrets.token_urlsafe(32)


@lru_cache()
def get_settings() -> Settings:
    """
    Factory function to get cached application settings instance.
    
    Requirement: System Configuration - Settings management
    """
    return Settings()