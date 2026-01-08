# Llama Mobile React Native SDK Tests

This directory contains the test suite for the Llama Mobile React Native SDK.

## Test Structure

```
test/
├── __mocks__/              # Mock implementations for testing
│   └── react-native.js     # Mock for React Native NativeModules
├── index.test.js           # Main test file for the SDK
└── README.md               # This file
```

## Test Types

### Unit Tests
- **Location**: `index.test.js`
- **Purpose**: Test the JavaScript bridge layer that interacts with the native modules
- **Mocking**: Uses mock NativeModules to isolate tests from actual native code

## Test Coverage

The test suite covers:

- ✅ SDK initialization
- ✅ Model loading with parameters
- ✅ Text generation
- ✅ Text generation streaming (error case)
- ✅ Generation stopping
- ✅ Model unloading
- ✅ Error handling
- ✅ Edge cases
- ✅ Parameter validation

## Running Tests

### Prerequisites

- Node.js installed
- Project dependencies installed (`npm install`)

### Test Commands

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage
```

## Mock Implementation

The test suite uses a mock implementation of the native module (`test/__mocks__/react-native.js`) to simulate native behavior without requiring actual native code execution.

## Test Files

### `index.test.js`

Contains tests for all public API methods:

- `initialize()`
- `loadModel(modelPath, params)`
- `generateText(prompt)`
- `generateTextStream(prompt)`
- `stopGeneration()`
- `unloadModel()`

### `__mocks__/react-native.js`

Provides mock implementations for the native module methods, including:

- Mock success responses for implemented methods
- Mock error responses for unimplemented methods
- Mock constant values (VERSION)

## Adding New Tests

When adding new tests:

1. Follow the existing test patterns
2. Use mock implementations for native module interactions
3. Test both success and error cases
4. Include edge cases when appropriate
5. Run the test suite to ensure no regressions

## Test Configuration

Test configuration is defined in:
- `jest.config.js` - Jest configuration
- `package.json` - Test scripts and dependencies
