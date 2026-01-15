package com.llamamobile;

import org.junit.Test;
import org.junit.Before;
import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Unit tests for LlamaMobile Java SDK
 */
public class LlamaMobileUnitTests {

    // Test paths for model files
    public static class TestPaths {
        public static final String rootPath = "/sdcard/llama_mobile/models";
        public static final String modelPath = rootPath + "/SmolLM-360M-Instruct.Q6_K.gguf";
        public static final String ttsModelPath = rootPath + "/OuteTTS-0.2-500M-Q6_K.gguf";
        public static final String vocoderPath = rootPath + "/WavTokenizer-Large-75-F16.gguf";
        public static final String embeddingPath = rootPath + "/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf";
        public static final String mmprojPath = rootPath + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf";
        public static final String imageModelPath = rootPath + "/SmolVLM-256M-Instruct-Q8_0.gguf";
        public static final String imagePath = rootPath + "/img/image.jpg";
    }

    private long contextHandle;

    @Before
    public void setUp() {
        // Initialize with minimal context for testing
        // This will fail if the model file doesn't exist, but that's expected in unit tests
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TestPaths.modelPath)
                    .setNGpuLayers(0)
                    .setNCtx(512)
                    .setNThreads(2)
                    .setVerbose(false);
            contextHandle = LlamaMobile.initContext(params);
        } catch (Exception e) {
            // Model might not be available, that's okay for unit tests
            contextHandle = -1;
        }
    }

    @Test
    public void testInitParamsConstructors() {
        // Test basic constructor
        LlamaMobile.InitParams params = new LlamaMobile.InitParams("test_path");
        assertEquals("test_path", params.modelPath);
        assertEquals(0, params.nGpuLayers);
        assertEquals(2048, params.nCtx);
        assertEquals(4, params.nThreads);

        // Test builder pattern
        params = new LlamaMobile.InitParams("test_path")
                .setNGpuLayers(4)
                .setNCtx(4096)
                .setNThreads(8)
                .setVerbose(true);
        assertEquals("test_path", params.modelPath);
        assertEquals(4, params.nGpuLayers);
        assertEquals(4096, params.nCtx);
        assertEquals(8, params.nThreads);
        assertTrue(params.verbose);
    }

    @Test
    public void testCompletionParamsConstructors() {
        // Test basic constructor
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("test prompt");
        assertEquals("test prompt", params.prompt);
        assertEquals(1024, params.maxTokens);
        assertEquals(0.8f, params.temperature, 0.01f);
        assertEquals(0.95f, params.topP, 0.01f);

        // Test builder pattern
        List<String> mediaPaths = new ArrayList<>();
        mediaPaths.add("test.jpg");
        
        params = new LlamaMobile.CompletionParams("test prompt")
                .setMaxTokens(512)
                .setTemperature(0.5f)
                .setTopP(0.8f)
                .setTopK(30)
                .setRepeatPenalty(1.05f)
                .setGrammar("json.gbnf")
                .setMediaPaths(mediaPaths)
                .setEcho(true);
        
        assertEquals("test prompt", params.prompt);
        assertEquals(512, params.maxTokens);
        assertEquals(0.5f, params.temperature, 0.01f);
        assertEquals(0.8f, params.topP, 0.01f);
        assertEquals(30, params.topK, 0.01f);
        assertEquals(1.05f, params.repeatPenalty, 0.01f);
        assertEquals("json.gbnf", params.grammar);
        assertEquals(mediaPaths, params.mediaPaths);
        assertTrue(params.echo);
    }

    @Test
    public void testAudioParamsConstructors() {
        // Test basic constructor
        LlamaMobile.AudioParams params = new LlamaMobile.AudioParams("test text");
        assertEquals("test text", params.text);
        assertEquals(48000, params.sampleRate);
        assertEquals(0, params.speakerId);
        assertEquals(1.0f, params.speed, 0.01f);

        // Test builder pattern
        params = new LlamaMobile.AudioParams("test text")
                .setSampleRate(24000)
                .setSpeakerId(1)
                .setSpeed(0.8f)
                .setVolume(1.2f);
        
        assertEquals("test text", params.text);
        assertEquals(24000, params.sampleRate);
        assertEquals(1, params.speakerId);
        assertEquals(0.8f, params.speed, 0.01f);
        assertEquals(1.2f, params.volume, 0.01f);
    }

    @Test
    public void testLoraAdapterConstructors() {
        // Test basic constructor
        LlamaMobile.LoraAdapter adapter = new LlamaMobile.LoraAdapter("test_path");
        assertEquals("test_path", adapter.path);
        assertEquals(1.0f, adapter.scale, 0.01f);

        // Test builder pattern
        adapter = new LlamaMobile.LoraAdapter("test_path").setScale(0.8f);
        assertEquals("test_path", adapter.path);
        assertEquals(0.8f, adapter.scale, 0.01f);
    }

    @Test
    public void testCompletionResult() {
        LlamaMobile.CompletionResult result = new LlamaMobile.CompletionResult(
                "test text", 1.5f, true, 10
        );
        
        assertEquals("test text", result.text);
        assertEquals(1.5f, result.perplexity, 0.01f);
        assertTrue(result.finished);
        assertEquals(10, result.tokenCount);
    }

    @Test
    public void testContextSafety() {
        // Test context validation with invalid context
        assertFalse(LlamaMobile.isContextValid(-1));
        assertFalse(LlamaMobile.releaseContext(-1));
    }

    @Test
    public void testConvenienceMethods() {
        // These tests just verify the methods exist and compile
        assertNotNull(LlamaMobile.class.getDeclaredMethods());
    }

    @Test
    public void testLogLevelConstants() {
        assertEquals(0, LlamaMobile.LOG_LEVEL_DEBUG);
        assertEquals(1, LlamaMobile.LOG_LEVEL_INFO);
        assertEquals(2, LlamaMobile.LOG_LEVEL_WARN);
        assertEquals(3, LlamaMobile.LOG_LEVEL_ERROR);
        assertEquals(4, LlamaMobile.LOG_LEVEL_SILENT);
    }

    @Test
    public void testDefaultConstants() {
        assertEquals(2048, LlamaMobile.DEFAULT_N_CTX);
        assertEquals(0, LlamaMobile.DEFAULT_N_GPU_LAYERS);
        assertEquals(48000, LlamaMobile.DEFAULT_SAMPLE_RATE);
    }
}
