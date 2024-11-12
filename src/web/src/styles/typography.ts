// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify font families are installed and available in the web environment
// 2. Test font scaling across different device sizes and breakpoints
// 3. Validate typography scale matches iOS native app specifications
// 4. Ensure custom fonts are properly loaded and cached for optimal performance

import { Platform } from 'react-native';
import { StyleSheet, CommonStyles } from '../constants/styles';
import type { Theme } from './theme';

// Global typography constants
const FONT_SCALE_BASE = 1;
const FONT_FAMILY_BASE = "'Inter', system-ui, -apple-system, sans-serif";
const FONT_FAMILY_MONO = "'JetBrains Mono', monospace";
const LINE_HEIGHT_BASE = 1.5;

/**
 * Font size scale constants for consistent sizing across the application
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const FontSizes = {
  xs: 12,
  sm: 14,
  md: 16,
  lg: 20,
  xl: 24,
};

/**
 * Font weight constants aligned with theme definitions
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const FontWeights = {
  regular: 400,
  medium: 500,
  bold: 700,
};

/**
 * Calculates responsive font size with platform-specific adjustments
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const getScaledFontSize = (baseSize: number, scaleFactor: number = FONT_SCALE_BASE): number => {
  const scaledSize = baseSize * scaleFactor;
  
  return Platform.select({
    web: scaledSize,
    ios: scaledSize,
    android: scaledSize * 0.95, // Slight adjustment for Android rendering
    default: scaledSize,
  });
};

/**
 * Creates consistent text style object with platform-specific adjustments
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const createTextStyle = (styleProps: Partial<Theme['typography']['scale'][keyof Theme['typography']['scale']]>) => {
  return StyleSheet.create({
    style: {
      fontFamily: Platform.select({
        web: FONT_FAMILY_BASE,
        ios: '-apple-system',
        android: 'Roboto',
        default: FONT_FAMILY_BASE,
      }),
      lineHeight: (styleProps.fontSize || FontSizes.md) * LINE_HEIGHT_BASE,
      ...styleProps,
    },
  }).style;
};

/**
 * Typography styles with platform-specific adjustments
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const Typography = {
  h1: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.xl * 1.5),
    fontWeight: FontWeights.bold.toString(),
    letterSpacing: -0.5,
  }),

  h2: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.xl),
    fontWeight: FontWeights.bold.toString(),
    letterSpacing: -0.25,
  }),

  h3: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.lg),
    fontWeight: FontWeights.medium.toString(),
    letterSpacing: 0,
  }),

  body1: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.md),
    fontWeight: FontWeights.regular.toString(),
    letterSpacing: 0.15,
  }),

  body2: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.sm),
    fontWeight: FontWeights.regular.toString(),
    letterSpacing: 0.25,
  }),

  caption: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.xs),
    fontWeight: FontWeights.regular.toString(),
    letterSpacing: 0.4,
  }),

  button: createTextStyle({
    fontSize: getScaledFontSize(FontSizes.sm),
    fontWeight: FontWeights.medium.toString(),
    letterSpacing: 0.25,
    textTransform: 'uppercase',
  }),

  /**
   * Monospace style for financial data display
   * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
   */
  mono: createTextStyle({
    fontFamily: FONT_FAMILY_MONO,
    fontSize: getScaledFontSize(FontSizes.sm),
    fontWeight: FontWeights.regular.toString(),
    letterSpacing: 0,
  }),
};