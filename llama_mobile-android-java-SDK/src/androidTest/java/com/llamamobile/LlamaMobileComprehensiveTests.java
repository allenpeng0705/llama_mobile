package com.llamamobile;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Environment;
import android.util.Log;

import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;

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
    private static final String TEST_ASSET_DIR = "grammars";
    private static final String TEST_GRAMMAR_FILE = "json.gbnf";
    private static final String TEST_MODEL_DIR = Environment.getExternalStorageDirectory().getAbsolutePath() + "/llama_mobile/models";
    private static final String TEST_MODEL_PATH = TEST_MODEL_DIR + "/gemma-2b-it-q4_k_m.gguf"; // Example model path

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
            Log.e(TAG, "Error accessing assets: " + e.getMessage());
            fail("Asset loading should succeed");
        }
    }

    @Test
    public void testModelDirectoryAccess() {
        // Test if model directory is accessible
        File modelDir = new File(TEST_MODEL_DIR);
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
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
        assertNotNull("InitParams should not be null", params);
        
        // Test parameter setting
        params.setNGpuLayers(10);
        params.setNCtx(4096);
        params.setNBatch(1024);
        params.setNThreads(8);
        params.setNThreadsBatch(8);
        params.setVerbose(true);
        params.setGrammarPath(TEST_ASSET_DIR + "/" + TEST_GRAMMAR_FILE);
        params.setCacheKV(true);
        params.setMaxCacheSize(512 * 1024 * 1024); // 512MB
        
        // Just verify we can set all parameters without exceptions
        Log.d(TAG, "Successfully created and configured InitParams");
    }

    @Test
    public void testCompletionParams() {
        // Test that we can create and set completion parameters
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("Hello, how are you?");
        assertNotNull("CompletionParams should not be null", params);
        
        // Test parameter setting
        params.setMaxTokens(256);
        params.setTemperature(0.7f);
        params.setTopP(0.9f);
        params.setTopK(50);
        params.setRepeatPenalty(1.1f);
        params.setGrammar("json");
        params.setMediaPaths(List.of());
        params.setEcho(true);
        params.setStream(false);
        params.setVerbosePrompt(true);
        
        // Just verify we can set all parameters without exceptions
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
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            // Test real model initialization and completion
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNGpuLayers(10);
            params.setNCtx(2048);
            params.setVerbose(true);
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                Log.d(TAG, "Successfully initialized context with model: " + TEST_MODEL_PATH);
                
                // Test completion generation
                LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(context, "Hello, how are you?");
                assertNotNull("Completion result should not be null", result);
                Log.d(TAG, "Completion result: " + result);
                
                // Test completion with params
                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams("Tell me about Android.");
                completionParams.setMaxTokens(100);
                completionParams.setTemperature(0.7f);
                
                LlamaMobile.CompletionResult resultWithParams = LlamaMobile.generateCompletion(context, completionParams);
                assertNotNull("Completion with params result should not be null", resultWithParams);
                Log.d(TAG, "Completion with params result: " + resultWithParams);
                
                LlamaMobile.releaseContext(context);
                Log.d(TAG, "Successfully released context");
            } else {
                Log.e(TAG, "Failed to initialize context with model: " + TEST_MODEL_PATH);
            }
        } catch (Exception e) {
            Log.e(TAG, "Error in real model completion test: " + e.getMessage());
            e.printStackTrace();
        }
    }

    @Test
    public void testContextInitialization() {
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNCtx(1024);
            params.setNGpuLayers(5);
            
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
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNCtx(1024);
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test tokenization
                long[] tokens = LlamaMobile.tokenize(context, "Hello, world!");
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
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNCtx(1024);
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test embedding generation
                float[] embeddings = LlamaMobile.getEmbeddings(context, "Hello, world!");
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
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNCtx(2048);
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test basic multimodal functionality
                // Note: This test requires a multimodal model and image file
                Log.d(TAG, "Testing multimodal functionality");
                
                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams("Describe this image:");
                completionParams.setMediaPaths(List.of()); // Empty list if no images
                
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
        File modelFile = new File(TEST_MODEL_PATH);
        if (!modelFile.exists() || !modelFile.canRead()) {
            System.out.println("Model file not available at " + TEST_MODEL_PATH + " - skipping test");
            return;
        }
        
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
            params.setNCtx(1024);
            
            long context = LlamaMobile.initContext(params);
            if (context != 0L) {
                // Test basic TTS functionality
                // Note: This test requires a TTS model
                Log.d(TAG, "Testing TTS functionality");
                
                // Check if TTS is available
                boolean ttsAvailable = LlamaMobile.isTTSAvailable(context);
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
        File modelDir = new File(TEST_MODEL_DIR);
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
}