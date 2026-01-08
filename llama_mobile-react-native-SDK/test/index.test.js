import LlamaMobileReactNativeSdk from '../src/index';
import { NativeModules } from 'react-native';

describe('LlamaMobileReactNativeSdk', () => {
  beforeEach(() => {
    // Reset mocks and set up initial implementations
    jest.restoreAllMocks();
    
    // Ensure NativeModules.LlamaMobileReactNativeSdk exists with proper methods
    if (!NativeModules.LlamaMobileReactNativeSdk) {
      NativeModules.LlamaMobileReactNativeSdk = {};
    }
    
    NativeModules.LlamaMobileReactNativeSdk.VERSION = '1.0.0';
    NativeModules.LlamaMobileReactNativeSdk.initialize = jest.fn();
    NativeModules.LlamaMobileReactNativeSdk.loadModel = jest.fn().mockResolvedValue('Model loaded successfully');
    NativeModules.LlamaMobileReactNativeSdk.generateText = jest.fn().mockResolvedValue('Generated text');
    NativeModules.LlamaMobileReactNativeSdk.generateTextStream = jest.fn().mockRejectedValue(new Error('NOT_IMPLEMENTED'));
    NativeModules.LlamaMobileReactNativeSdk.stopGeneration = jest.fn();
    NativeModules.LlamaMobileReactNativeSdk.unloadModel = jest.fn();
  });

  test('should export the NativeModule from react-native', () => {
    expect(LlamaMobileReactNativeSdk).toBe(NativeModules.LlamaMobileReactNativeSdk);
  });

  test('should have all expected methods', () => {
    expect(typeof LlamaMobileReactNativeSdk.initialize).toBe('function');
    expect(typeof LlamaMobileReactNativeSdk.loadModel).toBe('function');
    expect(typeof LlamaMobileReactNativeSdk.generateText).toBe('function');
    expect(typeof LlamaMobileReactNativeSdk.generateTextStream).toBe('function');
    expect(typeof LlamaMobileReactNativeSdk.stopGeneration).toBe('function');
    expect(typeof LlamaMobileReactNativeSdk.unloadModel).toBe('function');
  });

  test('should have VERSION constant', () => {
    expect(LlamaMobileReactNativeSdk.VERSION).toBe('1.0.0');
  });

  test('initialize should call the native method', () => {
    LlamaMobileReactNativeSdk.initialize();
    expect(NativeModules.LlamaMobileReactNativeSdk.initialize).toHaveBeenCalledTimes(1);
  });

  test('loadModel should call the native method with correct parameters', async () => {
    const modelPath = '/path/to/model.gguf';
    const params = {
      n_threads: 4,
      n_batch: 512,
      n_gpu_layers: 0
    };
    await LlamaMobileReactNativeSdk.loadModel(modelPath, params);
    expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledTimes(1);
    expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledWith(modelPath, params);
  });

  test('generateText should call the native method with correct parameters', async () => {
    const prompt = 'Hello, world!';
    await LlamaMobileReactNativeSdk.generateText(prompt);
    expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledTimes(1);
    expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledWith(prompt);
  });

  test('generateTextStream should call the native method with correct parameters', async () => {
    const prompt = 'Hello, world!';
    try {
      await LlamaMobileReactNativeSdk.generateTextStream(prompt);
    } catch (error) {
      // Expected to fail since it's not implemented
    }
    expect(NativeModules.LlamaMobileReactNativeSdk.generateTextStream).toHaveBeenCalledTimes(1);
    expect(NativeModules.LlamaMobileReactNativeSdk.generateTextStream).toHaveBeenCalledWith(prompt);
  });

  test('stopGeneration should call the native method', () => {
    LlamaMobileReactNativeSdk.stopGeneration();
    expect(NativeModules.LlamaMobileReactNativeSdk.stopGeneration).toHaveBeenCalledTimes(1);
  });

  test('unloadModel should call the native method', () => {
    LlamaMobileReactNativeSdk.unloadModel();
    expect(NativeModules.LlamaMobileReactNativeSdk.unloadModel).toHaveBeenCalledTimes(1);
  });

  test('loadModel should handle errors from native module', async () => {
    const errorMessage = 'Failed to load model';
    NativeModules.LlamaMobileReactNativeSdk.loadModel = jest.fn().mockRejectedValue(new Error(errorMessage));
    
    const modelPath = '/path/to/invalid/model.gguf';
    const params = { n_threads: 4 };
    
    // Expect the function to throw an error
    await expect(LlamaMobileReactNativeSdk.loadModel(modelPath, params)).rejects.toThrow(errorMessage);
    
    expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledTimes(1);
  });

  test('generateText should handle errors from native module', async () => {
    const errorMessage = 'Failed to generate text';
    NativeModules.LlamaMobileReactNativeSdk.generateText = jest.fn().mockRejectedValue(new Error(errorMessage));
    
    const prompt = 'Hello, world!';
    
    // Expect the function to throw an error
    await expect(LlamaMobileReactNativeSdk.generateText(prompt)).rejects.toThrow(errorMessage);
    
    expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledTimes(1);
  });

  test('generateTextStream should reject with NOT_IMPLEMENTED error', async () => {
    const prompt = 'Hello, world!';
    
    // Expect the function to throw NOT_IMPLEMENTED error
    await expect(LlamaMobileReactNativeSdk.generateTextStream(prompt)).rejects.toThrow('NOT_IMPLEMENTED');
    
    expect(NativeModules.LlamaMobileReactNativeSdk.generateTextStream).toHaveBeenCalledTimes(1);
  });

  test('loadModel should work with minimal parameters', async () => {
    const modelPath = '/path/to/model.gguf';
    const params = {};
    await LlamaMobileReactNativeSdk.loadModel(modelPath, params);
    
    expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledTimes(1);
    expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledWith(modelPath, params);
  });

  test('generateText should work with empty prompt', async () => {
    const prompt = '';
    await LlamaMobileReactNativeSdk.generateText(prompt);
    
    expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledTimes(1);
    expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledWith(prompt);
  });
});
