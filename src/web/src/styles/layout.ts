// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify container max-width behavior in production environment
// 2. Test grid system responsiveness across all breakpoints
// 3. Validate layout performance with large component trees
// 4. Ensure RTL layout support is properly configured

import { StyleSheet, Platform, Dimensions } from 'react-native'; // ^0.71.0
import { BREAKPOINTS } from '../styles/responsive';
import { Spacing } from '../constants/styles';

// Global constants for layout configuration
const CONTAINER_PADDING = 16;
const GRID_COLUMNS = 12;
const GRID_GUTTER = 16;
const MAX_CONTENT_WIDTH = 1200;

/**
 * Creates responsive container styles
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @param fluid - Whether container should be fluid width or fixed
 */
const createContainer = (fluid: boolean) => {
  const baseStyles = {
    paddingHorizontal: CONTAINER_PADDING,
    width: '100%',
    marginHorizontal: 'auto',
  };

  return StyleSheet.create({
    container: {
      ...baseStyles,
      ...(fluid
        ? {}
        : {
            maxWidth: Platform.select({
              web: MAX_CONTENT_WIDTH,
              default: '100%',
            }),
            [`@media (max-width: ${BREAKPOINTS.sm}px)`]: {
              maxWidth: '100%',
            },
            [`@media (min-width: ${BREAKPOINTS.sm}px)`]: {
              maxWidth: BREAKPOINTS.sm - CONTAINER_PADDING * 2,
            },
            [`@media (min-width: ${BREAKPOINTS.md}px)`]: {
              maxWidth: BREAKPOINTS.md - CONTAINER_PADDING * 2,
            },
            [`@media (min-width: ${BREAKPOINTS.lg}px)`]: {
              maxWidth: BREAKPOINTS.lg - CONTAINER_PADDING * 2,
            },
            [`@media (min-width: ${BREAKPOINTS.xl}px)`]: {
              maxWidth: MAX_CONTENT_WIDTH,
            },
          }),
    },
  }).container;
};

/**
 * Creates grid column styles with responsive widths
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const createGridColumn = (
  columns: number,
  breakpoints?: { [key: string]: number }
) => {
  if (columns < 1 || columns > GRID_COLUMNS) {
    throw new Error(`Columns must be between 1 and ${GRID_COLUMNS}`);
  }

  const baseWidth = (columns / GRID_COLUMNS) * 100;
  const styles: any = {
    flexGrow: 0,
    flexShrink: 0,
    paddingHorizontal: GRID_GUTTER / 2,
    width: `${baseWidth}%`,
  };

  if (breakpoints) {
    Object.entries(breakpoints).forEach(([breakpoint, cols]) => {
      if (BREAKPOINTS[breakpoint as keyof typeof BREAKPOINTS]) {
        styles[`@media (min-width: ${BREAKPOINTS[breakpoint as keyof typeof BREAKPOINTS]}px)`] = {
          width: `${(cols / GRID_COLUMNS) * 100}%`,
        };
      }
    });
  }

  return StyleSheet.create({ column: styles }).column;
};

/**
 * Container styles for page layouts
 * @requirements Dashboard Layout - 5.1.2 Dashboard Layout
 */
export const Container = {
  fluid: createContainer(true),
  fixed: createContainer(false),
};

/**
 * Grid system styles and utilities
 * @requirements Dashboard Layout - 5.1.2 Dashboard Layout
 */
export const Grid = {
  row: StyleSheet.create({
    row: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      marginHorizontal: -GRID_GUTTER / 2,
    },
  }).row,
  column: createGridColumn,
};

/**
 * Flexbox layout utilities
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const Flex = StyleSheet.create({
  row: {
    flexDirection: 'row',
  },
  column: {
    flexDirection: 'column',
  },
  center: {
    justifyContent: 'center',
    alignItems: 'center',
  },
});

/**
 * Spacing utility styles
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const Spacing = StyleSheet.create({
  margin: {
    sm: { margin: Spacing.sm },
    md: { margin: Spacing.md },
    lg: { margin: Spacing.lg },
  },
  padding: {
    sm: { padding: Spacing.sm },
    md: { padding: Spacing.md },
    lg: { padding: Spacing.lg },
  },
});