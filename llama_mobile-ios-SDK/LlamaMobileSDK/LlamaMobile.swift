//
//  LlamaMobile.swift
//  LlamaMobileSDK
//
//  Created by Your Name on 2025-12-29.
//

import Foundation

public class LlamaMobile {
    
    // MARK: - Types
    
    /// Callback type for progress updates during model loading
    public typealias ProgressCallback = (Float) -> Void
    
    /// Callback type for token streaming during completion generation
    /// - Returns: `true` to continue generation, `false` to stop
    public typealias TokenCallback = (String) -> Bool
    
    /// Parameters for initializing the Llama model
    public struct InitParams {
        /// Path to the GGUF model file on disk
        public let modelPath: String
        
        /// Name of the chat template to use for conversational AI
        public let chatTemplate: String?
        
        /// Size of the context window (maximum number of tokens that can be processed)
        public let nCtx: Int32
        
        /// Batch size for processing input tokens
        public let nBatch: Int32
        
        /// Micro-batch size for processing input tokens
        public let nUbatch: Int32
        
        /// Number of layers to offload to GPU (0 = no GPU acceleration)
        public let nGpuLayers: Int32
        
        /// Number of CPU threads to use for inference
        public let nThreads: Int32
        
        /// Whether to use memory-mapped files for model loading
        public let useMmap: Bool
        
        /// Whether to lock model memory in RAM (prevents swapping)
        public let useMlock: Bool
        
        /// Whether to enable embedding generation
        public let embedding: Bool
        
        /// Pooling type for embeddings (0 = no pooling, 1 = mean pooling, 2 = max pooling)
        public let poolingType: Int32
        
        /// Whether to normalize embeddings
        public let embdNormalize: Int32
        
        /// Whether to enable flash attention optimization
        public let flashAttn: Bool
        
        /// Cache type for key tensors (e.g., "f16", "q4_0")
        public let cacheTypeK: String?
        
        /// Cache type for value tensors (e.g., "f16", "q4_0")
        public let cacheTypeV: String?
        
        /// Callback for model loading progress updates (0.0 to 1.0)
        public let progressCallback: ProgressCallback?
        
        /// Initializes model parameters with default values
        /// - Parameters:
        ///   - modelPath: Path to the GGUF model file
        ///   - chatTemplate: Name of the chat template to use
        ///   - nCtx: Size of the context window
        ///   - nBatch: Batch size for input processing
        ///   - nUbatch: Micro-batch size
        ///   - nGpuLayers: Number of layers to offload to GPU
        ///   - nThreads: Number of CPU threads for inference
        ///   - useMmap: Whether to use memory-mapped files
        ///   - useMlock: Whether to lock model memory in RAM
        ///   - embedding: Whether to enable embeddings
        ///   - poolingType: Pooling type for embeddings
        ///   - embdNormalize: Whether to normalize embeddings
        ///   - flashAttn: Whether to enable flash attention
        ///   - cacheTypeK: Cache type for key tensors
        ///   - cacheTypeV: Cache type for value tensors
        ///   - progressCallback: Progress callback for model loading
        public init(modelPath: String,
                    chatTemplate: String? = nil,
                    nCtx: Int32 = 2048,
                    nBatch: Int32 = 512,
                    nUbatch: Int32 = 512,
                    nGpuLayers: Int32 = 0,
                    nThreads: Int32 = 4,
                    useMmap: Bool = true,
                    useMlock: Bool = false,
                    embedding: Bool = false,
                    poolingType: Int32 = 0,
                    embdNormalize: Int32 = 0,
                    flashAttn: Bool = false,
                    cacheTypeK: String? = nil,
                    cacheTypeV: String? = nil,
                    progressCallback: ProgressCallback? = nil) {
            self.modelPath = modelPath
            self.chatTemplate = chatTemplate
            self.nCtx = nCtx
            self.nBatch = nBatch
            self.nUbatch = nUbatch
            self.nGpuLayers = nGpuLayers
            self.nThreads = nThreads
            self.useMmap = useMmap
            self.useMlock = useMlock
            self.embedding = embedding
            self.poolingType = poolingType
            self.embdNormalize = embdNormalize
            self.flashAttn = flashAttn
            self.cacheTypeK = cacheTypeK
            self.cacheTypeV = cacheTypeV
            self.progressCallback = progressCallback
        }
    }
    
    /// Parameters for text completion generation
    public struct CompletionParams {
        /// The text prompt to generate a completion for
        public let prompt: String
        
        /// Maximum number of tokens to generate
        public let nPredict: Int32
        
        /// Number of CPU threads to use for generation
        public let nThreads: Int32
        
        /// Random seed for generation (use -1 for random seed)
        public let seed: Int32
        
        /// Temperature for sampling (higher values = more random output)
        public let temperature: Double
        
        /// Top-K sampling parameter (0 = disable)
        public let topK: Int32
        
        /// Top-P sampling parameter (nucleus sampling)
        public let topP: Double
        
        /// Minimum probability for sampling
        public let minP: Double
        
        /// Typical-P sampling parameter
        public let typicalP: Double
        
        /// Number of tokens to consider for repetition penalty
        public let penaltyLastN: Int32
        
        /// Penalty for repeated tokens
        public let penaltyRepeat: Double
        
        /// Frequency penalty for tokens
        public let penaltyFreq: Double
        
        /// Present penalty for tokens
        public let penaltyPresent: Double
        
        /// Mirostat sampling mode (0 = disable, 1 = Mirostat, 2 = Mirostat 2.0)
        public let mirostat: Int32
        
        /// Mirostat target entropy
        public let mirostatTau: Double
        
        /// Mirostat learning rate
        public let mirostatEta: Double
        
        /// Whether to ignore the end-of-sequence token
        public let ignoreEos: Bool
        
        /// Number of top probabilities to return per token (0 = disable)
        public let nProbs: Int32
        
        /// Sequences that will stop generation when encountered
        public let stopSequences: [String]
        
        /// Grammar for constrained generation (using GBNF format)
        public let grammar: String?
        
        /// Callback for streaming token generation
        public let tokenCallback: TokenCallback?
        
        /// Initializes completion parameters with default values
        /// - Parameters:
        ///   - prompt: Text prompt for generation
        ///   - nPredict: Maximum tokens to generate
        ///   - nThreads: Number of CPU threads
        ///   - seed: Random seed
        ///   - temperature: Sampling temperature
        ///   - topK: Top-K parameter
        ///   - topP: Top-P parameter
        ///   - minP: Minimum probability parameter
        ///   - typicalP: Typical-P parameter
        ///   - penaltyLastN: Penalty window size
        ///   - penaltyRepeat: Repetition penalty
        ///   - penaltyFreq: Frequency penalty
        ///   - penaltyPresent: Present penalty
        ///   - mirostat: Mirostat mode
        ///   - mirostatTau: Mirostat target entropy
        ///   - mirostatEta: Mirostat learning rate
        ///   - ignoreEos: Whether to ignore EOS token
        ///   - nProbs: Number of top probabilities to return
        ///   - stopSequences: Stop sequences
        ///   - grammar: Grammar for constrained generation
        ///   - tokenCallback: Token streaming callback
        public init(prompt: String,
                    nPredict: Int32 = 128,
                    nThreads: Int32 = 4,
                    seed: Int32 = -1,
                    temperature: Double = 0.8,
                    topK: Int32 = 40,
                    topP: Double = 0.9,
                    minP: Double = 0.05,
                    typicalP: Double = 1.0,
                    penaltyLastN: Int32 = 64,
                    penaltyRepeat: Double = 1.1,
                    penaltyFreq: Double = 0.0,
                    penaltyPresent: Double = 0.0,
                    mirostat: Int32 = 0,
                    mirostatTau: Double = 5.0,
                    mirostatEta: Double = 0.1,
                    ignoreEos: Bool = false,
                    nProbs: Int32 = 0,
                    stopSequences: [String] = [],
                    grammar: String? = nil,
                    tokenCallback: TokenCallback? = nil) {
            self.prompt = prompt
            self.nPredict = nPredict
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
            self.nProbs = nProbs
            self.stopSequences = stopSequences
            self.grammar = grammar
            self.tokenCallback = tokenCallback
        }
    }
    
    /// Result structure for text completion generation
    public struct CompletionResult {
        /// Generated text completion
        public let text: String
        
        /// Number of tokens predicted in the completion
        public let tokensPredicted: Int32
        
        /// Number of tokens evaluated from the prompt
        public let tokensEvaluated: Int32
        
        /// Whether the output was truncated due to context limits
        public let truncated: Bool
        
        /// Whether generation stopped at the end-of-sequence token
        public let stoppedEos: Bool
        
        /// Whether generation stopped at a stop sequence
        public let stoppedWord: Bool
        
        /// Whether generation stopped due to reaching maximum tokens limit
        public let stoppedLimit: Bool
        
        /// The stop sequence that caused generation to stop (if any)
        public let stoppingWord: String?
        
        /// Internal initializer from C API result
        /// - Parameter result: C API completion result structure
        internal init(from result: llama_mobile_completion_result_c_t) {
            self.text = String(cString: result.text)
            self.tokensPredicted = result.tokens_predicted
            self.tokensEvaluated = result.tokens_evaluated
            self.truncated = result.truncated
            self.stoppedEos = result.stopped_eos
            self.stoppedWord = result.stopped_word
            self.stoppedLimit = result.stopped_limit
            self.stoppingWord = result.stopping_word != nil ? String(cString: result.stopping_word) : nil
        }
    }
    
    /// Result structure for text tokenization
    public struct TokenizeResult {
        /// Array of token IDs representing the tokenized text
        public let tokens: [Int32]
        
        /// Whether the tokenized input contained media references
        public let hasMedia: Bool
        
        /// Hashes of processed bitmap media
        public let bitmapHashes: [String]
        
        /// Positions of text chunks in the token array
        public let chunkPositions: [Int]
        
        /// Positions of media chunks in the token array
        public let chunkPositionsMedia: [Int]
        
        /// Internal initializer from C API result
        /// - Parameter result: C API tokenization result structure
        internal init(from result: llama_mobile_tokenize_result_c_t) {
            // Convert tokens
            self.tokens = result.tokens.tokens != nil && result.tokens.count > 0 ? 
                Array(UnsafeBufferPointer(start: result.tokens.tokens, count: Int(result.tokens.count))) : []
            
            self.hasMedia = result.has_media
            
            // Convert bitmap hashes
            var hashes: [String] = []
            if let bitmapHashes = result.bitmap_hashes {
                for i in 0..<Int(result.bitmap_hash_count) {
                    if let hash = bitmapHashes[Int(i)] {
                        hashes.append(String(cString: hash))
                    }
                }
            }
            self.bitmapHashes = hashes
            
            // Convert chunk positions
            var positions: [Int] = []
            if let chunkPositions = result.chunk_positions {
                for i in 0..<Int(result.chunk_position_count) {
                    positions.append(Int(chunkPositions[Int(i)]))
                }
            }
            self.chunkPositions = positions
            
            // Convert media chunk positions
            var mediaPositions: [Int] = []
            if let chunkPositionsMedia = result.chunk_positions_media {
                for i in 0..<Int(result.chunk_position_media_count) {
                    mediaPositions.append(Int(chunkPositionsMedia[Int(i)]))
                }
            }
            self.chunkPositionsMedia = mediaPositions
        }
    }
    
    /// Structure for LoRA (Low-Rank Adaptation) adapter configuration
    public struct LoraAdapter {
        /// Path to the LoRA adapter file (.lora or .bin)
        public let path: String
        
        /// Scaling factor for the LoRA adapter (1.0 = default)
        public let scale: Float
        
        /// Initializes a LoRA adapter configuration
        /// - Parameters:
        ///   - path: Path to LoRA adapter file
        ///   - scale: Scaling factor (default: 1.0)
        public init(path: String, scale: Float = 1.0) {
            self.path = path
            self.scale = scale
        }
    }
    
    // MARK: - Properties
    
    private var contextHandle: llama_mobile_context_handle_t?
    
    // MARK: - Initialization
    
    /// Creates a new instance of the LlamaMobile SDK
    /// 
    /// This initializes the basic resources needed for the SDK. You must call `initialize(with:)` 
    /// with valid model parameters before using most functionality.
    public init() {
        // Initialize any necessary resources
    }
    
    /// Cleans up resources when the instance is deallocated
    /// 
    /// Frees the underlying model context if it was created, ensuring proper memory management.
    deinit {
        if let handle = contextHandle {
            llama_mobile_free_context_c(handle)
        }
    }
    
    /// Initializes the model with the specified parameters
    /// 
    /// This function loads the model from disk and prepares it for inference. It must be called 
    /// before generating completions, embeddings, or using any other model functionality.
    /// 
    /// - Parameter params: A structure containing all model initialization parameters
    /// - Returns: `true` if initialization succeeded, `false` otherwise
    /// 
    /// - Note: Currently, the progress callback is disabled to avoid closure capture issues. 
    /// This may be revisited in future versions with a proper context management solution.
    /// 
    /// Example:
    /// ```swift
    /// let initParams = LlamaMobile.InitParams(
    ///     modelPath: "/path/to/model.gguf",
    ///     nCtx: 2048,
    ///     nGpuLayers: 4,
    ///     nThreads: 4
    /// )
    /// 
    /// if llamaMobile.initialize(with: initParams) {
    ///     print("Model loaded successfully!")
    /// } else {
    ///     print("Failed to load model")
    /// }
    /// ```
    public func initialize(with params: InitParams) -> Bool {
        // For now, we'll disable the progress callback to avoid closure capture issues
        // This can be revisited later with a proper context management solution
        
        return params.modelPath.withCString { modelPathPtr in
            // Create C-compatible init params
            var cParams = llama_mobile_init_params_c_t()
            cParams.model_path = modelPathPtr
            cParams.n_ctx = params.nCtx
            cParams.n_batch = params.nBatch
            cParams.n_ubatch = params.nUbatch
            cParams.n_gpu_layers = params.nGpuLayers
            cParams.n_threads = params.nThreads
            cParams.use_mmap = params.useMmap
            cParams.use_mlock = params.useMlock
            cParams.embedding = params.embedding
            cParams.pooling_type = params.poolingType
            cParams.embd_normalize = params.embdNormalize
            cParams.flash_attn = params.flashAttn
            cParams.progress_callback = nil // Disable callback for now
            
            // Handle optional chat template
            if let chatTemplate = params.chatTemplate {
                chatTemplate.withCString { chatTemplatePtr in
                    cParams.chat_template = chatTemplatePtr
                    
                    // Handle optional cache types
                    if let cacheTypeK = params.cacheTypeK {
                        cacheTypeK.withCString { cacheTypeKPtr in
                            cParams.cache_type_k = cacheTypeKPtr
                            
                            if let cacheTypeV = params.cacheTypeV {
                                cacheTypeV.withCString { cacheTypeVPtr in
                                    cParams.cache_type_v = cacheTypeVPtr
                                    contextHandle = llama_mobile_init_context_c(&cParams)
                                }
                            } else {
                                cParams.cache_type_v = nil
                                contextHandle = llama_mobile_init_context_c(&cParams)
                            }
                        }
                    } else {
                        cParams.cache_type_k = nil
                        
                        if let cacheTypeV = params.cacheTypeV {
                            cacheTypeV.withCString { cacheTypeVPtr in
                                cParams.cache_type_v = cacheTypeVPtr
                                contextHandle = llama_mobile_init_context_c(&cParams)
                            }
                        } else {
                            cParams.cache_type_v = nil
                            contextHandle = llama_mobile_init_context_c(&cParams)
                        }
                    }
                }
            } else {
                cParams.chat_template = nil
                
                // Handle optional cache types
                if let cacheTypeK = params.cacheTypeK {
                    cacheTypeK.withCString { cacheTypeKPtr in
                        cParams.cache_type_k = cacheTypeKPtr
                        
                        if let cacheTypeV = params.cacheTypeV {
                            cacheTypeV.withCString { cacheTypeVPtr in
                                cParams.cache_type_v = cacheTypeVPtr
                                contextHandle = llama_mobile_init_context_c(&cParams)
                            }
                        } else {
                            cParams.cache_type_v = nil
                            contextHandle = llama_mobile_init_context_c(&cParams)
                        }
                    }
                } else {
                    cParams.cache_type_k = nil
                    
                    if let cacheTypeV = params.cacheTypeV {
                        cacheTypeV.withCString { cacheTypeVPtr in
                            cParams.cache_type_v = cacheTypeVPtr
                            contextHandle = llama_mobile_init_context_c(&cParams)
                        }
                    } else {
                        cParams.cache_type_v = nil
                        contextHandle = llama_mobile_init_context_c(&cParams)
                    }
                }
            }
            
            return contextHandle != nil
        }
    }
    
    // MARK: - Completion
    
    /// Generates text completion for a given prompt
    /// 
    /// This function generates a completion for the provided prompt using the loaded model. It supports
    /// various sampling parameters to control the generation process and can handle stop sequences
    /// and grammar constraints.
    /// 
    /// - Parameter params: A structure containing all completion generation parameters
    /// - Returns: A `CompletionResult` object with the generated text and metadata, or `nil` if generation failed
    /// 
    /// Example:
    /// ```swift
    /// let completionParams = LlamaMobile.CompletionParams(
    ///     prompt: "Explain quantum computing in simple terms",
    ///     nPredict: 256,
    ///     temperature: 0.7,
    ///     topK: 40,
    ///     topP: 0.9,
    ///     stopSequences: ["\n\n"]
    /// )
    /// 
    /// if let result = llamaMobile.completion(with: completionParams) {
    ///     print("Completion: \(result.text)")
    ///     print("Tokens predicted: \(result.tokensPredicted)")
    ///     print("Stopped at EOS: \(result.stoppedEos)")
    /// }
    /// ```
    public func completion(with params: CompletionParams) -> CompletionResult? {
        guard let handle = contextHandle else {
            return nil
        }
        
        return params.prompt.withCString { promptPtr in
            // Create C-compatible completion params
            var cParams = llama_mobile_completion_params_c_t()
            cParams.prompt = promptPtr
            cParams.n_predict = params.nPredict
            cParams.n_threads = params.nThreads
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
            cParams.n_probs = params.nProbs
            
            // Set up stop sequences
            var stopSequenceCStrings: [UnsafePointer<CChar>?] = []
            for sequence in params.stopSequences {
                stopSequenceCStrings.append(sequence.cString(using: .utf8))
            }
            stopSequenceCStrings.append(nil)
            
            cParams.stop_sequences = stopSequenceCStrings.withUnsafeMutableBufferPointer { 
                $0.baseAddress
            }
            cParams.stop_sequence_count = Int32(params.stopSequences.count)
            
            // Set up grammar
            if let grammar = params.grammar {
                return grammar.withCString { grammarPtr in
                    cParams.grammar = grammarPtr
                    
                    // Perform completion
                    var cResult = llama_mobile_completion_result_c_t()
                    let status = llama_mobile_completion_c(handle, &cParams, &cResult)
                    
                    if status == 0 {
                        // Create result object
                        let result = CompletionResult(from: cResult)
                        
                        // Free C result members
                        llama_mobile_free_completion_result_members_c(&cResult)
                        
                        return result
                    } else {
                        return nil
                    }
                }
            } else {
                cParams.grammar = nil
                
                // Perform completion
                var cResult = llama_mobile_completion_result_c_t()
                let status = llama_mobile_completion_c(handle, &cParams, &cResult)
                
                if status == 0 {
                    // Create result object
                    let result = CompletionResult(from: cResult)
                    
                    // Free C result members
                    llama_mobile_free_completion_result_members_c(&cResult)
                    
                    return result
                } else {
                    return nil
                }
            }
        }
    }
    
    // MARK: - Vocoder & TTS
    
    /// Initializes the vocoder for text-to-speech functionality
    /// 
    /// The vocoder converts text to speech by generating audio from generated tokens. This function must be called
    /// before using any TTS-related functionality. You'll need a separate vocoder model file (usually ending with .bin)
    /// to enable this feature.
    /// 
    /// - Parameter modelPath: Path to the vocoder model file on disk
    /// - Returns: `true` if vocoder initialization succeeded, `false` otherwise
    /// 
    /// Example:
    /// ```swift
    /// let vocoderPath = "/path/to/vocoder/model.bin"
    /// if llamaMobile.initializeVocoder(modelPath: vocoderPath) {
    ///     print("Vocoder initialized successfully")
    /// }
    /// ```
    public func initializeVocoder(modelPath: String) -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        let status = llama_mobile_init_vocoder_c(handle, modelPath.cString(using: .utf8))
        return status == 0
    }
    
    /// Checks if the vocoder is enabled and ready for use
    /// 
    /// This function returns the current state of the vocoder. You should call this before attempting
    /// to use any TTS functionality to ensure the vocoder is properly initialized.
    /// 
    /// - Returns: `true` if the vocoder is enabled and ready, `false` otherwise
    /// 
    /// Example:
    /// ```swift
    /// if llamaMobile.isVocoderEnabled() {
    ///     // TTS functionality is available
    ///     generateSpeech(text: "Hello world")
    /// } else {
    ///     // Need to initialize vocoder first
    ///     initializeVocoder(modelPath: vocoderPath)
    /// }
    /// ```
    public func isVocoderEnabled() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_is_vocoder_enabled_c(handle)
    }
    
    /// Gets the type of TTS (Text-to-Speech) supported by the loaded model
    /// 
    /// This function returns an integer representing the TTS type. The specific values are defined by
    /// the underlying Llama model implementation and indicate the TTS architecture or capabilities.
    /// 
    /// - Returns: An integer representing the TTS type, or -1 if TTS is not available
    /// 
    /// Example:
    /// ```swift
    /// let ttsType = llamaMobile.getTtsType()
    /// if ttsType != -1 {
    ///     print("TTS type: \(ttsType)")
    /// }
    /// ```
    public func getTtsType() -> Int32 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_tts_type_c(handle)
    }
    
    /// Gets formatted audio completion for text-to-speech generation
    /// 
    /// This function prepares text for TTS generation by formatting it according to the model's requirements.
    /// It returns a formatted string that can be used to generate speech tokens.
    /// 
    /// - Parameters:
    ///   - speakerJsonStr: Optional JSON string containing speaker configuration parameters (voice, speed, etc.)
    ///   - textToSpeak: The text to convert to speech
    /// - Returns: A formatted string ready for TTS generation, or `nil` if formatting failed
    /// 
    /// Example:
    /// ```swift
    /// let textToSpeak = "Hello, how are you today?"
    /// if let formattedText = llamaMobile.getFormattedAudioCompletion(textToSpeak: textToSpeak) {
    ///     // Use formattedText to generate speech tokens
    ///     print("Formatted text: \(formattedText)")
    /// }
    /// ```
    public func getFormattedAudioCompletion(speakerJsonStr: String? = nil, textToSpeak: String) -> String? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let cString = llama_mobile_get_formatted_audio_completion_c(handle, speakerJsonStr?.cString(using: .utf8), textToSpeak.cString(using: .utf8))
        guard let cString = cString else {
            return nil
        }
        
        let result = String(cString: cString)
        llama_mobile_free_string_c(cString)
        
        return result
    }
    
    /// Decodes audio tokens into raw audio data
    /// 
    /// This function takes a sequence of audio tokens and converts them into raw audio samples.
    /// The returned array contains floating-point audio samples that can be played back or further processed.
    /// 
    /// - Parameter tokens: Array of audio tokens to decode
    /// - Returns: An array of floating-point audio samples, or `nil` if decoding failed
    /// 
    /// Example:
    /// ```swift
    /// // Assume we've generated audio tokens
    /// let audioTokens: [Int32] = generateAudioTokens()
    /// 
    /// if let audioSamples = llamaMobile.decodeAudioTokens(tokens: audioTokens) {
    ///     // Process or play back the audio samples
    ///     print("Audio samples count: \(audioSamples.count)")
    ///     playAudioSamples(samples: audioSamples)
    /// }
    /// ```
    public func decodeAudioTokens(tokens: [Int32]) -> [Float]? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let audioData = llama_mobile_decode_audio_tokens_c(handle, tokens, Int32(tokens.count))
        
        guard audioData.count > 0, let values = audioData.values else {
            return nil
        }
        
        // Convert to Swift array
        let floatArray = Array<Float>(UnsafeBufferPointer(start: values, count: Int(audioData.count)))
        
        // Free the C array
        llama_mobile_free_float_array_c(audioData)
        
        return floatArray
    }
    
    /// Releases the vocoder resources
    /// 
    /// This function frees the memory and resources allocated for the vocoder. Call this when you're done
    /// using TTS functionality to ensure proper cleanup.
    /// 
    /// Example:
    /// ```swift
    /// // When done with TTS functionality
    /// llamaMobile.releaseVocoder()
    /// print("Vocoder resources released")
    /// ```
    public func releaseVocoder() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_release_vocoder_c(handle)
    }
    
    // MARK: - Tokenization
    
    /// Tokenizes text into integer tokens
    /// 
    /// This function converts natural language text into an array of integer tokens that the model can process.
    /// Tokenization is the first step in generating completions or embeddings.
    /// 
    /// - Parameter text: The text to tokenize
    /// - Returns: An array of integer tokens representing the text, or `nil` if tokenization failed
    /// 
    /// Example:
    /// ```swift
    /// let text = "Hello, world!"
    /// if let tokens = llamaMobile.tokenize(text: text) {
    ///     print("Tokens: \(tokens)")
    ///     print("Token count: \(tokens.count)")
    /// }
    /// ```
    public func tokenize(text: String) -> [Int32]? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let tokenArray = llama_mobile_tokenize_c(handle, text)
        
        guard tokenArray.count > 0, let tokens = tokenArray.tokens else {
            return nil
        }
        
        // Convert to Swift array
        let result = Array<Int32>(UnsafeBufferPointer(start: tokens, count: Int(tokenArray.count)))
        
        // Free the C array
        llama_mobile_free_token_array_c(tokenArray)
        
        return result
    }
    
    /// Tokenizes text with media references into tokens
    /// 
    /// This function tokenizes text that may reference media files (images, audio). It processes both the text
    /// and the media files, returning a comprehensive tokenization result that includes token positions and media metadata.
    /// 
    /// - Parameters:
    ///   - text: The text to tokenize, which may reference media files
    ///   - mediaPaths: Array of file paths to media files (images, audio) to include in tokenization
    /// - Returns: A `TokenizeResult` object containing tokens, media information, and token positions, or `nil` if tokenization failed
    /// 
    /// Example:
    /// ```swift
    /// let text = "Describe this image"
    /// let imagePath = "/path/to/image.jpg"
    /// if let tokenizeResult = llamaMobile.tokenizeWithMedia(text: text, mediaPaths: [imagePath]) {
    ///     print("Tokens: \(tokenizeResult.tokens)")
    ///     print("Has media: \(tokenizeResult.hasMedia)")
    ///     print("Bitmap hashes: \(tokenizeResult.bitmapHashes)")
    /// }
    /// ```
    public func tokenizeWithMedia(text: String, mediaPaths: [String]) -> TokenizeResult? {
        guard let handle = contextHandle else {
            return nil
        }
        
        // Convert media paths to C strings
        var mediaPathCStrings: [UnsafePointer<CChar>?] = []
        for path in mediaPaths {
            mediaPathCStrings.append(path.cString(using: .utf8))
        }
        
        // We need to use withUnsafeMutableBufferPointer for mutable pointer
        var result = text.withCString { textPtr in
            mediaPathCStrings.withUnsafeMutableBufferPointer { mediaPathsPtr in
                llama_mobile_tokenize_with_media_c(handle, textPtr, mediaPathsPtr.baseAddress, Int32(mediaPaths.count))
            }
        }
        
        // Create Swift result
        let tokenizeResult = TokenizeResult(from: result)
        
        // Free C result
        llama_mobile_free_tokenize_result_c(&result)
        
        return tokenizeResult
    }
    
    /// Detokenizes integer tokens back into text
    /// 
    /// This function converts an array of integer tokens back into natural language text. It's the inverse operation
    /// of tokenization and is used to convert model outputs back into human-readable text.
    /// 
    /// - Parameter tokens: An array of integer tokens to detokenize
    /// - Returns: The detokenized text, or `nil` if detokenization failed
    /// 
    /// Example:
    /// ```swift
    /// let tokens: [Int32] = [15339, 7889, 29991] // Example tokens for "Hello world"
    /// if let text = llamaMobile.detokenize(tokens: tokens) {
    ///     print("Detokenized text: \(text)")
    /// }
    /// ```
    public func detokenize(tokens: [Int32]) -> String? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let cString = llama_mobile_detokenize_c(handle, tokens, Int32(tokens.count))
        guard let cString = cString else {
            return nil
        }
        
        let result = String(cString: cString)
        llama_mobile_free_string_c(cString)
        
        return result
    }
    
    /// Sets guide tokens for generation guidance
    /// 
    /// Guide tokens are used to influence the generation process by providing a sequence of tokens that
    /// the model should follow or be guided by. This can be useful for controlling the style or content of generated text.
    /// 
    /// - Parameter tokens: An array of integer tokens to use as guidance
    /// 
    /// Example:
    /// ```swift
    /// // Set guide tokens to influence generation
    /// let guideText = "In a world where"
    /// if let guideTokens = llamaMobile.tokenize(text: guideText) {
    ///     llamaMobile.setGuideTokens(tokens: guideTokens)
    ///     print("Guide tokens set successfully")
    /// }
    /// ```
    public func setGuideTokens(tokens: [Int32]) {
        guard let handle = contextHandle else {
            return
        }
        
        tokens.withUnsafeBufferPointer { tokensPtr in
            llama_mobile_set_guide_tokens_c(handle, tokensPtr.baseAddress, Int32(tokens.count))
        }
    }
    
    // MARK: - Embeddings
    
    /// Generates text embeddings for the given text
    /// 
    /// Embeddings are numerical representations of text that capture semantic meaning. They can be used for
    /// various tasks like text similarity comparison, clustering, search, and recommendation systems. The embedding
    /// consists of an array of floating-point values that represent the text in a high-dimensional space.
    /// 
    /// - Note: You must enable embeddings during model initialization by setting `embedding: true` in `InitParams`
    /// for this function to work correctly.
    /// 
    /// - Parameter text: The text to generate embeddings for
    /// - Returns: An array of floating-point values representing the text embedding, or `nil` if embedding generation failed
    /// 
    /// Example:
    /// ```swift
    /// // First, initialize model with embeddings enabled
    /// let initParams = LlamaMobile.InitParams(
    ///     modelPath: "/path/to/model.gguf",
    ///     nCtx: 2048,
    ///     embedding: true // Enable embeddings
    /// )
    /// 
    /// if llamaMobile.initialize(with: initParams) {
    ///     let text1 = "The cat sat on the mat"
    ///     let text2 = "A feline rested on a rug"
    ///     
    ///     if let embedding1 = llamaMobile.embedding(text: text1),
    ///        let embedding2 = llamaMobile.embedding(text: text2) {
    ///         // Calculate similarity between embeddings
    ///         let similarity = cosineSimilarity(embedding1, embedding2)
    ///         print("Text similarity: \(similarity)")
    ///     }
    /// }
    /// ```
    public func embedding(text: String) -> [Float]? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let floatArray = llama_mobile_embedding_c(handle, text)
        
        guard floatArray.count > 0, let values = floatArray.values else {
            return nil
        }
        
        // Convert to Swift array
        let result = Array<Float>(UnsafeBufferPointer(start: values, count: Int(floatArray.count)))
        
        // Free the C array
        llama_mobile_free_float_array_c(floatArray)
        
        return result
    }
    
    // MARK: - Multimodal
    
    public func initMultimodal(mmprojPath: String, useGPU: Bool) -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        let status = mmprojPath.withCString { pathPtr in
            llama_mobile_init_multimodal_c(handle, pathPtr, useGPU)
        }
        
        return status == 0
    }
    
    public func isMultimodalEnabled() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_is_multimodal_enabled_c(handle)
    }
    
    public func supportsVision() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_supports_vision_c(handle)
    }
    
    public func supportsAudio() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_supports_audio_c(handle)
    }
    
    public func releaseMultimodal() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_release_multimodal_c(handle)
    }
    
    /// Generates text completion for a prompt with multimodal inputs (images/audio)
    /// 
    /// This function enables generating completions that incorporate media inputs (images, audio) 
    /// alongside text prompts. It requires that the model has multimodal capabilities enabled
    /// and that you have initialized multimodal support with `initMultimodal(mmprojPath:useGPU:)`. 
    /// 
    /// - Parameters:
    ///   - params: A structure containing all completion generation parameters
    ///   - mediaPaths: An array of file paths to media files (images, audio) to include in the completion
    /// - Returns: A `CompletionResult` object with the generated text and metadata, or `nil` if generation failed
    /// 
    /// Example:
    /// ```swift
    /// // First initialize multimodal support
    /// let success = llamaMobile.initMultimodal(mmprojPath: "/path/to/mmproj.bin", useGPU: true)
    /// 
    /// if success {
    ///     // Create completion parameters
    ///     let completionParams = LlamaMobile.CompletionParams(
    ///         prompt: "Describe what's in this image",
    ///         nPredict: 256,
    ///         temperature: 0.7
    ///     )
    ///     
    ///     // Generate multimodal completion
    ///     let imagePath = "/path/to/your/image.jpg"
    ///     if let result = llamaMobile.multimodalCompletion(with: completionParams, mediaPaths: [imagePath]) {
    ///         print("Image description: \(result.text)")
    ///     }
    /// }
    /// ```
    public func multimodalCompletion(with params: CompletionParams, mediaPaths: [String]) -> CompletionResult? {
        guard let handle = contextHandle else {
            return nil
        }
        
        // Convert media paths to C strings
        var mediaPathCStrings: [UnsafePointer<CChar>?] = []
        for path in mediaPaths {
            mediaPathCStrings.append(path.cString(using: .utf8))
        }
        
        return params.prompt.withCString { promptPtr in
            // Create C-compatible completion params
            var cParams = llama_mobile_completion_params_c_t()
            cParams.prompt = promptPtr
            cParams.n_predict = params.nPredict
            cParams.n_threads = params.nThreads
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
            cParams.n_probs = params.nProbs
            
            // Set up stop sequences
            var stopSequenceCStrings: [UnsafePointer<CChar>?] = []
            for sequence in params.stopSequences {
                stopSequenceCStrings.append(sequence.cString(using: .utf8))
            }
            stopSequenceCStrings.append(nil)
            
            cParams.stop_sequences = stopSequenceCStrings.withUnsafeMutableBufferPointer { 
                $0.baseAddress
            }
            cParams.stop_sequence_count = Int32(params.stopSequences.count)
            
            // Set up grammar
            if let grammar = params.grammar {
                return grammar.withCString { grammarPtr in
                    cParams.grammar = grammarPtr
                    
                    // Perform multimodal completion
                    var cResult = llama_mobile_completion_result_c_t()
                    let status = mediaPathCStrings.withUnsafeMutableBufferPointer { mediaPathsPtr in
                        llama_mobile_multimodal_completion_c(handle, &cParams, mediaPathsPtr.baseAddress, Int32(mediaPaths.count), &cResult)
                    }
                    
                    if status == 0 {
                        // Create result object
                        let result = CompletionResult(from: cResult)
                        
                        // Free C result members
                        llama_mobile_free_completion_result_members_c(&cResult)
                        
                        return result
                    } else {
                        return nil
                    }
                }
            } else {
                cParams.grammar = nil
                
                // Perform multimodal completion
                var cResult = llama_mobile_completion_result_c_t()
                let status = mediaPathCStrings.withUnsafeMutableBufferPointer { mediaPathsPtr in
                    llama_mobile_multimodal_completion_c(handle, &cParams, mediaPathsPtr.baseAddress, Int32(mediaPaths.count), &cResult)
                }
                
                if status == 0 {
                    // Create result object
                    let result = CompletionResult(from: cResult)
                    
                    // Free C result members
                    llama_mobile_free_completion_result_members_c(&cResult)
                    
                    return result
                } else {
                    return nil
                }
            }
        }
    }
    
    // MARK: - LoRA Adapters
    
    /// Applies LoRA (Low-Rank Adaptation) adapters to the model
    /// 
    /// LoRA adapters are small, lightweight models that modify the behavior of the base model without
    /// retraining it entirely. This allows you to fine-tune the model for specific tasks or domains
    /// with minimal computational resources.
    /// 
    /// - Parameter adapters: An array of LoRA adapter configurations
    /// - Returns: `true` if adapters were applied successfully, `false` otherwise
    /// 
    /// Example:
    /// ```swift
    /// // Apply a single LoRA adapter
    /// let adapter = LlamaMobile.LoraAdapter(
    ///     path: "/path/to/financial-adapter.lora",
    ///     scale: 0.8
    /// )
    /// 
    /// if llamaMobile.applyLoraAdapters(adapters: [adapter]) {
    ///     print("LoRA adapter applied successfully")
    ///     // Generate completions with the adapted model
    ///     let result = llamaMobile.completion(with: completionParams)
    /// }
    /// 
    /// // Apply multiple adapters with different scales
    /// let adapters = [
    ///     LlamaMobile.LoraAdapter(path: "/path/to/financial.lora", scale: 0.5),
    ///     LlamaMobile.LoraAdapter(path: "/path/to/creative.lora", scale: 0.5)
    /// ]
    /// 
    /// if llamaMobile.applyLoraAdapters(adapters: adapters) {
    ///     print("Multiple LoRA adapters applied successfully")
    /// }
    /// ```
    public func applyLoraAdapters(adapters: [LoraAdapter]) -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        // Convert Swift adapters to C adapters
        var cAdapters: [llama_mobile_lora_adapter_c_t] = []
        for adapter in adapters {
            var cAdapter = llama_mobile_lora_adapter_c_t()
            adapter.path.withCString { pathPtr in
                cAdapter.path = pathPtr
                cAdapter.scale = adapter.scale
                cAdapters.append(cAdapter)
            }
        }
        
        var cAdaptersStruct = llama_mobile_lora_adapters_c_t()
        cAdaptersStruct.adapters = cAdapters.withUnsafeMutableBufferPointer { $0.baseAddress }
        cAdaptersStruct.count = Int32(adapters.count)
        
        let status = llama_mobile_apply_lora_adapters_c(handle, &cAdaptersStruct)
        return status == 0
    }
    
    /// Removes all currently applied LoRA adapters from the model
    /// 
    /// This function disables all LoRA adapters that are currently active on the model, returning it
    /// to its original state. This is useful when you want to switch between different LoRA adapters
    /// or temporarily disable adaptation.
    /// 
    /// Example:
    /// ```swift
    /// // Apply some LoRA adapters
    /// llamaMobile.applyLoraAdapters(adapters: [adapter1, adapter2])
    /// 
    /// // Generate completions with adapted model
    /// let adaptedResult = llamaMobile.completion(with: completionParams)
    /// 
    /// // Remove adapters to return to base model
    /// llamaMobile.removeLoraAdapters()
    /// 
    /// // Generate completions with base model
    /// let baseResult = llamaMobile.completion(with: completionParams)
    /// ```
    public func removeLoraAdapters() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_remove_lora_adapters_c(handle)
    }
    
    /// Retrieves a list of currently loaded LoRA adapters
    /// 
    /// This function returns an array of all LoRA adapters that are currently applied to the model.
    /// It can be used to check which adapters are active and their configured scales.
    /// 
    /// - Returns: An array of `LoraAdapter` objects representing the currently loaded adapters
    /// 
    /// Example:
    /// ```swift
    /// // Apply some LoRA adapters
    /// let adapters = [
    ///     LlamaMobile.LoraAdapter(path: "/path/to/financial.lora", scale: 0.8),
    ///     LlamaMobile.LoraAdapter(path: "/path/to/creative.lora", scale: 0.5)
    /// ]
    /// llamaMobile.applyLoraAdapters(adapters: adapters)
    /// 
    /// // Get loaded adapters
    /// let loadedAdapters = llamaMobile.getLoadedLoraAdapters()
    /// print("Loaded LoRA adapters: \(loadedAdapters.count)")
    /// 
    /// for (index, adapter) in loadedAdapters.enumerated() {
    ///     print("Adapter \(index + 1): Path = \(adapter.path), Scale = \(adapter.scale)")
    /// }
    /// ```
    public func getLoadedLoraAdapters() -> [LoraAdapter] {
        guard let handle = contextHandle else {
            return []
        }
        
        var cAdapters = llama_mobile_get_loaded_lora_adapters_c(handle)
        
        // Convert to Swift array
        var adapters: [LoraAdapter] = []
        if cAdapters.count > 0, let cAdapterArray = cAdapters.adapters {
            for i in 0..<Int(cAdapters.count) {
                let cAdapter = cAdapterArray[i]
                if let path = cAdapter.path {
                    adapters.append(LoraAdapter(path: String(cString: path), scale: cAdapter.scale))
                }
            }
        }
        
        // Free C adapters
        llama_mobile_free_lora_adapters_c(&cAdapters)
        
        return adapters
    }
    
    // MARK: - Chat Template Support
    
    public func validateChatTemplate(useJinja: Bool, name: String) -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return name.withCString { namePtr in
            llama_mobile_validate_chat_template_c(handle, useJinja, namePtr)
        }
    }
    
    public func getFormattedChat(messages: String, chatTemplate: String?) -> String? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let cString = messages.withCString { messagesPtr in
            llama_mobile_get_formatted_chat_c(handle, messagesPtr, chatTemplate?.cString(using: .utf8))
        }
        
        guard let cString = cString else {
            return nil
        }
        
        let result = String(cString: cString)
        llama_mobile_free_string_c(cString)
        
        return result
    }
    
    // MARK: - Context Management
    
    public func rewind() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_rewind_c(handle)
    }
    
    public func initSampling() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_init_sampling_c(handle)
    }
    
    // MARK: - Completion Control
    
    public func stopCompletion() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_stop_completion_c(handle)
    }
    
    public func beginCompletion() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_begin_completion_c(handle)
    }
    
    public func endCompletion() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_end_completion_c(handle)
    }
    
    public func loadPrompt() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_load_prompt_c(handle)
    }
    
    public func loadPromptWithMedia(mediaPaths: [String]) {
        guard let handle = contextHandle else {
            return
        }
        
        // Convert media paths to C strings
        var mediaPathCStrings: [UnsafePointer<CChar>?] = []
        for path in mediaPaths {
            mediaPathCStrings.append(path.cString(using: .utf8))
        }
        
        // Use withUnsafeMutableBufferPointer for mutable pointer
        mediaPathCStrings.withUnsafeMutableBufferPointer { mediaPathsPtr in
            llama_mobile_load_prompt_with_media_c(handle, mediaPathsPtr.baseAddress, Int32(mediaPaths.count))
        }
    }
    
    // MARK: - Model Information
    
    public func getNctx() -> Int32 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_n_ctx_c(handle)
    }
    
    public func getNEmbd() -> Int32 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_n_embd_c(handle)
    }
    
    public func getModelDesc() -> String? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let cString = llama_mobile_get_model_desc_c(handle)
        guard let cString = cString else {
            return nil
        }
        
        let result = String(cString: cString)
        llama_mobile_free_string_c(cString)
        
        return result
    }
    
    public func getModelSize() -> Int64 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_model_size_c(handle)
    }
    
    public func getModelParams() -> Int64 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_model_params_c(handle)
    }
    
    // MARK: - Conversation Management
    
    public func generateResponse(userMessage: String, maxTokens: Int32) -> String? {
        guard let handle = contextHandle else {
            return nil
        }
        
        let cString = userMessage.withCString { messagePtr in
            llama_mobile_generate_response_c(handle, messagePtr, maxTokens)
        }
        
        guard let cString = cString else {
            return nil
        }
        
        let result = String(cString: cString)
        llama_mobile_free_string_c(cString)
        
        return result
    }
    
    public func clearConversation() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_clear_conversation_c(handle)
    }
    
    public func isConversationActive() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_is_conversation_active_c(handle)
    }
}
