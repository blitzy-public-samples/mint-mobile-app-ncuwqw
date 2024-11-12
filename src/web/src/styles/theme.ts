// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Verify theme appearance across different browsers and devices
// 2. Test system dark mode integration with theme switching
// 3. Validate responsive breakpoints with design team
// 4. Ensure theme tokens match iOS native app specifications

import { DefaultTheme } from '@react-navigation/native';
import { light, dark, shared } from '../constants/colors';
import { Spacing } from '../constants/styles';

// Global font constants
const FONT_FAMILY_BASE = "'Inter', system-ui, -apple-system, sans-serif";
const FONT_WEIGHT_REGULAR = '400';
const FONT_WEIGHT_MEDIUM = '500';
const FONT_WEIGHT_BOLD = '700';

/**
 * Theme type definition extending React Navigation's DefaultTheme
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export type Theme = {
  colors: typeof light & {
    semantic: typeof shared;
  };
  typography: {
    fontFamily: string;
    fontWeights: {
      regular: string;
      medium: string;
      bold: string;
    };
    scale: {
      h1: {
        fontSize: number;
        lineHeight: number;
        fontWeight: string;
      };
      h2: {
        fontSize: number;
        lineHeight: number;
        fontWeight: string;
      };
      h3: {
        fontSize: number;
        lineHeight: number;
        fontWeight: string;
      };
      body1: {
        fontSize: number;
        lineHeight: number;
      };
      body2: {
        fontSize: number;
        lineHeight: number;
      };
      caption: {
        fontSize: number;
        lineHeight: number;
      };
    };
  };
  spacing: typeof Spacing;
  shape: {
    borderRadius: {
      sm: number;
      md: number;
      lg: number;
    };
    shadow: {
      sm: string;
      md: string;
      lg: string;
    };
  };
} & typeof DefaultTheme;

/**
 * Creates a complete theme object based on color mode
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const createTheme = (mode: 'light' | 'dark'): Theme => {
  const colorPalette = mode === 'light' ? light : dark;

  return {
    ...DefaultTheme,
    colors: {
      ...colorPalette,
      semantic: shared,
    },
    typography: {
      fontFamily: FONT_FAMILY_BASE,
      fontWeights: {
        regular: FONT_WEIGHT_REGULAR,
        medium: FONT_WEIGHT_MEDIUM,
        bold: FONT_WEIGHT_BOLD,
      },
      scale: {
        h1: {
          fontSize: 32,
          lineHeight: 40,
          fontWeight: FONT_WEIGHT_BOLD,
        },
        h2: {
          fontSize: 24,
          lineHeight: 32,
          fontWeight: FONT_WEIGHT_BOLD,
        },
        h3: {
          fontSize: 20,
          lineHeight: 28,
          fontWeight: FONT_WEIGHT_MEDIUM,
        },
        body1: {
          fontSize: 16,
          lineHeight: 24,
        },
        body2: {
          fontSize: 14,
          lineHeight: 20,
        },
        caption: {
          fontSize: 12,
          lineHeight: 16,
        },
      },
    },
    spacing: {
      xs: Spacing.xs,
      sm: Spacing.sm,
      md: Spacing.md,
      lg: Spacing.lg,
    },
    shape: {
      borderRadius: {
        sm: 4,
        md: 8,
        lg: 12,
      },
      shadow: {
        sm: '0px 2px 4px rgba(0, 0, 0, 0.1)',
        md: '0px 4px 8px rgba(0, 0, 0, 0.12)',
        lg: '0px 8px 16px rgba(0, 0, 0, 0.14)',
      },
    },
  };
};

/**
 * Light theme configuration
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const lightTheme: Theme = createTheme('light');

/**
 * Dark theme configuration
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const darkTheme: Theme = createTheme('dark');