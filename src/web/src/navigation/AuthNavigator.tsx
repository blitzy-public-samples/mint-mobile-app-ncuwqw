/**
 * HUMAN TASKS:
 * 1. Verify navigation flow with UX team
 * 2. Test screen transitions across different browsers and devices
 * 3. Validate navigation state persistence requirements
 */

// react version: ^18.2.0
// @react-navigation/stack version: ^6.0.0

import React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

// Internal screen imports with relative paths
import LoginScreen from '../screens/auth/LoginScreen';
import RegisterScreen from '../screens/auth/RegisterScreen';
import ForgotPasswordScreen from '../screens/auth/ForgotPasswordScreen';

/**
 * Type definition for authentication stack navigation parameters
 * Requirement: Multi-platform user authentication (1.2 Scope/Account Management)
 * Ensures type safety for navigation between authentication screens
 */
export interface AuthStackParamList {
  Login: undefined;
  Register: undefined;
  ForgotPassword: undefined;
}

// Initialize the authentication stack navigator with proper typing
const Stack = createStackNavigator<AuthStackParamList>();

/**
 * Default screen options for consistent UI across authentication screens
 * Requirement: Authentication Flow (6.1.1 Authentication Flow)
 * Provides seamless navigation experience with proper styling
 */
const screenOptions = {
  headerShown: false,
  cardStyle: {
    backgroundColor: 'theme.colors.background'
  }
};

/**
 * Authentication navigator component that manages routing between auth screens
 * Requirement: Multi-platform user authentication (1.2 Scope/Account Management)
 * Requirement: Authentication Flow (6.1.1 Authentication Flow)
 */
const AuthNavigator: React.FC = React.memo(() => {
  return (
    <Stack.Navigator
      initialRouteName="Login"
      screenOptions={screenOptions}
    >
      <Stack.Screen
        name="Login"
        component={LoginScreen}
      />
      <Stack.Screen
        name="Register"
        component={RegisterScreen}
      />
      <Stack.Screen
        name="ForgotPassword"
        component={ForgotPasswordScreen}
      />
    </Stack.Navigator>
  );
});

// Set display name for debugging purposes
AuthNavigator.displayName = 'AuthNavigator';

export default AuthNavigator;