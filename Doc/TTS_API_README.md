# TTS (Text-to-Speech) API Documentation

## Overview

This document provides comprehensive documentation for the Text-to-Speech (TTS) capabilities in the Llama Mobile SDK across multiple platforms. The SDK offers consistent API options for generating speech from text, including asynchronous, synchronous, and streaming interfaces, with platform-specific implementations for iOS, Android Kotlin, and Android Java.

## Table of Contents

1. [Core TTS APIs](#core-tts-apis)
   - [iOS](#ios)
   - [Android Kotlin](#android-kotlin)
   - [Android Java](#android-java)
   - [Flutter](#flutter)
2. [Supporting Types](#supporting-types)
   - [iOS](#ios-1)
   - [Android Kotlin](#android-kotlin-1)
   - [Android Java](#android-java-1)
   - [Flutter](#flutter-1)
3. [API Usage Examples](#api-usage-examples)
   - [iOS](#ios-2)
   - [Android Kotlin](#android-kotlin-2)
   - [Android Java](#android-java-2)
   - [Flutter](#flutter-2)
4. [Implementation Details](#implementation-details)
5. [Streaming Implementation](#streaming-implementation)
6. [Error Handling](#error-handling)
7. [Best Practices](#best-practices)
8. [Platform-Specific Notes](#platform-specific-notes)

## Core TTS APIs

### iOS

#### 1. Asynchronous API: `generateSpeech`

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

#### 2. Synchronous API: `generateSpeechSync`

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

#### 3. Streaming API: `generateSpeechStream`

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

#### 4. Real Streaming for Long Text: `generateSpeechStreamForLongText`

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

### Android Kotlin

#### 1. Asynchronous API: `generateSpeech`

Generates speech from text asynchronously with progress tracking.

```kotlin
@JvmStatic
fun generateSpeech(
    contextHandle: Long,
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Unit)? = null
): Result<SpeechResult, TTSError>
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS (sample rate, file saving, etc.)
- `progressHandler`: Optional callback for progress updates (0.0 to 1.0)

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

#### 2. Synchronous API: `generateSpeechSync`

Generates speech from text synchronously (blocks the calling thread).

```kotlin
@JvmStatic
fun generateSpeechSync(
    contextHandle: Long,
    text: String,
    options: TTSOptions = TTSOptions()
): Result<SpeechResult, TTSError>
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

#### 3. Streaming API: `generateSpeechStream`

Generates speech from text with streaming support (simplified implementation).

```kotlin
@JvmStatic
fun generateSpeechStream(
    contextHandle: Long,
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Unit)? = null,
    audioChunkHandler: AudioChunkCallback
): Result<SpeechMetadata, TTSError>
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

#### 4. Real Streaming for Long Text: `generateSpeechStreamForLongText`

Generates speech from long text with real streaming capabilities.

```kotlin
@JvmStatic
fun generateSpeechStreamForLongText(
    contextHandle: Long,
    text: String,
    options: TTSOptions = TTSOptions(),
    progressHandler: ((Float) -> Unit)? = null,
    audioChunkHandler: AudioChunkCallback
): Result<SpeechMetadata, TTSError>
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Long text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks as they're generated

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

### Android Java

#### 1. Asynchronous API: `generateSpeech`

Generates speech from text asynchronously with progress tracking.

```java
public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler)
public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text)
public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, ProgressCallback progressHandler)
public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, TTSOptions options)
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS (sample rate, file saving, etc.)
- `progressHandler`: Optional callback for progress updates (0.0 to 1.0)

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

#### 2. Synchronous API: `generateSpeechSync`

Generates speech from text synchronously (blocks the calling thread).

```java
public static Result<SpeechResult, TTSError> generateSpeechSync(long contextHandle, String text, TTSOptions options)
public static Result<SpeechResult, TTSError> generateSpeechSync(long contextHandle, String text)
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS

**Returns:**
- `Result<SpeechResult, TTSError>`: Contains generated audio samples and metadata on success, or error on failure

#### 3. Streaming API: `generateSpeechStream`

Generates speech from text with streaming support (simplified implementation).

```java
public static Result<SpeechMetadata, TTSError> generateSpeechStream(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler, AudioChunkCallback audioChunkHandler)
public static Result<SpeechMetadata, TTSError> generateSpeechStream(long contextHandle, String text, AudioChunkCallback audioChunkHandler)
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

#### 4. Real Streaming for Long Text: `generateSpeechStreamForLongText`

Generates speech from long text with real streaming capabilities.

```java
public static Result<SpeechMetadata, TTSError> generateSpeechStreamForLongText(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler, AudioChunkCallback audioChunkHandler)
public static Result<SpeechMetadata, TTSError> generateSpeechStreamForLongText(long contextHandle, String text, AudioChunkCallback audioChunkHandler)
```

**Parameters:**
- `contextHandle`: Context handle obtained from `initContext`
- `text`: Long text to convert to speech
- `options`: Configuration options for TTS
- `progressHandler`: Optional callback for progress updates
- `audioChunkHandler`: Callback for receiving audio chunks as they're generated

**Returns:**
- `Result<SpeechMetadata, TTSError>`: Contains metadata on success, or error on failure

### Flutter

The Flutter SDK provides TTS functionality through the `LlamaContext` class. All TTS methods are available on a context instance after loading a TTS model.

#### 1. Asynchronous API: `generateSpeech`

Generates speech from text asynchronously.

```dart
Future<Map<String, dynamic>?> generateSpeech(
  String text, {
  Map<String, dynamic>? options,
})
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath)

**Returns:**
- A `Future<Map<String, dynamic>?>` containing audio data and metadata, or null if an error occurred

**Example:**
```dart
final result = await context?.generateSpeech(
  'Hello, world!',
  options: {
    'sampleRate': 24000,
    'speed': 1.0,
    'saveToFile': false,
  },
);

if (result != null) {
  final audioSamples = result['audioSamples'] as List<int>;
  final sampleRate = result['sampleRate'] as int;
  final duration = result['duration'] as double;
  print('Generated ${audioSamples.length} samples at ${sampleRate}Hz');
}
```

#### 2. Synchronous API: `generateSpeechSync`

Generates speech from text synchronously (blocks the calling thread).

```dart
Future<Map<String, dynamic>?> generateSpeechSync(
  String text, {
  Map<String, dynamic>? options,
})
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath)

**Returns:**
- A `Future<Map<String, dynamic>?>` containing audio data and metadata, or null if an error occurred

**Example:**
```dart
final result = await context?.generateSpeechSync(
  'Hello, world!',
  options: {
    'sampleRate': 24000,
    'speed': 1.0,
  },
);
```

#### 3. Streaming API: `generateSpeechStream`

Generates speech from text with streaming support (simplified implementation).

```dart
Future<Map<String, dynamic>?> generateSpeechStream(
  String text, {
  Map<String, dynamic>? options,
})
```

**Parameters:**
- `text`: Text to convert to speech
- `options`: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath)

**Returns:**
- A `Future<Map<String, dynamic>?>` containing stream metadata, or null if an error occurred

**Example:**
```dart
final result = await context?.generateSpeechStream(
  'Hello, world!',
  options: {
    'sampleRate': 24000,
  },
);
```

#### 4. Real Streaming for Long Text: `generateSpeechStreamForLongText`

Generates speech from long text with real streaming capabilities.

```dart
Future<Map<String, dynamic>?> generateSpeechStreamForLongText(
  String text, {
  Map<String, dynamic>? options,
})
```

**Parameters:**
- `text`: Long text to convert to speech
- `options`: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath)

**Returns:**
- A `Future<Map<String, dynamic>?>` containing stream metadata, or null if an error occurred

**Example:**
```dart
final result = await context?.generateSpeechStreamForLongText(
  'This is a long text that will be processed in chunks...',
  options: {
    'sampleRate': 24000,
  },
);
```

#### 5. Save Audio to WAV: `saveAudioToWav`

Saves audio samples to a WAV file.

```dart
Future<bool> saveAudioToWav(
  String filePath,
  List<int> audioSamples,
  int sampleRate,
)
```

**Parameters:**
- `filePath`: Path to save the WAV file
- `audioSamples`: List of audio samples (int16 values)
- `sampleRate`: Sample rate of the audio (Hz)

**Returns:**
- A `Future<bool>` indicating success

**Example:**
```dart
final result = await context?.generateSpeech('Hello, world!');
if (result != null) {
  final audioSamples = result['audioSamples'] as List<int>;
  final sampleRate = result['sampleRate'] as int;
  final success = await context?.saveAudioToWav(
    '/path/to/output.wav',
    audioSamples,
    sampleRate,
  );
  print('Saved to WAV: $success');
}
```

#### 6. Async Save Audio to WAV: `saveAudioToWavAsync`

Saves audio samples to a WAV file asynchronously (runs in background thread).

```dart
Future<bool> saveAudioToWavAsync(
  String filePath,
  List<int> audioSamples,
  int sampleRate,
)
```

**Parameters:**
- `filePath`: Path to save the WAV file
- `audioSamples`: List of audio samples (int16 values)
- `sampleRate`: Sample rate of the audio (Hz)

**Returns:**
- A `Future<bool>` indicating success

**Example:**
```dart
final result = await context?.generateSpeech('Hello, world!');
if (result != null) {
  final audioSamples = result['audioSamples'] as List<int>;
  final sampleRate = result['sampleRate'] as int;
  final success = await context?.saveAudioToWavAsync(
    '/path/to/output.wav',
    audioSamples,
    sampleRate,
  );
  print('Saved to WAV: $success');
}
```

#### 7. Async Load TTS Model: `loadTTSModelAsync`

Loads a TTS model asynchronously (runs in background thread).

```dart
Future<bool> loadTTSModelAsync(
  String modelPath,
  TTSModelType modelType,
)
```

**Parameters:**
- `modelPath`: Path to the TTS model file
- `modelType`: Type of TTS model to load

**Returns:**
- `true` if the model was loaded successfully, `false` otherwise

**Example:**
```dart
final success = await context?.loadTTSModelAsync(
  '/path/to/tts/model.bin',
  TTSModelType.outETTSv02,
);
print('Loaded TTS model: $success');
```

## Supporting Types

### iOS

#### TTSOptions

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

#### SpeechResult

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

#### SpeechMetadata

Metadata for speech generation (used in streaming).

```swift
struct SpeechMetadata {
    var sampleRate: Int
    var duration: TimeInterval
    var methodUsed: TTSMethod
    var outputFilePath: String?
}
```

#### TTSError

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

#### TTSMethod

Method used for speech generation.

```swift
enum TTSMethod {
    case builtIn
    case customWorkflow
}
```

### Android Kotlin

#### TTSOptions

Configuration options for TTS operations.

```kotlin
data class TTSOptions(
    val sampleRate: Int = 24000,
    val voice: String? = null,
    val speed: Float = 1.0f,
    val saveToFile: Boolean = false,
    val outputFilePath: String? = null
) {
    companion object {
        @JvmStatic
        fun create(): TTSOptions = TTSOptions()
    }
}
```

#### SpeechResult

Result of successful speech generation.

```kotlin
data class SpeechResult(
    val audioSamples: ShortArray,
    val sampleRate: Int,
    val duration: Double,
    val outputFilePath: String?,
    val methodUsed: TTSMethod
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as SpeechResult

        if (!audioSamples.contentEquals(other.audioSamples)) return false
        if (sampleRate != other.sampleRate) return false
        if (duration != other.duration) return false
        if (outputFilePath != other.outputFilePath) return false
        if (methodUsed != other.methodUsed) return false

        return true
    }

    override fun hashCode(): Int {
        var result = audioSamples.contentHashCode()
        result = 31 * result + sampleRate
        result = 31 * result + duration.hashCode()
        result = 31 * result + (outputFilePath?.hashCode() ?: 0)
        result = 31 * result + methodUsed.hashCode()
        return result
    }
}
```

#### SpeechMetadata

Metadata for speech generation (used in streaming).

```kotlin
data class SpeechMetadata(
    val sampleRate: Int,
    val duration: Double,
    val methodUsed: TTSMethod,
    val outputFilePath: String?
)
```

#### TTSError

Error types for TTS operations.

```kotlin
class TTSError private constructor(private val message: String) : Exception(message) {
    companion object {
        @JvmStatic
        fun noModelLoaded(): TTSError = TTSError("No model loaded")
        
        @JvmStatic
        fun noVocoderEnabled(): TTSError = TTSError("No vocoder enabled")
        
        @JvmStatic
        fun invalidText(): TTSError = TTSError("Invalid text")
        
        @JvmStatic
        fun generationFailed(): TTSError = TTSError("Generation failed")
        
        @JvmStatic
        fun formattingFailed(): TTSError = TTSError("Formatting failed")
        
        @JvmStatic
        fun tokenizationFailed(): TTSError = TTSError("Tokenization failed")
        
        @JvmStatic
        fun audioDecodingFailed(): TTSError = TTSError("Audio decoding failed")
        
        @JvmStatic
        fun fileSaveFailed(): TTSError = TTSError("File save failed")
        
        @JvmStatic
        fun unknownError(message: String): TTSError = TTSError(message)
    }
}
```

#### TTSMethod

Method used for speech generation.

```kotlin
enum class TTSMethod {
    BUILT_IN,
    CUSTOM_WORKFLOW
}
```

#### AudioChunkCallback

Callback interface for receiving audio chunks in streaming mode.

```kotlin
fun interface AudioChunkCallback {
    fun onAudioChunk(audioChunk: ShortArray)
}
```

### Android Java

#### TTSOptions

Configuration options for TTS operations.

```java
public static class TTSOptions {
    private final int sampleRate;
    private final String voice;
    private final float speed;
    private final boolean saveToFile;
    private final String outputFilePath;

    public TTSOptions() {
        this(24000, null, 1.0f, false, null);
    }

    public TTSOptions(int sampleRate, String voice, float speed, boolean saveToFile, String outputFilePath) {
        this.sampleRate = sampleRate;
        this.voice = voice;
        this.speed = speed;
        this.saveToFile = saveToFile;
        this.outputFilePath = outputFilePath;
    }

    public int getSampleRate() { return sampleRate; }
    public String getVoice() { return voice; }
    public float getSpeed() { return speed; }
    public boolean isSaveToFile() { return saveToFile; }
    public String getOutputFilePath() { return outputFilePath; }

    public static class Builder {
        private int sampleRate = 24000;
        private String voice = null;
        private float speed = 1.0f;
        private boolean saveToFile = false;
        private String outputFilePath = null;

        public Builder() {}

        public Builder sampleRate(int sampleRate) {
            this.sampleRate = sampleRate;
            return this;
        }

        public Builder voice(String voice) {
            this.voice = voice;
            return this;
        }

        public Builder speed(float speed) {
            this.speed = speed;
            return this;
        }

        public Builder saveToFile(boolean saveToFile) {
            this.saveToFile = saveToFile;
            return this;
        }

        public Builder outputFilePath(String outputFilePath) {
            this.outputFilePath = outputFilePath;
            return this;
        }

        public TTSOptions build() {
            return new TTSOptions(sampleRate, voice, speed, saveToFile, outputFilePath);
        }
    }
}
```

#### SpeechResult

Result of successful speech generation.

```java
public static class SpeechResult {
    private final short[] audioSamples;
    private final int sampleRate;
    private final double duration;
    private final String outputFilePath;
    private final TTSMethod methodUsed;

    public SpeechResult(short[] audioSamples, int sampleRate, double duration, String outputFilePath, TTSMethod methodUsed) {
        this.audioSamples = audioSamples;
        this.sampleRate = sampleRate;
        this.duration = duration;
        this.outputFilePath = outputFilePath;
        this.methodUsed = methodUsed;
    }

    public short[] getAudioSamples() { return audioSamples; }
    public int getSampleRate() { return sampleRate; }
    public double getDuration() { return duration; }
    public String getOutputFilePath() { return outputFilePath; }
    public TTSMethod getMethodUsed() { return methodUsed; }
}
```

#### SpeechMetadata

Metadata for speech generation (used in streaming).

```java
public static class SpeechMetadata {
    private final int sampleRate;
    private final double duration;
    private final TTSMethod methodUsed;
    private final String outputFilePath;

    public SpeechMetadata(int sampleRate, double duration, TTSMethod methodUsed, String outputFilePath) {
        this.sampleRate = sampleRate;
        this.duration = duration;
        this.methodUsed = methodUsed;
        this.outputFilePath = outputFilePath;
    }

    public int getSampleRate() { return sampleRate; }
    public double getDuration() { return duration; }
    public TTSMethod getMethodUsed() { return methodUsed; }
    public String getOutputFilePath() { return outputFilePath; }
}
```

#### TTSError

Error types for TTS operations.

```java
public static class TTSError extends Exception {
    private TTSError(String message) {
        super(message);
    }

    public static TTSError noModelLoaded() {
        return new TTSError("No model loaded");
    }

    public static TTSError noVocoderEnabled() {
        return new TTSError("No vocoder enabled");
    }

    public static TTSError invalidText() {
        return new TTSError("Invalid text");
    }

    public static TTSError generationFailed() {
        return new TTSError("Generation failed");
    }

    public static TTSError formattingFailed() {
        return new TTSError("Formatting failed");
    }

    public static TTSError tokenizationFailed() {
        return new TTSError("Tokenization failed");
    }

    public static TTSError audioDecodingFailed() {
        return new TTSError("Audio decoding failed");
    }

    public static TTSError fileSaveFailed() {
        return new TTSError("File save failed");
    }

    public static TTSError unknownError(String message) {
        return new TTSError(message);
    }
}
```

#### TTSMethod

Method used for speech generation.

```java
public enum TTSMethod {
    BUILT_IN,
    CUSTOM_WORKFLOW
}
```

#### AudioChunkCallback

Callback interface for receiving audio chunks in streaming mode.

```java
public interface AudioChunkCallback {
    void onAudioChunk(short[] audioChunk);
}
```

#### ProgressCallback

Callback interface for receiving progress updates.

```java
public interface ProgressCallback {
    void onProgress(float progress);
}
```

#### Result

Result class for TTS operations.

```java
public static class Result<S, E> {
    private final S value;
    private final E error;
    private final boolean isSuccess;

    private Result(S value, E error, boolean isSuccess) {
        this.value = value;
        this.error = error;
        this.isSuccess = isSuccess;
    }

    public static <S, E> Result<S, E> success(S value) {
        return new Result<>(value, null, true);
    }

    public static <S, E> Result<S, E> failure(E error) {
        return new Result<>(null, error, false);
    }

    public boolean isSuccess() {
        return isSuccess;
    }

    public boolean isFailure() {
        return !isSuccess;
    }

    public S getValue() {
        return value;
    }

    public E getError() {
        return error;
    }
}
```

### Flutter

#### TTSOptions

Configuration options for TTS operations in Flutter.

```dart
class TTSOptions {
  final int sampleRate;
  final String? voice;
  final double speed;
  final bool saveToFile;
  final String? outputFilePath;

  TTSOptions({
    this.sampleRate = 24000,
    this.voice,
    this.speed = 1.0,
    this.saveToFile = false,
    this.outputFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate,
      'voice': voice,
      'speed': speed,
      'saveToFile': saveToFile,
      'outputFilePath': outputFilePath,
    };
  }
}
```

#### SpeechResult

Result of successful speech generation in Flutter.

```dart
class SpeechResult {
  final List<int> audioSamples;
  final int sampleRate;
  final double duration;
  final String? outputFilePath;
  final TTSMethod methodUsed;

  SpeechResult({
    required this.audioSamples,
    required this.sampleRate,
    required this.duration,
    this.outputFilePath,
    required this.methodUsed,
  });

  factory SpeechResult.fromMap(Map<String, dynamic> map) {
    return SpeechResult(
      audioSamples: List<int>.from(map['audioSamples'] as List),
      sampleRate: map['sampleRate'] as int,
      duration: map['duration'] as double,
      outputFilePath: map['outputFilePath'] as String?,
      methodUsed: TTSMethod.fromRawValue(map['methodUsed'] as int),
    );
  }
}
```

#### SpeechMetadata

Metadata for speech generation (used in streaming) in Flutter.

```dart
class SpeechMetadata {
  final int sampleRate;
  final double duration;
  final TTSMethod methodUsed;
  final String? outputFilePath;

  SpeechMetadata({
    required this.sampleRate,
    required this.duration,
    required this.methodUsed,
    this.outputFilePath,
  });

  factory SpeechMetadata.fromMap(Map<String, dynamic> map) {
    return SpeechMetadata(
      sampleRate: map['sampleRate'] as int,
      duration: map['duration'] as double,
      methodUsed: TTSMethod.fromRawValue(map['methodUsed'] as int),
      outputFilePath: map['outputFilePath'] as String?,
    );
  }
}
```

#### TTSError

Error types for TTS operations in Flutter.

```dart
enum TTSError {
  noModelLoaded,
  noVocoderEnabled,
  invalidText,
  generationFailed,
  formattingFailed,
  tokenizationFailed,
  audioDecodingFailed,
  fileSaveFailed,
  unknownError;

  String get message {
    switch (this) {
      case noModelLoaded:
        return 'No model loaded';
      case noVocoderEnabled:
        return 'No vocoder enabled';
      case invalidText:
        return 'Invalid text';
      case generationFailed:
        return 'Generation failed';
      case formattingFailed:
        return 'Formatting failed';
      case tokenizationFailed:
        return 'Tokenization failed';
      case audioDecodingFailed:
        return 'Audio decoding failed';
      case fileSaveFailed:
        return 'File save failed';
      case unknownError:
        return 'Unknown error';
    }
  }
}
```

#### TTSMethod

Method used for speech generation in Flutter.

```dart
enum TTSMethod {
  builtIn,
  customWorkflow;

  int get rawValue {
    switch (this) {
      case builtIn:
        return 0;
      case customWorkflow:
        return 1;
    }
  }

  factory TTSMethod.fromRawValue(int value) {
    switch (value) {
      case 0:
        return builtIn;
      case 1:
        return customWorkflow;
      default:
        return builtIn;
    }
  }
}
```

## API Usage Examples

### iOS

#### Asynchronous API Example with Custom TTSOptions

```swift
func speakAsyncWithCustomOptions() async {
    let text = "Hello, this is a test of the asynchronous TTS API with custom options."
    
    let options = TTSOptions(
        sampleRate: 16000,  // Lower sample rate for smaller file size
        voice: "en-us",     // Specify voice (if supported)
        speed: 1.2,         // Slightly faster speech
        saveToFile: true,
        outputFilePath: NSTemporaryDirectory().appending("tts_output.wav")
    )
    
    let result = await llamaMobile.generateSpeech(
        text: text,
        options: options,
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

#### Asynchronous API Example (Basic)

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

#### Synchronous API Example

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

#### Streaming API Example with Custom Options

```swift
func speakWithStreaming() async {
    let text = "Hello, this is a test of the streaming TTS API with custom options."
    
    let options = TTSOptions(
        sampleRate: 24000,
        voice: "en-us",
        speed: 1.0
    )
    
    let result = await llamaMobile.generateSpeechStream(
        text: text,
        options: options,
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

#### Real Streaming for Long Text Example with Custom Options

```swift
func speakLongTextWithStreaming() async {
    let longText = """
    Hello! This is a long text example for streaming TTS. 
    This text will be split into multiple chunks and played continuously.
    Each sentence will be generated and played as soon as it's ready.
    This provides a much better user experience for long texts.
    """
    
    let options = TTSOptions(
        sampleRate: 24000,
        voice: "en-us",
        speed: 0.9  // Slightly slower for better comprehension
    )
    
    let result = await llamaMobile.generateSpeechStreamForLongText(
        text: longText,
        options: options,
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

### Android Kotlin

#### Asynchronous API Example with Custom TTSOptions

```kotlin
suspend fun speakAsyncWithCustomOptions() {
    val text = "Hello, this is a test of the asynchronous TTS API with custom options."
    val contextHandle = LlamaMobile.getContext()
    
    val options = TTSOptions(
        sampleRate = 16000,  // Lower sample rate for smaller file size
        voice = "en-us",     // Specify voice (if supported)
        speed = 1.2f,         // Slightly faster speech
        saveToFile = true,
        outputFilePath = "${context.cacheDir.path}/tts_output.wav"
    )
    
    val result = LlamaMobile.generateSpeech(
        contextHandle,
        text,
        options,
        progressHandler = { progress ->
            println("TTS Progress: ${(progress * 100).toInt()}%")
        }
    )
    
    if (result.isSuccess) {
        val speechResult = result.value
        println("Speech generated successfully!")
        println("Sample rate: ${speechResult.sampleRate}")
        println("Duration: ${speechResult.duration} seconds")
        println("Method used: ${speechResult.methodUsed}")
        if (speechResult.outputFilePath != null) {
            println("Saved to: ${speechResult.outputFilePath}")
        }
        // Play the audio samples
        playAudio(speechResult.audioSamples, speechResult.sampleRate)
    } else {
        val error = result.error
        println("Error generating speech: $error")
    }
}
```

#### Asynchronous API Example (Basic)

```kotlin
suspend fun speakAsync() {
    val text = "Hello, this is a test of the asynchronous TTS API."
    val contextHandle = LlamaMobile.getContext()
    
    val result = LlamaMobile.generateSpeech(
        contextHandle,
        text,
        TTSOptions(
            sampleRate = 24000,
            saveToFile = true,
            outputFilePath = "${context.cacheDir.path}/tts_output.wav"
        ),
        progressHandler = { progress ->
            println("TTS Progress: ${(progress * 100).toInt()}%")
        }
    )
    
    if (result.isSuccess) {
        val speechResult = result.value
        println("Speech generated successfully!")
        println("Sample rate: ${speechResult.sampleRate}")
        println("Duration: ${speechResult.duration} seconds")
        println("Method used: ${speechResult.methodUsed}")
        if (speechResult.outputFilePath != null) {
            println("Saved to: ${speechResult.outputFilePath}")
        }
        // Play the audio samples
        playAudio(speechResult.audioSamples, speechResult.sampleRate)
    } else {
        val error = result.error
        println("Error generating speech: $error")
    }
}
```

#### Synchronous API Example

```kotlin
fun speakSync() {
    val text = "Hello, this is a test of the synchronous TTS API."
    val contextHandle = LlamaMobile.getContext()
    
    val result = LlamaMobile.generateSpeechSync(
        contextHandle,
        text,
        TTSOptions(sampleRate = 24000)
    )
    
    if (result.isSuccess) {
        val speechResult = result.value
        println("Speech generated successfully!")
        println("Duration: ${speechResult.duration} seconds")
        // Play the audio samples
        playAudio(speechResult.audioSamples, speechResult.sampleRate)
    } else {
        val error = result.error
        println("Error generating speech: $error")
    }
}
```

#### Streaming API Example with Custom Options

```kotlin
suspend fun speakWithStreaming() {
    val text = "Hello, this is a test of the streaming TTS API with custom options."
    val contextHandle = LlamaMobile.getContext()
    
    val options = TTSOptions(
        sampleRate = 24000,
        voice = "en-us",
        speed = 1.0f
    )
    
    val result = LlamaMobile.generateSpeechStream(
        contextHandle,
        text,
        options,
        progressHandler = { progress ->
            println("Streaming Progress: ${(progress * 100).toInt()}%")
        },
        audioChunkHandler = { audioChunk ->
            println("Received audio chunk with ${audioChunk.size} samples")
            // Play the audio chunk
            playAudioChunk(audioChunk, 24000)
        }
    )
    
    if (result.isSuccess) {
        val metadata = result.value
        println("Streaming completed successfully!")
        println("Sample rate: ${metadata.sampleRate}")
        println("Method used: ${metadata.methodUsed}")
    } else {
        val error = result.error
        println("Error: $error")
    }
}
```

#### Real Streaming for Long Text Example with Custom Options

```kotlin
suspend fun speakLongTextWithStreaming() {
    val longText = """
    Hello! This is a long text example for streaming TTS. 
    This text will be split into multiple chunks and played continuously.
    Each sentence will be generated and played as soon as it's ready.
    This provides a much better user experience for long texts.
    """
    val contextHandle = LlamaMobile.getContext()
    
    val options = TTSOptions(
        sampleRate = 24000,
        voice = "en-us",
        speed = 0.9f  // Slightly slower for better comprehension
    )
    
    val result = LlamaMobile.generateSpeechStreamForLongText(
        contextHandle,
        longText,
        options,
        progressHandler = { progress ->
            println("Long Text Streaming Progress: ${(progress * 100).toInt()}%")
        },
        audioChunkHandler = { audioChunk ->
            println("Received audio chunk with ${audioChunk.size} samples")
            // Play the audio chunk immediately
            playAudioChunk(audioChunk, 24000)
        }
    )
    
    if (result.isSuccess) {
        val metadata = result.value
        println("Long text streaming completed successfully!")
        println("Total duration: ${metadata.duration} seconds")
        println("Method used: ${metadata.methodUsed}")
    } else {
        val error = result.error
        println("Error: $error")
    }
}
```

### Android Java

#### Asynchronous API Example with Custom TTSOptions

```java
public void speakAsyncWithCustomOptions() {
    String text = "Hello, this is a test of the asynchronous TTS API with custom options.";
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions.Builder()
        .sampleRate(16000)  // Lower sample rate for smaller file size
        .voice("en-us")     // Specify voice (if supported)
        .speed(1.2f)         // Slightly faster speech
        .saveToFile(true)
        .outputFilePath(getCacheDir().getPath() + "/tts_output.wav")
        .build();
    
    LlamaMobile.generateSpeech(
        contextHandle,
        text,
        options,
        progress -> {
            System.out.println("TTS Progress: " + (int)(progress * 100) + "%");
        },
        result -> {
            if (result.isSuccess()) {
                LlamaMobile.SpeechResult speechResult = result.getValue();
                System.out.println("Speech generated successfully!");
                System.out.println("Sample rate: " + speechResult.getSampleRate());
                System.out.println("Duration: " + speechResult.getDuration() + " seconds");
                System.out.println("Method used: " + speechResult.getMethodUsed());
                if (speechResult.getOutputFilePath() != null) {
                    System.out.println("Saved to: " + speechResult.getOutputFilePath());
                }
                // Play the audio samples
                playAudio(speechResult.getAudioSamples(), speechResult.getSampleRate());
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Error generating speech: " + error);
            }
        }
    );
}
```

#### Asynchronous API Example (Basic)

```java
public void speakAsync() {
    String text = "Hello, this is a test of the asynchronous TTS API.";
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.generateSpeech(
        contextHandle,
        text,
        new LlamaMobile.TTSOptions.Builder()
            .sampleRate(24000)
            .saveToFile(true)
            .outputFilePath(getCacheDir().getPath() + "/tts_output.wav")
            .build(),
        progress -> {
            System.out.println("TTS Progress: " + (int)(progress * 100) + "%");
        },
        result -> {
            if (result.isSuccess()) {
                LlamaMobile.SpeechResult speechResult = result.getValue();
                System.out.println("Speech generated successfully!");
                System.out.println("Sample rate: " + speechResult.getSampleRate());
                System.out.println("Duration: " + speechResult.getDuration() + " seconds");
                System.out.println("Method used: " + speechResult.getMethodUsed());
                if (speechResult.getOutputFilePath() != null) {
                    System.out.println("Saved to: " + speechResult.getOutputFilePath());
                }
                // Play the audio samples
                playAudio(speechResult.getAudioSamples(), speechResult.getSampleRate());
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Error generating speech: " + error);
            }
        }
    );
}
```

#### Synchronous API Example

```java
public void speakSync() {
    String text = "Hello, this is a test of the synchronous TTS API.";
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.Result<LlamaMobile.SpeechResult, LlamaMobile.TTSError> result = 
        LlamaMobile.generateSpeechSync(
            contextHandle,
            text,
            new LlamaMobile.TTSOptions.Builder()
                .sampleRate(24000)
                .build()
        );
    
    if (result.isSuccess()) {
        LlamaMobile.SpeechResult speechResult = result.getValue();
        System.out.println("Speech generated successfully!");
        System.out.println("Duration: " + speechResult.getDuration() + " seconds");
        // Play the audio samples
        playAudio(speechResult.getAudioSamples(), speechResult.getSampleRate());
    } else {
        LlamaMobile.TTSError error = result.getError();
        System.out.println("Error generating speech: " + error);
    }
}
```

#### Streaming API Example with Custom Options

```java
public void speakWithStreaming() {
    String text = "Hello, this is a test of the streaming TTS API with custom options.";
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions.Builder()
        .sampleRate(24000)
        .voice("en-us")
        .speed(1.0f)
        .build();
    
    LlamaMobile.generateSpeechStream(
        contextHandle,
        text,
        options,
        progress -> {
            System.out.println("Streaming Progress: " + (int)(progress * 100) + "%");
        },
        audioChunk -> {
            System.out.println("Received audio chunk with " + audioChunk.length + " samples");
            // Play the audio chunk
            playAudioChunk(audioChunk, 24000);
        },
        result -> {
            if (result.isSuccess()) {
                LlamaMobile.SpeechMetadata metadata = result.getValue();
                System.out.println("Streaming completed successfully!");
                System.out.println("Sample rate: " + metadata.getSampleRate());
                System.out.println("Method used: " + metadata.getMethodUsed());
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Error: " + error);
            }
        }
    );
}
```

#### Real Streaming for Long Text Example with Custom Options

```java
public void speakLongTextWithStreaming() {
    String longText = """
    Hello! This is a long text example for streaming TTS. 
    This text will be split into multiple chunks and played continuously.
    Each sentence will be generated and played as soon as it's ready.
    This provides a much better user experience for long texts.
    """;
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions.Builder()
        .sampleRate(24000)
        .voice("en-us")
        .speed(0.9f)  // Slightly slower for better comprehension
        .build();
    
    LlamaMobile.generateSpeechStreamForLongText(
        contextHandle,
        longText,
        options,
        progress -> {
            System.out.println("Long Text Streaming Progress: " + (int)(progress * 100) + "%");
        },
        audioChunk -> {
            System.out.println("Received audio chunk with " + audioChunk.length + " samples");
            // Play the audio chunk immediately
            playAudioChunk(audioChunk, 24000);
        },
        result -> {
            if (result.isSuccess()) {
                LlamaMobile.SpeechMetadata metadata = result.getValue();
                System.out.println("Long text streaming completed successfully!");
                System.out.println("Total duration: " + metadata.getDuration() + " seconds");
                System.out.println("Method used: " + metadata.getMethodUsed());
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Error: " + error);
            }
        }
    );
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

### Error Handling Examples

#### iOS

```swift
func testErrorHandling() async {
    let text = "Hello, world!"
    
    // Test with empty text
    let emptyTextResult = await llamaMobile.generateSpeech(
        text: "",
        options: TTSOptions()
    )
    
    switch emptyTextResult {
    case .success(_):
        print("Unexpected success with empty text")
    case .failure(let error):
        print("Expected error with empty text: \(error)")
    }
    
    // Test with invalid context (simulating no model loaded)
    let invalidContextResult = await llamaMobile.generateSpeech(
        text: text,
        options: TTSOptions()
    )
    
    switch invalidContextResult {
    case .success(_):
        print("Speech generated successfully")
    case .failure(let error):
        print("Error generating speech: \(error)")
        // Handle specific error types
        switch error {
        case .noModelLoaded:
            print("Please load a model first")
        case .noVocoderEnabled:
            print("Please enable vocoder for TTS")
        case .invalidText:
            print("Please provide valid text")
        default:
            print("An error occurred: \(error)")
        }
    }
}
```

#### Android Kotlin

```kotlin
suspend fun testErrorHandling() {
    val text = "Hello, world!"
    val contextHandle = LlamaMobile.getContext()
    
    // Test with empty text
    val emptyTextResult = LlamaMobile.generateSpeech(
        contextHandle,
        ""
    )
    
    if (emptyTextResult.isSuccess) {
        println("Unexpected success with empty text")
    } else {
        val error = emptyTextResult.error
        println("Expected error with empty text: $error")
    }
    
    // Test with invalid context (simulating no model loaded)
    val invalidContext = 0L
    val invalidContextResult = LlamaMobile.generateSpeech(
        invalidContext,
        text
    )
    
    if (invalidContextResult.isSuccess) {
        println("Speech generated successfully")
    } else {
        val error = invalidContextResult.error
        println("Error generating speech: $error")
        // Handle specific error scenarios
        when {
            error.message?.contains("No model loaded") == true -> {
                println("Please load a model first")
            }
            error.message?.contains("No vocoder enabled") == true -> {
                println("Please enable vocoder for TTS")
            }
            error.message?.contains("Invalid text") == true -> {
                println("Please provide valid text")
            }
            else -> {
                println("An error occurred: $error")
            }
        }
    }
}
```

#### Android Java

```java
public void testErrorHandling() {
    String text = "Hello, world!";
    long contextHandle = LlamaMobile.getContext();
    
    // Test with empty text
    LlamaMobile.generateSpeech(
        contextHandle,
        "",
        result -> {
            if (result.isSuccess()) {
                System.out.println("Unexpected success with empty text");
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Expected error with empty text: " + error);
            }
        }
    );
    
    // Test with invalid context (simulating no model loaded)
    long invalidContext = 0L;
    LlamaMobile.generateSpeech(
        invalidContext,
        text,
        result -> {
            if (result.isSuccess()) {
                System.out.println("Speech generated successfully");
            } else {
                LlamaMobile.TTSError error = result.getError();
                System.out.println("Error generating speech: " + error);
                // Handle specific error scenarios
                String errorMessage = error.getMessage();
                if (errorMessage.contains("No model loaded")) {
                    System.out.println("Please load a model first");
                } else if (errorMessage.contains("No vocoder enabled")) {
                    System.out.println("Please enable vocoder for TTS");
                } else if (errorMessage.contains("Invalid text")) {
                    System.out.println("Please provide valid text");
                } else {
                    System.out.println("An error occurred: " + error);
                }
            }
        }
    );
}
```

#### Flutter

##### Basic TTS Usage

```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

// Initialize context with TTS model
final llamaMobile = LlamaMobile();
final context = await llamaMobile.initContext(
  modelPath: 'path/to/tts/model.gguf',
);

// Generate speech asynchronously
final result = await context?.generateSpeech(
  'Hello, world!',
  options: {
    'sampleRate': 24000,
    'speed': 1.0,
  },
);

if (result != null) {
  final audioSamples = result['audioSamples'] as List<int>;
  final sampleRate = result['sampleRate'] as int;
  print('Generated ${audioSamples.length} samples at ${sampleRate}Hz');
}

// Clean up
await context?.free();
```

##### Saving to WAV File

```dart
// Generate speech and save to WAV file
final result = await context?.generateSpeech(
  'Hello, this will be saved to a WAV file.',
  options: {
    'sampleRate': 24000,
    'saveToFile': true,
    'outputFilePath': '/path/to/output.wav',
  },
);

if (result != null) {
  print('Speech saved to: ${result['outputFilePath']}');
}
```

##### Streaming for Long Text

```dart
// Generate speech for long text with streaming
final longText = 'This is a very long text that will be processed in chunks...';

final result = await context?.generateSpeechStreamForLongText(
  longText,
  options: {
    'sampleRate': 24000,
  },
);

if (result != null) {
  final sampleRate = result['sampleRate'] as int;
  final duration = result['duration'] as double;
  print('Generated ${duration}s of audio at ${sampleRate}Hz');
}
```

##### Custom TTS Options

```dart
// Use TTSOptions class for better type safety
final options = TTSOptions(
  sampleRate: 16000,
  voice: 'en-us',
  speed: 1.2,
  saveToFile: true,
  outputFilePath: '/path/to/custom_output.wav',
);

final result = await context?.generateSpeech(
  'Custom TTS options example.',
  options: options.toMap(),
);

if (result != null) {
  print('Generated speech with custom options');
}
```

##### Error Handling

```dart
try {
  final result = await context?.generateSpeech(
    'Hello, world!',
    options: {
      'sampleRate': 24000,
    },
  );

  if (result == null) {
    print('Failed to generate speech');
    // Check for specific errors
    final error = TTSError.unknownError;
    print('Error: ${error.message}');
  } else {
    print('Speech generated successfully');
  }
} catch (e) {
  print('Exception: $e');
}
```

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