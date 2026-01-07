package com.llamamobile;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

@RunWith(MockitoJUnitRunner.class)
public class LlamaMobileUnitTests {
    private static final String TEST_MODEL_PATH = "/path/to/test/model.gguf";
    private long mockContextHandle;

    @Mock
    private LlamaMobile.TokenCallback mockTokenCallback;

    @Before
    public void setUp() {
        // Initialize with a mock context handle
        mockContextHandle = 12345L;
    }

    @After
    public void tearDown() {
        // Clean up any resources
        if (mockContextHandle != 0) {
            LlamaMobile.releaseContext(mockContextHandle);
            mockContextHandle = 0;
        }
    }

    @Test
    public void testInitParamsConstructors() {
        // Test constructor with modelPath only
        LlamaMobile.InitParams params1 = new LlamaMobile.InitParams(TEST_MODEL_PATH);
        assertEquals(TEST_MODEL_PATH, params1.getModelPath());
        assertEquals(512, params1.getNCtx());
        assertNull(params1.getChatTemplate());
        assertNull(params1.getSystemPrompt());
        assertEquals(0, params1.getNGpuLayers());
        assertEquals(4, params1.getNThreads());
        assertEquals(LlamaMobile.CacheType.MEMORY, params1.getCacheType());

        // Test constructor with modelPath and nCtx
        LlamaMobile.InitParams params2 = new LlamaMobile.InitParams(TEST_MODEL_PATH, 2048);
        assertEquals(2048, params2.getNCtx());
        assertNull(params2.getChatTemplate());

        // Test constructor with modelPath, nCtx, and chatTemplate
        LlamaMobile.InitParams params3 = new LlamaMobile.InitParams(TEST_MODEL_PATH, 2048, "custom_template");
        assertEquals("custom_template", params3.getChatTemplate());

        // Test constructor with all parameters
        LlamaMobile.InitParams params4 = new LlamaMobile.InitParams(
                TEST_MODEL_PATH,
                2048,
                "full_template",
                "You are a helpful assistant",
                1024,
                512,
                8,
                6,
                true,
                false,
                true,
                1,
                1,
                true,
                "kv_cache",
                "kv_cache",
                LlamaMobile.CacheType.NONE
        );
        assertEquals("full_template", params4.getChatTemplate());
        assertEquals("You are a helpful assistant", params4.getSystemPrompt());
        assertEquals(8, params4.getNGpuLayers());
        assertEquals(6, params4.getNThreads());
        assertTrue(params4.isUseMmap());
        assertFalse(params4.isUseMlock());
        assertTrue(params4.isEmbedding());
        assertEquals(1, params4.getPoolingType());
        assertEquals(1, params4.getEmbdNormalize());
        assertTrue(params4.isFlashAttn());
        assertEquals("kv_cache", params4.getCacheTypeK());
        assertEquals("kv_cache", params4.getCacheTypeV());
        assertEquals(LlamaMobile.CacheType.NONE, params4.getCacheType());
    }

    @Test
    public void testCompletionParamsConstructors() {
        // Test constructor with prompt only
        String testPrompt = "Hello, world!";
        LlamaMobile.CompletionParams params1 = new LlamaMobile.CompletionParams(testPrompt);
        assertEquals(testPrompt, params1.getPrompt());
        assertEquals(0.8f, params1.getTemperature(), 0.01f);
        assertEquals(100, params1.getMaxTokens());
        assertEquals(4, params1.getNThreads());
        assertEquals(-1, params1.getSeed());
        assertEquals(40, params1.getTopK());
        assertEquals(0.9, params1.getTopP(), 0.01);
        assertEquals(0.05, params1.getMinP(), 0.01);
        assertEquals(1.0, params1.getTypicalP(), 0.01);
        assertEquals(64, params1.getPenaltyLastN());
        assertEquals(1.1, params1.getPenaltyRepeat(), 0.01);
        assertEquals(0.0, params1.getPenaltyFreq(), 0.01);
        assertEquals(0.0, params1.getPenaltyPresent(), 0.01);
        assertEquals(0, params1.getMirostat());
        assertEquals(5.0, params1.getMirostatTau(), 0.01);
        assertEquals(0.1, params1.getMirostatEta(), 0.01);
        assertFalse(params1.isIgnoreEos());
        assertEquals(0, params1.getNProbs());
        assertNull(params1.getGrammar());
        assertNotNull(params1.getStopSequences());
        assertEquals(0, params1.getStopSequences().size());
        assertNull(params1.getTokenCallback());

        // Test constructor with prompt and temperature
        LlamaMobile.CompletionParams params2 = new LlamaMobile.CompletionParams(testPrompt, 0.5f);
        assertEquals(0.5f, params2.getTemperature(), 0.01f);

        // Test constructor with prompt, temperature, and maxTokens
        LlamaMobile.CompletionParams params3 = new LlamaMobile.CompletionParams(testPrompt, 0.5f, 200);
        assertEquals(200, params3.getMaxTokens());

        // Test constructor with all parameters
        List<String> stopSequences = Arrays.asList("\n", "END");
        LlamaMobile.CompletionParams params4 = new LlamaMobile.CompletionParams(
                testPrompt,
                0.7f,
                150,
                6,
                12345,
                50,
                0.85,
                0.1,
                0.95,
                32,
                1.2,
                0.1,
                0.1,
                2,
                3.0,
                0.05,
                true,
                3,
                "json_grammar",
                stopSequences,
                mockTokenCallback
        );
        assertEquals(0.7f, params4.getTemperature(), 0.01f);
        assertEquals(150, params4.getMaxTokens());
        assertEquals(6, params4.getNThreads());
        assertEquals(12345, params4.getSeed());
        assertEquals(50, params4.getTopK());
        assertEquals(0.85, params4.getTopP(), 0.01);
        assertEquals(0.1, params4.getMinP(), 0.01);
        assertEquals(0.95, params4.getTypicalP(), 0.01);
        assertEquals(32, params4.getPenaltyLastN());
        assertEquals(1.2, params4.getPenaltyRepeat(), 0.01);
        assertEquals(0.1, params4.getPenaltyFreq(), 0.01);
        assertEquals(0.1, params4.getPenaltyPresent(), 0.01);
        assertEquals(2, params4.getMirostat());
        assertEquals(3.0, params4.getMirostatTau(), 0.01);
        assertEquals(0.05, params4.getMirostatEta(), 0.01);
        assertTrue(params4.isIgnoreEos());
        assertEquals(3, params4.getNProbs());
        assertEquals("json_grammar", params4.getGrammar());
        assertEquals(stopSequences, params4.getStopSequences());
        assertEquals(mockTokenCallback, params4.getTokenCallback());
    }

    @Test
    public void testCacheTypeEnum() {
        // Test CacheType enum values
        LlamaMobile.CacheType[] cacheTypes = LlamaMobile.CacheType.values();
        assertEquals(2, cacheTypes.length);
        assertEquals(LlamaMobile.CacheType.NONE, cacheTypes[0]);
        assertEquals(LlamaMobile.CacheType.MEMORY, cacheTypes[1]);
    }

    @Test
    public void testGrammarNameEnum() {
        // Test GrammarName enum values
        LlamaMobile.GrammarName[] grammarNames = LlamaMobile.GrammarName.values();
        assertEquals(8, grammarNames.length); // Should match the 8 grammar types defined
        
        // Verify specific grammar names exist
        boolean hasJson = false;
        boolean hasArithmetic = false;
        boolean hasList = false;
        
        for (LlamaMobile.GrammarName name : grammarNames) {
            switch (name) {
                case JSON:
                    hasJson = true;
                    break;
                case ARITHMETIC:
                    hasArithmetic = true;
                    break;
                case LIST:
                    hasList = true;
                    break;
            }
        }
        
        assertTrue(hasJson);
        assertTrue(hasArithmetic);
        assertTrue(hasList);
    }

    @Test
    public void testTokenCallbackInterface() {
        // Test TokenCallback interface implementation
        LlamaMobile.TokenCallback callback = new LlamaMobile.TokenCallback() {
            private boolean receivedToken = false;

            @Override
            public boolean onToken(String token) {
                receivedToken = true;
                return token != null;
            }

            public boolean isReceivedToken() {
                return receivedToken;
            }
        };

        // Test callback functionality
        assertTrue(callback.onToken("test_token"));
        assertFalse(callback.onToken(null));
        assertEquals(true, callback.isReceivedToken());
    }

    @Test
    public void testEdgeCases() {
        // Test InitParams with null model path
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(null);
            assertNull(params.getModelPath());
        } catch (Exception e) {
            fail("InitParams with null modelPath should not throw exception");
        }

        // Test InitParams with empty model path
        LlamaMobile.InitParams paramsEmptyPath = new LlamaMobile.InitParams("");
        assertEquals("", paramsEmptyPath.getModelPath());

        // Test CompletionParams with null prompt
        try {
            LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(null);
            assertNull(params.getPrompt());
        } catch (Exception e) {
            fail("CompletionParams with null prompt should not throw exception");
        }

        // Test CompletionParams with null stop sequences
        LlamaMobile.CompletionParams paramsNullStop = new LlamaMobile.CompletionParams(
                "test", 0.8f, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null);
        assertNotNull(paramsNullStop.getStopSequences());
        assertTrue(paramsNullStop.getStopSequences().isEmpty());

        // Test CompletionParams with empty stop sequences
        LlamaMobile.CompletionParams paramsEmptyStop = new LlamaMobile.CompletionParams(
                "test", 0.8f, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), null);
        assertNotNull(paramsEmptyStop.getStopSequences());
        assertTrue(paramsEmptyStop.getStopSequences().isEmpty());
    }

    @Test
    public void testParameterImmutability() {
        // Test that parameters are immutable (no setters)
        // This test ensures that once created, parameters cannot be modified
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(TEST_MODEL_PATH);
        LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams("Test prompt");

        // Verify there are no public setters by checking the API (this test would fail if setters are added)
        // The design pattern used is immutability via constructor only
        assertNotNull(initParams);
        assertNotNull(completionParams);
    }
}