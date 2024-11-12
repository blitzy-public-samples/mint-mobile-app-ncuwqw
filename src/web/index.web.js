/**
 * HUMAN TASKS:
 * 1. Verify root div element exists in index.html with id="root"
 * 2. Ensure web build configuration is properly set up for React Native Web
 * 3. Test application rendering across different web browsers
 * 4. Validate CSS reset and global styles are applied correctly
 */

// react-native version: ^0.71.0
import { AppRegistry, Platform } from 'react-native';

// Import root application component
import App from './src/App';

/**
 * Application name constant used for registration
 * Requirement: Cross-platform UI (1.1 System Overview/Client Applications)
 */
const appName = 'MintReplicaLite';

/**
 * Web-specific configuration for the application container
 * Requirement: Theme Support (5.1.7 Platform-Specific Implementation Notes/Web)
 */
const webAppConfig = {
  name: appName,
  styles: {
    height: '100%',
    width: '100%',
  }
};

/**
 * Registers the React Native Web application and configures web-specific settings
 * Requirement: Cross-platform UI (1.1 System Overview/Client Applications)
 */
const registerApp = () => {
  // Register the root component
  AppRegistry.registerComponent(appName, () => App);

  // Web-specific registration and setup
  if (Platform.OS === 'web') {
    // Configure global styles for the root container
    const rootTag = document.getElementById('root');
    if (rootTag) {
      rootTag.style.height = '100%';
      rootTag.style.width = '100%';
    }

    // Apply default styles to html and body
    document.documentElement.style.height = '100%';
    document.body.style.height = '100%';
    document.body.style.margin = '0';
    document.body.style.padding = '0';

    // Run the web application
    AppRegistry.runApplication(appName, {
      rootTag,
      initialProps: {},
      callback: () => {
        // Optional callback after successful rendering
        console.log(`${appName} web application initialized successfully`);
      }
    });
  }
};

// Initialize the application
registerApp();