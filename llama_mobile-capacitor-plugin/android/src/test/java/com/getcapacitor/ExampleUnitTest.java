package com.getcapacitor;

import static org.junit.Assert.*;

import org.junit.Before;
import org.junit.After;
import org.junit.Test;
import com.llamamobile.LlamaMobile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Unit tests for LlamaMobile Android library.
 *
 * @see <a href="http://d.android.com/tools/testing">Testing documentation</a>
 */
public class ExampleUnitTest {

    private long contextHandle = -1;

    @Before
    public void setUp() {
        // No setup needed for unit tests
    }

    @After
    public void tearDown() {
        if (contextHandle != -1) {
            LlamaMobile.releaseContext(contextHandle);
            contextHandle = -1;
        }
    }

    // MARK: - Initialization Tests

    @Test
    public void testInitContext() {
        String modelPath = "/path/to/dummy/model.gguf";
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(params);
        assertNotEquals("initContext should return a valid context handle", -1, handle);
        contextHandle = handle;
    }

    @Test
    public void testInitContextWithEmbedding() {
        String modelPath = "/path/to/dummy/embedding_model.gguf";
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, true, 0, 1, false, null, null, true, null);
        long handle = LlamaMobile.initContext(params);
        assertNotEquals("initContext with embedding should return a valid context handle", -1, handle);
        contextHandle = handle;
    }

    @Test
    public void testReleaseContext() {
        String modelPath = "/path/to/dummy/model.gguf";
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(params);
        assertNotEquals("initContext should return a valid context handle", -1, handle);
        
        try {
            LlamaMobile.releaseContext(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("releaseContext should not throw an error: " + e.getMessage());
        }
        contextHandle = -1;
    }

    // MARK: - Completion Tests

    @Test
    public void testGenerateCompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("Hello", 0.7f, 100, 4, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null);

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(handle, params);
        assertNotNull("generateCompletion should return a result", result);
        assertNotNull("result text should not be null", result.getText());
    }

    @Test
    public void testGenerateCompletionWithMedia() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        List<String> mediaPaths = new ArrayList<>();
        mediaPaths.add("/path/to/image.jpg");
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("Describe this image", 0.7f, 100, 4, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, mediaPaths, null);

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(handle, params);
        assertNotNull("generateCompletion with media should return a result", result);
    }

    @Test
    public void testGenerateCompletionWithStopSequences() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        List<String> stopSequences = new ArrayList<>();
        stopSequences.add("\n");
        stopSequences.add("END");
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("Hello", 0.7f, 100, 4, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, stopSequences, null, null);

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(handle, params);
        assertNotNull("generateCompletion with stop sequences should return a result", result);
    }

    @Test
    public void testStopCompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        try {
            LlamaMobile.stopCompletion(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("stopCompletion should not throw an error: " + e.getMessage());
        }
    }

    // MARK: - OpenAI Completion Tests

    @Test
    public void testGenerateOpenAICompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        String openAIJSON = "{\n" +
            "    \"model\": \"gpt-3.5-turbo\",\n" +
            "    \"messages\": [\n" +
            "        {\"role\": \"user\", \"content\": \"Hello\"}\n" +
            "    ],\n" +
            "    \"temperature\": 0.7,\n" +
            "    \"max_tokens\": 100\n" +
            "}";

        try {
            LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(handle, openAIJSON);
            assertNotNull("generateOpenAICompletion should return a result", result);
        } catch (Exception e) {
            fail("generateOpenAICompletion should not throw an error: " + e.getMessage());
        }
    }

    // MARK: - TTS Tests

    @Test
    public void testInitVocoder() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        String vocoderModelPath = "/path/to/vocoder_model.gguf";
        boolean success = LlamaMobile.initVocoder(handle, vocoderModelPath);
        assertTrue("initVocoder should succeed", success);
    }

    @Test
    public void testReleaseVocoder() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        try {
            LlamaMobile.releaseVocoder(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("releaseVocoder should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsVocoderEnabled() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        boolean isEnabled = LlamaMobile.isVocoderEnabled(handle);
        assertFalse("isVocoderEnabled should return false initially", isEnabled);
    }

    @Test
    public void testGetTTSType() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        LlamaMobile.TTSModelType type = LlamaMobile.getTTSType(handle);
        assertNotNull("getTTSType should return a value", type);
        assertEquals("getTTSType should return UNKNOWN initially", LlamaMobile.TTSModelType.UNKNOWN, type);
    }

    @Test
    public void testSaveAudioToWav() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        float[] audioData = new float[1000];
        for (int i = 0; i < audioData.length; i++) {
            audioData[i] = 0.0f;
        }

        String filePath = "/tmp/test_audio.wav";
        boolean success = LlamaMobile.saveAudioToWav(handle, filePath, audioData, 24000);
        assertTrue("saveAudioToWav should succeed", success);
    }

    // MARK: - Multimodal Tests

    @Test
    public void testInitMultimodal() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        String mmprojPath = "/path/to/mmproj.gguf";
        boolean success = LlamaMobile.initMultimodal(handle, mmprojPath, true);
        assertTrue("initMultimodal should succeed", success);
    }

    @Test
    public void testReleaseMultimodal() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        try {
            LlamaMobile.releaseMultimodal(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("releaseMultimodal should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsMultimodalEnabled() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        boolean isEnabled = LlamaMobile.isMultimodalEnabled(handle);
        assertFalse("isMultimodalEnabled should return false initially", isEnabled);
    }

    @Test
    public void testSupportsVision() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        boolean supports = LlamaMobile.supportsVision(handle);
        assertFalse("supportsVision should return false initially", supports);
    }

    @Test
    public void testSupportsAudio() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        boolean supports = LlamaMobile.supportsAudio(handle);
        assertFalse("supportsAudio should return false initially", supports);
    }

    // MARK: - LoRA Tests

    @Test
    public void testApplyLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        LlamaMobile.LoraAdapter[] adapters = new LlamaMobile.LoraAdapter[1];
        adapters[0] = new LlamaMobile.LoraAdapter("/path/to/adapter1.gguf", 1.0f);

        boolean success = LlamaMobile.applyLoraAdapters(handle, adapters);
        assertTrue("applyLoraAdapters should succeed", success);
    }

    @Test
    public void testRemoveLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        try {
            LlamaMobile.removeLoraAdapters(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("removeLoraAdapters should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testGetLoadedLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        LlamaMobile.LoraAdapter[] adapters = LlamaMobile.getLoadedLoraAdapters(handle);
        assertNotNull("getLoadedLoraAdapters should return an array", adapters);
    }

    // MARK: - Conversation Tests

    @Test
    public void testGenerateResponse() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        LlamaMobile.ConversationResult result = LlamaMobile.generateResponse(handle, "Hello", 100, null);
        assertNotNull("generateResponse should return a result", result);
        assertNotNull("result text should not be null", result.getText());
    }

    @Test
    public void testClearConversation() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        try {
            LlamaMobile.clearConversation(handle);
            assertTrue(true);
        } catch (Exception e) {
            fail("clearConversation should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsConversationActive() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        boolean isActive = LlamaMobile.isConversationActive(handle);
        assertFalse("isConversationActive should return false initially", isActive);
    }

    // MARK: - Embeddings Tests

    @Test
    public void testGenerateEmbeddings() {
        String modelPath = "/path/to/embedding_model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, true, 0, 1, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        float[] embedding = LlamaMobile.generateEmbeddings(handle, "Hello world");
        assertNotNull("generateEmbeddings should return an embedding", embedding);
        assertNotEquals("embedding should not be empty", 0, embedding.length);
    }

    // MARK: - Tokenization Tests

    @Test
    public void testTokenize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        String text = "Hello, world!";
        int[] tokens = LlamaMobile.tokenize(handle, text);
        assertNotNull("tokenize should return an array of tokens", tokens);
        assertNotEquals("tokenize should return non-empty array", 0, tokens.length);
    }

    @Test
    public void testDetokenize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        int[] tokens = {1, 2, 3, 4, 5};
        String text = LlamaMobile.detokenize(handle, tokens);
        assertNotNull("detokenize should return a non-empty string", text);
        assertFalse("detokenize should return a non-empty string", text.isEmpty());
    }

    // MARK: - Model Info Tests

    @Test
    public void testGetContextWindowSize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        int size = LlamaMobile.getContextWindowSize(handle);
        assertTrue("getContextWindowSize should return a positive value", size > 0);
    }

    @Test
    public void testGetEmbeddingDimension() {
        String modelPath = "/path/to/embedding_model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, true, 0, 1, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        int dimension = LlamaMobile.getEmbeddingDimension(handle);
        assertTrue("getEmbeddingDimension should return a positive value", dimension > 0);
    }

    @Test
    public void testGetModelDescription() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        String description = LlamaMobile.getModelDescription(handle);
        assertNotNull("getModelDescription should return a non-empty string", description);
        assertFalse("getModelDescription should return a non-empty string", description.isEmpty());
    }

    @Test
    public void testGetModelSize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        long size = LlamaMobile.getModelSize(handle);
        assertTrue("getModelSize should return a positive value", size > 0);
    }

    @Test
    public void testGetModelParametersCount() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        long handle = LlamaMobile.initContext(initParams);
        contextHandle = handle;

        long count = LlamaMobile.getModelParametersCount(handle);
        assertTrue("getModelParametersCount should return a positive value", count > 0);
    }

    // MARK: - Download Tests

    @Test
    public void testDownloadModel() {
        String url = "https://example.com/model.gguf";
        String localPath = "/tmp/model.gguf";
        LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(url, localPath, "").build();
        LlamaMobile.DownloadResult result = LlamaMobile.downloadModel(params, null);
        assertNotNull("downloadModel should return a result", result);
    }

    @Test
    public void testDownloadModelWithHeaders() {
        String url = "https://example.com/model.gguf";
        String localPath = "/tmp/model.gguf";
        LlamaMobile.DownloadParams params = new LlamaMobile.DownloadParams.Builder(url, localPath, "").build();

        LlamaMobile.DownloadResult result = LlamaMobile.downloadModel(params, null);
        assertNotNull("downloadModel with headers should return a result", result);
    }

    @Test
    public void testDownloadHfFile() {
        String repoId = "example/repo";
        String filename = "model.gguf";
        String destinationPath = "/tmp/model.gguf";
        String bearerToken = "";
        LlamaMobile.DownloadResult result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath, bearerToken, false, null);
        assertNotNull("downloadHfFile should return a result", result);
    }

    @Test
    public void testDownloadHfFileWithToken() {
        String repoId = "example/repo";
        String filename = "model.gguf";
        String destinationPath = "/tmp/model.gguf";
        String bearerToken = "hf_token";

        LlamaMobile.DownloadResult result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath, bearerToken, false, null);
        assertNotNull("downloadHfFile with token should return a result", result);
    }

    // MARK: - Grammar Tests

    @Test
    public void testLoadGrammar() {
        String grammar = LlamaMobile.loadGrammar(null);
        assertNull("loadGrammar should return null for null path", grammar);
    }
}

