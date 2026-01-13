# llama_mobile iOS SDK

A lightweight, high-performance iOS SDK for running large language models (LLMs) locally on iOS devices, based on llama.cpp.

## SDK Type

llama_mobile iOS SDK is a **dynamic library** distributed as an XCFramework. This means:

### Dynamic Library vs Static Library

| Feature | Static Library | Dynamic Library |
|---------|----------------|-----------------|
| Linking | Linked at compile time | Loaded at runtime |
| File Size | Increases app binary size | Does not increase app binary size |
| Updates | Requires app update to change | Can be updated independently (rare on iOS) |
| Memory Usage | Duplicated if used by multiple apps | Shared between apps (not applicable on iOS due to sandboxing) |
| Loading Time | Slightly faster app launch | Slightly slower app launch (negligible for most cases) |

On iOS, dynamic libraries offer several advantages:
- Smaller app binary size as the library code is not embedded
- Better code isolation and security
- Support for platform-specific optimizations like Metal acceleration

## Features

- 📱 **Local inference**: Run LLMs entirely on-device without internet connectivity
- 🚀 **High performance**: Optimized for Apple Silicon with Metal acceleration support
- 🔄 **Streaming generation**: Real-time token-by-token text generation
- 🎯 **Conversational interface**: Easy-to-use chat API with conversation history management
- 🖼️ **Multimodal support**: Process images and audio alongside text (requires compatible models)
- 📦 **LoRA adapters**: Support for lightweight model fine-tuning
- 📊 **Embeddings**: Generate text embeddings for semantic understanding

## Integration

### Option 1: Using Swift Package Manager (Recommended)

1. In Xcode, go to **File** > **Add Package Dependencies**
2. Enter the path to the `llama_mobile-ios-SDK` directory
3. Select the package and add it to your target

### Option 2: Using the pre-built xcframework

1. Add `llama_mobile.xcframework` to your Xcode project:
   - Drag and drop `llama_mobile.xcframework` into your project navigator
   - Ensure "Copy items if needed" is selected
   - Add to your target's "Frameworks, Libraries, and Embedded Content"

2. Import the framework in your Swift/Objective-C code:

   ```swift
   import llama_mobile
   ```

   ```objective-c
   #import <llama_mobile/llama_mobile_api.h>
   ```

### Option 3: Building from source

1. Run the build script:
   ```bash
   ./scripts/build-ios.sh
   ```

2. The built xcframework will be available at `llama_mobile-ios-SDK/llama_mobile.xcframework`

## API Usage

### Swift API (Recommended)

The Swift API provides a more idiomatic and type-safe interface to the llama_mobile framework:

#### Initialization

```swift
import llama_mobile
import LlamaMobile

// Create a LlamaMobile instance with minimal parameters
let modelPath = "/path/to/model.gguf"
guard let llama = LlamaMobile(with: .init(modelPath: modelPath, nGpuLayers: 4, nCtx: 2048)) else {
    print("Failed to initialize model")
    return
}

// Or with custom parameters
let params = LlamaMobile.InitParams(
    modelPath: modelPath,
    nCtx: 4096,
    nGpuLayers: 10,
    nThreads: 8,
    useMmap: true,
    flashAttention: true
)

guard let llama = LlamaMobile(with: params) else {
    print("Failed to initialize model")
    return
}
```

#### Text Completion

```swift
// Generate completion with default parameters
let prompt = "Once upon a time"
if let result = llama.generateCompletion(prompt: prompt, maxTokens: 100) {
    print("Generated text: \(result.text)")
    print("Tokens generated: \(result.tokensGenerated)")
}

// Generate completion with streaming tokens
let streamingParams = LlamaMobile.CompletionParams(prompt: "Explain quantum computing in simple terms")
if let result = llama.generateCompletion(with: streamingParams) {
    print("Final result: \(result.text)")
}
```

#### Multimodal Support

```swift
// Initialize multimodal support (for vision models)
let mmprojPath = "/path/to/mmproj-model.gguf"
if llama.initMultimodal(mmprojPath: mmprojPath) {
    // Generate completion with image
    let multimodalParams = LlamaMobile.CompletionParams(
        multimodalPrompt: "Describe this image",
        mediaPaths: ["/path/to/image.jpg"]
    )
    
    if let result = llama.generateCompletion(with: multimodalParams) {
        print("Image description: \(result.text)")
    }
}
```

#### Model Download Support

The iOS SDK includes built-in functionality to download models from Hugging Face repositories directly to your application's storage:

```swift
// Create a download task with progress tracking
let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
let modelPath = documentsDir.appendingPathComponent("llama-2-7b-chat.Q4_K_M.gguf").path

let downloadParams = LlamaMobile.DownloadParams(
    url: "meta-llama/Llama-2-7B-Chat-GGUF",  // Hugging Face repository ID
    localPath: modelPath,
    progressCallback: { progress in
        print("Download progress: \(Int(progress * 100))%")
    }
)

// Create a LlamaMobile instance (needed for download functionality)
let llama = LlamaMobile(modelPath: "/tmp/placeholder.gguf") // Placeholder path, model won't be loaded

// Download the model
let downloadResult = llama.download(with: downloadParams)

if downloadResult.success {
    print("Model downloaded successfully to: \(downloadResult.localPath)")
    
    // Now you can initialize the model using the downloaded file
    let params = LlamaMobile.InitParams(modelPath: downloadResult.localPath, nGpuLayers: 4, nCtx: 2048)
    if let downloadedLlama = LlamaMobile(with: params) {
        // Use the downloaded model
        let completion = downloadedLlama.generateCompletion(prompt: "Hello, world!")
        print(completion?.text ?? "Failed to generate completion")
    }
} else {
    print("Download failed: \(downloadResult.errorMessage ?? "Unknown error")")
}
```

#### Download with Authentication

```swift
// Download from a protected Hugging Face repository
let protectedDownloadParams = LlamaMobile.DownloadParams(
    url: "your-username/private-model-repo",  // Private Hugging Face repository ID
    localPath: modelPath,
    password: "your-hugging-face-token"  // Bearer token for authentication
)

let protectedResult = llama.download(with: protectedDownloadParams)
```

### C API (For Advanced Users)

The C API provides direct access to the underlying functionality:

#### Initialization

Initialize the model with a path to your GGUF model file:

```c
#include <llama_mobile/llama_mobile_api.h>

// Simple initialization
llama_mobile_context_t ctx = llama_mobile_init_simple(
    "/path/to/model.gguf",  // Path to model file
    2048,                    // Context window size
    0,                       // GPU layers (0 to disable GPU)
    4,                       // Number of threads
    NULL                     // Progress callback
);

if (ctx == NULL) {
    printf("Failed to initialize model\n");
    return 1;
}

// Advanced initialization with custom parameters
llama_mobile_init_params_t params = {
    .model_path = "/path/to/model.gguf",
    .n_ctx = 4096,
    .n_gpu_layers = 10,
    .n_threads = 4,
    .temperature = 0.8,
    .top_k = 40,
    .top_p = 0.95
};

llama_mobile_context_t ctx = llama_mobile_init(&params);
```

### Text Completion

Generate text completions from a prompt:

```c
// Simple completion
llama_mobile_completion_result_t result;
int status = llama_mobile_completion_simple(
    ctx,
    "Once upon a time",
    100,          // Max tokens
    0.8,          // Temperature
    NULL,         // Token callback
    &result
);

if (status == 0) {
    printf("Generated: %s\n", result.text);
    printf("Tokens generated: %d\n", result.tokens_generated);
    
    // Free the result when done
    llama_mobile_free_completion_result(&result);
    llama_mobile_free_string(result.text);
}

// Advanced completion with streaming
bool token_callback(const char* token) {
    printf("%s", token);
    fflush(stdout);
    return true; // Return false to stop generation
}

llama_mobile_completion_params_t completion_params = {
    .prompt = "Explain quantum computing in simple terms",
    .max_tokens = 200,
    .temperature = 0.7,
    .top_k = 50,
    .top_p = 0.9,
    .stop_sequences = (const char*[]) {"\n\n"},
    .stop_sequence_count = 1,
    .token_callback = token_callback
};

llama_mobile_completion_result_t result;
int status = llama_mobile_completion(ctx, &completion_params, &result);
```

### Conversational Interface

Maintain conversation context for natural back-and-forth interactions:

```c
// Generate a response in conversation context
llama_mobile_conversation_result_t conv_result;
int status = llama_mobile_generate_response_simple(
    ctx,
    "Hello, how are you?",
    100,          // Max tokens
    &conv_result
);

if (status == 0) {
    printf("Response: %s\n", conv_result.text);
    printf("Time to first token: %lld ms\n", conv_result.time_to_first_token);
    printf("Total time: %lld ms\n", conv_result.total_time);
    
    // Free resources
    llama_mobile_free_string(conv_result.text);
}

// Continue the conversation
status = llama_mobile_generate_response_simple(
    ctx,
    "Tell me about yourself",
    150,
    &conv_result
);

// Clear conversation history when done
llama_mobile_clear_conversation(ctx);
```

### Multimodal Support

Process images alongside text (requires compatible multimodal models):

```c
// Initialize multimodal support
int status = llama_mobile_init_multimodal_simple(
    ctx,
    "/path/to/mmproj-model.gguf"  // Path to multimodal projection file
);

if (status == 0) {
    // Generate completion with image
    const char* media_paths[] = {
        "/path/to/image.jpg"
    };
    
    llama_mobile_completion_params_t params = {
        .prompt = "Describe this image: <image>",
        .max_tokens = 150,
        .temperature = 0.7
    };
    
    llama_mobile_completion_result_t result;
    status = llama_mobile_multimodal_completion(
        ctx, &params, media_paths, 1, &result
    );
    
    if (status == 0) {
        printf("Image description: %s\n", result.text);
        llama_mobile_free_completion_result(&result);
        llama_mobile_free_string(result.text);
    }
}

// Release multimodal resources when done
llama_mobile_release_multimodal(ctx);
```

### Embeddings

Generate text embeddings for semantic understanding:

```c
llama_mobile_float_array_t embedding = llama_mobile_embedding(
    ctx,
    "The quick brown fox jumps over the lazy dog"
);

if (embedding.count > 0) {
    printf("Embedding dimension: %d\n", embedding.count);
    printf("First few values: %f, %f, %f\n", 
           embedding.values[0], embedding.values[1], embedding.values[2]);
    
    // Free embedding when done
    llama_mobile_free_float_array(embedding);
}
```

### Cleanup

Always free resources when done:

```c
llama_mobile_free(ctx);
```

## Key API Functions

### Context Management
- `llama_mobile_init()` - Initialize model with detailed parameters
- `llama_mobile_init_simple()` - Simple model initialization with defaults
- `llama_mobile_free()` - Free all model resources

### Text Generation
- `llama_mobile_completion()` - Generate text completion with advanced options
- `llama_mobile_completion_simple()` - Simple text completion
- `llama_mobile_stop_completion()` - Stop ongoing generation

### Conversation
- `llama_mobile_generate_response()` - Generate conversational response
- `llama_mobile_generate_response_simple()` - Simple conversational response
- `llama_mobile_clear_conversation()` - Clear conversation history

### Multimodal
- `llama_mobile_init_multimodal()` - Enable multimodal support
- `llama_mobile_init_multimodal_simple()` - Simple multimodal initialization
- `llama_mobile_multimodal_completion()` - Generate from text + media
- `llama_mobile_release_multimodal()` - Disable multimodal support

### Advanced
- `llama_mobile_tokenize()` - Convert text to tokens
- `llama_mobile_detokenize()` - Convert tokens to text
- `llama_mobile_embedding()` - Generate text embeddings
- `llama_mobile_apply_lora_adapters()` - Apply LoRA fine-tuning adapters
- `llama_mobile_remove_lora_adapters()` - Remove applied LoRA adapters

## Building the Framework

### Requirements

- macOS 13.0+
- Xcode 14.0+
- CMake 3.16+
- Command Line Tools for Xcode

### Build Steps

1. Ensure all submodules are initialized:
   ```bash
   git submodule update --init --recursive
   ```

2. Run the build script:
   ```bash
   ./scripts/build-ios.sh
   ```

3. The built xcframework will be available at:
   ```
   llama_mobile-ios-SDK/llama_mobile.xcframework
   ```

## iOS SDK Example

A demo iOS application named `iOSFrameworkExample` is available in the `examples` folder to help you understand how to use the llama_mobile framework in practice. This example demonstrates:

- Complete integration with the framework
- Testing all major APIs (initialization, completion, conversation, embeddings)
- Loading models from the `lib/models` directory
- Running on both simulator and physical devices

### How to Use the Example

1. Open `examples/iOSFrameworkExample/iOSFrameworkExample.xcodeproj` in Xcode
2. Ensure you have a GGUF model in the `lib/models` directory (e.g., `llama-2-7b-chat.Q4_K_M.gguf`)
3. Select a simulator or physical device as the run destination
4. Build and run the application

### Key Features Demonstrated

- **Model Initialization**: Loading models from the `lib/models` directory with custom parameters
- **Text Completion**: Generating text from prompts with streaming support
- **Conversational Interface**: Maintaining conversation history and generating responses
- **Embeddings**: Creating text embeddings for semantic understanding
- **Multi-architecture Support**: Working on both simulator (arm64/x86_64) and device (arm64)

## Tests

The llama_mobile iOS SDK includes a comprehensive test suite that covers all API functionality. These tests are designed to verify that the SDK behaves as expected and maintains backward compatibility.

### Building and Running Tests

#### Using Swift Package Manager (Recommended)

SPM automatically handles building when running tests, but you can also build separately:

```bash
# Navigate to the SDK directory
cd llama_mobile-ios-SDK

# Build the package (including tests)
swift build

# Run all tests (automatically builds if needed)
swift test

# Run tests with verbose output
swift test --verbose
```

#### Using Xcode

Xcode handles building automatically when running tests:

1. Open the package in Xcode by double-clicking on `llama_mobile-ios-SDK/Package.swift`
2. Build the package: `Cmd+B`
3. Use the Test Navigator (Cmd+6) to view all test cases
4. Click the "Play" button next to individual tests or press `Cmd+U` to run all tests
5. Test results will be displayed in the Test Report navigator

#### Using xcodebuild (Advanced)

```bash
# Navigate to the SDK directory
cd llama_mobile-ios-SDK

# Build the test target
xcodebuild build -scheme LlamaMobileTests -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"

# Run the tests
xcodebuild test -scheme LlamaMobileTests -destination "platform=iOS Simulator,name=iPhone 15,OS=latest"
```

#### Standalone Test Script

The SDK includes a standalone test script `TestLlamaMobile.swift` that demonstrates API usage:

```bash
# Navigate to the SDK directory
cd llama_mobile-ios-SDK

# Update model paths in TestLlamaMobile.swift first
# You can edit the file directly or use sed for quick updates
sed -i '' 's|/path/to/model.gguf|/your/actual/model/path.gguf|g' TestLlamaMobile.swift

# Build the standalone test script
swiftc -o TestRunner -framework llama_mobile TestLlamaMobile.swift

# Or run with automatic building
swift run --configuration release TestLlamaMobile
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

To add new tests to the suite:

1. Create a new Swift file in the `Tests/LlamaMobileTests` directory
2. Import `XCTest` and `LlamaMobile`
3. Create a test class that inherits from `XCTestCase`
4. Add test methods using the `func testXxx() throws` naming convention

```swift
import XCTest
import LlamaMobile

class MyNewTests: XCTestCase {
    func testMyNewFeature() {
        // Test implementation
        XCTAssertTrue(true)
    }
}
```

## Troubleshooting

### Model Loading Issues

- **"Failed to initialize model"**: Ensure the model path is correct and the file is accessible
- **"Model format not supported"**: Verify you're using a GGUF-format model compatible with llama.cpp
- **"Insufficient memory"**: Reduce the context window size (`n_ctx`) or disable GPU layers

### Performance Optimization

- **Slow inference**: Increase the number of threads (`n_threads`) or enable GPU acceleration
- **High memory usage**: Use smaller models or reduce `n_gpu_layers` to limit GPU memory usage
- **Battery drain**: Disable Metal acceleration (`n_gpu_layers = 0`) if battery life is a concern

### Common Errors

- **`EXC_BAD_ACCESS`**: Ensure you're not using a freed context or result
- **`LLAMA_MOBILE_ERROR_INVALID_PARAMS`**: Check that all required parameters are valid
- **`LLAMA_MOBILE_ERROR_NOT_INITIALIZED`**: Verify the context is properly initialized before use

## License

The llama_mobile framework is licensed under the MIT License.

## Credits

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) by Georgi Gerganov
- Metal optimizations for Apple Silicon
- GGUF model format support

## Contact

For issues, questions, or feature requests, please open an issue on the project repository.
