// react-native version: ^0.71.0

// Human Tasks:
// 1. Ensure all font files (Inter and JetBrains Mono) are placed in the assets/fonts directory
// 2. Verify font loading configuration in web/webpack.config.js for handling .ttf files
// 3. Test font loading performance and implement fallback strategies if needed
// 4. Validate font rendering consistency across different browsers and devices

import { Platform } from 'react-native';
import { FONT_FAMILY_BASE, FONT_FAMILY_MONO } from '../../styles/typography';

/**
 * Font weight constants for consistent typography
 * @requirements Cross-Platform Typography - 2.2.1 Client Applications/React Native
 */
export const FontWeights = {
  regular: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
} as const;

/**
 * Font source definitions mapping font families to their respective files
 * @requirements Cross-Platform Typography - 2.2.1 Client Applications/React Native
 */
const FONT_SOURCES = {
  Inter: {
    regular: 'Inter-Regular.ttf',
    medium: 'Inter-Medium.ttf',
    semibold: 'Inter-SemiBold.ttf',
    bold: 'Inter-Bold.ttf',
  },
  JetBrainsMono: {
    regular: 'JetBrainsMono-Regular.ttf',
    medium: 'JetBrainsMono-Medium.ttf',
    bold: 'JetBrainsMono-Bold.ttf',
  },
} as const;

/**
 * Platform-specific font family definitions
 * @requirements Cross-Platform Typography - 2.2.1 Client Applications/React Native
 * @requirements Financial Data Display - 5.1.5 Investment Portfolio View
 */
export const FontFamilies = {
  primary: FONT_FAMILY_BASE,
  mono: FONT_FAMILY_MONO,
} as const;

/**
 * Validates font weight against available weights
 * @param weight - Font weight to validate
 * @throws Error if weight is invalid
 */
const validateFontWeight = (weight: string): void => {
  if (!Object.values(FontWeights).includes(weight)) {
    throw new Error(`Invalid font weight: ${weight}. Available weights: ${Object.values(FontWeights).join(', ')}`);
  }
};

/**
 * Validates font name against available fonts
 * @param fontName - Font name to validate
 * @throws Error if font name is invalid
 */
const validateFontName = (fontName: string): void => {
  if (!Object.keys(FONT_SOURCES).includes(fontName)) {
    throw new Error(`Invalid font name: ${fontName}. Available fonts: ${Object.keys(FONT_SOURCES).join(', ')}`);
  }
};

/**
 * Returns platform-specific font family name with weight variation
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const getFontFamily = (fontName: string, weight: string): string => {
  validateFontName(fontName);
  validateFontWeight(weight);

  return Platform.select({
    web: `${fontName}-${weight}`,
    ios: fontName,
    android: fontName,
    default: fontName,
  }) as string;
};

/**
 * Loads font assets based on platform requirements
 * @requirements Cross-Platform Typography - 2.2.1 Client Applications/React Native
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const loadFonts = async (): Promise<void> => {
  try {
    if (Platform.OS === 'web') {
      const fontPromises: Promise<FontFace>[] = [];

      // Load Inter font variations
      Object.entries(FONT_SOURCES.Inter).forEach(([weight, filename]) => {
        const fontFace = new FontFace(
          'Inter',
          `url(${require(`./${filename}`).default})`,
          { weight: FontWeights[weight as keyof typeof FontWeights] }
        );
        fontPromises.push(fontFace.load());
        document.fonts.add(fontFace);
      });

      // Load JetBrains Mono font variations
      Object.entries(FONT_SOURCES.JetBrainsMono).forEach(([weight, filename]) => {
        const fontFace = new FontFace(
          'JetBrains Mono',
          `url(${require(`./${filename}`).default})`,
          { weight: FontWeights[weight as keyof typeof FontWeights] }
        );
        fontPromises.push(fontFace.load());
        document.fonts.add(fontFace);
      });

      await Promise.all(fontPromises);
      console.log('All fonts loaded successfully');
    } else {
      // For native platforms, fonts are loaded through the native bundler
      // and don't require runtime loading
      console.log('Native platform detected, skipping runtime font loading');
    }
  } catch (error) {
    console.error('Error loading fonts:', error);
    throw new Error('Failed to load application fonts');
  }
};