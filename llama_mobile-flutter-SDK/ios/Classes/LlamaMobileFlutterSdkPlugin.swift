import Flutter
import UIKit
import LlamaMobileSDK // Import the existing iOS SDK

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {
  // Hold a reference to the LlamaMobile instance
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
    let useMemoryCache = arguments["useMemoryCache"] as? Bool ?? true

    // Initialize LlamaMobile instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobile()
    }

    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile", details: nil))
      return
    }

    // Create init params
    let initParams = LlamaMobile.InitParams(
      modelPath: modelPath,
      nCtx: Int32(contextSize),
      nThreads: 4
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

    // Initialize LlamaMobile instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobile()
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

    // Create init params
    let initParams = LlamaMobile.InitParams(
      modelPath: modelPath,
      chatTemplate: chatTemplate,
      systemPrompt: systemPrompt,
      nCtx: Int32(nCtx),
      nBatch: Int32(nBatch),
      nUbatch: Int32(nUbatch),
      nGpuLayers: Int32(nGpuLayers),
      nThreads: Int32(nThreads),
      useMmap: useMmap,
      useMlock: useMlock,
      embedding: embedding,
      poolingType: Int32(poolingType),
      embdNormalize: embdNormalize ? 1 : 0,
      flashAttn: flashAttn,
      cacheTypeK: cacheTypeK,
      cacheTypeV: cacheTypeV
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

    // Create completion params
    let completionParams = LlamaMobile.CompletionParams(
      prompt: prompt,
      nPredict: Int32(maxTokens),
      temperature: temperature
    )

    // Generate completion
    if let completionResult = llamaMobile.completion(with: completionParams) {
      result(completionResult.text)
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

    // Create completion params
    let completionParams = LlamaMobile.CompletionParams(
      prompt: prompt,
      nPredict: Int32(maxTokens),
      nThreads: Int32(nThreads),
      seed: Int32(seed),
      temperature: temperature,
      topK: Int32(topK),
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: Int32(penaltyLastN),
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: Int32(mirostat),
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar
    )

    // Generate completion
    if let completionResult = llamaMobile.completion(with: completionParams) {
      result(completionResult.text)
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

    // Initialize LlamaMobile instance if needed
    if llamaMobile == nil {
      llamaMobile = LlamaMobile()
    }

    guard let llamaMobile = llamaMobile, let grammarName = LlamaMobile.GrammarName(rawValue: grammarNameStr) else {
      result(nil)
      return
    }

    // Get grammar content
    let grammarContent = llamaMobile.grammarContent(for: grammarName)
    result(grammarContent)
  }

  private func handleRelease(call: FlutterMethodCall, result: @escaping FlutterResult) {
    llamaMobile = nil // This will trigger deinit and release resources
    result(nil)
  }
}
