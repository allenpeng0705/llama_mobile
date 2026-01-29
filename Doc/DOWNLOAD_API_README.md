# Download API Documentation for iOS

## Overview

The Llama Mobile SDK provides a robust Download API that simplifies the process of downloading models and files, particularly from Hugging Face. This API abstracts the complexity of file downloads, including progress tracking, authentication, and error handling.

## Core Download API

### Download Method

```swift
public func download(with params: DownloadParams) -> DownloadResult
```

#### Parameters:
- `params`: Download configuration parameters

#### Returns:
- `DownloadResult`: Contains the download outcome, local path, and error information if applicable

## Supporting Types

### DownloadParams

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

### DownloadResult

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

## Usage Examples

### 1. Basic Download from Hugging Face

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

### 2. Download with Progress Tracking

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

### 3. Download with Authentication

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

### 4. Downloading a Vocoder Model for TTS

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

### 1. Use Background Threads

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

### 2. Error Handling

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

### 3. Storage Management

Be mindful of storage constraints when downloading large models:

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

### 4. Caching

Consider implementing a caching mechanism to avoid redundant downloads:

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

## Error Handling

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

The Download API in the Llama Mobile SDK provides a convenient and powerful way to download models and files, particularly from Hugging Face. By following the examples and best practices outlined in this documentation, you can implement robust download functionality in your iOS applications.

With support for progress tracking, authentication, and comprehensive error handling, the Download API simplifies the process of acquiring models for use with the Llama Mobile SDK, enabling a seamless user experience even when working with large model files.
