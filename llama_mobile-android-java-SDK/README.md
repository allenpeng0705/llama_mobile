# Llama Mobile Android SDK (Java)

Native Android SDK for running AI models using llama_mobile, providing Java bindings for seamless integration with Android applications.

## Project Overview

The Llama Mobile Android SDK (Java) is a lightweight, high-performance library for running AI models on Android devices. It provides a Java wrapper around the llama_mobile native C++ library, enabling developers to integrate large language models (LLMs) into Android applications with minimal effort.

## Features

- **Java API**: Clean, modern Java interface for easy integration
- **Pre-built Native Libraries**: Optimized C++ libraries with Neon SIMD support
- **Model Compatibility**: Support for various GGUF model formats
- **Multimodal Support**: Text generation, embeddings, and text-to-speech capabilities
- **Structured Output**: Built-in grammar support for JSON and other formats
- **LoRA Adapter Support**: Dynamic model fine-tuning at runtime

## Project Structure

```
llama_mobile-android-java-SDK/
├── src/
│   ├── main/
│   │   ├── assets/               # Grammar files for structured output
│   │   │   └── grammars/         # Various GBNF grammar definitions
│   │   ├── java/                 # Java source code
│   │   │   └── com/llamamobile/
│   │   │       └── LlamaMobile.java # Java wrapper API
│   │   ├── jniLibs/              # Required C++ standard library
│   │   │   ├── arm64-v8a/        # 64-bit ARM devices
│   │   │   │   └── libc++_shared.so
│   │   │   └── x86_64/           # x86_64 emulators
│   │   │       └── libc++_shared.so
│   │   ├── cpp/                  # JNI implementation and CMake config
│   │   │   ├── CMakeLists.txt    # Build configuration for native libraries
│   │   │   └── llama_mobile_jni.cpp # JNI bridge code
│   │   └── AndroidManifest.xml   # Android manifest file
│   └── androidTest/              # Comprehensive instrumented tests
│       └── java/com/llamamobile/
│           ├── LlamaMobileInstrumentedTests.java
│           └── LlamaMobileComprehensiveTests.java
│   └── test/                     # Unit tests
│       └── java/com/llamamobile/
│           └── LlamaMobileUnitTests.java
├── build.gradle                  # Gradle build configuration
├── settings.gradle               # Gradle settings
├── consumer-rules.pro            # ProGuard rules for SDK users
└── proguard-rules.pro            # ProGuard rules for the SDK itself
```

## Building

### What is "Building" the SDK?

The Llama Mobile Android SDK (Java) is a library project that packages:
- **Pre-built native libraries** (copied from `llama_mobile-android/libs/`)
- **Java wrapper code** (LlamaMobile.java)
- **Grammar files** for structured output

"Building" the SDK refers to compiling the Java wrapper and packaging everything into an AAR (Android Archive) file that can be imported into Android applications. The native C++ libraries are pre-built and simply copied during this process.

### When to Build the SDK

You typically need to build the SDK:
1. To generate an AAR file for distribution
2. To verify the Java wrapper compiles correctly
3. To run instrumented tests on devices/emulators

### How to Build the SDK

#### Using Android Studio

1. Open Android Studio
2. Select `File > Open` and navigate to the `llama_mobile-android-java-SDK` directory
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

## Native Libraries

The SDK requires two native libraries:
- `libllama_mobile.so` - The main llama_mobile library
- `libc++_shared.so` - C++ standard library (included in the SDK)

These libraries are located in the `src/main/jniLibs/` directory with support for both `arm64-v8a` and `x86_64` architectures.

## Usage

```java
// Initialize the SDK
LlamaMobile.InitParams params = new LlamaMobile.InitParams();
params.setModelPath("path/to/model.gguf");
params.setNGpuLayers(10);
params.setNCtx(2048);
long context = LlamaMobile.initContext(params);

if (context != 0L) {
    // Generate text
    String prompt = "Hello, world!";
    LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams();
    completionParams.setPrompt(prompt);
    completionParams.setMaxTokens(50);
    completionParams.setTemperature(0.7f);
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(context, completionParams);
    if (result != null) {
        System.out.println(result.getText());
    }
    
    // Release resources
    LlamaMobile.releaseContext(context);
}
```

## Using the SDK in Your Android Application

There are two primary ways to use the Llama Mobile Android SDK (Java) in your project:

### Option 1: Import as a Module in Android Studio

1. **Open your Android project** in Android Studio
2. **Import the SDK as a module**:
   - Select `File > New > Import Module`
   - Navigate to the `llama_mobile-android-java-SDK` directory
   - Click `Finish` to import
3. **Add the dependency**:
   - Open your app's `build.gradle` file
   - In the `dependencies` block, add:
     ```gradle
     implementation project(":llama_mobile-android-java-SDK")
     ```
4. **Sync your project** with Gradle

### Option 2: Use the AAR File

1. **Generate the AAR file**:
   - Open the SDK project in Android Studio
   - Select `Build > Make Project`
   - Find the AAR file at `llama_mobile-android-java-SDK/build/outputs/aar/llama_mobile-android-java-SDK-debug.aar` (or release version)

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
       implementation(name: 'llama_mobile-android-java-SDK-debug', ext: 'aar')
   }
   ```

4. **Sync your project** with Gradle

### Option 3: Direct Integration (For Advanced Users)

If you prefer to integrate the components directly:

1. **Copy the native libraries**:
   - Copy `llama_mobile-android-java-SDK/src/main/jniLibs/` to your app's `src/main/jniLibs/`
   - This includes both `libllama_mobile.so` and the required `libc++_shared.so` (C++ standard library)

2. **Copy the grammar files**:
   - Copy `llama_mobile-android-java-SDK/src/main/assets/grammars/` to your app's `src/main/assets/grammars/`

3. **Copy the Java wrapper**:
   - Copy `llama_mobile-android-java-SDK/src/main/java/com/llamamobile/LlamaMobile.java` to your app's source directory

4. **Add required dependencies**:
   ```gradle
   dependencies {
       implementation 'androidx.core:core-ktx:1.12.0'
       implementation 'androidx.appcompat:appcompat:1.6.1'
   }
   ```

## Verifying the Integration

After integrating the SDK, you can verify it works by adding a simple test to your app:

```java
import com.llamamobile.LlamaMobile;

// Check if the library is properly loaded
long context = LlamaMobile.initContext(new LlamaMobile.InitParams());
if (context == 0L) {
    System.out.println("Library loaded successfully, but context initialization failed (expected without model)");
} else {
    System.out.println("Library loaded and context initialized successfully");
    LlamaMobile.releaseContext(context);
}
```

## Basic Usage Example

Here's a simple example of using the SDK to generate text completion:

```java
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.InitParams;
import com.llamamobile.LlamaMobile.CompletionParams;
import com.llamamobile.LlamaMobile.CompletionResult;

// Model path on the device
String modelPath = "/storage/emulated/0/Android/data/com.yourapp/files/models/SmolLM-360M-Instruct.Q6_K.gguf";

// Initialize model context
InitParams initParams = new InitParams();
initParams.setModelPath(modelPath);
initParams.setNCtx(4096);
initParams.setNThreads(4);

long context = LlamaMobile.initContext(initParams);
if (context != 0L) {
    // Generate completion
    CompletionParams completionParams = new CompletionParams();
    completionParams.setPrompt("Hello, how are you?");
    completionParams.setMaxTokens(50);
    completionParams.setTemperature(0.7f);
    
    CompletionResult result = LlamaMobile.generateCompletion(context, completionParams);
    if (result != null) {
        System.out.println("Completion: " + result.getText());
    }
    
    // Release resources
    LlamaMobile.releaseContext(context);
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

### Running Tests with Android Studio

#### 1. Prerequisites
- Android Studio (latest version recommended)
- Android SDK with API levels 21-34
- Android device (USB debugging enabled) or emulator

#### 2. Run Instrumented Tests
1. Connect an Android device (with USB debugging enabled) or start an emulator
2. In the Project Explorer, navigate to `src/androidTest/java/com/llamamobile/`
3. Right-click either test file → `Run 'LlamaMobileInstrumentedTests'` or `Run 'LlamaMobileComprehensiveTests'`
4. Select the target device/emulator when prompted
5. View results in the "Run" window at the bottom

### Running Tests with Command Line

#### 1. Prerequisites
- Android SDK with `adb` and `gradle` tools in your PATH
- Connected Android device/emulator

#### 2. Run Instrumented Tests
```bash
# Navigate to SDK directory
cd llama_mobile-android-java-SDK

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
/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/
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
   - **For development tests**: `/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/`
   - **For unit tests**: `/storage/emulated/0/Android/data/com.llamamobile.test/files/`
4. Create the `models` directory structure as shown above
5. Upload your model files to the appropriate locations

#### Option 2: Use ADB Command Line
```bash
# Create directory structure
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/models/embedding
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/models/lora
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/models/img

# Upload model files
adb push ~/Documents/models/SmolLM-360M-Instruct.Q6_K.gguf /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/models/
adb push ~/Documents/models/Qwen3-Embedding-0.6B-Q8_0.gguf /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-java-SDK/files/models/embedding/
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

## Development Environment Setup

### Prerequisites

- **Android Studio** (latest stable version)
- **Android SDK** with API levels 21-34
- **Java** (latest version compatible with your Android Studio)

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
   - Select `File > Open` and navigate to the `llama_mobile-android-java-SDK` directory
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
```java
InitParams initParams = new InitParams();
initParams.setModelPath("/path/to/model.gguf");
initParams.setNCtx(4096);
initParams.setNThreads(4);
initParams.setSeed(42);

long context = LlamaMobile.initContext(initParams);
```

##### Text Generation
```java
CompletionParams completionParams = new CompletionParams();
completionParams.setPrompt("Hello, how are you?");
completionParams.setMaxTokens(50);
completionParams.setTemperature(0.7f);
completionParams.setTopP(0.9f);

CompletionResult result = LlamaMobile.generateCompletion(context, completionParams);
```

##### Embeddings
```java
float[] embedding = LlamaMobile.generateEmbedding(context, "This is a test sentence");
```

##### Text-to-Speech
```java
// Initialize vocoder
LlamaMobile.initVocoder(context, "/path/to/vocoder.gguf");

// Generate audio
int[] audioData = LlamaMobile.generateAudioFromText(context, "Hello from llama_mobile");
```

### Data Classes

#### InitParams
Configuration parameters for initializing a model context.

#### CompletionParams
Parameters for generating text completions.

#### CompletionResult
Result of a text generation operation.

#### LoraAdapter
Configuration for LoRA adapters.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) - A port of Facebook's LLaMA model in C/C++
- Inspired by the need for lightweight, on-device AI solutions for mobile applications
