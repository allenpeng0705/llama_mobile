//
//  LlamaMobile.swift
//  llama_mobile
//
//  Created by llama_mobile team
//

import Foundation
import llama_mobile

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
        
        /// Default initializer with minimal parameters
        public init(prompt: String) {
            self.prompt = prompt
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
        public init(prompt: String, maxTokens: Int32 = 128, nThreads: Int32? = nil, seed: Int32 = -1, temperature: Double = 0.8, topK: Int32 = 40, topP: Double = 0.95, minP: Double = 0.05, typicalP: Double = 1.0, penaltyLastN: Int32 = 64, penaltyRepeat: Double = 1.1, penaltyFreq: Double = 0.0, penaltyPresent: Double = 0.0, mirostat: Int32 = 0, mirostatTau: Double = 5.0, mirostatEta: Double = 0.1, ignoreEos: Bool = false, stopSequences: [String] = [], grammar: String? = nil, mediaPaths: [String] = [], tokenCallback: ((String) -> Bool)? = nil) {
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
            self.tokenCallback = tokenCallback
        }
    }
    
    /// Result of a text completion generation
    ///
    /// Contains the generated text and metadata about the completion process.
    public struct CompletionResult {
        /// Default initializer with all parameters
        public init(text: String, tokensGenerated: Int32, tokensEvaluated: Int32, truncated: Bool, stoppedEos: Bool, stoppedWord: Bool, stoppedLimit: Bool) {
            self.text = text
            self.tokensGenerated = tokensGenerated
            self.tokensEvaluated = tokensEvaluated
            self.truncated = truncated
            self.stoppedEos = stoppedEos
            self.stoppedWord = stoppedWord
            self.stoppedLimit = stoppedLimit
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
    
    /// Internal initialization method
    private func initialize(with params: InitParams) -> Bool {
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
        cParams.model_path = params.modelPath.withCString { $0 }
        cParams.chat_template = params.chatTemplate?.withCString { $0 }
        cParams.system_prompt = params.systemPrompt?.withCString { $0 }
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
        cParams.cache_type_k = params.cacheTypeK?.withCString { $0 }
        cParams.cache_type_v = params.cacheTypeV?.withCString { $0 }
        cParams.progress_callback = callbackWrapper
        
        // Initialize the context
        context = llama_mobile_init_context_c(&cParams)
        
        return context != nil
    }
    
    /// Clean up resources when the instance is deallocated
    deinit {
        if let context = context {
            llama_mobile_free_context_c(context)
        }
    }
    
    // MARK: - Completion Methods
    
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
        defer { stopSequencesC.deallocate() }
        
        for (index, sequence) in params.stopSequences.enumerated() {
            stopSequencesC[index] = sequence.withCString { $0 }
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
        var cParams = llama_mobile_completion_params_c_t()
        cParams.prompt = params.prompt.withCString { $0 }
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
        cParams.grammar = params.grammar?.withCString { $0 }
        cParams.token_callback = tokenCallbackPtr
        
        // Generate completion - use multimodal if media paths are provided
        var cResult = llama_mobile_completion_result_c_t()
        let status: Int32
        
        if !params.mediaPaths.isEmpty {
            // Convert media paths to C array
            let mediaCount = params.mediaPaths.count
            let mediaPathsC = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: mediaCount)
            defer { mediaPathsC.deallocate() }
            
            for (index, path) in params.mediaPaths.enumerated() {
                mediaPathsC[index] = path.withCString { $0 }
            }
            
            status = llama_mobile_multimodal_completion_c(context, &cParams, mediaPathsC, Int32(mediaCount), &cResult)
        } else {
            status = llama_mobile_completion_c(context, &cParams, &cResult)
        }
        
        guard status == 0, let text = cResult.text.map({ String(cString: $0) }) else {
            llama_mobile_free_completion_result_members_c(&cResult)
            return nil
        }
        
        // Create Swift result
        let result = CompletionResult(
            text: text,
            tokensGenerated: cResult.tokens_predicted,
            tokensEvaluated: cResult.tokens_evaluated,
            truncated: cResult.truncated,
            stoppedEos: cResult.stopped_eos,
            stoppedWord: cResult.stopped_word,
            stoppedLimit: cResult.stopped_limit
        )
        
        // Free C result members
        llama_mobile_free_completion_result_members_c(&cResult)
        
        return result
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

