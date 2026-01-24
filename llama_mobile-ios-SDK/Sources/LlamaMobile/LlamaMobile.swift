//
//  LlamaMobile.swift
//  llama_mobile
//
//  Created by llama_mobile team
//

import Foundation
import llama_mobile
import Darwin

// Global callback context holders
private var progressCallbackContext: ((Float) -> Void)? = nil
private var downloadProgressCallbackContext: ((Float) -> Void)? = nil
private var tokenCallbackContext: ((String) -> Bool)? = nil
private var completionCallbackContext: ((String) -> Void)? = nil
private var chunkCallbackContext: ((String) -> Void)? = nil
private var embeddingCallbackContext: (([Float]) -> Void)? = nil

// C-compatible callback functions
private func cProgressCallback(progress: Float) -> Void {
    progressCallbackContext?(progress)
}

private func cDownloadProgressCallback(progress: Float, status: UnsafePointer<CChar>?, downloadedBytes: Int64, totalBytes: Int64) -> Void {
    downloadProgressCallbackContext?(progress)
}

private func cTokenCallback(token: UnsafePointer<CChar>?) -> Bool {
    guard let token = token else { return true }
    let tokenString = String(cString: token)
    return tokenCallbackContext?(tokenString) ?? true
}

private func cCompletionCallback(text: UnsafePointer<Int8>?) -> Void {
    guard let text = text else { return }
    completionCallbackContext?(String(cString: text))
}

private func cChunkCallback(text: UnsafePointer<Int8>?) -> Void {
    guard let text = text else { return }
    chunkCallbackContext?(String(cString: text))
}

private func cEmbeddingCallback(embedding: UnsafePointer<Float>?, count: Int) -> Void {
    guard let embedding = embedding else { return }
    let embeddingArray = Array(UnsafeBufferPointer(start: embedding, count: count))
    embeddingCallbackContext?(embeddingArray)
}

/// LlamaMobile API wrapper for iOS
/// 
/// This class provides a Swift-friendly interface to the llama_mobile C API, 
/// offering the same feature set but with simplified parameter design and 
/// automatic memory management.
public class LlamaMobile {
    
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
    
    /// Chat template used by the model
    public var chatTemplate: String? = nil
    
    /// Configure Metal paths before model initialization
    private func configureMetalPaths() {
        // Get the framework bundle
        let frameworkBundle = Bundle(for: type(of: self))
        let frameworkPath = frameworkBundle.bundlePath
        
        // Log the paths for debugging
        print("[DEBUG] Framework bundle path: \(frameworkPath)")
        print("[DEBUG] Framework bundle resources path: \(frameworkBundle.resourcePath ?? "nil")")
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
        }
        
        /// Convenience initializer for embedding generation
        public init(modelPath: String, embedding: Bool, poolingType: Int32 = 0) {
            self.modelPath = modelPath
            self.embedding = embedding
            self.poolingType = poolingType
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
        public var maxTokens: Int32 = 128
        
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
        
        /// Whether to return the response in OpenAI-like JSON format
        public var useJsonResponse: Bool = false
        
        /// Custom chat template for formatting conversations
        public var chatTemplate: String? = nil
        
        /// Default initializer with minimal parameters
        public init(prompt: String) {
            self.prompt = prompt
        }
        
        /// Convenience initializer for chat conversations
        public init(chatMessages: [ChatMessage]) {
            self.prompt = ""
            self.chatMessages = chatMessages
            self.maxTokens = 256
            self.temperature = 0.7
            self.topP = 0.95
            self.topK = 40
            self.penaltyRepeat = 1.2
        }
        
        /// Convenience initializer for creative writing
        public init(creativePrompt: String, maxTokens: Int32 = 512) {
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
        public init(chatPrompt: String, maxTokens: Int32 = 256) {
            self.init(prompt: chatPrompt)
            self.maxTokens = maxTokens
            self.temperature = 0.7
            self.topP = 0.95
            self.topK = 40
            self.penaltyRepeat = 1.2
        }
        
        /// Convenience initializer for multimodal inputs
        public init(multimodalPrompt: String, mediaPaths: [String], maxTokens: Int32 = 256) {
            self.init(prompt: multimodalPrompt)
            self.maxTokens = maxTokens
            self.mediaPaths = mediaPaths
        }
        
        /// Full initializer with all parameters
        public init(prompt: String, maxTokens: Int32 = 128, nThreads: Int32? = nil, seed: Int32 = -1, temperature: Double = 0.8, topK: Int32 = 40, topP: Double = 0.95, minP: Double = 0.05, typicalP: Double = 1.0, penaltyLastN: Int32 = 64, penaltyRepeat: Double = 1.1, penaltyFreq: Double = 0.0, penaltyPresent: Double = 0.0, mirostat: Int32 = 0, mirostatTau: Double = 5.0, mirostatEta: Double = 0.1, ignoreEos: Bool = false, stopSequences: [String] = [], grammar: String? = nil, mediaPaths: [String] = [], chatMessages: [ChatMessage] = [], useJsonResponse: Bool = false, chatTemplate: String? = nil, tokenCallback: ((String) -> Bool)? = nil) {
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
            self.chatTemplate = chatTemplate
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
                
                // Add the text content to chat messages
                chatMessages.append(ChatMessage(role: role, content: textContent.trimmingCharacters(in: .whitespacesAndNewlines)))
            }
            
            // Call the existing chatMessages initializer first to ensure proper initialization
            self.init(chatMessages: chatMessages)
            
            // Override with improved parameters for OpenAI compatibility
            self.minP = 0.1
            self.penaltyRepeat = 1.0
            self.penaltyFreq = 0.0
            self.penaltyPresent = 0.0
            self.penaltyLastN = 64
            
            // No hardcoded stop sequences - let the caller set them explicitly
            // This allows better control over when generation stops
            
            // Enable JSON response format for OpenAI compatibility
            self.useJsonResponse = true
            
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
        
        /// Initialize a new chat message
        /// - Parameters:
        ///   - role: The role of the message sender
        ///   - content: The content of the message
        public init(role: String, content: String) {
            self.role = role
            self.content = content
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
        
        guard initialize(with: params) else {
            return nil
        }
    }
    
    /// Initialize a new llama_mobile context with detailed parameters
    /// - Parameter params: Initialization parameters
    public init?(with params: InitParams) {
        guard initialize(with: params) else {
            return nil
        }
    }
    
    /// Sets the chat template for the model.
    /// - Parameter template: The chat template to use.
    public func setChatTemplate(_ template: String?) {
        self.chatTemplate = template
    }
    
    /// Internal initialization method
    private func initialize(with params: InitParams) -> Bool {
        // Configure Metal paths before initialization
        configureMetalPaths()
        
        // Create progress callback wrapper if needed
        typealias ProgressCallbackType = @convention(c) (Float) -> Void
        var callbackWrapper: ProgressCallbackType? = nil
        
        if params.progressCallback != nil {
            // Store the closure in global context
            progressCallbackContext = params.progressCallback
            // Use the global C-compatible function
            callbackWrapper = { (progress: Float) -> Void in
                cProgressCallback(progress: progress)
            }
        }
        
        // Create and populate the C params struct
        var cParams = llama_mobile_init_params_c_t()
        memset(&cParams, 0, MemoryLayout<llama_mobile_init_params_c_t>.size)
        
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
        cParams.progress_callback = callbackWrapper
        
        // Store the chat template for later use
        let chatTemplateToStore = params.chatTemplate
        
        // Use strdup to create persistent copies of the strings
        let modelPathPtr = params.modelPath.withCString { strdup($0) }
        let chatTemplatePtr = params.chatTemplate?.withCString { strdup($0) }
        let systemPromptPtr = params.systemPrompt?.withCString { strdup($0) }
        let cacheTypeKPtr = params.cacheTypeK?.withCString { strdup($0) }
        let cacheTypeVPtr = params.cacheTypeV?.withCString { strdup($0) }
        
        // Set the pointers in the params struct
        cParams.model_path = UnsafePointer(modelPathPtr)
        cParams.chat_template = UnsafePointer(chatTemplatePtr)
        cParams.system_prompt = UnsafePointer(systemPromptPtr)
        cParams.cache_type_k = UnsafePointer(cacheTypeKPtr)
        cParams.cache_type_v = UnsafePointer(cacheTypeVPtr)
        
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
        
        // Store the chat template
        if let chatTemplate = chatTemplateToStore {
            self.chatTemplate = chatTemplate
        } else {
            // Note: We're unable to access the built-in template from Swift due to framework limitations
            // This functionality would require updating the binary framework's headers or modulemap
            // For now, apps can implement their own fallback logic using the setChatTemplate method
            self.chatTemplate = nil
        }
        
        return context != nil
    }
    
    /// Clean up resources when the instance is deallocated
    deinit {
        if let context = context {
            llama_mobile_free_context_c(context)
        }
    }
    
    // MARK: - Completion Methods
    
    /// Load grammar content from a file path
    /// - Parameter grammarPath: Path to the grammar file (.gbnf format)
    /// - Returns: Grammar content as a string, or nil if an error occurred
    public func loadGrammar(from grammarPath: String) -> String? {
        do {
            return try String(contentsOfFile: grammarPath, encoding: .utf8)
        } catch {
            print("Error loading grammar file: \(error)")
            return nil
        }
    }
    
    /// Load grammar content from the framework's grammars directory
    /// - Parameter grammarName: Name of the grammar file (without .gbnf extension)
    /// - Returns: Grammar content as a string, or nil if an error occurred
    public func loadGrammar(named grammarName: String) -> String? {
        // Get the framework bundle
        let frameworkBundle = Bundle(for: type(of: self))
        print("[DEBUG] Loading grammar '\(grammarName)' from framework bundle: \(frameworkBundle.bundlePath)")
        
        // Try to find the grammar file in the framework's grammars directory
        if let grammarURL = frameworkBundle.url(forResource: grammarName, withExtension: "gbnf", subdirectory: "grammars") {
            print("[DEBUG] Found grammar file at: \(grammarURL.path)")
            
            do {
                let content = try String(contentsOf: grammarURL, encoding: .utf8)
                print("[DEBUG] ✓ Successfully loaded grammar '\(grammarName)' (\(content.count) characters)")
                return content
            } catch {
                print("[ERROR] ✗ Failed to read grammar file: \(error)")
            }
        } else {
            // List available grammar files for debugging
            do {
                let grammarsDirURL = frameworkBundle.url(forResource: nil, withExtension: nil, subdirectory: "grammars")
                if let grammarsPath = grammarsDirURL?.path {
                    let availableGrammars = try FileManager.default.contentsOfDirectory(atPath: grammarsPath)
                    print("[DEBUG] Available grammar files in framework: \(availableGrammars)")
                }
            } catch {
                print("[ERROR] ✗ Failed to list available grammar files: \(error)")
            }
            
            print("[ERROR] ✗ Grammar file '\(grammarName).gbnf' not found in framework's grammars directory")
        }
        
        return nil
    }
    
    /// Generate a text completion from a prompt
    /// - Parameter params: Completion parameters
    /// - Returns: Completion result, or nil if an error occurred
    public func generateCompletion(with params: CompletionParams) -> CompletionResult? {
        guard let context = context else {
            return nil
        }
        
        // Convert stop sequences to C array
        let stopSequenceCount = params.stopSequences.count
        let stopSequencesC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: stopSequenceCount)
        
        // Array to store C strings that need to be freed
        var stopStringsToFree: [UnsafeMutablePointer<CChar>] = []
        defer {
            // Free all allocated C strings for stop sequences
            for cString in stopStringsToFree {
                cString.deallocate()
            }
            // Free the stop sequences array
            stopSequencesC.deallocate()
        }
        
        for (index, sequence) in params.stopSequences.enumerated() {
            // Allocate permanent C string for stop sequence
            let stopCString = UnsafeMutablePointer<CChar>.allocate(capacity: sequence.utf8.count + 1)
            sequence.withCString { source in
                stopCString.update(from: source, count: sequence.utf8.count + 1)
            }
            stopStringsToFree.append(stopCString)
            stopSequencesC[index] = UnsafePointer(stopCString)
        }
        
        // Create token callback wrapper if needed
        typealias TokenCallbackType = @convention(c) (UnsafePointer<CChar>?) -> Bool
        var tokenCallbackPtr: TokenCallbackType? = nil
        
        if params.tokenCallback != nil {
            // Store the closure in global context
            tokenCallbackContext = params.tokenCallback
            // Use the global C-compatible function
            tokenCallbackPtr = { (token: UnsafePointer<CChar>?) -> Bool in
                cTokenCallback(token: token)
            }
        }
        
        // Create and populate the C params struct
        // Initialize with zero values to prevent garbage memory issues
        var cParams = llama_mobile_completion_params_c_t()
        memset(&cParams, 0, MemoryLayout<llama_mobile_completion_params_c_t>.size)
        
        // Set prompt to empty string when chat messages are present, otherwise use the prompt
        let promptToUse = params.chatMessages.isEmpty ? params.prompt : ""
        cParams.prompt = promptToUse.withCString { $0 }
        cParams.n_predict = params.maxTokens
        cParams.n_threads = params.nThreads ?? 0
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
        cParams.stop_sequences = stopSequenceCount > 0 ? stopSequencesC : nil
        cParams.stop_sequence_count = Int32(stopSequenceCount)
        
        // Log grammar usage and handle grammar string
        var grammarCString: UnsafeMutablePointer<CChar>? = nil
        if let grammar = params.grammar {
            print("[DEBUG] Using grammar for generation")
            print("[DEBUG] Grammar preview: \(grammar.prefix(100))...")
            // Allocate permanent C string for grammar
            grammarCString = UnsafeMutablePointer<CChar>.allocate(capacity: grammar.utf8.count + 1)
            grammar.withCString { source in
                grammarCString?.update(from: source, count: grammar.utf8.count + 1)
            }
            cParams.grammar = UnsafePointer(grammarCString)
        } else {
            print("[DEBUG] No grammar specified for generation")
            cParams.grammar = nil
        }
        // Add grammar to cleanup list if allocated
        if let grammarCString = grammarCString {
            stopStringsToFree.append(grammarCString) // Reuse existing cleanup list
        }
        
        cParams.token_callback = tokenCallbackPtr
        
        // Handle chat messages if provided
        if !params.chatMessages.isEmpty {
            print("[DEBUG] Using structured chat messages instead of raw prompt")
            
            // Manually format chat messages using the template since C API doesn't support passing template with structured messages
            guard let chatTemplate = params.chatTemplate else {
                print("[ERROR] Cannot format chat messages: No chat template provided")
                return nil
            }
            
            print("[MANUAL FORMAT] Using chat template: \(chatTemplate)")
            
            var formattedPrompt = ""
            
            for message in params.chatMessages {
                var messageTemplate = chatTemplate
                messageTemplate = messageTemplate.replacingOccurrences(of: "{{role}}", with: message.role)
                messageTemplate = messageTemplate.replacingOccurrences(of: "{{content}}", with: message.content)
                formattedPrompt += messageTemplate
            }
            
            // Add the assistant prompt suffix based on the chat template
            // This extracts the assistant turn format by replacing role with 'assistant' and removing content placeholder and closing tag
            var assistantTurnTemplate = chatTemplate
            assistantTurnTemplate = assistantTurnTemplate.replacingOccurrences(of: "{{role}}", with: "assistant")
            
            // Find the position of the content placeholder and only keep the part before it
            if let contentPlaceholderRange = assistantTurnTemplate.range(of: "{{content}}") {
                // Only keep the part before the content placeholder
                assistantTurnTemplate = String(assistantTurnTemplate[..<contentPlaceholderRange.lowerBound])
            }
            
            // Trim whitespace
            assistantTurnTemplate = assistantTurnTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            formattedPrompt += assistantTurnTemplate + "\n"
            
            print("[DEBUG] Manually formatted prompt using template:")
            print(formattedPrompt)
            
            // Use the manually formatted prompt instead of structured chat messages
            // Create a persistent C string copy since withCString only keeps it valid for the closure
            let promptCString = UnsafeMutablePointer<CChar>.allocate(capacity: formattedPrompt.utf8.count + 1)
            formattedPrompt.withCString { source in
                promptCString.update(from: source, count: formattedPrompt.utf8.count + 1)
            }
            cParams.prompt = UnsafePointer(promptCString)
            cParams.chat_messages = nil
            cParams.chat_message_count = 0
            
            // Free the C string later using the existing cleanup list
            stopStringsToFree.append(promptCString)
        } else {
            cParams.chat_messages = nil
            cParams.chat_message_count = 0
        }
        
        // Set JSON response flag
        cParams.use_json_response = params.useJsonResponse
        
        // Generate completion - use multimodal if media paths are provided
        var cResult = llama_mobile_completion_result_c_t()
        let status: Int32
        
        if !params.mediaPaths.isEmpty {
            // Convert media paths to C array
            let mediaCount = params.mediaPaths.count
            let mediaPathsC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: mediaCount)
            
            // Array to store C strings that need to be freed
            var mediaStringsToFree: [UnsafeMutablePointer<CChar>] = []
            defer {
                // Free all allocated C strings for media paths
                for cString in mediaStringsToFree {
                    cString.deallocate()
                }
                // Free the media paths array
                mediaPathsC.deallocate()
            }
            
            for (index, path) in params.mediaPaths.enumerated() {
                // Allocate permanent C string for media path
                let mediaCString = UnsafeMutablePointer<CChar>.allocate(capacity: path.utf8.count + 1)
                path.withCString { source in
                    mediaCString.update(from: source, count: path.utf8.count + 1)
                }
                mediaStringsToFree.append(mediaCString)
                mediaPathsC[index] = UnsafePointer(mediaCString)
            }
            
            status = llama_mobile_multimodal_completion_c(context, &cParams, mediaPathsC, Int32(mediaCount), &cResult)
        } else {
            status = llama_mobile_completion_c(context, &cParams, &cResult)
        }
        
        // Log the result status
        print("[DEBUG] Completion C API status: \(status)")
        
        guard status == 0 else {
            print("[ERROR] Completion C API failed with status: \(status)")
            llama_mobile_free_completion_result_members_c(&cResult)
            return nil
        }
        
        guard let text = cResult.text.map({ String(cString: $0) }) else {
            print("[ERROR] Completion result has no text")
            llama_mobile_free_completion_result_members_c(&cResult)
            return nil
        }
        
        // Log token statistics
        print("[DEBUG] Tokens evaluated: \(cResult.tokens_evaluated)")
        print("[DEBUG] Tokens generated: \(cResult.tokens_predicted)")
        print("[DEBUG] Generation stopped because: \n  - End of sequence: \(cResult.stopped_eos)\n  - Stop word: \(cResult.stopped_word)\n  - Token limit: \(cResult.stopped_limit)")
        
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
        print("[DEBUG] Completion result: \(text)")
        
        // Validate if generated text is different from prompt
        if text == params.prompt {
            print("[WARNING] Generated text is identical to input prompt. This could indicate:")
            print("          - Model may not be generating any tokens")
            print("          - Generation parameters may be causing early stopping")
            print("          - Model file may be corrupt or incompatible")
            print("          - Prompt may need to be formatted differently for the model")
            print("[DEBUG] Tokens generated: \(cResult.tokens_predicted) (should be > 0 for new content)")
        }
        
        // Free C result members
        llama_mobile_free_completion_result_members_c(&cResult)
        
        return result
    }
    
    /// OpenAI-compatible completion API
    /// Accepts OpenAI format JSON and generates a completion
    /// - Parameter openAIJSON: OpenAI format JSON string
    /// - Parameter grammar: Optional grammar content to constrain generation
    /// - Returns: The generated completion result in OpenAI format, or nil if an error occurred.
    public func generateOpenAICompletion(with openAIJSON: String, grammar: String? = nil) -> CompletionResult? {
        guard let context = context else {
            return nil
        }
        
        do {
            // Create completion params from OpenAI JSON
            var params = try CompletionParams(openAIJSON: openAIJSON)
            
            // Only use the stored chat template if available
            // No fallback template - template remains nil if none is available
            params.chatTemplate = self.chatTemplate
            print("[JSON API] Using chat template: \(params.chatTemplate ?? "(none)")")
            
            // Set grammar if provided
            if let grammar = grammar {
                params.grammar = grammar
                print("[JSON API] Using grammar")
            }
            
            // Use JSON response format for OpenAI compatibility unless a custom grammar is provided
            // This avoids conflicts between built-in JSON formatting and custom JSON grammar
            params.useJsonResponse = grammar == nil
            
            // Generate completion using the standard method
            return generateCompletion(with: params)
        } catch {
            print("[ERROR] Error in generateOpenAICompletion: \(error)")
            return nil
        }
    }
    
    /// Generate a text completion with simplified parameters
    /// - Parameters:
    ///   - prompt: Input prompt text
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - temperature: Sampling temperature
    ///   - tokenCallback: Optional streaming callback for generated tokens
    /// - Returns: Completion result, or nil if an error occurred
    public func generateCompletion(prompt: String, maxTokens: Int32 = 128, temperature: Double = 0.8, tokenCallback: ((String) -> Bool)? = nil) -> CompletionResult? {
        var params = CompletionParams(prompt: prompt)
        params.maxTokens = maxTokens
        params.temperature = temperature
        params.tokenCallback = tokenCallback
        
        return generateCompletion(with: params)
    }
    
    /// Generate a completion with multimodal input (images/audio)
    /// - Parameters:
    ///   - params: Completion parameters
    ///   - mediaPaths: Array of paths to media files (images/audio)
    /// - Returns: Completion result, or nil if an error occurred
    /// - Note: This method is maintained for backward compatibility. Consider using `generateCompletion` with `mediaPaths` parameter instead.
    @available(*, deprecated, message: "Use generateCompletion(with:) with mediaPaths parameter instead")
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
    public func download(with params: DownloadParams) -> DownloadResult {
        // Create a progress callback wrapper if needed
        typealias DownloadProgressCallbackType = @convention(c) (Float, UnsafePointer<CChar>?, Int64, Int64) -> Void
        var callbackWrapper: DownloadProgressCallbackType? = nil
        
        if params.progressCallback != nil {
            // Store the closure in global context
            downloadProgressCallbackContext = params.progressCallback
            // Use the global C-compatible function
            callbackWrapper = { (progress: Float, status: UnsafePointer<CChar>?, downloadedBytes: Int64, totalBytes: Int64) -> Void in
                cDownloadProgressCallback(progress: progress, status: status, downloadedBytes: downloadedBytes, totalBytes: totalBytes)
            }
        }
        
        // Create destination directory if it doesn't exist
        let destinationURL = URL(fileURLWithPath: params.localPath)
        let destinationDir = destinationURL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        } catch {
            return DownloadResult(
                success: false,
                localPath: params.localPath,
                errorMessage: "Failed to create destination directory: \(error.localizedDescription)"
            )
        }
        
        // Use the download model function with appropriate parameters
        var cParams = llama_mobile_download_params_c_t()
        cParams.repo_id = params.url.withCString { $0 }
        cParams.filename = destinationURL.lastPathComponent.withCString { $0 }
        cParams.destination_path = destinationDir.path.withCString { $0 }
        cParams.bearer_token = params.password?.withCString { $0 } // password field used for bearer token
        cParams.offline = false
        cParams.progress_callback = callbackWrapper
        
        var cResult = llama_mobile_download_model_c(&cParams)
        
        // Convert C result to Swift result
        defer {
            // Free the C result
            llama_mobile_free_download_result_c(&cResult)
        }
        
        return DownloadResult(
            success: cResult.success,
            localPath: cResult.local_path != nil ? String(cString: cResult.local_path!) : params.localPath,
            errorMessage: cResult.error_message != nil ? String(cString: cResult.error_message!) : nil
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
            
            guard let tokens = cResult.tokens else {
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
    public func getFormattedAudioCompletion(speakerJson: String, textToSpeak: String) -> String? {
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
    public func getAudioGuideTokens(textToSpeak: String) -> [Int32]? {
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
    public func setGuideTokens(tokens: [Int32]) {
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
    public func decodeAudioTokens(tokens: [Int32]) -> [Float]? {
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
    
    /// Generate audio samples from text using TTS
    /// - Parameters:
    ///   - text: Text to convert to speech
    ///   - speakerJson: JSON string with speaker configuration (optional, defaults to default speaker)
    /// - Returns: Array of floating-point audio samples, or nil if an error occurred
    /// - Note: This method handles the entire TTS workflow in a single call: formatting, token generation, and audio decoding
    public func generateAudioFromText(text: String, speakerJson: String = "{\"speaker\": \"default\"}") -> [Float]? {
        guard let context = context, isVocoderEnabled() else {
            return nil
        }
        
        // Get formatted audio completion
        guard let formattedPrompt = getFormattedAudioCompletion(speakerJson: speakerJson, textToSpeak: text) else {
            return nil
        }
        
        // Generate audio tokens
        guard let audioTokens = getAudioGuideTokens(textToSpeak: formattedPrompt) else {
            return nil
        }
        
        // Decode audio tokens to samples
        return decodeAudioTokens(tokens: audioTokens)
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
    /// - Returns: Conversation result, or nil if an error occurred
    public func generateResponse(userMessage: String, maxTokens: Int32 = 128) -> ConversationResult? {
        guard let context = context else {
            return nil
        }
        
        return userMessage.withCString { messageC in
            var cResult = llama_mobile_continue_conversation_c(
                context,
                messageC,
                maxTokens
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
    
    /// Generate a response to a user message with streaming token callback
    /// - Parameters:
    ///   - userMessage: User's message
    ///   - maxTokens: Maximum number of tokens to generate
    ///   - tokenCallback: Streaming callback for generated tokens
    /// - Returns: Conversation result, or nil if an error occurred
    public func generateResponse(userMessage: String, maxTokens: Int32 = 128, tokenCallback: ((String) -> Bool)?) -> ConversationResult? {
        guard let context = context else {
            return nil
        }
        
        // Create token callback wrapper if needed
        typealias TokenCallbackType = @convention(c) (UnsafePointer<CChar>?) -> Bool
        var tokenCallbackPtr: TokenCallbackType? = nil
        
        if tokenCallback != nil {
            // Store the closure in global context
            tokenCallbackContext = tokenCallback
            // Use the global C-compatible function
            tokenCallbackPtr = { (token: UnsafePointer<CChar>?) -> Bool in
                cTokenCallback(token: token)
            }
        }
        
        return userMessage.withCString { messageC in
            var cResult = llama_mobile_continue_conversation_with_callback_c(
                context,
                messageC,
                maxTokens,
                tokenCallbackPtr
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

