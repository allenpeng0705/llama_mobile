import Flutter
import UIKit
import LlamaMobile // Import the existing iOS SDK

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {
  // Hold a reference to the LlamaMobile instance from the iOS SDK
  private var llamaMobile: LlamaMobile?

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
    case "generateResponse":
      handleGenerateResponse(call: call, result: result)
    case "streamCompletion":
      handleStreamCompletion(call: call, result: result)
    case "stopCompletion":
      handleStopCompletion(call: call, result: result)
    case "tokenize":
      handleTokenize(call: call, result: result)
    case "detokenize":
      handleDetokenize(call: call, result: result)
    case "generateEmbeddings":
      handleGenerateEmbeddings(call: call, result: result)
    case "generateEmbeddingsForPrompt":
      handleGenerateEmbeddingsForPrompt(call: call, result: result)
    case "initMultimodal":
      handleInitMultimodal(call: call, result: result)
    case "initTTS":
      handleInitTTS(call: call, result: result)
    case "generateAudio":
      handleGenerateAudio(call: call, result: result)
    case "applyLoraAdapters":
      handleApplyLoraAdapters(call: call, result: result)
    case "createConversation":
      handleCreateConversation(call: call, result: result)
    case "generateConversationResponse":
      handleGenerateConversationResponse(call: call, result: result)
    case "streamConversationResponse":
      handleStreamConversationResponse(call: call, result: result)
    case "getConversationHistory":
      handleGetConversationHistory(call: call, result: result)
    case "clearConversation":
      handleClearConversation(call: call, result: result)
    case "downloadModel":
      handleDownloadModel(call: call, result: result)
    case "getVersion":
      handleGetVersion(call: call, result: result)
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

    // Create a new LlamaMobile instance
    llamaMobile = LlamaMobile()

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

    // Create iOS SDK InitParams
    var initParams = LlamaMobile.InitParams(modelPath: modelPath)
    initParams.nCtx = Int32(nCtx)
    initParams.nGpuLayers = Int32(nGpuLayers)
    initParams.nThreads = Int32(nThreads)
    initParams.nBatch = Int32(nBatch)
    initParams.nUBatch = Int32(nUbatch)
    initParams.useMmap = useMmap
    initParams.useMlock = useMlock
    initParams.chatTemplate = chatTemplate
    initParams.systemPrompt = systemPrompt
    initParams.embedding = embedding
    initParams.poolingType = Int32(poolingType)
    initParams.embdNormalize = embdNormalize ? 1 : 0
    initParams.flashAttention = flashAttn
    initParams.cacheTypeK = cacheTypeK
    initParams.cacheTypeV = cacheTypeV

    // Initialize model
    do {
      try llamaMobile.initialize(params: initParams)
      result(true)
    } catch {
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile: \(error)", details: nil))
    }
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

    // Create iOS SDK CompletionParams
    var completionParams = LlamaMobile.CompletionParams(prompt: prompt)
    completionParams.maxTokens = Int32(maxTokens)
    completionParams.temperature = temperature
    completionParams.topK = Int32(topK)
    completionParams.topP = topP
    completionParams.minP = minP
    completionParams.typicalP = typicalP
    completionParams.seed = Int32(seed)
    completionParams.nThreads = Int32(nThreads)
    completionParams.penaltyLastN = Int32(penaltyLastN)
    completionParams.penaltyRepeat = penaltyRepeat
    completionParams.penaltyFreq = penaltyFreq
    completionParams.penaltyPresent = penaltyPresent
    completionParams.mirostat = Int32(mirostat)
    completionParams.mirostatTau = mirostatTau
    completionParams.mirostatEta = mirostatEta
    completionParams.ignoreEos = ignoreEos
    completionParams.stopSequences = stopSequences
    completionParams.grammar = grammar

    // Generate completion
    do {
      let completion = try llamaMobile.generate(params: completionParams)
      result(completion)
    } catch {
      result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate completion: \(error)", details: nil))
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

  private func handleGenerateResponse(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generateResponse", details: nil))
      return
    }

    // Parse all arguments (same as handleGenerate)
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

    // Create iOS SDK CompletionParams
    var completionParams = LlamaMobile.CompletionParams(prompt: prompt)
    completionParams.maxTokens = Int32(maxTokens)
    completionParams.temperature = temperature
    completionParams.topK = Int32(topK)
    completionParams.topP = topP
    completionParams.minP = minP
    completionParams.typicalP = typicalP
    completionParams.seed = Int32(seed)
    completionParams.nThreads = Int32(nThreads)
    completionParams.penaltyLastN = Int32(penaltyLastN)
    completionParams.penaltyRepeat = penaltyRepeat
    completionParams.penaltyFreq = penaltyFreq
    completionParams.penaltyPresent = penaltyPresent
    completionParams.mirostat = Int32(mirostat)
    completionParams.mirostatTau = mirostatTau
    completionParams.mirostatEta = mirostatEta
    completionParams.ignoreEos = ignoreEos
    completionParams.stopSequences = stopSequences
    completionParams.grammar = grammar

    // Generate detailed completion result
    do {
      let completionResult = try llamaMobile.generateResponse(params: completionParams)
      let resultDict: [String: Any] = [
        "text": completionResult.text,
        "tokensGenerated": completionResult.tokensGenerated,
        "tokensEvaluated": completionResult.tokensEvaluated,
        "truncated": completionResult.truncated,
        "stoppedEos": completionResult.stoppedEos,
        "stoppedWord": completionResult.stoppedWord,
        "stoppedLimit": completionResult.stoppedLimit
      ]
      result(resultDict)
    } catch {
      result(FlutterError(code: "GENERATION_FAILED", message: "Failed to generate response: \(error)", details: nil))
    }
  }

  private func handleStreamCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for streamCompletion", details: nil))
      return
    }

    // Parse all arguments (same as handleGenerate)
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

    // Create iOS SDK CompletionParams
    var completionParams = LlamaMobile.CompletionParams(prompt: prompt)
    completionParams.maxTokens = Int32(maxTokens)
    completionParams.temperature = temperature
    completionParams.topK = Int32(topK)
    completionParams.topP = topP
    completionParams.minP = minP
    completionParams.typicalP = typicalP
    completionParams.seed = Int32(seed)
    completionParams.nThreads = Int32(nThreads)
    completionParams.penaltyLastN = Int32(penaltyLastN)
    completionParams.penaltyRepeat = penaltyRepeat
    completionParams.penaltyFreq = penaltyFreq
    completionParams.penaltyPresent = penaltyPresent
    completionParams.mirostat = Int32(mirostat)
    completionParams.mirostatTau = mirostatTau
    completionParams.mirostatEta = mirostatEta
    completionParams.ignoreEos = ignoreEos
    completionParams.stopSequences = stopSequences
    completionParams.grammar = grammar

    // Stream completion
    do {
      let completion = try llamaMobile.streamCompletion(params: completionParams) {
        token, isDone in
        // Send token to Flutter
        result(FlutterEventSink.success(token))
        if isDone {
          result(FlutterEventSink.endOfStream)
        }
      }
      result(completion)
    } catch {
      result(FlutterError(code: "STREAM_FAILED", message: "Failed to stream completion: \(error)", details: nil))
    }
  }

  private func handleStopCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    do {
      try llamaMobile.stopCompletion()
      result(nil)
    } catch {
      result(FlutterError(code: "STOP_FAILED", message: "Failed to stop completion: \(error)", details: nil))
    }
  }

  private func handleTokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let text = arguments["text"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for tokenize", details: nil))
      return
    }

    do {
      let tokens = try llamaMobile.tokenize(text: text)
      result(tokens)
    } catch {
      result(FlutterError(code: "TOKENIZE_FAILED", message: "Failed to tokenize text: \(error)", details: nil))
    }
  }

  private func handleDetokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let tokens = arguments["tokens"] as? [Int] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for detokenize", details: nil))
      return
    }

    do {
      let text = try llamaMobile.detokenize(tokens: tokens)
      result(text)
    } catch {
      result(FlutterError(code: "DETOKENIZE_FAILED", message: "Failed to detokenize tokens: \(error)", details: nil))
    }
  }

  private func handleGenerateEmbeddings(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    do {
      let embeddings = try llamaMobile.generateEmbeddings()
      result(embeddings)
    } catch {
      result(FlutterError(code: "EMBEDDINGS_FAILED", message: "Failed to generate embeddings: \(error)", details: nil))
    }
  }

  private func handleGenerateEmbeddingsForPrompt(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let prompt = arguments["prompt"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for generateEmbeddingsForPrompt", details: nil))
      return
    }

    do {
      let embeddings = try llamaMobile.generateEmbeddingsForPrompt(prompt: prompt)
      result(embeddings)
    } catch {
      result(FlutterError(code: "EMBEDDINGS_FAILED", message: "Failed to generate embeddings for prompt: \(error)", details: nil))
    }
  }

  private func handleInitMultimodal(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    do {
      try llamaMobile.initMultimodal()
      result(true)
    } catch {
      result(FlutterError(code: "MULTIMODAL_FAILED", message: "Failed to initialize multimodal: \(error)", details: nil))
    }
  }

  private func handleInitTTS(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let ttsPath = arguments["ttsPath"] as? String,
          let modelTypeInt = arguments["modelType"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for initTTS", details: nil))
      return
    }

    let modelType = LlamaMobile.TTSModelType(rawValue: modelTypeInt)

    do {
      try llamaMobile.initTTS(ttsPath: ttsPath, modelType: modelType)
      result(true)
    } catch {
      result(FlutterError(code: "TTS_FAILED", message: "Failed to initialize TTS: \(error)", details: nil))
    }
  }

  private func handleGenerateAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
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

    do {
      let audioPath = try llamaMobile.generateAudio(text: text, voice: voice, speed: speed, pitch: pitch)
      result(audioPath)
    } catch {
      result(FlutterError(code: "AUDIO_FAILED", message: "Failed to generate audio: \(error)", details: nil))
    }
  }

  private func handleApplyLoraAdapters(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    guard let arguments = call.arguments as? [String: Any],
          let adaptersData = arguments["adapters"] as? [[String: Any]] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for applyLoraAdapters", details: nil))
      return
    }

    var adapters: [LlamaMobile.LoraAdapter] = []
    for adapterData in adaptersData {
      guard let path = adapterData["path"] as? String,
            let scale = adapterData["scale"] as? Double else {
        continue
      }
      let adapter = LlamaMobile.LoraAdapter(path: path, scale: scale)
      adapters.append(adapter)
    }

    do {
      try llamaMobile.applyLoraAdapters(adapters: adapters)
      result(true)
    } catch {
      result(FlutterError(code: "LORA_FAILED", message: "Failed to apply LoRA adapters: \(error)", details: nil))
    }
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
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call initialize first.", details: nil))
      return
    }

    do {
      let version = try llamaMobile.getVersion()
      result(version)
    } catch {
      result(FlutterError(code: "VERSION_FAILED", message: "Failed to get version: \(error)", details: nil))
    }
  }
}
