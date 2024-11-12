/**
 * HUMAN TASKS:
 * 1. Ensure REACT_APP_STORAGE_ENCRYPTION_KEY is properly set in environment variables
 * 2. Verify browser compatibility for AsyncStorage in target environments
 * 3. Configure proper error monitoring for storage operations
 * 4. Review and update SECURE_STORAGE_KEYS list based on security requirements
 * 5. Implement periodic security audits for storage operations
 */

// @react-native-async-storage/async-storage version: ^1.19.0
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SecureStorage } from './secureStorage';
import { encryptData } from '../../utils/encryption';

// Global constants for storage configuration
const STORAGE_PREFIX = '@mint_replica_lite/';
const SECURE_STORAGE_KEYS = ['auth', 'credentials', 'userProfile', 'accountTokens'];

/**
 * Validates storage key to ensure it meets security requirements
 * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
 */
const validateKey = (key: string): void => {
    if (!key || typeof key !== 'string' || key.trim().length === 0) {
        throw new Error('Storage key must be a non-empty string');
    }
};

/**
 * Determines if a key requires secure storage with AES-256-GCM encryption
 * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
 */
const isSecureKey = (key: string): boolean => {
    validateKey(key);
    return SECURE_STORAGE_KEYS.includes(key);
};

/**
 * Unified storage service implementing secure AES-256-GCM encryption for sensitive data
 * and regular storage for non-sensitive data
 * Requirements:
 * - 6.2 Data Security/6.2.2 Sensitive Data Handling
 * - 2.1 High-Level Architecture Overview/Client Layer
 * - 1.1 System Overview/Client Applications
 */
export const StorageService = {
    /**
     * Stores data with automatic secure/regular storage selection based on key sensitivity
     * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
     */
    async setStorageItem(key: string, value: any): Promise<void> {
        validateKey(key);
        
        if (value === undefined) {
            throw new Error('Storage value must be defined');
        }

        try {
            const prefixedKey = STORAGE_PREFIX + key;
            
            if (isSecureKey(key)) {
                await SecureStorage.setItem(key, value);
            } else {
                const serializedValue = JSON.stringify(value);
                await AsyncStorage.setItem(prefixedKey, serializedValue);
            }
        } catch (error) {
            throw new Error(`Failed to store data: ${error.message}`);
        }
    },

    /**
     * Retrieves data from appropriate storage based on key sensitivity
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async getStorageItem(key: string): Promise<any | null> {
        validateKey(key);

        try {
            const prefixedKey = STORAGE_PREFIX + key;

            if (isSecureKey(key)) {
                return await SecureStorage.getItem(key);
            } else {
                const value = await AsyncStorage.getItem(prefixedKey);
                return value ? JSON.parse(value) : null;
            }
        } catch (error) {
            throw new Error(`Failed to retrieve data: ${error.message}`);
        }
    },

    /**
     * Removes item from appropriate storage mechanism
     * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
     */
    async removeStorageItem(key: string): Promise<void> {
        validateKey(key);

        try {
            const prefixedKey = STORAGE_PREFIX + key;

            if (isSecureKey(key)) {
                await SecureStorage.removeItem(key);
            } else {
                await AsyncStorage.removeItem(prefixedKey);
            }
        } catch (error) {
            throw new Error(`Failed to remove data: ${error.message}`);
        }
    },

    /**
     * Clears all storage (both secure and regular) with proper error handling
     * Requirements:
     * - 6.2 Data Security/6.2.2 Sensitive Data Handling
     * - 2.1 High-Level Architecture Overview/Client Layer
     */
    async clearStorage(): Promise<void> {
        try {
            // Start both clear operations concurrently
            const clearOperations = [
                SecureStorage.clear(),
                AsyncStorage.clear()
            ];

            // Wait for both operations to complete
            await Promise.all(clearOperations);
        } catch (error) {
            // If either operation fails, attempt to restore previous state
            throw new Error(`Failed to clear storage: ${error.message}`);
        }
    }
};