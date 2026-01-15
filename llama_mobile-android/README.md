# LlamaMobile Android Library

## Overview

The `llama_mobile-android` directory contains the core **pre-built Android native libraries** (`libllama_mobile.so`) and **API headers** for the LlamaMobile library. This provides direct access to the native C++ implementation of Llama models, but **does not include any JNI layer, Kotlin wrapper, or Java wrapper**.

## Directory Structure

```
llama_mobile-android/
├── libs/                      # Pre-built native libraries
│   ├── arm64-v8a/            # ARM64-v8a architecture
│   │   ├── libllama_mobile.so      # Main native library
│   │   └── libc++_shared.so       # C++ standard library
│   └── x86_64/               # x86_64 architecture
│       ├── libllama_mobile.so      # Main native library
│       └── libc++_shared.so       # C++ standard library
├── include/                   # API headers
│   ├── llama_mobile_api.h    # Main API header
│   ├── llama_mobile_ffi.h    # FFI interface
│   └── llama_cpp/            # Complete llama_cpp headers
├── grammars/                  # Grammar files for structured output
│   ├── arithmetic.gbnf
│   ├── json.gbnf
│   ├── list.gbnf
│   └── more...
└── CMakeLists.txt            # CMake build configuration
```

## What This Is

The `llama_mobile-android` directory provides:
- Pre-built native libraries (`libllama_mobile.so`) for multiple architectures (arm64-v8a, x86_64)
- Complete API headers for C++ development
- Grammar files for structured output
- CMake configuration for building from source
- No JNI layer or language wrappers

## What This Is Not

This core library **does not include**:
- JNI layer for Java/Kotlin integration
- Kotlin wrapper or high-level API
- Java wrapper or high-level API
- Android Studio project files
- Sample apps or usage examples
- Test frameworks

## How to Use Directly

### 1. Add Native Libraries to Your Project

```bash
# Copy the pre-built libraries to your Android project
cp -r llama_mobile-android/libs/* your-project/src/main/jniLibs/

# Copy the grammar files to your assets
cp -r llama_mobile-android/grammars/ your-project/src/main/assets/
```

### 2. Include Headers for C++ Development

```bash
# Copy headers to your project
cp -r llama_mobile-android/include/ your-project/src/main/cpp/include/
```

### 3. Use in C++ Code

```cpp
#include <llama_mobile_api.h>
#include <llama_mobile_ffi.h>

// Initialize the context
llama_mobile_context_t context = llama_mobile_init("/path/to/model.gguf", NULL);

// Generate completion
llama_mobile_completion_params_t params;
memset(&params, 0, sizeof(params));
params.prompt = "Hello, world!";
params.max_tokens = 100;
params.temperature = 0.7;

llama_mobile_completion_result_t result;
int ret = llama_mobile_completion(context, &params, &result);

if (ret == 0) {
    // Handle the generated text
    llama_mobile_free_completion_result(&result);
}

// Release the context
llama_mobile_release(context);
```

## Usage in SDKs

### Building Android SDKs (like llama_mobile-android-SDK and llama_mobile-android-java-SDK)

To create an Android SDK on top of these native libraries:

1. **Implement a JNI layer** that bridges C++ API to Java
2. **Create Kotlin/Java wrappers** for the JNI methods
3. **Handle memory management** between Java/Kotlin and C++
4. **Add high-level abstractions** for common tasks
5. **Implement convenience methods** for features like text generation, embeddings, etc.

Example: The `llama_mobile-android-SDK` provides a Kotlin wrapper that simplifies usage:

```kotlin
import com.llamamobile.LlamaMobile

// Kotlin wrapper provides a cleaner API
val llama = LlamaMobile.initContext(InitParams(modelPath = "/path/to/model.gguf"))
val result = LlamaMobile.generateCompletion(llama, CompletionParams(prompt = "Hello, how are you?"))
```

### Cross-Platform SDKs

For cross-platform development (Flutter, React Native, Capacitor), you need to:

1. **Leverage these core native libraries** as the Android implementation
2. **Implement a JNI layer** to bridge C++ to Java
3. **Create platform-specific bindings** for your cross-platform framework
4. **Handle thread safety** and memory management across platforms
5. **Add appropriate language wrappers** (Kotlin for Flutter, JavaScript for React Native)

## Key Features

### Multi-Architecture Support
- Pre-built libraries for `arm64-v8a` (modern Android devices)
- Pre-built libraries for `x86_64` (emulators and some devices)
- Includes `libc++_shared.so` for proper C++ runtime support

### Grammar Support
- Built-in grammars for structured output
- Available in the `grammars/` directory
- JSON, lists, arithmetic, C code, and more

### API Headers
- Complete C++ API headers in `include/`
- `llama_mobile_api.h` for main functionality
- `llama_mobile_ffi.h` for FFI interface
- Full `llama_cpp/` headers for advanced usage

## Building

To rebuild the native libraries from source:

```bash
./scripts/build-android.sh
```

## Requirements
- Android NDK r25+
- CMake 3.21+
- Android API level 21+
- C++17 compatible compiler

## Comparison with SDK Versions

| Feature | llama_mobile-android (Core) | llama_mobile-android-SDK | llama_mobile-android-java-SDK |
|---------|---------------------------|-------------------------|------------------------------|
| Type | Native libraries only | Kotlin SDK with JNI | Java SDK with JNI |
| JNI Layer | ❌ | ✅ | ✅ |
| Kotlin Wrapper | ❌ | ✅ | ❌ |
| Java Wrapper | ❌ | ❌ | ✅ |
| High-Level API | ❌ | ✅ | ✅ |
| Usage | For advanced C++ developers | For Kotlin developers | For Java developers |
| Testing | None included | Built-in tests | Built-in tests |
| Examples | None included | Sample code and docs | Sample code and docs |

## Next Steps

1. **For Kotlin developers**: Use the `llama_mobile-android-SDK` which provides a Kotlin-friendly API
2. **For Java developers**: Use the `llama_mobile-android-java-SDK` which provides a Java-friendly API
3. **For C++ developers**: Use this core library directly
4. **For cross-platform developers**: Build bindings and JNI layer on top of this library
5. **For custom solutions**: Create your own JNI layer and wrappers around this library
