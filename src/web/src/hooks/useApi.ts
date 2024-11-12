/**
 * HUMAN TASKS:
 * 1. Configure request timeout values in environment configuration
 * 2. Set up error tracking service integration for API errors
 * 3. Configure retry strategies for failed requests if needed
 * 4. Verify CORS settings for API endpoints in production
 */

// react version: ^17.0.2
import { useState, useCallback, useEffect } from 'react';
// axios version: ^0.24.0
import type { AxiosRequestConfig, AxiosResponse } from 'axios';
import { apiInstance, handleApiError } from '../utils/api';
import { getAuthToken, isAuthenticated } from '../utils/auth';
import type { APIResponse, APIError } from '../types';

/**
 * Custom hook for making API requests with built-in state management
 * Requirement: API Integration - Implement centralized API request handling
 */
export function useApi<T>(
  config: AxiosRequestConfig,
  immediate = false
): {
  data: T | null;
  error: APIError | null;
  loading: boolean;
  execute: () => Promise<void>;
  reset: () => void;
} {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<APIError | null>(null);
  const [loading, setLoading] = useState<boolean>(false);

  /**
   * Reset all states to their initial values
   * Requirement: Error Handling - Implement consistent error handling
   */
  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setLoading(false);
  }, []);

  /**
   * Execute the API request with proper error handling and authentication
   * Requirements:
   * - Security Architecture - Ensure secure API communication
   * - Error Handling - Implement consistent error handling
   */
  const execute = useCallback(async () => {
    // Reset states before new request
    setError(null);
    setLoading(true);

    try {
      // Check authentication if required
      if (config.requiresAuth !== false && !(await isAuthenticated())) {
        throw new Error('Authentication required');
      }

      // Get fresh auth token
      const token = await getAuthToken();
      const configWithAuth: AxiosRequestConfig = {
        ...config,
        headers: {
          ...config.headers,
          ...(token && { Authorization: `Bearer ${token}` })
        }
      };

      // Make the API request
      const response = await apiInstance.request<APIResponse<T>>(configWithAuth);
      
      // Type guard to ensure response matches expected structure
      if (!response || typeof response !== 'object' || !('data' in response)) {
        throw new Error('Invalid response structure');
      }

      setData(response.data);
      setError(null);
    } catch (err: any) {
      const apiError = handleApiError(err);
      setError({
        status: apiError.code === 'NETWORK_ERROR' ? 0 : err.response?.status || 500,
        message: apiError.message,
        errors: apiError.details ? [apiError.details].flat() : [],
        code: apiError.code,
        timestamp: new Date()
      });
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [config]);

  /**
   * Handle automatic execution if immediate flag is true
   * Requirement: API Integration - Support immediate execution
   */
  useEffect(() => {
    let mounted = true;

    if (immediate && mounted) {
      execute();
    }

    return () => {
      mounted = false;
    };
  }, [immediate, execute]);

  return {
    data,
    error,
    loading,
    execute,
    reset
  };
}