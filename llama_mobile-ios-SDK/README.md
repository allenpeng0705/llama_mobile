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
    nGpuLayers: 4
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
    topP: 0.9
)

// Generate completion
if let result = llamaMobile.completion(with: completionParams) {
    print("Completion: \(result.text)")
    print("Tokens predicted: \(result.tokensPredicted)")
    print("Total tokens: \(result.totalTokens)")
}
```

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
   ./build-ios.sh
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