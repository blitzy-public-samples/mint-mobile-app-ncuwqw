/**
 * HUMAN TASKS:
 * 1. Verify test coverage meets security compliance requirements
 * 2. Add accessibility testing scenarios
 * 3. Review error message assertions with UX team
 * 4. Add performance testing scenarios if required
 */

// @testing-library/react version: ^13.0.0
// @jest/globals version: ^29.0.0
// react-redux version: ^8.1.0

import React from 'react';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { jest, describe, it, beforeEach, expect } from '@jest/globals';
import configureStore from 'redux-mock-store';
import AuthForm, { AuthFormProps } from '../../../components/auth/AuthForm';

// Mock the useAuth hook
jest.mock('../../../hooks/useAuth', () => ({
  login: jest.fn(),
  register: jest.fn(),
}));

// Import the mocked functions
import { login, register } from '../../../hooks/useAuth';

const mockStore = configureStore([]);

describe('AuthForm', () => {
  let store: any;
  const mockOnSuccess = jest.fn();
  const mockOnError = jest.fn();

  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    store = mockStore({
      auth: {
        isAuthenticated: false,
        user: null,
      },
    });

    // Reset mock functions
    mockOnSuccess.mockReset();
    mockOnError.mockReset();
  });

  // Requirement: Multi-platform Authentication - Verify cross-platform user authentication functionality
  it('renders login form correctly', () => {
    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    expect(screen.getByPlaceholder('Email address')).toBeInTheDocument();
    expect(screen.getByPlaceholder('Password')).toBeInTheDocument();
    expect(screen.getByText('Sign In')).toBeInTheDocument();
    expect(screen.queryByPlaceholder('Full name')).not.toBeInTheDocument();
  });

  // Requirement: Multi-platform Authentication - Verify cross-platform user authentication functionality
  it('renders registration form correctly', () => {
    render(
      <Provider store={store}>
        <AuthForm mode="register" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    expect(screen.getByPlaceholder('Email address')).toBeInTheDocument();
    expect(screen.getByPlaceholder('Password')).toBeInTheDocument();
    expect(screen.getByPlaceholder('Full name')).toBeInTheDocument();
    expect(screen.getByText('Create Account')).toBeInTheDocument();
  });

  // Requirement: Authentication Flow - Test secure user authentication flow implementation
  it('handles login submission correctly', async () => {
    const mockUser = { id: '1', email: 'test@example.com' };
    (login as jest.Mock).mockResolvedValueOnce(mockUser);

    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.change(screen.getByPlaceholder('Email address'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholder('Password'), {
      target: { value: 'Test123!@#' },
    });

    fireEvent.click(screen.getByText('Sign In'));

    await waitFor(() => {
      expect(login).toHaveBeenCalledWith('test@example.com', 'Test123!@#');
      expect(mockOnSuccess).toHaveBeenCalledWith(mockUser);
    });
  });

  // Requirement: Authentication Flow - Test secure user authentication flow implementation
  it('handles registration submission correctly', async () => {
    const mockUser = { id: '1', email: 'test@example.com', name: 'Test User' };
    (register as jest.Mock).mockResolvedValueOnce(mockUser);

    render(
      <Provider store={store}>
        <AuthForm mode="register" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.change(screen.getByPlaceholder('Full name'), {
      target: { value: 'Test User' },
    });
    fireEvent.change(screen.getByPlaceholder('Email address'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholder('Password'), {
      target: { value: 'Test123!@#' },
    });

    fireEvent.click(screen.getByText('Create Account'));

    await waitFor(() => {
      expect(register).toHaveBeenCalledWith('test@example.com', 'Test123!@#', 'Test User');
      expect(mockOnSuccess).toHaveBeenCalledWith(mockUser);
    });
  });

  // Requirement: Security Standards - Validate secure authentication implementation
  it('displays validation errors for empty fields', async () => {
    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.click(screen.getByText('Sign In'));

    await waitFor(() => {
      expect(screen.getByText('Email is required')).toBeInTheDocument();
      expect(screen.getByText('Password is required')).toBeInTheDocument();
    });
  });

  // Requirement: Security Standards - Validate secure authentication implementation
  it('displays validation errors for invalid email and password', async () => {
    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.change(screen.getByPlaceholder('Email address'), {
      target: { value: 'invalid-email' },
    });
    fireEvent.change(screen.getByPlaceholder('Password'), {
      target: { value: 'weak' },
    });

    fireEvent.click(screen.getByText('Sign In'));

    await waitFor(() => {
      expect(screen.getByText('Please enter a valid email address')).toBeInTheDocument();
      expect(screen.getByText('Password must be at least 8 characters')).toBeInTheDocument();
    });
  });

  // Requirement: Security Standards - Validate secure authentication implementation
  it('handles authentication errors correctly', async () => {
    const mockError = new Error('Invalid credentials');
    (login as jest.Mock).mockRejectedValueOnce(mockError);

    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.change(screen.getByPlaceholder('Email address'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholder('Password'), {
      target: { value: 'Test123!@#' },
    });

    fireEvent.click(screen.getByText('Sign In'));

    await waitFor(() => {
      expect(mockOnError).toHaveBeenCalledWith(mockError);
      expect(mockOnSuccess).not.toHaveBeenCalled();
    });
  });

  // Requirement: Security Standards - Validate secure authentication implementation
  it('disables form submission while processing', async () => {
    (login as jest.Mock).mockImplementation(() => new Promise(resolve => setTimeout(resolve, 1000)));

    render(
      <Provider store={store}>
        <AuthForm mode="login" onSuccess={mockOnSuccess} onError={mockOnError} />
      </Provider>
    );

    fireEvent.change(screen.getByPlaceholder('Email address'), {
      target: { value: 'test@example.com' },
    });
    fireEvent.change(screen.getByPlaceholder('Password'), {
      target: { value: 'Test123!@#' },
    });

    fireEvent.click(screen.getByText('Sign In'));

    expect(screen.getByText('Sign In')).toBeDisabled();
    expect(screen.getByPlaceholder('Email address')).toBeDisabled();
    expect(screen.getByPlaceholder('Password')).toBeDisabled();
  });
});