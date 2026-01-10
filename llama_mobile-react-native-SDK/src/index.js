import { NativeModules, NativeEventEmitter } from 'react-native';

const { LlamaMobileReactNativeSdk } = NativeModules;
const eventEmitter = new NativeEventEmitter(LlamaMobileReactNativeSdk);

/**
 * Enum for TTS Model Type
 * @readonly
 * @enum {number}
 */
export const TTSModelType = {
  LLAMA_MOBILE_TTS_VITS: 0,
  LLAMA_MOBILE_TTS_MMS: 1,
};

/**
 * Enum for Stop Type
 * @readonly
 * @enum {number}
 */
export const StopType = {
  LLAMA_MOBILE_STOP_TYPE_NONE: 0,
  LLAMA_MOBILE_STOP_TYPE_EOS: 1,
  LLAMA_MOBILE_STOP_TYPE_WORD: 2,
  LLAMA_MOBILE_STOP_TYPE_LIMIT: 3,
};

/**
 * Llama Mobile SDK for React Native
 * Provides access to all the features of the llama_mobile_api.h
 */
class LlamaMobile {
  constructor() {
    this.context = null;
    this.isInitialized = false;
    this.eventListeners = [];
  }

  /**
   * Initialize the SDK
   */
  async initialize() {
    await LlamaMobileReactNativeSdk.initialize();
    this.isInitialized = true;
  }

  /**
   * Load a model with specified parameters
   * @param {string} modelPath - Path to the model file
   * @param {Object} params - Model loading parameters
   * @returns {Promise<string>} Success message
   */
  async loadModel(modelPath, params = {}) {
    return LlamaMobileReactNativeSdk.loadModel(modelPath, params);
  }

  /**
   * Generate text completion
   * @param {string} prompt - The input prompt
   * @param {Object} params - Completion parameters
   * @returns {Promise<Object>} Completion result
   */
  async generateText(prompt, params = {}) {
    return LlamaMobileReactNativeSdk.generateText(prompt, params);
  }

  /**
   * Stream text completion
   * @param {string} prompt - The input prompt
   * @param {Object} params - Completion parameters
   * @returns {Promise<string>} Success message
   */
  async streamText(prompt, params = {}) {
    return LlamaMobileReactNativeSdk.streamText(prompt, params);
  }

  /**
   * Stop ongoing text generation
   */
  stopGeneration() {
    LlamaMobileReactNativeSdk.stopGeneration();
  }

  /**
   * Unload the current model
   */
  unloadModel() {
    LlamaMobileReactNativeSdk.unloadModel();
  }

  /**
   * Tokenize text
   * @param {string} text - Text to tokenize
   * @returns {Promise<number[]>} Array of tokens
   */
  async tokenize(text) {
    return LlamaMobileReactNativeSdk.tokenize(text);
  }

  /**
   * Detokenize tokens
   * @param {number[]} tokens - Array of tokens
   * @returns {Promise<string>} Detokenized text
   */
  async detokenize(tokens) {
    return LlamaMobileReactNativeSdk.detokenize(tokens);
  }

  /**
   * Generate embeddings for text
   * @param {string} text - Text to generate embeddings for
   * @returns {Promise<number[]>} Array of embedding values
   */
  async generateEmbeddings(text) {
    return LlamaMobileReactNativeSdk.generateEmbeddings(text);
  }

  /**
   * Apply LoRA adapters
   * @param {Object[]} adapters - Array of LoRA adapter configurations
   * @returns {Promise<string>} Success message
   */
  async applyLoraAdapters(adapters) {
    return LlamaMobileReactNativeSdk.applyLoraAdapters(adapters);
  }

  /**
   * Remove LoRA adapters
   * @returns {Promise<string>} Success message
   */
  async removeLoraAdapters() {
    return LlamaMobileReactNativeSdk.removeLoraAdapters();
  }

  /**
   * Initialize multimodal
   * @param {string} mmprojPath - Path to multimodal project file
   * @param {boolean} useGpu - Whether to use GPU acceleration
   * @returns {Promise<string>} Success message
   */
  async initMultimodal(mmprojPath, useGpu) {
    return LlamaMobileReactNativeSdk.initMultimodal(mmprojPath, useGpu);
  }

  /**
   * Check if multimodal is enabled
   * @returns {Promise<boolean>} Whether multimodal is enabled
   */
  async isMultimodalEnabled() {
    return LlamaMobileReactNativeSdk.isMultimodalEnabled();
  }

  /**
   * Release multimodal resources
   * @returns {Promise<string>} Success message
   */
  async releaseMultimodal() {
    return LlamaMobileReactNativeSdk.releaseMultimodal();
  }

  /**
   * Generate a conversation response
   * @param {string} userMessage - User message
   * @param {number} maxTokens - Maximum number of tokens to generate
   * @returns {Promise<Object>} Conversation result
   */
  async generateConversationResponse(userMessage, maxTokens) {
    return LlamaMobileReactNativeSdk.generateConversationResponse(userMessage, maxTokens);
  }

  /**
   * Clear conversation history
   * @returns {Promise<string>} Success message
   */
  async clearConversation() {
    return LlamaMobileReactNativeSdk.clearConversation();
  }

  /**
   * Add a listener for token events during streaming
   * @param {Function} callback - Callback function that receives tokens
   * @returns {Function} Function to remove the listener
   */
  onToken(callback) {
    const listener = eventEmitter.addListener('onToken', ({ token }) => {
      callback(token);
    });
    this.eventListeners.push(listener);
    return () => {
      listener.remove();
      this.eventListeners = this.eventListeners.filter(l => l !== listener);
    };
  }

  /**
   * Add a listener for completion events
   * @param {Function} callback - Callback function that receives completion results
   * @returns {Function} Function to remove the listener
   */
  onCompletion(callback) {
    const listener = eventEmitter.addListener('onCompletion', result => {
      callback(result);
    });
    this.eventListeners.push(listener);
    return () => {
      listener.remove();
      this.eventListeners = this.eventListeners.filter(l => l !== listener);
    };
  }

  /**
   * Add a listener for error events
   * @param {Function} callback - Callback function that receives error messages
   * @returns {Function} Function to remove the listener
   */
  onError(callback) {
    const listener = eventEmitter.addListener('onError', ({ error }) => {
      callback(error);
    });
    this.eventListeners.push(listener);
    return () => {
      listener.remove();
      this.eventListeners = this.eventListeners.filter(l => l !== listener);
    };
  }

  /**
   * Remove all event listeners
   */
  removeAllListeners() {
    this.eventListeners.forEach(listener => listener.remove());
    this.eventListeners = [];
  }
}

// Create and export a singleton instance
const llamaMobile = new LlamaMobile();

export default llamaMobile;

// Export the LlamaMobile class for creating new instances
export { LlamaMobile };
