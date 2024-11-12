// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Test alert component behavior across different screen sizes and orientations
// 2. Validate alert color contrast ratios for accessibility compliance
// 3. Review animation performance on lower-end devices
// 4. Verify alert message readability in both light and dark themes

import React, { useEffect, useRef } from 'react';
import { StyleSheet, View, Text, Animated, TouchableOpacity } from 'react-native';
import { shared } from '../../constants/colors';
import { Shadow } from '../../constants/styles';

/**
 * Props interface for the Alert component
 * @requirements User Feedback - 5.1.2 Screen Layouts
 */
interface AlertProps {
  message: string;
  severity?: 'info' | 'success' | 'warning' | 'error';
  dismissible?: boolean;
  duration?: number;
  onDismiss?: () => void;
}

/**
 * Generates alert styles based on severity level
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const getAlertStyles = (severity: AlertProps['severity'] = 'info') => {
  const colors = shared[severity];
  return {
    backgroundColor: colors.light,
    borderColor: colors.main,
    color: colors.dark,
  };
};

/**
 * Alert component for displaying status messages and notifications
 * @requirements User Feedback - 5.1.2 Screen Layouts
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const Alert: React.FC<AlertProps> = ({
  message,
  severity = 'info',
  dismissible = false,
  duration,
  onDismiss,
}) => {
  const fadeAnim = useRef(new Animated.Value(0)).current;
  const slideAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    // Fade in animation on mount
    Animated.timing(fadeAnim, {
      toValue: 1,
      duration: 200,
      useNativeDriver: true,
    }).start();

    // Auto-dismiss logic if duration is provided
    if (duration && duration > 0) {
      const timer = setTimeout(() => {
        handleDismiss();
      }, duration);

      return () => clearTimeout(timer);
    }
  }, []);

  const handleDismiss = () => {
    // Combine fade out and slide out animations
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(slideAnim, {
        toValue: -100,
        duration: 200,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onDismiss?.();
    });
  };

  const alertStyles = getAlertStyles(severity);

  return (
    <Animated.View
      style={[
        styles.container,
        {
          opacity: fadeAnim,
          transform: [{ translateX: slideAnim }],
          backgroundColor: alertStyles.backgroundColor,
          borderColor: alertStyles.borderColor,
        },
      ]}
    >
      <View style={styles.contentContainer}>
        <Text
          style={[
            styles.message,
            {
              color: alertStyles.color,
            },
          ]}
        >
          {message}
        </Text>
        {dismissible && (
          <TouchableOpacity
            style={styles.dismissButton}
            onPress={handleDismiss}
            accessibilityRole="button"
            accessibilityLabel="Dismiss alert"
          >
            <Text style={[styles.dismissText, { color: alertStyles.color }]}>
              ✕
            </Text>
          </TouchableOpacity>
        )}
      </View>
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  container: {
    borderRadius: 8,
    borderWidth: 1,
    marginVertical: 8,
    marginHorizontal: 16,
    ...Shadow.sm,
  },
  contentContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
  },
  message: {
    flex: 1,
    fontSize: 14,
    lineHeight: 20,
  },
  dismissButton: {
    padding: 4,
    marginLeft: 12,
  },
  dismissText: {
    fontSize: 16,
    fontWeight: '500',
  },
});

export default Alert;