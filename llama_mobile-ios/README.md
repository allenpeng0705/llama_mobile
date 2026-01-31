# llama_mobile iOS Libraries

This directory contains both static and shared (XCFramework) libraries for integrating llama_mobile into iOS projects.

## Directory Structure

```
llama_mobile-ios/
├── shared/             # Shared library (XCFramework)
│   └── llama_mobile.xcframework/  # iOS XCFramework bundle
├── static/             # Static libraries
│   ├── include/        # Header files
│   └── libs/           # Static library files (.a)
└── README.md           # This documentation
```

## Using the Shared XCFramework

The shared XCFramework is the recommended approach for modern iOS development.

### Integration Steps

1. **Add XCFramework to Project**
   - Drag and drop `llama_mobile.xcframework` into your Xcode project
   - In the "Add Files to Project" dialog, select "Copy items if needed" and click "Finish"

2. **Verify Frameworks**
   - In your project's "General" settings, ensure `llama_mobile.xcframework` is listed under "Frameworks, Libraries, and Embedded Content"
   - Set the "Embed" option to "Embed & Sign"

3. **Add Required System Frameworks**
   - In Xcode, go to "Build Phases" → "Link Binary With Libraries"
   - Add the following frameworks:
     - `Accelerate.framework` (for CPU acceleration)
     - `Metal.framework` (for GPU acceleration)

4. **Import Headers**
   ```objective-c
   // Objective-C
   #import <llama_mobile/llama_mobile_api.h>
   
   // Swift (via bridging header or @objc)
   // Include in bridging header:
   // #import <llama_mobile/llama_mobile_api.h>
   ```

5. **Initialize and Use**
   ```objective-c
   // Initialize the library
   llama_mobile_init();
   
   // Load a model
   llama_model* model = llama_mobile_load_model("path/to/model.gguf");
   
   // Generate text
   llama_context* ctx = llama_mobile_create_context(model);
   llama_mobile_generate(ctx, "Hello, world!");
   
   // Clean up
   llama_mobile_free_context(ctx);
   llama_mobile_free_model(model);
   llama_mobile_cleanup();
   ```

### Metal Support

The XCFramework includes built-in Metal support:
- Contains `ggml-llama.metallib` for GPU acceleration
- Automatically uses Metal when available
- No additional configuration required

## Using the Static Library

The static library provides a more traditional integration approach.

### Integration Steps

1. **Add Static Library**
   - In Xcode, go to "Build Phases" → "Link Binary With Libraries"
   - Click the "+" button and select "Add Other..." → "Add Files..."
   - Navigate to `static/libs/` and select the appropriate library for your target:
     - `ios-arm64/libllama_mobile.a` (for device builds)
     - `ios-arm64-simulator/libllama_mobile.a` (for simulator builds)

2. **Add Header Files**
   - In Xcode, go to "Build Settings" → "Search Paths"
   - Set "Header Search Paths" to include `static/include/`

3. **Add Required System Frameworks**
   - Same as XCFramework: add `Accelerate.framework` and `Metal.framework`

4. **Import Headers**
   ```objective-c
   #include "llama_mobile_api.h"
   ```

5. **Initialize and Use**
   ```objective-c
   // Same usage as XCFramework
   llama_mobile_init();
   // ...
   ```

### Metal Support

The static library includes Metal support compiled directly into the binary:
- Metal symbols are embedded in the `.a` file
- Automatically uses Metal when available
- No additional configuration required

## Key Differences

| Feature | XCFramework | Static Library |
|---------|-------------|----------------|
| Integration | Drag-and-drop | Manual linking |
| Size | Larger initial download | Smaller binary |
| Metal Support | Built-in `.metallib` | Embedded in binary |
| Distribution | Self-contained bundle | Requires separate headers |
| Debugging | Easier with separate binary | More integrated |

## Performance Considerations

- **Metal GPU Acceleration**: Both library types support Metal, providing significant performance improvements for model inference
- **CPU Optimization**: Both include Accelerate framework integration for optimized CPU performance
- **Memory Usage**: Similar memory usage during runtime
- **App Bundle Size**: Similar total app bundle size (XCFramework is embedded)

## Troubleshooting

### Common Issues

1. **Metal Not Working**
   - Ensure `Metal.framework` is added to your project
   - Verify your device/simulator supports Metal
   - Check console logs for Metal-related errors

2. **Linker Errors**
   - Ensure all required frameworks are added
   - Verify header search paths are correct
   - Check that you're using the correct library for your target architecture

3. **Model Loading Failures**
   - Ensure model file is included in your app bundle
   - Check that model path is correct
   - Verify model format is supported

## API Reference

For detailed API documentation, refer to the header files:
- `llama_mobile_api.h` - Main API functions
- `llama_mobile_ffi.h` - FFI bindings for other languages
- `llama_cpp/` - Underlying llama_cpp library headers

## Example Usage

### Basic Text Generation

```objective-c
#include "llama_mobile_api.h"

// Initialize
llama_mobile_init();

// Load model
const char* model_path = [[NSBundle mainBundle] pathForResource:@"model" ofType:@"gguf"].UTF8String;
llama_model* model = llama_mobile_load_model(model_path);

if (model) {
    // Create context
    llama_context* ctx = llama_mobile_create_context(model);
    
    if (ctx) {
        // Generate text
        const char* prompt = "Hello, world!";
        llama_mobile_generate(ctx, prompt);
        
        // Get generated text
        const char* output = llama_mobile_get_output(ctx);
        printf("Output: %s\n", output);
        
        // Clean up
        llama_mobile_free_context(ctx);
    }
    
    llama_mobile_free_model(model);
}

// Clean up
llama_mobile_cleanup();
```

## Supported Architectures

- **Device**: `arm64` (iPhone/iPad)
- **Simulator**: `arm64` and `x86_64` (Mac with Apple Silicon/Intel)

## Minimum iOS Version

- iOS 15.0+

## Building from Source

To rebuild these libraries, run:

```bash
# From repository root
./scripts/build-ios-framework.sh --build-type=Release
```

For more options, run:
```bash
./scripts/build-ios-framework.sh --help
```
For build iOS SDK, run:
```bash
./scripts/build-ios-framewrok.sh 
./scripts/build-ios-SDK.sh
```
