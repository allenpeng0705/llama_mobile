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
- Add `Sources/LlamaMobile/LlamaMobile.swift` to your Xcode project
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

### 4. Structured Output with Grammars

Use built-in grammars to constrain output format:

```swift
// Access grammars from framework bundle
if let bundlePath = Bundle.main.path(forResource: "llama_mobile", ofType: "framework", inDirectory: "Frameworks") {
    let grammarPath = bundlePath + "/grammars/json.gbnf"
    
    // Generate valid JSON output
    let jsonResult = llama.generateCompletion(
        prompt: "Generate a JSON object with name and age fields:",
        maxTokens: 128,
        temperature: 0.7,
        grammarPath: grammarPath
    )
    
    print("JSON result:", jsonResult?.text ?? "No result")
}
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

### 5. Advanced Features

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
```swift
// Generate with token callback
llama.generateCompletion(
    prompt: "Write a poem about AI:",
    maxTokens: 256,
    temperature: 0.8
) { token, isDone in
    if let token = token {
        print(token, terminator: "")
    }
    return true // Return false to stop generation
}
```

### 6. Available API Methods
The Swift wrapper provides these main functionalities:
- `init(modelPath: nGpuLayers: nCtx: nThreads:)` - Initialize with model
- `generateCompletion(prompt: maxTokens: temperature: tokenCallback:)` - Generate text
- `generateCompletion(prompt: imagePath: maxTokens: temperature: tokenCallback:)` - Multimodal generation
- `generateEmbeddings(for:)` - Generate embeddings
- `tokenize(text:)` - Tokenize text
- `detokenize(tokens:)` - Detokenize tokens
- `download(with:)` - Download models
- `speak(text:)` - Text-to-Speech conversion
- `stopGeneration()` - Stop ongoing generation

## Key Features

### Metal Support
The framework includes Metal acceleration:
- Built-in GPU support for faster inference
- Includes all necessary Metal shader files
- Enabled when `nGpuLayers > 0` in initialization

### Grammar Support
- Built-in grammars for structured output (JSON, lists, arithmetic, etc.)
- Available in `grammars/` directory within the framework bundle
- Can be used with completion parameters

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
- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+
- CMake 3.21+ (for building from source)

## Testing Tools

### Package.swift
A Swift Package Manager manifest file that enables building and testing the LlamaMobile library using SPM.

**Purpose:**
- Defines the library structure and dependencies
- Configures xcframework integration
- Sets up test targets for automated testing

**Key Features:**
```swift
// Binary target for the llama_mobile xcframework
.binaryTarget(
    name: "llama_mobile",
    path: "./llama_mobile.xcframework"
)

// Test target configuration
.testTarget(
    name: "LlamaMobileTests",
    dependencies: ["LlamaMobile"]
)
```

### run-tests.sh
A shell script that simplifies the process of running LlamaMobile iOS SDK tests.

**Purpose:**
- Automates framework availability checks
- Creates Package.swift if missing
- Runs tests with proper configuration
- Provides troubleshooting information

**Usage:**
```bash
# Make the script executable (if needed)
chmod +x run-tests.sh

# Run the tests
./run-tests.sh
```

**What the script does:**
1. Verifies the presence of `llama_mobile.xcframework`
2. Ensures Package.swift is properly configured
3. Executes tests using Swift Package Manager
4. Displays test results and helpful tips

**Output example:**
```
=== LlamaMobile iOS SDK Test Runner ===
✅ Found llama_mobile.xcframework
✅ Created Package.swift
=== Running tests ===
Note: Tests may fail because they require actual model files at specific paths
```

## Using the Testing Tools Together

The Package.swift and run-tests.sh files work together to provide a seamless testing experience:

1. **run-tests.sh** provides a user-friendly interface for test execution
2. **Package.swift** provides the technical configuration for SPM
3. Together, they eliminate the need for manual Xcode project setup

These tools are particularly useful for CI/CD pipelines and automated testing workflows.
