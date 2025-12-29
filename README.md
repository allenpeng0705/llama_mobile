# llama_mobile

A lightweight, high-performance framework for running AI models on mobile devices, based on llama.cpp and designed for cross-platform compatibility across iOS, Android, Flutter, ReactNative, and web-based applications via Capacitor.

## Project Overview

llama_mobile is a mobile-first AI framework that brings the power of llama.cpp to various mobile platforms and development frameworks. The project focuses on providing native SDKs and plugins for seamless integration of large language models (LLMs) into mobile and web applications.

## Architecture

### Core Components

- **lib/**: Main library directory containing:
  - **lib/tests/**: Tests for the C/C++ source code
  - **lib/llama_cpp/**: Core llama.cpp implementation
  - Mobile-specific adaptations and optimizations
  - Various GGUF models (normal, embedding, VLM, multimodal)

- **llama_mobile-ios/**: iOS framework project folder
- **llama_mobile-android/**: Android library project folder
- **llama_mobile-android-SDK/**: Android SDK wrapper project folder
- **llama_mobile-flutter-SDK/**: Flutter plugin project folder
- **scripts/**: Build and utility scripts
- **CMakeLists.txt**: Build configuration for the core library

### Planned Components

- **llama_mobile_reactnative/**: ReactNative plugin
- **llama_mobile_capacitor/**: Capacitor plugin for web-based apps

## Build Scripts

The project contains various build scripts:

- **build_and_run_lib_test.sh**: Builds the core library and tests, then runs them
- **build-ios.sh**: Builds the iOS framework based on the core library
- **build-android.sh**: Builds the Android library and SDK
- **build-flutter.sh**: Builds the Flutter plugin
- (Planned) **build-reactnative.sh**: Builds the ReactNative plugin

## Getting Started

### Build Core Library

```bash
# Build core library
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Build iOS Framework

```bash
# Build iOS framework
./build-ios.sh
```

### Build Android Library and SDK

```bash
# Build Android library and SDK
./build-android.sh
```

### Build and Run Tests

```bash
# Build and run tests
./scripts/build_and_run_lib_test.sh
```

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

## Integration Plans

The framework currently supports integration with:

1. **Native Applications**: 
   - iOS apps via `llama_mobile_ios` framework
   - Android apps via `llama_mobile-android` library and `llama_mobile-android-SDK` wrapper

2. **Cross-Platform Frameworks**:
   - ✅ Flutter via Flutter plugin (`llama_mobile-flutter-SDK`)
   - ⏳ ReactNative via ReactNative plugin

3. **Web-Based Applications** (Planned):
   - Capacitor plugin for web apps using native iOS/Android SDKs

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

## Building Instructions

### Prerequisites

- macOS with Xcode installed (for iOS builds)
- CMake 3.20 or later
- Python 3.x (for some utility scripts)
- iOS 13.0+ deployment target for mobile apps

### Core Library

```bash
# Build core library
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### iOS Framework

The iOS framework requires precompiled Metal libraries for optimal performance. The build process handles this automatically.

```bash
# Build iOS framework with precompiled Metal libraries
./scripts/build-ios.sh
```

#### Metal Library Compilation Details

The iOS framework relies on precompiled Metal shader libraries (`ggml-llama.metallib` for devices and `ggml-llama-sim.metallib` for simulators). These are automatically generated during the build process with:

- **Metal Language Version**: `ios-metal2.3` (compatible with iOS 13.0+)
- **Deployment Target**: iOS 14.0 (compatible with the core library requirements)

The build script (`scripts/build-ios.sh`) handles:
1. Compiling Metal shaders from `lib/llama_cpp/ggml-metal.metal`
2. Generating device and simulator-specific metallib files
3. Assembling the `llama_mobile.xcframework`
4. Copying necessary resources

#### Verifying Metal Libraries

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

### Future Building Instructions (Planned)

#### Android Framework
```bash
# Planned Android build script
./scripts/build-android.sh
```

#### Flutter Plugin
```bash
# Flutter build script
./scripts/build-flutter.sh
```

#### ReactNative Plugin
```bash
# Planned ReactNative build script
./scripts/build-reactnative.sh
```

#### Capacitor Plugin
```bash
# Planned Capacitor build script
./scripts/build-capacitor.sh
```

## Integration Guide

### iOS Integration

1. Add `llama_mobile.xcframework` to your Xcode project
2. Link against required system frameworks (Metal, MetalKit)
3. Import the framework in your code:
   ```swift
   import llama_mobile
   ```
4. Initialize the library and load models as needed

### Android Integration

1. Add the `llama_mobile-android` library as a module dependency in your Android Studio project
2. Add the following to your `settings.gradle`:
   ```gradle
   include ':llama_mobile'
   project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
   ```
3. Add the dependency to your app's `build.gradle`:
   ```gradle
   dependencies {
       implementation project(':llama_mobile')
   }
   ```
4. Import the library in your Kotlin code:
   ```kotlin
   import com.llamamobile.LlamaMobile
   ```
5. Initialize the library and load models as needed

### Flutter Integration

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

## Troubleshooting

### Metal Library Deployment Target Errors

If you encounter errors like:
```
This library is using a deployment target (0x00020008) that is not supported on this OS
```

This indicates incompatible Metal library deployment targets. The build script ensures compatibility by:
- Using `ios-metal2.3` language version (iOS 13.0+ compatible)
- Setting explicit deployment targets for both device and simulator builds

### Build Script Issues

Ensure all dependencies are installed and that you're running the scripts from the project root directory.
