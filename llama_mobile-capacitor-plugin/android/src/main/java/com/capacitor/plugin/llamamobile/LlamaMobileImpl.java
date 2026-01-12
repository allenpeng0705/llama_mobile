package com.capacitor.plugin.llamamobile;

import android.content.Context;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.CacheType;
import com.llamamobile.LlamaMobile.CompletionParams;
import com.llamamobile.LlamaMobile.CompletionResult;
import com.llamamobile.LlamaMobile.GrammarName;
import com.llamamobile.LlamaMobile.InitParams;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.List;

public class LlamaMobileImpl {
    private long contextHandle;
    private Context context;
    private boolean isMultimodalInitialized;

    public LlamaMobileImpl(Context context) {
        this.context = context;
        this.contextHandle = 0;
        this.isMultimodalInitialized = false;
    }

    public boolean initialize(JSObject params) throws JSONException {
        String modelPath = params.getString("modelPath");
        if (modelPath == null) {
            return false;
        }

        int nCtx = params.has("nCtx") ? params.getInt("nCtx") : 2048;
        String chatTemplate = params.getString("chatTemplate");
        String systemPrompt = params.getString("systemPrompt");
        int nBatch = params.has("nBatch") ? params.getInt("nBatch") : 512;
        int nUbatch = params.has("nUbatch") ? params.getInt("nUbatch") : 512;
        int nGpuLayers = params.has("nGpuLayers") ? params.getInt("nGpuLayers") : 0;
        int nThreads = params.has("nThreads") ? params.getInt("nThreads") : 4;
        boolean useMmap = params.has("useMmap") ? params.getBool("useMmap") : true;
        boolean useMlock = params.has("useMlock") ? params.getBool("useMlock") : false;
        boolean embedding = params.has("embedding") ? params.getBool("embedding") : false;
        int poolingType = params.has("poolingType") ? params.getInt("poolingType") : 0;
        boolean embdNormalize = params.has("embdNormalize") ? params.getBool("embdNormalize") : false;
        boolean flashAttn = params.has("flashAttn") ? params.getBool("flashAttn") : false;
        String cacheTypeK = params.getString("cacheTypeK");
        String cacheTypeV = params.getString("cacheTypeV");

        InitParams initParams = new InitParams(
            modelPath,
            nCtx,
            chatTemplate,
            systemPrompt,
            nBatch,
            nUbatch,
            nGpuLayers,
            nThreads,
            useMmap,
            useMlock,
            embedding,
            poolingType,
            embdNormalize ? 1 : 0,
            flashAttn,
            cacheTypeK,
            cacheTypeV,
            CacheType.MEMORY
        );

        contextHandle = LlamaMobile.initContext(initParams);
        return contextHandle != 0;
    }

    public JSObject generate(JSObject params) throws JSONException {
        if (contextHandle == 0) {
            return null;
        }

        String prompt = params.getString("prompt");
        if (prompt == null) {
            return null;
        }

        float temperature = params.has("temperature") ? ((Double) params.get("temperature")).floatValue() : 0.8f;
        int maxTokens = params.has("maxTokens") ? params.getInt("maxTokens") : 100;
        int nThreads = params.has("nThreads") ? params.getInt("nThreads") : 4;
        int seed = params.has("seed") ? params.getInt("seed") : -1;
        int topK = params.has("topK") ? params.getInt("topK") : 40;
        double topP = params.has("topP") ? params.getDouble("topP") : 0.95;
        double minP = params.has("minP") ? params.getDouble("minP") : 0.05;
        double typicalP = params.has("typicalP") ? params.getDouble("typicalP") : 1.0;
        int penaltyLastN = params.has("penaltyLastN") ? params.getInt("penaltyLastN") : 64;
        double penaltyRepeat = params.has("penaltyRepeat") ? params.getDouble("penaltyRepeat") : 1.1;
        double penaltyFreq = params.has("penaltyFreq") ? params.getDouble("penaltyFreq") : 0.0;
        double penaltyPresent = params.has("penaltyPresent") ? params.getDouble("penaltyPresent") : 0.0;
        int mirostat = params.has("mirostat") ? params.getInt("mirostat") : 0;
        double mirostatTau = params.has("mirostatTau") ? params.getDouble("mirostatTau") : 5.0;
        double mirostatEta = params.has("mirostatEta") ? params.getDouble("mirostatEta") : 0.1;
        boolean ignoreEos = params.has("ignoreEos") ? params.getBool("ignoreEos") : false;
        String grammar = params.getString("grammar");
        JSArray stopSequencesArray = params.getArray("stopSequences");
        List<String> stopSequences = null;
        if (stopSequencesArray != null) {
            stopSequences = new ArrayList<>();
            for (int i = 0; i < stopSequencesArray.length(); i++) {
                stopSequences.add(stopSequencesArray.getString(i));
            }
        }

        CompletionParams completionParams = new CompletionParams(
            prompt,
            temperature,
            maxTokens,
            nThreads,
            seed,
            topK,
            topP,
            minP,
            typicalP,
            penaltyLastN,
            penaltyRepeat,
            penaltyFreq,
            penaltyPresent,
            mirostat,
            mirostatTau,
            mirostatEta,
            ignoreEos,
            0,
            grammar,
            stopSequences,
            null
        );

        CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
        if (result != null) {
            JSObject jsResult = new JSObject();
            jsResult.put("output", result.getText());
            jsResult.put("tokensGenerated", 0);
            jsResult.put("tokensEvaluated", 0);
            jsResult.put("truncated", false);
            jsResult.put("stoppedEos", false);
            jsResult.put("stoppedWord", false);
            jsResult.put("stoppedLimit", false);
            return jsResult;
        }
        return null;
    }

    public JSObject multimodalCompletion(JSObject params, List<String> mediaPaths) throws JSONException {
        if (contextHandle == 0) {
            return null;
        }

        String prompt = params.getString("prompt");
        if (prompt == null) {
            return null;
        }

        float temperature = params.has("temperature") ? ((Double) params.get("temperature")).floatValue() : 0.8f;
        int maxTokens = params.has("maxTokens") ? params.getInt("maxTokens") : 100;
        int nThreads = params.has("nThreads") ? params.getInt("nThreads") : 4;
        int seed = params.has("seed") ? params.getInt("seed") : -1;
        int topK = params.has("topK") ? params.getInt("topK") : 40;
        double topP = params.has("topP") ? params.getDouble("topP") : 0.95;
        double minP = params.has("minP") ? params.getDouble("minP") : 0.05;
        double typicalP = params.has("typicalP") ? params.getDouble("typicalP") : 1.0;
        int penaltyLastN = params.has("penaltyLastN") ? params.getInt("penaltyLastN") : 64;
        double penaltyRepeat = params.has("penaltyRepeat") ? params.getDouble("penaltyRepeat") : 1.1;
        double penaltyFreq = params.has("penaltyFreq") ? params.getDouble("penaltyFreq") : 0.0;
        double penaltyPresent = params.has("penaltyPresent") ? params.getDouble("penaltyPresent") : 0.0;
        int mirostat = params.has("mirostat") ? params.getInt("mirostat") : 0;
        double mirostatTau = params.has("mirostatTau") ? params.getDouble("mirostatTau") : 5.0;
        double mirostatEta = params.has("mirostatEta") ? params.getDouble("mirostatEta") : 0.1;
        boolean ignoreEos = params.has("ignoreEos") ? params.getBool("ignoreEos") : false;
        String grammar = params.getString("grammar");

        CompletionParams completionParams = new CompletionParams(
            prompt,
            temperature,
            maxTokens,
            nThreads,
            seed,
            topK,
            topP,
            minP,
            typicalP,
            penaltyLastN,
            penaltyRepeat,
            penaltyFreq,
            penaltyPresent,
            mirostat,
            mirostatTau,
            mirostatEta,
            ignoreEos,
            0,
            grammar,
            null,
            null
        );

        // TODO: Implement multimodal completion when the native API is available
        CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
        if (result != null) {
            JSObject jsResult = new JSObject();
            jsResult.put("output", result.getText());
            jsResult.put("tokensGenerated", 0);
            jsResult.put("tokensEvaluated", 0);
            jsResult.put("truncated", false);
            jsResult.put("stoppedEos", false);
            jsResult.put("stoppedWord", false);
            jsResult.put("stoppedLimit", false);
            return jsResult;
        }
        return null;
    }

    public void stopCompletion() {
        // TODO: Implement stop completion when the native API is available
    }

    public List<Integer> tokenize(String text) {
        // TODO: Implement tokenize when the native API is available
        return null;
    }

    public String detokenize(List<Integer> tokens) {
        // TODO: Implement detokenize when the native API is available
        return null;
    }

    public List<Double> generateEmbeddings(String text) {
        // TODO: Implement generateEmbeddings when the native API is available
        return null;
    }

    public boolean applyLoraAdapters(List<JSObject> adapters) {
        // TODO: Implement applyLoraAdapters when the native API is available
        return false;
    }

    public void removeLoraAdapters() {
        // TODO: Implement removeLoraAdapters when the native API is available
    }

    public boolean initMultimodal(String mmprojPath, boolean useGpu) {
        // TODO: Implement initMultimodal when the native API is available
        isMultimodalInitialized = true;
        return true;
    }

    public boolean isMultimodalEnabled() {
        return isMultimodalInitialized;
    }

    public void releaseMultimodal() {
        // TODO: Implement releaseMultimodal when the native API is available
        isMultimodalInitialized = false;
    }

    public JSObject generateResponse(String userMessage, int maxTokens) {
        // TODO: Implement generateResponse when the native API is available
        JSObject result = new JSObject();
        result.put("text", "");
        result.put("timeToFirstToken", 0);
        result.put("totalTime", 0);
        result.put("tokensGenerated", 0);
        return result;
    }

    public void clearConversation() {
        // TODO: Implement clearConversation when the native API is available
    }

    public String getGrammarContent(String grammarName) {
        GrammarName androidGrammarName;
        try {
            // Convert from TypeScript enum format to Java enum format
            // e.g., jsonArr -> JSON_ARR
            String javaGrammarName = grammarName.replaceFirst("Arr$", "_ARR").toUpperCase();
            androidGrammarName = GrammarName.valueOf(javaGrammarName);
        } catch (IllegalArgumentException e) {
            return null;
        }

        return LlamaMobile.grammarContent(context, androidGrammarName);
    }

    public void release() {
        if (contextHandle != 0) {
            LlamaMobile.releaseContext(contextHandle);
            contextHandle = 0;
            isMultimodalInitialized = false;
        }
    }
}
