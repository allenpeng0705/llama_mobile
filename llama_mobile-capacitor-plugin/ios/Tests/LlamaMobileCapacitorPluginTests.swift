import XCTest
@testable import LlamaMobileCapacitorPlugin

class LlamaMobileCapacitorPluginTests: XCTestCase {
    var plugin: LlamaMobileCapacitorPlugin!
    var contextHandle: Int64 = -1
    
    override func setUp() {
        super.setUp()
        plugin = LlamaMobileCapacitorPlugin()
    }
    
    override func tearDown() {
        if contextHandle != -1 {
            plugin.releaseContext(contextHandle: contextHandle)
        }
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitContext() {
        let modelPath = "/path/to/dummy/model.gguf"
        contextHandle = plugin.initContext(modelPath: modelPath, nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNotEqual(contextHandle, -1, "initContext should return a valid context handle")
    }
    
    func testInitContextWithEmbedding() {
        let modelPath = "/path/to/dummy/embedding_model.gguf"
        contextHandle = plugin.initContext(modelPath: modelPath, nCtx: 2048, nGpuLayers: 0, nThreads: 4, embedding: true, poolingType: 0, embdNormalize: 1)
        XCTAssertNotEqual(contextHandle, -1, "initContext with embedding should return a valid context handle")
    }
    
    func testReleaseContext() {
        let handle: Int64 = 1
        XCTAssertNoThrow(plugin.releaseContext(contextHandle: handle), "releaseContext should not throw an error")
    }
    
    // MARK: - Completion Tests
    
    func testGenerateCompletion() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let result = plugin.generateCompletion(contextHandle: contextHandle, prompt: "Hello", temperature: 0.7, maxTokens: 100, nThreads: 4)
        XCTAssertNotNil(result, "generateCompletion should return a result")
        XCTAssertNotNil(result?.text, "result text should not be nil")
    }
    
    func testGenerateCompletionWithMedia() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let mediaPaths = ["/path/to/image.jpg"]
        let result = plugin.generateCompletion(contextHandle: contextHandle, prompt: "Describe this image", temperature: 0.7, maxTokens: 100, nThreads: 4, mediaPaths: mediaPaths)
        XCTAssertNotNil(result, "generateCompletion with media should return a result")
    }
    
    func testGenerateCompletionWithStopSequences() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let stopSequences = ["\n", "END"]
        let result = plugin.generateCompletion(contextHandle: contextHandle, prompt: "Hello", temperature: 0.7, maxTokens: 100, nThreads: 4, stopSequences: stopSequences)
        XCTAssertNotNil(result, "generateCompletion with stop sequences should return a result")
    }
    
    func testStopCompletion() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNoThrow(plugin.stopCompletion(contextHandle: contextHandle), "stopCompletion should not throw an error")
    }
    
    // MARK: - OpenAI Completion Tests
    
    func testGenerateOpenAICompletion() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
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
        let result = plugin.generateOpenAICompletion(contextHandle: contextHandle, openAIJSON: openAIJSON)
        XCTAssertNotNil(result, "generateOpenAICompletion should return a result")
    }
    
    func testGenerateOpenAICompletionWithGrammar() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let openAIJSON = """
        {
            "model": "gpt-3.5-turbo",
            "messages": [
                {"role": "user", "content": "Generate a JSON object"}
            ],
            "temperature": 0.7,
            "max_tokens": 100
        }
        """
        let grammar = plugin.getJsonGrammar()
        let result = plugin.generateOpenAICompletion(contextHandle: contextHandle, openAIJSON: openAIJSON, grammar: grammar)
        XCTAssertNotNil(result, "generateOpenAICompletion with grammar should return a result")
    }
    
    // MARK: - TTS Tests
    
    func testInitVocoder() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let vocoderModelPath = "/path/to/vocoder_model.gguf"
        let result = plugin.initVocoder(contextHandle: contextHandle, vocoderModelPath: vocoderModelPath)
        XCTAssertTrue(result.success, "initVocoder should succeed")
    }
    
    func testReleaseVocoder() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNoThrow(plugin.releaseVocoder(contextHandle: contextHandle), "releaseVocoder should not throw an error")
    }
    
    func testIsVocoderEnabled() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let isEnabled = plugin.isVocoderEnabled(contextHandle: contextHandle)
        XCTAssertFalse(isEnabled, "isVocoderEnabled should return false initially")
    }
    
    func testGetTTSType() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let ttsType = plugin.getTTSType(contextHandle: contextHandle)
        XCTAssertEqual(ttsType, "NONE", "getTTSType should return NONE initially")
    }
    
    func testGenerateAudioFromText() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let result = plugin.generateAudioFromText(contextHandle: contextHandle, text: "Hello world")
        XCTAssertNotNil(result, "generateAudioFromText should return audio data")
        XCTAssertFalse(result.isEmpty, "audio data should not be empty")
    }
    
    func testGenerateAudioFromTextWithSpeakerJson() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let speakerJson = """
        {
            "speaker": "default",
            "speed": 1.0
        }
        """
        let result = plugin.generateAudioFromText(contextHandle: contextHandle, text: "Hello world", speakerJson: speakerJson)
        XCTAssertNotNil(result, "generateAudioFromText with speaker json should return audio data")
    }
    
    func testSaveAudioToWav() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let audioData = [Float](repeating: 0.0, count: 1000)
        let filePath = "/tmp/test_audio.wav"
        let success = plugin.saveAudioToWav(contextHandle: contextHandle, filePath: filePath, audioData: audioData, sampleRate: 24000)
        XCTAssertTrue(success, "saveAudioToWav should succeed")
    }
    
    func testPlayAudio() {
        let audioData = [Float](repeating: 0.1, count: 1000)
        let success = plugin.playAudio(audioData: audioData, sampleRate: 24000)
        XCTAssertTrue(success, "playAudio should succeed")
    }
    
    // MARK: - Multimodal Tests
    
    func testInitMultimodal() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let mmprojPath = "/path/to/mmproj.gguf"
        let success = plugin.initMultimodal(contextHandle: contextHandle, mmprojPath: mmprojPath, useGpu: true)
        XCTAssertTrue(success, "initMultimodal should succeed")
    }
    
    func testReleaseMultimodal() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNoThrow(plugin.releaseMultimodal(contextHandle: contextHandle), "releaseMultimodal should not throw an error")
    }
    
    func testIsMultimodalEnabled() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let isEnabled = plugin.isMultimodalEnabled(contextHandle: contextHandle)
        XCTAssertFalse(isEnabled, "isMultimodalEnabled should return false initially")
    }
    
    func testSupportsVision() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let supports = plugin.supportsVision(contextHandle: contextHandle)
        XCTAssertFalse(supports, "supportsVision should return false initially")
    }
    
    func testSupportsAudio() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let supports = plugin.supportsAudio(contextHandle: contextHandle)
        XCTAssertFalse(supports, "supportsAudio should return false initially")
    }
    
    // MARK: - LoRA Tests
    
    func testApplyLoraAdapters() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let adapters = [["path": "/path/to/adapter1.gguf", "scale": 1.0]]
        let success = plugin.applyLoraAdapters(contextHandle: contextHandle, adapters: adapters)
        XCTAssertTrue(success, "applyLoraAdapters should succeed")
    }
    
    func testRemoveLoraAdapters() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNoThrow(plugin.removeLoraAdapters(contextHandle: contextHandle), "removeLoraAdapters should not throw an error")
    }
    
    func testGetLoadedLoraAdapters() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let adapters = plugin.getLoadedLoraAdapters(contextHandle: contextHandle)
        XCTAssertNotNil(adapters, "getLoadedLoraAdapters should return an array")
    }
    
    // MARK: - Conversation Tests
    
    func testGenerateResponse() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let result = plugin.generateResponse(contextHandle: contextHandle, userMessage: "Hello", maxTokens: 100)
        XCTAssertNotNil(result, "generateResponse should return a result")
        XCTAssertNotNil(result?.text, "result text should not be nil")
        XCTAssertGreaterThan(result?.timeToFirstToken ?? 0, 0, "timeToFirstToken should be positive")
        XCTAssertGreaterThan(result?.totalTime ?? 0, 0, "totalTime should be positive")
        XCTAssertGreaterThan(result?.tokensGenerated ?? 0, 0, "tokensGenerated should be positive")
    }
    
    func testClearConversation() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        XCTAssertNoThrow(plugin.clearConversation(contextHandle: contextHandle), "clearConversation should not throw an error")
    }
    
    func testIsConversationActive() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let isActive = plugin.isConversationActive(contextHandle: contextHandle)
        XCTAssertFalse(isActive, "isConversationActive should return false initially")
    }
    
    // MARK: - Embeddings Tests
    
    func testGenerateEmbeddings() {
        contextHandle = plugin.initContext(modelPath: "/path/to/embedding_model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4, embedding: true, poolingType: 0, embdNormalize: 1)
        let embedding = plugin.generateEmbeddings(contextHandle: contextHandle, text: "Hello world")
        XCTAssertNotNil(embedding, "generateEmbeddings should return an embedding")
        XCTAssertFalse(embedding.isEmpty, "embedding should not be empty")
    }
    
    // MARK: - Tokenization Tests
    
    func testTokenize() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let text = "Hello, world!"
        let tokens = plugin.tokenize(contextHandle: contextHandle, text: text)
        XCTAssertFalse(tokens.isEmpty, "tokenize should return an array of tokens")
    }
    
    func testDetokenize() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let tokens: [Int32] = [1, 2, 3, 4, 5]
        let text = plugin.detokenize(contextHandle: contextHandle, tokens: tokens)
        XCTAssertFalse(text.isEmpty, "detokenize should return a non-empty string")
    }
    
    // MARK: - Model Info Tests
    
    func testGetContextWindowSize() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let size = plugin.getContextWindowSize(contextHandle: contextHandle)
        XCTAssertGreaterThan(size, 0, "getContextWindowSize should return a positive value")
    }
    
    func testGetEmbeddingDimension() {
        contextHandle = plugin.initContext(modelPath: "/path/to/embedding_model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4, embedding: true, poolingType: 0, embdNormalize: 1)
        let dimension = plugin.getEmbeddingDimension(contextHandle: contextHandle)
        XCTAssertGreaterThan(dimension, 0, "getEmbeddingDimension should return a positive value")
    }
    
    func testGetModelDescription() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let description = plugin.getModelDescription(contextHandle: contextHandle)
        XCTAssertFalse(description.isEmpty, "getModelDescription should return a non-empty string")
    }
    
    func testGetModelSize() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let size = plugin.getModelSize(contextHandle: contextHandle)
        XCTAssertGreaterThan(size, 0, "getModelSize should return a positive value")
    }
    
    func testGetModelParametersCount() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let count = plugin.getModelParametersCount(contextHandle: contextHandle)
        XCTAssertGreaterThan(count, 0, "getModelParametersCount should return a positive value")
    }
    
    func testListFiles() {
        let directoryPath = "/path/to/models"
        let result = plugin.listFiles(directoryPath: directoryPath)
        XCTAssertNotNil(result, "listFiles should return a result")
        XCTAssertNotNil(result.files, "result files should not be nil")
    }
    
    func testListModels() {
        let result = plugin.listModels()
        XCTAssertNotNil(result, "listModels should return a result")
        XCTAssertNotNil(result.modelFiles, "result modelFiles should not be nil")
    }
    
    // MARK: - Download Tests
    
    func testDownloadModel() {
        let url = "https://example.com/model.gguf"
        let localPath = "/tmp/model.gguf"
        let result = plugin.downloadModel(url: url, localPath: localPath)
        XCTAssertNotNil(result, "downloadModel should return a result")
        XCTAssertTrue(result.success, "downloadModel should succeed")
    }
    
    func testDownloadModelWithHeaders() {
        let url = "https://example.com/model.gguf"
        let localPath = "/tmp/model.gguf"
        let headers = ["Authorization": "Bearer token"]
        let result = plugin.downloadModel(url: url, localPath: localPath, headers: headers)
        XCTAssertNotNil(result, "downloadModel with headers should return a result")
    }
    
    func testDownloadHfFile() {
        let repoId = "example/repo"
        let filename = "model.gguf"
        let destinationPath = "/tmp/model.gguf"
        let result = plugin.downloadHfFile(repoId: repoId, filename: filename, destinationPath: destinationPath)
        XCTAssertNotNil(result, "downloadHfFile should return a result")
        XCTAssertTrue(result.success, "downloadHfFile should succeed")
    }
    
    func testDownloadHfFileWithToken() {
        let repoId = "example/repo"
        let filename = "model.gguf"
        let destinationPath = "/tmp/model.gguf"
        let bearerToken = "hf_token"
        let result = plugin.downloadHfFile(repoId: repoId, filename: filename, destinationPath: destinationPath, bearerToken: bearerToken)
        XCTAssertNotNil(result, "downloadHfFile with token should return a result")
    }
    
    // MARK: - Grammar Tests
    
    func testGetJsonGrammar() {
        let grammar = plugin.getJsonGrammar()
        XCTAssertFalse(grammar.isEmpty, "getJsonGrammar should return a non-empty string")
    }
    
    func testGetArithmeticGrammar() {
        let grammar = plugin.getArithmeticGrammar()
        XCTAssertFalse(grammar.isEmpty, "getArithmeticGrammar should return a non-empty string")
    }
    
    func testGetCGrammar() {
        let grammar = plugin.getCGrammar()
        XCTAssertFalse(grammar.isEmpty, "getCGrammar should return a non-empty string")
    }
    
    // MARK: - Chat Tests
    
    func testSetChatTemplate() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let chatTemplate = "{{.System}}{{.User}}{{.Assistant}}"
        let success = plugin.setChatTemplate(contextHandle: contextHandle, chatTemplate: chatTemplate)
        XCTAssertTrue(success, "setChatTemplate should succeed")
    }
    
    func testGetModelChatTemplate() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let chatTemplate = plugin.getModelChatTemplate(contextHandle: contextHandle)
        XCTAssertNotNil(chatTemplate, "getModelChatTemplate should return a template")
    }
    
    func testFormatChatMessages() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let messagesJson = """
        [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi there!"}
        ]
        """
        let result = plugin.formatChatMessages(contextHandle: contextHandle, messagesJson: messagesJson)
        XCTAssertNotNil(result, "formatChatMessages should return a formatted prompt")
        XCTAssertFalse(result.isEmpty, "formatted prompt should not be empty")
    }
    
    func testFormatChatMessagesWithCustomTemplate() {
        contextHandle = plugin.initContext(modelPath: "/path/to/model.gguf", nCtx: 2048, nGpuLayers: 0, nThreads: 4)
        let messagesJson = """
        [
            {"role": "user", "content": "Hello"}
        ]
        """
        let customTemplate = "User: {{.User}}\nAssistant: {{.Assistant}}"
        let result = plugin.formatChatMessages(contextHandle: contextHandle, messagesJson: messagesJson, chatTemplate: customTemplate)
        XCTAssertNotNil(result, "formatChatMessages with custom template should return a formatted prompt")
        XCTAssertFalse(result.isEmpty, "formatted prompt should not be empty")
    }
}
