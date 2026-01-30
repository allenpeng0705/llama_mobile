package com.llamamobile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.json.JSONObject;
import org.json.JSONArray;

/**
 * LlamaMobile Android Library
 *
 * This class provides a Java wrapper around the llama_mobile C library,
 * allowing Android applications to interact with llama models.
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
     * Grammar name enum
     */
    public enum GrammarName {
        ARITHMETIC,
        C,
        CHESS,
        ENGLISH,
        JAPANESE,
        JSON,
        JSON_ARR,
        LIST
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
     * Progress callback interface for operations
     */
    public interface ProgressCallback {
        void onProgress(float progress);
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
     * Parameters for downloading models or files
     */
    public static class DownloadParams {
        private final String url;
        private final String localPath;
        private final String username;
        private final String password;
        private final Map<String, String> headers;
        private final ProgressCallback progressCallback;

        private DownloadParams(Builder builder) {
            this.url = builder.url;
            this.localPath = builder.localPath;
            this.username = builder.username;
            this.password = builder.password;
            this.headers = builder.headers;
            this.progressCallback = builder.progressCallback;
        }

        public String getUrl() { return url; }
        public String getLocalPath() { return localPath; }
        public String getUsername() { return username; }
        public String getPassword() { return password; }
        public Map<String, String> getHeaders() { return headers; }
        public ProgressCallback getProgressCallback() { return progressCallback; }

        public static class Builder {
            private final String url;
            private final String localPath;
            private String username;
            private String password;
            private Map<String, String> headers;
            private ProgressCallback progressCallback;

            public Builder(String url, String localPath) {
                this.url = url;
                this.localPath = localPath;
            }

            public Builder username(String username) {
                this.username = username;
                return this;
            }

            public Builder password(String password) {
                this.password = password;
                return this;
            }

            public Builder headers(Map<String, String> headers) {
                this.headers = headers;
                return this;
            }

            public Builder progressCallback(ProgressCallback progressCallback) {
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
                    if (reasoningContent.isEmpty()) reasoningContent = null;
                    String toolName = message.optString("tool_name", null);
                    if (toolName.isEmpty()) toolName = null;
                    String toolCallId = message.optString("tool_call_id", null);
                    if (toolCallId.isEmpty()) toolCallId = null;
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
     * Convenience method to get JSON grammar content
     * 
     * @param context Application context to access assets
     * @return JSON grammar content as string
     */
    public static String getJsonGrammar(android.content.Context context) {
        return grammarContent(context, GrammarName.JSON);
    }
    
    /**
     * Convenience method to get arithmetic grammar content
     * 
     * @param context Application context to access assets
     * @return Arithmetic grammar content as string
     */
    public static String getArithmeticGrammar(android.content.Context context) {
        return grammarContent(context, GrammarName.ARITHMETIC);
    }
    
    /**
     * Convenience method to get C grammar content
     * 
     * @param context Application context to access assets
     * @return C grammar content as string
     */
    public static String getCGrammar(android.content.Context context) {
        return grammarContent(context, GrammarName.C);
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
        // Load C++ shared library first - explicitly handle potential errors
        try {
            System.loadLibrary("c++_shared");
            // Then load our native libraries
            System.loadLibrary("llama_mobile");
            System.loadLibrary("llama_mobile_jni");
        } catch (UnsatisfiedLinkError e) {
            e.printStackTrace();
            // Try alternative loading approach if primary fails
            try {
                System.loadLibrary("c++_shared");
                System.loadLibrary("llama_mobile");
                System.loadLibrary("llama_mobile_jni");
            } catch (UnsatisfiedLinkError e2) {
                e2.printStackTrace();
                throw e2;
            }
        }
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
    public static native String getFormattedAudioCompletion(long contextHandle, String speakerJson, String textToSpeak);

    /**
     * Gets guide tokens for audio completion
     *
     * @param contextHandle Context handle obtained from initContext
     * @param textToSpeak Text to convert to speech
     * @return Array of guide tokens for audio generation, or null if an error occurred
     */
    public static native int[] getAudioGuideTokens(long contextHandle, String textToSpeak);

    /**
     * Decodes audio tokens into raw audio data
     *
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Audio tokens to decode
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    public static native float[] decodeAudioTokens(long contextHandle, int[] tokens);

    /**
     * Sets guide tokens for audio generation
     *
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Guide tokens to set for audio generation
     */
    public static native void setGuideTokens(long contextHandle, int[] tokens);

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
    public static float[] generateAudioFromText(long contextHandle, String text, String speakerJson) {
        if (!isVocoderEnabled(contextHandle)) {
            return null;
        }
        
        // Get formatted audio completion
        String formattedPrompt = getFormattedAudioCompletion(contextHandle, speakerJson, text);
        if (formattedPrompt == null) {
            return null;
        }
        
        // Generate audio tokens
        int[] audioTokens = getAudioGuideTokens(contextHandle, formattedPrompt);
        if (audioTokens == null) {
            return null;
        }
        
        // Decode audio tokens to samples
        return decodeAudioTokens(contextHandle, audioTokens);
    }

    /**
     * Generates audio samples from text using TTS with default speaker
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    public static float[] generateAudioFromText(long contextHandle, String text) {
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
    public static Result<SpeechResult, TTSError> generateSpeechSync(long contextHandle, String text, TTSOptions options) {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded());
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled());
        }
        
        // Check TTS model type
        TTSModelType ttsType = getTTSType(contextHandle);
        boolean isKnownTTSModel = ttsType != TTSModelType.UNKNOWN;
        
        float[] audioSamples;
        TTSMethod methodUsed = TTSMethod.BUILT_IN;
        
        if (isKnownTTSModel) {
            // Try Path 1: Built-in TTS method
            audioSamples = generateAudioFromText(contextHandle, text);
            methodUsed = TTSMethod.BUILT_IN;
        } else {
            // Try Path 2: Custom TTS workflow
            audioSamples = generateAudioFromText(contextHandle, text);
            methodUsed = TTSMethod.CUSTOM_WORKFLOW;
        }
        
        if (audioSamples == null) {
            return Result.failure(TTSError.generationFailed());
        }
        
        // Calculate duration
        double duration = audioSamples.length / (double) options.getSampleRate();
        
        // Convert FloatArray to ShortArray
        short[] shortSamples = new short[audioSamples.length];
        for (int i = 0; i < audioSamples.length; i++) {
            shortSamples[i] = (short) (audioSamples[i] * Short.MAX_VALUE);
        }
        
        // Save to file if requested
        String savedFilePath = null;
        if (options.isSaveToFile() && options.getOutputFilePath() != null) {
            boolean saveSuccess = saveAudioToWav(contextHandle, options.getOutputFilePath(), audioSamples, options.getSampleRate());
            if (saveSuccess) {
                savedFilePath = options.getOutputFilePath();
            } else {
                return Result.failure(TTSError.fileSaveFailed());
            }
        }
        
        // Create speech result
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
     * Generates speech from text using the best available method (synchronous) with default options
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeechSync(long contextHandle, String text) {
        return generateSpeechSync(contextHandle, text, new TTSOptions());
    }

    /**
     * Generates speech from text using the best available method (asynchronous)
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler) {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded());
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled());
        }
        
        if (progressHandler != null) {
            progressHandler.onProgress(0.1f); // Initial progress
        }
        
        // Check TTS model type
        TTSModelType ttsType = getTTSType(contextHandle);
        boolean isKnownTTSModel = ttsType != TTSModelType.UNKNOWN;
        
        if (progressHandler != null) {
            progressHandler.onProgress(0.2f); // Model check completed
        }
        
        float[] audioSamples;
        TTSMethod methodUsed = TTSMethod.BUILT_IN;
        
        if (isKnownTTSModel) {
            // Try Path 1: Built-in TTS method
            if (progressHandler != null) {
                progressHandler.onProgress(0.3f); // Starting built-in method
            }
            audioSamples = generateAudioFromText(contextHandle, text);
            methodUsed = TTSMethod.BUILT_IN;
            
            if (progressHandler != null) {
                progressHandler.onProgress(0.6f); // Built-in method completed
            }
        } else {
            // Try Path 2: Custom TTS workflow
            if (progressHandler != null) {
                progressHandler.onProgress(0.4f); // Starting custom workflow
            }
            audioSamples = generateAudioFromText(contextHandle, text);
            methodUsed = TTSMethod.CUSTOM_WORKFLOW;
        }
        
        if (audioSamples == null) {
            return Result.failure(TTSError.generationFailed());
        }
        
        if (progressHandler != null) {
            progressHandler.onProgress(0.8f); // Audio generation completed
        }
        
        // Calculate duration
        double duration = audioSamples.length / (double) options.getSampleRate();
        
        // Convert FloatArray to ShortArray
        short[] shortSamples = new short[audioSamples.length];
        for (int i = 0; i < audioSamples.length; i++) {
            shortSamples[i] = (short) (audioSamples[i] * Short.MAX_VALUE);
        }
        
        // Save to file if requested
        String savedFilePath = null;
        if (options.isSaveToFile() && options.getOutputFilePath() != null) {
            boolean saveSuccess = saveAudioToWav(contextHandle, options.getOutputFilePath(), audioSamples, options.getSampleRate());
            if (saveSuccess) {
                savedFilePath = options.getOutputFilePath();
            } else {
                return Result.failure(TTSError.fileSaveFailed());
            }
        }
        
        if (progressHandler != null) {
            progressHandler.onProgress(1.0f); // Completed
        }
        
        // Create speech result
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
     * Generates speech from text using the best available method (asynchronous) with default options
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text) {
        return generateSpeech(contextHandle, text, new TTSOptions(), null);
    }

    /**
     * Generates speech from text using the best available method (asynchronous) with progress handler
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param progressHandler Callback for progress updates
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, ProgressCallback progressHandler) {
        return generateSpeech(contextHandle, text, new TTSOptions(), progressHandler);
    }

    /**
     * Generates speech from text using the best available method (asynchronous) with options
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @return Result containing the generated audio samples and metadata
     */
    public static Result<SpeechResult, TTSError> generateSpeech(long contextHandle, String text, TTSOptions options) {
        return generateSpeech(contextHandle, text, options, null);
    }

    /**
     * Generates speech from text with streaming support (simplified implementation)
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param audioChunkHandler Callback for receiving audio chunks
     * @return Result containing metadata about the generated speech
     */
    public static Result<SpeechMetadata, TTSError> generateSpeechStream(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler, AudioChunkCallback audioChunkHandler) {
        // Generate full audio first (simplified streaming)
        Result<SpeechResult, TTSError> result = generateSpeech(contextHandle, text, options, progressHandler);
        
        if (result.isFailure()) {
            return Result.failure(result.getError());
        }
        
        SpeechResult speechResult = result.getValue();
        
        // Send the entire audio as a single chunk
        if (audioChunkHandler != null) {
            audioChunkHandler.onAudioChunk(speechResult.getAudioSamples());
        }
        
        // Create metadata
        SpeechMetadata metadata = new SpeechMetadata(
            speechResult.getSampleRate(),
            speechResult.getDuration(),
            speechResult.getMethodUsed(),
            speechResult.getOutputFilePath()
        );
        
        return Result.success(metadata);
    }

    /**
     * Generates speech from text with streaming support (simplified implementation) with default options
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param audioChunkHandler Callback for receiving audio chunks
     * @return Result containing metadata about the generated speech
     */
    public static Result<SpeechMetadata, TTSError> generateSpeechStream(long contextHandle, String text, AudioChunkCallback audioChunkHandler) {
        return generateSpeechStream(contextHandle, text, new TTSOptions(), null, audioChunkHandler);
    }

    /**
     * Generates speech from long text with real streaming capabilities
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Long text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param audioChunkHandler Callback for receiving audio chunks as they're generated
     * @return Result containing metadata about the generated speech
     */
    public static Result<SpeechMetadata, TTSError> generateSpeechStreamForLongText(long contextHandle, String text, TTSOptions options, ProgressCallback progressHandler, AudioChunkCallback audioChunkHandler) {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded());
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled());
        }
        
        // Split long text into sentences
        String[] sentences = text.split("[.!?]+\\s*");
        int totalSentences = sentences.length;
        
        double totalDuration = 0;
        TTSMethod methodUsed = TTSMethod.BUILT_IN;
        String outputFilePath = null;
        
        for (int i = 0; i < totalSentences; i++) {
            String sentence = sentences[i].trim();
            if (sentence.isEmpty()) {
                continue;
            }
            
            // Update progress
            if (progressHandler != null) {
                float progress = (float) (i + 1) / totalSentences;
                progressHandler.onProgress(0.1f + (progress * 0.8f)); // 0.1 to 0.9
            }
            
            // Generate speech for this sentence
            Result<SpeechResult, TTSError> sentenceResult = generateSpeechSync(contextHandle, sentence, options);
            
            if (sentenceResult.isFailure()) {
                return Result.failure(sentenceResult.getError());
            }
            
            SpeechResult speechResult = sentenceResult.getValue();
            
            // Send audio chunk
            if (audioChunkHandler != null) {
                audioChunkHandler.onAudioChunk(speechResult.getAudioSamples());
            }
            
            // Accumulate metadata
            totalDuration += speechResult.getDuration();
            methodUsed = speechResult.getMethodUsed();
            if (outputFilePath == null) {
                outputFilePath = speechResult.getOutputFilePath();
            }
        }
        
        if (progressHandler != null) {
            progressHandler.onProgress(1.0f); // Completed
        }
        
        // Create metadata
        SpeechMetadata metadata = new SpeechMetadata(
            options.getSampleRate(),
            totalDuration,
            methodUsed,
            outputFilePath
        );
        
        return Result.success(metadata);
    }

    /**
     * Generates speech from long text with real streaming capabilities with default options
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Long text to convert to speech
     * @param audioChunkHandler Callback for receiving audio chunks
     * @return Result containing metadata about the generated speech
     */
    public static Result<SpeechMetadata, TTSError> generateSpeechStreamForLongText(long contextHandle, String text, AudioChunkCallback audioChunkHandler) {
        return generateSpeechStreamForLongText(contextHandle, text, new TTSOptions(), null, audioChunkHandler);
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
    public static native long initContext(InitParams params);

    /**
     * Generates text completion
     *
     * @param contextHandle Context handle obtained from initContext
     * @param params Completion parameters
     * @return Generated text result, or null if generation failed
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
     * Gets the content of a grammar file
     *
     * @param context Application context to access assets
     * @param name Grammar name
     * @return Grammar content as string, or null if not found or error occurred
     */
    public static native String grammarContent(android.content.Context context, GrammarName name);

    /**
     * Downloads a model from Hugging Face repository
     *
     * @param params Download parameters
     * @param progressCallback Callback for download progress updates
     * @return Download result, or null if download failed
     */
    public static native DownloadResult downloadModel(DownloadParams params, ProgressCallback progressCallback);

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
    public static native DownloadResult downloadHfFile(
            String repoId,
            String filename,
            String destinationPath,
            String bearerToken,
            boolean offline,
            ProgressCallback progressCallback);

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
     * @param grammar Optional grammar string to constrain generation
     * @return Completion result, or null if generation failed
     */
    public static CompletionResult generateOpenAICompletion(long contextHandle, String openAIJSON, String grammar) {
        try {
            CompletionParams params = CompletionParams.fromOpenAIJSON(openAIJSON);
            params = new CompletionParams(
                params.getPrompt(),
                params.getTemperature(),
                params.getMaxTokens(),
                params.getNThreads(),
                params.getSeed(),
                params.getTopK(),
                params.getTopP(),
                params.getMinP(),
                params.getTypicalP(),
                params.getPenaltyLastN(),
                params.getPenaltyRepeat(),
                params.getPenaltyFreq(),
                params.getPenaltyPresent(),
                params.getMirostat(),
                params.getMirostatTau(),
                params.getMirostatEta(),
                params.isIgnoreEos(),
                params.getNProbs(),
                grammar != null ? grammar : params.getGrammar(),
                params.getStopSequences(),
                params.getMediaPaths(),
                params.getTokenCallback(),
                params.getChatMessages(),
                grammar != null ? false : params.isUseJsonResponse(),
                null,
                null,
                false,
                null
            );
            return generateCompletion(contextHandle, params);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Generates text completion from OpenAI format JSON with default grammar
     *
     * @param contextHandle Context handle obtained from initContext
     * @param openAIJSON JSON string in OpenAI format containing messages
     * @return Completion result, or null if generation failed
     */
    public static CompletionResult generateOpenAICompletion(long contextHandle, String openAIJSON) {
        return generateOpenAICompletion(contextHandle, openAIJSON, null);
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