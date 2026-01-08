package com.llamamobile.reactnative.llama_mobile_react_native_sdk;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import com.llamamobile.LlamaMobile;

import java.util.HashMap;
import java.util.Map;

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
            // Extract parameters with defaults
            int nThreads = params.hasKey("n_threads") ? params.getInt("n_threads") : 4;
            int nBatch = params.hasKey("n_batch") ? params.getInt("n_batch") : 512;
            int nGpuLayers = params.hasKey("n_gpu_layers") ? params.getInt("n_gpu_layers") : 0;
            int nCtx = params.hasKey("n_ctx") ? params.getInt("n_ctx") : 4096;
            
            // Use the intermediate SDK's Java API
            LlamaMobile.InitParams initParams = new LlamaMobile.InitParams(
                modelPath,
                nCtx,
                null,  // chatTemplate
                null,  // systemPrompt
                nBatch,
                512,   // nUbatch
                nGpuLayers,
                nThreads,
                true,  // useMmap
                false, // useMlock
                false, // embedding
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
    public void generateText(String prompt, Promise promise) {
        try {
            if (contextHandle == 0) {
                promise.reject("GENERATE_TEXT_ERROR", "No model loaded");
                return;
            }
            
            // Use the intermediate SDK's Java API
            LlamaMobile.CompletionParams completionParams = new LlamaMobile.CompletionParams(
                prompt,
                0.7f,   // temperature
                200,    // maxTokens
                4,      // nThreads
                -1,     // seed
                40,     // topK
                0.9,    // topP
                0.05,   // minP
                1.0,    // typicalP
                64,     // penaltyLastN
                1.1,    // penaltyRepeat
                0.0,    // penaltyFreq
                0.0,    // penaltyPresent
                0,      // mirostat
                5.0,    // mirostatTau
                0.1,    // mirostatEta
                false,  // ignoreEos
                0,      // nProbs
                null,   // grammar
                null,   // stopSequences
                null    // tokenCallback
            );
            
            LlamaMobile.CompletionResult result = LlamaMobile.generateCompletion(contextHandle, completionParams);
            
            if (result != null) {
                promise.resolve(result.getText());
            } else {
                promise.reject("GENERATE_TEXT_ERROR", "Failed to generate text");
            }
        } catch (Exception e) {
            promise.reject("GENERATE_TEXT_ERROR", e.getMessage());
        }
    }

    @ReactMethod
    public void generateTextStream(String prompt, Promise promise) {
        // This would be implemented with event emitters for streaming
        promise.reject("NOT_IMPLEMENTED", "Streaming not implemented yet");
    }

    @ReactMethod
    public void stopGeneration() {
        // Not implemented in the intermediate SDK yet
    }

    @ReactMethod
    public void unloadModel() {
        if (contextHandle != 0) {
            LlamaMobile.releaseContext(contextHandle);
            contextHandle = 0;
        }
    }
}
