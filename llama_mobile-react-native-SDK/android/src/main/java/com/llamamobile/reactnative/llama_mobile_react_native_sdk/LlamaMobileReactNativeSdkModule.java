package com.llamamobile.reactnative.llama_mobile_react_native_sdk;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;

import com.llamamobile.LlamaMobile;
import com.llamamobile.LlamaMobile.CompletionResult;
import com.llamamobile.LlamaMobile.InitParams;
import com.llamamobile.LlamaMobile.CompletionParams;
import com.llamamobile.LlamaMobile.LoraAdapter;
import com.llamamobile.LlamaMobile.ConversationResult;

import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.Arguments;

public class LlamaMobileReactNativeSdkModule extends ReactContextBaseJavaModule {
    private static ReactApplicationContext reactContext;
    private long contextHandle = 0;

    public LlamaMobileReactNativeSdkModule(ReactApplicationContext context) {
        super(context);
        reactContext = context;
    }

    @Override
    public String getName() {
        return "LlamaMobileReactNativeSdk";
    }

    @Override
    public Map<String, Object> getConstants() {
        final Map<String, Object> constants = new HashMap<>();
        constants.put("VERSION", "1.0.0");
        return constants;
    }

    @ReactMethod
    public void initialize() {
        // No explicit initialization needed, library is loaded by LlamaMobile class
    }

    @ReactMethod
    public void loadModel(String modelPath, ReadableMap params, Promise promise) {
        try {
            // Free existing context if it exists
            if (contextHandle != 0) {
                LlamaMobile.releaseContext(contextHandle);
                contextHandle = 0;
            }
            
            // Extract parameters with defaults
            int nThreads = params.hasKey("n_threads") ? params.getInt("n_threads") : 4;
            int nBatch = params.hasKey("n_batch") ? params.getInt("n_batch") : 512;
            int nGpuLayers = params.hasKey("n_gpu_layers") ? params.getInt("n_gpu_layers") : 0;
            int nCtx = params.hasKey("n_ctx") ? params.getInt("n_ctx") : 2048;
            boolean useMmap = params.hasKey("use_mmap") ? params.getBoolean("use_mmap") : true;
            boolean useMlock = params.hasKey("use_mlock") ? params.getBoolean("use_mlock") : false;
            boolean embedding = params.hasKey("embedding") ? params.getBoolean("embedding") : false;
            
            // Create init params matching C API structure
            InitParams initParams = new InitParams(
                modelPath,
                nCtx,
                null,  // chatTemplate
                null,  // systemPrompt
                nBatch,
                512,   // nUbatch
                nGpuLayers,
                nThreads,
                useMmap,
                useMlock,
                embedding,
                0,     // poolingType
                0,     // embdNormalize
                false, // flashAttn
                null,  // cacheTypeK
                null,  // cacheTypeV
                LlamaMobile.CacheType.MEMORY
            );
            
            contextHandle = LlamaMobile.initContext(initParams);
            
            if (contextHandle != 0) {
                promise.resolve("Model loaded successfully");
            } else {
                promise.reject("LOAD_MODEL_ERROR", "Failed to load model");
            }
        } catch (Exception e) {
            promise.reject("LOAD_MODEL_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void generateText(String prompt, ReadableMap params, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("GENERATE_TEXT_ERROR", "No model loaded");
                return;
            }
            
            // Extract parameters with defaults
            int maxTokens = params.hasKey("max_tokens") ? params.getInt("max_tokens") : 100;
            double temperature = params.hasKey("temperature") ? params.getDouble("temperature") : 0.7;
            int topK = params.hasKey("top_k") ? params.getInt("top_k") : 40;
            double topP = params.hasKey("top_p") ? params.getDouble("top_p") : 0.9;
            double minP = params.hasKey("min_p") ? params.getDouble("min_p") : 0.05;
            double penaltyRepeat = params.hasKey("penalty_repeat") ? params.getDouble("penalty_repeat") : 1.1;
            
            // Handle stop sequences
            String[] stopSequences = null;
            if (params.hasKey("stopSequences") && params.getArray("stopSequences") != null) {
                ReadableArray stopArray = params.getArray("stopSequences");
                stopSequences = new String[stopArray.size()];
                for (int i = 0; i < stopArray.size(); i++) {
                    stopSequences[i] = stopArray.getString(i);
                }
            }
            
            // Handle grammar
            String grammar = null;
            if (params.hasKey("grammar") && !params.isNull("grammar")) {
                grammar = params.getString("grammar");
            }
            
            // Create completion params
            CompletionParams completionParams = new CompletionParams(
                prompt,
                (float) temperature,
                maxTokens,
                4,      // nThreads (ignored, using context's value)
                -1,     // seed
                topK,
                (float) topP,
                (float) minP,
                1.0f,   // typicalP
                64,     // penaltyLastN
                (float) penaltyRepeat,
                0.0f,   // penaltyFreq
                0.0f,   // penaltyPresent
                0,      // mirostat
                5.0f,   // mirostatTau
                0.1f,   // mirostatEta
                false,  // ignoreEos
                0,      // nProbs
                grammar,
                stopSequences,
                null    // tokenCallback (handled in streaming)
            );
            
            // Generate completion
            CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
            
            if (result != null) {
                // Create response matching C API structure
                WritableMap response = new WritableNativeMap();
                response.putString("text", result.getText());
                response.putInt("tokensGenerated", result.getTokensGenerated());
                response.putInt("tokensEvaluated", result.getTokensEvaluated());
                response.putBoolean("truncated", result.isTruncated());
                response.putBoolean("stoppedEos", result.isStoppedEos());
                response.putBoolean("stoppedWord", result.isStoppedWord());
                response.putBoolean("stoppedLimit", result.isStoppedLimit());
                
                promise.resolve(response);
            } else {
                promise.reject("GENERATE_TEXT_ERROR", "Failed to generate text");
            }
        } catch (Exception e) {
            promise.reject("GENERATE_TEXT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void streamText(String prompt, ReadableMap params, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("STREAM_TEXT_ERROR", "No model loaded");
                return;
            }
            
            // Extract parameters with defaults
            int maxTokens = params.hasKey("max_tokens") ? params.getInt("max_tokens") : 100;
            double temperature = params.hasKey("temperature") ? params.getDouble("temperature") : 0.7;
            int topK = params.hasKey("top_k") ? params.getInt("top_k") : 40;
            double topP = params.hasKey("top_p") ? params.getDouble("top_p") : 0.9;
            double minP = params.hasKey("min_p") ? params.getDouble("min_p") : 0.05;
            double penaltyRepeat = params.hasKey("penalty_repeat") ? params.getDouble("penalty_repeat") : 1.1;
            
            // Handle stop sequences
            String[] stopSequences = null;
            if (params.hasKey("stopSequences") && params.getArray("stopSequences") != null) {
                ReadableArray stopArray = params.getArray("stopSequences");
                stopSequences = new String[stopArray.size()];
                for (int i = 0; i < stopArray.size(); i++) {
                    stopSequences[i] = stopArray.getString(i);
                }
            }
            
            // Handle grammar
            String grammar = null;
            if (params.hasKey("grammar") && !params.isNull("grammar")) {
                grammar = params.getString("grammar");
            }
            
            // Create completion params with token callback
            CompletionParams completionParams = new CompletionParams(
                prompt,
                (float) temperature,
                maxTokens,
                4,      // nThreads (ignored, using context's value)
                -1,     // seed
                topK,
                (float) topP,
                (float) minP,
                1.0f,   // typicalP
                64,     // penaltyLastN
                (float) penaltyRepeat,
                0.0f,   // penaltyFreq
                0.0f,   // penaltyPresent
                0,      // mirostat
                5.0f,   // mirostatTau
                0.1f,   // mirostatEta
                false,  // ignoreEos
                0,      // nProbs
                grammar,
                stopSequences,
                token -> {
                    // Send token event to JavaScript
                    WritableMap params = Arguments.createMap();
                    params.putString("token", token);
                    getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                            .emit("onToken", params);
                    return true;
                }
            );
            
            // Generate completion in a background thread
            new Thread(() -> {
                try {
                    CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
                    
                    if (result != null) {
                        // Send completion event
                        WritableMap completionParams = Arguments.createMap();
                        completionParams.putString("text", result.getText());
                        completionParams.putInt("tokensGenerated", result.getTokensGenerated());
                        completionParams.putInt("tokensEvaluated", result.getTokensEvaluated());
                        completionParams.putBoolean("truncated", result.isTruncated());
                        completionParams.putBoolean("stoppedEos", result.isStoppedEos());
                        completionParams.putBoolean("stoppedWord", result.isStoppedWord());
                        completionParams.putBoolean("stoppedLimit", result.isStoppedLimit());
                        
                        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                .emit("onCompletion", completionParams);
                    } else {
                        // Send error event
                        WritableMap errorParams = Arguments.createMap();
                        errorParams.putString("error", "Failed to generate text");
                        getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                                .emit("onError", errorParams);
                    }
                } catch (Exception e) {
                    // Send error event
                    WritableMap errorParams = Arguments.createMap();
                    errorParams.putString("error", e.getMessage());
                    getReactApplicationContext().getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                            .emit("onError", errorParams);
                }
            }).start();
            
            promise.resolve("Streaming started");
        } catch (Exception e) {
            promise.reject("STREAM_TEXT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void stopGeneration() {
        try {
            if (contextHandle != 0) {
                LlamaMobile.stopCompletion(contextHandle);
            }
        } catch (Exception e) {
            // Ignore errors during stop
        }
    }

    @ReactMethod
    public void unloadModel() {
        try {
            if (contextHandle != 0) {
                LlamaMobile.releaseContext(contextHandle);
                contextHandle = 0;
            }
        } catch (Exception e) {
            // Ignore errors during unload
        }
    }

    @ReactMethod
    public void tokenize(String text, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("TOKENIZE_ERROR", "No model loaded");
                return;
            }
            
            int[] tokens = LlamaMobile.tokenize(contextHandle, text);
            
            if (tokens != null) {
                WritableArray tokenArray = new WritableNativeArray();
                for (int token : tokens) {
                    tokenArray.pushInt(token);
                }
                promise.resolve(tokenArray);
            } else {
                promise.reject("TOKENIZE_ERROR", "Failed to tokenize");
            }
        } catch (Exception e) {
            promise.reject("TOKENIZE_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void detokenize(ReadableArray tokens, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("DETOKENIZE_ERROR", "No model loaded");
                return;
            }
            
            int[] tokenArray = new int[tokens.size()];
            for (int i = 0; i < tokens.size(); i++) {
                tokenArray[i] = tokens.getInt(i);
            }
            
            String result = LlamaMobile.detokenize(contextHandle, tokenArray);
            
            if (result != null) {
                promise.resolve(result);
            } else {
                promise.reject("DETOKENIZE_ERROR", "Failed to detokenize");
            }
        } catch (Exception e) {
            promise.reject("DETOKENIZE_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void generateEmbeddings(String text, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("EMBEDDINGS_ERROR", "No model loaded");
                return;
            }
            
            float[] embeddings = LlamaMobile.generateEmbeddings(contextHandle, text);
            
            if (embeddings != null) {
                WritableArray embeddingArray = new WritableNativeArray();
                for (float value : embeddings) {
                    embeddingArray.pushDouble(value);
                }
                promise.resolve(embeddingArray);
            } else {
                promise.reject("EMBEDDINGS_ERROR", "Failed to generate embeddings");
            }
        } catch (Exception e) {
            promise.reject("EMBEDDINGS_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void applyLoraAdapters(ReadableArray adapters, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("LORA_ERROR", "No model loaded");
                return;
            }
            
            int adapterCount = adapters.size();
            if (adapterCount == 0) {
                promise.resolve("No adapters to apply");
                return;
            }
            
            // Convert ReadableArray to LoraAdapter array
            LoraAdapter[] loraAdapters = new LoraAdapter[adapterCount];
            
            for (int i = 0; i < adapterCount; i++) {
                ReadableMap adapterMap = adapters.getMap(i);
                String path = adapterMap.getString("path");
                double scale = adapterMap.getDouble("scale");
                loraAdapters[i] = new LoraAdapter(path, (float) scale);
            }
            
            boolean success = LlamaMobile.applyLoraAdapters(contextHandle, loraAdapters);
            
            if (success) {
                promise.resolve("LoRA adapters applied successfully");
            } else {
                promise.reject("LORA_ERROR", "Failed to apply LoRA adapters");
            }
        } catch (Exception e) {
            promise.reject("LORA_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void removeLoraAdapters(Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.resolve("No model loaded, nothing to remove");
                return;
            }
            
            LlamaMobile.removeLoraAdapters(contextHandle);
            promise.resolve("LoRA adapters removed successfully");
        } catch (Exception e) {
            promise.reject("LORA_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void initMultimodal(String mmprojPath, boolean useGpu, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("MULTIMODAL_ERROR", "No model loaded");
                return;
            }
            
            boolean success = LlamaMobile.initMultimodal(contextHandle, mmprojPath, useGpu);
            
            if (success) {
                promise.resolve("Multimodal initialized successfully");
            } else {
                promise.reject("MULTIMODAL_ERROR", "Failed to initialize multimodal");
            }
        } catch (Exception e) {
            promise.reject("MULTIMODAL_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void isMultimodalEnabled(Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.resolve(false);
                return;
            }
            
            boolean isEnabled = LlamaMobile.isMultimodalEnabled(contextHandle);
            promise.resolve(isEnabled);
        } catch (Exception e) {
            promise.reject("MULTIMODAL_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void releaseMultimodal(Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.resolve("No model loaded, nothing to release");
                return;
            }
            
            LlamaMobile.releaseMultimodal(contextHandle);
            promise.resolve("Multimodal resources released");
        } catch (Exception e) {
            promise.reject("MULTIMODAL_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void generateConversationResponse(String userMessage, int maxTokens, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("CONVERSATION_ERROR", "No model loaded");
                return;
            }
            
            ConversationResult result = LlamaMobile.generateResponse(contextHandle, userMessage, maxTokens);
            
            if (result != null) {
                WritableMap response = new WritableNativeMap();
                response.putString("text", result.getText());
                response.putInt("timeToFirstToken", result.getTimeToFirstToken());
                response.putInt("totalTime", result.getTotalTime());
                response.putInt("tokensGenerated", result.getTokensGenerated());
                promise.resolve(response);
            } else {
                promise.reject("CONVERSATION_ERROR", "Failed to generate conversation response");
            }
        } catch (Exception e) {
            promise.reject("CONVERSATION_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void clearConversation(Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.resolve("No model loaded, nothing to clear");
                return;
            }
            
            LlamaMobile.clearConversation(contextHandle);
            promise.resolve("Conversation cleared successfully");
        } catch (Exception e) {
            promise.reject("CONVERSATION_ERROR", e.getMessage());
        }
    }
}
