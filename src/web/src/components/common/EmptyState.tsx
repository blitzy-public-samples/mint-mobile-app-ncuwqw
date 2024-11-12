// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify empty state appearance across different screen sizes and devices
// 2. Test icon rendering with various image formats and sizes
// 3. Validate accessibility labels and screen reader support
// 4. Ensure consistent spacing and alignment with design system

import React from 'react';
import {
  StyleSheet,
  View,
  Text,
  Image,
  ImageSourcePropType,
  ViewStyle,
} from 'react-native';
import { colors, spacing } from '../../styles/theme';
import Button from './Button';

interface EmptyStateProps {
  title: string;
  message?: string;
  icon?: ImageSourcePropType;
  actionButtonText?: string;
  onActionButtonPress?: () => void;
  containerStyle?: ViewStyle;
}

/**
 * A reusable empty state component that displays when no data is available
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const EmptyState: React.FC<EmptyStateProps> = ({
  title,
  message,
  icon,
  actionButtonText,
  onActionButtonPress,
  containerStyle,
}) => {
  return (
    <View style={[styles.container, containerStyle]}>
      {icon && (
        <Image
          source={icon}
          style={styles.icon}
          resizeMode="contain"
          accessibilityRole="image"
          accessibilityLabel={`Empty state illustration for ${title}`}
        />
      )}
      
      <Text
        style={styles.title}
        accessibilityRole="header"
      >
        {title}
      </Text>

      {message && (
        <Text
          style={styles.message}
          accessibilityRole="text"
        >
          {message}
        </Text>
      )}

      {actionButtonText && onActionButtonPress && (
        <Button
          variant="primary"
          onPress={onActionButtonPress}
          testID="empty-state-action-button"
        >
          {actionButtonText}
        </Button>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing.lg,
  },
  icon: {
    width: 80,
    height: 80,
    marginBottom: spacing.md,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing.sm,
  },
  message: {
    fontSize: 14,
    color: colors.text.secondary,
    textAlign: 'center',
    marginBottom: spacing.md,
  },
});

export default EmptyState;