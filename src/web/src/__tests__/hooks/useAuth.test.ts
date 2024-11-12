/**
 * HUMAN TASKS:
 * 1. Configure test environment variables for token refresh intervals
 * 2. Set up test coverage monitoring for authentication flows
 * 3. Configure mock service worker for consistent API mocking
 */

// @jest/globals version: ^29.0.0
// @testing-library/react-hooks version: ^8.0.1
// @testing-library/react version: ^14.0.0
// react-redux version: ^8.1.0

import { jest, describe, beforeEach, it, expect } from '@jest/globals';
import { renderHook, act } from '@testing-library/react-hooks';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import { useAuth } from '../../hooks/useAuth';
import { login, register, logout, refreshToken } from '../../services/api/auth';
import { authSlice } from '../../store/slices/authSlice';

// Mock the auth service functions
jest.mock('../../services/api/auth');

// Mock SecureStorage
jest.mock('../../services/storage/secureStorage', () => ({
  SecureStorage: {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
  },
}));

/**
 * Test suite for useAuth hook
 * Requirement: Multi-platform Authentication - Verify cross-platform user authentication for web platform
 */
describe('useAuth hook', () => {
  // Test store setup
  const store = configureStore({
    reducer: {
      auth: authSlice.reducer,
    },
  });

  // Wrapper component for providing Redux store
  const wrapper = ({ children }: { children: React.ReactNode }) => (
    <Provider store={store}>{children}</Provider>
  );

  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    // Reset store state
    store.dispatch(authSlice.actions.clearUser());
  });

  /**
   * Test successful login flow
   * Requirement: Authentication Flow - Test secure user authentication flow with JWT token management
   */
  it('should handle successful login', async () => {
    const mockUser = {
      id: '1',
      email: 'test@example.com',
      name: 'Test User',
    };

    const mockResponse = {
      data: { ...mockUser, token: 'mock-token' },
      status: 'success',
      message: 'Login successful',
      timestamp: new Date(),
    };

    (login as jest.Mock).mockResolvedValueOnce(mockResponse);

    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.isLoading).toBe(false);
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.user).toBeNull();

    await act(async () => {
      await result.current.login('test@example.com', 'Password123!');
    });

    expect(login).toHaveBeenCalledWith('test@example.com', 'Password123!');
    expect(result.current.isLoading).toBe(false);
    expect(result.current.isAuthenticated).toBe(true);
    expect(result.current.user).toEqual(mockUser);
  });

  /**
   * Test login error handling
   * Requirement: Security Standards - Validate secure authentication implementation
   */
  it('should handle login errors', async () => {
    const mockError = new Error('Invalid credentials');
    (login as jest.Mock).mockRejectedValueOnce(mockError);

    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      try {
        await result.current.login('test@example.com', 'wrong-password');
      } catch (error) {
        expect(error).toBe(mockError);
      }
    });

    expect(result.current.isLoading).toBe(false);
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.user).toBeNull();
  });

  /**
   * Test successful registration flow
   * Requirement: Multi-platform Authentication - Test cross-platform user registration
   */
  it('should handle successful registration', async () => {
    const mockUser = {
      id: '1',
      email: 'newuser@example.com',
      name: 'New User',
    };

    const mockResponse = {
      data: { ...mockUser, token: 'mock-token' },
      status: 'success',
      message: 'Registration successful',
      timestamp: new Date(),
    };

    (register as jest.Mock).mockResolvedValueOnce(mockResponse);

    const { result } = renderHook(() => useAuth(), { wrapper });

    await act(async () => {
      await result.current.register('newuser@example.com', 'Password123!', 'New User');
    });

    expect(register).toHaveBeenCalledWith(
      'newuser@example.com',
      'Password123!',
      'New User'
    );
    expect(result.current.isLoading).toBe(false);
    expect(result.current.isAuthenticated).toBe(true);
    expect(result.current.user).toEqual(mockUser);
  });

  /**
   * Test successful logout flow
   * Requirement: Authentication Flow - Test secure logout implementation
   */
  it('should handle successful logout', async () => {
    // Set initial authenticated state
    store.dispatch(
      authSlice.actions.setUser({
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
      })
    );

    (logout as jest.Mock).mockResolvedValueOnce({});

    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.isAuthenticated).toBe(true);

    await act(async () => {
      await result.current.logout();
    });

    expect(logout).toHaveBeenCalled();
    expect(result.current.isLoading).toBe(false);
    expect(result.current.isAuthenticated).toBe(false);
    expect(result.current.user).toBeNull();
  });

  /**
   * Test token refresh flow
   * Requirement: Authentication Flow - Test secure JWT token refresh
   */
  it('should handle token refresh', async () => {
    const mockToken = 'new-mock-token';
    const mockResponse = {
      data: { token: mockToken },
      status: 'success',
      message: 'Token refreshed',
      timestamp: new Date(),
    };

    (refreshToken as jest.Mock).mockResolvedValueOnce(mockResponse);

    // Set initial authenticated state
    store.dispatch(authSlice.actions.setToken('old-mock-token'));
    store.dispatch(
      authSlice.actions.setUser({
        id: '1',
        email: 'test@example.com',
        name: 'Test User',
      })
    );

    const { result } = renderHook(() => useAuth(), { wrapper });

    // Wait for automatic token refresh
    await act(async () => {
      // Trigger useEffect cleanup to simulate time passage
      jest.advanceTimersByTime(15 * 60 * 1000); // 15 minutes
    });

    expect(refreshToken).toHaveBeenCalled();
    expect(result.current.isAuthenticated).toBe(true);
  });
});