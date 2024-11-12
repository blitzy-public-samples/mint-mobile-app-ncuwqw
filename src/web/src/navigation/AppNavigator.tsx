/**
 * HUMAN TASKS:
 * 1. Verify navigation theme colors match design system
 * 2. Test navigation state persistence across app reloads
 * 3. Validate navigation transitions on different browsers
 */

// react version: ^18.0.0
// @react-navigation/native version: ^6.0.0
import React from 'react';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';

// Internal imports with relative paths
import AuthNavigator from './AuthNavigator';
import MainNavigator from './MainNavigator';
import { useAuth } from '../hooks/useAuth';

/**
 * Custom navigation theme with white background
 * Requirement: Navigation Structure (5.1 USER INTERFACE DESIGN/5.1.1 Mobile Navigation Structure)
 */
const navigationTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    background: '#FFFFFF'
  }
};

/**
 * Root navigation component that manages authentication-based navigation flow
 * Requirement: Multi-platform Navigation (1.1 System Overview/Client Applications)
 * Requirement: Authentication Flow (2.4 Security Architecture/Client Security)
 * Requirement: Navigation Structure (5.1 USER INTERFACE DESIGN/5.1.1 Mobile Navigation Structure)
 */
const AppNavigator: React.FC = React.memo(() => {
  // Get authentication state from auth hook
  const { isAuthenticated } = useAuth();

  return (
    <NavigationContainer theme={navigationTheme}>
      {isAuthenticated ? (
        // Render authenticated navigation flow
        <MainNavigator />
      ) : (
        // Render unauthenticated navigation flow
        <AuthNavigator />
      )}
    </NavigationContainer>
  );
});

// Set display name for debugging purposes
AppNavigator.displayName = 'AppNavigator';

export default AppNavigator;