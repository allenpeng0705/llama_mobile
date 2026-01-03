# LlamaMobile iOS SDK

A production-ready Swift-based SDK for the `llama_mobile` library, providing a clean, native interface for iOS applications while maintaining compatibility with Flutter/Capacitor.

## Features

- **Native Swift Interface**: Clean, type-safe Swift APIs for interacting with `llama_mobile`
- **Self-Contained**: Embedded `llama_mobile.xcframework` for easy integration
- **Automated Framework Updates**: Simple script to ensure you're always using the latest framework
- **Comprehensive Example**: Demo app showing complete SDK usage
- **Memory Safe**: Proper Swift-C interop with managed memory handling

## Installation

### Swift Package Manager (SPM)

Add the SDK as a dependency in your project's `Package.swift`:

```swift
dependencies: [
    .package(path: "/path/to/llama_mobile-ios-SDK")
]
```

Then add it to your target:

```swift
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["LlamaMobileSDK"]
    )
]
```

## Usage

### Basic Initialization

```swift
import LlamaMobileSDK

let llamaMobile = LlamaMobile()

// Initialize with model parameters
let initParams = LlamaMobile.InitParams(
    modelPath: "/path/to/your/model.gguf",
    nCtx: 2048,
    nGpuLayers: 4,
    nThreads: 4,
    useMmap: true,
    embedding: true  // Enable embeddings if needed
)

let success = llamaMobile.initialize(with: initParams)
if success {
    print("Model loaded successfully!")
} else {
    print("Failed to load model")
}
```

### Generating Completions

```swift
// Create completion parameters
let completionParams = LlamaMobile.CompletionParams(
    prompt: "Hello, world!",
    nPredict: 128,
    temperature: 0.7,
    topK: 40,
    topP: 0.9,
    penaltyRepeat: 1.1,
    stopSequences: ["\n", "<|endoftext|>"]
)

// Generate completion
if let result = llamaMobile.completion(with: completionParams) {
    print("Completion: \(result.text)")
    print("Tokens predicted: \(result.tokensPredicted)")
    print("Total tokens: \(result.totalTokens)")
}
```

### Multimodal Completion (Images/Audio)

Before using multimodal completion, you must initialize the multimodal component:

```swift
// Initialize multimodal component
let multimodalSuccess = llamaMobile.initMultimodal()
if multimodalSuccess {
    print("Multimodal component initialized!")
}

// Create completion parameters
let multimodalParams = LlamaMobile.CompletionParams(
    prompt: "Describe this image:",
    nPredict: 256,
    temperature: 0.7
)

// Path to image file
let imagePath = "/path/to/image.jpg"

// Generate multimodal completion
if let result = llamaMobile.multimodalCompletion(with: multimodalParams, mediaPaths: [imagePath]) {
    print("Multimodal completion: \(result.text)")
}
```

### LoRA Adapters

LoRA adapters allow you to fine-tune the model's behavior without retraining:

```swift
// Apply a single LoRA adapter
let adapter = LlamaMobile.LoraAdapter(
    path: "/path/to/financial-adapter.lora",
    scale: 0.8
)

if llamaMobile.applyLoraAdapters(adapters: [adapter]) {
    print("LoRA adapter applied successfully")
    
    // Generate completions with adapted model
    let financialPrompt = "Explain stock market fundamentals"
    let financialParams = LlamaMobile.CompletionParams(
        prompt: financialPrompt,
        nPredict: 200,
        temperature: 0.6
    )
    
    if let result = llamaMobile.completion(with: financialParams) {
        print("Financial explanation: \(result.text)")
    }
}

// Remove adapters to return to base model
llamaMobile.removeLoraAdapters()

// Check loaded adapters
let loadedAdapters = llamaMobile.getLoadedLoraAdapters()
print("Loaded LoRA adapters: \(loadedAdapters.count)")
```

### Tokenization

Convert between text and model tokens:

```swift
// Tokenize text
let text = "Hello, world!"
if let tokenizeResult = llamaMobile.tokenize(text: text) {
    print("Tokens: \(tokenizeResult.tokens)")
    print("Token count: \(tokenizeResult.tokens.count)")
}

// Detokenize tokens
let tokens: [Int32] = [15496, 11, 995, 0]
if let detokenizedText = llamaMobile.detokenize(tokens: tokens) {
    print("Detokenized text: \(detokenizedText)")
}
```

### Embeddings

Generate numerical representations of text:

```swift
// Note: Must set embedding: true in InitParams
let text = "The quick brown fox jumps over the lazy dog"
if let embeddings = llamaMobile.embedding(text: text) {
    print("Embedding dimensions: \(embeddings.count)")
    print("First few values: \(embeddings.prefix(5))")
}
```

### Vocoder & Text-to-Speech (TTS)

Convert text to speech:

```swift
// Initialize vocoder (requires separate vocoder model)
let vocoderPath = "/path/to/vocoder/model.bin"
if llamaMobile.initializeVocoder(modelPath: vocoderPath) {
    print("Vocoder initialized!")
    
    // Format text for TTS
    let textToSpeak = "Hello, how are you today?"
    if let formattedText = llamaMobile.getFormattedAudioCompletion(textToSpeak: textToSpeak) {
        // Generate speech tokens
        let ttsParams = LlamaMobile.CompletionParams(
            prompt: formattedText,
            nPredict: 1000,
            temperature: 0.0  // TTS typically uses 0 temperature for deterministic output
        )
        
        if let ttsResult = llamaMobile.completion(with: ttsParams) {
            // Get audio completion
            if let audioTokens = ttsResult.predictedTokens {
                // Decode tokens to audio samples
                if let audioSamples = llamaMobile.decodeAudioTokens(tokens: audioTokens) {
                    print("Generated audio samples: \(audioSamples.count)")
                    // Play or save audio samples
                }
            }
        }
    }
}

// Release vocoder when done
llamaMobile.releaseVocoder()
```

## API Reference

This section provides a comprehensive reference for all public APIs in the LlamaMobile SDK.

### Core Class

#### `LlamaMobile()`
Creates a new instance of the SDK.

```swift
let llamaMobile = LlamaMobile()
```

### Initialization

#### `initialize(with: InitParams) -> Bool`
Initializes the model with the specified parameters.

#### `initMultimodal() -> Bool`
Initializes the multimodal component for processing images/audio.

### Completion

#### `completion(with: CompletionParams) -> CompletionResult?`
Generates text completion for a prompt.

#### `multimodalCompletion(with: CompletionParams, mediaPaths: [String]) -> CompletionResult?`
Generates text completion with image/audio inputs.

### LoRA Adapters

#### `applyLoraAdapters(adapters: [LoraAdapter]) -> Bool`
Applies LoRA adapters to the model.

#### `removeLoraAdapters()`
Removes all applied LoRA adapters.

#### `getLoadedLoraAdapters() -> [LoraAdapter]`
Returns a list of currently loaded LoRA adapters.

### Tokenization

#### `tokenize(text: String) -> TokenizeResult?`
Converts text to model tokens.

#### `tokenizeWithMedia(text: String, mediaPaths: [String]) -> TokenizeResult?`
Tokenizes text with media inputs.

#### `detokenize(tokens: [Int32]) -> String?`
Converts tokens back to text.

#### `setGuideTokens(tokens: [Int32]) -> Bool`
Sets guide tokens for generation.

### Embeddings

#### `embedding(text: String) -> [Float]?`
Generates text embeddings.

### Vocoder & TTS

#### `initializeVocoder(modelPath: String) -> Bool`
Initializes the vocoder for TTS.

#### `releaseVocoder()`
Releases vocoder resources.

#### `isVocoderEnabled() -> Bool`
Checks if the vocoder is initialized.

#### `getTtsType() -> Int32`
Gets the TTS type supported by the model.

#### `getFormattedAudioCompletion(speakerJsonStr: String?, textToSpeak: String) -> String?`
Formats text for TTS generation.

#### `decodeAudioTokens(tokens: [Int32]) -> [Float]?`
Decodes audio tokens to audio samples.

## SDK Structure

```
llama_mobile-ios-SDK/
├── LlamaMobileSDK/
│   ├── LlamaMobile.swift          # Core Swift wrapper class
│   ├── LlamaMobileSDK-Bridging-Header.h  # C API bridging header
│   └── LlamaMobileSDK.h           # Public header file
├── Frameworks/
│   └── llama_mobile.xcframework/  # Embedded llama_mobile framework
├── Package.swift                  # Swift Package Manager configuration
├── examples/
│   └── iOSSDKExample/             # Demo application
└── README.md                      # This file
```

## Building the SDK

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd llama_mobile-ios-SDK
   ```

2. **Build the SDK**:
   ```bash
   swift build
   ```

## Updating the Framework

The SDK includes a script to automatically update the embedded `llama_mobile.xcframework` to the latest version:

1. **Build the latest framework** in the `llama_mobile-ios` directory:
   ```bash
   cd /path/to/llama_mobile/llama_mobile-ios
   # Build the framework according to its instructions
   ```

2. **Run the update script** from the root directory:
   ```bash
   cd /path/to/llama_mobile
   ./build-ios-SDK.sh
   ```

The script will:
- Verify the framework exists in `llama_mobile-ios/`
- Remove any old framework from the SDK
- Copy the latest framework to `llama_mobile-ios-SDK/Frameworks/`
- Make the script executable for future use

## Example Application

The SDK includes a comprehensive example app located at `examples/iOSSDKExample/` that demonstrates:

- Model loading functionality
- Prompt input handling
- Completion generation
- User interface components
- Error handling

To run the example:

```bash
cd llama_mobile-ios-SDK/examples/iOSSDKExample/
swift build
# Open in Xcode or run with your preferred method
```

## Notes and Limitations

- **Progress Callbacks**: Currently disabled due to C function pointer closure capture limitations. This can be revisited with a proper context management solution.
- **Platform Support**: iOS 15.0+
- **Swift Version**: Swift 5.9+
- **Framework Size**: The embedded xcframework contributes to the overall size of your application

## Contributing

Please refer to the main `llama_mobile` repository for contribution guidelines.

## License

Same license as the main `llama_mobile` library.