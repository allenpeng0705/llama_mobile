// LlamaEngine.swift — llama_mobile v2 iOS wrapper (M4)
//
// Threading contract (docs/api-contract-v2.md §8):
//   * Every heavy operation has a documented sync form (blocks the calling
//     thread — never call from the main/UI thread) and an async form that never
//     blocks the caller.
//   * Async work runs on the engine's private serial queue; events are emitted
//     on that queue. Use `await MainActor.run` in your UI when you need main.
//   * One engine = one active generation; a second concurrent call fails with
//     .alreadyRunning.
//   * Cancellation: streaming yields `.started(requestId)` before the first
//     token; `abort(requestId:)` is thread-safe and stops exactly that request
//     (the generation reports stopReason == .aborted).
//
// Lifetime rule for the C bridge: every C params struct only borrows the
// pointers it holds, so all strings/arrays referenced by a struct must stay
// alive until the blocking C call returns. We keep them in a `CBuf` pool that
// is released (freed) right after each C call — never inside a `withCString`
// closure that would die before the call runs.
//
// This is the iOS Swift wrapper for the v2 API (llama_mobile_v2.h). The v1
// public surface (LlamaMobile facade, v1 *_c/*_t C ABI) has been fully removed
// on this branch (see docs/v1-purge-workplan.md).
//
// The iOS framework's module.modulemap exposes the v2 header as its umbrella,
// so `import llama_mobile` resolves to the v2 C API only.

import Foundation
import llama_mobile   // exposes the v2 C API (lib/llama_mobile_v2.h) via the module

// MARK: - Errors

public enum LlamaError: Error, Equatable, Sendable {
    case invalidArgument
    case samplerInitFailed
    case generationFailed
    case modelLoadFailed
    case modelNotFound
    case io
    case unsupported
    case outOfMemory
    case contextFull
    case aborted
    case notInitialized
    case network
    case checksum
    case alreadyRunning
    case unknown(Int32)

    public init(status: llama_mobile_status_t) {
        if status == LLAMA_MOBILE_OK { self = .generationFailed } // OK is not an error
        else if status == LLAMA_MOBILE_ERR_INVALID_ARGUMENT { self = .invalidArgument }
        else if status == LLAMA_MOBILE_ERR_SAMPLER_INIT { self = .samplerInitFailed }
        else if status == LLAMA_MOBILE_ERR_GENERATION { self = .generationFailed }
        else if status == LLAMA_MOBILE_ERR_MODEL_LOAD { self = .modelLoadFailed }
        else if status == LLAMA_MOBILE_ERR_MODEL_NOT_FOUND { self = .modelNotFound }
        else if status == LLAMA_MOBILE_ERR_IO { self = .io }
        else if status == LLAMA_MOBILE_ERR_UNSUPPORTED { self = .unsupported }
        else if status == LLAMA_MOBILE_ERR_OOM { self = .outOfMemory }
        else if status == LLAMA_MOBILE_ERR_CONTEXT_FULL { self = .contextFull }
        else if status == LLAMA_MOBILE_ERR_ABORTED { self = .aborted }
        else if status == LLAMA_MOBILE_ERR_NOT_INITIALIZED { self = .notInitialized }
        else if status == LLAMA_MOBILE_ERR_NETWORK { self = .network }
        else if status == LLAMA_MOBILE_ERR_CHECKSUM { self = .checksum }
        else if status == LLAMA_MOBILE_ERR_ALREADY_RUNNING { self = .alreadyRunning }
        else { self = .unknown(status.rawValue) }
    }
}

// MARK: - Value types (mirror the C params 1:1)

public enum LlamaEngineSelect: Int32, Sendable {
    case auto = 0, cpu, metal, vulkan, opencl
}

public struct LlamaContextFlags: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let mmap       = LlamaContextFlags(rawValue: UInt32(LLAMA_MOBILE_CTX_MMAP))
    public static let mlock      = LlamaContextFlags(rawValue: UInt32(LLAMA_MOBILE_CTX_MLOCK))
    public static let embedding  = LlamaContextFlags(rawValue: UInt32(LLAMA_MOBILE_CTX_EMBEDDING))
    public static let flashAttn  = LlamaContextFlags(rawValue: UInt32(LLAMA_MOBILE_CTX_FLASH_ATTN))
    public static let chat       = LlamaContextFlags(rawValue: UInt32(LLAMA_MOBILE_CTX_CHAT))
}

public struct LlamaModelConfig: Sendable {
    public var modelPath: String
    public var engine: LlamaEngineSelect = .auto
    public var nGpuLayers: Int32 = 0
    public var nCtx: Int32 = 2048          // 0 = model default
    public var nBatch: Int32 = 512
    public var nUBatch: Int32 = 512
    public var nThreads: Int32 = 0         // 0 = auto
    public var flags: LlamaContextFlags = [.mmap, .chat]
    public var kvCacheTypeK: String? = nil
    public var kvCacheTypeV: String? = nil
    public var chatTemplate: String? = nil
    public var systemPrompt: String? = nil
    public var imageMinTokens: Int32 = -1
    /// Called on the loading thread with progress 0…1. Return false to abort the load.
    public var loadProgress: (@Sendable (Float) -> Bool)? = nil

    public init(modelPath: String) { self.modelPath = modelPath }
}

public struct LlamaSampling: Sendable {
    public var seed: Int32 = -1
    public var temperature: Float = 0.8     // 0 = greedy
    public var topK: Int32 = 40
    public var topP: Float = 0.95
    public var minP: Float = 0.05
    public var typicalP: Float = 1.0
    public var penaltyRepeat: Float = 1.1
    public var penaltyLastN: Int32 = 64
    public var penaltyFreq: Float = 0
    public var penaltyPresent: Float = 0
    public var mirostat: Int32 = 0
    public var mirostatTau: Float = 5.0
    public var mirostatEta: Float = 0.1
    public var ignoreEos: Bool = false
    public init() {}
}

public struct LlamaMessage: Sendable {
    public var role: String
    public var content: String
    public var name: String? = nil
    public var toolName: String? = nil
    public var toolCallId: String? = nil
    public init(role: String, content: String) { self.role = role; self.content = content }
}

public enum LlamaMediaKind: Int32, Sendable { case path = 0, uri, bytes }

public struct LlamaMedia: Sendable {
    public var kind: LlamaMediaKind
    public var path: String?        // path/uri
    public var bytes: Data?         // bytes
    public var mime: String? = nil
    public init(path: String, mime: String? = nil) { kind = .path; self.path = path; self.mime = mime }
}

public enum LlamaStopReason: Int32, Sendable {
    case eos, word, length, aborted, error
    init(c: llama_mobile_stop_reason_t) {
        if c == LLAMA_MOBILE_STOP_EOS { self = .eos }
        else if c == LLAMA_MOBILE_STOP_WORD { self = .word }
        else if c == LLAMA_MOBILE_STOP_LENGTH { self = .length }
        else if c == LLAMA_MOBILE_STOP_ABORTED { self = .aborted }
        else { self = .error }
    }
}

public struct LlamaGenerationRequest: Sendable {
    /// Exactly one of `prompt` or `messages` is used.
    public var prompt: String? = nil
    public var messages: [LlamaMessage] = []
    public var sampling = LlamaSampling()
    public var maxTokens: Int32 = 128     // -1 = no explicit limit
    public var stopSequences: [String] = []
    public var grammar: String? = nil     // inline GBNF content
    public var jsonSchema: String? = nil  // real schema→grammar output
    public var tools: String? = nil
    public var toolChoice: String? = "auto"
    public var media: [LlamaMedia] = []
    public init(prompt: String) { self.prompt = prompt }
    public init(messages: [LlamaMessage]) { self.messages = messages }
}

public struct LlamaUsage: Sendable {
    public var promptTokens: Int32
    public var generatedTokens: Int32
    public var timeToFirstTokenMs: Int64
    public var totalMs: Int64
}

public struct LlamaGenerationResult: Sendable {
    public var text: String
    public var stopReason: LlamaStopReason
    public var usage: LlamaUsage
}

public enum LlamaGenerationEvent: Sendable {
    case started(UInt64)             // request id — pass it to abort(requestId:)
    case token(String)
    case done(LlamaGenerationResult)
    case failed(LlamaError)
}

public struct LlamaModelInfo: Sendable {
    public var nCtx: Int32
    public var nEmbd: Int32
    public var sizeBytes: Int64
    public var nParams: Int64
    public var description: String

    public init(nCtx: Int32, nEmbd: Int32, sizeBytes: Int64, nParams: Int64,
                description: String) {
        self.nCtx = nCtx
        self.nEmbd = nEmbd
        self.sizeBytes = sizeBytes
        self.nParams = nParams
        self.description = description
    }
}

// MARK: - Engine

public final class LlamaEngine: @unchecked Sendable {
    private var ctx: llama_mobile_context_t?
    private let queue = DispatchQueue(label: "llama.engine.v2", qos: .userInitiated)
    private let lock = NSLock()

    public var isOpen: Bool { lock.lock(); defer { lock.unlock() }; return ctx != nil }

    // MARK: Sync factory (blocking load — call off the main thread)

    public static func open(_ config: LlamaModelConfig) throws -> LlamaEngine {
        let engine = LlamaEngine()
        try engine.start(config)
        return engine
    }

    // MARK: Async factory (never blocks the caller)

    public static func open(_ config: LlamaModelConfig) async throws -> LlamaEngine {
        try await Task.detached(priority: .userInitiated) { try open(config) }.value
    }

    private init() {}

    private func start(_ config: LlamaModelConfig) throws {
        let cc = UnsafeMutablePointer<llama_mobile_context_config_t>.allocate(capacity: 1)
        defer { cc.deallocate() }
        llama_mobile_context_config_init(cc)

        // All C strings referenced by `cc` live in this pool until create() returns.
        let buf = CBuf()
        defer { buf.release() }
        cc.pointee.model_path = buf.str(config.modelPath)
        cc.pointee.chat_template = buf.strOpt(config.chatTemplate)
        cc.pointee.system_prompt = buf.strOpt(config.systemPrompt)
        cc.pointee.kv_cache_type_k = buf.strOpt(config.kvCacheTypeK)
        cc.pointee.kv_cache_type_v = buf.strOpt(config.kvCacheTypeV)

        switch config.engine {
        case .auto: cc.pointee.engine = LLAMA_MOBILE_ENGINE_AUTO
        case .cpu: cc.pointee.engine = LLAMA_MOBILE_ENGINE_CPU
        case .metal: cc.pointee.engine = LLAMA_MOBILE_ENGINE_METAL
        case .vulkan: cc.pointee.engine = LLAMA_MOBILE_ENGINE_VULKAN
        case .opencl: cc.pointee.engine = LLAMA_MOBILE_ENGINE_OPENCL
        }
        cc.pointee.n_gpu_layers = config.nGpuLayers
        cc.pointee.n_ctx = config.nCtx
        cc.pointee.n_batch = config.nBatch
        cc.pointee.n_ubatch = config.nUBatch
        cc.pointee.n_threads = config.nThreads
        cc.pointee.flags = UInt32(config.flags.rawValue)
        cc.pointee.image_min_tokens = config.imageMinTokens

        // Load progress is delivered through a C trampoline + retained box.
        var progressBox: Unmanaged<ProgressBox>? = nil
        if let callback = config.loadProgress {
            progressBox = Unmanaged.passRetained(ProgressBox(callback))
            cc.pointee.load_progress_cb = Self.progressTrampoline
            cc.pointee.load_progress_user_data = progressBox!.toOpaque()
        }

        var out: llama_mobile_context_t? = nil
        let status = llama_mobile_context_create(cc, &out)
        progressBox?.release()   // C no longer calls the trampoline after create() returns

        guard status == LLAMA_MOBILE_OK, let opened = out else {
            throw LlamaError(status: status)
        }
        lock.lock(); ctx = opened; lock.unlock()
    }

    // MARK: Sync generate (blocking — call off the main thread)

    public func generate(_ request: LlamaGenerationRequest) throws -> LlamaGenerationResult {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        let built = buildParams(request)
        defer { built.free() }
        let result = UnsafeMutablePointer<llama_mobile_generate_result_t>.allocate(capacity: 1)
        defer {
            llama_mobile_generate_result_free(result)
            result.deallocate()
        }
        let status = llama_mobile_generate(c, built.ptr, nil, nil, nil, result)
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
        return convert(result.pointee)
    }

    // MARK: Async generate (never blocks the caller)

    public func generate(_ request: LlamaGenerationRequest) async throws -> LlamaGenerationResult {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    let r = try self.generate(request)
                    continuation.resume(returning: r)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: Stream (token events on the engine queue)

    public func generateStream(_ request: LlamaGenerationRequest) -> AsyncThrowingStream<LlamaGenerationEvent, Error> {
        AsyncThrowingStream { continuation in
            queue.async {
                // `rid` is written by the C layer as soon as generate() starts;
                // the first token callback therefore already sees the real id.
                let rid = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
                rid.initialize(to: 0)
                let box = TokenBox(rid: rid, onStarted: { id in
                    continuation.yield(.started(id))
                }, emit: { text in
                    continuation.yield(.token(text))
                    return true
                })
                let boxPtr = Unmanaged.passRetained(box).toOpaque()
                defer {
                    Unmanaged<TokenBox>.fromOpaque(boxPtr).release()
                    rid.deallocate()
                }
                let callback: llama_mobile_token_cb? = { (token, ud) -> Bool in
                    guard let ud else { return true }
                    let b = Unmanaged<TokenBox>.fromOpaque(ud).takeUnretainedValue()
                    return b.handleToken(token)
                }
                do {
                    guard let c = self.currentContext() else { throw LlamaError.notInitialized }
                    let built = self.buildParams(request)
                    defer { built.free() }
                    let result = UnsafeMutablePointer<llama_mobile_generate_result_t>.allocate(capacity: 1)
                    let status = llama_mobile_generate(c, built.ptr, callback, boxPtr, rid, result)
                    let value = try self.convertChecked(status, result.pointee)
                    llama_mobile_generate_result_free(result)
                    result.deallocate()
                    continuation.yield(.done(value))
                } catch let e as LlamaError {
                    continuation.yield(.failed(e))
                } catch {
                    continuation.yield(.failed(.unknown(0)))
                }
                continuation.finish()
            }
        }
    }

    // MARK: Abort (thread-safe; stops the request started with this id)

    public func abort(requestId: UInt64) throws {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        let status = llama_mobile_abort(c, requestId)
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
    }

    // MARK: Model info (sync; cheap)

    public func modelInfo() throws -> LlamaModelInfo {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        var info = llama_mobile_model_info_t()
        let status = llama_mobile_model_info(c, &info)
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
        defer { llama_mobile_model_info_free(&info) }
        var desc = ""
        if let d = info.description { desc = String(cString: d) }
        return LlamaModelInfo(nCtx: info.n_ctx,
                              nEmbd: info.n_embd,
                              sizeBytes: info.model_size_bytes,
                              nParams: info.n_params,
                              description: desc)
    }

    // MARK: Tokenize / detokenize / embed (sync; cheap)

    public func tokenize(_ text: String) throws -> [Int32] {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        var r = llama_mobile_tokenize_result_t()
        defer { llama_mobile_tokenize_result_free(&r) }
        let status = llama_mobile_tokenize(c, text, nil, 0, &r)
        guard status == LLAMA_MOBILE_OK, let toks = r.tokens else {
            throw LlamaError(status: status)
        }
        var out: [Int32] = []
        out.reserveCapacity(Int(r.n_tokens))
        for i in 0..<Int(r.n_tokens) { out.append(toks[i]) }
        return out
    }

    public func detokenize(_ tokens: [Int32]) throws -> String {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        var outText: UnsafeMutablePointer<CChar>? = nil
        let status = tokens.withUnsafeBufferPointer { buf in
            llama_mobile_detokenize(c, buf.baseAddress, buf.count, &outText)
        }
        defer { if let p = outText { llama_mobile_free_text(p) } }
        guard status == LLAMA_MOBILE_OK, let p = outText else {
            throw LlamaError(status: status)
        }
        return String(cString: p)
    }

    /// Batch embeddings (one row per input text). Requires the context to be
    /// opened with the `.embedding` flag set.
    public func embed(_ texts: [String]) throws -> [[Float]] {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        let buf = CBuf()
        defer { buf.release() }
        var ptrs: [UnsafePointer<CChar>?] = []
        ptrs.reserveCapacity(texts.count)
        for t in texts { ptrs.append(buf.str(t)) }
        var res = llama_mobile_embed_result_t()
        defer { llama_mobile_embed_result_free(&res) }
        let status = ptrs.withUnsafeBufferPointer { b in
            llama_mobile_embed(c, b.baseAddress, texts.count, &res)
        }
        guard status == LLAMA_MOBILE_OK, let values = res.values else {
            throw LlamaError(status: status)
        }
        var rows: [[Float]] = []
        rows.reserveCapacity(Int(res.n_texts))
        for i in 0..<Int(res.n_texts) {
            var row: [Float] = []
            row.reserveCapacity(Int(res.dim))
            for j in 0..<Int(res.dim) {
                row.append(values[i * res.dim + j])
            }
            rows.append(row)
        }
        return rows
    }

    // MARK: Multimodal module (attach an mmproj)

    public func initMultimodal(mmprojPath: String) throws {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        let status = llama_mobile_multimodal_init(c, mmprojPath)
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
    }

    public func releaseMultimodal() throws {
        guard let c = currentContext() else { throw LlamaError.notInitialized }
        let status = llama_mobile_multimodal_release(c)
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
    }

    // MARK: Close (sync; idempotent)

    public func close() {
        lock.lock()
        let c = ctx
        ctx = nil
        lock.unlock()
        if c != nil {
            var owned = c
            llama_mobile_context_destroy(&owned)
        }
    }

    // MARK: - Internals

    private func currentContext() -> llama_mobile_context_t? {
        lock.lock(); defer { lock.unlock() }
        return ctx
    }

    private static let progressTrampoline: @convention(c) (Float, UnsafeMutableRawPointer?) -> Bool = { progress, ud in
        guard let ud else { return true }
        return Unmanaged<ProgressBox>.fromOpaque(ud).takeUnretainedValue().callback(progress)
    }

    private final class ProgressBox {
        let callback: @Sendable (Float) -> Bool
        init(_ c: @escaping @Sendable (Float) -> Bool) { callback = c }
    }

    private final class TokenBox {
        private let rid: UnsafeMutablePointer<UInt64>
        private let onStarted: (UInt64) -> Void
        private let emit: (String) -> Bool
        private var started = false
        init(rid: UnsafeMutablePointer<UInt64>, onStarted: @escaping (UInt64) -> Void,
             emit: @escaping (String) -> Bool) {
            self.rid = rid
            self.onStarted = onStarted
            self.emit = emit
        }
        func handleToken(_ token: UnsafePointer<CChar>?) -> Bool {
            if !started {
                started = true
                onStarted(rid.pointee)
            }
            guard let token else { return true }
            return emit(String(cString: token))
        }
    }

    /// Owns malloc'd C buffers for the duration of one blocking C call.
    private final class CBuf {
        private var owned: [UnsafeMutableRawPointer] = []
        deinit { release() }

        func str(_ s: String) -> UnsafePointer<CChar> {
            let copy = strdup(s)!
            owned.append(copy)
            return UnsafePointer(copy)
        }
        func strOpt(_ s: String?) -> UnsafePointer<CChar>? { s.map { str($0) } }

        func typed<T>(_ type: T.Type, _ count: Int) -> UnsafeMutablePointer<T> {
            let raw = UnsafeMutableRawPointer.allocate(
                byteCount: max(count, 1) * MemoryLayout<T>.stride,
                alignment: MemoryLayout<T>.alignment)
            owned.append(raw)
            return raw.bindMemory(to: T.self, capacity: count)
        }
        func bytes(_ d: Data) -> UnsafePointer<UInt8>? {
            guard d.count > 0 else { return nil }
            let raw = UnsafeMutableRawPointer.allocate(byteCount: d.count, alignment: 1)
            d.copyBytes(to: raw.assumingMemoryBound(to: UInt8.self), count: d.count)
            owned.append(raw)
            return UnsafePointer(raw.assumingMemoryBound(to: UInt8.self))
        }
        func release() {
            for p in owned { free(p) }
            owned.removeAll()
        }
    }

    private struct BuiltParams {
        let ptr: UnsafeMutablePointer<llama_mobile_generate_params_t>
        let buf: CBuf
        func free() {
            ptr.deallocate()
            buf.release()
        }
    }

    private func buildParams(_ request: LlamaGenerationRequest) -> BuiltParams {
        let buf = CBuf()
        let p = UnsafeMutablePointer<llama_mobile_generate_params_t>.allocate(capacity: 1)
        llama_mobile_generate_params_init(p)

        p.pointee.prompt = buf.strOpt(request.prompt)
        if !request.messages.isEmpty {
            let ms = buf.typed(llama_mobile_message_t.self, request.messages.count)
            for (i, m) in request.messages.enumerated() {
                ms[i].role = buf.str(m.role)
                ms[i].content = buf.str(m.content)
                ms[i].name = buf.strOpt(m.name)
                ms[i].tool_name = buf.strOpt(m.toolName)
                ms[i].tool_call_id = buf.strOpt(m.toolCallId)
            }
            p.pointee.messages = UnsafePointer(ms)
            p.pointee.n_messages = request.messages.count
        }
        p.pointee.sampling = convertSampling(request.sampling)
        p.pointee.max_tokens = request.maxTokens

        if !request.stopSequences.isEmpty {
            let seqs = buf.typed(UnsafePointer<CChar>?.self, request.stopSequences.count)
            for (i, s) in request.stopSequences.enumerated() { seqs[i] = buf.str(s) }
            p.pointee.stop_sequences = seqs
            p.pointee.n_stop_sequences = request.stopSequences.count
        }
        p.pointee.grammar = buf.strOpt(request.grammar)
        p.pointee.json_schema = buf.strOpt(request.jsonSchema)
        p.pointee.tools = buf.strOpt(request.tools)
        p.pointee.tool_choice = buf.strOpt(request.toolChoice)

        if !request.media.isEmpty {
            let med = buf.typed(llama_mobile_media_t.self, request.media.count)
            for (i, m) in request.media.enumerated() {
                med[i].kind = llama_mobile_media_kind_t(rawValue: UInt32(m.kind.rawValue))
                med[i].path = buf.strOpt(m.path)
                med[i].bytes = buf.bytes(m.bytes ?? Data())
                med[i].bytes_len = m.bytes?.count ?? 0
                med[i].mime = buf.strOpt(m.mime)
            }
            p.pointee.media = UnsafePointer(med)
            p.pointee.n_media = request.media.count
        }
        return BuiltParams(ptr: p, buf: buf)
    }

    private func convertSampling(_ s: LlamaSampling) -> llama_mobile_sampling_t {
        var c = llama_mobile_sampling_t()
        llama_mobile_sampling_init(&c)
        c.seed = s.seed
        c.temperature = s.temperature
        c.top_k = s.topK
        c.top_p = s.topP
        c.min_p = s.minP
        c.typical_p = s.typicalP
        c.penalty_repeat = s.penaltyRepeat
        c.penalty_last_n = s.penaltyLastN
        c.penalty_freq = s.penaltyFreq
        c.penalty_present = s.penaltyPresent
        c.mirostat = s.mirostat
        c.mirostat_tau = s.mirostatTau
        c.mirostat_eta = s.mirostatEta
        c.ignore_eos = s.ignoreEos
        return c
    }

    private func convertChecked(_ status: llama_mobile_status_t, _ r: llama_mobile_generate_result_t) throws -> LlamaGenerationResult {
        guard status == LLAMA_MOBILE_OK else { throw LlamaError(status: status) }
        return convert(r)
    }

    private func convert(_ r: llama_mobile_generate_result_t) -> LlamaGenerationResult {
        var text = ""
        if let t = r.text { text = String(cString: t) }
        let usage = LlamaUsage(promptTokens: r.usage.prompt_tokens,
                               generatedTokens: r.usage.generated_tokens,
                               timeToFirstTokenMs: r.usage.time_to_first_token_ms,
                               totalMs: r.usage.total_ms)
        return LlamaGenerationResult(text: text,
                                     stopReason: LlamaStopReason(c: r.stop_reason),
                                     usage: usage)
    }
}
