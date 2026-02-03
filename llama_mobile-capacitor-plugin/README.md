# llama-mobile-capacitor-plugin

Capacitor plugin for llama_mobile SDK, providing native AI model inference capabilities for iOS and Android platforms.

## Features

- **Model Inference**: Run AI models locally on iOS and Android devices
- **Text Generation**: Generate text completions from prompts
- **Embeddings**: Generate text embeddings for similarity search
- **Tokenization**: Convert text to tokens and vice versa
- **TTS (Text-to-Speech)**: Generate audio from text
- **Multimodal Support**: Process images and audio (if supported by the model)
- **LoRA Adapters**: Apply LoRA adapters for model fine-tuning
- **Conversation Support**: Maintain chat contexts for natural conversations

## Install

```bash
# Install the plugin
npm install llama-mobile-capacitor-plugin

# Sync the plugin with your Capacitor project
npx cap sync
```

## Platform Requirements

### iOS
- iOS 15.0+
- Xcode 15.0+
- Swift 5.1+

### Android
- Android 7.0+
- Android Studio
- Android SDK with NDK

## Usage

### Basic Example

```typescript
import { LlamaMobileCapacitorPlugin } from 'llama-mobile-capacitor-plugin';

// Initialize the model
const { contextHandle } = await LlamaMobileCapacitorPlugin.initContext({
  modelPath: '/path/to/model.gguf',
  nCtx: 2048,
  nGpuLayers: 4,
  nThreads: 4
});

// Generate text completion
const result = await LlamaMobileCapacitorPlugin.generateCompletion({
  contextHandle,
  params: {
    prompt: 'Tell me a short story about AI',
    maxTokens: 200,
    temperature: 0.7
  }
});

console.log('Generated text:', result.text);

// Release the context when done
await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
```

### Advanced Example with Conversation

```typescript
import { LlamaMobileCapacitorPlugin } from 'llama-mobile-capacitor-plugin';

// Initialize the model
const { contextHandle } = await LlamaMobileCapacitorPlugin.initContext({
  modelPath: '/path/to/chat-model.gguf',
  nCtx: 4096,
  nGpuLayers: 4,
  nThreads: 4
});

// Generate response to user message
const response = await LlamaMobileCapacitorPlugin.generateResponse({
  contextHandle,
  userMessage: 'What is the capital of France?',
  maxTokens: 100
});

console.log('AI Response:', response.text);

// Generate another response (conversation context is maintained)
const response2 = await LlamaMobileCapacitorPlugin.generateResponse({
  contextHandle,
  userMessage: 'What is its population?',
  maxTokens: 100
});

console.log('AI Response:', response2.text);

// Clear the conversation context
await LlamaMobileCapacitorPlugin.clearConversation({ contextHandle });

// Release the context
await LlamaMobileCapacitorPlugin.releaseContext({ contextHandle });
```


## Build Instructions

### Prerequisites
- Node.js and npm
- Capacitor CLI
- iOS: Xcode with Command Line Tools
- Android: Android Studio with SDK and NDK

### Build the Plugin

```bash
# Clone the repository
git clone https://github.com/llama-mobile/llama-mobile-capacitor-plugin.git
cd llama-mobile-capacitor-plugin

# Install dependencies
npm install

# Build the plugin
npm run build

# Run tests
npm run verify
```

### Build with Native Dependencies

```bash
# Build the plugin with bundled iOS and Android dependencies
./scripts/build-capacitor-plugin.sh

# Build with custom options
./scripts/build-capacitor-plugin.sh --build-type=Release --verbose
```

## Platform-Specific Notes

### iOS
- The plugin uses Metal for GPU acceleration when available
- **Metal Support**: GPU acceleration is automatically enabled when `nGpuLayers > 0`
  - The plugin automatically includes and copies all necessary metal files (`ggml-llama.metallib`, `ggml-llama-sim.metallib`, `ggml-metal.metal`) to your app bundle during build
  - No manual file copying required!
- Models are loaded from the app's documents directory or a custom path
- For best performance, use models optimized for mobile devices
- iOS 15.0+ is recommended for optimal Metal performance

### Android
- The plugin uses the Android NDK for native performance
- Models are loaded from the app's files directory or a custom path
- GPU acceleration is available on devices with Vulkan support

## Troubleshooting

### Common Issues

1. **Model not found**: Ensure the model path is correct and the model file exists
2. **Out of memory**: Try using a smaller model or reducing the context size
3. **Slow performance**: Increase the number of GPU layers or threads if available
4. **Plugin not syncing**: Run `npx cap sync` to ensure the plugin is properly installed

### Debugging

```bash
# Enable verbose logging for iOS
XCODE_ATTRIBUTE_ENABLE_BITCODE=NO npx cap run ios --verbose

# Enable verbose logging for Android
npx cap run android --verbose
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute to this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

