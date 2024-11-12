// @ts-check

// HUMAN TASKS:
// 1. Ensure Node.js version >= 14.0.0 is installed
// 2. Install required dependencies with exact versions:
//    npm install --save-dev 
//      metro-react-native-babel-preset@0.76.0
//      @babel/preset-typescript@7.21.0
//      @babel/preset-react@7.18.0
//      @babel/plugin-proposal-decorators@7.21.0
//      @babel/plugin-transform-runtime@7.21.0
//      react-native-reanimated@3.0.0
//      babel-plugin-transform-remove-console@6.9.4
//      react-native-paper@5.0.0

// metro-react-native-babel-preset@0.76.0
// @babel/preset-typescript@7.21.0
// @babel/preset-react@7.18.0
// @babel/plugin-proposal-decorators@7.21.0
// @babel/plugin-transform-runtime@7.21.0
// react-native-reanimated@3.0.0
// babel-plugin-transform-remove-console@6.9.4
// react-native-paper@5.0.0

/**
 * Babel configuration for React Native Web application
 * Addresses requirements:
 * - Cross-platform Development: Configures transpilation for React Native Android and Web
 * - Type Safety: Enables TypeScript support with strict type checking
 */

/**
 * Returns the appropriate Babel presets based on the environment
 * @param {object} api - Babel API object
 * @returns {array} Array of configured presets
 */
const getPresets = (api) => {
  // Cache the configuration for better performance
  api.cache(true);

  return [
    // Base React Native preset for core JavaScript transformations
    [
      'module:metro-react-native-babel-preset',
      {
        // Enable JSX transformation optimizations
        enableBabelRuntime: true,
      }
    ],
    // TypeScript preset with strict mode enabled
    [
      '@babel/preset-typescript',
      {
        isTSX: true,
        allExtensions: true,
        allowNamespaces: true,
        allowDeclareFields: true,
        onlyRemoveTypeImports: true,
      }
    ],
    // React preset with React Native Web optimizations
    [
      '@babel/preset-react',
      {
        runtime: 'automatic',
        development: !api.env('production'),
        importSource: '@welldone-software/why-did-you-render',
      }
    ]
  ];
};

// Export Babel configuration
module.exports = function(api) {
  const presets = getPresets(api);
  
  return {
    presets,
    plugins: [
      // Enable React Native Reanimated support
      'react-native-reanimated/plugin',
      
      // Support for TypeScript decorators
      ['@babel/plugin-proposal-decorators', { 
        legacy: true 
      }],
      
      // Runtime transformation for async/await
      ['@babel/plugin-transform-runtime', {
        helpers: true,
        regenerator: true
      }],
    ],
    
    // Production-specific configuration
    env: {
      production: {
        plugins: [
          // Remove console.log statements in production
          'transform-remove-console',
          
          // React Native Paper optimizations
          'react-native-paper/babel'
        ]
      }
    }
  };
};