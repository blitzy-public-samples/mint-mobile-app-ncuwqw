/**
 * HUMAN TASKS:
 * 1. Ensure environment variables are properly configured for token storage keys
 * 2. Verify secure storage encryption key is set up in environment
 * 3. Configure error monitoring service for authentication failures
 * 4. Set up proper CORS and security headers in web server configuration
 */

// jwt-decode version: ^3.1.2
import jwtDecode from 'jwt-decode';
import { SecureStorage } from '../services/storage/secureStorage';
import type { User, APIResponse } from '../types';

// Global constants for token storage keys
const AUTH_TOKEN_KEY = '@mint_replica_lite/auth_token';
const REFRESH_TOKEN_KEY = '@mint_replica_lite/refresh_token';

/**
 * Interface for decoded JWT token payload
 * Requirement: 6.1 Authentication Flow - JWT token management
 */
interface TokenPayload {
    sub: string;
    exp: number;
    iat: number;
    user: User;
}

/**
 * Retrieves the stored authentication token from secure storage
 * Requirement: 6.1.1 Authentication Flow - Secure token retrieval
 */
export async function getAuthToken(): Promise<string | null> {
    try {
        const token = await SecureStorage.getItem(AUTH_TOKEN_KEY);
        if (!token) {
            return null;
        }

        // Validate token before returning
        const payload = parseToken(token);
        const currentTime = Math.floor(Date.now() / 1000);
        
        if (payload.exp <= currentTime) {
            await clearAuthToken();
            return null;
        }

        return token;
    } catch (error) {
        console.error('Error retrieving auth token:', error);
        return null;
    }
}

/**
 * Stores authentication token securely using AES-256-GCM encryption
 * Requirement: 6.3.1 Security Standards - OWASP secure storage
 */
export async function setAuthToken(token: string): Promise<void> {
    if (!token || typeof token !== 'string') {
        throw new Error('Invalid token provided');
    }

    try {
        // Validate token structure and expiration
        parseToken(token);
        
        // Store token securely
        await SecureStorage.setItem(AUTH_TOKEN_KEY, token);
    } catch (error) {
        console.error('Error storing auth token:', error);
        throw new Error('Failed to store authentication token securely');
    }
}

/**
 * Removes stored authentication tokens from secure storage
 * Requirement: 6.1.1 Authentication Flow - Token cleanup
 */
export async function clearAuthToken(): Promise<void> {
    try {
        await Promise.all([
            SecureStorage.removeItem(AUTH_TOKEN_KEY),
            SecureStorage.removeItem(REFRESH_TOKEN_KEY)
        ]);
    } catch (error) {
        console.error('Error clearing auth tokens:', error);
        throw new Error('Failed to clear authentication tokens');
    }
}

/**
 * Checks if user is currently authenticated with valid token
 * Requirement: 6.1.1 Authentication Flow - Authentication state management
 */
export async function isAuthenticated(): Promise<boolean> {
    try {
        const token = await getAuthToken();
        if (!token) {
            return false;
        }

        const payload = parseToken(token);
        const currentTime = Math.floor(Date.now() / 1000);
        
        return payload.exp > currentTime;
    } catch (error) {
        console.error('Error checking authentication status:', error);
        return false;
    }
}

/**
 * Decodes and validates JWT token structure and claims
 * Requirement: 6.3.1 Security Standards - Token validation
 */
export function parseToken(token: string): TokenPayload {
    if (!token || typeof token !== 'string') {
        throw new Error('Invalid token format');
    }

    try {
        const payload = jwtDecode<TokenPayload>(token);
        
        // Validate required claims
        if (!payload.sub || !payload.exp || !payload.iat || !payload.user) {
            throw new Error('Invalid token claims');
        }

        // Validate token expiration
        const currentTime = Math.floor(Date.now() / 1000);
        if (payload.exp <= currentTime) {
            throw new Error('Token has expired');
        }

        // Validate token issue time
        if (payload.iat > currentTime) {
            throw new Error('Token issue time is in the future');
        }

        return payload;
    } catch (error) {
        console.error('Error parsing token:', error);
        throw new Error('Invalid token structure or claims');
    }
}