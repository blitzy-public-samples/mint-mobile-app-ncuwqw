// @ts-check

// metro-config v0.76.0 - Metro bundler configuration for React Native
const { getDefaultConfig } = require('metro-config');
const path = require('path'); // path v0.12.7

/**
 * Human Tasks:
 * 1. Ensure node_modules directory is present at project root
 * 2. Install required dependencies:
 *    - metro-config@^0.76.0
 *    - metro-react-native-babel-transformer (latest)
 *    - react-native-web/asset-register (latest)
 * 3. Verify Metro bundler port 8081 is available
 */

/**
 * Retrieves and customizes the default Metro configuration for React Native web and Android compatibility
 * Requirements addressed:
 * - Cross-platform Development (1.1 System Overview/Client Applications)
 * - Client Applications (2.1 High-Level Architecture Overview/Client Layer)
 */
async function getConfig() {
  // Get default Metro configuration
  const config = await getDefaultConfig();

  // Configure module resolution settings
  const resolver = {
    ...config.resolver,
    // Source file extensions for JavaScript/TypeScript
    sourceExts: [
      'js',
      'jsx', 
      'ts',
      'tsx',
      'json'
    ],
    // Asset file extensions for images and fonts
    assetExts: [
      'png',
      'jpg', 
      'jpeg',
      'gif',
      'webp',
      'ttf',
      'otf'
    ],
    // Supported platforms
    platforms: [
      'android',
      'web'
    ],
    // Module resolution fields in package.json
    resolverMainFields: [
      'react-native',
      'browser',
      'main'
    ]
  };

  // Configure transformer settings
  const transformer = {
    ...config.transformer,
    // Babel transformer for React Native
    babelTransformerPath: require.resolve('metro-react-native-babel-transformer'),
    // Asset plugins for web platform
    assetPlugins: ['react-native-web/asset-register'],
    // Enable Babel runtime
    enableBabelRuntime: true,
    // Minification settings to preserve class and function names
    minifierConfig: {
      keep_classnames: true,
      keep_fnames: true,
      mangle: {
        keep_classnames: true,
        keep_fnames: true
      }
    }
  };

  // Configure development server settings
  const server = {
    ...config.server,
    port: 8081,
    enhanceMiddleware: true
  };

  // Configure watched folders
  const watchFolders = [
    path.resolve(__dirname, '../../node_modules')
  ];

  // Return customized configuration
  return {
    ...config,
    resolver,
    transformer,
    server,
    watchFolders
  };
}

// Export Metro configuration
module.exports = getConfig();