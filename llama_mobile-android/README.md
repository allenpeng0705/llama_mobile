# LlamaMobile Android Library

## Overview

The `llama_mobile-android` directory contains the core **pre-built Android native libraries** (`libllama_mobile.so`) and **API headers** for the LlamaMobile library. This provides direct access to the native C++ implementation of Llama models, but **does not include any JNI layer, Kotlin wrapper, or Java wrapper**.

## Directory Structure

```
llama_mobile-android/
├── libs/                      # Pre-built native libraries
│   ├── shared/               # Shared libraries
│   │   ├── arm64-v8a/        # ARM64-v8a architecture
│   │   │   ├── libllama_mobile.so      # Main native library
│   │   │   └── libc++_shared.so       # C++ standard library
│   │   └── x86_64/           # x86_64 architecture
│   │       ├── libllama_mobile.so      # Main native library
│   │       └── libc++_shared.so       # C++ standard library
│   └── static/               # Static libraries
│       ├── arm64-v8a/        # ARM64-v8a architecture
│       │   └── libllama_mobile.a      # Main static library
│       └── x86_64/           # x86_64 architecture
│           └── libllama_mobile.a      # Main static library
├── include/                   # API headers
│   ├── llama_mobile_api.h    # Main API header
│   ├── llama_mobile_ffi.h    # FFI interface
│   └── llama_cpp/            # Complete llama_cpp headers
└── CMakeLists.txt            # CMake build configuration
```

## What This Is

The `llama_mobile-android` directory provides:
- Pre-built **shared libraries** (`libllama_mobile.so`) for multiple architectures
- Pre-built **static libraries** (`libllama_mobile.a`) for multiple architectures
- Complete API headers for C++ development
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

### Option 1: Using Shared Libraries (Recommended for Most Use Cases)

Shared libraries (`libllama_mobile.so`) are dynamically linked at runtime and require `libc++_shared.so`:

```bash
# Copy shared libraries to your Android project
cp -r llama_mobile-android/libs/shared/* your-project/src/main/jniLibs/
```

### Option 2: Using Static Libraries

Static libraries (`libllama_mobile.a`) are linked at build time and don't require `libc++_shared.so`:

```bash
# Copy static libraries to your Android project
cp -r llama_mobile-android/libs/static/* your-project/src/main/jniLibs/
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

## Shared vs Static Libraries

### Shared Libraries (`libllama_mobile.so`)

**Advantages:**
- Smaller APK size (libraries are shared across multiple apps if needed)
- Faster build times (no need to link the entire library at build time)
- Easier updates (can be updated independently if needed)

**Disadvantages:**
- Requires `libc++_shared.so` to be included
- Runtime dependency resolution
- Potential compatibility issues if different versions are used

### Static Libraries (`libllama_mobile.a`)

**Advantages:**
- Self-contained (no external dependencies beyond standard libraries)
- No runtime dependency resolution
- More predictable behavior (all code is linked at build time)
- Better for apps that need maximum compatibility

**Disadvantages:**
- Larger APK size (library code is embedded in each app)
- Longer build times (entire library must be linked at build time)
- Updates require rebuilding the entire app

### Which to Choose?

| Use Case | Recommended Library Type | Reason |
|----------|---------------------------|--------|
| Most Android apps | Shared library | Smaller APK size, faster builds |
| Games or performance-critical apps | Static library | More predictable performance |
| Apps with strict compatibility requirements | Static library | Self-contained, no external dependencies |
| Apps that need to minimize APK size | Shared library | Smaller footprint |

## Key Features

### Multi-Architecture Support
- Pre-built **shared libraries** for `arm64-v8a` and `x86_64`
- Pre-built **static libraries** for `arm64-v8a` and `x86_64`
- Includes `libc++_shared.so` for shared library support

### API Headers
- Complete C++ API headers in `include/`
- `llama_mobile_api.h` for main functionality
- `llama_mobile_ffi.h` for FFI interface
- Full `llama_cpp/` headers for advanced usage

## Building

### Building Core Native Libraries

To rebuild the native libraries from source:

```bash
./scripts/build-android-lib.sh
```

This script will:
1. Clean only the necessary directories (preserving CMakeLists.txt and README.md)
2. Build both shared and static libraries for all specified ABIs
3. Copy header files
4. Create CMakeLists.txt if it doesn't exist

### CMake Integration

The provided `CMakeLists.txt` file supports both shared and static libraries. Here's how to integrate them into different types of Android projects:

#### Option 1: Using the Provided CMakeLists.txt

If you're including the entire `llama_mobile-android` directory in your project:

```cmake
# In your project's CMakeLists.txt
add_subdirectory(path/to/llama_mobile-android)

# For shared library
target_link_libraries(your_target PRIVATE llama_mobile)

# For static library
target_link_libraries(your_target PRIVATE llama_mobile_static)
```

#### Option 2: Manual Integration

If you've copied the libraries and headers to your project structure:

```cmake
# In your project's CMakeLists.txt

# Set paths to llama_mobile libraries and headers
set(LLAMA_MOBILE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/path/to/llama_mobile)

# Include directories
include_directories(
    ${LLAMA_MOBILE_DIR}/include
    ${LLAMA_MOBILE_DIR}/include/llama_cpp
)

# Shared library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_DIR}/libs/shared/${ANDROID_ABI}/libllama_mobile.so
)

# Static library
add_library(llama_mobile_static STATIC IMPORTED)
set_target_properties(llama_mobile_static PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_DIR}/libs/static/${ANDROID_ABI}/libllama_mobile.a
)

# Link against the library
target_link_libraries(your_target PRIVATE llama_mobile)  # or llama_mobile_static
```

#### Option 3: Gradle Integration (Without CMake)

For projects using Gradle without CMake:

```gradle
// In your app/build.gradle
android {
    sourceSets {
        main {
            // For shared libraries
            jniLibs.srcDirs += ['path/to/llama_mobile-android/libs/shared']
            
            // For static libraries (requires additional setup)
            // Static libraries must be linked at build time
        }
    }
}
```

#### Full Android Studio Integration Example

Here's a complete example for integrating with a new Android Studio project:

1. **Create a new Android Studio project** with C++ support
2. **Copy the libraries** to your project:
   ```bash
   # For shared libraries
   cp -r llama_mobile-android/libs/shared/* your-project/app/src/main/jniLibs/
   
   # For static libraries
   cp -r llama_mobile-android/libs/static/* your-project/app/src/main/cpp/libs/
   ```

3. **Copy the headers**:
   ```bash
   cp -r llama_mobile-android/include/ your-project/app/src/main/cpp/include/
   ```

4. **Update CMakeLists.txt**:
   ```cmake
   cmake_minimum_required(VERSION 3.18.1)
   project("yourproject")

   # Include directories
   include_directories(
       ${CMAKE_CURRENT_SOURCE_DIR}/include
       ${CMAKE_CURRENT_SOURCE_DIR}/include/llama_cpp
   )

   # Shared library
   add_library(llama_mobile SHARED IMPORTED)
   set_target_properties(llama_mobile PROPERTIES
       IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
   )

   # Static library (alternative)
   # add_library(llama_mobile_static STATIC IMPORTED)
   # set_target_properties(llama_mobile_static PROPERTIES
   #     IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libllama_mobile.a
   # )

   # Your native library
   add_library(native-lib SHARED
       native-lib.cpp
   )

   # Link against llama_mobile
   target_link_libraries(native-lib PRIVATE llama_mobile)
   ```

5. **Sample native-lib.cpp**:
   ```cpp
   #include <jni.h>
   #include <string>
   #include <llama_mobile_api.h>

   extern "C" JNIEXPORT jstring JNICALL
   Java_com_example_yourproject_MainActivity_stringFromJNI(
           JNIEnv* env,
           jobject /* this */) {
       // Initialize llama_mobile
       llama_mobile_context_t context = llama_mobile_init("/path/to/model.gguf", NULL);
       
       // Check if initialization was successful
       if (context) {
           // TODO: Use the context for inference
           llama_mobile_release(context);
           return env->NewStringUTF("LlamaMobile initialized successfully!");
       } else {
           return env->NewStringUTF("Failed to initialize LlamaMobile");
       }
   }
   ```

#### Troubleshooting CMake Integration

**Common issues and solutions:**

| Issue | Solution |
|-------|----------|
| `library not found` | Check the path to the library files in your CMakeLists.txt |
| `header not found` | Check the include directories in your CMakeLists.txt |
| `undefined reference` | Ensure you're linking against the correct library and all dependencies |
| `ABI mismatch` | Make sure you're building for the correct ABI (arm64-v8a or x86_64) |
| `libc++_shared.so not found` | For shared libraries, ensure libc++_shared.so is included in your jniLibs |

### Building Android SDKs

To build the Kotlin and Java SDKs with AAR files:

```bash
# First build the core native libraries
./scripts/build-android-lib.sh

# Then build the SDKs and generate AAR files
./scripts/build-android-SDK.sh
```

The `build-android-SDK.sh` script will:
1. Create clean SDK directory structures
2. Copy pre-built native libraries
3. Generate Kotlin and Java wrappers
4. Run tests for both SDKs
5. Generate AAR files for both SDKs

### Output

After successful build:

- **Kotlin SDK**: `llama_mobile-android-SDK/` with AAR files in `build/outputs/aar/`
- **Java SDK**: `llama_mobile-android-java-SDK/` with AAR files in `build/outputs/aar/`

### AAR Files

The generated AAR files can be used in other Android apps:

- **Kotlin SDK**: `llama_mobile-android-SDK/build/outputs/aar/llama_mobile-release.aar`
- **Java SDK**: `llama_mobile-android-java-SDK/build/outputs/aar/llama_mobile-release.aar`

## Requirements
- Android NDK r25+
- CMake 3.21+
- Android API level 21+
- C++17 compatible compiler
