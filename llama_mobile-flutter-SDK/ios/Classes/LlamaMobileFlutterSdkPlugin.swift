import Flutter
import UIKit

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {
  // Dictionary to store LlamaMobile instances
  private var contexts: [Int: LlamaMobile] = [:]
  // Counter for generating unique context handles
  private var nextContextHandle: Int = 1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "llama_mobile_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = LlamaMobileFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
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
    case "formatChatMessages":
      handleFormatChatMessages(call, result: result)
    case "setChatTemplate":
      handleSetChatTemplate(call, result: result)
    case "loadGrammar":
      handleLoadGrammar(call, result: result)
    case "generateEmbedding":
      handleGenerateEmbedding(call, result: result)
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
    case "downloadModel":
      handleDownloadModel(call, result: result)
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Context Management
  private func handleInitContext(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let modelPath = args["modelPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let chatTemplate = args["chatTemplate"] as? String
    let systemPrompt = args["systemPrompt"] as? String
    let nCtx = args["nCtx"] as? Int32 ?? 2048
    let nBatch = args["nBatch"] as? Int32 ?? 512
    let nGpuLayers = args["nGpuLayers"] as? Int32 ?? 0
    let nThreads = args["nThreads"] as? Int32 ?? 4

    if let llamaMobile = LlamaMobile(modelPath: modelPath, nCtx: nCtx, nGpuLayers: nGpuLayers, nThreads: nThreads) {
      // Set chat template if provided
      if let chatTemplate = chatTemplate {
        llamaMobile.setChatTemplate(chatTemplate)
      }
      let handle = nextContextHandle
      nextContextHandle += 1
      contexts[handle] = llamaMobile
      result(["contextHandle": handle])
    } else {
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
    // Note: formatChatMessages not implemented in iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "formatChatMessages not implemented in iOS SDK", details: nil))
  }

  private func handleSetChatTemplate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let template = args["template"] as? String
    llamaMobile.setChatTemplate(template)
    result(true)
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

    // Note: iOS SDK doesn't currently have a direct generateEmbedding method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "generateEmbedding not implemented in iOS SDK", details: nil))
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

    // Note: iOS SDK doesn't currently have loadLoraAdapter method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "loadLoraAdapter not implemented in iOS SDK", details: nil))
  }

  private func handleFreeLoraAdapter(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    // Note: iOS SDK doesn't currently have freeLoraAdapter method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "freeLoraAdapter not implemented in iOS SDK", details: nil))
  }

  // MARK: - TTS Methods
  private func handleLoadTTSModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let modelPath = args["modelPath"] as? String,
          let paramsDict = args["params"] as? [String: Any],
          let modelTypeRaw = paramsDict["modelType"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let modelType = LlamaMobile.TTSModelType(rawValue: modelTypeRaw)
    // Note: iOS SDK doesn't currently have loadTTSModel method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "loadTTSModel not implemented in iOS SDK", details: nil))
  }

  private func handleGenerateAudio(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    // Note: iOS SDK doesn't currently have generateAudio method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "generateAudio not implemented in iOS SDK", details: nil))
  }

  private func handleFreeTTSModel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    // Note: iOS SDK doesn't currently have freeTTSModel method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "freeTTSModel not implemented in iOS SDK", details: nil))
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

    // Note: iOS SDK doesn't currently have downloadModel method
    // This will need to be implemented in the iOS SDK
    result(FlutterError(code: "NOT_IMPLEMENTED", message: "downloadModel not implemented in iOS SDK", details: nil))
  }
}
