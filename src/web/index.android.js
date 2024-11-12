/**
 * HUMAN TASKS:
 * 1. Verify Android app registration in Android Manifest matches 'MintReplicaLite'
 * 2. Ensure minimum SDK version 21 is set in build.gradle
 * 3. Test app launch and initialization on various Android devices
 */

// react-native version: ^0.72.0
import { AppRegistry } from 'react-native';

// Import root application component
import App from './src/App';

/**
 * Android platform entry point that registers the root application component
 * 
 * Requirement: Cross-platform UI (1.1 System Overview/Client Applications)
 * - Initializes React Native Android application with consistent UI
 * 
 * Requirement: State Management (2.2.1 Client Applications/React Native)
 * - App component provides Redux store initialization for Android
 * 
 * Requirement: Platform-Specific Entry Point (5.1.6 Platform-Specific Implementation Notes/Android)
 * - Handles Android-specific registration and lifecycle management
 */

/**
 * Register the root application component with React Native's AppRegistry
 * AppRegistry handles:
 * - Component lifecycle management
 * - Native bridge initialization
 * - Performance optimization for Android
 */
AppRegistry.registerComponent('MintReplicaLite', () => App);