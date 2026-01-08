package com.capacitor.plugin.llamamobile;

import android.content.Context;
import com.getcapacitor.JSObject;
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.CacheType;
import com.llamamobile.LlamaMobile.CompletionParams;
import com.llamamobile.LlamaMobile.CompletionResult;
import com.llamamobile.LlamaMobile.GrammarName;
import com.llamamobile.LlamaMobile.InitParams;
import org.json.JSONException;

public class LlamaMobileImpl {
    private long contextHandle;
    private Context context;

    public LlamaMobileImpl(Context context) {
        this.context = context;
        this.contextHandle = 0;
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

    public String generate(JSObject params) throws JSONException {
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

        CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
        return result != null ? result.getText() : null;
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
        }
    }
}
