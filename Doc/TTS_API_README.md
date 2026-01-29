# TTS (Text-to-Speech) API Documentation for iOS

## Overview

This document provides comprehensive documentation for the Text-to-Speech (TTS) capabilities in the Llama Mobile iOS SDK. The SDK offers multiple API options for generating speech from text, including asynchronous, synchronous, and streaming interfaces.

## Table of Contents

1. [Core TTS APIs](#core-tts-apis)
2. [Supporting Types](#supporting-types)
3. [API Usage Examples](#api-usage-examples)
4. [Implementation Details](#implementation-details)
5. [Streaming Implementation](#streaming-implementation)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)

## Core TTS APIs

### 1. Asynchronous API: `generateSpeech`

Generates speech from text asynchronously with progress tracking.

```swift
func generateSpeech(
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Void)? = nil
) async -> Result<SpeechResult, TTSError>
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Configuration options for TTS (sample rate, file saving, etc.)
- `progressHandler`: Optional callback for progress updates (0.0 to 1.0)

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

### 2. Synchronous API: `generateSpeechSync`

Generates speech from text synchronously (blocks the calling thread).

```swift
func generateSpeechSync(
    text: String,
    options: TTSOptions = TTSOptions()
) -> Result<SpeechResult, TTSError>
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Configuration options for TTS

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

### 3. Streaming API: `generateSpeechStream`

Generates speech from text with streaming support (simplified implementation).

```swift
func generateSpeechStream(
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Void)? = nil,
    audioChunkHandler: @escaping ([Int16]) -> Void
) async -> Result<SpeechMetadata, TTSError>
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

### 4. Real Streaming for Long Text: `generateSpeechStreamForLongText`

Generates speech from long text with real streaming capabilities.

```swift
func generateSpeechStreamForLongText(
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Void)? = nil,
    audioChunkHandler: @escaping ([Int16]) -> Void
) async -> Result<SpeechMetadata, TTSError>
```

**Parameters:**
- `text`: Long text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks as they're generated

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

## Supporting Types

### TTSOptions

Configuration options for TTS operations.

```swift
struct TTSOptions {
    var sampleRate: Int = 24000
    var voice: String? = nil
    var speed: Float = 1.0
    var saveToFile: Bool = false
    var outputFilePath: String? = nil
}
```

### SpeechResult

Result of successful speech generation.

```swift
struct SpeechResult {
    var audioSamples: [Int16]
    var sampleRate: Int
    var duration: TimeInterval
    var outputFilePath: String?
    var methodUsed: TTSMethod
}
```

### SpeechMetadata

Metadata for speech generation (used in streaming).

```swift
struct SpeechMetadata {
    var sampleRate: Int
    var duration: TimeInterval
    var methodUsed: TTSMethod
    var outputFilePath: String?
}
```

### TTSError

Error types for TTS operations.

```swift
enum TTSError: Error {
    case noModelLoaded
    case noVocoderEnabled
    case invalidText
    case generationFailed
    case formattingFailed
    case tokenizationFailed
    case audioDecodingFailed
    case fileSaveFailed
    case unknownError(String)
}
```

### TTSMethod

Method used for speech generation.

```swift
enum TTSMethod {
    case builtIn
    case customWorkflow
}
```

## API Usage Examples

### Asynchronous API Example

```swift
func speakAsync() async {
    let text = "Hello, this is a test of the asynchronous TTS API."
    
    let result = await llamaMobile.generateSpeech(
        text: text,
        options: TTSOptions(
            sampleRate: 24000,
            saveToFile: true,
            outputFilePath: NSTemporaryDirectory().appending("tts_output.wav")
        ),
        progressHandler: { progress in
            print("TTS Progress: \(Int(progress * 100))%")
        }
    )
    
    switch result {
    case .success(let speechResult):
        print("Speech generated successfully!")
        print("Sample rate: \(speechResult.sampleRate)")
        print("Duration: \(speechResult.duration) seconds")
        print("Method used: \(speechResult.methodUsed)")
        if let filePath = speechResult.outputFilePath {
            print("Saved to: \(filePath)")
        }
        // Play the audio samples
        playAudio(speechResult.audioSamples, sampleRate: speechResult.sampleRate)
        
    case .failure(let error):
        print("Error generating speech: \(error)")
    }
}
```

### Synchronous API Example

```swift
func speakSync() {
    let text = "Hello, this is a test of the synchronous TTS API."
    
    let result = llamaMobile.generateSpeechSync(
        text: text,
        options: TTSOptions(sampleRate: 24000)
    )
    
    switch result {
    case .success(let speechResult):
        print("Speech generated successfully!")
        print("Duration: \(speechResult.duration) seconds")
        // Play the audio samples
        playAudio(speechResult.audioSamples, sampleRate: speechResult.sampleRate)
        
    case .failure(let error):
        print("Error generating speech: \(error)")
    }
}
```

### Streaming API Example

```swift
func speakWithStreaming() async {
    let text = "Hello, this is a test of the streaming TTS API."
    
    let result = await llamaMobile.generateSpeechStream(
        text: text,
        options: TTSOptions(sampleRate: 24000),
        progressHandler: { progress in
            print("Streaming Progress: \(Int(progress * 100))%")
        },
        audioChunkHandler: { audioChunk in
            print("Received audio chunk with \(audioChunk.count) samples")
            // Play the audio chunk
            playAudioChunk(audioChunk, sampleRate: 24000)
        }
    )
    
    switch result {
    case .success(let metadata):
        print("Streaming completed successfully!")
        print("Sample rate: \(metadata.sampleRate)")
        print("Method used: \(metadata.methodUsed)")
        
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Real Streaming for Long Text Example

```swift
func speakLongTextWithStreaming() async {
    let longText = """
    Hello! This is a long text example for streaming TTS. 
    This text will be split into multiple chunks and played continuously.
    Each sentence will be generated and played as soon as it's ready.
    This provides a much better user experience for long texts.
    """
    
    let result = await llamaMobile.generateSpeechStreamForLongText(
        text: longText,
        options: TTSOptions(sampleRate: 24000),
        progressHandler: { progress in
            print("Long Text Streaming Progress: \(Int(progress * 100))%")
        },
        audioChunkHandler: { audioChunk in
            print("Received audio chunk with \(audioChunk.count) samples")
            // Play the audio chunk immediately
            playAudioChunk(audioChunk, sampleRate: 24000)
        }
    )
    
    switch result {
    case .success(let metadata):
        print("Long text streaming completed successfully!")
        print("Total duration: \(metadata.duration) seconds")
        print("Method used: \(metadata.methodUsed)")
        
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

## Implementation Details

### TTS Workflow

The TTS system implements two main paths for speech generation:

#### Path 1: Built-in TTS

Used for known TTS models identified by `getTTSType()`.

1. **Text Input**: Receive text to convert to speech
2. **Built-in Generation**: Call `generateAudioFromText()` directly
3. **Audio Output**: Return generated audio samples

#### Path 2: Custom Workflow

Used as a fallback for other models.

1. **Text Formatting**: Format text for TTS using `getFormattedAudioCompletion()`
2. **Guide Token Generation**: Generate guide tokens using `getAudioGuideTokens()`
3. **Text Completion**: Generate audio content using `generateCompletion()`
4. **Tokenization**: Tokenize the combined prompt and completion
5. **Audio Decoding**: Decode audio tokens using `decodeAudioTokens()`
6. **Audio Output**: Return generated audio samples

### Progress Tracking

Progress tracking is implemented through a callback mechanism with the following stages:

- 0.1: Initialization
- 0.2: Model check completed
- 0.3: Starting built-in TTS method
- 0.4: Starting custom workflow (if needed)
- 0.6: Built-in method completed
- 0.8: Audio generation completed
- 1.0: Process completed

### Multi-threading

The TTS system uses Swift's async/await and `Task.detached` to handle multi-threading:

1. **Main Thread**: UI updates and user interactions
2. **Background Threads**: Audio generation and processing
3. **Parallel Execution**: Allows audio generation and playback to happen concurrently

## Streaming Implementation

### Simplified Streaming (`generateSpeechStream`)

1. **Full Generation First**: Generates the entire audio first using `generateSpeech`
2. **Single Chunk Delivery**: Sends the entire audio as a single chunk
3. **Metadata Return**: Returns metadata about the generated speech

### Real Streaming for Long Text (`generateSpeechStreamForLongText`)

1. **Text Splitting**: Splits long text into smaller chunks by sentence boundaries
2. **Sequential Processing**: Processes each chunk sequentially
3. **Real-time Delivery**: Sends each chunk for playback as soon as it's generated
4. **Continuous Playback**: Enables seamless continuous speech for long texts

## Error Handling

The TTS system provides comprehensive error handling through the `TTSError` enum:

- **noModelLoaded**: No model is currently loaded
- **noVocoderEnabled**: Vocoder is not enabled for the current model
- **invalidText**: Input text is invalid or empty
- **generationFailed**: Failed to generate audio from text
- **formattingFailed**: Failed to format text for TTS
- **tokenizationFailed**: Failed to tokenize text
- **audioDecodingFailed**: Failed to decode audio tokens
- **fileSaveFailed**: Failed to save audio to file
- **unknownError**: An unknown error occurred

## Best Practices

### For Short Text

- Use `generateSpeech` (async) for most use cases
- Use `generateSpeechSync` only when necessary (e.g., in background threads)

### For Long Text

- Use `generateSpeechStreamForLongText` for the best user experience
- Implement a queue-based audio player for continuous playback

### For Real-time Applications

- Use `generateSpeechStreamForLongText` with a low-latency audio player
- Consider using smaller text chunks for faster response times

### For Memory Management

- Use streaming APIs for long text to avoid loading large audio files into memory
- Set `saveToFile` to `true` for long audio to reduce memory usage

### For Error Recovery

- Implement retry logic for transient errors
- Provide clear error messages to users
- Consider fallback to text display if TTS fails

## Audio Player Implementation

Here's an example of a simple audio player that can handle continuous TTS playback:

```swift
class TTSAudioPlayer {
    private var audioQueue: [Data] = []
    private var isPlaying = false
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "TTSAudioPlayer.queue")
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        try? audioEngine.start()
    }
    
    func playAudioChunk(_ samples: [Int16], sampleRate: Int) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Convert Int16 samples to PCM buffer
            let buffer = self.createPCMBuffer(from: samples, sampleRate: sampleRate)
            guard let buffer = buffer else { return }
            
            // Add to queue
            self.audioQueue.append(buffer)
            
            // Start playing if not already
            if !self.isPlaying {
                self.processQueue()
            }
        }
    }
    
    private func processQueue() {
        guard !audioQueue.isEmpty else {
            isPlaying = false
            return
        }
        
        isPlaying = true
        
        let buffer = audioQueue.removeFirst()
        
        // Play the buffer
        playerNode.scheduleBuffer(buffer) { [weak self] in
            self?.processQueue()
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    private func createPCMBuffer(from samples: [Int16], sampleRate: Int) -> AVAudioPCMBuffer? {
        // Implementation to convert Int16 samples to AVAudioPCMBuffer
        // This is a simplified example - actual implementation would be more detailed
        return nil
    }
}
```

## Conclusion

The TTS API in the Llama Mobile iOS SDK provides a comprehensive set of tools for generating speech from text. With asynchronous, synchronous, and streaming options, developers can choose the best approach for their specific use case. The real streaming implementation for long text enables continuous playback with minimal latency, providing an excellent user experience for longer pieces of text.

By following the best practices outlined in this document, developers can create robust, responsive TTS applications that work seamlessly across different types of content and device configurations.