import XCTest
import LlamaMobile
import llama_mobile

/// Model fixture paths (mirrors the C++ core suite fixtures).
enum TestPaths {
    static let rootPath = "/Users/shileipeng/Documents/mygithub/llama_mobile/models"
    static let modelPath = rootPath + "/SmolLM-360M-Instruct.Q6_K.gguf"
    static let ttsModelPath = rootPath + "/OuteTTS-0.2-500M-Q6_K.gguf"
    static let altTTSModelPath = rootPath + "/Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf"
    static let vocoderPath = rootPath + "/WavTokenizer-Large-75-F16.gguf"
    static let embeddingPath = rootPath + "/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf"
    static let mmprojPath = rootPath + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
    static let loraPath = rootPath + "/lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf"
    static let imageModelPath = rootPath + "/SmolVLM-256M-Instruct-Q8_0.gguf"
    static let imagePath = rootPath + "/img/image.jpg"
}

/// Conformance tests for the v2 LlamaEngine wrapper.
///
/// Threading contract under test (docs/api-contract-v2.md §8):
///   * sync forms block the calling thread — the tests therefore run blocking
///     calls inside Task.detached so the test runner is never blocked;
///   * async forms never block the caller;
///   * streaming reports `.started(requestId)` before the first token and
///     `.done` after the request finishes;
///   * `abort(requestId:)` is thread-safe and the aborted generation reports
///     stopReason == .aborted.
///
/// Model-backed tests reuse the same fixtures as the C++ core suites and skip
/// (XCTSkip) when the file is not reachable, so the suite also runs on CI/dev
/// machines without the big models. On a device, put a GGUF where
/// LLAMA_MOBILE_TEST_MODEL points, or pass it via environment.
final class LlamaEngineTests: XCTestCase {

    private var modelPath: String {
        if let env = ProcessInfo.processInfo.environment["LLAMA_MOBILE_TEST_MODEL"],
           FileManager.default.fileExists(atPath: env) {
            return env
        }
        return TestPaths.modelPath
    }

    private func requireModel() throws {
        try XCTSkipUnless(FileManager.default.fileExists(atPath: modelPath),
                          "model not available: \(modelPath)")
    }

    private func makeConfig() -> LlamaModelConfig {
        var c = LlamaModelConfig(modelPath: modelPath)
        c.engine = .cpu
        c.nCtx = 2048
        return c
    }

    // MARK: - No-model tests (pure API surface)

    func testVersionApiIsV2() throws {
        guard let ver = llama_mobile_version() else {
            return XCTFail("llama_mobile_version() returned nil")
        }
        let v = ver.pointee
        XCTAssertEqual(v.api_version, 2)
        XCTAssertNotNil(String(cString: v.string).isEmpty ? nil : v.string)
    }

    func testErrorMappingFromStatus() {
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_OK), .generationFailed, "OK is not an error")
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_ERR_INVALID_ARGUMENT), .invalidArgument)
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_ERR_ALREADY_RUNNING), .alreadyRunning)
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_ERR_ABORTED), .aborted)
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_ERR_NOT_INITIALIZED), .notInitialized)
        XCTAssertEqual(LlamaError(status: LLAMA_MOBILE_ERR_UNSUPPORTED), .unsupported)
    }

    func testGenerateAfterCloseThrowsNotInitialized() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        engine.close()
        do {
            _ = try await engine.generate(LlamaGenerationRequest(prompt: "hi"))
            XCTFail("expected notInitialized after close")
        } catch let e as LlamaError {
            XCTAssertEqual(e, .notInitialized)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func testOpenMissingModelThrows() async throws {
        var c = LlamaModelConfig(modelPath: "/nonexistent/model.gguf")
        c.engine = .cpu
        do {
            _ = try await LlamaEngine.open(c)
            XCTFail("expected open to throw for a missing model")
        } catch let e as LlamaError {
            XCTAssertTrue(e == .modelLoadFailed || e == .modelNotFound || e == .io,
                          "got \(e)")
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    // MARK: - Model-backed tests (§8 sync/async/stream/abort)

    func testSyncOpenAndGenerate() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        defer { engine.close() }
        XCTAssertTrue(engine.isOpen)

        var req = LlamaGenerationRequest(prompt: "Complete: the capital of France is")
        req.maxTokens = 16
        req.sampling.temperature = 0
        req.sampling.topP = 1.0
        req.sampling.minP = 0
        // Sync form blocks: never call it on the actor, so hop off.
        let r = try await Task.detached { try engine.generate(req) }.value
        XCTAssertFalse(r.text.isEmpty)
        XCTAssertEqual(r.stopReason, .eos)
        XCTAssertGreaterThan(r.usage.generatedTokens, 0)
        XCTAssertGreaterThanOrEqual(r.usage.promptTokens, 0)
    }

    func testAsyncChatGenerate() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        defer { engine.close() }

        var chat = LlamaGenerationRequest(messages: [
            LlamaMessage(role: "system", content: "Answer in one short sentence."),
            LlamaMessage(role: "user", content: "What is 2+2?"),
        ])
        chat.maxTokens = 24
        chat.sampling.temperature = 0
        let r = try await engine.generate(chat)   // async form never blocks
        XCTAssertFalse(r.text.isEmpty)
    }

    func testLoadProgressCallbackFires() async throws {
        try requireModel()
        let lock = NSLock()
        var pings = 0
        var c = makeConfig()
        c.loadProgress = { p in
            lock.lock(); pings += 1; lock.unlock()
            return true
        }
        let engine = try await LlamaEngine.open(c)
        engine.close()
        lock.lock(); defer { lock.unlock() }
        XCTAssertGreaterThan(pings, 0, "load progress callback should fire")
    }

    /// Streaming: first event is .started(id), then tokens, then a terminal
    /// event; abort() from another thread stops it with stopReason == .aborted.
    func testStreamStartedAndMidStreamAbort() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        defer { engine.close() }

        var req = LlamaGenerationRequest(prompt: "Write a long, detailed essay about llamas. Do not stop.")
        req.maxTokens = 2000
        req.sampling.temperature = 0.9
        req.sampling.ignoreEos = true

        var startedId: UInt64?
        var tokenCount = 0
        var terminalReason: LlamaStopReason?
        var abortCalled = false
        var streamFailed = false

        for try await ev in engine.generateStream(req) {
            switch ev {
            case .started(let id):
                startedId = id
            case .token:
                tokenCount += 1
                if let sid = startedId, !abortCalled, tokenCount >= 2 {
                    abortCalled = true
                    do { try engine.abort(requestId: sid) }
                    catch { XCTFail("abort threw \(error)") }
                }
            case .done(let r):
                terminalReason = r.stopReason
            case .failed(let e):
                streamFailed = true
                XCTFail("stream failed: \(e)")
            }
        }
        XCTAssertNotNil(startedId)
        XCTAssertGreaterThan(startedId ?? 0, 0, "requestId must be nonzero")
        XCTAssertGreaterThan(tokenCount, 0)
        XCTAssertTrue(abortCalled, "abort was never invoked mid-stream")
        XCTAssertFalse(streamFailed)
        XCTAssertEqual(terminalReason, .aborted)
    }

    /// Streaming a short greedy request terminates normally with .done/.eos.
    func testStreamShortRequestCompletesWithEos() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        defer { engine.close() }

        var req = LlamaGenerationRequest(prompt: "Say exactly: hello")
        req.maxTokens = 16
        req.sampling.temperature = 0

        var text = ""
        var terminalReason: LlamaStopReason?
        for try await ev in engine.generateStream(req) {
            switch ev {
            case .started: break
            case .token(let t): text += t
            case .done(let r): terminalReason = r.stopReason
            case .failed(let e): XCTFail("stream failed \(e)")
            }
        }
        XCTAssertFalse(text.isEmpty)
        XCTAssertEqual(terminalReason, .eos)
    }

    /// Close is idempotent and safe to call after streams completed.
    func testCloseIsIdempotent() async throws {
        try requireModel()
        let engine = try await LlamaEngine.open(makeConfig())
        engine.close()
        engine.close()
        XCTAssertFalse(engine.isOpen)
    }
}
