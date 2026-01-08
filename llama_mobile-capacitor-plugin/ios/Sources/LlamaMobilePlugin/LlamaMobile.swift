import Foundation
import llama_mobile

@objc public class LlamaMobile: NSObject {
    private var context: llama_mobile_context_handle_t?
    private var grammarsPath: String?
    
    @objc override public init() {
        super.init()
        // Set up grammars path if needed
        if let bundle = Bundle(for: type(of: self)) {
            grammarsPath = bundle.path(forResource: "grammars", ofType: nil)
        }
    }
    
    @objc public func initialize(_ params: [String: Any]) -> Bool {
        guard let modelPath = params["modelPath"] as? String else {
            return false
        }
        
        // Set up initialization parameters
        var initParams = llama_mobile_init_params_c_t()
        initParams.model_path = strdup(modelPath)
        
        // Set default values
        initParams.n_ctx = params["nCtx"] as? Int ?? 2048
        initParams.n_gpu_layers = params["nGpuLayers"] as? Int ?? 0
        initParams.n_threads = params["nThreads"] as? Int ?? 4
        initParams.n_batch = params["nBatch"] as? Int ?? 512
        initParams.n_ubatch = params["nUbatch"] as? Int ?? 512
        initParams.use_mmap = params["useMmap"] as? Bool ?? true
        initParams.use_mlock = params["useMlock"] as? Bool ?? false
        initParams.embedding = params["embedding"] as? Bool ?? false
        initParams.pooling_type = params["poolingType"] as? Int ?? 0
        initParams.embd_normalize = params["embdNormalize"] as? Bool ?? false
        initParams.flash_attn = params["flashAttn"] as? Bool ?? false
        
        // Optional parameters
        if let chatTemplate = params["chatTemplate"] as? String {
            initParams.chat_template = strdup(chatTemplate)
        }
        if let systemPrompt = params["systemPrompt"] as? String {
            initParams.system_prompt = strdup(systemPrompt)
        }
        if let cacheTypeK = params["cacheTypeK"] as? String {
            initParams.cache_type_k = strdup(cacheTypeK)
        }
        if let cacheTypeV = params["cacheTypeV"] as? String {
            initParams.cache_type_v = strdup(cacheTypeV)
        }
        
        // Initialize the context
        context = llama_mobile_init_context_c(&initParams)
        
        // Free allocated strings
        free(UnsafeMutableRawPointer(mutating: initParams.model_path))
        if initParams.chat_template != nil {
            free(UnsafeMutableRawPointer(mutating: initParams.chat_template))
        }
        if initParams.system_prompt != nil {
            free(UnsafeMutableRawPointer(mutating: initParams.system_prompt))
        }
        if initParams.cache_type_k != nil {
            free(UnsafeMutableRawPointer(mutating: initParams.cache_type_k))
        }
        if initParams.cache_type_v != nil {
            free(UnsafeMutableRawPointer(mutating: initParams.cache_type_v))
        }
        
        return context != nil
    }
    
    @objc public func generate(_ params: [String: Any]) -> String? {
        guard let context = context, let prompt = params["prompt"] as? String else {
            return nil
        }
        
        // Set up completion parameters
        var completionParams = llama_mobile_completion_params_c_t()
        completionParams.prompt = strdup(prompt)
        
        // Set default values
        completionParams.max_tokens = params["maxTokens"] as? Int ?? 100
        completionParams.temperature = params["temperature"] as? Double ?? 0.8
        completionParams.top_k = params["topK"] as? Int ?? 40
        completionParams.top_p = params["topP"] as? Double ?? 0.95
        completionParams.min_p = params["minP"] as? Double ?? 0.05
        completionParams.typical_p = params["typicalP"] as? Double ?? 1.0
        completionParams.seed = params["seed"] as? Int ?? -1
        completionParams.n_threads = params["nThreads"] as? Int ?? 4
        completionParams.penalty_last_n = params["penaltyLastN"] as? Int ?? 64
        completionParams.penalty_repeat = params["penaltyRepeat"] as? Double ?? 1.1
        completionParams.penalty_freq = params["penaltyFreq"] as? Double ?? 0.0
        completionParams.penalty_present = params["penaltyPresent"] as? Double ?? 0.0
        completionParams.mirostat = params["mirostat"] as? Int ?? 0
        completionParams.mirostat_tau = params["mirostatTau"] as? Double ?? 5.0
        completionParams.mirostat_eta = params["mirostatEta"] as? Double ?? 0.1
        completionParams.ignore_eos = params["ignoreEos"] as? Bool ?? false
        
        // Optional grammar
        if let grammar = params["grammar"] as? String {
            completionParams.grammar = strdup(grammar)
        }
        
        // Generate completion
        let result = llama_mobile_completion_c(context, &completionParams)
        
        // Free allocated strings
        free(UnsafeMutableRawPointer(mutating: completionParams.prompt))
        if completionParams.grammar != nil {
            free(UnsafeMutableRawPointer(mutating: completionParams.grammar))
        }
        
        guard let resultStr = result else {
            return nil
        }
        
        let output = String(cString: resultStr)
        free(UnsafeMutableRawPointer(mutating: resultStr))
        
        return output
    }
    
    @objc public func getGrammarContent(_ grammarName: String) -> String? {
        guard let grammarsPath = grammarsPath else {
            return nil
        }
        
        let grammarFileName: String
        switch grammarName {
        case "arithmetic":
            grammarFileName = "arithmetic.gbnf"
        case "c":
            grammarFileName = "c.gbnf"
        case "chess":
            grammarFileName = "chess.gbnf"
        case "english":
            grammarFileName = "english.gbnf"
        case "japanese":
            grammarFileName = "japanese.gbnf"
        case "json":
            grammarFileName = "json.gbnf"
        case "jsonArr":
            grammarFileName = "json_arr.gbnf"
        case "list":
            grammarFileName = "list.gbnf"
        default:
            return nil
        }
        
        let grammarPath = "\(grammarsPath)/\(grammarFileName)"
        do {
            return try String(contentsOfFile: grammarPath, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    @objc public func release() {
        if let context = context {
            llama_mobile_release_context_c(context)
            self.context = nil
        }
    }
}
