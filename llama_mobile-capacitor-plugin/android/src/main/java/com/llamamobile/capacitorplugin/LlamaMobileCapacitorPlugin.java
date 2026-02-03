package com.llamamobile.capacitorplugin;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.PluginMethod;
import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.TTSOptions;
import com.llamamobile.LlamaMobile.SpeechResult;
import com.llamamobile.LlamaMobile.SpeechMetadata;
import com.llamamobile.LlamaMobile.TTSError;
import com.llamamobile.LlamaMobile.Result;
import com.llamamobile.LlamaMobile.ProgressCallback;
import com.llamamobile.LlamaMobile.AudioChunkCallback;
import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@CapacitorPlugin(name = "LlamaMobileCapacitorPlugin")
public class LlamaMobileCapacitorPlugin extends Plugin {

    private final ExecutorService executor = Executors.newCachedThreadPool();
    private final Map<Long, Long> contextHandles = new HashMap<>();
    private long nextContextHandle = 1;

    private synchronized long getNextContextHandle() {
        return nextContextHandle++;
    }

    private Long getNativeContextHandle(long contextHandle) {
        return contextHandles.get(contextHandle);
    }

    @Override
    protected void handleOnDestroy() {
        executor.shutdown();
        for (Long contextHandle : contextHandles.values()) {
            LlamaMobile.releaseContext(contextHandle);
        }
        contextHandles.clear();
    }

    // MARK: - Initialization

    @PluginMethod
    public void initContext(PluginCall call) {
        String modelPath = call.getString("modelPath");
        int nCtx = call.getInt("nCtx", 2048);
        int nGpuLayers = call.getInt("nGpuLayers", 0);
        int nThreads = call.getInt("nThreads", 4);
        boolean embedding = call.getBoolean("embedding", false);
        int poolingType = call.getInt("poolingType", 0);
        int embdNormalize = call.getInt("embdNormalize", 1);

        if (modelPath == null) {
            call.reject("modelPath is required");
            return;
        }

        executor.execute(() -> {
            try {
                LlamaMobile.InitParams params = new LlamaMobile.InitParams(
                    modelPath, nCtx, null, null, 512, 512, nGpuLayers, nThreads, 
                    true, false, embedding, poolingType, embdNormalize, false, 
                    null, null, false, null
                );
                long nativeContextHandle = LlamaMobile.initContext(params);

                long handle = getNextContextHandle();
                contextHandles.put(handle, nativeContextHandle);

                JSObject ret = new JSObject();
                ret.put("contextHandle", handle);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to initialize context: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void releaseContext(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = contextHandles.remove(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseContext(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release context: " + e.getMessage());
            }
        });
    }

    // MARK: - Completion

    @PluginMethod
    public void generateCompletion(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        JSObject params = call.getObject("params");
        String prompt = params != null ? params.optString("prompt", null) : null;
        int maxTokens = params != null ? params.optInt("maxTokens", 128) : 128;
        double temperature = params != null ? params.optDouble("temperature", 0.8) : 0.8;

        if (contextHandle == -1 || prompt == null) {
            call.reject("contextHandle and params.prompt are required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams(
                    prompt, (float) temperature, maxTokens
                );
                LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(
                    nativeContextHandle, completionParams
                );

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
                call.reject("Failed to generate completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateOpenAICompletion(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String openAIJSON = call.getString("openAIJSON");

        if (contextHandle == -1 || openAIJSON == null) {
            call.reject("contextHandle and openAIJSON are required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.CompletionResult result = LlamaMobile.generateOpenAICompletion(
                    nativeContextHandle, openAIJSON
                );

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
                call.reject("Failed to generate OpenAI completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void stopCompletion(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.stopCompletion(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to stop completion: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void loadGrammar(PluginCall call) {
        String filePath = call.getString("filePath");

        if (filePath == null) {
            call.reject("filePath is required");
            return;
        }

        executor.execute(() -> {
            try {
                String grammar = LlamaMobile.loadGrammar(filePath);
                JSObject ret = new JSObject();
                ret.put("grammar", grammar);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to load grammar: " + e.getMessage());
            }
        });
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

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean success = LlamaMobile.initVocoder(
                    nativeContextHandle, vocoderModelPath
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to initialize vocoder: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void releaseVocoder(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseVocoder(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release vocoder: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isVocoderEnabled(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean enabled = LlamaMobile.isVocoderEnabled(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("enabled", enabled);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check vocoder status: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getTTSType(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.TTSModelType type = LlamaMobile.getTTSType(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("type", type.name());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get TTS type: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateAudioFromText(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        String speakerJson = call.getString("speakerJson", "{\"speaker\": \"default\"}");

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                float[] audioSamples = LlamaMobile.generateAudioFromText(
                    nativeContextHandle, text, speakerJson
                );

                JSArray audioArray = new JSArray();
                for (float sample : audioSamples) {
                    audioArray.put(sample);
                }

                JSObject ret = new JSObject();
                ret.put("audio", audioArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate audio from text: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeech(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");
        String speakerJson = call.getString("speakerJson", "{\"speaker\": \"default\"}");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechResult, TTSError> result = LlamaMobile.generateSpeech(
                    nativeContextHandle, text, optionsBuilder.build(),
                    new ProgressCallback() {
                        @Override
                        public void onProgress(float progress) {
                            notifyListeners("progress", new JSObject().put("progress", progress));
                        }
                    }
                );

                if (result.isSuccess()) {
                    SpeechResult speechResult = result.getValue();
                    JSArray audioArray = new JSArray();
                    for (short sample : speechResult.getAudioSamples()) {
                        audioArray.put(sample);
                    }

                    JSObject ret = new JSObject();
                    ret.put("audio", audioArray);
                    ret.put("sampleRate", speechResult.getSampleRate());
                    ret.put("duration", speechResult.getDuration());
                    ret.put("methodUsed", speechResult.getMethodUsed().toString());
                    call.resolve(ret);
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeechSync(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechResult, TTSError> result = LlamaMobile.generateSpeechSync(
                    nativeContextHandle, text, optionsBuilder.build()
                );

                if (result.isSuccess()) {
                    SpeechResult speechResult = result.getValue();
                    JSArray audioArray = new JSArray();
                    for (short sample : speechResult.getAudioSamples()) {
                        audioArray.put(sample);
                    }

                    JSObject ret = new JSObject();
                    ret.put("audio", audioArray);
                    ret.put("sampleRate", speechResult.getSampleRate());
                    ret.put("duration", speechResult.getDuration());
                    ret.put("methodUsed", speechResult.getMethodUsed().toString());
                    call.resolve(ret);
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech sync: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech sync: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeechStream(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechMetadata, TTSError> result = LlamaMobile.generateSpeechStream(
                    nativeContextHandle, text, optionsBuilder.build(),
                    new ProgressCallback() {
                        @Override
                        public void onProgress(float progress) {
                            notifyListeners("progress", new JSObject().put("progress", progress));
                        }
                    },
                    new AudioChunkCallback() {
                        @Override
                        public void onAudioChunk(short[] audioChunk) {
                            JSArray audioArray = new JSArray();
                            for (short sample : audioChunk) {
                                audioArray.put(sample);
                            }
                            notifyListeners("audioChunk", new JSObject().put("audio", audioArray));
                        }
                    }
                );

                if (result.isSuccess()) {
                    SpeechMetadata metadata = result.getValue();
                    JSObject ret = new JSObject();
                    ret.put("sampleRate", metadata.getSampleRate());
                    ret.put("duration", metadata.getDuration());
                    ret.put("methodUsed", metadata.getMethodUsed().toString());
                    call.resolve(ret);
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech stream: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech stream: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void generateSpeechStreamForLongText(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);
        String method = call.getString("method", "best");

        TTSOptions.Builder optionsBuilder = new TTSOptions.Builder();
        optionsBuilder.sampleRate(sampleRate);

        switch (method.toLowerCase()) {
            case "custom":
                // optionsBuilder.method(LlamaMobile.TTSMethod.CUSTOM_WORKFLOW);
                break;
            case "builtin":
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
            default:
                // optionsBuilder.method(LlamaMobile.TTSMethod.BUILT_IN);
                break;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                Result<SpeechMetadata, TTSError> result = LlamaMobile.generateSpeechStreamForLongText(
                    nativeContextHandle, text, optionsBuilder.build(),
                    new ProgressCallback() {
                        @Override
                        public void onProgress(float progress) {
                            notifyListeners("progress", new JSObject().put("progress", progress));
                        }
                    },
                    new AudioChunkCallback() {
                        @Override
                        public void onAudioChunk(short[] audioChunk) {
                            JSArray audioArray = new JSArray();
                            for (short sample : audioChunk) {
                                audioArray.put(sample);
                            }
                            notifyListeners("audioChunk", new JSObject().put("audio", audioArray));
                        }
                    }
                );

                if (result.isSuccess()) {
                    SpeechMetadata metadata = result.getValue();
                    JSObject ret = new JSObject();
                    ret.put("sampleRate", metadata.getSampleRate());
                    ret.put("duration", metadata.getDuration());
                    ret.put("methodUsed", metadata.getMethodUsed().toString());
                    call.resolve(ret);
                } else {
                    TTSError error = result.getError();
                    call.reject("Failed to generate speech stream: " + error.getMessage());
                }
            } catch (Exception e) {
                call.reject("Failed to generate speech stream: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void saveAudioToWav(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String filePath = call.getString("filePath");
        JSArray audioDataArray = call.getArray("audioData");

        if (contextHandle == -1 || filePath == null || audioDataArray == null) {
            call.reject("contextHandle, filePath, and audioData are required");
            return;
        }

        int sampleRate = call.getInt("sampleRate", 24000);

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                float[] audioData = new float[(int) audioDataArray.length()];
                for (int i = 0; i < audioDataArray.length(); i++) {
                    audioData[i] = (float) audioDataArray.getDouble(i);
                }

                boolean success = LlamaMobile.saveAudioToWav(
                    nativeContextHandle, filePath, audioData, sampleRate
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to save audio to WAV: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void playAudio(PluginCall call) {
        JSArray audioDataArray = call.getArray("audioData");
        int sampleRate = call.getInt("sampleRate", 24000);

        if (audioDataArray == null) {
            call.reject("audioData is required");
            return;
        }

        executor.execute(() -> {
            JSObject ret = new JSObject();
            ret.put("success", false);
            call.resolve(ret);
        });
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

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean success = LlamaMobile.initMultimodal(
                    nativeContextHandle, mmprojPath, useGpu
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to initialize multimodal: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void releaseMultimodal(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.releaseMultimodal(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to release multimodal: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isMultimodalEnabled(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean enabled = LlamaMobile.isMultimodalEnabled(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("enabled", enabled);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check multimodal status: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void supportsVision(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean supported = LlamaMobile.supportsVision(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("supported", supported);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check vision support: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void supportsAudio(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean supported = LlamaMobile.supportsAudio(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("supported", supported);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check audio support: " + e.getMessage());
            }
        });
    }

    // MARK: - LoRA

    @PluginMethod
    public void applyLoraAdapters(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        JSArray adaptersArray = call.getArray("adapters");

        if (contextHandle == -1 || adaptersArray == null) {
            call.reject("contextHandle and adapters are required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.LoraAdapter[] adapters = new LlamaMobile.LoraAdapter[(int) adaptersArray.length()];
                for (int i = 0; i < adaptersArray.length(); i++) {
                    JSONObject adapterObj = adaptersArray.getJSONObject(i);
                    String path = adapterObj.getString("path");
                    double scale = adapterObj.has("scale") ? adapterObj.getDouble("scale") : 1.0;
                    adapters[i] = new LlamaMobile.LoraAdapter(path, (float) scale);
                }

                boolean success = LlamaMobile.applyLoraAdapters(
                    nativeContextHandle, adapters
                );

                JSObject ret = new JSObject();
                ret.put("success", success);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to apply LoRA adapters: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void removeLoraAdapters(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.removeLoraAdapters(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to remove LoRA adapters: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getLoadedLoraAdapters(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.LoraAdapter[] adapters = LlamaMobile.getLoadedLoraAdapters(
                    nativeContextHandle
                );

                JSArray adaptersArray = new JSArray();
                for (LlamaMobile.LoraAdapter adapter : adapters) {
                    JSObject adapterObj = new JSObject();
                    adapterObj.put("path", adapter.getPath());
                    adapterObj.put("scale", adapter.getScale());
                    adaptersArray.put(adapterObj);
                }

                JSObject ret = new JSObject();
                ret.put("adapters", adaptersArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get loaded LoRA adapters: " + e.getMessage());
            }
        });
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

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                LlamaMobile.ConversationResult result = LlamaMobile.generateResponse(
                    nativeContextHandle, userMessage, maxTokens
                );

                JSObject ret = new JSObject();
                ret.put("text", result.getText());
                ret.put("tokensGenerated", result.getTokensGenerated());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate response: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void clearConversation(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle != null) {
                    LlamaMobile.clearConversation(nativeContextHandle);
                }
                call.resolve();
            } catch (Exception e) {
                call.reject("Failed to clear conversation: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void isConversationActive(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                boolean active = LlamaMobile.isConversationActive(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("active", active);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to check conversation status: " + e.getMessage());
            }
        });
    }

    // MARK: - Embeddings

    @PluginMethod
    public void generateEmbeddings(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        String text = call.getString("text");

        if (contextHandle == -1 || text == null) {
            call.reject("contextHandle and text are required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                float[] embedding = LlamaMobile.generateEmbeddings(
                    nativeContextHandle, text
                );

                JSArray embeddingArray = new JSArray();
                for (float value : embedding) {
                    embeddingArray.put(value);
                }

                JSObject ret = new JSObject();
                ret.put("embedding", embeddingArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to generate embeddings: " + e.getMessage());
            }
        });
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

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int[] tokens = LlamaMobile.tokenize(nativeContextHandle, text);

                JSArray tokensArray = new JSArray();
                for (int token : tokens) {
                    tokensArray.put(token);
                }

                JSObject ret = new JSObject();
                ret.put("tokens", tokensArray);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to tokenize: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void detokenize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);
        JSArray tokensArray = call.getArray("tokens");

        if (contextHandle == -1 || tokensArray == null) {
            call.reject("contextHandle and tokens are required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int[] tokens = new int[(int) tokensArray.length()];
                for (int i = 0; i < tokensArray.length(); i++) {
                    tokens[i] = tokensArray.getInt(i);
                }

                String text = LlamaMobile.detokenize(nativeContextHandle, tokens);

                JSObject ret = new JSObject();
                ret.put("text", text);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to detokenize: " + e.getMessage());
            }
        });
    }

    // MARK: - Model Info

    @PluginMethod
    public void getContextWindowSize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int size = LlamaMobile.getContextWindowSize(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("size", size);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get context window size: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getEmbeddingDimension(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                int dimension = LlamaMobile.getEmbeddingDimension(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("dimension", dimension);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get embedding dimension: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelDescription(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                String description = LlamaMobile.getModelDescription(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("description", description);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model description: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelSize(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                long size = LlamaMobile.getModelSize(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("size", size);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model size: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void getModelParametersCount(PluginCall call) {
        long contextHandle = call.getLong("contextHandle", -1L);

        if (contextHandle == -1) {
            call.reject("contextHandle is required");
            return;
        }

        executor.execute(() -> {
            try {
                Long nativeContextHandle = getNativeContextHandle(contextHandle);
                if (nativeContextHandle == null) {
                    call.reject("Invalid context handle");
                    return;
                }

                long count = LlamaMobile.getModelParametersCount(nativeContextHandle);
                JSObject ret = new JSObject();
                ret.put("count", count);
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to get model parameters count: " + e.getMessage());
            }
        });
    }

    // MARK: - Download

    @PluginMethod
    public void downloadModel(PluginCall call) {
        String url = call.getString("url");
        String localPath = call.getString("localPath");

        if (url == null || localPath == null) {
            call.reject("url and localPath are required");
            return;
        }

        executor.execute(() -> {
            try {
                LlamaMobile.DownloadParams.Builder paramsBuilder = new LlamaMobile.DownloadParams.Builder(url, "", localPath);
                LlamaMobile.DownloadParams params = paramsBuilder.build();
                LlamaMobile.DownloadResult result = LlamaMobile.downloadModel(params, null);

                JSObject ret = new JSObject();
                ret.put("success", result.isSuccess());
                ret.put("localPath", result.getLocalPath());
                ret.put("errorMessage", result.getErrorMessage());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to download model: " + e.getMessage());
            }
        });
    }

    @PluginMethod
    public void downloadHfFile(PluginCall call) {
        String repoId = call.getString("repoId");
        String filename = call.getString("filename");
        String localPath = call.getString("localPath");
        String bearerToken = call.getString("bearerToken");
        boolean offline = call.getBoolean("offline", false);

        if (repoId == null || filename == null || localPath == null) {
            call.reject("repoId, filename, and localPath are required");
            return;
        }

        executor.execute(() -> {
            try {
                LlamaMobile.DownloadResult result = LlamaMobile.downloadHfFile(
                    repoId, filename, localPath, bearerToken, offline, null
                );

                JSObject ret = new JSObject();
                ret.put("success", result.isSuccess());
                ret.put("localPath", result.getLocalPath());
                ret.put("errorMessage", result.getErrorMessage());
                call.resolve(ret);
            } catch (Exception e) {
                call.reject("Failed to download HuggingFace file: " + e.getMessage());
            }
        });
    }

    // MARK: - Chat

    @PluginMethod
    public void setChatTemplate(PluginCall call) {
        call.resolve();
    }

    @PluginMethod
    public void getModelChatTemplate(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("template", "");
        call.resolve(ret);
    }

    @PluginMethod
    public void formatChatMessages(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("formattedPrompt", "");
        call.resolve(ret);
    }
}
