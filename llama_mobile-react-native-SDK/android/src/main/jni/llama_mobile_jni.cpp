#include <jni.h>
#include <string>
#include <android/log.h>
#include "llama_mobile_ffi.h"

// Logging macros
#define TAG "LlamaMobileJNI"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, TAG, __VA_ARGS__)

// Global context handle
static llama_mobile_context_handle_t g_context = nullptr;

extern "C" JNIEXPORT void JNICALL
Java_com_llamamobile_reactnative_llama_1mobile_1react_1native_1sdk_LlamaMobileReactNativeSdkModule_nativeInitialize(JNIEnv* env, jobject /* this */) {
    LOGD("Native initialize called");
    // No explicit initialization needed for the C API
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_llamamobile_reactnative_llama_1mobile_1react_1native_1sdk_LlamaMobileReactNativeSdkModule_nativeLoadModel(JNIEnv* env, jobject /* this */, jstring modelPath, jint nThreads, jint nBatch, jint nGpuLayers) {
    LOGD("Native loadModel called");
    
    const char* modelPathCStr = env->GetStringUTFChars(modelPath, nullptr);
    if (!modelPathCStr) {
        LOGE("Failed to get model path string");
        return JNI_FALSE;
    }
    
    // Create initialization parameters
    llama_mobile_init_params_c_t params = {};
    params.model_path = modelPathCStr;
    params.n_threads = nThreads;
    params.n_batch = nBatch;
    params.n_gpu_layers = nGpuLayers;
    params.n_ctx = 4096; // Default context size
    params.use_mmap = true;
    
    // Initialize the context
    g_context = llama_mobile_init_context_c(&params);
    
    env->ReleaseStringUTFChars(modelPath, modelPathCStr);
    
    if (!g_context) {
        LOGE("Failed to initialize model context");
        return JNI_FALSE;
    }
    
    LOGD("Model loaded successfully");
    return JNI_TRUE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_llamamobile_reactnative_llama_1mobile_1react_1native_1sdk_LlamaMobileReactNativeSdkModule_nativeGenerateText(JNIEnv* env, jobject /* this */, jstring prompt) {
    LOGD("Native generateText called");
    
    if (!g_context) {
        LOGE("Model not loaded");
        return nullptr;
    }
    
    const char* promptCStr = env->GetStringUTFChars(prompt, nullptr);
    if (!promptCStr) {
        LOGE("Failed to get prompt string");
        return nullptr;
    }
    
    // Create completion parameters
    llama_mobile_completion_params_c_t params = {};
    params.prompt = promptCStr;
    params.n_predict = 200; // Default max tokens
    params.temperature = 0.7;
    params.top_p = 0.9;
    
    // Create result structure
    llama_mobile_completion_result_c_t result = {};
    
    // Generate text
    int status = llama_mobile_completion_c(g_context, &params, &result);
    
    env->ReleaseStringUTFChars(prompt, promptCStr);
    
    jstring response = nullptr;
    if (status == 0 && result.text) {
        response = env->NewStringUTF(result.text);
        llama_mobile_free_completion_result_members_c(&result);
    } else {
        LOGE("Failed to generate text");
        if (result.text) {
            llama_mobile_free_completion_result_members_c(&result);
        }
    }
    
    return response;
}

extern "C" JNIEXPORT void JNICALL
Java_com_llamamobile_reactnative_llama_1mobile_1react_1native_1sdk_LlamaMobileReactNativeSdkModule_nativeStopGeneration(JNIEnv* env, jobject /* this */) {
    LOGD("Native stopGeneration called");
    
    if (g_context) {
        llama_mobile_stop_completion_c(g_context);
    }
}

extern "C" JNIEXPORT void JNICALL
Java_com_llamamobile_reactnative_llama_1mobile_1react_1native_1sdk_LlamaMobileReactNativeSdkModule_nativeUnloadModel(JNIEnv* env, jobject /* this */) {
    LOGD("Native unloadModel called");
    
    if (g_context) {
        llama_mobile_free_context_c(g_context);
        g_context = nullptr;
    }
}
