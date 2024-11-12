// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify shadow values render consistently across different web browsers
// 2. Test responsive spacing scales on various device sizes
// 3. Validate component style patterns with design team
// 4. Ensure shadow contrasts meet accessibility guidelines

import { StyleSheet, Platform } from 'react-native';
import { light, dark } from './colors';

// Base spacing unit (8pt grid system)
const SPACING_BASE = 8;
const BORDER_RADIUS_SM = 4;
const BORDER_RADIUS_MD = 8;
const BORDER_RADIUS_LG = 12;
const SHADOW_OPACITY = 0.15;
const ELEVATION_BASE = 3;

/**
 * Calculates scaled spacing based on base unit of 8
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const getScaledSpacing = (multiplier: number): number => {
  return SPACING_BASE * multiplier;
};

/**
 * Spacing scale constants based on 8pt grid system
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const Spacing = {
  xs: getScaledSpacing(0.5), // 4
  sm: getScaledSpacing(1),   // 8
  md: getScaledSpacing(2),   // 16
  lg: getScaledSpacing(3),   // 24
  xl: getScaledSpacing(4),   // 32
};

/**
 * Border radius constants for consistent component shapes
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const BorderRadius = {
  sm: BORDER_RADIUS_SM,
  md: BORDER_RADIUS_MD,
  lg: BORDER_RADIUS_LG,
};

/**
 * Creates platform-specific shadow styles
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const createShadow = (elevation: number, opacity: number = SHADOW_OPACITY) => {
  return Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: {
        width: 0,
        height: elevation,
      },
      shadowOpacity: opacity,
      shadowRadius: elevation * 0.75,
    },
    android: {
      elevation: elevation,
    },
    web: {
      boxShadow: `0px ${elevation}px ${elevation * 2}px rgba(0, 0, 0, ${opacity})`,
    },
    default: {},
  });
};

/**
 * Shadow style constants with platform-specific implementations
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const Shadow = {
  sm: createShadow(ELEVATION_BASE),
  md: createShadow(ELEVATION_BASE * 2),
  lg: createShadow(ELEVATION_BASE * 3),
};

/**
 * Common component style patterns using theme colors
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const CommonStyles = StyleSheet.create({
  card: {
    backgroundColor: light.surface.primary,
    borderRadius: BorderRadius.md,
    padding: Spacing.md,
    ...Shadow.sm,
  },

  input: {
    height: getScaledSpacing(5), // 40px
    borderWidth: 1,
    borderColor: light.border.primary,
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.sm,
    backgroundColor: light.surface.primary,
  },

  button: {
    height: getScaledSpacing(5), // 40px
    borderRadius: BorderRadius.sm,
    paddingHorizontal: Spacing.md,
    justifyContent: 'center',
    alignItems: 'center',
    ...Shadow.sm,
  },

  /**
   * Chart container styles for financial data visualization
   * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
   */
  chart: {
    backgroundColor: light.surface.secondary,
    borderRadius: BorderRadius.lg,
    padding: Spacing.md,
    marginVertical: Spacing.sm,
    ...Shadow.md,
    // Additional chart-specific styles
    aspectRatio: Platform.select({
      web: undefined,
      default: 16 / 9,
    }),
    minHeight: Platform.select({
      web: 300,
      default: undefined,
    }),
  },
});