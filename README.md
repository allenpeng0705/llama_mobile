@ -1,1253 +0,0 @@
# llama_mobile

```
    _______________________
   /                       \
  /   ████████  ████████   \
 |    ██      ██      ██    |
 |    ██  LLAMA MOBILE ██    |
 |    ██      ██      ██    |
 |    ████████  ████████    |
 |                           |
 |  ╔════════════════════╗   |
 |  ║    AI ON THE GO    ║   |
 |  ║                     ║   |
 |  ║  • iOS & Android    ║   |
 |  ║  • Flutter          ║   |
 |  ║  • React Native     ║   |
 |  ║  • Capacitor        ║   |
 |  ╚════════════════════╝   |
 |                           |
 |       🧠 📱 🚀          |
  \_________________________/
        /\
       /  \
      /____\
```

A lightweight, high-performance framework for running AI models on mobile devices, based on llama.cpp and designed for cross-platform compatibility across iOS, Android, Flutter, ReactNative, and web-based applications via Capacitor.

## Project Overview

llama_mobile is a mobile-first AI framework that brings the power of llama.cpp to various mobile platforms and development frameworks. The project focuses on providing native SDKs and plugins for seamless integration of large language models (LLMs) into mobile and web applications.

## Current Status

The project is currently in active development with the following components completed:

- ✅ Core C++ library (based on llama.cpp)
- ✅ iOS framework
- ✅ Android library (llama_mobile-android)
- ✅ Android SDK wrapper (llama_mobile-android-SDK)
- ✅ Basic test infrastructure
- ✅ Build scripts for core library, iOS, Android, and Flutter
- ✅ Example apps for iOS, Android, and Flutter
- ✅ Flutter plugin (llama_mobile-flutter-SDK)

Planned development:

- ⏳ ReactNative plugin
- ⏳ Capacitor plugin

## Supported Models

The framework supports various GGUF model types:

- Standard language models
- Embedding models
- Vision-Language Models (VLM)
- Multimodal models

## Plugins and SDKs

llama_mobile provides dedicated SDKs and plugins for various development platforms to simplify integration of AI models into your applications. Below is a comprehensive list of all available SDKs and plugins:

### Core SDKs

- **llama_mobile-ios-SDK/**: Native iOS SDK for integrating AI models into iOS applications. Supports both Swift and Objective-C with Metal acceleration for optimal performance.
  - **README**: [llama_mobile-ios-SDK/README.md](llama_mobile-ios-SDK/README.md)
  - **Build Script**: `scripts/build-ios.sh`

- **llama_mobile-android-SDK/**: Native Android SDK for integrating AI models into Android applications. Provides JNI bindings and Neon SIMD support for performance optimization.
  - **README**: [llama_mobile-android-SDK/README.md](llama_mobile-android-SDK/README.md)
  - **Build Script**: `scripts/build-android.sh`

- **llama_mobile-android-java-SDK/**: Java-based Android SDK that provides a convenient and Java-friendly API for interacting with llama models.
  - **README**: [llama_mobile-android-java-SDK/README.md](llama_mobile-android-java-SDK/README.md)
  - **Build Script**: `scripts/build-android.sh`

### Cross-Platform Plugins

- **llama_mobile-flutter-SDK/**: Flutter plugin that provides a Dart API for integrating AI models into cross-platform Flutter applications. Supports both iOS and Android targets.
  - **README**: [llama_mobile-flutter-SDK/README.md](llama_mobile-flutter-SDK/README.md)
  - **Build Script**: `scripts/build-flutter.sh`

- **llama_mobile-react-native-SDK/**: React Native plugin that provides JavaScript/TypeScript bindings for native AI model operations. Allows AI integration in React Native applications.
  - **README**: [llama_mobile-react-native-SDK/README.md](llama_mobile-react-native-SDK/README.md)

- **llama_mobile-capacitor/**: (Planned) Capacitor plugin for integrating AI models into web-based applications. Enables AI capabilities in cross-platform web apps.
   - **README**: [llama_mobile-capacitor-plugin/CONTRIBUTING.md](llama_mobile-capacitor-plugin/CONTRIBUTING.md)

### Example Applications

Each SDK and plugin comes with example applications that demonstrate basic usage:

#### iOS Examples
- **iOS SDK Example**: `examples/iOSSDKExample/` - Shows how to use the iOS SDK
- **SwiftUI Example**: `examples/LlamaMobileSwiftUIExample/` - Modern SwiftUI application example

#### Android Examples
- **Android SDK Example**: `examples/androidSDKExample/` - Android SDK usage example
- **Android Java SDK Example**: `examples/androidJavaSDKExample/` - Java-specific SDK usage example

#### Cross-Platform Examples
- **Flutter SDK Example**: `examples/flutterSDKExample/` - Flutter plugin integration example

#### Core Examples
- **C++ Example**: `examples/cpp/` - Direct usage of the core C++ library

## Architecture

### Core Components

- **lib/**: Main library directory containing:
  - **lib/tests/**: Tests for the C/C++ source code
  - **lib/llama_cpp/**: Core llama.cpp implementation
  - Mobile-specific adaptations and optimizations
  - Various GGUF models (normal, embedding, VLM, multimodal)

- **llama_mobile-ios-SDK/**: iOS SDK project folder
- **llama_mobile-android-SDK/**: Android SDK project folder
- **llama_mobile-android-java-SDK/**: Java-based Android SDK project folder
- **llama_mobile-flutter-SDK/**: Flutter plugin project folder
- **scripts/**: Build and utility scripts
- **CMakeLists.txt**: Build configuration for the core library

### Planned Components

- **llama_mobile_reactnative/**: ReactNative plugin
- **llama_mobile_capacitor/**: Capacitor plugin for web-based apps

## Getting Started

### Prerequisites

#### Common Requirements
- CMake 3.20 or later
- Python 3.x (for some utility scripts)

#### iOS Build Requirements
- macOS with Xcode installed
- iOS 13.0+ deployment target for mobile apps

#### Android Build Requirements
- Android Studio installed
- Java Development Kit (JDK) 8 or later
- Android SDK (API level 21 or higher)
- Android NDK version 29.0.14206865 (required for building native libraries)
- Set ANDROID_HOME environment variable pointing to your Android SDK directory

### Build Configuration

All build scripts now use a **centralized configuration system** through the `scripts/config.env` file. This file contains all environment variables needed for building different SDKs and plugins, with auto-detection and default values for most parameters.

### Key Features

- **Auto-detection**: SDK paths (ANDROID_HOME, NDK_PATH, XCODE_PATH) are automatically detected
- **Default values**: Reasonable defaults for build types (Release), architectures, and behavior flags
- **User customization**: Users can modify any variable in `config.env` and changes will be preserved
- **Cross-platform**: Works on both macOS/Linux (.sh) and Windows (.bat) scripts

For detailed configuration information, see the [Build Scripts README](scripts/README.md).

### Build Scripts

The project contains various build scripts in the `scripts/` directory:

- **build-tests-run.sh**: Builds and runs tests
- **build-ios.sh**: Builds the iOS framework based on the core library
- **build-ios-SDK.sh**: Builds the iOS SDK from pre-built libraries
- **build-android.sh**: Builds the Android library and SDK
- **build-android-SDK.sh**: Builds the Android SDK from pre-built libraries
- **build-flutter.sh**: Builds the Flutter plugin
- **build-reactnative.sh**: Builds the ReactNative plugin
- **build-capacitor.sh**: Builds the Capacitor plugin

All scripts use the centralized configuration system in `scripts/config.env`. For detailed information, see the [Build Scripts README](scripts/README.md).

## Building Instructions

### Build Core Library

```bash
# Build core library using the build script (uses config.env)
./scripts/build-lib.sh

# Or manually build
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Build iOS Framework

```bash
# Build iOS framework (uses config.env)
./scripts/build-ios.sh
```

### Build iOS SDK from Pre-built Libraries

```bash
# Build iOS SDK using pre-built framework
./scripts/build-ios-SDK.sh
```

### Build Android Library and SDK

```bash
# Build Android library and SDK (uses config.env)
./scripts/build-android.sh
```

### Build Android SDK from Pre-built Libraries

```bash
# Build Android SDK using pre-built libraries
./scripts/build-android-SDK.sh
```

### Build Flutter Plugin

```bash
# Build Flutter plugin (uses config.env)
./scripts/build-flutter.sh
```

### Build ReactNative Plugin

```bash
# Build ReactNative plugin (uses config.env)
./scripts/build-reactnative.sh
```

### Build Capacitor Plugin

```bash
# Build Capacitor plugin (uses config.env)
./scripts/build-capacitor.sh
```

### Build and Run Tests

#### Core Library Tests

The Core C++ library includes a comprehensive test suite (`lib/tests/test_api.cpp`) that covers:

- **Model Initialization**: Loading and initializing models with different parameters
- **Text Completion**: Basic and advanced text generation
- **Tokenization**: Converting between text and model tokens
- **Embedding Generation**: Generating numerical representations of text
- **Conversation Management**: Creating and managing conversation contexts
- **Grammar-Constrained Generation**: Generating text that adheres to specific grammar rules (e.g., JSON output)

To build and run the Core library tests:

```bash
# Build and run tests (uses config.env)
./scripts/build-tests-run.sh
```

Alternatively, you can build and run the tests manually:

```bash
# Build the test binary
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make test_api

# Run the tests
./test_api
```

### Running SDK Tests

#### iOS SDK Tests

```bash
# Build the iOS SDK (if not already built)
./scripts/build-ios-SDK.sh

# Run the iOS SDK tests in Xcode
# Open the project: llama_mobile-ios-SDK/llama_mobile-ios-SDK.xcodeproj
# Select the "Tests" scheme and run
```

#### Android SDK Tests

```bash
# Build the Android SDK (if not already built)
./scripts/build-android-SDK.sh

# Run the Android SDK tests in Android Studio
# 1. Open Android Studio
# 2. Import the module: llama_mobile-android-SDK/
# 3. Navigate to the "test" directory in the project structure
# 4. Right-click on the test file (LlamaMobileUnitTests.kt) and select "Run Tests"

# Or run tests from the command line using Gradle
cd llama_mobile-android-SDK
./gradlew test
```

#### SDK Tests

Each SDK has its own test suite. Please refer to the respective SDK README files for detailed information:

- **iOS SDK**: `llama_mobile-ios-SDK/README.md`
- **Android Kotlin SDK**: `llama_mobile-android-SDK/README.md`
- **Android Java SDK**: `llama_mobile-android-java-SDK/README.md`
- **Flutter SDK**: `llama_mobile-flutter-SDK/README.md`
- **ReactNative SDK**: `llama_mobile-react-native-SDK/README.md`
- **Capacitor Plugin**: `llama_mobile-capacitor-plugin/CONTRIBUTING.md`

## Integration Guide

### iOS Integration

1. Add `llama_mobile.xcframework` from the `llama_mobile-ios-SDK` directory to your Xcode project
2. Link against required system frameworks (Metal, MetalKit)
3. Import the SDK in your code:
   ```swift
   import llama_mobile
   import LlamaMobile
   ```
4. Initialize the SDK and load models as needed

### Android Integration

1. Add the `llama_mobile-android-SDK` library as a module dependency in your Android Studio project
2. Add the following to your `settings.gradle`:
   ```gradle
   include ':llama_mobile-android-SDK'
   project(':llama_mobile-android-SDK').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-SDK')
   ```
3. Add the dependency to your app's `build.gradle`:
   ```gradle
   dependencies {
       implementation project(':llama_mobile-android-SDK')
   }
   ```
4. Import the SDK in your Kotlin code:
   ```kotlin
   import com.llamamobile.LlamaMobile
   ```
5. Initialize the SDK and load models as needed

### Flutter Integration

#### Flutter Setup Prerequisites

Before using the Flutter plugin, ensure Flutter is properly installed and configured:

1. **Install Flutter SDK:**
   - Download the Flutter SDK from [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
   - Extract the SDK to a location like `/Users/yourname/flutter` (macOS/Linux) or `C:\flutter` (Windows)

2. **Set up Flutter PATH:**
   
   **For macOS/Linux:**
   - **Bash shell:** Add to `~/.bash_profile` or `~/.bashrc`:
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - **Zsh shell:** Add to `~/.zshrc`:
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - Run `source ~/.bashrc` or `source ~/.zshrc` to apply changes

   **For Windows:**
   - Add `C:\flutter\bin` to your system PATH environment variable

3. **Verify Flutter installation:**
   ```bash
flutter doctor
   ```
   Fix any issues reported by `flutter doctor` before proceeding

4. **Ensure minimum Flutter version:**
   - This plugin requires Flutter 3.0.0 or later
   - Check your Flutter version:
     ```bash
flutter --version
     ```

#### Integrating the Flutter Plugin

1. Add the `llama_mobile_flutter_sdk` to your Flutter project's `pubspec.yaml`:
   ```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
```

2. Import the library in your Dart code:
   ```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
```

3. Initialize the SDK and load a model:
   ```dart
final llamaSdk = LlamaMobileFlutterSdk();
final config = ModelConfig(modelPath: 'path/to/model.gguf');
final success = await llamaSdk.loadModel(config);
```

4. Generate completions:
   ```dart
final generationConfig = GenerationConfig(prompt: 'Hello,');
final completion = await llamaSdk.generateCompletion(generationConfig);
print(completion);
```

5. Release resources when done:
   ```dart
await llamaSdk.release();
```

### Future Integrations (Planned)

- **ReactNative**: JavaScript/TypeScript wrapper around native modules
- **Capacitor**: Web-compatible plugin for cross-platform web apps

## Using the SDKs in New Projects

### iOS Swift SDK App

#### Step 1: Create a New iOS Project
1. Open Xcode and select "Create a new Xcode project"
2. Choose "iOS" → "App"
3. Enter your project details:
   - Product Name: `LlamaMobileDemo`
   - Team: Select your development team
   - Interface: `Storyboard` or `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 13.0` or later
4. Save the project to your desired location

#### Step 2: Add the Self-Contained SDK
1. In Xcode, right-click on your project in the Project Navigator and select "Add Files to LlamaMobileDemo..."
2. Navigate to `/path/to/llama_mobile/llama_mobile-ios-SDK/llama_mobile.xcframework`
3. Select the xcframework and ensure:
   - "Copy items if needed" is checked
   - Your target is selected under "Add to targets"
4. Click "Add"

#### Step 3: Configure Project Settings
1. Select your project in the Project Navigator
2. Go to the "Build Phases" tab
3. Under "Link Binary With Libraries", verify `llama_mobile.xcframework` is listed
4. Add required system frameworks:
   - Click the "+" button
   - Add `Metal.framework`
   - Add `MetalKit.framework`
   - Add `Accelerate.framework`

#### Step 4: Add Required Permissions
1. Open `Info.plist`
2. Add the following keys:
   - For local file access: `Privacy - File Provider Domain Usage Description`
   - For model downloads: `Privacy - Network Usage Description`

#### Step 5: Basic Usage Example

```swift
import UIKit
import llama_mobile

class ViewController: UIViewController {
    private var modelPath: String?
    private var modelHandle: UnsafeMutableRawPointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLlamaMobile()
    }
    
    func setupLlamaMobile() {
        // Initialize the library
        llama_mobile_init()
        
        // Copy a model from bundle to documents directory
        copyModelToDocuments()
    }
    
    func copyModelToDocuments() {
        guard let modelURL = Bundle.main.url(forResource: "your-model", withExtension: "gguf") else {
            print("Model not found in bundle")
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("your-model.gguf")
        
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.copyItem(at: modelURL, to: destinationURL)
                modelPath = destinationURL.path
                loadModel()
            } catch {
                print("Failed to copy model: \(error)")
            }
        } else {
            modelPath = destinationURL.path
            loadModel()
        }
    }
    
    func loadModel() {
        guard let modelPath = modelPath else { return }
        
        // Set model parameters
        var params = llama_mobile_params()
        params.n_threads = 4
        params.n_gpu_layers = 4
        
        // Load the model
        let result = llama_mobile_load_model(modelPath, &params)
        if result != nil {
            modelHandle = result
            print("Model loaded successfully")
            generateText()
        } else {
            print("Failed to load model")
        }
    }
    
    func generateText() {
        guard let modelHandle = modelHandle else { return }
        
        // Set generation parameters
        var genParams = llama_mobile_gen_params()
        genParams.max_new_tokens = 100
        genParams.temperature = 0.7
        
        // Generate text
        let prompt = "Hello, how are you?"
        var output = ""
        
        let callback: llama_mobile_token_callback = { token_ptr, user_data in
            if let token_ptr = token_ptr {
                let token = String(cString: token_ptr)
                output += token
                print(token, terminator: "")
            }
            return 0
        }
        
        llama_mobile_generate(modelHandle, prompt, &genParams, callback, nil)
        print("\nGeneration complete: \(output)")
    }
    
    deinit {
        // Cleanup
        if let modelHandle = modelHandle {
            llama_mobile_free_model(modelHandle)
        }
        llama_mobile_cleanup()
    }
}
```

### Android SDK App

#### Step 1: Create a New Android Project
1. Open Android Studio
2. Select "New Project"
3. Choose "Empty Activity"
4. Enter your project details:
   - Name: `LlamaMobileDemo`
   - Package name: `com.example.llamamobiledemo`
   - Save location: Your desired location
   - Language: `Kotlin`
   - Minimum SDK: `API 21` or later
5. Click "Finish"

#### Step 2: Add the Self-Contained SDK
1. Add the SDK as a module dependency in your Android Studio project
   - Select "File" → "New" → "Import Module"
   - Navigate to `/path/to/llama_mobile/llama_mobile-android-SDK/`
   - Click "Finish"

#### Step 3: Configure Project Settings
1. Open `app/build.gradle.kts` (or `app/build.gradle`)
2. Add the following to the `dependencies` block:
   ```gradle
   implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
   implementation("androidx.appcompat:appcompat:1.6.1")
   implementation("com.google.android.material:material:1.9.0")
   implementation("androidx.constraintlayout:constraintlayout:2.1.4")
   ```
3. Ensure the `android` block includes:
   ```gradle
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_1_8
       targetCompatibility = JavaVersion.VERSION_1_8
   }
   kotlinOptions {
       jvmTarget = "1.8"
   }
   ```
4. Sync your project with Gradle files

#### Step 4: Add Required Permissions
1. Open `app/src/main/AndroidManifest.xml`

## JSON Output Support

llama_mobile supports returning responses in an OpenAI-like JSON format. This feature is **disabled by default** for backward compatibility but can be easily enabled.

### C++ API

#### Enable JSON Output

In the C++ API, set the `use_json_response` parameter to `true` in the `llama_mobile_completion_params_t` struct:

```cpp
#include "llama_mobile_api.h"

// Initialize completion parameters
llama_mobile_completion_params_t params;
memset(&params, 0, sizeof(params));

// Set basic parameters
params.prompt = "Hello, who are you?";
params.max_tokens = 128;
params.temperature = 0.7;

// Enable JSON response format
params.use_json_response = true;

// Call the completion API
llama_mobile_completion_result_t result;
int status = llama_mobile_completion(ctx, &params, &result);

if (status == 0 && result.text) {
    // result.text contains JSON output
    printf("JSON Response: %s\n", result.text);
    llama_mobile_free_string(result.text);
}
```

#### Set Stop Sequences

Stop sequences can be configured to terminate generation when specific patterns are detected. They work with both JSON and regular text output formats:

```cpp
#include "llama_mobile_api.h"

// Initialize completion parameters
llama_mobile_completion_params_t params;
memset(&params, 0, sizeof(params));

// Set basic parameters
params.prompt = "Hello, who are you?";
params.max_tokens = 128;
params.temperature = 0.7;

// Set stop sequences
const char* stop_sequences[] = {"\n\n", "<|im_end|>", "<|endoftext|>", "\nUser:"};
params.stop_sequences = stop_sequences;
params.stop_sequence_count = 4;

// Enable JSON response format
params.use_json_response = true;

// Call the completion API
llama_mobile_completion_result_t result;
int status = llama_mobile_completion(ctx, &params, &result);

if (status == 0 && result.text) {
    // result.text contains JSON output truncated at the first stop sequence
    printf("JSON Response: %s\n", result.text);
    llama_mobile_free_string(result.text);
}
```

#### Disable JSON Output

To disable JSON output (default behavior), set the parameter to `false`:

```cpp
params.use_json_response = false;
```

### iOS SDK

#### Objective-C

```objective-c
// Create completion parameters
LlamaMobileCompletionParams *params = [[LlamaMobileCompletionParams alloc] init];
params.prompt = @"Hello, who are you?";
params.maxTokens = 128;
params.temperature = 0.7;

// Enable JSON output
params.useJsonResponse = YES;

// Call completion API
[llamaMobile completionWithContext:ctx params:params completion:^(LlamaMobileCompletionResult *result, NSError *error) {
    if (result && result.text) {
        // result.text contains JSON output
        NSLog(@"JSON Response: %@", result.text);
    }
}];
```

#### Set Stop Sequences (Objective-C)

```objective-c
// Create completion parameters
LlamaMobileCompletionParams *params = [[LlamaMobileCompletionParams alloc] init];
params.prompt = @"Hello, who are you?";
params.maxTokens = 128;
params.temperature = 0.7;

// Set stop sequences
params.stopSequences = @[@"\n\n", @"<|im_end|>", @"<|endoftext|>", @"\nUser:"];

// Enable JSON output
params.useJsonResponse = YES;

// Call completion API
[llamaMobile completionWithContext:ctx params:params completion:^(LlamaMobileCompletionResult *result, NSError *error) {
    if (result && result.text) {
        // result.text contains JSON output truncated at the first stop sequence
        NSLog(@"JSON Response: %@", result.text);
    }
}];
```

#### Swift

```swift
// Create completion parameters
var params = LlamaMobileCompletionParams()
params.prompt = "Hello, who are you?"
params.maxTokens = 128
params.temperature = 0.7

// Enable JSON output
params.useJsonResponse = true

// Call completion API
llamaMobile.completion(with: ctx, params: params) { result, error in
    if let result = result, let text = result.text {
        // text contains JSON output
        print("JSON Response: \(text)")
    }
}
```

#### Set Stop Sequences (Swift)

```swift
// Create completion parameters
var params = LlamaMobileCompletionParams()
params.prompt = "Hello, who are you?"
params.maxTokens = 128
params.temperature = 0.7

// Set stop sequences
params.stopSequences = ["\n\n", "<|im_end|>", "<|endoftext|>", "\nUser:"]

// Enable JSON output
params.useJsonResponse = true

// Call completion API
llamaMobile.completion(with: ctx, params: params) { result, error in
    if let result = result, let text = result.text {
        // text contains JSON output truncated at the first stop sequence
        print("JSON Response: \(text)")
    }
}
```

### Android SDK

```java
// Create completion parameters
CompletionParams params = new CompletionParams.Builder()
    .setPrompt("Hello, who are you?")
    .setMaxTokens(128)
    .setTemperature(0.7f)
    .setUseJsonResponse(true)  // Enable JSON output
    .build();

// Call completion API
try {
    CompletionResult result = llamaMobile.completion(ctx, params);
    if (result.getText() != null) {
        // result.getText() contains JSON output
        Log.d("LlamaMobile", "JSON Response: " + result.getText());
    }
} catch (LlamaMobileException e) {
    e.printStackTrace();
}
```

#### Set Stop Sequences (Android)

```java
// Create completion parameters with stop sequences
CompletionParams params = new CompletionParams.Builder()
    .setPrompt("Hello, who are you?")
    .setMaxTokens(128)
    .setTemperature(0.7f)
    .setStopSequences(new String[] {"\n\n", "<|im_end|>", "<|endoftext|>", "\nUser:"})
    .setUseJsonResponse(true)  // Enable JSON output
    .build();

// Call completion API
try {
    CompletionResult result = llamaMobile.completion(ctx, params);
    if (result.getText() != null) {
        // result.getText() contains JSON output truncated at the first stop sequence
        Log.d("LlamaMobile", "JSON Response: " + result.getText());
    }
} catch (LlamaMobileException e) {
    e.printStackTrace();
}
```

### JSON Output Format

When enabled, the API returns responses in this format:

```json
{
  "id": "cmpl-1234567890abcdef",
  "object": "text_completion",
  "created": 1620000000,
  "model": "your-model-name",
  "choices": [
    {
      "text": "Hello! I'm a helpful assistant...",
      "index": 0,
      "logprobs": null,
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 5,
    "completion_tokens": 15,
    "total_tokens": 20
  }
}
```

### Backward Compatibility

- **Default behavior**: JSON output is disabled by default
- **Existing code**: All existing code will continue to work without changes
- **Explicit control**: Users can enable/disable JSON output on a per-request basis
- **Performance**: JSON output has minimal performance impact

### Troubleshooting

#### JSON output is not working

1. **Check parameter spelling**: Ensure you're using `use_json_response` (C++), `useJsonResponse` (Swift/Objective-C), or `setUseJsonResponse()` (Java)

2. **Verify parameter is set**: Double-check that the parameter is being set before calling the completion API

3. **Check API version**: Ensure you're using a version of the API that supports JSON output (latest version)

4. **Inspect response**: If JSON output is enabled, the response should contain `{"id":"cmpl-` at the beginning

#### Want to enable JSON by default in your application

To enable JSON output by default in your application, simply set the parameter to `true` whenever you create completion parameters:

```cpp
// Create a helper function to create default parameters
llama_mobile_completion_params_t create_default_params(const char* prompt) {
    llama_mobile_completion_params_t params;
    memset(&params, 0, sizeof(params));
    params.prompt = prompt;
    params.max_tokens = 128;
    params.temperature = 0.7;
    params.use_json_response = true; // Enable JSON by default
    return params;
}
```

## Text-to-Speech (TTS) Support

llama_mobile provides comprehensive TTS capabilities for generating speech from text. Here's how to use the TTS APIs effectively:

### Basic TTS Workflow

1. **Load Models**: Load both the main TTS model and the vocoder model
2. **Text Formatting**: Format your text for TTS generation
3. **Token Generation**: Generate tokens from the formatted text
4. **Token Filtering**: **Important!** Filter to include only audio tokens
5. **Audio Decoding**: Decode the audio tokens to raw audio samples
6. **Save/Play Audio**: Save the audio to a WAV file or play it directly

### Important: Token Filtering

A critical step in the TTS workflow that's easy to overlook: **only send audio tokens to the decoder**.

**Audio Token Range**: 151672-155772
**Audio End Token**: 151668 `<|audio_end|>`

```cpp
// Example token filtering (from C++ example)
for (token in generated_tokens) {
    // Check if token is in audio range
    if (token >= 151672 && token <= 155772) {
        audio_tokens.push_back(token);
    }
    
    // Check for end token
    if (token == 151668) {
        break; // Found audio end token
    }
}
```

**Why this matters**: Sending non-audio tokens to the decoder will cause crashes or invalid audio output.

### Important: Batch Size Configuration

When working with TTS, you may encounter this error:
```
LM_GGML_ASSERT(cparams.n_ubatch >= n_tokens && "encoder requires n_ubatch >= n_tokens")
```

**Solution**: Increase the `nUBatch` parameter when initializing the model:

```swift
// iOS example
var initParams = LlamaMobile.InitParams(modelPath: modelPath)
initParams.nUBatch = 1024 // Increase to handle large audio token batches
```

**Why this matters**: TTS models often generate large batches of audio tokens (500-1000+), and the unbounded batch size (`nUBatch`) must be larger than or equal to the number of generated audio tokens.

### Example Implementations

- **C++**: `examples/cpp/main_tts.cpp` - Full TTS workflow with token filtering
- **iOS**: `examples/iOSSDKExample` - Swift implementation with token filtering

### Key TTS Functions

- `generateAudioFromText()`: Single-call TTS generation (handles all steps internally)
- `formatTextForAudioCompletion()`: Format text for TTS
- `getAudioCompletionGuideTokens()`: Get guide tokens for better TTS quality
- `decodeAudioTokens()`: Decode audio tokens to samples (requires filtered tokens)
- `saveAudioToWav()`: Save audio samples to WAV file

### Important: Guide Tokens

Guide tokens are a critical feature for improving TTS quality and preventing unexpected audio output. They help the model focus on generating audio for your actual text rather than template content.

**What are guide tokens?**
- Special tokens that guide the TTS model to focus on your input text
- Prevent the model from speaking template/example content
- Available through `getAudioCompletionGuideTokens()` function

**How to use guide tokens (C++ example):**
```cpp
// Get guide tokens for your text
std::vector<llama_token> guide_tokens = context.getAudioCompletionGuideTokens(text_to_speak);
// Set guide tokens before generation
context.setGuideTokens(guide_tokens);
```

**How to use guide tokens (iOS example):**
```swift
// Get guide tokens for your text
guard let guideTokens = llamaMobile.getAudioGuideTokens(textToSpeak: text) else {
    print("Failed to get guide tokens")
}
// Set guide tokens before generation
if let guideTokens = guideTokens {
    llamaMobile.setGuideTokens(tokens: guideTokens)
}
```

**Why guide tokens matter:** Without guide tokens, the model may generate audio for template content (example text included in the model) before your actual input text, resulting in "weird words" at the beginning of the audio output.

### Template-Based TTS Generation

llama_mobile uses template data to format prompts for the TTS model. These templates provide examples of how text and audio should be structured:

#### Template Components

- **`default_audio_text`**: Example text sequence with special tokens
  - Format: `<|text_start|>word1<|text_sep|>word2<|text_sep|>...<|text_sep|>`
  - Purpose: Shows the model how to structure text with separators

- **`default_audio_data`**: Example audio data with timestamps and code tokens
  - Format: `word<|t_0.08|><|code_start|>audio_token1<|audio_token2|>...<|code_end|>`
  - Purpose: Demonstrates the expected audio output format with timing and code tokens

#### Template Usage in Prompt Construction

The `getFormattedAudioCompletion()` function constructs prompts by:
1. Starting with the template text
2. Inserting your processed text in the appropriate position
3. Appending the template audio data
4. Adjusting format based on TTS version (V0_2 vs V0_3)

**Example formatted prompt:**
```
<|im_start|>
<|text_start|>example<|text_sep|>template<|text_sep|>YOUR_PROCESSED_TEXT<|text_sep|><|text_end|>
example<|t_0.08|><|code_start|><|257|><|740|>...<|code_end|>
```

#### Avoiding Template Audio in Output

**Critical issue**: Without proper handling, the model may generate audio for the template content too.

**Solutions:**
1. **Use guide tokens**: Guide the model to focus only on your text
2. **Only tokenize completion**: When templates are present, tokenize only the completion result
3. **Token filtering**: Only decode audio tokens (151672-155772) and skip template-related tokens

**Example implementation (iOS):**
```swift
// Check if prompt contains template markers
let useOnlyCompletion = formattedPrompt.contains("<|audio_start|") || formattedPrompt.contains("<|text_start|")

// Only tokenize completion result when templates are present
let contentToTokenize = useOnlyCompletion ? completionResult.text : formattedPrompt + completionResult.text
```

This ensures you only get audio for your actual text, not the template content.

## Integration Plans

The framework currently supports integration with

1. **Native Applications**: 
   - iOS apps via `llama_mobile-ios-SDK` SDK
   - Android apps via `llama_mobile-android-SDK` SDK and `llama_mobile-android-java-SDK` SDK

2. **Cross-Platform Frameworks**:
   - ✅ Flutter via Flutter plugin (`llama_mobile-flutter-SDK`)
   - ⏳ ReactNative via ReactNative SDK

3. **Web-Based Applications**:
   - Capacitor plugin for web apps using (`llama_mobile-capacitor-plugin`)

## Arm Neon Support for Android

llama_mobile fully supports Arm Neon SIMD (Single Instruction, Multiple Data) technology for Android devices, providing significant performance improvements for AI model inference on Arm-based architectures.

### Key Features

- **Default Enabled**: Neon support is automatically enabled for `arm64-v8a` builds when using the Android NDK toolchain
- **Runtime Detection**: Neon capabilities are detected at runtime using Android's `getauxval()` system call
- **Optimized Operations**: Various performance-critical operations including matrix multiplication, tensor operations, and quantization/dequantization are optimized using Neon instructions
- **AArch64 Architecture**: Neon is guaranteed to be available on all AArch64 (ARM64) devices, and the framework leverages this guarantee for optimal performance

### Neon Detection and Usage

The framework automatically detects and uses Neon capabilities:

1. **Hardware Feature Detection**: The code checks for Neon and related extensions (dotprod, fp16, i8mm) at runtime
2. **Optimized Path Selection**: For each supported operation, the fastest available implementation (Neon vs. generic) is selected
3. **Fallback Support**: In cases where specific Neon extensions are not available, the framework gracefully falls back to generic implementations

### Performance Benefits

Using Neon acceleration provides significant performance improvements:
- **2-4x faster** matrix multiplication operations
- **30-50% overall performance boost** for AI model inference
- **Reduced battery consumption** due to faster computation

### Verifying Neon Support

Neon support is automatically enabled and used by the framework. The build process includes optimized Neon code paths for all supported operations.

## iOS SDK

The iOS SDK requires precompiled Metal libraries for optimal performance. The build process handles this automatically.

```bash
# Build iOS SDK with precompiled Metal libraries
./scripts/build-ios.sh
```

### Metal Library Compilation Details

The iOS SDK relies on precompiled Metal shader libraries (`ggml-llama.metallib` for devices and `ggml-llama-sim.metallib` for simulators). These are automatically generated during the build process with:

- **Metal Language Version**: `ios-metal2.3` (compatible with iOS 13.0+)
- **Deployment Target**: iOS 14.0 (compatible with the core library requirements)

The build script (`scripts/build-ios.sh`) handles:
1. Compiling Metal shaders from `lib/llama_cpp/ggml-metal.metal`
2. Generating device and simulator-specific metallib files
3. Assembling the `llama_mobile.xcframework`
4. Copying necessary resources

### Verifying Metal Libraries

To verify the deployment target of the generated metallib files:

```bash
# Check device metallib deployment target
strings lib/llama_cpp/ggml-llama.metallib | grep -i "apple-ios"

# Check simulator metallib deployment target
strings lib/llama_cpp/ggml-llama-sim.metallib | grep -i "apple-ios"
```

### iOS Example App

To run the iOS example app:

1. Open `examples/iOSFrameworkExample/iOSFrameworkExample.xcodeproj` in Xcode
2. Select a target device or simulator
3. Build and run the project

## Future Building Instructions (Planned)

### Android Library and SDK

Before building for Android, you need to ensure your development environment is properly configured:

#### Finding SDK and NDK Paths from Android Studio

You can find your SDK and NDK paths directly from Android Studio:

1. **Open Android Studio Preferences/Settings**:
   - On macOS: Android Studio → Preferences
   - On Windows/Linux: File → Settings

2. **Find Android SDK Path**:
   - Navigate to: Appearance & Behavior → System Settings → Android SDK
   - Your SDK path is displayed at the top of the window
   - Example: `/Users/yourname/Library/Android/sdk` (macOS)

3. **Find NDK Path**:
   - Still in the Android SDK settings, select the "SDK Tools" tab
   - Check the "Show Package Details" box
   - Expand the "NDK (Side by side)" section
   - Installed NDK versions are shown with their paths
   - You can also see the overall NDK location at the top
   - Example: `/Users/yourname/Library/Android/sdk/ndk/29.0.14206865`

#### Setting ANDROID_HOME

The build script will attempt to automatically detect your Android SDK path from common locations:
- macOS: `~/Library/Android/sdk` or `~/android-sdk`
- Linux: `~/Android/Sdk`, `~/android-sdk`, or `/opt/android-sdk`
- Windows (Git Bash): `%USERPROFILE%/AppData/Local/Android/Sdk` or `%USERPROFILE%/Android/Sdk`

If automatic detection fails, set ANDROID_HOME manually:

### Temporary Setting (Current Terminal Session Only)

```bash
# On macOS/Linux

export ANDROID_HOME=/path/to/your/android/sdk
./scripts/build-android.sh

# On Windows (Git Bash)
export ANDROID_HOME=C:/path/to/your/android/sdk
./scripts/build-android.sh
```

### Permanent Setting

#### On macOS/Linux

**For Bash shell:**
1. Open `~/.bash_profile` or `~/.bashrc` in a text editor
2. Add the line: `export ANDROID_HOME=/path/to/your/android/sdk`
3. Save the file
4. Run: `source ~/.bash_profile` or `source ~/.bashrc` to apply changes

**For Zsh shell (default on macOS Catalina and later):**
1. Open `~/.zshrc` in a text editor
2. Add the line: `export ANDROID_HOME=/path/to/your/android/sdk`
3. Save the file
4. Run: `source ~/.zshrc` to apply changes

**To verify the setting:**
```bash
echo $ANDROID_HOME
```
This should display the path to your Android SDK directory.

#### Setting NDK Path

The build script uses NDK version 29.0.14206865 by default. If you need to use a different NDK version, you can specify it:

```bash
# Build Android library with a specific NDK version
./scripts/build-android.sh --ndk-version=29.0.14206865
```

#### Building Android Library

```bash
# Build Android library and SDK
./scripts/build-android.sh
```

### Flutter Plugin
```bash
# Flutter build script
./scripts/build-flutter.sh
```

### ReactNative Plugin
```bash
# Planned ReactNative build script
./scripts/build-reactnative.sh
```

### Capacitor Plugin
```bash
# Planned Capacitor build script
./scripts/build-capacitor.sh
```

## Contributing

Contributions are welcome! Please feel free to:

- Submit bug fixes
- Propose new features
- Improve documentation
- Add support for additional platforms

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) by Georgi Gerganov
- Built with inspiration from various mobile AI frameworks

## Roadmap

1. ✅ Create Flutter plugin
2. Create ReactNative plugin
3. Develop Capacitor plugin for web apps
4. Add comprehensive documentation and examples
5. Optimize performance for mobile devices
6. Expand model support and compatibility

Stay tuned for updates as we continue to develop and expand the framework!