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
- `DownloadResult`: Contains download outcome, local path, and error information if applicable

### Android Kotlin {#android-kotlin-download}

#### Download Method

```kotlin
@JvmStatic
fun download(params: DownloadParams): DownloadResult
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains download outcome, local path, and error information if applicable

### Android Java {#android-java-download}

#### Download Method

```java
public static DownloadResult download(DownloadParams params)
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains download outcome, local path, and error information if applicable

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
    
    /// Custom HTTP headers for download request
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
    void onProgress(float progress, String status, long downloadedBytes, long totalBytes);
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
        println("Vocoder downloaded successfully to: ${result.localPath}")
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
    .progressCallback((progress, status, downloadedBytes, totalBytes) -> {
        System.out.println("Download progress: " + (int)(progress * 100) + "%");
        System.out.println("Status: " + status);
        System.out.println("Downloaded: " + downloadedBytes + " / " + totalBytes + " bytes");
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
    .progressCallback((progress, status, downloadedBytes, totalBytes) -> {
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
    .progressCallback((progress, status, downloadedBytes, totalBytes) -> {
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

1. **Parameter Validation**: The API validates input parameters and prepares the download request
2. **Directory Creation**: Automatically creates the destination directory if it doesn't exist
3. **Progress Tracking**: Provides real-time progress updates through callback
4. **Authentication**: Supports bearer token authentication for private repositories
5. **Error Handling**: Captures and reports errors at each stage of the download process
6. **Cleanup**: Properly frees all allocated resources

### Platform-Specific Implementations

#### iOS Implementation

The iOS SDK uses **URLSession** for native networking:

- **Built-in SSL/TLS**: No external dependencies required
- **Native Progress Tracking**: Uses KVO (Key-Value Observing) for progress updates
- **Error Handling**: Comprehensive error messages for network issues
- **Automatic Retry**: Built-in retry logic for transient failures

#### Android Implementation

The Android SDK uses **HttpURLConnection** for native networking:

- **Built-in SSL/TLS**: No external dependencies required (no OpenSSL needed)
- **Native Progress Tracking**: Real-time progress updates during download
- **Error Handling**: Comprehensive error messages for network issues
- **Thread Safety**: Designed to work with Android's threading model

### Key Features

1. **Hugging Face Integration**: Simplified downloading from Hugging Face repositories
2. **Progress Monitoring**: Real-time download progress updates
3. **Authentication Support**: Handles private repositories with API tokens
4. **Error Reporting**: Detailed error messages for debugging
5. **Automatic Directory Creation**: Ensures the destination directory exists
6. **Platform-Native**: Uses platform-specific networking APIs for optimal performance

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

Use Kotlin coroutines for background downloads:

```kotlin
fun downloadModelInBackground() {
    CoroutineScope(Dispatchers.IO).launch {
        val params = DownloadParams(
            url = "meta-llama/Llama-3.2-1B-Instruct",
            localPath = "${context.filesDir}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
            progressCallback = { progress ->
                withContext(Dispatchers.Main) {
                    // Update UI with progress
                    println("Download progress: ${(progress * 100).toInt()}%")
                }
            }
        )
        
        val result = LlamaMobile.download(params)
        
        withContext(Dispatchers.Main) {
            if (result.success) {
                println("Model downloaded successfully to: ${result.localPath}")
                // Update UI to reflect success
            } else {
                println("Error downloading model: ${result.errorMessage ?: "Unknown error"}")
                // Update UI to reflect error
            }
        }
    }
}
```

#### Android Java {#android-java-background-threads}

Use threads for background downloads:

```java
public void downloadModelInBackground() {
    new Thread(() -> {
        LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
            "meta-llama/Llama-3.2-1B-Instruct",
            getFilesDir() + File.separator + "Models" + File.separator + "Llama-3.2-1B-Instruct.Q4_K_M.gguf"
        )
        .progressCallback((progress, status, downloadedBytes, totalBytes) -> {
            runOnUiThread(() -> {
                // Update UI with progress
                System.out.println("Download progress: " + (int)(progress * 100) + "%");
            });
        })
        .build();
        
        LlamaMobile.DownloadResult result = LlamaMobile.download(params);
        
        runOnUiThread(() -> {
            if (result.isSuccess()) {
                System.out.println("Model downloaded successfully to: " + result.getLocalPath());
                // Update UI to reflect success
            } else {
                System.out.println("Error downloading model: " + (result.getErrorMessage() != null ? result.getErrorMessage() : "Unknown error"));
                // Update UI to reflect error
            }
        });
    }).start();
}
```

### 2. Error Handling {#error-handling}

#### iOS {#ios-error-handling}

The iOS SDK provides detailed error messages for common scenarios:

- **Network Connection Lost**: "Network connection lost. Please check your internet connection and try again."
- **Connection Timeout**: "Connection timed out. Please check your internet connection and try again."
- **No Internet Connection**: "No internet connection. Please check your network settings."
- **HTTP Errors**: "HTTP error: {status_code}"
- **File System Errors**: "Failed to create destination directory: {error}"

#### Android Kotlin {#android-kotlin-error-handling}

The Android SDK provides detailed error messages for common scenarios:

- **Socket Timeout**: Connection timeout errors
- **Unknown Host**: DNS resolution failures
- **IOException**: General I/O errors
- **HTTP Errors**: HTTP status code errors

#### Android Java {#android-java-error-handling}

The Android SDK provides detailed error messages for common scenarios:

- **Socket Timeout**: "Connection timed out. Please check your internet connection and try again."
- **Unknown Host**: "No internet connection. Please check your network settings."
- **IOException**: "Download failed: {error_message}"
- **HTTP Errors**: "HTTP error: {status_code}"

### 3. Storage Management {#storage-management}

#### iOS {#ios-storage-management}

iOS apps should use appropriate directories for storing downloaded models:

```swift
// Use documents directory for persistent storage
let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let modelsDir = documentsDir.appendingPathComponent("models")

// Use temporary directory for temporary files
let tempDir = FileManager.default.temporaryDirectory
```

#### Android Kotlin {#android-kotlin-storage-management}

Android apps should use appropriate directories for storing downloaded models:

```kotlin
// Use files directory for persistent storage
val modelsDir = context.filesDir
val modelsPath = File(modelsDir, "Models")

// Use cache directory for temporary files
val cacheDir = context.cacheDir
```

#### Android Java {#android-java-storage-management}

Android apps should use appropriate directories for storing downloaded models:

```java
// Use files directory for persistent storage
File modelsDir = context.getFilesDir();
File modelsPath = new File(modelsDir, "Models");

// Use cache directory for temporary files
File cacheDir = context.getCacheDir();
```

### 4. Caching {#caching}

#### iOS {#ios-caching}

Consider implementing caching for frequently downloaded models:

```swift
func downloadModelWithCache() {
    let cacheKey = "meta-llama/Llama-3.2-1B-Instruct"
    let cachePath = getCacheDirectory().appendingPathComponent(cacheKey)
    
    if FileManager.default.fileExists(atPath: cachePath.path) {
        print("Model found in cache: \(cachePath.path)")
        return DownloadResult(success: true, localPath: cachePath.path)
    }
    
    // Download to cache
    let params = LlamaMobile.DownloadParams(
        url: "meta-llama/Llama-3.2-1B-Instruct",
        localPath: cachePath.path
    )
    
    let result = llamaMobile.download(with: params)
    return result
}
```

#### Android Kotlin {#android-kotlin-caching}

Consider implementing caching for frequently downloaded models:

```kotlin
fun downloadModelWithCache() {
    val cacheKey = "meta-llama/Llama-3.2-1B-Instruct"
    val cachePath = File(context.cacheDir, cacheKey)
    
    if (cachePath.exists()) {
        println("Model found in cache: ${cachePath.absolutePath}")
        return DownloadResult(success = true, localPath = cachePath.absolutePath)
    }
    
    // Download to cache
    val params = DownloadParams(
        url = "meta-llama/Llama-3.2-1B-Instruct",
        localPath = cachePath.absolutePath
    )
    
    val result = LlamaMobile.download(params)
    return result
}
```

#### Android Java {#android-java-caching}

Consider implementing caching for frequently downloaded models:

```java
public void downloadModelWithCache() {
    String cacheKey = "meta-llama/Llama-3.2-1B-Instruct";
    File cachePath = new File(context.getCacheDir(), cacheKey);
    
    if (cachePath.exists()) {
        System.out.println("Model found in cache: " + cachePath.getAbsolutePath());
        return;
    }
    
    // Download to cache
    LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(
        "meta-llama/Llama-3.2-1B-Instruct",
        cachePath.getAbsolutePath()
    ).build();
    
    LlamaMobile.download(params);
}
```

## Error Handling {#error-handling-section}

### Common Error Scenarios

1. **Network Issues**: Check internet connection and VPN settings
2. **Authentication Failures**: Verify API tokens and permissions
3. **Storage Issues**: Ensure sufficient disk space and write permissions
4. **HTTP Errors**: Check status codes and server availability
5. **File System Errors**: Verify directory permissions and disk space

### Error Recovery Strategies

1. **Retry Logic**: Implement exponential backoff for retries
2. **Fallback URLs**: Use mirror sites if primary fails
3. **Partial Downloads**: Resume interrupted downloads if supported
4. **User Feedback**: Provide clear error messages and recovery options

## Security Considerations

### API Token Management

1. **Never Hardcode Tokens**: Use secure storage (Keychain, Keystore)
2. **Token Rotation**: Implement token refresh mechanisms
3. **Token Scoping**: Use tokens with minimal required permissions
4. **Token Revocation**: Handle token expiration gracefully

### Network Security

1. **HTTPS Only**: Always use HTTPS for downloads
2. **Certificate Validation**: Enable certificate pinning for sensitive downloads
3. **Proxy Support**: Respect system proxy settings
4. **VPN Compatibility**: Ensure downloads work with VPN connections

### Data Privacy

1. **User Consent**: Obtain user consent before downloading large files
2. **Storage Location**: Use app-specific directories
3. **Data Deletion**: Provide options to clear downloaded models
4. **Usage Tracking**: Track download usage for analytics (with consent)

## Conclusion

The Download API provides a robust, cross-platform solution for downloading models and files from Hugging Face and other sources. With platform-specific implementations for iOS (URLSession) and Android (HttpURLConnection), the API offers:

- **Native Performance**: Optimized for each platform
- **Built-in Security**: SSL/TLS support without external dependencies
- **Progress Tracking**: Real-time download progress updates
- **Error Handling**: Comprehensive error messages and recovery
- **Authentication Support**: Handles private repositories with API tokens

For more information, see the LLM API documentation for loading models and the TTS API documentation for vocoder model downloads.
