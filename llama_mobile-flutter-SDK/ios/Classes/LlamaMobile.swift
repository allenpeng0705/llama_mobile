//
//  LlamaMobile.swift
//  llama_mobile
//
//  Created by llama_mobile team
//

import Foundation
import llama_mobile
import Darwin
import Dispatch

// MARK: - Logging System

public enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4
}

private var currentLogLevel: LogLevel = .warning

public func setLogLevel(_ level: LogLevel) {
    currentLogLevel = level
}

private func log(_ message: String, level: LogLevel = .info) {
    guard level.rawValue >= currentLogLevel.rawValue else { return }
    
    let prefix: String
    switch level {
    case .debug: prefix = "[DEBUG]"
    case .info: prefix = "[INFO]"
    case .warning: prefix = "[WARNING]"
    case .error: prefix = "[ERROR]"
    case .none: return
    }
    
    print("\(prefix) \(message)")
}

// MARK: - Memory Management Helpers

private func allocateCString(from string: String) -> UnsafeMutablePointer<CChar> {
    let pointer = UnsafeMutablePointer<CChar>.allocate(capacity: string.utf8.count + 1)
    string.withCString { source in
        pointer.update(from: source, count: string.utf8.count + 1)
    }
    return pointer
}

private func allocateCStringArray(from strings: [String]) -> (UnsafeMutablePointer<UnsafePointer<CChar>?>, [UnsafeMutablePointer<CChar>]) {
    let count = strings.count
    let arrayPtr = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: count)
    var stringPtrs: [UnsafeMutablePointer<CChar>] = []
    
    for (index, string) in strings.enumerated() {
        let stringPtr = allocateCString(from: string)
        stringPtrs.append(stringPtr)
        arrayPtr[index] = UnsafePointer(stringPtr)
    }
    
    return (arrayPtr, stringPtrs)
}

// Global callback context holders
private let callbackQueue = DispatchQueue(label: "com.llamamobile.callbacks", attributes: .concurrent)
private var progressCallbackContext: ((Float) -> Void)? = nil
private var downloadProgressCallbackContext: ((Float) -> Void)? = nil
private var hfDownloadProgressCallbackContext: ((Float) -> Void)? = nil
private var tokenCallbackContext: ((String) -> Bool)? = nil
private var completionCallbackContext: ((String) -> Void)? = nil
private var chunkCallbackContext: ((String) -> Void)? = nil
private var embeddingCallbackContext: (([Float]) -> Void)? = nil

// Global properties to retain progress observers
private var progressObserver: NSKeyValueObservation?
private var hfProgressObserver: NSKeyValueObservation?

// C-compatible callback functions
private func cProgressCallback(progress: Float, user_data: UnsafeMutableRawPointer?) -> Void {
    callbackQueue.sync {
        progressCallbackContext?(progress)
    }
}

private func cDownloadProgressCallback(progress: Float, status: UnsafePointer<CChar>?, downloadedBytes: Int64, totalBytes: Int64, user_data: UnsafeMutableRawPointer?) -> Void {
    callbackQueue.sync {
        downloadProgressCallbackContext?(progress)
    }
}

private func cTokenCallback(token: UnsafePointer<CChar>?, user_data: UnsafeMutableRawPointer?) -> Bool {
    guard let token = token else { return true }
    let tokenString = String(cString: token)
    var shouldContinue = true
    callbackQueue.sync {
        shouldContinue = tokenCallbackContext?(tokenString) ?? true
    }
    return shouldContinue
}

private func cCompletionCallback(text: UnsafePointer<Int8>?) -> Void {
    guard let text = text else { return }
    callbackQueue.sync {
        completionCallbackContext?(String(cString: text))
    }
}

private func cChunkCallback(text: UnsafePointer<Int8>?) -> Void {
    guard let text = text else { return }
    callbackQueue.sync {
        chunkCallbackContext?(String(cString: text))
    }
}

private func cEmbeddingCallback(embedding: UnsafePointer<Float>?, count: Int) -> Void {
    guard let embedding = embedding else { return }
    let embeddingArray = Array(UnsafeBufferPointer(start: embedding, count: count))
    callbackQueue.sync {
        embeddingCallbackContext?(embeddingArray)
    }
}

/// LlamaMobile API wrapper for iOS
/// 
/// This class provides a Swift-friendly interface to the llama_mobile C API, 
/// offering the same feature set but with simplified parameter design and 
/// automatic memory management.
public class LlamaMobile: NSObject {
    
    /// Error types for LlamaMobile operations
    public enum Error: Swift.Error {
        case contextNotInitialized
        case invalidParameter(String)
        case operationFailed(String)
        case vocoderNotInitialized
        case multimodalNotInitialized
        case mediaProcessingFailed
        case tokenizationFailed
        case detokenizationFailed
        case embeddingGenerationFailed
        case audioGenerationFailed
        case conversationFailed
    }
    
    // MARK: - Types
    
    /// Opaque handle to the llama_mobile context
    private var context: llama_mobile_context_handle_t?
    
    /// Number of CPU threads to use (stored from initialization)
    private var initializationNThreads: Int32 = 4
    
    /// Configure Metal paths before model initialization
    private func configureMetalPaths() {
        // llama.cpp metal backend looks for ggml-llama.metallib
        // It first checks the main bundle resources
        if let path = Bundle.main.path(forResource: "ggml-llama", ofType: "metallib") {
            log("Found ggml-llama.metallib in main bundle: \(path)", level: .info)
            setenv("GGML_METAL_PATH_RESOURCES", path, 1)
        } else {
            // Also check the current framework bundle (where LlamaMobile is)
            let frameworkBundle = Bundle(for: type(of: self))
            if let path = frameworkBundle.path(forResource: "ggml-llama", ofType: "metallib") {
                log("Found ggml-llama.metallib in framework bundle: \(path)", level: .info)
                setenv("GGML_METAL_PATH_RESOURCES", path, 1)
            } else {
                log("Warning: ggml-llama.metallib NOT found in main or framework bundle. GPU acceleration might fail.", level: .warning)
            }
        }
    }
    
    /// Text-to-Speech model types
    public enum TTSModelType {
        case unknown
        case outETTSv02
        case outETTSv03
        
        public init(rawValue: Int) {
            switch rawValue {
            case 1:
                self = .outETTSv02
            case 2:
                self = .outETTSv03
            default:
                self = .unknown
            }
        }
        
        public var rawValue: Int {
            switch self {
            case .unknown:
                return -1
            case .outETTSv02:
                return 1
            case .outETTSv03:
                return 2
            }
        }
    }
    
    /// Stop conditions for text generation
    public enum StopType {
        case full
        case partial
        
        public var rawValue: Int {
            switch self {
            case .full:
                return 0
            case .partial:
                return 1
            }
        }
    }
    
    /// Parameters for initializing the llama_mobile context
    ///
    /// This struct configures how the model is loaded and executed, including
    /// performance settings, memory management, and feature enablement.
    public struct InitParams {
        /// Path to the model file (GGUF format)
        public var modelPath: String
        
        /// Custom chat template for conversation management
        public var chatTemplate: String? = nil
        
        /// System prompt to use for conversations
        public var systemPrompt: String? = nil
        
        /// Context window size (maximum number of tokens that can be processed)
        public var nCtx: Int32 = Int32(2048)
        
        /// Batch size for processing tokens (affects performance)
        public var nBatch: Int32 = Int32(512)
        
        /// Micro-batch size for processing tokens (affects performance)
        public var nUBatch: Int32 = Int32(512)
        
        /// Number of layers to offload to GPU (0 = CPU only)
        public var nGpuLayers: Int32 = Int32(0)
        
        /// Number of CPU threads to use for inference
        public var nThreads: Int32 = Int32(ProcessInfo.processInfo.processorCount)
        
        /// Use memory mapping for faster model loading
        public var useMmap: Bool = true
        
        /// Lock model memory to prevent swapping
        public var useMlock: Bool = false
        
        /// Enable embedding generation functionality
        public var embedding: Bool = false
        
        /// Embedding pooling type (0 = mean, 1 = max, 2 = cls)
        public var poolingType: Int32 = Int32(0)
        
        /// Normalize embeddings before returning
        public var embdNormalize: Int32 = Int32(0)
        
        /// Enable flash attention (faster attention computation on supported GPUs)
        public var flashAttention: Bool = false
        
        /// K cache type (e.g., "fp16", "q4_0")
        public var cacheTypeK: String? = nil
        
        /// V cache type (e.g., "fp16", "q4_0")
        public var cacheTypeV: String? = nil
        
        /// Enable chat template functionality
        public var enableChatTemplate: Bool = true
        
        /// Minimum number of image tokens for multimodal models (default: -1, use model default)
        public var imageMinTokens: Int32 = Int32(-1)
        
        /// Callback for model loading progress (0.0 to 1.0)
        public var progressCallback: ((Float) -> Void)? = nil
        
        /// Convenience initializer with minimal parameters
        public init(modelPath: String) {
            self.modelPath = modelPath
        }
        
        /// Convenience initializer for GPU-accelerated inference
        public init(modelPath: String, nGpuLayers: Int32, nCtx: Int32 = 2048) {
            self.modelPath = modelPath
            self.nGpuLayers = nGpuLayers
            self.nCtx = nCtx
            self.enableChatTemplate = true
        }
        
        /// Convenience initializer for embedding generation
        public init(modelPath: String, embedding: Bool, poolingType: Int32 = 0) {
            self.modelPath = modelPath
            self.embedding = embedding
            self.poolingType = poolingType
            self.enableChatTemplate = true
        }
    }
    
    /// Parameters for generating text completions
    ///
    /// This struct controls all aspects of text generation, including sampling
    /// behavior, output constraints, and multimodal inputs.
    public struct CompletionParams {
        /// The input prompt text to generate completions for
        public var prompt: String
        
        /// Maximum number of tokens to generate (0 = no limit)
        public var maxTokens: Int32 = 1024
        
        /// Override the number of CPU threads to use (nil = use initialization value)
        public var nThreads: Int32? = nil
        
        /// Random seed for generation (-1 = random seed)
        public var seed: Int32 = -1
        
        /// Sampling temperature (higher = more creative, lower = more deterministic)
        public var temperature: Double = 0.8
        
        /// Top-k sampling (selects from top k most likely tokens)
        public var topK: Int32 = 40
        
        /// Nucleus sampling threshold (selects smallest set of tokens whose cumulative probability exceeds top_p)
        public var topP: Double = 0.95
        
        /// Minimum probability for a token to be considered (alternative to top-k)
        public var minP: Double = 0.05
        
        /// Typical sampling threshold (controls diversity by filtering tokens with low typicality)
        public var typicalP: Double = 1.0
        
        /// Number of tokens to look back for repetition penalty
        public var penaltyLastN: Int32 = 64
        
        /// Repetition penalty (higher = more diverse output, lower = more repetitive)
        public var penaltyRepeat: Double = 1.1
        
        /// Frequency penalty (penalizes frequent tokens)
        public var penaltyFreq: Double = 0.0
        
        /// Presence penalty (penalizes tokens that have already appeared)
        public var penaltyPresent: Double = 0.0
        
        /// Mirostat sampling mode (0 = disabled, 1 = mirostat, 2 = mirostat 2.0)
        public var mirostat: Int32 = 0
        
        /// Mirostat target entropy (controls output quality)
        public var mirostatTau: Double = 5.0
        
        /// Mirostat learning rate (controls adaptation speed)
        public var mirostatEta: Double = 0.1
        
        /// Ignore end-of-sequence tokens
        public var ignoreEos: Bool = false
        
        /// Custom stop sequences to end generation
        public var stopSequences: [String] = []
        
        /// Grammar string for structured output
        public var grammar: String? = nil
        
        /// Streaming callback for generated tokens
        public var tokenCallback: ((String) -> Bool)? = nil
        
        /// Paths to media files for multimodal generation (images/audio)
        public var mediaPaths: [String] = []
        
        /// Structured chat messages for conversation-based input
        /// If provided, these will be formatted using the chat template instead of using the prompt directly
        public var chatMessages: [ChatMessage] = []
        
        public var useJsonResponse: Bool = true
        
        /// Number of token probabilities to generate
        public var nProbs: Int32 = 0
        
        /// JSON schema for structured output
        public var jsonSchema: String? = nil
        
        /// JSON string defining available tools for function calling
        public var tools: String? = nil
        
        /// Whether to support parallel tool calls
        public var parallelToolCalls: Bool = false
        
        /// Tool choice strategy (auto, required, none, or specific tool)
        public var toolChoice: String? = nil
        
        /// Default initializer with minimal parameters
        public init(prompt: String) {
            self.prompt = prompt
        }
        
        /// Convenience initializer for chat conversations
        public init(chatMessages: [ChatMessage]) {
            self.prompt = ""
            self.chatMessages = chatMessages
            self.maxTokens = 1024
            self.temperature = 0.7
            self.topP = 0.95
            self.topK = 40
            self.penaltyRepeat = 1.2
        }
        
        /// Convenience initializer for creative writing
        public init(creativePrompt: String, maxTokens: Int32 = 1024) {
            self.init(prompt: creativePrompt)
            self.maxTokens = maxTokens
            self.temperature = 1.0
            self.topP = 0.98
            self.topK = 100
        }
        
        /// Convenience initializer for factual/accurate outputs
        public init(factualPrompt: String) {
            self.init(prompt: factualPrompt)
            self.temperature = 0.1
            self.topP = 0.9
            self.topK = 20
        }
        
        /// Convenience initializer for chat-like responses
        public init(chatPrompt: String, maxTokens: Int32 = 1024) {
            self.init(prompt: chatPrompt)
            self.maxTokens = maxTokens
            self.temperature = 0.7
            self.topP = 0.95
            self.topK = 40
            self.penaltyRepeat = 1.2
        }
        
        /// Convenience initializer for multimodal inputs
        public init(multimodalPrompt: String, mediaPaths: [String], maxTokens: Int32 = 1024) {
            self.init(prompt: multimodalPrompt)
            self.maxTokens = maxTokens
            self.mediaPaths = mediaPaths
        }
        
        /// Full initializer with all parameters
        public init(prompt: String, maxTokens: Int32 = 128, nThreads: Int32? = nil, seed: Int32 = -1, temperature: Double = 0.8, topK: Int32 = 40, topP: Double = 0.95, minP: Double = 0.05, typicalP: Double = 1.0, penaltyLastN: Int32 = 64, penaltyRepeat: Double = 1.1, penaltyFreq: Double = 0.0, penaltyPresent: Double = 0.0, mirostat: Int32 = 0, mirostatTau: Double = 5.0, mirostatEta: Double = 0.1, ignoreEos: Bool = false, stopSequences: [String] = [], grammar: String? = nil, mediaPaths: [String] = [], chatMessages: [ChatMessage] = [], useJsonResponse: Bool = true, nProbs: Int32 = 0, jsonSchema: String? = nil, tools: String? = nil, parallelToolCalls: Bool = false, toolChoice: String? = nil, tokenCallback: ((String) -> Bool)? = nil) {
            self.prompt = prompt
            self.maxTokens = maxTokens
            self.nThreads = nThreads
            self.seed = seed
            self.temperature = temperature
            self.topK = topK
            self.topP = topP
            self.minP = minP
            self.typicalP = typicalP
            self.penaltyLastN = penaltyLastN
            self.penaltyRepeat = penaltyRepeat
            self.penaltyFreq = penaltyFreq
            self.penaltyPresent = penaltyPresent
            self.mirostat = mirostat
            self.mirostatTau = mirostatTau
            self.mirostatEta = mirostatEta
            self.ignoreEos = ignoreEos
            self.stopSequences = stopSequences
            self.grammar = grammar
            self.mediaPaths = mediaPaths
            self.chatMessages = chatMessages
            self.useJsonResponse = useJsonResponse
            self.nProbs = nProbs
            self.jsonSchema = jsonSchema
            self.tools = tools
            self.parallelToolCalls = parallelToolCalls
            self.toolChoice = toolChoice
            self.tokenCallback = tokenCallback
        }
        
        /// Initializer that accepts OpenAI format JSON
        /// Example JSON format:
        /// {"messages": [{"role": "system", "content": "You are a helpful assistant"}, {"role": "user", "content": "Hello"}]}
        public init(openAIJSON: String) throws {
            // Parse OpenAI JSON
            guard let jsonData = openAIJSON.data(using: .utf8) else {
                throw Error.invalidParameter("Invalid JSON string")
            }
            
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let root = jsonObject as? [String: Any], let messages = root["messages"] as? [[String: Any]] else {
                throw Error.invalidParameter("Invalid OpenAI JSON format - missing 'messages' field")
            }
            
            // Convert to ChatMessage objects and extract media paths
            var chatMessages: [ChatMessage] = []
            var mediaPaths: [String] = []
            
            for message in messages {
                guard let role = message["role"] as? String else {
                    throw Error.invalidParameter("Invalid message format - missing 'role'")
                }
                
                var textContent = ""
                
                // Check if content is an array (multimodal format)
                if let contentArray = message["content"] as? [[String: Any]] {
                    for contentItem in contentArray {
                        guard let type = contentItem["type"] as? String else {
                            throw Error.invalidParameter("Invalid content item format - missing 'type'")
                        }
                        
                        if type == "text" {
                            if let text = contentItem["text"] as? String {
                                textContent += text + " "
                            }
                        } else if type == "image_url" {
                            if let imageUrlDict = contentItem["image_url"] as? [String: Any],
                               let urlString = imageUrlDict["url"] as? String {
                                // For local files, extract path from URL
                                if let url = URL(string: urlString), url.scheme == "file" {
                                    mediaPaths.append(url.path)
                                } else {
                                    // For remote URLs, we'll need to download the image first
                                    // For now, just add the URL as-is (corelib might handle it)
                                    mediaPaths.append(urlString)
                                }
                            }
                        }
                    }
                } else if let content = message["content"] as? String {
                    // Legacy string format
                    textContent = content
                } else {
                    throw Error.invalidParameter("Invalid message format - 'content' must be string or array")
                }
                
                // Extract additional fields if present
                let reasoningContent = message["reasoning_content"] as? String
                let toolName = message["tool_name"] as? String
                let toolCallId = message["tool_call_id"] as? String
                
                // Add the text content to chat messages
                chatMessages.append(ChatMessage(
                    role: role,
                    content: textContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    reasoningContent: reasoningContent,
                    toolName: toolName,
                    toolCallId: toolCallId
                ))
            }
            
            // Call the existing chatMessages initializer first to ensure proper initialization
            self.init(chatMessages: chatMessages)
            
            // Override with improved parameters for OpenAI compatibility
            self.minP = 0.1
            self.penaltyRepeat = 1.0
            self.penaltyFreq = 0.0
            self.penaltyPresent = 0.0
            self.penaltyLastN = 64
            self.useJsonResponse = true
            self.grammar = nil
            
            // No hardcoded stop sequences - let the caller set them explicitly
            // This allows better control over when generation stops
            

            
            // Set media paths if any were found
            self.mediaPaths = mediaPaths
            
            // No hardcoded template - let the caller or SDK set it
        }
    }
    
    /// Chat message structure for structured conversation input
    ///
    /// Represents a single message in a chat conversation with a role and content.
    public struct ChatMessage {
        /// The role of the message sender (e.g., "system", "user", "assistant")
        public var role: String
        
        /// The content of the message
        public var content: String
        
        /// Reasoning/thinking content for advanced models
        public var reasoningContent: String? = nil
        
        /// Tool call name for function calling
        public var toolName: String? = nil
        
        /// Tool call ID for function calling
        public var toolCallId: String? = nil
        
        /// Initialize a new chat message
        /// - Parameters:
        ///   - role: The role of the message sender
        ///   - content: The content of the message
        ///   - reasoningContent: Reasoning/thinking content (optional)
        ///   - toolName: Tool call name (optional)
        ///   - toolCallId: Tool call ID (optional)
        public init(role: String, content: String, reasoningContent: String? = nil, toolName: String? = nil, toolCallId: String? = nil) {
            self.role = role
            self.content = content
            self.reasoningContent = reasoningContent
            self.toolName = toolName
            self.toolCallId = toolCallId
        }
    }
    
    /// Result of a text completion generation
    ///
    /// Contains the generated text and metadata about the completion process.
    public struct CompletionResult {
        /// Default initializer with all parameters
        public init(text: String, tokensGenerated: Int32, tokensEvaluated: Int32, truncated: Bool, stoppedEos: Bool, stoppedWord: Bool, stoppedLimit: Bool, stoppingWord: String?) {
            self.text = text
            self.tokensGenerated = tokensGenerated
            self.tokensEvaluated = tokensEvaluated
            self.truncated = truncated
            self.stoppedEos = stoppedEos
            self.stoppedWord = stoppedWord
            self.stoppedLimit = stoppedLimit
            self.stoppingWord = stoppingWord
        }
        /// The generated completion text
        public var text: String
        
        /// Number of tokens generated in the completion
        public var tokensGenerated: Int32
        
        /// Number of tokens evaluated from the prompt
        public var tokensEvaluated: Int32
        
        /// Whether the completion was truncated (due to context window limits)
        public var truncated: Bool
        
        /// Whether generation stopped due to end-of-sequence token
        public var stoppedEos: Bool
        
        /// Whether generation stopped due to a stop sequence
        public var stoppedWord: Bool
        
        /// Whether generation stopped due to reaching maxTokens limit
        public var stoppedLimit: Bool
        
        /// The specific stop sequence that triggered generation to stop (if applicable)
        public var stoppingWord: String?
    }
    
    /// LoRA adapter configuration
    ///
    /// Low-Rank Adaptation (LoRA) allows fine-tuning models with minimal parameters.
    public struct LoraAdapter: Equatable {
        /// Path to the LoRA adapter file (.gguf format)
        public var path: String
        
        /// LoRA adapter scale (controls the strength of the adaptation)
        public var scale: Float
        
        /// Initialize a LoRA adapter configuration
        /// - Parameters:
        ///   - path: Path to the LoRA adapter file
        ///   - scale: LoRA adapter scale (default: 1.0)
        public init(path: String, scale: Float = 1.0) {
            self.path = path
            self.scale = scale
        }
    }
    
    /// Result of a conversation generation
    ///
    /// Contains the generated response and performance metrics for the conversation.
    public struct ConversationResult {
        /// Default initializer with all parameters
        public init(text: String, timeToFirstToken: Int64, totalTime: Int64, tokensGenerated: Int32) {
            self.text = text
            self.timeToFirstToken = timeToFirstToken
            self.totalTime = totalTime
            self.tokensGenerated = tokensGenerated
        }
        /// The generated conversation response text
        public var text: String
        
        /// Time taken to generate the first token (in milliseconds)
        public var timeToFirstToken: Int64
        
        /// Total time taken for the entire generation (in milliseconds)
        public var totalTime: Int64
        
        /// Number of tokens generated in the response
        public var tokensGenerated: Int32
    }
    
    /// Parameters for downloading models or files
    ///
    /// Used for downloading models from Hugging Face or other sources.
    public struct DownloadParams {
        /// Default initializer with all parameters
        public init(url: String, localPath: String, username: String? = nil, password: String? = nil, headers: [String: String]? = nil, progressCallback: ((Float) -> Void)? = nil) {
            self.url = url
            self.localPath = localPath
            self.username = username
            self.password = password
            self.headers = headers
            self.progressCallback = progressCallback
        }
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
    }
    
    /// Parameters for downloading Hugging Face files
    ///
    /// Used specifically for downloading files from Hugging Face repositories.
    public struct HuggingFaceDownloadParams {
        /// Default initializer with all parameters
        public init(repoID: String, filename: String, destinationPath: String, bearerToken: String? = nil, offline: Bool = false, progressCallback: ((Float) -> Void)? = nil) {
            self.repoID = repoID
            self.filename = filename
            self.destinationPath = destinationPath
            self.bearerToken = bearerToken
            self.offline = offline
            self.progressCallback = progressCallback
        }
        
        /// Hugging Face repository ID (e.g., "microsoft/Phi-3-mini-4k-instruct-gguf")
        public var repoID: String
        
        /// Filename to download from the repository
        public var filename: String
        
        /// Local directory path where the file will be saved
        public var destinationPath: String
        
        /// Bearer token for authentication (optional)
        public var bearerToken: String? = nil
        
        /// Whether to operate in offline mode
        public var offline: Bool = false
        
        /// Callback for download progress (0.0 to 1.0)
        public var progressCallback: ((Float) -> Void)? = nil
    }
    
    /// Result of a download operation
    ///
    /// Contains the outcome of a model or file download.
    public struct DownloadResult {
        /// Default initializer with all parameters
        public init(success: Bool, localPath: String, errorMessage: String? = nil) {
            self.success = success
            self.localPath = localPath
            self.errorMessage = errorMessage
        }
        /// Whether the download was successful
        public var success: Bool
        
        /// Local path where the file was saved
        public var localPath: String
        
        /// Error message if the download failed (nil if successful)
        public var errorMessage: String? = nil
    }
    
    // MARK: - Initialization and Deinitialization
    
    /// Initialize a new llama_mobile context with simplified parameters
    /// - Parameters:
    ///   - modelPath: Path to the model file
    ///   - nCtx: Context window size
    ///   - nGpuLayers: Number of layers to offload to GPU
    ///   - nThreads: Number of CPU threads to use
    ///   - progressCallback: Optional progress callback for model loading
    public init?(modelPath: String, nCtx: Int32 = 2048, nGpuLayers: Int32 = 0, nThreads: Int32 = 4, progressCallback: ((Float) -> Void)? = nil) {
        var params = InitParams(modelPath: modelPath)
        params.nCtx = nCtx
        params.nGpuLayers = nGpuLayers
        params.nThreads = nThreads
        params.progressCallback = progressCallback
        super.init()
        guard initialize(with: params) else {
            return nil
        }
    }
    
    /// Initialize a new llama_mobile context with detailed parameters
    /// - Parameter params: Initialization parameters
    public init?(with params: InitParams) {
        super.init()
        guard initialize(with: params) else {
            return nil
        }
    }
    
    /// Internal initialization method
    private func initialize(with params: InitParams) -> Bool {
        // Configure Metal paths before initialization
        configureMetalPaths()
        
        // Create progress callback wrapper if needed
        typealias ProgressCallbackType = @convention(c) (Float, UnsafeMutableRawPointer?) -> Void
        var callbackWrapper: ProgressCallbackType? = nil
        
        if params.progressCallback != nil {
            // Store the closure in instance context
            progressCallbackContext = params.progressCallback
            // Use the C-compatible function with self as user_data
            callbackWrapper = { (progress: Float, user_data: UnsafeMutableRawPointer?) -> Void in
                cProgressCallback(progress: progress, user_data: user_data)
            }
        }
        
        // Create and populate the C params struct
        var cParams = llama_mobile_init_params_c_t()
        memset(&cParams, 0, MemoryLayout<llama_mobile_init_params_c_t>.size)
        
        // Use helper function to create persistent copies of the strings
        let modelPathPtr = allocateCString(from: params.modelPath)
        let chatTemplatePtr = params.chatTemplate.map { allocateCString(from: $0) }
        let systemPromptPtr = params.systemPrompt.map { allocateCString(from: $0) }
        let cacheTypeKPtr = params.cacheTypeK.map { allocateCString(from: $0) }
        let cacheTypeVPtr = params.cacheTypeV.map { allocateCString(from: $0) }
        
        // Set string parameters first
        cParams.model_path = UnsafePointer(modelPathPtr)
        cParams.chat_template = chatTemplatePtr.map { UnsafePointer($0) }
        cParams.system_prompt = systemPromptPtr.map { UnsafePointer($0) }
        cParams.cache_type_k = cacheTypeKPtr.map { UnsafePointer($0) }
        cParams.cache_type_v = cacheTypeVPtr.map { UnsafePointer($0) }
        
        // Set non-string parameters
        cParams.n_ctx = params.nCtx
        cParams.n_batch = params.nBatch
        cParams.n_ubatch = params.nUBatch
        cParams.n_gpu_layers = params.nGpuLayers
        cParams.n_threads = params.nThreads
        cParams.use_mmap = params.useMmap
        cParams.use_mlock = params.useMlock
        cParams.embedding = params.embedding
        cParams.pooling_type = params.poolingType
        cParams.embd_normalize = params.embdNormalize
        cParams.flash_attn = params.flashAttention
        cParams.image_min_tokens = params.imageMinTokens
        
        // Set callback with self as user_data
        cParams.progress_callback = callbackWrapper
        cParams.progress_callback_user_data = Unmanaged.passUnretained(self).toOpaque()
        
        // Set enable_chat_template at the end (matches C struct order)
        cParams.enable_chat_template = params.enableChatTemplate
        
        // Store the nThreads value for later use
        self.initializationNThreads = params.nThreads
        
        // Initialize the context
        context = llama_mobile_init_context_c(&cParams)
        
        // Free the duplicated strings
        free(modelPathPtr)
        if let chatTemplatePtr = chatTemplatePtr {
            free(chatTemplatePtr)
        }
        if let systemPromptPtr = systemPromptPtr {
            free(systemPromptPtr)
        }
        if let cacheTypeKPtr = cacheTypeKPtr {
            free(cacheTypeKPtr)
        }
        if let cacheTypeVPtr = cacheTypeVPtr {
            free(cacheTypeVPtr)
        }
        
        return context != nil
    }
    
    /// Clean up resources when the instance is deallocated
    deinit {
        if let context = context {
            llama_mobile_free_context_c(context)
        }
    }
    
    // MARK: - Diagnostics
    
    /// Gets GPU backend information for debugging
    /// - Returns: String containing information about available GPU backends
    public static func getGpuBackendInfo() -> String {
        guard let info = llama_mobile_get_gpu_backend_info_c() else {
            return "Unknown"
        }
        return String(cString: info)
    }
    
    /// Sets verbose logging for debugging GPU issues
    /// - Parameter enabled: true to enable verbose logging, false to disable
    public static func setVerboseLogging(_ enabled: Bool) {
        llama_mobile_set_verbose_logging_c(enabled)
    }
    
    // MARK: - Completion Methods
    
    /// Load grammar content from a file path
    /// - Parameter grammarPath: Path to the grammar file (.gbnf format)
    /// - Returns: Grammar content as a string, or nil if an error occurred
    public func loadGrammar(from grammarPath: String) -> String? {
        do {
            return try String(contentsOfFile: grammarPath, encoding: .utf8)
        } catch {
            log("Error loading grammar file: \(error)", level: .error)
            return nil
        }
    }
    
    /// Generate a text completion from a prompt
    /// - Parameter params: Completion parameters
    /// - Parameter useJsonResponse: Whether to return the response in OpenAI-like JSON format
    /// - Returns: Completion result, or nil if an error occurred
    public func generateCompletion(with params: CompletionParams) -> CompletionResult? {
        guard let context = context else {
            return nil
        }
        
        // Convert stop sequences to C array using helper function
        let (stopSequencesC, stopStringsToFreeOriginal) = allocateCStringArray(from: params.stopSequences)
        var stopStringsToFree = stopStringsToFreeOriginal
        
        // Variables for chat message memory management
        var chatMessagesC: UnsafeMutablePointer<llama_mobile_chat_message_c>? = nil
        var messageStringsToFree: [UnsafeMutablePointer<CChar>] = []
        
        defer {
            // Free all allocated C strings for stop sequences
            for cString in stopStringsToFree {
                cString.deallocate()
            }
            // Free the stop sequences array
            stopSequencesC.deallocate()
            
            // Free chat message memory if allocated
            for cString in messageStringsToFree {
                cString.deallocate()
            }
            if let chatMessagesC = chatMessagesC {
                chatMessagesC.deallocate()
            }
        }
        
        // Create token callback wrapper if needed
        typealias TokenCallbackType = @convention(c) (UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Bool
        var tokenCallbackPtr: TokenCallbackType? = nil
        
        if params.tokenCallback != nil {
            // Store the closure in instance context
            tokenCallbackContext = params.tokenCallback
            // Use the C-compatible function with self as user_data
            tokenCallbackPtr = { (token: UnsafePointer<CChar>?, user_data: UnsafeMutableRawPointer?) -> Bool in
                cTokenCallback(token: token, user_data: user_data)
            }
        }
        
        // Create and populate the C params struct
        // Initialize with zero values to prevent garbage memory issues
        var cParams = llama_mobile_completion_params_c_t()
        memset(&cParams, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
        
        // Set prompt to empty string when chat messages are present, otherwise use the prompt
        let promptToUse = params.chatMessages.isEmpty ? params.prompt : ""
        let promptCString = allocateCString(from: promptToUse)
        cParams.prompt = UnsafePointer(promptCString)
        stopStringsToFree.append(promptCString)
        cParams.n_predict = params.maxTokens
        cParams.n_threads = params.nThreads ?? self.initializationNThreads
        cParams.seed = params.seed
        cParams.temperature = params.temperature
        cParams.top_k = params.topK
        cParams.top_p = params.topP
        cParams.min_p = params.minP
        cParams.typical_p = params.typicalP
        cParams.penalty_last_n = params.penaltyLastN
        cParams.penalty_repeat = params.penaltyRepeat
        cParams.penalty_freq = params.penaltyFreq
        cParams.penalty_present = params.penaltyPresent
        cParams.mirostat = params.mirostat
        cParams.mirostat_tau = params.mirostatTau
        cParams.mirostat_eta = params.mirostatEta
        cParams.ignore_eos = params.ignoreEos
        cParams.stop_sequences = params.stopSequences.count > 0 ? stopSequencesC : nil
        cParams.stop_sequence_count = Int32(params.stopSequences.count)
        
        // Log grammar usage and handle grammar string
        var grammarCString: UnsafeMutablePointer<CChar>? = nil
        if let grammar = params.grammar {
            log("Using grammar for generation", level: .debug)
            log("Grammar preview: \(grammar.prefix(100))...", level: .debug)
            // Allocate permanent C string for grammar using helper function
            grammarCString = allocateCString(from: grammar)
            cParams.grammar = UnsafePointer(grammarCString)
        } else {
            log("No grammar specified for generation", level: .debug)
            cParams.grammar = nil
        }
        // Add grammar to cleanup list if allocated
        if let grammarCString = grammarCString {
            stopStringsToFree.append(grammarCString)
        }
        
        // Set callback
        cParams.token_callback = tokenCallbackPtr
        cParams.token_callback_user_data = nil
        
        // Handle chat messages if provided
        if !params.chatMessages.isEmpty {
            log("Using structured chat messages", level: .debug)
            
            // Convert chat messages to C array
            let messageCount = params.chatMessages.count
            chatMessagesC = UnsafeMutablePointer<llama_mobile_chat_message_c>.allocate(capacity: messageCount)
            memset(chatMessagesC, 0, MemoryLayout<llama_mobile_chat_message_c>.size * messageCount)
            
            // Array to store C strings that need to be freed
            
            for (index, message) in params.chatMessages.enumerated() {
                // Allocate permanent C strings for role and content using helper function
                let roleCString = allocateCString(from: message.role)
                let contentCString = allocateCString(from: message.content)
                let reasoningContentCString = message.reasoningContent.map { allocateCString(from: $0) }
                let toolNameCString = message.toolName.map { allocateCString(from: $0) }
                let toolCallIdCString = message.toolCallId.map { allocateCString(from: $0) }
                
                messageStringsToFree.append(roleCString)
                messageStringsToFree.append(contentCString)
                if let reasoningContentCString = reasoningContentCString {
                    messageStringsToFree.append(reasoningContentCString)
                }
                if let toolNameCString = toolNameCString {
                    messageStringsToFree.append(toolNameCString)
                }
                if let toolCallIdCString = toolCallIdCString {
                    messageStringsToFree.append(toolCallIdCString)
                }
                
                if let chatMessagesC = chatMessagesC {
                    chatMessagesC[index].role = UnsafePointer(roleCString)
                    chatMessagesC[index].content = UnsafePointer(contentCString)
                    chatMessagesC[index].reasoning_content = reasoningContentCString.map { UnsafePointer($0) }
                    chatMessagesC[index].tool_name = toolNameCString.map { UnsafePointer($0) }
                    chatMessagesC[index].tool_call_id = toolCallIdCString.map { UnsafePointer($0) }
                }
            }
            
            if let chatMessagesC = chatMessagesC {
                cParams.chat_messages = UnsafePointer(chatMessagesC)
            }
            cParams.chat_message_count = Int32(messageCount)
            
        } else {
            cParams.chat_messages = nil
            cParams.chat_message_count = 0
        }
        
        // Chat template is set during initialization, not during completion
        // The completion params struct doesn't support dynamic chat template setting
        
        // Set JSON response flag - ensure false when grammar is set
        cParams.use_json_response = params.grammar != nil ? false : params.useJsonResponse
        
        // Set additional parameters
        cParams.n_probs = params.nProbs
        
        // Set tool-related parameters if available
        let jsonSchemaCString = params.jsonSchema.map { allocateCString(from: $0) }
        let toolsCString = params.tools.map { allocateCString(from: $0) }
        let toolChoiceCString = params.toolChoice.map { allocateCString(from: $0) }
        
        // Add to cleanup list if allocated
        if let jsonSchemaCString = jsonSchemaCString {
            stopStringsToFree.append(jsonSchemaCString)
        }
        if let toolsCString = toolsCString {
            stopStringsToFree.append(toolsCString)
        }
        if let toolChoiceCString = toolChoiceCString {
            stopStringsToFree.append(toolChoiceCString)
        }
        
        // Set the parameters in the C struct
        cParams.json_schema = jsonSchemaCString.map { UnsafePointer($0) }
        cParams.tools = toolsCString.map { UnsafePointer($0) }
        cParams.tool_choice = toolChoiceCString.map { UnsafePointer($0) }
        cParams.parallel_tool_calls = params.parallelToolCalls
        
        // Generate completion - use multimodal if media paths are provided
        var cResult = llama_mobile_completion_result_c_t()
        let status: Int32
        
        if !params.mediaPaths.isEmpty {
            // Convert media paths to C array using helper function
            let (mediaPathsC, mediaStringsToFree) = allocateCStringArray(from: params.mediaPaths)
            defer {
                // Free all allocated C strings for media paths
                for cString in mediaStringsToFree {
                    cString.deallocate()
                }
                // Free the media paths array
                mediaPathsC.deallocate()
            }
            
            status = llama_mobile_multimodal_completion_c(context, &cParams, mediaPathsC, Int32(params.mediaPaths.count), &cResult)
        } else {
            status = llama_mobile_completion_c(context, &cParams, &cResult)
        }
        
        // Log the result status
        log("Completion C API status: \(status)", level: .debug)
        
        guard status == 0 else {
            log("Completion C API failed with status: \(status)", level: .error)
            llama_mobile_free_completion_result_members_c(&cResult)
            return nil
        }
        
        guard let text = cResult.text.map({ String(cString: $0) }) else {
            log("Completion result has no text", level: .error)
            llama_mobile_free_completion_result_members_c(&cResult)
            return nil
        }
        
        // Log token statistics
        log("Tokens evaluated: \(cResult.tokens_evaluated)", level: .debug)
        log("Tokens generated: \(cResult.tokens_predicted)", level: .debug)
        log("Generation stopped because: \n  - End of sequence: \(cResult.stopped_eos)\n  - Stop word: \(cResult.stopped_word)\n  - Token limit: \(cResult.stopped_limit)", level: .debug)
        
        // Get stopping word if available
        let stoppingWord = cResult.stopping_word != nil ? String(cString: cResult.stopping_word!) : nil
        
        // Create Swift result
        let result = CompletionResult(
            text: text,
            tokensGenerated: cResult.tokens_predicted,
            tokensEvaluated: cResult.tokens_evaluated,
            truncated: cResult.truncated,
            stoppedEos: cResult.stopped_eos,
            stoppedWord: cResult.stopped_word,
            stoppedLimit: cResult.stopped_limit,
            stoppingWord: stoppingWord
        )
        
        // Log the result for debugging
        log("Completion result: \(text)", level: .debug)
        
        // Validate if generated text is different from prompt
        if text == params.prompt {
            log("Generated text is identical to input prompt. This could indicate:", level: .warning)
            log("- Model may not be generating any tokens", level: .warning)
            log("- Generation parameters may be causing early stopping", level: .warning)
            log("- Model file may be corrupt or incompatible", level: .warning)
            log("- Prompt may need to be formatted differently for the model", level: .warning)
            log("Tokens generated: \(cResult.tokens_predicted) (should be > 0 for new content)", level: .debug)
        }
        
        // Free C result members
        llama_mobile_free_completion_result_members_c(&cResult)
        
        return result
    }
    
    /// OpenAI-compatible completion API
    /// Accepts OpenAI format JSON and generates a completion
    /// - Parameter openAIJSON: OpenAI format JSON string
    /// - Returns: The generated completion result in OpenAI format, or nil if an error occurred.
    public func generateOpenAICompletion(with openAIJSON: String) -> CompletionResult? {
        guard let context = context else {
            return nil
        }
        
        do {
            // Create completion params from OpenAI JSON
            var params = try CompletionParams(openAIJSON: openAIJSON)
            

            // we need to set grammar to nil if it is not nil
            params.grammar = nil
            params.useJsonResponse = true
            // Generate completion using the standard method
            return generateCompletion(with: params)
        } catch {
            log("Error in generateOpenAICompletion: \(error)", level: .error)
            return nil
        }
    }
    
    /// Generate a text completion with simplified parameters
    /// - Parameters:
    ///   - prompt: Input prompt text
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - temperature: Sampling temperature
    ///   - tokenCallback: Optional streaming callback for generated tokens
    ///   - useJsonResponse: Whether to return the response in OpenAI-like JSON format
    /// - Returns: Completion result, or nil if an error occurred
    public func generateCompletion(prompt: String, maxTokens: Int32 = 1024, temperature: Double = 0.8, tokenCallback: ((String) -> Bool)? = nil, useJsonResponse: Bool = true) -> CompletionResult? {
        var params = CompletionParams(prompt: prompt)
        params.maxTokens = maxTokens
        params.temperature = temperature
        params.tokenCallback = tokenCallback
        params.useJsonResponse = useJsonResponse
        
        return generateCompletion(with: params)
    }
    
    /// Generate a completion with multimodal input (images/audio)
    /// - Parameters:
    ///   - params: Completion parameters
    ///   - mediaPaths: Array of paths to media files (images/audio)
    /// - Returns: Completion result, or nil if an error occurred 
    public func generateMultimodalCompletion(with params: CompletionParams, mediaPaths: [String]) -> CompletionResult? {
        var paramsWithMedia = params
        paramsWithMedia.mediaPaths = mediaPaths
        return generateCompletion(with: paramsWithMedia)
    }
    
    /// Stop an ongoing completion generation
    public func stopCompletion() {
        if let context = context {
            llama_mobile_stop_completion_c(context)
        }
    }
    
    // MARK: - Download Methods
    
    /// Download a Hugging Face model file to a specified local path
    /// - Parameter params: Download parameters
    /// - Returns: Download result containing success status and local path
    public class func download(with params: DownloadParams) -> DownloadResult {
        var result: DownloadResult?
        let semaphore = DispatchSemaphore(value: 0)
        
        log("Starting download from: \(params.url)", level: .info)
        
        // Create destination directory if it doesn't exist
        let destinationURL = URL(fileURLWithPath: params.localPath)
        let destinationDir = destinationURL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            log("Created destination directory: \(destinationDir.path)", level: .debug)
        } catch {
            let errorMsg = "Failed to create destination directory: \(error.localizedDescription)"
            log(errorMsg, level: .error)
            return DownloadResult(
                success: false,
                localPath: params.localPath,
                errorMessage: errorMsg
            )
        }
        
        // Parse URL to determine if it's a Hugging Face repo ID or direct URL
        var downloadURL: URL?
        var filename: String?
        
        if params.url.contains("://") {
            // Direct URL
            downloadURL = URL(string: params.url)
            filename = destinationURL.lastPathComponent
            log("Using direct URL: \(params.url)", level: .debug)
        } else {
            // Hugging Face repo ID format: owner/repo
            let components = params.url.split(separator: "/")
            guard components.count >= 2 else {
                let errorMsg = "Invalid Hugging Face repo ID format. Expected: owner/repo/filename"
                log(errorMsg, level: .error)
                return DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
            }
            
            let owner = String(components[0])
            let repo = String(components[1])
            let file = components.count > 2 ? Array(components[2...]).joined(separator: "/") : destinationURL.lastPathComponent
            
            filename = file
            downloadURL = URL(string: "https://huggingface.co/\(owner)/\(repo)/resolve/main/\(file)")
            log("Using Hugging Face URL: \(downloadURL?.absoluteString ?? "invalid")", level: .debug)
        }
        
        guard let url = downloadURL else {
            let errorMsg = "Invalid URL"
            log(errorMsg, level: .error)
            return DownloadResult(
                success: false,
                localPath: params.localPath,
                errorMessage: errorMsg
            )
        }
        
        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        log("Created request for: \(url.absoluteString)", level: .debug)
        
        // Add authentication if provided
        if let username = params.username, let password = params.password {
            let credentials = "\(username):\(password)"
            if let credentialsData = credentials.data(using: .utf8) {
                let base64Credentials = credentialsData.base64EncodedString()
                request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
                log("Added Basic authentication", level: .debug)
            }
        } else if let bearerToken = params.password {
            // Use password field as bearer token for Hugging Face
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            log("Added Bearer token authentication", level: .debug)
        }
        
        // Add custom headers if provided
        if let headers = params.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
                log("Added header: \(key)", level: .debug)
            }
        }
        
        // Create download task with progress tracking
        var lastProgress: Float = 0.0
        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                let nsError = error as NSError
                let errorMsg: String
                
                if nsError.domain == NSURLErrorDomain && nsError.code == -1005 {
                    errorMsg = "Network connection lost. Please check your internet connection and try again."
                } else if nsError.domain == NSURLErrorDomain && nsError.code == -1001 {
                    errorMsg = "Connection timed out. Please check your internet connection and try again."
                } else if nsError.domain == NSURLErrorDomain && nsError.code == -1009 {
                    errorMsg = "No internet connection. Please check your network settings."
                } else {
                    errorMsg = "Download failed: \(error.localizedDescription)"
                }
                
                log(errorMsg, level: .error)
                log("Error details: \(error)", level: .debug)
                result = DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "Invalid response"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
                return
            }
            
            log("HTTP status code: \(httpResponse.statusCode)", level: .debug)
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "HTTP error: \(httpResponse.statusCode)"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
                return
            }
            
            guard let tempURL = tempURL else {
                let errorMsg = "No file received"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
                return
            }
            
            // Move temp file to destination
            do {
                if FileManager.default.fileExists(atPath: params.localPath) {
                    try FileManager.default.removeItem(atPath: params.localPath)
                    log("Removed existing file: \(params.localPath)", level: .debug)
                }
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                log("Successfully saved file to: \(params.localPath)", level: .info)
                result = DownloadResult(
                    success: true,
                    localPath: params.localPath
                )
            } catch {
                let errorMsg = "Failed to save file: \(error.localizedDescription)"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.localPath,
                    errorMessage: errorMsg
                )
            }
        }
        
        // Add progress observation with better tracking
        if let progressCallback = params.progressCallback {
            // Use a closure-based approach for progress tracking
            progressObserver = task.progress.observe(\.fractionCompleted) {progress, _ in
                let fraction = Float(progress.fractionCompleted)
                if fraction > lastProgress {
                    lastProgress = fraction
                    log("Download progress: \(Int(fraction * 100))%", level: .debug)
                    DispatchQueue.main.async {
                        progressCallback(fraction)
                    }
                }
            }
            log("Progress callback registered", level: .debug)
        }
        
        log("Starting download task", level: .info)
        task.resume()
        semaphore.wait()
        
        return result ?? DownloadResult(
            success: false,
            localPath: params.localPath,
            errorMessage: "Unknown error"
        )
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "fractionCompleted", let progress = object as? Progress {
            let fraction = Float(progress.fractionCompleted)
            log("Download progress: \(Int(fraction * 100))%", level: .debug)
            DispatchQueue.main.async {
                downloadProgressCallbackContext?(fraction)
                hfDownloadProgressCallbackContext?(fraction)
            }
        }
    }
    
    /// Download a file from Hugging Face repository
    /// - Parameter params: Hugging Face download parameters
    /// - Returns: Download result containing success status and local path
    public class func downloadHuggingFaceFile(with params: HuggingFaceDownloadParams) -> DownloadResult {
        var result: DownloadResult?
        let semaphore = DispatchSemaphore(value: 0)
        
        log("Starting Hugging Face download: \(params.repoID)/\(params.filename)", level: .info)
        
        // Create destination directory if it doesn't exist
        let destinationDir = URL(fileURLWithPath: params.destinationPath)
        
        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            log("Created destination directory: \(destinationDir.path)", level: .debug)
        } catch {
            let errorMsg = "Failed to create destination directory: \(error.localizedDescription)"
            log(errorMsg, level: .error)
            return DownloadResult(
                success: false,
                localPath: params.destinationPath + "/" + params.filename,
                errorMessage: errorMsg
            )
        }
        
        // Build Hugging Face URL
        let urlString = "https://huggingface.co/\(params.repoID)/resolve/main/\(params.filename)"
        guard let url = URL(string: urlString) else {
            let errorMsg = "Invalid URL"
            log(errorMsg, level: .error)
            return DownloadResult(
                success: false,
                localPath: params.destinationPath + "/" + params.filename,
                errorMessage: errorMsg
            )
        }
        
        log("Using Hugging Face URL: \(url.absoluteString)", level: .debug)
        
        // Create URL request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        log("Created request for: \(url.absoluteString)", level: .debug)
        
        // Add bearer token if provided
        if let bearerToken = params.bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
            log("Added Bearer token authentication", level: .debug)
        }
        
        // Create download task with progress tracking
        var lastProgress: Float = 0.0
        let task = URLSession.shared.downloadTask(with: request) { tempURL, response, error in
            defer {
                semaphore.signal()
            }
            
            if let error = error {
                let errorMsg = "Download failed: \(error.localizedDescription)"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.destinationPath + "/" + params.filename,
                    errorMessage: errorMsg
                )
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let errorMsg = "Invalid response"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.destinationPath + "/" + params.filename,
                    errorMessage: errorMsg
                )
                return
            }
            
            log("HTTP status code: \(httpResponse.statusCode)", level: .debug)
            
            guard httpResponse.statusCode == 200 else {
                let errorMsg = "HTTP error: \(httpResponse.statusCode)"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.destinationPath + "/" + params.filename,
                    errorMessage: errorMsg
                )
                return
            }
            
            guard let tempURL = tempURL else {
                let errorMsg = "No file received"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.destinationPath + "/" + params.filename,
                    errorMessage: errorMsg
                )
                return
            }
            
            // Move temp file to destination
            let destinationURL = destinationDir.appendingPathComponent(params.filename)
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(atPath: destinationURL.path)
                    log("Removed existing file: \(destinationURL.path)", level: .debug)
                }
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                log("Successfully saved file to: \(destinationURL.path)", level: .info)
                result = DownloadResult(
                    success: true,
                    localPath: destinationURL.path
                )
            } catch {
                let errorMsg = "Failed to save file: \(error.localizedDescription)"
                log(errorMsg, level: .error)
                result = DownloadResult(
                    success: false,
                    localPath: params.destinationPath + "/" + params.filename,
                    errorMessage: errorMsg
                )
            }
        }
        
        // Add progress observation with better tracking
        if let progressCallback = params.progressCallback {
            // Use a closure-based approach for progress tracking
            hfProgressObserver = task.progress.observe(\.fractionCompleted) {progress, _ in
                let fraction = Float(progress.fractionCompleted)
                if fraction > lastProgress {
                    lastProgress = fraction
                    log("Download progress: \(Int(fraction * 100))%", level: .debug)
                    DispatchQueue.main.async {
                        progressCallback(fraction)
                    }
                }
            }
            log("Progress callback registered", level: .debug)
        }
        
        log("Starting download task", level: .info)
        task.resume()
        semaphore.wait()
        
        return result ?? DownloadResult(
            success: false,
            localPath: params.destinationPath + "/" + params.filename,
            errorMessage: "Unknown error"
        )
    }
    
    // MARK: - Tokenization Methods
    
    /// Tokenize a text string into token IDs
    /// - Parameter text: Text string to tokenize
    /// - Returns: Array of token IDs, or nil if an error occurred
    public func tokenize(text: String) -> [Int32]? {
        guard let context = context else {
            return nil
        }
        
        return text.withCString { textC in
            let cResult = llama_mobile_tokenize_c(context, textC)
            defer { llama_mobile_free_token_array_c(cResult) }
            
            guard let tokens = cResult.tokens, cResult.count > 0 else {
                return nil
            }
            
            return Array(UnsafeBufferPointer(start: tokens, count: Int(cResult.count)))
        }
    }
    
    /// Detokenize an array of token IDs back to a text string
    /// - Parameter tokens: Array of token IDs to detokenize
    /// - Returns: Detokenized text string, or nil if an error occurred
    public func detokenize(tokens: [Int32]) -> String? {
        guard let context = context else {
            return nil
        }
        
        let cString = tokens.withUnsafeBufferPointer { buffer in
            llama_mobile_detokenize_c(context, buffer.baseAddress, Int32(buffer.count))
        }
        
        guard let cString = cString else {
            return nil
        }
        
        defer { llama_mobile_free_string_c(cString) }
        return String(cString: cString)
    }
    
    // MARK: - Embedding Methods
    
    /// Generate embeddings for a text string
    /// - Parameter text: Text string to generate embeddings for
    /// - Returns: Array of floating-point embeddings, or nil if an error occurred
    public func generateEmbeddings(for text: String) -> [Float]? {
        guard let context = context else {
            return nil
        }
        
        return text.withCString { textC in
            let cResult = llama_mobile_embedding_c(context, textC)
            defer { llama_mobile_free_float_array_c(cResult) }
            
            guard let values = cResult.values else {
                return nil
            }
            
            return Array(UnsafeBufferPointer(start: values, count: Int(cResult.count)))
        }
    }
    
    // MARK: - Multimodal Methods
    
    /// Initialize multimodal support (vision/audio)
    /// - Parameters:
    ///   - mmprojPath: Path to the multimodal projection file
    ///   - useGpu: Whether to use GPU acceleration for multimodal processing
    /// - Returns: true on success, false on failure
    public func initMultimodal(mmprojPath: String, useGpu: Bool = true) -> Bool {
        guard let context = context else {
            return false
        }
        
        return mmprojPath.withCString { pathC in
            llama_mobile_init_multimodal_c(context, pathC, useGpu) == 0
        }
    }
    
    /// Check if multimodal support is enabled
    /// - Returns: true if enabled, false otherwise
    public func isMultimodalEnabled() -> Bool {
        guard let context = context else {
            return false
        }
        
        return llama_mobile_is_multimodal_enabled_c(context)
    }
    
    /// Check if the model supports vision input
    /// - Returns: true if vision is supported, false otherwise
    public func supportsVision() -> Bool {
        guard let context = context else {
            return false
        }
        
        return llama_mobile_supports_vision_c(context)
    }
    
    /// Check if the model supports audio input
    /// - Returns: true if audio is supported, false otherwise
    public func supportsAudio() -> Bool {
        guard let context = context else {
            return false
        }
        
        return llama_mobile_supports_audio_c(context)
    }
    
    /// Release multimodal resources
    public func releaseMultimodal() {
        if let context = context {
            llama_mobile_release_multimodal_c(context)
        }
    }
    
    // MARK: - TTS Methods
    
    /// Initialize the vocoder for text-to-speech functionality
    /// - Parameter vocoderModelPath: Path to the vocoder model file
    /// - Returns: true on success, false on failure
    public func initVocoder(vocoderModelPath: String) -> Bool {
        guard let context = context else {
            return false
        }
        
        return vocoderModelPath.withCString { pathC in
            llama_mobile_init_vocoder_c(context, pathC) == 0
        }
    }
    
    /// Check if vocoder (TTS) support is enabled
    /// - Returns: true if enabled, false otherwise
    public func isVocoderEnabled() -> Bool {
        guard let context = context else {
            return false
        }
        
        return llama_mobile_is_vocoder_enabled_c(context)
    }
    
    /// Get the type of TTS model currently loaded
    /// - Returns: TTS model type
    public func getTTSType() -> TTSModelType {
        guard let context = context else {
            return .unknown
        }
        
        let rawType = llama_mobile_get_tts_type_c(context)
        return TTSModelType(rawValue: Int(rawType))
    }
    
    /// Format text for audio completion with speaker information
    /// - Parameters:
    ///   - speakerJson: JSON string with speaker configuration
    ///   - textToSpeak: Text to convert to speech
    /// - Returns: Formatted audio completion string, or nil if an error occurred
    private func getFormattedAudioCompletion(speakerJson: String, textToSpeak: String) -> String? {
        guard let context = context else {
            return nil
        }
        
        return speakerJson.withCString { speakerJsonC in
            textToSpeak.withCString { textToSpeakC in
                let cString = llama_mobile_get_formatted_audio_completion_c(
                    context,
                    speakerJsonC,
                    textToSpeakC
                )
                
                guard let cString = cString else {
                    return nil
                }
                
                defer { llama_mobile_free_string_c(cString) }
                return String(cString: cString)
            }
        }
    }
    
    /// Get guide tokens for audio completion
    /// - Parameter textToSpeak: Text to convert to speech
    /// - Returns: Array of guide tokens for audio generation, or nil if an error occurred
    private func getAudioGuideTokens(textToSpeak: String) -> [Int32]? {
        guard let context = context else {
            return nil
        }
        
        return textToSpeak.withCString { textC in
            let cResult = llama_mobile_get_audio_guide_tokens_c(context, textC)
            defer { llama_mobile_free_token_array_c(cResult) }
            
            guard let tokens = cResult.tokens else {
                return nil
            }
            
            return Array(UnsafeBufferPointer(start: tokens, count: Int(cResult.count)))
        }
    }
    
    /// Set guide tokens for audio generation
    /// - Parameter tokens: Array of guide tokens to use
    private func setGuideTokens(tokens: [Int32]) {
        guard let context = context else {
            return
        }
        
        tokens.withUnsafeBufferPointer { buffer in
            if let baseAddress = buffer.baseAddress {
                llama_mobile_set_guide_tokens_c(context, baseAddress, Int32(buffer.count))
            }
        }
    }
    
    /// Decode audio tokens into raw audio data
    /// - Parameter tokens: Audio tokens to decode
    /// - Returns: Array of floating-point audio samples, or nil if an error occurred
    private func decodeAudioTokens(tokens: [Int32]) -> [Float]? {
        guard let context = context else {
            return nil
        }
        
        let cResult = tokens.withUnsafeBufferPointer { buffer in
            llama_mobile_decode_audio_tokens_c(context, buffer.baseAddress, Int32(buffer.count))
        }
        
        defer { llama_mobile_free_float_array_c(cResult) }
        
        guard let values = cResult.values else {
            return nil
        }
        
        return Array(UnsafeBufferPointer(start: values, count: Int(cResult.count)))
    }
    
    /// Save audio data to a WAV file
    /// - Parameters:
    ///   - filePath: Path to the output WAV file
    ///   - audioData: Array of floating-point audio samples
    ///   - sampleRate: Audio sampling rate (default is 24000 Hz)
    /// - Returns: true on success, false on failure
    public func saveAudioToWav(filePath: String, audioData: [Float], sampleRate: Int32 = 24000) -> Bool {
        guard let context = context else {
            return false
        }
        
        return audioData.withUnsafeBufferPointer { buffer in
            filePath.withCString { filePathC in
                llama_mobile_save_audio_to_wav_c(context, filePathC, buffer.baseAddress, Int32(buffer.count), sampleRate)
            }
        }
    }
    
    /// Release vocoder (TTS) resources
    public func releaseVocoder() {
        if let context = context {
            llama_mobile_release_vocoder_c(context)
        }
    }
    
    /// Release the native context and free all resources
    /// After calling this method, the LlamaMobile instance cannot be used anymore
    public func releaseContext() {
        if let context = context {
            llama_mobile_free_context_c(context)
            self.context = nil
        }
    }
    
    /// Generate audio samples from text using TTS
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - speakerJson: JSON string with speaker configuration (optional, defaults to default speaker)
    /// - Returns: Array of floating-point audio samples, or nil if an error occurred
    /// - Note: This method handles the entire TTS workflow in a single call: formatting, token generation, and audio decoding
    private func generateAudioFromText(text: String, speakerJson: String = "{\"speaker\": \"default\"}") -> [Float]? {
        guard let context = context, isVocoderEnabled() else {
            return nil
        }
        
        // Get formatted audio completion
        guard let formattedPrompt = getFormattedAudioCompletion(speakerJson: speakerJson, textToSpeak: text) else {
            return nil
        }
        
        // Get audio guide tokens (this likely sets guide tokens internally)
        guard let guideTokens = getAudioGuideTokens(textToSpeak: formattedPrompt) else {
            return nil
        }
        
        // Set guide tokens for audio generation
        setGuideTokens(tokens: guideTokens)
        
        // Generate audio content using text completion (same as custom workflow)
        var completionParams = CompletionParams(prompt: formattedPrompt)
        completionParams.maxTokens = 200
        completionParams.temperature = 0.0
        completionParams.ignoreEos = false // Don't ignore EOS, let model stop naturally
        
        guard let completionResult = generateCompletion(with: completionParams) else {
            return nil
        }
        
        // Tokenize only the completion (not the prompt + completion)
        // The prompt is already represented by the guide tokens
        guard let audioTokens = tokenize(text: completionResult.text) else {
            return nil
        }
        
        // Filter audio tokens - match Android implementation
        var filteredTokens = [Int32]()
        let audioEndToken: Int32 = 151668 // <|audio_end|>
        let minAudioToken: Int32 = 151672
        let maxAudioToken: Int32 = 155772
        
        // Debug logging
        print("[TTS] Built-in - Original tokens count: \(audioTokens.count)")
        if !audioTokens.isEmpty {
            print("[TTS] Built-in - First 20 tokens: \(audioTokens.prefix(20))")
            print("[TTS] Built-in - Last 10 tokens: \(audioTokens.suffix(10))")
        }
        
        var nonAudioTokens = 0
        for token in audioTokens {
            // Check if token is in audio range
            if token >= minAudioToken && token <= maxAudioToken {
                filteredTokens.append(token)
            } else {
                nonAudioTokens += 1
            }
            
            // Check for end token
            if token == audioEndToken {
                print("[TTS] Built-in - Found audio end token")
                break
            }
        }
        
        // Debug logging
        print("[TTS] Built-in - Filtered tokens count: \(filteredTokens.count)")
        print("[TTS] Built-in - Non-audio tokens skipped: \(nonAudioTokens)")
        if !filteredTokens.isEmpty {
            print("[TTS] Built-in - First 10 filtered tokens: \(filteredTokens.prefix(10))")
        }
        
        // Decode audio tokens to samples
        return decodeAudioTokens(tokens: filteredTokens)
    }
    
    // MARK: - TTS Related Types
    
    /// TTS configuration options
    public struct TTSOptions {
        public var sampleRate: Int = 24000
        public var voice: String? = nil
        public var speed: Float = 1.0
        public var saveToFile: Bool = false
        public var outputFilePath: String? = nil
        
        public init() {
        }
        
        public init(
            sampleRate: Int = 24000,
            voice: String? = nil,
            speed: Float = 1.0,
            saveToFile: Bool = false,
            outputFilePath: String? = nil
        ) {
            self.sampleRate = sampleRate
            self.voice = voice
            self.speed = speed
            self.saveToFile = saveToFile
            self.outputFilePath = outputFilePath
        }
    }
    
    /// Result of successful speech generation
    public struct SpeechResult {
        public var audioSamples: [Int16]
        public var sampleRate: Int
        public var duration: TimeInterval
        public var outputFilePath: String?
        public var methodUsed: TTSMethod
        
        public init(
            audioSamples: [Int16],
            sampleRate: Int,
            duration: TimeInterval,
            outputFilePath: String?,
            methodUsed: TTSMethod
        ) {
            self.audioSamples = audioSamples
            self.sampleRate = sampleRate
            self.duration = duration
            self.outputFilePath = outputFilePath
            self.methodUsed = methodUsed
        }
    }
    
    /// Metadata for streaming speech generation
    public struct SpeechMetadata {
        public var sampleRate: Int
        public var duration: TimeInterval
        public var methodUsed: TTSMethod
        public var outputFilePath: String?
        
        public init(
            sampleRate: Int,
            duration: TimeInterval,
            methodUsed: TTSMethod,
            outputFilePath: String?
        ) {
            self.sampleRate = sampleRate
            self.duration = duration
            self.methodUsed = methodUsed
            self.outputFilePath = outputFilePath
        }
    }
    
    /// Error types for TTS operations
    public enum TTSError: Swift.Error {
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
    
    /// Method used for TTS generation
    public enum TTSMethod {
        case builtIn
        case customWorkflow
    }
    
    // MARK: - Simplified TTS Methods
    
    /// Generates speech from text using the best available method
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - options: TTS configuration options
    ///   - progressHandler: Optional callback for progress updates
    /// - Returns: Result containing the generated audio samples and metadata
    public func generateSpeechAsync(
        text: String,
        options: TTSOptions = TTSOptions(),
        progressHandler: ((Float) -> Void)? = nil
    ) async -> Result<SpeechResult, TTSError> {
        // Check if model is loaded
        guard let context = self.context else {
            return .failure(.noModelLoaded)
        }
        
        // Check if vocoder is enabled
        guard self.isVocoderEnabled() else {
            return .failure(.noVocoderEnabled)
        }
        
        progressHandler?(0.1) // Initial progress
        
        // Check TTS model type
        let ttsType = self.getTTSType()
        let isKnownTTSModel = ttsType != .unknown
        
        progressHandler?(0.2) // Model check completed
        
        var audioSamples: [Float]?
        var methodUsed: TTSMethod = .builtIn
        
        if isKnownTTSModel {
            // Try Path 1: Built-in TTS method
            progressHandler?(0.3) // Starting built-in method
            audioSamples = await Task.detached { 
                self.generateAudioFromText(text: text)
            }.value
            methodUsed = .builtIn
            
            progressHandler?(0.6) // Built-in method completed
        }
        
        if audioSamples == nil {
            // Try Path 2: Custom TTS workflow
            progressHandler?(0.4) // Starting custom workflow
            audioSamples = await self.performCustomTTSWorkflow(text: text, progressHandler: progressHandler)
            methodUsed = .customWorkflow
        }
        
        guard let floatSamples = audioSamples else {
            return .failure(.generationFailed)
        }
        
        progressHandler?(0.8) // Audio generation completed
        
        // Calculate duration
        let duration = TimeInterval(floatSamples.count) / TimeInterval(options.sampleRate)
        
        // Save to file if requested
        var outputFilePath: String? = nil
        if options.saveToFile {
            let filePath = options.outputFilePath ?? NSTemporaryDirectory().appending("tts_output_\(UUID().uuidString).wav")
            let saveSuccess = self.saveAudioToWav(
                filePath: filePath,
                audioData: floatSamples,
                sampleRate: Int32(options.sampleRate)
            )
            if saveSuccess {
                outputFilePath = filePath
            } else {
                return .failure(.fileSaveFailed)
            }
        }
        
        progressHandler?(1.0) // Process completed
        
        // Convert Float samples to Int16 for return
        let int16Samples = floatSamples.map { Int16(clamping: Int($0 * Float(Int16.max))) }
        
        let result = SpeechResult(
            audioSamples: int16Samples,
            sampleRate: options.sampleRate,
            duration: duration,
            outputFilePath: outputFilePath,
            methodUsed: methodUsed
        )
        
        return .success(result)
    }
    
    /// Generates speech from text synchronously
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - options: TTS configuration options
    /// - Returns: Result containing the generated audio samples and metadata
    public func generateSpeech(
        text: String,
        options: TTSOptions = TTSOptions()
    ) -> Result<SpeechResult, TTSError> {
        // Check if model is loaded
        guard let context = self.context else {
            return .failure(.noModelLoaded)
        }
        
        // Check if vocoder is enabled
        guard self.isVocoderEnabled() else {
            return .failure(.noVocoderEnabled)
        }
        
        // Check TTS model type
        let ttsType = self.getTTSType()
        let isKnownTTSModel = ttsType != .unknown
        
        var audioSamples: [Float]?
        var methodUsed: TTSMethod = .builtIn
        
        if isKnownTTSModel {
            // Try Path 1: Built-in TTS method
            audioSamples = self.generateAudioFromText(text: text)
            methodUsed = .builtIn
        }
        
        if audioSamples == nil {
            // Try Path 2: Custom TTS workflow
            audioSamples = self.performCustomTTSWorkflowSync(text: text)
            methodUsed = .customWorkflow
        }
        
        guard let floatSamples = audioSamples else {
            return .failure(.generationFailed)
        }
        
        // Calculate duration
        let duration = TimeInterval(floatSamples.count) / TimeInterval(options.sampleRate)
        
        // Save to file if requested
        var outputFilePath: String? = nil
        if options.saveToFile {
            let filePath = options.outputFilePath ?? NSTemporaryDirectory().appending("tts_output_\(UUID().uuidString).wav")
            let saveSuccess = self.saveAudioToWav(
                filePath: filePath,
                audioData: floatSamples,
                sampleRate: Int32(options.sampleRate)
            )
            if saveSuccess {
                outputFilePath = filePath
            } else {
                return .failure(.fileSaveFailed)
            }
        }
        
        // Convert Float samples to Int16 for return
        let int16Samples = floatSamples.map { Int16(clamping: Int($0 * Float(Int16.max))) }
        
        let result = SpeechResult(
            audioSamples: int16Samples,
            sampleRate: options.sampleRate,
            duration: duration,
            outputFilePath: outputFilePath,
            methodUsed: methodUsed
        )
        
        return .success(result)
    }
    
    /// Generates speech from text with streaming support (for long text)
    /// - Parameters:
    ///   - text: Text to convert to speech (can be long)
    ///   - options: TTS configuration options
    ///   - progressHandler: Optional callback for progress updates (0.0 to 1.0)
    ///   - audioChunkHandler: Callback for receiving audio chunks as they're generated
    /// - Returns: Result containing final metadata (duration, method used, etc.)
    public func generateSpeechStreamForLongTextAsync(
        text: String,
        options: TTSOptions = TTSOptions(),
        progressHandler: ((Float) -> Void)? = nil,
        audioChunkHandler: @escaping ([Int16]) -> Void
    ) async -> Result<SpeechMetadata, TTSError> {
        // Check if model is loaded
        guard let context = self.context else {
            return .failure(.noModelLoaded)
        }
        
        // Check if vocoder is enabled
        guard self.isVocoderEnabled() else {
            return .failure(.noVocoderEnabled)
        }
        
        progressHandler?(0.1) // Initial progress
        
        // Split text into chunks for streaming
        let textChunks = splitTextIntoChunks(text)
        let totalChunks = textChunks.count
        if totalChunks == 0 {
            return .failure(.invalidText)
        }
        
        progressHandler?(0.2) // Text splitting completed
        
        // Track total duration and method used
        var totalDuration: TimeInterval = 0
        var methodUsed: TTSMethod = .builtIn
        var firstMethodUsed: TTSMethod? = nil
        
        // Process each chunk in sequence
        for (index, chunk) in textChunks.enumerated() {
            let chunkProgress = Float(index) / Float(totalChunks) * 0.7
            progressHandler?(0.2 + chunkProgress) // Update progress
            
            // Generate speech for this chunk
            let chunkResult = self.generateSpeech(
                text: chunk,
                options: options
            )
            
            switch chunkResult {
            case .success(let speechResult):
                // Send this chunk for playback
                audioChunkHandler(speechResult.audioSamples)
                
                // Accumulate metrics
                totalDuration += speechResult.duration
                if firstMethodUsed == nil {
                    firstMethodUsed = speechResult.methodUsed
                }
                
            case .failure(let error):
                return .failure(error)
            }
        }
        
        progressHandler?(1.0) // Process completed
        
        // Use the first method used for the entire operation
        if let firstMethod = firstMethodUsed {
            methodUsed = firstMethod
        }
        
        let metadata = SpeechMetadata(
            sampleRate: options.sampleRate,
            duration: totalDuration,
            methodUsed: methodUsed,
            outputFilePath: nil
        )
        
        return .success(metadata)
    }
    
    /// Splits text into smaller chunks for streaming
    private func splitTextIntoChunks(_ text: String) -> [String] {
        // Split by sentences (period, exclamation, question mark) and newlines
        var chunks: [String] = []
        var currentChunk = ""
        
        for char in text {
            currentChunk.append(char)
            
            // Split on sentence boundaries
            if ".!?\n".contains(char) {
                let trimmedChunk = currentChunk.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedChunk.isEmpty {
                    chunks.append(trimmedChunk)
                    currentChunk = ""
                }
            }
            
            // Also split if chunk gets too long (fallback for long sentences)
            if currentChunk.count > 200 {
                let trimmedChunk = currentChunk.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedChunk.isEmpty {
                    chunks.append(trimmedChunk)
                    currentChunk = ""
                }
            }
        }
        
        // Add any remaining text
        let trimmedChunk = currentChunk.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedChunk.isEmpty {
            chunks.append(trimmedChunk)
        }
        
        return chunks
    }
    
    // MARK: - Private TTS Helper Methods
    
    /// Performs custom TTS workflow asynchronously
    private func performCustomTTSWorkflow(text: String, progressHandler: ((Float) -> Void)?) async -> [Float]? {
        // Format text for TTS
        guard let formattedPrompt = self.getFormattedAudioCompletion(speakerJson: "{\"speaker\": \"default\"}", textToSpeak: text) else {
            return nil
        }
        
        progressHandler?(0.5) // Text formatting completed
        
        // Get audio guide tokens
        guard let guideTokens = self.getAudioGuideTokens(textToSpeak: formattedPrompt) else {
            return nil
        }
        
        // Set guide tokens for audio generation
        self.setGuideTokens(tokens: guideTokens)
        
        progressHandler?(0.6) // Guide tokens generated
        
        // Generate audio content using text completion
        var completionParams = CompletionParams(prompt: formattedPrompt)
        completionParams.maxTokens = 200
        completionParams.temperature = 0.0
        completionParams.ignoreEos = false // Don't ignore EOS, let model stop naturally
        
        let completionResult = await Task.detached { 
            self.generateCompletion(with: completionParams)
        }.value
        
        guard let completionResult = completionResult else {
            return nil
        }
        
        progressHandler?(0.7) // Text completion generated
        
        // Tokenize only the completion (not the prompt + completion)
        // The prompt is already represented by the guide tokens
        guard let tokens = self.tokenize(text: completionResult.text) else {
            return nil
        }
        
        progressHandler?(0.8) // Content tokenized
        
        // Filter audio tokens - match Android implementation
        var filteredTokens = [Int32]()
        let audioEndToken: Int32 = 151668 // <|audio_end|>
        let minAudioToken: Int32 = 151672
        let maxAudioToken: Int32 = 155772
        
        // Debug logging
        print("[TTS] Custom - Original tokens count: \(tokens.count)")
        if !tokens.isEmpty {
            print("[TTS] Custom - First 20 tokens: \(tokens.prefix(20))")
            print("[TTS] Custom - Last 10 tokens: \(tokens.suffix(10))")
        }
        
        var nonAudioTokens = 0
        for token in tokens {
            // Check if token is in audio range
            if token >= minAudioToken && token <= maxAudioToken {
                filteredTokens.append(token)
            } else {
                nonAudioTokens += 1
            }
            
            // Check for end token
            if token == audioEndToken {
                print("[TTS] Found audio end token")
                break
            }
        }
        
        // Debug logging
        print("[TTS] Filtered tokens count: \(filteredTokens.count)")
        print("[TTS] Non-audio tokens skipped: \(nonAudioTokens)")
        if !filteredTokens.isEmpty {
            print("[TTS] First 10 filtered tokens: \(filteredTokens.prefix(10))")
        }
        
        // Decode audio tokens
        guard let audioSamples = self.decodeAudioTokens(tokens: filteredTokens) else {
            return nil
        }
        
        progressHandler?(0.9) // Audio decoded
        
        return audioSamples
    }
    
    /// Performs custom TTS workflow synchronously
    private func performCustomTTSWorkflowSync(text: String) -> [Float]? {
        // Format text for TTS
        guard let formattedPrompt = self.getFormattedAudioCompletion(speakerJson: "{\"speaker\": \"default\"}", textToSpeak: text) else {
            return nil
        }
        
        // Get audio guide tokens
        guard let guideTokens = self.getAudioGuideTokens(textToSpeak: formattedPrompt) else {
            return nil
        }
        
        // Set guide tokens for audio generation
        self.setGuideTokens(tokens: guideTokens)
        
        // Generate audio content using text completion
        var completionParams = CompletionParams(prompt: formattedPrompt)
        completionParams.maxTokens = 200
        completionParams.temperature = 0.0
        completionParams.ignoreEos = false // Don't ignore EOS, let model stop naturally
        
        guard let completionResult = self.generateCompletion(with: completionParams) else {
            return nil
        }
        
        // Tokenize only the completion (not the prompt + completion)
        // The prompt is already represented by the guide tokens
        guard let tokens = self.tokenize(text: completionResult.text) else {
            return nil
        }
        
        // Filter audio tokens - match Android implementation
        var filteredTokens = [Int32]()
        let audioEndToken: Int32 = 151668 // <|audio_end|>
        let minAudioToken: Int32 = 151672
        let maxAudioToken: Int32 = 155772
        
        // Debug logging
        print("[TTS] Original tokens count: \(tokens.count)")
        if !tokens.isEmpty {
            print("[TTS] First 10 tokens: \(tokens.prefix(10))")
            print("[TTS] Last 10 tokens: \(tokens.suffix(10))")
        }
        
        var nonAudioTokens = 0
        for token in tokens {
            // Check if token is in audio range
            if token >= minAudioToken && token <= maxAudioToken {
                filteredTokens.append(token)
            } else {
                nonAudioTokens += 1
            }
            
            // Check for end token
            if token == audioEndToken {
                print("[TTS] Found audio end token")
                break
            }
        }
        
        // Debug logging
        print("[TTS] Filtered tokens count: \(filteredTokens.count)")
        print("[TTS] Non-audio tokens skipped: \(nonAudioTokens)")
        if !filteredTokens.isEmpty {
            print("[TTS] First 10 filtered tokens: \(filteredTokens.prefix(10))")
        }
        
        // Decode audio tokens
        guard let audioSamples = self.decodeAudioTokens(tokens: filteredTokens) else {
            return nil
        }
        
        return audioSamples
    }
    
    // MARK: - LoRA Adapter Methods
    
    /// Apply LoRA adapters to the model
    /// - Parameter adapters: Array of LoRA adapter configurations
    /// - Returns: true on success, false on failure
    public func applyLoraAdapters(_ adapters: [LoraAdapter]) -> Bool {
        guard let context = context else {
            return false
        }
        
        // Convert Swift adapters to C array
        let adapterCount = adapters.count
        let cAdapters = UnsafeMutablePointer<llama_mobile_lora_adapter_c_t>.allocate(capacity: adapterCount)
        defer { cAdapters.deallocate() }
        
        for (index, adapter) in adapters.enumerated() {
            cAdapters[index].path = adapter.path.withCString { $0 }
            cAdapters[index].scale = adapter.scale
        }
        
        // Create C adapters struct
        var cLoraAdapters = llama_mobile_lora_adapters_c_t()
        cLoraAdapters.adapters = cAdapters
        cLoraAdapters.count = Int32(adapterCount)
        
        // Apply adapters
        let result = llama_mobile_apply_lora_adapters_c(context, &cLoraAdapters)
        
        return result == 0
    }
    
    /// Remove all loaded LoRA adapters
    public func removeLoraAdapters() {
        if let context = context {
            llama_mobile_remove_lora_adapters_c(context)
        }
    }
    
    /// Get the currently loaded LoRA adapters
    /// - Returns: Array of loaded LoRA adapter configurations, or nil if an error occurred
    public func getLoadedLoraAdapters() -> [LoraAdapter]? {
        guard let context = context else {
            return nil
        }
        
        var cResult = llama_mobile_get_loaded_lora_adapters_c(context)
        defer { llama_mobile_free_lora_adapters_c(&cResult) }
        
        guard let cAdapters = cResult.adapters else {
            return []
        }
        
        let adapterCount = Int(cResult.count)
        var adapters = [LoraAdapter](repeating: LoraAdapter(path: "", scale: 0.0), count: adapterCount)
        
        for index in 0..<adapterCount {
            let cAdapter = cAdapters[index]
            guard let path = cAdapter.path else {
                continue
            }
            
            adapters[index] = LoraAdapter(
                path: String(cString: path),
                scale: cAdapter.scale
            )
        }
        
        return adapters
    }
    
    // MARK: - Conversation Methods
    
    /// Generate a response to a user message in a conversation
    /// - Parameters:
    ///   - userMessage: User's message
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - tokenCallback: Optional streaming callback for generated tokens
    /// - Returns: Conversation result, or nil if an error occurred
    public func generateResponse(userMessage: String, maxTokens: Int32 = 128, tokenCallback: ((String) -> Bool)? = nil) -> ConversationResult? {
        guard let context = context else {
            return nil
        }
        
        // Create token callback wrapper if needed
        typealias TokenCallbackType = @convention(c) (UnsafePointer<CChar>?, UnsafeMutableRawPointer?) -> Bool
        var tokenCallbackPtr: TokenCallbackType? = nil
        
        if tokenCallback != nil {
            // Store the closure in global context
            tokenCallbackContext = tokenCallback
            // Use the global C-compatible function
            tokenCallbackPtr = { (token: UnsafePointer<CChar>?, user_data: UnsafeMutableRawPointer?) -> Bool in
                cTokenCallback(token: token, user_data: user_data)
            }
        }
        
        return userMessage.withCString { messageC in
            var cResult = llama_mobile_continue_conversation_with_callback_c(
                context,
                messageC,
                maxTokens,
                tokenCallbackPtr,
                nil // user_data
            )
            
            defer { llama_mobile_free_conversation_result_members_c(&cResult) }
            
            guard let text = cResult.text.map({ String(cString: $0) }) else {
                return nil
            }
            
            return ConversationResult(
                text: text,
                timeToFirstToken: cResult.time_to_first_token,
                totalTime: cResult.total_time,
                tokensGenerated: cResult.tokens_generated
            )
        }
    }
    
    /// Clear the current conversation context
    public func clearConversation() {
        if let context = context {
            llama_mobile_clear_conversation_c(context)
        }
    }
    
    /// Check if a conversation is currently active
    /// - Returns: true if active, false otherwise
    public func isConversationActive() -> Bool {
        guard let context = context else {
            return false
        }
        
        return llama_mobile_is_conversation_active_c(context)
    }
    
    // MARK: - Model Information Methods
    
    /// Get the size of the context window
    /// - Returns: Size of the context window in tokens
    public func getContextWindowSize() -> Int32 {
        guard let context = context else {
            return 0
        }
        
        return llama_mobile_get_n_ctx_c(context)
    }
    
    /// Get the dimension of the model's embeddings
    /// - Returns: Dimension of the model's embeddings
    public func getEmbeddingDimension() -> Int32 {
        guard let context = context else {
            return 0
        }
        
        return llama_mobile_get_n_embd_c(context)
    }
    
    /// Get a description of the loaded model
    /// - Returns: Model description string
    public func getModelDescription() -> String? {
        guard let context = context else {
            return nil
        }
        
        let cString = llama_mobile_get_model_desc_c(context)
        
        guard let cString = cString else {
            return nil
        }
        
        defer { llama_mobile_free_string_c(cString) }
        return String(cString: cString)
    }
    
    /// Get the size of the loaded model
    /// - Returns: Model size in bytes
    public func getModelSize() -> Int64 {
        guard let context = context else {
            return 0
        }
        
        return llama_mobile_get_model_size_c(context)
    }
    
    /// Get the number of parameters in the loaded model
    /// - Returns: Number of model parameters
    public func getModelParametersCount() -> Int64 {
        guard let context = context else {
            return 0
        }
        
        return llama_mobile_get_model_params_c(context)
    }
}

