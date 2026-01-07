package com.llamamobile;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.junit.MockitoJUnitRunner;

@RunWith(MockitoJUnitRunner.class)
public class LlamaMobileUnitTests {
    private static final String TEST_MODEL_PATH = "/path/to/test/model.gguf";
    private long mockContextHandle;

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
    public void testInitParamsCreation() {
        // Test creation of InitParams with default values
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(TEST_MODEL_PATH);
        assertEquals(TEST_MODEL_PATH, params.modelPath);
        assertEquals(512, params.nCtx);
        assertNull(params.chatTemplate);
        assertEquals(LlamaMobile.CacheType.MEMORY, params.cacheType);

        // Test creation of InitParams with custom values
        LlamaMobile.InitParams customParams = new LlamaMobile.InitParams(
                TEST_MODEL_PATH,
                2048,
                "custom_template",
                LlamaMobile.CacheType.NONE
        );
        assertEquals(2048, customParams.nCtx);
        assertEquals("custom_template", customParams.chatTemplate);
        assertEquals(LlamaMobile.CacheType.NONE, customParams.cacheType);
    }

    @Test
    public void testCompletionParamsCreation() {
        // Test creation of CompletionParams with default values
        String testPrompt = "Hello, world!";
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(testPrompt);
        assertEquals(testPrompt, params.prompt);
        assertEquals(0.8f, params.temperature, 0.01f);
        assertEquals(100, params.maxTokens);

        // Test creation of CompletionParams with custom values
        LlamaMobile.CompletionParams customParams = new LlamaMobile.CompletionParams(
                testPrompt,
                0.5f,
                200
        );
        assertEquals(0.5f, customParams.temperature, 0.01f);
        assertEquals(200, customParams.maxTokens);
    }

    @Test
    public void testCacheTypeEnum() {
        // Test that all enum values are present
        LlamaMobile.CacheType[] cacheTypes = LlamaMobile.CacheType.values();
        assertEquals(2, cacheTypes.length);
        assertEquals(LlamaMobile.CacheType.NONE, cacheTypes[0]);
        assertEquals(LlamaMobile.CacheType.MEMORY, cacheTypes[1]);
    }

    @Test
    public void testModelInitializationWithNullPath() {
        // Test that initializing with null model path fails gracefully
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(null);
            long handle = LlamaMobile.initContext(params);
            // Should return 0 for invalid path
            assertEquals(0L, handle);
        } catch (Exception e) {
            // Should not throw exception for null path
            fail("Initialization with null path should not throw exception");
        }
    }

    @Test
    public void testModelInitializationWithEmptyPath() {
        // Test that initializing with empty model path fails gracefully
        LlamaMobile.InitParams params = new LlamaMobile.InitParams("");
        long handle = LlamaMobile.initContext(params);
        // Should return 0 for invalid path
        assertEquals(0L, handle);
    }

    @Test
    public void testCompletionParamsWithEmptyPrompt() {
        // Test that CompletionParams with empty prompt is handled gracefully
        try {
            LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("");
            assertNotNull(params);
            assertEquals("", params.prompt);
        } catch (Exception e) {
            fail("CompletionParams with empty prompt should not throw exception");
        }
    }

    @Test
    public void testCompletionParamsWithNullPrompt() {
        // Test that CompletionParams with null prompt is handled gracefully
        try {
            LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams(null);
            assertNotNull(params);
            assertNull(params.prompt);
        } catch (Exception e) {
            fail("CompletionParams with null prompt should not throw exception");
        }
    }
}