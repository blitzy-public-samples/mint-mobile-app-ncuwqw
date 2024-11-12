/**
 * HUMAN TASKS:
 * 1. Verify localStorage is available and enabled in target browsers
 * 2. Ensure sufficient storage quota is available for the application's needs
 * 3. Configure error monitoring for storage operations
 * 4. Document storage size limits for operations team
 */

import { encryptData, decryptData } from './encryption';

// Storage prefixes for regular and secure data
const STORAGE_PREFIX = '@mint_replica_lite_web/';
const SECURE_STORAGE_PREFIX = '@mint_replica_lite_web_secure/';

/**
 * Validates storage key
 * @throws Error if key is invalid
 */
const validateKey = (key: string): void => {
  if (!key || typeof key !== 'string' || key.trim().length === 0) {
    throw new Error('Storage key must be a non-empty string');
  }
};

/**
 * Validates storage value
 * @throws Error if value is undefined
 */
const validateValue = (value: any): void => {
  if (value === undefined) {
    throw new Error('Storage value cannot be undefined');
  }
};

/**
 * Gets the appropriate storage prefix based on security flag
 */
const getPrefix = (secure: boolean): string => {
  return secure ? SECURE_STORAGE_PREFIX : STORAGE_PREFIX;
};

/**
 * Storage utility object providing secure and non-secure local storage operations
 * Implements requirements:
 * - Client Storage (2.2.1)
 * - Data Security (6.2.2)
 * - Platform-Specific Storage (6.3.4)
 */
export const storage = {
  /**
   * Stores data with optional encryption
   * @param key Storage key
   * @param value Data to store
   * @param secure Whether to encrypt the data
   */
  async setItem(key: string, value: any, secure: boolean = false): Promise<void> {
    validateKey(key);
    validateValue(value);

    try {
      const prefix = getPrefix(secure);
      const serializedValue = JSON.stringify(value);
      
      let finalValue = serializedValue;
      if (secure) {
        // Requirement: Data Security (6.2.2) - Encrypt sensitive data
        finalValue = await encryptData(serializedValue, window.location.hostname);
      }

      localStorage.setItem(prefix + key, finalValue);
    } catch (error) {
      throw new Error(`Storage operation failed: ${error.message}`);
    }
  },

  /**
   * Retrieves data with automatic decryption if needed
   * @param key Storage key
   * @param secure Whether the data is encrypted
   * @returns Retrieved value or null if not found
   */
  async getItem(key: string, secure: boolean = false): Promise<any | null> {
    validateKey(key);

    try {
      const prefix = getPrefix(secure);
      const storedValue = localStorage.getItem(prefix + key);

      if (storedValue === null) {
        return null;
      }

      if (secure) {
        // Requirement: Data Security (6.2.2) - Decrypt sensitive data
        const decrypted = await decryptData(storedValue, window.location.hostname);
        return JSON.parse(decrypted);
      }

      return JSON.parse(storedValue);
    } catch (error) {
      throw new Error(`Retrieval operation failed: ${error.message}`);
    }
  },

  /**
   * Removes item from storage
   * @param key Storage key
   * @param secure Whether the item is in secure storage
   */
  async removeItem(key: string, secure: boolean = false): Promise<void> {
    validateKey(key);

    try {
      const prefix = getPrefix(secure);
      localStorage.removeItem(prefix + key);
    } catch (error) {
      throw new Error(`Remove operation failed: ${error.message}`);
    }
  },

  /**
   * Clears storage based on security scope
   * @param secureOnly Whether to clear only secure storage
   */
  async clear(secureOnly: boolean = false): Promise<void> {
    try {
      const keys = Object.keys(localStorage);
      
      keys.forEach(key => {
        if (secureOnly) {
          if (key.startsWith(SECURE_STORAGE_PREFIX)) {
            localStorage.removeItem(key);
          }
        } else {
          if (key.startsWith(STORAGE_PREFIX) || key.startsWith(SECURE_STORAGE_PREFIX)) {
            localStorage.removeItem(key);
          }
        }
      });
    } catch (error) {
      throw new Error(`Clear operation failed: ${error.message}`);
    }
  },

  /**
   * Gets all storage keys for the specified security scope
   * @param secure Whether to get secure storage keys
   * @returns Array of storage keys without prefixes
   */
  async getAllKeys(secure: boolean = false): Promise<string[]> {
    try {
      const prefix = getPrefix(secure);
      const allKeys = Object.keys(localStorage);
      
      return allKeys
        .filter(key => key.startsWith(prefix))
        .map(key => key.slice(prefix.length));
    } catch (error) {
      throw new Error(`Get keys operation failed: ${error.message}`);
    }
  }
};