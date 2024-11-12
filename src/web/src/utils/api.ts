/**
 * HUMAN TASKS:
 * 1. Configure error monitoring service integration
 * 2. Set up proper CORS configuration in deployment environment
 * 3. Configure rate limiting and request throttling parameters
 * 4. Verify SSL/TLS certificate configuration for API endpoints
 */

// axios version: ^0.24.0
import axios, { AxiosInstance, AxiosError, AxiosRequestConfig, AxiosResponse } from 'axios';
import { API_ENDPOINTS } from '../constants/api';
import { getAuthToken, setAuthToken, clearAuthToken } from './auth';

/**
 * Interface for standardized API error response
 * Requirement: Error Handling - Implement generic error messages
 */
interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

/**
 * Creates and configures the axios instance with default settings
 * Requirement: API Integration - Implement centralized API client configuration
 */
function createApiInstance(): AxiosInstance {
  const instance = axios.create({
    baseURL: API_ENDPOINTS.BASE_URL,
    timeout: API_ENDPOINTS.TIMEOUT,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-API-Version': API_ENDPOINTS.API_VERSION
    }
  });

  setupRequestInterceptor(instance);
  setupResponseInterceptor(instance);

  return instance;
}

/**
 * Configures request interceptor for authentication and common headers
 * Requirement: Security Architecture - Implement secure API communication with JWT tokens
 */
function setupRequestInterceptor(instance: AxiosInstance): void {
  instance.interceptors.request.use(
    async (config: AxiosRequestConfig) => {
      try {
        const token = await getAuthToken();
        if (token) {
          config.headers = {
            ...config.headers,
            Authorization: `Bearer ${token}`
          };
        }
        return config;
      } catch (error) {
        console.error('Request interceptor error:', error);
        return config;
      }
    },
    (error: AxiosError) => {
      return Promise.reject(handleApiError(error));
    }
  );
}

/**
 * Configures response interceptor for error handling and token refresh
 * Requirement: Error Handling - Implement proper error handling
 */
function setupResponseInterceptor(instance: AxiosInstance): void {
  instance.interceptors.response.use(
    (response: AxiosResponse) => {
      return response.data;
    },
    async (error: AxiosError) => {
      if (error.response?.status === 401) {
        await clearAuthToken();
        // Redirect to login or handle unauthorized access
        window.location.href = '/login';
      }
      return Promise.reject(handleApiError(error));
    }
  );
}

/**
 * Processes API errors and formats them for consistent handling
 * Requirement: Error Handling - Implement generic error messages
 */
export function handleApiError(error: AxiosError): ApiError {
  let errorResponse: ApiError = {
    code: 'UNKNOWN_ERROR',
    message: 'An unexpected error occurred. Please try again later.'
  };

  if (!error.response) {
    // Network error or no response from server
    errorResponse = {
      code: 'NETWORK_ERROR',
      message: 'Unable to connect to the server. Please check your internet connection.'
    };
  } else {
    const status = error.response.status;
    const data = error.response.data as any;

    switch (status) {
      case 400:
        errorResponse = {
          code: 'VALIDATION_ERROR',
          message: 'Invalid request. Please check your input.',
          details: data.errors
        };
        break;
      case 401:
        errorResponse = {
          code: 'UNAUTHORIZED',
          message: 'Your session has expired. Please log in again.'
        };
        break;
      case 403:
        errorResponse = {
          code: 'FORBIDDEN',
          message: 'You do not have permission to perform this action.'
        };
        break;
      case 404:
        errorResponse = {
          code: 'NOT_FOUND',
          message: 'The requested resource was not found.'
        };
        break;
      case 429:
        errorResponse = {
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'Too many requests. Please try again later.'
        };
        break;
      case 500:
      case 502:
      case 503:
      case 504:
        errorResponse = {
          code: 'SERVER_ERROR',
          message: 'A server error occurred. Please try again later.'
        };
        break;
    }
  }

  // Log error for monitoring
  console.error('API Error:', {
    code: errorResponse.code,
    message: errorResponse.message,
    originalError: error
  });

  return errorResponse;
}

// Create and export the configured API instance
// Requirement: API Integration - Implement centralized API client configuration
export const apiInstance = createApiInstance();