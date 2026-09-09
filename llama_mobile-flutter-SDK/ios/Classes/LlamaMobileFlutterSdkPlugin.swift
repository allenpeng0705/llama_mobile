// LlamaMobileFlutterSdkPlugin.swift — Flutter iOS plugin (v2, M6)
//
// Implements the `llama_mobile_flutter_sdk/v2` method channel verbs used by the
// Dart LlamaEngine wrapper: version / open / generate / abort / modelInfo /
// close. Heavy work (open/generate/modelInfo) runs off the main thread; results
// and errors are delivered on the main thread (§8). One engine per client
// handle; generation is single-flight; `abort` targets the running request id.

import Flutter
import UIKit
import llama_mobile

extension LlamaError {
  /// v2 status code (mirrors llama_mobile_status_t).
  var statusCode: Int {
    switch self {
    case .invalidArgument: return -1
    case .samplerInitFailed: return -2
    case .generationFailed: return -3
    case .modelLoadFailed: return -4
    case .modelNotFound: return -5
    case .io: return -6
    case .unsupported: return -7
    case .outOfMemory: return -8
    case .contextFull: return -9
    case .aborted: return -10
    case .notInitialized: return -11
    case .network: return -12
    case .checksum: return -13
    case .alreadyRunning: return -14
    case .unknown: return 0
    }
  }
}

public class LlamaMobileFlutterSdkPlugin: NSObject, FlutterPlugin {

  private final class Entry {
    let engine: LlamaEngine
    var activeRequestId: UInt64 = 0
    init(_ engine: LlamaEngine) { self.engine = engine }
  }

  private let lock = NSLock()
  private var entries: [Int: Entry] = [:]
  private var nextHandle = 1

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "llama_mobile_flutter_sdk/v2",
                                       binaryMessenger: registrar.messenger())
    let instance = LlamaMobileFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "version":
      if let v = llama_mobile_version() {
        result(String(cString: v.pointee.string))
      } else {
        result("")
      }
    case "open":
      open(call, result: result)
    case "generate":
      generate(call, result: result)
    case "abort":
      abort(call, result: result)
    case "modelInfo":
      modelInfo(call, result: result)
    case "initMultimodal":
      initMultimodal(call, result: result)
    case "tokenize":
      tokenize(call, result: result)
    case "detokenize":
      detokenize(call, result: result)
    case "embed":
      embed(call, result: result)
    case "close":
      close(call, result: result)
    case "releaseMultimodal":
      releaseMultimodal(call, result: result)
    case "multimodalEnabled":
      boolProp(call, result: result, read: { try $0.multimodalEnabled() })
    case "supportsVision":
      boolProp(call, result: result, read: { try $0.multimodalSupportsVision() })
    case "supportsAudio":
      boolProp(call, result: result, read: { try $0.multimodalSupportsAudio() })
    case "ttsInit":
      ttsInit(call, result: result)
    case "ttsSpeak":
      ttsSpeak(call, result: result)
    case "ttsRelease":
      ttsReleaseAction(call, result: result)
    case "ttsEnabled":
      boolProp(call, result: result, read: { try $0.ttsEnabled() })
    default:
      result(err(-7, message: "Unknown method \(call.method)"))
    }
  }

  // MARK: helpers

  private func err(_ code: Int, message: String) -> FlutterError {
    FlutterError(code: "\(code)", message: message, details: nil)
  }

  private func err(_ e: LlamaError) -> FlutterError {
    err(e.statusCode, message: "\(e)")
  }

  private func onMain(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
  }

  private func entry(_ handle: Int) -> Entry? {
    lock.lock(); defer { lock.unlock() }
    return entries[handle]
  }

  private func takeEntry(_ handle: Int) -> Entry? {
    lock.lock(); defer { lock.unlock() }
    return entries.removeValue(forKey: handle)
  }

  private func register(_ engine: LlamaEngine) -> Int {
    lock.lock(); defer { lock.unlock() }
    let h = nextHandle
    nextHandle += 1
    entries[h] = Entry(engine)
    return h
  }

  private func dict(_ args: Any?) -> [String: Any]? {
    args as? [String: Any]
  }

  private func string(_ dict: [String: Any], _ key: String) -> String? {
    dict[key] as? String
  }

  private func int(_ dict: [String: Any], _ key: String, _ def: Int) -> Int {
    (dict[key] as? NSNumber)?.intValue ?? def
  }

  private func bool(_ dict: [String: Any], _ key: String, _ def: Bool) -> Bool {
    (dict[key] as? NSNumber)?.boolValue ?? def
  }

  // MARK: open

  private func open(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let d = dict(call.arguments), let path = string(d, "modelPath"), !path.isEmpty else {
      result(err(-1, message: "modelPath required")); return
    }
    var config = LlamaModelConfig(modelPath: path)
    config.nCtx = Int32(int(d, "nCtx", 2048))
    config.nBatch = Int32(int(d, "nBatch", 512))
    config.nUBatch = Int32(int(d, "nUBatch", 512))
    config.nThreads = Int32(int(d, "nThreads", 0))
    config.nGpuLayers = Int32(int(d, "nGpuLayers", 0))
    var flags: LlamaContextFlags = []
    if bool(d, "useMmap", true) { flags.insert(.mmap) }
    if bool(d, "useMlock", false) { flags.insert(.mlock) }
    if bool(d, "embedding", false) { flags.insert(.embedding) }
    if bool(d, "flashAttention", false) { flags.insert(.flashAttn) }
    if bool(d, "chat", true) { flags.insert(.chat) }
    config.flags = flags
    config.kvCacheTypeK = string(d, "kvCacheTypeK")
    config.kvCacheTypeV = string(d, "kvCacheTypeV")
    config.chatTemplate = string(d, "chatTemplate")
    config.systemPrompt = string(d, "systemPrompt")

    Task.detached(priority: .userInitiated) {
      do {
        let engine = try LlamaEngine.open(config)
        let handle = self.register(engine)
        self.onMain { result(handle) }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-4, message: "\(error)")) }
      }
    }
  }

  // MARK: generate

  private func generate(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = dict(call.arguments) else {
      result(err(-1, message: "arguments required")); return
    }
    let handle = int(args, "handle", -1)
    guard let entry = entry(handle), let rq = dict(args["request"]) else {
      result(err(-11, message: "no engine for handle \(handle)")); return
    }
    let request = parse(request: rq)

    Task.detached(priority: .userInitiated) {
      var text = ""
      var stopValue = 4
      var promptTokens = 0
      var generated = 0
      var failure: LlamaError? = nil
      do {
        for try await event in entry.engine.generateStream(request) {
          switch event {
          case .started(let id):
            self.lock.lock(); entry.activeRequestId = id; self.lock.unlock()
          case .token(let t):
            text += t
          case .done(let r):
            stopValue = Int(r.stopReason.rawValue)
            promptTokens = Int(r.usage.promptTokens)
            generated = Int(r.usage.generatedTokens)
          case .failed(let e):
            failure = e
          }
        }
      } catch let e as LlamaError {
        failure = e
      } catch {
        failure = .generationFailed
      }
      self.lock.lock(); entry.activeRequestId = 0; self.lock.unlock()

      if let failure {
        self.onMain { result(self.err(failure)) }
        return
      }
      self.onMain {
        result([
          "text": text,
          "stopReason": stopValue,
          "promptTokens": promptTokens,
          "generatedTokens": generated,
        ])
      }
    }
  }

  private func parse(request rq: [String: Any]) -> LlamaGenerationRequest {
    let sampling = (rq["sampling"] as? [String: Any]) ?? [:]
    // Prefer messages when present. Dart sends prompt:null for chat mode;
    // never coerce that to "" — an empty non-nil prompt confuses the C layer
    // ("exactly one of prompt or messages").
    let roles = (rq["roles"] as? [String]) ?? []
    let contents = (rq["contents"] as? [String]) ?? []
    let promptRaw = string(rq, "prompt")
    let promptNonEmpty = (promptRaw?.isEmpty == false) ? promptRaw : nil

    var req: LlamaGenerationRequest
    if roles.count == contents.count && !roles.isEmpty {
      req = LlamaGenerationRequest(
        messages: zip(roles, contents).map { LlamaMessage(role: $0.0, content: $0.1) }
      )
    } else if let promptNonEmpty {
      req = LlamaGenerationRequest(prompt: promptNonEmpty)
    } else {
      req = LlamaGenerationRequest(messages: [])
    }

    req.maxTokens = Int32(int(rq, "maxTokens", 128))
    req.grammar = string(rq, "grammar")
    req.jsonSchema = string(rq, "jsonSchema")
    req.stopSequences = (rq["stopSequences"] as? [String]) ?? []
    let mediaPaths = (rq["mediaPaths"] as? [String]) ?? []
    if !mediaPaths.isEmpty {
        req.media = mediaPaths.map { LlamaMedia(path: $0) }
    }

    var s = LlamaSampling()
    s.seed = Int32(int(sampling, "seed", -1))
    s.temperature = (sampling["temperature"] as? NSNumber)?.floatValue ?? 0.8
    s.topK = Int32(int(sampling, "topK", 40))
    s.topP = (sampling["topP"] as? NSNumber)?.floatValue ?? 0.95
    s.minP = (sampling["minP"] as? NSNumber)?.floatValue ?? 0.05
    s.typicalP = (sampling["typicalP"] as? NSNumber)?.floatValue ?? 1.0
    s.penaltyRepeat = (sampling["penaltyRepeat"] as? NSNumber)?.floatValue ?? 1.1
    s.penaltyLastN = Int32(int(sampling, "penaltyLastN", 64))
    s.penaltyFreq = (sampling["penaltyFreq"] as? NSNumber)?.floatValue ?? 0
    s.penaltyPresent = (sampling["penaltyPresent"] as? NSNumber)?.floatValue ?? 0
    s.mirostat = Int32(int(sampling, "mirostat", 0))
    s.mirostatTau = (sampling["mirostatTau"] as? NSNumber)?.floatValue ?? 5.0
    s.mirostatEta = (sampling["mirostatEta"] as? NSNumber)?.floatValue ?? 0.1
    s.ignoreEos = bool(sampling, "ignoreEos", false)
    req.sampling = s
    return req
  }


  // MARK: tokenize / detokenize / embed

  private func tokenize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let o = call.arguments as? [String: Any],
          let handle = (o["handle"] as? NSNumber)?.intValue,
          let text = o["text"] as? String,
          let entry = entry(handle) else {
      result(err(-11, message: "no engine / text for handle"))
      return
    }
    Task.detached {
      do {
        let tokens = try entry.engine.tokenize(text)
        self.onMain { result(tokens.map { Int($0) }) }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-3, message: "\(error)")) }
      }
    }
  }

  private func detokenize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let o = call.arguments as? [String: Any],
          let handle = (o["handle"] as? NSNumber)?.intValue,
          let raw = o["tokens"] as? [NSNumber],
          let entry = entry(handle) else {
      result(err(-11, message: "no engine / tokens for handle"))
      return
    }
    let tokens = raw.map { $0.int32Value }
    Task.detached {
      do {
        let text = try entry.engine.detokenize(tokens)
        self.onMain { result(text) }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-3, message: "\(error)")) }
      }
    }
  }

  private func embed(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let o = call.arguments as? [String: Any],
          let handle = (o["handle"] as? NSNumber)?.intValue,
          let texts = o["texts"] as? [String],
          let entry = entry(handle) else {
      result(err(-11, message: "no engine / texts for handle"))
      return
    }
    Task.detached {
      do {
        let rows = try entry.engine.embed(texts)
        self.onMain { result(rows.map { $0.map { NSNumber(value: $0) } }) }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-3, message: "\(error)")) }
      }
    }
  }

  // MARK: initMultimodal

  private func initMultimodal(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let o = call.arguments as? [String: Any],
          let handle = (o["handle"] as? NSNumber)?.intValue,
          let mmproj = o["mmprojPath"] as? String,
          let entry = entry(handle) else {
      result(err(-11, message: "no engine / mmproj for handle"))
      return
    }
    Task.detached {
      do {
        try entry.engine.initMultimodal(mmprojPath: mmproj)
        self.onMain { result(true) }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-4, message: "\(error)")) }
      }
    }
  }

  // MARK: abort / modelInfo / close

  private func abort(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = dict(call.arguments) else {
      result(err(-1, message: "arguments required")); return
    }
    let handle = int(args, "handle", -1)
    guard let entry = entry(handle) else {
      result(err(-11, message: "no engine for handle \(handle)")); return
    }
    let requestId: UInt64
    lock.lock(); requestId = entry.activeRequestId; lock.unlock()
    if requestId == 0 {
      result(false)
      return
    }
    Task.detached {
      do {
        try entry.engine.abort(requestId: requestId)
        self.onMain { result(true) }
      } catch {
        self.onMain { result(false) }
      }
    }
  }

  private func modelInfo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = dict(call.arguments) else {
      result(err(-1, message: "arguments required")); return
    }
    let handle = int(args, "handle", -1)
    guard let entry = entry(handle) else {
      result(err(-11, message: "no engine for handle \(handle)")); return
    }
    Task.detached {
      do {
        let info = try entry.engine.modelInfo()
        self.onMain {
          result([
            "nCtx": info.nCtx,
            "nEmbd": info.nEmbd,
            "modelSizeBytes": info.sizeBytes,
            "nParams": info.nParams,
            "description": info.description,
          ])
        }
      } catch let e as LlamaError {
        self.onMain { result(self.err(e)) }
      } catch {
        self.onMain { result(self.err(-11, message: "\(error)")) }
      }
    }
  }

  private func close(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let handle = dict(call.arguments).map { int($0, "handle", -1) } ?? -1
    let entry = takeEntry(handle)
    Task.detached {
      entry?.engine.close()
      self.onMain { result(nil) }
    }
  }
  // MARK: full-surface channel handlers (v2 parity)

  private func releaseMultimodal(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let handle = argInt(call, "handle")
    guard let e = entry(handle) else { result(err(-11, message: "no engine for handle")); return }
    Task.detached {
      do { try e.engine.releaseMultimodal(); self.onMain { result(true) } }
      catch let er as LlamaError { self.onMain { result(self.err(er)) } }
      catch { self.onMain { result(self.err(-3, message: "\(error)")) } }
    }
  }

  private func ttsReleaseAction(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let handle = argInt(call, "handle")
    guard let e = entry(handle) else { result(err(-11, message: "no engine for handle")); return }
    Task.detached {
      do { try e.engine.ttsRelease(); self.onMain { result(true) } }
      catch let er as LlamaError { self.onMain { result(self.err(er)) } }
      catch { self.onMain { result(self.err(-3, message: "\(error)")) } }
    }
  }

  private func boolProp(_ call: FlutterMethodCall, result: @escaping FlutterResult,
                        read: @escaping (LlamaEngine) throws -> Bool) {
    let handle = argInt(call, "handle")
    guard let e = entry(handle) else { result(err(-11, message: "no engine for handle")); return }
    Task.detached {
      do { let v = try read(e.engine); self.onMain { result(v) } }
      catch let er as LlamaError { self.onMain { result(self.err(er)) } }
      catch { self.onMain { result(self.err(-3, message: "\(error)")) } }
    }
  }

  private func ttsInit(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let handle = argInt(call, "handle")
    guard let e = entry(handle),
          let vocoder = (call.arguments as? [String: Any])?["vocoderPath"] as? String
    else { result(err(-1, message: "bad ttsInit args")); return }
    Task.detached {
      do { try e.engine.ttsInit(vocoderModelPath: vocoder); self.onMain { result(true) } }
      catch let er as LlamaError { self.onMain { result(self.err(er)) } }
      catch { self.onMain { result(self.err(-3, message: "\(error)")) } }
    }
  }

  private func ttsSpeak(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let handle = argInt(call, "handle")
    guard let e = entry(handle),
          let args = call.arguments as? [String: Any],
          let text = args["text"] as? String
    else { result(err(-1, message: "bad ttsSpeak args")); return }
    let rate = Int32(args["sampleRate"] as? Int ?? 24000)
    let speed = args["speed"] as? Float ?? 1.0
    Task.detached {
      do {
        let out = try e.engine.ttsSpeak(text: text, sampleRate: rate, speed: speed)
        let ns = out.pcm.map { NSNumber(value: $0) }
        self.onMain { result(ns) }
      } catch let er as LlamaError { self.onMain { result(self.err(er)) } }
      catch { self.onMain { result(self.err(-3, message: "\(error)")) } }
    }
  }

  private func argInt(_ call: FlutterMethodCall, _ key: String) -> Int {
    ((call.arguments as? [String: Any])?[key] as? NSNumber)?.intValue ?? -1
  }

}
