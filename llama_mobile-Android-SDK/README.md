# llama_mobile-android-SDK

A higher-level Android SDK that wraps the `llama_mobile-android` library, providing a more convenient and Kotlin-friendly API for interacting with llama models.

## Overview

The `llama_mobile-android-SDK` provides a streamlined, higher-level API on top of the raw `llama_mobile-android` library. It handles threading, error management, and provides a more intuitive interface for Android developers.

## Features

- Simplified API for model loading and text generation
- Built-in threading support to avoid UI blocking
- Callback-based API for asynchronous operations
- Error handling with descriptive exceptions
- Consistent naming and Kotlin idioms

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

2. Build the Android library and SDK:

```bash
./build-android.sh
```

3. Add both modules as dependencies in your Android Studio project:

```gradle
// settings.gradle
include ':llama_mobile'
include ':llama_mobile_sdk'

project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
project(':llama_mobile_sdk').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-SDK')

// app/build.gradle
dependencies {
    implementation project(':llama_mobile_sdk')
}
```

## Usage

### Basic Example

```kotlin
import com.llamamobile.sdk.LlamaMobileSdk

// Initialize the SDK
val llamaMobileSdk = LlamaMobileSdk()

// Load model
val modelConfig = LlamaMobileSdk.ModelConfig(
    modelPath = "/sdcard/Download/llama-model.gguf",
    contextSize = 1024,
    useMemoryCache = true
)

llamaMobileSdk.loadModel(modelConfig, object : LlamaMobileSdk.ResultCallback<Boolean> {
    override fun onSuccess(result: Boolean) {
        runOnUiThread {
            if (result) {
                // Model loaded successfully
                Toast.makeText(this@MainActivity, "Model loaded", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@MainActivity, "Failed to load model", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onError(error: Throwable) {
        runOnUiThread {
            Toast.makeText(this@MainActivity, "Error: ${error.message}", Toast.LENGTH_LONG).show()
        }
    }
})

// Generate text
val generationConfig = LlamaMobileSdk.GenerationConfig(
    prompt = "Hello, world!",
    temperature = 0.8f,
    maxTokens = 100
)

llamaMobileSdk.generate(generationConfig, object : LlamaMobileSdk.GenerationListener {
    override fun onGenerationStart(prompt: String) {
        runOnUiThread {
            // Update UI to show generation started
            statusTextView.text = "Generating..."
        }
    }

    override fun onGenerationComplete(result: String) {
        runOnUiThread {
            // Display generated text
            resultTextView.text = result
            statusTextView.text = "Generation complete"
        }
    }

    override fun onError(error: Throwable) {
        runOnUiThread {
            Toast.makeText(this@MainActivity, "Error: ${error.message}", Toast.LENGTH_LONG).show()
        }
    }
})

// Release resources when done
llamaMobileSdk.release()
```

## API Reference

### LlamaMobileSdk.ModelConfig

Configuration for loading a model.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `modelPath` | String | Path to the llama model file (.gguf) | - |
| `contextSize` | Int | Size of the context window | 1024 |
| `useMemoryCache` | Boolean | Whether to use memory caching | true |

### LlamaMobileSdk.GenerationConfig

Configuration for generating text completions.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `prompt` | String | Input prompt for text generation | - |
| `temperature` | Float | Temperature for sampling | 0.8 |
| `maxTokens` | Int | Maximum number of tokens to generate | 100 |

### LlamaMobileSdk.ResultCallback<T>

Callback interface for operations that return a single result.

| Method | Description |
|--------|-------------|
| `onSuccess(result: T)` | Called when the operation completes successfully |
| `onError(error: Throwable)` | Called when an error occurs |

### LlamaMobileSdk.GenerationListener

Listener interface for text generation events.

| Method | Description |
|--------|-------------|
| `onGenerationStart(prompt: String)` | Called when generation starts |
| `onGenerationComplete(result: String)` | Called when generation completes successfully |
| `onError(error: Throwable)` | Called when an error occurs during generation |

### LlamaMobileSdk Methods

| Method | Description |
|--------|-------------|
| `loadModel(config: ModelConfig, callback: ResultCallback<Boolean>)` | Loads a model with the specified configuration |
| `generate(config: GenerationConfig, listener: GenerationListener)` | Generates text completion with the specified configuration |
| `release()` | Releases all resources used by the SDK |

## Example App

An example Android app demonstrating how to use the SDK can be found in the `examples/androidSDKExample` directory.

## License

MIT License

## Troubleshooting

### Permission Issues

- Ensure the app has the necessary permissions to read the model file:

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
```

- For Android 13+, use the MediaStore API to access files.

### Memory Issues

- Reduce the `contextSize` parameter to use less memory.
- Set `useMemoryCache = false` to reduce memory usage.

### Performance Issues

- The SDK runs on a single background thread. For multiple concurrent operations, create separate SDK instances.
- Consider reducing `maxTokens` for faster generation.

## Testing

### Test Structure

The Android SDK includes two types of tests:

#### Unit Tests

Unit tests verify core functionality in isolation:

```
src/test/
├── java/com/llamamobile/sdk/      # Unit test classes
└── resources/
    ├── models/                    # Place model files here for unit tests
    └── grammars/                  # Place grammar files here for unit tests
```

#### Instrumented Tests

Instrumented tests verify functionality on actual Android devices or emulators:

```
src/androidTest/
├── java/com/llamamobile/sdk/      # Instrumented test classes
└── resources/
    ├── models/                    # Place model files here for instrumented tests
    └── grammars/                  # Place grammar files here for instrumented tests
```

### Test Resources

#### Models

1. Download a GGUF format model (e.g., `mistral-7b-v0.1.Q4_K_M.gguf`)
2. Copy the model file to both test resource folders:

```bash
# For unit tests
cp model.gguf src/test/resources/models/

# For instrumented tests
cp model.gguf src/androidTest/resources/models/
```

#### Grammars

Grammar files are used for constrained generation tests:

```bash
# Copy grammar files from the Core library
cp -r ../lib/grammars/* src/test/resources/grammars/
cp -r ../lib/grammars/* src/androidTest/resources/grammars/
```

### Running Tests

#### Running Unit Tests

Use Gradle to run unit tests:

```bash
./gradlew test
```

#### Running Instrumented Tests

Use Gradle to run instrumented tests on connected devices/emulators:

```bash
./gradlew connectedAndroidTest
```

#### Running Specific Tests

```bash
# Run specific unit tests
./gradlew test --tests "com.llamamobile.sdk.LlamaMobileSdkUnitTests"

# Run specific instrumented tests
./gradlew connectedAndroidTest --tests "com.llamamobile.sdk.LlamaMobileSdkInstrumentedTests"
```

### Test Coverage

The Android SDK tests cover:

- SDK initialization and model loading
- Text generation and completion
- Error handling
- Threading and callback functionality
- Grammar-constrained generation

### Example Test Class

```kotlin
// src/test/java/com/llamamobile/sdk/LlamaMobileSdkUnitTests.kt
package com.llamamobile.sdk

import org.junit.Test
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull

class LlamaMobileSdkUnitTests {
    
    @Test
    fun testModelConfigCreation() {
        val modelConfig = LlamaMobileSdk.ModelConfig(
            modelPath = "/path/to/model.gguf",
            contextSize = 2048,
            useMemoryCache = true
        )
        
        assertNotNull(modelConfig)
        assertEquals("/path/to/model.gguf", modelConfig.modelPath)
        assertEquals(2048, modelConfig.contextSize)
        assertEquals(true, modelConfig.useMemoryCache)
    }
    
    @Test
    fun testGenerationConfigCreation() {
        val generationConfig = LlamaMobileSdk.GenerationConfig(
            prompt = "Hello, world!",
            temperature = 0.7f,
            maxTokens = 50
        )
        
        assertNotNull(generationConfig)
        assertEquals("Hello, world!", generationConfig.prompt)
        assertEquals(0.7f, generationConfig.temperature, 0.01f)
        assertEquals(50, generationConfig.maxTokens)
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
