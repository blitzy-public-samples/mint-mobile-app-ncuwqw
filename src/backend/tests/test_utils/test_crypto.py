"""
Unit tests for cryptographic utility functions ensuring secure hashing, password handling, and cryptographic operations.

Human Tasks:
1. Review test coverage and add additional test cases if needed
2. Verify test parameters align with security requirements
3. Ensure all error cases and edge conditions are tested
"""

# pytest: ^7.0.0
# unittest.mock: ^3.9.0

import pytest
from app.utils.crypto import (
    generate_salt,
    hash_password,
    verify_password,
    generate_key,
    compute_hash,
    KeyDerivation
)

def pytest_configure(config):
    """
    Configure pytest environment and register markers.
    
    Args:
        config: pytest configuration object
    """
    config.addinivalue_line(
        "markers", "unit: mark test as a unit test"
    )

@pytest.mark.unit
class TestCrypto:
    """Test suite for cryptographic utility functions implementing industry-standard algorithms"""

    def test_generate_salt(self):
        """
        Requirement: Data Security - 6.2.1 Encryption Implementation
        Test salt generation with various lengths.
        """
        # Test default length
        salt = generate_salt(32)
        assert isinstance(salt, bytes)
        assert len(salt) == 32

        # Test custom length
        salt_64 = generate_salt(64)
        assert len(salt_64) == 64

        # Verify uniqueness
        salt1 = generate_salt(32)
        salt2 = generate_salt(32)
        assert salt1 != salt2

        # Test invalid length
        with pytest.raises(ValueError, match="Salt length must be positive"):
            generate_salt(-1)

    def test_hash_password(self):
        """
        Requirement: Password Security - 6.2.2 Sensitive Data Handling
        Test password hashing functionality using bcrypt.
        """
        # Test ASCII password
        password = "SecurePassword123!"
        hashed = hash_password(password)
        assert isinstance(hashed, bytes)
        assert len(hashed) > 0

        # Test empty password
        with pytest.raises(ValueError):
            hash_password("")

        # Test Unicode password
        unicode_password = "パスワード123!@#"
        unicode_hash = hash_password(unicode_password)
        assert isinstance(unicode_hash, bytes)

        # Verify different passwords produce different hashes
        hash1 = hash_password("password1")
        hash2 = hash_password("password2")
        assert hash1 != hash2

        # Verify same password produces different hashes
        hash3 = hash_password("password1")
        assert hash1 != hash3  # Due to random salt

    def test_verify_password(self):
        """
        Requirement: Password Security - 6.2.2 Sensitive Data Handling
        Test password verification against bcrypt hashes.
        """
        password = "SecurePassword123!"
        hashed = hash_password(password)

        # Test correct password
        assert verify_password(password, hashed) is True

        # Test incorrect password
        assert verify_password("WrongPassword123!", hashed) is False

        # Test empty password
        with pytest.raises(ValueError):
            verify_password("", hashed)

        # Test Unicode password
        unicode_password = "パスワード123!@#"
        unicode_hash = hash_password(unicode_password)
        assert verify_password(unicode_password, unicode_hash) is True

        # Test invalid hash format
        with pytest.raises(ValueError):
            verify_password(password, b"invalid_hash_format")

    def test_generate_key(self):
        """
        Requirement: Key Management - 6.2.1 Encryption Implementation
        Test cryptographic key generation.
        """
        # Test default length
        key = generate_key(32)
        assert isinstance(key, bytes)
        assert len(key) == 32

        # Test custom length
        key_64 = generate_key(64)
        assert len(key_64) == 64

        # Verify uniqueness
        key1 = generate_key(32)
        key2 = generate_key(32)
        assert key1 != key2

        # Test invalid length
        with pytest.raises(ValueError, match="Key length must be positive"):
            generate_key(-1)

    def test_compute_hash(self):
        """
        Requirement: Data Security - 6.2.1 Encryption Implementation
        Test hash computation with different algorithms.
        """
        test_data = "test_data"
        test_bytes = b"test_bytes"

        # Test string input with SHA-256
        hash1 = compute_hash(test_data)
        assert isinstance(hash1, str)
        assert len(hash1) == 64  # SHA-256 produces 64 hex chars

        # Test bytes input with SHA-256
        hash2 = compute_hash(test_bytes)
        assert isinstance(hash2, str)
        assert len(hash2) == 64

        # Test different algorithms
        hash_512 = compute_hash(test_data, "sha512")
        assert len(hash_512) == 128  # SHA-512 produces 128 hex chars

        hash_384 = compute_hash(test_data, "sha384")
        assert len(hash_384) == 96  # SHA-384 produces 96 hex chars

        # Verify consistent results
        assert compute_hash(test_data) == compute_hash(test_data)

        # Test invalid algorithm
        with pytest.raises(ValueError, match="Unsupported hash algorithm"):
            compute_hash(test_data, "invalid_algo")

        # Test empty input
        empty_hash = compute_hash("")
        assert isinstance(empty_hash, str)
        assert len(empty_hash) == 64

    def test_key_derivation(self):
        """
        Requirement: Key Management - 6.2.1 Encryption Implementation
        Test key derivation functionality using PBKDF2-HMAC-SHA256.
        """
        # Initialize with standard parameters
        kdf = KeyDerivation(iterations=100000, key_length=32)

        # Test key derivation
        password = "SecurePassword123!"
        salt = generate_salt(32)
        derived_key = kdf.derive_key(password, salt)
        assert isinstance(derived_key, bytes)
        assert len(derived_key) == 32

        # Test different iteration counts
        kdf_low = KeyDerivation(iterations=10000, key_length=32)
        key_low = kdf_low.derive_key(password, salt)
        assert key_low != derived_key

        # Verify consistent derivation
        key1 = kdf.derive_key(password, salt)
        key2 = kdf.derive_key(password, salt)
        assert key1 == key2

        # Test empty password
        with pytest.raises(ValueError):
            kdf.derive_key("", salt)

        # Test invalid parameters
        with pytest.raises(ValueError, match="Iterations must be positive"):
            KeyDerivation(iterations=0, key_length=32)

        with pytest.raises(ValueError, match="Key length must be positive"):
            KeyDerivation(iterations=100000, key_length=0)