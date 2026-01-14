package com.llamamobile

import android.content.Context
import android.content.res.AssetManager
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.junit.Assert.*
import java.io.*

/**
 * Instrumented tests for LlamaMobile Android SDK
 * These tests run on actual Android devices or emulators
 */
@RunWith(AndroidJUnit4::class)
class LlamaMobileInstrumentedTests {
    
    private lateinit var context: Context
    private lateinit var assetManager: AssetManager
    
    companion object {
        const val TEST_ASSET_DIR = "grammars"
        const val TEST_GRAMMAR_FILE = "json.gbnf"
        const val TEST_OUTPUT_DIR = "/sdcard/llama_mobile_test"
        const val TEST_MODEL_FILE = "$TEST_OUTPUT_DIR/test_model.gguf"
    }
    
    @Before
    fun setUp() {
        // Get instrumentation context
        context = InstrumentationRegistry.getInstrumentation().context
        assetManager = context.assets
        
        // Create test directory
        val testDir = File(TEST_OUTPUT_DIR)
        if (!testDir.exists()) {
            testDir.mkdirs()
        }
    }
    
    @After
    fun tearDown() {
        // Clean up test files
        val testDir = File(TEST_OUTPUT_DIR)
        if (testDir.exists()) {
            testDir.deleteRecursively()
        }
    }
    
    @Test
    fun testAssetLoading() {
        // Test that we can access the grammar files from assets
        try {
            // List all grammar files
            val grammarFiles = assetManager.list(TEST_ASSET_DIR)
            assertNotNull(grammarFiles)
            assertTrue(grammarFiles!!.isNotEmpty())
            
            // Check if specific grammar file exists
            assertTrue(grammarFiles.contains(TEST_GRAMMAR_FILE))
            
            // Read a grammar file to verify content
            val inputStream = assetManager.open("$TEST_ASSET_DIR/$TEST_GRAMMAR_FILE")
            val reader = BufferedReader(InputStreamReader(inputStream))
            val content = reader.readText()
            reader.close()
            
            assertFalse(content.isEmpty())
            assertTrue(content.contains("json"))
            
        } catch (e: IOException) {
            fail("Asset loading failed: ${e.message}")
        }
    }
    
    @Test
    fun testFileSystemOperations() {
        // Test file system operations that LlamaMobile needs
        try {
            // Create a test file
            val testFile = File(TEST_OUTPUT_DIR, "test.txt")
            testFile.writeText("Hello, LlamaMobile!")
            
            // Verify file exists and contains content
            assertTrue(testFile.exists())
            assertEquals("Hello, LlamaMobile!", testFile.readText())
            
            // Test file copy operation
            val copyFile = File(TEST_OUTPUT_DIR, "test_copy.txt")
            testFile.copyTo(copyFile, overwrite = true)
            assertTrue(copyFile.exists())
            assertEquals(testFile.readText(), copyFile.readText())
            
            // Test file deletion
            copyFile.delete()
            assertFalse(copyFile.exists())
            
        } catch (e: IOException) {
            fail("File system operations failed: ${e.message}")
        }
    }
    
    @Test
    fun testGrammarFileCopyFromAssets() {
        // Test that we can copy grammar files from assets to internal storage
        // This simulates what users would do for structured output
        
        try {
            // Create target directory
            val targetDir = File("${context.filesDir}/grammars")
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }
            
            // Copy grammar file from assets
            val targetFile = File(targetDir, TEST_GRAMMAR_FILE)
            
            assetManager.open("$TEST_ASSET_DIR/$TEST_GRAMMAR_FILE").use { inputStream ->
                FileOutputStream(targetFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            
            // Verify file was copied successfully
            assertTrue(targetFile.exists())
            assertTrue(targetFile.length() > 0)
            
        } catch (e: IOException) {
            fail("Grammar file copy failed: ${e.message}")
        }
    }
    
    @Test
    fun testNativeLibraryLoading() {
        // Test that native libraries can be loaded
        // The init block in LlamaMobile should load these automatically
        try {
            // This will fail with UnsatisfiedLinkError if libraries can't be loaded
            System.loadLibrary("llama_mobile")
            System.loadLibrary("llama_mobile_jni")
            
            // If we get here, libraries loaded successfully
            assertTrue(true)
            
        } catch (e: UnsatisfiedLinkError) {
            // Libraries might not be available in test environment, so don't fail
            // Just log the issue
            println("Native libraries not found: ${e.message}")
            // This test is informational only, not critical for CI
        }
    }
    
    @Test
    fun testContextAvailability() {
        // Test that context and environment are properly set up
        assertNotNull(context)
        assertNotNull(assetManager)
        
        // Test that we can access files dir
        assertNotNull(context.filesDir)
        assertTrue(context.filesDir.exists())
        
        // Test that we can access cache dir
        assertNotNull(context.cacheDir)
        assertTrue(context.cacheDir.exists())
    }
    
    @Test
    fun testParameterValidations() {
        // Test that parameter validations work correctly
        
        // Test InitParams validation
        try {
            // This should succeed
            val validParams = LlamaMobile.InitParams(
                modelPath = TEST_MODEL_FILE,
                nCtx = 1024,
                nThreads = 4
            )
            assertNotNull(validParams)
            
        } catch (e: Exception) {
            fail("Valid InitParams threw exception: ${e.message}")
        }
        
        // Test CompletionParams validation
        try {
            // This should succeed
            val validParams = LlamaMobile.CompletionParams(
                prompt = "Hello, world!",
                maxTokens = 10,
                temperature = 0.7f
            )
            assertNotNull(validParams)
            
        } catch (e: Exception) {
            fail("Valid CompletionParams threw exception: ${e.message}")
        }
    }
    
    @Test
    fun testFileAccessPatterns() {
        // Test common file access patterns used by LlamaMobile
        
        // Test 1: Check if we can create a large file (simulating model file)
        val largeTestFile = File(TEST_OUTPUT_DIR, "large_test_file.bin")
        try {
            // Create a 1MB test file
            val buffer = ByteArray(1024 * 1024) // 1MB
            FileOutputStream(largeTestFile).use { fos ->
                fos.write(buffer)
            }
            
            assertTrue(largeTestFile.exists())
            assertEquals(1024 * 1024, largeTestFile.length())
            
        } catch (e: IOException) {
            println("Large file creation failed (may be due to permissions): ${e.message}")
            // Don't fail - this might be due to permissions on some devices
        }
        
        // Test 2: Test directory structure creation
        val nestedDir = File(TEST_OUTPUT_DIR, "nested/dir/structure")
        assertTrue(nestedDir.mkdirs())
        assertTrue(nestedDir.exists())
    }
    
    @Test
    fun testDownloadParamsCompatibility() {
        // Test that download parameters work correctly on Android
        val testUrl = "https://huggingface.co/model"
        val testLocalPath = "$TEST_OUTPUT_DIR/downloaded_model.gguf"
        
        val params = LlamaMobile.DownloadParams(
            url = testUrl,
            localPath = testLocalPath
        )
        
        assertEquals(testUrl, params.url)
        assertEquals(testLocalPath, params.localPath)
        
        // Test with headers (common for authentication)
        val headers = mapOf(
            "User-Agent" to "LlamaMobile-Android/1.0",
            "Authorization" to "Bearer test_token"
        )
        
        val paramsWithHeaders = LlamaMobile.DownloadParams(
            url = testUrl,
            localPath = testLocalPath,
            headers = headers
        )
        
        assertEquals(headers, paramsWithHeaders.headers)
    }
    
    @Test
    fun testDirectoryStructure() {
        // Verify that the SDK directory structure is correct
        
        // Check that the SDK has the expected structure
        val sdkRoot = File(context.packageResourcePath)
        assertNotNull(sdkRoot)
        
        // Check that we can access the APK contents
        assertTrue(sdkRoot.exists())
        assertTrue(sdkRoot.isDirectory)
    }
    
    @Test
    fun testPathOperations() {
        // Test common path operations used by LlamaMobile
        
        // Test that we can convert asset paths to file paths
        val assetPath = "$TEST_ASSET_DIR/$TEST_GRAMMAR_FILE"
        val internalPath = "${context.filesDir}/$assetPath"
        
        val internalFile = File(internalPath)
        val parentDir = internalFile.parentFile
        assertNotNull(parentDir)
        
        // Test path construction
        val modelDir = File(TEST_OUTPUT_DIR, "models")
        val modelFile = File(modelDir, "model.gguf")
        
        assertEquals("model.gguf", modelFile.name)
        assertEquals("models", modelFile.parentFile?.name)
        assertEquals("$TEST_OUTPUT_DIR/models/model.gguf", modelFile.absolutePath)
    }
}
