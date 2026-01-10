# llama_mobile-android-SDK

An Android SDK that provides bindings for the llama_mobile C library, allowing Android applications to interact with llama models.

## Overview

The `llama_mobile-android-SDK` provides a Kotlin wrapper around the native llama_mobile C library, enabling Android applications to load and use llama models for text generation tasks.

## Features

- 📱 **Local inference**: Run LLMs entirely on-device without internet connectivity
- 🚀 **High performance**: Optimized for Android devices with GPU acceleration support
- 🔄 **Streaming generation**: Real-time token-by-token text generation
- 🎯 **Conversational interface**: Easy-to-use chat API with conversation history management
- 🖼️ **Multimodal support**: Process images and audio alongside text (requires compatible models)
- 📦 **LoRA adapters**: Support for lightweight model fine-tuning
- 📊 **Embeddings**: Generate text embeddings for semantic understanding
- 🎤 **Text-to-Speech**: Convert text to speech using built-in TTS capabilities
- ⚙️ **Flexible configuration**: Comprehensive parameter tuning for inference control

## Installation

### Prerequisites

- Android SDK 21 or higher
- Android NDK 25 or higher
- CMake 3.22 or higher

### Adding to Your Project

1. Clone the repository:

```bash
git clone https://github.com/yourusername/llama_mobile.git
cd llama_mobile
```

2. Build the Android library using the provided script:

```bash
./build-android.sh
```

3. Add the library as a module dependency in your Android Studio project:

```gradle
// settings.gradle
include ':llama_mobile'
project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-SDK')

// app/build.gradle
dependencies {
    implementation project(':llama_mobile')
}
```

## Usage

### Basic Example

```kotlin
import com.llamamobile.LlamaMobile

// Initialize the context
val initParams = LlamaMobile.InitParams(
    modelPath = "/sdcard/Download/llama-model.gguf",
    nCtx = 2048,      // Context size
    nGpuLayers = 4,    // Number of layers to offload to GPU
    nThreads = 8       // Number of CPU threads to use
)

val contextHandle = LlamaMobile.initContext(initParams)

if (contextHandle != 0L) {
    // Generate completion
    val completionParams = LlamaMobile.CompletionParams(
        prompt = "Hello, world!",
        temperature = 0.8f,
        maxTokens = 100
    )

    val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
    println("Result: ${result?.text}")

    // Release context when done
    LlamaMobile.releaseContext(contextHandle)
}
```

### Advanced Completion

```kotlin
// Generate completion with custom parameters
val customParams = LlamaMobile.CompletionParams(
    prompt = "Explain machine learning in simple terms",
    maxTokens = 256,
    temperature = 0.7f,
    topK = 40,
    topP = 0.95f,
    penaltyRepeat = 1.2f
)

val result = LlamaMobile.generateCompletion(contextHandle, customParams)
println("Generated text: ${result?.text}")
println("Tokens generated: ${result?.tokensGenerated}")
println("Stopped at limit: ${result?.stoppedLimit}")
```

### Multimodal Support

```kotlin
// Initialize multimodal support (for vision models)
val mmprojPath = "/sdcard/Download/mmproj-model.gguf"
if (LlamaMobile.initMultimodal(contextHandle, mmprojPath)) {
    // Generate completion with image
    val multimodalParams = LlamaMobile.CompletionParams(
        multimodalPrompt = "Describe this image",
        mediaPaths = listOf("/sdcard/Download/image.jpg"),
        maxTokens = 150
    )
    
    val result = LlamaMobile.generateCompletion(contextHandle, multimodalParams)
    println("Image description: ${result?.text}")
}
```

### Text-to-Speech

```kotlin
// Initialize vocoder for TTS
val vocoderPath = "/sdcard/Download/vocoder-model.gguf"
if (LlamaMobile.initVocoder(contextHandle, vocoderPath)) {
    // Generate audio samples from text
    val textToSpeak = "Hello, this is a test of the text-to-speech functionality"
    val audioSamples = LlamaMobile.generateAudioFromText(contextHandle, textToSpeak)
    
    // Use the audio samples with Android AudioTrack
    // ...
}
```

### Embeddings

```kotlin
// Generate embeddings for text
val text = "The quick brown fox jumps over the lazy dog"
val embeddings = LlamaMobile.generateEmbeddings(contextHandle, text)

if (embeddings != null) {
    println("Embedding dimension: ${embeddings.size}")
    println("First few values: ${embeddings.take(3).joinToString()}")
}
```

### Conversational Interface

```kotlin
// Generate response to user message
val userMessage = "What is the capital of France?"
val response = LlamaMobile.generateResponse(contextHandle, userMessage)
println("Response: ${response?.text}")

// Continue the conversation
val followUpMessage = "How big is its population?"
val followUpResponse = LlamaMobile.generateResponse(contextHandle, followUpMessage)
println("Follow-up response: ${followUpResponse?.text}")

// Clear conversation history when done
LlamaMobile.clearConversation(contextHandle)
```

### Background Threading

It's recommended to perform model loading and text generation on a background thread to avoid blocking the UI:

```kotlin
val executor = Executors.newSingleThreadExecutor()
val handler = Handler(Looper.getMainLooper())

executor.execute {
    // Load model and generate text here
    val contextHandle = LlamaMobile.initContext(initParams)
    
    if (contextHandle != 0L) {
        val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
        
        handler.post {
            // Update UI with result
            textView.text = result?.text
        }
        
        LlamaMobile.releaseContext(contextHandle)
    }
}
```

### Model Download Support

The Android SDK includes built-in functionality to download models from Hugging Face repositories directly to your application's storage:

```kotlin
import java.io.File
import java.util.concurrent.Executors
import android.os.Handler
import android.os.Looper

// Create an executor for background tasks
val executor = Executors.newSingleThreadExecutor()
val handler = Handler(Looper.getMainLooper())

// Define the local path for the downloaded model
val filesDir = context.filesDir
val modelPath = File(filesDir, "llama-2-7b-chat.Q4_K_M.gguf").absolutePath

// Create download parameters
val downloadParams = LlamaMobile.DownloadParams(
    url = "meta-llama/Llama-2-7B-Chat-GGUF",  // Hugging Face repository ID
    localPath = modelPath
)

executor.execute {
    // Download the model
    val downloadResult = LlamaMobile.downloadModel(downloadParams) { progress ->
        // Update progress on UI thread
        val progressPercentage = (progress * 100).toInt()
        handler.post {
            progressBar.progress = progressPercentage
            progressText.text = "Downloading: $progressPercentage%"
        }
    }
    
    handler.post {
        if (downloadResult?.success == true) {
            progressText.text = "Download successful!"
            
            // Now you can initialize the model using the downloaded file
            executor.execute {
                val initParams = LlamaMobile.InitParams(
                    modelPath = downloadResult.localPath,
                    nGpuLayers = 4,
                    nCtx = 2048
                )
                
                val contextHandle = LlamaMobile.initContext(initParams)
                
                if (contextHandle != 0L) {
                    val completionResult = LlamaMobile.generateCompletion(
                        contextHandle,
                        "Hello, world!",
                        maxTokens = 50
                    )
                    
                    handler.post {
                        resultText.text = completionResult?.text ?: "Failed to generate completion"
                    }
                    
                    LlamaMobile.releaseContext(contextHandle)
                }
            }
        } else {
            progressText.text = "Download failed: ${downloadResult?.errorMessage ?: "Unknown error"}"
        }
    }
}
```

### Download with Authentication

For private Hugging Face repositories, you can provide a bearer token for authentication:

```kotlin
val protectedDownloadParams = LlamaMobile.DownloadParams(
    url = "your-username/private-model-repo",  // Private Hugging Face repository ID
    localPath = modelPath,
    password = "your-hugging-face-token"  // Bearer token for authentication
)

val protectedResult = LlamaMobile.downloadModel(protectedDownloadParams)
```

### Convenience Download Method

The SDK also provides a convenience method that matches the iOS API signature for cross-platform consistency:

```kotlin
val downloadParams = LlamaMobile.DownloadParams(
    url = "meta-llama/Llama-2-7B-Chat-GGUF",
    localPath = modelPath
)

val result = LlamaMobile.download(with = downloadParams)
```

## API Reference

### LlamaMobile.InitParams

Parameters for initializing a llama context.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `modelPath` | String | Path to the llama model file (.gguf) | - |
| `nCtx` | Int | Size of the context window | 2048 |
| `chatTemplate` | String? | Chat template to use (optional) | null |
| `systemPrompt` | String? | System prompt for chat models (optional) | null |
| `nBatch` | Int | Batch size for processing | 512 |
| `nUBatch` | Int | Unbounded batch size | 512 |
| `nGpuLayers` | Int | Number of layers to offload to GPU | 0 |
| `nThreads` | Int | Number of CPU threads to use | 4 |
| `useMmap` | Boolean | Whether to use memory mapping | true |
| `useMlock` | Boolean | Whether to lock memory | false |
| `embedding` | Boolean | Whether to enable embedding generation | false |
| `poolingType` | Int | Pooling type for embeddings | 0 |
| `embdNormalize` | Int | Embedding normalization flag | 0 |
| `flashAttention` | Boolean | Whether to use flash attention | false |
| `cacheTypeK` | String? | Cache type for K values (optional) | null |
| `cacheTypeV` | String? | Cache type for V values (optional) | null |

### LlamaMobile.CompletionParams

Parameters for generating text completions.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `prompt` | String | Input prompt for text generation | - |
| `maxTokens` | Int | Maximum number of tokens to generate | 128 |
| `temperature` | Float | Temperature for sampling | 0.8f |
| `topK` | Int | Top-K sampling parameter | 40 |
| `topP` | Float | Top-P sampling parameter | 0.95f |
| `minP` | Float | Min-P sampling parameter | 0.05f |
| `typicalP` | Float | Typical-P sampling parameter | 1.0f |
| `penaltyLastN` | Int | Penalty window size | 64 |
| `penaltyRepeat` | Float | Repetition penalty | 1.1f |
| `penaltyFreq` | Float | Frequency penalty | 0.0f |
| `penaltyPresent` | Float | Presence penalty | 0.0f |
| `mirostat` | Int | Mirostat sampling parameter | 0 |
| `mirostatTau` | Float | Mirostat tau parameter | 5.0f |
| `mirostatEta` | Float | Mirostat eta parameter | 0.1f |
| `ignoreEos` | Boolean | Whether to ignore EOS token | false |
| `stopSequences` | List<String> | List of stop sequences | emptyList() |
| `grammar` | String? | Grammar string for constrained generation (optional) | null |
| `mediaPaths` | List<String> | List of media paths for multimodal input | emptyList() |

### LlamaMobile.CompletionResult

Result of a text completion generation.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | String | Generated text |
| `tokensGenerated` | Int | Number of tokens generated |
| `tokensEvaluated` | Int | Number of tokens evaluated |
| `truncated` | Boolean | Whether the generation was truncated |
| `stoppedEos` | Boolean | Whether generation stopped due to EOS token |
| `stoppedWord` | Boolean | Whether generation stopped due to stop sequence |
| `stoppedLimit` | Boolean | Whether generation stopped due to token limit |

### LlamaMobile.LoraAdapter

LoRA adapter configuration.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `path` | String | Path to the LoRA adapter file | - |
| `scale` | Float | LoRA adapter scale | 1.0f |

### LlamaMobile.ConversationResult

Result of a conversation generation.

| Parameter | Type | Description |
|-----------|------|-------------|
| `text` | String | Generated response text |
| `timeToFirstToken` | Long | Time to generate first token in milliseconds |
| `totalTime` | Long | Total generation time in milliseconds |
| `tokensGenerated` | Int | Number of tokens generated |

### LlamaMobile.DownloadParams

Parameters for downloading models or files from Hugging Face.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `url` | String | Hugging Face repository ID (e.g., "meta-llama/Llama-2-7B-Chat-GGUF") | - |
| `localPath` | String | Local path to save the downloaded file | - |
| `password` | String? | Bearer token for authentication (for private repositories) | null |
| `headers` | Map<String, String>? | Additional HTTP headers | null |

### LlamaMobile.DownloadResult

Result of a download operation.

| Parameter | Type | Description |
|-----------|------|-------------|
| `success` | Boolean | Whether the download was successful |
| `localPath` | String | Local path where the file was saved |
| `errorMessage` | String? | Error message if download failed |

### LlamaMobile.TTSModelType

Text-to-Speech model types.

- `UNKNOWN`: Unknown model type
- `OUT_ETTS_V02`: Out-ETTS v0.2 model
- `OUT_ETTS_V03`: Out-ETTS v0.3 model

### LlamaMobile Methods

#### Context Management

| Method | Description |
|--------|-------------|
| `initContext(params: InitParams): Long` | Initializes a new llama context and returns a handle |
| `releaseContext(contextHandle: Long)` | Releases the llama context and frees resources |

#### Text Generation

| Method | Description |
|--------|-------------|
| `generateCompletion(contextHandle: Long, params: CompletionParams): CompletionResult?` | Generates text completion with detailed parameters |
| `generateCompletion(contextHandle: Long, prompt: String, maxTokens: Int = 128, temperature: Float = 0.8f): CompletionResult?` | Generates text completion with simplified parameters |
| `stopCompletion(contextHandle: Long)` | Stops an ongoing completion generation |

#### Tokenization

| Method | Description |
|--------|-------------|
| `tokenize(contextHandle: Long, text: String): IntArray?` | Tokenizes a text string into token IDs |
| `detokenize(contextHandle: Long, tokens: IntArray): String?` | Detokenizes an array of token IDs back to a text string |

#### Multimodal

| Method | Description |
|--------|-------------|
| `initMultimodal(contextHandle: Long, mmprojPath: String, useGpu: Boolean = true): Boolean` | Initializes multimodal support (vision/audio) |
| `isMultimodalEnabled(contextHandle: Long): Boolean` | Checks if multimodal support is enabled |
| `supportsVision(contextHandle: Long): Boolean` | Checks if the model supports vision input |
| `supportsAudio(contextHandle: Long): Boolean` | Checks if the model supports audio input |
| `releaseMultimodal(contextHandle: Long)` | Releases multimodal resources |

#### Text-to-Speech

| Method | Description |
|--------|-------------|
| `initVocoder(contextHandle: Long, vocoderModelPath: String): Boolean` | Initializes the vocoder for text-to-speech functionality |
| `isVocoderEnabled(contextHandle: Long): Boolean` | Checks if vocoder (TTS) support is enabled |
| `getTTSType(contextHandle: Long): TTSModelType` | Gets the type of TTS model currently loaded |
| `getFormattedAudioCompletion(contextHandle: Long, speakerJson: String, textToSpeak: String): String?` | Formats text for audio completion with speaker information |
| `getAudioGuideTokens(contextHandle: Long, textToSpeak: String): IntArray?` | Gets guide tokens for audio completion |
| `decodeAudioTokens(contextHandle: Long, tokens: IntArray): FloatArray?` | Decodes audio tokens into raw audio data |
| `generateAudioFromText(contextHandle: Long, text: String, speakerJson: String = "{\"speaker\": \"default\"}"): FloatArray?` | Generates audio samples from text using TTS |
| `releaseVocoder(contextHandle: Long)` | Releases vocoder (TTS) resources |

#### LoRA Adapters

| Method | Description |
|--------|-------------|
| `applyLoraAdapters(contextHandle: Long, adapters: Array<LoraAdapter>): Boolean` | Applies LoRA adapters to the model |
| `removeLoraAdapters(contextHandle: Long)` | Removes all loaded LoRA adapters |
| `getLoadedLoraAdapters(contextHandle: Long): Array<LoraAdapter>?` | Gets the currently loaded LoRA adapters |

#### Conversation

| Method | Description |
|--------|-------------|
| `generateResponse(contextHandle: Long, userMessage: String, maxTokens: Int = 128): ConversationResult?` | Generates a response to a user message in a conversation |
| `clearConversation(contextHandle: Long)` | Clears the current conversation context |
| `isConversationActive(contextHandle: Long): Boolean` | Checks if a conversation is currently active |

#### Model Information

| Method | Description |
|--------|-------------|
| `getContextWindowSize(contextHandle: Long): Int` | Gets the size of the context window |
| `getEmbeddingDimension(contextHandle: Long): Int` | Gets the dimension of the model's embeddings |
| `getModelDescription(contextHandle: Long): String?` | Gets a description of the loaded model |
| `getModelSize(contextHandle: Long): Long` | Gets the size of the loaded model in bytes |
| `getModelParametersCount(contextHandle: Long): Long` | Gets the number of parameters in the loaded model |

#### Embeddings

| Method | Description |
|--------|-------------|
| `generateEmbeddings(contextHandle: Long, text: String): FloatArray?` | Generates embeddings for a text string |

#### Download

| Method | Description |
|--------|-------------|
| `downloadModel(params: DownloadParams, progressCallback: ((Float) -> Unit)? = null): DownloadResult?` | Downloads a model from Hugging Face repository |
| `downloadHfFile(repoId: String, filename: String, destinationPath: String, bearerToken: String? = null, offline: Boolean = false, progressCallback: ((Float) -> Unit)? = null): DownloadResult?` | Downloads a specific file from Hugging Face repository |
| `download(with params: DownloadParams): DownloadResult?` | Convenience method for downloading models, matching the iOS API signature |

## Build Instructions

### Prerequisites

- Android Studio
- Android NDK 29.0.14206865 or compatible
- CMake 3.22 or higher

### Building the Library

1. **ANDROID_HOME Configuration**:
   - The `build-android.sh` script automatically detects `ANDROID_HOME` from multiple sources:
     - Android Studio preferences (macOS/Linux)
     - Windows registry (Windows Git Bash)
     - Emulator preferences (macOS)
     - Common SDK paths based on your operating system
   
   - If auto-detection fails, you can set it manually:
     ```bash
     # macOS/Linux
     export ANDROID_HOME=/path/to/your/android/sdk
     ./build-android.sh
     
     # Windows (Git Bash)
     export ANDROID_HOME=C:/path/to/your/android/sdk
     ./build-android.sh
     ```

2. Run the build script:

```bash
./build-android.sh
```

This script will:
- Create platform-specific build directories
- Configure CMake with Android-specific flags
- Build the native libraries for arm64-v8a and x86_64 ABIs in parallel
- Copy the native libraries and Kotlin wrapper to the `llama_mobile-android-SDK` directory

### Using Script Options

The build script now includes a `--help` flag that shows all available options:

```bash
./build-android.sh --help
```

Output:
```
Usage: ./build-android.sh [OPTIONS]

Builds the llama_mobile Android library with cross-platform support.

Options:
  -h, --help              Show this help message and exit
  --abi=ABI1,ABI2         Specify which ABIs to build (default: arm64-v8a,x86_64)
  --ndk-version=VERSION   Use specific NDK version (default: 29.0.14206865)
```

### Building for Specific ABIs

You can specify the ABIs to build for using either the environment variable or the command line option:

```bash
# Using environment variable
ABIS="arm64-v8a,x86_64" ./build-android.sh

# Using command line option
./build-android.sh --abi=arm64-v8a,x86_64
```

Supported ABIs:
- `arm64-v8a` (64-bit ARM, for modern Android devices)
- `x86_64` (64-bit x86, for emulators and some devices)

### Using a Specific NDK Version

You can specify a custom NDK version to use:

```bash
# Using environment variable
NDK_VERSION=29.0.14206865 ./build-android.sh

# Using command line option
./build-android.sh --ndk-version=29.0.14206865
```

### Troubleshooting Build Issues

#### Common Problems and Solutions:

- **ANDROID_HOME not found**:
  - Run `./build-android.sh --help` for detailed configuration instructions
  - Check that Android Studio is installed with SDK
  - Try setting ANDROID_HOME manually with the full path
  - On macOS, check `~/Library/Android/sdk` exists
  - On Linux, check `~/Android/Sdk` or `/opt/android-sdk` exists
  - On Windows, check `C:\Users\<username>\AppData\Local\Android\Sdk` exists

- **NDK version mismatch**:
  - Install the required NDK version from Android Studio SDK Manager
  - Or use the `--ndk-version` flag to specify your installed version
  - Run `ls -la $ANDROID_HOME/ndk/` to see available versions

- **CMake errors**:
  - Ensure CMake 3.22+ is installed
  - On macOS: `brew install cmake`
  - On Ubuntu: `sudo apt-get install cmake`
  - On Windows: Download from [CMake website](https://cmake.org/download/)
  - Verify cmake is in your PATH: `which cmake`

- **Permission errors**:
  - Make the script executable: `chmod +x ./build-android.sh`
  - Run as normal user (not root)

- **Build failures**:
  - Check that you're in the correct directory (root of the llama_mobile repo)
  - Ensure the `lib` directory exists with the C library source code
  - Check that all required dependencies are installed

#### Environment Variables Reference:

| Variable | Description | Default |
|----------|-------------|---------|
| `ANDROID_HOME` | Path to Android SDK | Auto-detected |
| `ABIS` | ABIs to build for | `arm64-v8a,x86_64` |
| `NDK_VERSION` | Android NDK version | `29.0.14206865` |
| `ANDROID_PLATFORM` | Minimum Android API level | `android-21` |
| `CMAKE_BUILD_TYPE` | Build type | `Release` |

## Example App

An example Android app demonstrating how to use the library can be found in the `examples/androidLibExample` directory.

## Tests

The llama_mobile Android SDK includes a comprehensive test suite consisting of both unit tests and instrumented tests to ensure API correctness and reliability.

### Test Structure

The SDK uses two types of tests:

#### Unit Tests

- Located in `src/test/java/com/llamamobile/LlamaMobileUnitTests.kt`
- Run on the local JVM without requiring an Android device or emulator
- Test core functionality, parameter validation, and error handling
- Focus on pure Kotlin logic and API structure

#### Instrumented Tests

- Located in `src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt`
- Run on physical Android devices or emulators
- Test real-world behavior, device-specific functionality, and integration with Android framework
- Verify API behavior in actual runtime environment

### Running Tests

#### Using Android Studio

1. Open the `llama_mobile-android-SDK` directory in Android Studio
2. **Unit Tests**: 
   - Navigate to `LlamaMobileUnitTests.kt` in the Project view
   - Right-click and select "Run 'LlamaMobileUnitTests'"

3. **Instrumented Tests**: 
   - Connect a physical device or start an emulator
   - Navigate to `LlamaMobileInstrumentedTests.kt` in the Project view
   - Right-click and select "Run 'LlamaMobileInstrumentedTests'"

#### Using Command Line

```bash
# Navigate to the SDK directory
cd llama_mobile-android-SDK

# Run unit tests
./gradlew test

# Run instrumented tests (requires connected device/emulator)
./gradlew connectedAndroidTest
```

### Test Coverage

The test suite covers all major SDK APIs:

- **Initialization**: Context creation, parameter validation, error handling
- **Completion Generation**: Text generation, streaming, parameter combinations
- **Conversation**: Chat API, conversation history, streaming responses
- **Tokenization**: Text-to-tokens and tokens-to-text conversion
- **Embeddings**: Generating and validating embeddings
- **Multimodal**: Vision/audio input processing
- **TTS**: Text-to-speech functionality
- **LoRA Adapters**: Loading and managing adapters
- **Download**: Model downloading with progress tracking
- **Error Handling**: Graceful handling of invalid inputs and failures

### Adding New Tests

#### Unit Tests

Add new unit tests to `src/test/java/com/llamamobile/LlamaMobileUnitTests.kt`:

```kotlin
import org.junit.Test
import org.junit.Assert.*

class LlamaMobileUnitTests {
    @Test
    fun testMyNewFeature() {
        // Test implementation
        assertEquals(42, myNewFunction())
    }
}
```

#### Instrumented Tests

Add new instrumented tests to `src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt`:

```kotlin
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*

@RunWith(AndroidJUnit4::class)
class LlamaMobileInstrumentedTests {
    @Test
    fun testMyNewFeatureOnDevice() {
        val appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assertNotNull(appContext)
        // Test implementation
    }
}
```

## License

MIT License

## Troubleshooting

### Model Loading Issues

- Ensure the model file path is correct and the app has read permissions for the location.
- For Android 10+, you may need to request the `MANAGE_EXTERNAL_STORAGE` permission.

### Performance Issues

- Reduce the `nCtx` parameter to use less memory.
- Use `CacheType.NONE` to reduce memory usage at the cost of slower generation.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
