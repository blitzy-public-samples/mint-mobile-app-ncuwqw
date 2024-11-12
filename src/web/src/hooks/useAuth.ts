/**
 * HUMAN TASKS:
 * 1. Configure token refresh interval in environment variables
 * 2. Set up error monitoring for authentication failures
 * 3. Verify secure storage implementation in production environment
 */

// react version: ^18.2.0
// react-redux version: ^8.1.0
import { useState, useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { login, register, logout, refreshToken } from '../services/api/auth';
import { SecureStorage } from '../services/storage/secureStorage';
import { User } from '../types';
import { authSlice } from '../store/slices/authSlice';

// Token storage key
const AUTH_TOKEN_KEY = 'auth_token';

// Token refresh interval (15 minutes)
const TOKEN_REFRESH_INTERVAL = 15 * 60 * 1000;

/**
 * Custom hook for managing authentication state and operations
 * Requirement: Multi-platform Authentication - Support cross-platform user authentication
 */
export function useAuth() {
    const dispatch = useDispatch();
    const authState = useSelector(state => state.auth);
    const [isLoading, setIsLoading] = useState(false);

    /**
     * Check for stored authentication token on mount
     * Requirement: Authentication Flow - Implement secure JWT token management
     */
    useEffect(() => {
        const initializeAuth = async () => {
            try {
                const storedToken = await SecureStorage.getItem(AUTH_TOKEN_KEY);
                if (storedToken) {
                    dispatch(authSlice.actions.setToken(storedToken));
                    // Trigger token refresh if needed
                    const lastRefresh = authState.lastTokenRefresh;
                    if (!lastRefresh || Date.now() - lastRefresh > TOKEN_REFRESH_INTERVAL) {
                        await handleTokenRefresh();
                    }
                }
            } catch (error) {
                console.error('Auth initialization failed:', error);
                await handleLogout();
            }
        };

        initializeAuth();
    }, []);

    /**
     * Set up automatic token refresh
     * Requirement: Authentication Flow - Implement secure JWT token refresh
     */
    useEffect(() => {
        if (!authState.isAuthenticated) return;

        const refreshInterval = setInterval(async () => {
            await handleTokenRefresh();
        }, TOKEN_REFRESH_INTERVAL);

        return () => clearInterval(refreshInterval);
    }, [authState.isAuthenticated]);

    /**
     * Handle user login
     * Requirement: Authentication Flow - Implement secure user authentication flow
     */
    const handleLogin = async (email: string, password: string): Promise<void> => {
        setIsLoading(true);
        try {
            const response = await login(email, password);
            dispatch(authSlice.actions.setUser(response.data));
            setIsLoading(false);
        } catch (error) {
            setIsLoading(false);
            throw error;
        }
    };

    /**
     * Handle user registration
     * Requirement: Multi-platform Authentication - Implement cross-platform user registration
     */
    const handleRegister = async (email: string, password: string, name: string): Promise<void> => {
        setIsLoading(true);
        try {
            const response = await register(email, password, name);
            dispatch(authSlice.actions.setUser(response.data));
            setIsLoading(false);
        } catch (error) {
            setIsLoading(false);
            throw error;
        }
    };

    /**
     * Handle user logout
     * Requirement: Security Standards - Implement secure logout
     */
    const handleLogout = async (): Promise<void> => {
        setIsLoading(true);
        try {
            await logout();
            dispatch(authSlice.actions.clearUser());
            await SecureStorage.removeItem(AUTH_TOKEN_KEY);
        } catch (error) {
            console.error('Logout failed:', error);
            // Still clear local state even if API call fails
            dispatch(authSlice.actions.clearUser());
            await SecureStorage.removeItem(AUTH_TOKEN_KEY);
        } finally {
            setIsLoading(false);
        }
    };

    /**
     * Handle token refresh
     * Requirement: Security Standards - Implement secure token refresh
     */
    const handleTokenRefresh = async (): Promise<void> => {
        try {
            const response = await refreshToken();
            await SecureStorage.setItem(AUTH_TOKEN_KEY, response.data.token);
            dispatch(authSlice.actions.setToken(response.data.token));
        } catch (error) {
            console.error('Token refresh failed:', error);
            await handleLogout();
        }
    };

    return {
        user: authState.user as User | null,
        isLoading,
        isAuthenticated: authState.isAuthenticated,
        login: handleLogin,
        register: handleRegister,
        logout: handleLogout
    };
}