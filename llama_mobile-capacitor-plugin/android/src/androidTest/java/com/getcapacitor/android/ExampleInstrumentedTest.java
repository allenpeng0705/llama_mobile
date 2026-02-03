package com.getcapacitor.android;

import static org.junit.Assert.*;

import android.content.Context;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.platform.app.InstrumentationRegistry;

import com.llamamobile.LlamaMobile;
import com.llamamobile.capacitorplugin.LlamaMobileCapacitorPlugin;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RunWith(AndroidJUnit4.class)
public class ExampleInstrumentedTest {

    private LlamaMobileCapacitorPlugin plugin;
    private long contextHandle = -1;

    @Before
    public void setUp() {
        plugin = new LlamaMobileCapacitorPlugin();
    }

    @After
    public void tearDown() {
        if (contextHandle != -1) {
            LlamaMobile.releaseContext(contextHandle);
        }
    }

    // MARK: - Initialization Tests

    @Test
    public void testInitContext() {
        String modelPath = "/path/to/dummy/model.gguf";
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(params);
        assertNotEquals("initContext should return a valid context handle", -1, contextHandle);
    }

    @Test
    public void testInitContextWithEmbedding() {
        String modelPath = "/path/to/dummy/embedding_model.gguf";
        LlamaMobile.InitParams params = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, true, 0, 1
        );
        contextHandle = LlamaMobile.initContext(params);
        assertNotEquals("initContext with embedding should return a valid context handle", -1, contextHandle);
    }

    @Test
    public void testReleaseContext() {
        long handle = 1;
        try {
            LlamaMobile.releaseContext(handle);
        } catch (Exception e) {
            fail("releaseContext should not throw an error: " + e.getMessage());
        }
    }

    // MARK: - Completion Tests

    @Test
    public void testGenerateCompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams();
        params.prompt = "Hello";
        params.temperature = 0.7;
        params.maxTokens = 100;
        params.nThreads = 4;

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
        assertNotNull("generateCompletion should return a result", result);
        assertNotNull("result text should not be null", result.text);
    }

    @Test
    public void testGenerateCompletionWithMedia() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams();
        params.prompt = "Describe this image";
        params.temperature = 0.7;
        params.maxTokens = 100;
        params.nThreads = 4;
        params.mediaPaths = new ArrayList<>();
        params.mediaPaths.add("/path/to/image.jpg");

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
        assertNotNull("generateCompletion with media should return a result", result);
    }

    @Test
    public void testGenerateCompletionWithStopSequences() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams();
        params.prompt = "Hello";
        params.temperature = 0.7;
        params.maxTokens = 100;
        params.nThreads = 4;
        params.stopSequences = new ArrayList<>();
        params.stopSequences.add("\n");
        params.stopSequences.add("END");

        LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, params);
        assertNotNull("generateCompletion with stop sequences should return a result", result);
    }

    @Test
    public void testStopCompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        try {
            LlamaMobile.stopCompletion(contextHandle);
        } catch (Exception e) {
            fail("stopCompletion should not throw an error: " + e.getMessage());
        }
    }

    // MARK: - OpenAI Completion Tests

    @Test
    public void testGenerateOpenAICompletion() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String openAIJSON = "{\n" +
            "    \"model\": \"gpt-3.5-turbo\",\n" +
            "    \"messages\": [\n" +
            "        {\"role\": \"user\", \"content\": \"Hello\"}\n" +
            "    ],\n" +
            "    \"temperature\": 0.7,\n" +
            "    \"max_tokens\": 100\n" +
            "}";

        LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON);
        assertNotNull("generateOpenAICompletion should return a result", result);
    }

    @Test
    public void testGenerateOpenAICompletionWithGrammar() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String openAIJSON = "{\n" +
            "    \"model\": \"gpt-3.5-turbo\",\n" +
            "    \"messages\": [\n" +
            "        {\"role\": \"user\", \"content\": \"Generate a JSON object\"}\n" +
            "    ],\n" +
            "    \"temperature\": 0.7,\n" +
            "    \"max_tokens\": 100\n" +
            "}";

        String grammar = LlamaMobile.getJsonGrammar();
        LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON, grammar);
        assertNotNull("generateOpenAICompletion with grammar should return a result", result);
    }

    // MARK: - TTS Tests

    @Test
    public void testInitVocoder() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String vocoderModelPath = "/path/to/vocoder_model.gguf";
        Map<String, Object> result = LlamaMobile.initVocoder(contextHandle, vocoderModelPath);
        assertNotNull("initVocoder should return a result", result);
        assertTrue("initVocoder should succeed", (Boolean) result.get("success"));
    }

    @Test
    public void testReleaseVocoder() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        try {
            LlamaMobile.releaseVocoder(contextHandle);
        } catch (Exception e) {
            fail("releaseVocoder should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsVocoderEnabled() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        boolean isEnabled = LlamaMobile.isVocoderEnabled(contextHandle);
        assertFalse("isVocoderEnabled should return false initially", isEnabled);
    }

    @Test
    public void testGetTTSType() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String ttsType = LlamaMobile.getTTSType(contextHandle);
        assertEquals("getTTSType should return NONE initially", "NONE", ttsType);
    }

    @Test
    public void testGenerateAudioFromText() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        Map<String, Object> result = LlamaMobile.generateAudioFromText(contextHandle, "Hello world");
        assertNotNull("generateAudioFromText should return audio data", result);
        assertNotNull("audio data should not be null", result.get("audio"));
    }

    @Test
    public void testGenerateAudioFromTextWithSpeakerJson() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String speakerJson = "{\n" +
            "    \"speaker\": \"default\",\n" +
            "    \"speed\": 1.0\n" +
            "}";

        Map<String, Object> result = LlamaMobile.generateAudioFromText(contextHandle, "Hello world", speakerJson);
        assertNotNull("generateAudioFromText with speaker json should return audio data", result);
    }

    @Test
    public void testSaveAudioToWav() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        List<Float> audioData = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            audioData.add(0.0f);
        }

        String filePath = "/tmp/test_audio.wav";
        boolean success = LlamaMobile.saveAudioToWav(contextHandle, filePath, audioData, 24000);
        assertTrue("saveAudioToWav should succeed", success);
    }

    @Test
    public void testPlayAudio() {
        List<Float> audioData = new ArrayList<>();
        for (int i = 0; i < 1000; i++) {
            audioData.add(0.1f);
        }

        boolean success = LlamaMobile.playAudio(audioData, 24000);
        assertTrue("playAudio should succeed", success);
    }

    // MARK: - Multimodal Tests

    @Test
    public void testInitMultimodal() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String mmprojPath = "/path/to/mmproj.gguf";
        boolean success = LlamaMobile.initMultimodal(contextHandle, mmprojPath, true);
        assertTrue("initMultimodal should succeed", success);
    }

    @Test
    public void testReleaseMultimodal() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        try {
            LlamaMobile.releaseMultimodal(contextHandle);
        } catch (Exception e) {
            fail("releaseMultimodal should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsMultimodalEnabled() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        boolean isEnabled = LlamaMobile.isMultimodalEnabled(contextHandle);
        assertFalse("isMultimodalEnabled should return false initially", isEnabled);
    }

    @Test
    public void testSupportsVision() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        boolean supports = LlamaMobile.supportsVision(contextHandle);
        assertFalse("supportsVision should return false initially", supports);
    }

    @Test
    public void testSupportsAudio() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        boolean supports = LlamaMobile.supportsAudio(contextHandle);
        assertFalse("supportsAudio should return false initially", supports);
    }

    // MARK: - LoRA Tests

    @Test
    public void testApplyLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        List<Map<String, Object>> adapters = new ArrayList<>();
        Map<String, Object> adapter1 = new HashMap<>();
        adapter1.put("path", "/path/to/adapter1.gguf");
        adapter1.put("scale", 1.0);
        adapters.add(adapter1);

        boolean success = LlamaMobile.applyLoraAdapters(contextHandle, adapters);
        assertTrue("applyLoraAdapters should succeed", success);
    }

    @Test
    public void testRemoveLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        try {
            LlamaMobile.removeLoraAdapters(contextHandle);
        } catch (Exception e) {
            fail("removeLoraAdapters should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testGetLoadedLoraAdapters() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        List<Map<String, Object>> adapters = LlamaMobile.getLoadedLoraAdapters(contextHandle);
        assertNotNull("getLoadedLoraAdapters should return an array", adapters);
    }

    // MARK: - Conversation Tests

    @Test
    public void testGenerateResponse() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        Map<String, Object> result = LlamaMobile.generateResponse(contextHandle, "Hello", 100);
        assertNotNull("generateResponse should return a result", result);
        assertNotNull("result text should not be null", result.get("text"));
        assertTrue("timeToFirstToken should be positive", (Long) result.get("timeToFirstToken") > 0);
        assertTrue("totalTime should be positive", (Long) result.get("totalTime") > 0);
        assertTrue("tokensGenerated should be positive", (Integer) result.get("tokensGenerated") > 0);
    }

    @Test
    public void testClearConversation() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        try {
            LlamaMobile.clearConversation(contextHandle);
        } catch (Exception e) {
            fail("clearConversation should not throw an error: " + e.getMessage());
        }
    }

    @Test
    public void testIsConversationActive() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        boolean isActive = LlamaMobile.isConversationActive(contextHandle);
        assertFalse("isConversationActive should return false initially", isActive);
    }

    // MARK: - Embeddings Tests

    @Test
    public void testGenerateEmbeddings() {
        String modelPath = "/path/to/embedding_model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, true, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        List<Float> embedding = LlamaMobile.generateEmbeddings(contextHandle, "Hello world");
        assertNotNull("generateEmbeddings should return an embedding", embedding);
        assertFalse("embedding should not be empty", embedding.isEmpty());
    }

    // MARK: - Tokenization Tests

    @Test
    public void testTokenize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String text = "Hello, world!";
        List<Integer> tokens = LlamaMobile.tokenize(contextHandle, text);
        assertFalse("tokenize should return an array of tokens", tokens.isEmpty());
    }

    @Test
    public void testDetokenize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        List<Integer> tokens = new ArrayList<>();
        tokens.add(1);
        tokens.add(2);
        tokens.add(3);
        tokens.add(4);
        tokens.add(5);

        String text = LlamaMobile.detokenize(contextHandle, tokens);
        assertFalse("detokenize should return a non-empty string", text.isEmpty());
    }

    // MARK: - Model Info Tests

    @Test
    public void testGetContextWindowSize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        int size = LlamaMobile.getContextWindowSize(contextHandle);
        assertTrue("getContextWindowSize should return a positive value", size > 0);
    }

    @Test
    public void testGetEmbeddingDimension() {
        String modelPath = "/path/to/embedding_model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, true, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        int dimension = LlamaMobile.getEmbeddingDimension(contextHandle);
        assertTrue("getEmbeddingDimension should return a positive value", dimension > 0);
    }

    @Test
    public void testGetModelDescription() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String description = LlamaMobile.getModelDescription(contextHandle);
        assertFalse("getModelDescription should return a non-empty string", description.isEmpty());
    }

    @Test
    public void testGetModelSize() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        long size = LlamaMobile.getModelSize(contextHandle);
        assertTrue("getModelSize should return a positive value", size > 0);
    }

    @Test
    public void testGetModelParametersCount() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        long count = LlamaMobile.getModelParametersCount(contextHandle);
        assertTrue("getModelParametersCount should return a positive value", count > 0);
    }

    @Test
    public void testListFiles() {
        String directoryPath = "/path/to/models";
        Map<String, Object> result = LlamaMobile.listFiles(directoryPath);
        assertNotNull("listFiles should return a result", result);
        assertNotNull("result files should not be null", result.get("files"));
    }

    @Test
    public void testListModels() {
        Map<String, Object> result = LlamaMobile.listModels();
        assertNotNull("listModels should return a result", result);
        assertNotNull("result modelFiles should not be null", result.get("modelFiles"));
    }

    // MARK: - Download Tests

    @Test
    public void testDownloadModel() {
        String url = "https://example.com/model.gguf";
        String localPath = "/tmp/model.gguf";
        Map<String, Object> result = LlamaMobile.downloadModel(url, localPath);
        assertNotNull("downloadModel should return a result", result);
        assertTrue("downloadModel should succeed", (Boolean) result.get("success"));
    }

    @Test
    public void testDownloadModelWithHeaders() {
        String url = "https://example.com/model.gguf";
        String localPath = "/tmp/model.gguf";
        Map<String, String> headers = new HashMap<>();
        headers.put("Authorization", "Bearer token");

        Map<String, Object> result = LlamaMobile.downloadModel(url, localPath, headers);
        assertNotNull("downloadModel with headers should return a result", result);
    }

    @Test
    public void testDownloadHfFile() {
        String repoId = "example/repo";
        String filename = "model.gguf";
        String destinationPath = "/tmp/model.gguf";
        Map<String, Object> result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath);
        assertNotNull("downloadHfFile should return a result", result);
        assertTrue("downloadHfFile should succeed", (Boolean) result.get("success"));
    }

    @Test
    public void testDownloadHfFileWithToken() {
        String repoId = "example/repo";
        String filename = "model.gguf";
        String destinationPath = "/tmp/model.gguf";
        String bearerToken = "hf_token";

        Map<String, Object> result = LlamaMobile.downloadHfFile(repoId, filename, destinationPath, bearerToken);
        assertNotNull("downloadHfFile with token should return a result", result);
    }

    // MARK: - Grammar Tests

    @Test
    public void testGetJsonGrammar() {
        String grammar = LlamaMobile.getJsonGrammar();
        assertFalse("getJsonGrammar should return a non-empty string", grammar.isEmpty());
    }

    @Test
    public void testGetArithmeticGrammar() {
        String grammar = LlamaMobile.getArithmeticGrammar();
        assertFalse("getArithmeticGrammar should return a non-empty string", grammar.isEmpty());
    }

    @Test
    public void testGetCGrammar() {
        String grammar = LlamaMobile.getCGrammar();
        assertFalse("getCGrammar should return a non-empty string", grammar.isEmpty());
    }

    // MARK: - Chat Tests

    @Test
    public void testSetChatTemplate() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String chatTemplate = "{{.System}}{{.User}}{{.Assistant}}";
        boolean success = LlamaMobile.setChatTemplate(contextHandle, chatTemplate);
        assertTrue("setChatTemplate should succeed", success);
    }

    @Test
    public void testGetModelChatTemplate() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String chatTemplate = LlamaMobile.getModelChatTemplate(contextHandle);
        assertNotNull("getModelChatTemplate should return a template", chatTemplate);
    }

    @Test
    public void testFormatChatMessages() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String messagesJson = "[\n" +
            "    {\"role\": \"user\", \"content\": \"Hello\"},\n" +
            "    {\"role\": \"assistant\", \"content\": \"Hi there!\"}\n" +
            "]";

        String result = LlamaMobile.formatChatMessages(contextHandle, messagesJson);
        assertNotNull("formatChatMessages should return a formatted prompt", result);
        assertFalse("formatted prompt should not be empty", result.isEmpty());
    }

    @Test
    public void testFormatChatMessagesWithCustomTemplate() {
        String modelPath = "/path/to/model.gguf";
        LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
            modelPath, 2048, 0, 4, false, 0, 1
        );
        contextHandle = LlamaMobile.initContext(initParams);

        String messagesJson = "[\n" +
            "    {\"role\": \"user\", \"content\": \"Hello\"}\n" +
            "]";

        String customTemplate = "User: {{.User}}\\nAssistant: {{.Assistant}}";
        String result = LlamaMobile.formatChatMessages(contextHandle, messagesJson, customTemplate);
        assertNotNull("formatChatMessages with custom template should return a formatted prompt", result);
        assertFalse("formatted prompt should not be empty", result.isEmpty());
    }
}
