// crypto-js version: ^4.1.1
import CryptoJS from 'crypto-js';
import { SecurityConfig } from '../constants/config';

/**
 * HUMAN TASKS:
 * 1. Verify that the production environment has sufficient entropy for secure random number generation
 * 2. Ensure key storage mechanisms are properly configured in the deployment environment
 * 3. Validate that the encryption key size meets security requirements for the specific deployment region
 * 4. Configure proper error monitoring for cryptographic operations
 */

// Global constants for cryptographic operations
const IV_LENGTH = 16; // Initialization Vector length in bytes for AES-GCM
const SALT_LENGTH = 16; // Salt length in bytes for PBKDF2
const AUTH_TAG_LENGTH = 16; // Authentication tag length in bytes for AES-GCM

/**
 * Generates cryptographically secure random bytes using Web Crypto API
 * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
 */
export function generateRandomBytes(length: number): Uint8Array {
    if (length <= 0) {
        throw new Error('Length must be a positive number');
    }
    
    const randomBytes = new Uint8Array(length);
    crypto.getRandomValues(randomBytes);
    return randomBytes;
}

/**
 * Generates a cryptographic key using PBKDF2 key derivation
 * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
 * Requirement: 6.3 Security Protocols/6.3.1 Security Standards Compliance
 */
export async function generateKey(password: string, salt?: Uint8Array): Promise<CryptoKey> {
    if (!password) {
        throw new Error('Password is required for key generation');
    }

    const keyMaterial = await crypto.subtle.importKey(
        'raw',
        new TextEncoder().encode(password),
        'PBKDF2',
        false,
        ['deriveBits', 'deriveKey']
    );

    const actualSalt = salt || generateRandomBytes(SALT_LENGTH);

    return crypto.subtle.deriveKey(
        {
            name: 'PBKDF2',
            salt: actualSalt,
            iterations: 100000,
            hash: 'SHA-256'
        },
        keyMaterial,
        {
            name: 'AES-GCM',
            length: SecurityConfig.ENCRYPTION_KEY_SIZE
        },
        true,
        ['encrypt', 'decrypt']
    );
}

/**
 * Encrypts data using AES-256-GCM encryption with authentication
 * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
 * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
 */
export async function encryptData(data: any, key: string): Promise<string> {
    if (!data || !key) {
        throw new Error('Data and encryption key are required');
    }

    try {
        // Generate random IV for this encryption operation
        const iv = generateRandomBytes(IV_LENGTH);
        
        // Convert data to JSON string if it's not already a string
        const jsonString = typeof data === 'string' ? data : JSON.stringify(data);
        
        // Create word array from data
        const dataWords = CryptoJS.enc.Utf8.parse(jsonString);
        const keyWords = CryptoJS.enc.Utf8.parse(key);
        const ivWords = CryptoJS.lib.WordArray.create(iv);

        // Perform AES-GCM encryption
        const encrypted = CryptoJS.AES.encrypt(dataWords, keyWords, {
            iv: ivWords,
            mode: CryptoJS.mode.GCM,
            padding: CryptoJS.pad.NoPadding,
            tagLength: AUTH_TAG_LENGTH * 8
        });

        // Combine IV and ciphertext
        const combined = CryptoJS.lib.WordArray.create()
            .concat(ivWords)
            .concat(encrypted.ciphertext)
            .concat(encrypted.tag);

        // Return base64 encoded result
        return CryptoJS.enc.Base64.stringify(combined);
    } catch (error) {
        throw new Error(`Encryption failed: ${error.message}`);
    }
}

/**
 * Decrypts AES-256-GCM encrypted data with authentication verification
 * Requirement: 6.2 Data Security/6.2.1 Encryption Implementation
 * Requirement: 6.2 Data Security/6.2.2 Sensitive Data Handling
 */
export async function decryptData(encryptedData: string, key: string): Promise<any> {
    if (!encryptedData || !key) {
        throw new Error('Encrypted data and key are required');
    }

    try {
        // Decode base64 data
        const combined = CryptoJS.enc.Base64.parse(encryptedData);
        
        // Extract IV, ciphertext, and auth tag
        const iv = CryptoJS.lib.WordArray.create(combined.words.slice(0, IV_LENGTH / 4));
        const tag = CryptoJS.lib.WordArray.create(
            combined.words.slice(combined.words.length - AUTH_TAG_LENGTH / 4)
        );
        const ciphertext = CryptoJS.lib.WordArray.create(
            combined.words.slice(IV_LENGTH / 4, combined.words.length - AUTH_TAG_LENGTH / 4)
        );

        const keyWords = CryptoJS.enc.Utf8.parse(key);

        // Create cipher params with extracted components
        const cipherParams = CryptoJS.lib.CipherParams.create({
            ciphertext: ciphertext,
            iv: iv,
            tag: tag,
            algorithm: CryptoJS.algo.AES,
            mode: CryptoJS.mode.GCM,
            padding: CryptoJS.pad.NoPadding,
            blockSize: 4,
            formatter: CryptoJS.format.OpenSSL
        });

        // Perform decryption
        const decrypted = CryptoJS.AES.decrypt(cipherParams, keyWords, {
            iv: iv,
            mode: CryptoJS.mode.GCM,
            padding: CryptoJS.pad.NoPadding,
            tagLength: AUTH_TAG_LENGTH * 8
        });

        // Convert to UTF8 string and parse JSON
        const decryptedStr = decrypted.toString(CryptoJS.enc.Utf8);
        try {
            return JSON.parse(decryptedStr);
        } catch {
            return decryptedStr;
        }
    } catch (error) {
        throw new Error(`Decryption failed: ${error.message}`);
    }
}