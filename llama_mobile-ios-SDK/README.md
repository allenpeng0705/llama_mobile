# llama_mobile iOS SDK

The llama_mobile iOS SDK provides a Swift wrapper around the llama_mobile C API for easy integration into iOS projects. It includes both the XCFramework with native implementations and a Swift wrapper for a friendly API.

## Project Structure

```
llama_mobile-ios-SDK/
├── llama_mobile.xcframework/      # Core framework with native implementations
│   ├── ios-arm64/                 # Device architecture (arm64)
│   │   └── llama_mobile.framework/
│   │       ├── Headers/           # Public headers
│   │       ├── Modules/           # Swift module definitions
│   │       ├── ggml-llama.metallib # Metal shader library
│   │       └── llama_mobile       # Framework binary
│   ├── ios-arm64-simulator/       # Simulator architecture
│   │   └── llama_mobile.framework/ # Same structure as device version
│   └── Info.plist                 # XCFramework configuration
├── Sources/
│   └── LlamaMobile/               # Swift wrapper files
│       └── LlamaMobile.swift      # Main Swift API wrapper
├── Tests/
│   └── LlamaMobileTests/          # Test files
│       └── LlamaMobileTests.swift # SDK test cases
├── llama_mobileBundle/            # Complete integration bundle
│   ├── Frameworks/                # XCFramework copy
│   ├── Sources/                   # Swift wrapper copy
│   ├── README.md                  # Bundle documentation
│   └── llama_mobile.podspec       # CocoaPod spec
├── llama_mobile.podspec           # CocoaPod spec for easy integration
├── Package.swift                  # Swift Package Manager configuration
└── README.md                      # SDK documentation
```

## Building

### What is "Building" the SDK?

The llama_mobile-ios-SDK is a library project that packages:
- **Pre-built native XCFramework** (copied from `llama_mobile-ios/shared/`)
- **Swift wrapper code** (LlamaMobile.swift)

"Building" the SDK refers to updating the SDK structure with the latest XCFramework and ensuring all components are properly organized for integration. The native C++ libraries are pre-built and simply copied during this process.

### When to Build the SDK

You typically need to build the SDK:
1. When you've updated the native libraries in `llama_mobile-ios/shared/`
2. To regenerate the SDK structure after making changes to the Swift wrapper
3. To create a fresh SDK package for distribution

### How to Build the SDK

#### Using the Build Script

```bash
# Navigate to the root directory
cd llama_mobile

# Rebuild the iOS SDK structure
./scripts/build-ios-SDK.sh
```

This script will:
1. Backup the existing SDK directory
2. Copy the latest pre-built XCFramework from `llama_mobile-ios/shared/`
3. Update the SDK structure with the latest files
4. Preserve any custom modifications in your Swift wrapper, tests, and configuration files
5. Validate SDK structure and buildability
6. Create the framework bundle after successful validation
7. Copy the complete SDK bundle to `output/llama_mobile-iOS-SDK/` for easy distribution

## Output Directory

After running the build script, the iOS SDK is available at:
- **Development SDK**: `llama_mobile-ios-SDK/` (in the project root) - Complete SDK with all integration methods
- **Distribution Bundle**: `output/llama_mobile-iOS-SDK/llama_mobileBundle/` - Self-contained bundle for manual distribution

The `output/llama_mobile-iOS-SDK/llama_mobileBundle/` directory is a self-contained bundle that includes:
- **Frameworks/llama_mobile.xcframework** - Native C++ libraries for iOS
- **Sources/LlamaMobile/** - Swift wrapper source code
- **README.md** - Integration instructions
- **llama_mobile.podspec** - CocoaPod specification

This bundle is ready for distribution and can be directly copied to other iOS projects for simple manual integration.

## Testing

### Running Tests

The SDK includes test files that validate functionality, but full test execution requires Xcode with iOS simulator setup. Tests are not run automatically during the SDK build process due to these requirements.

### How to Run Tests

1. **Open the SDK in Xcode**
   ```bash
   # Generate Xcode project (optional)
   cd llama_mobile-ios-SDK
   swift package generate-xcodeproj
   
   # Open in Xcode
   open LlamaMobile.xcodeproj
   ```

2. **Configure Test Environment**
   - Ensure you have an iOS simulator set up
   - Update model paths in `Tests/LlamaMobileTests/LlamaMobileTests.swift` to point to actual model files

3. **Run Tests**
   - Select an iOS simulator as the run destination
   - Press `Command+U` to run all tests, or run specific tests from the Test Navigator

### Test Requirements

- **Xcode 14.0+** with iOS simulator support
- **iOS 15.0+** simulator
- **Model files** at paths specified in test files
- **Proper iOS sandbox permissions**

## Integration Options

### Option 1: Use the complete bundle

1. Drag and drop the `llama_mobileBundle` folder into your Xcode project
2. Ensure the XCFramework is added to your target's Frameworks, Libraries, and Embedded Content
3. Add the Swift wrapper files to your project
4. Import `LlamaMobile` in your Swift files
5. Use the API as documented in the Swift wrapper

### Option 2: Use individual components

1. Add the `llama_mobile.xcframework` to your Xcode project
2. Add the `LlamaMobile.swift` file to your project
3. Import `LlamaMobile` in your Swift files
4. Use the existing API structure from `LlamaMobile.swift`

### Option 3: Use CocoaPods

1. Add the following to your `Podfile`:
   ```ruby
   pod 'llama_mobile', :path => '/path/to/llama_mobile-ios-SDK'
   ```

2. Run `pod install` to install the SDK

3. Import `LlamaMobile` in your Swift files

4. Use the API as documented in the Swift wrapper

### Option 4: Use Swift Package Manager

1. In Xcode, go to File > Add Package Dependencies...
2. Enter the path to the `llama_mobile-ios-SDK` directory
3. Select the package and add it to your project
4. Import `LlamaMobile` in your Swift files
5. Use the API as documented in the Swift wrapper

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.0+

## Framework Dependencies

The SDK requires the following frameworks:

- Accelerate
- Metal
- libc++

These are automatically included when using CocoaPods or Swift Package Manager, or you can add them manually when integrating the framework directly.

## Usage Example

```swift
import LlamaMobile

// Initialize the model
let params = LlamaMobile.InitParams(
    modelPath: "/path/to/model.gguf",
    threadCount: 4,
    contextSize: 2048
)

do {
    let llamaMobile = try LlamaMobile(params: params)
    
    // Generate completion
    let completionParams = LlamaMobile.CompletionParams(
        prompt: "Hello, world!",
        maxTokens: 100,
        temperature: 0.7
    )
    
    try llamaMobile.generateCompletion(params: completionParams) { result in
        switch result {
        case .success(let text):
            print("Generated text: \(text)")
        case .failure(let error):
            print("Error: \(error)")
        }
    }
} catch {
    print("Initialization error: \(error)")
}
```

## API Reference

For detailed API documentation, please refer to the comments in the `LlamaMobile.swift` file.

## Troubleshooting

### Common Issues

1. **Framework not found**: Ensure the XCFramework is properly added to your project and embedded in your target.

2. **Swift wrapper not found**: Ensure the Swift wrapper files are added to your project.

3. **Metal-related errors**: Ensure your device supports Metal and that the Metal files are properly included in the framework.

4. **Dependency issues**: Ensure the Accelerate framework and libc++ library are properly added to your project.

### Logging

The SDK includes logging functionality that can help with troubleshooting. You can set the log level using:

```swift
LlamaMobile.setLogLevel(.debug)
```

## License

The llama_mobile iOS SDK is available under the MIT license. See the LICENSE file for more information.
