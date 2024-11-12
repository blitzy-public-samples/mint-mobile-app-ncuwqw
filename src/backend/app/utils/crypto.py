"""
Cryptographic utility module for Mint Replica Lite system.

Human Tasks:
1. Verify bcrypt rounds (BCRYPT_ROUNDS) meets current security standards for production
2. Ensure PBKDF2 iterations count is sufficient for production environment
3. Review and validate key lengths meet security requirements
4. Confirm AES-256-GCM implementation aligns with security policies
"""

# hashlib: ^3.9.0
# secrets: ^3.9.0
# bcrypt: ^4.0.1
# cryptography: ^41.0.0
# typing: ^3.9.0

import hashlib
import secrets
import bcrypt
from typing import Union
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from ..constants import ENCRYPTION_ALGORITHM

# Global constants
# Requirement: Data Security - 6.2.2 Sensitive Data Handling
HASH_ALGORITHM: str = 'sha256'
SALT_LENGTH: int = 32
BCRYPT_ROUNDS: int = 12

def generate_salt(length: int) -> bytes:
    """
    Requirement: Data Security - 6.2.1 Encryption Implementation
    Generates a cryptographically secure random salt.
    
    Args:
        length: Length of salt in bytes
        
    Returns:
        Cryptographically secure random salt
        
    Raises:
        ValueError: If length is not positive
    """
    if length <= 0:
        raise ValueError("Salt length must be positive")
    return secrets.token_bytes(length)

def hash_password(password: str) -> bytes:
    """
    Requirement: Password Security - 6.2.2 Sensitive Data Handling
    Securely hashes a password using bcrypt with configurable rounds.
    
    Args:
        password: Plain text password to hash
        
    Returns:
        Bcrypt hashed password with salt
    """
    password_bytes = password.encode('utf-8')
    salt = bcrypt.gensalt(rounds=BCRYPT_ROUNDS)
    return bcrypt.hashpw(password_bytes, salt)

def verify_password(password: str, hashed_password: bytes) -> bool:
    """
    Requirement: Password Security - 6.2.2 Sensitive Data Handling
    Verifies a password against its bcrypt hash.
    
    Args:
        password: Plain text password to verify
        hashed_password: Bcrypt hash to verify against
        
    Returns:
        True if password matches hash, False otherwise
    """
    password_bytes = password.encode('utf-8')
    return bcrypt.checkpw(password_bytes, hashed_password)

def generate_key(length: int) -> bytes:
    """
    Requirement: Key Management - 6.2.1 Encryption Implementation
    Generates a cryptographically secure key.
    
    Args:
        length: Length of key in bytes
        
    Returns:
        Cryptographically secure key
        
    Raises:
        ValueError: If length is not positive
    """
    if length <= 0:
        raise ValueError("Key length must be positive")
    return secrets.token_bytes(length)

def compute_hash(data: Union[str, bytes], algorithm: str = HASH_ALGORITHM) -> str:
    """
    Requirement: Data Security - 6.2.1 Encryption Implementation
    Computes cryptographic hash of data using specified algorithm.
    
    Args:
        data: Data to hash (string or bytes)
        algorithm: Hash algorithm to use (default: sha256)
        
    Returns:
        Hexadecimal hash digest
        
    Raises:
        ValueError: If algorithm is not supported
    """
    if isinstance(data, str):
        data = data.encode('utf-8')
    try:
        hash_obj = hashlib.new(algorithm)
        hash_obj.update(data)
        return hash_obj.hexdigest()
    except ValueError as e:
        raise ValueError(f"Unsupported hash algorithm: {algorithm}") from e

class KeyDerivation:
    """
    Requirement: Key Management - 6.2.1 Encryption Implementation
    Handles secure key derivation operations using PBKDF2-HMAC-SHA256.
    """
    
    def __init__(self, iterations: int, key_length: int):
        """
        Initialize key derivation parameters.
        
        Args:
            iterations: Number of PBKDF2 iterations
            key_length: Length of derived key in bytes
            
        Raises:
            ValueError: If iterations or key_length is not positive
        """
        if iterations <= 0:
            raise ValueError("Iterations must be positive")
        if key_length <= 0:
            raise ValueError("Key length must be positive")
        
        self._iterations = iterations
        self._key_length = key_length

    def derive_key(self, password: str, salt: bytes) -> bytes:
        """
        Derives a key from password and salt using PBKDF2-HMAC-SHA256.
        
        Args:
            password: Password to derive key from
            salt: Salt for key derivation
            
        Returns:
            Derived key of specified length
        """
        password_bytes = password.encode('utf-8')
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=self._key_length,
            salt=salt,
            iterations=self._iterations
        )
        return kdf.derive(password_bytes)