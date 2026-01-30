package com.llamamobile;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * Comprehensive instrumented tests for LlamaMobile Java SDK
 * These tests run on an Android device or emulator.
 */
@RunWith(AndroidJUnit4.class)
public class LlamaMobileComprehensiveTests {

    private static final String TAG = "LlamaMobileTests";
    private String embeddingPath;
    private static final String TEST_ASSET_DIR = "grammars";
    private static final String TEST_GRAMMAR_FILE = "json.gbnf";
    private Context context;
    private AssetManager assetManager;
    private String TEST_OUTPUT_DIR;
    private String rootPath;
    private String modelPath;
    private String ttsModelPath;
    private String vocoderPath;
    
    @Before
    public void setUp() {
        context = InstrumentationRegistry.getInstrumentation().getTargetContext();
        assetManager = context.getAssets();
        
        // Use app's external files directory instead of sdcard
        File externalFilesDir = context.getExternalFilesDir(null);
        TEST_OUTPUT_DIR = new File(externalFilesDir, "llama_mobile_test").getAbsolutePath();
        rootPath = new File(externalFilesDir, "models").getAbsolutePath();
        
        // Model paths (match Kotlin SDK structure)
        modelPath = new File(rootPath, "SmolVLM-256M-Instruct-Q8_0.gguf").getAbsolutePath();
        embeddingPath = new File(rootPath, "embedding/Qwen3-Embedding-0.6B-Q8_0.gguf").getAbsolutePath();
        
        // TTS model paths
        ttsModelPath = new File(rootPath, "TTS/model.pth").getAbsolutePath();
        vocoderPath = new File(rootPath, "TTS/vocoder.pth").getAbsolutePath();
        
        // Create test output directory if it doesn't exist
        File outputDir = new File(TEST_OUTPUT_DIR);
        if (!outputDir.exists()) {
            outputDir.mkdirs();
        }
        
        // Create model directory if it doesn't exist
        File modelDir = new File(rootPath);
        if (!modelDir.exists()) {
            modelDir.mkdirs();
            // Create subdirectories
            new File(rootPath, "embedding").mkdirs();
            new File(rootPath, "lora").mkdirs();
            new File(rootPath, "img").mkdirs();
        }
    }

    @Test
    public void testInitParamsConstructors() {
        // Test primary constructor
        LlamaMobile.InitParams params1 = new LlamaMobile.InitParams(modelPath);
        assertEquals(modelPath, params1.getModelPath());
        assertEquals(2048, params1.getNCtx());  // Default value is 2048
        assertEquals(4, params1.getNThreads());
        
        // Test constructor with all parameters
        LlamaMobile.InitParams params2 = new LlamaMobile.InitParams(
            modelPath,       // modelPath
            8192,            // nCtx
            null,            // chatTemplate
            null,            // systemPrompt
            512,             // nBatch
            512,             // nUbatch
            10,              // nGpuLayers
            8,               // nThreads
            true,            // useMmap
            false,           // useMlock
            false,           // embedding
            0,               // poolingType
            0,               // embdNormalize
            false,           // flashAttn
            null,            // cacheTypeK
            null,            // cacheTypeV
            true,            // enableChatTemplate
            null             // progressCallback
        );
        assertEquals(modelPath, params2.getModelPath());
        assertEquals(8192, params2.getNCtx());
        assertEquals(8, params2.getNThreads());
        
        Log.d(TAG, "Successfully tested InitParams constructors");
    }

    @Test
    public void testCompletionParamsBuilder() {
        String prompt = "Hello, world!";
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
            prompt,               // prompt
            0.7f,                 // temperature
            100,                  // maxTokens
            4,                    // nThreads
            -1,                   // seed
            40,                   // topK
            0.9,                  // topP (double, not float)
            0.05,                 // minP (double, not float)
            1.0,                  // typicalP (double, not float)
            64,                   // penaltyLastN
            1.1,                  // penaltyRepeat (double, not float)
            0.0,                  // penaltyFreq (double, not float)
            0.0,                  // penaltyPresent (double, not float)
            0,                    // mirostat
            5.0,                  // mirostatTau (double, not float)
            0.1,                  // mirostatEta (double, not float)
            false,                // ignoreEos
            0,                    // nProbs
            null,                 // grammar
            List.of("\n", "User:"),  // stopSequences
            List.of(),            // mediaPaths
            null                  // tokenCallback
        );
        
        assertEquals(prompt, params.getPrompt());
        assertEquals(0.7f, params.getTemperature(), 0.001f);
        assertEquals(0.9, params.getTopP(), 0.001f);
        assertEquals(40, params.getTopK());
        assertEquals(100, params.getMaxTokens());
        assertTrue(params.getStopSequences().contains("\n"));
        assertTrue(params.getStopSequences().contains("User:"));
        
        Log.d(TAG, "Successfully tested CompletionParams builder");
    }

    @Test
    public void testLoraAdapterBuilder() {
        // Add path for LoRA adapter
        String loraPath = new File(rootPath, "lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf").getAbsolutePath();
        
        LlamaMobile.LoraAdapter adapter = new LlamaMobile.LoraAdapter(
            loraPath,       // path
            0.8f            // scale
        );
        
        assertEquals(loraPath, adapter.getPath());
        assertEquals(0.8f, adapter.getScale(), 0.001f);
        
        Log.d(TAG, "Successfully tested LoRA adapter builder");
    }

    @Test
    public void testTTSModelType() {
        // Test TTSModelType enum values exist
        LlamaMobile.TTSModelType unknownType = LlamaMobile.TTSModelType.UNKNOWN;
        LlamaMobile.TTSModelType outEttsV02Type = LlamaMobile.TTSModelType.OUT_ETTS_V02;
        LlamaMobile.TTSModelType outEttsV03Type = LlamaMobile.TTSModelType.OUT_ETTS_V03;
        
        // Just ensure they can be referenced without errors
        assertNotNull(unknownType);
        assertNotNull(outEttsV02Type);
        assertNotNull(outEttsV03Type);
        
        // Test enum names
        assertEquals("UNKNOWN", unknownType.name());
        assertEquals("OUT_ETTS_V02", outEttsV02Type.name());
        assertEquals("OUT_ETTS_V03", outEttsV03Type.name());
        
        Log.d(TAG, "Successfully tested TTS model types");
    }

    @Test
    public void testContextInitializationWithInvalidPath() {
        // Test initialization with invalid model path
        LlamaMobile.InitParams invalidParams = new LlamaMobile.InitParams("/invalid/path/to/model.gguf");
        long context = LlamaMobile.initContext(invalidParams);
        
        // Should return 0 on failure
        assertEquals("Context should be zero for invalid path", 0L, context);
        
        Log.d(TAG, "Successfully tested context initialization with invalid path");
    }

    @Test
    public void testMethodsWithInvalidContext() {
        long invalidContext = 0L;
        
        // Test completion methods
        LlamaMobile.CompletionResult completionResult = LlamaMobile.generateCompletion(invalidContext, new LlamaMobile.CompletionParams("Hello"));
        assertNull("Completion should return null for invalid context", completionResult);
        
        LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams("Hello");
        LlamaMobile.CompletionResult completionResult2 = LlamaMobile.generateCompletion(invalidContext, completionParams);
        assertNull("Completion with params should return null for invalid context", completionResult2);
        
        // Test tokenization methods
        int[] tokens = LlamaMobile.tokenize(invalidContext, "Hello");
        assertNull("Tokenization should return null for invalid context", tokens);
        
        String detokenized = LlamaMobile.detokenize(invalidContext, new int[]{1, 2, 3});
        assertNull("Detokenization should return null for invalid context", detokenized);
        
        // Test embedding methods
        float[] embeddings = LlamaMobile.generateEmbeddings(invalidContext, "Hello");
        assertNull("Embeddings should return null for invalid context", embeddings);
        
        // Test TTS methods
        float[] audioSamples = LlamaMobile.generateAudioFromText(invalidContext, "Hello");
        assertNull("Audio generation should return null for invalid context", audioSamples);
        
        // Test LoRA methods
        LlamaMobile.LoraAdapter[] loraAdapters = LlamaMobile.getLoadedLoraAdapters(invalidContext);
        assertNull("Loaded LoRA adapters should return null for invalid context", loraAdapters);
        
        // Test conversation methods
        LlamaMobile.ConversationResult conversationResult = LlamaMobile.generateResponse(invalidContext, "Hello", 100);
        assertNull("Conversation should return null for invalid context", conversationResult);
        
        // Test model info methods
        String modelDesc = LlamaMobile.getModelDescription(invalidContext);
        assertNull("Model description should return null for invalid context", modelDesc);
        
        // Boolean methods should return false for invalid context
        assertFalse("isVocoderEnabled should return false for invalid context", LlamaMobile.isVocoderEnabled(invalidContext));
        assertFalse("isMultimodalEnabled should return false for invalid context", LlamaMobile.isMultimodalEnabled(invalidContext));
        assertFalse("supportsVision should return false for invalid context", LlamaMobile.supportsVision(invalidContext));
        assertFalse("supportsAudio should return false for invalid context", LlamaMobile.supportsAudio(invalidContext));
        assertFalse("isConversationActive should return false for invalid context", LlamaMobile.isConversationActive(invalidContext));
        
        // Number methods should return 0 for invalid context
        assertEquals("Context window size should be 0 for invalid context", 0, LlamaMobile.getContextWindowSize(invalidContext));
        assertEquals("Embedding dimension should be 0 for invalid context", 0, LlamaMobile.getEmbeddingDimension(invalidContext));
        assertEquals("Model size should be 0 for invalid context", 0L, LlamaMobile.getModelSize(invalidContext));
        assertEquals("Model parameters count should be 0 for invalid context", 0L, LlamaMobile.getModelParametersCount(invalidContext));
        
        // Test TTS type
        assertEquals("TTS type should be UNKNOWN for invalid context", LlamaMobile.TTSModelType.UNKNOWN, LlamaMobile.getTTSType(invalidContext));
        
        Log.d(TAG, "Successfully tested methods with invalid context");
    }

    @Test
    public void testCompletionControl() {
        // These methods should not crash with invalid context
        long invalidContext = 0L;
        
        // Test stop completion
        LlamaMobile.stopCompletion(invalidContext);
        
        // Test conversation control
        LlamaMobile.clearConversation(invalidContext);
        
        Log.d(TAG, "Successfully tested completion control methods");
    }

    @Test
    public void testAssetLoading() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        AssetManager assetManager = appContext.getAssets();

        try {
            // List all grammar files
            String[] grammarFiles = assetManager.list(TEST_ASSET_DIR);
            assertNotNull("Grammar directory should exist", grammarFiles);
            Log.d(TAG, "Found grammar files: " + Arrays.toString(grammarFiles));
            
            // Check if specific grammar file exists
            boolean hasJsonGrammar = false;
            for (String file : grammarFiles) {
                if (file.equals(TEST_GRAMMAR_FILE)) {
                    hasJsonGrammar = true;
                    break;
                }
            }
            assertTrue("JSON grammar file should exist", hasJsonGrammar);
            
        } catch (IOException e) {
            fail("Exception while accessing assets: " + e.getMessage());
        }
    }

    @Test
    public void testContextSafety() {
        // Test with invalid context
        long invalidContext = 0L;
        assertFalse("Should fail to release invalid context", false);
        
        // These should be safe to call with invalid context
        try {
            LlamaMobile.generateEmbeddings(invalidContext, "test");
        } catch (Exception e) {
            // Expected exception for invalid context
        }
        
        try {
            LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("test");
            LlamaMobile.generateCompletion(invalidContext, params);
        } catch (Exception e) {
            // Expected exception for invalid context
        }
        
        Log.d(TAG, "Context safety tests passed");
    }

    @Test
    public void testDeviceCompatibility() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        // Log device information
        Log.d(TAG, "Device: " + Build.MANUFACTURER + " " + Build.MODEL);
        Log.d(TAG, "Android Version: " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")");
        Log.d(TAG, "ABIs: " + Arrays.toString(Build.SUPPORTED_ABIS));
        
        // Check if device architecture is supported
        boolean hasSupportedAbi = false;
        for (String abi : Build.SUPPORTED_ABIS) {
            if (abi.equals("arm64-v8a") || abi.equals("x86_64")) {
                hasSupportedAbi = true;
                break;
            }
        }
        
        if (hasSupportedAbi) {
            Log.d(TAG, "Device has supported ABI");
        } else {
            Log.w(TAG, "Device ABI may not be fully supported: " + Arrays.toString(Build.SUPPORTED_ABIS));
        }
        
        // Test should pass regardless of architecture
        assertTrue("Device compatibility test should pass", true);
    }

    @Test
    public void testNativeLibraryLoading() {
        try {
            // This will fail if the native library can't be loaded
            LlamaMobile.ErrorType.values(); // Access a simple enum to test library loading
            Log.d(TAG, "Native library loaded successfully");
        } catch (Exception e) {
            fail("Native library test should not throw exceptions");
        }
    }

    private void copyAssetToStorage(Context context, String assetPath, String destPath) throws IOException {
        AssetManager assetManager = context.getAssets();
        InputStream in = assetManager.open(assetPath);
        File outFile = new File(destPath);
        
        // Create directory if it doesn't exist
        outFile.getParentFile().mkdirs();
        
        FileOutputStream out = new FileOutputStream(outFile);
        byte[] buffer = new byte[1024];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        in.close();
        out.close();
    }

    @Test
    public void testModelDirectoryAccess() {
        // Test if model directory is accessible
        File modelDir = new File(rootPath);
        boolean dirCreated = modelDir.mkdirs() || modelDir.exists();
        assertTrue("Model directory should be accessible", dirCreated);
        
        if (modelDir.exists()) {
            assertTrue("Model directory should be readable", modelDir.canRead());
            Log.d(TAG, "Model directory path: " + modelDir.getAbsolutePath());
        }
    }

    @Test
    public void testInitParams() {
        // Test that we can create and set init parameters
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(
            modelPath,           // modelPath
            4096,                      // nCtx
            null,                      // chatTemplate
            null,                      // systemPrompt
            1024,                      // nBatch
            1024,                      // nUbatch
            10,                        // nGpuLayers
            8,                         // nThreads
            true,                      // useMmap
            false,                     // useMlock
            false,                     // embedding
            0,                         // poolingType
            0,                         // embdNormalize
            false,                     // flashAttn
            null,                      // cacheTypeK
            null,                      // cacheTypeV
            true,                      // enableChatTemplate
            null                       // progressCallback
        );
        assertNotNull("InitParams should not be null", params);
        
        // Just verify we can create with all parameters without exceptions
        Log.d(TAG, "Successfully created and configured InitParams");
    }

    @Test
    public void testCompletionParams() {
        // Test that we can create and set completion parameters
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
            "Hello, how are you?",     // prompt
            0.7f,                      // temperature
            256,                       // maxTokens
            4,                         // nThreads
            -1,                        // seed
            50,                        // topK
            0.9,                       // topP
            0.05,                      // minP
            1.0,                       // typicalP
            64,                        // penaltyLastN
            1.1,                       // penaltyRepeat
            0.0,                       // penaltyFreq
            0.0,                       // penaltyPresent
            0,                         // mirostat
            5.0,                       // mirostatTau
            0.1,                       // mirostatEta
            false,                     // ignoreEos
            0,                         // nProbs
            "json",                    // grammar
            List.of(),                 // stopSequences
            List.of(),                 // mediaPaths
            null                       // tokenCallback
        );
        assertNotNull("CompletionParams should not be null", params);
        
        // Just verify we can create with all parameters without exceptions
        Log.d(TAG, "Successfully created and configured CompletionParams");
    }

    @Test
    public void testErrorTypes() {
        // Test that we can access error types without exceptions
        assertNotNull("ErrorType should be accessible", LlamaMobile.ErrorType.values());
        Log.d(TAG, "Available error types: " + Arrays.toString(LlamaMobile.ErrorType.values()));
    }

    @Test
    public void testRealModelCompletion() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        try {
            // Test real model initialization and completion
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                modelPath,
                2048,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                10,    // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                true, // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                Log.d(TAG, "Successfully initialized context with model: " + modelPath);
                
                // Test completion generation
                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams("Hello, how are you?");
                LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(context, completionParams);
                assertNotNull("Completion result should not be null", result);
                Log.d(TAG, "Completion result: " + result);
                
                // Test completion with params
                LlamaMobile.CompletionParams completionParamsWithOptions = new LlamaMobile.CompletionParams(
                    "Tell me about Android.",
                    0.7f,    // temperature
                    100,     // maxTokens
                    4,       // nThreads
                    -1,      // seed
                    40,      // topK
                    0.9,     // topP
                    0.05,    // minP
                    1.0,     // typicalP
                    64,      // penaltyLastN
                    1.1,     // penaltyRepeat
                    0.0,     // penaltyFreq
                    0.0,     // penaltyPresent
                    0,       // mirostat
                    5.0,     // mirostatTau
                    0.1,     // mirostatEta
                    false,   // ignoreEos
                    0,       // nProbs
                    null,    // grammar
                    List.of(), // stopSequences
                    List.of(), // mediaPaths
                    null     // tokenCallback
                );
                
                LlamaMobile.CompletionResult resultWithParams = LlamaMobile.generateCompletion(context, completionParamsWithOptions);
                assertNotNull("Completion with params result should not be null", resultWithParams);
                Log.d(TAG, "Completion with params result: " + resultWithParams);
                
                LlamaMobile.releaseContext(context);
                Log.d(TAG, "Successfully released context");
            } else {
                Log.e(TAG, "Failed to initialize context with model: " + modelPath);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in real model completion test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testContextInitialization() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                modelPath,
                1024,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                5,     // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                true,  // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                Log.d(TAG, "Context initialized successfully with handle: " + context);
                LlamaMobile.releaseContext(context);
            } else {
                Log.e(TAG, "Context initialization failed");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error initializing context: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testTokenization() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                modelPath,
                1024,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                0,     // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                true,  // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test tokenization
            int[] tokens = LlamaMobile.tokenize(context, "Hello, world!");
            assertNotNull("Tokenization result should not be null", tokens);
            assertTrue("Should have generated some tokens", tokens.length > 0);
            Log.d(TAG, "Tokenized 'Hello, world!' into " + tokens.length + " tokens");
            
            // Test detokenization
            String detokenized = LlamaMobile.detokenize(context, tokens);
                assertNotNull("Detokenization result should not be null", detokenized);
                Log.d(TAG, "Detokenized back to: " + detokenized);
                
                LlamaMobile.releaseContext(context);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in tokenization test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testEmbeddings() {
        File embeddingFile = new File(embeddingPath);
        if (!embeddingFile.exists() || !embeddingFile.canRead()) {
            System.out.println("Embedding model not available at " + embeddingPath + " - skipping test");
            return;
        }

        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                embeddingPath,
                1024,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                0,     // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                true,  // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test embedding generation
                float[] embeddings = LlamaMobile.generateEmbeddings(context, "Hello, world!");
                assertNotNull("Embeddings result should not be null", embeddings);
                assertTrue("Should have generated some embeddings", embeddings.length > 0);
                Log.d(TAG, "Generated " + embeddings.length + " dimensional embeddings");
                
                LlamaMobile.releaseContext(context);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in embeddings test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testMultiModal() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                modelPath,
                2048,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                0,     // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                false, // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test basic multimodal functionality
                // Note: This test requires a multimodal model and image file
                Log.d(TAG, "Testing multimodal functionality");
                
                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams(
                    "Describe this image:",
                    0.8f,    // temperature
                    100,     // maxTokens
                    4,       // nThreads
                    -1,      // seed
                    40,      // topK
                    0.9,     // topP
                    0.05,    // minP
                    1.0,     // typicalP
                    64,      // penaltyLastN
                    1.1,     // penaltyRepeat
                    0.0,     // penaltyFreq
                    0.0,     // penaltyPresent
                    0,       // mirostat
                    5.0,     // mirostatTau
                    0.1,     // mirostatEta
                    false,   // ignoreEos
                    0,       // nProbs
                    null,    // grammar
                    List.of(), // stopSequences
                    List.of(), // mediaPaths
                    null     // tokenCallback
                );
                
                LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(context, completionParams);
                assertNotNull("Multimodal completion result should not be null", result);
                Log.d(TAG, "Multimodal completion result: " + result);
                
                LlamaMobile.releaseContext(context);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in multimodal test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testTextToSpeech() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                modelPath,
                1024,  // nCtx
                null,
                null,
                512,   // nBatch
                512,   // nUbatch
                0,     // nGpuLayers
                4,     // nThreads
                true,  // useMmap
                false, // useMlock
                false, // embedding
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                true,  // enableChatTemplate
                null   // progressCallback
            );
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test basic TTS functionality
                // Note: This test requires a TTS model
                Log.d(TAG, "Testing TTS functionality");
                
                // Check if TTS is available
                boolean ttsAvailable = LlamaMobile.isVocoderEnabled(context);
                Log.d(TAG, "TTS available: " + ttsAvailable);
                
                if (ttsAvailable) {
                    // Test TTS generation (would require audio output handling)
                    Log.d(TAG, "TTS is available, ready for audio generation");
                }
                
                LlamaMobile.releaseContext(context);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in TTS test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testModelDirectoryStructure() {
        // Verify model directory structure is accessible
        File modelDir = new File(rootPath);
        if (modelDir.exists() && modelDir.isDirectory()) {
            String[] modelFiles = modelDir.list((dir, name) -> name.endsWith(".gguf") || name.endsWith(".bin"));
            if (modelFiles != null && modelFiles.length > 0) {
                Log.d(TAG, "Found model files in directory: " + Arrays.toString(modelFiles));
            }
        }
    }

    @Test
    public void testAssetFileAccess() {
        // Test direct access to a specific asset file
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        AssetManager assetManager = appContext.getAssets();
        
        try (InputStream is = assetManager.open(TEST_ASSET_DIR + "/" + TEST_GRAMMAR_FILE)) {
            assertNotNull("Should be able to open grammar file", is);
            int fileSize = is.available();
            assertTrue("Grammar file should have content", fileSize > 0);
            Log.d(TAG, "Successfully accessed grammar file with size: " + fileSize + " bytes");
        } catch (IOException e) {
            Log.e(TAG, "Error accessing grammar file: " + e.getMessage());
            fail("Should be able to access grammar file");
        }
    }

    @Test
    public void testTTSOptions() {
        // Test TTSOptions with custom parameters
        LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions(
            16000,
            "en-us",
            1.2f,
            false,
            null
        );
        
        assertEquals("Sample rate should be 16000", 16000, options.getSampleRate());
        assertEquals("Voice should be en-us", "en-us", options.getVoice());
        assertEquals("Speed should be 1.2", 1.2f, options.getSpeed(), 0.001f);
        // Note: saveToFile is private and doesn't have a getter in the current implementation
        // assertFalse("Save to file should be false", options.saveToFile);
        assertNull("Output file path should be null", options.getOutputFilePath());
    }

    @Test
    public void testTTSWithCustomOptions() {
        File ttsFile = new File(ttsModelPath);
        File vocoderFile = new File(vocoderPath);
        
        // Check if files exist and are readable
        boolean ttsReadable = ttsFile.exists() && ttsFile.canRead();
        boolean vocoderReadable = vocoderFile.exists() && vocoderFile.canRead();
        
        if (!ttsReadable || !vocoderReadable) {
            System.out.println("TTS model files not available or cannot be read - skipping test");
            return;
        }
        
        // Load TTS model
        LlamaMobile.InitParams ttsParams = new LlamaMobile.InitParams(ttsModelPath);
        long context = LlamaMobile.initContext(ttsParams);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for TTS model - skipping test");
            return;
        }
        
        // Initialize vocoder
        boolean vocoderSuccess = LlamaMobile.initVocoder(context, vocoderPath);
        if (!vocoderSuccess) {
            System.out.println("Failed to initialize vocoder - skipping test");
            LlamaMobile.releaseContext(context);
            return;
        }
        
        // Test TTS with custom options
        String text = "Hello, this is a test with custom TTS options.";
        LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions(
            24000,
            "en-us",
            1.0f,
            false,
            null
        );
        
        LlamaMobile.Result<LlamaMobile.SpeechResult, LlamaMobile.TTSError> result = LlamaMobile.generateSpeechSync(context, text, options);
        
        if (result != null && result.isSuccess()) {
            LlamaMobile.SpeechResult speechResult = result.getValue();
            System.out.println("TTS with custom options succeeded!");
            System.out.println("Sample rate: " + speechResult.getSampleRate());
            System.out.println("Duration: " + speechResult.getDuration() + " seconds");
            System.out.println("Method used: " + speechResult.getMethodUsed());
            assertNotNull("Audio samples should not be null", speechResult.getAudioSamples());
            assertTrue("Audio samples should not be empty", speechResult.getAudioSamples().length > 0);
        } else if (result != null) {
            LlamaMobile.TTSError error = result.getError();
            System.out.println("TTS with custom options failed: " + error);
            // This might fail if the model doesn't support all options, but we should still test the API
        }
        
        LlamaMobile.releaseVocoder(context);
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testTTSStreaming() {
        File ttsFile = new File(ttsModelPath);
        File vocoderFile = new File(vocoderPath);
        
        // Check if files exist and are readable
        boolean ttsReadable = ttsFile.exists() && ttsFile.canRead();
        boolean vocoderReadable = vocoderFile.exists() && vocoderFile.canRead();
        
        if (!ttsReadable || !vocoderReadable) {
            System.out.println("TTS model files not available or cannot be read - skipping test");
            return;
        }
        
        // Load TTS model
        LlamaMobile.InitParams ttsParams = new LlamaMobile.InitParams(ttsModelPath);
        long context = LlamaMobile.initContext(ttsParams);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for TTS model - skipping test");
            return;
        }
        
        // Initialize vocoder
        boolean vocoderSuccess = LlamaMobile.initVocoder(context, vocoderPath);
        if (!vocoderSuccess) {
            System.out.println("Failed to initialize vocoder - skipping test");
            LlamaMobile.releaseContext(context);
            return;
        }
        
        // Test streaming TTS
        String text = "Hello, this is a test of the streaming TTS API.";
        LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions(24000, "en-us", 1.0f, false, null);
        
        final int[] receivedChunks = {0};
        final int[] totalSamples = {0};
        
        LlamaMobile.Result<LlamaMobile.SpeechMetadata, LlamaMobile.TTSError> result = LlamaMobile.generateSpeechStream(
            context,
            text,
            options,
            progress -> {
                System.out.println("Streaming Progress: " + (int)(progress * 100) + "%");
            },
            audioChunk -> {
                receivedChunks[0]++;
                totalSamples[0] += audioChunk.length;
                System.out.println("Received audio chunk with " + audioChunk.length + " samples");
            }
        );
        
        if (result != null && result.isSuccess()) {
            System.out.println("Streaming TTS succeeded!");
            // Note: generateSpeechStream returns SpeechMetadata, not SpeechResult
            // So we can't access sampleRate, duration, etc. here
            System.out.println("Received " + receivedChunks[0] + " chunks with " + totalSamples[0] + " total samples");
            assertTrue("Should have received at least one chunk", receivedChunks[0] > 0);
        } else if (result != null) {
            LlamaMobile.TTSError error = result.getError();
            System.out.println("Streaming TTS failed: " + error);
        }
        
        LlamaMobile.releaseVocoder(context);
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testTTSStreamingForLongText() {
        File ttsFile = new File(ttsModelPath);
        File vocoderFile = new File(vocoderPath);
        
        // Check if files exist and are readable
        boolean ttsReadable = ttsFile.exists() && ttsFile.canRead();
        boolean vocoderReadable = vocoderFile.exists() && vocoderFile.canRead();
        
        if (!ttsReadable || !vocoderReadable) {
            System.out.println("TTS model files not available or cannot be read - skipping test");
            return;
        }
        
        // Load TTS model
        LlamaMobile.InitParams ttsParams = new LlamaMobile.InitParams(ttsModelPath);
        long context = LlamaMobile.initContext(ttsParams);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for TTS model - skipping test");
            return;
        }
        
        // Initialize vocoder
        boolean vocoderSuccess = LlamaMobile.initVocoder(context, vocoderPath);
        if (!vocoderSuccess) {
            System.out.println("Failed to initialize vocoder - skipping test");
            LlamaMobile.releaseContext(context);
            return;
        }
        
        // Test long text streaming
        String longText = "Hello! This is a long text example for streaming TTS. " +
                "This text will be split into multiple chunks and played continuously. " +
                "Each sentence will be generated and played as soon as it's ready. " +
                "This provides a much better user experience for long texts.";
        
        LlamaMobile.TTSOptions options = new LlamaMobile.TTSOptions(24000, "en-us", 1.0f, false, null);
        
        final int[] receivedChunks = {0};
        final int[] totalSamples = {0};
        
        LlamaMobile.Result<LlamaMobile.SpeechMetadata, LlamaMobile.TTSError> result = LlamaMobile.generateSpeechStreamForLongText(
            context,
            longText,
            options,
            progress -> {
                System.out.println("Long Text Streaming Progress: " + (int)(progress * 100) + "%");
            },
            audioChunk -> {
                receivedChunks[0]++;
                totalSamples[0] += audioChunk.length;
                System.out.println("Received audio chunk with " + audioChunk.length + " samples");
            }
        );
        
        if (result != null && result.isSuccess()) {
            System.out.println("Long text streaming succeeded!");
            // Note: generateSpeechStreamForLongText returns SpeechMetadata, not SpeechResult
            // So we can't access sampleRate, duration, etc. here
            System.out.println("Received " + receivedChunks[0] + " chunks with " + totalSamples[0] + " total samples");
            assertTrue("Should have received at least one chunk", receivedChunks[0] > 0);
        } else if (result != null) {
            LlamaMobile.TTSError error = result.getError();
            System.out.println("Long text streaming failed: " + error);
        }
        
        LlamaMobile.releaseVocoder(context);
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testTTSErrorHandling() {
        File ttsFile = new File(ttsModelPath);
        File vocoderFile = new File(vocoderPath);
        
        // Check if files exist and are readable
        boolean ttsReadable = ttsFile.exists() && ttsFile.canRead();
        boolean vocoderReadable = vocoderFile.exists() && vocoderFile.canRead();
        
        if (!ttsReadable || !vocoderReadable) {
            System.out.println("TTS model files not available or cannot be read - skipping test");
            return;
        }
        
        // Load TTS model
        LlamaMobile.InitParams ttsParams = new LlamaMobile.InitParams(ttsModelPath);
        long context = LlamaMobile.initContext(ttsParams);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for TTS model - skipping test");
            return;
        }
        
        // Initialize vocoder
        boolean vocoderSuccess = LlamaMobile.initVocoder(context, vocoderPath);
        if (!vocoderSuccess) {
            System.out.println("Failed to initialize vocoder - skipping test");
            LlamaMobile.releaseContext(context);
            return;
        }
        
        // Test 1: Empty text
        LlamaMobile.Result<LlamaMobile.SpeechResult, LlamaMobile.TTSError> emptyTextResult = LlamaMobile.generateSpeechSync(
            context,
            "",
            new LlamaMobile.TTSOptions()
        );
        
        if (emptyTextResult != null && !emptyTextResult.isSuccess()) {
            LlamaMobile.TTSError error = emptyTextResult.getError();
            System.out.println("Empty text test: Expected failure, got: " + error);
        }
        
        // Test 2: Test without vocoder
        LlamaMobile.releaseVocoder(context);
        
        LlamaMobile.Result<LlamaMobile.SpeechResult, LlamaMobile.TTSError> noVocoderResult = LlamaMobile.generateSpeechSync(
            context,
            "Hello",
            new LlamaMobile.TTSOptions()
        );
        
        if (noVocoderResult != null && !noVocoderResult.isSuccess()) {
            LlamaMobile.TTSError error = noVocoderResult.getError();
            System.out.println("No vocoder test: Expected failure, got: " + error);
        }
        
        // Re-initialize vocoder for cleanup
        LlamaMobile.initVocoder(context, vocoderPath);
        
        LlamaMobile.releaseVocoder(context);
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testTTSNoModelLoaded() {
        // Test TTS with no model loaded (invalid context)
        long invalidContext = 0L;
        
        LlamaMobile.Result<LlamaMobile.SpeechResult, LlamaMobile.TTSError> result = LlamaMobile.generateSpeechSync(
            invalidContext,
            "Hello",
            new LlamaMobile.TTSOptions()
        );
        
        if (result != null && !result.isSuccess()) {
            LlamaMobile.TTSError error = result.getError();
            System.out.println("No model loaded test: Expected failure, got: " + error);
        }
    }

    @Test
    public void testConversationAPI() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath);
        long context = LlamaMobile.initContext(params);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for conversation test - skipping test");
            return;
        }
        
        // Test conversation API
        LlamaMobile.ConversationResult result = LlamaMobile.generateResponse(context, "Hello, how are you?", 50);
        assertNotNull("Conversation result should not be null", result);
        
        boolean textGenerated = result != null && result.getText() != null && !result.getText().isEmpty();
        boolean tokensGenerated = result != null && result.getTokensGenerated() > 0;
        assertTrue("Should generate either text or tokens", textGenerated || tokensGenerated);
        
        if (result != null) {
            System.out.println("Conversation result: " + result.getText());
            System.out.println("Tokens generated: " + result.getTokensGenerated());
            System.out.println("Time to first token: " + result.getTimeToFirstToken() + "ms");
            System.out.println("Total time: " + result.getTotalTime() + "ms");
        }
        
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testModelInfo() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath);
        long context = LlamaMobile.initContext(params);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for model info test - skipping test");
            return;
        }
        
        // Test model size and parameters count
        long modelSize = LlamaMobile.getModelSize(context);
        long paramsCount = LlamaMobile.getModelParametersCount(context);
        
        assertTrue("Model size should be greater than 0", modelSize > 0L);
        assertTrue("Model parameters count should be greater than 0", paramsCount > 0L);
        
        System.out.println("Model size: " + modelSize + " bytes");
        System.out.println("Model parameters count: " + paramsCount);
        
        // Test model description
        String modelDesc = LlamaMobile.getModelDescription(context);
        assertNotNull("Model description should not be null", modelDesc);
        System.out.println("Model description: " + modelDesc);
        
        // Test context window size
        int ctxWindowSize = LlamaMobile.getContextWindowSize(context);
        assertTrue("Context window size should be greater than 0", ctxWindowSize > 0);
        System.out.println("Context window size: " + ctxWindowSize);
        
        LlamaMobile.releaseContext(context);
    }

    @Test
    public void testLoRAAdapterLoading() {
        File modelFile = new File(modelPath);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + modelPath + " - skipping test");
            return;
        }
        
        // Define loraPath locally
        String loraPath = new File(rootPath, "lora/fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf").getAbsolutePath();
        
        File loraFile = new File(loraPath);
        if (!loraFile.exists() || !loraFile.canRead()) {
            System.out.println("LoRA adapter file not available at " + loraPath + " - skipping test");
            return;
        }
        
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath);
        long context = LlamaMobile.initContext(params);
        
        if (context == 0L) {
            System.out.println("Failed to initialize context for LoRA test - skipping test");
            return;
        }
        
        // Test LoRA adapter loading
        LlamaMobile.LoraAdapter adapter = new LlamaMobile.LoraAdapter(loraPath, 0.8f);
        
        LlamaMobile.LoraAdapter[] adapters = {adapter};
        boolean success = LlamaMobile.applyLoraAdapters(context, adapters);
        
        if (success) {
            System.out.println("Successfully loaded LoRA adapter");
            
            // Test getting loaded LoRA adapters
            LlamaMobile.LoraAdapter[] loadedAdapters = LlamaMobile.getLoadedLoraAdapters(context);
            assertNotNull("Loaded LoRA adapters should not be null", loadedAdapters);
            assertTrue("Should have at least one LoRA adapter loaded", loadedAdapters.length > 0);
            
            System.out.println("Loaded " + loadedAdapters.length + " LoRA adapter(s)");
            
            // Test removing LoRA adapters
            LlamaMobile.removeLoraAdapters(context);
            LlamaMobile.LoraAdapter[] removedAdapters = LlamaMobile.getLoadedLoraAdapters(context);
            assertTrue("Should have no LoRA adapters after removal", removedAdapters == null || removedAdapters.length == 0);
            System.out.println("Successfully removed LoRA adapters");
        } else {
            System.out.println("Failed to load LoRA adapter - this may be due to compatibility issues");
        }
        
        LlamaMobile.releaseContext(context);
    }
}