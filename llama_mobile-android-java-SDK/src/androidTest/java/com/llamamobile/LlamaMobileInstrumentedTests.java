package com.llamamobile;

import static org.junit.Assert.*;

import android.content.Context;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

@RunWith(AndroidJUnit4.class)
public class LlamaMobileInstrumentedTests {
    private static final String TAG = "LlamaMobileInstrumentedTests";
    private static final String TEST_MODEL_PATH = "/sdcard/test/model.gguf";
    private long contextHandle;
    private Context appContext;

    @Before
    public void setUp() {
        // Get the application context for instrumentation tests
        appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        contextHandle = 0;
    }

    @After
    public void tearDown() {
        // Clean up any resources and release context
        if (contextHandle != 0) {
            LlamaMobile.releaseContext(contextHandle);
            contextHandle = 0;
        }

        // Clean up test model file if it exists
        File testModelFile = new File(TEST_MODEL_PATH);
        if (testModelFile.exists()) {
            testModelFile.delete();
        }
    }

    @Test
    public void testGrammarContentRetrieval() {
        // Test that grammarContent method works with different grammar names
        
        // Test with JSON grammar
        String jsonGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.JSON);
        assertNotNull("JSON grammar should not be null", jsonGrammar);
        assertFalse("JSON grammar should not be empty", jsonGrammar.trim().isEmpty());
        
        // Test with ARITHMETIC grammar
        String arithmeticGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.ARITHMETIC);
        assertNotNull("Arithmetic grammar should not be null", arithmeticGrammar);
        assertFalse("Arithmetic grammar should not be empty", arithmeticGrammar.trim().isEmpty());
        
        // Test with LIST grammar
        String listGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.LIST);
        assertNotNull("List grammar should not be null", listGrammar);
        assertFalse("List grammar should not be empty", listGrammar.trim().isEmpty());
        
        // Test with C grammar
        String cGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.C);
        assertNotNull("C grammar should not be null", cGrammar);
        assertFalse("C grammar should not be empty", cGrammar.trim().isEmpty());
        
        // Test with CHESS grammar
        String chessGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.CHESS);
        assertNotNull("Chess grammar should not be null", chessGrammar);
        assertFalse("Chess grammar should not be empty", chessGrammar.trim().isEmpty());
    }

    @Test
    public void testModelInitializationWithDifferentCacheTypes() {
        // Test initialization with MEMORY cache type
        LlamaMobile.InitParams memoryParams = new LlamaMobile.InitParams(
                TEST_MODEL_PATH,
                512,
                null,
                null,
                512,
                512,
                0,
                4,
                true,
                false,
                false,
                0,
                0,
                false,
                null,
                null,
                LlamaMobile.CacheType.MEMORY
        );
        long memoryHandle = LlamaMobile.initContext(memoryParams);
        assertEquals(0L, memoryHandle); // Should fail but not crash
        
        if (memoryHandle != 0) {
            LlamaMobile.releaseContext(memoryHandle);
        }

        // Test initialization with NONE cache type
        LlamaMobile.InitParams noneParams = new LlamaMobile.InitParams(
                TEST_MODEL_PATH,
                512,
                null,
                null,
                512,
                512,
                0,
                4,
                true,
                false,
                false,
                0,
                0,
                false,
                null,
                null,
                LlamaMobile.CacheType.NONE
        );
        long noneHandle = LlamaMobile.initContext(noneParams);
        assertEquals(0L, noneHandle); // Should fail but not crash
        
        if (noneHandle != 0) {
            LlamaMobile.releaseContext(noneHandle);
        }
    }

    @Test
    public void testCompletionWithGrammarParameter() {
        // Get JSON grammar content
        String jsonGrammar = LlamaMobile.grammarContent(appContext, LlamaMobile.GrammarName.JSON);
        assertNotNull("JSON grammar should be available", jsonGrammar);
        
        // Create completion params with grammar
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
                "Generate a simple JSON object: ",
                0.7f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                0,
                5.0,
                0.1,
                false,
                0,
                jsonGrammar,
                null,
                null
        );
        
        // This should fail gracefully since we don't have a valid context
        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(0L, params);
        assertNull("Completion should fail with invalid context", result);
    }

    @Test
    public void testCompletionWithStopSequences() {
        // Create completion params with stop sequences
        List<String> stopSequences = new ArrayList<>();
        stopSequences.add("\n");
        stopSequences.add(".");
        stopSequences.add("END");
        
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
                "Test with stop sequences: ",
                0.8f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                0,
                5.0,
                0.1,
                false,
                0,
                null,
                stopSequences,
                null
        );
        
        // Verify stop sequences were set correctly
        assertEquals("Stop sequences count should match", 3, params.getStopSequences().size());
        assertTrue("Stop sequences should contain newline", params.getStopSequences().contains("\n"));
        assertTrue("Stop sequences should contain period", params.getStopSequences().contains("."));
        assertTrue("Stop sequences should contain END", params.getStopSequences().contains("END"));
        
        // This should fail gracefully since we don't have a valid context
        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(0L, params);
        assertNull("Completion should fail with invalid context", result);
    }

    @Test
    public void testCompletionWithTokenCallback() {
        // Create a token callback that collects tokens
        final List<String> receivedTokens = new ArrayList<>();
        
        LlamaMobile.TokenCallback callback = new LlamaMobile.TokenCallback() {
            @Override
            public boolean onToken(String token) {
                if (token != null) {
                    receivedTokens.add(token);
                }
                return true; // Continue generation
            }
        };
        
        // Create completion params with token callback
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(
                "Test with token callback: ",
                0.8f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                0,
                5.0,
                0.1,
                false,
                0,
                null,
                null,
                callback
        );
        
        // This should fail gracefully since we don't have a valid context
        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(0L, params);
        assertNull("Completion should fail with invalid context", result);
        
        // Since we never got any tokens, the list should be empty
        assertTrue("No tokens should be received with invalid context", receivedTokens.isEmpty());
    }

    @Test
    public void testContextLifecycle() {
        // Test context initialization and release sequence
        
        // Initialize with invalid model path (should fail but not crash)
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
        contextHandle = LlamaMobile.initContext(params);
        assertEquals(0L, contextHandle);
        
        // Try to release invalid handle (should not crash)
        LlamaMobile.releaseContext(0L);
        
        // Try to release null handle (should not crash)
        LlamaMobile.releaseContext(contextHandle);
    }

    @Test
    public void testAllGrammarNames() {
        // Test all grammar names from the enum
        for (LlamaMobile.GrammarName grammarName : LlamaMobile.GrammarName.values()) {
            String grammarContent = LlamaMobile.grammarContent(appContext, grammarName);
            assertNotNull(grammarName.name() + " grammar should not be null", grammarContent);
            assertFalse(grammarName.name() + " grammar should not be empty", grammarContent.trim().isEmpty());
        }
    }

    @Test
    public void testMirostatParameterRange() {
        // Test different mirostat values (0, 1, 2)
        LlamaMobile.CompletionParams params0 = new LlamaMobile.CompletionParams(
                "Test mirostat 0: ",
                0.8f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                0, // mirostat 0
                5.0,
                0.1,
                false,
                0,
                null,
                null,
                null
        );
        
        LlamaMobile.CompletionParams params1 = new LlamaMobile.CompletionParams(
                "Test mirostat 1: ",
                0.8f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                1, // mirostat 1
                5.0,
                0.1,
                false,
                0,
                null,
                null,
                null
        );
        
        LlamaMobile.CompletionParams params2 = new LlamaMobile.CompletionParams(
                "Test mirostat 2: ",
                0.8f,
                100,
                4,
                -1,
                40,
                0.9,
                0.05,
                1.0,
                64,
                1.1,
                0.0,
                0.0,
                2, // mirostat 2
                5.0,
                0.1,
                false,
                0,
                null,
                null,
                null
        );
        
        assertEquals(0, params0.getMirostat());
        assertEquals(1, params1.getMirostat());
        assertEquals(2, params2.getMirostat());
        
        // Test completion generation fails with all these params (no valid context)
        assertNull(LlamaMobile.generateCompletion(0L, params0));
        assertNull(LlamaMobile.generateCompletion(0L, params1));
        assertNull(LlamaMobile.generateCompletion(0L, params2));
    }
}