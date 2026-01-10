# llama_mobile-android-java-SDK

A Java-based Android SDK that wraps the `llama_mobile-android-SDK` library, providing a convenient and Java-friendly API for interacting with llama models.

## Overview

The `llama_mobile-android-java-SDK` provides a streamlined, higher-level Java API on top of the raw `llama_mobile-android-SDK` library. It handles threading, error management, and provides an intuitive interface for Java Android developers.

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

project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android-SDK')
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

### Model Download Support

The Java SDK includes built-in functionality to download models from Hugging Face repositories directly to your application's storage:

```java
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.DownloadParams;
import com.llamamobile.LlamaMobile.DownloadResult;
import com.llamamobile.LlamaMobile.ProgressCallback;

import java.io.File;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// Create an executor for background tasks
ExecutorService executor = Executors.newSingleThreadExecutor();

// Define the local path for the downloaded model
File filesDir = context.getFilesDir();
String modelPath = new File(filesDir, "llama-2-7b-chat.Q4_K_M.gguf").getAbsolutePath();

// Create download parameters
DownloadParams downloadParams = new DownloadParams(
    "meta-llama/Llama-2-7B-Chat-GGUF", // Hugging Face repository ID
    modelPath
);

executor.execute(new Runnable() {
    @Override
    public void run() {
        // Download the model with progress tracking
        DownloadResult result = LlamaMobile.downloadModel(downloadParams, new ProgressCallback() {
            @Override
            public void onProgress(float progress) {
                final int progressPercentage = Math.round(progress * 100);
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        progressBar.setProgress(progressPercentage);
                        progressText.setText("Downloading: " + progressPercentage + "%");
                    }
                });
            }
        });

        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (result != null && result.isSuccess()) {
                    progressText.setText("Download successful!");
                    
                    // Now initialize the model with the downloaded file
                    initModel(result.getLocalPath());
                } else {
                    String errorMsg = result != null ? result.getErrorMessage() : "Unknown error";
                    progressText.setText("Download failed: " + errorMsg);
                }
            }
        });
    }
});

private void initModel(String modelPath) {
    executor.execute(new Runnable() {
        @Override
        public void run() {
            // Initialize the model
            LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
                modelPath,
                2048,
                null,
                null,
                512,
                512,
                4,
                4,
                true,
                false,
                false,
                0,
                0,
                false,
                null,
                null,
                LlamaMobile.CacheType.MEMORY
            );

            long contextHandle = LlamaMobile.initContext(initParams);
            if (contextHandle != 0) {
                // Model is ready to use
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        statusText.setText("Model initialized successfully!");
                    }
                });
            }
        }
    });
}
```

### Download with Authentication

For private Hugging Face repositories, you can provide a bearer token for authentication:

```java
DownloadParams protectedParams = new DownloadParams(
    "your-username/private-model-repo", // Private Hugging Face repository ID
    modelPath,
    "your-hugging-face-token" // Bearer token for authentication
);

DownloadResult protectedResult = LlamaMobile.download(protectedParams);
```

### Download Specific File

You can also download specific files from Hugging Face repositories:

```java
DownloadResult specificFileResult = LlamaMobile.downloadHfFile(
    "meta-llama/Llama-2-7B-Chat-GGUF", // Repository ID
    "llama-2-7b-chat.Q2_K.gguf", // Specific filename
    destinationPath,
    null, // Bearer token (optional)
    false, // Offline mode
    null // Progress callback (optional)
);
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

### LlamaMobile.ProgressCallback

Callback interface for download progress updates.

| Method | Description |
|--------|-------------|
| `onProgress(float progress)` | Called with download progress (0.0 to 1.0). |

### LlamaMobile.DownloadParams

Parameters for downloading models or files from Hugging Face.

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `url` | String | Hugging Face repository ID (e.g., "meta-llama/Llama-2-7B-Chat-GGUF") | - |
| `localPath` | String | Local path to save the downloaded file | - |
| `password` | String | Bearer token for authentication (optional) | null |

### LlamaMobile.DownloadResult

Result of a download operation.

| Method | Description |
|--------|-------------|
| `isSuccess()` | Whether the download was successful |
| `getLocalPath()` | Local path where the file was saved |
| `getErrorMessage()` | Error message if download failed |
| `getFileSize()` | Size of the downloaded file in bytes |

### LlamaMobile Methods

| Method | Description |
|--------|-------------|
| `initContext(InitParams params)` | Initializes a new llama context |
| `generateCompletion(long contextHandle, CompletionParams params)` | Generates text completion |
| `releaseContext(long contextHandle)` | Releases the llama context |
| `grammarContent(Context context, GrammarName name)` | Gets grammar content for constrained generation |
| `downloadModel(DownloadParams params, ProgressCallback progressCallback)` | Downloads a model from Hugging Face repository |
| `downloadHfFile(String repoId, String filename, String destinationPath, String bearerToken, boolean offline, ProgressCallback progressCallback)` | Downloads a specific file from Hugging Face repository |
| `download(DownloadParams params)` | Convenience method for downloading models |

## Tests

The llama_mobile Android Java SDK includes a comprehensive test suite consisting of both unit tests and instrumented tests to ensure API correctness and reliability.

### Test Structure

The SDK uses two types of tests:

#### Unit Tests

- Located in `src/test/java/com/llamamobile/LlamaMobileUnitTests.java`
- Run on the local JVM without requiring an Android device or emulator
- Test core functionality, parameter validation, and error handling
- Focus on pure Java logic and API structure

```
src/test/
├── java/com/llamamobile/      # Unit test classes
└── resources/
    ├── models/                # Place model files here for unit tests
    └── grammars/              # Place grammar files here for unit tests
```

#### Instrumented Tests

- Located in `src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java`
- Run on physical Android devices or emulators
- Test real-world behavior, device-specific functionality, and integration with Android framework
- Verify API behavior in actual runtime environment

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

#### Using Android Studio

1. Open the `llama_mobile-android-java-SDK` directory in Android Studio
2. **Unit Tests**: 
   - Navigate to `LlamaMobileUnitTests.java` in the Project view
   - Right-click and select "Run 'LlamaMobileUnitTests'"

3. **Instrumented Tests**: 
   - Connect a physical device or start an emulator
   - Navigate to `LlamaMobileInstrumentedTests.java` in the Project view
   - Right-click and select "Run 'LlamaMobileInstrumentedTests'"

#### Using Command Line

```bash
# Navigate to the SDK directory
cd llama_mobile-android-java-SDK

# Run unit tests
./gradlew test

# Run instrumented tests (requires connected device/emulator)
./gradlew connectedAndroidTest

# Run specific unit tests
./gradlew test --tests "com.llamamobile.LlamaMobileUnitTests"

# Run specific instrumented tests
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileInstrumentedTests"
```

### Test Coverage

The test suite covers all major SDK APIs:

- **Initialization**: Context creation, parameter validation, error handling
- **Completion Generation**: Text generation, streaming, parameter combinations
- **Conversation**: Chat API, conversation history, streaming responses
- **Tokenization**: Text-to-tokens and tokens-to-text conversion
- **Embeddings**: Generating and validating embeddings
- **Multimodal**: Vision/audio input processing
- **TTS**: Text-to-speech functionality
- **LoRA Adapters**: Loading and managing adapters
- **Download**: Model downloading with progress tracking
- **Error Handling**: Graceful handling of invalid inputs and failures
- **Grammar Constraints**: Constrained text generation
- **Memory Management**: Resource cleanup and context handling

### Adding New Tests

#### Unit Tests

Add new unit tests to `src/test/java/com/llamamobile/LlamaMobileUnitTests.java`:

```java
package com.llamamobile;

import org.junit.Test;
import org.junit.Assert;

public class LlamaMobileUnitTests {
    
    @Test
    public void testMyNewFeature() {
        // Test implementation
        LlamaMobile.MyNewClass instance = new LlamaMobile.MyNewClass();
        Assert.assertEquals(42, instance.getAnswer());
    }
}
```

#### Instrumented Tests

Add new instrumented tests to `src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java`:

```java
package com.llamamobile;

import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.Assert;

@RunWith(AndroidJUnit4.class)
public class LlamaMobileInstrumentedTests {
    
    @Test
    public void testMyNewFeatureOnDevice() {
        android.content.Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        Assert.assertNotNull(appContext);
        
        // Test implementation with device context
        LlamaMobile.MyNewClass instance = new LlamaMobile.MyNewClass(appContext);
        Assert.assertTrue(instance.isDeviceCompatible());
    }
}```

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
