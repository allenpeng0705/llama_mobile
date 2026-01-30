# LlamaMobile iOS SDK

## Clean SDK Structure

```
llama_mobile-ios-SDK/
├── llama_mobile.xcframework/       # Pre-built iOS framework
│   ├── ios-arm64/                 # ARM64 device binary
│   │   └── llama_mobile.framework/
│   │       ├── Headers/           # All API headers
│   │       │   ├── llama_mobile_api.h  # Main API header
│   │       │   ├── llama_mobile_ffi.h  # FFI interface
│   │       │   └── llama_cpp/     # llama_cpp headers (including Metal)
│   │       ├── grammars/          # Grammar files for structured output
│   │       ├── Modules/           # Xcode module definition
│   │       └── llama_mobile       # Binary library
│   └── ios-arm64-simulator/       # Simulator binary (same structure)
├── Sources/
│   └── LlamaMobile/
│       └── LlamaMobile.swift      # Swift wrapper API
├── Tests/
│   └── LlamaMobileTests/          # Tests for Swift wrapper
│       └── LlamaMobileTests.swift
└── README.md                      # This documentation
```

## How to Use

### 1. Add Framework to Xcode Project
- Drag and drop `llama_mobile.xcframework` into your Xcode project
- In the target's Build Phases, ensure it's added to Link Binary With Libraries
- Set Embed & Sign in Framework, Libraries, and Embedded Content

### 2. Add Swift Wrapper
- Add `Sources/LlamaMobile/LlamaMobile.swift` to your Xcode project (Copy LlamaMobile.swift to your project source code folder)
- This provides a Swift-friendly API that wraps the C++ implementation

### 3. Basic Usage Example
```swift
import Foundation
import LlamaMobile

// Initialize with model path
let llama = LlamaMobile(modelPath: "/path/to/model.gguf", nGpuLayers: 10)

// Generate completion
let result = llama.generateCompletion(
    prompt: "Hello, how are you?",
    maxTokens: 128,
    temperature: 0.7
)

print(result?.text ?? "No result")
```

### 4. Advanced Features

#### Multimodal Support
```swift
// Generate completion with image input
let imageResult = llama.generateCompletion(
    prompt: "Describe this image:",
    imagePath: "/path/to/image.jpg",
    maxTokens: 256,
    temperature: 0.7
)
```

#### LoRA Adapter
```swift
// Initialize with LoRA adapter
let llamaWithLora = LlamaMobile(
    modelPath: "/path/to/model.gguf",
    nGpuLayers: 10,
    loraPath: "/path/to/adapter.lora"
)
```

#### Token Streaming
The iOS SDK supports real-time token streaming through callback mechanisms. This allows you to receive tokens as they're generated, enabling interactive UIs and progress tracking.

**Basic Streaming Example:**
```swift
// Generate with token callback
let result = llama.generateCompletion(
    prompt: "Write a poem about AI:",
    maxTokens: 256,
    temperature: 0.8,
    tokenCallback: { token in
        print(token, terminator: "")
        return true // Return false to stop generation
    }
)
```

**Advanced Streaming with CompletionParams:**
```swift
// Create completion parameters with token callback
let params = CompletionParams(
    prompt: "Explain quantum computing in simple terms",
    maxTokens: 256,
    temperature: 0.7,
    tokenCallback: { token in
        print("Generated token: \(token)")
        // Return true to continue, false to stop
        return true
    }
)

// Generate completion with streaming
if let result = llama.generateCompletion(with: params) {
    print("\nFinal result length: \(result.text.count) characters")
    print("Tokens generated: \(result.tokensGenerated)")
}
```

**Streaming with Early Stopping:**
```swift
var generatedText = ""
let params = CompletionParams(
    prompt: "Write a short story about a robot:",
    maxTokens: 512,
    temperature: 0.9,
    tokenCallback: { token in
        generatedText += token
        print("Current text: \(generatedText)")
        
        // Stop early if we reach a certain condition
        if generatedText.contains("The end") {
            print("\nStopping early - found ending marker")
            return false
        }
        return true
    }
)

if let result = llama.generateCompletion(with: params) {
    print("\nFinal result: \(result.text)")
}
```

**Streaming Support Across Functions:**
Streaming is available in all generation functions:
- `generateCompletion(with: params)` - via `tokenCallback` in params
- `generateOpenAICompletion(with: openAIJSON, grammar: String?)` - internally supports streaming
- `generateCompletion(prompt: String, maxTokens: Int32, temperature: Double, tokenCallback: ((String) -> Bool)?)` - direct parameter
- `generateMultimodalCompletion(with: params, mediaPaths: [String])` - supports streaming for multimodal inputs

**Callback Signature:**
The token callback has the signature `((String) -> Bool)?` where:
- `token`: The newly generated token as a string
- Return value: `true` to continue generation, `false` to stop early

**Key Features:**
- ✅ Real-time token delivery
- ✅ Early stopping capability
- ✅ Support for all generation types
- ✅ Works with both standard and OpenAI format requests
- ✅ Compatible with multimodal inputs

### 5. Initialization Methods
The iOS SDK provides multiple initialization methods to suit different use cases, all of which offer full parameter access through the `InitParams` struct.

#### 5.1 Simplified Initialization
**Basic Initialization:**
```swift
// Minimal initialization
let llama = LlamaMobile(modelPath: "/path/to/model.gguf")

// Initialization with GPU acceleration
let llama = LlamaMobile(
    modelPath: "/path/to/model.gguf",
    nGpuLayers: 10  // Offload 10 layers to GPU
)

// Initialization with custom context size and progress tracking
let llama = LlamaMobile(
    modelPath: "/path/to/model.gguf",
    nCtx: 4096,      // Larger context window
    nGpuLayers: 10,  // GPU layers
    nThreads: 8,     // CPU threads
    progressCallback: { progress in
        print("Loading: \(progress * 100)%")
    }
)
```

#### 5.2 Full Parameter Initialization
**Using InitParams for complete control:**
```swift
// Create init parameters with full configuration
var initParams = LlamaMobile.InitParams(modelPath: "/path/to/model.gguf")

// Core settings
initParams.nCtx = 4096                // Context window size
initParams.nGpuLayers = 10            // GPU layers
initParams.nThreads = 8               // CPU threads
initParams.nBatch = 1024              // Batch size
initParams.nUBatch = 1024             // Micro-batch size

// Memory management
initParams.useMmap = true             // Memory mapping for faster loading
initParams.useMlock = false           // Memory locking

// Embedding settings
initParams.embedding = true           // Enable embedding generation
initParams.poolingType = 0            // Pooling type (0=mean, 1=max, 2=cls)
initParams.embdNormalize = 1          // Normalize embeddings

// Performance settings
initParams.flashAttention = true      // Enable flash attention
initParams.cacheTypeK = "fp16"        // K cache type
initParams.cacheTypeV = "fp16"        // V cache type

// Chat settings
initParams.chatTemplate = "custom template..." // Custom chat template
initParams.systemPrompt = "You are a helpful assistant" // System prompt

// Progress tracking
initParams.progressCallback = { progress in
    print("Loading: \(progress * 100)%")
}

// Initialize with full configuration
let llama = LlamaMobile(with: initParams)
```

### 6. Completion API Methods
The SDK provides flexible completion methods for text generation, all supporting streaming and full parameter control.

#### 6.1 Simplified Completion
**Basic Text Generation:**
```swift
// Simple completion
let result = llama.generateCompletion(
    prompt: "Write a poem about AI",
    maxTokens: 256,
    temperature: 0.7
)

// Completion with streaming
let result = llama.generateCompletion(
    prompt: "Write a story about robots",
    maxTokens: 512,
    temperature: 0.8,
    tokenCallback: { token in
        print(token, terminator: "")
        return true // Return false to stop
    }
)
```

#### 6.2 Full Parameter Completion
**Using CompletionParams for complete control:**
```swift
// Create completion parameters with full configuration
var params = LlamaMobile.CompletionParams(prompt: "Write a detailed essay")

// Core generation settings
params.maxTokens = 1024        // Max tokens to generate
params.nThreads = 8            // Override thread count
params.seed = 42               // Random seed

// Sampling settings
params.temperature = 0.7       // Sampling temperature
params.topK = 40               // Top-k sampling
params.topP = 0.95             // Nucleus sampling
params.minP = 0.05             // Minimum probability
params.typicalP = 1.0          // Typical sampling

// Repetition penalties
params.penaltyLastN = 64       // Repetition penalty window
params.penaltyRepeat = 1.1     // Repetition penalty
params.penaltyFreq = 0.0       // Frequency penalty
params.penaltyPresent = 0.0    // Presence penalty

// Mirostat sampling
params.mirostat = 1            // Mirostat mode (0=disabled, 1=mirostat, 2=mirostat 2.0)
params.mirostatTau = 5.0       // Mirostat target entropy
params.mirostatEta = 0.1       // Mirostat learning rate

// Stop conditions
params.ignoreEos = false       // Ignore end-of-sequence tokens
params.stopSequences = ["\n\n", "###"] // Custom stop sequences

// Structured output
params.grammar = jsonGrammar   // Grammar for structured output

// Multimodal inputs
params.mediaPaths = ["/path/to/image.jpg"] // Image inputs

// Chat format
params.chatMessages = chatMessages // Structured chat messages
// Note: Chat template is set during initialization, not during completion

// Response format
params.useJsonResponse = true  // OpenAI-like JSON response

// Streaming
params.tokenCallback = { token in
    print(token, terminator: "")
    return true
}

// Generate with full configuration
let result = llama.generateCompletion(with: params)
```

#### 6.3 Specialized Completion Methods
**OpenAI Format Completion:**
```swift
// Generate completion from OpenAI format JSON
let openAIJSON = """
{
  "messages": [
    {"role": "system", "content": "You are a helpful assistant"},
    {"role": "user", "content": "Hello, how are you?"}
  ]
}
"""

let result = llama.generateOpenAICompletion(with: openAIJSON)
```

**Multimodal Completion:**
```swift
// Generate completion with image input
let result = llama.generateCompletion(
    prompt: "Describe this image:",
    mediaPaths: ["/path/to/image.jpg"],
    maxTokens: 256
)
```

## 7. Troubleshooting

### Model Returns the Same Input

If the model returns the same text as the input prompt (no new content generated), check these common issues:

1. **Token Generation**: Verify that `tokensGenerated > 0` in the completion result
2. **Model File**: Ensure you're using a valid, compatible `.gguf` model file
3. **Prompt Format**: Check if the model requires specific prompt formatting (e.g., chat templates)
4. **Generation Parameters**: Try adjusting `temperature`, `top_p`, and increasing `maxTokens`
5. **Debug Logs**: The SDK includes comprehensive debug logs that can help identify issues:
   - Grammar loading success/failure
   - C API status codes
   - Token generation statistics
   - Stop reason analysis

### Grammar Loading Issues

If grammar files aren't loading properly:

1. **Built-in Grammars**: Verify the grammar name exists in the built-in list (see section 6.3)
2. **File Extensions**: Don't include `.gbnf` extension when using `loadGrammar(named:)`
3. **Framework Integration**: Ensure the framework bundle is correctly integrated in Xcode
4. **Permissions**: For custom paths, check file read permissions

### Debug Logging

The SDK includes extensive debug logging that can be viewed in Xcode's console:

```
[DEBUG] Loading grammar 'json' from framework bundle: /path/to/llama_mobile.framework
[DEBUG] Found grammar file at: /path/to/llama_mobile.framework/grammars/json.gbnf
[DEBUG] ✓ Successfully loaded grammar 'json' (601 characters)
[DEBUG] Using grammar for generation
[DEBUG] Grammar preview: root ::= json_object
json_object ::= "{" ws string ":" ws value "}"
json_array ::= "[" ws value "]"...
[DEBUG] Completion C API status: 0
[DEBUG] Tokens evaluated: 10
[DEBUG] Tokens generated: 15
[DEBUG] Generation stopped because:
  - End of sequence: false
  - Stop word: false
  - Token limit: false
[DEBUG] Completion result: {"name":"John","age":30}
```

### Common Error Messages

- `[ERROR] Completion C API failed with status: X`: The underlying C API returned an error
- `[ERROR] ✗ Grammar file 'X.gbnf' not found`: Grammar file missing or incorrectly named
- `[WARNING] Generated text is identical to input prompt`: No new tokens were generated

## Key Features

### Metal Support
The framework includes Metal acceleration:
- Built-in GPU support for faster inference
- Includes all necessary Metal shader files
- Enabled when `nGpuLayers > 0` in initialization

### Grammar Support
- **Built-in grammars**: Structured output formats (JSON, lists, arithmetic, etc.) are included directly in the framework
- **No copying required**: Grammar files are embedded in the framework bundle at `grammars/` directory
- **On-demand loading**: Grammars are loaded when needed, not during model initialization
- **Simple API**: Convenient methods to load grammars by name or custom path
- **Model integration**: Grammar content is passed as a parameter to generation methods

**Key Benefits:**
- 📦 **Self-contained**: No external grammar files needed
- ⚡ **Efficient**: Only loaded when required for generation
- 🔧 **Flexible**: Can use built-in or custom grammars
- 📖 **Well-documented**: Clear methods and examples for usage

### API Compatibility
- Maintains backward compatibility with existing code
- Same Swift API as previous versions
- Works with both device and simulator

## Building

To rebuild the SDK:

```bash
# First build the framework
./scripts/build-ios-framework.sh

# Then build the SDK
./scripts/build-ios-SDK.sh
```

## Testing

### Running Tests with Xcode (Recommended)

1. **Open the Project in Xcode**
   ```bash
   cd llama_mobile-ios-SDK
   open Package.swift
   ```

2. **Select iOS Simulator Destination**
   - In Xcode's top bar, select an iOS simulator as the destination
   - Choose from available simulators like "iPhone 15" or "iPhone 15 Pro"
   - Avoid selecting "Any iOS Device" as the framework requires a simulator

3. **Run Tests**
   - Open the Test Navigator (`Cmd+6`)
   - Click the "Play" button next to "LlamaMobileTests" to run all tests
   - Or run individual test methods by clicking their play buttons
   - You can also use `Cmd+U` to run all tests in the current scheme

### What to Expect

The Xcode project is automatically configured with:
- Proper framework linking to `llama_mobile.xcframework`
- Correct iOS platform settings (iOS 15+)
- All necessary dependencies configured
- Test targets already set up and ready to run

### Test Configuration

The tests expect model files at specific paths:
```swift
struct TestPaths {
    static let modelPath = "/tmp/test/model.gguf"
    static let vocoderPath = "/tmp/test/vocoder.gguf"
    static let mmprojPath = "/tmp/test/mmproj.bin"
    static let loraPath = "/tmp/test/lora.gguf"
    static let imagePath = "/tmp/test/image.jpg"
}
```

To make tests pass:
- Place actual model files at these paths, or
- Modify `Tests/LlamaMobileTests/LlamaMobileTests.swift` to point to your model files

### Running Tests from Command Line

The LlamaMobile iOS SDK requires an iOS simulator destination to run tests, which has limitations with the Swift CLI. You can use the provided helper script:

```bash
cd llama_mobile-ios-SDK
./run-tests.sh
```

The script will:
1. Verify the framework is available
2. Ensure Package.swift is properly configured
3. Attempt to build for iOS simulator
4. Provide guidance on running tests in Xcode

### Recommended: Running Tests from Xcode

For the most reliable test experience:

1. Open the project in Xcode
2. Select an iOS simulator as the destination
3. Run the tests from the Test Navigator
4. The SDK has been configured to link properly with the xcframework

### Test Configuration

The tests have been configured to use actual model files from the project's models directory:

```swift
// Root path to models directory
static let rootPath = "/Users/shileipeng/Documents/mygithub/llama_mobile/models"

// Regular text model
static let modelPath = rootPath + "/SmolLM-360M-Instruct.Q6_K.gguf"

// TTS vocoder model
static let vocoderPath = rootPath + "/OuteTTS-0.2-500M-Q6_K.gguf"

// Multimodal projection file
static let mmprojPath = rootPath + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
```

### Available Models in Test Suite

The tests are pre-configured to use these models:
- **Text Model**: SmolLM-360M-Instruct.Q6_K.gguf (360M parameters, text generation)
- **TTS Model**: OuteTTS-0.2-500M-Q6_K.gguf (text-to-speech)
- **Vision Model**: SmolVLM-256M-Instruct-Q8_0.gguf (image understanding)

### Running Tests with Real Models

With the updated configuration, tests can now run with real models. When executed in Xcode:
1. Select an iOS simulator as the destination
2. Run the tests from the Test Navigator
3. The tests will automatically use the model files from the models directory

Note: Some tests still use temporary paths for files that aren't in the models directory (LoRA adapters, test images), but the core model files will be loaded from the proper location.

## API Reference

### Core Classes & Structs

#### `LlamaMobile`
The main class for interacting with the LlamaMobile framework.

**Initialization**:
```swift
// Basic initialization
let llama = try LlamaMobile(modelPath: "/path/to/model.gguf")

// Advanced initialization
let params = LlamaParams(
    threads: 4,
    gpuLayers: 1,
    ropeScaling: "yarn",
    ropeFactor: 1.0,
    batchSize: 512
)
let llama = try LlamaMobile(modelPath: "/path/to/model.gguf", params: params)
```

**Key Methods**:

```swift
// Text completion
generateCompletion(prompt: String, maxTokens: Int32 = 128, temperature: Double = 0.8, tokenCallback: ((String) -> Bool)? = nil) -> CompletionResult?

// Structured output with grammar
generateCompletion(prompt: String, grammarPath: String) -> CompletionResult?

// Grammar loading methods
loadGrammar(named grammarName: String) -> String?  // Load from framework bundle
loadGrammar(from grammarPath: String) -> String?   // Load from file path

// Embeddings
generateEmbeddings(for text: String) -> [Float]?

// Tokenization
tokenize(text: String) -> [Int32]?
detokenize(tokens: [Int32]) -> String?

// Multimodal
initMultimodal(mmprojPath: String, useGpu: Bool = true) -> Bool
generateCompletion(prompt: String, mediaPaths: [String]) -> CompletionResult?

// TTS
generateAudioFromText(text: String, speakerJson: String = "{\"speaker\": \"default\"}") -> [Float]?
```

#### `CompletionParams`
Parameters for text completion generation.

```swift
public struct CompletionParams {
    public var prompt: String
    public var maxTokens: Int32 = 128
    public var temperature: Double = 0.8
    public var topP: Double = 0.95
    public var topK: Int32 = 40
    public var grammarPath: String? = nil
    public var mediaPaths: [String] = []
    // ... more parameters
}
```

#### `CompletionResult`
Result of text completion generation.

```swift
public struct CompletionResult {
    public let text: String
    public let tokensGenerated: Int32
    public let tokensEvaluated: Int32
    public let truncated: Bool
    public let stoppedEos: Bool
    public let stoppedWord: Bool
    public let stoppedLimit: Bool
    // ... more fields
}
```

### API Categories

#### Text Generation
- `generateCompletion(with:)` - Generate text with full parameter control
- `generateCompletion(prompt:)` - Simplified text generation
- `stopCompletion()` - Stop ongoing generation

#### Embeddings
- `generateEmbeddings(for:)` - Generate embeddings for text

#### Tokenization
- `tokenize(text:)` - Convert text to tokens
- `detokenize(tokens:)` - Convert tokens back to text

#### Multimodal
- `initMultimodal(mmprojPath:)` - Initialize multimodal support
- `supportsVision()` - Check if vision is supported
- `supportsAudio()` - Check if audio is supported
- `releaseMultimodal()` - Release multimodal resources

#### TTS (Text-to-Speech)
- `initVocoder(vocoderModelPath:)` - Initialize TTS vocoder
- `generateAudioFromText(text:)` - Convert text to speech audio
- `getFormattedAudioCompletion(speakerJson:textToSpeak:)` - Format text for audio generation

#### LoRA Adapters
- `applyLoraAdapters(_:)` - Apply LoRA adapters to the model
- `removeLoraAdapters()` - Remove all LoRA adapters
- `getLoadedLoraAdapters()` - Get loaded LoRA adapters

#### Conversation Management
- `generateResponse(userMessage:)` - Generate a response in conversation
- `clearConversation()` - Clear conversation context
- `isConversationActive()` - Check if conversation is active

#### Model Information
- `getModelDescription()` - Get model description
- `getModelSize()` - Get model size in bytes
- `getModelParametersCount()` - Get number of model parameters
- `getContextWindowSize()` - Get context window size
- `getEmbeddingDimension()` - Get embedding dimension

## Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- CMake 3.21+ (for building from source)
- **System Dependencies** (automatically linked via xcframework):
  - Accelerate framework (for vDSP optimized operations)
  - Metal framework (for GPU acceleration)
  - C++ Standard Library (libc++ for C++ functionality)

## Troubleshooting

### Q&A

#### Q: Cannot import LlamaMobile correctly
**A:** Ensure you've added both the `llama_mobile.xcframework` to your project and copied the `LlamaMobile.swift` file to your source code folder. Verify that the framework is properly linked in Build Phases > Link Binary With Libraries and set to Embed & Sign in Framework, Libraries, and Embedded Content.

#### Q: Metal library loading errors
**A:** The framework automatically handles Metal library paths. If you encounter errors like "library not found" or "unsupported Metal language version", ensure:
- Your device/simulator is running iOS 17.0+
- The framework was built with the correct Metal version (3.1 for iOS 17+)
- The metallib files are present in the framework bundle

#### Q: Cannot load local model files
**A:** Verify the model path is correct:
- Use absolute paths to your model files
- Ensure the model format is supported (GGUF format recommended)
- Check that the model file size is appropriate for your device

#### Q: Framework bundle path issues
**A:** The SDK includes automatic bundle detection to find the framework within your app bundle. If you're still having issues, you can manually specify the framework path:
```swift
let frameworkBundle = Bundle(for: LlamaMobile.self)
print("Framework bundle path: \(frameworkBundle.bundlePath)")
```

#### Q: Build errors about missing dependencies
**A:** Ensure Xcode is using the correct iOS SDK and that you've installed all required development tools:
```bash
xcode-select --install
brew install cmake
```

#### Q: Metal performance issues
**A:** Optimize GPU usage with these tips:
- Adjust `nGpuLayers` parameter (higher values use more GPU memory but faster inference)
- Use models optimized for mobile (e.g., Q4_K to Q6_K quantization)
- Ensure your device has sufficient available memory

#### Q: Framework compatibility with iOS versions
**A:** The framework is built for iOS 17.0+ with Metal 3.1. If you need to support older iOS versions:
- Modify `build-ios-framework.sh` to set a lower deployment target
- Update the Metal compilation command to use an older Metal language version
- Note that performance may be reduced on older devices
