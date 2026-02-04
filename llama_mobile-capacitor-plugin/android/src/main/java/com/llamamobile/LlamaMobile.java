package com.llamamobile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.json.JSONObject;
import org.json.JSONArray;
import android.os.Handler;
import android.os.Looper;

/**
 * LlamaMobile Android Library
 *
 * This class provides a Java wrapper around the llama_mobile C library,
 * allowing Android applications to interact with llama models.
 *
 * This is the core Java implementation that both Java and Kotlin developers can use.
 * Kotlin developers can also use the Kotlin extensions in LlamaMobileKt.kt for
 * a more idiomatic Kotlin API with DSL support and coroutines.
 */
public class LlamaMobile {
    /**
     * Error types for LlamaMobile operations
     */
    public enum ErrorType {
        CONTEXT_NOT_INITIALIZED,
        INVALID_PARAMETER,
        OPERATION_FAILED,
        VOCODER_NOT_INITIALIZED,
        MULTIMODAL_NOT_INITIALIZED,
        MEDIA_PROCESSING_FAILED,
        TOKENIZATION_FAILED,
        DETOKENIZATION_FAILED,
        EMBEDDING_GENERATION_FAILED,
        AUDIO_GENERATION_FAILED,
        CONVERSATION_FAILED
    }

    /**
     * Text-to-Speech model types
     */
    public enum TTSModelType {
        UNKNOWN,
        OUT_ETTS_V02,
        OUT_ETTS_V03;
        
        public static TTSModelType fromInt(int value) {
            switch (value) {
                case 1: return OUT_ETTS_V02;
                case 2: return OUT_ETTS_V03;
                default: return UNKNOWN;
            }
        }
    }
    
    /**
     * Method used for TTS generation
     */
    public enum TTSMethod {
        BUILT_IN,
        CUSTOM_WORKFLOW
    }
    
    /**
     * TTS configuration options
     */
    public static class TTSOptions {
        private final int sampleRate;
        private final String voice;
        private final float speed;
        private final boolean saveToFile;
        private final String outputFilePath;

        public TTSOptions() {
            this(24000, null, 1.0f, false, null);
        }

        public TTSOptions(int sampleRate, String voice, float speed, boolean saveToFile, String outputFilePath) {
            this.sampleRate = sampleRate;
            this.voice = voice;
            this.speed = speed;
            this.saveToFile = saveToFile;
            this.outputFilePath = outputFilePath;
        }

        public int getSampleRate() { return sampleRate; }
        public String getVoice() { return voice; }
        public float getSpeed() { return speed; }
        public boolean isSaveToFile() { return saveToFile; }
        public String getOutputFilePath() { return outputFilePath; }

        public static class Builder {
            private int sampleRate = 24000;
            private String voice = null;
            private float speed = 1.0f;
            private boolean saveToFile = false;
            private String outputFilePath = null;

            public Builder() {}

            public Builder sampleRate(int sampleRate) {
                this.sampleRate = sampleRate;
                return this;
            }

            public Builder voice(String voice) {
                this.voice = voice;
                return this;
            }

            public Builder speed(float speed) {
                this.speed = speed;
                return this;
            }

            public Builder saveToFile(boolean saveToFile) {
                this.saveToFile = saveToFile;
                return this;
            }

            public Builder outputFilePath(String outputFilePath) {
                this.outputFilePath = outputFilePath;
                return this;
            }

            public TTSOptions build() {
                return new TTSOptions(sampleRate, voice, speed, saveToFile, outputFilePath);
            }
        }
    }
    
    /**
     * Result of successful speech generation
     */
    public static class SpeechResult {
        private final short[] audioSamples;
        private final int sampleRate;
        private final double duration;
        private final String outputFilePath;
        private final TTSMethod methodUsed;

        public SpeechResult(short[] audioSamples, int sampleRate, double duration, String outputFilePath, TTSMethod methodUsed) {
            this.audioSamples = audioSamples;
            this.sampleRate = sampleRate;
            this.duration = duration;
            this.outputFilePath = outputFilePath;
            this.methodUsed = methodUsed;
        }

        public short[] getAudioSamples() { return audioSamples; }
        public int getSampleRate() { return sampleRate; }
        public double getDuration() { return duration; }
        public String getOutputFilePath() { return outputFilePath; }
        public TTSMethod getMethodUsed() { return methodUsed; }
    }
    
    /**
     * Metadata for speech generation (used in streaming)
     */
    public static class SpeechMetadata {
        private final int sampleRate;
        private final double duration;
        private final TTSMethod methodUsed;
        private final String outputFilePath;

        public SpeechMetadata(int sampleRate, double duration, TTSMethod methodUsed, String outputFilePath) {
            this.sampleRate = sampleRate;
            this.duration = duration;
            this.methodUsed = methodUsed;
            this.outputFilePath = outputFilePath;
        }

        public int getSampleRate() { return sampleRate; }
        public double getDuration() { return duration; }
        public TTSMethod getMethodUsed() { return methodUsed; }
        public String getOutputFilePath() { return outputFilePath; }
    }
    
    /**
     * Error types for TTS operations
     */
    public static class TTSError extends Exception {
        private TTSError(String message) {
            super(message);
        }

        public static TTSError noModelLoaded() {
            return new TTSError("No model loaded");
        }

        public static TTSError noVocoderEnabled() {
            return new TTSError("No vocoder enabled");
        }

        public static TTSError invalidText() {
            return new TTSError("Invalid text");
        }

        public static TTSError generationFailed() {
            return new TTSError("Generation failed");
        }

        public static TTSError formattingFailed() {
            return new TTSError("Formatting failed");
        }

        public static TTSError tokenizationFailed() {
            return new TTSError("Tokenization failed");
        }

        public static TTSError audioDecodingFailed() {
            return new TTSError("Audio decoding failed");
        }

        public static TTSError fileSaveFailed() {
            return new TTSError("File save failed");
        }

        public static TTSError unknownError(String message) {
            return new TTSError(message);
        }
    }
    
    /**
     * Cache type enum
     */
    public enum CacheType {
        NONE,
        MEMORY
    }

    /**
     * Chat message structure for structured input
     */
    public static class ChatMessage {
        private final String role;
        private final String content;
        private final String reasoningContent;
        private final String toolName;
        private final String toolCallId;

        public ChatMessage(String role, String content) {
            this(role, content, null, null, null);
        }

        public ChatMessage(String role, String content, String reasoningContent, String toolName, String toolCallId) {
            this.role = role;
            this.content = content;
            this.reasoningContent = reasoningContent;
            this.toolName = toolName;
            this.toolCallId = toolCallId;
        }

        public String getRole() {
            return role;
        }

        public String getContent() {
            return content;
        }

        public String getReasoningContent() {
            return reasoningContent;
        }

        public String getToolName() {
            return toolName;
        }

        public String getToolCallId() {
            return toolCallId;
        }
    }

    /**
     * Token callback interface for streaming generation
     */
    public interface TokenCallback {
        boolean onToken(String token);
    }

    /**
     * Progress callback interface for operations (initialization, TTS)
     */
    public interface ProgressCallback {
        void onProgress(float progress);
    }

    /**
     * Download progress callback interface
     */
    public interface DownloadProgressCallback {
        void onProgress(float progress, String status, long downloadedBytes, long totalBytes);
    }

    /**
     * Audio chunk callback interface for streaming TTS
     */
    public interface AudioChunkCallback {
        void onAudioChunk(short[] audioChunk);
    }

    /**
     * Result class for operations
     */
    public static class Result<S, E> {
        private final S value;
        private final E error;
        private final boolean isSuccess;

        private Result(S value, E error, boolean isSuccess) {
            this.value = value;
            this.error = error;
            this.isSuccess = isSuccess;
        }

        public static <S, E> Result<S, E> success(S value) {
            return new Result<>(value, null, true);
        }

        public static <S, E> Result<S, E> failure(E error) {
            return new Result<>(null, error, false);
        }

        public boolean isSuccess() {
            return isSuccess;
        }

        public boolean isFailure() {
            return !isSuccess;
        }

        public S getValue() {
            return value;
        }

        public E getError() {
            return error;
        }
    }

    /**
     * Completion result
     */
    public static class CompletionResult {
        private final String text;
        private final int tokensGenerated;
        private final int tokensEvaluated;
        private final boolean truncated;
        private final boolean stoppedEos;
        private final boolean stoppedWord;
        private final boolean stoppedLimit;
        private final String stoppingWord;

        public CompletionResult(String text, int tokensGenerated, int tokensEvaluated, boolean truncated, boolean stoppedEos, boolean stoppedWord, boolean stoppedLimit, String stoppingWord) {
            this.text = text;
            this.tokensGenerated = tokensGenerated;
            this.tokensEvaluated = tokensEvaluated;
            this.truncated = truncated;
            this.stoppedEos = stoppedEos;
            this.stoppedWord = stoppedWord;
            this.stoppedLimit = stoppedLimit;
            this.stoppingWord = stoppingWord;
        }

        public String getText() { return text; }
        public int getTokensGenerated() { return tokensGenerated; }
        public int getTokensEvaluated() { return tokensEvaluated; }
        public boolean isTruncated() { return truncated; }
        public boolean isStoppedEos() { return stoppedEos; }
        public boolean isStoppedWord() { return stoppedWord; }
        public boolean isStoppedLimit() { return stoppedLimit; }
        public String getStoppingWord() { return stoppingWord; }
    }

    /**
     * Parameters for downloading models or files from Hugging Face
     */
    public static class DownloadParams {
        private final String repoId;
        private final String filename;
        private final String destinationPath;
        private final String bearerToken;
        private final boolean offline;
        private final DownloadProgressCallback progressCallback;

        private DownloadParams(Builder builder) {
            this.repoId = builder.repoId;
            this.filename = builder.filename;
            this.destinationPath = builder.destinationPath;
            this.bearerToken = builder.bearerToken;
            this.offline = builder.offline;
            this.progressCallback = builder.progressCallback;
        }

        public String getRepoId() { return repoId; }
        public String getFilename() { return filename; }
        public String getDestinationPath() { return destinationPath; }
        public String getBearerToken() { return bearerToken; }
        public boolean isOffline() { return offline; }
        public DownloadProgressCallback getProgressCallback() { return progressCallback; }

        public static class Builder {
            private final String repoId;
            private final String filename;
            private final String destinationPath;
            private String bearerToken;
            private boolean offline;
            private DownloadProgressCallback progressCallback;

            public Builder(String repoId, String filename, String destinationPath) {
                this.repoId = repoId;
                this.filename = filename;
                this.destinationPath = destinationPath;
            }

            public Builder bearerToken(String bearerToken) {
                this.bearerToken = bearerToken;
                return this;
            }

            public Builder offline(boolean offline) {
                this.offline = offline;
                return this;
            }

            public Builder progressCallback(DownloadProgressCallback progressCallback) {
                this.progressCallback = progressCallback;
                return this;
            }

            public DownloadParams build() {
                return new DownloadParams(this);
            }
        }
    }

    /**
     * Result of a download operation
     */
    public static class DownloadResult {
        private final boolean success;
        private final String localPath;
        private final String errorMessage;

        public DownloadResult(boolean success, String localPath, String errorMessage) {
            this.success = success;
            this.localPath = localPath;
            this.errorMessage = errorMessage;
        }

        public boolean isSuccess() { return success; }
        public String getLocalPath() { return localPath; }
        public String getErrorMessage() { return errorMessage; }
    }

    /**
     * Initialization parameters for creating a llama context
     */
    public static class InitParams {
        private final String modelPath;
        private final int nCtx;
        private final String chatTemplate;
        private final String systemPrompt;
        private final int nBatch;
        private final int nUBatch;
        private final int nGpuLayers;
        private final int nThreads;
        private final boolean useMmap;
        private final boolean useMlock;
        private final boolean embedding;
        private final int poolingType;
        private final int embdNormalize;
        private final boolean flashAttention;
        private final String cacheTypeK;
        private final String cacheTypeV;
        private final boolean enableChatTemplate;
        private final ProgressCallback progressCallback;

        public InitParams(String modelPath) {
            this(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        }

        public InitParams(String modelPath, int nCtx) {
            this(modelPath, nCtx, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        }

        public InitParams(String modelPath, int nCtx, String chatTemplate) {
            this(modelPath, nCtx, chatTemplate, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, true, null);
        }

        public InitParams(String modelPath, int nCtx, String chatTemplate, String systemPrompt, int nBatch, int nUBatch, int nGpuLayers, int nThreads, boolean useMmap, boolean useMlock, boolean embedding, int poolingType, int embdNormalize, boolean flashAttention, String cacheTypeK, String cacheTypeV, boolean enableChatTemplate, ProgressCallback progressCallback) {
            this.modelPath = modelPath;
            this.nCtx = nCtx;
            this.chatTemplate = chatTemplate;
            this.systemPrompt = systemPrompt;
            this.nBatch = nBatch;
            this.nUBatch = nUBatch;
            this.nGpuLayers = nGpuLayers;
            this.nThreads = nThreads;
            this.useMmap = useMmap;
            this.useMlock = useMlock;
            this.embedding = embedding;
            this.poolingType = poolingType;
            this.embdNormalize = embdNormalize;
            this.flashAttention = flashAttention;
            this.cacheTypeK = cacheTypeK;
            this.cacheTypeV = cacheTypeV;
            this.enableChatTemplate = enableChatTemplate;
            this.progressCallback = progressCallback;
        }

        public String getModelPath() { return modelPath; }
        public int getNCtx() { return nCtx; }
        public String getChatTemplate() { return chatTemplate; }
        public String getSystemPrompt() { return systemPrompt; }
        public int getNBatch() { return nBatch; }
        public int getNUBatch() { return nUBatch; }
        public int getNGpuLayers() { return nGpuLayers; }
        public int getNThreads() { return nThreads; }
        public boolean isUseMmap() { return useMmap; }
        public boolean isUseMlock() { return useMlock; }
        public boolean isEmbedding() { return embedding; }
        public int getPoolingType() { return poolingType; }
        public int getEmbdNormalize() { return embdNormalize; }
        public boolean isFlashAttention() { return flashAttention; }
        public String getCacheTypeK() { return cacheTypeK; }
        public String getCacheTypeV() { return cacheTypeV; }
        public boolean isEnableChatTemplate() { return enableChatTemplate; }
        public ProgressCallback getProgressCallback() { return progressCallback; }

        /**
         * Convenience factory for GPU-accelerated inference
         */
        public static InitParams gpu(String modelPath, int nGpuLayers, int nCtx) {
            return new InitParams(modelPath, nCtx, null, null, 512, 512, nGpuLayers, 4, true, false, false, 0, 0, false, null, null, true, null);
        }

        /**
         * Convenience factory for embedding generation
         */
        public static InitParams embedding(String modelPath, int poolingType) {
            return new InitParams(modelPath, 2048, null, null, 512, 512, 0, 4, true, false, true, poolingType, 0, false, null, null, true, null);
        }
    }

    /**
     * Completion parameters for generating text
     */
    public static class CompletionParams {
        private final String prompt;
        private final float temperature;
        private final int maxTokens;
        private final int nThreads;
        private final int seed;
        private final int topK;
        private final double topP;
        private final double minP;
        private final double typicalP;
        private final int penaltyLastN;
        private final double penaltyRepeat;
        private final double penaltyFreq;
        private final double penaltyPresent;
        private final int mirostat;
        private final double mirostatTau;
        private final double mirostatEta;
        private final boolean ignoreEos;
        private final int nProbs;
        private final String grammar;
        private final List<String> stopSequences;
        private final List<String> mediaPaths;
        private final TokenCallback tokenCallback;
        private final List<ChatMessage> chatMessages;
        private final boolean useJsonResponse;
        private final String jsonSchema;
        private final String tools;
        private final boolean parallelToolCalls;
        private final String toolChoice;

        public CompletionParams(String prompt) {
            this(prompt, 0.8f, 1024, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, true, null, null, false, null);
        }

        public CompletionParams(String prompt, float temperature) {
            this(prompt, temperature, 1024, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, true, null, null, false, null);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens) {
            this(prompt, temperature, maxTokens, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, true, null, null, false, null);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens, Integer nThreads, int seed, int topK, double topP, double minP, double typicalP, int penaltyLastN, double penaltyRepeat, double penaltyFreq, double penaltyPresent, int mirostat, double mirostatTau, double mirostatEta, boolean ignoreEos, int nProbs, String grammar, List<String> stopSequences, List<String> mediaPaths, TokenCallback tokenCallback) {
            this(prompt, temperature, maxTokens, nThreads, seed, topK, topP, minP, typicalP, penaltyLastN, penaltyRepeat, penaltyFreq, penaltyPresent, mirostat, mirostatTau, mirostatEta, ignoreEos, nProbs, grammar, stopSequences, mediaPaths, tokenCallback, null, true, null, null, false, null);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens, Integer nThreads, int seed, int topK, double topP, double minP, double typicalP, int penaltyLastN, double penaltyRepeat, double penaltyFreq, double penaltyPresent, int mirostat, double mirostatTau, double mirostatEta, boolean ignoreEos, int nProbs, String grammar, List<String> stopSequences, List<String> mediaPaths, TokenCallback tokenCallback, List<ChatMessage> chatMessages, boolean useJsonResponse, String jsonSchema, String tools, boolean parallelToolCalls, String toolChoice) {
            this.prompt = prompt;
            this.temperature = temperature;
            this.maxTokens = maxTokens;
            this.nThreads = nThreads != null ? nThreads : 4;
            this.seed = seed;
            this.topK = topK;
            this.topP = topP;
            this.minP = minP;
            this.typicalP = typicalP;
            this.penaltyLastN = penaltyLastN;
            this.penaltyRepeat = penaltyRepeat;
            this.penaltyFreq = penaltyFreq;
            this.penaltyPresent = penaltyPresent;
            this.mirostat = mirostat;
            this.mirostatTau = mirostatTau;
            this.mirostatEta = mirostatEta;
            this.ignoreEos = ignoreEos;
            this.nProbs = nProbs;
            this.grammar = grammar;
            this.stopSequences = stopSequences != null ? stopSequences : new ArrayList<>();
            this.mediaPaths = mediaPaths != null ? mediaPaths : new ArrayList<>();
            this.tokenCallback = tokenCallback;
            this.chatMessages = chatMessages != null ? chatMessages : new ArrayList<>();
            this.useJsonResponse = useJsonResponse;
            this.jsonSchema = jsonSchema;
            this.tools = tools;
            this.parallelToolCalls = parallelToolCalls;
            this.toolChoice = toolChoice;
        }

        public String getPrompt() { return prompt; }
        public float getTemperature() { return temperature; }
        public int getMaxTokens() { return maxTokens; }
        public Integer getNThreads() { return nThreads; }
        public int getSeed() { return seed; }
        public int getTopK() { return topK; }
        public double getTopP() { return topP; }
        public double getMinP() { return minP; }
        public double getTypicalP() { return typicalP; }
        public int getPenaltyLastN() { return penaltyLastN; }
        public double getPenaltyRepeat() { return penaltyRepeat; }
        public double getPenaltyFreq() { return penaltyFreq; }
        public double getPenaltyPresent() { return penaltyPresent; }
        public int getMirostat() { return mirostat; }
        public double getMirostatTau() { return mirostatTau; }
        public double getMirostatEta() { return mirostatEta; }
        public boolean isIgnoreEos() { return ignoreEos; }
        public int getNProbs() { return nProbs; }
        public String getGrammar() { return grammar; }
        public List<String> getStopSequences() { return stopSequences; }
        public List<String> getMediaPaths() { return mediaPaths; }
        public TokenCallback getTokenCallback() { return tokenCallback; }
        public List<ChatMessage> getChatMessages() { return chatMessages; }
        public boolean isUseJsonResponse() { return useJsonResponse; }
        public String getJsonSchema() { return jsonSchema; }
        public String getTools() { return tools; }
        public boolean isParallelToolCalls() { return parallelToolCalls; }
        public String getToolChoice() { return toolChoice; }

        /**
         * Creates CompletionParams from OpenAI format JSON
         * Example JSON format:
         * {"messages": [{"role": "system", "content": "You are a helpful assistant"}, {"role": "user", "content": "Hello"}]}
         */
        public static CompletionParams fromOpenAIJSON(String openAIJSON) throws Exception {
            return new CompletionParams("", 0.7f, 256, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.0, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), parseMediaPaths(openAIJSON), null, parseChatMessages(openAIJSON), true, null, null, false, null);
        }

        /**
         * Convenience factory for creative writing
         */
        public static CompletionParams creative(String prompt, int maxTokens) {
            return new CompletionParams(prompt, 1.0f, maxTokens, null, -1, 100, 0.98, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), new ArrayList<>(), null);
        }

        /**
         * Convenience factory for factual/accurate outputs
         */
        public static CompletionParams factual(String prompt) {
            return new CompletionParams(prompt, 0.1f, 1024, null, -1, 20, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), new ArrayList<>(), null);
        }

        /**
         * Convenience factory for chat conversations using structured messages
         */
        public static CompletionParams chat(List<ChatMessage> messages, int maxTokens) {
            return new CompletionParams("", 0.7f, maxTokens, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.2, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), new ArrayList<>(), null, messages, true, null, null, false, null);
        }

        /**
         * Convenience factory for chat-like responses using raw prompt
         */
        public static CompletionParams chat(String prompt, int maxTokens) {
            return new CompletionParams(prompt, 0.7f, maxTokens, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.2, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), new ArrayList<>(), null);
        }

        /**
         * Convenience factory for multimodal inputs
         */
        public static CompletionParams multimodal(String prompt, List<String> mediaPaths, int maxTokens) {
            return new CompletionParams(prompt, 0.8f, maxTokens, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), mediaPaths, null);
        }

        /**
         * Convenience factory for JSON output
         */
        public static CompletionParams jsonOutput(String prompt, int maxTokens) {
            return new CompletionParams(prompt, 0.8f, maxTokens, null, -1, 40, 0.95, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, new ArrayList<>(), new ArrayList<>(), null);
        }


        /**
         * Parse chat messages from OpenAI JSON
         */
        private static List<ChatMessage> parseChatMessages(String openAIJSON) throws Exception {
            List<ChatMessage> chatMessages = new ArrayList<>();
            JSONObject jsonObject = new JSONObject(openAIJSON);
            JSONArray messages = jsonObject.optJSONArray("messages");
            if (messages != null) {
                for (int i = 0; i < messages.length(); i++) {
                    JSONObject message = messages.getJSONObject(i);
                    String role = message.getString("role");
                    String content = message.getString("content");
                    String reasoningContent = message.optString("reasoning_content", null);
                    if (reasoningContent != null && reasoningContent.isEmpty()) reasoningContent = null;
                    String toolName = message.optString("tool_name", null);
                    if (toolName != null && toolName.isEmpty()) toolName = null;
                    String toolCallId = message.optString("tool_call_id", null);
                    if (toolCallId != null && toolCallId.isEmpty()) toolCallId = null;
                    chatMessages.add(new ChatMessage(role, content, reasoningContent, toolName, toolCallId));
                }
            }
            return chatMessages;
        }

        /**
         * Parse media paths from OpenAI JSON
         */
        private static List<String> parseMediaPaths(String openAIJSON) throws Exception {
            List<String> mediaPaths = new ArrayList<>();
            JSONObject jsonObject = new JSONObject(openAIJSON);
            JSONArray messages = jsonObject.optJSONArray("messages");
            if (messages != null) {
                for (int i = 0; i < messages.length(); i++) {
                    JSONObject message = messages.getJSONObject(i);
                    JSONArray contentArray = message.optJSONArray("content");
                    if (contentArray != null) {
                        for (int j = 0; j < contentArray.length(); j++) {
                            JSONObject contentItem = contentArray.getJSONObject(j);
                            String type = contentItem.getString("type");
                            if ("image_url".equals(type)) {
                                JSONObject imageUrl = contentItem.getJSONObject("image_url");
                                String url = imageUrl.getString("url");
                                if (url.startsWith("file://")) {
                                    String path = url.substring(7);
                                    mediaPaths.add(path);
                                }
                            }
                        }
                    }
                }
            }
            return mediaPaths;
        }
    }
    
    /**
     * Reads grammar content from a file
     *
     * @param filePath Path to the grammar file
     * @return Grammar content as string, or null if file not found or error occurred
     */
    public static String loadGrammar(String filePath) {
        if (filePath == null || filePath.isEmpty()) {
            return null;
        }

        try {
            java.io.File file = new java.io.File(filePath);
            if (!file.exists()) {
                return null;
            }

            java.io.FileInputStream fis = new java.io.FileInputStream(file);
            byte[] buffer = new byte[(int) file.length()];
            fis.read(buffer);
            fis.close();

            return new String(buffer, "UTF-8");
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }



    /**
     * Result of a conversation generation
     */
    public static class ConversationResult {
        private final String text;
        private final long timeToFirstToken;
        private final long totalTime;
        private final int tokensGenerated;

        public ConversationResult(String text, long timeToFirstToken, long totalTime, int tokensGenerated) {
            this.text = text;
            this.timeToFirstToken = timeToFirstToken;
            this.totalTime = totalTime;
            this.tokensGenerated = tokensGenerated;
        }

        public String getText() { return text; }
        public long getTimeToFirstToken() { return timeToFirstToken; }
        public long getTotalTime() { return totalTime; }
        public int getTokensGenerated() { return tokensGenerated; }
    }



    /**
     * Loads the native libraries
     */
    static {
        // Load JNI library (statically linked with c++_static, no external dependencies)
        System.loadLibrary("llama_mobile_jni");
    }

    /**
     * Stops an ongoing completion generation
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void stopCompletion(long contextHandle);

    /**
     * Tokenizes a text string into token IDs
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text string to tokenize
     * @return Array of token IDs, or null if tokenization failed
     */
    public static native int[] tokenize(long contextHandle, String text);

    /**
     * Detokenizes an array of token IDs back to a text string
     *
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Array of token IDs to detokenize
     * @return Detokenized text string, or null if detokenization failed
     */
    public static native String detokenize(long contextHandle, int[] tokens);

    /**
     * Generates embeddings for a text string
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text string to generate embeddings for
     * @return Array of floating-point embeddings, or null if embedding generation failed
     */
    public static native float[] generateEmbeddings(long contextHandle, String text);

    /**
     * Initializes multimodal support (vision/audio)
     *
     * @param contextHandle Context handle obtained from initContext
     * @param mmprojPath Path to the multimodal projection file
     * @param useGpu Whether to use GPU acceleration for multimodal processing (default: true)
     * @return true on success, false on failure
     */
    public static native boolean initMultimodal(long contextHandle, String mmprojPath, boolean useGpu);

    /**
     * Checks if multimodal support is enabled
     *
     * @param contextHandle Context handle obtained from initContext
     * @return true if enabled, false otherwise
     */
    public static native boolean isMultimodalEnabled(long contextHandle);

    /**
     * Checks if the model supports vision input
     *
     * @param contextHandle Context handle obtained from initContext
     * @return true if vision is supported, false otherwise
     */
    public static native boolean supportsVision(long contextHandle);

    /**
     * Checks if the model supports audio input
     *
     * @param contextHandle Context handle obtained from initContext
     * @return true if audio is supported, false otherwise
     */
    public static native boolean supportsAudio(long contextHandle);

    /**
     * Releases multimodal resources
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void releaseMultimodal(long contextHandle);

    /**
     * Initializes the vocoder for text-to-speech functionality
     *
     * @param contextHandle Context handle obtained from initContext
     * @param vocoderModelPath Path to the vocoder model file
     * @return true on success, false on failure
     */
    public static native boolean initVocoder(long contextHandle, String vocoderModelPath);

    /**
     * Checks if vocoder (TTS) support is enabled
     *
     * @param contextHandle Context handle obtained from initContext
     * @return true if enabled, false otherwise
     */
    public static native boolean isVocoderEnabled(long contextHandle);

    /**
     * Gets the type of TTS model currently loaded
     *
     * @param contextHandle Context handle obtained from initContext
     * @return TTS model type
     */
    public static native TTSModelType getTTSType(long contextHandle);

    /**
     * Formats text for audio completion with speaker information
     *
     * @param contextHandle Context handle obtained from initContext
     * @param speakerJson JSON string with speaker configuration
     * @param textToSpeak Text to convert to speech
     * @return Formatted audio completion string, or null if an error occurred
     */
    private static native String getFormattedAudioCompletion(long contextHandle, String speakerJson, String textToSpeak);

    /**
     * Gets guide tokens for audio completion
     *
     * @param contextHandle Context handle obtained from initContext
     * @param textToSpeak Text to convert to speech
     * @return Array of guide tokens for audio generation, or null if an error occurred
     */
    private static native int[] getAudioGuideTokens(long contextHandle, String textToSpeak);

    /**
     * Decodes audio tokens into raw audio data
     *
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Audio tokens to decode
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    private static native float[] decodeAudioTokens(long contextHandle, int[] tokens);

    /**
     * Sets guide tokens for audio generation
     *
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Guide tokens to set for audio generation
     */
    private static native void setGuideTokens(long contextHandle, int[] tokens);

    /**
     * Saves audio samples to WAV file
     *
     * @param contextHandle Context handle obtained from initContext
     * @param filePath Path to save the WAV file
     * @param audioData Array of floating-point audio samples
     * @param sampleRate Sample rate for the audio (e.g., 48000)
     * @return true on success, false on failure
     */
    public static native boolean saveAudioToWav(long contextHandle, String filePath, float[] audioData, int sampleRate);

    /**
     * Releases vocoder (TTS) resources
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void releaseVocoder(long contextHandle);

    /**
     * LoRA adapter configuration
     */
    public static class LoraAdapter {
        private final String path;
        private final float scale;

        public LoraAdapter(String path) {
            this(path, 1.0f);
        }

        public LoraAdapter(String path, float scale) {
            this.path = path;
            this.scale = scale;
        }

        public String getPath() { return path; }
        public float getScale() { return scale; }
    }

    /**
     * Applies LoRA adapters to the model
     *
     * @param contextHandle Context handle obtained from initContext
     * @param adapters Array of LoRA adapter configurations
     * @return true on success, false on failure
     */
    public static native boolean applyLoraAdapters(long contextHandle, LoraAdapter[] adapters);

    /**
     * Removes all loaded LoRA adapters
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void removeLoraAdapters(long contextHandle);

    /**
     * Gets the currently loaded LoRA adapters
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Array of loaded LoRA adapter configurations, or null if an error occurred
     */
    public static native LoraAdapter[] getLoadedLoraAdapters(long contextHandle);

    /**
     * Generates a response to a user message in a conversation
     *
     * @param contextHandle Context handle obtained from initContext
     * @param userMessage User's message
     * @param maxTokens Maximum number of tokens to generate
     * @return Conversation result, or null if an error occurred
     */
    public static native ConversationResult generateResponse(long contextHandle, String userMessage, int maxTokens);

    /**
     * Generates a response to a user message in a conversation with streaming token callback
     *
     * @param contextHandle Context handle obtained from initContext
     * @param userMessage User's message
     * @param maxTokens Maximum number of tokens to generate
     * @param tokenCallback Optional callback for streaming tokens as they are generated
     * @return Conversation result, or null if an error occurred
     */
    public static native ConversationResult generateResponseWithCallback(long contextHandle, String userMessage, int maxTokens, TokenCallback tokenCallback);

    /**
     * Generates a response to a user message in a conversation with optional streaming token callback
     *
     * @param contextHandle Context handle obtained from initContext
     * @param userMessage User's message
     * @param maxTokens Maximum number of tokens to generate
     * @param tokenCallback Optional callback for streaming tokens as they are generated
     * @return Conversation result, or null if an error occurred
     */
    public static ConversationResult generateResponse(long contextHandle, String userMessage, int maxTokens, TokenCallback tokenCallback) {
        return generateResponseWithCallback(contextHandle, userMessage, maxTokens, tokenCallback);
    }

    /**
     * Clears the current conversation context
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void clearConversation(long contextHandle);

    /**
     * Checks if a conversation is currently active
     *
     * @param contextHandle Context handle obtained from initContext
     * @return true if active, false otherwise
     */
    public static native boolean isConversationActive(long contextHandle);

    /**
     * Gets the size of the context window
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Size of the context window in tokens
     */
    public static native int getContextWindowSize(long contextHandle);

    /**
     * Gets the dimension of the model's embeddings
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Dimension of the model's embeddings
     */
    public static native int getEmbeddingDimension(long contextHandle);

    /**
     * Gets a description of the loaded model
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Model description string, or null if an error occurred
     */
    public static native String getModelDescription(long contextHandle);

    /**
     * Gets the size of the loaded model
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Model size in bytes
     */
    public static native long getModelSize(long contextHandle);



    /**
     * Generates audio samples from text using TTS
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param speakerJson JSON string with speaker configuration (optional, defaults to default speaker)
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    private static float[] generateAudioFromText(long contextHandle, String text, String speakerJson) {
        if (contextHandle == 0L) {
            return null;
        }
        
        if (!isVocoderEnabled(contextHandle)) {
            return null;
        }
        
        if (text == null || text.isEmpty()) {
            return null;
        }
        
        if (speakerJson == null) {
            speakerJson = "{\"speaker\": \"default\"}";
        }
        
        // Get formatted audio completion
        String formattedPrompt = getFormattedAudioCompletion(contextHandle, speakerJson, text);
        if (formattedPrompt == null) {
            return null;
        }
        
        // Get audio guide tokens
        int[] guideTokens = getAudioGuideTokens(contextHandle, formattedPrompt);
        if (guideTokens == null) {
            return null;
        }
        
        // Set guide tokens for audio generation
        setGuideTokens(contextHandle, guideTokens);
        
        // Generate completion using the formatted prompt with proper constructor
        CompletionParams completionParams = new CompletionParams(
            formattedPrompt, // prompt
            0.0f, // temperature
            200, // maxTokens
            null, // nThreads
            -1, // seed
            40, // topK
            0.95, // topP
            0.05, // minP
            1.0, // typicalP
            64, // penaltyLastN
            1.1, // penaltyRepeat
            0.0, // penaltyFreq
            0.0, // penaltyPresent
            0, // mirostat
            5.0, // mirostatTau
            0.1, // mirostatEta
            false, // ignoreEos
            0, // nProbs
            null, // grammar
            null, // stopSequences
            null, // mediaPaths
            null, // tokenCallback
            null, // chatMessages
            true, // useJsonResponse
            null, // jsonSchema
            null, // tools
            false, // parallelToolCalls
            null // toolChoice
        );
        
        CompletionResult completionResult = generateCompletion(contextHandle, completionParams);
        if (completionResult == null) {
            return null;
        }
        
        // Tokenize only the completion (not the prompt + completion)
        int[] audioTokens = tokenize(contextHandle, completionResult.text);
        if (audioTokens == null) {
            return null;
        }
        
        // Filter audio tokens - match iOS implementation
        java.util.ArrayList<Integer> filteredTokens = new java.util.ArrayList<>();
        int audioEndToken = 151668; // <|audio_end|>
        int minAudioToken = 151672;
        int maxAudioToken = 155772;
        
        for (int token : audioTokens) {
            // Check if token is in audio range
            if (token >= minAudioToken && token <= maxAudioToken) {
                filteredTokens.add(token);
            }
            
            // Check for end token
            if (token == audioEndToken) {
                break;
            }
        }
        
        // Convert ArrayList to int array
        int[] filteredTokenArray = new int[filteredTokens.size()];
        for (int i = 0; i < filteredTokens.size(); i++) {
            filteredTokenArray[i] = filteredTokens.get(i);
        }
        
        // Decode audio tokens to samples
        return decodeAudioTokens(contextHandle, filteredTokenArray);
    }

    /**
     * Generates audio samples from text using TTS with default speaker
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    private static float[] generateAudioFromText(long contextHandle, String text) {
        return generateAudioFromText(contextHandle, text, "{\"speaker\": \"default\"}");
    }

    /**
     * Generates speech from text using the best available method (synchronous)
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, TTSOptions options) {
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded());
        }
        
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled());
        }
        
        float[] audioSamples = generateAudioFromText(contextHandle, text);
        
        if (audioSamples == null) {
            return Result.failure(TTSError.generationFailed());
        }
        
        double duration = audioSamples.length / (double) options.getSampleRate();
        
        short[] shortSamples = new short[audioSamples.length];
        for (int i = 0; i < audioSamples.length; i++) {
            shortSamples[i] = (short) (audioSamples[i] * Short.MAX_VALUE);
        }
        
        String savedFilePath = null;
        if (options.isSaveToFile() && options.getOutputFilePath() != null) {
            boolean saveSuccess = saveAudioToWav(contextHandle, options.getOutputFilePath(), audioSamples, options.getSampleRate());
            if (saveSuccess) {
                savedFilePath = options.getOutputFilePath();
            } else {
                return Result.failure(TTSError.fileSaveFailed());
            }
        }
        
        TTSMethod methodUsed = TTSMethod.BUILT_IN;
        SpeechResult speechResult = new SpeechResult(
            shortSamples,
            options.getSampleRate(),
            duration,
            savedFilePath,
            methodUsed
        );
        
        return Result.success(speechResult);
    }

    /**
     * Generates speech from text using the best available method (asynchronous)
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param resultCallback Callback for receiving the final result
     */
    public static void generateSpeechAsync(long contextHandle, String text, TTSOptions options, final ProgressCallback progressHandler, final SpeechResultCallback resultCallback) {
        if (contextHandle == 0L) {
            resultCallback.onResult(Result.failure(TTSError.noModelLoaded()));
            return;
        }
        
        if (!isVocoderEnabled(contextHandle)) {
            resultCallback.onResult(Result.failure(TTSError.noVocoderEnabled()));
            return;
        }
        
        // Execute in a background thread
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    if (progressHandler != null) {
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                progressHandler.onProgress(0.1f);
                            }
                        });
                    }
                    
                    float[] audioSamples = generateAudioFromText(contextHandle, text);
                    
                    if (progressHandler != null) {
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                progressHandler.onProgress(0.8f);
                            }
                        });
                    }
                    
                    if (audioSamples == null) {
                        final Result<SpeechResult, TTSError> failureResult = Result.failure(TTSError.generationFailed());
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                resultCallback.onResult(failureResult);
                            }
                        });
                        return;
                    }
                    
                    double duration = audioSamples.length / (double) options.getSampleRate();
                    
                    short[] shortSamples = new short[audioSamples.length];
                    for (int i = 0; i < audioSamples.length; i++) {
                        shortSamples[i] = (short) (audioSamples[i] * Short.MAX_VALUE);
                    }
                    
                    String savedFilePath = null;
                    if (options.isSaveToFile() && options.getOutputFilePath() != null) {
                        boolean saveSuccess = saveAudioToWav(contextHandle, options.getOutputFilePath(), audioSamples, options.getSampleRate());
                        if (saveSuccess) {
                            savedFilePath = options.getOutputFilePath();
                        } else {
                            final Result<SpeechResult, TTSError> failureResult = Result.failure(TTSError.fileSaveFailed());
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    resultCallback.onResult(failureResult);
                                }
                            });
                            return;
                        }
                    }
                    
                    if (progressHandler != null) {
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                progressHandler.onProgress(1.0f);
                            }
                        });
                    }
                    
                    TTSMethod methodUsed = TTSMethod.BUILT_IN;
                    final SpeechResult speechResult = new SpeechResult(
                        shortSamples,
                        options.getSampleRate(),
                        duration,
                        savedFilePath,
                        methodUsed
                    );
                    
                    final Result<SpeechResult, TTSError> successResult = Result.success(speechResult);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            resultCallback.onResult(successResult);
                        }
                    });
                } catch (final Exception e) {
                    final Result<SpeechResult, TTSError> errorResult = Result.failure(TTSError.generationFailed());
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            resultCallback.onResult(errorResult);
                        }
                    });
                }
            }
        }).start();
    }
    
    /**
     * Callback interface for speech generation results
     */
    public interface SpeechResultCallback {
        void onResult(Result<SpeechResult, TTSError> result);
    }
    
    /**
     * Callback interface for speech metadata results
     */
    public interface SpeechMetadataCallback {
        void onResult(Result<SpeechMetadata, TTSError> result);
    }
    
    /**
     * Runs a runnable on the main thread
     */
    private static void runOnMainThread(Runnable runnable) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            runnable.run();
        } else {
            new Handler(Looper.getMainLooper()).post(runnable);
        }
    }


    /**
     * Generates speech from long text with real streaming capabilities
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Long text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param audioChunkHandler Callback for receiving audio chunks as they're generated
     * @param resultCallback Callback for receiving the final metadata result
     */
    public static void generateSpeechStreamForLongTextAsync(long contextHandle, String text, TTSOptions options, final ProgressCallback progressHandler, final AudioChunkCallback audioChunkHandler, final SpeechMetadataCallback resultCallback) {
        // Check if context is valid
        if (contextHandle == 0L) {
            resultCallback.onResult(Result.failure(TTSError.noModelLoaded()));
            return;
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            resultCallback.onResult(Result.failure(TTSError.noVocoderEnabled()));
            return;
        }
        
        // Execute in a background thread
        new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    // Split long text into sentences
                    String[] sentences = text.split("[.!?]+\\s*");
                    int totalSentences = sentences.length;
                    
                    double totalDuration = 0;
                    TTSMethod methodUsed = TTSMethod.BUILT_IN;
                    String outputFilePath = null;
                    
                    for (int i = 0; i < totalSentences; i++) {
                        final String sentence = sentences[i].trim();
                        if (sentence.isEmpty()) {
                            continue;
                        }
                        
                        // Update progress
                        if (progressHandler != null) {
                            final float progress = (float) (i + 1) / totalSentences;
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    progressHandler.onProgress(0.1f + (progress * 0.8f)); // 0.1 to 0.9
                                }
                            });
                        }
                        
                        // Generate speech for this sentence
                        Result<SpeechResult, TTSError> sentenceResult = generateSpeech(contextHandle, sentence, options);
                        
                        if (sentenceResult.isFailure()) {
                            final Result<SpeechMetadata, TTSError> failureResult = Result.failure(sentenceResult.getError());
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    resultCallback.onResult(failureResult);
                                }
                            });
                            return;
                        }
                        
                        SpeechResult speechResult = sentenceResult.getValue();
                        
                        // Send audio chunk
                        if (audioChunkHandler != null) {
                            final short[] audioSamples = speechResult.getAudioSamples();
                            runOnMainThread(new Runnable() {
                                @Override
                                public void run() {
                                    audioChunkHandler.onAudioChunk(audioSamples);
                                }
                            });
                        }
                        
                        // Accumulate metadata
                        totalDuration += speechResult.getDuration();
                        methodUsed = speechResult.getMethodUsed();
                        if (outputFilePath == null) {
                            outputFilePath = speechResult.getOutputFilePath();
                        }
                    }
                    
                    if (progressHandler != null) {
                        runOnMainThread(new Runnable() {
                            @Override
                            public void run() {
                                progressHandler.onProgress(1.0f); // Completed
                            }
                        });
                    }
                    
                    // Create metadata
                    final SpeechMetadata metadata = new SpeechMetadata(
                        options.getSampleRate(),
                        totalDuration,
                        methodUsed,
                        outputFilePath
                    );
                    
                    final Result<SpeechMetadata, TTSError> successResult = Result.success(metadata);
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            resultCallback.onResult(successResult);
                        }
                    });
                } catch (final Exception e) {
                    final Result<SpeechMetadata, TTSError> errorResult = Result.failure(TTSError.generationFailed());
                    runOnMainThread(new Runnable() {
                        @Override
                        public void run() {
                            resultCallback.onResult(errorResult);
                        }
                    });
                }
            }
        }).start();
    }


    /**
     * Gets the number of parameters in the loaded model
     *
     * @param contextHandle Context handle obtained from initContext
     * @return Number of model parameters
     */
    public static native long getModelParametersCount(long contextHandle);

    /**
     * Initializes a new llama context
     *
     * @param params Initialization parameters
     * @return Context handle, or 0 if initialization failed
     */
    /**
     * Initializes a new LlamaMobile context with the given parameters.
     *
     * @param params Initialization parameters including model path, context size, and callbacks
     * @return Context handle, or 0 if initialization failed
     * 
     * @warning Callback Limitations: Due to native API design, progress callbacks are shared
     * across all contexts. Only one context should be initialized with a progress callback
     * at a time. Multiple contexts with progress callbacks will result in only the last
     * callback being used. See CRITICAL_CALLBACK_ISSUE.md for details.
     */
    public static native long initContext(InitParams params);

    /**
     * Generates text completion
     *
     * @param contextHandle Context handle obtained from initContext
     * @param params Completion parameters
     * @return Generated text result, or null if generation failed
     * 
     * @warning Callback Limitations: Due to native API design, token callbacks are shared
     * across all completions. Only one completion should run with a token callback
     * at a time. Multiple concurrent completions with token callbacks will result in
     * only the last callback being used. See CRITICAL_CALLBACK_ISSUE.md for details.
     */
    public static CompletionResult generateCompletion(long contextHandle, CompletionParams params) {
        return nativeGenerateCompletion(contextHandle, params);
    }
    
    /**
     * Native implementation of generateCompletion
     */
    private static native CompletionResult nativeGenerateCompletion(long contextHandle, CompletionParams params);

    /**
     * Releases a llama context
     *
     * @param contextHandle Context handle obtained from initContext
     */
    public static native void releaseContext(long contextHandle);

    /**
     * Downloads a model from Hugging Face repository
     *
     * @param params Download parameters
     * @param progressCallback Callback for download progress updates
     * @return Download result, or null if download failed
     */
    public static DownloadResult downloadModel(DownloadParams params, DownloadProgressCallback progressCallback) {
        String url;
        String filename;
        String destinationPath = params.getDestinationPath();
        
        if (params.getRepoId().contains("://")) {
            url = params.getRepoId();
            filename = params.getFilename();
        } else {
            String[] components = params.getRepoId().split("/");
            if (components.length < 2) {
                return new DownloadResult(false, destinationPath + "/" + params.getFilename(), 
                    "Invalid Hugging Face repo ID format. Expected: owner/repo/filename");
            }
            
            String owner = components[0];
            String repo = components[1];
            String file = components.length > 2 ? String.join("/", java.util.Arrays.copyOfRange(components, 2, components.length)) : params.getFilename();
            
            filename = file;
            url = "https://huggingface.co/" + owner + "/" + repo + "/resolve/main/" + file;
        }
        
        return downloadFromURL(url, filename, destinationPath, params.getBearerToken(), progressCallback);
    }

    /**
     * Downloads a specific file from Hugging Face repository
     *
     * @param repoId Hugging Face repository ID
     * @param filename Name of the file to download
     * @param destinationPath Local path to save the file
     * @param bearerToken Bearer token for authentication (optional)
     * @param offline Whether to use offline mode
     * @param progressCallback Callback for download progress updates
     * @return Download result, or null if download failed
     */
    public static DownloadResult downloadHfFile(
            String repoId,
            String filename,
            String destinationPath,
            String bearerToken,
            boolean offline,
            DownloadProgressCallback progressCallback) {
        
        String url = "https://huggingface.co/" + repoId + "/resolve/main/" + filename;
        return downloadFromURL(url, filename, destinationPath, bearerToken, progressCallback);
    }

    /**
     * Downloads a file from a URL using Android's native networking
     *
     * @param url URL to download from
     * @param filename Name of the file
     * @param destinationPath Local path to save the file
     * @param bearerToken Bearer token for authentication (optional)
     * @param progressCallback Callback for download progress updates
     * @return Download result
     */
    private static DownloadResult downloadFromURL(
            String url,
            String filename,
            String destinationPath,
            String bearerToken,
            DownloadProgressCallback progressCallback) {
        
        java.io.File destDir = new java.io.File(destinationPath);
        if (!destDir.exists()) {
            if (!destDir.mkdirs()) {
                return new DownloadResult(false, destinationPath + "/" + filename, 
                    "Failed to create destination directory");
            }
        }
        
        java.io.File destFile = new java.io.File(destDir, filename);
        
        try {
            java.net.URL downloadUrl = new java.net.URL(url);
            java.net.HttpURLConnection connection = (java.net.HttpURLConnection) downloadUrl.openConnection();
            
            connection.setRequestMethod("GET");
            connection.setConnectTimeout(30000);
            connection.setReadTimeout(30000);
            
            if (bearerToken != null && !bearerToken.isEmpty()) {
                connection.setRequestProperty("Authorization", "Bearer " + bearerToken);
            }
            
            connection.connect();
            
            int responseCode = connection.getResponseCode();
            if (responseCode != 200) {
                return new DownloadResult(false, destFile.getAbsolutePath(), 
                    "HTTP error: " + responseCode);
            }
            
            int contentLength = connection.getContentLength();
            java.io.InputStream inputStream = connection.getInputStream();
            java.io.FileOutputStream outputStream = new java.io.FileOutputStream(destFile);
            
            byte[] buffer = new byte[8192];
            int bytesRead;
            long totalBytesRead = 0;
            
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, bytesRead);
                totalBytesRead += bytesRead;
                
                if (progressCallback != null && contentLength > 0) {
                    float progress = (float) totalBytesRead / contentLength;
                    String status = "Downloading...";
                    progressCallback.onProgress(progress, status, totalBytesRead, contentLength);
                }
            }
            
            outputStream.close();
            inputStream.close();
            connection.disconnect();
            
            return new DownloadResult(true, destFile.getAbsolutePath(), null);
            
        } catch (java.net.SocketTimeoutException e) {
            return new DownloadResult(false, destFile.getAbsolutePath(), 
                "Connection timed out. Please check your internet connection and try again.");
        } catch (java.net.UnknownHostException e) {
            return new DownloadResult(false, destFile.getAbsolutePath(), 
                "No internet connection. Please check your network settings.");
        } catch (java.io.IOException e) {
            return new DownloadResult(false, destFile.getAbsolutePath(), 
                "Download failed: " + e.getMessage());
        } catch (Exception e) {
            return new DownloadResult(false, destFile.getAbsolutePath(), 
                "Download failed: " + e.getMessage());
        }
    }

    /**
     * Convenience method for generating text completion with simplified parameters
     *
     * @param contextHandle Context handle obtained from initContext
     * @param prompt Input prompt text
     * @param maxTokens Maximum number of tokens to generate (default: 128)
     * @param temperature Sampling temperature (default: 0.8)
     * @return Completion result, or null if generation failed
     */
    public static CompletionResult generateCompletion(long contextHandle, String prompt, int maxTokens, float temperature) {
        CompletionParams params = new CompletionParams(prompt, temperature, maxTokens);
        return generateCompletion(contextHandle, params);
    }

    /**
     * Generates text completion from OpenAI format JSON
     *
     * @param contextHandle Context handle obtained from initContext
     * @param openAIJSON JSON string in OpenAI format containing messages
     * @return Completion result, or null if generation failed
     */
    public static CompletionResult generateOpenAICompletion(long contextHandle, String openAIJSON) {
        try {
            CompletionParams params = CompletionParams.fromOpenAIJSON(openAIJSON);
            return generateCompletion(contextHandle, params);
        } catch (Exception e) {
            return null;
        }
    }


    /**
     * Convenience method for downloading models
     *
     * @param params Download parameters
     * @return Download result, or null if download failed
     */
    public static DownloadResult download(DownloadParams params) {
        return downloadModel(params, params.getProgressCallback());
    }

    // Private constructor to prevent instantiation
    private LlamaMobile() {
    }
}