// react version: ^18.0.0

// Human Tasks:
// 1. Test theme persistence across browser sessions
// 2. Verify system theme detection works across different browsers and operating systems
// 3. Validate theme transition animations if implemented
// 4. Test theme synchronization between multiple open tabs/windows

import { useState, useEffect, useCallback } from 'react';
import { lightTheme, darkTheme, Theme } from '../styles/theme';

// Local storage key for theme preference
const THEME_STORAGE_KEY = 'mint-replica-lite-theme-preference';

/**
 * Custom hook for managing theme state and preferences
 * @returns Object containing theme state and control functions
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const useTheme = () => {
  // Initialize theme state from localStorage or system preference
  const [isDarkMode, setIsDarkMode] = useState<boolean>(() => {
    const savedTheme = localStorage.getItem(THEME_STORAGE_KEY);
    if (savedTheme) {
      return savedTheme === 'dark';
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches;
  });

  // Current theme object based on mode
  const [theme, setThemeState] = useState<Theme>(isDarkMode ? darkTheme : lightTheme);

  /**
   * Handle system theme change events
   * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
   */
  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    const handleSystemThemeChange = (event: MediaQueryListEvent) => {
      const savedTheme = localStorage.getItem(THEME_STORAGE_KEY);
      // Only update if user hasn't set a manual preference
      if (!savedTheme) {
        setIsDarkMode(event.matches);
        setThemeState(event.matches ? darkTheme : lightTheme);
      }
    };

    // Add listener for system theme changes
    if (mediaQuery.addEventListener) {
      mediaQuery.addEventListener('change', handleSystemThemeChange);
    } else {
      // Fallback for older browsers
      mediaQuery.addListener(handleSystemThemeChange);
    }

    // Cleanup listener
    return () => {
      if (mediaQuery.removeEventListener) {
        mediaQuery.removeEventListener('change', handleSystemThemeChange);
      } else {
        // Fallback for older browsers
        mediaQuery.removeListener(handleSystemThemeChange);
      }
    };
  }, []);

  /**
   * Update theme state and persist preference
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  useEffect(() => {
    setThemeState(isDarkMode ? darkTheme : lightTheme);
    localStorage.setItem(THEME_STORAGE_KEY, isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  /**
   * Toggle between light and dark themes
   * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
   */
  const toggleTheme = useCallback(() => {
    setIsDarkMode(prev => !prev);
  }, []);

  /**
   * Explicitly set theme mode
   * @param mode - The desired theme mode ('light' | 'dark')
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  const setTheme = useCallback((mode: 'light' | 'dark') => {
    setIsDarkMode(mode === 'dark');
  }, []);

  return {
    theme,
    isDarkMode,
    toggleTheme,
    setTheme,
  };
};