// @jest/globals version: ^29.0.0
import { describe, it, expect, beforeEach } from '@jest/globals';
// @reduxjs/toolkit version: ^1.9.5
import { configureStore } from '@reduxjs/toolkit';
import { authReducer, setUser, clearUser, setToken, loginThunk, registerThunk, logoutThunk, refreshTokenThunk } from '../../../store/slices/authSlice';
import type { User, APIResponse, APIError } from '../../../types';

/**
 * HUMAN TASKS:
 * 1. Configure Jest environment with timezone settings for consistent timestamp testing
 * 2. Set up test coverage reporting for authentication flows
 * 3. Configure API mocking environment variables for testing
 * 4. Set up error tracking integration for failed test cases
 */

// Helper function to create a test store instance
const setupTestStore = () => {
  return configureStore({
    reducer: {
      auth: authReducer
    }
  });
};

// Mock API response helpers
const mockLoginSuccess = (mockUser: User): void => {
  jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({
        data: mockUser,
        status: 200,
        message: 'Login successful'
      } as APIResponse<User>)
    } as Response)
  );
};

const mockLoginFailure = (error: APIError): void => {
  jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
    Promise.resolve({
      ok: false,
      json: () => Promise.resolve({
        status: error.status,
        message: error.message,
        errors: ['Authentication failed']
      } as APIError)
    } as Response)
  );
};

describe('Auth Slice', () => {
  let store: ReturnType<typeof setupTestStore>;

  beforeEach(() => {
    store = setupTestStore();
    jest.clearAllMocks();
  });

  // Requirement: Multi-platform Authentication - Verify initial state
  it('should have correct initial state with no user or token', () => {
    const state = store.getState().auth;
    expect(state.user).toBeNull();
    expect(state.token).toBeNull();
    expect(state.isAuthenticated).toBeFalsy();
    expect(state.isLoading).toBeFalsy();
    expect(state.error).toBeNull();
    expect(state.lastTokenRefresh).toBeNull();
  });

  // Requirement: Authentication Flow - Test successful login
  it('should handle successful login with user data and token', async () => {
    const mockUser: User = {
      id: '123',
      email: 'test@example.com',
      name: 'Test User'
    };

    mockLoginSuccess(mockUser);

    await store.dispatch(loginThunk({
      email: 'test@example.com',
      password: 'password123'
    }));

    const state = store.getState().auth;
    expect(state.user).toEqual(mockUser);
    expect(state.isAuthenticated).toBeTruthy();
    expect(state.isLoading).toBeFalsy();
    expect(state.error).toBeNull();
  });

  // Requirement: Security Standards - Test login failure handling
  it('should handle login failure with error state', async () => {
    const mockError: APIError = {
      status: 401,
      message: 'Invalid credentials',
      errors: ['Authentication failed'],
      code: 'AUTH_001',
      timestamp: new Date()
    };

    mockLoginFailure(mockError);

    await store.dispatch(loginThunk({
      email: 'test@example.com',
      password: 'wrongpassword'
    }));

    const state = store.getState().auth;
    expect(state.user).toBeNull();
    expect(state.isAuthenticated).toBeFalsy();
    expect(state.isLoading).toBeFalsy();
    expect(state.error).toBe('Invalid credentials');
  });

  // Requirement: Multi-platform Authentication - Test registration success
  it('should handle successful registration with new user data', async () => {
    const mockUser: User = {
      id: '456',
      email: 'newuser@example.com',
      name: 'New User'
    };

    jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({
          data: mockUser,
          status: 201,
          message: 'Registration successful'
        } as APIResponse<User>)
      } as Response)
    );

    await store.dispatch(registerThunk({
      email: 'newuser@example.com',
      password: 'newpassword123',
      name: 'New User'
    }));

    const state = store.getState().auth;
    expect(state.user).toEqual(mockUser);
    expect(state.isAuthenticated).toBeTruthy();
    expect(state.isLoading).toBeFalsy();
    expect(state.error).toBeNull();
  });

  // Requirement: Security Standards - Test registration failure
  it('should handle registration failure with error state', async () => {
    jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
      Promise.resolve({
        ok: false,
        json: () => Promise.resolve({
          status: 400,
          message: 'Email already exists',
          errors: ['Duplicate email']
        } as APIError)
      } as Response)
    );

    await store.dispatch(registerThunk({
      email: 'existing@example.com',
      password: 'password123',
      name: 'Existing User'
    }));

    const state = store.getState().auth;
    expect(state.user).toBeNull();
    expect(state.isAuthenticated).toBeFalsy();
    expect(state.isLoading).toBeFalsy();
    expect(state.error).toBe('Email already exists');
  });

  // Requirement: Authentication Flow - Test logout functionality
  it('should handle user logout and clear state', async () => {
    // First set a user
    store.dispatch(setUser({
      id: '789',
      email: 'user@example.com',
      name: 'Test User'
    }));

    jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({
          status: 200,
          message: 'Logout successful'
        })
      } as Response)
    );

    await store.dispatch(logoutThunk());

    const state = store.getState().auth;
    expect(state.user).toBeNull();
    expect(state.token).toBeNull();
    expect(state.isAuthenticated).toBeFalsy();
    expect(state.lastTokenRefresh).toBeNull();
    expect(state.error).toBeNull();
  });

  // Requirement: Authentication Flow - Test token refresh
  it('should handle token refresh with new token', async () => {
    const newToken = 'new.jwt.token';
    
    jest.spyOn(global, 'fetch').mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        json: () => Promise.resolve({
          data: { token: newToken },
          status: 200,
          message: 'Token refreshed'
        } as APIResponse<{ token: string }>)
      } as Response)
    );

    await store.dispatch(refreshTokenThunk());

    const state = store.getState().auth;
    expect(state.token).toBe(newToken);
    expect(state.lastTokenRefresh).toBeTruthy();
    expect(state.error).toBeNull();
  });

  // Requirement: Security Standards - Test user state management
  it('should update user state with new user data', () => {
    const mockUser: User = {
      id: '101',
      email: 'updated@example.com',
      name: 'Updated User'
    };

    store.dispatch(setUser(mockUser));

    const state = store.getState().auth;
    expect(state.user).toEqual(mockUser);
    expect(state.isAuthenticated).toBeTruthy();
  });

  // Requirement: Security Standards - Test user state clearing
  it('should clear user state on logout', () => {
    // First set a user
    store.dispatch(setUser({
      id: '102',
      email: 'test@example.com',
      name: 'Test User'
    }));

    store.dispatch(clearUser());

    const state = store.getState().auth;
    expect(state.user).toBeNull();
    expect(state.token).toBeNull();
    expect(state.isAuthenticated).toBeFalsy();
    expect(state.lastTokenRefresh).toBeNull();
  });

  // Requirement: Authentication Flow - Test token management
  it('should update auth token in state', () => {
    const mockToken = 'test.jwt.token';

    store.dispatch(setToken(mockToken));

    const state = store.getState().auth;
    expect(state.token).toBe(mockToken);
    expect(state.lastTokenRefresh).toBeTruthy();
  });
});