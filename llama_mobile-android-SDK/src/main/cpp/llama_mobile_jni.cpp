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
    
    // Create a simple result struct
    llama_mobile_completion_result_c_t result = {};
    
    // Call the completion function
    int ret = llama_mobile_completion_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        &params,
        &result
    );
    
    // Release prompt string
    releaseStringUTFChars(env, nullptr, prompt);
    
    if (ret != 0 || result.text == nullptr) {
        if (result.text != nullptr) {
            llama_mobile_free_string_c(result.text);
        }
        return nullptr;
    }
    
    jstring javaResult = env->NewStringUTF(result.text);
    
    // Clean up
    llama_mobile_free_string_c(result.text);
    
    return javaResult;
}

// Helper function to extract DownloadParams from Java object
static bool extractDownloadParams(JNIEnv* env, jobject downloadParamsObj, llama_mobile_download_params_c_t& params, const char*& repoId, const char*& filename) {
    jclass paramsClass = env->GetObjectClass(downloadParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID urlField = env->GetFieldID(paramsClass, "url", "Ljava/lang/String;");
    jfieldID localPathField = env->GetFieldID(paramsClass, "localPath", "Ljava/lang/String;");
    jfieldID passwordField = env->GetFieldID(paramsClass, "password", "Ljava/lang/String;");
    
    if (urlField == nullptr || localPathField == nullptr || passwordField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring urlStr = (jstring)env->GetObjectField(downloadParamsObj, urlField);
    jstring localPathStr = (jstring)env->GetObjectField(downloadParamsObj, localPathField);
    jstring passwordStr = (jstring)env->GetObjectField(downloadParamsObj, passwordField);
    
    // Convert strings
    const char* url = getStringUTFChars(env, urlStr);
    const char* localPath = getStringUTFChars(env, localPathStr);
    const char* password = getStringUTFChars(env, passwordStr);
    
    // Split URL into repo_id and filename
    // Expected format: https://huggingface.co/repo_id/resolve/main/filename
    // Or just repo_id/filename
    if (url != nullptr) {
        // Check if it's a full URL
        const char* repo_id_start = strstr(url, "huggingface.co/");
        if (repo_id_start != nullptr) {
            repo_id_start += strlen("huggingface.co/");
        } else {
            repo_id_start = url;
        }
        
        // Find the first slash after repo_id
        const char* slash_pos = strchr(repo_id_start, '/');
        if (slash_pos != nullptr) {
            // Create repo_id string
            size_t repo_id_len = slash_pos - repo_id_start;
            char* repo_id = new char[repo_id_len + 1];
            strncpy(repo_id, repo_id_start, repo_id_len);
            repo_id[repo_id_len] = '\0';
            repoId = repo_id;
            
            // Extract filename from the rest
            const char* filename_start = strrchr(slash_pos, '/');
            if (filename_start != nullptr) {
                filename_start++;
            } else {
                filename_start = slash_pos + 1;
            }
            
            filename = filename_start;
        }
    }
    
    // Set params
    params.repo_id = repoId;
    params.filename = filename;
    params.destination_path = localPath;
    params.bearer_token = password;
    params.offline = false;
    params.progress_callback = nullptr;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(urlStr);
    env->DeleteLocalRef(localPathStr);
    env->DeleteLocalRef(passwordStr);
    
    return true;
}

// Create Java DownloadResult object from C result
static jobject createDownloadResult(JNIEnv* env, llama_mobile_download_result_c_t& cResult) {
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$DownloadResult");
    if (resultClass == nullptr) {
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(ZLjava/lang/String;Ljava/lang/String;)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jstring localPath = (cResult.local_path != nullptr) ? env->NewStringUTF(cResult.local_path) : nullptr;
    jstring errorMessage = (cResult.error_message != nullptr) ? env->NewStringUTF(cResult.error_message) : nullptr;
    
    jobject resultObj = env->NewObject(resultClass, constructor, cResult.success, localPath, errorMessage);
    
    // Clean up
    if (localPath != nullptr) {
        env->DeleteLocalRef(localPath);
    }
    if (errorMessage != nullptr) {
        env->DeleteLocalRef(errorMessage);
    }
    env->DeleteLocalRef(resultClass);
    
    return resultObj;
}

// Download model
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadModel(
    JNIEnv *env, jobject thiz, jobject downloadParamsObj, jobject progressCallback) {
    
    llama_mobile_download_params_c_t params = {};
    const char* repoId = nullptr;
    const char* filename = nullptr;
    
    if (!extractDownloadParams(env, downloadParamsObj, params, repoId, filename)) {
        return nullptr;
    }
    
    if (repoId == nullptr || filename == nullptr) {
        if (repoId != nullptr) {
            delete[] repoId;
        }
        return nullptr;
    }
    
    // Call C API directly using download_hf_file_c
    llama_mobile_download_result_c_t cResult = llama_mobile_download_hf_file_c(
        repoId,
        filename,
        params.destination_path,
        params.bearer_token,
        params.offline,
        nullptr  // Progress callback not implemented in this version
    );
    
    // Create Java result object
    jobject resultObj = createDownloadResult(env, cResult);
    
    // Clean up
    if (repoId != nullptr) {
        delete[] repoId;
    }
    llama_mobile_free_download_result_c(&cResult);
    
    return resultObj;
}

// Download Hugging Face file
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadHfFile(
    JNIEnv *env, jobject thiz, jstring repoIdStr, jstring filenameStr, jstring destinationPathStr, 
    jstring bearerTokenStr, jboolean offline, jobject progressCallback) {
    
    // Convert strings
    const char* repoId = getStringUTFChars(env, repoIdStr);
    const char* filename = getStringUTFChars(env, filenameStr);
    const char* destinationPath = getStringUTFChars(env, destinationPathStr);
    const char* bearerToken = getStringUTFChars(env, bearerTokenStr);
    
    if (repoId == nullptr || filename == nullptr || destinationPath == nullptr) {
        releaseStringUTFChars(env, repoIdStr, repoId);
        releaseStringUTFChars(env, filenameStr, filename);
        releaseStringUTFChars(env, destinationPathStr, destinationPath);
        releaseStringUTFChars(env, bearerTokenStr, bearerToken);
        return nullptr;
    }
    
    // Call C API
    llama_mobile_download_result_c_t cResult = llama_mobile_download_hf_file_c(
        repoId,
        filename,
        destinationPath,
        bearerToken,
        static_cast<bool>(offline),
        nullptr  // Progress callback not implemented in this version
    );
    
    // Create Java result object
    jobject resultObj = createDownloadResult(env, cResult);
    
    // Clean up
    releaseStringUTFChars(env, repoIdStr, repoId);
    releaseStringUTFChars(env, filenameStr, filename);
    releaseStringUTFChars(env, destinationPathStr, destinationPath);
    releaseStringUTFChars(env, bearerTokenStr, bearerToken);
    llama_mobile_free_download_result_c(&cResult);
    
    return resultObj;
}

// Release context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_free_context_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Stop completion
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_stopCompletion(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_stop_completion_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Tokenize text
JNIEXPORT jintArray JNICALL Java_com_llamamobile_LlamaMobile_tokenize(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring textStr) {
    
    if (contextHandle == 0 || textStr == nullptr) {
        return nullptr;
    }
    
    const char* text = getStringUTFChars(env, textStr);
    if (text == nullptr) {
        return nullptr;
    }
    
    llama_mobile_token_array_c_t tokens = llama_mobile_tokenize_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        text
    );
    
    releaseStringUTFChars(env, textStr, text);
    
    if (tokens.tokens == nullptr || tokens.count <= 0) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    jintArray result = env->NewIntArray(tokens.count);
    if (result == nullptr) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    
    llama_mobile_free_token_array_c(tokens);
    
    return result;
}

// Detokenize tokens
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_detokenize(
    JNIEnv *env, jobject thiz, jlong contextHandle, jintArray tokensArray) {
    
    if (contextHandle == 0 || tokensArray == nullptr) {
        return nullptr;
    }
    
    jsize length = env->GetArrayLength(tokensArray);
    if (length <= 0) {
        return nullptr;
    }
    
    jint* tokens = env->GetIntArrayElements(tokensArray, nullptr);
    if (tokens == nullptr) {
        return nullptr;
    }
    
    char* text = llama_mobile_detokenize_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        reinterpret_cast<int32_t*>(tokens),
        static_cast<int32_t>(length)
    );
    
    env->ReleaseIntArrayElements(tokensArray, tokens, JNI_ABORT);
    
    if (text == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(text);
    
    llama_mobile_free_string_c(text);
    
    return result;
}

// Generate embeddings
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_generateEmbeddings(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring textStr) {
    
    if (contextHandle == 0 || textStr == nullptr) {
        return nullptr;
    }
    
    const char* text = getStringUTFChars(env, textStr);
    if (text == nullptr) {
        return nullptr;
    }
    
    llama_mobile_float_array_c_t embeddings = llama_mobile_embedding_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        text
    );
    
    releaseStringUTFChars(env, textStr, text);
    
    if (embeddings.values == nullptr || embeddings.count <= 0) {
        llama_mobile_free_float_array_c(embeddings);
        return nullptr;
    }
    
    jfloatArray result = env->NewFloatArray(embeddings.count);
    if (result == nullptr) {
        llama_mobile_free_float_array_c(embeddings);
        return nullptr;
    }
    
    env->SetFloatArrayRegion(result, 0, embeddings.count, reinterpret_cast<jfloat*>(embeddings.values));
    
    llama_mobile_free_float_array_c(embeddings);
    
    return result;
}

// Initialize multimodal
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_initMultimodal(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring mmprojPathStr, jboolean useGpu) {
    
    if (contextHandle == 0 || mmprojPathStr == nullptr) {
        return JNI_FALSE;
    }
    
    const char* mmprojPath = getStringUTFChars(env, mmprojPathStr);
    if (mmprojPath == nullptr) {
        return JNI_FALSE;
    }
    
    int result = llama_mobile_init_multimodal_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        mmprojPath,
        static_cast<bool>(useGpu)
    );
    
    releaseStringUTFChars(env, mmprojPathStr, mmprojPath);
    
    return result == 0 ? JNI_TRUE : JNI_FALSE;
}

// Check if multimodal is enabled
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isMultimodalEnabled(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    return llama_mobile_is_multimodal_enabled_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    ) ? JNI_TRUE : JNI_FALSE;
}

// Check if vision is supported
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_supportsVision(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    return llama_mobile_supports_vision_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    ) ? JNI_TRUE : JNI_FALSE;
}

// Check if audio is supported
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_supportsAudio(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    return llama_mobile_supports_audio_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    ) ? JNI_TRUE : JNI_FALSE;
}

// Release multimodal
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseMultimodal(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_multimodal_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Initialize vocoder
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_initVocoder(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring vocoderModelPathStr) {
    
    if (contextHandle == 0 || vocoderModelPathStr == nullptr) {
        return JNI_FALSE;
    }
    
    const char* vocoderModelPath = getStringUTFChars(env, vocoderModelPathStr);
    if (vocoderModelPath == nullptr) {
        return JNI_FALSE;
    }
    
    int result = llama_mobile_init_vocoder_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        vocoderModelPath
    );
    
    releaseStringUTFChars(env, vocoderModelPathStr, vocoderModelPath);
    
    return result == 0 ? JNI_TRUE : JNI_FALSE;
}

// Check if vocoder is enabled
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isVocoderEnabled(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    return llama_mobile_is_vocoder_enabled_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    ) ? JNI_TRUE : JNI_FALSE;
}

// Get TTS type
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getTTSType(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return 0; // UNKNOWN
    }
    
    return llama_mobile_get_tts_type_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
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
        releaseStringUTFChars(env, speakerJsonStr, speakerJson);
        releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
        return nullptr;
    }
    
    char* result = llama_mobile_get_formatted_audio_completion_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        speakerJson,
        textToSpeak
    );
    
    releaseStringUTFChars(env, speakerJsonStr, speakerJson);
    releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
    
    if (result == nullptr) {
        return nullptr;
    }
    
    jstring javaResult = env->NewStringUTF(result);
    
    llama_mobile_free_string_c(result);
    
    return javaResult;
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
    
    llama_mobile_token_array_c_t tokens = llama_mobile_get_audio_guide_tokens_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        textToSpeak
    );
    
    releaseStringUTFChars(env, textToSpeakStr, textToSpeak);
    
    if (tokens.tokens == nullptr || tokens.count <= 0) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    jintArray result = env->NewIntArray(tokens.count);
    if (result == nullptr) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    
    llama_mobile_free_token_array_c(tokens);
    
    return result;
}

// Decode audio tokens
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_decodeAudioTokens(
    JNIEnv *env, jobject thiz, jlong contextHandle, jintArray tokensArray) {
    
    if (contextHandle == 0 || tokensArray == nullptr) {
        return nullptr;
    }
    
    jsize length = env->GetArrayLength(tokensArray);
    if (length <= 0) {
        return nullptr;
    }
    
    jint* tokens = env->GetIntArrayElements(tokensArray, nullptr);
    if (tokens == nullptr) {
        return nullptr;
    }
    
    llama_mobile_float_array_c_t audio = llama_mobile_decode_audio_tokens_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        reinterpret_cast<int32_t*>(tokens),
        static_cast<int32_t>(length)
    );
    
    env->ReleaseIntArrayElements(tokensArray, tokens, JNI_ABORT);
    
    if (audio.values == nullptr || audio.count <= 0) {
        llama_mobile_free_float_array_c(audio);
        return nullptr;
    }
    
    jfloatArray result = env->NewFloatArray(audio.count);
    if (result == nullptr) {
        llama_mobile_free_float_array_c(audio);
        return nullptr;
    }
    
    env->SetFloatArrayRegion(result, 0, audio.count, reinterpret_cast<jfloat*>(audio.values));
    
    llama_mobile_free_float_array_c(audio);
    
    return result;
}

// Release vocoder
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseVocoder(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_vocoder_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Apply LoRA adapters
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_applyLoraAdapters(
    JNIEnv *env, jobject thiz, jlong contextHandle, jobjectArray adaptersArray) {
    
    if (contextHandle == 0 || adaptersArray == nullptr) {
        return JNI_FALSE;
    }
    
    jsize adapterCount = env->GetArrayLength(adaptersArray);
    if (adapterCount <= 0) {
        return JNI_TRUE; // No adapters to apply
    }
    
    llama_mobile_lora_adapters_c_t adapters = {};
    adapters.count = static_cast<int32_t>(adapterCount);
    adapters.adapters = new llama_mobile_lora_adapter_c_t[adapterCount];
    
    for (jsize i = 0; i < adapterCount; i++) {
        jobject adapterObj = env->GetObjectArrayElement(adaptersArray, i);
        jclass adapterClass = env->GetObjectClass(adapterObj);
        
        jfieldID pathField = env->GetFieldID(adapterClass, "path", "Ljava/lang/String;");
        jfieldID scaleField = env->GetFieldID(adapterClass, "scale", "F");
        
        if (pathField == nullptr || scaleField == nullptr) {
            env->DeleteLocalRef(adapterClass);
            env->DeleteLocalRef(adapterObj);
            delete[] adapters.adapters;
            return JNI_FALSE;
        }
        
        jstring pathStr = (jstring)env->GetObjectField(adapterObj, pathField);
        jfloat scale = env->GetFloatField(adapterObj, scaleField);
        
        const char* path = getStringUTFChars(env, pathStr);
        
        adapters.adapters[i].path = path;
        adapters.adapters[i].scale = static_cast<float>(scale);
        
        env->DeleteLocalRef(pathStr);
        env->DeleteLocalRef(adapterClass);
        env->DeleteLocalRef(adapterObj);
    }
    
    int result = llama_mobile_apply_lora_adapters_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        &adapters
    );
    
    // Clean up
    for (jsize i = 0; i < adapterCount; i++) {
        releaseStringUTFChars(env, nullptr, adapters.adapters[i].path);
    }
    delete[] adapters.adapters;
    
    return result == 0 ? JNI_TRUE : JNI_FALSE;
}

// Remove LoRA adapters
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_removeLoraAdapters(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_remove_lora_adapters_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Get loaded LoRA adapters
JNIEXPORT jobjectArray JNICALL Java_com_llamamobile_LlamaMobile_getLoadedLoraAdapters(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_lora_adapters_c_t adapters = llama_mobile_get_loaded_lora_adapters_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
    
    if (adapters.adapters == nullptr || adapters.count <= 0) {
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    jclass adapterClass = env->FindClass("com/llamamobile/LlamaMobile$LoraAdapter");
    if (adapterClass == nullptr) {
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(adapterClass, "<init>", "(Ljava/lang/String;F)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(adapterClass);
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    jobjectArray result = env->NewObjectArray(adapters.count, adapterClass, nullptr);
    if (result == nullptr) {
        env->DeleteLocalRef(adapterClass);
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    for (int32_t i = 0; i < adapters.count; i++) {
        jstring path = env->NewStringUTF(adapters.adapters[i].path);
        jobject adapter = env->NewObject(adapterClass, constructor, path, adapters.adapters[i].scale);
        
        env->SetObjectArrayElement(result, i, adapter);
        
        env->DeleteLocalRef(path);
        env->DeleteLocalRef(adapter);
    }
    
    env->DeleteLocalRef(adapterClass);
    llama_mobile_free_lora_adapters_c(&adapters);
    
    return result;
}

// Generate response
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_generateResponse(
    JNIEnv *env, jobject thiz, jlong contextHandle, jstring userMessageStr, jint maxTokens) {
    
    if (contextHandle == 0 || userMessageStr == nullptr) {
        return nullptr;
    }
    
    const char* userMessage = getStringUTFChars(env, userMessageStr);
    if (userMessage == nullptr) {
        return nullptr;
    }
    
    char* result = llama_mobile_generate_response_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle),
        userMessage,
        static_cast<int32_t>(maxTokens)
    );
    
    releaseStringUTFChars(env, userMessageStr, userMessage);
    
    if (result == nullptr) {
        return nullptr;
    }
    
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$ConversationResult");
    if (resultClass == nullptr) {
        llama_mobile_free_string_c(result);
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(Ljava/lang/String;JJI)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(resultClass);
        llama_mobile_free_string_c(result);
        return nullptr;
    }
    
    jstring text = env->NewStringUTF(result);
    jobject conversationResult = env->NewObject(resultClass, constructor, text, 0L, 0L, 0);
    
    env->DeleteLocalRef(text);
    env->DeleteLocalRef(resultClass);
    llama_mobile_free_string_c(result);
    
    return conversationResult;
}

// Clear conversation
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_clearConversation(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_clear_conversation_c(reinterpret_cast<llama_mobile_context_handle_t>(contextHandle));
    }
}

// Check if conversation is active
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isConversationActive(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    return llama_mobile_is_conversation_active_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    ) ? JNI_TRUE : JNI_FALSE;
}

// Get context window size
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getContextWindowSize(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return 0;
    }
    
    return llama_mobile_get_n_ctx_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
}

// Get embedding dimension
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getEmbeddingDimension(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return 0;
    }
    
    return llama_mobile_get_n_embd_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
}

// Get model description
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_getModelDescription(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return nullptr;
    }
    
    char* description = llama_mobile_get_model_desc_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
    
    if (description == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(description);
    
    llama_mobile_free_string_c(description);
    
    return result;
}

// Get model size
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_getModelSize(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return 0;
    }
    
    return llama_mobile_get_model_size_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
}

// Get model parameters count
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_getModelParametersCount(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle == 0) {
        return 0;
    }
    
    return llama_mobile_get_model_params_c(
        reinterpret_cast<llama_mobile_context_handle_t>(contextHandle)
    );
}

#ifdef __cplusplus
}
#endif
