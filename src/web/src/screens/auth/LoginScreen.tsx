/**
 * HUMAN TASKS:
 * 1. Verify biometric authentication configuration with security team
 * 2. Test accessibility compliance with screen readers
 * 3. Validate error message content with UX team
 * 4. Ensure proper SSL/TLS configuration in production environment
 */

// react version: ^18.2.0
// react-router-dom version: ^6.0.0
// react-native version: ^0.71.0

import React, { useCallback } from 'react';
import { StyleSheet, View } from 'react-native';
import { useNavigate } from 'react-router-dom';

// Internal imports with relative paths
import AuthForm from '../../components/auth/AuthForm';
import { useAuth } from '../../hooks/useAuth';
import EmptyState from '../../components/common/EmptyState';
import type { User } from '../../hooks/useAuth';

// Requirement: Multi-platform Authentication - Support cross-platform user authentication
interface LoginScreenProps {}

// Requirement: Authentication Flow - Implement secure user authentication flow with JWT token management
const LoginScreen: React.FC<LoginScreenProps> = () => {
  const navigate = useNavigate();
  const { login, loading } = useAuth();

  // Requirement: Security Standards - Implement secure authentication following OWASP security standards
  const handleLoginSuccess = useCallback((user: User) => {
    // After successful authentication, navigate to the dashboard
    navigate('/dashboard');
  }, [navigate]);

  const handleLoginError = useCallback((error: Error) => {
    // Log authentication errors for monitoring but show generic message to user
    console.error('Authentication error:', error);
  }, []);

  // Show loading state while authentication is in progress
  if (loading) {
    return (
      <View style={styles.container}>
        <EmptyState
          title="Authenticating..."
          message="Please wait while we securely log you in"
          icon={{ uri: '/assets/images/loading.gif' }}
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AuthForm
        mode="login"
        onSuccess={handleLoginSuccess}
        onError={handleLoginError}
      />
    </View>
  );
};

// Theme-based container styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
});

export default LoginScreen;