import XCTest
@testable import LlamaMobile

class LlamaMobileTests: XCTestCase {
    var contextHandle: Int64 = -1
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        if contextHandle != -1 {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = -1
        }
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitContext() {
        let modelPath = "/path/to/dummy/model.gguf"
        let params = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(params)
        XCTAssertNotEqual(contextHandle, -1, "initContext should return a valid context handle")
    }
    
    func testInitContextWithEmbedding() {
        let modelPath = "/path/to/dummy/embedding_model.gguf"
        let params = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: true,
            poolingType: 0,
            embdNormalize: 1,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(params)
        XCTAssertNotEqual(contextHandle, -1, "initContext with embedding should return a valid context handle")
    }
    
    func testReleaseContext() {
        let handle: Int64 = 1
        XCTAssertNoThrow(LlamaMobile.releaseContext(handle), "releaseContext should not throw an error")
    }
    
    // MARK: - Completion Tests
    
    func testGenerateCompletion() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let params = LlamaMobile.CompletionParams(
            prompt: "Hello",
            temperature: 0.7,
            maxTokens: 100,
            nThreads: 4,
            seed: -1,
            topK: 40,
            topP: 0.95,
            minP: 0.05,
            typicalP: 1.0,
            penaltyLastN: 64,
            penaltyRepeat: 1.1,
            penaltyFreq: 0.0,
            penaltyPresent: 0.0,
            mirostat: 0,
            mirostatTau: 5.0,
            mirostatEta: 0.1,
            ignoreEos: false,
            nProbs: 0,
            grammar: nil,
            stopSequences: nil,
            mediaPaths: nil,
            chatMessages: nil,
            useJsonResponse: false,
            jsonSchema: nil,
            tools: nil,
            parallelToolCalls: false,
            toolChoice: nil,
            chatTemplate: nil
        )
        let result = LlamaMobile.generateCompletion(contextHandle, params)
        XCTAssertNotNil(result, "generateCompletion should return a result")
        XCTAssertNotNil(result.text, "result text should not be nil")
    }
    
    func testGenerateCompletionWithMedia() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let mediaPaths = ["/path/to/image.jpg"]
        let params = LlamaMobile.CompletionParams(
            prompt: "Describe this image",
            temperature: 0.7,
            maxTokens: 100,
            nThreads: 4,
            seed: -1,
            topK: 40,
            topP: 0.95,
            minP: 0.05,
            typicalP: 1.0,
            penaltyLastN: 64,
            penaltyRepeat: 1.1,
            penaltyFreq: 0.0,
            penaltyPresent: 0.0,
            mirostat: 0,
            mirostatTau: 5.0,
            mirostatEta: 0.1,
            ignoreEos: false,
            nProbs: 0,
            grammar: nil,
            stopSequences: nil,
            mediaPaths: mediaPaths,
            chatMessages: nil,
            useJsonResponse: false,
            jsonSchema: nil,
            tools: nil,
            parallelToolCalls: false,
            toolChoice: nil,
            chatTemplate: nil
        )
        let result = LlamaMobile.generateCompletion(contextHandle, params)
        XCTAssertNotNil(result, "generateCompletion with media should return a result")
    }
    
    func testGenerateCompletionWithStopSequences() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let stopSequences = ["\n", "END"]
        let params = LlamaMobile.CompletionParams(
            prompt: "Hello",
            temperature: 0.7,
            maxTokens: 100,
            nThreads: 4,
            seed: -1,
            topK: 40,
            topP: 0.95,
            minP: 0.05,
            typicalP: 1.0,
            penaltyLastN: 64,
            penaltyRepeat: 1.1,
            penaltyFreq: 0.0,
            penaltyPresent: 0.0,
            mirostat: 0,
            mirostatTau: 5.0,
            mirostatEta: 0.1,
            ignoreEos: false,
            nProbs: 0,
            grammar: nil,
            stopSequences: stopSequences,
            mediaPaths: nil,
            chatMessages: nil,
            useJsonResponse: false,
            jsonSchema: nil,
            tools: nil,
            parallelToolCalls: false,
            toolChoice: nil,
            chatTemplate: nil
        )
        let result = LlamaMobile.generateCompletion(contextHandle, params)
        XCTAssertNotNil(result, "generateCompletion with stop sequences should return a result")
    }
    
    func testStopCompletion() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        XCTAssertNoThrow(LlamaMobile.stopCompletion(contextHandle), "stopCompletion should not throw an error")
    }
    
    // MARK: - OpenAI Completion Tests
    
    func testGenerateOpenAICompletion() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let openAIJSON = """
        {
            "model": "gpt-3.5-turbo",
            "messages": [
                {"role": "user", "content": "Hello"}
            ],
            "temperature": 0.7,
            "max_tokens": 100
        }
        """
        XCTAssertNoThrow(try LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON), "generateOpenAICompletion should not throw an error")
    }
    
    // MARK: - TTS Tests
    
    func testInitVocoder() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let vocoderModelPath = "/path/to/vocoder_model.gguf"
        let result = LlamaMobile.initVocoder(contextHandle, vocoderModelPath)
        XCTAssertTrue(result.success, "initVocoder should succeed")
    }
    
    func testReleaseVocoder() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        XCTAssertNoThrow(LlamaMobile.releaseVocoder(contextHandle), "releaseVocoder should not throw an error")
    }
    
    func testIsVocoderEnabled() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let isEnabled = LlamaMobile.isVocoderEnabled(contextHandle)
        XCTAssertFalse(isEnabled, "isVocoderEnabled should return false initially")
    }
    
    func testGetTTSType() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let ttsType = LlamaMobile.getTTSType(contextHandle)
        XCTAssertEqual(ttsType, .UNKNOWN, "getTTSType should return UNKNOWN initially")
    }

    func testSaveAudioToWav() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let audioData = [Float](repeating: 0.0, count: 1000)
        let filePath = "/tmp/test_audio.wav"
        let success = LlamaMobile.saveAudioToWav(contextHandle, filePath, audioData, 24000)
        XCTAssertTrue(success, "saveAudioToWav should succeed")
    }
    
    // MARK: - Multimodal Tests
    
    func testInitMultimodal() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let mmprojPath = "/path/to/mmproj.gguf"
        let success = LlamaMobile.initMultimodal(contextHandle, mmprojPath, true)
        XCTAssertTrue(success, "initMultimodal should succeed")
    }
    
    func testReleaseMultimodal() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        XCTAssertNoThrow(LlamaMobile.releaseMultimodal(contextHandle), "releaseMultimodal should not throw an error")
    }
    
    func testIsMultimodalEnabled() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let isEnabled = LlamaMobile.isMultimodalEnabled(contextHandle)
        XCTAssertFalse(isEnabled, "isMultimodalEnabled should return false initially")
    }
    
    func testSupportsVision() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let supports = LlamaMobile.supportsVision(contextHandle)
        XCTAssertFalse(supports, "supportsVision should return false initially")
    }
    
    func testSupportsAudio() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let supports = LlamaMobile.supportsAudio(contextHandle)
        XCTAssertFalse(supports, "supportsAudio should return false initially")
    }
    
    // MARK: - LoRA Tests
    
    func testApplyLoraAdapters() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let adapters = [LlamaMobile.LoraAdapter(path: "/path/to/adapter1.gguf", scale: 1.0)]
        let success = LlamaMobile.applyLoraAdapters(contextHandle, adapters)
        XCTAssertTrue(success, "applyLoraAdapters should succeed")
    }
    
    func testRemoveLoraAdapters() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        XCTAssertNoThrow(LlamaMobile.removeLoraAdapters(contextHandle), "removeLoraAdapters should not throw an error")
    }
    
    func testGetLoadedLoraAdapters() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let adapters = LlamaMobile.getLoadedLoraAdapters(contextHandle)
        XCTAssertNotNil(adapters, "getLoadedLoraAdapters should return an array")
    }
    
    // MARK: - Conversation Tests
    
    func testGenerateResponse() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let result = LlamaMobile.generateResponse(contextHandle, "Hello", 100, nil)
        XCTAssertNotNil(result, "generateResponse should return a result")
        XCTAssertNotNil(result.text, "result text should not be nil")
    }
    
    func testClearConversation() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        XCTAssertNoThrow(LlamaMobile.clearConversation(contextHandle), "clearConversation should not throw an error")
    }
    
    func testIsConversationActive() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        let isActive = LlamaMobile.isConversationActive(contextHandle)
        XCTAssertFalse(isActive, "isConversationActive should return false initially")
    }
    
    // MARK: - Embeddings Tests
    
    func testGenerateEmbeddings() {
        let modelPath = "/path/to/embedding_model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: true,
            poolingType: 0,
            embdNormalize: 1,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let embedding = LlamaMobile.generateEmbeddings(contextHandle, "Hello world")
        XCTAssertNotNil(embedding, "generateEmbeddings should return an embedding")
        XCTAssertFalse(embedding.isEmpty, "embedding should not be empty")
    }
    
    // MARK: - Tokenization Tests
    
    func testTokenize() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let text = "Hello, world!"
        let tokens = LlamaMobile.tokenize(contextHandle, text)
        XCTAssertFalse(tokens.isEmpty, "tokenize should return an array of tokens")
    }
    
    func testDetokenize() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let tokens: [Int32] = [1, 2, 3, 4, 5]
        let text = LlamaMobile.detokenize(contextHandle, tokens)
        XCTAssertFalse(text.isEmpty, "detokenize should return a non-empty string")
    }
    
    // MARK: - Model Info Tests
    
    func testGetContextWindowSize() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let size = LlamaMobile.getContextWindowSize(contextHandle)
        XCTAssertGreaterThan(size, 0, "getContextWindowSize should return a positive value")
    }
    
    func testGetEmbeddingDimension() {
        let modelPath = "/path/to/embedding_model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: true,
            poolingType: 0,
            embdNormalize: 1,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let dimension = LlamaMobile.getEmbeddingDimension(contextHandle)
        XCTAssertGreaterThan(dimension, 0, "getEmbeddingDimension should return a positive value")
    }
    
    func testGetModelDescription() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let description = LlamaMobile.getModelDescription(contextHandle)
        XCTAssertFalse(description.isEmpty, "getModelDescription should return a non-empty string")
    }
    
    func testGetModelSize() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let size = LlamaMobile.getModelSize(contextHandle)
        XCTAssertGreaterThan(size, 0, "getModelSize should return a positive value")
    }
    
    func testGetModelParametersCount() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let count = LlamaMobile.getModelParametersCount(contextHandle)
        XCTAssertGreaterThan(count, 0, "getModelParametersCount should return a positive value")
    }
    
    // MARK: - Download Tests
    
    func testDownloadModel() {
        let url = "https://example.com/model.gguf"
        let localPath = "/tmp/model.gguf"
        let result = LlamaMobile.downloadModel(url, localPath)
        XCTAssertNotNil(result, "downloadModel should return a result")
        XCTAssertTrue(result.success, "downloadModel should succeed")
    }
    
    func testDownloadModelWithHeaders() {
        let url = "https://example.com/model.gguf"
        let localPath = "/tmp/model.gguf"
        let headers = ["Authorization": "Bearer token"]
        let result = LlamaMobile.downloadModel(url, localPath, headers)
        XCTAssertNotNil(result, "downloadModel with headers should return a result")
    }
    
    func testDownloadHfFile() {
        let repoId = "example/repo"
        let filename = "model.gguf"
        let destinationPath = "/tmp/model.gguf"
        let result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath)
        XCTAssertNotNil(result, "downloadHfFile should return a result")
        XCTAssertTrue(result.success, "downloadHfFile should succeed")
    }
    
    func testDownloadHfFileWithToken() {
        let repoId = "example/repo"
        let filename = "model.gguf"
        let destinationPath = "/tmp/model.gguf"
        let bearerToken = "hf_token"
        let result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath, bearerToken)
        XCTAssertNotNil(result, "downloadHfFile with token should return a result")
    }
    
    // MARK: - Grammar Tests
    
    func testGetJsonGrammar() {
        let grammar = LlamaMobile.getJsonGrammar()
        XCTAssertFalse(grammar.isEmpty, "getJsonGrammar should return a non-empty string")
    }
    
    func testGetArithmeticGrammar() {
        let grammar = LlamaMobile.getArithmeticGrammar()
        XCTAssertFalse(grammar.isEmpty, "getArithmeticGrammar should return a non-empty string")
    }
    
    func testGetCGrammar() {
        let grammar = LlamaMobile.getCGrammar()
        XCTAssertFalse(grammar.isEmpty, "getCGrammar should return a non-empty string")
    }
    
    // MARK: - Chat Tests
    
    func testSetChatTemplate() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let chatTemplate = "{{.System}}{{.User}}{{.Assistant}}"
        let success = LlamaMobile.setChatTemplate(contextHandle, chatTemplate)
        XCTAssertTrue(success, "setChatTemplate should succeed")
    }
    
    func testGetModelChatTemplate() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let chatTemplate = LlamaMobile.getModelChatTemplate(contextHandle)
        XCTAssertNotNil(chatTemplate, "getModelChatTemplate should return a template")
    }
    
    func testFormatChatMessages() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let messagesJson = """
        [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi there!"}
        ]
        """
        let result = LlamaMobile.formatChatMessages(contextHandle, messagesJson)
        XCTAssertNotNil(result, "formatChatMessages should return a formatted prompt")
        XCTAssertFalse(result.isEmpty, "formatted prompt should not be empty")
    }
    
    func testFormatChatMessagesWithCustomTemplate() {
        let modelPath = "/path/to/model.gguf"
        let initParams = LlamaMobile.InitParams(
            modelPath: modelPath,
            nCtx: 2048,
            chatTemplate: nil,
            systemPrompt: nil,
            nBatch: 512,
            nUBatch: 512,
            nGpuLayers: 0,
            nThreads: 4,
            useMmap: true,
            useMlock: false,
            embedding: false,
            poolingType: 0,
            embdNormalize: 0,
            flashAttention: false,
            cacheTypeK: nil,
            cacheTypeV: nil,
            enableChatTemplate: true,
            chatTemplate: nil
        )
        contextHandle = LlamaMobile.initContext(initParams)
        
        let messagesJson = """
        [
            {"role": "user", "content": "Hello"}
        ]
        """
        let customTemplate = "User: {{.User}}\nAssistant: {{.Assistant}}"
        let result = LlamaMobile.formatChatMessages(contextHandle, messagesJson, customTemplate)
        XCTAssertNotNil(result, "formatChatMessages with custom template should return a formatted prompt")
        XCTAssertFalse(result.isEmpty, "formatted prompt should not be empty")
    }
}
