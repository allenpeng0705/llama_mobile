// LlamaMobileCapacitorPlugin.java — Capacitor Android plugin (v2, M7)
//
// Implements the `LlamaMobile` bridge used by the v2 TypeScript wrapper:
// libraryVersion / open / generate / abort / modelInfo / close. Heavy work runs
// on a background executor; results resolve on the main thread (§8). The
// native core keeps one active generation per engine and `abort` is
// thread-safe. Registered plugin name: "LlamaMobile".

package com.llamamobile.capacitorplugin;

import android.os.Handler;
import android.os.Looper;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import org.json.JSONArray;
import org.json.JSONObject;

import com.llamamobile.LlamaEngine;
import com.llamamobile.LlamaException;
import com.llamamobile.LlamaChatMessage;
import com.llamamobile.LlamaGenerationRequest;
import com.llamamobile.LlamaSampling;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;

@CapacitorPlugin(name = "LlamaMobile")
public class LlamaMobileCapacitorPlugin extends Plugin {

    private final Map<Integer, LlamaEngine> engines = new ConcurrentHashMap<>();
    private final AtomicInteger nextHandle = new AtomicInteger(1);
    private final ExecutorService bg = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "llama-engine-v2");
        t.setDaemon(true);
        return t;
    });
    private final Handler main = new Handler(Looper.getMainLooper());

    @Override
    protected void handleOnDestroy() {
        engines.values().forEach(LlamaEngine::close);
        engines.clear();
        bg.shutdownNow();
    }

    // ------------------------------------------------------------- helpers

    private void runBg(Runnable task) {
        bg.execute(task);
    }

    private void runMain(Runnable task) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            task.run();
        } else {
            main.post(task);
        }
    }

    private void fail(PluginCall call, int statusCode, String message) {
        runMain(() -> call.reject(message, String.valueOf(statusCode)));
    }

    private void fail(PluginCall call, LlamaException e) {
        fail(call, e.getCode(), e.getMessage() == null ? e.toString() : e.getMessage());
    }

    private static String optString(JSObject o, String key, String def) {
        String v = o.optString(key, def);
        return "null".equals(v) ? def : v;
    }

    /// Resolves a possibly bundle-relative model path ('models/x.gguf') to an
    /// absolute file. The demo web assets ship the same models under the app's
    /// assets/public/models; on first use the file is extracted next to the
    /// app's external files dir so llama.cpp can fopen it (Android scoped
    /// storage hides shared Download/ from other apps). Absolute paths pass
    /// through untouched.
    private String resolveModelPath(String raw) throws java.io.IOException {
        if (raw == null || raw.isEmpty()) return raw;
        if (raw.startsWith("/")) return raw;
        java.io.File dest = new java.io.File(getContext().getExternalFilesDir(null), raw);
        java.io.File f = dest.getCanonicalFile();
        if (f.exists() && f.length() > 0) return f.getAbsolutePath();
        java.io.File parent = f.getParentFile();
        if (parent != null && !parent.exists() && !parent.mkdirs()) {
            throw new java.io.IOException("cannot create dir " + parent);
        }
        try (java.io.InputStream in = getContext().getAssets().open("public/" + raw);
             java.io.OutputStream out = new java.io.FileOutputStream(f)) {
            byte[] buf = new byte[1 << 20];
            int n;
            while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
        }
        return f.getAbsolutePath();
    }

    // ------------------------------------------------------------- methods

    @PluginMethod()
    public void libraryVersion(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("value", LlamaEngine.libraryVersion());
        call.resolve(ret);
    }

    @PluginMethod()
    public void open(PluginCall call) {
        LlamaEngine.Config config = new LlamaEngine.Config();
        config.setModelPath(call.getString("modelPath") == null ? "" : call.getString("modelPath"));
        config.setEngine(call.getInt("engine", 0));
        config.setNGpuLayers(call.getInt("nGpuLayers", 0));
        config.setNCtx(call.getInt("nCtx", 2048));
        config.setNBatch(call.getInt("nBatch", 512));
        config.setNUBatch(call.getInt("nUBatch", 512));
        config.setNThreads(call.getInt("nThreads", 0));
        config.setUseMmap(call.getBoolean("useMmap", true));
        config.setUseMlock(call.getBoolean("useMlock", false));
        config.setEmbedding(call.getBoolean("embedding", false));
        config.setFlashAttention(call.getBoolean("flashAttention", false));
        config.setChat(call.getBoolean("chat", true));
        config.setKvCacheTypeK(call.getString("kvCacheTypeK"));
        config.setKvCacheTypeV(call.getString("kvCacheTypeV"));
        config.setChatTemplate(call.getString("chatTemplate"));
        config.setSystemPrompt(call.getString("systemPrompt"));

        runBg(() -> {
            try {
                config.setModelPath(resolveModelPath(config.getModelPath()));
                LlamaEngine engine = LlamaEngine.open(config);
                int handle = nextHandle.getAndIncrement();
                engines.put(handle, engine);
                JSObject ret = new JSObject();
                ret.put("value", handle);
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                if (t instanceof LlamaException) fail(call, (LlamaException) t);
                else fail(call, -4, String.valueOf(t.getMessage()));
            }
        });
    }

    @PluginMethod()
    public void generate(PluginCall call) {
        Integer handle = call.getInt("handle");
        LlamaEngine engine = handle == null ? null : engines.get(handle);
        if (engine == null) {
            fail(call, -11, "no engine for handle " + handle);
            return;
        }
        // The TS wrapper sends request fields flat on the call data
        // ({ handle, prompt/roles/contents/… }); some callers nest them under
        // "request". Accept both shapes.
        JSObject rq = call.getObject("request");
        if (rq == null) rq = call.getData();
        if (rq == null) {
            fail(call, -1, "request required");
            return;
        }
        LlamaGenerationRequest request = parseRequest(rq);
        runBg(() -> {
            try {
                java.util.List<String> mp = request.getMediaPaths();
                if (mp != null && !mp.isEmpty()) {
                    java.util.List<String> resolved = new java.util.ArrayList<>();
                    for (String p : mp) resolved.add(resolveModelPath(p));
                    request.setMediaPaths(resolved);
                }
                com.llamamobile.LlamaGenerationResult res = engine.generate(request, null);
                JSObject ret = new JSObject();
                ret.put("text", res.getText());
                ret.put("stopReason", res.getStopReason().getValue());
                ret.put("promptTokens", res.getUsage().getPromptTokens());
                ret.put("generatedTokens", res.getUsage().getGeneratedTokens());
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                if (t instanceof LlamaException) fail(call, (LlamaException) t);
                else fail(call, -3, String.valueOf(t.getMessage()));
            }
        });
    }

    @PluginMethod()
    public void abort(PluginCall call) {
        Integer handle = call.getInt("handle");
        LlamaEngine engine = handle == null ? null : engines.get(handle);
        if (engine == null) {
            fail(call, -11, "no engine for handle " + handle);
            return;
        }
        runBg(() -> {
            boolean ok = engine.abort();
            JSObject ret = new JSObject();
            ret.put("value", ok);
            runMain(() -> call.resolve(ret));
        });
    }

    @PluginMethod()
    public void modelInfo(PluginCall call) {
        Integer handle = call.getInt("handle");
        LlamaEngine engine = handle == null ? null : engines.get(handle);
        if (engine == null) {
            fail(call, -11, "no engine for handle " + handle);
            return;
        }
        runBg(() -> {
            try {
                com.llamamobile.LlamaModelInfo info = engine.modelInfo();
                JSObject ret = new JSObject();
                ret.put("nCtx", info.getNCtx());
                ret.put("nEmbd", info.getNEmbd());
                ret.put("modelSizeBytes", info.getModelSizeBytes());
                ret.put("nParams", info.getNParams());
                ret.put("description", info.getDescription());
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                fail(call, -11, String.valueOf(t.getMessage()));
            }
        });
    }

    @PluginMethod()
    public void close(PluginCall call) {
        Integer handle = call.getInt("handle");
        LlamaEngine engine = handle == null ? null : engines.remove(handle);
        if (engine == null) {
            call.resolve();
            return;
        }
        runBg(() -> {
            engine.close();
            runMain(() -> call.resolve());
        });
    }

    // ------------------------------------------------------------- request


    private LlamaEngine engineFor(PluginCall call, int errCode) {
        Integer handle = call.getInt("handle");
        LlamaEngine engine = handle == null ? null : engines.get(handle);
        if (engine == null) {
            fail(call, errCode, "no engine for handle " + handle);
            return null;
        }
        return engine;
    }

    @PluginMethod()
    public void initMultimodal(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        String mmproj = call.getString("mmprojPath");
        if (mmproj == null) { fail(call, -1, "mmprojPath required"); return; }
        runBg(() -> {
            try {
                boolean ok = engine.initMultimodal(resolveModelPath(mmproj));
                JSObject ret = new JSObject();
                ret.put("value", ok);
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                runMain(() -> fail(call, -4, String.valueOf(t.getMessage())));
            }
        });
    }

    @PluginMethod()
    public void tokenize(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        String text = call.getString("text");
        if (text == null) { fail(call, -1, "text required"); return; }
        runBg(() -> {
            int[] tokens = engine.tokenize(text);
            JSObject ret = new JSObject();
            ret.put("value", intsToJS(tokens));
            runMain(() -> call.resolve(ret));
        });
    }

    @PluginMethod()
    public void detokenize(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        com.getcapacitor.JSArray tokens = call.getArray("tokens");
        if (tokens == null) { fail(call, -1, "tokens required"); return; }
        runBg(() -> {
            int[] arr = new int[tokens.length()];
            for (int i = 0; i < arr.length; i++) arr[i] = tokens.optInt(i);
            String text = engine.detokenize(arr);
            JSObject ret = new JSObject();
            ret.put("value", text);
            runMain(() -> call.resolve(ret));
        });
    }

    @PluginMethod()
    public void embed(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        com.getcapacitor.JSArray texts = call.getArray("texts");
        if (texts == null) { fail(call, -1, "texts required"); return; }
        runBg(() -> {
            java.util.List<String> list = new java.util.ArrayList<>();
            for (int i = 0; i < texts.length(); i++) list.add(texts.optString(i));
            java.util.List<float[]> rows = engine.embed(list);
            JSObject ret = new JSObject();
            ret.put("value", floatRowsToJS(rows));
            runMain(() -> call.resolve(ret));
        });
    }


    private static com.getcapacitor.JSArray intsToJS(int[] values) {
        com.getcapacitor.JSArray arr = new com.getcapacitor.JSArray();
        for (int v : values) arr.put(v);
        return arr;
    }

    private static com.getcapacitor.JSArray floatRowsToJS(java.util.List<float[]> rows) {
        com.getcapacitor.JSArray out = new com.getcapacitor.JSArray();
        try {
            for (float[] row : rows) {
                com.getcapacitor.JSArray r = new com.getcapacitor.JSArray();
                for (float v : row) r.put(v);
                out.put(r);
            }
        } catch (org.json.JSONException ignored) {
        }
        return out;
    }

    private LlamaGenerationRequest parseRequest(JSObject rq) {
        JSONObject sampling = rq.optJSONObject("sampling");
        LlamaSampling s = new LlamaSampling();
        if (sampling != null) {
            s.setSeed(sampling.optLong("seed", -1));
            s.setTemperature((float) sampling.optDouble("temperature", 0.8));
            s.setTopK(sampling.optInt("topK", 40));
            s.setTopP((float) sampling.optDouble("topP", 0.95));
            s.setMinP((float) sampling.optDouble("minP", 0.05));
            s.setTypicalP((float) sampling.optDouble("typicalP", 1.0));
            s.setPenaltyRepeat((float) sampling.optDouble("penaltyRepeat", 1.1));
            s.setPenaltyLastN(sampling.optInt("penaltyLastN", 64));
            s.setPenaltyFreq((float) sampling.optDouble("penaltyFreq", 0));
            s.setPenaltyPresent((float) sampling.optDouble("penaltyPresent", 0));
            s.setMirostat(sampling.optInt("mirostat", 0));
            s.setMirostatTau((float) sampling.optDouble("mirostatTau", 5.0));
            s.setMirostatEta((float) sampling.optDouble("mirostatEta", 0.1));
            s.setIgnoreEos(sampling.optBoolean("ignoreEos", false));
        }
        LlamaGenerationRequest request = new LlamaGenerationRequest();
        String prompt = optString(rq, "prompt", null);
        if (prompt != null) request.setPrompt(prompt);
        request.setSampling(s);
        request.setMaxTokens(rq.optInt("maxTokens", 128));
        request.setGrammar(rq.optString("grammar", null));
        request.setJsonSchema(rq.optString("jsonSchema", null));
        JSONArray rolesArr = rq.optJSONArray("roles");
        JSONArray contentsArr = rq.optJSONArray("contents");
        if (rolesArr != null && contentsArr != null) {
            java.util.List<LlamaChatMessage> msgs = new java.util.ArrayList<>();
            for (int i = 0; i < rolesArr.length() && i < contentsArr.length(); i++) {
                msgs.add(new LlamaChatMessage(rolesArr.optString(i), contentsArr.optString(i)));
            }
            request.setMessages(msgs);
        }
        JSONArray mediaArr = rq.optJSONArray("mediaPaths");
        if (mediaArr != null) {
            java.util.List<String> list = new java.util.ArrayList<>();
            for (int i = 0; i < mediaArr.length(); i++) {
                String p = mediaArr.optString(i, null);
                if (p != null && !p.isEmpty() && !"null".equals(p)) list.add(p);
            }
            if (!list.isEmpty()) request.setMediaPaths(list);
        }
        JSONArray stops = rq.optJSONArray("stopSequences");
        if (stops != null) {
            java.util.List<String> list = new java.util.ArrayList<>();
            for (int i = 0; i < stops.length(); i++) list.add(stops.optString(i));
            request.setStopSequences(list);
        }
        return request;
    }
    // MARK: full-surface bridge (v2 parity)

    @PluginMethod()
    public void releaseMultimodal(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        runBg(() -> { JSObject ret = new JSObject(); ret.put("value", engine.releaseMultimodal()); runMain(() -> call.resolve(ret)); });
    }

    @PluginMethod()
    public void multimodalEnabled(PluginCall call) { boolProp(call, engine -> engine.multimodalEnabled()); }
    @PluginMethod()
    public void supportsVision(PluginCall call) { boolProp(call, engine -> engine.supportsVision()); }
    @PluginMethod()
    public void supportsAudio(PluginCall call) { boolProp(call, engine -> engine.supportsAudio()); }
    @PluginMethod()
    public void ttsEnabled(PluginCall call) { boolProp(call, engine -> engine.ttsEnabled()); }

    @PluginMethod()
    public void ttsInit(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        String vocoder = call.getString("vocoderPath");
        if (vocoder == null) { fail(call, -1, "vocoderPath required"); return; }
        runBg(() -> {
            try {
                JSObject ret = new JSObject(); ret.put("value", engine.ttsInit(resolveModelPath(vocoder)));
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                runMain(() -> fail(call, -4, String.valueOf(t.getMessage())));
            }
        });
    }

    @PluginMethod()
    public void ttsSpeak(PluginCall call) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        String text = call.getString("text");
        if (text == null) { fail(call, -1, "text required"); return; }
        int sampleRate = call.getInt("sampleRate", 24000);
        double speed = call.getDouble("speed", 1.0);
        runBg(() -> {
            try {
                com.llamamobile.LlamaTtsResult out = engine.ttsSpeak(text, sampleRate, (float) speed);
                JSArray samples = new JSArray();
                for (int v : out.getPcm()) { samples.put(v); }
                JSObject ret = new JSObject(); ret.put("value", samples);
                runMain(() -> call.resolve(ret));
            } catch (Throwable t) {
                runMain(() -> fail(call, -3, String.valueOf(t)));
            }
        });
    }

    @PluginMethod()
    public void ttsRelease(PluginCall call) { boolProp(call, engine -> engine.ttsRelease()); }

    private void boolProp(PluginCall call, java.util.function.Function<LlamaEngine, Boolean> read) {
        LlamaEngine engine = engineFor(call, -11);
        if (engine == null) return;
        runBg(() -> { JSObject ret = new JSObject(); ret.put("value", read.apply(engine)); runMain(() -> call.resolve(ret)); });
    }

}
