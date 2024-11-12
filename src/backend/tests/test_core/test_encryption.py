"""
Test suite for core encryption functionality.

Human Tasks:
1. Ensure AWS KMS key ID is configured in test environment variables
2. Verify test AWS credentials are properly configured
3. Configure moto test environment for AWS mocking
4. Review test coverage requirements for encryption module
"""

# pytest: ^7.0.0
import pytest
# pytest-mock: ^3.10.0
from pytest_mock import MockerFixture
# moto: ^4.0.0
from moto import mock_kms

import os
import json
from typing import Dict, Any

from app.core.encryption import EncryptionManager
from app.utils.crypto import generate_salt

# Test constants
TEST_KMS_KEY_ID = "test-key-id-12345"
TEST_DATA = "sensitive-test-data-12345"
TEST_FILE_DATA = b"sensitive-file-content-12345"

@pytest.fixture
def encryption_manager():
    """
    Requirement: Key Management Testing - 6.2 Data Security/6.2.1 Encryption Implementation
    Sets up encryption manager with mocked KMS for testing.
    """
    with mock_kms():
        # Set up test environment
        os.environ['AWS_KMS_KEY_ID'] = TEST_KMS_KEY_ID
        
        # Create encryption manager instance
        manager = EncryptionManager()
        yield manager
        
        # Cleanup
        del os.environ['AWS_KMS_KEY_ID']

class TestEncryption:
    """Test class for encryption functionality validation."""
    
    def setup_method(self, method):
        """Set up test environment before each test."""
        # Initialize test data
        self.test_data = TEST_DATA
        self.test_file_data = TEST_FILE_DATA
        self.test_salt = generate_salt(16)
    
    def teardown_method(self, method):
        """Clean up after each test."""
        # Clear test data
        self.test_data = None
        self.test_file_data = None
        self.test_salt = None

    def test_encryption_manager_initialization(self, encryption_manager: EncryptionManager):
        """
        Requirement: Key Management Testing - 6.2 Data Security/6.2.1 Encryption Implementation
        Tests proper initialization of EncryptionManager with KMS integration.
        """
        assert encryption_manager._kms_client is not None
        assert encryption_manager._key is not None
        assert len(encryption_manager._key) == 32  # AES-256 key length

    def test_field_encryption_decryption(self, encryption_manager: EncryptionManager):
        """
        Requirement: Data Encryption Testing - 6. Security Considerations/6.2 Data Security/6.2.1 Encryption Implementation
        Tests field-level encryption and decryption using AES-256-GCM.
        """
        # Test with string data
        encrypted_data = encryption_manager.encrypt_field(self.test_data)
        
        # Verify encrypted data structure
        assert 'ciphertext' in encrypted_data
        assert 'nonce' in encrypted_data
        assert 'tag' in encrypted_data
        assert len(encrypted_data['nonce']) == 12  # GCM nonce length
        assert len(encrypted_data['tag']) == 16    # GCM tag length
        
        # Test decryption
        decrypted_data = encryption_manager.decrypt_field(encrypted_data)
        assert decrypted_data.decode('utf-8') == self.test_data

    def test_file_encryption_decryption(self, encryption_manager: EncryptionManager):
        """
        Requirement: Data Encryption Testing - 6. Security Considerations/6.2 Data Security/6.2.1 Encryption Implementation
        Tests file encryption and decryption using AES-256-CBC.
        """
        # Encrypt file data
        encrypted_data, iv = encryption_manager.encrypt_file(self.test_file_data)
        
        # Verify encryption results
        assert len(iv) == 16  # AES block size
        assert len(encrypted_data) > 0
        assert encrypted_data != self.test_file_data
        
        # Test decryption
        decrypted_data = encryption_manager.decrypt_file(encrypted_data, iv)
        assert decrypted_data == self.test_file_data

    def test_key_rotation(self, encryption_manager: EncryptionManager, mocker: MockerFixture):
        """
        Requirement: Key Management Testing - 6.2 Data Security/6.2.1 Encryption Implementation
        Tests encryption key rotation functionality with AWS KMS.
        """
        # Encrypt data with initial key
        initial_encrypted = encryption_manager.encrypt_field(self.test_data)
        initial_key = encryption_manager._key
        
        # Mock KMS response for new key
        mock_kms_response = {
            'Plaintext': os.urandom(32),
            'CiphertextBlob': b'mock-encrypted-key'
        }
        mocker.patch.object(
            encryption_manager._kms_client,
            'generate_data_key',
            return_value=mock_kms_response
        )
        
        # Perform key rotation
        encryption_manager.rotate_key()
        
        # Verify key was rotated
        assert encryption_manager._key != initial_key
        assert len(encryption_manager._key) == 32
        
        # Verify new key can encrypt/decrypt
        new_encrypted = encryption_manager.encrypt_field(self.test_data)
        decrypted = encryption_manager.decrypt_field(new_encrypted)
        assert decrypted.decode('utf-8') == self.test_data

    def test_encryption_error_handling(self, encryption_manager: EncryptionManager):
        """
        Requirement: Sensitive Data Protection Testing - 6.2 Data Security/6.2.2 Sensitive Data Handling
        Tests error handling in encryption/decryption operations.
        """
        # Test invalid input data
        with pytest.raises(TypeError):
            encryption_manager.encrypt_field(None)
        
        with pytest.raises(ValueError):
            encryption_manager.encrypt_field("")
        
        # Test corrupted encrypted data
        encrypted_data = encryption_manager.encrypt_field(self.test_data)
        corrupted_data = encrypted_data.copy()
        corrupted_data['ciphertext'] = os.urandom(32)
        
        with pytest.raises(ValueError):
            encryption_manager.decrypt_field(corrupted_data)
        
        # Test invalid nonce
        invalid_nonce = encrypted_data.copy()
        invalid_nonce['nonce'] = os.urandom(12)
        
        with pytest.raises(ValueError):
            encryption_manager.decrypt_field(invalid_nonce)
        
        # Test invalid authentication tag
        invalid_tag = encrypted_data.copy()
        invalid_tag['tag'] = os.urandom(16)
        
        with pytest.raises(ValueError):
            encryption_manager.decrypt_field(invalid_tag)

    def test_sensitive_data_encryption(self, encryption_manager: EncryptionManager):
        """
        Requirement: Sensitive Data Protection Testing - 6.2 Data Security/6.2.2 Sensitive Data Handling
        Tests encryption of sensitive financial and personal information.
        """
        sensitive_data = {
            'account_number': '1234-5678-9012-3456',
            'ssn': '123-45-6789',
            'api_key': 'sk_test_abcdef123456',
            'credentials': {
                'username': 'testuser',
                'password': 'testpass123'
            }
        }
        
        # Encrypt each sensitive field
        encrypted_fields = {}
        for key, value in sensitive_data.items():
            if isinstance(value, dict):
                encrypted_fields[key] = {
                    k: encryption_manager.encrypt_field(v)
                    for k, v in value.items()
                }
            else:
                encrypted_fields[key] = encryption_manager.encrypt_field(value)
        
        # Verify all fields were encrypted
        for key, value in encrypted_fields.items():
            if isinstance(value, dict):
                for k, v in value.items():
                    assert 'ciphertext' in v
                    assert 'nonce' in v
                    assert 'tag' in v
            else:
                assert 'ciphertext' in value
                assert 'nonce' in value
                assert 'tag' in value
        
        # Verify decryption of all fields
        for key, value in encrypted_fields.items():
            if isinstance(value, dict):
                decrypted = {
                    k: encryption_manager.decrypt_field(v).decode('utf-8')
                    for k, v in value.items()
                }
                assert decrypted == sensitive_data[key]
            else:
                decrypted = encryption_manager.decrypt_field(value).decode('utf-8')
                assert decrypted == sensitive_data[key]