package com.llamamobile

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.util.*

/**
 * Instrumented tests for LlamaMobile Kotlin SDK
 */
@RunWith(AndroidJUnit4::class)
class LlamaMobileInstrumentedTests {
    private val TAG = "LlamaMobileInstrumentedTests"
    private val TEST_MODEL_PATH = "/sdcard/test/model.gguf"
    private var contextHandle: Long = 0
    private lateinit var appContext: Context

    @Before
    fun setUp() {
        // Get the application context for instrumentation tests
        appContext = InstrumentationRegistry.getInstrumentation().targetContext
        contextHandle = 0
    }

    @After
    fun tearDown() {
        // Clean up any resources and release context
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = 0
        }

        // Clean up test model file if it exists
        val testModelFile = File(TEST_MODEL_PATH)
        if (testModelFile.exists()) {
            testModelFile.delete()
        }
    }

    @Test
    fun testContextInitializationWithInvalidPath() {
        // Test context initialization with invalid path (should fail gracefully)
        val params = LlamaMobile.InitParams(TEST_MODEL_PATH)
        contextHandle = LlamaMobile.initContext(params)
        Assert.assertEquals(0L, contextHandle) // Should fail but not crash
    }

    @Test
    fun testContextLifecycle() {
        // Test context initialization and release sequence
        val params = LlamaMobile.InitParams(TEST_MODEL_PATH)
        contextHandle = LlamaMobile.initContext(params)
        
        // Should fail with invalid path
        Assert.assertEquals(0L, contextHandle)
        
        // Try to release invalid handle (should not crash)
        LlamaMobile.releaseContext(0L)
        LlamaMobile.releaseContext(12345L)
    }

    @Test
    fun testCompletionParameters() {
        // Test completion parameters with various configurations
        val params1 = LlamaMobile.CompletionParams(prompt = "Hello, world!")
        Assert.assertEquals("Hello, world!", params1.prompt)
        Assert.assertEquals(128, params1.maxTokens)
        Assert.assertEquals(0.8f, params1.temperature)
        
        val params2 = LlamaMobile.CompletionParams(
            prompt = "Hello, world!",
            maxTokens = 256,
            temperature = 0.5f,
            topK = 50,
            topP = 0.9f,
            minP = 0.1f,
            penaltyRepeat = 1.2f,
            ignoreEos = true,
            stopSequences = listOf("END", "\n"),
            mediaPaths = listOf("/path/to/image.jpg")
        )
        Assert.assertEquals(256, params2.maxTokens)
        Assert.assertEquals(0.5f, params2.temperature)
        Assert.assertEquals(50, params2.topK)
        Assert.assertEquals(0.9f, params2.topP)
        Assert.assertEquals(0.1f, params2.minP)
        Assert.assertEquals(1.2f, params2.penaltyRepeat)
        Assert.assertTrue(params2.ignoreEos)
        Assert.assertEquals(listOf("END", "\n"), params2.stopSequences)
        Assert.assertEquals(listOf("/path/to/image.jpg"), params2.mediaPaths)
    }

    @Test
    fun testCompletionWithDifferentMirostatValues() {
        // Test different mirostat values (0, 1, 2)
        val params0 = LlamaMobile.CompletionParams(
            prompt = "Test mirostat 0",
            mirostat = 0
        )
        Assert.assertEquals(0, params0.mirostat)
        
        val params1 = LlamaMobile.CompletionParams(
            prompt = "Test mirostat 1",
            mirostat = 1
        )
        Assert.assertEquals(1, params1.mirostat)
        
        val params2 = LlamaMobile.CompletionParams(
            prompt = "Test mirostat 2",
            mirostat = 2
        )
        Assert.assertEquals(2, params2.mirostat)
        
        // Test that completion fails gracefully with invalid context
        Assert.assertNull(LlamaMobile.generateCompletion(0L, params0))
        Assert.assertNull(LlamaMobile.generateCompletion(0L, params1))
        Assert.assertNull(LlamaMobile.generateCompletion(0L, params2))
    }

    @Test
    fun testCompletionWithStopSequences() {
        // Create completion params with stop sequences
        val stopSequences = listOf("\n", ".", "END")
        val params = LlamaMobile.CompletionParams(
            prompt = "Test with stop sequences",
            stopSequences = stopSequences
        )
        
        // Verify stop sequences were set correctly
        Assert.assertEquals(3, params.stopSequences.size)
        Assert.assertTrue(params.stopSequences.contains("\n"))
        Assert.assertTrue(params.stopSequences.contains("."))
        Assert.assertTrue(params.stopSequences.contains("END"))
        
        // Test completion fails gracefully with invalid context
        Assert.assertNull(LlamaMobile.generateCompletion(0L, params))
    }

    @Test
    fun testMultimodalCompletion() {
        // Test multimodal completion params
        val mediaPaths = listOf("/path/to/image.jpg", "/path/to/audio.wav")
        val params = LlamaMobile.CompletionParams(
            multimodalPrompt = "What's in this image?",
            mediaPaths = mediaPaths
        )
        
        Assert.assertEquals("What's in this image?", params.prompt)
        Assert.assertEquals(mediaPaths, params.mediaPaths)
        
        // Test fails gracefully with invalid context
        Assert.assertNull(LlamaMobile.generateCompletion(0L, params))
        
        // Test deprecated API for backward compatibility
        Assert.assertNull(LlamaMobile.generateMultimodalCompletion(with = params, mediaPaths = mediaPaths))
    }

    @Test
    fun testConversationAPI() {
        // Test conversation methods fail gracefully with invalid context
        Assert.assertNull(LlamaMobile.generateResponse(0L, "Hello, how are you?"))
        Assert.assertNull(LlamaMobile.generateResponse(0L, "Hello, how are you?", maxTokens = 100))
        
        // Test with token callback
        var tokenCount = 0
        val callback: (String) -> Boolean = { _ -> 
            tokenCount++
            true 
        }
        
        Assert.assertNull(LlamaMobile.generateResponse(0L, "Hello, how are you?", tokenCallback = callback))
        Assert.assertEquals(0, tokenCount) // No tokens should be received with invalid context
        
        // Test conversation control methods
        LlamaMobile.clearConversation(0L) // Should not crash
        Assert.assertFalse(LlamaMobile.isConversationActive(0L)) // Should return false with invalid context
    }

    @Test
    fun testTTSAPI() {
        // Test TTS methods fail gracefully with invalid context
        Assert.assertFalse(LlamaMobile.initVocoder(0L, "invalid/path/to/vocoder.gguf"))
        Assert.assertFalse(LlamaMobile.isVocoderEnabled(0L))
        Assert.assertEquals(LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.getTTSType(0L))
        Assert.assertNull(LlamaMobile.getFormattedAudioCompletion(0L, "{}", "Hello"))
        Assert.assertNull(LlamaMobile.getAudioGuideTokens(0L, "Hello"))
        Assert.assertNull(LlamaMobile.decodeAudioTokens(0L, intArrayOf(1, 2, 3)))
        Assert.assertNull(LlamaMobile.generateAudioFromText(0L, "Hello"))
        
        // Test with custom speaker
        Assert.assertNull(LlamaMobile.generateAudioFromText(0L, "Hello", speakerJson = "{\"speaker\": \"female\"}"))
    }

    @Test
    fun testLoRAAdapters() {
        // Test LoRA adapter methods
        val adapter = LlamaMobile.LoraAdapter(path = "/path/to/lora.gguf", scale = 0.8f)
        Assert.assertEquals("/path/to/lora.gguf", adapter.path)
        Assert.assertEquals(0.8f, adapter.scale)
        
        // Test methods fail gracefully with invalid context
        Assert.assertFalse(LlamaMobile.applyLoraAdapters(0L, arrayOf(adapter)))
        Assert.assertNull(LlamaMobile.getLoadedLoraAdapters(0L))
        LlamaMobile.removeLoraAdapters(0L) // Should not crash
    }

    @Test
    fun testModelInformationMethods() {
        // Test model information methods
        Assert.assertEquals(0, LlamaMobile.getContextWindowSize(0L))
        Assert.assertEquals(0, LlamaMobile.getEmbeddingDimension(0L))
        Assert.assertNull(LlamaMobile.getModelDescription(0L))
        Assert.assertEquals(0L, LlamaMobile.getModelSize(0L))
        Assert.assertEquals(0L, LlamaMobile.getModelParametersCount(0L))
    }

    @Test
    fun testMultimodalSupportMethods() {
        // Test multimodal support methods fail gracefully
        Assert.assertFalse(LlamaMobile.initMultimodal(0L, "/path/to/mmproj.bin"))
        Assert.assertFalse(LlamaMobile.isMultimodalEnabled(0L))
        Assert.assertFalse(LlamaMobile.supportsVision(0L))
        Assert.assertFalse(LlamaMobile.supportsAudio(0L))
        LlamaMobile.releaseMultimodal(0L) // Should not crash
    }

    @Test
    fun testDownloadMethod() {
        // Test download method with various parameters
        val params = LlamaMobile.DownloadParams(
            url = "https://huggingface.co/invalid/model",
            localPath = "/tmp/test/model.gguf",
            password = "test123"
        )
        
        Assert.assertEquals("https://huggingface.co/invalid/model", params.url)
        Assert.assertEquals("/tmp/test/model.gguf", params.localPath)
        Assert.assertEquals("test123", params.password)
        
        // Test that download fails gracefully
        val result = LlamaMobile.download(with = params)
        Assert.assertNotNull(result)
        Assert.assertFalse(result!!.success)
        Assert.assertEquals("/tmp/test/model.gguf", result.localPath)
    }
}