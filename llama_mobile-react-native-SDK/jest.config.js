module.exports = {
  preset: 'react-native',
  setupFilesAfterEnv: [],
  moduleNameMapper: {
    '^react-native$': require.resolve('react-native'),
  },
  transform: {
    '^.+\\.(js|jsx)$': 'babel-jest',
  },
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: ['src/**/*.js'],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov'],
  globals: {
    'ts-jest': {
      babelConfig: true,
    },
  },
};
