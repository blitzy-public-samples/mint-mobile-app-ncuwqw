/**
 * HUMAN TASKS:
 * 1. Verify dark mode detection works correctly across different browsers
 * 2. Test Redux state persistence after browser refresh
 * 3. Validate theme transitions when system preference changes
 * 4. Ensure styled-components SSR configuration is set up for production
 */

// react version: ^18.0.0
import React from 'react';
// react-redux version: ^8.1.0
import { Provider } from 'react-redux';
// redux-persist version: ^6.0.0
import { PersistGate } from 'redux-persist/integration/react';
// @react-native-web/styled-components version: ^1.15.0
import { ThemeProvider } from '@react-native-web/styled-components';

// Internal imports with relative paths
import AppNavigator from './navigation/AppNavigator';
import { store, persistor } from './store';
import { lightTheme, darkTheme } from './styles/theme';

/**
 * Root application component that sets up core infrastructure and providers
 * Requirement: Cross-platform UI (1.1 System Overview/Client Applications)
 * Requirement: State Management (2.2.1 Client Applications/React Native)
 * Requirement: Theme Support (5.1.7 Platform-Specific Implementation Notes/Web)
 */
const App: React.FC = React.memo(() => {
  // Initialize dark mode detection using system preferences
  const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;

  // Set up theme based on system preference
  const [currentTheme, setCurrentTheme] = React.useState(isDarkMode ? darkTheme : lightTheme);

  // Update theme when system preference changes
  React.useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    
    const handleThemeChange = (event: MediaQueryListEvent) => {
      setCurrentTheme(event.matches ? darkTheme : lightTheme);
    };

    // Add listener for theme changes
    mediaQuery.addEventListener('change', handleThemeChange);

    // Cleanup listener on component unmount
    return () => {
      mediaQuery.removeEventListener('change', handleThemeChange);
    };
  }, []);

  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <ThemeProvider theme={currentTheme}>
          <AppNavigator />
        </ThemeProvider>
      </PersistGate>
    </Provider>
  );
});

// Set display name for debugging purposes
App.displayName = 'App';

export default App;