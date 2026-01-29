package com.llamamobile.capacitorplugin;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.llamamobile.LlamaMobile;

@CapacitorPlugin(name = "LlamaMobileCapacitorPlugin")
public class LlamaMobileCapacitorPluginPlugin extends Plugin {

    private LlamaMobileCapacitorPlugin implementation = new LlamaMobileCapacitorPlugin();

    // MARK: - Initialization
    
    @PluginMethod
    public void initContext(PluginCall call) {
        String modelPath = call.getString("modelPath");
        int nCtx = call.getInt("nCtx", 2048);
        int nGpuLayers = call.getInt("nGpuLayers", 0);
        int nThreads = call.getInt("nThreads", 4);

        if (modelPath == null) {
            call.reject("modelPath is required");
            return;
        }

        long contextHandle = implementation.initContext(modelPath, nCtx, nGpuLayers, nThreads);
        JSObject ret = new JSObject();
        ret.put("contextHandle", contextHandle);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void releaseContext(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.releaseContext(contextHandle);
        call.resolve();
    }
    
    // MARK: - Completion
    
    @PluginMethod
    public void generateCompletion(PluginCall call) {
        try {
            long contextHandle = call.getLong("contextHandle", -1L);
            JSObject params = call.getObject("params");
            String prompt = params != null ? params.getString("prompt") : null;
            int maxTokens = params != null ? (params.has("maxTokens") ? params.getInt("maxTokens") : 128) : 128;
            double temperature = params != null ? (params.has("temperature") ? params.getDouble("temperature") : 0.8) : 0.8;

            if (contextHandle == -1 || prompt == null) {
                call.reject("contextHandle and params.prompt are required");
                return;
            }

            LlamaMobile.CompletionResult result = implementation.generateCompletion(contextHandle, prompt, maxTokens, temperature);
            JSObject ret = new JSObject();
            ret.put("text", result.getText());
            ret.put("tokensGenerated", result.getTokensGenerated());
            ret.put("tokensEvaluated", result.getTokensEvaluated());
            ret.put("truncated", result.isTruncated());
            ret.put("stoppedEos", result.isStoppedEos());
            ret.put("stoppedWord", result.isStoppedWord());
            ret.put("stoppedLimit", result.isStoppedLimit());
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }
    
    @PluginMethod
    public void generateOpenAICompletion(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String openAIJSON = call.getString("openAIJSON");

        if (contextHandle == -1 || openAIJSON == null) {
            call.reject("contextHandle and openAIJSON are required");
            return;
        }

        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("text", "");
        ret.put("tokensGenerated", 0);
        ret.put("tokensEvaluated", 0);
        ret.put("truncated", false);
        ret.put("stoppedEos", false);
        ret.put("stoppedWord", false);
        ret.put("stoppedLimit", false);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void stopCompletion(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.stopCompletion(contextHandle);
        call.resolve();
    }
    
    // MARK: - TTS
    
    @PluginMethod
    public void initVocoder(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String vocoderModelPath = call.getString("vocoderModelPath");

        if (contextHandle == -1 || vocoderModelPath == null) {
            call.reject("contextHandle and vocoderModelPath are required");
            return;
        }

        boolean success = implementation.initVocoder(contextHandle, vocoderModelPath);
        JSObject ret = new JSObject();
        ret.put("success", success);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void releaseVocoder(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.releaseVocoder(contextHandle);
        call.resolve();
    }
    
    @PluginMethod
    public void isVocoderEnabled(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        boolean enabled = implementation.isVocoderEnabled(contextHandle);
        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getTTSType(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        String type = implementation.getTTSType(contextHandle);
        JSObject ret = new JSObject();
        ret.put("type", type);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void generateAudioFromText(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("audio", new JSArray());
        call.resolve(ret);
    }
    
    @PluginMethod
    public void saveAudioToWav(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String filePath = call.getString("filePath");

        if (contextHandle == -1 || filePath == null) {
            call.reject("contextHandle and filePath are required");
            return;
        }

        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("success", false);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void playAudio(PluginCall call) {
        JSArray audioData = call.getArray("audioData");
        int sampleRate = call.getInt("sampleRate", 24000);

        if (audioData == null) {
            call.reject("audioData is required");
            return;
        }

        // Simplified implementation - Android audio playback would need proper implementation
        JSObject ret = new JSObject();
        ret.put("success", false);
        call.resolve(ret);
    }
    
    // MARK: - Multimodal
    
    @PluginMethod
    public void initMultimodal(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String mmprojPath = call.getString("mmprojPath");
        boolean useGpu = call.getBoolean("useGpu", true);

        if (contextHandle == -1 || mmprojPath == null) {
            call.reject("contextHandle and mmprojPath are required");
            return;
        }

        boolean success = implementation.initMultimodal(contextHandle, mmprojPath, useGpu);
        JSObject ret = new JSObject();
        ret.put("success", success);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void releaseMultimodal(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.releaseMultimodal(contextHandle);
        call.resolve();
    }
    
    @PluginMethod
    public void isMultimodalEnabled(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        boolean enabled = implementation.isMultimodalEnabled(contextHandle);
        JSObject ret = new JSObject();
        ret.put("enabled", enabled);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void supportsVision(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        boolean supported = implementation.supportsVision(contextHandle);
        JSObject ret = new JSObject();
        ret.put("supported", supported);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void supportsAudio(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        boolean supported = implementation.supportsAudio(contextHandle);
        JSObject ret = new JSObject();
        ret.put("supported", supported);
        call.resolve(ret);
    }
    
    // MARK: - LoRA
    
    @PluginMethod
    public void applyLoraAdapters(PluginCall call) {
        try {
            long contextHandle = call.getLong("contextHandle", -1L);
            JSArray adaptersArray = call.getArray("adapters");

            if (contextHandle == -1 || adaptersArray == null) {
                call.reject("contextHandle and adapters are required");
                return;
            }

            int length = (int) adaptersArray.length();
            Object[] adapters = new Object[length];
            for (int i = 0; i < length; i++) {
                adapters[i] = adaptersArray.get(i);
            }

            boolean success = implementation.applyLoraAdapters(contextHandle, adapters);
            JSObject ret = new JSObject();
            ret.put("success", success);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }
    
    @PluginMethod
    public void removeLoraAdapters(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.removeLoraAdapters(contextHandle);
        call.resolve();
    }
    
    @PluginMethod
    public void getLoadedLoraAdapters(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("adapters", new JSArray());
        call.resolve(ret);
    }
    
    // MARK: - Conversation
    
    @PluginMethod
    public void generateResponse(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String userMessage = call.getString("userMessage");
        int maxTokens = call.getInt("maxTokens", 128);

        if (contextHandle == -1 || userMessage == null) {
            call.reject("contextHandle and userMessage are required");
            return;
        }

        LlamaMobile.CompletionResult result = implementation.generateResponse(contextHandle, userMessage, maxTokens);
        JSObject ret = new JSObject();
        ret.put("text", result.getText());
        ret.put("tokensGenerated", result.getTokensGenerated());
        ret.put("tokensEvaluated", result.getTokensEvaluated());
        ret.put("truncated", result.isTruncated());
        ret.put("stoppedEos", result.isStoppedEos());
        ret.put("stoppedWord", result.isStoppedWord());
        ret.put("stoppedLimit", result.isStoppedLimit());
        call.resolve(ret);
    }
    
    @PluginMethod
    public void clearConversation(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        implementation.clearConversation(contextHandle);
        call.resolve();
    }
    
    @PluginMethod
    public void isConversationActive(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        boolean active = implementation.isConversationActive(contextHandle);
        JSObject ret = new JSObject();
        ret.put("active", active);
        call.resolve(ret);
    }
    
    // MARK: - Embeddings
    
    @PluginMethod
    public void generateEmbeddings(PluginCall call) {
        try {
            long contextHandle = call.getLong("contextHandle", -1L);
            String text = call.getString("text");

            if (contextHandle == -1 || text == null) {
                call.reject("contextHandle and text are required");
                return;
            }

            float[] embedding = implementation.generateEmbeddings(contextHandle, text);
            JSArray embeddingArray = new JSArray();
            for (float value : embedding) {
                embeddingArray.put(value);
            }
            JSObject ret = new JSObject();
            ret.put("embedding", embeddingArray);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }
    
    // MARK: - Tokenization
    
    @PluginMethod
    public void tokenize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int[] tokens = implementation.tokenize(contextHandle, text);
        JSArray tokensArray = new JSArray();
        for (int token : tokens) {
            tokensArray.put(token);
        }
        JSObject ret = new JSObject();
        ret.put("tokens", tokensArray);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void detokenize(PluginCall call) {
        try {
            long contextHandle = call.getLong("contextHandle", -1L);
            JSArray tokensArray = call.getArray("tokens");

            if (contextHandle == -1 || tokensArray == null) {
                call.reject("contextHandle and tokens are required");
                return;
            }

            int tokenLength = (int) tokensArray.length();
            int[] tokens = new int[tokenLength];
            for (int i = 0; i < tokenLength; i++) {
                tokens[i] = tokensArray.getInt(i);
            }

            String text = implementation.detokenize(contextHandle, tokens);
            JSObject ret = new JSObject();
            ret.put("text", text);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage());
        }
    }
    
    // MARK: - Model Info
    
    @PluginMethod
    public void getContextWindowSize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        int size = implementation.getContextWindowSize(contextHandle);
        JSObject ret = new JSObject();
        ret.put("size", size);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getEmbeddingDimension(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        int dimension = implementation.getEmbeddingDimension(contextHandle);
        JSObject ret = new JSObject();
        ret.put("dimension", dimension);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getModelDescription(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        String description = implementation.getModelDescription(contextHandle);
        JSObject ret = new JSObject();
        ret.put("description", description);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getModelSize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        long size = implementation.getModelSize(contextHandle);
        JSObject ret = new JSObject();
        ret.put("size", size);
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getModelParametersCount(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        long count = implementation.getModelParametersCount(contextHandle);
        JSObject ret = new JSObject();
        ret.put("count", count);
        call.resolve(ret);
    }
    
    // MARK: - Download
    
    @PluginMethod
    public void downloadModel(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("success", false);
        ret.put("localPath", "");
        ret.put("errorMessage", "Not implemented");
        call.resolve(ret);
    }
    
    @PluginMethod
    public void downloadHfFile(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("success", false);
        ret.put("localPath", "");
        ret.put("errorMessage", "Not implemented");
        call.resolve(ret);
    }
    
    // MARK: - Grammar
    
    @PluginMethod
    public void getJsonGrammar(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("grammar", "");
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getArithmeticGrammar(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("grammar", "");
        call.resolve(ret);
    }
    
    @PluginMethod
    public void getCGrammar(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("grammar", "");
        call.resolve(ret);
    }
    
    // MARK: - Chat
    
    @PluginMethod
    public void setChatTemplate(PluginCall call) {
        // Simplified implementation
        call.resolve();
    }
    
    @PluginMethod
    public void formatChatMessages(PluginCall call) {
        // Simplified implementation
        JSObject ret = new JSObject();
        ret.put("formattedPrompt", "");
        call.resolve(ret);
    }
}

