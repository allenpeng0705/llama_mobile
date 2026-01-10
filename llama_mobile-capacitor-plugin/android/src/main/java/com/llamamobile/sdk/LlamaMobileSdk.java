package com.llamamobile.sdk;

import android.content.Context;
import android.util.Log;
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.CacheType;
import com.llamamobile.LlamaMobile.CompletionParams;
import com.llamamobile.LlamaMobile.InitParams;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * High-level Java SDK for LlamaMobile Android
 *
 * This class provides a simplified interface for interacting with the LlamaMobile native library,
 * handling threading, error management, and providing a more developer-friendly API.
 */
public class LlamaMobileSdk {

    private static final String TAG = LlamaMobileSdk.class.getSimpleName();

    private final Context context;
    private final ExecutorService executorService;
    private long contextHandle = 0L;

    /**
     * Callback interface for asynchronous operations
     */
    public interface ResultCallback<T> {
        void onSuccess(T result);
        void onError(Exception e);
    }

    /**
     * Model configuration for Llama model
     */
    public static class ModelConfig {

        private final String modelPath;
        private final int contextSize;
        private final String chatTemplate;
        private final CacheType cacheType;

        private ModelConfig(Builder builder) {
            this.modelPath = builder.modelPath;
            this.contextSize = builder.contextSize;
            this.chatTemplate = builder.chatTemplate;
            this.cacheType = builder.cacheType;
        }

        public String getModelPath() {
            return modelPath;
        }

        public int getContextSize() {
            return contextSize;
        }

        public String getChatTemplate() {
            return chatTemplate;
        }

        public CacheType getCacheType() {
            return cacheType;
        }

        /**
         * Builder for ModelConfig
         */
        public static class Builder {

            private final String modelPath;
            private int contextSize = 512;
            private String chatTemplate = null;
            private CacheType cacheType = CacheType.MEMORY;

            public Builder(String modelPath) {
                this.modelPath = modelPath;
            }

            public Builder contextSize(int contextSize) {
                this.contextSize = contextSize;
                return this;
            }

            public Builder chatTemplate(String chatTemplate) {
                this.chatTemplate = chatTemplate;
                return this;
            }

            public Builder cacheType(CacheType cacheType) {
                this.cacheType = cacheType;
                return this;
            }

            public ModelConfig build() {
                return new ModelConfig(this);
            }
        }
    }

    /**
     * Configuration for text generation
     */
    public static class GenerationConfig {

        private final String prompt;
        private final float temperature;
        private final int maxTokens;

        private GenerationConfig(Builder builder) {
            this.prompt = builder.prompt;
            this.temperature = builder.temperature;
            this.maxTokens = builder.maxTokens;
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

        /**
         * Builder for GenerationConfig
         */
        public static class Builder {

            private final String prompt;
            private float temperature = 0.8f;
            private int maxTokens = 100;

            public Builder(String prompt) {
                this.prompt = prompt;
            }

            public Builder temperature(float temperature) {
                this.temperature = temperature;
                return this;
            }

            public Builder maxTokens(int maxTokens) {
                this.maxTokens = maxTokens;
                return this;
            }

            public GenerationConfig build() {
                return new GenerationConfig(this);
            }
        }
    }

    /**
     * Result of text generation
     */
    public static class GenerationResult {

        private final String generatedText;
        private final boolean success;
        private final String errorMessage;

        private GenerationResult(Builder builder) {
            this.generatedText = builder.generatedText;
            this.success = builder.success;
            this.errorMessage = builder.errorMessage;
        }

        public String getGeneratedText() {
            return generatedText;
        }

        public boolean isSuccess() {
            return success;
        }

        public String getErrorMessage() {
            return errorMessage;
        }

        /**
         * Builder for GenerationResult
         */
        public static class Builder {

            private String generatedText = "";
            private boolean success = false;
            private String errorMessage = null;

            public Builder generatedText(String generatedText) {
                this.generatedText = generatedText;
                return this;
            }

            public Builder success(boolean success) {
                this.success = success;
                return this;
            }

            public Builder errorMessage(String errorMessage) {
                this.errorMessage = errorMessage;
                return this;
            }

            public GenerationResult build() {
                return new GenerationResult(this);
            }
        }
    }

    /**
     * Listener for generation events
     */
    public interface GenerationListener {
        void onGenerationStart(String prompt);
        void onGenerationComplete(GenerationResult result);
        void onError(Exception e);
    }

    /**
     * Constructor for LlamaMobileSdk
     *
     * @param context Android context
     */
    public LlamaMobileSdk(Context context) {
        this.context = context;
        this.executorService = Executors.newSingleThreadExecutor();
    }

    /**
     * Loads a Llama model synchronously
     *
     * @param config Model configuration
     * @return true if the model was loaded successfully, false otherwise
     */
    public boolean loadModel(ModelConfig config) {
        try {
            if (contextHandle != 0L) {
                releaseModel();
            }

            // Use single-argument constructor with default values
            InitParams initParams = new InitParams(config.getModelPath());

            contextHandle = LlamaMobile.initContext(initParams);
            return contextHandle != 0L;
        } catch (Exception e) {
            Log.e(TAG, "Error loading model: " + e.getMessage(), e);
            return false;
        }
    }

    /**
     * Loads a Llama model asynchronously
     *
     * @param config Model configuration
     * @param callback Callback to receive result
     */
    public void loadModelAsync(ModelConfig config, final ResultCallback<Boolean> callback) {
        executorService.execute(() -> {
            try {
                boolean result = loadModel(config);
                if (result) {
                    callback.onSuccess(true);
                } else {
                    callback.onError(new Exception("Failed to load model"));
                }
            } catch (Exception e) {
                callback.onError(e);
            }
        });
    }

    /**
     * Generates text synchronously
     *
     * @param config Generation configuration
     * @return GenerationResult containing the generated text
     */
    public GenerationResult generate(GenerationConfig config) {
        try {
            if (contextHandle == 0L) {
                throw new IllegalStateException("Model not loaded. Call loadModel() first.");
            }

            CompletionParams completionParams = new CompletionParams(config.getPrompt(), config.getTemperature(), config.getMaxTokens());

            com.llamamobile.LlamaMobile.CompletionResult completionResult = LlamaMobile.generateCompletion(contextHandle, completionParams);
            String generatedText = completionResult != null ? completionResult.getText() : "";
            return new GenerationResult.Builder().generatedText(generatedText).success(completionResult != null).build();
        } catch (Exception e) {
            Log.e(TAG, "Error generating text: " + e.getMessage(), e);
            return new GenerationResult.Builder().success(false).errorMessage(e.getMessage()).build();
        }
    }

    /**
     * Generates text asynchronously
     *
     * @param config Generation configuration
     * @param listener Listener to receive generation events
     */
    public void generateAsync(GenerationConfig config, final GenerationListener listener) {
        executorService.execute(() -> {
            try {
                listener.onGenerationStart(config.getPrompt());
                GenerationResult result = generate(config);
                listener.onGenerationComplete(result);
            } catch (Exception e) {
                listener.onError(e);
            }
        });
    }

    /**
     * Releases the loaded model
     */
    public void releaseModel() {
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle);
            contextHandle = 0L;
        }
    }

    /**
     * Checks if a model is currently loaded
     *
     * @return true if a model is loaded, false otherwise
     */
    public boolean isModelLoaded() {
        return contextHandle != 0L;
    }

    /**
     * Closes the SDK and releases all resources
     */
    public void close() {
        releaseModel();
        executorService.shutdown();
    }
}
