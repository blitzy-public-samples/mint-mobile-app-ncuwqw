/**
 * HUMAN TASKS:
 * 1. Configure test environment variables for API endpoints
 * 2. Set up test database with sample user data
 * 3. Configure test coverage thresholds in jest.config.js
 * 4. Verify test SSL certificates for HTTPS requests
 */

// @jest/globals version: ^27.0.0
import { describe, test, expect, beforeEach, afterEach, jest } from '@jest/globals';
// axios-mock-adapter version: ^1.20.0
import MockAdapter from 'axios-mock-adapter';

import { 
  login, 
  register, 
  forgotPassword, 
  resetPassword, 
  logout, 
  refreshToken 
} from '../../../services/api/auth';
import { apiInstance } from '../../../utils/api';
import type { User, APIResponse, APIError } from '../../../types';

// Mock API instance
const mockApi = new MockAdapter(apiInstance);

// Test data
const mockUser: User = {
  id: 'test-user-id',
  email: 'test@example.com',
  name: 'Test User'
};

const mockAuthResponse: APIResponse<User & { token: string }> = {
  data: {
    ...mockUser,
    token: 'mock-jwt-token'
  },
  status: 200,
  message: 'Success',
  timestamp: new Date()
};

const mockApiError: APIError = {
  status: 401,
  message: 'Authentication failed',
  errors: ['Invalid credentials'],
  code: 'AUTH_ERROR',
  timestamp: new Date('2023-01-01T00:00:00Z')
};

// Reset mocks before each test
beforeEach(() => {
  mockApi.reset();
  jest.clearAllMocks();
  localStorage.clear();
});

// Clean up after tests
afterEach(() => {
  mockApi.restore();
});

/**
 * Test suite for login functionality
 * Requirement: Authentication Flow - Verify secure user authentication flow with JWT tokens
 */
describe('login', () => {
  test('should successfully login with valid credentials', async () => {
    mockApi.onPost('/auth/login').reply(200, mockAuthResponse);

    const response = await login('test@example.com', 'ValidPass123!');
    
    expect(response.data).toEqual(mockUser);
    expect(response.status).toBe(200);
    expect(localStorage.getItem('authToken')).toBe('mock-jwt-token');
  });

  test('should handle invalid credentials', async () => {
    mockApi.onPost('/auth/login').reply(401, mockApiError);

    await expect(login('test@example.com', 'wrong-password'))
      .rejects.toEqual(expect.objectContaining({
        code: 'AUTH_ERROR',
        message: 'Authentication failed'
      }));
  });

  test('should validate email format', async () => {
    await expect(login('invalid-email', 'ValidPass123!'))
      .rejects.toThrow('Invalid email format');
  });

  test('should validate password format', async () => {
    await expect(login('test@example.com', 'weak'))
      .rejects.toThrow('Invalid password format');
  });
});

/**
 * Test suite for user registration
 * Requirement: Multi-platform Authentication - Test implementation of cross-platform user authentication
 */
describe('register', () => {
  test('should successfully register new user', async () => {
    mockApi.onPost('/auth/register').reply(200, mockAuthResponse);

    const response = await register('test@example.com', 'ValidPass123!', 'Test User');
    
    expect(response.data).toEqual(mockUser);
    expect(response.status).toBe(200);
    expect(localStorage.getItem('authToken')).toBe('mock-jwt-token');
  });

  test('should handle existing email registration', async () => {
    const existingEmailError = {
      ...mockApiError,
      message: 'Email already registered',
      code: 'EMAIL_EXISTS'
    };
    mockApi.onPost('/auth/register').reply(400, existingEmailError);

    await expect(register('existing@example.com', 'ValidPass123!', 'Test User'))
      .rejects.toEqual(expect.objectContaining({
        code: 'EMAIL_EXISTS',
        message: 'Email already registered'
      }));
  });

  test('should validate registration inputs', async () => {
    await expect(register('invalid-email', 'ValidPass123!', 'Test User'))
      .rejects.toThrow('Invalid email format');

    await expect(register('test@example.com', 'weak', 'Test User'))
      .rejects.toThrow('Invalid password format');

    await expect(register('test@example.com', 'ValidPass123!', ''))
      .rejects.toThrow('Invalid name format');
  });
});

/**
 * Test suite for password reset request
 * Requirement: Security Standards - Validate authentication implementation against security standards
 */
describe('forgotPassword', () => {
  test('should successfully request password reset', async () => {
    const mockResponse: APIResponse<void> = {
      data: undefined,
      status: 200,
      message: 'Password reset email sent',
      timestamp: new Date()
    };
    mockApi.onPost('/auth/forgot-password').reply(200, mockResponse);

    const response = await forgotPassword('test@example.com');
    
    expect(response.status).toBe(200);
    expect(response.message).toBe('Password reset email sent');
  });

  test('should handle non-existent email', async () => {
    const nonExistentError = {
      ...mockApiError,
      message: 'Email not found',
      code: 'EMAIL_NOT_FOUND'
    };
    mockApi.onPost('/auth/forgot-password').reply(404, nonExistentError);

    await expect(forgotPassword('nonexistent@example.com'))
      .rejects.toEqual(expect.objectContaining({
        code: 'EMAIL_NOT_FOUND',
        message: 'Email not found'
      }));
  });

  test('should validate email format', async () => {
    await expect(forgotPassword('invalid-email'))
      .rejects.toThrow('Invalid email format');
  });
});

/**
 * Test suite for password reset
 * Requirement: Security Standards - Validate authentication implementation against security standards
 */
describe('resetPassword', () => {
  test('should successfully reset password', async () => {
    const mockResponse: APIResponse<void> = {
      data: undefined,
      status: 200,
      message: 'Password successfully reset',
      timestamp: new Date()
    };
    mockApi.onPost('/auth/reset-password').reply(200, mockResponse);

    const response = await resetPassword('valid-reset-token-123456', 'NewValidPass123!');
    
    expect(response.status).toBe(200);
    expect(response.message).toBe('Password successfully reset');
  });

  test('should handle invalid reset token', async () => {
    const invalidTokenError = {
      ...mockApiError,
      message: 'Invalid or expired reset token',
      code: 'INVALID_TOKEN'
    };
    mockApi.onPost('/auth/reset-password').reply(400, invalidTokenError);

    await expect(resetPassword('invalid-token', 'NewValidPass123!'))
      .rejects.toEqual(expect.objectContaining({
        code: 'INVALID_TOKEN',
        message: 'Invalid or expired reset token'
      }));
  });

  test('should validate password format', async () => {
    await expect(resetPassword('valid-token', 'weak'))
      .rejects.toThrow('Invalid password format');
  });

  test('should validate token format', async () => {
    await expect(resetPassword('short', 'ValidPass123!'))
      .rejects.toThrow('Invalid reset token');
  });
});

/**
 * Test suite for user logout
 * Requirement: Authentication Flow - Verify secure user authentication flow with JWT tokens
 */
describe('logout', () => {
  test('should successfully logout user', async () => {
    mockApi.onPost('/auth/logout').reply(200);
    localStorage.setItem('authToken', 'mock-jwt-token');

    await logout();
    
    expect(localStorage.getItem('authToken')).toBeNull();
  });

  test('should handle logout errors', async () => {
    const logoutError = {
      ...mockApiError,
      message: 'Logout failed',
      code: 'LOGOUT_ERROR'
    };
    mockApi.onPost('/auth/logout').reply(500, logoutError);
    localStorage.setItem('authToken', 'mock-jwt-token');

    await expect(logout()).rejects.toEqual(expect.objectContaining({
      code: 'LOGOUT_ERROR',
      message: 'Logout failed'
    }));
    // Token should still be cleared even if API call fails
    expect(localStorage.getItem('authToken')).toBeNull();
  });
});

/**
 * Test suite for token refresh
 * Requirement: Authentication Flow - Verify secure user authentication flow with JWT tokens
 */
describe('refreshToken', () => {
  test('should successfully refresh token', async () => {
    const mockRefreshResponse: APIResponse<{ token: string }> = {
      data: { token: 'new-mock-jwt-token' },
      status: 200,
      message: 'Token refreshed',
      timestamp: new Date()
    };
    mockApi.onPost('/auth/refresh').reply(200, mockRefreshResponse);

    const response = await refreshToken();
    
    expect(response.data.token).toBe('new-mock-jwt-token');
    expect(localStorage.getItem('authToken')).toBe('new-mock-jwt-token');
  });

  test('should handle expired refresh token', async () => {
    const expiredTokenError = {
      ...mockApiError,
      message: 'Refresh token expired',
      code: 'REFRESH_TOKEN_EXPIRED'
    };
    mockApi.onPost('/auth/refresh').reply(401, expiredTokenError);
    localStorage.setItem('authToken', 'old-token');

    await expect(refreshToken()).rejects.toEqual(expect.objectContaining({
      code: 'REFRESH_TOKEN_EXPIRED',
      message: 'Refresh token expired'
    }));
    // Token should be cleared on refresh failure
    expect(localStorage.getItem('authToken')).toBeNull();
  });
});