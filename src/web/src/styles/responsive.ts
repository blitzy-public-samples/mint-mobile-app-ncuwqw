// react-native version: ^0.71.0

// Human Tasks:
// 1. Test breakpoint behavior across different devices and browsers
// 2. Validate container width calculations with design team
// 3. Verify responsive behavior in development and production environments
// 4. Ensure breakpoints align with design system specifications

import { Dimensions, Platform } from 'react-native';
import { sm, md, lg } from '../constants/styles';

/**
 * Standard breakpoints for responsive design system
 * @requirements Responsive Design Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const BREAKPOINTS = {
  xs: 0,    // Mobile-first base size
  sm: 576,  // Small devices (landscape phones)
  md: 768,  // Medium devices (tablets)
  lg: 992,  // Large devices (desktops)
  xl: 1200, // Extra large devices (large desktops)
} as const;

/**
 * Grid system configuration
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 */
const GRID_COLUMNS = 12;

/**
 * Container padding for different breakpoints
 * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
const CONTAINER_PADDING = {
  xs: 16, // Aligned with spacing system
  sm: 24, // Matches md spacing constant
  md: 32, // Matches lg spacing constant
  lg: 48, // Extra padding for larger screens
};

type BreakpointKey = keyof typeof BREAKPOINTS;

/**
 * Determines current breakpoint based on screen width
 * @requirements Responsive Design Support - 5.1.7 Platform-Specific Implementation Notes/Web
 * @param width - Current screen width
 * @returns Current breakpoint key
 */
export const getBreakpoint = (width: number): BreakpointKey => {
  if (width >= BREAKPOINTS.xl) return 'xl';
  if (width >= BREAKPOINTS.lg) return 'lg';
  if (width >= BREAKPOINTS.md) return 'md';
  if (width >= BREAKPOINTS.sm) return 'sm';
  return 'xs';
};

/**
 * Checks if current screen width matches or exceeds given breakpoint
 * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
 * @param breakpoint - Breakpoint to check against
 * @returns Boolean indicating if screen size matches or exceeds breakpoint
 */
export const isScreenSize = (breakpoint: BreakpointKey): boolean => {
  const { width } = Dimensions.get('window');
  return width >= BREAKPOINTS[breakpoint];
};

/**
 * Calculates container width based on current breakpoint
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 * @param breakpoint - Current breakpoint
 * @returns Container width in pixels
 */
export const getContainerWidth = (breakpoint: BreakpointKey): number => {
  // Get the maximum width for the current breakpoint
  const maxWidth = BREAKPOINTS[breakpoint];
  
  // Get the padding for the current breakpoint
  const padding = CONTAINER_PADDING[breakpoint as keyof typeof CONTAINER_PADDING];
  
  // For xs breakpoint, use full width minus padding
  if (breakpoint === 'xs') {
    const { width } = Dimensions.get('window');
    return Math.max(width - (padding * 2), 0);
  }
  
  // For other breakpoints, use breakpoint width minus padding
  return Math.max(maxWidth - (padding * 2), 0);
};

/**
 * Platform-specific responsive adjustments
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 */
if (Platform.OS === 'web') {
  // Add resize event listener to update dimensions
  window.addEventListener('resize', () => {
    // Force dimension update on web platform
    Dimensions.addEventListener('change', () => {});
  });
}