import Flutter
import UIKit
import llama_mobile // Import the existing iOS SDK
import Darwin // For strdup and free functions

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {
  // Hold a reference to the llama_mobile context from the C API
  private var llamaMobileContext: llama_mobile_context_t?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "llama_mobile_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = LlamaMobileFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "initialize":
      handleInitialize(call: call, result: result)
    case "generate":
      handleGenerate(call: call, result: result)
    case "streamCompletion":
      handleStreamCompletion(call: call, result: result)
    case "stopCompletion":
      handleStopCompletion(call: call, result: result)
    case "tokenize":
      handleTokenize(call: call, result: result)
    case "detokenize":
      handleDetokenize(call: call, result: result)
    case "generateEmbeddingsForPrompt":
      handleGenerateEmbeddingsForPrompt(call: call, result: result)
    case "applyLoraAdapters":
      handleApplyLoraAdapters(call: call, result: result)
    case "release":
      handleRelease(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let modelPath = arguments["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for initialize", details: nil))
      return
    }

    // Parse arguments
    let nCtx = arguments["nCtx"] as? Int ?? 2048
    let nGpuLayers = arguments["nGpuLayers"] as? Int ?? 0
    let nThreads = arguments["nThreads"] as? Int ?? 4
    let useMmap = arguments["useMmap"] as? Bool ?? true
    let useMlock = arguments["useMlock"] as? Bool ?? false
    let embedding = arguments["embedding"] as? Bool ?? false
    let cacheTypeK = arguments["cacheTypeK"] as? String
    let cacheTypeV = arguments["cacheTypeV"] as? String

    // Create C API init params
    var initParams = llama_mobile_init_params_c_t(
      model_path: modelPath,
      chat_template: nil,
      system_prompt: nil,
      n_ctx: Int32(nCtx),
      n_batch: 512,
      n_ubatch: 512,
      n_gpu_layers: Int32(nGpuLayers),
      n_threads: Int32(nThreads),
      use_mmap: useMmap,
      use_mlock: useMlock,
      embedding: embedding,
      pooling_type: 0,
      embd_normalize: 0,
      flash_attn: false,
      cache_type_k: cacheTypeK,
      cache_type_v: cacheTypeV,
      progress_callback: nil
    )

    // Initialize the model using C API
    llamaMobileContext = llama_mobile_init_context_c(&initParams)

    if llamaMobileContext != nil {
      result(true)
    } else {
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile context", details: nil))
    }
  }

  private func handleGenerateCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // This method is deprecated, use handleGenerate instead
    result(FlutterError(code: "DEPRECATED_METHOD", message: "Use generate method instead", details: nil))
  }

  private func handleGenerate(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
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

    // Convert stop sequences to C-compatible format
    var stopSequencePointer: UnsafeMutablePointer<UnsafePointer<CChar>?>?
    var cStringStorage: [UnsafeMutablePointer<CChar>] = []
    
    if !stopSequences.isEmpty {
      // Allocate memory for the stop sequences array
      stopSequencePointer = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: stopSequences.count + 1)
      
      // Convert each string to C string and store in the array
        for i in 0..<stopSequences.count {
          let cString = strdup(stopSequences[i])
          cStringStorage.append(cString!)
          stopSequencePointer![i] = UnsafePointer(cString)
        }
      
      // Add null terminator
      stopSequencePointer![stopSequences.count] = nil
    }

    // Create C API completion params
    var completionParams = llama_mobile_completion_params_c_t(
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
      stop_sequences: stopSequencePointer,
      stop_sequence_count: Int32(stopSequences.count),
      grammar: grammar,
      token_callback: nil
    )

    // Generate completion using C API
    var completionResult = llama_mobile_completion_result_c_t()
    let success = llama_mobile_completion_c(llamaMobileContext, &completionParams, &completionResult) == 0
    
    // Free allocated memory for stop sequences
    if let pointer = stopSequencePointer {
      pointer.deallocate()
    }
    for cString in cStringStorage {
      free(cString)
    }
    
    if success, let textPointer = completionResult.text {
      let resultText = String(cString: textPointer)
      llama_mobile_free_completion_result_members_c(&completionResult)
      result(resultText)
    } else {
      llama_mobile_free_completion_result_members_c(&completionResult)
      result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate completion", details: nil))
    }
  }

  private func handleGetGrammarContent(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleRelease(call: FlutterMethodCall, result: @escaping FlutterResult) {
    if let context = llamaMobileContext {
      llama_mobile_free_context_c(context)
      llamaMobileContext = nil
    }
    result(nil)
  }

  private func handleGenerateResponse(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleStreamCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for streamCompletion", details: nil))
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

    // Convert stop sequences to C-compatible format
    var stopSequencePointer: UnsafeMutablePointer<UnsafePointer<CChar>?>?
    var cStringStorage: [UnsafeMutablePointer<CChar>] = []
    
    if !stopSequences.isEmpty {
      // Allocate memory for the stop sequences array
      stopSequencePointer = UnsafeMutablePointer<UnsafePointer<CChar>?>.allocate(capacity: stopSequences.count + 1)
      
      // Convert each string to C string and store in the array
      for i in 0..<stopSequences.count {
        let cString = strdup(stopSequences[i])
        cStringStorage.append(cString!)
        stopSequencePointer![i] = UnsafePointer(cString)
      }
      
      // Add null terminator
      stopSequencePointer![stopSequences.count] = nil
    }

    // Create C API completion params
    var completionParams = llama_mobile_completion_params_c_t(
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
      stop_sequences: stopSequencePointer,
      stop_sequence_count: Int32(stopSequences.count),
      grammar: grammar,
      token_callback: { token in
        // Process streaming token here
        return true
      }
    )

    // Free allocated memory for stop sequences
    if let pointer = stopSequencePointer {
      pointer.deallocate()
    }
    for cString in cStringStorage {
      free(cString)
    }

    // Use C API for streaming completion
    // Note: Streaming implementation will need to be handled with proper callback
    result(FlutterMethodNotImplemented)
  }

  private func handleStopCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    llama_mobile_stop_completion_c(llamaMobileContext)
    result(nil)
  }

  private func handleTokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for tokenize", details: nil))
      return
    }

    // Use C API for tokenization
    let tokenArray = llama_mobile_tokenize_c(llamaMobileContext, text)
    defer {
      llama_mobile_free_token_array_c(tokenArray)
    }

    if tokenArray.tokens != nil {
      var tokens = [Int]()
      for i in 0..<Int(tokenArray.count) {
        tokens.append(Int(tokenArray.tokens![i]))
      }
      result(tokens)
    } else {
      result(FlutterError(code: "TOKENIZE_FAILED", message: "Failed to tokenize text", details: nil))
    }
  }

  private func handleDetokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let tokens = arguments["tokens"] as? [Int] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for detokenize", details: nil))
      return
    }

    // Convert Swift array to C array
    let tokenCount = Int32(tokens.count)
    let tokenArray = tokens.map { Int32($0) }

    // Use C API for detokenization
    let detokenizedText = llama_mobile_detokenize_c(llamaMobileContext, tokenArray, tokenCount)
    if detokenizedText != nil {
      let resultText = String(cString: detokenizedText!)
      llama_mobile_free_string_c(detokenizedText)
      result(resultText)
    } else {
      result(FlutterError(code: "DETOKENIZE_FAILED", message: "Failed to detokenize tokens", details: nil))
    }
  }

  private func handleGenerateEmbeddings(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleGenerateEmbeddingsForPrompt(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generateEmbeddingsForPrompt", details: nil))
      return
    }

    // Use C API for embeddings
    let embeddingArray = llama_mobile_embedding_c(llamaMobileContext, prompt)
    defer {
      llama_mobile_free_float_array_c(embeddingArray)
    }

    if embeddingArray.values != nil {
      var embeddings = [Float]()
      for i in 0..<Int(embeddingArray.count) {
        embeddings.append(embeddingArray.values![i])
      }
      result(embeddings)
    } else {
      result(FlutterError(code: "EMBEDDINGS_FAILED", message: "Failed to generate embeddings for prompt", details: nil))
    }
  }

  private func handleInitMultimodal(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let mmprojPath = arguments["mmprojPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for initMultimodal", details: nil))
      return
    }

    let useGpu = arguments["useGpu"] as? Bool ?? false
    let success = llama_mobile_init_multimodal_c(llamaMobileContext, mmprojPath, useGpu) == 0
    result(success)
  }

  private func handleInitTTS(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let ttsPath = arguments["ttsPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for initTTS", details: nil))
      return
    }

    // TTS model type is handled internally in C API
    let success = llama_mobile_init_vocoder_c(llamaMobileContext, ttsPath) == 0
    result(success)
  }

  private func handleGenerateAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobileContext = llamaMobileContext else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile context not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String,
          let voice = arguments["voice"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generateAudio", details: nil))
      return
    }

    let speed = arguments["speed"] as? Double ?? 1.0
    let pitch = arguments["pitch"] as? Double ?? 1.0

    // Create speaker JSON string
    let speakerJson = "{\"voice\":\"\(voice)\",\"speed\":\(speed),\"pitch\":\(pitch)}"
    
    let audioPath = llama_mobile_get_formatted_audio_completion_c(llamaMobileContext, speakerJson, text)
    if audioPath != nil {
      let resultPath = String(cString: audioPath!)
      llama_mobile_free_string_c(audioPath)
      result(resultPath)
    } else {
      result(FlutterError(code: "AUDIO_FAILED", message: "Failed to generate audio", details: nil))
    }
  }

  private func handleApplyLoraAdapters(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  // Conversation-related methods will be implemented in the future
  private func handleCreateConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleGenerateConversationResponse(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleStreamConversationResponse(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleGetConversationHistory(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleClearConversation(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  // Download-related methods will be implemented in the future
  private func handleDownloadModel(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }

  private func handleGetVersion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    result(FlutterMethodNotImplemented)
  }
}
