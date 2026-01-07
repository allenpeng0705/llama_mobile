package com.llamamobile

import android.content.Context
import android.content.res.AssetManager
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream

@RunWith(AndroidJUnit4::class)
class LlamaMobileInstrumentedTests {
    private val TAG = "LlamaMobileInstrumentedTests"
    private val testModelPath = "/sdcard/test/model.gguf"
    private var contextHandle: Long = 0
    private lateinit var appContext: Context
    private lateinit var assetManager: AssetManager

    @Before
    fun setUp() {
        // Get the application context for instrumentation tests
        appContext = InstrumentationRegistry.getInstrumentation().targetContext
        assetManager = appContext.assets
        contextHandle = 0
    }

    @After
    fun tearDown() {
        // Clean up any resources and release context
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = 0
            Log.d(TAG, "Released context handle")
        }

        // Clean up test model file if it exists
        val testModelFile = File(testModelPath)
        if (testModelFile.exists()) {
            testModelFile.delete()
            Log.d(TAG, "Deleted test model file")
        }
    }

    @Test
    fun `test model initialization fails with non-existent model`() {
        // Test that model initialization fails gracefully with non-existent model
        val initParams = LlamaMobile.InitParams("/non/existent/path/model.gguf")
        contextHandle = LlamaMobile.initContext(initParams)
        assertEquals(0L, contextHandle)
        Log.d(TAG, "Model initialization correctly failed with non-existent model")
    }

    @Test
    fun `test model initialization with valid path format`() {
        // Test that model initialization handles valid path format (even if file doesn't exist)
        val initParams = LlamaMobile.InitParams(testModelPath)
        contextHandle = LlamaMobile.initContext(initParams)
        assertEquals(0L, contextHandle) // Should fail but not crash
        Log.d(TAG, "Model initialization correctly handled valid path format")
    }

    @Test
    fun `test completion generation fails with invalid context`() {
        // Test that completion generation fails gracefully with invalid context
        val completionParams = LlamaMobile.CompletionParams("Hello, world!")
        val result = LlamaMobile.generateCompletion(0L, completionParams)
        assertNull(result)
        Log.d(TAG, "Completion generation correctly failed with invalid context")
    }

    @Test
    fun `test release context handles invalid handle`() {
        // Test that releaseContext handles invalid handle gracefully (no crash)
        try {
            LlamaMobile.releaseContext(999999L) // Invalid handle
            LlamaMobile.releaseContext(0L) // Null handle
            assertTrue(true) // No exception thrown
            Log.d(TAG, "releaseContext correctly handled invalid handles")
        } catch (e: Exception) {
            fail("releaseContext should not throw exception for invalid handle")
        }
    }

    @Test
    fun `test AssetManager access`() {
        // Test that we can access assets (required for grammar files)
        try {
            // Try to list assets - this verifies we have proper access
            val assets = assetManager.list("")
            assertNotNull(assets)
            Log.d(TAG, "AssetManager access verified")
        } catch (e: Exception) {
            fail("Should be able to access AssetManager: ${e.message}")
        }
    }

    @Test
    fun `test InitParams with different cache types`() {
        // Test that InitParams works with both cache types
        val memoryParams = LlamaMobile.InitParams(
            modelPath = testModelPath,
            cacheType = LlamaMobile.CacheType.MEMORY
        )
        assertEquals(LlamaMobile.CacheType.MEMORY, memoryParams.cacheType)

        val noneParams = LlamaMobile.InitParams(
            modelPath = testModelPath,
            cacheType = LlamaMobile.CacheType.NONE
        )
        assertEquals(LlamaMobile.CacheType.NONE, noneParams.cacheType)

        Log.d(TAG, "Cache type parameters tested successfully")
    }

    @Test
    fun `test CompletionParams with extreme values`() {
        // Test that CompletionParams handles extreme values gracefully
        val completionParams = LlamaMobile.CompletionParams(
            prompt = "Test",
            temperature = 0.0f, // Minimum temperature
            maxTokens = 1 // Minimum tokens
        )
        assertEquals(0.0f, completionParams.temperature, 0.01f)
        assertEquals(1, completionParams.maxTokens)

        val maxParams = LlamaMobile.CompletionParams(
            prompt = "Test",
            temperature = 2.0f, // High temperature
            maxTokens = 1000 // Many tokens
        )
        assertEquals(2.0f, maxParams.temperature, 0.01f)
        assertEquals(1000, maxParams.maxTokens)

        Log.d(TAG, "Extreme CompletionParams values tested successfully")
    }

    @Test
    fun `test context lifecycle`() {
        // Test complete context lifecycle: create -> use -> release
        val initParams = LlamaMobile.InitParams(testModelPath)
        
        // Initialization should fail with non-existent model but not crash
        contextHandle = LlamaMobile.initContext(initParams)
        assertEquals(0L, contextHandle)

        // Should be able to release even if initialization failed
        LlamaMobile.releaseContext(contextHandle)
        contextHandle = 0

        Log.d(TAG, "Context lifecycle tested successfully")
    }
}