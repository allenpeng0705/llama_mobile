// JNI wrapper for llama_mobile Android library
#include <jni.h>
#include <string>
#include <cstring>

// Include the llama_mobile headers
#include "llama_mobile_api.h"

#ifdef __cplusplus
extern "C" {
#endif

// JNI helper function to convert jstring to const char*
static const char* getStringUTFChars(JNIEnv* env, jstring str) {
    if (str == nullptr) {
        return nullptr;
    }
    return env->GetStringUTFChars(str, nullptr);
}

// JNI helper function to release const char*
static void releaseStringUTFChars(JNIEnv* env, jstring str, const char* cStr) {
    if (str != nullptr && cStr != nullptr) {
        env->ReleaseStringUTFChars(str, cStr);
    }
}

// Helper function to extract InitParams from Java object
static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate) {
    jclass paramsClass = env->GetObjectClass(initParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID modelPathField = env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;");
    jfieldID nCtxField = env->GetFieldID(paramsClass, "nCtx", "I");
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    jfieldID cacheTypeField = env->GetFieldID(paramsClass, "cacheType", "Lcom/llamamobile/LlamaMobile;");
    
    if (modelPathField == nullptr || nCtxField == nullptr || chatTemplateField == nullptr || cacheTypeField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
    jint nCtx = env->GetIntField(initParamsObj, nCtxField);
    jstring chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
    jobject cacheTypeObj = env->GetObjectField(initParamsObj, cacheTypeField);
    
    // Get cache type enum value
    jint cacheType = 0; // Default to NONE
    if (cacheTypeObj != nullptr) {
        jclass cacheTypeClass = env->GetObjectClass(cacheTypeObj);
        jmethodID ordinalMethod = env->GetMethodID(cacheTypeClass, "ordinal", "()I");
        if (ordinalMethod != nullptr) {
            cacheType = env->CallIntMethod(cacheTypeObj, ordinalMethod);
        }
        env->DeleteLocalRef(cacheTypeClass);
    }
    
    // Convert strings
    modelPath = getStringUTFChars(env, modelPathStr);
    chatTemplate = getStringUTFChars(env, chatTemplateStr);
    
    // Set params
    params.model_path = modelPath;
    params.n_ctx = nCtx;
    params.chat_template = chatTemplate;
    params.cache_type = cacheType;
    params.progress_callback = nullptr;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(modelPathStr);
    env->DeleteLocalRef(chatTemplateStr);
    env->DeleteLocalRef(cacheTypeObj);
    
    return true;
}

// Extract CompletionParams from Java object
static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt) {
    jclass paramsClass = env->GetObjectClass(completionParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID promptField = env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;");
    jfieldID temperatureField = env->GetFieldID(paramsClass, "temperature", "F");
    jfieldID maxTokensField = env->GetFieldID(paramsClass, "maxTokens", "I");
    
    if (promptField == nullptr || temperatureField == nullptr || maxTokensField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
    jfloat temperature = env->GetFloatField(completionParamsObj, temperatureField);
    jint maxTokens = env->GetIntField(completionParamsObj, maxTokensField);
    
    // Convert string
    prompt = getStringUTFChars(env, promptStr);
    
    // Set params
    params.prompt = prompt;
    params.temperature = temperature;
    params.max_new_tokens = maxTokens;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(promptStr);
    
    return true;
}

// Initialize context
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(
    JNIEnv *env, jobject thiz, jobject initParamsObj) {
    
    llama_mobile_init_params_c_t params = {};
    const char* modelPath = nullptr;
    const char* chatTemplate = nullptr;
    
    if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate)) {
        return 0;
    }
    
    if (modelPath == nullptr) {
        return 0;
    }
    
    void *context = llama_mobile_init_context_c(&params);
    
    // Release strings
    releaseStringUTFChars(env, nullptr, modelPath);
    releaseStringUTFChars(env, nullptr, chatTemplate);
    
    return reinterpret_cast<jlong>(context);
}

// Generate completion
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_generateCompletion(
    JNIEnv *env, jobject thiz, jlong contextHandle, jobject completionParamsObj) {
    
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_completion_params_c_t params = {};
    const char* prompt = nullptr;
    
    if (!extractCompletionParams(env, completionParamsObj, params, prompt)) {
        return nullptr;
    }
    
    if (prompt == nullptr) {
        return nullptr;
    }
    
    char *result = llama_mobile_generate_completion_c(reinterpret_cast<void*>(contextHandle), &params);
    
    // Release prompt string
    releaseStringUTFChars(env, nullptr, prompt);
    
    if (result == nullptr) {
        return nullptr;
    }
    
    jstring javaResult = env->NewStringUTF(result);
    free(result);
    
    return javaResult;
}

// Release context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_context_c(reinterpret_cast<void*>(contextHandle));
    }
}

// Initialize vocoder
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_initVocoder(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring vocoderModelPathStr) {
    
    if (contextHandle == 0 || vocoderModelPathStr == nullptr) {
        return -1;
    }
    
    const char* vocoderModelPath = getStringUTFChars(env, vocoderModelPathStr);
    if (vocoderModelPath == nullptr) {
        return -1;
    }
    
    int result = llama_mobile_init_vocoder_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle), 
        vocoderModelPath);
    
    releaseStringUTFChars(env, vocoderModelPathStr, vocoderModelPath);
    
    return result;
}

// Check if vocoder is enabled
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isVocoderEnabled(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    bool result = llama_mobile_is_vocoder_enabled_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    
    return static_cast<jboolean>(result);
}

// Get TTS type
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getTtsType(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return -1;
    }
    
    int32_t result = llama_mobile_get_tts_type_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    
    return static_cast<jint>(result);
}

// Get formatted audio completion
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_getFormattedAudioCompletion(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring speakerJsonStr, jstring textToSpeakStr) {
    
    if (contextHandle == 0 || speakerJsonStr == nullptr || textToSpeakStr == nullptr) {
        return nullptr;
    }
    
    const char* speakerJson = getStringUTFChars(env, speakerJsonStr);
    const char* textToSpeak = getStringUTFChars(env, textToSpeakStr);
    
    if (speakerJson == nullptr || textToSpeak == nullptr) {
        if (speakerJson != nullptr) {
            releaseStringUTFChars(env, speakerJsonStr, speakerJson);
        }
        if (textToSpeak != nullptr) {
            releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
        }
        return nullptr;
    }
    
    char* result = llama_mobile_get_formatted_audio_completion_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle), 
        speakerJson, 
        textToSpeak);
    
    releaseStringUTFChars(env, speakerJsonStr, speakerJson);
    releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
    
    if (result == nullptr) {
        return nullptr;
    }
    
    jstring jResult = env->NewStringUTF(result);
    llama_mobile_free_result_string_c(result);
    
    return jResult;
}

// Get audio guide tokens
JNIEXPORT jintArray JNICALL Java_com_llamamobile_LlamaMobile_getAudioGuideTokens(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring textToSpeakStr) {
    
    if (contextHandle == 0 || textToSpeakStr == nullptr) {
        return nullptr;
    }
    
    const char* textToSpeak = getStringUTFChars(env, textToSpeakStr);
    if (textToSpeak == nullptr) {
        return nullptr;
    }
    
    llama_mobile_token_array_c_t result = llama_mobile_get_audio_guide_tokens_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle), 
        textToSpeak);
    
    releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
    
    if (result.tokens == nullptr || result.count <= 0) {
        return nullptr;
    }
    
    jintArray jResult = env->NewIntArray(result.count);
    if (jResult == nullptr) {
        llama_mobile_free_token_array_c(&result);
        return nullptr;
    }
    
    env->SetIntArrayRegion(jResult, 0, result.count, reinterpret_cast<const jint*>(result.tokens));
    llama_mobile_free_token_array_c(&result);
    
    return jResult;
}

// Decode audio tokens
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_decodeAudioTokens(
    JNIEnv *env, jobject thiz, jlong contextHandle, jintArray tokensArray) {
    
    if (contextHandle == 0 || tokensArray == nullptr) {
        return nullptr;
    }
    
    jsize tokensLength = env->GetArrayLength(tokensArray);
    if (tokensLength <= 0) {
        return nullptr;
    }
    
    // Get the tokens from the Java array
    jint* tokens = env->GetIntArrayElements(tokensArray, nullptr);
    if (tokens == nullptr) {
        return nullptr;
    }
    
    // Call the C API
    llama_mobile_float_array_c_t result = llama_mobile_decode_audio_tokens_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle), 
        reinterpret_cast<const int32_t*>(tokens), 
        static_cast<int32_t>(tokensLength));
    
    // Release the Java array
    env->ReleaseIntArrayElements(tokensArray, tokens, JNI_ABORT);
    
    if (result.data == nullptr || result.count <= 0) {
        return nullptr;
    }
    
    // Create a new Java float array
    jfloatArray jResult = env->NewFloatArray(result.count);
    if (jResult == nullptr) {
        llama_mobile_free_float_array_c(&result);
        return nullptr;
    }
    
    // Copy the data to the Java array
    env->SetFloatArrayRegion(jResult, 0, result.count, reinterpret_cast<const jfloat*>(result.data));
    llama_mobile_free_float_array_c(&result);
    
    return jResult;
}

// Release vocoder
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseVocoder(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_vocoder_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

#ifdef __cplusplus
}
#endif
