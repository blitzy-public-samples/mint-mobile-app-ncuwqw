// @reduxjs/toolkit version: ^1.9.0

/**
 * HUMAN TASKS:
 * 1. Verify Redux DevTools is configured in store setup
 * 2. Ensure theme changes persist in local storage
 * 3. Test responsive breakpoints across different devices
 * 4. Validate alert timing configurations
 */

import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { UIState } from '../../types';
import { CommonStyles } from '../../constants/styles';

// Initial state definition based on global configuration
const initialState: UIState = {
  theme: 'light',
  loading: {},
  alerts: [],
  modals: {},
  navigation: {
    currentRoute: '/',
    previousRoute: null
  },
  layout: {
    isMobile: false,
    isTablet: false,
    isDesktop: true
  }
};

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
export const uiSlice = createSlice({
  name: 'ui',
  initialState,
  reducers: {
    // Theme management
    setTheme: (state, action: PayloadAction<'light' | 'dark'>) => {
      const theme = action.payload;
      if (theme !== 'light' && theme !== 'dark') return;
      
      state.theme = theme;
      // Apply theme-specific styles from CommonStyles
      const themeStyles = theme === 'light' ? CommonStyles.card : {
        ...CommonStyles.card,
        backgroundColor: '#1a1a1a'
      };
      
      // Store theme preference in localStorage
      try {
        localStorage.setItem('theme_preference', theme);
      } catch (error) {
        console.error('Failed to persist theme preference:', error);
      }
    },

    // Loading state management
    setLoading: (state, action: PayloadAction<{ [key: string]: boolean }>) => {
      const loadingState = action.payload;
      
      // Validate loading state structure
      Object.entries(loadingState).forEach(([key, value]) => {
        if (typeof value === 'boolean') {
          state.loading[key] = value;
        }
      });

      // Clear loading states after timeout
      Object.keys(loadingState).forEach((key) => {
        if (loadingState[key]) {
          setTimeout(() => {
            state.loading[key] = false;
          }, 30000); // 30-second timeout
        }
      });
    },

    // Alert management
    showAlert: (state, action: PayloadAction<{
      id: string;
      type: 'success' | 'error' | 'warning' | 'info';
      message: string;
      duration?: number;
      dismissible?: boolean;
    }>) => {
      const alert = action.payload;
      
      // Validate alert configuration
      if (!alert.id || !alert.type || !alert.message) return;
      
      // Add alert to queue
      state.alerts.push({
        ...alert,
        timestamp: new Date().toISOString(),
        duration: alert.duration || 5000,
        dismissible: alert.dismissible ?? true
      });

      // Handle alert auto-dismissal
      if (alert.duration !== 0) {
        setTimeout(() => {
          state.alerts = state.alerts.filter(a => a.id !== alert.id);
        }, alert.duration || 5000);
      }
    },

    dismissAlert: (state, action: PayloadAction<string>) => {
      state.alerts = state.alerts.filter(alert => alert.id !== action.payload);
    },

    // Requirement: Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
    updateLayout: (state, action: PayloadAction<{
      width: number;
      height: number;
    }>) => {
      const { width } = action.payload;
      
      // Calculate device type based on viewport width
      state.layout = {
        isMobile: width < 768,
        isTablet: width >= 768 && width < 1024,
        isDesktop: width >= 1024
      };

      // Apply layout-specific styles
      if (state.layout.isMobile) {
        Object.assign(CommonStyles.button, {
          width: '100%',
          height: 48
        });
      } else {
        Object.assign(CommonStyles.button, {
          width: 'auto',
          height: 40
        });
      }
    },

    // Modal management
    showModal: (state, action: PayloadAction<{
      id: string;
      component: string;
      props?: Record<string, unknown>;
    }>) => {
      state.modals[action.payload.id] = {
        component: action.payload.component,
        props: action.payload.props || {},
        isOpen: true
      };
    },

    hideModal: (state, action: PayloadAction<string>) => {
      if (state.modals[action.payload]) {
        state.modals[action.payload].isOpen = false;
      }
    },

    // Navigation state management
    setCurrentRoute: (state, action: PayloadAction<string>) => {
      state.navigation.previousRoute = state.navigation.currentRoute;
      state.navigation.currentRoute = action.payload;
    }
  }
});

// Export actions for component usage
export const {
  setTheme,
  setLoading,
  showAlert,
  dismissAlert,
  updateLayout,
  showModal,
  hideModal,
  setCurrentRoute
} = uiSlice.actions;

// Export reducer as default for store configuration
export default uiSlice.reducer;