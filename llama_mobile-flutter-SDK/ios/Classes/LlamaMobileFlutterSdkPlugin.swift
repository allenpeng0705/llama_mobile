import Flutter
import UIKit

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  // Dictionary to store LlamaMobile instances
  private var contexts: [Int: LlamaMobile] = [:]
  // Counter for generating unique context handles
  private var nextContextHandle: Int = 1
  
  // Stream handlers
  private var tokenEventSink: FlutterEventSink?
  private var progressEventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "llama_mobile_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = LlamaMobileFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Register event channels for streaming
    let tokenChannel = FlutterEventChannel(name: "llama_mobile_flutter_sdk/token", binaryMessenger: registrar.messenger())
    tokenChannel.setStreamHandler(instance)
    
    let progressChannel = FlutterEventChannel(name: "llama_mobile_flutter_sdk/progress", binaryMessenger: registrar.messenger())
    progressChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initContext":
      handleInitContext(call, result: result)
    case "freeContext":
      handleFreeContext(call, result: result)
    case "generateCompletion":
      handleGenerateCompletion(call, result: result)
    case "generateMultimodalCompletion":
      handleGenerateMultimodalCompletion(call, result: result)
    case "generateConversation":
      handleGenerateConversation(call, result: result)
    case "generateStreamingCompletion":
      handleGenerateStreamingCompletion(call, result: result)
    case "generateStreamingOpenAICompletion":
      handleGenerateStreamingOpenAICompletion(call, result: result)
    case "stopCompletion":
      handleStopCompletion(call, result: result)
    case "getContextWindowSize":
      handleGetContextWindowSize(call, result: result)
    case "getEmbeddingDimension":
      handleGetEmbeddingDimension(call, result: result)
    case "getModelDescription":
      handleGetModelDescription(call, result: result)
    case "getModelSize":
      handleGetModelSize(call, result: result)
    case "getModelParametersCount":
      handleGetModelParametersCount(call, result: result)
    case "getLoadedLoraAdapters":
      handleGetLoadedLoraAdapters(call, result: result)
    case "listFiles":
      handleListFiles(call, result: result)
    case "listModels":
      handleListModels(call, result: result)
    case "downloadHfFile":
      handleDownloadHfFile(call, result: result)
    case "getJsonGrammar":
      handleGetJsonGrammar(call, result: result)
    case "getArithmeticGrammar":
      handleGetArithmeticGrammar(call, result: result)
    case "getCGrammar":
      handleGetCGrammar(call, result: result)
    case "isMultimodalEnabled":
      handleIsMultimodalEnabled(call, result: result)
    case "supportsVision":
      handleSupportsVision(call, result: result)
    case "supportsAudio":
      handleSupportsAudio(call, result: result)
    case "isVocoderEnabled":
      handleIsVocoderEnabled(call, result: result)
    case "getTTSType":
      handleGetTTSType(call, result: result)
    case "formatChatMessages":
      handleFormatChatMessages(call, result: result)

    case "loadGrammar":
      handleLoadGrammar(call, result: result)
    case "generateEmbedding":
      handleGenerateEmbedding(call, result: result)
    case "tokenize":
      handleTokenize(call, result: result)
    case "detokenize":
      handleDetokenize(call, result: result)
    case "loadLoraAdapter":
      handleLoadLoraAdapter(call, result: result)
    case "freeLoraAdapter":
      handleFreeLoraAdapter(call, result: result)
    case "loadTTSModel":
      handleLoadTTSModel(call, result: result)
    case "generateAudio":
      handleGenerateAudio(call, result: result)
    case "freeTTSModel":
      handleFreeTTSModel(call, result: result)
    case "saveAudioToWav":
      handleSaveAudioToWav(call, result: result)
    case "initMultimodal":
      handleInitMultimodal(call, result: result)
    case "downloadModel":
      handleDownloadModel(call, result: result)
    case "generateOpenAICompletion":
      handleGenerateOpenAICompletion(call, result: result)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Context Management
  private func handleInitContext(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[DEBUG] Flutter Plugin: handleInitContext called")
    guard let args = call.arguments as? [String: Any] else {
      print("[DEBUG] Flutter Plugin: Missing arguments")
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }
    
    print("[DEBUG] Flutter Plugin: Args received: \(args.description)")
    
    guard let modelPath = args["modelPath"] as? String else {
      print("[DEBUG] Flutter Plugin: Missing modelPath")
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    print("[DEBUG] Flutter Plugin: Extracting parameters")
    let chatTemplate = args["chatTemplate"] as? String
    let systemPrompt = args["systemPrompt"] as? String
    let nCtx = args["nCtx"] as? Int32 ?? 2048
    let nBatch = args["nBatch"] as? Int32 ?? 512
    let nUBatch = args["nUBatch"] as? Int32 ?? 512
    let nGpuLayers = args["nGpuLayers"] as? Int32 ?? 0
    let nThreads = args["nThreads"] as? Int32 ?? 4
    let useMmap = args["useMmap"] as? Bool ?? true
    let useMlock = args["useMlock"] as? Bool ?? false
    let embedding = args["embedding"] as? Bool ?? false
    let poolingType = args["poolingType"] as? Int32 ?? 0
    let embdNormalize = args["embdNormalize"] as? Int32 ?? 0
    let flashAttention = args["flashAttention"] as? Bool ?? false
    let cacheTypeK = args["cacheTypeK"] as? String
    let cacheTypeV = args["cacheTypeV"] as? String

    print("[DEBUG] Flutter Plugin: Creating InitParams")
    print("[DEBUG] Flutter Plugin: modelPath: \(modelPath)")
    print("[DEBUG] Flutter Plugin: chatTemplate: \(chatTemplate ?? "nil")")
    print("[DEBUG] Flutter Plugin: systemPrompt: \(systemPrompt ?? "nil")")
    print("[DEBUG] Flutter Plugin: nCtx: \(nCtx)")
    print("[DEBUG] Flutter Plugin: nBatch: \(nBatch)")
    print("[DEBUG] Flutter Plugin: nUBatch: \(nUBatch)")
    print("[DEBUG] Flutter Plugin: nGpuLayers: \(nGpuLayers)")
    print("[DEBUG] Flutter Plugin: nThreads: \(nThreads)")
    print("[DEBUG] Flutter Plugin: useMmap: \(useMmap ? 1 : 0)")
    print("[DEBUG] Flutter Plugin: useMlock: \(useMlock ? 1 : 0)")
    print("[DEBUG] Flutter Plugin: embedding: \(embedding ? 1 : 0)")
    print("[DEBUG] Flutter Plugin: poolingType: \(poolingType)")
    print("[DEBUG] Flutter Plugin: embdNormalize: \(embdNormalize)")
    print("[DEBUG] Flutter Plugin: flashAttention: \(flashAttention ? 1 : 0)")
    print("[DEBUG] Flutter Plugin: cacheTypeK: \(cacheTypeK ?? "nil")")
    print("[DEBUG] Flutter Plugin: cacheTypeV: \(cacheTypeV ?? "nil")")

    // Create InitParams like iOSSDKExample does
    var initParams = LlamaMobile.InitParams(modelPath: modelPath)
    initParams.chatTemplate = chatTemplate
    initParams.systemPrompt = systemPrompt
    initParams.nCtx = nCtx
    initParams.nBatch = nBatch
    initParams.nUBatch = nUBatch
    initParams.nGpuLayers = nGpuLayers
    initParams.nThreads = nThreads
    initParams.useMmap = useMmap
    initParams.useMlock = useMlock
    initParams.embedding = embedding
    initParams.poolingType = poolingType
    initParams.embdNormalize = embdNormalize
    initParams.flashAttention = flashAttention
    initParams.cacheTypeK = cacheTypeK
    initParams.cacheTypeV = cacheTypeV

    print("[DEBUG] Flutter Plugin: Calling LlamaMobile(with: initParams)")
    if let llamaMobile = LlamaMobile(with: initParams) {
      print("[DEBUG] Flutter Plugin: LlamaMobile instance created successfully")
      let handle = nextContextHandle
      nextContextHandle += 1
      contexts[handle] = llamaMobile
      print("[DEBUG] Flutter Plugin: Returning contextHandle: \(handle)")
      result(["contextHandle": handle])
    } else {
      print("[DEBUG] Flutter Plugin: Failed to create LlamaMobile instance")
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile context", details: nil))
    }
  }

  private func handleFreeContext(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing contextHandle", details: nil))
      return
    }

    contexts.removeValue(forKey: contextHandle)
    result(true)
  }

  // MARK: - Streaming Methods
  private func handleGenerateStreamingCompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let params = args["params"] as? [String: Any],
          let prompt = params["prompt"] as? String,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let completionParams = createCompletionParams(from: params, prompt: prompt)

    if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
        let resultDict: [String: Any] = [
            "text": completionResult.text,
            "tokensGenerated": completionResult.tokensGenerated,
            "tokensEvaluated": completionResult.tokensEvaluated,
            "truncated": completionResult.truncated,
            "stoppedEos": completionResult.stoppedEos,
            "stoppedWord": completionResult.stoppedWord,
            "stoppedLimit": completionResult.stoppedLimit,
            "stoppingWord": completionResult.stoppingWord
        ]
        result(resultDict)
    } else {
        result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate completion", details: nil))
    }
  }

  private func handleGenerateStreamingOpenAICompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let openAIJSON = args["openAIJSON"] as? String,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let grammar = args["grammar"] as? String

    // Parse OpenAI JSON to extract messages
    if let data = openAIJSON.data(using: .utf8),
       let json = try? JSONSerialization.jsonObject(with: data, options: []),
       let openAIRequest = json as? [String: Any],
       let chatMessages = openAIRequest["messages"] as? [[String: String]] {
        
        // Convert chat messages to LlamaMobile.ChatMessage
        var messages: [LlamaMobile.ChatMessage] = []
        for msg in chatMessages {
            if let role = msg["role"], let content = msg["content"] {
                messages.append(LlamaMobile.ChatMessage(role: role, content: content))
            }
        }

        // Create completion params for chat messages
        let completionParams = LlamaMobile.CompletionParams(chatMessages: messages)

        if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
            let resultDict: [String: Any] = [
                "text": completionResult.text,
                "tokensGenerated": completionResult.tokensGenerated,
                "tokensEvaluated": completionResult.tokensEvaluated,
                "truncated": completionResult.truncated,
                "stoppedEos": completionResult.stoppedEos,
                "stoppedWord": completionResult.stoppedWord,
                "stoppedLimit": completionResult.stoppedLimit,
                "stoppingWord": completionResult.stoppingWord
            ]
            result(resultDict)
        } else {
            result(FlutterError(code: "OPENAI_COMPLETION_FAILED", message: "Failed to generate OpenAI completion", details: nil))
        }
    } else {
        result(FlutterError(code: "INVALID_OPENAI_JSON", message: "Failed to parse OpenAI JSON format", details: nil))
    }
  }

  private func handleStopCompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support stopping completions
    result(true)
  }

  // MARK: - Model Info Methods
  private func handleGetContextWindowSize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result(2048) // Default context window size
  }

  private func handleGetEmbeddingDimension(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result(768) // Default embedding dimension
  }

  private func handleGetModelDescription(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result("Unknown model")
  }

  private func handleGetModelSize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result(0)
  }

  private func handleGetModelParametersCount(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result(0)
  }

  // MARK: - LoRA Methods
  private func handleGetLoadedLoraAdapters(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support LoRA adapters
    result([])
  }

  // MARK: - File & Model Methods
  private func handleListFiles(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let directory = args["directoryPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result([:])
  }

  private func handleListModels(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Note: iOS SDK doesn't currently support this method
    result([:])
  }

  // MARK: - Download Methods
  private func handleDownloadHfFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let repoId = args["repoId"] as? String,
          let filename = args["filename"] as? String,
          let localPath = args["localPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    // Note: iOS SDK doesn't currently support this method
    result([
        "success": false,
        "localPath": "",
        "errorMessage": "Download not supported on iOS"
    ])
  }

  // MARK: - Grammar Methods
  private func handleGetJsonGrammar(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Note: iOS SDK doesn't currently support this method
    result("# JSON grammar not supported on iOS")
  }

  private func handleGetArithmeticGrammar(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Note: iOS SDK doesn't currently support this method
    result("# Arithmetic grammar not supported on iOS")
  }

  private func handleGetCGrammar(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Note: iOS SDK doesn't currently support this method
    result("# C grammar not supported on iOS")
  }

  // MARK: - Multimodal & Audio Methods
  private func handleIsMultimodalEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let enabled = llamaMobile.isMultimodalEnabled()
    result(enabled)
  }

  private func handleSupportsVision(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let supported = llamaMobile.supportsVision()
    result(supported)
  }

  private func handleSupportsAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let supported = llamaMobile.supportsAudio()
    result(supported)
  }

  private func handleIsVocoderEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let enabled = llamaMobile.isVocoderEnabled()
    result(enabled)
  }

  private func handleGetTTSType(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let ttsType = llamaMobile.getTTSType()
    result(ttsType.rawValue)
  }

  // MARK: - Completion Methods
  private func handleGenerateCompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let paramsDict = args["params"] as? [String: Any],
          let prompt = paramsDict["prompt"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let completionParams = createCompletionParams(from: paramsDict, prompt: prompt)
    if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
      let resultDict: [String: Any] = [
        "text": completionResult.text,
        "tokensGenerated": completionResult.tokensGenerated,
        "tokensEvaluated": completionResult.tokensEvaluated,
        "truncated": completionResult.truncated,
        "stoppedEos": completionResult.stoppedEos,
        "stoppedWord": completionResult.stoppedWord,
        "stoppedLimit": completionResult.stoppedLimit,
        "stoppingWord": completionResult.stoppingWord
      ]
      result(resultDict)
    } else {
      result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate completion", details: nil))
    }
  }

  private func handleGenerateMultimodalCompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let paramsDict = args["params"] as? [String: Any],
          let prompt = paramsDict["prompt"] as? String,
          let mediaPaths = args["mediaPaths"] as? [String],
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    var completionParams = createCompletionParams(from: paramsDict, prompt: prompt)
    completionParams.mediaPaths = mediaPaths

    if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
      let resultDict: [String: Any] = [
        "text": completionResult.text,
        "tokensGenerated": completionResult.tokensGenerated,
        "tokensEvaluated": completionResult.tokensEvaluated,
        "truncated": completionResult.truncated,
        "stoppedEos": completionResult.stoppedEos,
        "stoppedWord": completionResult.stoppedWord,
        "stoppedLimit": completionResult.stoppedLimit,
        "stoppingWord": completionResult.stoppingWord
      ]
      result(resultDict)
    } else {
      result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate multimodal completion", details: nil))
    }
  }

  private func handleGenerateConversation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let paramsDict = args["params"] as? [String: Any],
          let chatMessages = args["chatMessages"] as? [[String: String]],
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    // Convert chat messages to LlamaMobile.ChatMessage
    var messages: [LlamaMobile.ChatMessage] = []
    for msg in chatMessages {
      if let role = msg["role"], let content = msg["content"] {
        messages.append(LlamaMobile.ChatMessage(role: role, content: content))
      }
    }

    // Create completion params for chat messages
    let completionParams = LlamaMobile.CompletionParams(chatMessages: messages)

    if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
      let resultDict: [String: Any] = [
        "text": completionResult.text,
        "timeToFirstToken": 0, // Placeholder - iOS SDK doesn't currently provide this
        "totalTime": 0, // Placeholder - iOS SDK doesn't currently provide this
        "tokensGenerated": completionResult.tokensGenerated
      ]
      result(resultDict)
    } else {
      result(FlutterError(code: "CONVERSATION_FAILED", message: "Failed to generate conversation", details: nil))
    }
  }

  // MARK: - Helper Methods
  private func createCompletionParams(from dict: [String: Any], prompt: String) -> LlamaMobile.CompletionParams {
    let maxTokens = dict["maxTokens"] as? Int32 ?? 128
    let nThreads = dict["nThreads"] as? Int32
    let seed = dict["seed"] as? Int32 ?? -1
    let temperature = dict["temperature"] as? Double ?? 0.8
    let topK = dict["topK"] as? Int32 ?? 40
    let topP = dict["topP"] as? Double ?? 0.95
    let minP = dict["minP"] as? Double ?? 0.05
    let typicalP = dict["typicalP"] as? Double ?? 1.0
    let penaltyLastN = dict["penaltyLastN"] as? Int32 ?? 64
    let penaltyRepeat = dict["penaltyRepeat"] as? Double ?? 1.1
    let penaltyFreq = dict["penaltyFreq"] as? Double ?? 0.0
    let penaltyPresent = dict["penaltyPresent"] as? Double ?? 0.0
    let mirostat = dict["mirostat"] as? Int32 ?? 0
    let mirostatTau = dict["mirostatTau"] as? Double ?? 5.0
    let mirostatEta = dict["mirostatEta"] as? Double ?? 0.1
    let ignoreEos = dict["ignoreEos"] as? Bool ?? false
    let stopSequences = dict["stopSequences"] as? [String] ?? []
    let grammar = dict["grammar"] as? String
    let useJsonResponse = dict["useJsonResponse"] as? Bool ?? false
    let chatTemplate = dict["chatTemplate"] as? String

    return LlamaMobile.CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar,
      useJsonResponse: useJsonResponse,
      chatTemplate: chatTemplate
    )
  }

  // MARK: - Chat Methods
  private func handleFormatChatMessages(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let chatMessages = args["messages"] as? [[String: String]],
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let chatTemplate = args["chatTemplate"] as? String

        var messages: [LlamaMobile.ChatMessage] = []
        for msg in chatMessages {
            if let role = msg["role"], let content = msg["content"] {
                messages.append(LlamaMobile.ChatMessage(role: role, content: content))
            }
        }

        if let template = chatTemplate {
            var formattedPrompt = ""
            
            for message in messages {
                var messageTemplate = template
                messageTemplate = messageTemplate.replacingOccurrences(of: "{{role}}", with: message.role)
                messageTemplate = messageTemplate.replacingOccurrences(of: "{{content}}", with: message.content)
                formattedPrompt += messageTemplate
            }
            
            var assistantTurnTemplate = template
            assistantTurnTemplate = assistantTurnTemplate.replacingOccurrences(of: "{{role}}", with: "assistant")
            
            if let contentPlaceholderRange = assistantTurnTemplate.range(of: "{{content}}") {
                assistantTurnTemplate = String(assistantTurnTemplate[..<contentPlaceholderRange.lowerBound])
            }
            
            assistantTurnTemplate = assistantTurnTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            formattedPrompt += assistantTurnTemplate + "\n"
            
            result(formattedPrompt)
        } else {
            result(FlutterError(code: "TEMPLATE_MISSING", message: "No chat template provided", details: nil))
        }
}

  // MARK: - Utility Methods
  private func handleLoadGrammar(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let grammarName = args["grammarName"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let grammar = llamaMobile.loadGrammar(named: grammarName)
    result(grammar)
  }

  // MARK: - Embedding Methods
  private func handleGenerateEmbedding(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        if let embedding = llamaMobile.generateEmbeddings(for: text) {
            let doubleEmbedding = embedding.map { Double($0) }
            result(doubleEmbedding)
        } else {
            result(FlutterError(code: "EMBEDDING_FAILED", message: "Failed to generate embedding", details: nil))
        }
    }

  // MARK: - Tokenization Methods
  private func handleTokenize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        if let tokens = llamaMobile.tokenize(text: text) {
            let intTokens = tokens.map { Int($0) }
            result(intTokens)
        } else {
            result(FlutterError(code: "TOKENIZE_FAILED", message: "Failed to tokenize text", details: nil))
        }
    }

  private func handleDetokenize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let tokens = args["tokens"] as? [Int],
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let int32Tokens = tokens.map { Int32($0) }
        if let text = llamaMobile.detokenize(tokens: int32Tokens) {
            result(text)
        } else {
            result(FlutterError(code: "DETOKENIZE_FAILED", message: "Failed to detokenize tokens", details: nil))
        }
    }

  // MARK: - LoRA Methods
  private func handleLoadLoraAdapter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let adapterPath = args["adapterPath"] as? String,
              let scale = args["scale"] as? Double,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let adapter = LlamaMobile.LoraAdapter(path: adapterPath, scale: Float(scale))
        let success = llamaMobile.applyLoraAdapters([adapter])
        result(success)
    }

    private func handleFreeLoraAdapter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.removeLoraAdapters()
        result(true)
    }

  // MARK: - TTS Methods
  private func handleLoadTTSModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let modelPath = args["modelPath"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let success = llamaMobile.initVocoder(vocoderModelPath: modelPath)
        if success {
            let ttsType = llamaMobile.getTTSType()
            result(["success": true, "modelType": ttsType.rawValue])
        } else {
            result(FlutterError(code: "TTS_LOAD_FAILED", message: "Failed to load TTS model", details: nil))
        }
    }

    private func handleGenerateAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        // Check if vocoder is enabled
        let vocoderEnabled = llamaMobile.isVocoderEnabled()
        print("Vocoder enabled: \(vocoderEnabled)")
        
        if !vocoderEnabled {
            result(FlutterError(code: "VOCODER_NOT_ENABLED", message: "Vocoder is not enabled. Please load a vocoder model first.", details: nil))
            return
        }

        // Get TTS model type for debugging
        let ttsType = llamaMobile.getTTSType()
        print("TTS Model Type: \(ttsType.rawValue)")

        let speakerJson = "{\"speaker\": \"default\"}"

        // Step 1: Format the text to get the proper prompt
        guard let formattedPrompt = llamaMobile.getFormattedAudioCompletion(speakerJson: speakerJson, textToSpeak: text) else {
            result(FlutterError(code: "FORMAT_FAILED", message: "Failed to format text for TTS", details: nil))
            return
        }

        print("Formatted prompt: \(formattedPrompt)")

        // Step 2: Generate audio content using text completion
        var completionParams = LlamaMobile.CompletionParams(prompt: formattedPrompt)
        completionParams.maxTokens = 200 // Generate appropriate audio content
        completionParams.temperature = 0.0 // Deterministic output
        completionParams.ignoreEos = true // Don't stop at end-of-sequence

        guard let completionResult = llamaMobile.generateCompletion(with: completionParams) else {
            result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate audio content", details: nil))
            return
        }

        print("Completion result: \(completionResult.text)")

        // Check if prompt contains template markers
        let useOnlyCompletion = formattedPrompt.contains("<|audio_start|") || formattedPrompt.contains("<|text_start|")
        print("Use only completion: \(useOnlyCompletion)")

        // Combine prompt and completion for full audio tokens - or just use completion if prompt contains template markers
        let contentToTokenize: String
        if useOnlyCompletion {
            // If prompt contains template markers, only use the completion result (prevents audio from template)
            contentToTokenize = completionResult.text
            print("Using only completion result for tokenization")
        } else {
            // Otherwise combine both
            contentToTokenize = formattedPrompt + completionResult.text
            print("Combining prompt and completion for tokenization")
        }

        print("Content to tokenize: \(contentToTokenize)")

        // Step 3: Tokenize the audio content
        guard let tokens = llamaMobile.tokenize(text: contentToTokenize) else {
            result(FlutterError(code: "TOKENIZATION_FAILED", message: "Failed to tokenize audio content", details: nil))
            return
        }

        print("Total tokens: \(tokens.count)")
        print("First 10 tokens: \(tokens.prefix(10))")
        print("Last 10 tokens: \(tokens.suffix(10))")

        // Step 4: Filter audio tokens (151672-155772)
        let audioStartToken = 151672
        let audioEndToken = 155772
        var audioTokens: [Int32] = []
        var nonAudioTokens = 0

        for token in tokens {
            // Check if token is in audio range
            if token >= Int32(audioStartToken) && token <= Int32(audioEndToken) {
                audioTokens.append(token)
            } else {
                nonAudioTokens += 1
            }
        }

        print("Filtered audio tokens: \(audioTokens.count)")
        print("Non-audio tokens: \(nonAudioTokens)")
        print("First 10 audio tokens: \(audioTokens.prefix(10))")

        // Step 5: Decode the audio tokens
        guard !audioTokens.isEmpty else {
            result(FlutterError(code: "NO_AUDIO_TOKENS", message: "No audio tokens generated", details: nil))
            return
        }

        guard let audioData = llamaMobile.decodeAudioTokens(tokens: audioTokens) else {
            result(FlutterError(code: "DECODE_FAILED", message: "Failed to decode audio tokens", details: nil))
            return
        }
        
        print("Decoded audio data count: \(audioData.count)")

        // Convert to int audio data
        let intAudioData = audioData.map { Int($0 * Float(Int16.max)) }
        result([
            "audioData": intAudioData
        ])
    }

    private func handleFreeTTSModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.releaseVocoder()
        result(true)
    }

    private func handleSaveAudioToWav(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let filePath = args["filePath"] as? String,
              let audioData = args["audioData"] as? [Int],
              let sampleRate = args["sampleRate"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        print("[TTS] handleSaveAudioToWav called with file path: \(filePath), \(audioData.count) samples, \(sampleRate) Hz")

        // Convert 16-bit integer samples back to floating-point samples
        let floatAudioData = audioData.map { Float($0) / Float(Int16.max) }
        print("[TTS] Converted \(floatAudioData.count) samples to floating-point")

        let success = llamaMobile.saveAudioToWav(filePath: filePath, audioData: floatAudioData, sampleRate: Int32(sampleRate))
        print("[TTS] saveAudioToWav result: \(success)")
        result(success)
    }

    private func handleInitMultimodal(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let mmprojPath = args["mmprojPath"] as? String,
              let useGpu = args["useGpu"] as? Bool,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let success = llamaMobile.initMultimodal(mmprojPath: mmprojPath, useGpu: useGpu)
        result(success)
    }

  // MARK: - Download Methods
  private func handleDownloadModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let url = args["url"] as? String,
              let localPath = args["localPath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let username = args["username"] as? String
        let password = args["password"] as? String
        let headers = args["headers"] as? [String: String]

        let downloadParams = LlamaMobile.DownloadParams(
            url: url,
            localPath: localPath,
            username: username,
            password: password,
            headers: headers,
            progressCallback: nil
        )

        let initParams = LlamaMobile.InitParams(modelPath: "")
        if let llamaMobile = LlamaMobile(with: initParams) {
            let downloadResult = llamaMobile.download(with: downloadParams)
            result([
                "success": downloadResult.success,
                "localPath": downloadResult.localPath,
                "errorMessage": downloadResult.errorMessage
            ])
        } else {
            result(FlutterError(code: "DOWNLOAD_FAILED", message: "Failed to initialize LlamaMobile for download", details: nil))
        }
    }

  // MARK: - OpenAI Completion Methods
  private func handleGenerateOpenAICompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let openAIJSON = args["openAIJSON"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let grammar = args["grammar"] as? String

        // Parse OpenAI JSON to extract messages
        if let data = openAIJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let openAIRequest = json as? [String: Any],
           let chatMessages = openAIRequest["messages"] as? [[String: String]] {
            
            // Convert chat messages to LlamaMobile.ChatMessage
            var messages: [LlamaMobile.ChatMessage] = []
            for msg in chatMessages {
                if let role = msg["role"], let content = msg["content"] {
                    messages.append(LlamaMobile.ChatMessage(role: role, content: content))
                }
            }

            // Create completion params for chat messages
            let completionParams = LlamaMobile.CompletionParams(chatMessages: messages)

            if let completionResult = llamaMobile.generateCompletion(with: completionParams) {
                let resultDict: [String: Any] = [
                    "text": completionResult.text,
                    "tokensGenerated": completionResult.tokensGenerated,
                    "tokensEvaluated": completionResult.tokensEvaluated,
                    "truncated": completionResult.truncated,
                    "stoppedEos": completionResult.stoppedEos,
                    "stoppedWord": completionResult.stoppedWord,
                    "stoppedLimit": completionResult.stoppedLimit,
                    "stoppingWord": completionResult.stoppingWord
                ]
                result(resultDict)
            } else {
                result(FlutterError(code: "OPENAI_COMPLETION_FAILED", message: "Failed to generate OpenAI completion", details: nil))
            }
        } else {
            result(FlutterError(code: "INVALID_OPENAI_JSON", message: "Failed to parse OpenAI JSON format", details: nil))
        }
    }

  // MARK: - FlutterStreamHandler Methods
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    if let channelName = arguments as? String {
        switch channelName {
        case "token":
            tokenEventSink = events
        case "progress":
            progressEventSink = events
        default:
            break
        }
    }
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let channelName = arguments as? String {
        switch channelName {
        case "token":
            tokenEventSink = nil
        case "progress":
            progressEventSink = nil
        default:
            break
        }
    }
    return nil
  }
}
