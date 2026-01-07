package com.llamamobile

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito.*
import org.mockito.junit.MockitoJUnitRunner
import java.util.concurrent.atomic.AtomicBoolean

@RunWith(MockitoJUnitRunner::class)
class LlamaMobileUnitTests {
    private val testModelPath = "/path/to/test/model.gguf"
    private var mockContextHandle: Long = 0
    private val testPrompt = "Hello, world!"
    private val testCompletion = "How can I help you today?"

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
    fun `test InitParams creation with default values`() {
        // Test creation of InitParams with default values
        val params = LlamaMobile.InitParams(testModelPath)
        assertEquals(testModelPath, params.modelPath)
        assertEquals(512, params.nCtx)
        assertNull(params.chatTemplate)
        assertEquals(LlamaMobile.CacheType.MEMORY, params.cacheType)
    }

    @Test
    fun `test InitParams creation with custom values`() {
        // Test creation of InitParams with custom values
        val customParams = LlamaMobile.InitParams(
            modelPath = testModelPath,
            nCtx = 2048,
            chatTemplate = "custom_template",
            cacheType = LlamaMobile.CacheType.NONE
        )
        assertEquals(2048, customParams.nCtx)
        assertEquals("custom_template", customParams.chatTemplate)
        assertEquals(LlamaMobile.CacheType.NONE, customParams.cacheType)
    }

    @Test
    fun `test CompletionParams creation with default values`() {
        // Test creation of CompletionParams with default values
        val testPrompt = "Hello, world!"
        val params = LlamaMobile.CompletionParams(testPrompt)
        assertEquals(testPrompt, params.prompt)
        assertEquals(0.8f, params.temperature, 0.01f)
        assertEquals(100, params.maxTokens)
    }

    @Test
    fun `test CompletionParams creation with custom values`() {
        // Test creation of CompletionParams with custom values
        val testPrompt = "Hello, world!"
        val customParams = LlamaMobile.CompletionParams(
            prompt = testPrompt,
            temperature = 0.5f,
            maxTokens = 200
        )
        assertEquals(0.5f, customParams.temperature, 0.01f)
        assertEquals(200, customParams.maxTokens)
    }

    @Test
    fun `test CacheType enum values`() {
        // Test that all enum values are present and correct
        val cacheTypes = LlamaMobile.CacheType.values()
        assertEquals(2, cacheTypes.size)
        assertEquals(LlamaMobile.CacheType.NONE, cacheTypes[0])
        assertEquals(LlamaMobile.CacheType.MEMORY, cacheTypes[1])
    }

    @Test
    fun `test initialization edge cases`() {
        // Test null model path handling
        val nullPathParams = LlamaMobile.InitParams("")
        val nullPathHandle = LlamaMobile.initContext(nullPathParams)
        assertEquals(0L, nullPathHandle)

        // Test empty model path handling
        val emptyPathParams = LlamaMobile.InitParams("")
        val emptyPathHandle = LlamaMobile.initContext(emptyPathParams)
        assertEquals(0L, emptyPathHandle)
    }

    @Test
    fun `test CompletionParams edge cases`() {
        // Test empty prompt handling
        val emptyPromptParams = LlamaMobile.CompletionParams("")
        assertNotNull(emptyPromptParams)
        assertEquals("", emptyPromptParams.prompt)

        // Test null prompt handling
        val nullPromptParams = LlamaMobile.CompletionParams(null)
        assertNotNull(nullPromptParams)
        assertNull(nullPromptParams.prompt)
    }

    @Test
    fun `test parameter immutability`() {
        // Test that parameters are immutable (data classes)
        val initParams = LlamaMobile.InitParams(testModelPath)
        val completionParams = LlamaMobile.CompletionParams("Test prompt")

        // Verify they are data classes (have copy method)
        val copiedInitParams = initParams.copy(nCtx = 1024)
        val copiedCompletionParams = completionParams.copy(temperature = 0.7f)

        // Verify copies have changed values but originals remain the same
        assertEquals(512, initParams.nCtx)
        assertEquals(1024, copiedInitParams.nCtx)
        assertEquals(0.8f, completionParams.temperature, 0.01f)
        assertEquals(0.7f, copiedCompletionParams.temperature, 0.01f)
    }

    @Test
    fun `test token callback functionality`() {
        // Test the token callback interface
        val receivedTokens = mutableListOf<String>()
        val callbackCalled = AtomicBoolean(false)
        
        val callback = LlamaMobile.TokenCallback {
            callbackCalled.set(true)
            if (it != null) {
                receivedTokens.add(it)
            }
            true
        }
        
        // Test the callback
        assertTrue(callback.onToken(testPrompt))
        assertTrue(callbackCalled.get())
        assertTrue(receivedTokens.contains(testPrompt))
        
        // Test with null token
        assertFalse(callback.onToken(null))
    }

    @Test
    fun `test completion params with various parameters`() {
        // Test CompletionParams with all possible parameters
        val stopSequences = listOf("\n", ".", "END")
        val grammar = "# Grammar rules\nstart: 'hello'"
        
        val params = LlamaMobile.CompletionParams(
            prompt = testPrompt,
            temperature = 0.7f,
            maxTokens = 200,
            nThreads = 6,
            seed = 12345,
            topK = 50,
            topP = 0.95,
            minP = 0.1,
            typicalP = 0.9,
            penaltyLastN = 32,
            penaltyRepeat = 1.2,
            penaltyFreq = 0.1,
            penaltyPresent = 0.1,
            mirostat = 2,
            mirostatTau = 3.0,
            mirostatEta = 0.05,
            ignoreEos = true,
            nProbs = 5,
            grammar = grammar,
            stopSequences = stopSequences
        )
        
        assertEquals(testPrompt, params.prompt)
        assertEquals(0.7f, params.temperature, 0.01f)
        assertEquals(200, params.maxTokens)
        assertEquals(6, params.nThreads)
        assertEquals(12345, params.seed)
        assertEquals(50, params.topK)
        assertEquals(0.95, params.topP, 0.01)
        assertEquals(0.1, params.minP, 0.01)
        assertEquals(0.9, params.typicalP, 0.01)
        assertEquals(32, params.penaltyLastN)
        assertEquals(1.2, params.penaltyRepeat, 0.01)
        assertEquals(0.1, params.penaltyFreq, 0.01)
        assertEquals(0.1, params.penaltyPresent, 0.01)
        assertEquals(2, params.mirostat)
        assertEquals(3.0, params.mirostatTau, 0.01)
        assertEquals(0.05, params.mirostatEta, 0.01)
        assertTrue(params.ignoreEos)
        assertEquals(5, params.nProbs)
        assertEquals(grammar, params.grammar)
        assertEquals(stopSequences, params.stopSequences)
    }
}
