# llama-mobile-capacitor-plugin

Capacitor plugin for llama_mobile SDK, providing native AI model inference capabilities for iOS and Android platforms.

## Overview

This plugin allows you to run AI models locally on mobile devices using Capacitor, with asynchronous APIs by default for a smooth user experience.

## Getting Started

### Installation

#### From npm

```bash
# Install the plugin
npm install llama-mobile-capacitor-plugin

# Sync with your Capacitor project
npx cap sync
```

#### From Local Directory

```bash
# Navigate to your Capacitor project
cd your-capacitor-project

# Install from local path
npm install /path/to/llama_mobile-capacitor-plugin

# Sync the plugin
npx cap sync
```

### Platform Requirements

- **iOS**: iOS 15.0+, Xcode 15.0+, Swift 5.1+
- **Android**: Android 7.0+, Android Studio, Android SDK with NDK

## Building the Plugin

### Prerequisites
- Node.js and npm
- Capacitor CLI (`npm install -g @capacitor/cli`)
- iOS: Xcode with Command Line Tools
- Android: Android Studio with SDK and NDK

### Build Steps

```bash
# Clone the repository
git clone https://github.com/llama-mobile/llama_mobile-capacitor-plugin.git
cd llama_mobile-capacitor-plugin

# Install dependencies
npm install

# Build the plugin
npm run build

# Verify the build
npm run verify
```

### Build with Native Dependencies

```bash
# Build with bundled iOS and Android dependencies
./scripts/build-capacitor-plugin.sh

# Build with custom options
./scripts/build-capacitor-plugin.sh --build-type=Release --verbose
```

## Usage Examples

### Text Generation

```typescript
import { LlamaMobileCapacitorPlugin } from 'llama-mobile-capacitor-plugin';

// Initialize the model
const { contextHandle } = await LlamaMobileCapacitorPlugin.initContext({
  modelPath: '/path/to/model.gguf',
  nCtx: 2048,
  nGpuLayers: 4,
  nThreads: 4
});

// Generate text
const result = await LlamaMobileCapacitorPlugin.generateCompletion({
  contextHandle,
  params: {
    prompt: 'Tell me a short story about AI',
    maxTokens: 200,
    temperature: 0.7
  }
});

console.log('Generated text:', result.text);

// Release resources
await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
```

### Chat Conversation

```typescript
// Initialize with a chat model
const { contextHandle } = await LlamaMobileCapacitorPlugin.initContext({
  modelPath: '/path/to/chat-model.gguf',
  nCtx: 4096
});

// Generate chat response
const response = await LlamaMobileCapacitorPlugin.generateResponse({
  contextHandle,
  userMessage: 'What is the capital of France?',
  maxTokens: 100
});

console.log('AI Response:', response.text);

// Release resources
await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
```

### Text-to-Speech

```typescript
// Initialize TTS vocoder
await LlamaMobileCapacitorPlugin.initVocoder({
  contextHandle,
  vocoderModelPath: '/path/to/vocoder-model.bin'
});

// Generate speech
const speechResult = await LlamaMobileCapacitorPlugin.generateSpeechAsync({
  contextHandle,
  text: 'Hello, this is a test of the text-to-speech functionality.'
});

// Play the audio
await LlamaMobileCapacitorPlugin.playAudioFromFile({
  filePath: speechResult.audioPath
});
```

### Model Download

```typescript
// Listen to download progress
const progressListener = await LlamaMobileCapacitorPlugin.addListener(
  'progress',
  (data) => {
    console.log('Download progress:', (data.progress * 100).toFixed(0) + '%');
  }
);

// Download from Hugging Face
const downloadResult = await LlamaMobileCapacitorPlugin.downloadHfFile({
  repoId: 'meta-llama/Llama-3.2-1B-Instruct',
  filename: 'Llama-3.2-1B-Instruct.Q4_K_M.gguf',
  localPath: '/path/to/save/model.gguf'
});

// Remove listener
await progressListener.remove();

if (downloadResult.success) {
  console.log('Model downloaded to:', downloadResult.localPath);
} else {
  console.error('Download failed:', downloadResult.errorMessage);
}
```

## Major API Reference

### Initialization
- `initContext`: Initialize a model context
- `releaseContext`: Release a model context

### Text Generation
- `generateCompletion`: Generate text from a prompt
- `generateResponse`: Generate chat response (maintains context)
- `stopCompletion`: Stop ongoing text generation

### TTS
- `initVocoder`: Initialize TTS vocoder
- `generateSpeechAsync`: Generate speech asynchronously
- `playAudioFromFile`: Play generated audio

### Embeddings
- `generateEmbeddings`: Generate text embeddings

### Model Management
- `downloadHfFile`: Download model from Hugging Face
- `listModels`: List available models

## Troubleshooting

### Common Issues

1. **Model not found**
   - Check the model path is correct
   - Verify the file exists at the specified location
   - Use `listModels` to see available models

2. **Out of memory**
   - Use a smaller model
   - Reduce `nCtx` (context size)
   - Decrease `nGpuLayers` if using too much GPU memory

3. **Slow performance**
   - Increase `nGpuLayers` (if device supports)
   - Adjust `nThreads` based on device CPU
   - Use quantized models (Q4_K_M, Q5_K_M)

4. **Plugin not syncing**
   - Run `npx cap sync`
   - Check for Capacitor CLI updates
   - Verify platform requirements

5. **TTS issues**
   - Ensure vocoder model is properly initialized
   - Check audio permissions on the device
   - Verify TTS model compatibility

### Debugging

```bash
# Run with verbose logging
npx cap run ios --verbose
npx cap run android --verbose

# Check device logs
npx cap log ios
npx cap log android
```

## Platform Notes

- **iOS**: Metal GPU acceleration enabled automatically when `nGpuLayers > 0`
- **Android**: Vulkan support for GPU acceleration on compatible devices
- **Async by default**: All Capacitor APIs return promises for smooth integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.