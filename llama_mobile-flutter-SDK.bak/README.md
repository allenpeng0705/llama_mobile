# Llama Mobile Flutter SDK

A cross-platform Flutter SDK for Llama Mobile that integrates the native iOS and Android SDKs, providing a unified API for model loading, text completion generation, and resource management.

## Features

- **Unified API**: Single Dart interface for both iOS and Android platforms, mirroring native SDKs
- **Model Management**: Easy model initialization and resource release
- **Text Generation**: Generate text completions with detailed configuration options
- **Streaming Support**: Real-time token streaming during text generation
- **Conversation Management**: Create and manage multi-turn conversations with history
- **Embeddings**: Generate vector embeddings for text
- **Tokenization**: Convert text to tokens and vice versa
- **LoRA Adapters**: Apply Low-Rank Adaptation adapters to models
- **Text-to-Speech**: Convert text to speech using TTS models
- **Multimodal Support**: Initialize multimodal capabilities
- **Model Download**: Download models from URLs with progress tracking
- **Cross-Platform**: Works seamlessly on both iOS and Android devices
- **Performance Optimized**: Leverages native platform capabilities for optimal performance
- **Comprehensive Documentation**: Complete API documentation for all features
- **Tested**: Comprehensive test suite covering all APIs

## Installation

### Prerequisites

- Flutter SDK 3.0.0 or higher
- iOS 13.0 or higher
- Android 7.0 (API level 24) or higher

### Dependency

Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile-flutter-SDK
```

Then run:

```bash
flutter pub get
```

## API Documentation

### Enums

#### TTSModelType

Enum for text-to-speech model types:

```dart
enum TTSModelType {
  outETTSv02,  // Outlines eTTS v0.2 model
}
```

#### StopType

Enum for stop generation types:

```dart
enum StopType {
  eos,       // End-of-sequence token
  word,      // User-specified stop word
  limit,     // Maximum token limit reached
  user,      // User interrupted generation
}
```

#### GrammarName

Enum for built-in grammar types:

```dart
enum GrammarName {
  json,        // JSON grammar
  arithmetic,  // Arithmetic expressions
  list,        // List format
}
```

### Data Models

#### InitParams

Configuration for initializing a model:

```dart
class InitParams {
  final String modelPath;        // Path to the GGUF model file
  final int nCtx;               // Context size for the model (default: 2048)
  final int nGpuLayers;         // Number of GPU layers to use (default: 0)
  final int nThreads;           // Number of CPU threads to use (default: 4)
  final int nBatch;             // Batch size for model processing (default: 512)
  final int nUbatch;            // Micro-batch size for model processing (default: 512)
  final bool useMmap;           // Whether to use memory-mapped files (default: true)
  final bool useMlock;          // Whether to lock memory (default: false)
  final bool embedding;         // Whether to generate embeddings (default: false)
}
```

#### CompletionParams

Configuration for generating text completions:

```dart
class CompletionParams {
  final String prompt;           // Prompt text for generation
  final int maxTokens;           // Maximum tokens to generate (default: 100)
  final double temperature;      // Sampling temperature (default: 0.8)
  final int topK;                // Top-K sampling parameter (default: 40)
  final double topP;             // Top-P sampling parameter (default: 0.95)
  final double minP;             // Min-P sampling parameter (default: 0.05)
  final double typicalP;         // Typical-P sampling parameter (default: 1.0)
  final int seed;                // Random seed (default: -1 for random)
  final int nThreads;            // Number of CPU threads to use (default: 4)
  final int penaltyLastN;        // Penalty window size (default: 64)
  final double penaltyRepeat;    // Repetition penalty (default: 1.1)
  final double penaltyFreq;      // Frequency penalty (default: 0.0)
  final double penaltyPresent;   // Presence penalty (default: 0.0)
  final int mirostat;            // Mirostat sampling mode (0: disabled, 1: v1, 2: v2)
  final double mirostatTau;      // Mirostat target entropy (default: 5.0)
  final double mirostatEta;      // Mirostat learning rate (default: 0.1)
  final bool ignoreEos;          // Whether to ignore end-of-sequence tokens (default: false)
  final List<String> stopSequences; // List of stop sequences (default: empty)
  final String? grammar;         // Grammar string for constrained generation (optional)
}
```

#### CompletionResult

Result of a text completion generation:

```dart
class CompletionResult {
  final String text;             // Generated text completion
  final int tokensGenerated;     // Number of tokens generated
  final int tokensEvaluated;     // Number of tokens evaluated
  final bool truncated;          // Whether the generation was truncated
  final bool stoppedEos;         // Whether generation stopped at EOS token
  final bool stoppedWord;        // Whether generation stopped at a stop word
  final bool stoppedLimit;       // Whether generation stopped at token limit
}
```

#### LoraAdapter

Configuration for LoRA adapters:

```dart
class LoraAdapter {
  final String path;             // Path to the LoRA adapter file
  final double scale;            // LoRA scaling factor (default: 1.0)
}
```

#### TTSParams

Configuration for text-to-speech generation:

```dart
class TTSParams {
  final String text;             // Text to convert to speech
  final String voice;            // Voice identifier
  final int seed;                // Random seed (default: -1 for random)
  final double speed;            // Speech speed (default: 1.0)
  final double lengthScale;      // Length scale (default: 1.0)
}
```

#### ConversationParams

Configuration for creating conversations:

```dart
class ConversationParams {
  final String systemPrompt;     // System prompt for the conversation
  final String chatTemplate;     // Chat template to use
}
```

#### DownloadParams

Configuration for downloading models:

```dart
class DownloadParams {
  final String url;              // Download URL
  final String destinationPath;  // Destination path for the downloaded file
  final int expectedSizeMb;      // Expected file size in MB
}
```

### Methods

#### initialize

Initializes a model from the specified path with the given configuration:

```dart
Future<bool> initialize(InitParams params)
```

**Parameters:**
- `params`: Initialization configuration object

**Returns:**
- `true` if the model was initialized successfully, `false` otherwise

#### generate

Generates text completion based on the given prompt and configuration:

```dart
Future<String> generate(CompletionParams params)
```

**Parameters:**
- `params`: Completion configuration object

**Returns:**
- Generated text completion as a string

#### generateResponse

Generates detailed text completion with additional metadata:

```dart
Future<CompletionResult> generateResponse(CompletionParams params)
```

**Parameters:**
- `params`: Completion configuration object

**Returns:**
- `CompletionResult` object with generated text and metadata

#### streamCompletion

Streams tokens during text generation:

```dart
Future<String> streamCompletion(CompletionParams params, Function(String) onToken)
```

**Parameters:**
- `params`: Completion configuration object
- `onToken`: Callback function invoked for each generated token

**Returns:**
- Complete generated text as a string

#### stopCompletion

Stops ongoing text generation:

```dart
Future<void> stopCompletion()
```

#### tokenize

Tokenizes text into model tokens:

```dart
Future<List<int>> tokenize(String text)
```

**Parameters:**
- `text`: Text to tokenize

**Returns:**
- List of token IDs

#### detokenize

Converts tokens back to text:

```dart
Future<String> detokenize(List<int> tokens)
```

**Parameters:**
- `tokens`: List of token IDs

**Returns:**
- Detokenized text

#### generateEmbeddings

Generates embeddings for the last generated text:

```dart
Future<List<double>> generateEmbeddings()
```

**Returns:**
- List of embedding values

#### generateEmbeddingsForPrompt

Generates embeddings for the given prompt:

```dart
Future<List<double>> generateEmbeddingsForPrompt(String prompt)
```

**Parameters:**
- `prompt`: Prompt text to generate embeddings for

**Returns:**
- List of embedding values

#### initMultimodal

Initializes multimodal capabilities:

```dart
Future<bool> initMultimodal()
```

**Returns:**
- `true` if multimodal was initialized successfully, `false` otherwise

#### initTTS

Initializes text-to-speech capabilities:

```dart
Future<bool> initTTS(String ttsPath, TTSModelType modelType)
```

**Parameters:**
- `ttsPath`: Path to the TTS model file
- `modelType`: TTS model type

**Returns:**
- `true` if TTS was initialized successfully, `false` otherwise

#### generateAudio

Generates audio from text:

```dart
Future<String> generateAudio(TTSParams params)
```

**Parameters:**
- `params`: TTS configuration object

**Returns:**
- Path to the generated audio file

#### applyLoraAdapters

Applies LoRA adapters to the model:

```dart
Future<bool> applyLoraAdapters(List<LoraAdapter> adapters)
```

**Parameters:**
- `adapters`: List of LoRA adapter configurations

**Returns:**
- `true` if adapters were applied successfully, `false` otherwise

#### createConversation

Creates a new conversation:

```dart
Future<String> createConversation(ConversationParams params)
```

**Parameters:**
- `params`: Conversation configuration object

**Returns:**
- Unique conversation ID

#### generateConversationResponse

Generates a response for a specific conversation:

```dart
Future<String> generateConversationResponse(String conversationId, CompletionParams params)
```

**Parameters:**
- `conversationId`: Unique conversation ID
- `params`: Completion configuration object

**Returns:**
- Generated conversation response

#### streamConversationResponse

Streams tokens during conversation response generation:

```dart
Future<String> streamConversationResponse(String conversationId, CompletionParams params, Function(String) onToken)
```

**Parameters:**
- `conversationId`: Unique conversation ID
- `params`: Completion configuration object
- `onToken`: Callback function invoked for each generated token

**Returns:**
- Complete generated conversation response

#### getConversationHistory

Retrieves the history of a specific conversation:

```dart
Future<List<Map<String, dynamic>>> getConversationHistory(String conversationId)
```

**Parameters:**
- `conversationId`: Unique conversation ID

**Returns:**
- List of message maps with 'role' and 'content' keys

#### clearConversation

Clears the history of a specific conversation:

```dart
Future<void> clearConversation(String conversationId)
```

**Parameters:**
- `conversationId`: Unique conversation ID

#### downloadModel

Downloads a model from a URL:

```dart
Future<bool> downloadModel(DownloadParams params, Function(double) onProgress)
```

**Parameters:**
- `params`: Download configuration object
- `onProgress`: Progress callback function (0.0 to 1.0)

**Returns:**
- `true` if download completed successfully, `false` otherwise

#### getGrammarContent

Retrieves the content of a built-in grammar:

```dart
Future<String?> getGrammarContent(GrammarName grammarName)
```

**Parameters:**
- `grammarName`: Name of the built-in grammar

**Returns:**
- Grammar content as a string if found, null otherwise

#### getVersion

Retrieves the SDK version:

```dart
Future<String> getVersion()
```

**Returns:**
- SDK version string

#### release

Releases the loaded model and frees resources:

```dart
Future<void> release()
```

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _llamaSdk = LlamaMobileFlutterSdk();
  bool _isModelInitialized = false;
  String _generatedText = '';
  String _streamedText = '';
  bool _isGenerating = false;

  Future<void> _initializeModel() async {
    try {
      final params = InitParams(
        modelPath: '/path/to/your/model.gguf',
        nCtx: 2048,
        nGpuLayers: 10,
        nThreads: 4,
        useMmap: true,
      );
      
      final success = await _llamaSdk.initialize(params);
      setState(() {
        _isModelInitialized = success;
      });
    } catch (e) {
      print('Error initializing model: $e');
    }
  }

  Future<void> _generateResponse() async {
    if (!_isModelInitialized || _isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _generatedText = 'Generating...';
    });
    
    try {
      final params = CompletionParams(
        prompt: 'Hello, how are you?',
        temperature: 0.7,
        maxTokens: 150,
        topP: 0.95,
      );
      
      final result = await _llamaSdk.generateResponse(params);
      setState(() {
        _generatedText = result.text;
        print('Generated tokens: ${result.tokensGenerated}');
        print('Evaluation tokens: ${result.tokensEvaluated}');
      });
    } catch (e) {
      print('Error generating response: $e');
      setState(() {
        _generatedText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _streamResponse() async {
    if (!_isModelInitialized || _isGenerating) return;
    
    setState(() {
      _isGenerating = true;
      _streamedText = 'Streaming...';
    });
    
    try {
      final params = CompletionParams(
        prompt: 'Explain quantum computing in simple terms.',
        temperature: 0.6,
        maxTokens: 200,
      );
      
      // Clear the streaming text first
      setState(() {
        _streamedText = '';
      });
      
      await _llamaSdk.streamCompletion(params, (token) {
        setState(() {
          _streamedText += token;
        });
      });
    } catch (e) {
      print('Error streaming response: $e');
      setState(() {
        _streamedText = 'Error: $e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  Future<void> _createAndUseConversation() async {
    if (!_isModelInitialized) return;
    
    try {
      // Create a conversation
      final conversationId = await _llamaSdk.createConversation(
        ConversationParams(
          systemPrompt: 'You are a helpful assistant.',
          chatTemplate: 'default',
        ),
      );
      
      // Generate a response
      final params = CompletionParams(
        prompt: 'What is Flutter?',
        temperature: 0.7,
        maxTokens: 100,
      );
      
      final response = await _llamaSdk.generateConversationResponse(
        conversationId,
        params,
      );
      
      print('Conversation response: $response');
      
      // Get conversation history
      final history = await _llamaSdk.getConversationHistory(conversationId);
      print('Conversation history: $history');
      
      // Clear conversation
      await _llamaSdk.clearConversation(conversationId);
    } catch (e) {
      print('Error using conversation: $e');
    }
  }

  @override
  void dispose() {
    _llamaSdk.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Llama Mobile Flutter SDK Example')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isModelInitialized ? null : _initializeModel,
                child: Text('Initialize Model'),
              ),
              SizedBox(height: 20),
              Text('Model Status: $_isModelInitialized'),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isModelInitialized && !_isGenerating ? _generateResponse : null,
                child: Text('Generate Response'),
              ),
              SizedBox(height: 10),
              Text(_generatedText),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isModelInitialized && !_isGenerating ? _streamResponse : null,
                child: Text('Stream Response'),
              ),
              SizedBox(height: 10),
              Text(_streamedText),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isModelInitialized ? _createAndUseConversation : null,
                child: Text('Use Conversation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Running Tests

The Llama Mobile Flutter SDK includes a comprehensive test suite to verify all API functionality. To run the tests:

```bash
cd /path/to/llama_mobile-flutter-SDK
flutter test
```

### Test Coverage

The test suite covers:
- Model initialization and release
- Text completion generation (both regular and detailed)
- Token streaming during generation
- Generation cancellation
- Tokenization and detokenization
- Embeddings generation
- LoRA adapter application
- Text-to-speech functionality
- Conversation management
- Model downloading
- SDK version retrieval

All tests use a mock platform implementation to simulate native behavior, ensuring reliable testing without physical devices.

## Platform-Specific Configuration

### iOS

The iOS implementation uses the `llama_mobile-ios-SDK`, which is automatically copied into the Flutter plugin during the build process by the `build-flutter.sh` script. The plugin's `podspec` file is configured to reference this SDK, ensuring it's properly linked during iOS app builds.

### Android

The Android implementation uses the `llama_mobile-android-SDK`, which is automatically copied into the Flutter plugin during the build process by the `build-flutter.sh` or `build-flutter.bat` scripts. This includes the JNI libraries, native C++ files, Kotlin/Java classes, and assets/grammars folder, ensuring all dependencies are properly included in Android app builds.

## Build Scripts

The Flutter SDK provides build scripts to ensure it's properly configured and independent:

### macOS/Linux

```bash
# From the repository root
bash scripts/build-flutter.sh
```

### Windows

```batch
# From the repository root
scripts\build-flutter.bat
```

These scripts:
- Build the iOS and Android SDK dependencies
- Copy the necessary SDK files into the Flutter plugin
- Resolve Flutter dependencies
- Analyze the plugin code
- Optionally build the example app

By running these scripts, you ensure the Flutter SDK has all the necessary dependencies and is ready for use.

## Troubleshooting

### Model Loading Issues

- Ensure the model path is correct and the file exists
- Check that you have the necessary permissions to access the model file
- Verify the model format is compatible (GGUF format)

### Generation Issues

- Make sure a model is loaded before attempting to generate completions
- Check that the prompt text is properly formatted
- Adjust temperature and maxTokens parameters if needed

## Example App

An example application demonstrating the usage of the Llama Mobile Flutter SDK is available in the `examples/flutter_sdk_example` directory.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING](CONTRIBUTING.md) file for more information.

## Support

For issues and questions, please create an issue in the project repository.

