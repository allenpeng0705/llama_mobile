package com.llamamobile

import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.Assert.*

/**
 * Comprehensive unit test suite for LlamaMobile Android SDK
 * This test suite follows the same structure as the iOS SDK tests for consistency
 */
class LlamaMobileUnitTests {
    
    /**
     * Test helper structure for model paths
     */
    companion object TestPaths {
        // Root path to models directory
        const val rootPath = "/sdcard/llama_mobile/models"
        
        // Regular text model
        const val modelPath = "$rootPath/SmolLM-360M-Instruct.Q6_K.gguf"
        
        // TTS models
        const val ttsModelPath = "$rootPath/OuteTTS-0.2-500M-Q6_K.gguf"
        const val altTTSModelPath = "$rootPath/Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf"
        
        // Vocoder model
        const val vocoderPath = "$rootPath/WavTokenizer-Large-75-F16.gguf"
        
        // Embedding model
        const val embeddingPath = "$rootPath/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf"
        
        // Multimodal projection file
        const val mmprojPath = "$rootPath/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf"
        
        // LoRA adapter
        const val loraPath = "$rootPath/lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf"
        
        // Vision model
        const val imageModelPath = "$rootPath/SmolVLM-256M-Instruct-Q8_0.gguf"
        
        // Test image
        const val imagePath = "$rootPath/img/image.jpg"
        
        // Invalid paths for error testing
        const val invalidModelPath = "/invalid/path/to/model.gguf"
        const val invalidEmbeddingPath = "/invalid/path/to/embedding.gguf"
    }
    
    // Test context handle
    private var contextHandle: Long = 0
    
    @Before
    fun setUp() {
        // Initialize with invalid path to get a test instance (nil context testing)
        val params = LlamaMobile.InitParams(modelPath = invalidModelPath)
        contextHandle = LlamaMobile.initContext(params)
    }
    
    @After
    fun tearDown() {
        // Release context if valid
        if (contextHandle > 0) {
            LlamaMobile.releaseContext(contextHandle)
        }
        contextHandle = 0
    }
    
    // MARK: - Enum Tests
    
    @Test
    fun testErrorTypeEnum() {
        // Test that all error types exist and can be accessed
        val errorTypes = listOf(
            LlamaMobile.ErrorType.CONTEXT_NOT_INITIALIZED,
            LlamaMobile.ErrorType.INVALID_PARAMETER,
            LlamaMobile.ErrorType.OPERATION_FAILED,
            LlamaMobile.ErrorType.VOCODER_NOT_INITIALIZED,
            LlamaMobile.ErrorType.MULTIMODAL_NOT_INITIALIZED,
            LlamaMobile.ErrorType.MEDIA_PROCESSING_FAILED,
            LlamaMobile.ErrorType.TOKENIZATION_FAILED,
            LlamaMobile.ErrorType.DETOKENIZATION_FAILED,
            LlamaMobile.ErrorType.EMBEDDING_GENERATION_FAILED,
            LlamaMobile.ErrorType.AUDIO_GENERATION_FAILED,
            LlamaMobile.ErrorType.CONVERSATION_FAILED
        )
        assertEquals(11, errorTypes.size)
    }
    
    @Test
    fun testTTSModelTypeEnum() {
        // Test TTS model type conversions
        assertEquals(LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.TTSModelType.fromInt(0))
        assertEquals(LlamaMobile.TTSModelType.OUT_ETTS_V02, LlamaMobile.TTSModelType.fromInt(1))
        assertEquals(LlamaMobile.TTSModelType.OUT_ETTS_V03, LlamaMobile.TTSModelType.fromInt(2))
        assertEquals(LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.TTSModelType.fromInt(999))
    }
    
    // MARK: - Data Class Tests
    
    @Test
    fun testInitParamsConstructors() {
        // Test default constructor
        val defaultParams = LlamaMobile.InitParams(modelPath = modelPath)
        assertEquals(modelPath, defaultParams.modelPath)
        assertEquals(2048, defaultParams.nCtx)
        assertNull(defaultParams.chatTemplate)
        assertNull(defaultParams.systemPrompt)
        assertEquals(512, defaultParams.nBatch)
        assertEquals(512, defaultParams.nUBatch)
        assertEquals(0, defaultParams.nGpuLayers)
        assertEquals(4, defaultParams.nThreads)
        assertTrue(defaultParams.useMmap)
        assertFalse(defaultParams.useMlock)
        assertFalse(defaultParams.embedding)
        assertEquals(0, defaultParams.poolingType)
        assertEquals(0, defaultParams.embdNormalize)
        assertFalse(defaultParams.flashAttention)
        assertNull(defaultParams.cacheTypeK)
        assertNull(defaultParams.cacheTypeV)
        
        // Test GPU constructor
        val gpuParams = LlamaMobile.InitParams(modelPath = modelPath, nGpuLayers = 4, nCtx = 4096)
        assertEquals(4, gpuParams.nGpuLayers)
        assertEquals(4096, gpuParams.nCtx)
        
        // Test embedding constructor
        val embeddingParams = LlamaMobile.InitParams(modelPath = embeddingPath, embedding = true, poolingType = 1)
        assertTrue(embeddingParams.embedding)
        assertEquals(1, embeddingParams.poolingType)
    }
    
    @Test
    fun testCompletionParamsConstructors() {
        val testPrompt = "Hello, world!"
        
        // Test default constructor
        val defaultParams = LlamaMobile.CompletionParams(prompt = testPrompt)
        assertEquals(testPrompt, defaultParams.prompt)
        assertEquals(128, defaultParams.maxTokens)
        assertEquals(0.8f, defaultParams.temperature)
        assertEquals(40, defaultParams.topK)
        assertEquals(0.95f, defaultParams.topP)
        assertEquals(0.05f, defaultParams.minP)
        assertEquals(1.0f, defaultParams.typicalP)
        assertEquals(64, defaultParams.penaltyLastN)
        assertEquals(1.1f, defaultParams.penaltyRepeat)
        assertEquals(0.0f, defaultParams.penaltyFreq)
        assertEquals(0.0f, defaultParams.penaltyPresent)
        assertEquals(0, defaultParams.mirostat)
        assertEquals(5.0f, defaultParams.mirostatTau)
        assertEquals(0.1f, defaultParams.mirostatEta)
        assertFalse(defaultParams.ignoreEos)
        assertTrue(defaultParams.stopSequences.isEmpty())
        assertNull(defaultParams.grammar)
        assertTrue(defaultParams.mediaPaths.isEmpty())
        
        // Test creative writing constructor
        val creativeParams = LlamaMobile.CompletionParams(creativePrompt = testPrompt, maxTokens = 512)
        assertEquals(testPrompt, creativeParams.prompt)
        assertEquals(512, creativeParams.maxTokens)
        assertEquals(1.0f, creativeParams.temperature)
        assertEquals(0.98f, creativeParams.topP)
        assertEquals(100, creativeParams.topK)
        
        // Test factual output constructor
        val factualParams = LlamaMobile.CompletionParams(factualPrompt = testPrompt)
        assertEquals(testPrompt, factualParams.prompt)
        assertEquals(0.1f, factualParams.temperature)
        assertEquals(0.9f, factualParams.topP)
        assertEquals(20, factualParams.topK)
        
        // Test chat response constructor
        val chatParams = LlamaMobile.CompletionParams(chatPrompt = testPrompt, maxTokens = 256)
        assertEquals(testPrompt, chatParams.prompt)
        assertEquals(256, chatParams.maxTokens)
        assertEquals(0.7f, chatParams.temperature)
        assertEquals(0.95f, chatParams.topP)
        assertEquals(40, chatParams.topK)
        assertEquals(1.2f, chatParams.penaltyRepeat)
        
        // Test multimodal constructor
        val multimodalParams = LlamaMobile.CompletionParams(
            multimodalPrompt = testPrompt, 
            mediaPaths = listOf(imagePath), 
            maxTokens = 256
        )
        assertEquals(testPrompt, multimodalParams.prompt)
        assertEquals(256, multimodalParams.maxTokens)
        assertEquals(1, multimodalParams.mediaPaths.size)
        assertEquals(imagePath, multimodalParams.mediaPaths.first())
    }
    
    @Test
    fun testLoraAdapterDataClass() {
        // Test LoraAdapter data class
        val loraAdapter = LlamaMobile.LoraAdapter(path = loraPath, scale = 1.5f)
        assertEquals(loraPath, loraAdapter.path)
        assertEquals(1.5f, loraAdapter.scale)
        
        // Test default scale
        val defaultAdapter = LlamaMobile.LoraAdapter(path = loraPath)
        assertEquals(1.0f, defaultAdapter.scale)
    }
    
    @Test
    fun testDownloadParamsDataClass() {
        // Test DownloadParams data class
        val testUrl = "https://huggingface.co/model"
        val testLocalPath = "/sdcard/download/model.gguf"
        
        val params = LlamaMobile.DownloadParams(url = testUrl, localPath = testLocalPath)
        assertEquals(testUrl, params.url)
        assertEquals(testLocalPath, params.localPath)
        assertNull(params.password)
        assertNull(params.headers)
        
        // Test with optional parameters
        val headers = mapOf("Authorization" to "Bearer token")
        val paramsWithAuth = LlamaMobile.DownloadParams(
            url = testUrl, 
            localPath = testLocalPath, 
            password = "secret", 
            headers = headers
        )
        assertEquals("secret", paramsWithAuth.password)
        assertEquals(headers, paramsWithAuth.headers)
    }
    
    // MARK: - Context Management Tests
    
    @Test
    fun testContextInitializationWithInvalidPath() {
        // Test initialization with invalid model path
        val params = LlamaMobile.InitParams(modelPath = invalidModelPath)
        val handle = LlamaMobile.initContext(params)
        assertEquals(0, handle)
        
        // Should release gracefully
        LlamaMobile.releaseContext(handle)
    }
    
    // MARK: - Method Safety Tests with Nil Context
    
    @Test
    fun testCompletionMethodsWithInvalidContext() {
        // All completion methods should return null with invalid context
        val params = LlamaMobile.CompletionParams(prompt = "Hello")
        val result1 = LlamaMobile.generateCompletion(0, params)
        assertNull(result1)
        
        val result2 = LlamaMobile.generateCompletion(0, "Hello")
        assertNull(result2)
        
        // Test stop completion with invalid context (should not crash)
        LlamaMobile.stopCompletion(0)
    }
    
    @Test
    fun testTokenizationMethodsWithInvalidContext() {
        // Tokenization methods should return null with invalid context
        val tokens = LlamaMobile.tokenize(0, "Hello")
        assertNull(tokens)
        
        val text = LlamaMobile.detokenize(0, intArrayOf(1, 2, 3))
        assertNull(text)
    }
    
    @Test
    fun testEmbeddingMethodsWithInvalidContext() {
        // Embedding methods should return null with invalid context
        val embeddings = LlamaMobile.generateEmbeddings(0, "Hello")
        assertNull(embeddings)
        
        val dim = LlamaMobile.getEmbeddingDimension(0)
        assertEquals(0, dim)
    }
    
    @Test
    fun testMultimodalMethodsWithInvalidContext() {
        // Multimodal methods should return false with invalid context
        val result1 = LlamaMobile.initMultimodal(0, mmprojPath)
        assertFalse(result1)
        
        val result2 = LlamaMobile.isMultimodalEnabled(0)
        assertFalse(result2)
        
        val result3 = LlamaMobile.supportsVision(0)
        assertFalse(result3)
        
        val result4 = LlamaMobile.supportsAudio(0)
        assertFalse(result4)
        
        // Should not crash
        LlamaMobile.releaseMultimodal(0)
    }
    
    @Test
    fun testTTSMethodsWithInvalidContext() {
        // TTS methods should return appropriate values with invalid context
        val result1 = LlamaMobile.initVocoder(0, vocoderPath)
        assertFalse(result1)
        
        val result2 = LlamaMobile.isVocoderEnabled(0)
        assertFalse(result2)
        
        val result3 = LlamaMobile.getTTSType(0)
        assertEquals(LlamaMobile.TTSModelType.UNKNOWN, result3)
        
        val result4 = LlamaMobile.getFormattedAudioCompletion(0, "{}", "Hello")
        assertNull(result4)
        
        val result5 = LlamaMobile.getAudioGuideTokens(0, "Hello")
        assertNull(result5)
        
        val result6 = LlamaMobile.decodeAudioTokens(0, intArrayOf(1, 2, 3))
        assertNull(result6)
        
        val result7 = LlamaMobile.generateAudioFromText(0, "Hello")
        assertNull(result7)
        
        // Should not crash
        LlamaMobile.releaseVocoder(0)
    }
    
    @Test
    fun testLoRAMethodsWithInvalidContext() {
        // LoRA methods should return appropriate values with invalid context
        val adapter = LlamaMobile.LoraAdapter(path = loraPath)
        val result1 = LlamaMobile.applyLoraAdapters(0, arrayOf(adapter))
        assertFalse(result1)
        
        val result2 = LlamaMobile.getLoadedLoraAdapters(0)
        assertNull(result2)
        
        // Should not crash
        LlamaMobile.removeLoraAdapters(0)
    }
    
    @Test
    fun testConversationMethodsWithInvalidContext() {
        // Conversation methods should return appropriate values with invalid context
        val result1 = LlamaMobile.generateResponse(0, "Hello")
        assertNull(result1)
        
        val result2 = LlamaMobile.isConversationActive(0)
        assertFalse(result2)
        
        // Should not crash
        LlamaMobile.clearConversation(0)
    }
    
    @Test
    fun testModelInfoMethodsWithInvalidContext() {
        // Model info methods should return appropriate values with invalid context
        val result1 = LlamaMobile.getContextWindowSize(0)
        assertEquals(0, result1)
        
        val result2 = LlamaMobile.getModelDescription(0)
        assertNull(result2)
        
        val result3 = LlamaMobile.getModelSize(0)
        assertEquals(0, result3)
        
        val result4 = LlamaMobile.getModelParametersCount(0)
        assertEquals(0, result4)
    }
    
    // MARK: - Parameter Edge Cases Tests
    
    @Test
    fun testCompletionParamsEdgeCases() {
        // Test completion with various edge case parameters
        val params = LlamaMobile.CompletionParams(
            prompt = "",
            maxTokens = 0,
            temperature = 0.0f,
            topK = 0,
            topP = 0.0f,
            minP = 0.0f,
            typicalP = 0.0f,
            penaltyLastN = 0,
            penaltyRepeat = 0.0f,
            penaltyFreq = 0.0f,
            penaltyPresent = 0.0f,
            mirostat = 0,
            mirostatTau = 0.0f,
            mirostatEta = 0.0f,
            ignoreEos = true,
            stopSequences = listOf("\n"),
            grammar = "",
            mediaPaths = listOf("")
        )
        
        // Verify all edge case parameters were set correctly
        assertEquals("", params.prompt)
        assertEquals(0, params.maxTokens)
        assertEquals(0.0f, params.temperature)
        assertEquals(0, params.topK)
        assertEquals(0.0f, params.topP)
        assertEquals(1, params.stopSequences.size)
        assertEquals(1, params.mediaPaths.size)
    }
    
    @Test
    fun testInitParamsEdgeCases() {
        // Test init parameters with edge cases
        val params = LlamaMobile.InitParams(
            modelPath = modelPath,
            nCtx = 1,
            nBatch = 1,
            nUBatch = 1,
            nGpuLayers = -1,
            nThreads = -1,
            useMmap = false,
            useMlock = true,
            embedding = true,
            poolingType = 999,
            embdNormalize = 999,
            flashAttention = true
        )
        
        // Verify all edge case parameters were set correctly
        assertEquals(1, params.nCtx)
        assertEquals(1, params.nBatch)
        assertEquals(1, params.nUBatch)
        assertEquals(-1, params.nGpuLayers)
        assertEquals(-1, params.nThreads)
        assertFalse(params.useMmap)
        assertTrue(params.useMlock)
        assertTrue(params.embedding)
        assertEquals(999, params.poolingType)
        assertEquals(999, params.embdNormalize)
        assertTrue(params.flashAttention)
    }
    
    // MARK: - Integration Tests with Real Models (Conditional)
    
    @Test
    fun testRealModelLoading() {
        // Skip if model file doesn't exist
        val modelFile = java.io.File(modelPath)
        if (!modelFile.exists()) {
            return
        }
        
        // Test real model loading
        val params = LlamaMobile.InitParams(modelPath = modelPath)
        val handle = LlamaMobile.initContext(params)
        
        // This might fail if model is not accessible, so we won't assert success
        if (handle > 0) {
            // If model loaded successfully, verify basic info
            val modelSize = LlamaMobile.getModelSize(handle)
            assertTrue(modelSize > 0)
            
            val paramCount = LlamaMobile.getModelParametersCount(handle)
            assertTrue(paramCount > 0)
            
            LlamaMobile.releaseContext(handle)
        }
    }
    
    @Test
    fun testRealEmbeddingModel() {
        // Skip if embedding model file doesn't exist
        val embeddingFile = java.io.File(embeddingPath)
        if (!embeddingFile.exists()) {
            return
        }
        
        // Test real embedding model
        val params = LlamaMobile.InitParams(modelPath = embeddingPath, embedding = true)
        val handle = LlamaMobile.initContext(params)
        
        if (handle > 0) {
            val embeddings = LlamaMobile.generateEmbeddings(handle, "Hello, world!")
            if (embeddings != null) {
                assertTrue(embeddings.isNotEmpty())
            }
            
            val dim = LlamaMobile.getEmbeddingDimension(handle)
            assertTrue(dim > 0)
            
            LlamaMobile.releaseContext(handle)
        }
    }
    
    @Test
    fun testRealModelCompletion() {
        // Skip if model file doesn't exist
        val modelFile = java.io.File(modelPath)
        if (!modelFile.exists()) {
            return
        }
        
        // Test real model completion
        val params = LlamaMobile.InitParams(modelPath = modelPath)
        val handle = LlamaMobile.initContext(params)
        
        if (handle > 0) {
            val completionParams = LlamaMobile.CompletionParams(
                prompt = "Hello, my name is",
                maxTokens = 10,
                temperature = 0.7f
            )
            
            val result = LlamaMobile.generateCompletion(handle, completionParams)
            if (result != null) {
                assertFalse(result.text.isEmpty())
                assertTrue(result.tokensGenerated > 0)
            }
            
            LlamaMobile.releaseContext(handle)
        }
    }
}
