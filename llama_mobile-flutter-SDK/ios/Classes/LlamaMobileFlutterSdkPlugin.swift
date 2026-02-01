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
    case "initContextAsync":
      handleInitContextAsync(call, result: result)
    case "freeContext":
      handleFreeContext(call, result: result)
    case "freeContextAsync":
      handleFreeContextAsync(call, result: result)
    case "generateCompletion":
      handleGenerateCompletion(call, result: result)
    case "generateCompletionAsync":
      handleGenerateCompletionAsync(call, result: result)
    case "generateMultimodalCompletion":
      handleGenerateMultimodalCompletion(call, result: result)
    case "generateMultimodalCompletionAsync":
      handleGenerateMultimodalCompletionAsync(call, result: result)
    case "generateConversation":
      handleGenerateConversation(call, result: result)
    case "generateConversationAsync":
      handleGenerateConversationAsync(call, result: result)
    case "generateStreamingCompletion":
      handleGenerateStreamingCompletion(call, result: result)
    case "generateStreamingCompletionAsync":
      handleGenerateStreamingCompletionAsync(call, result: result)
    case "generateStreamingOpenAICompletion":
      handleGenerateStreamingOpenAICompletion(call, result: result)
    case "generateStreamingOpenAICompletionAsync":
      handleGenerateStreamingOpenAICompletionAsync(call, result: result)
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
    case "downloadHfFile":
      handleDownloadHfFile(call, result: result)
    case "downloadHfFileAsync":
      handleDownloadHfFileAsync(call, result: result)
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
    case "formatChatMessagesAsync":
      handleFormatChatMessagesAsync(call, result: result)

    case "loadGrammar":
      handleLoadGrammar(call, result: result)
    case "loadGrammarAsync":
      handleLoadGrammarAsync(call, result: result)
    case "generateEmbedding":
      handleGenerateEmbedding(call, result: result)
    case "tokenize":
      handleTokenize(call, result: result)
    case "detokenize":
      handleDetokenize(call, result: result)
    case "loadLoraAdapter":
      handleLoadLoraAdapter(call, result: result)
    case "loadLoraAdapterAsync":
      handleLoadLoraAdapterAsync(call, result: result)
    case "freeLoraAdapter":
      handleFreeLoraAdapter(call, result: result)
    case "freeLoraAdapterAsync":
      handleFreeLoraAdapterAsync(call, result: result)
    case "loadTTSModel":
      handleLoadTTSModel(call, result: result)
    case "loadTTSModelAsync":
      handleLoadTTSModelAsync(call, result: result)
    case "generateAudio":
      handleGenerateAudio(call, result: result)
    case "freeTTSModel":
      handleFreeTTSModel(call, result: result)
    case "freeTTSModelAsync":
      handleFreeTTSModelAsync(call, result: result)
    case "saveAudioToWav":
      handleSaveAudioToWav(call, result: result)
    case "initMultimodal":
      handleInitMultimodal(call, result: result)
    case "initMultimodalAsync":
      handleInitMultimodalAsync(call, result: result)
    case "releaseMultimodal":
      handleReleaseMultimodal(call, result: result)
    case "releaseMultimodalAsync":
      handleReleaseMultimodalAsync(call, result: result)
    case "initVocoder":
      handleInitVocoder(call, result: result)
    case "initVocoderAsync":
      handleInitVocoderAsync(call, result: result)
    case "releaseVocoder":
      handleReleaseVocoder(call, result: result)
    case "releaseVocoderAsync":
      handleReleaseVocoderAsync(call, result: result)
    case "clearConversation":
      handleClearConversation(call, result: result)
    case "isConversationActive":
      handleIsConversationActive(call, result: result)
    case "removeLoraAdapters":
      handleRemoveLoraAdapters(call, result: result)
    case "removeLoraAdaptersAsync":
      handleRemoveLoraAdaptersAsync(call, result: result)
    case "generateAudioFromText":
      handleGenerateAudioFromText(call, result: result)
    case "getFormattedAudioCompletion":
      handleGetFormattedAudioCompletion(call, result: result)
    case "getAudioGuideTokens":
      handleGetAudioGuideTokens(call, result: result)
    case "setGuideTokens":
      handleSetGuideTokens(call, result: result)
    case "decodeAudioTokens":
      handleDecodeAudioTokens(call, result: result)
    case "generateSpeechSync":
      handleGenerateSpeechSync(call, result: result)
    case "generateSpeech":
      handleGenerateSpeech(call, result: result)
    case "generateSpeechAsync":
      handleGenerateSpeechAsync(call, result: result)
    case "generateSpeechStream":
      handleGenerateSpeechStream(call, result: result)
    case "generateSpeechStreamAsync":
      handleGenerateSpeechStreamAsync(call, result: result)
    case "generateSpeechStreamForLongText":
      handleGenerateSpeechStreamForLongText(call, result: result)
    case "generateSpeechStreamForLongTextAsync":
      handleGenerateSpeechStreamForLongTextAsync(call, result: result)
    case "setLogLevel":
      handleSetLogLevel(call, result: result)
    case "downloadModel":
      handleDownloadModel(call, result: result)
    case "downloadModelAsync":
      handleDownloadModelAsync(call, result: result)
    case "generateOpenAICompletion":
      handleGenerateOpenAICompletion(call, result: result)
    case "generateOpenAICompletionAsync":
      handleGenerateOpenAICompletionAsync(call, result: result)
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

  private func handleInitContextAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[DEBUG] Flutter Plugin: handleInitContextAsync called")
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

    // Run the initialization asynchronously
    DispatchQueue.global(qos: .userInitiated).async {
      print("[DEBUG] Flutter Plugin: Calling LlamaMobile(with: initParams) asynchronously")
      if let llamaMobile = LlamaMobile(with: initParams) {
        print("[DEBUG] Flutter Plugin: LlamaMobile instance created successfully")
        let handle = self.nextContextHandle
        self.nextContextHandle += 1
        self.contexts[handle] = llamaMobile
        print("[DEBUG] Flutter Plugin: Returning contextHandle: \(handle)")
        DispatchQueue.main.async {
          result(["contextHandle": handle])
        }
      } else {
        print("[DEBUG] Flutter Plugin: Failed to create LlamaMobile instance")
        DispatchQueue.main.async {
          result(FlutterError(code: "INIT_FAILED", message: "Failed to initialize LlamaMobile context", details: nil))
        }
      }
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

  private func handleFreeContextAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing contextHandle", details: nil))
      return
    }

    // Run asynchronously
    DispatchQueue.global(qos: .userInitiated).async {
      self.contexts.removeValue(forKey: contextHandle)
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleGenerateCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleGenerateCompletion(call, result: result)
    }
  }

  private func handleGenerateMultimodalCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleGenerateMultimodalCompletion(call, result: result)
    }
  }

  private func handleGenerateConversationAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleGenerateConversation(call, result: result)
    }
  }

  private func handleGenerateStreamingCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleGenerateStreamingCompletion(call, result: result)
    }
  }

  private func handleGenerateStreamingOpenAICompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleGenerateStreamingOpenAICompletion(call, result: result)
    }
  }

  private func handleDownloadHfFileAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleDownloadHfFile(call, result: result)
    }
  }

  private func handleFormatChatMessagesAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleFormatChatMessages(call, result: result)
    }
  }

  private func handleLoadGrammarAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleLoadGrammar(call, result: result)
    }
  }

  private func handleLoadLoraAdapterAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleLoadLoraAdapter(call, result: result)
    }
  }

  private func handleFreeLoraAdapterAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleFreeLoraAdapter(call, result: result)
    }
  }

  private func handleLoadTTSModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.handleLoadTTSModel(call, result: result)
    }
  }

  private func handleFreeTTSModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.releaseVocoder()
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleInitMultimodalAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support explicit multimodal initialization
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleReleaseMultimodalAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support explicit multimodal release
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleInitVocoderAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let modelPath = args["modelPath"] as? String,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.initVocoder(vocoderModelPath: modelPath)
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleReleaseVocoderAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.releaseVocoder()
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleRemoveLoraAdaptersAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.removeLoraAdapters()
      DispatchQueue.main.async {
        result(true)
      }
    }
  }

  private func handleGenerateSpeechAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support this method directly
      DispatchQueue.main.async {
        result(FlutterError(code: "NOT_SUPPORTED", message: "Method not supported on iOS", details: nil))
      }
    }
  }

  private func handleGenerateSpeechStreamAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support this method directly
      DispatchQueue.main.async {
        result(FlutterError(code: "NOT_SUPPORTED", message: "Method not supported on iOS", details: nil))
      }
    }
  }

  private func handleGenerateSpeechStreamForLongTextAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support this method directly
      DispatchQueue.main.async {
        result(FlutterError(code: "NOT_SUPPORTED", message: "Method not supported on iOS", details: nil))
      }
    }
  }

  private func handleDownloadModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let modelUrl = args["modelUrl"] as? String,
          let localPath = args["localPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      // iOS SDK doesn't currently support this method directly
      DispatchQueue.main.async {
        result(FlutterError(code: "NOT_SUPPORTED", message: "Method not supported on iOS", details: nil))
      }
    }
  }

  private func handleGenerateOpenAICompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let openAIJSON = args["openAIJSON"] as? String,
          let llamaMobile = self.contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
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
            DispatchQueue.main.async {
              result(resultDict)
            }
        } else {
            DispatchQueue.main.async {
              result(FlutterError(code: "OPENAI_COMPLETION_FAILED", message: "Failed to generate OpenAI completion", details: nil))
            }
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "INVALID_OPENAI_JSON", message: "Failed to parse OpenAI JSON format", details: nil))
        }
      }
    }
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
  // MARK: - Download Methods
  private func handleDownloadHfFile(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let repoId = args["repoId"] as? String,
          let filename = args["filename"] as? String,
          let localPath = args["localPath"] as? String else {
        result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
        return
    }

    let bearerToken = args["bearerToken"] as? String
    let offline = args["offline"] as? Bool ?? false

    let hfParams = LlamaMobile.HuggingFaceDownloadParams(
        repoID: repoId,
        filename: filename,
        destinationPath: localPath,
        bearerToken: bearerToken,
        offline: offline,
        progressCallback: nil
    )

    let downloader = LlamaMobile(modelPath: "")
    guard let downloadResult = downloader?.downloadHuggingFaceFile(with: hfParams) else {
        result([
            "success": false,
            "localPath": "",
            "errorMessage": "Failed to create downloader"
        ])
        return
    }
    result([
        "success": downloadResult.success,
        "localPath": downloadResult.localPath,
        "errorMessage": downloadResult.errorMessage
    ])
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
      useJsonResponse: useJsonResponse
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
          let grammarPath = args["grammarPath"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let grammar = llamaMobile.loadGrammar(from: grammarPath)
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

    private func handleReleaseMultimodal(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.releaseMultimodal()
        result(nil)
    }

    private func handleInitVocoder(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let vocoderModelPath = args["vocoderModelPath"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let success = llamaMobile.initVocoder(vocoderModelPath: vocoderModelPath)
        result(success)
    }

    private func handleReleaseVocoder(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.releaseVocoder()
        result(nil)
    }

    private func handleClearConversation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.clearConversation()
        result(nil)
    }

    private func handleIsConversationActive(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let isActive = llamaMobile.isConversationActive()
        result(isActive)
    }

    private func handleRemoveLoraAdapters(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        llamaMobile.removeLoraAdapters()
        result(nil)
    }

    private func handleGenerateAudioFromText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let speakerJson = args["speakerJson"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        if let audioSamples = llamaMobile.generateAudioFromText(text: text, speakerJson: speakerJson) {
            result(audioSamples)
        } else {
            result(FlutterError(code: "AUDIO_GENERATION_FAILED", message: "Failed to generate audio from text", details: nil))
        }
    }

    private func handleGetFormattedAudioCompletion(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let speakerJson = args["speakerJson"] as? String,
              let textToSpeak = args["textToSpeak"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let formattedCompletion = llamaMobile.getFormattedAudioCompletion(speakerJson: speakerJson, textToSpeak: textToSpeak)
        result(formattedCompletion)
    }

    private func handleGetAudioGuideTokens(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let textToSpeak = args["textToSpeak"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        if let guideTokens = llamaMobile.getAudioGuideTokens(textToSpeak: textToSpeak) {
            result(guideTokens.map { Int($0) })
        } else {
            result(FlutterError(code: "GET_GUIDE_TOKENS_FAILED", message: "Failed to get audio guide tokens", details: nil))
        }
    }

    private func handleSetGuideTokens(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let tokens = args["tokens"] as? [Int],
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let int32Tokens = tokens.map { Int32($0) }
        llamaMobile.setGuideTokens(tokens: int32Tokens)
        result(nil)
    }

    private func handleDecodeAudioTokens(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let tokens = args["tokens"] as? [Int],
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let int32Tokens = tokens.map { Int32($0) }
        if let audioSamples = llamaMobile.decodeAudioTokens(tokens: int32Tokens) {
            result(audioSamples)
        } else {
            result(FlutterError(code: "DECODE_AUDIO_TOKENS_FAILED", message: "Failed to decode audio tokens", details: nil))
        }
    }

    private func handleGenerateSpeechSync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let optionsDict = args["options"] as? [String: Any]
        let options = parseTTSOptions(optionsDict)

        let speechResult = llamaMobile.generateSpeechSync(text: text, options: options)

        switch speechResult {
        case .success(let speechResult):
            let methodUsed = speechResult.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
            result([
                "audioSamples": speechResult.audioSamples,
                "sampleRate": speechResult.sampleRate,
                "duration": speechResult.duration,
                "outputFilePath": speechResult.outputFilePath ?? NSNull(),
                "methodUsed": methodUsed
            ])
        case .failure(let error):
            var errorMessage = "Unknown error"
            switch error {
            case .noModelLoaded:
                errorMessage = "No model loaded"
            case .noVocoderEnabled:
                errorMessage = "No vocoder enabled"
            case .invalidText:
                errorMessage = "Invalid text"
            case .generationFailed:
                errorMessage = "Generation failed"
            case .formattingFailed:
                errorMessage = "Formatting failed"
            case .tokenizationFailed:
                errorMessage = "Tokenization failed"
            case .audioDecodingFailed:
                errorMessage = "Audio decoding failed"
            case .fileSaveFailed:
                errorMessage = "File save failed"
            case .unknownError(let message):
                errorMessage = message
            }
            result(FlutterError(code: "SPEECH_GENERATION_FAILED", message: errorMessage, details: nil))
        }
    }

    private func handleGenerateSpeech(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let optionsDict = args["options"] as? [String: Any]
        let options = parseTTSOptions(optionsDict)

        Task {
            let speechResult = await llamaMobile.generateSpeech(text: text, options: options)

            switch speechResult {
            case .success(let speechResult):
                let methodUsed = speechResult.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                result([
                    "audioSamples": speechResult.audioSamples,
                    "sampleRate": speechResult.sampleRate,
                    "duration": speechResult.duration,
                    "outputFilePath": speechResult.outputFilePath ?? NSNull(),
                    "methodUsed": methodUsed
                ])
            case .failure(let error):
                var errorMessage = "Unknown error"
                switch error {
                case .noModelLoaded:
                    errorMessage = "No model loaded"
                case .noVocoderEnabled:
                    errorMessage = "No vocoder enabled"
                case .invalidText:
                    errorMessage = "Invalid text"
                case .generationFailed:
                    errorMessage = "Generation failed"
                case .formattingFailed:
                    errorMessage = "Formatting failed"
                case .tokenizationFailed:
                    errorMessage = "Tokenization failed"
                case .audioDecodingFailed:
                    errorMessage = "Audio decoding failed"
                case .fileSaveFailed:
                    errorMessage = "File save failed"
                case .unknownError(let message):
                    errorMessage = message
                }
                result(FlutterError(code: "SPEECH_GENERATION_FAILED", message: errorMessage, details: nil))
            }
        }
    }

    private func handleGenerateSpeechStream(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let optionsDict = args["options"] as? [String: Any]
        let options = parseTTSOptions(optionsDict)

        Task {
            let speechResult = await llamaMobile.generateSpeechStreamForLongText(
                text: text,
                options: options,
                progressHandler: { progress in
                    // TODO: Send progress updates via event channel
                },
                audioChunkHandler: { audioChunk in
                    // TODO: Send audio chunks via event channel
                }
            )

            switch speechResult {
            case .success(let metadata):
                let methodUsed = metadata.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                result([
                    "sampleRate": metadata.sampleRate,
                    "duration": metadata.duration,
                    "outputFilePath": metadata.outputFilePath ?? NSNull(),
                    "methodUsed": methodUsed
                ])
            case .failure(let error):
                var errorMessage = "Unknown error"
                switch error {
                case .noModelLoaded:
                    errorMessage = "No model loaded"
                case .noVocoderEnabled:
                    errorMessage = "No vocoder enabled"
                case .invalidText:
                    errorMessage = "Invalid text"
                case .generationFailed:
                    errorMessage = "Generation failed"
                case .formattingFailed:
                    errorMessage = "Formatting failed"
                case .tokenizationFailed:
                    errorMessage = "Tokenization failed"
                case .audioDecodingFailed:
                    errorMessage = "Audio decoding failed"
                case .fileSaveFailed:
                    errorMessage = "File save failed"
                case .unknownError(let message):
                    errorMessage = message
                }
                result(FlutterError(code: "SPEECH_STREAM_FAILED", message: errorMessage, details: nil))
            }
        }
    }

    private func handleGenerateSpeechStreamForLongText(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let contextHandle = args["contextHandle"] as? Int,
              let text = args["text"] as? String,
              let llamaMobile = contexts[contextHandle] else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let optionsDict = args["options"] as? [String: Any]
        let options = parseTTSOptions(optionsDict)

        Task {
            let speechResult = await llamaMobile.generateSpeechStreamForLongText(
                text: text,
                options: options,
                progressHandler: { progress in
                    // TODO: Send progress updates via event channel
                },
                audioChunkHandler: { audioChunk in
                    // TODO: Send audio chunks via event channel
                }
            )

            switch speechResult {
            case .success(let metadata):
                let methodUsed = metadata.methodUsed == .builtIn ? "builtIn" : "customWorkflow"
                result([
                    "sampleRate": metadata.sampleRate,
                    "duration": metadata.duration,
                    "outputFilePath": metadata.outputFilePath ?? NSNull(),
                    "methodUsed": methodUsed
                ])
            case .failure(let error):
                var errorMessage = "Unknown error"
                switch error {
                case .noModelLoaded:
                    errorMessage = "No model loaded"
                case .noVocoderEnabled:
                    errorMessage = "No vocoder enabled"
                case .invalidText:
                    errorMessage = "Invalid text"
                case .generationFailed:
                    errorMessage = "Generation failed"
                case .formattingFailed:
                    errorMessage = "Formatting failed"
                case .tokenizationFailed:
                    errorMessage = "Tokenization failed"
                case .audioDecodingFailed:
                    errorMessage = "Audio decoding failed"
                case .fileSaveFailed:
                    errorMessage = "File save failed"
                case .unknownError(let message):
                    errorMessage = message
                }
                result(FlutterError(code: "SPEECH_STREAM_FAILED", message: errorMessage, details: nil))
            }
        }
    }

    private func parseTTSOptions(_ optionsDict: [String: Any]?) -> LlamaMobile.TTSOptions {
        guard let optionsDict = optionsDict else {
            return LlamaMobile.TTSOptions()
        }

        return LlamaMobile.TTSOptions(
            sampleRate: optionsDict["sampleRate"] as? Int ?? 24000,
            voice: optionsDict["voice"] as? String,
            speed: Float(optionsDict["speed"] as? Double ?? 1.0),
            saveToFile: optionsDict["saveToFile"] as? Bool ?? false,
            outputFilePath: optionsDict["outputFilePath"] as? String
        )
    }

    private func handleSetLogLevel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
            return
        }

        let logLevel = LogLevel(rawValue: level) ?? .info
        setLogLevel(logLevel)
        result(nil)
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

    let downloader = LlamaMobile(modelPath: "")
    guard let downloadResult = downloader?.download(with: downloadParams) else {
        result([
            "success": false,
            "localPath": "",
            "errorMessage": "Failed to create downloader"
        ])
        return
    }
    result([
        "success": downloadResult.success,
        "localPath": downloadResult.localPath,
        "errorMessage": downloadResult.errorMessage
    ])
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

  // MARK: - Async Methods

  private func handleGenerateCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let params = args["params"] as? [String: Any],
          let prompt = params["prompt"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let completionParams = createCompletionParams(from: params, prompt: prompt)

    DispatchQueue.global(qos: .userInitiated).async {
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
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate completion", details: nil))
        }
      }
    }
  }

  private func handleGenerateMultimodalCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let params = args["params"] as? [String: Any],
          let mediaPaths = args["mediaPaths"] as? [String],
          let prompt = params["prompt"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let completionParams = createCompletionParams(from: params, prompt: prompt)

    DispatchQueue.global(qos: .userInitiated).async {
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
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate multimodal completion", details: nil))
        }
      }
    }
  }

  private func handleGenerateConversationAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let params = args["params"] as? [String: Any],
          let chatMessages = args["chatMessages"] as? [[String: String]],
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    var messages: [LlamaMobile.ChatMessage] = []
    for msg in chatMessages {
      if let role = msg["role"], let content = msg["content"] {
        messages.append(LlamaMobile.ChatMessage(role: role, content: content))
      }
    }

    let completionParams = LlamaMobile.CompletionParams(chatMessages: messages)

    DispatchQueue.global(qos: .userInitiated).async {
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
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "CONVERSATION_FAILED", message: "Failed to generate conversation", details: nil))
        }
      }
    }
  }

  private func handleGenerateStreamingCompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let params = args["params"] as? [String: Any],
          let prompt = params["prompt"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let completionParams = createCompletionParams(from: params, prompt: prompt)

    DispatchQueue.global(qos: .userInitiated).async {
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
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "COMPLETION_FAILED", message: "Failed to generate streaming completion", details: nil))
        }
      }
    }
  }

  private func handleGenerateStreamingOpenAICompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let openAIJSON = args["openAIJSON"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let grammar = args["grammar"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      if let data = openAIJSON.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data, options: []),
         let openAIRequest = json as? [String: Any],
         let chatMessages = openAIRequest["messages"] as? [[String: String]] {
        
        var messages: [LlamaMobile.ChatMessage] = []
        for msg in chatMessages {
          if let role = msg["role"], let content = msg["content"] {
            messages.append(LlamaMobile.ChatMessage(role: role, content: content))
          }
        }

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
          DispatchQueue.main.async {
            result(resultDict)
          }
        } else {
          DispatchQueue.main.async {
            result(FlutterError(code: "OPENAI_COMPLETION_FAILED", message: "Failed to generate streaming OpenAI completion", details: nil))
          }
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "INVALID_OPENAI_JSON", message: "Failed to parse OpenAI JSON format", details: nil))
        }
      }
    }
  }

  private func handleFormatChatMessagesAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let messages = args["messages"] as? [[String: String]],
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let chatTemplate = args["chatTemplate"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      var chatMessages: [LlamaMobile.ChatMessage] = []
      for msg in messages {
        if let role = msg["role"], let content = msg["content"] {
          chatMessages.append(LlamaMobile.ChatMessage(role: role, content: content))
        }
      }

      let formatted = llamaMobile.formatChatMessages(chatMessages, chatTemplate: chatTemplate)
      DispatchQueue.main.async {
        result(formatted)
      }
    }
  }

  private func handleLoadGrammarAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let grammarPath = args["grammarPath"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let grammar = llamaMobile.loadGrammar(from: grammarPath)
      DispatchQueue.main.async {
        result(grammar)
      }
    }
  }

  private func handleGenerateEmbeddingAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      if let embedding = llamaMobile.generateEmbedding(for: text) {
        DispatchQueue.main.async {
          result(embedding)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "EMBEDDING_FAILED", message: "Failed to generate embedding", details: nil))
        }
      }
    }
  }

  private func handleLoadLoraAdapterAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let adapterPath = args["adapterPath"] as? String,
          let scale = args["scale"] as? Double,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.loadLoraAdapter(from: adapterPath, scale: Float(scale))
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleFreeLoraAdapterAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.freeLoraAdapter()
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleLoadTTSModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let modelPath = args["modelPath"] as? String,
          let params = args["params"] as? [String: Any],
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let sampleRate = params["sampleRate"] as? Int ?? 24000
    let voice = params["voice"] as? String
    let speed = params["speed"] as? Double ?? 1.0

    DispatchQueue.global(qos: .userInitiated).async {
      let ttsOptions = LlamaMobile.TTSOptions()
      ttsOptions.sampleRate = Int32(sampleRate)
      ttsOptions.voice = voice
      ttsOptions.speed = Float(speed)

      let success = llamaMobile.loadTTSModel(from: modelPath, options: ttsOptions)
      DispatchQueue.main.async {
        result(["success": success])
      }
    }
  }

  private func handleFreeTTSModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.freeTTSModel()
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleInitMultimodalAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let mmprojPath = args["mmprojPath"] as? String,
          let useGpu = args["useGpu"] as? Bool,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.initMultimodal(from: mmprojPath, useGpu: useGpu)
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleReleaseMultimodalAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.releaseMultimodal()
      DispatchQueue.main.async {
        result(nil)
      }
    }
  }

  private func handleInitVocoderAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let vocoderModelPath = args["vocoderModelPath"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let success = llamaMobile.initVocoder(from: vocoderModelPath)
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func handleReleaseVocoderAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.releaseVocoder()
      DispatchQueue.main.async {
        result(nil)
      }
    }
  }

  private func handleRemoveLoraAdaptersAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      llamaMobile.removeLoraAdapters()
      DispatchQueue.main.async {
        result(nil)
      }
    }
  }

  private func handleGenerateSpeechAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let options = args["options"] as? [String: Any]

    DispatchQueue.global(qos: .userInitiated).async {
      if let speechResult = llamaMobile.generateSpeech(for: text, options: options) {
        let resultDict: [String: Any] = [
          "audioData": speechResult.audioData,
          "sampleRate": speechResult.sampleRate,
          "duration": speechResult.duration,
          "outputFilePath": speechResult.outputFilePath ?? "",
          "methodUsed": speechResult.methodUsed.rawValue
        ]
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "SPEECH_FAILED", message: "Failed to generate speech", details: nil))
        }
      }
    }
  }

  private func handleGenerateSpeechStreamAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let options = args["options"] as? [String: Any]

    DispatchQueue.global(qos: .userInitiated).async {
      if let speechResult = llamaMobile.generateSpeechStream(for: text, options: options) {
        let resultDict: [String: Any] = [
          "audioData": speechResult.audioData,
          "sampleRate": speechResult.sampleRate,
          "duration": speechResult.duration,
          "outputFilePath": speechResult.outputFilePath ?? "",
          "methodUsed": speechResult.methodUsed.rawValue
        ]
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "SPEECH_FAILED", message: "Failed to generate speech stream", details: nil))
        }
      }
    }
  }

  private func handleGenerateSpeechStreamForLongTextAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let text = args["text"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let options = args["options"] as? [String: Any]

    DispatchQueue.global(qos: .userInitiated).async {
      if let speechResult = llamaMobile.generateSpeechStreamForLongText(for: text, options: options) {
        let resultDict: [String: Any] = [
          "audioData": speechResult.audioData,
          "sampleRate": speechResult.sampleRate,
          "duration": speechResult.duration,
          "outputFilePath": speechResult.outputFilePath ?? "",
          "methodUsed": speechResult.methodUsed.rawValue
        ]
        DispatchQueue.main.async {
          result(resultDict)
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "SPEECH_FAILED", message: "Failed to generate speech stream for long text", details: nil))
        }
      }
    }
  }

  private func handleDownloadModelAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let url = args["url"] as? String,
          let localPath = args["localPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let username = args["username"] as? String
    let password = args["password"] as? String
    let headers = args["headers"] as? [String: String]

    DispatchQueue.global(qos: .userInitiated).async {
      let downloadParams = LlamaMobile.DownloadParams(
        url: url,
        localPath: localPath,
        username: username,
        password: password,
        headers: headers,
        progressCallback: nil
      )

      let downloader = LlamaMobile(modelPath: "")
      if let downloadResult = downloader?.download(with: downloadParams) {
        DispatchQueue.main.async {
          result([
            "success": downloadResult.success,
            "localPath": downloadResult.localPath,
            "errorMessage": downloadResult.errorMessage
          ])
        }
      } else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "localPath": "",
            "errorMessage": "Failed to create downloader"
          ])
        }
      }
    }
  }

  private func handleDownloadHfFileAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let repoId = args["repoId"] as? String,
          let filename = args["filename"] as? String,
          let localPath = args["localPath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let bearerToken = args["bearerToken"] as? String
    let offline = args["offline"] as? Bool ?? false

    DispatchQueue.global(qos: .userInitiated).async {
      let downloadParams = LlamaMobile.DownloadParams(
        url: "",
        localPath: localPath,
        username: nil,
        password: nil,
        headers: nil,
        progressCallback: nil
      )

      let downloader = LlamaMobile(modelPath: "")
      if let downloadResult = downloader?.downloadHfFile(with: downloadParams, repoId: repoId, filename: filename, bearerToken: bearerToken, offline: offline) {
        DispatchQueue.main.async {
          result([
            "success": downloadResult.success,
            "localPath": downloadResult.localPath,
            "errorMessage": downloadResult.errorMessage
          ])
        }
      } else {
        DispatchQueue.main.async {
          result([
            "success": false,
            "localPath": "",
            "errorMessage": "Failed to create downloader"
          ])
        }
      }
    }
  }

  private func handleGenerateOpenAICompletionAsync(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let contextHandle = args["contextHandle"] as? Int,
          let openAIJSON = args["openAIJSON"] as? String,
          let llamaMobile = contexts[contextHandle] else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing required parameters", details: nil))
      return
    }

    let grammar = args["grammar"] as? String

    DispatchQueue.global(qos: .userInitiated).async {
      if let data = openAIJSON.data(using: .utf8),
         let json = try? JSONSerialization.jsonObject(with: data, options: []),
         let openAIRequest = json as? [String: Any],
         let chatMessages = openAIRequest["messages"] as? [[String: String]] {
        
        var messages: [LlamaMobile.ChatMessage] = []
        for msg in chatMessages {
          if let role = msg["role"], let content = msg["content"] {
            messages.append(LlamaMobile.ChatMessage(role: role, content: content))
          }
        }

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
          DispatchQueue.main.async {
            result(resultDict)
          }
        } else {
          DispatchQueue.main.async {
            result(FlutterError(code: "OPENAI_COMPLETION_FAILED", message: "Failed to generate OpenAI completion", details: nil))
          }
        }
      } else {
        DispatchQueue.main.async {
          result(FlutterError(code: "INVALID_OPENAI_JSON", message: "Failed to parse OpenAI JSON format", details: nil))
        }
      }
    }
  }
}
