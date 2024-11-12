"""
Core encryption module implementing AES-256 encryption for field-level and file encryption.

Human Tasks:
1. Ensure AWS KMS key ID is properly configured in environment variables (AWS_KMS_KEY_ID)
2. Verify AWS IAM permissions for KMS key access
3. Configure AWS credentials in deployment environment
4. Review and validate encryption settings in production environment
5. Set up key rotation schedule in AWS KMS
"""

# cryptography: ^41.0.0
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend

# boto3: ^1.26.0
import boto3

# secrets: ^3.9.0
import secrets

# typing: ^3.9.0
from typing import Union, BinaryIO, Dict, Tuple

# os: ^3.9.0
import os

# Internal imports
from app.constants import ENCRYPTION_ALGORITHM

# Global constants
KMS_KEY_ID = os.getenv('AWS_KMS_KEY_ID')
NONCE_LENGTH = 12  # Standard length for GCM nonce
TAG_LENGTH = 16    # Standard length for authentication tag
SALT_LENGTH = 16   # Standard length for salt

def generate_salt(length: int) -> bytes:
    """
    Generates a cryptographically secure random salt.
    
    Requirement: Data Security/6.2.2 Sensitive Data Handling
    Implements secure salt generation for encryption operations.
    
    Args:
        length: Length of salt to generate
        
    Returns:
        Random salt bytes of specified length
    
    Raises:
        ValueError: If length is not positive
    """
    if length <= 0:
        raise ValueError("Salt length must be positive")
    return secrets.token_bytes(length)

class EncryptionManager:
    """
    Manages encryption and decryption operations using AES-256.
    
    Requirement: Data Encryption/6.2.1 Encryption Implementation
    Implements AES-256-GCM for field-level encryption and AES-256-CBC for file encryption.
    """
    
    def __init__(self):
        """Initialize encryption manager with KMS integration."""
        if not KMS_KEY_ID:
            raise ValueError("AWS KMS key ID not configured")
        
        self._algorithm = ENCRYPTION_ALGORITHM
        self._kms_client = boto3.client('kms')
        
        # Generate initial encryption key using KMS
        response = self._kms_client.generate_data_key(
            KeyId=KMS_KEY_ID,
            KeySpec='AES_256'
        )
        self._key = response['Plaintext']
    
    def encrypt_field(self, data: Union[str, bytes]) -> Dict[str, bytes]:
        """
        Encrypts a field value using AES-256-GCM with authenticated encryption.
        
        Requirement: Sensitive Data Protection/6.2.2 Sensitive Data Handling
        Implements secure field-level encryption for sensitive data.
        
        Args:
            data: Data to encrypt (string or bytes)
            
        Returns:
            Dictionary containing encrypted data, nonce and authentication tag
        """
        if isinstance(data, str):
            data = data.encode('utf-8')
            
        nonce = secrets.token_bytes(NONCE_LENGTH)
        aesgcm = AESGCM(self._key)
        ciphertext = aesgcm.encrypt(nonce, data, None)
        
        # Split ciphertext and authentication tag
        encrypted_data = ciphertext[:-TAG_LENGTH]
        tag = ciphertext[-TAG_LENGTH:]
        
        return {
            'ciphertext': encrypted_data,
            'nonce': nonce,
            'tag': tag
        }
    
    def decrypt_field(self, encrypted_data: Dict[str, bytes]) -> bytes:
        """
        Decrypts an encrypted field value with authentication check.
        
        Requirement: Data Encryption/6.2.1 Encryption Implementation
        Implements secure field-level decryption with authentication.
        
        Args:
            encrypted_data: Dictionary containing ciphertext, nonce and tag
            
        Returns:
            Decrypted data as bytes
        """
        ciphertext = encrypted_data['ciphertext'] + encrypted_data['tag']
        nonce = encrypted_data['nonce']
        
        aesgcm = AESGCM(self._key)
        return aesgcm.decrypt(nonce, ciphertext, None)
    
    def encrypt_file(self, file_data: Union[str, bytes, BinaryIO]) -> Tuple[bytes, bytes]:
        """
        Encrypts a file using AES-256-CBC with random IV.
        
        Requirement: Data Encryption/6.2.1 Encryption Implementation
        Implements secure file encryption using AES-256-CBC.
        
        Args:
            file_data: File data to encrypt
            
        Returns:
            Tuple of (encrypted_data, initialization_vector)
        """
        if isinstance(file_data, str):
            file_data = file_data.encode('utf-8')
        elif hasattr(file_data, 'read'):
            file_data = file_data.read()
            
        iv = secrets.token_bytes(16)  # AES block size
        
        # Set up CBC cipher
        cipher = Cipher(
            algorithms.AES(self._key),
            modes.CBC(iv),
            backend=default_backend()
        )
        encryptor = cipher.encryptor()
        
        # Apply padding
        padder = padding.PKCS7(algorithms.AES.block_size).padder()
        padded_data = padder.update(file_data) + padder.finalize()
        
        # Encrypt
        encrypted_data = encryptor.update(padded_data) + encryptor.finalize()
        
        return encrypted_data, iv
    
    def decrypt_file(self, encrypted_data: bytes, iv: bytes) -> bytes:
        """
        Decrypts an encrypted file using AES-256-CBC.
        
        Requirement: Data Encryption/6.2.1 Encryption Implementation
        Implements secure file decryption using AES-256-CBC.
        
        Args:
            encrypted_data: Encrypted file data
            iv: Initialization vector used for encryption
            
        Returns:
            Decrypted file data
        """
        # Set up CBC cipher
        cipher = Cipher(
            algorithms.AES(self._key),
            modes.CBC(iv),
            backend=default_backend()
        )
        decryptor = cipher.decryptor()
        
        # Decrypt
        padded_data = decryptor.update(encrypted_data) + decryptor.finalize()
        
        # Remove padding
        unpadder = padding.PKCS7(algorithms.AES.block_size).unpadder()
        return unpadder.update(padded_data) + unpadder.finalize()
    
    def rotate_key(self) -> None:
        """
        Rotates the encryption key using AWS KMS.
        
        Requirement: Key Management/6.2.1 Encryption Implementation
        Implements secure key rotation using AWS KMS.
        """
        # Generate new key using KMS
        response = self._kms_client.generate_data_key(
            KeyId=KMS_KEY_ID,
            KeySpec='AES_256'
        )
        new_key = response['Plaintext']
        
        # Securely replace the old key
        old_key = self._key
        self._key = new_key
        
        # Securely clear old key from memory
        for i in range(len(old_key)):
            old_key[i:i+1] = b'\x00'