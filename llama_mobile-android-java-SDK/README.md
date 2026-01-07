# llama_mobile-android-java-SDK

A Java-based Android SDK that wraps the `llama_mobile-android` library, providing a convenient and Java-friendly API for interacting with llama models.

## Overview

The `llama_mobile-android-java-SDK` provides a streamlined, higher-level Java API on top of the raw `llama_mobile-android` library. It handles threading, error management, and provides an intuitive interface for Java Android developers.

## Features

- Simplified Java API for model loading and text generation
- Built-in threading support to avoid UI blocking
- Callback-based API for asynchronous operations
- Error handling with descriptive exceptions
- Consistent naming and Java idioms
- Grammar-constrained text generation
- Token streaming support

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
include ':llama_mobile_java_sdk'

project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
project(':llama_mobile_java_sdk').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-java-SDK')

// app/build.gradle
dependencies {
    implementation project(':llama_mobile_java_sdk')
}
```

## Usage

### Basic Example

```java
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.InitParams;
import com.llamamobile.LlamaMobile.CompletionParams;

// Initialize the context
InitParams initParams = new InitParams(
    "/sdcard/Download/mistral-7b-v0.1.Q4_K_M.gguf",
    2048 // Context size
);

long contextHandle = LlamaMobile.initContext(initParams);
if (contextHandle != 0) {
    // Generate text completion
    CompletionParams completionParams = new CompletionParams(
        "Hello, how are you?",
        0.8f, // Temperature
        100   // Max tokens
    );
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
    if (result != null) {
        String generatedText = result.getText();
        // Use the generated text
        System.out.println("Generated: " + generatedText);
    }
    
    // Release resources
    LlamaMobile.releaseContext(contextHandle);
}
```

### Example with Streaming

```java
// Initialize context (same as above)

// Create completion params with streaming callback
CompletionParams streamingParams = new CompletionParams(
    "Explain quantum computing in simple terms",
    0.7f,
    200,
    4, // Threads
    -1, // Seed (-1 for random)
    40, // Top K
    0.9, // Top P
    0.05, // Min P
    1.0, // Typical P
    64, // Penalty last N
    1.1, // Penalty repeat
    0.0, // Penalty freq
    0.0, // Penalty present
    0, // Mirostat
    5.0, // Mirostat tau
    0.1, // Mirostat eta
    false, // Ignore EOS
    0, // N probs
    null, // Grammar
    null, // Stop sequences
    token -> {
        // Process each token as it's generated
        System.out.print(token);
        return true; // Return false to stop generation
    }
);

LlamaMobile.generateCompletion(contextHandle, streamingParams);
```

### Example with Grammar Constraints

```java
// Initialize context (same as above)

// Get grammar content
String jsonGrammar = LlamaMobile.grammarContent(getApplicationContext(), LlamaMobile.GrammarName.JSON);

// Create completion params with grammar
CompletionParams jsonParams = new CompletionParams(
    "Generate a JSON object with name and age fields: ",
    0.7f,
    100,
    4,
    -1,
    40,
    0.9,
    0.05,
    1.0,
    64,
    1.1,
    0.0,
    0.0,
    0,
    5.0,
    0.1,
    false,
    0,
    jsonGrammar, // Grammar constraint
    null,
    null
);

LlamaMobile.CompletionResult jsonResult = LlamaMobile.generateCompletion(contextHandle, jsonParams);
// Will generate valid JSON like: {"name": "John", "age": 30}
```

## API Reference

### LlamaMobile.InitParams

Initialization parameters for creating a llama context.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `modelPath` | String | Path to the llama model file (.gguf) | - |
| `nCtx` | int | Context window size | 512 |
| `chatTemplate` | String | Chat template to use | null |
| `systemPrompt` | String | System prompt | null |
| `nGpuLayers` | int | Number of layers to offload to GPU | 0 |
| `nThreads` | int | Number of CPU threads | 4 |
| `useMmap` | boolean | Use memory-mapped I/O | true |
| `cacheType` | CacheType | Cache type (NONE or MEMORY) | MEMORY |

### LlamaMobile.CompletionParams

Configuration for generating text completions.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `prompt` | String | Input prompt for text generation | - |
| `temperature` | float | Temperature for sampling | 0.8 |
| `maxTokens` | int | Maximum number of tokens to generate | 100 |
| `nThreads` | int | Number of CPU threads | 4 |
| `topK` | int | Top-K sampling parameter | 40 |
| `topP` | double | Top-P sampling parameter | 0.9 |
| `penaltyRepeat` | double | Repetition penalty | 1.1 |
| `grammar` | String | Grammar content for constrained generation | null |
| `stopSequences` | List<String> | Stop sequences to end generation | empty |
| `tokenCallback` | TokenCallback | Callback for streaming tokens | null |

### LlamaMobile.TokenCallback

Callback interface for streaming token generation.

| Method | Description |
|--------|-------------|
| `onToken(String token)` | Called for each generated token. Return false to stop generation. |

### LlamaMobile.CompletionResult

Result interface for text generation.

| Method | Description |
|--------|-------------|
| `getText()` | Gets the generated text |

### LlamaMobile Methods

| Method | Description |
|--------|-------------|
| `initContext(InitParams params)` | Initializes a new llama context |
| `generateCompletion(long contextHandle, CompletionParams params)` | Generates text completion |
| `releaseContext(long contextHandle)` | Releases the llama context |
| `grammarContent(Context context, GrammarName name)` | Gets grammar content for constrained generation |

## Testing

### Test Structure

The Android Java SDK includes two types of tests:

#### Unit Tests

Unit tests verify core functionality in isolation:

```
src/test/
├── java/com/llamamobile/      # Unit test classes
└── resources/
    ├── models/                # Place model files here for unit tests
    └── grammars/              # Place grammar files here for unit tests
```

#### Instrumented Tests

Instrumented tests verify functionality on actual Android devices or emulators:

```
src/androidTest/
├── java/com/llamamobile/      # Instrumented test classes
└── resources/
    ├── models/                # Place model files here for instrumented tests
    └── grammars/              # Place grammar files here for instrumented tests
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
./gradlew test --tests "com.llamamobile.LlamaMobileUnitTests"

# Run specific instrumented tests
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileInstrumentedTests"
```

### Test Coverage

The Android Java SDK tests cover:

- SDK initialization and model loading
- Text generation and completion
- Token streaming functionality
- Error handling
- Grammar-constrained generation
- Memory management

### Example Test Class

```java
// src/test/java/com/llamamobile/LlamaMobileUnitTests.java
package com.llamamobile;

import org.junit.Test;
import org.junit.Assert;

public class LlamaMobileUnitTests {
    
    @Test
    public void testInitParamsCreation() {
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(
            "/path/to/model.gguf",
            2048
        );
        
        Assert.assertNotNull(params);
        Assert.assertEquals("/path/to/model.gguf", params.getModelPath());
        Assert.assertEquals(2048, params.getNCtx());
        Assert.assertEquals(0, params.getNGpuLayers());
        Assert.assertEquals(4, params.getNThreads());
    }
    
    @Test
    public void testCompletionParamsCreation() {
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
            "Hello, world!",
            0.7f,
            50
        );
        
        Assert.assertNotNull(params);
        Assert.assertEquals("Hello, world!", params.getPrompt());
        Assert.assertEquals(0.7f, params.getTemperature(), 0.01f);
        Assert.assertEquals(50, params.getMaxTokens());
    }
}
```

## Example App

An example Android app demonstrating how to use the Java SDK can be found in the `examples/androidJavaSDKExample` directory.

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

- Reduce the `nCtx` parameter to use less memory.
- Set `cacheType` to `CacheType.NONE` to reduce memory usage.

### Performance Issues

- Increase the `nThreads` parameter for faster generation (balance with device capabilities).
- Offload layers to GPU by increasing `nGpuLayers` (if device has sufficient GPU memory).
- Consider reducing `maxTokens` for faster generation.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
