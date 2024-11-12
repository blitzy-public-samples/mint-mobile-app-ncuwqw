// HUMAN TASKS:
// 1. Verify all testing library packages are installed with correct versions:
//    - jest@^29.0.0
//    - ts-jest@^29.0.0
//    - @testing-library/react@^14.0.0
//    - @testing-library/react-native@^12.0.0
//    - @testing-library/jest-dom@^5.16.0
// 2. Ensure setupTests.ts is properly configured with testing library imports
// 3. Configure IDE Jest test runner integration

// Requirement: Testing Infrastructure (A.2 Code Quality Standards)
// Configure comprehensive testing setup with Jest and Testing Library

const { compilerOptions } = require('./tsconfig.json');

/**
 * Creates a module name mapper configuration from TypeScript path aliases
 * @returns {Object} Module name mapper object
 */
function createModuleNameMapper() {
  const { paths } = compilerOptions;
  
  const moduleNameMapper = {};
  for (const [alias, [path]] of Object.entries(paths)) {
    // Convert TypeScript path mapping syntax to Jest syntax
    const key = `^${alias.replace('/*', '/(.*)$')}`;
    const value = `<rootDir>/${path.replace('/*', '/$1')}`;
    moduleNameMapper[key] = value;
  }

  return moduleNameMapper;
}

// Requirement: Cross-platform Testing (1.1 System Overview/Client Applications)
// Configure test environment for React Native Web platform
const config = {
  // Use React Native preset as base configuration
  preset: 'react-native',

  // Configure jsdom test environment for web testing
  testEnvironment: 'jsdom',

  // Setup files to run before tests
  setupFilesAfterEnv: [
    '@testing-library/jest-dom' // Adds custom DOM matchers
  ],
  setupFiles: [
    '<rootDir>/src/setupTests.ts'
  ],

  // Test file patterns
  testMatch: [
    '<rootDir>/src/**/__tests__/**/*.{js,jsx,ts,tsx}',
    '<rootDir>/src/**/*.{spec,test}.{js,jsx,ts,tsx}'
  ],

  // Module resolution configuration
  moduleNameMapper: createModuleNameMapper(),

  // TypeScript and JavaScript transformation
  transform: {
    '^.+\\.(ts|tsx|js|jsx)$': 'ts-jest'
  },

  // Ignore transformation for specific node_modules
  transformIgnorePatterns: [
    'node_modules/(?!(react-native|@react-native|react-native-reanimated)/)'
  ],

  // Coverage configuration
  collectCoverage: true,
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.d.ts',
    '!src/index.tsx',
    '!src/serviceWorker.ts'
  ],
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/android/',
    '/ios/',
    '/build/',
    '/dist/'
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80
    }
  },
  coverageReporters: [
    'json',
    'lcov',
    'text',
    'clover'
  ],

  // Additional configuration
  verbose: true,
  clearMocks: true,
  resetMocks: true,
  restoreMocks: true,
  testTimeout: 10000,
  
  // Globals configuration
  globals: {
    'ts-jest': {
      tsconfig: './tsconfig.json',
      diagnostics: true,
      isolatedModules: true
    }
  }
};

module.exports = config;