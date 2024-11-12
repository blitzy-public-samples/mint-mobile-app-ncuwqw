// HUMAN TASKS:
// 1. Verify all ESLint plugins are installed with correct versions in package.json
// 2. Ensure TypeScript and Prettier are properly configured in the development environment
// 3. Configure IDE/editor ESLint integration for real-time linting

// External plugin versions:
// @typescript-eslint/parser@^5.0.0
// @typescript-eslint/eslint-plugin@^5.0.0
// eslint-plugin-react@^7.32.0
// eslint-plugin-react-hooks@^4.6.0
// eslint-plugin-react-native@^4.0.0
// eslint-config-prettier@^8.8.0
// eslint-plugin-import@^2.27.0
// eslint-plugin-jest@^27.2.0

// Requirement: Code Quality Standards - Static code analysis enforcement using ESLint
module.exports = {
  root: true,
  
  // Environment configuration
  env: {
    browser: true,
    es2021: true,
    node: true,
    jest: true,
    'react-native/react-native': true,
  },

  // Requirement: Type Safety - TypeScript linting rules integration
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
    'plugin:react-native/all',
    'plugin:jest/recommended',
    'prettier', // Must be last to override other configs
  ],

  // TypeScript parser configuration
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    ecmaVersion: 2021,
    sourceType: 'module',
    project: './tsconfig.json', // Reference to TypeScript configuration
  },

  // Required plugins
  plugins: [
    '@typescript-eslint',
    'react',
    'react-hooks',
    'react-native',
    'import',
    'jest',
  ],

  // Requirement: Cross-platform Development - React Native Web specific settings
  settings: {
    react: {
      version: 'detect',
    },
    'import/resolver': {
      typescript: {}, // Use TypeScript resolver
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx'],
      },
    },
  },

  // Linting rules configuration
  rules: {
    // TypeScript specific rules
    '@typescript-eslint/explicit-function-return-type': 'off', // Allow type inference
    '@typescript-eslint/explicit-module-boundary-types': 'off', // Allow type inference for exported functions
    '@typescript-eslint/no-explicit-any': 'error', // Enforce type safety
    '@typescript-eslint/no-unused-vars': ['error', { 
      argsIgnorePattern: '^_', // Allow unused variables starting with underscore
    }],

    // React specific rules
    'react/prop-types': 'off', // Not needed with TypeScript
    'react-hooks/rules-of-hooks': 'error', // Enforce hooks rules
    'react-hooks/exhaustive-deps': 'warn', // Warn about missing dependencies

    // React Native specific rules
    'react-native/no-unused-styles': 'error', // Prevent unused style definitions
    'react-native/split-platform-components': 'error', // Enforce platform-specific components
    'react-native/no-inline-styles': 'warn', // Discourage inline styles
    'react-native/no-raw-text': 'warn', // Enforce Text component usage

    // Import/export rules
    'import/order': ['error', {
      groups: [
        'builtin',
        'external',
        'internal',
        'parent',
        'sibling',
        'index',
      ],
      'newlines-between': 'always',
      alphabetize: {
        order: 'asc',
      },
    }],

    // Jest testing rules
    'jest/no-disabled-tests': 'warn',
    'jest/no-focused-tests': 'error',
    'jest/valid-expect': 'error',
  },
};