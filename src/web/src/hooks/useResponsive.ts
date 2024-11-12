// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Test hook behavior across different screen sizes and orientations
// 2. Verify breakpoint transitions are smooth and performant
// 3. Test memory leaks with component unmounting
// 4. Validate responsive behavior in different browsers

import { useState, useEffect } from 'react';
import { Dimensions } from 'react-native';
import { BREAKPOINTS, getBreakpoint, isScreenSize } from '../utils/responsive';

/**
 * Interface defining the return type of useResponsive hook
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
 */
export interface ResponsiveInfo {
  currentBreakpoint: string;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  width: number;
  height: number;
}

/**
 * Custom hook that provides responsive design utilities and screen size information
 * using a mobile-first approach
 * @returns {ResponsiveInfo} Object containing current breakpoint, device type flags, and screen dimensions
 * @requirements Responsive Design Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const useResponsive = (): ResponsiveInfo => {
  // Initialize screen dimensions state
  const [dimensions, setDimensions] = useState(() => ({
    width: Dimensions.get('window').width,
    height: Dimensions.get('window').height
  }));

  // Initialize current breakpoint state
  const [currentBreakpoint, setCurrentBreakpoint] = useState(() => 
    getBreakpoint(dimensions.width)
  );

  /**
   * Handle screen dimension changes and update states
   * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
   */
  useEffect(() => {
    const handleDimensionChange = ({ window }: { window: { width: number; height: number } }) => {
      setDimensions({
        width: window.width,
        height: window.height
      });
      setCurrentBreakpoint(getBreakpoint(window.width));
    };

    // Subscribe to dimension changes
    const subscription = Dimensions.addEventListener('change', handleDimensionChange);

    // Cleanup subscription on unmount
    return () => {
      subscription.remove();
    };
  }, []);

  /**
   * Calculate device type flags based on current screen size
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications
   */
  const isMobile = !isScreenSize('sm'); // xs only
  const isTablet = isScreenSize('md') && !isScreenSize('lg'); // md only
  const isDesktop = isScreenSize('lg'); // lg and above

  return {
    currentBreakpoint,
    isMobile,
    isTablet,
    isDesktop,
    width: dimensions.width,
    height: dimensions.height
  };
};

export default useResponsive;