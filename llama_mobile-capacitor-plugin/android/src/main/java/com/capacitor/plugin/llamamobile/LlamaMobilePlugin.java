package com.capacitor.plugin.llamamobile;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONException;

@CapacitorPlugin(name = "LlamaMobile")
public class LlamaMobilePlugin extends Plugin {

    private LlamaMobileImpl implementation;

    @Override
    public void load() {
        super.load();
        this.implementation = new LlamaMobileImpl(getContext());
    }

    @PluginMethod
    public void initialize(PluginCall call) {
        JSObject params = call.getObject("params");
        if (params == null) {
            call.reject("Missing params");
            return;
        }

        try {
            boolean success = implementation.initialize(params);
            JSObject result = new JSObject();
            result.put("success", success);
            call.resolve(result);
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
    }

    @PluginMethod
    public void generate(PluginCall call) {
        JSObject params = call.getObject("params");
        if (params == null) {
            call.reject("Missing params");
            return;
        }

        try {
            JSObject result = implementation.generate(params);
            if (result != null) {
                call.resolve(result);
            } else {
                call.reject("Generation failed");
            }
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
    }

    @PluginMethod
    public void multimodalCompletion(PluginCall call) {
        JSObject params = call.getObject("params");
        JSArray mediaPathsArray = call.getArray("mediaPaths");

        if (params == null || mediaPathsArray == null) {
            call.reject("Missing params or mediaPaths");
            return;
        }

        List<String> mediaPaths = new ArrayList<>();
        try {
            for (int i = 0; i < mediaPathsArray.length(); i++) {
                mediaPaths.add(mediaPathsArray.getString(i));
            }

            JSObject result = implementation.multimodalCompletion(params, mediaPaths);
            if (result != null) {
                call.resolve(result);
            } else {
                call.reject("Generation failed");
            }
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
    }

    @PluginMethod
    public void stopCompletion(PluginCall call) {
        implementation.stopCompletion();
        call.resolve();
    }

    @PluginMethod
    public void tokenize(PluginCall call) {
        String text = call.getString("text");
        if (text == null) {
            call.reject("Missing text");
            return;
        }

        List<Integer> tokens = implementation.tokenize(text);
        if (tokens != null) {
            JSObject result = new JSObject();
            result.put("tokens", tokens);
            call.resolve(result);
        } else {
            call.reject("Tokenization failed");
        }
    }

    @PluginMethod
    public void detokenize(PluginCall call) {
        JSArray tokensArray = call.getArray("tokens");
        if (tokensArray == null) {
            call.reject("Missing tokens");
            return;
        }

        List<Integer> tokens = new ArrayList<>();
        try {
            for (int i = 0; i < tokensArray.length(); i++) {
                tokens.add(tokensArray.getInt(i));
            }

            String text = implementation.detokenize(tokens);
            if (text != null) {
                JSObject result = new JSObject();
                result.put("text", text);
                call.resolve(result);
            } else {
                call.reject("Detokenization failed");
            }
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
    }

    @PluginMethod
    public void generateEmbeddings(PluginCall call) {
        String text = call.getString("text");
        if (text == null) {
            call.reject("Missing text");
            return;
        }

        List<Double> embeddings = implementation.generateEmbeddings(text);
        if (embeddings != null) {
            JSObject result = new JSObject();
            result.put("embeddings", embeddings);
            call.resolve(result);
        } else {
            call.reject("Embedding generation failed");
        }
    }

    @PluginMethod
    public void applyLoraAdapters(PluginCall call) {
        JSArray adaptersArray = call.getArray("adapters");
        if (adaptersArray == null) {
            call.reject("Missing adapters");
            return;
        }

        List<JSObject> adapters = new ArrayList<>();
        try {
            for (int i = 0; i < adaptersArray.length(); i++) {
                adapters.add(adaptersArray.getJSObject(i));
            }

            boolean success = implementation.applyLoraAdapters(adapters);
            JSObject result = new JSObject();
            result.put("success", success);
            call.resolve(result);
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
    }

    @PluginMethod
    public void removeLoraAdapters(PluginCall call) {
        implementation.removeLoraAdapters();
        call.resolve();
    }

    @PluginMethod
    public void initMultimodal(PluginCall call) {
        String mmprojPath = call.getString("mmprojPath");
        Boolean useGpu = call.getBoolean("useGpu");

        if (mmprojPath == null || useGpu == null) {
            call.reject("Missing mmprojPath or useGpu");
            return;
        }

        boolean success = implementation.initMultimodal(mmprojPath, useGpu);
        JSObject result = new JSObject();
        result.put("success", success);
        call.resolve(result);
    }

    @PluginMethod
    public void isMultimodalEnabled(PluginCall call) {
        boolean isEnabled = implementation.isMultimodalEnabled();
        JSObject result = new JSObject();
        result.put("enabled", isEnabled);
        call.resolve(result);
    }

    @PluginMethod
    public void releaseMultimodal(PluginCall call) {
        implementation.releaseMultimodal();
        call.resolve();
    }

    @PluginMethod
    public void generateResponse(PluginCall call) {
        String userMessage = call.getString("userMessage");
        Integer maxTokens = call.getInt("maxTokens");

        if (userMessage == null || maxTokens == null) {
            call.reject("Missing userMessage or maxTokens");
            return;
        }

        JSObject result = implementation.generateResponse(userMessage, maxTokens);
        if (result != null) {
            call.resolve(result);
        } else {
            call.reject("Response generation failed");
        }
    }

    @PluginMethod
    public void clearConversation(PluginCall call) {
        implementation.clearConversation();
        call.resolve();
    }

    @PluginMethod
    public void getGrammarContent(PluginCall call) {
        String grammarName = call.getString("grammarName");
        if (grammarName == null) {
            call.reject("Missing grammarName");
            return;
        }

        String content = implementation.getGrammarContent(grammarName);
        if (content != null) {
            JSObject result = new JSObject();
            result.put("content", content);
            call.resolve(result);
        } else {
            call.reject("Grammar not found");
        }
    }

    @PluginMethod
    public void release(PluginCall call) {
        implementation.release();
        call.resolve();
    }
}
