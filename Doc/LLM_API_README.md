# LLM API Documentation for iOS

## Overview

The Llama Mobile SDK provides a comprehensive set of APIs for working with Large Language Models (LLMs) on iOS devices. This documentation covers all major API categories including model loading, text completion, multimodal processing, embeddings, and vocoder functionality.

## 1. Loading Model APIs

### Initialization Methods

#### Basic Initialization

```swift
public init?(modelPath: String, nCtx: Int32 = 2048, nGpuLayers: Int32 = 0, nThreads: Int32 = 4, progressCallback: ((Float) -> Void)? = nil)
```

#### Advanced Initialization

```swift
public init?(with params: InitParams)
```

### InitParams Structure

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

### Usage Examples

#### Basic Model Loading

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

#### Model Loading with Progress

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

#### Advanced Model Loading

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

## 3. Multimodal APIs

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

## 5. Vocoder Load APIs

### Initialize Vocoder

```swift
public func initVocoder(vocoderModelPath: String) -> Bool
```

### Check Vocoder Status

```swift
public func isVocoderEnabled() -> Bool
```

### Release Vocoder

```swift
public func releaseVocoder()
```

### Usage Examples

#### Initialize Vocoder for TTS

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

#### Check Vocoder Status

```swift
func checkVocoderStatus() {
    if llamaMobile.isVocoderEnabled() {
        print("Vocoder is enabled and ready for TTS")
    } else {
        print("Vocoder is not enabled. Please initialize it first.")
    }
}
```

#### Release Vocoder Resources

```swift
func cleanupVocoder() {
    llamaMobile.releaseVocoder()
    print("Vocoder resources released")
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

The Llama Mobile SDK provides a powerful and flexible set of APIs for working with LLMs on iOS devices. By leveraging these APIs, developers can create applications that utilize state-of-the-art language models for a wide range of tasks, including text generation, chatbots, image analysis, semantic search, and text-to-speech.

Whether you're building a simple chat application or a complex multimodal system, the SDK's comprehensive API surface and detailed documentation make it easy to integrate LLM capabilities into your iOS projects.

By following the best practices outlined in this documentation, you can ensure that your application provides a smooth, efficient, and secure user experience while harnessing the full power of large language models.
