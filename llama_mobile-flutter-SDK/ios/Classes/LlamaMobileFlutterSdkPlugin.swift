import Flutter
import UIKit
import llama_mobile // Import the existing iOS SDK

// Swift wrapper for the llama_mobile C API
class LlamaMobileWrapper {
    private var context: llama_mobile_context_handle_t?
    
    init() {
    }
    
    deinit {
        if let context = context {
            llama_mobile_free_context_c(context)
        }
    }
    
    func initialize(with params: llama_mobile_init_params_c_t) -> Bool {
        if let context = context {
            llama_mobile_free_context_c(context)
        }
        
        // Create mutable copy for inout argument
        var mutableParams = params
        context = llama_mobile_init_context_c(&mutableParams)
        return context != nil
    }
    
    func generateCompletion(with params: llama_mobile_completion_params_c_t) -> String? {
        guard let context = context else {
            return nil
        }
        
        var result = llama_mobile_completion_result_c_t()
        // Create mutable copy for inout argument
        var mutableParams = params
        let success = llama_mobile_completion_c(context, &mutableParams, &result)
        
        if success == 0 {
            defer {
                llama_mobile_free_completion_result_members_c(&result)
            }
            
            if let text = result.text {
                return String(cString: text)
            }
        }
        
        return nil
    }
    
    func grammarContent(for name: String) -> String? {
        // Grammar content functionality not available in the current C API
        // This is a placeholder implementation
        return nil
    }
}

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {
  // Hold a reference to the LlamaMobile wrapper instance
  private var llamaMobile: LlamaMobileWrapper?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "llama_mobile_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = LlamaMobileFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "loadModel":
      handleLoadModel(call: call, result: result)
    case "initialize":
      handleInitialize(call: call, result: result)
    case "generateCompletion":
      handleGenerateCompletion(call: call, result: result)
    case "generate":
      handleGenerate(call: call, result: result)
    case "getGrammarContent":
      handleGetGrammarContent(call: call, result: result)
    case "release":
      handleRelease(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleLoadModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let modelPath = arguments["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for loadModel", details: nil))
      return
    }

    let contextSize = arguments["contextSize"] as? Int ?? 1024

    // Initialize LlamaMobile instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobileWrapper()
    }

    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile", details: nil))
      return
    }

    // Create C API init params
    let initParams = llama_mobile_init_params_c_t(
      model_path: modelPath,
      chat_template: nil,
      system_prompt: nil,
      n_ctx: Int32(contextSize),
      n_batch: 512,
      n_ubatch: 512,
      n_gpu_layers: 0,
      n_threads: 4,
      use_mmap: true,
      use_mlock: false,
      embedding: false,
      pooling_type: 0,
      embd_normalize: 0,
      flash_attn: false,
      cache_type_k: nil,
      cache_type_v: nil,
      progress_callback: nil
    )

    // Load model
    let success = llamaMobile.initialize(with: initParams)
    result(success)
  }

  private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let modelPath = arguments["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for initialize", details: nil))
      return
    }

    // Initialize LlamaMobile wrapper instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobileWrapper()
    }

    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile", details: nil))
      return
    }

    // Parse all arguments
    let nCtx = arguments["nCtx"] as? Int ?? 2048
    let nGpuLayers = arguments["nGpuLayers"] as? Int ?? 0
    let nThreads = arguments["nThreads"] as? Int ?? 4
    let nBatch = arguments["nBatch"] as? Int ?? 512
    let nUbatch = arguments["nUbatch"] as? Int ?? 512
    let useMmap = arguments["useMmap"] as? Bool ?? true
    let useMlock = arguments["useMlock"] as? Bool ?? false
    let chatTemplate = arguments["chatTemplate"] as? String
    let systemPrompt = arguments["systemPrompt"] as? String
    let embedding = arguments["embedding"] as? Bool ?? false
    let poolingType = arguments["poolingType"] as? Int ?? 0
    let embdNormalize = arguments["embdNormalize"] as? Bool ?? false
    let flashAttn = arguments["flashAttn"] as? Bool ?? false
    let cacheTypeK = arguments["cacheTypeK"] as? String
    let cacheTypeV = arguments["cacheTypeV"] as? String

    // Create C API init params
    let initParams = llama_mobile_init_params_c_t(
      model_path: modelPath,
      chat_template: chatTemplate,
      system_prompt: systemPrompt,
      n_ctx: Int32(nCtx),
      n_batch: Int32(nBatch),
      n_ubatch: Int32(nUbatch),
      n_gpu_layers: Int32(nGpuLayers),
      n_threads: Int32(nThreads),
      use_mmap: useMmap,
      use_mlock: useMlock,
      embedding: embedding,
      pooling_type: Int32(poolingType),
      embd_normalize: embdNormalize ? 1 : 0,
      flash_attn: flashAttn,
      cache_type_k: cacheTypeK,
      cache_type_v: cacheTypeV,
      progress_callback: nil
    )

    // Initialize model
    let success = llamaMobile.initialize(with: initParams)
    result(success)
  }

  private func handleGenerateCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generateCompletion", details: nil))
      return
    }

    let temperature = arguments["temperature"] as? Double ?? 0.8
    let maxTokens = arguments["maxTokens"] as? Int ?? 100

    // Create C API completion params
    let completionParams = llama_mobile_completion_params_c_t(
      prompt: prompt,
      n_predict: Int32(maxTokens),
      n_threads: 4,
      seed: -1,
      temperature: temperature,
      top_k: 40,
      top_p: 0.95,
      min_p: 0.05,
      typical_p: 1.0,
      penalty_last_n: 64,
      penalty_repeat: 1.1,
      penalty_freq: 0.0,
      penalty_present: 0.0,
      mirostat: 0,
      mirostat_tau: 5.0,
      mirostat_eta: 0.1,
      ignore_eos: false,
      n_probs: 0,
      stop_sequences: nil,
      stop_sequence_count: 0,
      grammar: nil,
      token_callback: nil
    )

    // Generate completion
    if let completionText = llamaMobile.generateCompletion(with: completionParams) {
      result(completionText)
    } else {
      result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate completion", details: nil))
    }
  }

  private func handleGenerate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generate", details: nil))
      return
    }

    // Parse all arguments
    let maxTokens = arguments["maxTokens"] as? Int ?? 100
    let temperature = arguments["temperature"] as? Double ?? 0.8
    let topK = arguments["topK"] as? Int ?? 40
    let topP = arguments["topP"] as? Double ?? 0.95
    let minP = arguments["minP"] as? Double ?? 0.05
    let typicalP = arguments["typicalP"] as? Double ?? 1.0
    let seed = arguments["seed"] as? Int ?? -1
    let nThreads = arguments["nThreads"] as? Int ?? 4
    let penaltyLastN = arguments["penaltyLastN"] as? Int ?? 64
    let penaltyRepeat = arguments["penaltyRepeat"] as? Double ?? 1.1
    let penaltyFreq = arguments["penaltyFreq"] as? Double ?? 0.0
    let penaltyPresent = arguments["penaltyPresent"] as? Double ?? 0.0
    let mirostat = arguments["mirostat"] as? Int ?? 0
    let mirostatTau = arguments["mirostatTau"] as? Double ?? 5.0
    let mirostatEta = arguments["mirostatEta"] as? Double ?? 0.1
    let ignoreEos = arguments["ignoreEos"] as? Bool ?? false
    let stopSequences = arguments["stopSequences"] as? [String] ?? []
    let grammar = arguments["grammar"] as? String

    // Create C API completion params
    let completionParams = llama_mobile_completion_params_c_t(
      prompt: prompt,
      n_predict: Int32(maxTokens),
      n_threads: Int32(nThreads),
      seed: Int32(seed),
      temperature: temperature,
      top_k: Int32(topK),
      top_p: topP,
      min_p: minP,
      typical_p: typicalP,
      penalty_last_n: Int32(penaltyLastN),
      penalty_repeat: penaltyRepeat,
      penalty_freq: penaltyFreq,
      penalty_present: penaltyPresent,
      mirostat: Int32(mirostat),
      mirostat_tau: mirostatTau,
      mirostat_eta: mirostatEta,
      ignore_eos: ignoreEos,
      n_probs: 0,
      stop_sequences: nil,  // Temporarily disabled due to conversion complexity
      stop_sequence_count: 0,
      grammar: grammar,
      token_callback: nil
    )

    // Generate completion
    if let completionText = llamaMobile.generateCompletion(with: completionParams) {
      result(completionText)
    } else {
      result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate completion", details: nil))
    }
  }

  private func handleGetGrammarContent(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let grammarNameStr = arguments["grammarName"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for getGrammarContent", details: nil))
      return
    }

    // Initialize LlamaMobile wrapper instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobileWrapper()
    }

    guard let llamaMobile = llamaMobile else {
      result(nil)
      return
    }

    // Get grammar content
    let grammarContent = llamaMobile.grammarContent(for: grammarNameStr)
    result(grammarContent)
  }

  private func handleRelease(call: FlutterMethodCall, result: @escaping FlutterResult) {
    llamaMobile = nil // This will trigger deinit and release resources
    result(nil)
  }
}
