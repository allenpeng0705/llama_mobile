package com.llamamobile

import android.content.Context
import android.content.res.AssetManager
import android.os.Build
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.*
import java.util.*

/**
 * Comprehensive instrumented tests for LlamaMobile Kotlin SDK
 * These tests run on an Android device or emulator.
 */
@RunWith(AndroidJUnit4::class)
class LlamaMobileComprehensiveTests {

    private lateinit var context: Context
    private lateinit var assetManager: AssetManager
    
    companion object TestPaths {
    }

    private lateinit var TEST_OUTPUT_DIR: String
    private lateinit var rootPath: String
    private lateinit var modelPath: String
    private lateinit var ttsModelPath: String
    private lateinit var altTTSModelPath: String
    private lateinit var vocoderPath: String
    private lateinit var embeddingPath: String
    private lateinit var mmprojPath: String
    private lateinit var loraPath: String
    private lateinit var imageModelPath: String
    private lateinit var imagePath: String

    @Before
    fun setUp() {
        context = InstrumentationRegistry.getInstrumentation().context
        assetManager = context.assets
        
        // Use internal device storage instead of sdcard
        val externalFilesDir = context.getExternalFilesDir(null)
        TEST_OUTPUT_DIR = File(externalFilesDir, "llama_mobile_test").absolutePath
        rootPath = File(externalFilesDir, "models").absolutePath
        
        // Model paths (will use internal device storage directory structure)
        modelPath = File(rootPath, "SmolVLM-256M-Instruct-Q8_0.gguf").absolutePath
        ttsModelPath = File(rootPath, "OuteTTS-0.2-500M-Q6_K.gguf").absolutePath
        altTTSModelPath = File(rootPath, "Qwen3-1.7B-Multilingual-TTS.Q5_K_M.gguf").absolutePath
        vocoderPath = File(rootPath, "WavTokenizer-Large-75-F16.gguf").absolutePath
        embeddingPath = File(rootPath, "embedding/Qwen3-Embedding-0.6B-Q8_0.gguf").absolutePath
        mmprojPath = File(rootPath, "mmproj-SmolVLM-256M-Instruct-Q8_0.gguf").absolutePath
        loraPath = File(rootPath, "lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf").absolutePath
        imageModelPath = File(rootPath, "SmolVLM-256M-Instruct-Q8_0.gguf").absolutePath
        imagePath = File(rootPath, "img/image.jpg").absolutePath
        
        // Create test output directory if it doesn't exist
        val outputDir = File(TEST_OUTPUT_DIR)
        if (!outputDir.exists()) {
            outputDir.mkdirs()
        }
        
        // Create model directory structure if it doesn't exist
        val modelDir = File(rootPath)
        if (!modelDir.exists()) {
            modelDir.mkdirs()
            // Create subdirectories
            File(rootPath, "embedding").mkdirs()
            File(rootPath, "lora").mkdirs()
            File(rootPath, "img").mkdirs()
        }
    }

    @Test
    fun testModelDirectoryAccess() {
        // Test that the model directory exists
        val modelDir = File(rootPath)
        if (!modelDir.exists()) {
            // If the directory doesn't exist, try to create it for future tests
            modelDir.mkdirs()
            System.err.println("Model directory created. Please place models at $rootPath")
        }
        
        // Test that we can list files in the directory (if it exists)
        if (modelDir.exists()) {
            val files = modelDir.listFiles()
            println("Files in model directory: ${files?.size ?: 0}")
            files?.forEach { file ->
                println("  - ${file.name}")
            }
        }
    }

    @Test
    fun testInitParamsConstructors() {
        // Test primary constructor
        val params1 = LlamaMobile.InitParams(modelPath)
        assertEquals(modelPath, params1.modelPath)
        assertEquals(2048, params1.nCtx)
        assertEquals(4, params1.nThreads)
        
        // Test secondary constructor
        val params2 = LlamaMobile.InitParams(modelPath, 8192)
        assertEquals(modelPath, params2.modelPath)
        assertEquals(8192, params2.nCtx)
        assertEquals(4, params2.nThreads)
    }

    @Test
    fun testCompletionParamsBuilder() {
        val prompt = "Hello, world!"
        val params = LlamaMobile.CompletionParams(prompt, 0.7f, 100)
        
        assertEquals(prompt, params.prompt)
        assertEquals(0.7f, params.temperature)
        assertEquals(100, params.maxTokens)
    }

    // Note: AudioParams test removed as it doesn't exist in current API

    @Test
    fun testLoraAdapterBuilder() {
        val adapter = LlamaMobile.LoraAdapter(loraPath, 0.8f)
        
        assertEquals(loraPath, adapter.path)
        assertEquals(0.8f, adapter.scale)
    }

    @Test
    fun testTTSModelType() {
        // Test TTSModelType enum values exist
        val unknownType = LlamaMobile.TTSModelType.UNKNOWN
        val outEttsV02Type = LlamaMobile.TTSModelType.OUT_ETTS_V02
        val outEttsV03Type = LlamaMobile.TTSModelType.OUT_ETTS_V03
        
        // Just ensure they can be referenced without errors
        assertNotNull(unknownType)
        assertNotNull(outEttsV02Type)
        assertNotNull(outEttsV03Type)
        
        // Test enum names
        assertEquals("UNKNOWN", unknownType.name)
        assertEquals("OUT_ETTS_V02", outEttsV02Type.name)
        assertEquals("OUT_ETTS_V03", outEttsV03Type.name)
    }

    @Test
    fun testErrorTypes() {
        // Test that all ErrorType enum values exist
        // Simply referencing them ensures they compile
        LlamaMobile.ErrorType.CONTEXT_NOT_INITIALIZED
        LlamaMobile.ErrorType.INVALID_PARAMETER
        LlamaMobile.ErrorType.OPERATION_FAILED
        LlamaMobile.ErrorType.VOCODER_NOT_INITIALIZED
        LlamaMobile.ErrorType.MULTIMODAL_NOT_INITIALIZED
        LlamaMobile.ErrorType.MEDIA_PROCESSING_FAILED
        LlamaMobile.ErrorType.TOKENIZATION_FAILED
        LlamaMobile.ErrorType.DETOKENIZATION_FAILED
        LlamaMobile.ErrorType.EMBEDDING_GENERATION_FAILED
        LlamaMobile.ErrorType.AUDIO_GENERATION_FAILED
        LlamaMobile.ErrorType.CONVERSATION_FAILED
    }

    @Test
    fun testTTSMethod() {
        // Test TTSMethod enum values exist
        val builtIn = LlamaMobile.TTSMethod.BUILT_IN
        val customWorkflow = LlamaMobile.TTSMethod.CUSTOM_WORKFLOW
        
        assertNotNull(builtIn)
        assertNotNull(customWorkflow)
        
        assertEquals("BUILT_IN", builtIn.name)
        assertEquals("CUSTOM_WORKFLOW", customWorkflow.name)
    }

    @Test
    fun testCacheType() {
        // Test CacheType enum values exist
        val none = LlamaMobile.CacheType.NONE
        val memory = LlamaMobile.CacheType.MEMORY
        
        assertNotNull(none)
        assertNotNull(memory)
        
        assertEquals("NONE", none.name)
        assertEquals("MEMORY", memory.name)
    }

    @Test
    fun testTTSOptions() {
        // Test default constructor
        val options1 = LlamaMobile.TTSOptions()
        assertEquals(24000, options1.sampleRate)
        assertNull(options1.voice)
        assertEquals(1.0f, options1.speed, 0.001f)
        assertFalse(options1.isSaveToFile)
        assertNull(options1.outputFilePath)
        
        // Test builder with all parameters
        val options2 = LlamaMobile.TTSOptions.Builder()
            .sampleRate(48000)
            .voice("custom_voice")
            .speed(1.5f)
            .saveToFile(true)
            .outputFilePath("/path/to/output.wav")
            .build()
        
        assertEquals(48000, options2.sampleRate)
        assertEquals("custom_voice", options2.voice)
        assertEquals(1.5f, options2.speed, 0.001f)
        assertTrue(options2.isSaveToFile)
        assertEquals("/path/to/output.wav", options2.outputFilePath)
    }

    @Test
    fun testSpeechResult() {
        val audioSamples = shortArrayOf(100, 200, 300, 400, 500)
        val result = LlamaMobile.SpeechResult(
            audioSamples,
            48000,
            0.125,
            "/path/to/output.wav",
            LlamaMobile.TTSMethod.BUILT_IN
        )
        
        assertEquals(5, result.audioSamples.size)
        assertEquals(48000, result.sampleRate)
        assertEquals(0.125, result.duration, 0.001)
        assertEquals("/path/to/output.wav", result.outputFilePath)
        assertEquals(LlamaMobile.TTSMethod.BUILT_IN, result.methodUsed)
    }

    @Test
    fun testSpeechMetadata() {
        val metadata = LlamaMobile.SpeechMetadata(
            24000,
            1.5,
            LlamaMobile.TTSMethod.BUILT_IN,
            "/path/to/output.wav"
        )
        
        assertEquals(24000, metadata.sampleRate)
        assertEquals(1.5, metadata.duration, 0.001)
        assertEquals(LlamaMobile.TTSMethod.BUILT_IN, metadata.methodUsed)
        assertEquals("/path/to/output.wav", metadata.outputFilePath)
    }

    // ==================== Context Management Tests ====================

    @Test
    fun testContextCreationAndRelease() {
        // Test context creation with invalid path (should fail)
        val invalidParams = LlamaMobile.InitParams("/invalid/path/model.gguf")
        val invalidContext = LlamaMobile.initContext(invalidParams)
        assertEquals(0, invalidContext)

        // Test context creation parameters
        val params = LlamaMobile.InitParams(modelPath)
        assertNotNull(params)
        assertEquals(modelPath, params.modelPath)
        assertEquals(2048, params.nCtx)
        assertEquals(4, params.nThreads)
    }

    @Test
    fun testInitParamsFactories() {
        // Test GPU factory
        val gpuParams = LlamaMobile.InitParams.gpu(modelPath, 4, 4096)
        assertEquals(modelPath, gpuParams.modelPath)
        assertEquals(4096, gpuParams.nCtx)
        assertEquals(4, gpuParams.nGpuLayers)

        // Test embedding factory
        val embeddingParams = LlamaMobile.InitParams.embedding(modelPath, 1)
        assertEquals(modelPath, embeddingParams.modelPath)
        assertTrue(embeddingParams.isEmbedding)
        assertEquals(1, embeddingParams.poolingType)
    }

    // ==================== Text Generation Tests ====================

    @Test
    fun testCompletionParamsFactories() {
        // Test creative factory
        val creativeParams = LlamaMobile.CompletionParams.creative("Hello", 200)
        assertEquals("Hello", creativeParams.prompt)
        assertEquals(1.0f, creativeParams.temperature)
        assertEquals(200, creativeParams.maxTokens)

        // Test factual factory
        val factualParams = LlamaMobile.CompletionParams.factual("Hello")
        assertEquals("Hello", factualParams.prompt)
        assertEquals(0.1f, factualParams.temperature)

        // Test chat factory with messages
        val messages = listOf(
            LlamaMobile.ChatMessage("user", "Hello")
        )
        val chatParams = LlamaMobile.CompletionParams.chat(messages, 100)
        assertEquals(100, chatParams.maxTokens)
        assertEquals(1, chatParams.chatMessages.size)

        // Test chat factory with raw prompt
        val chatPromptParams = LlamaMobile.CompletionParams.chat("Hello", 100)
        assertEquals("Hello", chatPromptParams.prompt)
        assertEquals(100, chatPromptParams.maxTokens)

        // Test multimodal factory
        val mediaPaths = listOf(imagePath)
        val multimodalParams = LlamaMobile.CompletionParams.multimodal("Describe this image", mediaPaths, 100)
        assertEquals("Describe this image", multimodalParams.prompt)
        assertEquals(1, multimodalParams.mediaPaths.size)

        // Test JSON output factory
        val jsonParams = LlamaMobile.CompletionParams.jsonOutput("Generate JSON", 100)
        assertEquals("Generate JSON", jsonParams.prompt)
        assertTrue(jsonParams.isUseJsonResponse)
    }

    @Test
    fun testCompletionParamsFromOpenAIJSON() {
        val openAIJson = "{" +
            "\"messages\": [" +
            "{\"role\": \"system\", \"content\": \"You are a helpful assistant\"}," +
            "{\"role\": \"user\", \"content\": \"Hello\"}" +
            "]}"
        
        try {
            val params = LlamaMobile.CompletionParams.fromOpenAIJSON(openAIJson)
            assertNotNull(params)
        } catch (e: Exception) {
            fail("Failed to parse OpenAI JSON: ${e.message}")
        }
    }

    // ==================== Tokenization Tests ====================

    @Test
    fun testTokenization() {
        // Test tokenization with invalid context (should return null)
        val tokens = LlamaMobile.tokenize(0, "Hello world")
        assertNull(tokens)

        // Test detokenization with invalid context (should return null)
        val text = LlamaMobile.detokenize(0, intArrayOf(1, 2, 3))
        assertNull(text)
    }

    // ==================== Embeddings Tests ====================

    @Test
    fun testEmbeddings() {
        // Test embedding generation with invalid context (should return null)
        val embeddings = LlamaMobile.generateEmbeddings(0, "Hello world")
        assertNull(embeddings)
    }

    // ==================== Multimodal Tests ====================

    @Test
    fun testMultimodal() {
        // Test multimodal initialization with invalid context (should return false)
        val result = LlamaMobile.initMultimodal(0, mmprojPath, true)
        assertFalse(result)

        // Test multimodal status with invalid context (should return false)
        assertFalse(LlamaMobile.isMultimodalEnabled(0))
        assertFalse(LlamaMobile.supportsVision(0))
        assertFalse(LlamaMobile.supportsAudio(0))

        // Test multimodal release (should not crash)
        LlamaMobile.releaseMultimodal(0)
    }

    // ==================== TTS Tests ====================

    @Test
    fun testVocoder() {
        // Test vocoder initialization with invalid context (should return false)
        val result = LlamaMobile.initVocoder(0, vocoderPath)
        assertFalse(result)

        // Test vocoder status with invalid context (should return false)
        assertFalse(LlamaMobile.isVocoderEnabled(0))

        // Test TTS type with invalid context (should return UNKNOWN)
        val ttsType = LlamaMobile.getTTSType(0)
        assertEquals(LlamaMobile.TTSModelType.UNKNOWN, ttsType)

        // Test vocoder release (should not crash)
        LlamaMobile.releaseVocoder(0)
    }

    @Test
    fun testSpeechGeneration() {
        // Test audio generation with invalid context (should return null)
        val audio = LlamaMobile.generateAudioFromText(0, "Hello", null)
        assertNull(audio)

        // Test speech generation with invalid context (should return failure)
        val result = LlamaMobile.generateSpeech(0, "Hello")
        assertNotNull(result)
        assertTrue(result.isFailure)

        // Test speech stream with invalid context (should return failure)
        val streamResult = LlamaMobile.generateSpeechStream(0, "Hello", {})
        assertNotNull(streamResult)
        assertTrue(streamResult.isFailure)
    }

    @Test
    fun testTTSOptionsBuilder() {
        val options = LlamaMobile.TTSOptions.Builder()
            .sampleRate(48000)
            .voice("custom")
            .speed(1.5f)
            .saveToFile(true)
            .outputFilePath("/test/output.wav")
            .build()
        
        assertEquals(48000, options.sampleRate)
        assertEquals("custom", options.voice)
        assertEquals(1.5f, options.speed, 0.001f)
        assertTrue(options.isSaveToFile)
        assertEquals("/test/output.wav", options.outputFilePath)
    }

    // ==================== LoRA Tests ====================

    @Test
    fun testLoraAdapters() {
        // Test LoRA adapter creation
        val adapter = LlamaMobile.LoraAdapter(loraPath, 0.8f)
        assertEquals(loraPath, adapter.path)
        assertEquals(0.8f, adapter.scale)

        // Test LoRA application with invalid context (should return false)
        val adapters = arrayOf(adapter)
        val result = LlamaMobile.applyLoraAdapters(0, adapters)
        assertFalse(result)

        // Test LoRA removal (should not crash)
        LlamaMobile.removeLoraAdapters(0)

        // Test get loaded LoRA adapters (should return null)
        val loadedAdapters = LlamaMobile.getLoadedLoraAdapters(0)
        assertNull(loadedAdapters)
    }

    // ==================== Utility Tests ====================

    @Test
    fun testLoadGrammar() {
        // Test load grammar with null path (should return null)
        val grammar1 = LlamaMobile.loadGrammar(null)
        assertNull(grammar1)

        // Test load grammar with empty path (should return null)
        val grammar2 = LlamaMobile.loadGrammar("")
        assertNull(grammar2)

        // Test load grammar with invalid path (should return null)
        val grammar3 = LlamaMobile.loadGrammar("/invalid/path/grammar.gbnf")
        assertNull(grammar3)
    }

    // ==================== Download Tests ====================

    @Test
    fun testDownloadParams() {
        val params = LlamaMobile.DownloadParams.Builder(
            "facebook/opt-125m",
            "model.safetensors",
            "/test/download/path"
        )
            .bearerToken("test-token")
            .offline(true)
            .build()
        
        assertEquals("facebook/opt-125m", params.repoId)
        assertEquals("model.safetensors", params.filename)
        assertEquals("/test/download/path", params.destinationPath)
        assertEquals("test-token", params.bearerToken)
        assertTrue(params.isOffline)
    }

    // ==================== Error Handling Tests ====================

    @Test
    fun testTTSErrors() {
        val noModelError = LlamaMobile.TTSError.noModelLoaded()
        assertNotNull(noModelError)

        val noVocoderError = LlamaMobile.TTSError.noVocoderEnabled()
        assertNotNull(noVocoderError)

        val invalidTextError = LlamaMobile.TTSError.invalidText()
        assertNotNull(invalidTextError)

        val generationFailedError = LlamaMobile.TTSError.generationFailed()
        assertNotNull(generationFailedError)

        val formattingFailedError = LlamaMobile.TTSError.formattingFailed()
        assertNotNull(formattingFailedError)

        val tokenizationFailedError = LlamaMobile.TTSError.tokenizationFailed()
        assertNotNull(tokenizationFailedError)

        val audioDecodingFailedError = LlamaMobile.TTSError.audioDecodingFailed()
        assertNotNull(audioDecodingFailedError)

        val fileSaveFailedError = LlamaMobile.TTSError.fileSaveFailed()
        assertNotNull(fileSaveFailedError)

        val unknownError = LlamaMobile.TTSError.unknownError("Test error")
        assertNotNull(unknownError)
    }

    @Test
    fun testResultClass() {
        // Test success result
        val successResult = LlamaMobile.Result.success<String, String>("Test success")
        assertTrue(successResult.isSuccess)
        assertFalse(successResult.isFailure)
        assertEquals("Test success", successResult.value)
        assertNull(successResult.error)

        // Test failure result
        val failureResult = LlamaMobile.Result.failure<String, String>("Test failure")
        assertFalse(failureResult.isSuccess)
        assertTrue(failureResult.isFailure)
        assertNull(failureResult.value)
        assertEquals("Test failure", failureResult.error)
    }

    // ==================== Chat Message Tests ====================

    @Test
    fun testChatMessage() {
        // Test basic chat message
        val basicMessage = LlamaMobile.ChatMessage("user", "Hello")
        assertEquals("user", basicMessage.role)
        assertEquals("Hello", basicMessage.content)
        assertNull(basicMessage.reasoningContent)
        assertNull(basicMessage.toolName)
        assertNull(basicMessage.toolCallId)

        // Test chat message with all parameters
        val fullMessage = LlamaMobile.ChatMessage(
            "assistant",
            "Hello",
            "Thinking",
            "test-tool",
            "tool-123"
        )
        assertEquals("assistant", fullMessage.role)
        assertEquals("Hello", fullMessage.content)
        assertEquals("Thinking", fullMessage.reasoningContent)
        assertEquals("test-tool", fullMessage.toolName)
        assertEquals("tool-123", fullMessage.toolCallId)
    }

    // ==================== Callback Tests ====================

    @Test
    fun testCallbacks() {
        // Test token callback
        val tokenCallback = object : LlamaMobile.TokenCallback {
            override fun onToken(token: String): Boolean {
                return true
            }
        }
        assertNotNull(tokenCallback)

        // Test progress callback
        val progressCallback = object : LlamaMobile.ProgressCallback {
            override fun onProgress(progress: Float) {
                // Do nothing
            }
        }
        assertNotNull(progressCallback)

        // Test download progress callback
        val downloadCallback = object : LlamaMobile.DownloadProgressCallback {
            override fun onProgress(progress: Float, status: String, downloadedBytes: Long, totalBytes: Long) {
                // Do nothing
            }
        }
        assertNotNull(downloadCallback)

        // Test audio chunk callback
        val audioCallback = object : LlamaMobile.AudioChunkCallback {
            override fun onAudioChunk(audioChunk: ShortArray) {
                // Do nothing
            }
        }
        assertNotNull(audioCallback)
    }
}
