# LLM API Documentation

## Overview

The Llama Mobile SDK provides a comprehensive set of APIs for working with Large Language Models (LLMs) on iOS and Android devices. This documentation covers all major API categories including model loading, text completion, multimodal processing, embeddings, and vocoder functionality for both platforms.

## Table of Contents

1. [Loading Model APIs](#loading-model-apis)
   - [iOS](#ios-loading)
   - [Android Kotlin](#android-kotlin-loading)
   - [Android Java](#android-java-loading)
   - [Flutter](#flutter-loading)
2. [Completion APIs](#completion-apis)
   - [iOS](#ios-completion)
   - [Android Kotlin](#android-kotlin-completion)
   - [Android Java](#android-java-completion)
   - [Flutter](#flutter-completion)
3. [Multimodal APIs](#multimodal-apis)
   - [iOS](#ios-multimodal)
   - [Android Kotlin](#android-kotlin-multimodal)
   - [Android Java](#android-java-multimodal)
   - [Flutter](#flutter-multimodal)
4. [Embedding APIs](#embedding-apis)
   - [iOS](#ios-embedding)
   - [Android Kotlin](#android-kotlin-embedding)
   - [Android Java](#android-java-embedding)
   - [Flutter](#flutter-embedding)
5. [Vocoder Load APIs](#vocoder-load-apis)
   - [iOS](#ios-vocoder)
   - [Android Kotlin](#android-kotlin-vocoder)
   - [Android Java](#android-java-vocoder)
6. [Supporting Types](#supporting-types)
   - [iOS](#ios-types)
   - [Android Kotlin](#android-kotlin-types)
   - [Android Java](#android-java-types)
   - [Flutter](#flutter-types)
7. [API Usage Examples](#api-usage-examples)
   - [iOS](#ios-examples)
   - [Android Kotlin](#android-kotlin-examples)
   - [Android Java](#android-java-examples)
   - [Flutter](#flutter-examples)

## Loading Model APIs

### iOS {#ios-loading}

#### Initialization Methods

##### Basic Initialization

```swift
public init?(modelPath: String, nCtx: Int32 = 2048, nGpuLayers: Int32 = 0, nThreads: Int32 = 4, progressCallback: ((Float) -> Void)? = nil)
```

##### Advanced Initialization

```swift
public init?(with params: InitParams)
```

#### InitParams Structure

```swift
public struct InitParams {
    /// Path to the model file
    public var modelPath: String
    
    /// Context window size
    public var nCtx: Int32 = 2048
    
    /// Batch size for processing
    public var nBatch: Int32 = 512
    
    /// Micro batch size
    public var nUBatch: Int32 = 512
    
    /// Number of layers to offload to GPU
    public var nGpuLayers: Int32 = 0
    
    /// Number of CPU threads to use
    public var nThreads: Int32 = 4
    
    /// Enable memory mapping
    public var useMmap: Bool = true
    
    /// Enable memory locking
    public var useMlock: Bool = false
    
    /// Enable embedding generation
    public var embedding: Bool = false
    
    /// Pooling type for embeddings
    public var poolingType: Int32 = 0
    
    /// Normalize embeddings
    public var embdNormalize: Bool = false
    
    /// Enable chat template
    public var enableChatTemplate: Bool = false
    
    /// Chat template string
    public var chatTemplate: String? = nil
    
    /// System prompt for chat template
    public var systemPrompt: String? = nil
    
    /// Cache type for key
    public var cacheTypeK: String? = nil
    
    /// Cache type for value
    public var cacheTypeV: String? = nil
    
    /// Enable flash attention
    public var flashAttention: Bool = false
    
    /// Optional progress callback for model loading
    public var progressCallback: ((Float) -> Void)? = nil
    
    /// Default initializer with model path
    public init(modelPath: String)
    
    /// Convenience initializer for embedding generation
    public init(modelPath: String, embedding: Bool, poolingType: Int32 = 0)
}
```

#### Usage Examples

##### Basic Model Loading

```swift
func loadModel() {
    // Load a model with default parameters
    guard let llamaMobile = LlamaMobile(modelPath: "\(Bundle.main.bundlePath)/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf") else {
        print("Failed to load model")
        return
    }
    
    print("Model loaded successfully")
    // Use the model for completions, embeddings, etc.
}
```

##### Model Loading with Progress

```swift
func loadModelWithProgress() {
    // Load a model with progress tracking
    guard let llamaMobile = LlamaMobile(
        modelPath: "\(Bundle.main.bundlePath)/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf",
        nCtx: 4096,
        nGpuLayers: 4,
        progressCallback: { progress in
            print("Loading progress: \(Int(progress * 100))%")
        }
    ) else {
        print("Failed to load model")
        return
    }
    
    print("Model loaded successfully")
}
```

##### Advanced Model Loading

```swift
func loadModelAdvanced() {
    // Create advanced initialization parameters
    var params = LlamaMobile.InitParams(modelPath: "\(Bundle.main.bundlePath)/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf")
    params.nCtx = 4096
    params.nBatch = 1024
    params.nGpuLayers = 4
    params.nThreads = 4
    params.useMmap = true
    params.flashAttention = true
    params.enableChatTemplate = true
    params.systemPrompt = "You are a helpful assistant"
    
    // Load the model
    guard let llamaMobile = LlamaMobile(with: params) else {
        print("Failed to load model")
        return
    }
    
    print("Model loaded successfully with advanced parameters")
}
```

### Android Kotlin {#android-kotlin-loading}

#### Initialization Methods

##### Basic Initialization

```kotlin
@JvmStatic
fun getContext(): Long

@JvmStatic
fun loadModel(
    modelPath: String,
    nCtx: Int = 2048,
    nGpuLayers: Int = 0,
    nThreads: Int = 4,
    progressCallback: ((Float) -> Unit)? = null
): Long
```

##### Advanced Initialization

```kotlin
@JvmStatic
fun loadModel(params: InitParams): Long
```

#### InitParams Structure

```kotlin
data class InitParams(
    val modelPath: String,
    val nCtx: Int = 2048,
    val nBatch: Int = 512,
    val nUBatch: Int = 512,
    val nGpuLayers: Int = 0,
    val nThreads: Int = 4,
    val useMmap: Boolean = true,
    val useMlock: Boolean = false,
    val embedding: Boolean = false,
    val poolingType: Int = 0,
    val embdNormalize: Boolean = false,
    val enableChatTemplate: Boolean = false,
    val chatTemplate: String? = null,
    val systemPrompt: String? = null,
    val cacheTypeK: String? = null,
    val cacheTypeV: String? = null,
    val flashAttention: Boolean = false,
    val progressCallback: ((Float) -> Unit)? = null
) {
    companion object {
        @JvmStatic
        fun create(modelPath: String): InitParams = InitParams(modelPath = modelPath)
        
        @JvmStatic
        fun createForEmbedding(modelPath: String, poolingType: Int = 0): InitParams = 
            InitParams(modelPath = modelPath, embedding = true, poolingType = poolingType)
    }
}
```

#### Usage Examples

##### Basic Model Loading

```kotlin
fun loadModel() {
    val modelPath = "${context.filesDir.path}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    
    val contextHandle = LlamaMobile.loadModel(modelPath)
    
    if (contextHandle > 0) {
        println("Model loaded successfully")
        // Use the model for completions, embeddings, etc.
    } else {
        println("Failed to load model")
    }
}
```

##### Model Loading with Progress

```kotlin
fun loadModelWithProgress() {
    val modelPath = "${context.filesDir.path}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    
    val contextHandle = LlamaMobile.loadModel(
        modelPath = modelPath,
        nCtx = 4096,
        nGpuLayers = 4,
        progressCallback = { progress ->
            println("Loading progress: ${(progress * 100).toInt()}%")
        }
    )
    
    if (contextHandle > 0) {
        println("Model loaded successfully")
    } else {
        println("Failed to load model")
    }
}
```

##### Advanced Model Loading

```kotlin
fun loadModelAdvanced() {
    val modelPath = "${context.filesDir.path}/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf"
    
    val params = InitParams(
        modelPath = modelPath,
        nCtx = 4096,
        nBatch = 1024,
        nGpuLayers = 4,
        nThreads = 4,
        useMmap = true,
        flashAttention = true,
        enableChatTemplate = true,
        systemPrompt = "You are a helpful assistant"
    )
    
    val contextHandle = LlamaMobile.loadModel(params)
    
    if (contextHandle > 0) {
        println("Model loaded successfully with advanced parameters")
    } else {
        println("Failed to load model")
    }
}
```

### Android Java {#android-java-loading}

#### Initialization Methods

##### Basic Initialization

```java
public static long getContext()

public static long loadModel(
    String modelPath,
    int nCtx,
    int nGpuLayers,
    int nThreads,
    ProgressCallback progressCallback
)

// Overload with default parameters
public static long loadModel(String modelPath)
```

##### Advanced Initialization

```java
public static long loadModel(InitParams params)
```

#### InitParams Structure

```java
public static class InitParams {
    private final String modelPath;
    private final int nCtx;
    private final int nBatch;
    private final int nUBatch;
    private final int nGpuLayers;
    private final int nThreads;
    private final boolean useMmap;
    private final boolean useMlock;
    private final boolean embedding;
    private final int poolingType;
    private final boolean embdNormalize;
    private final boolean enableChatTemplate;
    private final String chatTemplate;
    private final String systemPrompt;
    private final String cacheTypeK;
    private final String cacheTypeV;
    private final boolean flashAttention;
    private final ProgressCallback progressCallback;

    private InitParams(Builder builder) {
        this.modelPath = builder.modelPath;
        this.nCtx = builder.nCtx;
        this.nBatch = builder.nBatch;
        this.nUBatch = builder.nUBatch;
        this.nGpuLayers = builder.nGpuLayers;
        this.nThreads = builder.nThreads;
        this.useMmap = builder.useMmap;
        this.useMlock = builder.useMlock;
        this.embedding = builder.embedding;
        this.poolingType = builder.poolingType;
        this.embdNormalize = builder.embdNormalize;
        this.enableChatTemplate = builder.enableChatTemplate;
        this.chatTemplate = builder.chatTemplate;
        this.systemPrompt = builder.systemPrompt;
        this.cacheTypeK = builder.cacheTypeK;
        this.cacheTypeV = builder.cacheTypeV;
        this.flashAttention = builder.flashAttention;
        this.progressCallback = builder.progressCallback;
    }

    public static class Builder {
        private final String modelPath;
        private int nCtx = 2048;
        private int nBatch = 512;
        private int nUBatch = 512;
        private int nGpuLayers = 0;
        private int nThreads = 4;
        private boolean useMmap = true;
        private boolean useMlock = false;
        private boolean embedding = false;
        private int poolingType = 0;
        private boolean embdNormalize = false;
        private boolean enableChatTemplate = false;
        private String chatTemplate = null;
        private String systemPrompt = null;
        private String cacheTypeK = null;
        private String cacheTypeV = null;
        private boolean flashAttention = false;
        private ProgressCallback progressCallback = null;

        public Builder(String modelPath) {
            this.modelPath = modelPath;
        }

        public Builder nCtx(int nCtx) {
            this.nCtx = nCtx;
            return this;
        }

        public Builder nBatch(int nBatch) {
            this.nBatch = nBatch;
            return this;
        }

        public Builder nUBatch(int nUBatch) {
            this.nUBatch = nUBatch;
            return this;
        }

        public Builder nGpuLayers(int nGpuLayers) {
            this.nGpuLayers = nGpuLayers;
            return this;
        }

        public Builder nThreads(int nThreads) {
            this.nThreads = nThreads;
            return this;
        }

        public Builder useMmap(boolean useMmap) {
            this.useMmap = useMmap;
            return this;
        }

        public Builder useMlock(boolean useMlock) {
            this.useMlock = useMlock;
            return this;
        }

        public Builder embedding(boolean embedding) {
            this.embedding = embedding;
            return this;
        }

        public Builder poolingType(int poolingType) {
            this.poolingType = poolingType;
            return this;
        }

        public Builder embdNormalize(boolean embdNormalize) {
            this.embdNormalize = embdNormalize;
            return this;
        }

        public Builder enableChatTemplate(boolean enableChatTemplate) {
            this.enableChatTemplate = enableChatTemplate;
            return this;
        }

        public Builder chatTemplate(String chatTemplate) {
            this.chatTemplate = chatTemplate;
            return this;
        }

        public Builder systemPrompt(String systemPrompt) {
            this.systemPrompt = systemPrompt;
            return this;
        }

        public Builder cacheTypeK(String cacheTypeK) {
            this.cacheTypeK = cacheTypeK;
            return this;
        }

        public Builder cacheTypeV(String cacheTypeV) {
            this.cacheTypeV = cacheTypeV;
            return this;
        }

        public Builder flashAttention(boolean flashAttention) {
            this.flashAttention = flashAttention;
            return this;
        }

        public Builder progressCallback(ProgressCallback progressCallback) {
            this.progressCallback = progressCallback;
            return this;
        }

        public InitParams build() {
            return new InitParams(this);
        }
    }

    // Getters
    public String getModelPath() { return modelPath; }
    public int getNCtx() { return nCtx; }
    public int getNBatch() { return nBatch; }
    public int getNUBatch() { return nUBatch; }
    public int getNGpuLayers() { return nGpuLayers; }
    public int getNThreads() { return nThreads; }
    public boolean isUseMmap() { return useMmap; }
    public boolean isUseMlock() { return useMlock; }
    public boolean isEmbedding() { return embedding; }
    public int getPoolingType() { return poolingType; }
    public boolean isEmbdNormalize() { return embdNormalize; }
    public boolean isEnableChatTemplate() { return enableChatTemplate; }
    public String getChatTemplate() { return chatTemplate; }
    public String getSystemPrompt() { return systemPrompt; }
    public String getCacheTypeK() { return cacheTypeK; }
    public String getCacheTypeV() { return cacheTypeV; }
    public boolean isFlashAttention() { return flashAttention; }
    public ProgressCallback getProgressCallback() { return progressCallback; }
}
```

#### ProgressCallback Interface

```java
public interface ProgressCallback {
    void onProgress(float progress);
}
```

#### Usage Examples

##### Basic Model Loading

```java
public void loadModel() {
    String modelPath = getFilesDir().getPath() + "/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf";
    
    long contextHandle = LlamaMobile.loadModel(modelPath);
    
    if (contextHandle > 0) {
        System.out.println("Model loaded successfully");
        // Use the model for completions, embeddings, etc.
    } else {
        System.out.println("Failed to load model");
    }
}
```

##### Model Loading with Progress

```java
public void loadModelWithProgress() {
    String modelPath = getFilesDir().getPath() + "/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf";
    
    long contextHandle = LlamaMobile.loadModel(
        modelPath,
        4096,  // nCtx
        4,     // nGpuLayers
        4,     // nThreads
        progress -> {
            System.out.println("Loading progress: " + (int)(progress * 100) + "%");
        }
    );
    
    if (contextHandle > 0) {
        System.out.println("Model loaded successfully");
    } else {
        System.out.println("Failed to load model");
    }
}
```

##### Advanced Model Loading

```java
public void loadModelAdvanced() {
    String modelPath = getFilesDir().getPath() + "/Models/Llama-3.2-1B-Instruct.Q4_K_M.gguf";
    
    InitParams params = new InitParams.Builder(modelPath)
        .nCtx(4096)
        .nBatch(1024)
        .nGpuLayers(4)
        .nThreads(4)
        .useMmap(true)
        .flashAttention(true)
        .enableChatTemplate(true)
        .systemPrompt("You are a helpful assistant")
        .build();
    
    long contextHandle = LlamaMobile.loadModel(params);
    
    if (contextHandle > 0) {
        System.out.println("Model loaded successfully with advanced parameters");
    } else {
        System.out.println("Failed to load model");
    }
}
```

### Flutter {#flutter-loading}

#### Initialization Methods

##### Basic Initialization

```dart
Future<LlamaContext?> initContext({
  required String modelPath,
  String? chatTemplate,
  String? systemPrompt,
  int nCtx = 2048,
  int nBatch = 512,
  int nUBatch = 512,
  int nGpuLayers = 0,
  int nThreads = 4,
  bool useMmap = true,
  bool useMlock = false,
  bool embedding = false,
  int poolingType = 0,
  int embdNormalize = 0,
  bool flashAttention = false,
  String? cacheTypeK,
  String? cacheTypeV,
  bool enableChatTemplate = true,
})
```

##### Advanced Initialization

```dart
Future<LlamaContext?> initContextWithParams(InitParams params)
```

#### InitParams Structure

```dart
class InitParams {
  final String modelPath;
  final String? chatTemplate;
  final String? systemPrompt;
  final int nCtx;
  final int nBatch;
  final int nUBatch;
  final int nGpuLayers;
  final int nThreads;
  final bool useMmap;
  final bool useMlock;
  final bool embedding;
  final int poolingType;
  final int embdNormalize;
  final bool flashAttention;
  final String? cacheTypeK;
  final String? cacheTypeV;
  final bool enableChatTemplate;

  InitParams({
    required this.modelPath,
    this.chatTemplate,
    this.systemPrompt,
    this.nCtx = 2048,
    this.nBatch = 512,
    this.nUBatch = 512,
    this.nGpuLayers = 0,
    this.nThreads = 4,
    this.useMmap = true,
    this.useMlock = false,
    this.embedding = false,
    this.poolingType = 0,
    this.embdNormalize = 0,
    this.flashAttention = false,
    this.cacheTypeK,
    this.cacheTypeV,
    this.enableChatTemplate = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'modelPath': modelPath,
      'chatTemplate': chatTemplate,
      'systemPrompt': systemPrompt,
      'nCtx': nCtx,
      'nBatch': nBatch,
      'nUBatch': nUBatch,
      'nGpuLayers': nGpuLayers,
      'nThreads': nThreads,
      'useMmap': useMmap,
      'useMlock': useMlock,
      'embedding': embedding,
      'poolingType': poolingType,
      'embdNormalize': embdNormalize,
      'flashAttention': flashAttention,
      'cacheTypeK': cacheTypeK,
      'cacheTypeV': cacheTypeV,
      'enableChatTemplate': enableChatTemplate,
    };
  }
}
```

#### Usage Examples

##### Basic Model Loading

```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

final llamaMobile = LlamaMobile();

final context = await llamaMobile.initContext(
  modelPath: 'assets/models/your-model.gguf',
  nCtx: 2048,
  nGpuLayers: 4,
  nThreads: 4,
);

if (context != null) {
  print('Model loaded successfully');
  // Use the model for completions, embeddings, etc.
} else {
  print('Failed to load model');
}
```

##### Advanced Model Loading

```dart
final params = InitParams(
  modelPath: 'assets/models/your-model.gguf',
  nCtx: 4096,
  nBatch: 1024,
  nGpuLayers: 4,
  nThreads: 4,
  useMmap: true,
  flashAttention: true,
  enableChatTemplate: true,
  systemPrompt: 'You are a helpful assistant',
);

final context = await llamaMobile.initContextWithParams(params);

if (context != null) {
  print('Model loaded successfully with advanced parameters');
} else {
  print('Failed to load model');
}
```

## 2. Completion APIs

### Core Completion Method

```swift
public func generateCompletion(with params: CompletionParams) -> CompletionResult?
```

### Simplified Completion Method

```swift
public func generateCompletion(prompt: String, maxTokens: Int32 = 1024, temperature: Double = 0.8, tokenCallback: ((String) -> Bool)? = nil, useJsonResponse: Bool = true) -> CompletionResult?
```

### OpenAI-Compatible Completion

```swift
public func generateOpenAICompletion(with openAIJSON: String) -> CompletionResult?
```

### Stop Completion

```swift
public func stopCompletion()
```

### CompletionParams Structure

```swift
public struct CompletionParams {
    /// Input prompt text
    public var prompt: String
    
    /// Maximum number of tokens to generate
    public var maxTokens: Int32 = 1024
    
    /// Number of CPU threads to use (0 = use default)
    public var nThreads: Int32? = nil
    
    /// Random seed for generation
    public var seed: Int32 = -1
    
    /// Sampling temperature
    public var temperature: Double = 0.8
    
    /// Top-k sampling
    public var topK: Int32 = 40
    
    /// Top-p sampling
    public var topP: Double = 0.95
    
    /// Minimum probability threshold
    public var minP: Double = 0.05
    
    /// Typical probability
    public var typicalP: Double = 1.0
    
    /// Last n tokens to consider for repetition penalty
    public var penaltyLastN: Int32 = 64
    
    /// Repetition penalty
    public var penaltyRepeat: Double = 1.1
    
    /// Frequency penalty
    public var penaltyFreq: Double = 0.0
    
    /// Presence penalty
    public var penaltyPresent: Double = 0.0
    
    /// Mirostat sampling
    public var mirostat: Int32 = 0
    
    /// Mirostat tau
    public var mirostatTau: Double = 5.0
    
    /// Mirostat eta
    public var mirostatEta: Double = 0.1
    
    /// Ignore end-of-sequence token
    public var ignoreEos: Bool = false
    
    /// Stop sequences for generation
    public var stopSequences: [String] = []
    
    /// Grammar to constrain generation
    public var grammar: String? = nil
    
    /// Whether to return response in OpenAI-like JSON format
    public var useJsonResponse: Bool = false
    
    /// Optional callback for streaming tokens
    public var tokenCallback: ((String) -> Bool)? = nil
    
    /// Chat messages (for chat template)
    public var chatMessages: [ChatMessage] = []
    
    /// Media paths for multimodal input
    public var mediaPaths: [String] = []
    
    /// JSON schema for structured output
    public var jsonSchema: String? = nil
    
    /// Tools definition for function calling
    public var tools: String? = nil
    
    /// Tool choice for function calling
    public var toolChoice: String? = nil
    
    /// Enable parallel tool calls
    public var parallelToolCalls: Bool = false
    
    /// Number of probability values to return per token
    public var nProbs: Int32 = 0
    
    /// Default initializer with prompt
    public init(prompt: String)
    
    /// Initializer from OpenAI format JSON
    public init(openAIJSON: String) throws
}
```

### CompletionResult Structure

```swift
public struct CompletionResult {
    /// Generated text
    public var text: String
    
    /// Number of tokens generated
    public var tokensGenerated: Int32
    
    /// Number of tokens evaluated
    public var tokensEvaluated: Int32
    
    /// Whether the output was truncated
    public var truncated: Bool
    
    /// Whether generation stopped at end-of-sequence
    public var stoppedEos: Bool
    
    /// Whether generation stopped at a stop word
    public var stoppedWord: Bool
    
    /// Whether generation stopped at token limit
    public var stoppedLimit: Bool
    
    /// The word that caused generation to stop
    public var stoppingWord: String?
    
    /// Default initializer with all parameters
    public init(text: String, tokensGenerated: Int32, tokensEvaluated: Int32, truncated: Bool, stoppedEos: Bool, stoppedWord: Bool, stoppedLimit: Bool, stoppingWord: String? = nil)
}
```

### Usage Examples

#### Basic Completion

```swift
func generateBasicCompletion() {
    // Assuming llamaMobile is already initialized
    let params = LlamaMobile.CompletionParams(prompt: "Write a short story about a robot learning to paint.")
    params.maxTokens = 512
    params.temperature = 0.7
    
    if let result = llamaMobile.generateCompletion(with: params) {
        print("Generated text: \(result.text)")
        print("Tokens generated: \(result.tokensGenerated)")
        print("Tokens evaluated: \(result.tokensEvaluated)")
    } else {
        print("Failed to generate completion")
    }
}
```

#### Streaming Completion

```swift
func generateStreamingCompletion() {
    let params = LlamaMobile.CompletionParams(prompt: "Explain quantum computing in simple terms.")
    params.maxTokens = 300
    params.temperature = 0.6
    
    // Add streaming callback
    params.tokenCallback = { token in
        print(token, terminator: "")
        return true // Return false to stop generation
    }
    
    if let result = llamaMobile.generateCompletion(with: params) {
        print("\n\nGeneration complete!")
        print("Total tokens: \(result.tokensGenerated)")
    }
}
```

#### Chat Completion

```swift
func generateChatCompletion() {
    let messages: [LlamaMobile.ChatMessage] = [
        LlamaMobile.ChatMessage(role: "system", content: "You are a helpful assistant.")
        LlamaMobile.ChatMessage(role: "user", content: "What's the capital of France?")
        LlamaMobile.ChatMessage(role: "assistant", content: "The capital of France is Paris.")
        LlamaMobile.ChatMessage(role: "user", content: "What's a famous landmark there?")
    ]
    
    var params = LlamaMobile.CompletionParams(prompt: "")
    params.chatMessages = messages
    params.maxTokens = 200
    params.temperature = 0.7
    
    if let result = llamaMobile.generateCompletion(with: params) {
        print("Assistant: \(result.text)")
    }
}
```

#### OpenAI-Compatible Completion

```swift
func generateOpenAICompletion() {
    let openAIJSON = """
    {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Tell me a joke about computers."}
        ],
        "max_tokens": 150,
        "temperature": 0.7
    }
    """
    
    if let result = llamaMobile.generateOpenAICompletion(with: openAIJSON) {
        print("Generated response: \(result.text)")
    }
}
```

### Android Kotlin {#android-kotlin-completion}

#### Core Completion Method

```kotlin
@JvmStatic
fun generateCompletion(
    contextHandle: Long,
    params: CompletionParams
): CompletionResult?
```

#### Simplified Completion Method

```kotlin
@JvmStatic
fun generateCompletion(
    contextHandle: Long,
    prompt: String,
    maxTokens: Int = 1024,
    temperature: Double = 0.8,
    tokenCallback: ((String) -> Boolean)? = null,
    useJsonResponse: Boolean = true
): CompletionResult?
```

#### OpenAI-Compatible Completion

```kotlin
@JvmStatic
fun generateOpenAICompletion(
    contextHandle: Long,
    openAIJSON: String
): CompletionResult?
```

#### Stop Completion

```kotlin
@JvmStatic
fun stopCompletion(contextHandle: Long)
```

#### CompletionParams Structure

```kotlin
data class CompletionParams(
    val prompt: String,
    val maxTokens: Int = 1024,
    val nThreads: Int? = null,
    val seed: Int = -1,
    val temperature: Double = 0.8,
    val topK: Int = 40,
    val topP: Double = 0.95,
    val minP: Double = 0.05,
    val typicalP: Double = 1.0,
    val penaltyLastN: Int = 64,
    val penaltyRepeat: Double = 1.1,
    val penaltyFreq: Double = 0.0,
    val penaltyPresent: Double = 0.0,
    val mirostat: Int = 0,
    val mirostatTau: Double = 5.0,
    val mirostatEta: Double = 0.1,
    val ignoreEos: Boolean = false,
    val stopSequences: List<String> = emptyList(),
    val grammar: String? = null,
    val useJsonResponse: Boolean = false,
    val tokenCallback: ((String) -> Boolean)? = null,
    val chatMessages: List<ChatMessage> = emptyList(),
    val mediaPaths: List<String> = emptyList(),
    val jsonSchema: String? = null,
    val tools: String? = null,
    val toolChoice: String? = null,
    val parallelToolCalls: Boolean = false,
    val nProbs: Int = 0
) {
    companion object {
        @JvmStatic
        fun create(prompt: String): CompletionParams = CompletionParams(prompt = prompt)
        
        @JvmStatic
        fun createFromOpenAIJSON(openAIJSON: String): CompletionParams {
            // Implementation to parse OpenAI JSON
            return CompletionParams(prompt = "")
        }
    }
}
```

#### ChatMessage Structure

```kotlin
data class ChatMessage(
    val role: String,
    val content: String
)
```

#### CompletionResult Structure

```kotlin
data class CompletionResult(
    val text: String,
    val tokensGenerated: Int,
    val tokensEvaluated: Int,
    val truncated: Boolean,
    val stoppedEos: Boolean,
    val stoppedWord: Boolean,
    val stoppedLimit: Boolean,
    val stoppingWord: String? = null
)
```

#### Usage Examples

##### Basic Completion

```kotlin
fun generateBasicCompletion() {
    val contextHandle = LlamaMobile.getContext()
    val params = CompletionParams(
        prompt = "Write a short story about a robot learning to paint."
    )
    params.maxTokens = 512
    params.temperature = 0.7
    
    val result = LlamaMobile.generateCompletion(contextHandle, params)
    
    if (result != null) {
        println("Generated text: ${result.text}")
        println("Tokens generated: ${result.tokensGenerated}")
        println("Tokens evaluated: ${result.tokensEvaluated}")
    } else {
        println("Failed to generate completion")
    }
}
```

##### Streaming Completion

```kotlin
fun generateStreamingCompletion() {
    val contextHandle = LlamaMobile.getContext()
    val params = CompletionParams(
        prompt = "Explain quantum computing in simple terms."
    )
    params.maxTokens = 300
    params.temperature = 0.6
    
    // Add streaming callback
    params.tokenCallback = { token ->
        print(token)
        return@tokenCallback true // Return false to stop generation
    }
    
    val result = LlamaMobile.generateCompletion(contextHandle, params)
    
    if (result != null) {
        println("\n\nGeneration complete!")
        println("Total tokens: ${result.tokensGenerated}")
    }
}
```

##### Chat Completion

```kotlin
fun generateChatCompletion() {
    val contextHandle = LlamaMobile.getContext()
    val messages = listOf(
        ChatMessage(role = "system", content = "You are a helpful assistant."),
        ChatMessage(role = "user", content = "What's the capital of France?"),
        ChatMessage(role = "assistant", content = "The capital of France is Paris."),
        ChatMessage(role = "user", content = "What's a famous landmark there?")
    )
    
    val params = CompletionParams(prompt = "")
    params.chatMessages = messages
    params.maxTokens = 200
    params.temperature = 0.7
    
    val result = LlamaMobile.generateCompletion(contextHandle, params)
    
    if (result != null) {
        println("Assistant: ${result.text}")
    }
}
```

##### OpenAI-Compatible Completion

```kotlin
fun generateOpenAICompletion() {
    val contextHandle = LlamaMobile.getContext()
    val openAIJSON = """
    {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Tell me a joke about computers."}
        ],
        "max_tokens": 150,
        "temperature": 0.7
    }
    """
    
    val result = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON)
    
    if (result != null) {
        println("Generated response: ${result.text}")
    }
}
```

### Android Java {#android-java-completion}

#### Core Completion Method

```java
public static CompletionResult generateCompletion(
    long contextHandle,
    CompletionParams params
)
```

#### Simplified Completion Method

```java
public static CompletionResult generateCompletion(
    long contextHandle,
    String prompt,
    int maxTokens,
    double temperature,
    TokenCallback tokenCallback,
    boolean useJsonResponse
)

// Overload with default parameters
public static CompletionResult generateCompletion(
    long contextHandle,
    String prompt
)
```

#### OpenAI-Compatible Completion

```java
public static CompletionResult generateOpenAICompletion(
    long contextHandle,
    String openAIJSON
)
```

#### Stop Completion

```java
public static void stopCompletion(long contextHandle)
```

#### CompletionParams Structure

```java
public static class CompletionParams {
    private final String prompt;
    private final int maxTokens;
    private final Integer nThreads;
    private final int seed;
    private final double temperature;
    private final int topK;
    private final double topP;
    private final double minP;
    private final double typicalP;
    private final int penaltyLastN;
    private final double penaltyRepeat;
    private final double penaltyFreq;
    private final double penaltyPresent;
    private final int mirostat;
    private final double mirostatTau;
    private final double mirostatEta;
    private final boolean ignoreEos;
    private final List<String> stopSequences;
    private final String grammar;
    private final boolean useJsonResponse;
    private final TokenCallback tokenCallback;
    private final List<ChatMessage> chatMessages;
    private final List<String> mediaPaths;
    private final String jsonSchema;
    private final String tools;
    private final String toolChoice;
    private final boolean parallelToolCalls;
    private final int nProbs;

    private CompletionParams(Builder builder) {
        this.prompt = builder.prompt;
        this.maxTokens = builder.maxTokens;
        this.nThreads = builder.nThreads;
        this.seed = builder.seed;
        this.temperature = builder.temperature;
        this.topK = builder.topK;
        this.topP = builder.topP;
        this.minP = builder.minP;
        this.typicalP = builder.typicalP;
        this.penaltyLastN = builder.penaltyLastN;
        this.penaltyRepeat = builder.penaltyRepeat;
        this.penaltyFreq = builder.penaltyFreq;
        this.penaltyPresent = builder.penaltyPresent;
        this.mirostat = builder.mirostat;
        this.mirostatTau = builder.mirostatTau;
        this.mirostatEta = builder.mirostatEta;
        this.ignoreEos = builder.ignoreEos;
        this.stopSequences = builder.stopSequences;
        this.grammar = builder.grammar;
        this.useJsonResponse = builder.useJsonResponse;
        this.tokenCallback = builder.tokenCallback;
        this.chatMessages = builder.chatMessages;
        this.mediaPaths = builder.mediaPaths;
        this.jsonSchema = builder.jsonSchema;
        this.tools = builder.tools;
        this.toolChoice = builder.toolChoice;
        this.parallelToolCalls = builder.parallelToolCalls;
        this.nProbs = builder.nProbs;
    }

    public static class Builder {
        private final String prompt;
        private int maxTokens = 1024;
        private Integer nThreads = null;
        private int seed = -1;
        private double temperature = 0.8;
        private int topK = 40;
        private double topP = 0.95;
        private double minP = 0.05;
        private double typicalP = 1.0;
        private int penaltyLastN = 64;
        private double penaltyRepeat = 1.1;
        private double penaltyFreq = 0.0;
        private double penaltyPresent = 0.0;
        private int mirostat = 0;
        private double mirostatTau = 5.0;
        private double mirostatEta = 0.1;
        private boolean ignoreEos = false;
        private List<String> stopSequences = new ArrayList<>();
        private String grammar = null;
        private boolean useJsonResponse = false;
        private TokenCallback tokenCallback = null;
        private List<ChatMessage> chatMessages = new ArrayList<>();
        private List<String> mediaPaths = new ArrayList<>();
        private String jsonSchema = null;
        private String tools = null;
        private String toolChoice = null;
        private boolean parallelToolCalls = false;
        private int nProbs = 0;

        public Builder(String prompt) {
            this.prompt = prompt;
        }

        public Builder maxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
            return this;
        }

        public Builder nThreads(Integer nThreads) {
            this.nThreads = nThreads;
            return this;
        }

        public Builder seed(int seed) {
            this.seed = seed;
            return this;
        }

        public Builder temperature(double temperature) {
            this.temperature = temperature;
            return this;
        }

        public Builder topK(int topK) {
            this.topK = topK;
            return this;
        }

        public Builder topP(double topP) {
            this.topP = topP;
            return this;
        }

        public Builder minP(double minP) {
            this.minP = minP;
            return this;
        }

        public Builder typicalP(double typicalP) {
            this.typicalP = typicalP;
            return this;
        }

        public Builder penaltyLastN(int penaltyLastN) {
            this.penaltyLastN = penaltyLastN;
            return this;
        }

        public Builder penaltyRepeat(double penaltyRepeat) {
            this.penaltyRepeat = penaltyRepeat;
            return this;
        }

        public Builder penaltyFreq(double penaltyFreq) {
            this.penaltyFreq = penaltyFreq;
            return this;
        }

        public Builder penaltyPresent(double penaltyPresent) {
            this.penaltyPresent = penaltyPresent;
            return this;
        }

        public Builder mirostat(int mirostat) {
            this.mirostat = mirostat;
            return this;
        }

        public Builder mirostatTau(double mirostatTau) {
            this.mirostatTau = mirostatTau;
            return this;
        }

        public Builder mirostatEta(double mirostatEta) {
            this.mirostatEta = mirostatEta;
            return this;
        }

        public Builder ignoreEos(boolean ignoreEos) {
            this.ignoreEos = ignoreEos;
            return this;
        }

        public Builder stopSequences(List<String> stopSequences) {
            this.stopSequences = stopSequences;
            return this;
        }

        public Builder grammar(String grammar) {
            this.grammar = grammar;
            return this;
        }

        public Builder useJsonResponse(boolean useJsonResponse) {
            this.useJsonResponse = useJsonResponse;
            return this;
        }

        public Builder tokenCallback(TokenCallback tokenCallback) {
            this.tokenCallback = tokenCallback;
            return this;
        }

        public Builder chatMessages(List<ChatMessage> chatMessages) {
            this.chatMessages = chatMessages;
            return this;
        }

        public Builder mediaPaths(List<String> mediaPaths) {
            this.mediaPaths = mediaPaths;
            return this;
        }

        public Builder jsonSchema(String jsonSchema) {
            this.jsonSchema = jsonSchema;
            return this;
        }

        public Builder tools(String tools) {
            this.tools = tools;
            return this;
        }

        public Builder toolChoice(String toolChoice) {
            this.toolChoice = toolChoice;
            return this;
        }

        public Builder parallelToolCalls(boolean parallelToolCalls) {
            this.parallelToolCalls = parallelToolCalls;
            return this;
        }

        public Builder nProbs(int nProbs) {
            this.nProbs = nProbs;
            return this;
        }

        public CompletionParams build() {
            return new CompletionParams(this);
        }
    }

    // Getters
    public String getPrompt() { return prompt; }
    public int getMaxTokens() { return maxTokens; }
    public Integer getNThreads() { return nThreads; }
    public int getSeed() { return seed; }
    public double getTemperature() { return temperature; }
    public int getTopK() { return topK; }
    public double getTopP() { return topP; }
    public double getMinP() { return minP; }
    public double getTypicalP() { return typicalP; }
    public int getPenaltyLastN() { return penaltyLastN; }
    public double getPenaltyRepeat() { return penaltyRepeat; }
    public double getPenaltyFreq() { return penaltyFreq; }
    public double getPenaltyPresent() { return penaltyPresent; }
    public int getMirostat() { return mirostat; }
    public double getMirostatTau() { return mirostatTau; }
    public double getMirostatEta() { return mirostatEta; }
    public boolean isIgnoreEos() { return ignoreEos; }
    public List<String> getStopSequences() { return stopSequences; }
    public String getGrammar() { return grammar; }
    public boolean isUseJsonResponse() { return useJsonResponse; }
    public TokenCallback getTokenCallback() { return tokenCallback; }
    public List<ChatMessage> getChatMessages() { return chatMessages; }
    public List<String> getMediaPaths() { return mediaPaths; }
    public String getJsonSchema() { return jsonSchema; }
    public String getTools() { return tools; }
    public String getToolChoice() { return toolChoice; }
    public boolean isParallelToolCalls() { return parallelToolCalls; }
    public int getNProbs() { return nProbs; }
}
```

#### ChatMessage Structure

```java
public static class ChatMessage {
    private final String role;
    private final String content;

    public ChatMessage(String role, String content) {
        this.role = role;
        this.content = content;
    }

    public String getRole() { return role; }
    public String getContent() { return content; }
}
```

#### CompletionResult Structure

```java
public static class CompletionResult {
    private final String text;
    private final int tokensGenerated;
    private final int tokensEvaluated;
    private final boolean truncated;
    private final boolean stoppedEos;
    private final boolean stoppedWord;
    private final boolean stoppedLimit;
    private final String stoppingWord;

    public CompletionResult(String text, int tokensGenerated, int tokensEvaluated, 
                           boolean truncated, boolean stoppedEos, boolean stoppedWord, 
                           boolean stoppedLimit, String stoppingWord) {
        this.text = text;
        this.tokensGenerated = tokensGenerated;
        this.tokensEvaluated = tokensEvaluated;
        this.truncated = truncated;
        this.stoppedEos = stoppedEos;
        this.stoppedWord = stoppedWord;
        this.stoppedLimit = stoppedLimit;
        this.stoppingWord = stoppingWord;
    }

    public String getText() { return text; }
    public int getTokensGenerated() { return tokensGenerated; }
    public int getTokensEvaluated() { return tokensEvaluated; }
    public boolean isTruncated() { return truncated; }
    public boolean isStoppedEos() { return stoppedEos; }
    public boolean isStoppedWord() { return stoppedWord; }
    public boolean isStoppedLimit() { return stoppedLimit; }
    public String getStoppingWord() { return stoppingWord; }
}
```

#### TokenCallback Interface

```java
public interface TokenCallback {
    boolean onToken(String token);
}
```

#### Usage Examples

##### Basic Completion

```java
public void generateBasicCompletion() {
    long contextHandle = LlamaMobile.getContext();
    LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams.Builder(
        "Write a short story about a robot learning to paint."
    )
    .maxTokens(512)
    .temperature(0.7)
    .build();
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
    
    if (result != null) {
        System.out.println("Generated text: " + result.getText());
        System.out.println("Tokens generated: " + result.getTokensGenerated());
        System.out.println("Tokens evaluated: " + result.getTokensEvaluated());
    } else {
        System.out.println("Failed to generate completion");
    }
}
```

##### Streaming Completion

```java
public void generateStreamingCompletion() {
    long contextHandle = LlamaMobile.getContext();
    LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams.Builder(
        "Explain quantum computing in simple terms."
    )
    .maxTokens(300)
    .temperature(0.6)
    .tokenCallback(token -> {
        System.out.print(token);
        return true; // Return false to stop generation
    })
    .build();
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
    
    if (result != null) {
        System.out.println("\n\nGeneration complete!");
        System.out.println("Total tokens: " + result.getTokensGenerated());
    }
}
```

##### Chat Completion

```java
public void generateChatCompletion() {
    long contextHandle = LlamaMobile.getContext();
    List<LlamaMobile.ChatMessage> messages = new ArrayList<>();
    messages.add(new LlamaMobile.ChatMessage("system", "You are a helpful assistant."));
    messages.add(new LlamaMobile.ChatMessage("user", "What's the capital of France?"));
    messages.add(new LlamaMobile.ChatMessage("assistant", "The capital of France is Paris."));
    messages.add(new LlamaMobile.ChatMessage("user", "What's a famous landmark there?"));
    
    LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams.Builder("")
    .chatMessages(messages)
    .maxTokens(200)
    .temperature(0.7)
    .build();
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
    
    if (result != null) {
        System.out.println("Assistant: " + result.getText());
    }
}
```

##### OpenAI-Compatible Completion

```java
public void generateOpenAICompletion() {
    long contextHandle = LlamaMobile.getContext();
    String openAIJSON = """
    {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Tell me a joke about computers."}
        ],
        "max_tokens": 150,
        "temperature": 0.7
    }
    """;
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON);
    
    if (result != null) {
        System.out.println("Generated response: " + result.getText());
    }
}
```

### Flutter {#flutter-completion}

#### Core Completion Methods

##### Basic Completion

```dart
Future<CompletionResult?> generateCompletion({
  required String prompt,
  int maxTokens = 1024,
  int? nThreads,
  int seed = -1,
  double temperature = 0.8,
  int topK = 40,
  double topP = 0.95,
  double minP = 0.05,
  double typicalP = 1.0,
  int penaltyLastN = 64,
  double penaltyRepeat = 1.1,
  double penaltyFreq = 0.0,
  double penaltyPresent = 0.0,
  int mirostat = 0,
  double mirostatTau = 5.0,
  double mirostatEta = 0.1,
  bool ignoreEos = false,
  List<String> stopSequences = const [],
  String? grammar,
  bool useJsonResponse = true,
  String? chatTemplate,
})
```

##### Completion with Params

```dart
Future<CompletionResult?> generateCompletionWithParams(CompletionParams params)
```

##### Streaming Completion

```dart
Future<CompletionResult?> generateStreamingCompletion({
  required String prompt,
  int maxTokens = 1024,
  int? nThreads,
  int seed = -1,
  double temperature = 0.8,
  int topK = 40,
  double topP = 0.95,
  double minP = 0.05,
  double typicalP = 1.0,
  int penaltyLastN = 64,
  double penaltyRepeat = 1.1,
  double penaltyFreq = 0.0,
  double penaltyPresent = 0.0,
  int mirostat = 0,
  double mirostatTau = 5.0,
  double mirostatEta = 0.1,
  bool ignoreEos = false,
  List<String> stopSequences = const [],
  String? grammar,
  bool useJsonResponse = true,
  String? chatTemplate,
})
```

##### Conversation Generation

```dart
Future<ConversationResult?> generateConversation({
  required List<ChatMessage> chatMessages,
  int maxTokens = 1024,
  int? nThreads,
  int seed = -1,
  double temperature = 0.8,
  int topK = 40,
  double topP = 0.95,
  double minP = 0.05,
  double typicalP = 1.0,
  int penaltyLastN = 64,
  double penaltyRepeat = 1.1,
  double penaltyFreq = 0.0,
  double penaltyPresent = 0.0,
  int mirostat = 0,
  double mirostatTau = 5.0,
  double mirostatEta = 0.1,
  bool ignoreEos = false,
  List<String> stopSequences = const [],
  String? grammar,
  bool useJsonResponse = true,
  String? chatTemplate,
})
```

##### OpenAI-Compatible Completion

```dart
Future<CompletionResult?> generateOpenAICompletion({
  required String openAIJSON,
  String? grammar,
})
```

#### CompletionParams Structure

```dart
class CompletionParams {
  final String prompt;
  final int maxTokens;
  final int? nThreads;
  final int seed;
  final double temperature;
  final int topK;
  final double topP;
  final double minP;
  final double typicalP;
  final int penaltyLastN;
  final double penaltyRepeat;
  final double penaltyFreq;
  final double penaltyPresent;
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  final bool ignoreEos;
  final List<String> stopSequences;
  final String? grammar;
  final bool useJsonResponse;
  final int nProbs;
  final String? jsonSchema;
  final String? tools;
  final bool parallelToolCalls;
  final String? toolChoice;
  final List<String> mediaPaths;
  final List<ChatMessage> chatMessages;
  final String? chatTemplate;

  CompletionParams({
    required this.prompt,
    this.maxTokens = 1024,
    this.nThreads,
    this.seed = -1,
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.minP = 0.05,
    this.typicalP = 1.0,
    this.penaltyLastN = 64,
    this.penaltyRepeat = 1.1,
    this.penaltyFreq = 0.0,
    this.penaltyPresent = 0.0,
    this.mirostat = 0,
    this.mirostatTau = 5.0,
    this.mirostatEta = 0.1,
    this.ignoreEos = false,
    this.stopSequences = const [],
    this.grammar,
    this.useJsonResponse = true,
    this.nProbs = 0,
    this.jsonSchema,
    this.tools,
    this.parallelToolCalls = false,
    this.toolChoice,
    this.mediaPaths = const [],
    this.chatMessages = const [],
    this.chatTemplate,
  });

  Map<String, dynamic> toMap() {
    return {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'nThreads': nThreads,
      'seed': seed,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
      'penaltyLastN': penaltyLastN,
      'penaltyRepeat': penaltyRepeat,
      'penaltyFreq': penaltyFreq,
      'penaltyPresent': penaltyPresent,
      'mirostat': mirostat,
      'mirostatTau': mirostatTau,
      'mirostatEta': mirostatEta,
      'ignoreEos': ignoreEos,
      'stopSequences': stopSequences,
      'grammar': grammar,
      'useJsonResponse': useJsonResponse,
      'nProbs': nProbs,
      'jsonSchema': jsonSchema,
      'tools': tools,
      'parallelToolCalls': parallelToolCalls,
      'toolChoice': toolChoice,
      'mediaPaths': mediaPaths,
      'chatMessages': chatMessages.map((m) => m.toMap()).toList(),
      'chatTemplate': chatTemplate,
    };
  }
}
```

#### Usage Examples

##### Basic Completion

```dart
final result = await context?.generateCompletion(
  prompt: 'Hello, how are you?',
  maxTokens: 128,
  temperature: 0.8,
  topP: 0.95,
  topK: 40,
);

if (result != null) {
  print('Generated: ${result.text}');
}
```

##### Conversation

```dart
final messages = [
  ChatMessage(role: 'user', content: 'Hello, what is AI?'),
];

final response = await context?.generateConversation(
  chatMessages: messages,
  maxTokens: 256,
);

if (response != null) {
  print('Response: ${response.text}');
}
```

##### Streaming Completion

```dart
final result = await context?.generateStreamingCompletion(
  prompt: 'Tell me a story',
  maxTokens: 512,
);

if (result != null) {
  print('Generated: ${result.text}');
}
```

##### OpenAI-Compatible Completion

```dart
final openAIJSON = '''
{
  "model": "gpt-3.5-turbo",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Tell me a joke about computers."}
  ],
  "max_tokens": 150,
  "temperature": 0.7
}
''';

final result = await context?.generateOpenAICompletion(
  openAIJSON: openAIJSON,
);

if (result != null) {
  print('Generated: ${result.text}');
}
```

## Multimodal APIs

### Multimodal Completion

```swift
public func generateMultimodalCompletion(with params: CompletionParams, mediaPaths: [String]) -> CompletionResult?
```

### Usage Examples

#### Image Analysis

```swift
func analyzeImage() {
    // Path to an image file
    let imagePath = "\(Bundle.main.bundlePath)/Images/cat.jpg"
    
    let params = LlamaMobile.CompletionParams(prompt: "Describe this image in detail.")
    params.maxTokens = 500
    params.temperature = 0.7
    
    if let result = llamaMobile.generateMultimodalCompletion(with: params, mediaPaths: [imagePath]) {
        print("Image description: \(result.text)")
    } else {
        print("Failed to analyze image")
    }
}
```

#### Multiple Media Analysis

```swift
func analyzeMultipleImages() {
    // Paths to image files
    let imagePaths = [
        "\(Bundle.main.bundlePath)/Images/forest.jpg",
        "\(Bundle.main.bundlePath)/Images/mountain.jpg"
    ]
    
    let params = LlamaMobile.CompletionParams(prompt: "Compare these two images and describe the differences.")
    params.maxTokens = 600
    params.temperature = 0.7
    
    if let result = llamaMobile.generateMultimodalCompletion(with: params, mediaPaths: imagePaths) {
        print("Comparison: \(result.text)")
    } else {
        print("Failed to analyze images")
    }
}
```

### Android Kotlin {#android-kotlin-multimodal}

#### Multimodal Completion

```kotlin
@JvmStatic
fun generateMultimodalCompletion(
    contextHandle: Long,
    params: CompletionParams,
    mediaPaths: List<String>
): CompletionResult?
```

#### Usage Examples

##### Image Analysis

```kotlin
fun analyzeImage() {
    // Path to an image file
    val imagePath = "${context.filesDir}/Images/cat.jpg"
    val contextHandle = LlamaMobile.getContext()
    
    val params = CompletionParams(
        prompt = "Describe this image in detail."
    )
    params.maxTokens = 500
    params.temperature = 0.7
    
    val result = LlamaMobile.generateMultimodalCompletion(contextHandle, params, listOf(imagePath))
    
    if (result != null) {
        println("Image description: ${result.text}")
    } else {
        println("Failed to analyze image")
    }
}
```

##### Multiple Media Analysis

```kotlin
fun analyzeMultipleImages() {
    // Paths to image files
    val imagePaths = listOf(
        "${context.filesDir}/Images/forest.jpg",
        "${context.filesDir}/Images/mountain.jpg"
    )
    val contextHandle = LlamaMobile.getContext()
    
    val params = CompletionParams(
        prompt = "Compare these two images and describe the differences."
    )
    params.maxTokens = 600
    params.temperature = 0.7
    
    val result = LlamaMobile.generateMultimodalCompletion(contextHandle, params, imagePaths)
    
    if (result != null) {
        println("Comparison: ${result.text}")
    } else {
        println("Failed to analyze images")
    }
}
```

### Android Java {#android-java-multimodal}

#### Multimodal Completion

```java
public static CompletionResult generateMultimodalCompletion(
    long contextHandle,
    CompletionParams params,
    List<String> mediaPaths
)
```

#### Usage Examples

##### Image Analysis

```java
public void analyzeImage() {
    // Path to an image file
    String imagePath = getFilesDir() + File.separator + "Images" + File.separator + "cat.jpg";
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams.Builder(
        "Describe this image in detail."
    )
    .maxTokens(500)
    .temperature(0.7)
    .build();
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateMultimodalCompletion(
        contextHandle, params, Collections.singletonList(imagePath)
    );
    
    if (result != null) {
        System.out.println("Image description: " + result.getText());
    } else {
        System.out.println("Failed to analyze image");
    }
}
```

##### Multiple Media Analysis

```java
public void analyzeMultipleImages() {
    // Paths to image files
    List<String> imagePaths = Arrays.asList(
        getFilesDir() + File.separator + "Images" + File.separator + "forest.jpg",
        getFilesDir() + File.separator + "Images" + File.separator + "mountain.jpg"
    );
    long contextHandle = LlamaMobile.getContext();
    
    LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams.Builder(
        "Compare these two images and describe the differences."
    )
    .maxTokens(600)
    .temperature(0.7)
    .build();
    
    LlamaMobile.CompletionResult result = LlamaMobile.generateMultimodalCompletion(
        contextHandle, params, imagePaths
    );
    
    if (result != null) {
        System.out.println("Comparison: " + result.getText());
    } else {
        System.out.println("Failed to analyze images");
    }
}
```

### Flutter {#flutter-multimodal}

#### Multimodal Completion

```dart
Future<CompletionResult?> generateMultimodalCompletion({
  required String prompt,
  required List<String> mediaPaths,
  int maxTokens = 1024,
  int? nThreads,
  int seed = -1,
  double temperature = 0.8,
  int topK = 40,
  double topP = 0.95,
  double minP = 0.05,
  double typicalP = 1.0,
  int penaltyLastN = 64,
  double penaltyRepeat = 1.1,
  double penaltyFreq = 0.0,
  double penaltyPresent = 0.0,
  int mirostat = 0,
  double mirostatTau = 5.0,
  double mirostatEta = 0.1,
  bool ignoreEos = false,
  List<String> stopSequences = const [],
  String? grammar,
  bool useJsonResponse = true,
  String? chatTemplate,
})
```

#### Usage Examples

##### Image Analysis

```dart
final imagePath = 'assets/images/cat.jpg';

final result = await context?.generateMultimodalCompletion(
  prompt: 'Describe this image in detail.',
  mediaPaths: [imagePath],
  maxTokens: 500,
  temperature: 0.7,
);

if (result != null) {
  print('Image description: ${result.text}');
} else {
  print('Failed to analyze image');
}
```

##### Multiple Media Analysis

```dart
final imagePaths = [
  'assets/images/cat.jpg',
  'assets/images/dog.jpg',
];

final result = await context?.generateMultimodalCompletion(
  prompt: 'Compare these two images and describe the differences.',
  mediaPaths: imagePaths,
  maxTokens: 600,
  temperature: 0.7,
);

if (result != null) {
  print('Comparison: ${result.text}');
} else {
  print('Failed to analyze images');
}
```

## 4. Embedding APIs

### Generate Embeddings

```swift
public func generateEmbedding(text: String) -> [Float]?
```

### Get Embedding Dimension

```swift
public func getEmbeddingDimension() -> Int
```

### Usage Examples

#### Basic Embedding Generation

```swift
func generateEmbeddings() {
    // Assuming llamaMobile is initialized with embedding=true
    let text = "The quick brown fox jumps over the lazy dog"
    
    if let embedding = llamaMobile.generateEmbedding(text: text) {
        print("Embedding generated successfully")
        print("Embedding dimension: \(embedding.count)")
        print("First 5 values: \(embedding.prefix(5))")
    } else {
        print("Failed to generate embedding")
    }
}
```

#### Semantic Similarity

```swift
func calculateSimilarity() {
    // Generate embeddings for two texts
    let text1 = "A cat sitting on a couch"
    let text2 = "A feline resting on furniture"
    
    guard let embedding1 = llamaMobile.generateEmbedding(text: text1),
          let embedding2 = llamaMobile.generateEmbedding(text: text2) else {
        print("Failed to generate embeddings")
        return
    }
    
    // Calculate cosine similarity
    let similarity = cosineSimilarity(embedding1, embedding2)
    print("Semantic similarity: \(similarity)")
}

func cosineSimilarity(_ vector1: [Float], _ vector2: [Float]) -> Float {
    guard vector1.count == vector2.count else {
        return 0.0
    }
    
    var dotProduct: Float = 0.0
    var norm1: Float = 0.0
    var norm2: Float = 0.0
    
    for i in 0..<vector1.count {
        dotProduct += vector1[i] * vector2[i]
        norm1 += vector1[i] * vector1[i]
        norm2 += vector2[i] * vector2[i]
    }
    
    guard norm1 > 0 && norm2 > 0 else {
        return 0.0
    }
    
    return dotProduct / (sqrt(norm1) * sqrt(norm2))
}
```

### Android Kotlin {#android-kotlin-embedding}

#### Generate Embeddings

```kotlin
@JvmStatic
fun generateEmbedding(
    contextHandle: Long,
    text: String
): FloatArray?
```

#### Get Embedding Dimension

```kotlin
@JvmStatic
fun getEmbeddingDimension(contextHandle: Long): Int
```

#### Usage Examples

##### Basic Embedding Generation

```kotlin
fun generateEmbeddings() {
    // Assuming model is initialized with embedding=true
    val text = "The quick brown fox jumps over the lazy dog"
    val contextHandle = LlamaMobile.getContext()
    
    val embedding = LlamaMobile.generateEmbedding(contextHandle, text)
    
    if (embedding != null) {
        println("Embedding generated successfully")
        println("Embedding dimension: ${embedding.size}")
        println("First 5 values: ${embedding.take(5).joinToString()}")
    } else {
        println("Failed to generate embedding")
    }
}
```

##### Semantic Similarity

```kotlin
fun calculateSimilarity() {
    // Generate embeddings for two texts
    val text1 = "A cat sitting on a couch"
    val text2 = "A feline resting on furniture"
    val contextHandle = LlamaMobile.getContext()
    
    val embedding1 = LlamaMobile.generateEmbedding(contextHandle, text1)
    val embedding2 = LlamaMobile.generateEmbedding(contextHandle, text2)
    
    if (embedding1 != null && embedding2 != null) {
        // Calculate cosine similarity
        val similarity = cosineSimilarity(embedding1, embedding2)
        println("Semantic similarity: $similarity")
    } else {
        println("Failed to generate embeddings")
    }
}

fun cosineSimilarity(vector1: FloatArray, vector2: FloatArray): Float {
    if (vector1.size != vector2.size) return 0.0f
    
    var dotProduct: Float = 0.0f
    var norm1: Float = 0.0f
    var norm2: Float = 0.0f
    
    for (i in vector1.indices) {
        dotProduct += vector1[i] * vector2[i]
        norm1 += vector1[i] * vector1[i]
        norm2 += vector2[i] * vector2[i]
    }
    
    if (norm1 <= 0.0f || norm2 <= 0.0f) return 0.0f
    
    return dotProduct / (kotlin.math.sqrt(norm1) * kotlin.math.sqrt(norm2))
}
```

### Android Java {#android-java-embedding}

#### Generate Embeddings

```java
public static float[] generateEmbedding(
    long contextHandle,
    String text
)
```

#### Get Embedding Dimension

```java
public static int getEmbeddingDimension(long contextHandle)
```

#### Usage Examples

##### Basic Embedding Generation

```java
public void generateEmbeddings() {
    // Assuming model is initialized with embedding=true
    String text = "The quick brown fox jumps over the lazy dog";
    long contextHandle = LlamaMobile.getContext();
    
    float[] embedding = LlamaMobile.generateEmbedding(contextHandle, text);
    
    if (embedding != null) {
        System.out.println("Embedding generated successfully");
        System.out.println("Embedding dimension: " + embedding.length);
        System.out.print("First 5 values: ");
        for (int i = 0; i < Math.min(5, embedding.length); i++) {
            System.out.print(embedding[i] + " ");
        }
        System.out.println();
    } else {
        System.out.println("Failed to generate embedding");
    }
}
```

##### Semantic Similarity

```java
public void calculateSimilarity() {
    // Generate embeddings for two texts
    String text1 = "A cat sitting on a couch";
    String text2 = "A feline resting on furniture";
    long contextHandle = LlamaMobile.getContext();
    
    float[] embedding1 = LlamaMobile.generateEmbedding(contextHandle, text1);
    float[] embedding2 = LlamaMobile.generateEmbedding(contextHandle, text2);
    
    if (embedding1 != null && embedding2 != null) {
        // Calculate cosine similarity
        double similarity = cosineSimilarity(embedding1, embedding2);
        System.out.println("Semantic similarity: " + similarity);
    } else {
        System.out.println("Failed to generate embeddings");
    }
}

public double cosineSimilarity(float[] vector1, float[] vector2) {
    if (vector1.length != vector2.length) return 0.0;
    
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    
    for (int i = 0; i < vector1.length; i++) {
        dotProduct += vector1[i] * vector2[i];
        norm1 += vector1[i] * vector1[i];
        norm2 += vector2[i] * vector2[i];
    }
    
    if (norm1 <= 0.0 || norm2 <= 0.0) return 0.0;
    
    return dotProduct / (Math.sqrt(norm1) * Math.sqrt(norm2));
}
```

### Flutter {#flutter-embedding}

#### Generate Embeddings

```dart
Future<List<double>?> generateEmbedding(String text)
```

#### Get Embedding Dimension

```dart
Future<int?> getEmbeddingDimension()
```

#### Usage Examples

##### Basic Embedding Generation

```dart
final text = 'The quick brown fox jumps over the lazy dog';

final embedding = await context?.generateEmbedding(text);

if (embedding != null) {
  print('Embedding generated successfully');
  print('Embedding dimension: ${embedding.length}');
  print('First 5 values: ${embedding.take(5)}');
} else {
  print('Failed to generate embedding');
}
```

##### Semantic Search with Embeddings

```dart
final query = 'What is artificial intelligence?';
final documents = [
  'AI is the simulation of human intelligence by machines.',
  'Machine learning is a subset of AI.',
  'Deep learning uses neural networks.',
];

final queryEmbedding = await context?.generateEmbedding(query);
final documentEmbeddings = await Future.wait(
  documents.map((doc) => context?.generateEmbedding(doc)),
);

if (queryEmbedding != null && documentEmbeddings.every((e) => e != null)) {
  final similarities = documentEmbeddings.asMap().entries.map((entry) {
    final idx = entry.key;
    final docEmbedding = entry.value!;
    return {
      'document': documents[idx],
      'similarity': cosineSimilarity(queryEmbedding!, docEmbedding),
    };
  }).toList();

  final sorted = similarities.toList()
    ..sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

  print('Most similar document:');
  print('${sorted.first['document']}');
  print('Similarity: ${sorted.first['similarity']}');
}
```

##### Cosine Similarity Helper

```dart
double cosineSimilarity(List<double> vector1, List<double> vector2) {
  if (vector1.length != vector2.length) return 0.0;

  double dotProduct = 0.0;
  double norm1 = 0.0;
  double norm2 = 0.0;

  for (int i = 0; i < vector1.length; i++) {
    dotProduct += vector1[i] * vector2[i];
    norm1 += vector1[i] * vector1[i];
    norm2 += vector2[i] * vector2[i];
  }

  if (norm1 <= 0.0 || norm2 <= 0.0) return 0.0;

  return dotProduct / (sqrt(norm1) * sqrt(norm2));
}
```

## 5. Vocoder Load APIs

### iOS {#ios-vocoder}

#### Initialize Vocoder

```swift
public func initVocoder(vocoderModelPath: String) -> Bool
```

#### Check Vocoder Status

```swift
public func isVocoderEnabled() -> Bool
```

#### Release Vocoder

```swift
public func releaseVocoder()
```

#### Usage Examples

##### Initialize Vocoder for TTS

```swift
func setupVocoder() {
    // Path to vocoder model
    let vocoderPath = "\(Bundle.main.bundlePath)/Models/vocoder-model.gguf"
    
    if llamaMobile.initVocoder(vocoderModelPath: vocoderPath) {
        print("Vocoder initialized successfully")
    } else {
        print("Failed to initialize vocoder")
    }
}
```

##### Check Vocoder Status

```swift
func checkVocoderStatus() {
    if llamaMobile.isVocoderEnabled() {
        print("Vocoder is enabled and ready for TTS")
    } else {
        print("Vocoder is not enabled. Please initialize it first.")
    }
}
```

##### Release Vocoder Resources

```swift
func cleanupVocoder() {
    llamaMobile.releaseVocoder()
    print("Vocoder resources released")
}
```

### Android Kotlin {#android-kotlin-vocoder}

#### Initialize Vocoder

```kotlin
@JvmStatic
fun initVocoder(vocoderModelPath: String): Boolean
```

#### Check Vocoder Status

```kotlin
@JvmStatic
fun isVocoderEnabled(): Boolean
```

#### Release Vocoder

```kotlin
@JvmStatic
fun releaseVocoder()
```

#### Usage Examples

##### Initialize Vocoder for TTS

```kotlin
fun setupVocoder() {
    // Path to vocoder model
    val vocoderPath = "${context.filesDir}/Models/vocoder-model.gguf"
    
    if (LlamaMobile.initVocoder(vocoderPath)) {
        println("Vocoder initialized successfully")
    } else {
        println("Failed to initialize vocoder")
    }
}
```

##### Check Vocoder Status

```kotlin
fun checkVocoderStatus() {
    if (LlamaMobile.isVocoderEnabled()) {
        println("Vocoder is enabled and ready for TTS")
    } else {
        println("Vocoder is not enabled. Please initialize it first.")
    }
}
```

##### Release Vocoder Resources

```kotlin
fun cleanupVocoder() {
    LlamaMobile.releaseVocoder()
    println("Vocoder resources released")
}
```

### Android Java {#android-java-vocoder}

#### Initialize Vocoder

```java
public static boolean initVocoder(String vocoderModelPath)
```

#### Check Vocoder Status

```java
public static boolean isVocoderEnabled()
```

#### Release Vocoder

```java
public static void releaseVocoder()
```

#### Usage Examples

##### Initialize Vocoder for TTS

```java
public void setupVocoder() {
    // Path to vocoder model
    String vocoderPath = getFilesDir() + File.separator + "Models" + File.separator + "vocoder-model.gguf";
    
    if (LlamaMobile.initVocoder(vocoderPath)) {
        System.out.println("Vocoder initialized successfully");
    } else {
        System.out.println("Failed to initialize vocoder");
    }
}
```

##### Check Vocoder Status

```java
public void checkVocoderStatus() {
    if (LlamaMobile.isVocoderEnabled()) {
        System.out.println("Vocoder is enabled and ready for TTS");
    } else {
        System.out.println("Vocoder is not enabled. Please initialize it first.");
    }
}
```

##### Release Vocoder Resources

```java
public void cleanupVocoder() {
    LlamaMobile.releaseVocoder();
    System.out.println("Vocoder resources released");
}
```

### Flutter {#flutter-vocoder}

#### Initialize Vocoder

```dart
Future<bool> initVocoder(String vocoderModelPath)
```

#### Check Vocoder Status

```dart
Future<bool> isVocoderEnabled()
```

#### Release Vocoder

```dart
Future<void> releaseVocoder()
```

#### Usage Examples

##### Initialize Vocoder for TTS

```dart
final vocoderPath = 'assets/models/vocoder-model.gguf';

final success = await context?.initVocoder(vocoderPath);

if (success ?? false) {
  print('Vocoder initialized successfully');
} else {
  print('Failed to initialize vocoder');
}
```

##### Check Vocoder Status

```dart
final isEnabled = await context?.isVocoderEnabled();

if (isEnabled ?? false) {
  print('Vocoder is enabled and ready for TTS');
} else {
  print('Vocoder is not enabled. Please initialize it first.');
}
```

##### Release Vocoder Resources

```dart
  await context?.releaseVocoder();
  print('Vocoder resources released');
}
```

### Flutter {#flutter-types}

#### CompletionResult

Result of a text completion.

```dart
class CompletionResult {
  final String text;
  final int tokensGenerated;
  final int tokensEvaluated;
  final bool truncated;
  final bool stoppedEos;
  final bool stoppedWord;
  final bool stoppedLimit;
  final String? stoppingWord;

  CompletionResult({
    required this.text,
    required this.tokensGenerated,
    required this.tokensEvaluated,
    required this.truncated,
    required this.stoppedEos,
    required this.stoppedWord,
    required this.stoppedLimit,
    this.stoppingWord,
  });

  factory CompletionResult.fromMap(Map<String, dynamic> map) {
    return CompletionResult(
      text: map['text'] as String,
      tokensGenerated: map['tokensGenerated'] as int,
      tokensEvaluated: map['tokensEvaluated'] as int,
      truncated: map['truncated'] as bool,
      stoppedEos: map['stoppedEos'] as bool,
      stoppedWord: map['stoppedWord'] as bool,
      stoppedLimit: map['stoppedLimit'] as bool,
      stoppingWord: map['stoppingWord'] as String?,
    );
  }
}
```

#### ConversationResult

Result of a conversation generation.

```dart
class ConversationResult {
  final String text;
  final int timeToFirstToken;
  final int totalTime;
  final int tokensGenerated;

  ConversationResult({
    required this.text,
    required this.timeToFirstToken,
    required this.totalTime,
    required this.tokensGenerated,
  });

  factory ConversationResult.fromMap(Map<String, dynamic> map) {
    return ConversationResult(
      text: map['text'] as String,
      timeToFirstToken: map['timeToFirstToken'] as int,
      totalTime: map['totalTime'] as int,
      tokensGenerated: map['tokensGenerated'] as int,
    );
  }
}
```

#### ChatMessage

Represents a chat message.

```dart
class ChatMessage {
  final String role;
  final String content;
  final String? reasoningContent;
  final String? toolName;
  final String? toolCallId;

  ChatMessage({
    required this.role,
    required this.content,
    this.reasoningContent,
    this.toolName,
    this.toolCallId,
  });

  Map<String, String?> toMap() {
    return {
      'role': role,
      'content': content,
      'reasoning_content': reasoningContent,
      'tool_name': toolName,
      'tool_call_id': toolCallId,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      content: map['content'] as String,
      reasoningContent: map['reasoning_content'] as String?,
      toolName: map['tool_name'] as String?,
      toolCallId: map['tool_call_id'] as String?,
    );
  }
}
```

#### DownloadResult

Result of a download operation.

```dart
class DownloadResult {
  final bool success;
  final String localPath;
  final String? errorMessage;

  DownloadResult({
    required this.success,
    required this.localPath,
    this.errorMessage,
  });

  factory DownloadResult.fromMap(Map<String, dynamic> map) {
    return DownloadResult(
      success: map['success'] as bool,
      localPath: map['localPath'] as String,
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
```

#### TTSModelType

TTS model types.

```dart
enum TTSModelType {
  unknown,
  outETTSv02,
  outETTSv03;

  int get rawValue {
    switch (this) {
      case unknown:
        return -1;
      case outETTSv02:
        return 1;
      case outETTSv03:
        return 2;
    }
  }

  factory TTSModelType.fromRawValue(int value) {
    switch (value) {
      case 1:
        return outETTSv02;
      case 2:
        return outETTSv03;
      default:
        return unknown;
    }
  }
}
```

#### LogLevel

Log levels for the SDK.

```dart
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  none(4);

  final int value;
  const LogLevel(this.value);

  int get rawValue => value;

  factory LogLevel.fromRawValue(int value) {
    switch (value) {
      case 0:
        return debug;
      case 1:
        return info;
      case 2:
        return warning;
      case 3:
        return error;
      case 4:
        return none;
      default:
        return info;
    }
  }
}
```

## Best Practices

### 1. Model Management

- **Model Selection**: Choose the appropriate model size based on device capabilities
- **Model Caching**: Cache models locally to avoid repeated downloads
- **Memory Management**: Monitor memory usage, especially with larger models
- **Background Loading**: Load models in the background to avoid UI blocking

### 2. Performance Optimization

- **Thread Management**: Adjust nThreads based on device capabilities
- **GPU Offloading**: Use nGpuLayers to offload computation to GPU when available
- **Batch Processing**: Use appropriate batch sizes for optimal performance
- **Streaming**: Use tokenCallback for streaming responses to improve perceived performance

### 3. Error Handling

- **Initialization Errors**: Always check if model initialization succeeds
- **Completion Errors**: Handle nil completion results gracefully
- **Resource Constraints**: Check for sufficient memory and storage before loading models
- **Input Validation**: Validate user inputs to prevent errors during generation

### 4. Security Considerations

- **Model Provenance**: Only use models from trusted sources
- **Input Sanitization**: Sanitize user inputs to prevent prompt injection
- **Data Privacy**: Be mindful of data privacy when processing sensitive inputs
- **Resource Protection**: Handle model files securely to prevent unauthorized access

### 5. Multimodal Best Practices

- **Media Format**: Ensure media files are in supported formats
- **Media Size**: Optimize media file sizes for faster processing
- **Prompt Engineering**: Craft specific prompts for better multimodal results
- **Error Handling**: Handle media loading errors appropriately

## Conclusion

The Llama Mobile SDK provides a powerful and flexible set of APIs for working with Large Language Models (LLMs) on both iOS and Android devices. By leveraging these APIs, developers can create applications that utilize state-of-the-art language models for a wide range of tasks, including text generation, chatbots, image analysis, semantic search, and text-to-speech.

The SDK's cross-platform design ensures a consistent experience across all supported platforms, with platform-specific optimizations and patterns to follow each language's best practices. Whether you're building for iOS (Swift), Android Kotlin, or Android Java, the SDK's comprehensive API surface and detailed documentation make it easy to integrate LLM capabilities into your projects.

Whether you're building a simple chat application or a complex multimodal system, the Llama Mobile SDK provides the tools and documentation needed to create powerful, efficient, and reliable LLM-powered applications across all major mobile platforms.

By following the best practices outlined in this documentation, you can ensure that your application provides a smooth, efficient, and secure user experience while harnessing the full power of large language models.
