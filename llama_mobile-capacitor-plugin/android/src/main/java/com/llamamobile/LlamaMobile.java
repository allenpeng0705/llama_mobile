package com.llamamobile;

import java.util.ArrayList;
import java.util.List;

/**
 * LlamaMobile Android Library
 *
 * This class provides a Java wrapper around the llama_mobile C library,
 * allowing Android applications to interact with llama models.
 */
public class LlamaMobile {

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
     * Token callback interface for streaming generation
     */
    public interface TokenCallback {
        boolean onToken(String token);
    }

    /**
     * Completion result interface
     */
    public interface CompletionResult {
        String getText();
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

        public InitParams(
            String modelPath,
            int nCtx,
            String chatTemplate,
            String systemPrompt,
            int nBatch,
            int nUbatch,
            int nGpuLayers,
            int nThreads,
            boolean useMmap,
            boolean useMlock,
            boolean embedding,
            int poolingType,
            int embdNormalize,
            boolean flashAttn,
            String cacheTypeK,
            String cacheTypeV,
            CacheType cacheType
        ) {
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

        public String getModelPath() {
            return modelPath;
        }

        public int getNCtx() {
            return nCtx;
        }

        public String getChatTemplate() {
            return chatTemplate;
        }

        public String getSystemPrompt() {
            return systemPrompt;
        }

        public int getNBatch() {
            return nBatch;
        }

        public int getNUbatch() {
            return nUbatch;
        }

        public int getNGpuLayers() {
            return nGpuLayers;
        }

        public int getNThreads() {
            return nThreads;
        }

        public boolean isUseMmap() {
            return useMmap;
        }

        public boolean isUseMlock() {
            return useMlock;
        }

        public boolean isEmbedding() {
            return embedding;
        }

        public int getPoolingType() {
            return poolingType;
        }

        public int getEmbdNormalize() {
            return embdNormalize;
        }

        public boolean isFlashAttn() {
            return flashAttn;
        }

        public String getCacheTypeK() {
            return cacheTypeK;
        }

        public String getCacheTypeV() {
            return cacheTypeV;
        }

        public CacheType getCacheType() {
            return cacheType;
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
        private final TokenCallback tokenCallback;

        public CompletionParams(String prompt) {
            this(prompt, 0.8f, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null);
        }

        public CompletionParams(String prompt, float temperature) {
            this(prompt, temperature, 100, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null);
        }

        public CompletionParams(String prompt, float temperature, int maxTokens) {
            this(prompt, temperature, maxTokens, 4, -1, 40, 0.9, 0.05, 1.0, 64, 1.1, 0.0, 0.0, 0, 5.0, 0.1, false, 0, null, null, null);
        }

        public CompletionParams(
            String prompt,
            float temperature,
            int maxTokens,
            int nThreads,
            int seed,
            int topK,
            double topP,
            double minP,
            double typicalP,
            int penaltyLastN,
            double penaltyRepeat,
            double penaltyFreq,
            double penaltyPresent,
            int mirostat,
            double mirostatTau,
            double mirostatEta,
            boolean ignoreEos,
            int nProbs,
            String grammar,
            List<String> stopSequences,
            TokenCallback tokenCallback
        ) {
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
            this.tokenCallback = tokenCallback;
        }

        public String getPrompt() {
            return prompt;
        }

        public float getTemperature() {
            return temperature;
        }

        public int getMaxTokens() {
            return maxTokens;
        }

        public int getNThreads() {
            return nThreads;
        }

        public int getSeed() {
            return seed;
        }

        public int getTopK() {
            return topK;
        }

        public double getTopP() {
            return topP;
        }

        public double getMinP() {
            return minP;
        }

        public double getTypicalP() {
            return typicalP;
        }

        public int getPenaltyLastN() {
            return penaltyLastN;
        }

        public double getPenaltyRepeat() {
            return penaltyRepeat;
        }

        public double getPenaltyFreq() {
            return penaltyFreq;
        }

        public double getPenaltyPresent() {
            return penaltyPresent;
        }

        public int getMirostat() {
            return mirostat;
        }

        public double getMirostatTau() {
            return mirostatTau;
        }

        public double getMirostatEta() {
            return mirostatEta;
        }

        public boolean isIgnoreEos() {
            return ignoreEos;
        }

        public int getNProbs() {
            return nProbs;
        }

        public String getGrammar() {
            return grammar;
        }

        public List<String> getStopSequences() {
            return stopSequences;
        }

        public TokenCallback getTokenCallback() {
            return tokenCallback;
        }
    }

    /**
     * Loads the native libraries
     */
    static {
        System.loadLibrary("llama_mobile");
        System.loadLibrary("llama_mobile_jni");
    }

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

    // Private constructor to prevent instantiation
    private LlamaMobile() {}
}
