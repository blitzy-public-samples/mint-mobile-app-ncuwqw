// react version: ^18.2.0
// @testing-library/react version: ^14.0.0
// @jest/globals version: ^29.0.0
// react-redux version: ^8.1.0
// react-router-dom version: ^6.0.0

import React from 'react';
import { render, fireEvent, waitFor, screen } from '@testing-library/react';
import { Provider } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { jest, describe, beforeEach, test, expect } from '@jest/globals';

import LoginScreen from '../../../screens/auth/LoginScreen';
import { useAuth } from '../../../hooks/useAuth';

// Mock the useAuth hook
jest.mock('../../../hooks/useAuth');

// Mock useNavigate hook from react-router-dom
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate,
}));

// Mock Redux store
const mockStore = {
  getState: () => ({
    auth: {
      loading: false,
      user: null,
      error: null
    }
  }),
  subscribe: jest.fn(),
  dispatch: jest.fn(),
};

// Helper function to render component with required providers
const renderWithProviders = (component: React.ReactElement) => {
  return render(
    <Provider store={mockStore}>
      <BrowserRouter>
        {component}
      </BrowserRouter>
    </Provider>
  );
};

describe('LoginScreen', () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
    mockNavigate.mockClear();
    
    // Reset useAuth mock implementation
    (useAuth as jest.Mock).mockImplementation(() => ({
      login: jest.fn(),
      loading: false
    }));
  });

  // Requirement: Multi-platform Authentication - Verify cross-platform user authentication functionality
  test('renders login form correctly', () => {
    renderWithProviders(<LoginScreen />);
    
    // Verify form elements are present
    expect(screen.getByPlaceholderText(/email/i)).toBeInTheDocument();
    expect(screen.getByPlaceholderText(/password/i)).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument();
    
    // Verify form is enabled initially
    expect(screen.getByPlaceholderText(/email/i)).not.toBeDisabled();
    expect(screen.getByPlaceholderText(/password/i)).not.toBeDisabled();
    expect(screen.getByRole('button', { name: /sign in/i })).not.toBeDisabled();
  });

  // Requirement: Authentication Flow - Test secure user authentication flow with JWT token management
  test('handles successful login', async () => {
    const mockLogin = jest.fn().mockResolvedValue({
      id: '123',
      email: 'test@example.com'
    });
    
    (useAuth as jest.Mock).mockImplementation(() => ({
      login: mockLogin,
      loading: false
    }));

    renderWithProviders(<LoginScreen />);

    // Fill in login form
    fireEvent.change(screen.getByPlaceholderText(/email/i), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByPlaceholderText(/password/i), {
      target: { value: 'Password123!' }
    });

    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    // Verify login function was called with correct credentials
    expect(mockLogin).toHaveBeenCalledWith('test@example.com', 'Password123!');

    // Wait for navigation to dashboard after successful login
    await waitFor(() => {
      expect(mockNavigate).toHaveBeenCalledWith('/dashboard');
    });
  });

  // Requirement: Security Standards - Validate authentication implementation against OWASP security standards
  test('handles login errors', async () => {
    const mockLogin = jest.fn().mockRejectedValue(new Error('Invalid credentials'));
    
    (useAuth as jest.Mock).mockImplementation(() => ({
      login: mockLogin,
      loading: false
    }));

    renderWithProviders(<LoginScreen />);

    // Fill in login form with invalid credentials
    fireEvent.change(screen.getByPlaceholderText(/email/i), {
      target: { value: 'invalid@example.com' }
    });
    fireEvent.change(screen.getByPlaceholderText(/password/i), {
      target: { value: 'wrongpassword' }
    });

    // Submit form
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    // Verify error handling
    await waitFor(() => {
      expect(mockLogin).toHaveBeenCalledWith('invalid@example.com', 'wrongpassword');
      expect(screen.getByText(/please wait while we securely log you in/i)).not.toBeInTheDocument();
      expect(screen.getByRole('button', { name: /sign in/i })).not.toBeDisabled();
    });
  });

  // Requirement: Authentication Flow - Test loading state during authentication
  test('shows loading state during login attempt', async () => {
    const mockLogin = jest.fn().mockImplementation(() => new Promise(resolve => setTimeout(resolve, 1000)));
    
    (useAuth as jest.Mock).mockImplementation(() => ({
      login: mockLogin,
      loading: true
    }));

    renderWithProviders(<LoginScreen />);

    // Fill in and submit login form
    fireEvent.change(screen.getByPlaceholderText(/email/i), {
      target: { value: 'test@example.com' }
    });
    fireEvent.change(screen.getByPlaceholderText(/password/i), {
      target: { value: 'Password123!' }
    });
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    // Verify loading state
    await waitFor(() => {
      expect(screen.getByText(/authenticating/i)).toBeInTheDocument();
      expect(screen.getByText(/please wait while we securely log you in/i)).toBeInTheDocument();
    });
  });

  // Requirement: Security Standards - Test form validation following OWASP standards
  test('validates form inputs before submission', async () => {
    const mockLogin = jest.fn();
    
    (useAuth as jest.Mock).mockImplementation(() => ({
      login: mockLogin,
      loading: false
    }));

    renderWithProviders(<LoginScreen />);

    // Try to submit empty form
    fireEvent.click(screen.getByRole('button', { name: /sign in/i }));

    // Verify validation errors
    await waitFor(() => {
      expect(mockLogin).not.toHaveBeenCalled();
      expect(screen.getByText(/email is required/i)).toBeInTheDocument();
      expect(screen.getByText(/password is required/i)).toBeInTheDocument();
    });

    // Try invalid email format
    fireEvent.change(screen.getByPlaceholderText(/email/i), {
      target: { value: 'invalidemail' }
    });

    await waitFor(() => {
      expect(screen.getByText(/please enter a valid email address/i)).toBeInTheDocument();
    });

    // Try weak password
    fireEvent.change(screen.getByPlaceholderText(/password/i), {
      target: { value: 'weak' }
    });

    await waitFor(() => {
      expect(screen.getByText(/password must be at least 8 characters/i)).toBeInTheDocument();
    });
  });
});