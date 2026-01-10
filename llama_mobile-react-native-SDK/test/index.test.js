import llamaMobile, { TTSModelType, StopType, LlamaMobile } from '../src/index';
import { NativeModules, NativeEventEmitter } from 'react-native';

// Mock React Native modules
jest.mock('react-native', () => ({
  NativeModules: {
    LlamaMobileReactNativeSdk: {
      VERSION: '1.0.0',
      initialize: jest.fn(),
      loadModel: jest.fn().mockResolvedValue('Model loaded successfully'),
      generateText: jest.fn().mockResolvedValue({ text: 'Generated text', tokensGenerated: 5 }),
      streamText: jest.fn().mockResolvedValue('Streaming started'),
      stopGeneration: jest.fn(),
      unloadModel: jest.fn(),
      tokenize: jest.fn().mockResolvedValue([1, 2, 3, 4, 5]),
      detokenize: jest.fn().mockResolvedValue('Detokenized text'),
      generateEmbeddings: jest.fn().mockResolvedValue([0.1, 0.2, 0.3]),
      applyLoraAdapters: jest.fn().mockResolvedValue('LoRA adapters applied successfully'),
      removeLoraAdapters: jest.fn().mockResolvedValue('LoRA adapters removed successfully'),
      initMultimodal: jest.fn().mockResolvedValue('Multimodal initialized successfully'),
      isMultimodalEnabled: jest.fn().mockResolvedValue(false),
      releaseMultimodal: jest.fn().mockResolvedValue('Multimodal resources released'),
      generateConversationResponse: jest.fn().mockResolvedValue({ text: 'Conversation response', tokensGenerated: 8 }),
      clearConversation: jest.fn().mockResolvedValue('Conversation cleared successfully'),
    },
  },
  NativeEventEmitter: jest.fn().mockImplementation(() => ({
    addListener: jest.fn().mockReturnValue({ remove: jest.fn() }),
  })),
}));

describe('LlamaMobile SDK', () => {
  beforeEach(() => {
    // Reset mocks
    jest.restoreAllMocks();
  });

  test('should export a singleton instance', () => {
    expect(llamaMobile).toBeInstanceOf(LlamaMobile);
  });

  test('should export enum constants', () => {
    expect(TTSModelType).toBeDefined();
    expect(StopType).toBeDefined();
    expect(TTSModelType.LLAMA_MOBILE_TTS_VITS).toBe(0);
    expect(TTSModelType.LLAMA_MOBILE_TTS_MMS).toBe(1);
    expect(StopType.LLAMA_MOBILE_STOP_TYPE_NONE).toBe(0);
    expect(StopType.LLAMA_MOBILE_STOP_TYPE_EOS).toBe(1);
    expect(StopType.LLAMA_MOBILE_STOP_TYPE_WORD).toBe(2);
    expect(StopType.LLAMA_MOBILE_STOP_TYPE_LIMIT).toBe(3);
  });

  test('should export the LlamaMobile class', () => {
    expect(LlamaMobile).toBeDefined();
    expect(typeof LlamaMobile).toBe('function');
  });

  describe('initialization', () => {
    test('should initialize the SDK', async () => {
      await llamaMobile.initialize();
      expect(NativeModules.LlamaMobileReactNativeSdk.initialize).toHaveBeenCalledTimes(1);
    });
  });

  describe('model operations', () => {
    test('should load a model with parameters', async () => {
      const modelPath = '/path/to/model.gguf';
      const params = {
        n_threads: 4,
        n_batch: 512,
        n_gpu_layers: 0,
        n_ctx: 2048,
        use_mmap: true,
        use_mlock: false,
      };
      
      await llamaMobile.loadModel(modelPath, params);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.loadModel).toHaveBeenCalledWith(modelPath, params);
    });

    test('should unload a model', async () => {
      await llamaMobile.unloadModel();
      expect(NativeModules.LlamaMobileReactNativeSdk.unloadModel).toHaveBeenCalledTimes(1);
    });
  });

  describe('text generation', () => {
    test('should generate text with parameters', async () => {
      const prompt = 'Hello, world!';
      const params = {
        max_tokens: 100,
        temperature: 0.7,
        top_k: 40,
        top_p: 0.9,
        min_p: 0.05,
        penalty_repeat: 1.1,
      };
      
      const result = await llamaMobile.generateText(prompt, params);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.generateText).toHaveBeenCalledWith(prompt, params);
      expect(result).toEqual({ text: 'Generated text', tokensGenerated: 5 });
    });

    test('should stream text with parameters', async () => {
      const prompt = 'Hello, world!';
      const params = {
        max_tokens: 100,
        temperature: 0.7,
      };
      
      const result = await llamaMobile.streamText(prompt, params);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.streamText).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.streamText).toHaveBeenCalledWith(prompt, params);
      expect(result).toBe('Streaming started');
    });

    test('should stop generation', () => {
      llamaMobile.stopGeneration();
      expect(NativeModules.LlamaMobileReactNativeSdk.stopGeneration).toHaveBeenCalledTimes(1);
    });
  });

  describe('tokenization', () => {
    test('should tokenize text', async () => {
      const text = 'Hello, world!';
      const tokens = await llamaMobile.tokenize(text);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.tokenize).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.tokenize).toHaveBeenCalledWith(text);
      expect(tokens).toEqual([1, 2, 3, 4, 5]);
    });

    test('should detokenize tokens', async () => {
      const tokens = [1, 2, 3, 4, 5];
      const text = await llamaMobile.detokenize(tokens);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.detokenize).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.detokenize).toHaveBeenCalledWith(tokens);
      expect(text).toBe('Detokenized text');
    });
  });

  describe('embeddings', () => {
    test('should generate embeddings', async () => {
      const text = 'Hello, world!';
      const embeddings = await llamaMobile.generateEmbeddings(text);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.generateEmbeddings).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.generateEmbeddings).toHaveBeenCalledWith(text);
      expect(embeddings).toEqual([0.1, 0.2, 0.3]);
    });
  });

  describe('LoRA adapters', () => {
    test('should apply LoRA adapters', async () => {
      const adapters = [
        { path: '/path/to/lora1', scale: 0.5 },
        { path: '/path/to/lora2', scale: 0.8 },
      ];
      
      const result = await llamaMobile.applyLoraAdapters(adapters);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.applyLoraAdapters).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.applyLoraAdapters).toHaveBeenCalledWith(adapters);
      expect(result).toBe('LoRA adapters applied successfully');
    });

    test('should remove LoRA adapters', async () => {
      const result = await llamaMobile.removeLoraAdapters();
      
      expect(NativeModules.LlamaMobileReactNativeSdk.removeLoraAdapters).toHaveBeenCalledTimes(1);
      expect(result).toBe('LoRA adapters removed successfully');
    });
  });

  describe('multimodal', () => {
    test('should initialize multimodal', async () => {
      const mmprojPath = '/path/to/mmproj';
      const useGpu = true;
      
      const result = await llamaMobile.initMultimodal(mmprojPath, useGpu);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.initMultimodal).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.initMultimodal).toHaveBeenCalledWith(mmprojPath, useGpu);
      expect(result).toBe('Multimodal initialized successfully');
    });

    test('should check if multimodal is enabled', async () => {
      const isEnabled = await llamaMobile.isMultimodalEnabled();
      
      expect(NativeModules.LlamaMobileReactNativeSdk.isMultimodalEnabled).toHaveBeenCalledTimes(1);
      expect(isEnabled).toBe(false);
    });

    test('should release multimodal resources', async () => {
      const result = await llamaMobile.releaseMultimodal();
      
      expect(NativeModules.LlamaMobileReactNativeSdk.releaseMultimodal).toHaveBeenCalledTimes(1);
      expect(result).toBe('Multimodal resources released');
    });
  });

  describe('conversation', () => {
    test('should generate conversation response', async () => {
      const userMessage = 'Hello!';
      const maxTokens = 50;
      
      const result = await llamaMobile.generateConversationResponse(userMessage, maxTokens);
      
      expect(NativeModules.LlamaMobileReactNativeSdk.generateConversationResponse).toHaveBeenCalledTimes(1);
      expect(NativeModules.LlamaMobileReactNativeSdk.generateConversationResponse).toHaveBeenCalledWith(userMessage, maxTokens);
      expect(result).toEqual({ text: 'Conversation response', tokensGenerated: 8 });
    });

    test('should clear conversation', async () => {
      const result = await llamaMobile.clearConversation();
      
      expect(NativeModules.LlamaMobileReactNativeSdk.clearConversation).toHaveBeenCalledTimes(1);
      expect(result).toBe('Conversation cleared successfully');
    });
  });

  describe('error handling', () => {
    test('should handle loadModel errors', async () => {
      const errorMessage = 'Failed to load model';
      NativeModules.LlamaMobileReactNativeSdk.loadModel = jest.fn().mockRejectedValue(new Error(errorMessage));
      
      await expect(llamaMobile.loadModel('/path/to/model.gguf', {})).rejects.toThrow(errorMessage);
    });

    test('should handle generateText errors', async () => {
      const errorMessage = 'Failed to generate text';
      NativeModules.LlamaMobileReactNativeSdk.generateText = jest.fn().mockRejectedValue(new Error(errorMessage));
      
      await expect(llamaMobile.generateText('prompt', {})).rejects.toThrow(errorMessage);
    });
  });

  describe('event listeners', () => {
    test('should add token listener', () => {
      const listenerCallback = jest.fn();
      const removeListener = llamaMobile.onToken(listenerCallback);
      
      expect(NativeEventEmitter).toHaveBeenCalled();
      expect(NativeEventEmitter).toHaveBeenCalledWith(NativeModules.LlamaMobileReactNativeSdk);
      expect(NativeEventEmitter.mock.results[0].value.addListener).toHaveBeenCalledWith('onToken', expect.any(Function));
      expect(typeof removeListener).toBe('function');
    });

    test('should add completion listener', () => {
      const listenerCallback = jest.fn();
      const removeListener = llamaMobile.onCompletion(listenerCallback);
      
      expect(NativeEventEmitter.mock.results[0].value.addListener).toHaveBeenCalledWith('onCompletion', expect.any(Function));
      expect(typeof removeListener).toBe('function');
    });

    test('should add error listener', () => {
      const listenerCallback = jest.fn();
      const removeListener = llamaMobile.onError(listenerCallback);
      
      expect(NativeEventEmitter.mock.results[0].value.addListener).toHaveBeenCalledWith('onError', expect.any(Function));
      expect(typeof removeListener).toBe('function');
    });

    test('should remove all listeners', () => {
      // Create a mock remove function
      const mockRemove = jest.fn();
      
      // Create a new instance
      const newInstance = new LlamaMobile();
      
      // Mock the event emitter's addListener method to return our mock remove function
      const mockAddListener = NativeEventEmitter.mock.results[0].value.addListener;
      mockAddListener.mockReturnValue({ remove: mockRemove });
      
      // Add some listeners
      newInstance.onToken(() => {});
      newInstance.onCompletion(() => {});
      newInstance.onError(() => {});
      
      // Remove all listeners
      newInstance.removeAllListeners();
      
      // Verify remove was called for each listener
      expect(mockRemove).toHaveBeenCalledTimes(3);
    });
  });
});
