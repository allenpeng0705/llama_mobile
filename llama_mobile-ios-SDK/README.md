# llama_mobile iOS SDK

The llama_mobile iOS SDK provides the v2 Swift API (`LlamaEngine`) around the llama_mobile v2 C API (`llama_mobile_v2.h`) for easy integration into iOS projects. It includes the XCFramework with native implementations and the Swift wrapper.

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
│       └── LlamaEngine.swift      # v2 Swift API wrapper (LlamaEngine)
├── Tests/
│   └── LlamaMobileTests/          # Test files
│       └── LlamaEngineTests.swift # v2 conformance tests
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
- **Swift wrapper code** (`LlamaEngine.swift`)

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
- **Sources/LlamaMobile/** - v2 Swift wrapper source code (`LlamaEngine.swift`)
- **README.md** - Integration instructions
- **llama_mobile.podspec** - CocoaPod specification

This bundle is ready for distribution and can be directly copied to other iOS projects for simple manual integration.

## Testing

### Running Tests

The SDK includes test files that validate functionality, but full test execution requires Xcode with iOS simulator setup. Tests are not run automatically during the SDK build process due to these requirements.

### How to Run Tests

1. **Run from the package root** (Xcode auto-schemes Swift packages; no
   `generate-xcodeproj` needed):
   ```bash
   cd llama_mobile-ios-SDK
   xcodebuild test -scheme LlamaMobile \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
   ```

2. **Configure Test Environment**
   - `LlamaEngineTests` (v2 §8 conformance: sync/async/stream/abort, plus
     tokenize/detokenize round-trip, `modelInfo` fields, embeddings on the
     Qwen3-Embedding fixture) reads model paths from
     `Tests/LlamaMobileTests/LlamaEngineTests.swift`. Set
     `LLAMA_MOBILE_TEST_MODEL` to a GGUF to override the chat fixture.
     Model-backed tests `XCTSkip` when no model is reachable.
   - The multimodal vision test is device-only (the mtmd projector loads on the
     GPU and simulator Metal crashes) — it is skipped on simulators and runs on
     a real iPhone.

3. **Run Tests**
   - Or open the package in Xcode, pick an iOS simulator, and press
     `Command+U`.

### Test Requirements

- **Xcode 14.0+** with iOS simulator support
- **iOS 15.0+** simulator
- **Model files** at paths specified in test files (chat model; optional
  embedding model and vision fixtures for the embedding/vision tests)
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
2. Add the `LlamaEngine.swift` file to your project
3. Import `LlamaMobile` in your Swift files
4. Use the `LlamaEngine` API (see the usage section above)

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

## Usage — v2 `LlamaEngine` (recommended for new code)

`LlamaEngine` is the v2 Swift API built on the v2 C API (`llama_mobile_v2.h`).
The legacy v1 `LlamaMobile` facade and the v1 C ABI have been fully removed on
this branch (see the V1 removal section below).

Every operation comes in two documented forms (threading contract in
`docs/api-contract-v2.md` §8):

- a **sync** form that blocks the calling thread — never call it from the
  main/UI thread;
- an **async** form that never blocks the caller.

```swift
import LlamaMobile

// --- Open a model ---------------------------------------------------------
// Sync (blocking load — call off the main thread):
//   let engine = try LlamaEngine.open(config)
// Async (never blocks the caller):
var config = LlamaModelConfig(modelPath: "/path/to/model.gguf")
config.engine = .auto               // .cpu / .metal / .vulkan / .opencl
config.nCtx = 2048
config.flags = [.mmap, .chat]       // context flags
config.loadProgress = { progress in // 0...1 on the loading thread
    print("loading \(progress)")
    return true                     // false aborts the load
}
let engine = try await LlamaEngine.open(config)

// --- One-shot generation --------------------------------------------------
// Sync (blocks the calling thread — never call from the main/UI thread):
var req = LlamaGenerationRequest(prompt: "Write a haiku about llamas")
req.maxTokens = 64
req.sampling.temperature = 0.8
let r = try await Task.detached { try engine.generate(req) }.value  // sync form
print(r.text, r.stopReason, r.usage)

// Async (never blocks):
let asyncResult = try await engine.generate(req)

// --- Chat via messages ----------------------------------------------------
var chat = LlamaGenerationRequest(messages: [
    LlamaMessage(role: "system", content: "You are a concise assistant."),
    LlamaMessage(role: "user", content: "What is 2+2?"),
])
chat.maxTokens = 128
let answer = try await engine.generate(chat)

// --- Streaming + abort ----------------------------------------------------
var streamReq = LlamaGenerationRequest(prompt: "Tell me a long story")
streamReq.maxTokens = 1000
var requestId: UInt64?
for try await event in engine.generateStream(streamReq) {
    switch event {
    case .started(let id):  requestId = id        // pass this to abort()
    case .token(let text):  print(text, terminator: "")
    case .done(let result):
        if result.stopReason == .aborted { print("\n[aborted by user]") }
    case .failed(let error): print("\n[error] \(error)")
    }
}
// abort() is thread-safe — safe to call from any thread (e.g. a UI action):
try engine.abort(requestId: requestId!)

// --- Lifecycle -------------------------------------------------------------
engine.close()   // idempotent
```

**Threading rules (short version):** use the `async` forms from your UI code;
they never block the caller and all events are delivered on the engine's
private serial queue — hop back to the main actor with `await MainActor.run`
when you touch UI state. One engine runs one generation at a time; a second
concurrent call throws `.alreadyRunning`.

## V1 removal

The legacy v1 Swift facade (`LlamaMobile`) and the v1 C ABI (`*_c`/`*_t`) have
been fully removed on this branch (see `docs/v1-purge-workplan.md`). The SDK
exposes only the v2 `LlamaEngine` API on top of `llama_mobile_v2.h`. The v1.x
git tag keeps the old line available.

## API Reference

For detailed API documentation, please refer to the comments in the
`LlamaEngine.swift` file and the frozen `lib/llama_mobile_v2.h` header.
Also available on `LlamaEngine`: `modelInfo()`, `tokenize(_:)`/`detokenize(_:)`,
batch `embed(_:)`, and `initMultimodal(mmprojPath:)` / `releaseMultimodal()`
(attach an mmproj, then include `LlamaMedia` in requests for vision).


## Troubleshooting

### Common Issues

1. **Framework not found**: Ensure the XCFramework is properly added to your project and embedded in your target.

2. **Swift wrapper not found**: Ensure the Swift wrapper files are added to your project.

3. **Metal-related errors**: Ensure your device supports Metal and that the Metal files are properly included in the framework.

4. **Dependency issues**: Ensure the Accelerate framework and libc++ library are properly added to your project.

### Logging

The C API exposes `llama_mobile_log_set_level(level)` /
`llama_mobile_log_set_callback(cb, user_data)` (see `llama_mobile_v2.h`). A
Swift convenience on `LlamaEngine` is planned with the engine configuration
work; until then, call the C functions directly when you need verbose logs
during debugging.

## License

The llama_mobile iOS SDK is available under the MIT license. See the LICENSE file for more information.
