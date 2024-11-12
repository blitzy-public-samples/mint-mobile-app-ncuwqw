/**
 * HUMAN TASKS:
 * 1. Verify navigation container ref setup with analytics team
 * 2. Test navigation state persistence across app reloads
 * 3. Validate screen transition animations on different devices
 * 4. Ensure proper deep linking configuration in app manifest
 */

// react version: ^18.0.0
// @react-navigation/native version: ^6.0.0
// @react-navigation/stack version: ^6.0.0

import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createStackNavigator } from '@react-navigation/stack';

// Internal imports with relative paths
import AuthNavigator from './AuthNavigator';
import TabNavigator from './TabNavigator';
import { useAppSelector, type RootState } from '../store';

/**
 * Type definition for root navigation stack parameters
 * Requirement: Cross-Platform Navigation (2.2.1 Client Applications/React Native)
 */
export interface RootStackParamList {
  Auth: undefined;
  Main: undefined;
}

// Initialize the root stack navigator with proper typing
const Stack = createStackNavigator<RootStackParamList>();

// Default screen options for consistent UI and security
const screenOptions = {
  headerShown: false,
  gestureEnabled: false, // Disable gestures for security
};

/**
 * Main navigation component that handles routing between authenticated and unauthenticated states
 * Requirement: Multi-platform user authentication (1.2 Scope/Account Management)
 * Requirement: Authentication Flow (6.1 SECURITY CONSIDERATIONS/6.1.1 Authentication Flow)
 */
const MainNavigator: React.FC = React.memo(() => {
  // Get authentication state from Redux store
  const isAuthenticated = useAppSelector((state: RootState) => 
    state.auth.isAuthenticated
  );

  return (
    <NavigationContainer
      // Disable navigation state persistence for security
      persistenceKey={process.env.NODE_ENV === 'development' ? 'NavigationState' : undefined}
      // Apply theme based on system preferences
      theme={{
        dark: false,
        colors: {
          primary: 'theme.colors.primary',
          background: 'theme.colors.background',
          card: 'theme.colors.surface',
          text: 'theme.colors.text',
          border: 'theme.colors.border',
          notification: 'theme.colors.error',
        },
      }}
    >
      <Stack.Navigator
        screenOptions={screenOptions}
        // Requirement: Authentication Flow - Conditional initial route based on auth state
        initialRouteName={isAuthenticated ? 'Main' : 'Auth'}
      >
        {!isAuthenticated ? (
          // Unauthenticated stack
          <Stack.Screen
            name="Auth"
            component={AuthNavigator}
            options={{
              animationTypeForReplace: 'pop',
            }}
          />
        ) : (
          // Authenticated stack
          <Stack.Screen
            name="Main"
            component={TabNavigator}
            options={{
              animationTypeForReplace: 'push',
            }}
          />
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
});

// Set display name for debugging purposes
MainNavigator.displayName = 'MainNavigator';

export default MainNavigator;