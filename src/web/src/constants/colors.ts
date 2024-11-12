// react-native version: 0.71.0

// Human Tasks:
// 1. Verify color contrast ratios meet WCAG 2.1 AA standards for accessibility
// 2. Validate color combinations with design team for financial data visualization
// 3. Test color appearance across different monitor calibrations and devices
// 4. Ensure color-blind friendly alternatives are available for charts

import { Platform } from 'react-native';

// Global opacity constants for interactive states
export const OPACITY_DISABLED = 0.5;
export const OPACITY_PRESSED = 0.7;

/**
 * Light theme color palette
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const light = {
  background: {
    primary: '#FFFFFF',
    secondary: '#F5F7FA',
    tertiary: '#E8ECF0'
  },
  surface: {
    primary: '#FFFFFF',
    secondary: '#F8FAFC',
    elevated: '#FFFFFF'
  },
  text: {
    primary: '#1A2027',
    secondary: '#4A5568',
    tertiary: '#718096',
    inverse: '#FFFFFF'
  },
  border: {
    primary: '#E2E8F0',
    secondary: '#EDF2F7'
  }
};

/**
 * Dark theme color palette
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const dark = {
  background: {
    primary: '#121212',
    secondary: '#1E1E1E',
    tertiary: '#2D2D2D'
  },
  surface: {
    primary: '#1E1E1E',
    secondary: '#2D2D2D',
    elevated: '#383838'
  },
  text: {
    primary: '#FFFFFF',
    secondary: '#E2E8F0',
    tertiary: '#A0AEC0',
    inverse: '#1A2027'
  },
  border: {
    primary: '#2D2D2D',
    secondary: '#383838'
  }
};

/**
 * Shared semantic colors for both light and dark themes
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const shared = {
  primary: {
    main: '#0066FF',
    light: '#3384FF',
    dark: '#0052CC'
  },
  secondary: {
    main: '#6B7280',
    light: '#9CA3AF',
    dark: '#4B5563'
  },
  success: {
    main: '#10B981',
    light: '#34D399',
    dark: '#059669'
  },
  warning: {
    main: '#F59E0B',
    light: '#FBBF24',
    dark: '#D97706'
  },
  error: {
    main: '#EF4444',
    light: '#F87171',
    dark: '#DC2626'
  },
  info: {
    main: '#3B82F6',
    light: '#60A5FA',
    dark: '#2563EB'
  }
};

/**
 * Specialized color arrays for financial data visualization
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const ChartColors = {
  // Color sequence for investment portfolio visualization
  investment: [
    '#0066FF', // Primary blue
    '#10B981', // Success green
    '#F59E0B', // Warning orange
    '#3B82F6', // Info blue
    '#8B5CF6', // Purple
    '#EC4899'  // Pink
  ],
  
  // Color sequence for budget category visualization
  budget: [
    '#10B981', // Success green
    '#F59E0B', // Warning orange
    '#EF4444', // Error red
    '#6B7280'  // Secondary gray
  ],
  
  // Status indicator colors
  status: {
    positive: '#10B981', // Success green
    negative: '#EF4444', // Error red
    neutral: '#6B7280'   // Secondary gray
  }
};

// Export combined color object for theme-aware components
export const Colors = {
  light,
  dark,
  shared,
  // Platform-specific opacity handling
  opacity: Platform.select({
    web: {
      disabled: OPACITY_DISABLED,
      pressed: OPACITY_PRESSED
    },
    default: {
      disabled: OPACITY_DISABLED,
      pressed: OPACITY_PRESSED
    }
  })
};