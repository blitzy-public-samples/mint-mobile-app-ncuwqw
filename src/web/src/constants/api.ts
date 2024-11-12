// @types/node version: ^18.0.0

/**
 * HUMAN TASKS:
 * 1. Ensure REACT_APP_API_URL environment variable is set in deployment environments
 * 2. Update API_VERSION when deploying new API versions
 * 3. Verify API_TIMEOUT value is aligned with backend timeout settings
 */

// Base API configuration
// Requirement: API Integration - Define API endpoint constants for communication with backend services
export const API_VERSION = 'v1';
export const BASE_URL = process.env.REACT_APP_API_URL || 'https://api.mintreplicalite.com';
export const API_TIMEOUT = 30000;

// API configuration object for axios/fetch setup
// Requirement: RESTful Services - Configure RESTful API endpoint constants for different environments
export const API_ENDPOINTS = {
  BASE_URL,
  API_VERSION,
  TIMEOUT: API_TIMEOUT
};

// Authentication endpoints
// Requirement: Service Integration - Define endpoint constants for authentication service
export const AUTH_ENDPOINTS = {
  LOGIN: `/api/${API_VERSION}/auth/login`,
  REGISTER: `/api/${API_VERSION}/auth/register`,
  REFRESH_TOKEN: `/api/${API_VERSION}/auth/refresh`,
  LOGOUT: `/api/${API_VERSION}/auth/logout`
};

// Account management endpoints
// Requirement: Service Integration - Define endpoint constants for account management service
export const ACCOUNT_ENDPOINTS = {
  LIST: `/api/${API_VERSION}/accounts`,
  DETAILS: `/api/${API_VERSION}/accounts/:id`,
  SYNC: `/api/${API_VERSION}/accounts/sync`
};

// Transaction management endpoints
// Requirement: Service Integration - Define endpoint constants for transaction service
export const TRANSACTION_ENDPOINTS = {
  LIST: `/api/${API_VERSION}/transactions`,
  DETAILS: `/api/${API_VERSION}/transactions/:id`,
  CATEGORIES: `/api/${API_VERSION}/transactions/categories`
};

// Budget management endpoints
// Requirement: Service Integration - Define endpoint constants for budget service
export const BUDGET_ENDPOINTS = {
  LIST: `/api/${API_VERSION}/budgets`,
  DETAILS: `/api/${API_VERSION}/budgets/:id`,
  PROGRESS: `/api/${API_VERSION}/budgets/:id/progress`
};

// Financial goal endpoints
// Requirement: Service Integration - Define endpoint constants for goal service
export const GOAL_ENDPOINTS = {
  LIST: `/api/${API_VERSION}/goals`,
  DETAILS: `/api/${API_VERSION}/goals/:id`,
  PROGRESS: `/api/${API_VERSION}/goals/:id/progress`
};

// Investment tracking endpoints
// Requirement: Service Integration - Define endpoint constants for investment service
export const INVESTMENT_ENDPOINTS = {
  LIST: `/api/${API_VERSION}/investments`,
  DETAILS: `/api/${API_VERSION}/investments/:id`,
  PERFORMANCE: `/api/${API_VERSION}/investments/:id/performance`
};

// Push notification endpoints
// Requirement: Service Integration - Define endpoint constants for notification service
export const NOTIFICATION_ENDPOINTS = {
  REGISTER_DEVICE: `/api/${API_VERSION}/notifications/devices`,
  PREFERENCES: `/api/${API_VERSION}/notifications/preferences`
};