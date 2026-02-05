# LlamaMobile Flutter SDK

A powerful Flutter plugin that brings local LLM (Large Language Model) capabilities to your Flutter applications. Run LLaMA models directly on-device with support for text completion, multimodal processing, embeddings, TTS, and more.

## What is This Plugin?

This is a **Flutter Plugin** that provides native iOS and Android bindings for the LlamaMobile C++ library. It allows Flutter developers to integrate local LLM functionality into their apps without needing external API calls or internet connectivity.

### Key Benefits

- **100% Offline**: Run models locally on-device
- **Cross-Platform**: Works on both iOS and Android
- **High Performance**: GPU acceleration on both platforms (Metal on iOS, Vulkan/OpenCL on Android)
- **Rich Features**: Text generation, multimodal, embeddings, TTS, and more
- **Easy Integration**: Simple Dart API with familiar Flutter patterns

## Project Structure

```
llama_mobile-flutter-SDK/
├── android/                     # Android platform implementation
│   ├── src/main/
│   │   ├── java/com/llamamobile/  # Android Java source files
│   │   ├── kotlin/com/llamamobile/ # Android Kotlin plugin
│   │   ├── jniLibs/              # Native Android libraries (.so files)
│   │   └── cpp/                  # JNI layer (C++)
│   └── build.gradle
├── ios/                         # iOS platform implementation
│   ├── Classes/                 # Swift plugin implementation
│   │   ├── LlamaMobileFlutterSdkPlugin.swift
│   │   └── LlamaMobile.swift     # iOS SDK wrapper
│   └── LlamaMobile/             # iOS framework (bundled)
│       └── llama_mobile.xcframework
├── lib/                         # Dart API layer
│   ├── llama_mobile_flutter_sdk.dart       # Main API class
│   ├── llama_mobile_flutter_sdk_platform_interface.dart # Platform interface
│   └── models/                  # Data models
├── example/                     # Example Flutter app
├── test/                        # Unit tests
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
- **OpenAI JSON Format**: Generate responses in OpenAI-compatible JSON format for easy migration from OpenAI API

## Installation

### Quick Start

Add the plugin to your Flutter app and start using it in minutes!

### Step 1: Add Dependency

Choose one of the following methods to add the plugin to your Flutter project:

#### Option A: From pub.dev (Recommended for Production)

```yaml
dependencies:
  llama_mobile_flutter_sdk: ^1.0.0
```

#### Option B: From Local Folder (For Development)

If you have the SDK source code locally:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
```

Or use a relative path:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: ../llama_mobile/llama_mobile-flutter-SDK
```

#### Option C: From Git Repository

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    git:
      url: https://github.com/your-org/llama_mobile.git
      path: llama_mobile-flutter-SDK
```

### Step 2: Install Packages

Run the following command in your Flutter project directory:

```bash
flutter pub get
```

### Step 3: Platform-Specific Setup

#### Android Setup

1. **Update minSdkVersion**

   Open `android/app/build.gradle` and ensure minSdkVersion is at least 21:

   ```gradle
   android {
       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 34
           // ... other configurations
       }
   }
   ```

2. **Add Permissions**

   Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <manifest>
       <!-- Required for file access -->
       <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
       <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
       
       <!-- Required for Android 13+ -->
       <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
       <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
       <uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
       
       <!-- Required for network access (for downloading models) -->
       <uses-permission android:name="android.permission.INTERNET" />
   </manifest>
   ```

3. **Request Runtime Permissions (Android 6.0+)**

   In your Flutter app, request storage permissions before accessing files:

   ```dart
   import 'package:permission_handler/permission_handler.dart';
   
   Future<void> requestPermissions() async {
     final status = await Permission.storage.request();
     if (!status.isGranted) {
       // Handle permission denied
     }
   }
   ```

#### iOS Setup

1. **Update Deployment Target**

   Open `ios/Runner.xcodeproj/project.pbxproj` in Xcode or edit directly to set the minimum deployment target to iOS 13.0 or higher:

   ```xml
   IPHONEOS_DEPLOYMENT_TARGET = 13.0;
   ```

2. **Add Permissions to Info.plist**

   Add the following to `ios/Runner/Info.plist`:

   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>This app needs access to photos to process images.</string>
   
   <key>NSCameraUsageDescription</key>
   <string>This app needs access to camera to capture images.</string>
   
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>This app needs permission to save photos to your library.</string>
   ```

3. **Metal Library Setup (Required for GPU Acceleration)**

   The iOS framework uses Metal for GPU acceleration. The SDK automatically handles Metal library setup, but you should be aware of the following:

   **What Happens Automatically:**
   - The SDK checks if `.metallib` files exist in the app bundle
   - The podspec includes a post-install script to copy Metal shader files from the xcframework
   - Verifies they're accessible for the Metal runtime during initialization

   **Verification:**
   - The SDK will log Metal library setup during initialization
   - Look for logs like "✓ Found metallib file" in your console
   - If you see "⚠ No metallib files found in framework bundle", check the troubleshooting section below

   **Troubleshooting Metal Shader Issues:**

   If you encounter issues with Metal shaders not loading:

   1. **Clean and Rebuild:**
      ```bash
      cd ios
      rm -rf Pods Podfile.lock
      pod install
      cd ..
      flutter clean
      flutter pub get
      flutter build ios
      ```

   2. **Check Framework Bundle:**
      - Open Xcode and navigate to your app target
      - Go to "Build Phases" → "Link Binary With Libraries"
      - Ensure `llama_mobile.xcframework` is listed
      - Check that Metal framework is also linked

   3. **Verify Metal Files in App Bundle:**
      - After building, check your app's `.app` bundle
      - Look for `.metallib` files in the framework directory
      - They should be located at: `YourApp.app/Frameworks/llama_mobile.framework/*.metallib`

   4. **Check Console Logs:**
      - Run your app with Xcode connected
      - Look for Metal-related log messages
      - Check for errors about missing or inaccessible metallib files

   5. **Manual Verification:**
      - If issues persist, verify the xcframework contains Metal files:
      ```bash
      ls -la ios/LlamaMobile/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/
      ```
      - You should see files like `ggml-llama.metallib` and `ggml-metal.metal`

### Step 4: Build Your App

After completing the setup, build your app:

```bash
# For Android
flutter build apk

# For iOS
flutter build ios
```

The Flutter build system will automatically:
- Build the plugin into an AAR for Android
- Include the xcframework for iOS
- Bundle all native libraries and frameworks

## Getting Started

### Basic Usage Example

Here's a complete example of how to use the LlamaMobile plugin in your Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LlamaMobile Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LlamaMobilePage(),
    );
  }
}

class LlamaMobilePage extends StatefulWidget {
  const LlamaMobilePage({super.key});

  @override
  State<LlamaMobilePage> createState() => _LlamaMobilePageState();
}

class _LlamaMobilePageState extends State<LlamaMobilePage> {
  final LlamaMobile _llamaMobile = LlamaMobile();
  LlamaContext? _context;
  String _response = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeContext();
  }

  Future<void> _initializeContext() async {
    setState(() => _isLoading = true);
    
    try {
      // Initialize a context with a model
      _context = await _llamaMobile.initContext(
        modelPath: 'assets/models/your-model.gguf', // Path to your model file
        nCtx: 2048,          // Context window size
        nGpuLayers: 4,       // Number of GPU layers to use (Metal on iOS, Vulkan on Android)
        nThreads: 4,         // Number of CPU threads
        embedding: false,    // Whether to enable embeddings
      );
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = 'Error initializing context: $e';
      });
    }
  }

  Future<void> _generateCompletion() async {
    if (_context == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final completion = await _context?.generateCompletion(
        prompt: 'Hello, how are you?',
        maxTokens: 128,       // Maximum tokens to generate
        temperature: 0.8,     // Sampling temperature (0.0 - 1.0)
        topP: 0.95,           // Top-p sampling parameter (0.0 - 1.0)
        topK: 40,             // Top-k sampling parameter
      );
      
      setState(() {
        _response = completion?.text ?? 'No response';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _response = 'Error generating completion: $e';
      });
    }
  }

  @override
  void dispose() {
    // Don't forget to free the context when done
    _context?.free();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LlamaMobile Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _generateCompletion,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Completion'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_response.isEmpty ? 'No response yet' : _response),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Model Setup

Before using the plugin, you need to have a model file. Here are the options:

#### Option 1: Include Model in Assets

1. Create a folder in your Flutter project: `assets/models/`
2. Copy your model file (`.gguf` format) to this folder
3. Update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/models/
```

4. Use the model:

```dart
final context = await _llamaMobile.initContext(
  modelPath: 'assets/models/your-model.gguf',
);
```

#### Option 2: Download Model at Runtime

```dart
// Download a model from URL
final downloadResult = await _llamaMobile.downloadModel(
  url: 'https://example.com/model.gguf',
  localPath: '/path/to/save/model.gguf',
);

if (downloadResult?.success == true) {
  // Use the downloaded model
  final context = await _llamaMobile.initContext(
    modelPath: downloadResult!.localPath,
  );
}
```

#### Option 3: Download from Hugging Face

```dart
// Download a model from Hugging Face
final downloadResult = await _llamaMobile.downloadHfFile(
  repoId: 'username/model-name',
  filename: 'model.gguf',
  localPath: '/path/to/save/model.gguf',
  bearerToken: 'your-hf-token', // Optional
  offline: false, // Use cached version if available
);

if (downloadResult?.success == true) {
  final context = await _llamaMobile.initContext(
    modelPath: downloadResult!.localPath,
  );
}
```

### Common Use Cases

#### 1. Chat Application

```dart
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final LlamaMobile _llamaMobile = LlamaMobile();
  LlamaContext? _context;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeContext();
  }

  Future<void> _initializeContext() async {
    _context = await _llamaMobile.initContext(
      modelPath: 'assets/models/chat-model.gguf',
      nCtx: 4096,
    );
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty || _context == null) return;

    final userMessage = _controller.text;
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: userMessage));
      _controller.clear();
    });

    final response = await _context?.generateConversation(
      chatMessages: _messages,
      maxTokens: 512,
    );

    setState(() {
      _messages.add(ChatMessage(role: 'assistant', content: response?.text ?? ''));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.role),
                  subtitle: Text(message.content),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _context?.free();
    super.dispose();
  }
}
```

#### 2. Text Summarization

```dart
Future<String> summarizeText(String text) async {
  final context = await _llamaMobile.initContext(
    modelPath: 'assets/models/summarization-model.gguf',
    nCtx: 4096,
  );

  final summary = await context?.generateCompletion(
    prompt: 'Summarize the following text:\n\n$text',
    maxTokens: 256,
    temperature: 0.3, // Lower temperature for more focused output
  );

  context?.free();
  return summary?.text ?? '';
}
```

#### 3. Code Generation

```dart
Future<String> generateCode(String description) async {
  final context = await _llamaMobile.initContext(
    modelPath: 'assets/models/code-model.gguf',
    nCtx: 2048,
  );

  final code = await context?.generateCompletion(
    prompt: 'Write a function to: $description',
    maxTokens: 512,
    temperature: 0.2, // Low temperature for deterministic code
  );

  context?.free();
  return code?.text ?? '';
}
```

#### 4. Embeddings for Semantic Search

```dart
Future<List<double>> generateEmbedding(String text) async {
  final context = await _llamaMobile.initContext(
    modelPath: 'assets/models/embedding-model.gguf',
    embedding: true, // Enable embeddings
  );

  final embedding = await context?.generateEmbedding(text);
  
  context?.free();
  return embedding ?? [];
}

Future<double> calculateSimilarity(
  List<double> embedding1,
  List<double> embedding2,
) {
  // Calculate cosine similarity
  double dotProduct = 0;
  double norm1 = 0;
  double norm2 = 0;

  for (int i = 0; i < embedding1.length; i++) {
    dotProduct += embedding1[i] * embedding2[i];
    norm1 += embedding1[i] * embedding1[i];
    norm2 += embedding2[i] * embedding2[i];
  }

  return dotProduct / (sqrt(norm1) * sqrt(norm2));
}
```

## Advanced Features

### Grammar Files

Constrain model output to specific formats using grammar files:

```dart
// Load a grammar file from a file path
final jsonGrammar = await context?.loadGrammar('/path/to/json.gbnf');

// Generate completion with grammar constraint
final structuredResult = await context?.generateCompletion(
  prompt: 'Create a JSON object with user info: name, age, email',
  maxTokens: 128,
  grammar: jsonGrammar,
);

print(structuredResult?.text); // Will be valid JSON
```

**Common Grammar Files:**
- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

### OpenAI JSON Format

Generate responses in OpenAI-compatible JSON format:

```dart
final completion = await context?.generateCompletion(
  prompt: 'Tell me about artificial intelligence',
  maxTokens: 150,
  temperature: 0.7,
  useJsonResponse: true, // Enable OpenAI JSON format
);

print(completion?.text); // Will contain JSON formatted response
```

### Text-to-Speech (TTS)

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

### LoRA Adapters

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

## API Reference

### LlamaMobile Class

The main entry point for the SDK.

#### Methods

##### `initContext()`
Initializes a new Llama context with the specified parameters.

**Parameters:**
- `modelPath`: Path to the model file (required)
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
- `url`: URL to download the model from (required)
- `localPath`: Local path to save the model (required)
- `username`: Username for authentication (optional)
- `password`: Password for authentication (optional)
- `headers`: Additional HTTP headers (optional)

**Returns:** A `Future<DownloadResult?>` with download status.

##### `downloadHfFile()`
Downloads a file from Hugging Face.

**Parameters:**
- `repoId`: Hugging Face repository ID (required)
- `filename`: Filename to download (required)
- `localPath`: Local path to save the file (required)
- `bearerToken`: Hugging Face authentication token (optional)
- `offline`: Use cached version if available (default: false)

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
- `prompt`: Input prompt (required)
- `maxTokens`: Maximum tokens to generate (default: 128)
- `temperature`: Sampling temperature (default: 0.8)
- `topK`: Top-k sampling parameter (default: 40)
- `topP`: Top-p sampling parameter (default: 0.95)
- `minP`: Minimum probability for top-p filtering (default: 0.05)
- `grammar`: Grammar string to constrain output (optional)
- `useJsonResponse`: Enable OpenAI JSON format (default: false)

**Returns:** A `Future<CompletionResult?>` with the generated text.

##### `generateMultimodalCompletion()`
Generates completion from text and images.

**Parameters:**
- `prompt`: Input prompt (required)
- `mediaPaths`: List of image file paths (required)
- `maxTokens`: Maximum tokens to generate (default: 128)

**Returns:** A `Future<CompletionResult?>` with the generated text.

##### `generateConversation()`
Generates a response to a chat conversation.

**Parameters:**
- `chatMessages`: List of chat messages (required)
- `maxTokens`: Maximum tokens to generate (default: 128)
- `useJsonResponse`: Enable OpenAI JSON format (default: false)

**Returns:** A `Future<ConversationResult?>` with the generated response.

##### `generateEmbedding()`
Generates an embedding from text.

**Parameters:**
- `text`: Input text (required)

**Returns:** A `Future<List<double>?>` with the embedding vector.

##### `loadGrammar()`
Loads a grammar file from a file path.

**Parameters:**
- `grammarPath`: Path to the grammar file (required)

**Returns:** A `Future<String?>` with the grammar content.

#### TTS Methods

##### `loadTTSModel()`
Loads a text-to-speech model.

**Parameters:**
- `modelPath`: Path to the TTS model file (required)
- `modelType`: Type of TTS model (TTSModelType) (required)

**Returns:** A `Future<bool>` indicating success.

##### `generateAudio()`
Generates audio from text.

**Parameters:**
- `text`: Text to convert to speech (required)

**Returns:** A `Future<AudioResult?>` with the audio data.

##### `freeTTSModel()`
Releases the TTS model resources.

**Returns:** A `Future<bool>` indicating success.

#### LoRA Methods

##### `loadLoraAdapter()`
Loads a LoRA adapter.

**Parameters:**
- `adapterPath`: Path to the LoRA adapter file (required)
- `adapterScale`: LoRA adapter scale (default: 0.75)

**Returns:** A `Future<bool>` indicating success.

##### `freeLoraAdapter()`
Releases the LoRA adapter resources.

**Returns:** A `Future<bool>` indicating success.

## Platform-Specific Considerations

### Android
- **Permissions**: Requires READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE for file access
- **GPU Acceleration**: Configured via `nGpuLayers` parameter (uses Vulkan or OpenCL)
- **Performance**: Use smaller context sizes on lower-end devices
- **Min SDK**: Requires Android 5.0 (API 21) or higher

### iOS
- **Metal Acceleration**: Enabled by default for GPU acceleration
- **Storage**: Uses app sandbox for file access
- **Deployment**: Requires iOS 13.0 or higher
- **Architecture**: Supports both arm64 (devices) and arm64-simulator

## Troubleshooting

### Common Issues

#### Model Loading Failures
- Ensure the model path is correct and accessible
- Check that the model file isn't corrupted
- Verify the model format is compatible with LlamaMobile (.gguf format)
- Make sure you have requested the necessary permissions

#### Performance Issues
- Reduce `nCtx` to balance memory usage and context window
- Adjust `nThreads` based on device capabilities
- For Android, increase `nGpuLayers` to offload more work to GPU
- For iOS, Metal acceleration is automatic but can be tuned via `nGpuLayers`

#### Build Issues
- Ensure you've run `flutter pub get` after adding the dependency
- Check that minSdkVersion is at least 21 for Android
- Verify iOS deployment target is at least 13.0
- Clean and rebuild: `flutter clean && flutter pub get`

## Example Application

Check the `example/` directory for a complete Flutter application that demonstrates all SDK features:

```bash
cd example
flutter pub get
flutter run
```

The example app includes:
- Text completion
- Chat conversation
- Multimodal processing
- Embeddings
- TTS
- Model downloads
- Grammar usage

## Building the Plugin

If you want to build the plugin from source:

```bash
# Build iOS framework first (required)
./scripts/build-ios-framework.sh --build-type=Release

# Build Android libraries first (required)
./scripts/build-android-lib.sh --build-type=Release

# Build Flutter plugin
./scripts/build-flutter-SDK.sh --build-type=Release
```

The built plugin will be available in:
- `llama_mobile/llama_mobile-flutter-SDK/` (development version)
- `llama_mobile/output/llama_mobile-flutter-SDK/` (distribution version)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

The LlamaMobile Flutter SDK is released under the MIT License.

## Support

For issues and questions, please open a GitHub issue in the repository.
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

4. **Metal Library Setup (Required for GPU Acceleration)**

   Metal shader libraries (`.metallib` files) are required for GPU acceleration on iOS. These files contain precompiled Metal shaders that enable hardware acceleration for model inference.

   **Why This Is Necessary:**
   - The `llama_mobile` framework uses Metal for GPU acceleration
   - The `.metallib` files need to be in a location where the framework can find them
   - In Flutter apps, these files are embedded in the framework bundle but need to be accessible at runtime

   **How to Ensure Metal Libraries Are Available:**

   The SDK automatically handles Metal library setup by:
   1. Checking if `.metallib` files exist in the app bundle
   2. Copying them from the framework bundle to the app's binary directory if needed
   3. Verifying they're accessible for the Metal runtime

   **Manual Setup (If Automatic Setup Fails):**
   1. Locate the `.metallib` files in the framework bundle:
      - `ggml-llama.metallib`
      - `ggml-llama-sim.metallib`
   2. Copy these files to your app's `ios/Runner` directory
   3. In Xcode, add these files to your project by dragging them into the Runner target
   4. Ensure they're included in the app bundle by checking "Copy items if needed" and selecting your target

   **Verification:**
   - The SDK will log Metal library setup during initialization
   - Look for logs like "✓ Found metallib file" in your console
   - If you see "✗ Metallib file not found", check that the files are properly included in your app bundle

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

### Grammar Files

The SDK supports loading grammar files from file paths to constrain model output to specific formats. You can use your own grammar files or download them from the LlamaMobile repository.

**Using Grammars:**

```dart
// Load a grammar file from a file path
final jsonGrammar = await context?.loadGrammar('/path/to/json.gbnf');

// Generate completion with grammar constraint
final structuredResult = await context?.generateCompletion(
  prompt: 'Create a JSON object with user info: name, age, email',
  maxTokens: 128,
  grammar: jsonGrammar,
);

print(structuredResult?.text); // Will be valid JSON
```

**Common Grammar Files:**

You can find various grammar files in the LlamaMobile repository or create your own:

- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

### OpenAI JSON Format

The SDK supports generating responses in OpenAI-compatible JSON format, making it easy to migrate applications from the OpenAI API:

```dart
// Generate completion with OpenAI JSON format
final completion = await context?.generateCompletion(
  prompt: 'Tell me about artificial intelligence',
  maxTokens: 150,
  temperature: 0.7,
  useJsonResponse: true, // Enable OpenAI JSON format
);

print(completion?.text); // Will contain JSON formatted response
```

**Example Output:**

```json
{
  "id": "chatcmpl-123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "model-name",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "AI, or artificial intelligence, refers to the simulation of human intelligence in machines..."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 50,
    "total_tokens": 60
  }
}
```

This format is also supported for conversation generation:

```dart
final response = await context?.generateConversation(
  chatMessages: [
    ChatMessage(role: "user", content: "Hello!"),
  ],
  maxTokens: 100,
  useJsonResponse: true, // Enable OpenAI JSON format
);

print(response?.text); // Will contain JSON formatted response
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
Loads a grammar file from a file path.

**Parameters:**
- `grammarPath`: Path to the grammar file

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


### TTS Pipeline
1. Load main TTS model (OuteTTS-0.2-500M-Q6_K.gguf)
2. Load vocoder model (WavTokenizer-Large-75-F16.gguf)
3. Format text for TTS using``getFormattedAudioCompletion``
4. Generate guide tokens using``getAudioGuideTokens``
5. Set the guide tokens using``setGuideTokens``
6. Generate completion from the main model, which will generate audio tokens
7. Filter the generated tokens to only include audio tokens (151672-155772)
8. Decode the filtered audio tokens using the vocoder

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