/**
 * HUMAN TASKS:
 * 1. Configure rate limiting parameters for authentication endpoints
 * 2. Set up monitoring for failed authentication attempts
 * 3. Configure password policy and validation rules
 * 4. Verify CORS settings for authentication endpoints
 */

// axios version: ^0.24.0
import { AxiosResponse } from 'axios';
import { apiInstance, handleApiError } from '../api';
import { setAuthToken, clearAuthToken } from '../../utils/auth';
import type { User, APIResponse } from '../../types';

/**
 * Input validation for email format
 * Requirement: Security Standards - Input validation
 */
const validateEmail = (email: string): boolean => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
};

/**
 * Input validation for password strength
 * Requirement: Security Standards - Password security
 */
const validatePassword = (password: string): boolean => {
    // Minimum 8 characters, at least one uppercase, one lowercase, one number
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\W]{8,}$/;
    return passwordRegex.test(password);
};

/**
 * Authenticates user with email and password
 * Requirement: Authentication Flow - Implement secure user authentication flow with JWT tokens
 */
export async function login(email: string, password: string): Promise<APIResponse<User>> {
    try {
        if (!validateEmail(email)) {
            throw new Error('Invalid email format');
        }

        if (!validatePassword(password)) {
            throw new Error('Invalid password format');
        }

        const response = await apiInstance.post<APIResponse<User & { token: string }>>(
            '/auth/login',
            { email, password }
        );

        // Store authentication token securely
        await setAuthToken(response.data.data.token);

        // Return user data without token
        const { token, ...userData } = response.data.data;
        return {
            data: userData,
            status: response.data.status,
            message: response.data.message,
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Registers new user account
 * Requirement: Multi-platform Authentication - Implement cross-platform user authentication
 */
export async function register(
    email: string,
    password: string,
    name: string
): Promise<APIResponse<User>> {
    try {
        if (!validateEmail(email)) {
            throw new Error('Invalid email format');
        }

        if (!validatePassword(password)) {
            throw new Error('Invalid password format');
        }

        if (!name || name.trim().length < 2) {
            throw new Error('Invalid name format');
        }

        const response = await apiInstance.post<APIResponse<User & { token: string }>>(
            '/auth/register',
            { email, password, name }
        );

        // Store authentication token securely
        await setAuthToken(response.data.data.token);

        // Return user data without token
        const { token, ...userData } = response.data.data;
        return {
            data: userData,
            status: response.data.status,
            message: response.data.message,
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Initiates password reset process
 * Requirement: Security Standards - Secure password reset flow
 */
export async function forgotPassword(email: string): Promise<APIResponse<void>> {
    try {
        if (!validateEmail(email)) {
            throw new Error('Invalid email format');
        }

        const response = await apiInstance.post<APIResponse<void>>(
            '/auth/forgot-password',
            { email }
        );

        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Resets user password with reset token
 * Requirement: Security Standards - Secure password reset implementation
 */
export async function resetPassword(
    token: string,
    newPassword: string
): Promise<APIResponse<void>> {
    try {
        if (!token || token.length < 32) {
            throw new Error('Invalid reset token');
        }

        if (!validatePassword(newPassword)) {
            throw new Error('Invalid password format');
        }

        const response = await apiInstance.post<APIResponse<void>>(
            '/auth/reset-password',
            { token, newPassword }
        );

        return response.data;
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Logs out current user
 * Requirement: Authentication Flow - Secure logout implementation
 */
export async function logout(): Promise<void> {
    try {
        await apiInstance.post('/auth/logout');
        await clearAuthToken();
    } catch (error) {
        // Still clear tokens locally even if API call fails
        await clearAuthToken();
        throw handleApiError(error);
    }
}

/**
 * Refreshes expired authentication token
 * Requirement: Authentication Flow - Implement secure JWT token refresh
 */
export async function refreshToken(): Promise<APIResponse<{ token: string }>> {
    try {
        const response = await apiInstance.post<APIResponse<{ token: string }>>(
            '/auth/refresh'
        );

        // Store new token securely
        await setAuthToken(response.data.data.token);

        return response.data;
    } catch (error) {
        // Clear tokens if refresh fails
        await clearAuthToken();
        throw handleApiError(error);
    }
}