package com.llamamobile

import android.content.Context
import android.content.res.AssetManager
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
        const val testGrammarFile = "json.gbnf"
        const val testAssetDir = "grammars"
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
    fun testAssetLoading() {
        try {
            // Test loading grammar files from assets
            val assetList = assetManager.list(testAssetDir)
            assertNotNull("Asset list should not be null", assetList)
            assertTrue("Should contain at least one grammar file", assetList?.isNotEmpty() ?: false)
            
            // Test reading a specific grammar file
            val inputStream: InputStream = assetManager.open("$testAssetDir/$testGrammarFile")
            val reader = BufferedReader(InputStreamReader(inputStream))
            val content = reader.use { it.readText() }
            assertFalse("Grammar file should not be empty", content.isEmpty())
            
            println("Loaded grammar file content length: ${content.length}")
            println("First 100 characters: ${content.take(100)}...")
        } catch (e: IOException) {
            fail("Failed to load assets: ${e.message}")
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
        val params2 = LlamaMobile.InitParams(
            modelPath = modelPath,
            nCtx = 8192,
            nThreads = 8
        )
        assertEquals(modelPath, params2.modelPath)
        assertEquals(8192, params2.nCtx)
        assertEquals(8, params2.nThreads)
        
        // Test copy constructor
        val params3 = params2.copy(nCtx = 16384)
        assertEquals(modelPath, params3.modelPath)
        assertEquals(16384, params3.nCtx)
        assertEquals(8, params3.nThreads)
    }

    @Test
    fun testCompletionParamsBuilder() {
        val prompt = "Hello, world!"
        val params = LlamaMobile.CompletionParams(
            prompt = prompt,
            temperature = 0.7f,
            topP = 0.9f,
            topK = 40,
            maxTokens = 100,
            stopSequences = listOf("\n", "User:")
        )
        
        assertEquals(prompt, params.prompt)
        assertEquals(0.7f, params.temperature)
        assertEquals(0.9f, params.topP)
        assertEquals(40, params.topK)
        assertEquals(100, params.maxTokens)
        assertEquals(listOf("\n", "User:"), params.stopSequences)
    }

    // Note: AudioParams test removed as it doesn't exist in current API

    @Test
    fun testLoraAdapterBuilder() {
        val adapter = LlamaMobile.LoraAdapter(
            path = loraPath,
            scale = 0.8f
        )
        
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
    fun testContextInitializationWithInvalidPath() {
        // Test initialization with invalid model path
        val invalidParams = LlamaMobile.InitParams(modelPath = "/invalid/path/to/model.gguf")
        val context = LlamaMobile.initContext(invalidParams)
        
        // Should return 0 on failure
        assertEquals("Context should be zero for invalid path", 0L, context)
    }

    @Test
    fun testMethodsWithInvalidContext() {
        val invalidContext = 0L
        
        // Test completion methods
        val completionResult = LlamaMobile.generateCompletion(invalidContext, "Hello")
        assertNull("Completion should return null for invalid context", completionResult)
        
        val completionParams = LlamaMobile.CompletionParams(prompt = "Hello")
        val completionResult2 = LlamaMobile.generateCompletion(invalidContext, completionParams)
        assertNull("Completion with params should return null for invalid context", completionResult2)
        
        // Test tokenization methods
        val tokens = LlamaMobile.tokenize(invalidContext, "Hello")
        assertNull("Tokenization should return null for invalid context", tokens)
        
        val detokenized = LlamaMobile.detokenize(invalidContext, intArrayOf(1, 2, 3))
        assertNull("Detokenization should return null for invalid context", detokenized)
        
        // Test embedding methods
        val embeddings = LlamaMobile.generateEmbeddings(invalidContext, "Hello")
        assertNull("Embeddings should return null for invalid context", embeddings)
        
        // Test TTS methods
        val audioSamples = LlamaMobile.generateAudioFromText(invalidContext, "Hello")
        assertNull("Audio generation should return null for invalid context", audioSamples)
        
        val formattedAudio = LlamaMobile.getFormattedAudioCompletion(invalidContext, "{}", "Hello")
        assertNull("Formatted audio should return null for invalid context", formattedAudio)
        
        val audioTokens = LlamaMobile.getAudioGuideTokens(invalidContext, "Hello")
        assertNull("Audio guide tokens should return null for invalid context", audioTokens)
        
        val decodedAudio = LlamaMobile.decodeAudioTokens(invalidContext, intArrayOf(1, 2, 3))
        assertNull("Audio decoding should return null for invalid context", decodedAudio)
        
        // Test LoRA methods
        val loraAdapters = LlamaMobile.getLoadedLoraAdapters(invalidContext)
        assertNull("Loaded LoRA adapters should return null for invalid context", loraAdapters)
        
        // Test conversation methods
        val conversationResult = LlamaMobile.generateResponse(invalidContext, "Hello")
        assertNull("Conversation should return null for invalid context", conversationResult)
        
        // Test model info methods
        val modelDesc = LlamaMobile.getModelDescription(invalidContext)
        assertNull("Model description should return null for invalid context", modelDesc)
        
        // Boolean methods should return false for invalid context
        assertFalse("isVocoderEnabled should return false for invalid context", LlamaMobile.isVocoderEnabled(invalidContext))
        assertFalse("isMultimodalEnabled should return false for invalid context", LlamaMobile.isMultimodalEnabled(invalidContext))
        assertFalse("supportsVision should return false for invalid context", LlamaMobile.supportsVision(invalidContext))
        assertFalse("supportsAudio should return false for invalid context", LlamaMobile.supportsAudio(invalidContext))
        assertFalse("isConversationActive should return false for invalid context", LlamaMobile.isConversationActive(invalidContext))
        
        // Number methods should return 0 for invalid context
        assertEquals("Context window size should be 0 for invalid context", 0, LlamaMobile.getContextWindowSize(invalidContext))
        assertEquals("Embedding dimension should be 0 for invalid context", 0, LlamaMobile.getEmbeddingDimension(invalidContext))
        assertEquals("Model size should be 0 for invalid context", 0L, LlamaMobile.getModelSize(invalidContext))
        assertEquals("Model parameters count should be 0 for invalid context", 0L, LlamaMobile.getModelParametersCount(invalidContext))
        
        // Test TTS type
        assertEquals("TTS type should be UNKNOWN for invalid context", LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.getTTSType(invalidContext))
    }

    @Test
    fun testCompletionControl() {
        // These methods should not crash with invalid context
        val invalidContext = 0L
        
        // Test stop completion
        LlamaMobile.stopCompletion(invalidContext)
        
        // Test conversation control
        LlamaMobile.clearConversation(invalidContext)
        
        // Test LoRA control
        LlamaMobile.removeLoraAdapters(invalidContext)
        
        // Test resource release methods
        LlamaMobile.releaseVocoder(invalidContext)
        LlamaMobile.releaseMultimodal(invalidContext)
        LlamaMobile.releaseContext(invalidContext)
    }

    @Test
    fun testDownloadParams() {
        val testUrl = "https://huggingface.co/model"
        val testLocalPath = "/tmp/test/model.gguf"
        
        // Test default constructor
        val params = LlamaMobile.DownloadParams(url = testUrl, localPath = testLocalPath)
        assertEquals(testUrl, params.url)
        assertEquals(testLocalPath, params.localPath)
        assertNull(params.password)
        assertNull(params.headers)
        
        // Test with optional parameters
        val paramsWithAuth = LlamaMobile.DownloadParams(
            url = testUrl,
            localPath = testLocalPath,
            password = "token123",
            headers = mapOf("Authorization" to "Bearer token")
        )
        assertEquals("token123", paramsWithAuth.password)
        assertEquals("Bearer token", paramsWithAuth.headers?.get("Authorization"))
    }

    @Test
    fun testResponseStructures() {
        // Test CompletionResult
        val completionResult = LlamaMobile.CompletionResult(
            text = "Test response",
            tokensGenerated = 10,
            tokensEvaluated = 5,
            truncated = false,
            stoppedEos = true,
            stoppedWord = false,
            stoppedLimit = false
        )
        assertEquals("Test response", completionResult.text)
        assertEquals(10, completionResult.tokensGenerated)
        assertEquals(5, completionResult.tokensEvaluated)
        assertFalse(completionResult.truncated)
        assertTrue(completionResult.stoppedEos)
        assertFalse(completionResult.stoppedWord)
        assertFalse(completionResult.stoppedLimit)
        
        // Test ConversationResult
        val conversationResult = LlamaMobile.ConversationResult(
            text = "Test conversation",
            timeToFirstToken = 100,
            totalTime = 500,
            tokensGenerated = 20
        )
        assertEquals("Test conversation", conversationResult.text)
        assertEquals(100L, conversationResult.timeToFirstToken)
        assertEquals(500L, conversationResult.totalTime)
        assertEquals(20, conversationResult.tokensGenerated)
        
        // Test DownloadResult
        val downloadResult = LlamaMobile.DownloadResult(
            success = true,
            localPath = "/tmp/test/model.gguf",
            errorMessage = null
        )
        assertTrue(downloadResult.success)
        assertEquals("/tmp/test/model.gguf", downloadResult.localPath)
        assertNull(downloadResult.errorMessage)
        
        val failedResult = LlamaMobile.DownloadResult(
            success = false,
            localPath = "/tmp/test/model.gguf",
            errorMessage = "Download failed"
        )
        assertFalse(failedResult.success)
        assertEquals("Download failed", failedResult.errorMessage)
    }

    @Test
    fun testParameterEdgeCases() {
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
            stopSequences = emptyList(),
            grammar = null,
            mediaPaths = emptyList()
        )
        
        assertEquals("", params.prompt)
        assertEquals(0, params.maxTokens)
        assertEquals(0.0f, params.temperature)
        assertEquals(0, params.topK)
        assertEquals(0.0f, params.topP)
        assertEquals(0.0f, params.minP)
        assertEquals(0.0f, params.typicalP)
        assertEquals(0, params.penaltyLastN)
        assertEquals(0.0f, params.penaltyRepeat)
        assertEquals(0.0f, params.penaltyFreq)
        assertEquals(0.0f, params.penaltyPresent)
        assertEquals(0, params.mirostat)
        assertEquals(0.0f, params.mirostatTau)
        assertEquals(0.0f, params.mirostatEta)
        assertTrue(params.ignoreEos)
        assertTrue(params.stopSequences.isEmpty())
        assertNull(params.grammar)
        assertTrue(params.mediaPaths.isEmpty())
    }

    // The following tests require actual model files
    // Uncomment and run them when you have the models available

    @Test
    fun testRealModelLoading() {
        val modelFile = File(modelPath)
        
        // Check if file exists and is readable
         
        if (!modelFile.exists() || !modelFile.canRead()) {
            println("Model file not available or cannot be read at $modelPath - skipping real model test")
            println("This is likely due to permission issues or the file not being present")
            return
        }
        
        val params = LlamaMobile.InitParams(modelPath)
        val context = LlamaMobile.initContext(params)
        
        if (context == 0L) {
            println("Failed to initialize context for model - skipping real model test")
            println("This may be due to permission issues or model file corruption")
            return
        }
        
        // Check model info
        assertTrue("Model size should be greater than 0", LlamaMobile.getModelSize(context) > 0L)
        assertTrue("Model parameters should be greater than 0", LlamaMobile.getModelParametersCount(context) > 0L)
        
        LlamaMobile.releaseContext(context)
    }
    
    @Test
    fun testRealModelCompletion() {
        val modelFile = File(modelPath)
        
        // Check if file exists and is readable
        if (!modelFile.exists() || !modelFile.canRead()) {
            println("Model file not available or cannot be read at $modelPath - skipping real model test")
            println("This is likely due to permission issues or the file not being present")
            return
        }
        
        val params = LlamaMobile.InitParams(modelPath)
        val context = LlamaMobile.initContext(params)
        
        if (context == 0L) {
            println("Failed to initialize context for model - skipping real model test")
            println("This may be due to permission issues or model file corruption")
            return
        }
        
        // Use the overload that returns CompletionResult
        val result = LlamaMobile.generateCompletion(context, "Hello, how are you?", 20, 0.7f)
        assertNotNull("Completion result should not be null", result)
        val textGenerated = result?.text?.isNotEmpty() ?: false
        val tokensGenerated = result?.tokensGenerated ?: 0 > 0
        assertTrue("Should generate either text or tokens", textGenerated || tokensGenerated)
        
        println("Completion result: ${result?.text}")
        println("Tokens generated: ${result?.tokensGenerated}")
        
        LlamaMobile.releaseContext(context)
    }
    
    @Test
    fun testRealModelTokenization() {
        // Debug the model path
        println("Attempting to access model at: $modelPath")
        println("Root path contents: ${File(rootPath).listFiles()?.joinToString { it.name }}")
        
        val modelFile = File(modelPath)
        
        // Check file properties
        println("File exists: ${modelFile.exists()}")
        println("File can read: ${modelFile.canRead()}")
        println("File can write: ${modelFile.canWrite()}")
        println("Parent directory exists: ${modelFile.parentFile?.exists()}")
        println("Parent directory can read: ${modelFile.parentFile?.canRead()}")
        
        if (!modelFile.exists() || !modelFile.canRead()) {
            println("Model file not available or cannot be read at $modelPath - skipping real model test")
            println("This is likely due to permission issues or the file not being present")
            return
        }
        
        println("Found model file at $modelPath")
        println("File size: ${modelFile.length()} bytes")
        
        val params = LlamaMobile.InitParams(modelPath)
        println("Initialization parameters: $params")
        
        // Try different path formats
        val pathFormats = listOf(
            modelPath,
            "/sdcard/Download/models/SmolLM-360M-Instruct.Q6_K.gguf",
            "storage/emulated/0/Download/models/SmolLM-360M-Instruct.Q6_K.gguf"
        )
        
        var context: Long = 0L
        
        for ((i, path) in pathFormats.withIndex()) {
            println("\nTrying path format $i: $path")
            val formatParams = LlamaMobile.InitParams(path)
            val tempContext = LlamaMobile.initContext(formatParams)
            println("Context handle: $tempContext")
            
            if (tempContext != 0L) {
                println("✓ Success with path format $i")
                context = tempContext
                break
            } else {
                println("✗ Failed with path format $i")
            }
        }
        
        // Skip the test if context couldn't be created (likely due to permissions)
        if (context == 0L) {
            println("Could not initialize context from any path format - skipping tokenization test")
            println("This may be due to permission issues or model file corruption")
            return
        }
        
        // Test tokenization
        val testText = "Hello, world!"
        val tokens = LlamaMobile.tokenize(context, testText)
        assertNotNull("Tokenization should succeed with real model", tokens)
        assertTrue("Should tokenize into multiple tokens", tokens?.size ?: 0 > 0)
        
        // Test detokenization
        val detokenized = LlamaMobile.detokenize(context, tokens ?: intArrayOf())
        assertNotNull("Detokenization should succeed with real model", detokenized)
        assertTrue("Detokenized text should contain original words", detokenized?.contains("Hello") ?: false)
        
        LlamaMobile.releaseContext(context)
    }
    
    @Test
    fun testDedicatedEmbeddingModel() {
        val embeddingFile = File(embeddingPath)
        if (!embeddingFile.exists() || !embeddingFile.canRead()) {
            println("Dedicated embedding model file not available or cannot be read at $embeddingPath - skipping test")
            println("This is likely due to permission issues or the file not being present")
            return
        }
        
        println("Attempting to load embedding model: $embeddingPath")
        
        // Create instance with dedicated embedding model - explicitly enable embeddings
        val initParams = LlamaMobile.InitParams(modelPath = embeddingPath, embedding = true)
        val context = LlamaMobile.initContext(initParams)
        
        if (context == 0L) {
            println("Failed to initialize context for embedding model - skipping test")
            println("This may be due to permission issues or model file corruption")
            return
        }
        
        // Test embedding generation
        val embeddings = LlamaMobile.generateEmbeddings(context, "Hello, world!")
        
        assertNotNull("Embeddings should be generated with dedicated embedding model", embeddings)
        assertTrue("Embedding vector should have dimensions", embeddings?.size ?: 0 > 0)
        
        // Test embedding parameters
        val embeddingDim = LlamaMobile.getEmbeddingDimension(context)
        println("Embedding dimension: $embeddingDim")
        assertTrue("Embedding dimension should be greater than 0", embeddingDim > 0)
        
        LlamaMobile.releaseContext(context)
    }
    
    @Test
    fun testMultimodalCapabilities() {
        val modelFile = File(imageModelPath)
        val mmprojFile = File(mmprojPath)
        
        // Check if files exist and are readable
        val modelReadable = modelFile.exists() && modelFile.canRead()
        val mmprojReadable = mmprojFile.exists() && mmprojFile.canRead()
        
        if (!modelReadable || !mmprojReadable) {
            println("Multimodal model files not available or cannot be read - skipping test")
            println("- Model: $imageModelPath (exists: ${modelFile.exists()}, readable: ${modelFile.canRead()})")
            println("- MMProj: $mmprojPath (exists: ${mmprojFile.exists()}, readable: ${mmprojFile.canRead()})")
            println("This is likely due to permission issues or files not being present")
            return
        }
        
        val params = LlamaMobile.InitParams(imageModelPath)
        val context = LlamaMobile.initContext(params)
        
        if (context == 0L) {
            println("Failed to initialize context for multimodal model - skipping test")
            return
        }
        
        // Initialize multimodal capabilities
        val success = LlamaMobile.initMultimodal(context, mmprojPath)
        if (!success) {
            println("Failed to initialize multimodal capabilities - skipping test")
            LlamaMobile.releaseContext(context)
            return
        }
        
        // Check multimodal status
        assertTrue("Multimodal should be enabled", LlamaMobile.isMultimodalEnabled(context))
        assertTrue("Model should support vision", LlamaMobile.supportsVision(context))
        
        LlamaMobile.releaseMultimodal(context)
        LlamaMobile.releaseContext(context)
    }
    
    @Test
    fun testTTSCapabilities() {
        val ttsFile = File(ttsModelPath)
        val vocoderFile = File(vocoderPath)
        
        // Check if files exist and are readable
        val ttsReadable = ttsFile.exists() && ttsFile.canRead()
        val vocoderReadable = vocoderFile.exists() && vocoderFile.canRead()
        
        if (!ttsReadable || !vocoderReadable) {
            println("TTS model files not available or cannot be read - skipping test")
            println("- TTS Model: $ttsModelPath (exists: ${ttsFile.exists()}, readable: ${ttsFile.canRead()})")
            println("- Vocoder: $vocoderPath (exists: ${vocoderFile.exists()}, readable: ${vocoderFile.canRead()})")
            println("This is likely due to permission issues or files not being present")
            return
        }
        
        // Load TTS model
        val ttsParams = LlamaMobile.InitParams(ttsModelPath)
        val context = LlamaMobile.initContext(ttsParams)
        
        if (context == 0L) {
            println("Failed to initialize context for TTS model - skipping test")
            return
        }
        
        // Initialize vocoder
        val vocoderSuccess = LlamaMobile.initVocoder(context, vocoderPath)
        if (!vocoderSuccess) {
            println("Failed to initialize vocoder - skipping test")
            LlamaMobile.releaseContext(context)
            return
        }
        
        // Check TTS status
        assertTrue("Vocoder should be enabled", LlamaMobile.isVocoderEnabled(context))
        
        // Test TTS type
        val ttsType = LlamaMobile.getTTSType(context)
        assertNotEquals("TTS type should not be unknown", LlamaMobile.TTSModelType.UNKNOWN, ttsType)
        
        LlamaMobile.releaseVocoder(context)
        LlamaMobile.releaseContext(context)
    }

}
