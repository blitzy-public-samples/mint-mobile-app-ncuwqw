// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify button touch targets meet accessibility size guidelines (44x44px minimum)
// 2. Test button feedback states with various input devices (mouse, touch, keyboard)
// 3. Validate color contrast ratios for all button variants and states
// 4. Ensure loading spinner animations perform well on lower-end devices

import React from 'react';
import {
  StyleSheet,
  Pressable,
  Text,
  ActivityIndicator,
  StyleProp,
  ViewStyle,
} from 'react-native';
import { CommonStyles } from '../../constants/styles';
import { Colors, OPACITY_DISABLED, OPACITY_PRESSED } from '../../constants/colors';
import { useTheme } from '../../hooks/useTheme';

interface ButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'outline' | 'text';
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  loading?: boolean;
  onPress: () => void;
  style?: StyleProp<ViewStyle>;
  testID?: string;
}

/**
 * A reusable button component with multiple variants and states
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'medium',
  disabled = false,
  loading = false,
  onPress,
  style,
  testID,
}) => {
  const { theme } = useTheme();

  // Get base button styles
  const getButtonStyles = () => {
    const baseStyles = [styles.container];
    
    // Apply variant styles
    switch (variant) {
      case 'primary':
        baseStyles.push({
          backgroundColor: Colors.shared.primary.main,
        });
        break;
      case 'secondary':
        baseStyles.push({
          backgroundColor: Colors.shared.secondary.main,
        });
        break;
      case 'outline':
        baseStyles.push({
          backgroundColor: 'transparent',
          borderWidth: 1,
          borderColor: Colors.shared.primary.main,
        });
        break;
      case 'text':
        baseStyles.push({
          backgroundColor: 'transparent',
          ...StyleSheet.flatten(Shadow.none),
        });
        break;
    }

    // Apply size styles
    switch (size) {
      case 'small':
        baseStyles.push(styles.smallButton);
        break;
      case 'large':
        baseStyles.push(styles.largeButton);
        break;
    }

    return StyleSheet.flatten([baseStyles, style]);
  };

  // Get text styles based on variant
  const getTextStyles = () => {
    const baseStyles = [styles.text];

    switch (variant) {
      case 'primary':
        baseStyles.push({
          color: theme.text.inverse,
        });
        break;
      case 'secondary':
        baseStyles.push({
          color: theme.text.inverse,
        });
        break;
      case 'outline':
      case 'text':
        baseStyles.push({
          color: Colors.shared.primary.main,
        });
        break;
    }

    switch (size) {
      case 'small':
        baseStyles.push(styles.smallText);
        break;
      case 'large':
        baseStyles.push(styles.largeText);
        break;
    }

    return baseStyles;
  };

  return (
    <Pressable
      testID={testID}
      style={({ pressed }) => [
        getButtonStyles(),
        disabled && styles.disabled,
        pressed && styles.pressed,
      ]}
      onPress={onPress}
      disabled={disabled || loading}
      accessibilityRole="button"
      accessibilityState={{
        disabled: disabled || loading,
        busy: loading,
      }}
    >
      {loading ? (
        <ActivityIndicator
          size="small"
          color={variant === 'primary' ? theme.text.inverse : Colors.shared.primary.main}
        />
      ) : (
        <Text style={getTextStyles()}>{children}</Text>
      )}
    </Pressable>
  );
};

const styles = StyleSheet.create({
  container: {
    ...CommonStyles.button,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    minWidth: 80,
  },
  text: {
    fontSize: 16,
    fontWeight: '600',
    textAlign: 'center',
  },
  smallButton: {
    height: 32,
    paddingHorizontal: 12,
    minWidth: 64,
  },
  largeButton: {
    height: 48,
    paddingHorizontal: 24,
    minWidth: 96,
  },
  smallText: {
    fontSize: 14,
  },
  largeText: {
    fontSize: 18,
  },
  disabled: {
    opacity: OPACITY_DISABLED,
  },
  pressed: {
    opacity: OPACITY_PRESSED,
  },
});

export default Button;