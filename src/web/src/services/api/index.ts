/**
 * HUMAN TASKS:
 * 1. Configure error monitoring service integration in production environment
 * 2. Set up proper CORS configuration in deployment environment
 * 3. Configure rate limiting parameters in API Gateway
 * 4. Verify JWT token expiration settings match security requirements
 */

// axios version: ^0.24.0
import { apiInstance, handleApiError } from '../../utils/api';
import {
  Account,
  Transaction,
  Budget,
  Investment,
  APIResponse,
  APIError
} from '../../types';
import * as accountService from './accounts';

/**
 * Initializes the API service with configuration and interceptors
 * Requirement: API Integration - Implement centralized API client configuration
 * Requirement: Security Architecture - Implement secure API communication with TLS and JWT tokens
 */
export const initializeApi = (): void => {
  // Configure request monitoring and logging
  apiInstance.interceptors.request.use(
    (config) => {
      // Add request timestamp for monitoring
      config.metadata = { startTime: new Date() };
      return config;
    },
    (error) => {
      return Promise.reject(error);
    }
  );

  // Configure response monitoring and logging
  apiInstance.interceptors.response.use(
    (response) => {
      // Calculate request duration for monitoring
      const startTime = response.config.metadata?.startTime;
      if (startTime) {
        const duration = new Date().getTime() - startTime.getTime();
        // Log duration for monitoring (implement proper logging in production)
        console.debug(`API call to ${response.config.url} took ${duration}ms`);
      }
      return response;
    },
    (error) => {
      return Promise.reject(error);
    }
  );
};

/**
 * Generic handler for API responses with type safety
 * Requirement: Data Flow Architecture - Handle API gateway, authentication, and validation layers
 */
export const handleApiResponse = async <T>(
  apiResponse: Promise<APIResponse<T>>
): Promise<T> => {
  try {
    const response = await apiResponse;
    
    // Validate response structure
    if (!response || typeof response.status !== 'number' || !response.data) {
      throw new Error('Invalid API response structure');
    }

    // Check for successful status codes (2xx range)
    if (response.status < 200 || response.status >= 300) {
      throw new Error(`API request failed with status ${response.status}`);
    }

    return response.data;
  } catch (error) {
    // Transform error to standardized format using utility
    const apiError = handleApiError(error);
    throw apiError;
  }
};

/**
 * Unified API service namespace exposing all API functionality
 * Requirement: API Integration - Implement centralized API client configuration
 */
export const api = {
  // Account management services
  accounts: {
    getAll: () => handleApiResponse(accountService.getAccounts()),
    getById: (id: string) => handleApiResponse(accountService.getAccountById(id)),
    link: (institutionId: string, credentials: Record<string, string>, accountType: string) =>
      handleApiResponse(accountService.linkAccount({ institutionId, credentials, accountType })),
    unlink: (id: string) => handleApiResponse(accountService.unlinkAccount(id)),
    sync: (id: string) => handleApiResponse(accountService.syncAccount(id))
  },

  // Transaction services (to be implemented)
  transactions: {
    // Placeholder for transaction service implementations
  },

  // Budget services (to be implemented)
  budgets: {
    // Placeholder for budget service implementations
  },

  // Investment services (to be implemented)
  investments: {
    // Placeholder for investment service implementations
  },

  // Financial goal services (to be implemented)
  goals: {
    // Placeholder for goal service implementations
  }
};