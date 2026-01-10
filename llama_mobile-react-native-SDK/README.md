# llama_mobile React Native SDK

A self-contained React Native SDK for running large language models on iOS and Android devices.

## Overview

The `llama_mobile-react-native-SDK` is a self-contained React Native module that provides access to the llama_mobile AI models on both iOS and Android platforms. This SDK is designed to be used without external dependencies, as it embeds all necessary native components directly.

### Key Features

- **Self-contained**: Embeds iOS xcframework and Android native libraries
- **Cross-platform**: Works on both iOS and Android devices
- **Stream support**: Generate text in real-time with streaming API
- **Memory management**: Automatic context handling and memory cleanup
- **Customizable**: Configure model parameters like threads, GPU layers, and context size

## Installation

### Prerequisites

- React Native 0.60 or higher
- Node.js 16 or higher
- npm 8 or higher

### Step 1: Add the SDK to your project

Copy the entire `llama_mobile-react-native-SDK` directory to your React Native project, then install it:

```bash
npm install ./llama_mobile-react-native-SDK
```

### Step 2: Configure iOS

1. Open your iOS project in Xcode
2. Make sure the SDK is linked (React Native 0.60+ should handle this automatically via CocoaPods)
3. Run `pod install` in the `ios` directory

### Step 3: Configure Android

No additional configuration is required for Android (React Native 0.60+ should handle linking automatically).

## Basic Usage

### Import the SDK

```javascript
import llamaMobile, { TTSModelType, StopType } from 'llama_mobile-react-native-SDK';
```

### Initialize the SDK

```javascript
// Initialize with default settings
await llamaMobile.initialize();
```

### Load a Model

```javascript
// Load a model from the device filesystem
const modelPath = '/path/to/your/model.gguf';

const params = {
  n_threads: 4,
  n_gpu_layers: 1,
  n_ctx: 2048,
  use_mmap: true,
  use_mlock: false
};

try {
  await llamaMobile.loadModel(modelPath, params);
  console.log('Model loaded successfully');
} catch (error) {
  console.error('Error loading model:', error);
}
```

### Generate Text

```javascript
const prompt = 'Once upon a time';
const generateParams = {
  temperature: 0.7,
  top_p: 0.9,
  min_p: 0.05,
  max_tokens: 100,
  penalty_repeat: 1.1,
  stopSequences: ['\n\n', 'User:']
};

try {
  const result = await llamaMobile.generateText(prompt, generateParams);
  console.log('Generated text:', result.text);
  console.log('Tokens generated:', result.tokensGenerated);
  console.log('Tokens evaluated:', result.tokensEvaluated);
} catch (error) {
  console.error('Error generating text:', error);
}
```

### Stream Text

```javascript
const prompt = 'Tell me a story';
const generateParams = {
  temperature: 0.7,
  max_tokens: 500,
  stopSequences: ['\n\n']
};

// Set up event listeners
const removeTokenListener = llamaMobile.onToken((token) => {
  console.log('Received token:', token);
});

const removeCompletionListener = llamaMobile.onCompletion((result) => {
  console.log('Completion finished:', result);
  removeTokenListener();
  removeCompletionListener();
  removeErrorListener();
});

const removeErrorListener = llamaMobile.onError((error) => {
  console.error('Stream error:', error);
  removeTokenListener();
  removeCompletionListener();
  removeErrorListener();
});

try {
  await llamaMobile.streamText(prompt, generateParams);
  console.log('Streaming started');
} catch (error) {
  console.error('Error starting stream:', error);
  removeTokenListener();
  removeCompletionListener();
  removeErrorListener();
}
```

### Tokenization

```javascript
// Tokenize text
const text = 'Hello, world!';
try {
  const tokens = await llamaMobile.tokenize(text);
  console.log('Tokens:', tokens);
} catch (error) {
  console.error('Error tokenizing text:', error);
}

// Detokenize tokens
const tokens = [1, 2, 3, 4, 5];
try {
  const text = await llamaMobile.detokenize(tokens);
  console.log('Detokenized text:', text);
} catch (error) {
  console.error('Error detokenizing tokens:', error);
}
```

### Generate Embeddings

```javascript
const text = 'Hello, world!';
try {
  const embeddings = await llamaMobile.generateEmbeddings(text);
  console.log('Embeddings:', embeddings);
  console.log('Embedding length:', embeddings.length);
} catch (error) {
  console.error('Error generating embeddings:', error);
}
```

### LoRA Adapters

```javascript
// Apply LoRA adapters
const adapters = [
  { path: '/path/to/lora1.gguf', scale: 0.5 },
  { path: '/path/to/lora2.gguf', scale: 0.8 }
];

try {
  await llamaMobile.applyLoraAdapters(adapters);
  console.log('LoRA adapters applied successfully');
} catch (error) {
  console.error('Error applying LoRA adapters:', error);
}

// Remove all LoRA adapters
try {
  await llamaMobile.removeLoraAdapters();
  console.log('LoRA adapters removed successfully');
} catch (error) {
  console.error('Error removing LoRA adapters:', error);
}
```

### Multimodal

```javascript
// Initialize multimodal
const mmprojPath = '/path/to/mmproj.gguf';
try {
  await llamaMobile.initMultimodal(mmprojPath, true); // Use GPU
  console.log('Multimodal initialized successfully');
} catch (error) {
  console.error('Error initializing multimodal:', error);
}

// Check if multimodal is enabled
try {
  const isEnabled = await llamaMobile.isMultimodalEnabled();
  console.log('Multimodal enabled:', isEnabled);
} catch (error) {
  console.error('Error checking multimodal status:', error);
}

// Release multimodal resources
try {
  await llamaMobile.releaseMultimodal();
  console.log('Multimodal resources released');
} catch (error) {
  console.error('Error releasing multimodal resources:', error);
}
```

### Conversation Management

```javascript
// Generate a conversation response
const userMessage = 'Hello, how are you?';
try {
  const result = await llamaMobile.generateConversationResponse(userMessage, 100);
  console.log('Assistant response:', result.text);
  console.log('Time to first token:', result.timeToFirstToken);
} catch (error) {
  console.error('Error generating conversation response:', error);
}

// Clear conversation history
try {
  await llamaMobile.clearConversation();
  console.log('Conversation history cleared');
} catch (error) {
  console.error('Error clearing conversation:', error);
}
```

### Stop Generation

```javascript
// Stop any ongoing generation
llamaMobile.stopGeneration();
```

### Unload Model

```javascript
try {
  await llamaMobile.unloadModel();
  console.log('Model unloaded successfully');
} catch (error) {
  console.error('Error unloading model:', error);
}
```

### Remove Event Listeners

```javascript
// Remove all event listeners at once
llamaMobile.removeAllListeners();
```

## API Reference

### Enums

#### `TTSModelType`

Enum for specifying TTS (Text-to-Speech) model types.

```javascript
enum TTSModelType {
  LLAMA_MOBILE_TTS_VITS = 0,
  LLAMA_MOBILE_TTS_MMS = 1
}
```

#### `StopType`

Enum for specifying why generation stopped.

```javascript
enum StopType {
  LLAMA_MOBILE_STOP_TYPE_NONE = 0,
  LLAMA_MOBILE_STOP_TYPE_EOS = 1,
  LLAMA_MOBILE_STOP_TYPE_WORD = 2,
  LLAMA_MOBILE_STOP_TYPE_LIMIT = 3
}
```

### Methods

#### `initialize()`

Initializes the llama_mobile SDK.

- Returns: `Promise<void>`

#### `loadModel(modelPath, params)`

Loads a model from the specified path with the given parameters.

- **Parameters:**
  - `modelPath`: `string` - Path to the model file (GGUF format)
  - `params`: `object` - Model loading parameters
    - `n_threads`: `number` (optional) - Number of CPU threads to use (default: 4)
    - `n_gpu_layers`: `number` (optional) - Number of layers to offload to GPU (default: 0)
    - `n_ctx`: `number` (optional) - Context window size (default: 2048)
    - `n_batch`: `number` (optional) - Batch size (default: 512)
    - `use_mmap`: `boolean` (optional) - Use memory-mapped I/O (default: true)
    - `use_mlock`: `boolean` (optional) - Lock model in memory (default: false)
    - `embedding`: `boolean` (optional) - Enable embedding extraction (default: false)

- Returns: `Promise<void>`

#### `generateText(prompt, params)`

Generates text from the loaded model.

- **Parameters:**
  - `prompt`: `string` - Input prompt for text generation
  - `params`: `object` - Generation parameters
    - `temperature`: `number` (optional) - Sampling temperature (default: 0.7)
    - `top_k`: `number` (optional) - Top-k sampling parameter (default: 40)
    - `top_p`: `number` (optional) - Top-p sampling parameter (default: 0.9)
    - `min_p`: `number` (optional) - Min-p sampling parameter (default: 0.05)
    - `max_tokens`: `number` (optional) - Maximum number of tokens to generate (default: 100)
    - `penalty_repeat`: `number` (optional) - Repeat penalty (default: 1.1)
    - `stopSequences`: `string[]` (optional) - Array of stop sequences (default: [])
    - `grammar`: `string` (optional) - Context-free grammar for constrained generation

- Returns: `Promise<object>` - Generated text result
  - `text`: `string` - Generated text
  - `tokensGenerated`: `number` - Number of tokens generated
  - `tokensEvaluated`: `number` - Number of tokens evaluated
  - `truncated`: `boolean` - Whether the generation was truncated
  - `stoppedEos`: `boolean` - Whether generation stopped at EOS token
  - `stoppedWord`: `boolean` - Whether generation stopped at a stop word
  - `stoppedLimit`: `boolean` - Whether generation stopped at max tokens

#### `streamText(prompt, params)`

Streams text generation from the loaded model using event emitters.

- **Parameters:**
  - `prompt`: `string` - Input prompt for text generation
  - `params`: `object` - Generation parameters (same as `generateText`)

- Returns: `Promise<void>`

- **Events:**
  - `onToken(token)`: Emitted for each generated token
  - `onCompletion(result)`: Emitted when generation completes
  - `onError(error)`: Emitted if an error occurs during generation

#### `stopGeneration()`

Stops any ongoing text generation.

- Returns: `void`

#### `unloadModel()`

Unloads the currently loaded model and frees resources.

- Returns: `Promise<void>`

#### `tokenize(text)`

Tokenizes the given text into model tokens.

- **Parameters:**
  - `text`: `string` - Text to tokenize

- Returns: `Promise<number[]>` - Array of token IDs

#### `detokenize(tokens)`

Detokenizes the given token IDs back into text.

- **Parameters:**
  - `tokens`: `number[]` - Array of token IDs to detokenize

- Returns: `Promise<string>` - Detokenized text

#### `generateEmbeddings(text)`

Generates embeddings for the given text.

- **Parameters:**
  - `text`: `string` - Text to generate embeddings for

- Returns: `Promise<number[]>` - Array of embedding values

#### `applyLoraAdapters(adapters)`

Applies LoRA adapters to the loaded model.

- **Parameters:**
  - `adapters`: `object[]` - Array of LoRA adapter configurations
    - `path`: `string` - Path to the LoRA adapter file
    - `scale`: `number` - LoRA adapter scale (default: 1.0)

- Returns: `Promise<string>` - Success message

#### `removeLoraAdapters()`

Removes all applied LoRA adapters from the model.

- Returns: `Promise<string>` - Success message

#### `initMultimodal(mmprojPath, useGpu)`

Initializes multimodal functionality for the loaded model.

- **Parameters:**
  - `mmprojPath`: `string` - Path to the multimodal projection file
  - `useGpu`: `boolean` - Whether to use GPU acceleration

- Returns: `Promise<string>` - Success message

#### `isMultimodalEnabled()`

Checks if multimodal functionality is enabled.

- Returns: `Promise<boolean>` - Whether multimodal is enabled

#### `releaseMultimodal()`

Releases multimodal resources.

- Returns: `Promise<string>` - Success message

#### `generateConversationResponse(userMessage, maxTokens)`

Generates a response to a user message in a conversation context.

- **Parameters:**
  - `userMessage`: `string` - User's message
  - `maxTokens`: `number` - Maximum number of tokens to generate

- Returns: `Promise<object>` - Conversation result
  - `text`: `string` - Generated response
  - `timeToFirstToken`: `number` - Time to generate first token (ms)
  - `totalTime`: `number` - Total generation time (ms)
  - `tokensGenerated`: `number` - Number of tokens generated

#### `clearConversation()`

Clears the conversation history.

- Returns: `Promise<string>` - Success message

### Event Listeners

#### `onToken(callback)`

Registers a callback for token events during streaming.

- **Parameters:**
  - `callback`: `function(token)` - Callback function that receives each token

- Returns: `function` - Function to remove the listener

#### `onCompletion(callback)`

Registers a callback for completion events.

- **Parameters:**
  - `callback`: `function(result)` - Callback function that receives the completion result

- Returns: `function` - Function to remove the listener

#### `onError(callback)`

Registers a callback for error events.

- **Parameters:**
  - `callback`: `function(error)` - Callback function that receives the error

- Returns: `function` - Function to remove the listener

#### `removeAllListeners()`

Removes all registered event listeners.

- Returns: `void`

## Testing

### Running Tests

```bash
cd llama_mobile-react-native-SDK
npm install
npm run test
```

### Test Coverage

The SDK includes comprehensive Jest tests for all API methods:

- Initialization
- Model loading/unloading
- Text generation
- Stream generation
- Error handling

## Build Instructions

### Building the Self-contained SDK

The SDK comes with a build script that ensures all native components are properly embedded:

```bash
cd llama_mobile-react-native-SDK
./build-react-native-sdk.sh
```

### Updating Native SDK Components

To update the embedded iOS and Android SDK components:

```bash
./build-react-native-sdk.sh --update-sdks
```

This will build fresh copies of the intermediate SDKs (if available) and embed them in the React Native SDK.

## Platform-Specific Notes

### iOS

- Requires iOS 14 or higher
- Uses Metal for GPU acceleration
- Embeds `llama_mobile.xcframework` in the SDK

### Android

- Requires Android 7.0 (API level 24) or higher
- Uses Vulkan for GPU acceleration (if available)
- Embeds JNI libraries and Java classes

## Troubleshooting

### Common Issues

1. **Model not found**: Ensure the path to the model file is correct and accessible
2. **Out of memory**: Reduce `n_ctx` size or `n_gpu_layers` parameter
3. **iOS build errors**: Run `pod install` again and check Xcode project settings
4. **Android linking issues**: Ensure the SDK is properly linked in `settings.gradle`

### Performance Tips

- Increase `n_threads` for faster CPU generation
- Use `n_gpu_layers` to offload work to GPU (iOS only)
- Reduce `n_ctx` to save memory
- Adjust `n_batch` based on your device's memory

## License

This SDK is licensed under the MIT License.

## Support

For issues and questions, please refer to the project's GitHub repository.
