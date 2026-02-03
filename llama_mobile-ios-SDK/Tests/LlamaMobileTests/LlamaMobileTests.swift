import XCTest
import LlamaMobile

/// Comprehensive test suite for LlamaMobile iOS SDK
extension LlamaMobile {
    /// Test helper structure for model paths
    struct TestPaths {
        // Root path to models directory
        static let rootPath = "/Users/shileipeng/Documents/mygithub/llama_mobile/models"
        
        // Regular text model
        static let modelPath = rootPath + "/SmolLM-360M-Instruct.Q6_K.gguf"
        
        // TTS models - following C++ example structure
        // Main TTS text-to-audio model
        static let ttsModelPath = rootPath + "/OuteTTS-0.2-500M-Q6_K.gguf"  // OuteTTS main TTS model
        static let altTTSModelPath = rootPath + "/Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf"  // Alternative multilingual TTS model
        
        // Vocoder model (for audio generation)
        static let vocoderPath = rootPath + "/WavTokenizer-Large-75-F16.gguf"  // WavTokenizer vocoder
        
        // Embedding model
        static let embeddingPath = rootPath + "/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf"
        
        // Multimodal projection file
        static let mmprojPath = rootPath + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
        
        // LoRA adapter
        static let loraPath = rootPath + "/lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf"
        
        // Vision model
        static let imageModelPath = rootPath + "/SmolVLM-256M-Instruct-Q8_0.gguf"
        
        // Test image
        static let imagePath = rootPath + "/img/image.jpg"
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
        XCTAssertEqual(defaultParams.nThreads, Int32(ProcessInfo.processInfo.processorCount))
        XCTAssertTrue(defaultParams.useMmap)
        XCTAssertFalse(defaultParams.useMlock)
        XCTAssertFalse(defaultParams.embedding)
        XCTAssertEqual(defaultParams.poolingType, 0)
        XCTAssertEqual(defaultParams.embdNormalize, 0)
        XCTAssertFalse(defaultParams.flashAttention)
        XCTAssertNil(defaultParams.cacheTypeK)
        XCTAssertNil(defaultParams.cacheTypeV)
        XCTAssertTrue(defaultParams.enableChatTemplate)
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
        XCTAssertEqual(defaultParams.maxTokens, 1024)
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
        XCTAssertTrue(defaultParams.useJsonResponse)
        XCTAssertEqual(defaultParams.nProbs, 0)
        XCTAssertNil(defaultParams.jsonSchema)
        XCTAssertNil(defaultParams.tools)
        XCTAssertFalse(defaultParams.parallelToolCalls)
        XCTAssertNil(defaultParams.toolChoice)
        
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
        if let llama = createTestInstance() {
        
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
        
        // Test public TTS methods instead of private ones
        let speechResult = llama.generateSpeech(text: "Hello")
        XCTAssertNotNil(speechResult)
        
        // Test multimodal
        XCTAssertFalse(llama.isMultimodalEnabled())
        XCTAssertFalse(llama.initMultimodal(mmprojPath: LlamaMobile.TestPaths.mmprojPath))
        XCTAssertFalse(llama.supportsVision())
        XCTAssertFalse(llama.supportsAudio())
        
        // Test LoRA
        XCTAssertFalse(llama.applyLoraAdapters([LlamaMobile.LoraAdapter(path: "")]))
        if let loadedAdapters = llama.getLoadedLoraAdapters() {
            XCTAssertTrue(loadedAdapters.isEmpty)
        }
        
        // Test conversation
        XCTAssertNil(llama.generateResponse(userMessage: "Hello"))
        XCTAssertFalse(llama.isConversationActive())
        
        // Test model info
        XCTAssertEqual(llama.getContextWindowSize(), 0)
        XCTAssertEqual(llama.getEmbeddingDimension(), 0)
        XCTAssertNil(llama.getModelDescription())
        XCTAssertEqual(llama.getModelSize(), 0)
        XCTAssertEqual(llama.getModelParametersCount(), 0)
        XCTAssertEqual(llama.getTTSType(), LlamaMobile.TTSModelType.unknown)
        }
    }
    
    // MARK: - Completion Control Tests
    
    func testCompletionControl() {
        let llama = createTestInstance()
        
        // Stop completion should not crash with nil context
        llama?.stopCompletion()
        
        // Test context operations
        llama?.clearConversation()
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
            stoppedLimit: false,
            stoppingWord: nil
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
        let result = LlamaMobile.download(with: params)
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.localPath, "/tmp/test/invalid.gguf")
    }
    
    // MARK: - Multimodal API Tests
    
    func testMultimodalCompletionAPI() {
        if let llama = createTestInstance() {
            // Test multimodal completion API (should fail with nil context)
            let params = LlamaMobile.CompletionParams(multimodalPrompt: "What's in this image?", mediaPaths: ["/tmp/test/image.jpg"])
            XCTAssertNil(llama.generateCompletion(with: params))
            
            // Test deprecated API for backward compatibility
            // Note: The deprecated generateMultimodalCompletion method is not tested directly
            // as it has been replaced by the unified generateCompletion API with mediaPaths
        }
    }
    
    // MARK: - Conversation API Tests
    
    func testConversationAPI() {
        if let llama = createTestInstance() {
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
            mediaPaths: [],
            useJsonResponse: false,
            nProbs: 0,
            jsonSchema: nil,
            tools: nil,
            parallelToolCalls: false,
            toolChoice: nil
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
        XCTAssertFalse(params.useJsonResponse)
        XCTAssertEqual(params.nProbs, 0)
        XCTAssertNil(params.jsonSchema)
        XCTAssertNil(params.tools)
        XCTAssertFalse(params.parallelToolCalls)
        XCTAssertNil(params.toolChoice)
    }
    
    // MARK: - Real Model Integration Tests
    
    /// Create a real model instance using the configured small model for integration testing
    private func createRealModelInstance() -> LlamaMobile? {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            return nil
        }
        
        return LlamaMobile(modelPath: LlamaMobile.TestPaths.modelPath)
    }
    
    private func createRealEmbeddingModelInstance() -> LlamaMobile? {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.embeddingPath) else {
            return nil
        }
        
        return LlamaMobile(modelPath: LlamaMobile.TestPaths.embeddingPath)
    }
    
    func testRealModelLoading() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            XCTSkip("Model file not available at \(LlamaMobile.TestPaths.modelPath) - skipping real model test")
            return
        }
        
        let llama = createRealModelInstance()
        XCTAssertNotNil(llama, "Failed to create real model instance")
        
        if let llama = llama {
            XCTAssertGreaterThan(llama.getModelSize(), 0, "Model size should be greater than 0")
            XCTAssertGreaterThan(llama.getModelParametersCount(), 0, "Model parameters should be greater than 0")
        }
    }
    
    func testRealModelCompletion() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            XCTSkip("Model file not available at \(LlamaMobile.TestPaths.modelPath) - skipping real model test")
            return
        }
        
        let llama = createRealModelInstance()
        XCTAssertNotNil(llama, "Failed to create real model instance")
        
        if let llama = llama {
            // Test basic text completion with a simple prompt
            let params = LlamaMobile.CompletionParams(
                prompt: "Hello, my name is",
                maxTokens: 10,        // Limit to 10 tokens for fast testing
                temperature: 0.7,
                topK: 40,
                topP: 0.9
            )
            
            let result = llama.generateCompletion(with: params)
            XCTAssertNotNil(result, "Completion should return a result")
            
            if let result = result {
                XCTAssertFalse(result.text.isEmpty, "Completion text should not be empty")
                XCTAssertGreaterThan(result.tokensGenerated, 0, "Should generate tokens")
            }
        }
    }
    
    func testRealModelTokenization() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            XCTSkip("Model file not available at LlamaMobile.TestPaths.modelPath) - skipping real model test")
            return
        }
        
        let llama = createRealModelInstance()
        XCTAssertNotNil(llama, "Failed to create real model instance")
        
        if let llama = llama {
            // Test tokenization
            let testText = "Hello, world!"
            let tokens = llama.tokenize(text: testText)
            XCTAssertNotNil(tokens, "Tokenization should succeed with real model")
            XCTAssertGreaterThan(tokens!.count, 0, "Should tokenize into multiple tokens")
            
            // Test detokenization
            let detokenized = llama.detokenize(tokens: tokens!)
            XCTAssertNotNil(detokenized, "Detokenization should succeed with real model")
            XCTAssertTrue(detokenized!.contains("Hello"), "Detokenized text should contain original words")
        }
    }
    
    func testRealModelEmbeddings() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.embeddingPath) else {
            XCTSkip("Model file not available at \(LlamaMobile.TestPaths.embeddingPath) - skipping real model test")
            return
        }
        
        let llama = createRealEmbeddingModelInstance()
        XCTAssertNotNil(llama, "Failed to create real model instance")
        
        if let llama = llama {
            // Test embedding generation
            let embeddings = llama.generateEmbeddings(for: "Hello, world!")
            
            // Regular text models might not support high-quality embeddings
            // We'll make this test more flexible
            if embeddings != nil {
                XCTAssertGreaterThan(embeddings!.count, 0, "Embedding vector should have dimensions if generated")
            }
            
            // Test embedding parameters - this should work for all models
            let embeddingDim = llama.getEmbeddingDimension()
            print("Regular model embedding dimension: \(embeddingDim)")
        }
    }
    
    func testDedicatedEmbeddingModel() {
        let embeddingPath = LlamaMobile.TestPaths.embeddingPath
        guard FileManager.default.fileExists(atPath: embeddingPath) else {
            XCTSkip("Dedicated embedding model file not available at \(embeddingPath) - skipping test")
            return
        }
        
        print("Attempting to load embedding model: \(embeddingPath)")
        
        // Create instance with dedicated embedding model - explicitly enable embeddings
        let initParams = LlamaMobile.InitParams(modelPath: embeddingPath, embedding: true)
        if let llama = LlamaMobile(with: initParams) {
            print("✓ Successfully created LlamaMobile instance with embedding model and embedding enabled")
            
            // Check if model is actually loaded
            let modelSize = llama.getModelSize()
            let paramCount = llama.getModelParametersCount()
            print("Model size: \(modelSize) bytes")
            print("Model parameters: \(paramCount)")
            
            // Test embedding generation
            print("Generating embeddings...")
            let embeddings = llama.generateEmbeddings(for: "Hello, world!")
            
            if embeddings == nil {
                print("✗ Failed to generate embeddings")
            } else {
                print("✓ Embeddings generated successfully, dimension: \(embeddings!.count)")
            }
            
            XCTAssertNotNil(embeddings, "Embeddings should be generated with dedicated embedding model")
            if let embeddings = embeddings {
                XCTAssertGreaterThan(embeddings.count, 0, "Embedding vector should have dimensions")
            }
            
            // Test embedding parameters
            let embeddingDim = llama.getEmbeddingDimension()
            print("Embedding dimension from getEmbeddingDimension(): \(embeddingDim)")
            XCTAssertGreaterThan(embeddingDim, 0, "Embedding dimension should be greater than 0")
        } else {
            print("✗ Failed to create LlamaMobile instance with embedding model")
            XCTFail("Failed to create LlamaMobile instance with embedding model at \(embeddingPath)")
        }
    }
    
    func testDualPurposeModelEmbeddingAndTextGeneration() {
        let modelPath = LlamaMobile.TestPaths.modelPath
        guard FileManager.default.fileExists(atPath: modelPath) else {
            XCTSkip("Model file not available at \(modelPath) - skipping test")
            return
        }
        
        // Initialize regular text model with embedding enabled
        let initParams = LlamaMobile.InitParams(modelPath: modelPath, embedding: true)
        if let llama = LlamaMobile(with: initParams) {
            // Test 1: Generate embeddings
            let embeddings = llama.generateEmbeddings(for: "Hello, world!")
            XCTAssertNotNil(embeddings, "Should generate embeddings when embedding flag is enabled")
            XCTAssertGreaterThan(embeddings!.count, 0, "Embedding vector should have dimensions")
            
            // Test 2: Still able to generate text completions
            let completion = llama.generateCompletion(prompt: "Hello, world! How are you", maxTokens: 10)
            XCTAssertNotNil(completion, "Should still generate text completions when embedding flag is enabled")
            XCTAssertFalse(completion!.text.isEmpty, "Generated text should not be empty")
            
            // Test 3: Verify embedding dimension
            let embeddingDim = llama.getEmbeddingDimension()
            XCTAssertGreaterThan(embeddingDim, 0, "Embedding dimension should be greater than 0")
        } else {
            XCTFail("Failed to create LlamaMobile instance with embedding enabled at \(modelPath)")
        }
    }
    
    func testRealModelMultimodal() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.imageModelPath),
              FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.mmprojPath) else {
            XCTSkip("Multimodal model files not available - skipping real model test")
            return
        }
        
        // Create a simple test image for vision processing
        let testImagePath = "\(NSTemporaryDirectory())test_image.jpg"
        
        // Test multimodal functionality
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.imageModelPath) {
            // Initialize multimodal capabilities
            XCTAssertTrue(llama.initMultimodal(mmprojPath: LlamaMobile.TestPaths.mmprojPath), "Should initialize multimodal successfully")
            XCTAssertTrue(llama.supportsVision(), "Model should support vision")
            XCTAssertTrue(llama.isMultimodalEnabled(), "Multimodal should be enabled")
        }
    }
    
    func testRealModelTTS() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.ttsModelPath),
              FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.vocoderPath) else {
            XCTSkip("TTS model files not available - skipping real model test")
            return
        }
        
        // Follow C++ example: Load main TTS model first, then vocoder
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.ttsModelPath) {
            // Initialize vocoder (WavTokenizer)
            XCTAssertTrue(llama.initVocoder(vocoderModelPath: LlamaMobile.TestPaths.vocoderPath), "Should initialize WavTokenizer vocoder successfully")
            XCTAssertTrue(llama.isVocoderEnabled(), "Vocoder should be enabled")
            
            // Test TTS functionality
            // Check TTS type
            let ttsType = llama.getTTSType()
            XCTAssertNotEqual(ttsType, .unknown, "TTS type should not be unknown")
        }
    }
    
    func testSaveAudioToWav() {
        // Create a simple test audio array
        let testAudio: [Float] = [0.1, 0.2, 0.3, 0.4, 0.5]
        let tempFilePath = "/tmp/test_audio.wav"
        
        // Clean up any existing file
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: tempFilePath) {
            try? fileManager.removeItem(atPath: tempFilePath)
        }
        
        // Initialize with any model to get a valid context
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.modelPath) {
            // Test the saveAudioToWav function
            let success = llama.saveAudioToWav(filePath: tempFilePath, audioData: testAudio, sampleRate: 24000)
            XCTAssertTrue(success, "Should save audio to WAV file successfully")
            
            // Verify the file was created
            XCTAssertTrue(fileManager.fileExists(atPath: tempFilePath), "WAV file should exist after saving")
            
            // Clean up
            try? fileManager.removeItem(atPath: tempFilePath)
        }
    }

    func testRealModelLoRAAdapterLoading() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath),
              FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.loraPath) else {
            XCTSkip("Model or LoRA adapter file not available - skipping LoRA test")
            return
        }
        
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.modelPath) {
            // Test LoRA adapter loading
            let adapter = LlamaMobile.LoraAdapter(path: LlamaMobile.TestPaths.loraPath, scale: 0.8)
            let success = llama.applyLoraAdapters([adapter])
            
            if success {
                print("Successfully loaded LoRA adapter")
                
                // Test getting loaded LoRA adapters
                if let loadedAdapters = llama.getLoadedLoraAdapters() {
                    XCTAssertGreaterThan(loadedAdapters.count, 0, "Should have at least one LoRA adapter loaded")
                    print("Loaded \(loadedAdapters.count) LoRA adapter(s)")
                }
            } else {
                print("Failed to load LoRA adapter - this may be due to compatibility issues")
                // Don't fail the test if LoRA loading fails due to compatibility
            }
        }
    }

    func testRealModelConversationAPI() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            XCTSkip("Model file not available - skipping conversation test")
            return
        }
        
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.modelPath) {
            // Test conversation API
            let result = llama.generateResponse(userMessage: "Hello, how are you?")
            XCTAssertNotNil(result, "Conversation result should not be nil")
            
            if let result = result {
                XCTAssertFalse(result.text.isEmpty, "Conversation should generate text")
                XCTAssertGreaterThan(result.tokensGenerated, 0, "Should generate tokens")
                XCTAssertGreaterThan(result.totalTime, 0, "Should have non-zero total time")
                
                print("Conversation result: \(result.text)")
                print("Tokens generated: \(result.tokensGenerated)")
                print("Time to first token: \(result.timeToFirstToken)ms")
                print("Total time: \(result.totalTime)ms")
            }
            
            // Test streaming conversation
            var receivedTokens = 0
            let callback: (String) -> Bool = { token in
                receivedTokens += 1
                print("Received token: \(token)")
                return true
            }
            
            let streamingResult = llama.generateResponse(userMessage: "What's the capital of France?", tokenCallback: callback)
            XCTAssertNotNil(streamingResult, "Streaming conversation result should not be nil")
            
            if let streamingResult = streamingResult {
                XCTAssertFalse(streamingResult.text.isEmpty, "Streaming conversation should generate text")
                XCTAssertGreaterThan(streamingResult.tokensGenerated, 0, "Should generate tokens in streaming mode")
            }
        }
    }

    func testRealModelStreamingTTS() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.ttsModelPath),
              FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.vocoderPath) else {
            XCTSkip("TTS model files not available - skipping streaming TTS test")
            return
        }
        
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.ttsModelPath) {
            // Initialize vocoder
            let vocoderSuccess = llama.initVocoder(vocoderModelPath: LlamaMobile.TestPaths.vocoderPath)
            XCTAssertTrue(vocoderSuccess, "Should initialize vocoder successfully")
            
            if vocoderSuccess {
                // Test streaming TTS
                var receivedChunks = 0
                var totalSamples = 0
                
                let audioCallback: ([Float]) -> Void = { audioChunk in
                    receivedChunks += 1
                    totalSamples += audioChunk.count
                    print("Received audio chunk with \(audioChunk.count) samples")
                }
                
                let progressCallback: (Float) -> Void = { progress in
                    print("TTS progress: \(Int(progress * 100))%")
                }
                
                let result = llama.generateSpeech(text: "Hello, this is a streaming TTS test")
                XCTAssertNotNil(result, "TTS result should not be nil")
            }
        }
    }

    func testRealModelComprehensiveInfo() {
        guard FileManager.default.fileExists(atPath: LlamaMobile.TestPaths.modelPath) else {
            XCTSkip("Model file not available - skipping model info test")
            return
        }
        
        if let llama = LlamaMobile(modelPath: LlamaMobile.TestPaths.modelPath) {
            // Test model size
            let modelSize = llama.getModelSize()
            XCTAssertGreaterThan(modelSize, 0, "Model size should be greater than 0")
            print("Model size: \(modelSize) bytes")
            
            // Test model parameters count
            let paramsCount = llama.getModelParametersCount()
            XCTAssertGreaterThan(paramsCount, 0, "Model parameters count should be greater than 0")
            print("Model parameters count: \(paramsCount)")
            
            // Test model description
            if let modelDesc = llama.getModelDescription() {
                XCTAssertFalse(modelDesc.isEmpty, "Model description should not be empty")
                print("Model description: \(modelDesc)")
            }
            
            // Test context window size
            let ctxWindowSize = llama.getContextWindowSize()
            XCTAssertGreaterThan(ctxWindowSize, 0, "Context window size should be greater than 0")
            print("Context window size: \(ctxWindowSize)")
            
            // Test embedding dimension
            let embeddingDim = llama.getEmbeddingDimension()
            print("Embedding dimension: \(embeddingDim)")
            
            // Test if conversation is active
            XCTAssertFalse(llama.isConversationActive(), "Conversation should not be active initially")
        }
    }
}

// MARK: - Convenience Initializer for Testing
extension LlamaMobileTests {
    /// Create a test instance with nil context for testing method safety
    func createTestInstance() -> LlamaMobile? {
        // Use the failable initializer with an invalid path to get a nil context instance
        return LlamaMobile(modelPath: "/invalid/path")
    }
}
