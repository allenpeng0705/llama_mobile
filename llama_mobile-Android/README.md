# llama_mobile-Android

An Android library that provides bindings for the llama_mobile C library, allowing Android applications to interact with llama models.

## Overview

The `llama_mobile-Android` library provides a Kotlin wrapper around the native llama_mobile C library, enabling Android applications to load and use llama models for text generation tasks.

## Features

- Load llama models (.gguf format)
- Generate text completions
- Configure generation parameters (temperature, max tokens)
- Memory-efficient operation

## Installation

### Prerequisites

- Android SDK 21 or higher
- Android NDK 25 or higher
- CMake 3.22 or higher

### Adding to Your Project

1. Clone the repository:

```bash
git clone https://github.com/yourusername/llama_mobile.git
cd llama_mobile
```

2. Build the Android library using the provided script:

```bash
./build-android.sh
```

3. Add the library as a module dependency in your Android Studio project:

```gradle
// settings.gradle
include ':llama_mobile'
project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-Android')

// app/build.gradle
dependencies {
    implementation project(':llama_mobile')
}
```

## Usage

### Basic Example

```kotlin
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.CacheType

// Initialize the context
val initParams = LlamaMobile.InitParams(
    modelPath = "/sdcard/Download/llama-model.gguf",
    nCtx = 1024,  // Context size
    cacheType = CacheType.MEMORY
)

val contextHandle = LlamaMobile.initContext(initParams)

if (contextHandle != 0L) {
    // Generate completion
    val completionParams = LlamaMobile.CompletionParams(
        prompt = "Hello, world!",
        temperature = 0.8f,
        maxTokens = 100
    )

    val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
    println("Result: $result")

    // Release context when done
    LlamaMobile.releaseContext(contextHandle)
}
```

### Background Threading

It's recommended to perform model loading and text generation on a background thread to avoid blocking the UI:

```kotlin
thread {
    // Load model and generate text here
    val contextHandle = LlamaMobile.initContext(initParams)
    
    if (contextHandle != 0L) {
        val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
        
        runOnUiThread {
            // Update UI with result
            textView.text = result
        }
        
        LlamaMobile.releaseContext(contextHandle)
    }
}
```

## API Reference

### LlamaMobile.InitParams

Parameters for initializing a llama context.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `modelPath` | String | Path to the llama model file (.gguf) | - |
| `nCtx` | Int | Size of the context window | 512 |
| `chatTemplate` | String? | Chat template to use (optional) | null |
| `cacheType` | CacheType | Cache type to use | MEMORY |

### LlamaMobile.CompletionParams

Parameters for generating text completions.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `prompt` | String | Input prompt for text generation | - |
| `temperature` | Float | Temperature for sampling | 0.8 |
| `maxTokens` | Int | Maximum number of tokens to generate | 100 |

### LlamaMobile.CacheType

Enum for cache types:

- `NONE`: No caching
- `MEMORY`: In-memory caching

### LlamaMobile Methods

| Method | Description |
|--------|-------------|
| `initContext(params: InitParams): Long` | Initializes a new llama context and returns a handle |
| `generateCompletion(contextHandle: Long, params: CompletionParams): String?` | Generates text completion for the given prompt |
| `releaseContext(contextHandle: Long)` | Releases the llama context and frees resources |

## Build Instructions

### Prerequisites

- Android Studio
- Android NDK 29.0.14206865 or compatible
- CMake 3.22 or higher

### Building the Library

1. **ANDROID_HOME Configuration**:
   - The `build-android.sh` script automatically detects `ANDROID_HOME` from multiple sources:
     - Android Studio preferences (macOS/Linux)
     - Windows registry (Windows Git Bash)
     - Emulator preferences (macOS)
     - Common SDK paths based on your operating system
   
   - If auto-detection fails, you can set it manually:
     ```bash
     # macOS/Linux
     export ANDROID_HOME=/path/to/your/android/sdk
     ./build-android.sh
     
     # Windows (Git Bash)
     export ANDROID_HOME=C:/path/to/your/android/sdk
     ./build-android.sh
     ```

2. Run the build script:

```bash
./build-android.sh
```

This script will:
- Create platform-specific build directories
- Configure CMake with Android-specific flags
- Build the native libraries for arm64-v8a and x86_64 ABIs in parallel
- Copy the native libraries and Kotlin wrapper to the `llama_mobile-Android` directory

### Using Script Options

The build script now includes a `--help` flag that shows all available options:

```bash
./build-android.sh --help
```

Output:
```
Usage: ./build-android.sh [OPTIONS]

Builds the llama_mobile Android library with cross-platform support.

Options:
  -h, --help              Show this help message and exit
  --abi=ABI1,ABI2         Specify which ABIs to build (default: arm64-v8a,x86_64)
  --ndk-version=VERSION   Use specific NDK version (default: 29.0.14206865)
```

### Building for Specific ABIs

You can specify the ABIs to build for using either the environment variable or the command line option:

```bash
# Using environment variable
ABIS="arm64-v8a,x86_64" ./build-android.sh

# Using command line option
./build-android.sh --abi=arm64-v8a,x86_64
```

Supported ABIs:
- `arm64-v8a` (64-bit ARM, for modern Android devices)
- `x86_64` (64-bit x86, for emulators and some devices)

### Using a Specific NDK Version

You can specify a custom NDK version to use:

```bash
# Using environment variable
NDK_VERSION=29.0.14206865 ./build-android.sh

# Using command line option
./build-android.sh --ndk-version=29.0.14206865
```

### Troubleshooting Build Issues

#### Common Problems and Solutions:

- **ANDROID_HOME not found**:
  - Run `./build-android.sh --help` for detailed configuration instructions
  - Check that Android Studio is installed with SDK
  - Try setting ANDROID_HOME manually with the full path
  - On macOS, check `~/Library/Android/sdk` exists
  - On Linux, check `~/Android/Sdk` or `/opt/android-sdk` exists
  - On Windows, check `C:\Users\<username>\AppData\Local\Android\Sdk` exists

- **NDK version mismatch**:
  - Install the required NDK version from Android Studio SDK Manager
  - Or use the `--ndk-version` flag to specify your installed version
  - Run `ls -la $ANDROID_HOME/ndk/` to see available versions

- **CMake errors**:
  - Ensure CMake 3.22+ is installed
  - On macOS: `brew install cmake`
  - On Ubuntu: `sudo apt-get install cmake`
  - On Windows: Download from [CMake website](https://cmake.org/download/)
  - Verify cmake is in your PATH: `which cmake`

- **Permission errors**:
  - Make the script executable: `chmod +x ./build-android.sh`
  - Run as normal user (not root)

- **Build failures**:
  - Check that you're in the correct directory (root of the llama_mobile repo)
  - Ensure the `lib` directory exists with the C library source code
  - Check that all required dependencies are installed

#### Environment Variables Reference:

| Variable | Description | Default |
|----------|-------------|---------|
| `ANDROID_HOME` | Path to Android SDK | Auto-detected |
| `ABIS` | ABIs to build for | `arm64-v8a,x86_64` |
| `NDK_VERSION` | Android NDK version | `29.0.14206865` |
| `ANDROID_PLATFORM` | Minimum Android API level | `android-21` |
| `CMAKE_BUILD_TYPE` | Build type | `Release` |

## Example App

An example Android app demonstrating how to use the library can be found in the `examples/androidLibExample` directory.

## License

MIT License

## Troubleshooting

### Model Loading Issues

- Ensure the model file path is correct and the app has read permissions for the location.
- For Android 10+, you may need to request the `MANAGE_EXTERNAL_STORAGE` permission.

### Performance Issues

- Reduce the `nCtx` parameter to use less memory.
- Use `CacheType.NONE` to reduce memory usage at the cost of slower generation.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
