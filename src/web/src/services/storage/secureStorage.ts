/**
 * HUMAN TASKS:
 * 1. Ensure REACT_APP_STORAGE_ENCRYPTION_KEY is properly set in environment variables
 * 2. Verify browser compatibility for AsyncStorage in target environments
 * 3. Configure proper error monitoring for storage operations
 * 4. Implement secure key rotation mechanism for production deployment
 * 5. Set up proper security headers for storage access
 */

// @react-native-async-storage/async-storage version: ^1.19.0
import AsyncStorage from '@react-native-async-storage/async-storage';
import { encryptData, decryptData } from '../../utils/encryption';

// Storage namespace prefix to isolate application data
const STORAGE_PREFIX = '@mint_replica_lite/';
const ENCRYPTION_KEY = process.env.REACT_APP_STORAGE_ENCRYPTION_KEY;

/**
 * Validates storage key to ensure it meets security requirements
 * Requirement: 6.3 Security Protocols/6.3.1 Security Standards Compliance
 */
const validateKey = (key: string): void => {
    if (!key || typeof key !== 'string' || key.trim().length === 0) {
        throw new Error('Storage key must be a non-empty string');
    }
};

/**
 * Validates that encryption key is available
 * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
 */
const validateEncryptionKey = (): void => {
    if (!ENCRYPTION_KEY) {
        throw new Error('Storage encryption key is not configured');
    }
};

/**
 * Secure storage implementation with AES-256-GCM encryption
 * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
 */
export const SecureStorage = {
    /**
     * Securely stores encrypted data
     * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
     */
    async setItem(key: string, value: any): Promise<void> {
        validateKey(key);
        validateEncryptionKey();

        if (value === undefined) {
            throw new Error('Storage value must be defined');
        }

        try {
            const prefixedKey = STORAGE_PREFIX + key;
            const encryptedValue = await encryptData(value, ENCRYPTION_KEY!);
            await AsyncStorage.setItem(prefixedKey, encryptedValue);
        } catch (error) {
            throw new Error(`Failed to securely store data: ${error.message}`);
        }
    },

    /**
     * Retrieves and decrypts stored data
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async getItem(key: string): Promise<any | null> {
        validateKey(key);
        validateEncryptionKey();

        try {
            const prefixedKey = STORAGE_PREFIX + key;
            const encryptedValue = await AsyncStorage.getItem(prefixedKey);

            if (!encryptedValue) {
                return null;
            }

            return await decryptData(encryptedValue, ENCRYPTION_KEY!);
        } catch (error) {
            throw new Error(`Failed to retrieve secure data: ${error.message}`);
        }
    },

    /**
     * Removes item from secure storage
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async removeItem(key: string): Promise<void> {
        validateKey(key);

        try {
            const prefixedKey = STORAGE_PREFIX + key;
            await AsyncStorage.removeItem(prefixedKey);
        } catch (error) {
            throw new Error(`Failed to remove secure data: ${error.message}`);
        }
    },

    /**
     * Clears all securely stored data within the application namespace
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async clear(): Promise<void> {
        try {
            const allKeys = await AsyncStorage.getAllKeys();
            const namespacedKeys = allKeys.filter(key => key.startsWith(STORAGE_PREFIX));
            
            if (namespacedKeys.length > 0) {
                await AsyncStorage.multiRemove(namespacedKeys);
            }
        } catch (error) {
            throw new Error(`Failed to clear secure storage: ${error.message}`);
        }
    },

    /**
     * Retrieves all storage keys within the application namespace
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async getAllKeys(): Promise<string[]> {
        try {
            const allKeys = await AsyncStorage.getAllKeys();
            const namespacedKeys = allKeys.filter(key => key.startsWith(STORAGE_PREFIX));
            
            // Remove prefix from keys before returning
            return namespacedKeys.map(key => key.replace(STORAGE_PREFIX, ''));
        } catch (error) {
            throw new Error(`Failed to retrieve secure storage keys: ${error.message}`);
        }
    }
};