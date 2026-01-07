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
static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate, const char*& systemPrompt, const char*& cacheTypeK, const char*& cacheTypeV) {
    jclass paramsClass = env->GetObjectClass(initParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID modelPathField = env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;");
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    jfieldID systemPromptField = env->GetFieldID(paramsClass, "systemPrompt", "Ljava/lang/String;");
    jfieldID nCtxField = env->GetFieldID(paramsClass, "nCtx", "I");
    jfieldID nBatchField = env->GetFieldID(paramsClass, "nBatch", "I");
    jfieldID nUbatchField = env->GetFieldID(paramsClass, "nUbatch", "I");
    jfieldID nGpuLayersField = env->GetFieldID(paramsClass, "nGpuLayers", "I");
    jfieldID nThreadsField = env->GetFieldID(paramsClass, "nThreads", "I");
    jfieldID useMmapField = env->GetFieldID(paramsClass, "useMmap", "Z");
    jfieldID useMlockField = env->GetFieldID(paramsClass, "useMlock", "Z");
    jfieldID embeddingField = env->GetFieldID(paramsClass, "embedding", "Z");
    jfieldID poolingTypeField = env->GetFieldID(paramsClass, "poolingType", "I");
    jfieldID embdNormalizeField = env->GetFieldID(paramsClass, "embdNormalize", "I");
    jfieldID flashAttnField = env->GetFieldID(paramsClass, "flashAttn", "Z");
    jfieldID cacheTypeField = env->GetFieldID(paramsClass, "cacheType", "Lcom/llamamobile/LlamaMobile$CacheType;");
    jfieldID cacheTypeKField = env->GetFieldID(paramsClass, "cacheTypeK", "Ljava/lang/String;");
    jfieldID cacheTypeVField = env->GetFieldID(paramsClass, "cacheTypeV", "Ljava/lang/String;");
    
    if (modelPathField == nullptr || chatTemplateField == nullptr || systemPromptField == nullptr || 
        nCtxField == nullptr || nBatchField == nullptr || nUbatchField == nullptr || 
        nGpuLayersField == nullptr || nThreadsField == nullptr || useMmapField == nullptr || 
        useMlockField == nullptr || embeddingField == nullptr || poolingTypeField == nullptr || 
        embdNormalizeField == nullptr || flashAttnField == nullptr || cacheTypeField == nullptr || 
        cacheTypeKField == nullptr || cacheTypeVField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
    jstring chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
    jstring systemPromptStr = (jstring)env->GetObjectField(initParamsObj, systemPromptField);
    jint nCtx = env->GetIntField(initParamsObj, nCtxField);
    jint nBatch = env->GetIntField(initParamsObj, nBatchField);
    jint nUbatch = env->GetIntField(initParamsObj, nUbatchField);
    jint nGpuLayers = env->GetIntField(initParamsObj, nGpuLayersField);
    jint nThreads = env->GetIntField(initParamsObj, nThreadsField);
    jboolean useMmap = env->GetBooleanField(initParamsObj, useMmapField);
    jboolean useMlock = env->GetBooleanField(initParamsObj, useMlockField);
    jboolean embedding = env->GetBooleanField(initParamsObj, embeddingField);
    jint poolingType = env->GetIntField(initParamsObj, poolingTypeField);
    jint embdNormalize = env->GetIntField(initParamsObj, embdNormalizeField);
    jboolean flashAttn = env->GetBooleanField(initParamsObj, flashAttnField);
    jobject cacheTypeObj = env->GetObjectField(initParamsObj, cacheTypeField);
    jstring cacheTypeKStr = (jstring)env->GetObjectField(initParamsObj, cacheTypeKField);
    jstring cacheTypeVStr = (jstring)env->GetObjectField(initParamsObj, cacheTypeVField);
    
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
    systemPrompt = getStringUTFChars(env, systemPromptStr);
    cacheTypeK = getStringUTFChars(env, cacheTypeKStr);
    cacheTypeV = getStringUTFChars(env, cacheTypeVStr);
    
    // Set params
    params.model_path = modelPath;
    params.chat_template = chatTemplate;
    params.system_prompt = systemPrompt;
    params.n_ctx = nCtx;
    params.n_batch = nBatch;
    params.n_ubatch = nUbatch;
    params.n_gpu_layers = nGpuLayers;
    params.n_threads = nThreads;
    params.use_mmap = useMmap;
    params.use_mlock = useMlock;
    params.embedding = embedding;
    params.pooling_type = poolingType;
    params.embd_normalize = embdNormalize;
    params.flash_attn = flashAttn;
    params.cache_type = cacheType;
    params.cache_type_k = cacheTypeK;
    params.cache_type_v = cacheTypeV;
    params.progress_callback = nullptr;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(modelPathStr);
    env->DeleteLocalRef(chatTemplateStr);
    env->DeleteLocalRef(systemPromptStr);
    env->DeleteLocalRef(cacheTypeObj);
    env->DeleteLocalRef(cacheTypeKStr);
    env->DeleteLocalRef(cacheTypeVStr);
    
    return true;
}

// Token callback structure to hold JNI references
struct TokenCallbackData {
    JNIEnv* env;
    jobject callbackObj;
    jmethodID onTokenMethod;
};

// Token callback function for C API
static bool tokenCallback(void* user_data, const char* token) {
    TokenCallbackData* data = static_cast<TokenCallbackData*>(user_data);
    if (data == nullptr || data->env == nullptr || data->callbackObj == nullptr) {
        return true; // Continue generation
    }
    
    // Create Java string from token
    jstring tokenStr = data->env->NewStringUTF(token);
    if (tokenStr == nullptr) {
        return true; // Continue generation
    }
    
    // Call the Java callback method
    jboolean continueGeneration = data->env->CallBooleanMethod(data->callbackObj, data->onTokenMethod, tokenStr);
    
    // Check for exceptions
    if (data->env->ExceptionCheck()) {
        data->env->ExceptionDescribe();
        data->env->ExceptionClear();
        return true; // Continue generation even if callback threw exception
    }
    
    // Release the token string
    data->env->DeleteLocalRef(tokenStr);
    
    return static_cast<bool>(continueGeneration);
}

// Extract CompletionParams from Java object
static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt, const char*& grammar, std::vector<const char*>& stopSequences, TokenCallbackData*& callbackData) {
    jclass paramsClass = env->GetObjectClass(completionParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID promptField = env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;");
    jfieldID nPredictField = env->GetFieldID(paramsClass, "nPredict", "I");
    jfieldID nThreadsField = env->GetFieldID(paramsClass, "nThreads", "I");
    jfieldID seedField = env->GetFieldID(paramsClass, "seed", "I");
    jfieldID temperatureField = env->GetFieldID(paramsClass, "temperature", "D");
    jfieldID topKField = env->GetFieldID(paramsClass, "topK", "I");
    jfieldID topPField = env->GetFieldID(paramsClass, "topP", "D");
    jfieldID minPField = env->GetFieldID(paramsClass, "minP", "D");
    jfieldID typicalPField = env->GetFieldID(paramsClass, "typicalP", "D");
    jfieldID penaltyLastNField = env->GetFieldID(paramsClass, "penaltyLastN", "I");
    jfieldID penaltyRepeatField = env->GetFieldID(paramsClass, "penaltyRepeat", "D");
    jfieldID penaltyFreqField = env->GetFieldID(paramsClass, "penaltyFreq", "D");
    jfieldID penaltyPresentField = env->GetFieldID(paramsClass, "penaltyPresent", "D");
    jfieldID mirostatField = env->GetFieldID(paramsClass, "mirostat", "I");
    jfieldID mirostatTauField = env->GetFieldID(paramsClass, "mirostatTau", "D");
    jfieldID mirostatEtaField = env->GetFieldID(paramsClass, "mirostatEta", "D");
    jfieldID ignoreEosField = env->GetFieldID(paramsClass, "ignoreEos", "Z");
    jfieldID nProbsField = env->GetFieldID(paramsClass, "nProbs", "I");
    jfieldID grammarField = env->GetFieldID(paramsClass, "grammar", "Ljava/lang/String;");
    jfieldID stopSequencesField = env->GetFieldID(paramsClass, "stopSequences", "Ljava/util/List;");
    jfieldID tokenCallbackField = env->GetFieldID(paramsClass, "tokenCallback", "Lcom/llamamobile/LlamaMobile$TokenCallback;");
    
    if (promptField == nullptr || nPredictField == nullptr || nThreadsField == nullptr || 
        seedField == nullptr || temperatureField == nullptr || topKField == nullptr || 
        topPField == nullptr || minPField == nullptr || typicalPField == nullptr || 
        penaltyLastNField == nullptr || penaltyRepeatField == nullptr || penaltyFreqField == nullptr || 
        penaltyPresentField == nullptr || mirostatField == nullptr || mirostatTauField == nullptr || 
        mirostatEtaField == nullptr || ignoreEosField == nullptr || nProbsField == nullptr || 
        grammarField == nullptr || stopSequencesField == nullptr || tokenCallbackField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
    jint nPredict = env->GetIntField(completionParamsObj, nPredictField);
    jint nThreads = env->GetIntField(completionParamsObj, nThreadsField);
    jint seed = env->GetIntField(completionParamsObj, seedField);
    jdouble temperature = env->GetDoubleField(completionParamsObj, temperatureField);
    jint topK = env->GetIntField(completionParamsObj, topKField);
    jdouble topP = env->GetDoubleField(completionParamsObj, topPField);
    jdouble minP = env->GetDoubleField(completionParamsObj, minPField);
    jdouble typicalP = env->GetDoubleField(completionParamsObj, typicalPField);
    jint penaltyLastN = env->GetIntField(completionParamsObj, penaltyLastNField);
    jdouble penaltyRepeat = env->GetDoubleField(completionParamsObj, penaltyRepeatField);
    jdouble penaltyFreq = env->GetDoubleField(completionParamsObj, penaltyFreqField);
    jdouble penaltyPresent = env->GetDoubleField(completionParamsObj, penaltyPresentField);
    jint mirostat = env->GetIntField(completionParamsObj, mirostatField);
    jdouble mirostatTau = env->GetDoubleField(completionParamsObj, mirostatTauField);
    jdouble mirostatEta = env->GetDoubleField(completionParamsObj, mirostatEtaField);
    jboolean ignoreEos = env->GetBooleanField(completionParamsObj, ignoreEosField);
    jint nProbs = env->GetIntField(completionParamsObj, nProbsField);
    jstring grammarStr = (jstring)env->GetObjectField(completionParamsObj, grammarField);
    jobject stopSequencesObj = env->GetObjectField(completionParamsObj, stopSequencesField);
    
    // Convert strings
    prompt = getStringUTFChars(env, promptStr);
    grammar = getStringUTFChars(env, grammarStr);
    
    // Extract stop sequences
    jclass listClass = env->GetObjectClass(stopSequencesObj);
    jmethodID sizeMethod = env->GetMethodID(listClass, "size", "()I");
    jmethodID getMethod = env->GetMethodID(listClass, "get", "(I)Ljava/lang/Object;");
    
    jint stopSequencesSize = env->CallIntMethod(stopSequencesObj, sizeMethod);
    for (jint i = 0; i < stopSequencesSize; ++i) {
        jobject stopSequenceObj = env->CallObjectMethod(stopSequencesObj, getMethod, i);
        jstring stopSequenceStr = (jstring)stopSequenceObj;
        const char* stopSequence = getStringUTFChars(env, stopSequenceStr);
        stopSequences.push_back(stopSequence);
        env->DeleteLocalRef(stopSequenceObj);
    }
    
    env->DeleteLocalRef(listClass);
    
    // Extract token callback
    jobject tokenCallbackObj = env->GetObjectField(completionParamsObj, tokenCallbackField);
    callbackData = nullptr;
    
    if (tokenCallbackObj != nullptr) {
        // Create callback data structure
        callbackData = new TokenCallbackData();
        if (callbackData == nullptr) {
            env->DeleteLocalRef(paramsClass);
            env->DeleteLocalRef(promptStr);
            env->DeleteLocalRef(grammarStr);
            env->DeleteLocalRef(stopSequencesObj);
            env->DeleteLocalRef(tokenCallbackObj);
            return false;
        }
        
        // Get the onToken method
        jclass tokenCallbackClass = env->GetObjectClass(tokenCallbackObj);
        jmethodID onTokenMethod = env->GetMethodID(tokenCallbackClass, "onToken", "(Ljava/lang/String;)Z");
        
        if (onTokenMethod == nullptr) {
            delete callbackData;
            env->DeleteLocalRef(paramsClass);
            env->DeleteLocalRef(promptStr);
            env->DeleteLocalRef(grammarStr);
            env->DeleteLocalRef(stopSequencesObj);
            env->DeleteLocalRef(tokenCallbackObj);
            env->DeleteLocalRef(tokenCallbackClass);
            return false;
        }
        
        // Set up callback data
        callbackData->env = env;
        callbackData->callbackObj = env->NewGlobalRef(tokenCallbackObj);
        callbackData->onTokenMethod = onTokenMethod;
        
        // Set callback in params
        params.token_callback = tokenCallback;
        params.user_data = callbackData;
        
        // Clean up local references
        env->DeleteLocalRef(tokenCallbackClass);
    }
    
    // Set params
    params.prompt = prompt;
    params.n_predict = nPredict;
    params.n_threads = nThreads;
    params.seed = seed;
    params.temperature = temperature;
    params.top_k = topK;
    params.top_p = topP;
    params.min_p = minP;
    params.typical_p = typicalP;
    params.penalty_last_n = penaltyLastN;
    params.penalty_repeat = penaltyRepeat;
    params.penalty_freq = penaltyFreq;
    params.penalty_present = penaltyPresent;
    params.mirostat = mirostat;
    params.mirostat_tau = mirostatTau;
    params.mirostat_eta = mirostatEta;
    params.ignore_eos = ignoreEos;
    params.n_probs = nProbs;
    params.grammar = grammar;
    params.stop_sequences = stopSequences.data();
    params.n_stop_sequences = stopSequences.size();
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(promptStr);
    env->DeleteLocalRef(grammarStr);
    env->DeleteLocalRef(stopSequencesObj);
    
    return true;
}

// Initialize context
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(
    JNIEnv *env, jobject thiz, jobject initParamsObj) {
    
    llama_mobile_init_params_c_t params = {};
    const char* modelPath = nullptr;
    const char* chatTemplate = nullptr;
    const char* systemPrompt = nullptr;
    const char* cacheTypeK = nullptr;
    const char* cacheTypeV = nullptr;
    
    if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate, systemPrompt, cacheTypeK, cacheTypeV)) {
        return 0;
    }
    
    if (modelPath == nullptr) {
        return 0;
    }
    
    void *context = llama_mobile_init_context_c(&params);
    
    // Release strings
    releaseStringUTFChars(env, nullptr, modelPath);
    releaseStringUTFChars(env, nullptr, chatTemplate);
    releaseStringUTFChars(env, nullptr, systemPrompt);
    releaseStringUTFChars(env, nullptr, cacheTypeK);
    releaseStringUTFChars(env, nullptr, cacheTypeV);
    
    return reinterpret_cast<jlong>(context);
}

// Generate completion
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_generateCompletion(
    JNIEnv *env, jobject thiz, jlong contextHandle, jobject completionParamsObj) {
    
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_completion_params_c_t params = {};
    const char* prompt = nullptr;
    const char* grammar = nullptr;
    std::vector<const char*> stopSequences;
    TokenCallbackData* callbackData = nullptr;
    
    if (!extractCompletionParams(env, completionParamsObj, params, prompt, grammar, stopSequences, callbackData)) {
        return nullptr;
    }
    
    if (prompt == nullptr) {
        return nullptr;
    }
    
    // Call the C API function that returns structured result
    llama_mobile_completion_result_c_t result = {};
    int success = llama_mobile_completion_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle), &params, &result);
    
    // Release strings
    releaseStringUTFChars(env, nullptr, prompt);
    releaseStringUTFChars(env, nullptr, grammar);
    
    // Release stop sequences
    for (const char* stopSequence : stopSequences) {
        releaseStringUTFChars(env, nullptr, stopSequence);
    }
    
    if (success != 0 || result.text == nullptr) {
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    // Get the CompletionResult class
    jclass completionResultClass = env->FindClass("com/llamamobile/LlamaMobile$CompletionResult");
    if (completionResultClass == nullptr) {
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    // Get the constructor
    jmethodID constructor = env->GetMethodID(completionResultClass, "<init>", "(Ljava/lang/String;IIZZZZLjava/lang/String;)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(completionResultClass);
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    // Create Java strings
    jstring textStr = env->NewStringUTF(result.text);
    jstring stoppingWordStr = (result.stopping_word != nullptr) ? env->NewStringUTF(result.stopping_word) : nullptr;
    
    // Create the CompletionResult object
    jobject javaResult = env->NewObject(
        completionResultClass,
        constructor,
        textStr,
        result.tokens_predicted,
        result.tokens_evaluated,
        result.truncated,
        result.stopped_eos,
        result.stopped_word,
        result.stopped_limit,
        stoppingWordStr
    );
    
    // Cleanup
    env->DeleteLocalRef(completionResultClass);
    if (textStr != nullptr) {
        env->DeleteLocalRef(textStr);
    }
    if (stoppingWordStr != nullptr) {
        env->DeleteLocalRef(stoppingWordStr);
    }
    
    // Free C result memory
    llama_mobile_free_completion_result_members_c(&result);
    
    // Clean up token callback data if it was created
    if (callbackData != nullptr) {
        if (callbackData->callbackObj != nullptr) {
            env->DeleteGlobalRef(callbackData->callbackObj);
        }
        delete callbackData;
    }
    
    return javaResult;
}

// Release context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_context_c(reinterpret_cast<void*>(contextHandle));
    }
}

#ifdef __cplusplus
}
#endif
