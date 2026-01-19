package com.llamamobile;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

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

        public ChatMessage(String role, String content) {
            this.role = role;
            this.content = content;
        }

        public String getRole() {
            return role;
        }

        public String getContent() {
            return content;
        }
    }

    /**
     * Token callback interface for streaming generation
     */
    public interface TokenCallback {
        boolean onToken(String token);
    }

    /**
     * Progress callback interface for download operations
     */
    public interface ProgressCallback {
        void onProgress(float progress);
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

        public CompletionResult(String text, int tokensGenerated, int tokensEvaluated, boolean truncated, boolean stoppedEos, boolean stoppedWord, boolean stoppedLimit) {
            this.text = text;
            this.tokensGenerated = tokensGenerated;
            this.tokensEvaluated = tokensEvaluated;
            this.truncated = truncated;
            this.stoppedEos = stoppedEos;
            this.stoppedWord = stoppedWord;
            this.stoppedLimit = stoppedLimit;
        }

        public String getText() { return text; }
        public int getTokensGenerated() { return tokensGenerated; }
        public int getTokensEvaluated() { return tokensEvaluated; }
        public boolean isTruncated() { return truncated; }
        public boolean isStoppedEos() { return stoppedEos; }
        public boolean isStoppedWord() { return stoppedWord; }
        public boolean isStoppedLimit() { return stoppedLimit; }
    }

    /**
     * Parameters for downloading models or files
     */
    public static class DownloadParams {
        private final String url;
        private final String localPath;
        private final String password;
        private final Map<String, String> headers;

        public DownloadParams(String url, String localPath) {
            this(url, localPath, null, null);
        }

        public DownloadParams(String url, String localPath, String password) {
            this(url, localPath, password, null);
        }

        public DownloadParams(String url, String localPath, String password, Map<String, String> headers) {
            this.url = url;
            this.localPath = localPath;
            this.password = password;
            this.headers = headers;
        }

        public String getUrl() { return url; }
        public String getLocalPath() { return localPath; }
        public String getPassword() { return password; }
        public Map<String, String> getHeaders() { return headers; }
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
        private final int nUbatch;
        private final int nGpuLayers;
        private final int nThreads;
        private final boolean useMmap;
        private final boolean useMlock;
        private final boolean embedding;
        private final int poolingType;
        private final int embdNormalize;
        private final boolean flashAttn;
        private final String cacheTypeK;
        private final String cacheTypeV;
        private final CacheType cacheType;

        public InitParams(String modelPath) {
            this(modelPath, 512, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, CacheType.MEMORY);
        }

        public InitParams(String modelPath, int nCtx) {
            this(modelPath, nCtx, null, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, CacheType.MEMORY);
        }

        public InitParams(String modelPath, int nCtx, String chatTemplate) {
            this(modelPath, nCtx, chatTemplate, null, 512, 512, 0, 4, true, false, false, 0, 0, false, null, null, CacheType.MEMORY);
        }

        public InitParams(String modelPath, int nCtx, String chatTemplate, String systemPrompt, int nBatch, int nUbatch, int nGpuLayers, int nThreads, boolean useMmap, boolean useMlock, boolean embedding, int poolingType, int embdNormalize, boolean flashAttn, String cacheTypeK, String cacheTypeV, CacheType cacheType) {
            this.modelPath = modelPath;
            this.nCtx = nCtx;
            this.chatTemplate = chatTemplate;
            this.systemPrompt = systemPrompt;
            this.nBatch = nBatch;
            this.nUbatch = nUbatch;
            this.nGpuLayers = nGpuLayers;
            this.nThreads = nThreads;
            this.useMmap = useMmap;
            this.useMlock = useMlock;
            this.embedding = embedding;
            this.poolingType = poolingType;
            this.embdNormalize = embdNormalize;
            this.flashAttn = flashAttn;
            this.cacheTypeK = cacheTypeK;
            this.cacheTypeV = cacheTypeV;
            this.cacheType = cacheType;
        }

        public String getModelPath() { return modelPath; }
        public int getNCtx() { return nCtx; }
        public String getChatTemplate() { return chatTemplate; }
        public String getSystemPrompt() { return systemPrompt; }
        public int getNBatch() { return nBatch; }
        public int getNUbatch() { return nUbatch; }
        public int getNGpuLayers() { return nGpuLayers; }
        public int getNThreads() { return nThreads; }
        public boolean isUseMmap() { return useMmap; }
        public boolean isUseMlock() { return useMlock; }
        public boolean isEmbedding() { return embedding; }
        public int getPoolingType() { return poolingType; }
        public int getEmbdNormalize() { return embdNormalize; }
        public boolean isFlashAttn() { return flashAttn; }
        public String getCacheTypeK() { return cacheTypeK; }
        public String getCacheTypeV() { return cacheTypeV; }
        public CacheType getCacheType() { return cacheType; }
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

        public CompletionParams(String prompt) {
            this(prompt, 0.8f, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, false);
        }

        public CompletionParams(String prompt, float temperature) {
            this(prompt, temperature, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, false);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens) {
            this(prompt, temperature, maxTokens, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null, null, null, false);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens, int nThreads, int seed, int topK, double topP, double minP, double typicalP, int penaltyLastN, double penaltyRepeat, double penaltyFreq, double penaltyPresent, int mirostat, double mirostatTau, double mirostatEta, boolean ignoreEos, int nProbs, String grammar, List<String> stopSequences, List<String> mediaPaths, TokenCallback tokenCallback) {
            this(prompt, temperature, maxTokens, nThreads, seed, topK, topP, minP, typicalP, penaltyLastN, penaltyRepeat, penaltyFreq, penaltyPresent, mirostat, mirostatTau, mirostatEta, ignoreEos, nProbs, grammar, stopSequences, mediaPaths, tokenCallback, null, false);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens, int nThreads, int seed, int topK, double topP, double minP, double typicalP, int penaltyLastN, double penaltyRepeat, double penaltyFreq, double penaltyPresent, int mirostat, double mirostatTau, double mirostatEta, boolean ignoreEos, int nProbs, String grammar, List<String> stopSequences, List<String> mediaPaths, TokenCallback tokenCallback, List<ChatMessage> chatMessages, boolean useJsonResponse) {
            this.prompt = prompt;
            this.temperature = temperature;
            this.maxTokens = maxTokens;
            this.nThreads = nThreads;
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
        }

        public String getPrompt() { return prompt; }
        public float getTemperature() { return temperature; }
        public int getMaxTokens() { return maxTokens; }
        public int getNThreads() { return nThreads; }
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
    public static native CompletionResult generateCompletion(long contextHandle, CompletionParams params);

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
     * Convenience method for generating audio samples from text using default speaker
     *
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    public static float[] generateAudioFromText(long contextHandle, String text) {
        return generateAudioFromText(contextHandle, text, "{\"speaker\": \"default\"}");
    }

    /**
     * Convenience method for downloading models
     *
     * @param params Download parameters
     * @return Download result, or null if download failed
     */
    public static DownloadResult download(DownloadParams params) {
        return downloadModel(params, null);
    }

    // Private constructor to prevent instantiation
    private LlamaMobile() {
    }
}