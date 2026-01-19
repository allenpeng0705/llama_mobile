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

### 3. Built-in Grammar Files

The framework includes grammar files in the `grammars/` directory that can constrain the model output to specific formats (JSON, lists, etc.). These files are automatically available to your app - **no copying required!**

**Available grammar files:**
- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

### 4. Basic Usage Example
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

### 5. Structured Output with Grammars

The framework includes grammar files in the `grammars/` directory that can constrain the model output to specific formats (JSON, lists, etc.).

**Key Concepts:**
- ✅ **No copying required**: Grammar files are built directly into the framework bundle
- ⏱️ **Loaded at generation time**: Grammars are loaded when needed, not during model initialization
- 📋 **Passed as a parameter**: Grammar content is passed to the `generateCompletion` method
- 🔄 **Reusable**: Grammar content can be loaded once and reused for multiple generations

**When to Load Grammars:**
- Grammar files are **loaded at generation time**, not when loading the model
- Load grammar files just before calling `generateCompletion` with the grammar parameter
- For optimal performance, load each grammar once and reuse it for multiple generations

**How Grammars Work:**
1. The grammar content is passed to the model during generation
2. The model uses the grammar rules to constrain its output to valid syntax
3. The result will always conform to the specified grammar format

**Available grammar files:**
- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

#### Option 1: Using Built-in Grammar Loading Methods (Recommended)

**Important:** The grammar loading methods (`loadGrammar(named:)`) are instance methods of `LlamaMobile`, which means they can only be called **after the model is initialized**.

The SDK provides convenient methods to load grammar files directly:

```swift
// Initialize the LlamaMobile instance
let llama = LlamaMobile(modelPath: "/path/to/model.gguf", nGpuLayers: 10)

// Complete workflow example: Model initialization to structured output
class LLMAgent {
    let llama: LlamaMobile?
    var jsonGrammar: String?
    var listGrammar: String?
    
    init() {
        // Step 1: Initialize the model (this loads the model into memory)
        print("Initializing model...")
        llama = LlamaMobile(modelPath: "/path/to/model.gguf", nGpuLayers: 10)
        
        if llama != nil {
            print("Model initialized successfully!")
            
            // Step 2: Pre-load commonly used grammars
            // This is optional but improves performance if grammars are reused
            loadGrammars()
        } else {
            print("Failed to initialize model")
        }
    }
    
    func loadGrammars() {
        print("Pre-loading grammars...")
        
        // Load JSON grammar for structured data output
        if let jsonGrammarContent = llama?.loadGrammar(named: "json") {
            jsonGrammar = jsonGrammarContent
            print("✓ JSON grammar loaded")
        }
        
        // Load list grammar for bullet points
        if let listGrammarContent = llama?.loadGrammar(named: "list") {
            listGrammar = listGrammarContent
            print("✓ List grammar loaded")
        }
    }
    
    func generateJSONResponse(prompt: String) -> String? {
        // Step 3: Use pre-loaded grammar during generation
        guard let jsonGrammar = jsonGrammar, let llama = llama else {
            return nil
        }
        
        print("Generating JSON response...")
        
        let result = llama.generateCompletion(
            with: CompletionParams(
                prompt: prompt,
                maxTokens: 256,
                temperature: 0.7,
                grammar: jsonGrammar
            )
        )
        
        return result?.text
    }
    
    func generateListResponse(prompt: String) -> String? {
        // Step 3: Use pre-loaded grammar during generation
        guard let listGrammar = listGrammar, let llama = llama else {
            return nil
        }
        
        print("Generating list response...")
        
        let result = llama.generateCompletion(
            with: CompletionParams(
                prompt: prompt,
                maxTokens: 256,
                temperature: 0.7,
                grammar: listGrammar
            )
        )
        
        return result?.text
    }
}

// Usage in app
do {
    // Initialize agent with model and pre-load grammars
    let agent = LLMAgent()
    
    // Generate JSON output
    if let jsonResult = agent.generateJSONResponse(prompt: "Create a JSON object with product details: name, price, category") {
        print("\nJSON Response:")
        print(jsonResult)
        // Output: {"name": "Laptop", "price": 999.99, "category": "Electronics"}
    }
    
    // Generate list output
    if let listResult = agent.generateListResponse(prompt: "Create a list of 3 healthy breakfast options") {
        print("\nList Response:")
        print(listResult)
        // Output: 1. Oatmeal with fruits and nuts
        //         2. Greek yogurt with granola
        //         3. Smoothie with spinach and berries
    }
} catch {    
    print("Error: \(error)")
}

// Option 1b: Load grammar from a custom file path
let customGrammarPath = "/path/to/custom.grammar.gbnf"
if let customGrammar = llama?.loadGrammar(from: customGrammarPath) {
    // Use the custom grammar
    let customResult = llama?.generateCompletion(
        with: CompletionParams(
            prompt: "Generate something according to custom grammar:",
            maxTokens: 128,
            temperature: 0.7,
            grammar: customGrammar
        )
    )
    
    print("Custom grammar result:", customResult?.text ?? "No result")
}
```

#### Option 2: Manual Framework Bundle Access

You can also access grammar files directly using the Bundle API:

```swift
// Access grammars from framework bundle
let frameworkBundle = Bundle(for: LlamaMobile.self)

if let grammarURL = frameworkBundle.url(forResource: "json", withExtension: "gbnf", subdirectory: "grammars") {
    do {
        let grammarContent = try String(contentsOf: grammarURL, encoding: .utf8)
        
        // Generate valid JSON output
        let jsonResult = llama?.generateCompletion(
            with: CompletionParams(
                prompt: "Generate a JSON object with name and age fields:",
                maxTokens: 128,
                temperature: 0.7,
                grammar: grammarContent
            )
        )
        
        print("JSON result:", jsonResult?.text ?? "No result")
    } catch {
        print("Error loading grammar:", error)
    }
}
```

#### Option 3: Copy Grammars to App Resources

For easier access or to modify grammars, copy them to your app's resources:

##### Manual Copy (One-time Setup)

```bash
# Copy grammar files to your project's Resources directory
mkdir -p YourProject/Resources/grammars/
cp -r llama_mobile.xcframework/ios-arm64/llama_mobile.framework/grammars/* YourProject/Resources/grammars/
```

##### Automatic Copy with Build Script

Add this build script to your Xcode project (Build Phases > New Run Script Phase):

```bash
# Build script to automatically copy grammar files during build
echo "Copying grammar files from framework to app resources..."

# Path to the framework in build products
FRAMEWORK_PATH="${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/llama_mobile.framework"

# Path to the app's resources directory
RESOURCES_PATH="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}/Resources"

# Create grammars directory if it doesn't exist
mkdir -p "${RESOURCES_PATH}/grammars"

# Copy grammar files if framework directory exists
if [ -d "${FRAMEWORK_PATH}/grammars" ]; then
    cp "${FRAMEWORK_PATH}/grammars"/*.gbnf "${RESOURCES_PATH}/grammars/"
    echo "✓ Successfully copied grammar files"
    
    # List copied files for verification
    echo "Copied grammar files:"
    ls -la "${RESOURCES_PATH}/grammars/"
else
    echo "⚠️  Grammars directory not found in framework bundle at ${FRAMEWORK_PATH}"
fi
```

Then load from your app bundle:

```swift
// Access grammars from app bundle (after copying)
if let grammarURL = Bundle.main.url(forResource: "json", withExtension: "gbnf", subdirectory: "grammars") {
    do {
        let grammarContent = try String(contentsOf: grammarURL, encoding: .utf8)
        
        // Generate with grammar constraint
        let jsonResult = llama.generateCompletion(
            prompt: "Generate a JSON object with name and age fields:",
            maxTokens: 128,
            temperature: 0.7,
            grammar: grammarContent
        )
        
        print("JSON result:", jsonResult?.text ?? "No result")
    } catch {
        print("Error loading grammar:", error)
    }
}
```

#### Available Grammars

The framework includes these grammar files:
- `json.gbnf` - Valid JSON objects and values
- `json_arr.gbnf` - Valid JSON arrays
- `arithmetic.gbnf` - Arithmetic expressions
- `c.gbnf` - C programming language syntax
- `chess.gbnf` - Chess moves notation
- `english.gbnf` - English language bias
- `japanese.gbnf` - Japanese language bias
- `list.gbnf` - Structured lists

You can also create custom grammar files following the GBNF (Gradio BNF) format.

### 6. Advanced Features

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

### 7. Available API Methods
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
- `loadGrammar(from:)` - Load grammar from file path
- `loadGrammar(named:)` - Load grammar from framework bundle

## 8. Troubleshooting

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
