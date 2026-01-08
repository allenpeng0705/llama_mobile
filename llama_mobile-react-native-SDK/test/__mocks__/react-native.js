const NativeModules = {
  LlamaMobileReactNativeSdk: {
    VERSION: '1.0.0',
    initialize: jest.fn(),
    loadModel: jest.fn(() => Promise.resolve('Model loaded successfully')),
    generateText: jest.fn(() => Promise.resolve('Mock text generation result')),
    generateTextStream: jest.fn(() => Promise.reject(new Error('NOT_IMPLEMENTED'))),
    stopGeneration: jest.fn(),
    unloadModel: jest.fn(),
  },
};

module.exports = { NativeModules };
