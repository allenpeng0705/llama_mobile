# Download API Documentation

## Overview

The Llama Mobile SDK provides a robust Download API that simplifies the process of downloading models and files, particularly from Hugging Face. This API abstracts the complexity of file downloads, including progress tracking, authentication, and error handling. The API is available on both iOS and Android platforms, with platform-specific implementations for Swift, Kotlin, and Java.

## Table of Contents

1. [Core Download API](#core-download-api)
   - [iOS](#ios-download)
   - [Android Kotlin](#android-kotlin-download)
   - [Android Java](#android-java-download)
2. [Supporting Types](#supporting-types)
   - [iOS](#ios-download-types)
   - [Android Kotlin](#android-kotlin-download-types)
   - [Android Java](#android-java-download-types)
3. [Usage Examples](#usage-examples)
   - [iOS](#ios-download-examples)
   - [Android Kotlin](#android-kotlin-download-examples)
   - [Android Java](#android-java-download-examples)
4. [Implementation Details](#implementation-details)
5. [Best Practices](#best-practices)
   - [1. Use Background Threads](#use-background-threads)
     - [iOS](#ios-background-threads)
     - [Android Kotlin](#android-kotlin-background-threads)
     - [Android Java](#android-java-background-threads)
   - [2. Error Handling](#error-handling)
     - [iOS](#ios-error-handling)
     - [Android Kotlin](#android-kotlin-error-handling)
     - [Android Java](#android-java-error-handling)
   - [3. Storage Management](#storage-management)
     - [iOS](#ios-storage-management)
     - [Android Kotlin](#android-kotlin-storage-management)
     - [Android Java](#android-java-storage-management)
   - [4. Caching](#caching)
     - [iOS](#ios-caching)
     - [Android Kotlin](#android-kotlin-caching)
     - [Android Java](#android-java-caching)
6. [Error Handling](#error-handling-section)
7. [Security Considerations](#security-considerations)
8. [Conclusion](#conclusion)

## Core Download API

### iOS {#ios-download}

#### Download Method

```swift
public func download(with params: DownloadParams) -> DownloadResult
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains the download outcome, local path, and error information if applicable

### Android Kotlin {#android-kotlin-download}

#### Download Method

```kotlin
@JvmStatic
fun download(params: DownloadParams): DownloadResult
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains the download outcome, local path, and error information if applicable

### Android Java {#android-java-download}

#### Download Method

```java
public static DownloadResult download(DownloadParams params)
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains the download outcome, local path, and error information if applicable

## Supporting Types

### iOS {#ios-download-types}

#### DownloadParams

```swift
public struct DownloadParams {
    /// URL to download from (supports Hugging Face repo IDs)
    public var url: String
    
    /// Local path to save the downloaded file
    public var localPath: String
    
    /// Username for authentication (if required)
    public var username: String? = nil
    
    /// Password or API token for authentication (if required)
    public var password: String? = nil
    
    /// Custom HTTP headers for the download request
    public var headers: [String: String]? = nil
    
    /// Callback for download progress (0.0 to 1.0)
    public var progressCallback: ((Float) -> Void)? = nil
    
    /// Default initializer with all parameters
    public init(url: String, localPath: String, username: String? = nil, password: String? = nil, headers: [String: String]? = nil, progressCallback: ((Float) -> Void)? = nil)
}
```

#### DownloadResult

```swift
public struct DownloadResult {
    /// Whether the download was successful
    public var success: Bool
    
    /// Local path where the file was saved
    public var localPath: String
    
    /// Error message if the download failed (nil if successful)
    public var errorMessage: String? = nil
    
    /// Default initializer with all parameters
    public init(success: Bool, localPath: String, errorMessage: String? = nil)
}
```

### Android Kotlin {#android-kotlin-download-types}

#### DownloadParams

```kotlin
data class DownloadParams(
    val url: String,
    val localPath: String,
    val username: String? = null,
    val password: String? = null,
    val headers: Map<String, String>? = null,
    val progressCallback: ((Float) -> Unit)? = null
) {
    companion object {
        @JvmStatic
        fun create(url: String, localPath: String): DownloadParams {
            return DownloadParams(url, localPath)
        }
    }
}
```

#### DownloadResult

```kotlin
data class DownloadResult(
    val success: Boolean,
    val localPath: String,
    val errorMessage: String? = null
)
```

### Android Java {#android-java-download-types}

#### DownloadParams

```java
public static class DownloadParams {
    private final String url;
    private final String localPath;
    private final String username;
    private final String password;
    private final Map<String, String> headers;
    private final ProgressCallback progressCallback;

    private DownloadParams(Builder builder) {
        this.url = builder.url;
        this.localPath = builder.localPath;
        this.username = builder.username;
        this.password = builder.password;
        this.headers = builder.headers;
        this.progressCallback = builder.progressCallback;
    }

    public static class Builder {
        private final String url;
        private final String localPath;
        private String username = null;
        private String password = null;
        private Map<String, String> headers = null;
        private ProgressCallback progressCallback = null;

        public Builder(String url, String localPath) {
            this.url = url;
            this.localPath = localPath;
        }

        public Builder username(String username) {
            this.username = username;
            return this;
        }

        public Builder password(String password) {
            this.password = password;
            return this;
        }

        public Builder headers(Map<String, String> headers) {
            this.headers = headers;
            return this;
        }

        public Builder progressCallback(ProgressCallback progressCallback) {
            this.progressCallback = progressCallback;
            return this;
        }

        public DownloadParams build() {
            return new DownloadParams(this);
        }
    }

    // Getters
    public String getUrl() { return url; }
    public String getLocalPath() { return localPath; }
    public String getUsername() { return username; }
    public String getPassword() { return password; }
    public Map<String, String> getHeaders() { return headers; }
    public ProgressCallback getProgressCallback() { return progressCallback; }
}
```

#### ProgressCallback Interface

```java
public interface ProgressCallback {
    void onProgress(float progress);
}
```

#### DownloadResult

```java
public static class DownloadResult {
    private final boolean success;
    private final String localPath;
    private final String errorMessage;

    private DownloadResult(Builder builder) {
        this.success = builder.success;
        this.localPath = builder.localPath;
        this.errorMessage = builder.errorMessage;
    }

    public static class Builder {
        private final boolean success;
        private final String localPath;
        private String errorMessage = null;

        public Builder(boolean success, String localPath) {
            this.success = success;
            this.localPath = localPath;
        }

        public Builder errorMessage(String errorMessage) {
            this.errorMessage = errorMessage;
            return this;
        }

        public DownloadResult build() {
            return new DownloadResult(this);
        }
    }

    // Getters
    public boolean isSuccess() { return success; }
    public String getLocalPath() { return localPath; }
    public String getErrorMessage() { return errorMessage; }
}
```

## Usage Examples

### iOS {#ios-download-examples}

#### 1. Basic Download from Hugging Face

```swift
func downloadModel() {
    // Create download parameters
    let params = LlamaMobile.DownloadParams(
        url: "meta-llama/Llama-3.2-1B-Instruct",
        localPath: "\(NSTemporaryDirectory())Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    )
    
    // Perform download
    let result = llamaMobile.download(with: params)
    
    // Handle result
    if result.success {
        print("Model downloaded successfully to: \(result.localPath)")
        // Now you can load the model
    } else {
        print("Error downloading model: \(result.errorMessage ?? "Unknown error")")
    }
}
```

#### 2. Download with Progress Tracking

```swift
func downloadModelWithProgress() {
    // Create download parameters with progress callback
    let params = LlamaMobile.DownloadParams(
        url: "meta-llama/Llama-3.2-1B-Instruct",
        localPath: "\(NSTemporaryDirectory())Llama-3.2-1B-Instruct.Q4_K_M.gguf",
        progressCallback: { progress in
            print("Download progress: \(Int(progress * 100))%")
        }
    )
    
    // Perform download
    let result = llamaMobile.download(with: params)
    
    // Handle result
    if result.success {
        print("Model downloaded successfully to: \(result.localPath)")
    } else {
        print("Error downloading model: \(result.errorMessage ?? "Unknown error")")
    }
}
```

#### 3. Download with Authentication

```swift
func downloadPrivateModel() {
    // Create download parameters with authentication
    let params = LlamaMobile.DownloadParams(
        url: "username/private-model",
        localPath: "\(NSTemporaryDirectory())private-model.gguf",
        username: "your-username",
        password: "your-huggingface-token", // Use your Hugging Face API token here
        progressCallback: { progress in
            print("Download progress: \(Int(progress * 100))%")
        }
    )
    
    // Perform download
    let result = llamaMobile.download(with: params)
    
    // Handle result
    if result.success {
        print("Private model downloaded successfully to: \(result.localPath)")
    } else {
        print("Error downloading private model: \(result.errorMessage ?? "Unknown error")")
    }
}
```

#### 4. Downloading a Vocoder Model for TTS

```swift
func downloadVocoderModel() {
    // Create download parameters for vocoder model
    let params = LlamaMobile.DownloadParams(
        url: "facebook/tts-transformer",
        localPath: "\(NSTemporaryDirectory())vocoder-model.gguf",
        progressCallback: { progress in
            print("Vocoder download progress: \(Int(progress * 100))%")
        }
    )
    
    // Perform download
    let result = llamaMobile.download(with: params)
    
    // Handle result
    if result.success {
        print("Vocoder model downloaded successfully to: \(result.localPath)")
        // Now you can set this as the vocoder model path
    } else {
        print("Error downloading vocoder model: \(result.errorMessage ?? "Unknown error")")
    }
}
```

### Android Kotlin {#android-kotlin-download-examples}

#### 1. Basic Download from Hugging Face

```kotlin
fun downloadModel() {
    // Create download parameters
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    )
    
    // Perform download
    val result = LlamaMobile.download(params)
    
    // Handle result
    if (result.success) {
        println("Model downloaded successfully to: ${result.localPath}")
        // Now you can load the model
    } else {
        println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
    }
}
```

#### 2. Download with Progress Tracking

```kotlin
fun downloadModelWithProgress() {
    // Create download parameters with progress callback
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
        progressCallback = { progress ->
            println("Download progress: ${(progress * 100).toInt()}%")
        }
    )
    
    // Perform download
    val result = LlamaMobile.download(params)
    
    // Handle result
    if (result.success) {
        println("Model downloaded successfully to: ${result.localPath}")
    } else {
        println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
    }
}
```

#### 3. Download with Authentication

```kotlin
fun downloadPrivateModel() {
    // Create download parameters with authentication
    val params = DownloadParams(
        url = "username/private-model",
        localPath = "${context.filesDir}/Models/private-model.gguf",
        username = "your-username",
        password = "your-huggingface-token", // Use your Hugging Face API token here
        progressCallback = { progress ->
            println("Download progress: ${(progress * 100).toInt()}%")
        }
    )
    
    // Perform download
    val result = LlamaMobile.download(params)
    
    // Handle result
    if (result.success) {
        println("Private model downloaded successfully to: ${result.localPath}")
    } else {
        println("Error downloading private model: ${result.errorMessage ?: "Unknown error"}")
    }
}
```

#### 4. Downloading a Vocoder Model for TTS

```kotlin
fun downloadVocoderModel() {
    // Create download parameters for vocoder model
    val params = DownloadParams(
        url = "facebook/tts-transformer",
        localPath = "${context.filesDir}/Models/vocoder-model.gguf",
        progressCallback = { progress ->
            println("Vocoder download progress: ${(progress * 100).toInt()}%")
        }
    )
    
    // Perform download
    val result = LlamaMobile.download(params)
    
    // Handle result
    if (result.success) {
        println("Vocoder model downloaded successfully to: ${result.localPath}")
        // Now you can set this as the vocoder model path
    } else {
        println("Error downloading vocoder model: ${result.errorMessage ?: "Unknown error"}")
    }
}
```

### Android Java {#android-java-download-examples}

#### 1. Basic Download from Hugging Face

```java
public void downloadModel() {
    // Create download parameters
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "meta-llama/Llama-3.2-1B-Instruct",
        getFilesDir() + File.separator + "Models" + File.separator + "Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    ).build();
    
    // Perform download
    LlamaMobile.DownloadResult result = LlamaMobile.download(params);
    
    // Handle result
    if (result.isSuccess()) {
        System.out.println("Model downloaded successfully to: " + result.getLocalPath());
        // Now you can load the model
    } else {
        System.out.println("Error downloading model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
    }
}
```

#### 2. Download with Progress Tracking

```java
public void downloadModelWithProgress() {
    // Create download parameters with progress callback
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "meta-llama/Llama-3.2-1B-Instruct",
        getFilesDir() + File.separator + "Models" + File.separator + "Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    )
    .progressCallback(progress -> {
        System.out.println("Download progress: " + (int)(progress * 100) + "%");
    })
    .build();
    
    // Perform download
    LlamaMobile.DownloadResult result = LlamaMobile.download(params);
    
    // Handle result
    if (result.isSuccess()) {
        System.out.println("Model downloaded successfully to: " + result.getLocalPath());
    } else {
        System.out.println("Error downloading model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
    }
}
```

#### 3. Download with Authentication

```java
public void downloadPrivateModel() {
    // Create download parameters with authentication
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "username/private-model",
        getFilesDir() + File.separator + "Models" + File.separator + "private-model.gguf"
    )
    .username("your-username")
    .password("your-huggingface-token") // Use your Hugging Face API token here
    .progressCallback(progress -> {
        System.out.println("Download progress: " + (int)(progress * 100) + "%");
    })
    .build();
    
    // Perform download
    LlamaMobile.DownloadResult result = LlamaMobile.download(params);
    
    // Handle result
    if (result.isSuccess()) {
        System.out.println("Private model downloaded successfully to: " + result.getLocalPath());
    } else {
        System.out.println("Error downloading private model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
    }
}
```

#### 4. Downloading a Vocoder Model for TTS

```java
public void downloadVocoderModel() {
    // Create download parameters for vocoder model
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "facebook/tts-transformer",
        getFilesDir() + File.separator + "Models" + File.separator + "vocoder-model.gguf"
    )
    .progressCallback(progress -> {
        System.out.println("Vocoder download progress: " + (int)(progress * 100) + "%");
    })
    .build();
    
    // Perform download
    LlamaMobile.DownloadResult result = LlamaMobile.download(params);
    
    // Handle result
    if (result.isSuccess()) {
        System.out.println("Vocoder model downloaded successfully to: " + result.getLocalPath());
        // Now you can set this as the vocoder model path
    } else {
        System.out.println("Error downloading vocoder model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
    }
}
```

## Implementation Details

### How It Works

1. **Parameter Validation**: The API validates the input parameters and prepares the download request
2. **Directory Creation**: Automatically creates the destination directory if it doesn't exist
3. **Progress Tracking**: Provides real-time progress updates through the callback
4. **Authentication**: Supports bearer token authentication for private repositories
5. **Error Handling**: Captures and reports errors at each stage of the download process
6. **Cleanup**: Properly frees all allocated resources

### Key Features

1. **Hugging Face Integration**: Simplified downloading from Hugging Face repositories
2. **Progress Monitoring**: Real-time download progress updates
3. **Authentication Support**: Handles private repositories with API tokens
4. **Error Reporting**: Detailed error messages for debugging
5. **Automatic Directory Creation**: Ensures the destination directory exists

## Best Practices

### 1. Use Background Threads {#use-background-threads}

#### iOS {#ios-background-threads}

The `download` method is synchronous and may block the main thread for large downloads. It's recommended to run it on a background thread:

```swift
func downloadModelInBackground() {
    DispatchQueue.global(qos: .background).async {
        let params = LlamaMobile.DownloadParams(
            url: "meta-llama/Llama-3.2-1B-Instruct",
            localPath: "\(NSTemporaryDirectory())Llama-3.2-1B-Instruct.Q4_K_M.gguf",
            progressCallback: { progress in
                DispatchQueue.main.async {
                    // Update UI with progress
                    print("Download progress: \(Int(progress * 100))%")
                }
            }
        )
        
        let result = llamaMobile.download(with: params)
        
        DispatchQueue.main.async {
            if result.success {
                print("Model downloaded successfully to: \(result.localPath)")
                // Update UI to reflect success
            } else {
                print("Error downloading model: \(result.errorMessage ?? "Unknown error")")
                // Update UI to reflect error
            }
        }
    }
}
```

#### Android Kotlin {#android-kotlin-background-threads}

```kotlin
fun downloadModelInBackground() {
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
        progressCallback = { progress ->
            // Update UI with progress on main thread
            Handler(Looper.getMainLooper()).post {
                println("Download progress: ${(progress * 100).toInt()}%")
            }
        }
    )
    
    // Run download on a background thread
    Thread {
        val result = LlamaMobile.download(params)
        
        // Update UI on main thread
        Handler(Looper.getMainLooper()).post {
            if (result.success) {
                println("Model downloaded successfully to: ${result.localPath}")
                // Update UI to reflect success
            } else {
                println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
                // Update UI to reflect error
            }
        }
    }.start()
}

// Using Kotlin Coroutines (recommended)
suspend fun downloadModelWithCoroutines() {
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
        progressCallback = { progress ->
            // Update UI with progress
            println("Download progress: ${(progress * 100).toInt()}%")
        }
    )
    
    // Run download in a background coroutine
    val result = withContext(Dispatchers.IO) {
        LlamaMobile.download(params)
    }
    
    // Handle result (already on main thread if called from lifecycleScope)
    if (result.success) {
        println("Model downloaded successfully to: ${result.localPath}")
        // Update UI to reflect success
    } else {
        println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
        // Update UI to reflect error
    }
}
```

#### Android Java {#android-java-background-threads}

```java
public void downloadModelInBackground() {
    final LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "meta-llama/Llama-3.2-1B-Instruct",
        getFilesDir() + File.separator + "Models" + File.separator + "Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    )
    .progressCallback(new LlamaMobile.ProgressCallback() {
        @Override
        public void onProgress(float progress) {
            // Update UI with progress on main thread
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    System.out.println("Download progress: " + (int)(progress * 100) + "%");
                }
            });
        }
    })
    .build();
    
    // Run download on a background thread
    new Thread(new Runnable() {
        @Override
        public void run() {
            final LlamaMobile.DownloadResult result = LlamaMobile.download(params);
            
            // Update UI on main thread
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    if (result.isSuccess()) {
                        System.out.println("Model downloaded successfully to: " + result.getLocalPath());
                        // Update UI to reflect success
                    } else {
                        System.out.println("Error downloading model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
                        // Update UI to reflect error
                    }
                }
            });
        }
    }).start();
}
```

### 2. Error Handling

#### iOS {#ios-error-handling}

Always handle download errors gracefully:

```swift
func handleDownloadError(_ result: LlamaMobile.DownloadResult) {
    if !result.success {
        switch result.errorMessage {
        case let message where message?.contains("401") == true:
            print("Authentication error: Please check your API token")
        case let message where message?.contains("404") == true:
            print("Not found error: Please check the repository and filename")
        case let message where message?.contains("network") == true:
            print("Network error: Please check your internet connection")
        default:
            print("Download error: \(result.errorMessage ?? "Unknown error")")
        }
    }
}
```

#### Android Kotlin {#android-kotlin-error-handling}

```kotlin
fun handleDownloadError(result: DownloadResult) {
    if (!result.success) {
        val errorMessage = result.errorMessage
        when {
            errorMessage?.contains("401") == true -> {
                println("Authentication error: Please check your API token")
            }
            errorMessage?.contains("404") == true -> {
                println("Not found error: Please check the repository and filename")
            }
            errorMessage?.contains("network") == true -> {
                println("Network error: Please check your internet connection")
            }
            else -> {
                println("Download error: ${errorMessage ?: "Unknown error"}")
            }
        }
    }
}
```

#### Android Java {#android-java-error-handling}

```java
public void handleDownloadError(LlamaMobile.DownloadResult result) {
    if (!result.isSuccess()) {
        String errorMessage = result.getErrorMessage();
        if (errorMessage != null) {
            if (errorMessage.contains("401")) {
                System.out.println("Authentication error: Please check your API token");
            } else if (errorMessage.contains("404")) {
                System.out.println("Not found error: Please check the repository and filename");
            } else if (errorMessage.contains("network")) {
                System.out.println("Network error: Please check your internet connection");
            } else {
                System.out.println("Download error: " + errorMessage);
            }
        } else {
            System.out.println("Download error: Unknown error");
        }
    }
}
```

### 3. Storage Management

Be mindful of storage constraints when downloading large models:

#### iOS {#ios-storage-management}

```swift
func checkStorageBeforeDownload() {
    let fileManager = FileManager.default
    let temporaryDirectory = NSTemporaryDirectory()
    
    do {
        let attributes = try fileManager.attributesOfItem(atPath: temporaryDirectory)
        if let freeSize = attributes[.systemFreeSize] as? Int64 {
            let freeSizeMB = Double(freeSize) / (1024 * 1024)
            
            // Check if there's enough space (assuming model is ~2GB)
            if freeSizeMB < 2500 { // 2.5GB buffer
                print("Warning: Low storage space. Consider freeing up space before downloading.")
                return
            }
        }
    } catch {
        print("Error checking storage: \(error)")
        return
    }
    
    // Proceed with download
    downloadModel()
}
```

#### Android Kotlin {#android-kotlin-storage-management}

```kotlin
fun checkStorageBeforeDownload() {
    val path = context.filesDir
    
    try {
        val statFs = StatFs(path.absolutePath)
        val blockSize = statFs.blockSizeLong
        val availableBlocks = statFs.availableBlocksLong
        val freeSize = availableBlocks * blockSize
        val freeSizeMB = freeSize / (1024 * 1024)
        
        // Check if there's enough space (assuming model is ~2GB)
        if (freeSizeMB < 2500) { // 2.5GB buffer
            println("Warning: Low storage space. Consider freeing up space before downloading.")
            return
        }
    } catch (e: Exception) {
        println("Error checking storage: ${e.message}")
        return
    }
    
    // Proceed with download
    downloadModel()
}
```

#### Android Java {#android-java-storage-management}

```java
public void checkStorageBeforeDownload() {
    File path = getFilesDir();
    
    try {
        StatFs statFs = new StatFs(path.getAbsolutePath());
        long blockSize = statFs.getBlockSizeLong();
        long availableBlocks = statFs.getAvailableBlocksLong();
        long freeSize = availableBlocks * blockSize;
        long freeSizeMB = freeSize / (1024 * 1024);
        
        // Check if there's enough space (assuming model is ~2GB)
        if (freeSizeMB < 2500) { // 2.5GB buffer
            System.out.println("Warning: Low storage space. Consider freeing up space before downloading.");
            return;
        }
    } catch (Exception e) {
        System.out.println("Error checking storage: " + e.getMessage());
        return;
    }
    
    // Proceed with download
    downloadModel();
}
```

### 4. Caching

Consider implementing a caching mechanism to avoid redundant downloads:

#### iOS {#ios-caching}

```swift
func downloadModelIfNeeded() {
    let modelPath = "\(NSTemporaryDirectory())Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    
    // Check if model already exists
    if FileManager.default.fileExists(atPath: modelPath) {
        print("Model already exists at: \(modelPath)")
        // Use existing model
        return
    }
    
    // Download if not exists
    let params = LlamaMobile.DownloadParams(
        url: "meta-llama/Llama-3.2-1B-Instruct",
        localPath: modelPath
    )
    
    let result = llamaMobile.download(with: params)
    
    if result.success {
        print("Model downloaded successfully")
    } else {
        print("Error downloading model: \(result.errorMessage ?? "Unknown error")")
    }
}
```

#### Android Kotlin {#android-kotlin-caching}

```kotlin
fun downloadModelIfNeeded() {
    val modelPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    
    // Check if model already exists
    val file = File(modelPath)
    if (file.exists()) {
        println("Model already exists at: $modelPath")
        // Use existing model
        return
    }
    
    // Download if not exists
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = modelPath
    )
    
    val result = LlamaMobile.download(params)
    
    if (result.success) {
        println("Model downloaded successfully")
    } else {
        println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
    }
}
```

#### Android Java {#android-java-caching}

```java
public void downloadModelIfNeeded() {
    String modelPath = getFilesDir() + File.separator + "Models" + File.separator + "Llama-3.2-1B-Instruct.Q4_K_M.gguf";
    
    // Check if model already exists
    File file = new File(modelPath);
    if (file.exists()) {
        System.out.println("Model already exists at: " + modelPath);
        // Use existing model
        return;
    }
    
    // Download if not exists
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "meta-llama/Llama-3.2-1B-Instruct",
        modelPath
    ).build();
    
    LlamaMobile.DownloadResult result = LlamaMobile.download(params);
    
    if (result.isSuccess()) {
        System.out.println("Model downloaded successfully");
    } else {
        System.out.println("Error downloading model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
    }
}
```

## Error Handling {#error-handling-section}

### Common Error Scenarios

| Error Type | Possible Causes | Solutions |
|------------|----------------|-----------|
| Authentication Error | Invalid API token | Check your Hugging Face API token |
| Not Found Error | Invalid repository or filename | Verify the repository ID and filename |
| Network Error | No internet connection | Check network connectivity |
| Storage Error | Insufficient space or permissions | Free up space and check permissions |
| Directory Creation Error | Invalid path or permissions | Use a valid path with write permissions |

### Error Recovery Strategies

1. **Retry Mechanism**: Implement automatic retries for transient errors
2. **Fallback Models**: Provide smaller model alternatives if downloads fail
3. **Offline Mode**: Check for existing models before attempting downloads
4. **User Feedback**: Provide clear error messages and recovery options

## Security Considerations

1. **API Token Handling**: Never hardcode API tokens in your application
2. **Secure Storage**: Store authentication credentials securely
3. **Network Security**: Ensure downloads use HTTPS
4. **Permission Management**: Request appropriate storage permissions

## Conclusion

The Download API in the Llama Mobile SDK provides a convenient and powerful way to download models and files, particularly from Hugging Face. By following the examples and best practices outlined in this documentation, you can implement robust download functionality in your iOS, Android Kotlin, and Android Java applications.

The API's cross-platform design ensures a consistent experience across all supported platforms, with platform-specific optimizations and patterns to follow each language's best practices. Whether you're building for iOS or Android, the Download API simplifies the process of acquiring models and files, enabling you to focus on creating great user experiences with the Llama Mobile SDK.

With support for progress tracking, authentication, and comprehensive error handling, the Download API simplifies the process of acquiring models for use with the Llama Mobile SDK, enabling a seamless user experience even when working with large model files.
