# llama_mobile-android-SDK

Native Android SDK for running AI models using llama_mobile, providing Kotlin bindings for seamless integration with Android applications.

## Project Overview

The llama_mobile-android-SDK is a lightweight, high-performance library for running AI models on Android devices. It provides a Kotlin wrapper around the llama_mobile native C++ library, enabling developers to integrate large language models (LLMs) into Android applications with minimal effort.

## Features

- **Kotlin API**: Clean, modern Kotlin interface for easy integration
- **Pre-built Native Libraries**: Optimized C++ libraries with Neon SIMD support
- **Model Compatibility**: Support for various GGUF model formats
- **Multimodal Support**: Text generation, embeddings, and text-to-speech capabilities
- **Structured Output**: Built-in grammar support for JSON and other formats
- **LoRA Adapter Support**: Dynamic model fine-tuning at runtime

## Project Structure

```
llama_mobile-android-SDK/
├── src/
│   ├── main/
│   │   ├── assets/               # Grammar files for structured output
│   │   │   └── grammars/         # Various GBNF grammar definitions
│   │   ├── java/                 # Kotlin source code
│   │   │   └── com/llamamobile/
│   │   │       └── LlamaMobile.kt # Kotlin wrapper API
│   │   ├── jniLibs/              # Pre-built native libraries
│   │   │   ├── arm64-v8a/        # 64-bit ARM devices
│   │   │   │   ├── libllama_mobile.so
│   │   │   │   └── libc++_shared.so
│   │   │   └── x86_64/           # x86_64 emulators
│   │   │       ├── libllama_mobile.so
│   │   │       └── libc++_shared.so
│   │   └── AndroidManifest.xml   # Android manifest file
│   └── androidTest/              # Comprehensive instrumented tests
│       └── java/com/llamamobile/
│           └── LlamaMobileComprehensiveTests.kt
├── build.gradle                  # Gradle build configuration
├── settings.gradle               # Gradle settings
├── consumer-rules.pro            # ProGuard rules for SDK users
└── proguard-rules.pro            # ProGuard rules for the SDK itself
```

## Building

### What is "Building" the SDK?

The llama_mobile-android-SDK is a library project that packages:
- **Pre-built native libraries** (copied from `llama_mobile-android/libs/`)
- **Kotlin wrapper code** (LlamaMobile.kt)
- **Grammar files** for structured output

"Building" the SDK refers to compiling the Kotlin wrapper and packaging everything into an AAR (Android Archive) file that can be imported into Android applications. The native C++ libraries are pre-built and simply copied during this process.

### When to Build the SDK

You typically need to build the SDK:
1. To generate an AAR file for distribution
2. To verify the Kotlin wrapper compiles correctly
3. To run instrumented tests on devices/emulators

### How to Build the SDK

#### Using Android Studio

1. Open Android Studio
2. Select `File > Open` and navigate to the `llama_mobile-android-SDK` directory
3. Click `Open` to load the project as a library
4. Select `Build > Make Project` (or press Cmd+F9 on macOS, Ctrl+F9 on Windows)

#### Using the Build Script

```bash
# Navigate to the root directory
cd llama_mobile

# Rebuild the Android SDK structure
./scripts/build-android-SDK.sh
```

This script will:
1. Copy the latest pre-built native libraries from `llama_mobile-android/libs/`
2. Copy grammar files from `llama_mobile-android/grammars/`
3. Update the Android SDK structure with the latest files
4. Preserve any custom modifications in your test files

## Using the SDK in Your Android Application

There are two primary ways to use the llama_mobile-android-SDK in your project:

### Option 1: Import as a Module in Android Studio

1. **Open your Android project** in Android Studio
2. **Import the SDK as a module**:
   - Select `File > New > Import Module`
   - Navigate to the `llama_mobile-android-SDK` directory
   - Click `Finish` to import
3. **Add the dependency**:
   - Open your app's `build.gradle` file
   - In the `dependencies` block, add:
     ```gradle
     implementation project(":llama_mobile-android-SDK")
     ```
4. **Sync your project** with Gradle

### Option 2: Use the AAR File

1. **Generate the AAR file**:
   - Open the SDK project in Android Studio
   - Select `Build > Make Project`
   - Find the AAR file at `llama_mobile-android-SDK/build/outputs/aar/llama_mobile-android-SDK-debug.aar` (or release version)

2. **Add the AAR to your project**:
   - Create a `libs` directory in your app's module if it doesn't exist
   - Copy the AAR file into `app/libs/`

3. **Update your app's build.gradle**:
   ```gradle
   repositories {
       flatDir {
           dirs 'libs'
       }
   }
   
   dependencies {
       implementation(name: 'llama_mobile-android-SDK-debug', ext: 'aar')
   }
   ```

4. **Sync your project** with Gradle

### Option 3: Direct Integration (For Advanced Users)

If you prefer to integrate the components directly:

1. **Copy the native libraries**:
   - Copy `llama_mobile-android-SDK/src/main/jniLibs/` to your app's `src/main/jniLibs/`
   - This includes both `libllama_mobile.so` and the required `libc++_shared.so` (C++ standard library)

2. **Copy the grammar files**:
   - Copy `llama_mobile-android-SDK/src/main/assets/grammars/` to your app's `src/main/assets/grammars/`

3. **Copy the Kotlin wrapper**:
   - Copy `llama_mobile-android-SDK/src/main/java/com/llamamobile/LlamaMobile.kt` to your app's source directory

4. **Add required dependencies**:
   ```gradle
   dependencies {
       implementation 'androidx.core:core-ktx:1.12.0'
       implementation 'androidx.appcompat:appcompat:1.6.1'
   }
   ```

## Verifying the Integration

After integrating the SDK, you can verify it works by adding a simple test to your app:

```kotlin
import com.llamamobile.LlamaMobile

// Check if the library is properly loaded
val version = LlamaMobile.getLibraryVersion()
Log.d("LlamaMobile", "Library version: $version")
```

If you see the library version in your logs, the integration is successful!

## Basic Usage Example

Here's a simple example of using the SDK to generate text completion:

```kotlin
import com.llamamobile.LlamaMobile

// Model path on the device
val modelPath = "/sdcard/llama_mobile/models/SmolLM-360M-Instruct.Q6_K.gguf"

// Initialize model context
val initParams = LlamaMobile.InitParams(
    modelPath = modelPath,
    maxCtx = 4096,
    threads = 4
)

val context = LlamaMobile.initContext(initParams)
if (LlamaMobile.isContextValid(context)) {
    // Generate completion
    val completionParams = LlamaMobile.CompletionParams(
        prompt = "Hello, how are you?"
    )
    .setMaxTokens(50)
    .setTemperature(0.7f)
    
    val result = LlamaMobile.generateCompletion(context, completionParams)
    Log.d("LlamaMobile", "Completion: ${result.text}")
    
    // Release resources
    LlamaMobile.releaseContext(context)
}
```

## Troubleshooting

- **JDK Configuration Issues**: If you see "Invalid Gradle JDK configuration" errors, use Android Studio's embedded JDK via `File > Project Structure > SDK Location > JDK Location`
- **Native Library Loading Errors**: Ensure both `.so` files (`libllama_mobile.so` and `libc++_shared.so`) are in the correct `jniLibs` directories for your target ABIs
- **C++ Standard Library Issues**: The SDK requires `libc++_shared.so` (included in the jniLibs directories) for proper C++ standard library functionality
- **Missing Dependencies**: Double-check that all required dependencies are added to your app's build.gradle
- **Model Access Permissions**: Ensure your app has READ_EXTERNAL_STORAGE/WRITE_EXTERNAL_STORAGE permissions if accessing models from external storage

## Testing

The SDK includes comprehensive instrumented tests that run on Android devices or emulators:

### Running Tests with Android Studio (Option A - Recommended)

#### 1. Prerequisites
- Android Studio (latest version recommended)
- Android SDK with API levels 21-34
- Android device (USB debugging enabled) or emulator

#### 2. Open the SDK Project
```bash
cd llama_mobile-android-SDK
# Open this directory in Android Studio
```

#### 3. Run Instrumented Tests
1. Connect an Android device (with USB debugging enabled) or start an emulator
2. In the Project Explorer, navigate to `src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt`
3. Right-click the file → `Run 'LlamaMobileComprehensiveTests'`
4. Select the target device/emulator when prompted
5. View results in the "Run" window at the bottom

### Running Tests with Command Line (Option B)

#### 1. Prerequisites
- Android SDK with `adb` and `gradle` tools in your PATH
- Connected Android device/emulator

#### 2. Run Instrumented Tests
```bash
# Navigate to SDK directory
cd llama_mobile-android-SDK

# Ensure device/emulator is connected
adb devices

# Run all instrumented tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileComprehensiveTests"

# Run specific test method
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileComprehensiveTests.testAssetLoading"
```

### Test Configuration

The tests now use internal device storage instead of sdcard, which eliminates permission issues. The tests automatically create the following directory structure:

```
/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/
├── models/
│   ├── SmolLM-360M-Instruct.Q6_K.gguf           # Main model
│   ├── OuteTTS-0.2-500M-Q6_K.gguf               # TTS model
│   ├── Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf  # Alternative TTS model
│   ├── WavTokenizer-Large-75-F16.gguf           # Vocoder model
│   ├── SmolVLM-256M-Instruct-Q8_0.gguf          # Vision model
│   ├── mmproj-SmolVLM-256M-Instruct-Q8_0.gguf   # Multimodal projection
│   ├── embedding/
│   │   └── Qwen3-Embedding-0.6B-Q8_0.gguf       # Embedding model
│   ├── lora/
│   │   └── fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf  # LoRA adapter
│   └── img/
│       └── image.jpg                             # Test image
└── llama_mobile_test/                            # Test output directory
```

### Placing Model Files for Testing

#### Option 1: Use Android Studio Device File Explorer
1. Connect your device/emulator
2. Go to `View > Tool Windows > Device File Explorer`
3. Navigate to either:
   - **For development tests**: `/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/`
   - **For unit tests**: `/storage/emulated/0/Android/data/com.llamamobile.test/files/`
4. Create the `models` directory structure as shown above
5. Upload your model files to the appropriate locations

#### Option 2: Use ADB Command Line
```bash
# Create directory structure
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/embedding
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/lora
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/img

# Upload model files
adb push ~/Documents/models/SmolLM-360M-Instruct.Q6_K.gguf /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/
adb push ~/Documents/models/Qwen3-Embedding-0.6B-Q8_0.gguf /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/embedding/
# Upload other model files similarly
```

### Test Model Requirements

To run all tests, you'll need these model files:

| Model Type | Required File | Notes |
|------------|---------------|-------|
| Text Generation | `SmolLM-360M-Instruct.Q6_K.gguf` | Main language model |
| TTS | `OuteTTS-0.2-500M-Q6_K.gguf` | Primary TTS model |
| Vocoder | `WavTokenizer-Large-75-F16.gguf` | For TTS audio generation |
| Embeddings | `Qwen3-Embedding-0.6B-Q8_0.gguf` | For text embeddings |
| Vision | `SmolVLM-256M-Instruct-Q8_0.gguf` | For image processing |
| Multimodal | `mmproj-SmolVLM-256M-Instruct-Q8_0.gguf` | Projection for vision model |

Note: Tests will skip gracefully if some model files are missing, so you don't need all of them to run basic tests.

### Test Results

- **Instrumented Tests**: Results are in `build/reports/androidTests/connected/index.html`

## Running Tests

### From Android Studio

1. **Open the Project**
   - Launch Android Studio
   - Click `File > Open` and select the `llama_mobile-android-SDK` directory
   - Android Studio will automatically detect it as an Android project and sync with Gradle

2. **Run Comprehensive Tests**
   - Connect an Android device or start an emulator
   - Navigate to `src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt`
   - Right-click on the file and select `Run 'LlamaMobileComprehensiveTests'`
   - Or right-click on any specific test method to run just that test

### From Command Line

If you prefer to use the command line, Android Studio automatically includes a Gradle wrapper:

```bash
# Run instrumented tests (requires connected device/emulator)
./gradlew connectedAndroidTest
```

**Note:** Android Studio manages Gradle automatically, so you don't need a global Gradle installation to run tests from the IDE.

## Development Environment Setup

### Prerequisites

- **Android Studio** (latest stable version)
- **Android SDK** with API levels 21-34
- **Kotlin** (latest version compatible with your Android Studio)

### Setting Up the Project

1. **Clone the Repository**
   ```bash
   git clone https://github.com/your-username/llama_mobile.git
   cd llama_mobile
   ```

2. **Build the Android Libraries**
   ```bash
   # Build the native libraries
   ./scripts/build-android.sh
   
   # Build the Android SDK
   ./scripts/build-android-SDK.sh
   ```

3. **Open in Android Studio**
   - Launch Android Studio
   - Select `File > Open` and navigate to the `llama_mobile-android-SDK` directory
   - Click `Open` and wait for the project to sync

4. **Configure Device/Emulator**
   - Connect an Android device with USB debugging enabled
   - Or create and start an Android emulator with API level 21 or higher

5. **Upload Model Files to Emulator**
   To run tests with real models, you need to upload model files to your emulator. There are three primary ways:

   ### Drag and Drop (Easiest)
   For most files (images, PDFs, or generic data), you can simply drag the file from your computer's file explorer (Finder or Windows Explorer) and drop it directly onto the emulator screen.

   - **Location**: Files are placed in the `/sdcard/Download` folder by default
   - **Note**: If you drag an APK file, the emulator will attempt to install it instead of just saving the file

   ### Android Studio Device File Explorer (Best for Folders)
   If you need to put a file into a specific system directory or manage existing folders:

   1. In Android Studio, go to `View > Tool Windows > Device File Explorer`
   2. Select your running emulator from the dropdown at the top
   3. Navigate to the destination folder (usually `sdcard/Download` or `storage/emulated/0/`)
   4. Right-click on the folder and select `Upload...`
   5. Select the file or folder from your computer

   ### ADB Command Line (Best for Large Files/Automation)
   For large model files or entire directories:

   ```bash
   # Push a single file
   adb push ~/Documents/my_model.bin /sdcard/Download/

   # Push an entire folder
   adb push ~/Documents/my_folder /sdcard/Download/
   ```

## API Reference

### Core Classes

#### LlamaMobile
The main entry point for the SDK, providing static methods for model management and inference.

##### Initialization
```kotlin
val initParams = LlamaMobile.InitParams(
    modelPath = "/path/to/model.gguf",
    maxCtx = 4096,
    threads = 4,
    seed = 42
)

val context = LlamaMobile.initContext(initParams)
```

##### Text Generation
```kotlin
val completionParams = LlamaMobile.CompletionParams("Hello, how are you?")
    .setMaxTokens(50)
    .setTemperature(0.7f)
    .setTopP(0.9f)

val result = LlamaMobile.generateCompletion(context, completionParams)
```

##### Embeddings
```kotlin
val embedding = LlamaMobile.generateEmbedding(context, "This is a test sentence")
```

##### Text-to-Speech
```kotlin
// Initialize vocoder
LlamaMobile.initVocoder(context, "/path/to/vocoder.gguf")

// Generate audio
val audioParams = LlamaMobile.AudioParams("Hello from llama_mobile")
    .setSampleRate(48000)
    .setSpeakerId(0)
    .setSpeed(1.0f)

val audioData = LlamaMobile.generateAudioFromText(context, audioParams)
```

### Data Classes

#### InitParams
Configuration parameters for initializing a model context.

#### CompletionParams
Parameters for generating text completions.

#### AudioParams
Parameters for generating audio from text.

#### LoraAdapter
Configuration for LoRA adapters.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) - A port of Facebook's LLaMA model in C/C++
- Inspired by the need for lightweight, on-device AI solutions for mobile applications
