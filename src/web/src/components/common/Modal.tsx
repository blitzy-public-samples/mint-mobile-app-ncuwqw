// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify modal behavior across different screen sizes and devices
// 2. Test keyboard focus trapping within modal
// 3. Validate animation performance on lower-end devices
// 4. Ensure ARIA attributes are correctly implemented for screen readers

import React, { useEffect, useRef } from 'react';
import {
  StyleSheet,
  Modal as RNModal,
  View,
  Text,
  Pressable,
  useWindowDimensions,
  Animated,
} from 'react-native';
import Button from './Button';
import { fadeIn, fadeOut } from '../../styles/animations';
import { Theme } from '../../styles/theme';
import { useTheme } from '../../hooks/useTheme';

interface ModalProps {
  visible: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  testID?: string;
}

/**
 * A reusable modal component with animated transitions and accessibility support
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Progressive Enhancement - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const Modal: React.FC<ModalProps> = ({
  visible,
  onClose,
  title,
  children,
  testID,
}) => {
  const { theme } = useTheme();
  const { width: windowWidth } = useWindowDimensions();
  const fadeAnim = useRef(new Animated.Value(0)).current;

  // Handle escape key press
  useEffect(() => {
    const handleEscapeKey = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && visible) {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscapeKey);
    return () => {
      document.removeEventListener('keydown', handleEscapeKey);
    };
  }, [visible, onClose]);

  // Handle animation on visibility change
  useEffect(() => {
    if (visible) {
      fadeIn.animation(() => {})?.start();
    } else {
      fadeOut.animation(() => {})?.start();
    }
  }, [visible]);

  // Handle backdrop press
  const handleBackdropPress = () => {
    onClose();
  };

  return (
    <RNModal
      visible={visible}
      transparent
      animationType="none"
      onRequestClose={onClose}
      testID={testID}
      statusBarTranslucent
    >
      <Animated.View style={[styles.container, fadeIn.style(fadeAnim)]}>
        <Pressable
          style={[styles.backdrop, { backgroundColor: 'rgba(0, 0, 0, 0.5)' }]}
          onPress={handleBackdropPress}
          accessibilityRole="button"
          accessibilityLabel="Close modal"
        />
        
        <View
          style={[
            styles.content,
            {
              backgroundColor: theme.colors.background,
              borderRadius: theme.shape.borderRadius.md,
              padding: theme.spacing.lg,
              width: Math.min(windowWidth * 0.9, 500),
            },
          ]}
          accessibilityRole="dialog"
          accessibilityModal={true}
        >
          <View style={styles.header}>
            <Text
              style={[
                styles.title,
                {
                  color: theme.colors.text,
                  fontSize: theme.typography.scale.h3.fontSize,
                  fontWeight: theme.typography.fontWeights.medium,
                },
              ]}
              accessibilityRole="heading"
            >
              {title}
            </Text>
            <Button
              variant="text"
              size="small"
              onPress={onClose}
              testID={`${testID}-close-button`}
            >
              ✕
            </Button>
          </View>
          
          <View style={styles.body}>{children}</View>
        </View>
      </Animated.View>
    </RNModal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  backdrop: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  content: {
    maxHeight: '90%',
    elevation: 5,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 4,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    flex: 1,
    marginRight: 16,
  },
  body: {
    overflow: 'auto',
  },
});

export default Modal;