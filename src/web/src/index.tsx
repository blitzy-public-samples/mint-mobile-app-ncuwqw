/**
 * HUMAN TASKS:
 * 1. Verify React Developer Tools are installed in the browser for development
 * 2. Ensure Redux DevTools extension is installed for state debugging
 * 3. Test Hot Module Replacement functionality in development mode
 * 4. Validate root element creation and mounting in different environments
 */

// react version: ^18.0.0
import React from 'react';
// react-dom version: ^18.0.0
import { createRoot } from 'react-dom/client';
// react-redux version: ^8.1.0
import { Provider } from 'react-redux';
// redux-persist version: ^6.0.0
import { PersistGate } from 'redux-persist/integration/react';

// Internal imports with relative paths
import App from './App';
import { store, persistor } from './store';

/**
 * Requirement: Cross-platform UI (1.1 System Overview/Client Applications)
 * Get or create the root DOM element for mounting the application
 */
const rootElement = document.getElementById('root') || document.createElement('div');
if (!rootElement.id) {
  rootElement.id = 'root';
}

// Append root element to document if not already present
if (!document.body.contains(rootElement)) {
  document.body.appendChild(rootElement);
}

// Development mode flag for conditional features
const isDevelopment = process.env.NODE_ENV === 'development';

/**
 * Renders the root application component with all required providers
 * Requirement: State Management (2.2.1 Client Applications/React Native)
 * Requirement: Theme Support (5.1.7 Platform-Specific Implementation Notes/Web)
 */
const renderApp = () => {
  const root = createRoot(rootElement);

  root.render(
    isDevelopment ? (
      <React.StrictMode>
        <Provider store={store}>
          <PersistGate loading={null} persistor={persistor}>
            <App />
          </PersistGate>
        </Provider>
      </React.StrictMode>
    ) : (
      <Provider store={store}>
        <PersistGate loading={null} persistor={persistor}>
          <App />
        </PersistGate>
      </Provider>
    )
  );
};

// Initial render
renderApp();

/**
 * Enable Hot Module Replacement for development
 * Allows for instant feedback during development without full page reloads
 */
if (isDevelopment && module.hot) {
  module.hot.accept('./App', () => {
    renderApp();
  });
}