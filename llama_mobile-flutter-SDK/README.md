# LlamaMobile Flutter SDK

## Project Structure

```
llama_mobile-flutter-SDK/
├── android/                     # Android platform implementation
│   ├── src/main/java/com/llamamobile/  # Android Java source files
│   │   └── LlamaMobile.kt       # Kotlin implementation
│   ├── src/main/jniLibs/        # Native Android libraries
│   └── src/main/assets/grammars/ # Built-in grammar files
├── ios/                         # iOS platform implementation
│   ├── Classes/                 # Swift plugin implementation
│   │   └── LlamaMobileFlutterSdkPlugin.swift
│   └── LlamaMobile/             # iOS framework (bundled)
│       └── llama_mobile.xcframework
├── lib/                         # Dart API layer
│   ├── llama_mobile_flutter_sdk.dart       # Main API class
│   ├── llama_mobile_flutter_sdk_platform_interface.dart # Platform interface
│   └── models/                  # Data models
├── example/                     # Example Flutter app
├── test/                        # Unit tests
├── build-flutter-SDK.sh         # Build script
└── README.md                    # This documentation
```

## Features

### Core Functionality
- **Context Management**: Initialize and free Llama contexts with customizable parameters
- **Text Completion**: Generate text completions from prompts
- **Multimodal Completion**: Process text with images to generate multimodal responses
- **Conversation Handling**: Maintain chat conversations with proper context
- **Embeddings**: Generate vector embeddings from text

### Advanced Features
- **LoRA Adapters**: Load and use LoRA adapters for fine-tuned models
- **Text-to-Speech (TTS)**: Generate audio from text using TTS models
- **Model Downloads**: Download models directly within your application
- **Grammar Support**: Load and use grammar files to constrain generation

## Installation

### 1. Add Dependency to pubspec.yaml

#### Option A: From pub.dev (Recommended for Production)

```yaml
dependencies:
  llama_mobile_flutter_sdk: ^1.0.0
```

#### Option B: From Local Folder (For Development)

If you have the SDK source code in a local folder, you can add it as a path dependency:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
```

You can use relative paths too:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: ../llama_mobile/llama_mobile-flutter-SDK
```

This is useful when you want to make changes to the SDK source code and test them immediately in your app.

### 2. Install Packages

```bash
flutter pub get
```

### 3. Platform-Specific Setup

#### Android Setup

1. Open `android/build.gradle` and ensure you have the necessary repositories:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

2. Set minSdkVersion to at least 21 in `android/app/build.gradle`:

```gradle
defaultConfig {
    minSdkVersion 21
    // ... other configurations
}
```

3. Add storage permissions to `AndroidManifest.xml` if needed:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS Setup

1. Open your iOS project in Xcode
2. Set the minimum deployment target to iOS 13.0 or higher
3. Add the following to your `Info.plist` if using file system access:

```xml
<key>NSFileProtectionCompleteUntilFirstUserAuthentication</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>*</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Getting Started

### Basic Usage

```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

// Create a new instance of LlamaMobile
final llamaMobile = LlamaMobile();

// Initialize a context with a model
final context = await llamaMobile.initContext(
  modelPath: 'path/to/your/model.gguf',
  nCtx: 2048,          // Context window size
  nGpuLayers: 4,        // Number of GPU layers to use
  nThreads: 4,          // Number of CPU threads
  embedding: false,     // Whether to enable embeddings
);

// Generate text completion
final completion = await context?.generateCompletion(
  prompt: 'Hello, how are you?',
  maxTokens: 128,       // Maximum tokens to generate
  temperature: 0.8,     // Sampling temperature
  topP: 0.95,           // Top-p sampling parameter
);

print(completion?.text); // Generated text

// Don't forget to free the context when done
await context?.free();
```

### Built-in Grammar Files

The SDK includes grammar files that can constrain model output to specific formats:

- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

**Using Grammars:**

```dart
// Load a grammar file
final jsonGrammar = await context?.loadGrammar('json');

// Generate completion with grammar constraint
final structuredResult = await context?.generateCompletion(
  prompt: 'Create a JSON object with user info: name, age, email',
  maxTokens: 128,
  grammar: jsonGrammar,
);

print(structuredResult?.text); // Will be valid JSON
```

### Advanced Usage Examples

#### Conversation Handling

```dart
final messages = [
  ChatMessage(role: 'user', content: 'Hello, what is AI?'),
];

final conversationResult = await context?.generateConversation(
  chatMessages: messages,
  maxTokens: 256,
);

print(conversationResult?.text);

// Add assistant's response to the conversation
messages.add(ChatMessage(role: 'assistant', content: conversationResult!.text));

// Continue the conversation
messages.add(ChatMessage(role: 'user', content: 'How is AI used today?'));
final followupResult = await context?.generateConversation(
  chatMessages: messages,
  maxTokens: 256,
);
```

#### Text-to-Speech (TTS)

```dart
// Load a TTS model
await context?.loadTTSModel(
  'path/to/tts/model.gguf',
  TTSModelType.outETTSv02,
);

// Generate audio
final audioResult = await context?.generateAudio(
  'Hello, this is a test of the text-to-speech functionality.',
);

// Access the audio data
if (audioResult != null) {
  final audioData = audioResult.audioData;    // Uint8List of audio samples
  final sampleRate = audioResult.sampleRate;  // Sample rate (Hz)
  final channels = audioResult.channels;      // Number of audio channels
  
  // Play or save the audio data
  print('Generated ${audioData.length} bytes of audio at $sampleRate Hz');
}

// Free TTS model when done
await context?.freeTTSModel();
```

#### Embeddings

```dart
// Initialize context with embedding enabled
final embeddingContext = await llamaMobile.initContext(
  modelPath: 'path/to/embedding/model.gguf',
  embedding: true, // Enable embeddings
);

// Generate embedding
final embedding = await embeddingContext?.generateEmbedding(
  'Text to generate embedding for',
);

if (embedding != null) {
  print('Generated embedding with ${embedding.length} dimensions');
  print('First few values: ${embedding.take(5)}');
}

await embeddingContext?.free();
```

#### LoRA Adapters

```dart
// Load a LoRA adapter
await context?.loadLoraAdapter(
  'path/to/lora/adapter.gguf',
  0.75, // LoRA adapter scale
);

// Generate completion using the LoRA adapter
final loraResult = await context?.generateCompletion(
  prompt: 'Text using the LoRA adapter',
  maxTokens: 128,
);

print(loraResult?.text);

// Free the LoRA adapter when done
await context?.freeLoraAdapter();
```

#### Model Downloads

```dart
// Download a model from URL
final downloadResult = await llamaMobile.downloadModel(
  url: 'https://example.com/model.gguf',
  localPath: '/path/to/save/model.gguf',
  // Optional authentication
  // username: 'your_username',
  // password: 'your_password',
);

if (downloadResult?.success == true) {
  print('Model downloaded to: ${downloadResult?.localPath}');
  // Now you can use this model path to initialize a context
  final downloadedContext = await llamaMobile.initContext(
    modelPath: downloadResult!.localPath,
    nCtx: 2048,
  );
} else {
  print('Download failed: ${downloadResult?.errorMessage}');
}
```

## API Reference

### LlamaMobile Class

The main entry point for the SDK.

#### Methods

##### `initContext()`
Initializes a new Llama context with the specified parameters.

**Parameters:**
- `modelPath`: Path to the model file
- `chatTemplate`: Custom chat template (optional)
- `systemPrompt`: System prompt for conversation (optional)
- `nCtx`: Context window size (default: 2048)
- `nBatch`: Batch size for processing (default: 512)
- `nUBatch`: Micro batch size (default: 512)
- `nGpuLayers`: Number of GPU layers to use (default: 0)
- `nThreads`: Number of CPU threads (default: 4)
- `useMmap`: Whether to use memory mapping (default: true)
- `useMlock`: Whether to lock memory (default: false)
- `embedding`: Whether to enable embeddings (default: false)

**Returns:** A `Future<LlamaContext?>` representing the initialized context.

##### `downloadModel()`
Downloads a model from a URL to a local path.

**Parameters:**
- `url`: URL to download the model from
- `localPath`: Local path to save the model
- `username`: Username for authentication (optional)
- `password`: Password for authentication (optional)
- `headers`: Additional HTTP headers (optional)

**Returns:** A `Future<DownloadResult?>` with download status.

### LlamaContext Class

Represents a Llama model context.

#### Core Methods

##### `free()`
Releases the context resources.

**Returns:** A `Future<bool>` indicating success.

##### `generateCompletion()`
Generates text completion from a prompt.

**Parameters:**
- `prompt`: Input prompt
- `maxTokens`: Maximum tokens to generate (default: 128)
- `temperature`: Sampling temperature (default: 0.8)
- `topK`: Top-k sampling parameter (default: 40)
- `topP`: Top-p sampling parameter (default: 0.95)
- `minP`: Minimum probability for top-p filtering (default: 0.05)
- `grammar`: Grammar string to constrain output (optional)

**Returns:** A `Future<CompletionResult?>` with the generated text.

##### `generateMultimodalCompletion()`
Generates completion from text and images.

**Parameters:**
- `prompt`: Input prompt
- `mediaPaths`: List of image file paths
- `maxTokens`: Maximum tokens to generate (default: 128)

**Returns:** A `Future<CompletionResult?>` with the generated text.

##### `generateConversation()`
Generates a response to a chat conversation.

**Parameters:**
- `chatMessages`: List of chat messages
- `maxTokens`: Maximum tokens to generate (default: 128)

**Returns:** A `Future<ConversationResult?>` with the generated response.

##### `generateEmbedding()`
Generates an embedding from text.

**Parameters:**
- `text`: Input text

**Returns:** A `Future<List<double>?>` with the embedding vector.

##### `loadGrammar()`
Loads a built-in grammar file.

**Parameters:**
- `grammarName`: Name of the grammar file (without extension)

**Returns:** A `Future<String?>` with the grammar content.

#### TTS Methods

##### `loadTTSModel()`
Loads a text-to-speech model.

**Parameters:**
- `modelPath`: Path to the TTS model file
- `modelType`: Type of TTS model (TTSModelType)

**Returns:** A `Future<bool>` indicating success.

##### `generateAudio()`
Generates audio from text.

**Parameters:**
- `text`: Text to convert to speech

**Returns:** A `Future<AudioResult?>` with the audio data.

##### `freeTTSModel()`
Releases the TTS model resources.

**Returns:** A `Future<bool>` indicating success.

#### LoRA Methods

##### `loadLoraAdapter()`
Loads a LoRA adapter.

**Parameters:**
- `adapterPath`: Path to the LoRA adapter file
- `adapterScale`: LoRA adapter scale (default: 0.75)

**Returns:** A `Future<bool>` indicating success.

##### `freeLoraAdapter()`
Releases the LoRA adapter resources.

**Returns:** A `Future<bool>` indicating success.

## Platform-Specific Considerations

### Android
- **Permissions**: Requires READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE for file access
- **GPU Acceleration**: Configured via `nGpuLayers` parameter
- **Performance**: Use smaller context sizes on lower-end devices

### iOS
- **Metal Acceleration**: Enabled by default for GPU acceleration
- **Storage**: Uses app sandbox for file access
- **Deployment**: Requires iOS 13.0 or higher

## Troubleshooting

### Common Issues

#### Model Loading Failures
- Ensure the model path is correct and accessible
- Check that the model file isn't corrupted
- Verify the model format is compatible with LlamaMobile

#### Performance Issues
- Reduce `nCtx` to balance memory usage and context window
- Adjust `nThreads` based on device capabilities
- For Android, increase `nGpuLayers` to offload more work to GPU

#### Grammar Issues
- Ensure the grammar file name is correct (without extension)
- Some complex grammars may increase generation time

## Example Application

Check the `example/` directory for a complete Flutter application that demonstrates all SDK features:

```bash
cd example
flutter run
```

## Build Script

Use the provided build script to build a self-contained SDK:

```bash
./scripts/build-flutter-SDK.sh --build-type=Release
```

## API Documentation

For detailed API documentation, see the [Dartdoc](https://dart.dev/tools/dartdoc) documentation or the source code comments.

## License

The LlamaMobile Flutter SDK is released under the MIT License.

## Support

For issues and questions, please open a GitHub issue in the repository.