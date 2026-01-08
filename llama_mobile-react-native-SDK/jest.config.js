module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: [],
  moduleNameMapper: {
    '^react-native$': require.resolve('react-native'),
  },
  transform: {
    '^.+\.(js|jsx|ts|tsx)$': 'babel-jest',
  },
  transformIgnorePatterns: [
    'node_modules/(?!(@react-native|react-native|react-native-.*)/)',
  ],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: ['src/**/*.js'],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  // Disable TypeScript-related globals since we're not using TypeScript
  globals: {},
  // Mock React Native modules that don't work in Jest
  setupFiles: [
    './node_modules/react-native/jest/setup.js',
  ],
};
