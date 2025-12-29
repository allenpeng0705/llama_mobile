# Llama Mobile Flutter SDK

A cross-platform Flutter SDK for Llama Mobile that integrates the native iOS and Android SDKs, providing a unified API for model loading, text completion generation, and resource management.

## Features

- **Unified API**: Single Dart interface for both iOS and Android platforms
- **Model Management**: Easy model loading and resource release
- **Text Generation**: Generate text completions with configurable parameters
- **Cross-Platform**: Works seamlessly on both iOS and Android devices
- **Performance Optimized**: Leverages native platform capabilities for optimal performance

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

### Data Models

#### ModelConfig

Configuration for loading a model:

```dart
class ModelConfig {
  final String modelPath;        // Path to the GGUF model file
  final int contextSize;         // Context size for the model (default: 1024)
  final bool useMemoryCache;     // Whether to use memory cache (default: true)
}
```

#### GenerationConfig

Configuration for generating text completions:

```dart
class GenerationConfig {
  final String prompt;           // Prompt text for generation
  final double temperature;      // Sampling temperature (default: 0.8)
  final int maxTokens;           // Maximum tokens to generate (default: 100)
}
```

### Methods

#### loadModel

Loads a model from the specified path with the given configuration:

```dart
Future<bool> loadModel(ModelConfig config)
```

**Parameters:**
- `config`: Model configuration object

**Returns:**
- `true` if the model was loaded successfully, `false` otherwise

#### generateCompletion

Generates text completion based on the given prompt and configuration:

```dart
Future<String> generateCompletion(GenerationConfig config)
```

**Parameters:**
- `config`: Generation configuration object

**Returns:**
- Generated text completion as a string

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
  bool _isModelLoaded = false;

  Future<void> _loadModel() async {
    try {
      final config = ModelConfig(
        modelPath: '/path/to/your/model.gguf',
        contextSize: 2048,
        useMemoryCache: true,
      );
      
      final success = await _llamaSdk.loadModel(config);
      setState(() {
        _isModelLoaded = success;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  Future<void> _generateText() async {
    if (!_isModelLoaded) return;
    
    try {
      final config = GenerationConfig(
        prompt: 'Hello, how are you?',
        temperature: 0.7,
        maxTokens: 150,
      );
      
      final result = await _llamaSdk.generateCompletion(config);
      print('Generated completion: $result');
    } catch (e) {
      print('Error generating text: $e');
    }
  }

  @override
  void dispose() {
    _llamaSdk.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Your UI implementation here
  }
}
```

## Platform-Specific Configuration

### iOS

The iOS implementation requires the `llama_mobile-ios-SDK` to be available. This is configured automatically through the CocoaPods dependency in the plugin's `podspec` file.

### Android

The Android implementation requires the `llama_mobile-android-SDK` to be available. This is configured automatically through the Gradle dependencies in the plugin's `build.gradle` file.

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

