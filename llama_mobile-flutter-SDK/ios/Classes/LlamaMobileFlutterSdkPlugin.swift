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
    case "generateCompletion":
      handleGenerateCompletion(call: call, result: result)
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

  private func handleGenerateCompletion(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let llamaMobile = llamaMobile else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "LlamaMobile not initialized. Call loadModel first.", details: nil))
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

  private func handleRelease(call: FlutterMethodCall, result: @escaping FlutterResult) {
    llamaMobile = nil // This will trigger deinit and release resources
    result(nil)
  }
}
