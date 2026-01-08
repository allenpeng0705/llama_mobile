package com.llamamobile.reactnative.llama_mobile_react_native_sdk;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;

import java.util.HashMap;
import java.util.Map;

public class LlamaMobileReactNativeSdkModule extends ReactContextBaseJavaModule {
    // Load the JNI library
    static {
        System.loadLibrary("llama_mobile_jni");
    }
    private static ReactApplicationContext reactContext;

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

    // Native method declarations
    private native void nativeInitialize();
    private native boolean nativeLoadModel(String modelPath, int nThreads, int nBatch, int nGpuLayers);
    private native String nativeGenerateText(String prompt);
    private native void nativeStopGeneration();
    private native void nativeUnloadModel();

    @ReactMethod
    public void initialize() {
        nativeInitialize();
    }

    @ReactMethod
    public void loadModel(String modelPath, ReadableMap params, Promise promise) {
        try {
            // Extract parameters with defaults
            int nThreads = params.hasKey("n_threads") ? params.getInt("n_threads") : 4;
            int nBatch = params.hasKey("n_batch") ? params.getInt("n_batch") : 512;
            int nGpuLayers = params.hasKey("n_gpu_layers") ? params.getInt("n_gpu_layers") : 0;
            
            boolean success = nativeLoadModel(modelPath, nThreads, nBatch, nGpuLayers);
            if (success) {
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
            String result = nativeGenerateText(prompt);
            if (result != null) {
                promise.resolve(result);
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
        nativeStopGeneration();
    }

    @ReactMethod
    public void unloadModel() {
        nativeUnloadModel();
    }
}
