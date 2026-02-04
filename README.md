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
 |  ║  • Capacitor        ║   |
 |  ╚════════════════════╝   |
 |                           |
 |       🧠 📱 🚀          |
  \_________________________/
        /\
       /  \
      /____\
```

A lightweight, high-performance framework for running AI models on mobile devices, based on llama.cpp and designed for cross-platform compatibility across iOS, Android, Flutter, and web-based applications via Capacitor.

## Project Overview

llama_mobile is a mobile-first AI framework that brings the power of llama.cpp to various mobile platforms and development frameworks. The project focuses on providing native SDKs and plugins for seamless integration of large language models (LLMs) into mobile and web applications.

## Major Features

- **Local LLM Inference**: Run large language models directly on mobile devices
- **Multimodal Support**: Process images and text together
- **Text-to-Speech (TTS)**: Generate speech from text
- **LoRA Adapters**: Apply fine-tuning adapters to models
- **Embedding Generation**: Create text embeddings for semantic search
- **GGUF Format Support**: Compatible with various GGUF model types
- **Asynchronous APIs**: Simplified async integration for Flutter and Capacitor
- **Hardware Acceleration**: 
  - **iOS**: Metal shader support for optimal performance
  - **Android**: Arm Neon SIMD support for performance optimization
  - **Vulkan**: GPU acceleration on compatible Android devices

## Project Structure

```
llama_mobile/
├── core/                     # Core C++ library (based on llama.cpp)
├── llama_mobile-ios/         # iOS specific implementation
├── llama_mobile-ios-SDK/     # Native iOS SDK
├── llama_mobile-android/     # Android specific implementation
├── llama_mobile-android-SDK/ # Native Android SDK
├── llama_mobile-flutter-SDK/ # Flutter plugin
├── llama_mobile-capacitor-plugin/ # Capacitor plugin
├── scripts/                  # Build scripts for all platforms
├── Doc/                      # API documentation
│   ├── LLM_API_README.md     # LLM API documentation
│   ├── TTS_API_README.md     # TTS API documentation
│   └── DOWNLOAD_API_README.md # Model download API documentation
└── README.md                 # Project documentation
```

## Supported Platforms

### Native SDKs

- **iOS SDK**: Native iOS framework with Swift/Objective-C support
  - **Directory**: `llama_mobile-ios-SDK/`
  - **Features**: Metal shader acceleration, both sync and async APIs

- **Android SDK**: Native Android library with Kotlin/Java support
  - **Directory**: `llama_mobile-android-SDK/`
  - **Features**: Arm Neon SIMD support, Vulkan acceleration on compatible devices, both sync and async APIs

### Cross-Platform Solutions

- **Flutter Plugin**: Dart implementation for cross-platform apps
  - **Directory**: `llama_mobile-flutter-SDK/`
  - **Features**: Asynchronous APIs, iOS and Android support

- **Capacitor Plugin**: Web-based implementation for mobile web apps
  - **Directory**: `llama_mobile-capacitor-plugin/`
  - **Features**: Asynchronous APIs by default, cross-platform web compatibility

## API Documentation

Comprehensive API documentation is available in the `Doc/` directory:

- **LLM_API_README.md**: Documentation for LLM-related APIs across all platforms
- **TTS_API_README.md**: Documentation for Text-to-Speech functionality
- **DOWNLOAD_API_README.md**: Documentation for model download capabilities

## Supported Models

The framework supports various GGUF model types:

- Standard language models
- Embedding models
- Vision-Language Models (VLM)
- Multimodal models
- Text-to-Speech models

## Getting Started

### For iOS Developers

Refer to the [iOS SDK README](llama_mobile-ios-SDK/README.md) for detailed instructions on integrating the SDK into your iOS applications.

### For Android Developers

Refer to the [Android SDK README](llama_mobile-android-SDK/README.md) for detailed instructions on integrating the SDK into your Android applications.

### For Flutter Developers

Refer to the [Flutter Plugin README](llama_mobile-flutter-SDK/README.md) for detailed instructions on integrating the plugin into your Flutter applications.

### For Web Developers

Refer to the [Capacitor Plugin README](llama_mobile-capacitor-plugin/README.md) for detailed instructions on integrating the plugin into your Capacitor applications.

## Building the Project

Build scripts for all platforms are available in the `scripts/` directory. Refer to the specific platform documentation for build instructions.

## Contributing

Contributions are welcome! Please refer to the CONTRIBUTING.md files in each component directory for contribution guidelines.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Inspired by the growing ecosystem of mobile AI solutions

---

Stay tuned for updates as we continue to develop and expand the framework!
