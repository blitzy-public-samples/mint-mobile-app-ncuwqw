// react version: ^18.0.0
// react-native version: ^0.71.0
// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Verify loading animation performance on low-end devices
// 2. Test loading states with different network conditions
// 3. Validate loading indicator contrast ratios for accessibility
// 4. Ensure reduced motion preferences are respected

import React from 'react';
import {
  ActivityIndicator,
  View,
  Text,
  StyleSheet,
  Animated,
} from 'react-native';
import { useTheme } from '@react-navigation/native';
import { fadeIn } from '../../styles/animations';
import type { Theme } from '../../styles/theme';

/**
 * Props interface for Loading component
 */
interface LoadingProps {
  /**
   * Size of the loading indicator
   * @default "small"
   */
  size?: 'small' | 'large';
  
  /**
   * Optional message to display below the loading indicator
   */
  message?: string;
  
  /**
   * Optional custom color for the loading indicator
   * Defaults to theme primary color
   */
  color?: string;
}

/**
 * A reusable loading component that displays an animated spinner with optional message
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Progressive Enhancement - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const Loading: React.FunctionComponent<LoadingProps> = ({
  size = 'small',
  message,
  color,
}) => {
  // Access theme context for colors and spacing
  const theme = useTheme() as Theme;
  
  // Create animated value for fade effect
  const fadeAnim = React.useRef(new Animated.Value(0)).current;
  
  React.useEffect(() => {
    // Start fade in animation when component mounts
    fadeIn.animation(() => {
      // Animation completion callback if needed
    }).start();
  }, []);

  return (
    <Animated.View style={[
      styles.container,
      { padding: theme.spacing.md },
      fadeIn.style(fadeAnim)
    ]}>
      <ActivityIndicator
        size={size}
        color={color || theme.colors.primary}
        testID="loading-indicator"
      />
      {message && (
        <Text
          style={[
            styles.message,
            {
              color: theme.colors.text,
              marginTop: theme.spacing.sm,
              fontFamily: theme.typography.fontFamily,
              ...theme.typography.scale.body2
            }
          ]}
          accessibilityRole="alert"
          accessibilityLive="polite"
        >
          {message}
        </Text>
      )}
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    justifyContent: 'center',
    minHeight: 100,
  },
  message: {
    textAlign: 'center',
  },
});