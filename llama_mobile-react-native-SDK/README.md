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
import LlamaMobile from 'llama_mobile-react-native-SDK';
```

### Initialize the SDK

```javascript
// Initialize with default settings
await LlamaMobile.initialize();
```

### Load a Model

```javascript
// Load a model from the device filesystem
const modelPath = '/path/to/your/model.gguf';

const params = {
  n_threads: 4,
  n_gpu_layers: 1,
  n_ctx: 2048
};

try {
  await LlamaMobile.loadModel(modelPath, params);
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
  max_tokens: 100
};

try {
  const result = await LlamaMobile.generateText(prompt, generateParams);
  console.log('Generated text:', result.text);
} catch (error) {
  console.error('Error generating text:', error);
}
```

### Generate Text Stream

```javascript
const prompt = 'Tell me a story';
const generateParams = {
  temperature: 0.7,
  max_tokens: 500
};

try {
  await LlamaMobile.generateTextStream(
    prompt, 
    generateParams,
    (token) => {
      // Handle each generated token
      console.log('Token:', token);
    },
    (error) => {
      // Handle any errors
      console.error('Stream error:', error);
    },
    () => {
      // Stream completed
      console.log('Stream completed');
    }
  );
} catch (error) {
  console.error('Error starting stream:', error);
}
```

### Unload Model

```javascript
try {
  await LlamaMobile.unloadModel();
  console.log('Model unloaded successfully');
} catch (error) {
  console.error('Error unloading model:', error);
}
```

## API Reference

### Constants

#### `VERSION`

The current version of the SDK.

```javascript
console.log('SDK Version:', LlamaMobile.VERSION);
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

- Returns: `Promise<void>`

#### `generateText(prompt, params)`

Generates text from the loaded model.

- **Parameters:**
  - `prompt`: `string` - Input prompt for text generation
  - `params`: `object` - Generation parameters
    - `temperature`: `number` (optional) - Sampling temperature (default: 0.8)
    - `top_p`: `number` (optional) - Top-p sampling parameter (default: 0.95)
    - `max_tokens`: `number` (optional) - Maximum number of tokens to generate (default: 100)

- Returns: `Promise<object>` - Generated text result
  - `text`: `string` - Generated text

#### `generateTextStream(prompt, params, onToken, onError, onComplete)`

Generates text in real-time stream from the loaded model.

- **Parameters:**
  - `prompt`: `string` - Input prompt for text generation
  - `params`: `object` - Generation parameters (same as `generateText`)
  - `onToken`: `function` - Callback for each generated token
  - `onError`: `function` - Callback for errors
  - `onComplete`: `function` - Callback when generation is complete

- Returns: `Promise<void>`

#### `stopGeneration()`

Stops any ongoing text generation.

- Returns: `Promise<void>`

#### `unloadModel()`

Unloads the currently loaded model and frees resources.

- Returns: `Promise<void>`

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
