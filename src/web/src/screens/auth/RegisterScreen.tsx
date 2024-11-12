/**
 * HUMAN TASKS:
 * 1. Verify error message content with UX team
 * 2. Test registration flow with different network conditions
 * 3. Validate accessibility compliance with WCAG standards
 * 4. Ensure analytics events are properly tracked
 */

// react version: ^18.2.0
// @react-navigation/native version: ^6.0.0

import React from 'react';
import { useNavigation } from '@react-navigation/native';
import AuthForm from '../../components/auth/AuthForm';
import Loading from '../../components/common/Loading';
import { useAuth } from '../../hooks/useAuth';
import type { User } from '../../types';

/**
 * RegisterScreen component that handles new user registration
 * Requirement: Multi-platform Authentication - Support cross-platform user authentication for web platform
 * Requirement: Authentication Flow - Implement secure user registration flow with JWT token management
 */
const RegisterScreen: React.FC = () => {
  const navigation = useNavigation();
  const { register, loading } = useAuth();

  /**
   * Handles successful user registration
   * Requirement: Authentication Flow - Implement secure user registration flow
   * @param user - The registered user object
   */
  const handleRegistrationSuccess = (user: User): void => {
    // Navigate to dashboard after successful registration
    navigation.navigate('Dashboard');
  };

  /**
   * Handles registration errors with appropriate user feedback
   * Requirement: Security Standards - Implement secure registration following OWASP security standards
   * @param error - The error object from registration attempt
   */
  const handleRegistrationError = (error: Error): void => {
    // Log error for monitoring while keeping user-facing message generic
    console.error('Registration error:', error);
    
    // Error is handled by AuthForm component which will display
    // appropriate error messages to the user
  };

  // Show loading indicator during registration process
  if (loading) {
    return (
      <Loading 
        size="large"
        message="Creating your account..."
      />
    );
  }

  return (
    <AuthForm
      mode="register"
      onSuccess={handleRegistrationSuccess}
      onError={handleRegistrationError}
    />
  );
};

export default RegisterScreen;