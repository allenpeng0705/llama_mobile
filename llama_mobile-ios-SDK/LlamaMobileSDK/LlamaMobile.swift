//
//  LlamaMobile.swift
//  LlamaMobileSDK
//
//  Created by Your Name on 2025-12-29.
//

import Foundation

public class LlamaMobile {
    
    // MARK: - Types
    
    public typealias ProgressCallback = (Float) -> Void
    public typealias TokenCallback = (String) -> Bool
    
    public struct InitParams {
        public let modelPath: String
        public let chatTemplate: String?
        public let nCtx: Int32
        public let nBatch: Int32
        public let nUbatch: Int32
        public let nGpuLayers: Int32
        public let nThreads: Int32
        public let useMmap: Bool
        public let useMlock: Bool
        public let embedding: Bool
        public let poolingType: Int32
        public let embdNormalize: Int32
        public let flashAttn: Bool
        public let cacheTypeK: String?
        public let cacheTypeV: String?
        public let progressCallback: ProgressCallback?
        
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
    
    public struct CompletionParams {
        public let prompt: String
        public let nPredict: Int32
        public let nThreads: Int32
        public let seed: Int32
        public let temperature: Double
        public let topK: Int32
        public let topP: Double
        public let minP: Double
        public let typicalP: Double
        public let penaltyLastN: Int32
        public let penaltyRepeat: Double
        public let penaltyFreq: Double
        public let penaltyPresent: Double
        public let mirostat: Int32
        public let mirostatTau: Double
        public let mirostatEta: Double
        public let ignoreEos: Bool
        public let nProbs: Int32
        public let stopSequences: [String]
        public let grammar: String?
        public let tokenCallback: TokenCallback?
        
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
    
    public struct CompletionResult {
        public let text: String
        public let tokensPredicted: Int32
        public let tokensEvaluated: Int32
        public let truncated: Bool
        public let stoppedEos: Bool
        public let stoppedWord: Bool
        public let stoppedLimit: Bool
        public let stoppingWord: String?
        
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
    
    public struct TokenizeResult {
        public let tokens: [Int32]
        public let hasMedia: Bool
        public let bitmapHashes: [String]
        public let chunkPositions: [Int]
        public let chunkPositionsMedia: [Int]
        
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
    
    public struct LoraAdapter {
        public let path: String
        public let scale: Float
        
        public init(path: String, scale: Float = 1.0) {
            self.path = path
            self.scale = scale
        }
    }
    
    // MARK: - Properties
    
    private var contextHandle: llama_mobile_context_handle_t?
    
    // MARK: - Initialization
    
    public init() {
        // Initialize any necessary resources
    }
    
    deinit {
        if let handle = contextHandle {
            llama_mobile_free_context_c(handle)
        }
    }
    
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
    
    public func initializeVocoder(modelPath: String) -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        let status = llama_mobile_init_vocoder_c(handle, modelPath.cString(using: .utf8))
        return status == 0
    }
    
    public func isVocoderEnabled() -> Bool {
        guard let handle = contextHandle else {
            return false
        }
        
        return llama_mobile_is_vocoder_enabled_c(handle)
    }
    
    public func getTtsType() -> Int32 {
        guard let handle = contextHandle else {
            return -1
        }
        
        return llama_mobile_get_tts_type_c(handle)
    }
    
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
    
    public func releaseVocoder() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_release_vocoder_c(handle)
    }
    
    // MARK: - Tokenization
    
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
    
    public func setGuideTokens(tokens: [Int32]) {
        guard let handle = contextHandle else {
            return
        }
        
        tokens.withUnsafeBufferPointer { tokensPtr in
            llama_mobile_set_guide_tokens_c(handle, tokensPtr.baseAddress, Int32(tokens.count))
        }
    }
    
    // MARK: - Embeddings
    
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
    
    public func removeLoraAdapters() {
        guard let handle = contextHandle else {
            return
        }
        
        llama_mobile_remove_lora_adapters_c(handle)
    }
    
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
