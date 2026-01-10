import XCTest
import LlamaMobile

/// Comprehensive test suite for LlamaMobile iOS SDK
extension LlamaMobile {
    /// Test helper structure for model paths
    struct TestPaths {
        static let modelPath = "/tmp/test/model.gguf"
        static let vocoderPath = "/tmp/test/vocoder.gguf"
        static let mmprojPath = "/tmp/test/mmproj.bin"
        static let loraPath = "/tmp/test/lora.gguf"
        static let imagePath = "/tmp/test/image.jpg"
    }
}

final class LlamaMobileTests: XCTestCase {
    
    // MARK: - Properties
    
    private var llama: LlamaMobile?
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // Create directories for test files
        let fileManager = FileManager.default
        let testDir = URL(fileURLWithPath: "/tmp/test/")
        
        if !fileManager.fileExists(atPath: testDir.path) {
            try fileManager.createDirectory(at: testDir, withIntermediateDirectories: true)
        }
        
        llama = nil
    }
    
    override func tearDownWithError() throws {
        // Clean up test instance
        llama = nil
        
        // Remove test directory and files
        let fileManager = FileManager.default
        let testDir = URL(fileURLWithPath: "/tmp/test/")
        
        if fileManager.fileExists(atPath: testDir.path) {
            try fileManager.removeItem(at: testDir)
        }
    }
    
    // MARK: - InitParams Tests
    
    func testInitParamsConstructors() {
        // Test default constructor
        let defaultParams = LlamaMobile.InitParams(modelPath: LlamaMobile.TestPaths.modelPath)
        XCTAssertEqual(defaultParams.modelPath, LlamaMobile.TestPaths.modelPath)
        XCTAssertEqual(defaultParams.nCtx, 2048)
        XCTAssertNil(defaultParams.chatTemplate)
        XCTAssertNil(defaultParams.systemPrompt)
        XCTAssertEqual(defaultParams.nGpuLayers, 0)
        XCTAssertEqual(defaultParams.nThreads, ProcessInfo.processInfo.processorCount)
        XCTAssertTrue(defaultParams.useMmap)
        XCTAssertFalse(defaultParams.useMlock)
        XCTAssertFalse(defaultParams.embedding)
        XCTAssertEqual(defaultParams.poolingType, 0)
        XCTAssertEqual(defaultParams.embdNormalize, 0)
        XCTAssertFalse(defaultParams.flashAttention)
        XCTAssertNil(defaultParams.cacheTypeK)
        XCTAssertNil(defaultParams.cacheTypeV)
        XCTAssertNil(defaultParams.progressCallback)
        
        // Test GPU constructor
        let gpuParams = LlamaMobile.InitParams(
            modelPath: LlamaMobile.TestPaths.modelPath,
            nGpuLayers: 4,
            nCtx: 4096
        )
        XCTAssertEqual(gpuParams.nGpuLayers, 4)
        XCTAssertEqual(gpuParams.nCtx, 4096)
        
        // Test embedding constructor
        let embeddingParams = LlamaMobile.InitParams(
            modelPath: LlamaMobile.TestPaths.modelPath,
            embedding: true,
            poolingType: 1
        )
        XCTAssertTrue(embeddingParams.embedding)
        XCTAssertEqual(embeddingParams.poolingType, 1)
    }
    
    // MARK: - CompletionParams Tests
    
    func testCompletionParamsConstructors() {
        let testPrompt = "Hello, world!"
        
        // Test default constructor
        let defaultParams = LlamaMobile.CompletionParams(prompt: testPrompt)
        XCTAssertEqual(defaultParams.prompt, testPrompt)
        XCTAssertEqual(defaultParams.maxTokens, 128)
        XCTAssertNil(defaultParams.nThreads)
        XCTAssertEqual(defaultParams.seed, -1)
        XCTAssertEqual(defaultParams.temperature, 0.8)
        XCTAssertEqual(defaultParams.topK, 40)
        XCTAssertEqual(defaultParams.topP, 0.95)
        XCTAssertEqual(defaultParams.minP, 0.05)
        XCTAssertEqual(defaultParams.typicalP, 1.0)
        XCTAssertEqual(defaultParams.penaltyLastN, 64)
        XCTAssertEqual(defaultParams.penaltyRepeat, 1.1)
        XCTAssertEqual(defaultParams.penaltyFreq, 0.0)
        XCTAssertEqual(defaultParams.penaltyPresent, 0.0)
        XCTAssertEqual(defaultParams.mirostat, 0)
        XCTAssertEqual(defaultParams.mirostatTau, 5.0)
        XCTAssertEqual(defaultParams.mirostatEta, 0.1)
        XCTAssertFalse(defaultParams.ignoreEos)
        XCTAssertNil(defaultParams.grammar)
        XCTAssertEqual(defaultParams.stopSequences.count, 0)
        XCTAssertNil(defaultParams.tokenCallback)
        XCTAssertEqual(defaultParams.mediaPaths.count, 0)
        
        // Test creative constructor
        let creativeParams = LlamaMobile.CompletionParams(
            creativePrompt: testPrompt,
            maxTokens: 512
        )
        XCTAssertEqual(creativeParams.prompt, testPrompt)
        XCTAssertEqual(creativeParams.maxTokens, 512)
        XCTAssertEqual(creativeParams.temperature, 1.0)
        XCTAssertEqual(creativeParams.topP, 0.98)
        XCTAssertEqual(creativeParams.topK, 100)
        
        // Test factual constructor
        let factualParams = LlamaMobile.CompletionParams(factualPrompt: testPrompt)
        XCTAssertEqual(factualParams.temperature, 0.1)
        XCTAssertEqual(factualParams.topP, 0.9)
        XCTAssertEqual(factualParams.topK, 20)
        
        // Test chat constructor
        let chatParams = LlamaMobile.CompletionParams(
            chatPrompt: testPrompt,
            maxTokens: 256
        )
        XCTAssertEqual(chatParams.maxTokens, 256)
        XCTAssertEqual(chatParams.temperature, 0.7)
        XCTAssertEqual(chatParams.topP, 0.95)
        XCTAssertEqual(chatParams.topK, 40)
        XCTAssertEqual(chatParams.penaltyRepeat, 1.2)
        
        // Test multimodal constructor
        let multimodalParams = LlamaMobile.CompletionParams(
            multimodalPrompt: testPrompt,
            mediaPaths: [LlamaMobile.TestPaths.imagePath],
            maxTokens: 256
        )
        XCTAssertEqual(multimodalParams.maxTokens, 256)
        XCTAssertEqual(multimodalParams.mediaPaths.count, 1)
        XCTAssertEqual(multimodalParams.mediaPaths.first, LlamaMobile.TestPaths.imagePath)
    }
    
    // MARK: - TTSModelType Tests
    
    func testTTSModelType() {
        XCTAssertEqual(LlamaMobile.TTSModelType.unknown.rawValue, -1)
        XCTAssertEqual(LlamaMobile.TTSModelType.outETTSv02.rawValue, 1)
        XCTAssertEqual(LlamaMobile.TTSModelType.outETTSv03.rawValue, 2)
        
        // Test rawValue initializer
        XCTAssertEqual(LlamaMobile.TTSModelType(rawValue: 0), .unknown)
        XCTAssertEqual(LlamaMobile.TTSModelType(rawValue: 1), .outETTSv02)
        XCTAssertEqual(LlamaMobile.TTSModelType(rawValue: 2), .outETTSv03)
        XCTAssertEqual(LlamaMobile.TTSModelType(rawValue: 3), .unknown)
    }
    
    // MARK: - StopType Tests
    
    func testStopType() {
        XCTAssertEqual(LlamaMobile.StopType.full.rawValue, 0)
        XCTAssertEqual(LlamaMobile.StopType.partial.rawValue, 1)
    }
    
    // MARK: - Error Enum Tests
    
    func testErrorEnum() {
        // Test error cases exist
        let _: LlamaMobile.Error = .contextNotInitialized
        let _: LlamaMobile.Error = .invalidParameter("")
        let _: LlamaMobile.Error = .operationFailed("")
        let _: LlamaMobile.Error = .vocoderNotInitialized
        let _: LlamaMobile.Error = .multimodalNotInitialized
        let _: LlamaMobile.Error = .mediaProcessingFailed
        let _: LlamaMobile.Error = .tokenizationFailed
        let _: LlamaMobile.Error = .detokenizationFailed
        let _: LlamaMobile.Error = .embeddingGenerationFailed
        let _: LlamaMobile.Error = .audioGenerationFailed
        let _: LlamaMobile.Error = .conversationFailed
    }
    
    // MARK: - Init & Release Tests
    
    func testContextInitializationWithInvalidPath() {
        // Test initialization with invalid model path
        // Should fail gracefully and return nil
        let llama = LlamaMobile(modelPath: "/invalid/path/to/model.gguf")
        XCTAssertNil(llama)
        
        let params = LlamaMobile.InitParams(modelPath: "/invalid/path/to/model.gguf")
        let llamaWithParams = LlamaMobile(with: params)
        XCTAssertNil(llamaWithParams)
    }
    
    // MARK: - Method Safety Tests
    
    func testMethodsWithNilContext() {
        // All methods should fail gracefully with nil context
        let llama = LlamaMobile()
        
        // Test completion
        XCTAssertNil(llama.generateCompletion(prompt: "Hello"))
        
        // Test tokenization
        XCTAssertNil(llama.tokenize(text: "Hello"))
        
        // Test detokenization
        XCTAssertNil(llama.detokenize(tokens: [1, 2, 3]))
        
        // Test embeddings
        XCTAssertNil(llama.generateEmbeddings(for: "Hello"))
        
        // Test TTS
        XCTAssertFalse(llama.isVocoderEnabled())
        XCTAssertFalse(llama.initVocoder(vocoderModelPath: LlamaMobile.TestPaths.vocoderPath))
        XCTAssertNil(llama.getFormattedAudioCompletion(speakerJson: "{}", textToSpeak: "Hello"))
        XCTAssertNil(llama.getAudioGuideTokens(textToSpeak: "Hello"))
        XCTAssertNil(llama.decodeAudioTokens(tokens: [1, 2, 3]))
        XCTAssertNil(llama.generateAudioFromText(text: "Hello"))
        
        // Test multimodal
        XCTAssertFalse(llama.isMultimodalEnabled())
        XCTAssertFalse(llama.initMultimodal(mmprojPath: LlamaMobile.TestPaths.mmprojPath))
        XCTAssertFalse(llama.supportsVision())
        XCTAssertFalse(llama.supportsAudio())
        
        // Test LoRA
        XCTAssertFalse(llama.applyLoraAdapters([LlamaMobile.LoraAdapter(path: "")]))
        XCTAssertEqual(llama.getLoadedLoraAdapters(), [])
        
        // Test conversation
        XCTAssertNil(llama.generateResponse(userMessage: "Hello"))
        XCTAssertFalse(llama.isConversationActive())
        
        // Test model info
        XCTAssertEqual(llama.getContextWindowSize(), 0)
        XCTAssertEqual(llama.getEmbeddingDimension(), 0)
        XCTAssertNil(llama.getModelDescription())
        XCTAssertEqual(llama.getModelSize(), 0)
        XCTAssertEqual(llama.getModelParametersCount(), 0)
        XCTAssertEqual(llama.getTTSType(), .unknown)
    }
    
    // MARK: - Completion Control Tests
    
    func testCompletionControl() {
        let llama = LlamaMobile()
        
        // Stop completion should not crash with nil context
        llama.stopCompletion()
        
        // Test context operations
        llama.clearConversation()
    }
    
    // MARK: - Download Tests
    
    func testDownloadParams() {
        let testUrl = "https://huggingface.co/model"
        let testLocalPath = "/tmp/test/model.gguf"
        
        let params = LlamaMobile.DownloadParams(url: testUrl, localPath: testLocalPath)
        XCTAssertEqual(params.url, testUrl)
        XCTAssertEqual(params.localPath, testLocalPath)
        XCTAssertNil(params.username)
        XCTAssertNil(params.password)
        XCTAssertNil(params.headers)
        XCTAssertNil(params.progressCallback)
        
        // Test with optional parameters
        let paramsWithAuth = LlamaMobile.DownloadParams(
            url: testUrl,
            localPath: testLocalPath,
            username: "user",
            password: "pass",
            headers: ["Authorization": "Bearer token"]
        )
        XCTAssertEqual(paramsWithAuth.username, "user")
        XCTAssertEqual(paramsWithAuth.password, "pass")
        XCTAssertEqual(paramsWithAuth.headers?["Authorization"], "Bearer token")
    }
    
    // MARK: - LoRA Adapter Tests
    
    func testLoraAdapter() {
        let testPath = LlamaMobile.TestPaths.loraPath
        
        // Test default constructor
        let defaultAdapter = LlamaMobile.LoraAdapter(path: testPath)
        XCTAssertEqual(defaultAdapter.path, testPath)
        XCTAssertEqual(defaultAdapter.scale, 1.0)
        
        // Test with custom scale
        let customAdapter = LlamaMobile.LoraAdapter(path: testPath, scale: 0.5)
        XCTAssertEqual(customAdapter.scale, 0.5)
    }
    
    // MARK: - Response Structures Tests
    
    func testResponseStructures() {
        // Test CompletionResult
        let completionResult = LlamaMobile.CompletionResult(
            text: "Test response",
            tokensGenerated: 10,
            tokensEvaluated: 5,
            truncated: false,
            stoppedEos: true,
            stoppedWord: false,
            stoppedLimit: false
        )
        XCTAssertEqual(completionResult.text, "Test response")
        XCTAssertEqual(completionResult.tokensGenerated, 10)
        XCTAssertEqual(completionResult.tokensEvaluated, 5)
        XCTAssertFalse(completionResult.truncated)
        XCTAssertTrue(completionResult.stoppedEos)
        XCTAssertFalse(completionResult.stoppedWord)
        XCTAssertFalse(completionResult.stoppedLimit)
        
        // Test ConversationResult
        let conversationResult = LlamaMobile.ConversationResult(
            text: "Test conversation",
            timeToFirstToken: 100,
            totalTime: 500,
            tokensGenerated: 20
        )
        XCTAssertEqual(conversationResult.text, "Test conversation")
        XCTAssertEqual(conversationResult.timeToFirstToken, 100)
        XCTAssertEqual(conversationResult.totalTime, 500)
        XCTAssertEqual(conversationResult.tokensGenerated, 20)
        
        // Test DownloadResult
        let downloadResult = LlamaMobile.DownloadResult(
            success: true,
            localPath: "/tmp/test/model.gguf",
            errorMessage: nil
        )
        XCTAssertTrue(downloadResult.success)
        XCTAssertEqual(downloadResult.localPath, "/tmp/test/model.gguf")
        XCTAssertNil(downloadResult.errorMessage)
        
        let failedResult = LlamaMobile.DownloadResult(
            success: false,
            localPath: "/tmp/test/model.gguf",
            errorMessage: "Download failed"
        )
        XCTAssertFalse(failedResult.success)
        XCTAssertEqual(failedResult.errorMessage, "Download failed")
    }
    
    // MARK: - Download Method Tests
    
    func testDownloadMethod() {
        let params = LlamaMobile.DownloadParams(
            url: "https://huggingface.co/invalid/model",
            localPath: "/tmp/test/invalid.gguf"
        )
        
        // Test should return DownloadResult even with invalid URL
        let result = LlamaMobile().download(with: params)
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.success)
        XCTAssertEqual(result!.localPath, "/tmp/test/invalid.gguf")
    }
    
    // MARK: - Multimodal API Tests
    
    func testMultimodalCompletionAPI() {
        let llama = LlamaMobile()
        
        // Test multimodal completion API (should fail with nil context)
        let params = LlamaMobile.CompletionParams(multimodalPrompt: "What's in this image?", mediaPaths: ["/tmp/test/image.jpg"])
        XCTAssertNil(llama.generateCompletion(with: params))
        
        // Test deprecated API for backward compatibility
        XCTAssertNil(llama.generateMultimodalCompletion(with: params, mediaPaths: ["/tmp/test/image.jpg"]))
    }
    
    // MARK: - Conversation API Tests
    
    func testConversationAPI() {
        let llama = LlamaMobile()
        
        // Test conversation methods
        XCTAssertNil(llama.generateResponse(userMessage: "Hello"))
        XCTAssertNil(llama.generateResponse(userMessage: "Hello", tokenCallback: { _ in true }))
        
        // Test streaming callback
        var tokenCount = 0
        let callback: (String) -> Bool = { token in
            tokenCount += 1
            return true
        }
        
        XCTAssertNil(llama.generateResponse(userMessage: "Hello", tokenCallback: callback))
        XCTAssertEqual(tokenCount, 0) // No tokens should be received with nil context
        
        // Test conversation control
        llama.clearConversation()
        XCTAssertFalse(llama.isConversationActive())
    }
    
    // MARK: - Parameter Edge Cases Tests
    
    func testParameterEdgeCases() {
        // Test completion with various parameters
        let params = LlamaMobile.CompletionParams(
            prompt: "",
            maxTokens: 0,
            temperature: 0.0,
            topK: 0,
            topP: 0.0,
            minP: 0.0,
            typicalP: 0.0,
            penaltyLastN: 0,
            penaltyRepeat: 0.0,
            penaltyFreq: 0.0,
            penaltyPresent: 0.0,
            mirostat: 0,
            mirostatTau: 0.0,
            mirostatEta: 0.0,
            ignoreEos: true,
            stopSequences: [],
            grammar: nil,
            mediaPaths: []
        )
        
        XCTAssertEqual(params.prompt, "")
        XCTAssertEqual(params.maxTokens, 0)
        XCTAssertEqual(params.temperature, 0.0)
        XCTAssertEqual(params.topK, 0)
        XCTAssertEqual(params.topP, 0.0)
        XCTAssertEqual(params.minP, 0.0)
        XCTAssertEqual(params.typicalP, 0.0)
        XCTAssertEqual(params.penaltyLastN, 0)
        XCTAssertEqual(params.penaltyRepeat, 0.0)
        XCTAssertEqual(params.penaltyFreq, 0.0)
        XCTAssertEqual(params.penaltyPresent, 0.0)
        XCTAssertEqual(params.mirostat, 0)
        XCTAssertEqual(params.mirostatTau, 0.0)
        XCTAssertEqual(params.mirostatEta, 0.0)
        XCTAssertTrue(params.ignoreEos)
        XCTAssertTrue(params.stopSequences.isEmpty)
        XCTAssertNil(params.grammar)
        XCTAssertTrue(params.mediaPaths.isEmpty)
    }
}

// MARK: - Convenience Initializer for Testing
extension LlamaMobile {
    /// Convenience initializer for testing (creates instance with nil context)
    convenience init() {
        // Private initializer for testing only
        self.init() { _ in false }
    }
    
    /// Private initializer for testing
    private convenience init(_ dummy: Bool) {
        // Create instance with nil context for testing method safety
        self.init(modelPath: "/invalid/path")
    }
}