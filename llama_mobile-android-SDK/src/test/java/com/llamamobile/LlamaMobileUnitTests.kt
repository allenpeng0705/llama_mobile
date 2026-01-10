package com.llamamobile

import org.junit.After
import org.junit.Assert
import org.junit.Before
import org.junit.Test
import java.util.*

/**
 * Unit tests for LlamaMobile Kotlin SDK
 */
class LlamaMobileUnitTests {
    private val TEST_MODEL_PATH = "/path/to/test/model.gguf"
    private var mockContextHandle: Long = 0

    @Before
    fun setUp() {
        // Initialize with a mock context handle
        mockContextHandle = 12345L
    }

    @After
    fun tearDown() {
        // Clean up any resources
        if (mockContextHandle != 0L) {
            LlamaMobile.releaseContext(mockContextHandle)
            mockContextHandle = 0
        }
    }

    @Test
    fun testInitParamsConstructors() {
        // Test primary constructor
        val params1 = LlamaMobile.InitParams(TEST_MODEL_PATH)
        Assert.assertEquals(TEST_MODEL_PATH, params1.modelPath)
        Assert.assertEquals(2048, params1.nCtx)
        Assert.assertNull(params1.chatTemplate)
        Assert.assertNull(params1.systemPrompt)
        Assert.assertEquals(0, params1.nGpuLayers)
        Assert.assertEquals(4, params1.nThreads)
        Assert.assertTrue(params1.useMmap)
        Assert.assertFalse(params1.useMlock)
        Assert.assertFalse(params1.embedding)
        Assert.assertEquals(0, params1.poolingType)
        Assert.assertEquals(0, params1.embdNormalize)
        Assert.assertFalse(params1.flashAttention)
        Assert.assertNull(params1.cacheTypeK)
        Assert.assertNull(params1.cacheTypeV)

        // Test GPU constructor
        val params2 = LlamaMobile.InitParams(TEST_MODEL_PATH, nGpuLayers = 4, nCtx = 4096)
        Assert.assertEquals(TEST_MODEL_PATH, params2.modelPath)
        Assert.assertEquals(4096, params2.nCtx)
        Assert.assertEquals(4, params2.nGpuLayers)

        // Test embedding constructor
        val params3 = LlamaMobile.InitParams(TEST_MODEL_PATH, embedding = true, poolingType = 1)
        Assert.assertEquals(TEST_MODEL_PATH, params3.modelPath)
        Assert.assertTrue(params3.embedding)
        Assert.assertEquals(1, params3.poolingType)
    }

    @Test
    fun testCompletionParamsConstructors() {
        val testPrompt = "Hello, world!"

        // Test primary constructor
        val params1 = LlamaMobile.CompletionParams(prompt = testPrompt)
        Assert.assertEquals(testPrompt, params1.prompt)
        Assert.assertEquals(128, params1.maxTokens)
        Assert.assertEquals(0.8f, params1.temperature)
        Assert.assertEquals(40, params1.topK)
        Assert.assertEquals(0.95f, params1.topP)
        Assert.assertEquals(0.05f, params1.minP)
        Assert.assertEquals(1.0f, params1.typicalP)
        Assert.assertEquals(64, params1.penaltyLastN)
        Assert.assertEquals(1.1f, params1.penaltyRepeat)
        Assert.assertEquals(0.0f, params1.penaltyFreq)
        Assert.assertEquals(0.0f, params1.penaltyPresent)
        Assert.assertEquals(0, params1.mirostat)
        Assert.assertEquals(5.0f, params1.mirostatTau)
        Assert.assertEquals(0.1f, params1.mirostatEta)
        Assert.assertFalse(params1.ignoreEos)
        Assert.assertTrue(params1.stopSequences.isEmpty())
        Assert.assertNull(params1.grammar)
        Assert.assertTrue(params1.mediaPaths.isEmpty())

        // Test creative prompt constructor
        val params2 = LlamaMobile.CompletionParams(creativePrompt = testPrompt, maxTokens = 512)
        Assert.assertEquals(testPrompt, params2.prompt)
        Assert.assertEquals(512, params2.maxTokens)
        Assert.assertEquals(1.0f, params2.temperature)
        Assert.assertEquals(0.98f, params2.topP)
        Assert.assertEquals(100, params2.topK)

        // Test factual prompt constructor
        val params3 = LlamaMobile.CompletionParams(factualPrompt = testPrompt)
        Assert.assertEquals(testPrompt, params3.prompt)
        Assert.assertEquals(0.1f, params3.temperature)
        Assert.assertEquals(0.9f, params3.topP)
        Assert.assertEquals(20, params3.topK)

        // Test chat prompt constructor
        val params4 = LlamaMobile.CompletionParams(chatPrompt = testPrompt, maxTokens = 256)
        Assert.assertEquals(testPrompt, params4.prompt)
        Assert.assertEquals(256, params4.maxTokens)
        Assert.assertEquals(0.7f, params4.temperature)
        Assert.assertEquals(0.95f, params4.topP)
        Assert.assertEquals(40, params4.topK)
        Assert.assertEquals(1.2f, params4.penaltyRepeat)

        // Test multimodal prompt constructor
        val mediaPaths = listOf("/path/to/image.jpg", "/path/to/audio.wav")
        val params5 = LlamaMobile.CompletionParams(
            multimodalPrompt = testPrompt,
            mediaPaths = mediaPaths,
            maxTokens = 256
        )
        Assert.assertEquals(testPrompt, params5.prompt)
        Assert.assertEquals(256, params5.maxTokens)
        Assert.assertEquals(mediaPaths, params5.mediaPaths)
    }

    @Test
    fun testLoraAdapter() {
        // Test default constructor
        val adapter1 = LlamaMobile.LoraAdapter(path = "/path/to/lora.gguf")
        Assert.assertEquals("/path/to/lora.gguf", adapter1.path)
        Assert.assertEquals(1.0f, adapter1.scale)

        // Test constructor with custom scale
        val adapter2 = LlamaMobile.LoraAdapter(path = "/path/to/lora.gguf", scale = 0.5f)
        Assert.assertEquals(0.5f, adapter2.scale)
    }

    @Test
    fun testErrorTypeEnum() {
        // Test all error types exist
        val errorTypes = LlamaMobile.ErrorType.values()
        Assert.assertEquals(11, errorTypes.size) // Should match number of enum values

        // Verify specific error types
        Assert.assertNotNull(LlamaMobile.ErrorType.CONTEXT_NOT_INITIALIZED)
        Assert.assertNotNull(LlamaMobile.ErrorType.INVALID_PARAMETER)
        Assert.assertNotNull(LlamaMobile.ErrorType.OPERATION_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.VOCODER_NOT_INITIALIZED)
        Assert.assertNotNull(LlamaMobile.ErrorType.MULTIMODAL_NOT_INITIALIZED)
        Assert.assertNotNull(LlamaMobile.ErrorType.MEDIA_PROCESSING_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.TOKENIZATION_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.DETOKENIZATION_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.EMBEDDING_GENERATION_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.AUDIO_GENERATION_FAILED)
        Assert.assertNotNull(LlamaMobile.ErrorType.CONVERSATION_FAILED)
    }

    @Test
    fun testTTSModelTypeEnum() {
        // Test all TTS model types exist
        val ttsTypes = LlamaMobile.TTSModelType.values()
        Assert.assertEquals(3, ttsTypes.size) // Should match number of enum values

        // Test fromInt conversion
        Assert.assertEquals(LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.TTSModelType.fromInt(0))
        Assert.assertEquals(LlamaMobile.TTSModelType.OUT_ETTS_V02, LlamaMobile.TTSModelType.fromInt(1))
        Assert.assertEquals(LlamaMobile.TTSModelType.OUT_ETTS_V03, LlamaMobile.TTSModelType.fromInt(2))
        Assert.assertEquals(LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.TTSModelType.fromInt(100)) // Invalid value
    }

    @Test
    fun testParameterImmutability() {
        // Test that parameters are immutable (data classes)
        val initParams = LlamaMobile.InitParams(TEST_MODEL_PATH)
        val completionParams = LlamaMobile.CompletionParams(prompt = "test")
        val loraAdapter = LlamaMobile.LoraAdapter(path = "/path/to/lora")

        // Verify objects can be created and properties accessed
        Assert.assertNotNull(initParams)
        Assert.assertNotNull(completionParams)
        Assert.assertNotNull(loraAdapter)
    }

    @Test
    fun testEdgeCases() {
        // Test empty strings
        val initParamsEmptyPath = LlamaMobile.InitParams("")
        Assert.assertEquals("", initParamsEmptyPath.modelPath)

        val completionParamsEmptyPrompt = LlamaMobile.CompletionParams(prompt = "")
        Assert.assertEquals("", completionParamsEmptyPrompt.prompt)

        // Test null values (should be handled gracefully)
        val initParamsWithNulls = LlamaMobile.InitParams(
            modelPath = TEST_MODEL_PATH,
            chatTemplate = null,
            systemPrompt = null
        )
        Assert.assertNull(initParamsWithNulls.chatTemplate)
        Assert.assertNull(initParamsWithNulls.systemPrompt)

        // Test with zero values
        val completionParamsWithZero = LlamaMobile.CompletionParams(
            prompt = testPrompt,
            maxTokens = 0,
            temperature = 0.0f,
            topK = 0
        )
        Assert.assertEquals(0, completionParamsWithZero.maxTokens)
        Assert.assertEquals(0.0f, completionParamsWithZero.temperature)
        Assert.assertEquals(0, completionParamsWithZero.topK)
    }

    @Test
    fun testMethodSafetyWithInvalidContext() {
        // Test that methods fail gracefully with invalid context (0L)
        val invalidContext = 0L

        // Test basic operations
        Assert.assertNull(LlamaMobile.generateCompletion(invalidContext, LlamaMobile.CompletionParams(prompt = "test")))
        Assert.assertNull(LlamaMobile.tokenize(invalidContext, "test"))
        Assert.assertNull(LlamaMobile.detokenize(invalidContext, intArrayOf(1, 2, 3)))
        Assert.assertNull(LlamaMobile.generateEmbeddings(invalidContext, "test"))

        // Test TTS operations
        Assert.assertFalse(LlamaMobile.isVocoderEnabled(invalidContext))
        Assert.assertFalse(LlamaMobile.initVocoder(invalidContext, "/path/to/vocoder.gguf"))
        Assert.assertNull(LlamaMobile.getFormattedAudioCompletion(invalidContext, "{}", "test"))
        Assert.assertNull(LlamaMobile.getAudioGuideTokens(invalidContext, "test"))
        Assert.assertNull(LlamaMobile.decodeAudioTokens(invalidContext, intArrayOf(1, 2, 3)))

        // Test LoRA operations
        Assert.assertFalse(LlamaMobile.applyLoraAdapters(invalidContext, arrayOf(LlamaMobile.LoraAdapter(path = ""))))
        Assert.assertNull(LlamaMobile.getLoadedLoraAdapters(invalidContext))

        // Test conversation operations
        Assert.assertNull(LlamaMobile.generateResponse(invalidContext, "test"))
        Assert.assertFalse(LlamaMobile.isConversationActive(invalidContext))

        // Test model info operations
        Assert.assertEquals(0, LlamaMobile.getContextWindowSize(invalidContext))
        Assert.assertEquals(0, LlamaMobile.getEmbeddingDimension(invalidContext))
        Assert.assertNull(LlamaMobile.getModelDescription(invalidContext))
        Assert.assertEquals(0L, LlamaMobile.getModelSize(invalidContext))
        Assert.assertEquals(0L, LlamaMobile.getModelParametersCount(invalidContext))
    }

    companion object {
        private const val testPrompt = "Hello, world!"
    }
}