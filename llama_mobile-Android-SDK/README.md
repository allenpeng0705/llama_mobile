# llama_mobile Android SDK

## Clean SDK Structure

```
llama_mobile-android-SDK/
├── src/main/
│   ├── jniLibs/                   # Pre-built native libraries
│   │   ├── arm64-v8a/             # ARM64 device binary
│   │   │   └── libllama_mobile.so
│   │   └── x86_64/                # x86_64 simulator binary
│   │       └── libllama_mobile.so
│   ├── assets/
│   │   └── grammars/              # Grammar files for structured output
│   ├── java/
│   │   └── com/llamamobile/
│   │       └── LlamaMobile.kt     # Kotlin wrapper API
│   └── AndroidManifest.xml        # Android manifest file
├── src/test/                      # Unit tests (JVM)
│   └── java/com/llamamobile/
│       └── LlamaMobileUnitTests.kt
├── src/androidTest/               # Instrumented tests (device/emulator)
│   └── java/com/llamamobile/
│       └── LlamaMobileInstrumentedTests.kt
├── README.md                      # This documentation
├── build.gradle                   # Gradle build configuration
├── settings.gradle                # Gradle settings
├── consumer-rules.pro             # ProGuard rules for SDK users
└── proguard-rules.pro             # ProGuard rules for SDK itself
```

## How to Use

### 1. Add SDK to Android Studio Project

**Option A: Import as Module**
- Open your Android Studio project
- `File` → `New` → `Import Module`
- Select the `llama_mobile-android-SDK` directory
- Click `Finish` to import

**Option B: Add as Library Dependency**
```gradle
// In your app's build.gradle
implementation project(':llama_mobile-android-SDK')
```

### 2. Basic Usage Example

```kotlin
import com.llamamobile.LlamaMobile

// Initialize with model path
val params = LlamaMobile.InitParams(
    modelPath = "/sdcard/models/SmolLM-360M-Instruct.Q6_K.gguf",
    nGpuLayers = 4,
    nCtx = 2048
)

val contextHandle = LlamaMobile.initContext(params)

if (contextHandle > 0) {
    // Generate completion
    val completionParams = LlamaMobile.CompletionParams(
        prompt = "Hello, how are you?",
        maxTokens = 128,
        temperature = 0.7f
    )
    
    val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
    println(result?.text ?: "No result")
    
    // Release resources
    LlamaMobile.releaseContext(contextHandle)
}
```

### 3. Structured Output with Grammars

Use built-in grammars to constrain output format:

```kotlin
// Access grammar files from assets
val grammarAssetPath = "grammars/json.gbnf"

// Generate valid JSON output
val jsonParams = LlamaMobile.CompletionParams(
    prompt = "Generate a JSON object with name and age fields:",
    maxTokens = 128,
    temperature = 0.7f,
    grammar = grammarAssetPath
)

val jsonResult = LlamaMobile.generateCompletion(contextHandle, jsonParams)
println("JSON result: ${jsonResult?.text}")
```

Available grammars:
- `json.gbnf` - Valid JSON output
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming code
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

### 4. Advanced Features

#### Multimodal Support
```kotlin
// Initialize multimodal with projection file
val mmprojPath = "/sdcard/models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
if (LlamaMobile.initMultimodal(contextHandle, mmprojPath)) {
    // Generate completion with image input
    val imagePath = "/sdcard/images/cat.jpg"
    val multimodalParams = LlamaMobile.CompletionParams(
        prompt = "What's in this image?",
        mediaPaths = listOf(imagePath),
        maxTokens = 256
    )
    
    val imageResult = LlamaMobile.generateCompletion(contextHandle, multimodalParams)
    println(imageResult?.text)
}
```

#### LoRA Adapter
```kotlin
// Apply LoRA adapter
val loraAdapter = LlamaMobile.LoraAdapter(
    path = "/sdcard/models/fine-tuned-smolLM2-360M.gguf",
    scale = 1.0f
)

if (LlamaMobile.applyLoraAdapters(contextHandle, arrayOf(loraAdapter))) {
    // Generate completion with LoRA applied
    val loraResult = LlamaMobile.generateCompletion(
        contextHandle,
        "Explain quantum physics:",
        maxTokens = 128
    )
    println(loraResult?.text)
    
    // Remove adapter when done
    LlamaMobile.removeLoraAdapters(contextHandle)
}
```

#### Text-to-Speech
```kotlin
// Initialize TTS vocoder
val vocoderPath = "/sdcard/models/WavTokenizer-Large-75-F16.gguf"
if (LlamaMobile.initVocoder(contextHandle, vocoderPath)) {
    // Generate audio from text
    val audioSamples = LlamaMobile.generateAudioFromText(
        contextHandle,
        "Hello, this is LlamaMobile TTS test"
    )
    
    // Process audio samples (save to file, play, etc.)
    if (audioSamples != null) {
        println("Generated ${audioSamples.size} audio samples")
    }
    
    // Release vocoder resources
    LlamaMobile.releaseVocoder(contextHandle)
}
```

## Testing

The SDK includes two types of tests:
- **Unit Tests**: Run on local JVM (`src/test/`)
- **Instrumented Tests**: Run on Android device/emulator (`src/androidTest/`)

### Running Tests with Android Studio (Option A - Recommended)

#### 1. Prerequisites
- Android Studio (latest version recommended)
- Android SDK with API levels 21-34
- For instrumented tests: Android device (USB debugging enabled) or emulator

#### 2. Open the SDK Project
```bash
cd llama_mobile-android-SDK
# Open this directory in Android Studio
```

#### 3. Run Unit Tests
1. In the Project Explorer, navigate to `src/test/java/com/llamamobile/LlamaMobileUnitTests.kt`
2. Right-click the file → `Run 'LlamaMobileUnitTests'`
3. Or right-click individual test methods → `Run 'testMethodName'`
4. View results in the "Run" window at the bottom

#### 4. Run Instrumented Tests
1. Connect an Android device (with USB debugging enabled) or start an emulator
2. In the Project Explorer, navigate to `src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt`
3. Right-click the file → `Run 'LlamaMobileInstrumentedTests'`
4. Select the target device/emulator when prompted
5. View results in the "Run" window

### Running Tests with Command Line (Option B)

#### 1. Prerequisites
- Android SDK with `adb` and `gradle` tools in your PATH
- For instrumented tests: Connected Android device/emulator

#### 2. Run Unit Tests (JVM)
```bash
# Navigate to SDK directory
cd llama_mobile-android-SDK

# Run all unit tests
./gradlew test

# Run specific test class
./gradlew test --tests "com.llamamobile.LlamaMobileUnitTests"

# Run specific test method
./gradlew test --tests "com.llamamobile.LlamaMobileUnitTests.testInitParamsConstructors"
```

#### 3. Run Instrumented Tests
```bash
# Navigate to SDK directory
cd llama_mobile-android-SDK

# Ensure device/emulator is connected
adb devices

# Run all instrumented tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileInstrumentedTests"

# Run specific test method
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileInstrumentedTests.testAssetLoading"
```

### Test Configuration

The tests expect model files at these paths:

```kotlin
// In LlamaMobileUnitTests.kt and LlamaMobileInstrumentedTests.kt
companion object TestPaths {
    // Regular text model
    const val modelPath = "/sdcard/llama_mobile/models/SmolLM-360M-Instruct.Q6_K.gguf"
    
    // TTS models
    const val ttsModelPath = "/sdcard/llama_mobile/models/OuteTTS-0.2-500M-Q6_K.gguf"
    const val vocoderPath = "/sdcard/llama_mobile/models/WavTokenizer-Large-75-F16.gguf"
    
    // Embedding model
    const val embeddingPath = "/sdcard/llama_mobile/models/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf"
    
    // Multimodal projection file
    const val mmprojPath = "/sdcard/llama_mobile/models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
    
    // Vision model
    const val imageModelPath = "/sdcard/llama_mobile/models/SmolVLM-256M-Instruct-Q8_0.gguf"
    
    // Test image
    const val imagePath = "/sdcard/llama_mobile/models/img/image.jpg"
}
```

### Test Results

- **Unit Tests**: Results are in `build/reports/tests/testDebugUnitTest/index.html`
- **Instrumented Tests**: Results are in `build/reports/androidTests/connected/index.html`

## Building

To rebuild the SDK:

```bash
# Build the Android libraries first
./scripts/build-android-lib.sh

# Then build the SDK
./scripts/build-android-SDK.sh
```

## Key Features

### GPU Acceleration
- Built-in GPU support via Vulkan
- Enabled when `nGpuLayers > 0` in initialization
- Supports both device and emulator (with limitations)

### Grammar Support
- Built-in grammars for structured output (JSON, lists, arithmetic, etc.)
- Available in `assets/grammars/` directory
- Can be used with completion parameters

### API Compatibility
- Consistent Kotlin API across Android versions
- Same core functionality as iOS SDK
- Works with both device and emulator

## Requirements
- Android API level 21+ (Android 5.0+)
- Kotlin 1.8+
- Gradle 7.0+
- Android Studio Flamingo+ (2022.2.1+)