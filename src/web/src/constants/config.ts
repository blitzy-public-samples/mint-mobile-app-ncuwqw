// react-native version: ^0.71.0
import { Platform } from 'react-native';
import { BASE_URL, API_VERSION } from './api';

/**
 * HUMAN TASKS:
 * 1. Ensure all environment variables are properly set in deployment environments
 * 2. Verify encryption key sizes meet security requirements for production
 * 3. Configure feature flags based on platform capabilities
 * 4. Update version and build numbers during release process
 */

// Environment detection
// Requirement 2.5.1 Production Environment - Define environment-specific configuration settings
export const ENV = process.env.REACT_APP_ENV || 'development';
export const IS_DEV = process.env.NODE_ENV === 'development';
export const IS_PROD = process.env.NODE_ENV === 'production';

// Core application configuration
// Requirement 2.2.1 Client Applications/React Native - Define configuration settings for React Native Web platform
export const AppConfig = {
  APP_NAME: 'Mint Replica Lite',
  VERSION: '1.0.0',
  BUILD_NUMBER: process.env.REACT_APP_BUILD_NUMBER || '1',
  API_BASE_URL: BASE_URL,
  API_VERSION: API_VERSION
};

// Security configuration
// Requirement 2.4 Security Architecture - Configure security-related settings including authentication timeouts and encryption
export const SecurityConfig = {
  TOKEN_EXPIRY: 3600, // 1 hour in seconds
  REFRESH_TOKEN_EXPIRY: 2592000, // 30 days in seconds
  ENCRYPTION_KEY_SIZE: 256, // AES-256 encryption
  MIN_PASSWORD_LENGTH: 12,
  MAX_LOGIN_ATTEMPTS: 5
};

// Feature flags configuration
// Requirement 2.2.1 Client Applications/React Native - Platform-specific feature configuration
export const FeatureFlags = {
  ENABLE_BIOMETRIC: Platform.select({
    ios: true,
    android: true,
    web: false
  }),
  ENABLE_PUSH_NOTIFICATIONS: Platform.select({
    ios: true,
    android: true,
    web: true
  }),
  ENABLE_OFFLINE_MODE: Platform.select({
    ios: true,
    android: true,
    web: false
  }),
  ENABLE_DARK_MODE: true
};

// Storage configuration for offline data management
// Requirement 2.2.1 Client Applications/React Native - Define configuration settings for React Native Web platform
export const StorageConfig = {
  CACHE_TTL: 86400, // 24 hours in seconds
  MAX_OFFLINE_DAYS: 30,
  STORAGE_KEY_PREFIX: '@MintReplicaLite:'
};

// Sync configuration for offline-online data synchronization
// Requirement 2.2.1 Client Applications/React Native - Define configuration settings for React Native Web platform
export const SyncConfig = {
  AUTO_SYNC_INTERVAL: 300000, // 5 minutes in milliseconds
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 5000 // 5 seconds in milliseconds
};

// Environment-specific configuration function
// Requirement 2.5.1 Production Environment - Define environment-specific configuration settings
export const getEnvironmentConfig = () => {
  const baseConfig = {
    apiUrl: BASE_URL,
    apiVersion: API_VERSION,
    timeout: 30000,
    enableLogging: false,
    enableAnalytics: true,
    enableCrashReporting: true
  };

  switch (ENV) {
    case 'production':
      return {
        ...baseConfig,
        enableLogging: false,
        securityLevel: 'high',
        cacheStrategy: 'network-first',
        retryAttempts: 5
      };

    case 'staging':
      return {
        ...baseConfig,
        enableLogging: true,
        securityLevel: 'high',
        cacheStrategy: 'network-first',
        retryAttempts: 3
      };

    case 'development':
    default:
      return {
        ...baseConfig,
        enableLogging: true,
        securityLevel: 'medium',
        cacheStrategy: 'cache-first',
        retryAttempts: 1
      };
  }
};