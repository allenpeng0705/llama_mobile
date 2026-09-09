// LlamaMobileCapacitorPlugin.swift — Capacitor iOS plugin (v2, M7)
//
// Implements the `LlamaMobile` bridge used by the v2 TypeScript wrapper:
// libraryVersion / open / generate / abort / modelInfo / close. Heavy work runs
// off the main thread (Task.detached) and calls resolve on the main thread
// (§8). Generation is single-flight per engine; abort targets the request id
// reported by the stream's `.started` event. Registered name: "LlamaMobile".

import Foundation
@preconcurrency import Capacitor
import llama_mobile

@objc(LlamaMobileCapacitorPlugin)
public class LlamaMobileCapacitorPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "LlamaMobile"
    public let jsName = "LlamaMobile"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "libraryVersion", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "generate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "abort", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "modelInfo", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "initMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "releaseMultimodal", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "multimodalEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "supportsVision", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "supportsAudio", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "tokenize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "detokenize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "embed", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ttsEnabled", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ttsInit", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ttsSpeak", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "ttsRelease", returnType: CAPPluginReturnPromise),
    ]

    private final class Entry {
        let engine: LlamaEngine
        var activeRequestId: UInt64 = 0
        init(_ engine: LlamaEngine) { self.engine = engine }
    }

    private let lock = NSLock()
    private var entries: [Int: Entry] = [:]
    private var nextHandle = 1

    // MARK: helpers

    private func onMain(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    private func reject(_ call: CAPPluginCall, code: Int, message: String) {
        onMain { call.reject(message, "\(code)", nil) }
    }

    private func reject(_ call: CAPPluginCall, _ error: LlamaError) {
        reject(call, code: Self.statusCode(error), message: "\(error)")
    }

    private static func statusCode(_ e: LlamaError) -> Int {
        switch e {
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

    private func opt(_ call: CAPPluginCall, _ key: String) -> Any? {
        call.options[key]
    }

    private func str(_ value: Any?, _ key: String) -> String? {
        (value as? [String: Any])?[key] as? String
    }

    private func int(_ value: Any?, _ key: String, _ def: Int) -> Int {
        ((value as? [String: Any])?[key] as? NSNumber)?.intValue ?? def
    }

    private func float(_ value: Any?, _ key: String, _ def: Float) -> Float {
        ((value as? [String: Any])?[key] as? NSNumber)?.floatValue ?? def
    }

    private func bool(_ value: Any?, _ key: String, _ def: Bool) -> Bool {
        ((value as? [String: Any])?[key] as? NSNumber)?.boolValue ?? def
    }

    // MARK: bridge methods

    @objc func libraryVersion(_ call: CAPPluginCall) {
        var v = ""
        if let p = llama_mobile_version() { v = String(cString: p.pointee.string) }
        call.resolve(["value": v])
    }

    @objc func open(_ call: CAPPluginCall) {
        let o = call.options ?? [:]
        guard let path = o["modelPath"] as? String, !path.isEmpty else {
            reject(call, code: -1, message: "modelPath required")
            return
        }
        var config = LlamaModelConfig(modelPath: path)
        config.nCtx = Int32(int(o, "nCtx", 2048))
        config.nBatch = Int32(int(o, "nBatch", 512))
        config.nUBatch = Int32(int(o, "nUBatch", 512))
        config.nThreads = Int32(int(o, "nThreads", 0))
        config.nGpuLayers = Int32(int(o, "nGpuLayers", 0))
        var flags: LlamaContextFlags = []
        if bool(o, "useMmap", true) { flags.insert(.mmap) }
        if bool(o, "useMlock", false) { flags.insert(.mlock) }
        if bool(o, "embedding", false) { flags.insert(.embedding) }
        if bool(o, "flashAttention", false) { flags.insert(.flashAttn) }
        if bool(o, "chat", true) { flags.insert(.chat) }
        config.flags = flags
        config.kvCacheTypeK = str(o, "kvCacheTypeK")
        config.kvCacheTypeV = str(o, "kvCacheTypeV")
        config.chatTemplate = str(o, "chatTemplate")
        config.systemPrompt = str(o, "systemPrompt")

        Task.detached(priority: .userInitiated) {
            do {
                let engine = try LlamaEngine.open(config)
                let handle = self.register(engine)
                self.onMain { call.resolve(["value": handle]) }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.reject(call, code: -4, message: "\(error)")
            }
        }
    }

    @objc func generate(_ call: CAPPluginCall) {
        let o = call.options ?? [:]
        guard let handle = (o["handle"] as? NSNumber)?.intValue,
              let entry = entry(handle) else {
            reject(call, code: -11, message: "no engine / request for handle")
            return
        }
        // The TS wrapper sends the request fields flat on the options object
        // ({ handle, prompt/roles/contents/… }); some callers nest them under
        // "request". Accept both shapes.
        let rq: [String: Any]
        if let nested = o["request"] as? [String: Any] {
            rq = nested
        } else {
            // call.options is [AnyHashable: Any]; rebuild with String keys.
            rq = Dictionary(
                uniqueKeysWithValues: o.map { (String(describing: $0.key), $0.value) })
        }
        let request = parse(request: rq)

        Task.detached(priority: .userInitiated) {
            var text = ""
            var doneText: String?
            var stopValue = 4
            var promptTokens = 0
            var generated = 0
            var failure: LlamaError?
            do {
                for try await event in entry.engine.generateStream(request) {
                    switch event {
                    case .started(let id):
                        self.lock.lock(); entry.activeRequestId = id; self.lock.unlock()
                    case .token(let t): text += t
                    case .done(let r):
                        doneText = r.text
                        stopValue = Int(r.stopReason.rawValue)
                        promptTokens = Int(r.usage.promptTokens)
                        generated = Int(r.usage.generatedTokens)
                    case .failed(let e): failure = e
                    }
                }
            } catch let e as LlamaError {
                failure = e
            } catch {
                failure = .generationFailed
            }
            self.lock.lock(); entry.activeRequestId = 0; self.lock.unlock()
            if let doneText { text = doneText }

            if let failure {
                self.reject(call, failure)
                return
            }
            self.onMain {
                call.resolve([
                    "text": text,
                    "stopReason": stopValue,
                    "promptTokens": promptTokens,
                    "generatedTokens": generated,
                ])
            }
        }
    }

    @objc func abort(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle) else {
            reject(call, code: -11, message: "no engine for handle")
            return
        }
        lock.lock(); let requestId = entry.activeRequestId; lock.unlock()
        guard requestId != 0 else {
            call.resolve(["value": false])
            return
        }
        Task.detached {
            do {
                try entry.engine.abort(requestId: requestId)
                self.onMain { call.resolve(["value": true]) }
            } catch {
                self.onMain { call.resolve(["value": false]) }
            }
        }
    }

    @objc func modelInfo(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle) else {
            reject(call, code: -11, message: "no engine for handle")
            return
        }
        Task.detached {
            do {
                let info = try entry.engine.modelInfo()
                self.onMain {
                    call.resolve([
                        "nCtx": info.nCtx,
                        "nEmbd": info.nEmbd,
                        "modelSizeBytes": info.sizeBytes,
                        "nParams": info.nParams,
                        "description": info.description,
                    ])
                }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.reject(call, code: -11, message: "\(error)")
            }
        }
    }


    @objc func initMultimodal(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle),
              let mmproj = (call.options ?? [:])["mmprojPath"] as? String else {
            reject(call, code: -11, message: "no engine / mmproj for handle")
            return
        }
        Task.detached {
            do {
                try entry.engine.initMultimodal(mmprojPath: mmproj)
                self.onMain { call.resolve(["value": true]) }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.onMain { call.resolve(["value": false]) }
            }
        }
    }

    @objc func tokenize(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle),
              let text = (call.options ?? [:])["text"] as? String else {
            reject(call, code: -11, message: "no engine / text for handle")
            return
        }
        Task.detached {
            do {
                let tokens = try entry.engine.tokenize(text)
                self.onMain { call.resolve(["value": tokens.map { Int($0) }]) }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.reject(call, code: -3, message: "\(error)")
            }
        }
    }

    @objc func detokenize(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle),
              let raw = (call.options ?? [:])["tokens"] as? [NSNumber] else {
            reject(call, code: -11, message: "no engine / tokens for handle")
            return
        }
        let tokens = raw.map { $0.int32Value }
        Task.detached {
            do {
                let text = try entry.engine.detokenize(tokens)
                self.onMain { call.resolve(["value": text]) }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.reject(call, code: -3, message: "\(error)")
            }
        }
    }

    @objc func embed(_ call: CAPPluginCall) {
        guard let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue,
              let entry = entry(handle),
              let texts = (call.options ?? [:])["texts"] as? [String] else {
            reject(call, code: -11, message: "no engine / texts for handle")
            return
        }
        Task.detached {
            do {
                let rows = try entry.engine.embed(texts)
                self.onMain { call.resolve(["value": rows.map { $0.map { NSNumber(value: $0) } }]) }
            } catch let e as LlamaError {
                self.reject(call, e)
            } catch {
                self.reject(call, code: -3, message: "\(error)")
            }
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        let handle = (((call.options ?? [:])["handle"] as? NSNumber))?.intValue ?? -1
        let entry = takeEntry(handle)
        Task.detached {
            entry?.engine.close()
            self.onMain { call.resolve() }
        }
    }

        // MARK: full-surface bridge (v2 parity)

    @objc func releaseMultimodal(_ call: CAPPluginCall) {
        guard let e = entryFor(call) else { call.reject("no engine"); return }
        Task.detached {
            do { try e.engine.releaseMultimodal(); self.onMain { call.resolve(["value": true]) } }
            catch let er as LlamaError { self.onMain { call.reject("\(er)") } }
            catch { self.onMain { call.reject("\(error)") } }
        }
    }

    @objc func multimodalEnabled(_ call: CAPPluginCall) { boolBridge(call) { try $0.multimodalEnabled() } }
    @objc func supportsVision(_ call: CAPPluginCall) { boolBridge(call) { try $0.multimodalSupportsVision() } }
    @objc func supportsAudio(_ call: CAPPluginCall) { boolBridge(call) { try $0.multimodalSupportsAudio() } }
    @objc func ttsEnabled(_ call: CAPPluginCall) { boolBridge(call) { try $0.ttsEnabled() } }

    @objc func ttsInit(_ call: CAPPluginCall) {
        guard let e = entryFor(call), let voc = call.options?["vocoderPath"] as? String else {
            call.reject("no engine / vocoderPath"); return
        }
        Task.detached {
            do { try e.engine.ttsInit(vocoderModelPath: voc); self.onMain { call.resolve(["value": true]) } }
            catch let er as LlamaError { self.onMain { call.reject("\(er)") } }
            catch { self.onMain { call.reject("\(error)") } }
        }
    }

    @objc func ttsSpeak(_ call: CAPPluginCall) {
        guard let e = entryFor(call), let text = call.options?["text"] as? String else {
            call.reject("no engine / text"); return
        }
        let rate = Int32((call.options?["sampleRate"] as? NSNumber)?.intValue ?? 24000)
        let speed = (call.options?["speed"] as? NSNumber)?.floatValue ?? 1.0
        Task.detached {
            do {
                let out = try e.engine.ttsSpeak(text: text, sampleRate: rate, speed: speed)
                let samples = out.pcm.map { NSNumber(value: $0) }
                self.onMain { call.resolve(["value": samples]) }
            } catch let er as LlamaError { self.onMain { call.reject("\(er)") } }
            catch { self.onMain { call.reject("\(error)") } }
        }
    }

    @objc func ttsRelease(_ call: CAPPluginCall) {
        guard let e = entryFor(call) else { call.reject("no engine"); return }
        Task.detached {
            do { try e.engine.ttsRelease(); self.onMain { call.resolve(["value": true]) } }
            catch let er as LlamaError { self.onMain { call.reject("\(er)") } }
            catch { self.onMain { call.reject("\(error)") } }
        }
    }

    private func entryFor(_ call: CAPPluginCall) -> Entry? {
        guard let handle = (call.options?["handle"] as? NSNumber)?.intValue else { return nil }
        lock.lock(); defer { lock.unlock() }
        return entries[handle]
    }

    private func boolBridge(_ call: CAPPluginCall, read: @escaping (LlamaEngine) throws -> Bool) {
        guard let e = entryFor(call) else { call.reject("no engine"); return }
        Task.detached {
            do { let v = try read(e.engine); self.onMain { call.resolve(["value": v]) } }
            catch let er as LlamaError { self.onMain { call.reject("\(er)") } }
            catch { self.onMain { call.reject("\(error)") } }
        }
    }

// MARK: request parsing

    private func parse(request rq: [String: Any]) -> LlamaGenerationRequest {
        let sampling = (rq["sampling"] as? [String: Any]) ?? [:]

        // Chat messages (parallel roles/contents) take precedence over the raw
        // prompt. Never coerce a missing/empty prompt to "" — the C contract is
        // "exactly one of prompt or messages", and an empty non-nil prompt with
        // no messages would be treated as an empty raw prompt.
        let roles = (rq["roles"] as? [String]) ?? []
        let contents = (rq["contents"] as? [String]) ?? []
        let hasMessages = roles.count == contents.count && !roles.isEmpty
        let promptRaw = (rq["prompt"] as? String)?.trimmingCharacters(in: .whitespaces)
        let prompt: String? =
            (promptRaw == nil || promptRaw!.isEmpty || hasMessages) ? nil : promptRaw

        var req: LlamaGenerationRequest
        if hasMessages {
            req = LlamaGenerationRequest(messages: zip(roles, contents).map {
                LlamaMessage(role: $0.0, content: $0.1)
            })
        } else {
            req = LlamaGenerationRequest(prompt: prompt ?? "")
        }
        req.maxTokens = Int32(int(rq, "maxTokens", 128))
        req.grammar = rq["grammar"] as? String
        req.jsonSchema = rq["jsonSchema"] as? String
        req.stopSequences = (rq["stopSequences"] as? [String]) ?? []

        let mediaPaths = (rq["mediaPaths"] as? [String]) ?? []
        if !mediaPaths.isEmpty {
            req.media = mediaPaths.map { LlamaMedia(path: $0) }
        }

        var s = LlamaSampling()
        s.seed = Int32(int(sampling, "seed", -1))
        s.temperature = float(sampling, "temperature", 0.8)
        s.topK = Int32(int(sampling, "topK", 40))
        s.topP = float(sampling, "topP", 0.95)
        s.minP = float(sampling, "minP", 0.05)
        s.typicalP = float(sampling, "typicalP", 1.0)
        s.penaltyRepeat = float(sampling, "penaltyRepeat", 1.1)
        s.penaltyLastN = Int32(int(sampling, "penaltyLastN", 64))
        s.penaltyFreq = float(sampling, "penaltyFreq", 0)
        s.penaltyPresent = float(sampling, "penaltyPresent", 0)
        s.mirostat = Int32(int(sampling, "mirostat", 0))
        s.mirostatTau = float(sampling, "mirostatTau", 5.0)
        s.mirostatEta = float(sampling, "mirostatEta", 0.1)
        s.ignoreEos = bool(sampling, "ignoreEos", false)
        req.sampling = s
        return req
    }
}
