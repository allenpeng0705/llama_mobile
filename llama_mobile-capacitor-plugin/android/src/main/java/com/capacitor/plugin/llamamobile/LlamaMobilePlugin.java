package com.capacitor.plugin.llamamobile;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
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
            String output = implementation.generate(params);
            if (output != null) {
                JSObject result = new JSObject();
                result.put("output", output);
                call.resolve(result);
            } else {
                call.reject("Generation failed");
            }
        } catch (JSONException e) {
            call.reject("JSON error: " + e.getMessage());
        }
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
