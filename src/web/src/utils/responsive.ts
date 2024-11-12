// react-native version: ^0.71.0

// Human Tasks:
// 1. Test breakpoint behavior across different browser window sizes
// 2. Validate responsive value fallback chains in edge cases
// 3. Verify responsive calculations with design team's specifications
// 4. Test orientation change handling on mobile devices

import { Dimensions, Platform } from 'react-native';
import { xs, sm } from '../constants/styles';

/**
 * Core breakpoint definitions for responsive design system
 * @requirements Responsive Design Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const BREAKPOINTS = {
  xs: 0,    // Extra small devices (portrait phones)
  sm: 576,  // Small devices (landscape phones)
  md: 768,  // Medium devices (tablets)
  lg: 992,  // Large devices (desktops)
  xl: 1200, // Extra large devices (large desktops)
} as const;

/**
 * Screen size category mappings for device-specific adaptations
 * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
export const SCREEN_SIZES = {
  MOBILE: 'xs',  // Mobile phones
  TABLET: 'md',  // Tablets
  DESKTOP: 'lg', // Desktop computers
} as const;

/**
 * Generic type for responsive value objects supporting any value type
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 */
export interface ResponsiveValue<T> {
  xs?: T; // Extra small screens (0-575px)
  sm?: T; // Small screens (576-767px)
  md?: T; // Medium screens (768-991px)
  lg?: T; // Large screens (992-1199px)
  xl?: T; // Extra large screens (1200px+)
}

// Type for valid breakpoint strings
type Breakpoint = keyof typeof BREAKPOINTS;

/**
 * Determines the current breakpoint based on screen width using mobile-first approach
 * @requirements Responsive Design Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const getBreakpoint = (width: number = Dimensions.get('window').width): Breakpoint => {
  // Check breakpoints in descending order to find the matching breakpoint
  if (width >= BREAKPOINTS.xl) return 'xl';
  if (width >= BREAKPOINTS.lg) return 'lg';
  if (width >= BREAKPOINTS.md) return 'md';
  if (width >= BREAKPOINTS.sm) return 'sm';
  return 'xs';
};

/**
 * Checks if current screen width matches or exceeds a given breakpoint
 * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
export const isScreenSize = (breakpoint: Breakpoint): boolean => {
  const currentWidth = Dimensions.get('window').width;
  const breakpointValue = BREAKPOINTS[breakpoint];
  
  return currentWidth >= breakpointValue;
};

/**
 * Returns a value based on current breakpoint from provided responsive object
 * Implements mobile-first fallback chain for missing breakpoint values
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 */
export const getResponsiveValue = <T>(responsiveValues: ResponsiveValue<T>): T => {
  const currentBreakpoint = getBreakpoint();
  const breakpointOrder: Breakpoint[] = ['xl', 'lg', 'md', 'sm', 'xs'];
  
  // Find the first defined value in the fallback chain
  const breakpointIndex = breakpointOrder.indexOf(currentBreakpoint);
  for (let i = breakpointIndex; i < breakpointOrder.length; i++) {
    const breakpoint = breakpointOrder[i];
    const value = responsiveValues[breakpoint];
    if (value !== undefined) {
      return value;
    }
  }
  
  // If no value is found in the fallback chain, throw an error
  throw new Error('No responsive value found in fallback chain. Ensure at least xs is defined.');
};

// Add event listener for dimension changes on web platform
if (Platform.OS === 'web') {
  window.addEventListener('resize', () => {
    // Force dimension update on window resize
    Dimensions.set({
      window: {
        width: window.innerWidth,
        height: window.innerHeight,
        scale: 1,
        fontScale: 1,
      },
    });
  });
}