"""
Configuration module for Mint Replica Lite backend application.

Human Tasks:
1. Create and configure .env file with required environment variables
2. Set up AWS credentials and S3 bucket for production environment
3. Configure Plaid API credentials and environment settings
4. Generate and securely store production SECRET_KEY
5. Set up PostgreSQL and Redis credentials for production
"""

# Library versions:
# pydantic==1.9.0
# python-dotenv==0.19.0
# pathlib from Python 3.9.0

from pathlib import Path
from pydantic import BaseSettings, SecretStr
from dotenv import load_dotenv

from app.constants import (
    API_VERSION,
    API_PREFIX,
    JWT_ALGORITHM,
    ENCRYPTION_ALGORITHM
)

# Project root directory path
BASE_DIR = Path(__file__).resolve().parent.parent

# Load environment variables from .env file if it exists
load_dotenv(BASE_DIR / '.env')

class AppSettings(BaseSettings):
    """
    Application settings management with environment variable support and validation.
    
    Requirement: System Configuration - Define and manage core system configuration settings
    """
    # Application Settings
    PROJECT_NAME: str = "Mint Replica Lite"
    ENVIRONMENT: str = "development"
    DEBUG: str = "False"
    
    # API Settings
    API_VERSION: str = API_VERSION
    API_PREFIX: str = API_PREFIX
    
    # Security Settings
    # Requirement: Security Configuration - Configure security parameters and JWT settings
    SECRET_KEY: SecretStr
    JWT_ALGORITHM: str = JWT_ALGORITHM
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Database Settings
    # Requirement: Infrastructure Configuration - Configure database connections
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_PORT: int = 5432
    POSTGRES_DB: str = "mintreplicadb"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: SecretStr
    
    # Redis Settings
    # Requirement: Infrastructure Configuration - Configure cache service
    REDIS_HOST: str = "localhost"
    REDIS_PORT: int = 6379
    REDIS_PASSWORD: SecretStr
    
    # AWS Settings
    # Requirement: Infrastructure Configuration - Configure cloud service connections
    AWS_REGION: str = "us-east-1"
    AWS_ACCESS_KEY_ID: SecretStr
    AWS_SECRET_ACCESS_KEY: SecretStr
    S3_BUCKET_NAME: str = "mintreplica-storage"
    
    # Plaid API Settings
    PLAID_CLIENT_ID: SecretStr
    PLAID_SECRET: SecretStr
    PLAID_ENVIRONMENT: str = "sandbox"
    
    # Encryption Settings
    # Requirement: Security Configuration - Configure encryption options
    ENCRYPTION_ALGORITHM: str = ENCRYPTION_ALGORITHM
    
    class Config:
        """Pydantic settings configuration"""
        case_sensitive = True
        env_file = '.env'
        
    def get_database_url(self) -> str:
        """
        Construct PostgreSQL database URL from settings.
        
        Returns:
            str: Complete PostgreSQL connection URL with credentials
        """
        return (
            f"postgresql://{self.POSTGRES_USER}:"
            f"{self.POSTGRES_PASSWORD.get_secret_value()}@"
            f"{self.POSTGRES_SERVER}:{self.POSTGRES_PORT}/"
            f"{self.POSTGRES_DB}"
        )
    
    def get_redis_url(self) -> str:
        """
        Construct Redis connection URL from settings.
        
        Returns:
            str: Complete Redis connection URL with credentials
        """
        if self.REDIS_PASSWORD:
            return (
                f"redis://:{self.REDIS_PASSWORD.get_secret_value()}@"
                f"{self.REDIS_HOST}:{self.REDIS_PORT}/0"
            )
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/0"
    
    def get_plaid_environment(self) -> str:
        """
        Get Plaid API environment configuration based on application environment.
        
        Returns:
            str: Plaid environment name (sandbox/development/production)
        """
        env_mapping = {
            "development": "sandbox",
            "staging": "development",
            "production": "production"
        }
        return env_mapping.get(self.ENVIRONMENT.lower(), "sandbox")

# Global settings instance
settings = AppSettings()