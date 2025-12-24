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

- **llama_mobile_ios/**: iOS framework project folder
- **scripts/**: Build and utility scripts
- **CMakeLists.txt**: Build configuration for the core library

### Planned Components

- **llama_mobile_android/**: Android framework project
- **llama_mobile_flutter/**: Flutter plugin
- **llama_mobile_reactnative/**: ReactNative plugin
- **llama_mobile_capacitor/**: Capacitor plugin for web-based apps

## Build Scripts

The `scripts/` directory contains various build scripts:

- **build_and_run_lib_test.sh**: Builds the core library and tests, then runs them
- **build-ios.sh**: Builds the iOS framework based on the core library
- (Planned) **build-android.sh**: Builds the Android framework
- (Planned) **build-flutter.sh**: Builds the Flutter plugin
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
./scripts/build-ios.sh
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
- ✅ Basic test infrastructure
- ✅ Build scripts for core library and iOS

Planned development:

- ⏳ Android framework
- ⏳ Flutter plugin
- ⏳ ReactNative plugin
- ⏳ Capacitor plugin
- ⏳ Documentation and examples

## Supported Models

The framework supports various GGUF model types:

- Standard language models
- Embedding models
- Vision-Language Models (VLM)
- Multimodal models

## Integration Plans

Once completed, the framework will support integration with:

1. **Native Applications**: 
   - iOS apps via `llama_mobile_ios` framework
   - Android apps via planned Android framework

2. **Cross-Platform Frameworks**:
   - Flutter via planned Flutter plugin
   - ReactNative via planned ReactNative plugin

3. **Web-Based Applications**:
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

1. Complete Android framework development
2. Create Flutter and ReactNative plugins
3. Develop Capacitor plugin for web apps
4. Add comprehensive documentation and examples
5. Optimize performance for mobile devices
6. Expand model support and compatibility

Stay tuned for updates as we continue to develop and expand the framework!
