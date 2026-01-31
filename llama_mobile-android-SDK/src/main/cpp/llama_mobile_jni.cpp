// JNI wrapper for llama_mobile Android library
// Supports both Java and Kotlin SDKs
#include <jni.h>
#include <string>
#include <cstring>
#include <vector>
#include <map>
#include <mutex>

// Include the llama_mobile headers
#include "llama_mobile_api.h"
#include "llama_mobile_ffi.h"

#ifdef __cplusplus
extern "C" {
#endif

// Global reference for JavaVM (needed for callback thread attachment)
static JavaVM* g_jvm = nullptr;

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

// Progress callback wrapper (uses user_data for per-context callbacks)
static void progressCallbackWrapper(float progress, void* user_data) {
    JNIEnv* env = nullptr;
    if (g_jvm == nullptr) {
        return;
    }
    
    jint getEnvResult = g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    bool shouldDetach = false;
    
    if (getEnvResult == JNI_EDETACHED) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            return;
        }
        shouldDetach = true;
    } else if (getEnvResult != JNI_OK) {
        return;
    }
    
    if (user_data == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jobject callback = static_cast<jobject>(user_data);
    if (callback == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jclass callbackClass = env->GetObjectClass(callback);
    if (callbackClass == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jmethodID onProgressMethod = env->GetMethodID(callbackClass, "onProgress", "(F)V");
    if (onProgressMethod != nullptr) {
        env->CallVoidMethod(callback, onProgressMethod, progress);
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
    }
    
    env->DeleteLocalRef(callbackClass);
    
    if (shouldDetach) {
        g_jvm->DetachCurrentThread();
    }
}

// Token callback wrapper (uses user_data for per-context callbacks)
static bool tokenCallbackWrapper(const char* token_json, void* user_data) {
    JNIEnv* env = nullptr;
    if (g_jvm == nullptr) {
        return true;
    }
    
    jint getEnvResult = g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    bool shouldDetach = false;
    
    if (getEnvResult == JNI_EDETACHED) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            return true;
        }
        shouldDetach = true;
    } else if (getEnvResult != JNI_OK) {
        return true;
    }
    
    if (user_data == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return true;
    }
    
    jobject callback = static_cast<jobject>(user_data);
    if (callback == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return true;
    }
    
    jclass callbackClass = env->GetObjectClass(callback);
    if (callbackClass == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return true;
    }
    
    jmethodID onTokenMethod = env->GetMethodID(callbackClass, "onToken", "(Ljava/lang/String;)Z");
    if (onTokenMethod == nullptr) {
        env->DeleteLocalRef(callbackClass);
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return true;
    }
    
    jstring tokenStr = token_json != nullptr ? env->NewStringUTF(token_json) : nullptr;
    jboolean result = env->CallBooleanMethod(callback, onTokenMethod, tokenStr);
    
    if (env->ExceptionCheck()) {
        env->ExceptionDescribe();
        env->ExceptionClear();
        result = JNI_TRUE;
    }
    
    if (tokenStr != nullptr) {
        env->DeleteLocalRef(tokenStr);
    }
    env->DeleteLocalRef(callbackClass);
    
    if (shouldDetach) {
        g_jvm->DetachCurrentThread();
    }
    
    return result == JNI_TRUE;
}

// Download progress callback wrapper (uses user_data for per-callback support)
static void downloadProgressCallbackWrapper(float progress, const char* status, int64_t downloaded_bytes, int64_t total_bytes, void* user_data) {
    JNIEnv* env = nullptr;
    if (g_jvm == nullptr) {
        return;
    }
    
    jint getEnvResult = g_jvm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    bool shouldDetach = false;
    
    if (getEnvResult == JNI_EDETACHED) {
        if (g_jvm->AttachCurrentThread(&env, nullptr) != JNI_OK) {
            return;
        }
        shouldDetach = true;
    } else if (getEnvResult != JNI_OK) {
        return;
    }
    
    if (user_data == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jobject callback = static_cast<jobject>(user_data);
    if (callback == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jclass callbackClass = env->GetObjectClass(callback);
    if (callbackClass == nullptr) {
        if (shouldDetach) {
            g_jvm->DetachCurrentThread();
        }
        return;
    }
    
    jmethodID onProgressMethod = env->GetMethodID(callbackClass, "onProgress", "(FLjava/lang/String;JJ)V");
    if (onProgressMethod != nullptr) {
        jstring statusStr = status != nullptr ? env->NewStringUTF(status) : nullptr;
        env->CallVoidMethod(callback, onProgressMethod, progress, statusStr, downloaded_bytes, total_bytes);
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        if (statusStr != nullptr) {
            env->DeleteLocalRef(statusStr);
        }
    }
    
    env->DeleteLocalRef(callbackClass);
    
    if (shouldDetach) {
        g_jvm->DetachCurrentThread();
    }
}

// Helper function to extract InitParams from Java object
static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate, const char*& systemPrompt, jstring& modelPathStr, jstring& chatTemplateStr, jstring& systemPromptStr, jstring& cacheTypeKStr, jstring& cacheTypeVStr) {
    jclass paramsClass = env->GetObjectClass(initParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields for Java InitParams
    jfieldID modelPathField = env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;");
    jfieldID nCtxField = env->GetFieldID(paramsClass, "nCtx", "I");
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    jfieldID systemPromptField = env->GetFieldID(paramsClass, "systemPrompt", "Ljava/lang/String;");
    jfieldID nBatchField = env->GetFieldID(paramsClass, "nBatch", "I");
    jfieldID nUBatchField = env->GetFieldID(paramsClass, "nUBatch", "I");
    jfieldID nGpuLayersField = env->GetFieldID(paramsClass, "nGpuLayers", "I");
    jfieldID nThreadsField = env->GetFieldID(paramsClass, "nThreads", "I");
    jfieldID useMmapField = env->GetFieldID(paramsClass, "useMmap", "Z");
    jfieldID useMlockField = env->GetFieldID(paramsClass, "useMlock", "Z");
    jfieldID embeddingField = env->GetFieldID(paramsClass, "embedding", "Z");
    jfieldID poolingTypeField = env->GetFieldID(paramsClass, "poolingType", "I");
    jfieldID embdNormalizeField = env->GetFieldID(paramsClass, "embdNormalize", "I");
    jfieldID flashAttnField = env->GetFieldID(paramsClass, "flashAttention", "Z");
    jfieldID cacheTypeKField = env->GetFieldID(paramsClass, "cacheTypeK", "Ljava/lang/String;");
    jfieldID cacheTypeVField = env->GetFieldID(paramsClass, "cacheTypeV", "Ljava/lang/String;");
    jfieldID enableChatTemplateField = env->GetFieldID(paramsClass, "enableChatTemplate", "Z");
    jfieldID progressCallbackField = env->GetFieldID(paramsClass, "progressCallback", "Lcom/llamamobile/LlamaMobile$ProgressCallback;");
    
    if (modelPathField == nullptr || nCtxField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
    jint nCtx = env->GetIntField(initParamsObj, nCtxField);
    chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
    systemPromptStr = (jstring)env->GetObjectField(initParamsObj, systemPromptField);
    jint nBatch = (nBatchField != nullptr) ? env->GetIntField(initParamsObj, nBatchField) : 512;
    jint nUbatch = (nUBatchField != nullptr) ? env->GetIntField(initParamsObj, nUBatchField) : 512;
    jint nGpuLayers = (nGpuLayersField != nullptr) ? env->GetIntField(initParamsObj, nGpuLayersField) : 0;
    jint nThreads = (nThreadsField != nullptr) ? env->GetIntField(initParamsObj, nThreadsField) : 4;
    jboolean useMmap = (useMmapField != nullptr) ? env->GetBooleanField(initParamsObj, useMmapField) : true;
    jboolean useMlock = (useMlockField != nullptr) ? env->GetBooleanField(initParamsObj, useMlockField) : false;
    jboolean embedding = (embeddingField != nullptr) ? env->GetBooleanField(initParamsObj, embeddingField) : false;
    jint poolingType = (poolingTypeField != nullptr) ? env->GetIntField(initParamsObj, poolingTypeField) : 0;
    jint embdNormalize = (embdNormalizeField != nullptr) ? env->GetIntField(initParamsObj, embdNormalizeField) : 0;
    jboolean flashAttn = (flashAttnField != nullptr) ? env->GetBooleanField(initParamsObj, flashAttnField) : false;
    jboolean enableChatTemplate = (enableChatTemplateField != nullptr) ? env->GetBooleanField(initParamsObj, enableChatTemplateField) : true;
    jobject progressCallbackObj = (progressCallbackField != nullptr) ? env->GetObjectField(initParamsObj, progressCallbackField) : nullptr;
    cacheTypeKStr = (cacheTypeKField != nullptr) ? (jstring)env->GetObjectField(initParamsObj, cacheTypeKField) : nullptr;
    cacheTypeVStr = (cacheTypeVField != nullptr) ? (jstring)env->GetObjectField(initParamsObj, cacheTypeVField) : nullptr;
    
    // Convert strings
    modelPath = getStringUTFChars(env, modelPathStr);
    chatTemplate = (chatTemplateField != nullptr) ? getStringUTFChars(env, chatTemplateStr) : nullptr;
    systemPrompt = (systemPromptField != nullptr) ? getStringUTFChars(env, systemPromptStr) : nullptr;
    const char* cacheTypeK = (cacheTypeKField != nullptr && cacheTypeKStr != nullptr) ? getStringUTFChars(env, cacheTypeKStr) : nullptr;
    const char* cacheTypeV = (cacheTypeVField != nullptr && cacheTypeVStr != nullptr) ? getStringUTFChars(env, cacheTypeVStr) : nullptr;
    
    // Set params
    memset(&params, 0, sizeof(llama_mobile_init_params_c_t));
    params.model_path = modelPath;
    params.n_ctx = nCtx;
    params.chat_template = chatTemplate;
    params.system_prompt = systemPrompt;
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
    params.cache_type_k = cacheTypeK;
    params.cache_type_v = cacheTypeV;
    params.enable_chat_template = enableChatTemplate;
    
    if (progressCallbackObj != nullptr) {
        params.progress_callback = progressCallbackWrapper;
        params.progress_callback_user_data = progressCallbackObj;
    } else {
        params.progress_callback = nullptr;
        params.progress_callback_user_data = nullptr;
    }
    
    env->DeleteLocalRef(paramsClass);
    
    return true;
}

// Extract CompletionParams from Java object
static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt, const char*& grammar, std::vector<std::string>& mediaPaths, jstring& promptStr, jstring& grammarStr, jstring& jsonSchemaStr, jstring& toolsStr, jstring& toolChoiceStr) {
    jclass paramsClass = env->GetObjectClass(completionParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields for Java CompletionParams
    jfieldID promptField = env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;");
    jfieldID temperatureField = env->GetFieldID(paramsClass, "temperature", "F");
    jfieldID maxTokensField = env->GetFieldID(paramsClass, "maxTokens", "I");
    jfieldID nThreadsField = env->GetFieldID(paramsClass, "nThreads", "I");
    jfieldID seedField = env->GetFieldID(paramsClass, "seed", "I");
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
    jfieldID jsonSchemaField = env->GetFieldID(paramsClass, "jsonSchema", "Ljava/lang/String;");
    jfieldID toolsField = env->GetFieldID(paramsClass, "tools", "Ljava/lang/String;");
    jfieldID parallelToolCallsField = env->GetFieldID(paramsClass, "parallelToolCalls", "Z");
    jfieldID toolChoiceField = env->GetFieldID(paramsClass, "toolChoice", "Ljava/lang/String;");
    jfieldID tokenCallbackField = env->GetFieldID(paramsClass, "tokenCallback", "Lcom/llamamobile/LlamaMobile$TokenCallback;");
    
    if (promptField == nullptr || temperatureField == nullptr || maxTokensField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
    jfloat temperature = env->GetFloatField(completionParamsObj, temperatureField);
    jint maxTokens = env->GetIntField(completionParamsObj, maxTokensField);
    
    // Handle int nThreads
    jint nThreads = 4; // Default value
    if (nThreadsField != nullptr) {
        nThreads = env->GetIntField(completionParamsObj, nThreadsField);
    }
    
    jint seed = (seedField != nullptr) ? env->GetIntField(completionParamsObj, seedField) : -1;
    jint topK = (topKField != nullptr) ? env->GetIntField(completionParamsObj, topKField) : 40;
    jdouble topP = (topPField != nullptr) ? env->GetDoubleField(completionParamsObj, topPField) : 0.95;
    jdouble minP = (minPField != nullptr) ? env->GetDoubleField(completionParamsObj, minPField) : 0.05;
    jdouble typicalP = (typicalPField != nullptr) ? env->GetDoubleField(completionParamsObj, typicalPField) : 1.0;
    jint penaltyLastN = (penaltyLastNField != nullptr) ? env->GetIntField(completionParamsObj, penaltyLastNField) : 64;
    jdouble penaltyRepeat = (penaltyRepeatField != nullptr) ? env->GetDoubleField(completionParamsObj, penaltyRepeatField) : 1.1;
    jdouble penaltyFreq = (penaltyFreqField != nullptr) ? env->GetDoubleField(completionParamsObj, penaltyFreqField) : 0.0;
    jdouble penaltyPresent = (penaltyPresentField != nullptr) ? env->GetDoubleField(completionParamsObj, penaltyPresentField) : 0.0;
    jint mirostat = (mirostatField != nullptr) ? env->GetIntField(completionParamsObj, mirostatField) : 0;
    jdouble mirostatTau = (mirostatTauField != nullptr) ? env->GetDoubleField(completionParamsObj, mirostatTauField) : 5.0;
    jdouble mirostatEta = (mirostatEtaField != nullptr) ? env->GetDoubleField(completionParamsObj, mirostatEtaField) : 0.1;
    jboolean ignoreEos = (ignoreEosField != nullptr) ? env->GetBooleanField(completionParamsObj, ignoreEosField) : false;
    jint nProbs = (nProbsField != nullptr) ? env->GetIntField(completionParamsObj, nProbsField) : 0;
    grammarStr = (grammarField != nullptr) ? (jstring)env->GetObjectField(completionParamsObj, grammarField) : nullptr;
    jsonSchemaStr = (jsonSchemaField != nullptr) ? (jstring)env->GetObjectField(completionParamsObj, jsonSchemaField) : nullptr;
    toolsStr = (toolsField != nullptr) ? (jstring)env->GetObjectField(completionParamsObj, toolsField) : nullptr;
    jboolean parallelToolCalls = (parallelToolCallsField != nullptr) ? env->GetBooleanField(completionParamsObj, parallelToolCallsField) : false;
    toolChoiceStr = (toolChoiceField != nullptr) ? (jstring)env->GetObjectField(completionParamsObj, toolChoiceField) : nullptr;
    
    // Extract stop sequences
    std::vector<std::string> stopSequences;
    jfieldID stopSequencesField = env->GetFieldID(paramsClass, "stopSequences", "Ljava/util/List;");
    if (stopSequencesField != nullptr) {
        jobject stopSequencesObj = env->GetObjectField(completionParamsObj, stopSequencesField);
        if (stopSequencesObj != nullptr) {
            jclass listClass = env->GetObjectClass(stopSequencesObj);
            jmethodID sizeMethod = env->GetMethodID(listClass, "size", "()I");
            jmethodID getMethod = env->GetMethodID(listClass, "get", "(I)Ljava/lang/Object;");
            
            if (sizeMethod != nullptr && getMethod != nullptr) {
                jint size = env->CallIntMethod(stopSequencesObj, sizeMethod);
                for (jint i = 0; i < size; i++) {
                    jobject stopSeqObj = env->CallObjectMethod(stopSequencesObj, getMethod, i);
                    if (stopSeqObj != nullptr) {
                        const char* stopSeq = getStringUTFChars(env, (jstring)stopSeqObj);
                        if (stopSeq != nullptr) {
                            stopSequences.push_back(std::string(stopSeq));
                            releaseStringUTFChars(env, (jstring)stopSeqObj, stopSeq);
                        }
                        env->DeleteLocalRef(stopSeqObj);
                    }
                }
            }
            
            env->DeleteLocalRef(listClass);
            env->DeleteLocalRef(stopSequencesObj);
        }
    }
    
    // Extract media paths
    mediaPaths.clear(); // Clear the passed vector
    jfieldID mediaPathsField = env->GetFieldID(paramsClass, "mediaPaths", "Ljava/util/List;");
    if (mediaPathsField != nullptr) {
        jobject mediaPathsObj = env->GetObjectField(completionParamsObj, mediaPathsField);
        if (mediaPathsObj != nullptr) {
            jclass listClass = env->GetObjectClass(mediaPathsObj);
            jmethodID sizeMethod = env->GetMethodID(listClass, "size", "()I");
            jmethodID getMethod = env->GetMethodID(listClass, "get", "(I)Ljava/lang/Object;");
            
            if (sizeMethod != nullptr && getMethod != nullptr) {
                jint size = env->CallIntMethod(mediaPathsObj, sizeMethod);
                for (jint i = 0; i < size; i++) {
                    jobject mediaPathObj = env->CallObjectMethod(mediaPathsObj, getMethod, i);
                    if (mediaPathObj != nullptr) {
                        const char* mediaPath = getStringUTFChars(env, (jstring)mediaPathObj);
                        if (mediaPath != nullptr) {
                            mediaPaths.push_back(std::string(mediaPath));
                            releaseStringUTFChars(env, (jstring)mediaPathObj, mediaPath);
                        }
                        env->DeleteLocalRef(mediaPathObj);
                    }
                }
            }
            
            env->DeleteLocalRef(listClass);
            env->DeleteLocalRef(mediaPathsObj);
        }
    }
    
    // Extract chat messages
    std::vector<llama_mobile_chat_message_c> chatMessages;
    jfieldID chatMessagesField = env->GetFieldID(paramsClass, "chatMessages", "Ljava/util/List;");
    if (chatMessagesField != nullptr) {
        jobject chatMessagesObj = env->GetObjectField(completionParamsObj, chatMessagesField);
        if (chatMessagesObj != nullptr) {
            jclass listClass = env->GetObjectClass(chatMessagesObj);
            jmethodID sizeMethod = env->GetMethodID(listClass, "size", "()I");
            jmethodID getMethod = env->GetMethodID(listClass, "get", "(I)Ljava/lang/Object;");
            
            if (sizeMethod != nullptr && getMethod != nullptr) {
                jint size = env->CallIntMethod(chatMessagesObj, sizeMethod);
                for (jint i = 0; i < size; i++) {
                    jobject chatMessageObj = env->CallObjectMethod(chatMessagesObj, getMethod, i);
                    if (chatMessageObj != nullptr) {
                        jclass chatMessageClass = env->GetObjectClass(chatMessageObj);
                        jfieldID roleField = env->GetFieldID(chatMessageClass, "role", "Ljava/lang/String;");
                        jfieldID contentField = env->GetFieldID(chatMessageClass, "content", "Ljava/lang/String;");
                        jfieldID reasoningContentField = env->GetFieldID(chatMessageClass, "reasoningContent", "Ljava/lang/String;");
                        jfieldID toolNameField = env->GetFieldID(chatMessageClass, "toolName", "Ljava/lang/String;");
                        jfieldID toolCallIdField = env->GetFieldID(chatMessageClass, "toolCallId", "Ljava/lang/String;");
                        
                        if (roleField != nullptr && contentField != nullptr) {
                            jstring roleStr = (jstring)env->GetObjectField(chatMessageObj, roleField);
                            jstring contentStr = (jstring)env->GetObjectField(chatMessageObj, contentField);
                            jstring reasoningContentStr = (reasoningContentField != nullptr) ? (jstring)env->GetObjectField(chatMessageObj, reasoningContentField) : nullptr;
                            jstring toolNameStr = (toolNameField != nullptr) ? (jstring)env->GetObjectField(chatMessageObj, toolNameField) : nullptr;
                            jstring toolCallIdStr = (toolCallIdField != nullptr) ? (jstring)env->GetObjectField(chatMessageObj, toolCallIdField) : nullptr;
                            
                            const char* role = getStringUTFChars(env, roleStr);
                            const char* content = getStringUTFChars(env, contentStr);
                            const char* reasoningContent = (reasoningContentStr != nullptr) ? getStringUTFChars(env, reasoningContentStr) : nullptr;
                            const char* toolName = (toolNameStr != nullptr) ? getStringUTFChars(env, toolNameStr) : nullptr;
                            const char* toolCallId = (toolCallIdStr != nullptr) ? getStringUTFChars(env, toolCallIdStr) : nullptr;
                            
                            if (role != nullptr && content != nullptr) {
                                llama_mobile_chat_message_c message;
                                message.role = strdup(role);
                                message.content = strdup(content);
                                message.reasoning_content = (reasoningContent != nullptr) ? strdup(reasoningContent) : nullptr;
                                message.tool_name = (toolName != nullptr) ? strdup(toolName) : nullptr;
                                message.tool_call_id = (toolCallId != nullptr) ? strdup(toolCallId) : nullptr;
                                chatMessages.push_back(message);
                            }
                            
                            releaseStringUTFChars(env, roleStr, role);
                            releaseStringUTFChars(env, contentStr, content);
                            if (reasoningContentStr != nullptr) {
                                releaseStringUTFChars(env, reasoningContentStr, reasoningContent);
                            }
                            if (toolNameStr != nullptr) {
                                releaseStringUTFChars(env, toolNameStr, toolName);
                            }
                            if (toolCallIdStr != nullptr) {
                                releaseStringUTFChars(env, toolCallIdStr, toolCallId);
                            }
                            
                            env->DeleteLocalRef(roleStr);
                            env->DeleteLocalRef(contentStr);
                            if (reasoningContentStr != nullptr) {
                                env->DeleteLocalRef(reasoningContentStr);
                            }
                            if (toolNameStr != nullptr) {
                                env->DeleteLocalRef(toolNameStr);
                            }
                            if (toolCallIdStr != nullptr) {
                                env->DeleteLocalRef(toolCallIdStr);
                            }
                        }
                        
                        env->DeleteLocalRef(chatMessageClass);
                        env->DeleteLocalRef(chatMessageObj);
                    }
                }
            }
            
            env->DeleteLocalRef(listClass);
            env->DeleteLocalRef(chatMessagesObj);
        }
    }
    
    // Extract useJsonResponse flag
    bool useJsonResponse = false;
    jfieldID useJsonResponseField = env->GetFieldID(paramsClass, "useJsonResponse", "Z");
    if (useJsonResponseField != nullptr) {
        useJsonResponse = env->GetBooleanField(completionParamsObj, useJsonResponseField);
    }
    
    // Convert strings
    prompt = getStringUTFChars(env, promptStr);
    grammar = (grammarField != nullptr && grammarStr != nullptr) ? getStringUTFChars(env, grammarStr) : nullptr;
    const char* jsonSchema = (jsonSchemaField != nullptr && jsonSchemaStr != nullptr) ? getStringUTFChars(env, jsonSchemaStr) : nullptr;
    const char* tools = (toolsField != nullptr && toolsStr != nullptr) ? getStringUTFChars(env, toolsStr) : nullptr;
    const char* toolChoice = (toolChoiceField != nullptr && toolChoiceStr != nullptr) ? getStringUTFChars(env, toolChoiceStr) : nullptr;
    
    // Set params
    memset(&params, 0, sizeof(llama_mobile_completion_params_c_t));
    
    // Only set prompt if chat messages are not provided
    if (chatMessages.empty()) {
        params.prompt = prompt;
    }
    
    params.temperature = temperature;
    params.n_predict = maxTokens;
    params.n_threads = nThreads;
    params.seed = seed;
    params.top_k = topK;
    params.top_p = (float)topP;
    params.min_p = (float)minP;
    params.typical_p = (float)typicalP;
    params.penalty_last_n = penaltyLastN;
    params.penalty_repeat = (float)penaltyRepeat;
    params.penalty_freq = (float)penaltyFreq;
    params.penalty_present = (float)penaltyPresent;
    params.mirostat = mirostat;
    params.mirostat_tau = (float)mirostatTau;
    params.mirostat_eta = (float)mirostatEta;
    params.ignore_eos = ignoreEos;
    params.n_probs = nProbs;
    params.grammar = grammar;
    
    // Set chat messages
    if (!chatMessages.empty()) {
        // Allocate non-const memory first
        llama_mobile_chat_message_c* temp_messages = new llama_mobile_chat_message_c[chatMessages.size()];
        
        // Copy elements individually
        for (size_t i = 0; i < chatMessages.size(); i++) {
            temp_messages[i].role = chatMessages[i].role;
            temp_messages[i].content = chatMessages[i].content;
            temp_messages[i].reasoning_content = chatMessages[i].reasoning_content;
            temp_messages[i].tool_name = chatMessages[i].tool_name;
            temp_messages[i].tool_call_id = chatMessages[i].tool_call_id;
        }
        
        // Assign to the const pointer
        params.chat_messages = temp_messages;
        params.chat_message_count = static_cast<int32_t>(chatMessages.size());
    }
    
    // Set JSON response flag
    params.use_json_response = useJsonResponse;
    
    // Set new fields
    params.json_schema = jsonSchema;
    params.tools = tools;
    params.parallel_tool_calls = parallelToolCalls;
    params.tool_choice = toolChoice;
    
    // Extract and set token callback
    jobject tokenCallbackObj = (tokenCallbackField != nullptr) ? env->GetObjectField(completionParamsObj, tokenCallbackField) : nullptr;
    if (tokenCallbackObj != nullptr) {
        params.token_callback = tokenCallbackWrapper;
        params.token_callback_user_data = tokenCallbackObj;
    } else {
        params.token_callback = nullptr;
        params.token_callback_user_data = nullptr;
    }
    
    // Set stop sequences
    if (!stopSequences.empty()) {
        params.stop_sequences = new const char*[stopSequences.size() + 1];
        for (size_t i = 0; i < stopSequences.size(); i++) {
            params.stop_sequences[i] = strdup(stopSequences[i].c_str());
        }
        params.stop_sequences[stopSequences.size()] = nullptr;
        params.stop_sequence_count = static_cast<int>(stopSequences.size());
    }
    
    // Don't delete the jstring objects here - they need to be kept alive
    // so the caller can release the C string pointers properly
    
    return true;
}

// Create CompletionResult Java object from C struct
static jobject createCompletionResult(JNIEnv* env, const llama_mobile_completion_result_c_t& result) {
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$CompletionResult");
    if (resultClass == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(Ljava/lang/String;IIZZZZLjava/lang/String;)V");
    if (constructor == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jstring text = env->NewStringUTF(result.text);
    if (text == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jstring stoppingWord = result.stopping_word ? env->NewStringUTF(result.stopping_word) : nullptr;
    if (env->ExceptionCheck()) {
        env->DeleteLocalRef(text);
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jobject completionResult = env->NewObject(resultClass, constructor,
        text,
        (jint)result.tokens_predicted,
        (jint)result.tokens_evaluated,
        (jboolean)result.truncated,
        (jboolean)result.stopped_eos,
        (jboolean)result.stopped_word,
        (jboolean)result.stopped_limit,
        stoppingWord);
    
    env->DeleteLocalRef(text);
    env->DeleteLocalRef(stoppingWord);
    env->DeleteLocalRef(resultClass);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return completionResult;
}

// Create ConversationResult Java object
static jobject createConversationResult(JNIEnv* env, const char* text, long timeToFirstToken, long totalTime, int tokensGenerated) {
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$ConversationResult");
    if (resultClass == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(Ljava/lang/String;JJI)V");
    if (constructor == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jstring textStr = env->NewStringUTF(text);
    if (textStr == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    jobject conversationResult = env->NewObject(resultClass, constructor,
        textStr,
        (jlong)timeToFirstToken,
        (jlong)totalTime,
        (jint)tokensGenerated);
    
    env->DeleteLocalRef(textStr);
    env->DeleteLocalRef(resultClass);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return conversationResult;
}

// JNI method implementations

// Initializes a new context for the model
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(JNIEnv* env, jclass clazz, jobject initParamsObj) {
    llama_mobile_init_params_c_t params;
    const char* modelPath = nullptr;
    const char* chatTemplate = nullptr;
    const char* systemPrompt = nullptr;
    
    jstring modelPathStr = nullptr;
    jstring chatTemplateStr = nullptr;
    jstring systemPromptStr = nullptr;
    jstring cacheTypeKStr = nullptr;
    jstring cacheTypeVStr = nullptr;
    
    if (env->ExceptionCheck()) {
        return 0;
    }
    
    if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate, systemPrompt, modelPathStr, chatTemplateStr, systemPromptStr, cacheTypeKStr, cacheTypeVStr)) {
        return 0;
    }
    
    if (env->ExceptionCheck()) {
        if (modelPathStr != nullptr) env->DeleteLocalRef(modelPathStr);
        if (chatTemplateStr != nullptr) env->DeleteLocalRef(chatTemplateStr);
        if (systemPromptStr != nullptr) env->DeleteLocalRef(systemPromptStr);
        if (cacheTypeKStr != nullptr) env->DeleteLocalRef(cacheTypeKStr);
        if (cacheTypeVStr != nullptr) env->DeleteLocalRef(cacheTypeVStr);
        return 0;
    }
    
    llama_mobile_context_handle_t context = llama_mobile_init_context_c(&params);
    
    releaseStringUTFChars(env, modelPathStr, modelPath);
    if (chatTemplateStr != nullptr && chatTemplate != nullptr) {
        releaseStringUTFChars(env, chatTemplateStr, chatTemplate);
    }
    if (systemPromptStr != nullptr && systemPrompt != nullptr) {
        releaseStringUTFChars(env, systemPromptStr, systemPrompt);
    }
    if (cacheTypeKStr != nullptr && params.cache_type_k != nullptr) {
        releaseStringUTFChars(env, cacheTypeKStr, params.cache_type_k);
    }
    if (cacheTypeVStr != nullptr && params.cache_type_v != nullptr) {
        releaseStringUTFChars(env, cacheTypeVStr, params.cache_type_v);
    }
    
    if (modelPathStr != nullptr) env->DeleteLocalRef(modelPathStr);
    if (chatTemplateStr != nullptr) env->DeleteLocalRef(chatTemplateStr);
    if (systemPromptStr != nullptr) env->DeleteLocalRef(systemPromptStr);
    if (cacheTypeKStr != nullptr) env->DeleteLocalRef(cacheTypeKStr);
    if (cacheTypeVStr != nullptr) env->DeleteLocalRef(cacheTypeVStr);
    
    return reinterpret_cast<jlong>(context);
}

// Generates completion text based on the given prompt and parameters
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_nativeGenerateCompletion(JNIEnv* env, jclass cls, jlong contextHandle, jobject completionParamsObj) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    llama_mobile_completion_params_c_t params;
    const char* prompt = nullptr;
    const char* grammar = nullptr;
    std::vector<std::string> mediaPaths;
    jstring promptStr = nullptr;
    jstring grammarStr = nullptr;
    jstring jsonSchemaStr = nullptr;
    jstring toolsStr = nullptr;
    jstring toolChoiceStr = nullptr;
    
    if (!extractCompletionParams(env, completionParamsObj, params, prompt, grammar, mediaPaths, promptStr, grammarStr, jsonSchemaStr, toolsStr, toolChoiceStr)) {
        return nullptr;
    }
    
    llama_mobile_completion_result_c_t result;
    memset(&result, 0, sizeof(llama_mobile_completion_result_c_t));
    int ret;
    
    // Use multimodal completion if media paths are present
    if (!mediaPaths.empty()) {
        const char** mediaPathsArray = new const char*[mediaPaths.size()];
        for (size_t i = 0; i < mediaPaths.size(); i++) {
            mediaPathsArray[i] = mediaPaths[i].c_str();
        }
        
        ret = llama_mobile_multimodal_completion_c(context, &params, mediaPathsArray, static_cast<int>(mediaPaths.size()), &result);
        
        delete[] mediaPathsArray;
    } else {
        ret = llama_mobile_completion_c(context, &params, &result);
    }
    
    // Release C string pointers
    if (prompt != nullptr) {
        releaseStringUTFChars(env, promptStr, prompt);
    }
    if (grammar != nullptr) {
        releaseStringUTFChars(env, grammarStr, grammar);
    }
    if (params.json_schema != nullptr) {
        releaseStringUTFChars(env, jsonSchemaStr, params.json_schema);
    }
    if (params.tools != nullptr) {
        releaseStringUTFChars(env, toolsStr, params.tools);
    }
    if (params.tool_choice != nullptr) {
        releaseStringUTFChars(env, toolChoiceStr, params.tool_choice);
    }
    
    // Release jstring objects
    if (promptStr != nullptr) env->DeleteLocalRef(promptStr);
    if (grammarStr != nullptr) env->DeleteLocalRef(grammarStr);
    if (jsonSchemaStr != nullptr) env->DeleteLocalRef(jsonSchemaStr);
    if (toolsStr != nullptr) env->DeleteLocalRef(toolsStr);
    if (toolChoiceStr != nullptr) env->DeleteLocalRef(toolChoiceStr);
    
    // Free stop sequences
    if (params.stop_sequences != nullptr) {
        for (size_t i = 0; params.stop_sequences[i] != nullptr; i++) {
            free((void*)params.stop_sequences[i]);
        }
        delete[] params.stop_sequences;
    }
    
    // Free chat messages
    if (params.chat_messages != nullptr && params.chat_message_count > 0) {
        for (int i = 0; i < params.chat_message_count; i++) {
            free((void*)params.chat_messages[i].role);
            free((void*)params.chat_messages[i].content);
            if (params.chat_messages[i].reasoning_content != nullptr) {
                free((void*)params.chat_messages[i].reasoning_content);
            }
            if (params.chat_messages[i].tool_name != nullptr) {
                free((void*)params.chat_messages[i].tool_name);
            }
            if (params.chat_messages[i].tool_call_id != nullptr) {
                free((void*)params.chat_messages[i].tool_call_id);
            }
        }
        delete[] params.chat_messages;
    }
    
    if (ret != 0) {
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    jobject completionResult = createCompletionResult(env, result);
    llama_mobile_free_completion_result_members_c(&result);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return completionResult;
}

// Stops an ongoing completion generation
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_stopCompletion(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_stop_completion_c(context);
}

// Tokenizes a text string into token IDs
JNIEXPORT jintArray JNICALL Java_com_llamamobile_LlamaMobile_tokenize(JNIEnv* env, jclass clazz, jlong contextHandle, jstring text) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cText = getStringUTFChars(env, text);
    if (cText == nullptr) {
        return nullptr;
    }
    
    llama_mobile_token_array_c_t tokens = llama_mobile_tokenize_c(context, cText);
    
    releaseStringUTFChars(env, text, cText);
    
    jintArray result = env->NewIntArray(tokens.count);
    if (result == nullptr || env->ExceptionCheck()) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    
    llama_mobile_free_token_array_c(tokens);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return result;
}

// Detokenizes token IDs back to a text string
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_detokenize(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    jsize length = env->GetArrayLength(tokens);
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    jint* tokenArray = env->GetIntArrayElements(tokens, nullptr);
    if (tokenArray == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    std::vector<int32_t> cTokens(length);
    for (jsize i = 0; i < length; ++i) {
        cTokens[i] = static_cast<int32_t>(tokenArray[i]);
    }
    
    char* text = llama_mobile_detokenize_c(context, cTokens.data(), cTokens.size());
    
    env->ReleaseIntArrayElements(tokens, tokenArray, JNI_ABORT);
    
    if (text == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(text);
    free(text);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return result;
}

// Generates embeddings for the given text
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_generateEmbeddings(JNIEnv* env, jclass clazz, jlong contextHandle, jstring text) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cText = getStringUTFChars(env, text);
    if (cText == nullptr) {
        return nullptr;
    }
    
    llama_mobile_float_array_c_t embeddings = llama_mobile_embedding_c(context, cText);
    
    releaseStringUTFChars(env, text, cText);
    
    if (embeddings.values == nullptr) {
        return nullptr;
    }
    
    jfloatArray result = env->NewFloatArray(embeddings.count);
    if (result == nullptr || env->ExceptionCheck()) {
        free(embeddings.values);
        return nullptr;
    }
    
    env->SetFloatArrayRegion(result, 0, embeddings.count, embeddings.values);
    
    free(embeddings.values);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return result;
}

// Initializes multimodal support
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_initMultimodal(JNIEnv* env, jclass clazz, jlong contextHandle, jstring mmprojPath, jboolean useGpu) {
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    if (env->ExceptionCheck()) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cMmprojPath = getStringUTFChars(env, mmprojPath);
    if (cMmprojPath == nullptr) {
        return JNI_FALSE;
    }
    
    bool success = llama_mobile_init_multimodal_c(context, cMmprojPath, useGpu);
    
    releaseStringUTFChars(env, mmprojPath, cMmprojPath);
    
    return success ? JNI_TRUE : JNI_FALSE;
}

// Checks if multimodal support is enabled
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isMultimodalEnabled(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return llama_mobile_is_multimodal_enabled_c(context) ? JNI_TRUE : JNI_FALSE;
}

// Checks if vision is supported
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_supportsVision(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return llama_mobile_supports_vision_c(context) ? JNI_TRUE : JNI_FALSE;
}

// Checks if audio is supported
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_supportsAudio(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return llama_mobile_supports_audio_c(context) ? JNI_TRUE : JNI_FALSE;
}

// Formats chat messages using the specified template
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_formatChatMessages(JNIEnv* env, jclass clazz, jlong contextHandle, jstring messagesJson, jstring chatTemplate) {
    if (contextHandle == 0 || messagesJson == nullptr) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    const char* messages_c = env->GetStringUTFChars(messagesJson, nullptr);
    if (messages_c == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    const char* template_c = chatTemplate != nullptr ? env->GetStringUTFChars(chatTemplate, nullptr) : nullptr;
    if (env->ExceptionCheck()) {
        env->ReleaseStringUTFChars(messagesJson, messages_c);
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    char* formatted_prompt = llama_mobile_get_formatted_chat_c(context, messages_c, template_c);
    
    env->ReleaseStringUTFChars(messagesJson, messages_c);
    if (chatTemplate != nullptr) {
        env->ReleaseStringUTFChars(chatTemplate, template_c);
    }
    
    if (formatted_prompt != nullptr) {
        jstring result = env->NewStringUTF(formatted_prompt);
        llama_mobile_free_string_c(formatted_prompt);
        
        if (env->ExceptionCheck()) {
            return nullptr;
        }
        
        return result;
    }
    
    return nullptr;
}

// Releases multimodal resources
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseMultimodal(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_release_multimodal_c(context);
}

// Initializes vocoder for text-to-speech
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_initVocoder(JNIEnv* env, jclass clazz, jlong contextHandle, jstring vocoderModelPath) {
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    if (env->ExceptionCheck()) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cVocoderModelPath = getStringUTFChars(env, vocoderModelPath);
    if (cVocoderModelPath == nullptr) {
        return JNI_FALSE;
    }
    
    bool success = llama_mobile_init_vocoder_c(context, cVocoderModelPath);
    
    releaseStringUTFChars(env, vocoderModelPath, cVocoderModelPath);
    
    return success ? JNI_TRUE : JNI_FALSE;
}

// Checks if vocoder is enabled
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isVocoderEnabled(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return llama_mobile_is_vocoder_enabled_c(context) ? JNI_TRUE : JNI_FALSE;
}

// Gets the TTS model type
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_getTTSType(JNIEnv* env, jclass clazz, jlong contextHandle) {
    jclass ttsModelTypeClass = env->FindClass("com/llamamobile/LlamaMobile$TTSModelType");
    if (ttsModelTypeClass == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    jfieldID valuesField = env->GetStaticFieldID(ttsModelTypeClass, "$VALUES", "[Lcom/llamamobile/LlamaMobile$TTSModelType;");
    if (valuesField == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(ttsModelTypeClass);
        return nullptr;
    }
    
    jobjectArray enumValues = (jobjectArray)env->GetStaticObjectField(ttsModelTypeClass, valuesField);
    if (enumValues == nullptr || env->ExceptionCheck()) {
        env->DeleteLocalRef(ttsModelTypeClass);
        return nullptr;
    }
    
    if (contextHandle == 0) {
        jobject unknownEnum = env->GetObjectArrayElement(enumValues, 0);
        env->DeleteLocalRef(ttsModelTypeClass);
        env->DeleteLocalRef(enumValues);
        return unknownEnum;
    }
    
    int index;
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    int ttsType = static_cast<int>(llama_mobile_get_tts_type_c(context));
    switch (ttsType) {
        case 1: index = 1; break;
        case 2: index = 2; break;
        case 4: index = 3; break;
        case 5: index = 4; break;
        default: index = 0; break;
    }
    
    jobject enumValue = env->GetObjectArrayElement(enumValues, index);
    if (enumValue != nullptr) {
        env->DeleteLocalRef(ttsModelTypeClass);
        env->DeleteLocalRef(enumValues);
        return env->NewLocalRef(enumValue);
    }
    
    env->DeleteLocalRef(ttsModelTypeClass);
    env->DeleteLocalRef(enumValues);
    return nullptr;
}

// Gets formatted audio completion
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_getFormattedAudioCompletion(JNIEnv* env, jclass clazz, jlong contextHandle, jstring speakerJson, jstring textToSpeak) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cSpeakerJson = getStringUTFChars(env, speakerJson);
    const char* cTextToSpeak = getStringUTFChars(env, textToSpeak);
    
    if (cSpeakerJson == nullptr || cTextToSpeak == nullptr) {
        releaseStringUTFChars(env, speakerJson, cSpeakerJson);
        releaseStringUTFChars(env, textToSpeak, cTextToSpeak);
        return nullptr;
    }
    
    // Use FFI function that returns result directly
    char* resultText = llama_mobile_get_formatted_audio_completion_c(context, cSpeakerJson, cTextToSpeak);
    
    releaseStringUTFChars(env, speakerJson, cSpeakerJson);
    releaseStringUTFChars(env, textToSpeak, cTextToSpeak);
    
    if (resultText == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(resultText);
    free(resultText);
    
    return result;
}

// Gets audio guide tokens
JNIEXPORT jintArray JNICALL Java_com_llamamobile_LlamaMobile_getAudioGuideTokens(JNIEnv* env, jclass clazz, jlong contextHandle, jstring textToSpeak) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cTextToSpeak = getStringUTFChars(env, textToSpeak);
    if (cTextToSpeak == nullptr) {
        return nullptr;
    }
    
    llama_mobile_token_array_c_t tokens = llama_mobile_get_audio_guide_tokens_c(context, cTextToSpeak);
    
    releaseStringUTFChars(env, textToSpeak, cTextToSpeak);
    
    if (tokens.tokens == nullptr) {
        return nullptr;
    }
    
    jintArray result = env->NewIntArray(tokens.count);
    if (result == nullptr || env->ExceptionCheck()) {
        llama_mobile_free_token_array_c(tokens);
        return nullptr;
    }
    
    env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    
    llama_mobile_free_token_array_c(tokens);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return result;
}

// Decodes audio tokens
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_decodeAudioTokens(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    jsize length = env->GetArrayLength(tokens);
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    jint* tokenArray = env->GetIntArrayElements(tokens, nullptr);
    if (tokenArray == nullptr || env->ExceptionCheck()) {
        return nullptr;
    }
    
    std::vector<int32_t> cTokens(length);
    for (jsize i = 0; i < length; ++i) {
        cTokens[i] = static_cast<int32_t>(tokenArray[i]);
    }
    
    llama_mobile_float_array_c_t audioData = llama_mobile_decode_audio_tokens_c(context, cTokens.data(), cTokens.size());
    
    env->ReleaseIntArrayElements(tokens, tokenArray, JNI_ABORT);
    
    if (audioData.values == nullptr) {
        return nullptr;
    }
    
    jfloatArray result = env->NewFloatArray(audioData.count);
    if (result == nullptr || env->ExceptionCheck()) {
        llama_mobile_free_float_array_c(audioData);
        return nullptr;
    }
    
    env->SetFloatArrayRegion(result, 0, audioData.count, audioData.values);
    
    llama_mobile_free_float_array_c(audioData);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return result;
}

// Sets guide tokens for audio generation
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_setGuideTokens(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    if (contextHandle == 0 || tokens == nullptr) {
        return;
    }
    
    if (env->ExceptionCheck()) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    jsize tokenCount = env->GetArrayLength(tokens);
    if (env->ExceptionCheck()) {
        return;
    }
    
    jint* tokenValues = env->GetIntArrayElements(tokens, nullptr);
    if (tokenValues == nullptr || env->ExceptionCheck()) {
        return;
    }
    
    std::vector<int32_t> tokenVector;
    tokenVector.reserve(tokenCount);
    
    for (jsize i = 0; i < tokenCount; i++) {
        tokenVector.push_back(static_cast<int32_t>(tokenValues[i]));
    }
    
    llama_mobile_set_guide_tokens_c(context, tokenVector.data(), tokenVector.size());
    
    env->ReleaseIntArrayElements(tokens, tokenValues, JNI_ABORT);
}

// Saves audio samples to WAV file
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_saveAudioToWav(JNIEnv* env, jclass clazz, jlong contextHandle, jstring filePath, jfloatArray audioData, jint sampleRate) {
    if (contextHandle == 0 || filePath == nullptr || audioData == nullptr) {
        return JNI_FALSE;
    }
    
    if (env->ExceptionCheck()) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cFilePath = getStringUTFChars(env, filePath);
    if (cFilePath == nullptr) {
        return JNI_FALSE;
    }
    
    jsize dataCount = env->GetArrayLength(audioData);
    if (env->ExceptionCheck()) {
        releaseStringUTFChars(env, filePath, cFilePath);
        return JNI_FALSE;
    }
    
    jfloat* dataValues = env->GetFloatArrayElements(audioData, nullptr);
    if (dataValues == nullptr || env->ExceptionCheck()) {
        releaseStringUTFChars(env, filePath, cFilePath);
        return JNI_FALSE;
    }
    
    std::vector<float> audioVector;
    audioVector.reserve(dataCount);
    
    for (jsize i = 0; i < dataCount; i++) {
        audioVector.push_back(static_cast<float>(dataValues[i]));
    }
    
    bool result = llama_mobile_save_audio_to_wav_c(context, cFilePath, audioVector.data(), audioVector.size(), sampleRate);
    
    env->ReleaseFloatArrayElements(audioData, dataValues, JNI_ABORT);
    releaseStringUTFChars(env, filePath, cFilePath);
    
    return result ? JNI_TRUE : JNI_FALSE;
}

// Releases vocoder resources
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseVocoder(JNIEnv* env, jclass clazz, jlong contextHandle) {
    if (contextHandle == 0) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_release_vocoder_c(context);
}

// Applies LoRA adapters
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_applyLoraAdapters(JNIEnv* env, jclass clazz, jlong contextHandle, jobjectArray adaptersArray) {
    if (contextHandle == 0 || adaptersArray == nullptr) {
        return JNI_FALSE;
    }
    
    if (env->ExceptionCheck()) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    if (!context) {
        return JNI_FALSE;
    }

    jsize adapterCount = env->GetArrayLength(adaptersArray);
    if (adapterCount == 0 || env->ExceptionCheck()) {
        return JNI_FALSE;
    }

    llama_mobile_lora_adapter_t* adapters = new llama_mobile_lora_adapter_t[adapterCount];
    if (!adapters) {
        return JNI_FALSE;
    }

    jclass loraAdapterClass = env->FindClass("com/llamamobile/LlamaMobile$LoraAdapter");
    if (!loraAdapterClass || env->ExceptionCheck()) {
        delete[] adapters;
        return JNI_FALSE;
    }

    jfieldID pathField = env->GetFieldID(loraAdapterClass, "path", "Ljava/lang/String;");
    jfieldID scaleField = env->GetFieldID(loraAdapterClass, "scale", "F");
    if (!pathField || !scaleField || env->ExceptionCheck()) {
        env->DeleteLocalRef(loraAdapterClass);
        delete[] adapters;
        return JNI_FALSE;
    }

    std::vector<jstring> pathStrings;
    for (int i = 0; i < adapterCount; i++) {
        jobject adapterObj = env->GetObjectArrayElement(adaptersArray, i);
        if (!adapterObj || env->ExceptionCheck()) {
            continue;
        }

        jstring pathStr = static_cast<jstring>(env->GetObjectField(adapterObj, pathField));
        if (pathStr) {
            pathStrings.push_back(pathStr);
            const char* path = env->GetStringUTFChars(pathStr, nullptr);
            if (path) {
                adapters[i].path = path;
            }
        }

        adapters[i].scale = env->GetFloatField(adapterObj, scaleField);

        env->DeleteLocalRef(adapterObj);
    }

    int result = llama_mobile_apply_lora_adapters(context, adapters, adapterCount);

    for (int i = 0; i < pathStrings.size(); i++) {
        if (adapters[i].path) {
            env->ReleaseStringUTFChars(pathStrings[i], adapters[i].path);
        }
        env->DeleteLocalRef(pathStrings[i]);
    }
    delete[] adapters;
    env->DeleteLocalRef(loraAdapterClass);

    return (result == 0) ? JNI_TRUE : JNI_FALSE;
}

// Removes all LoRA adapters
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_removeLoraAdapters(JNIEnv* env, jclass clazz, jlong contextHandle) {
    if (contextHandle != 0) {
        llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
        llama_mobile_remove_lora_adapters(context);
    }
}

// Gets loaded LoRA adapters
JNIEXPORT jobjectArray JNICALL Java_com_llamamobile_LlamaMobile_getLoadedLoraAdapters(JNIEnv* env, jclass clazz, jlong contextHandle) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    llama_mobile_lora_adapters_c_t adapters = llama_mobile_get_loaded_lora_adapters_c(context);
    
    if (adapters.count == 0 || adapters.adapters == nullptr) {
        return nullptr;
    }
    
    jclass loraAdapterClass = env->FindClass("com/llamamobile/LlamaMobile$LoraAdapter");
    if (loraAdapterClass == nullptr) {
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(loraAdapterClass, "<init>", "(Ljava/lang/String;F)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(loraAdapterClass);
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    jobjectArray resultArray = env->NewObjectArray(adapters.count, loraAdapterClass, nullptr);
    if (resultArray == nullptr) {
        env->DeleteLocalRef(loraAdapterClass);
        llama_mobile_free_lora_adapters_c(&adapters);
        return nullptr;
    }
    
    for (int32_t i = 0; i < adapters.count; i++) {
        jstring path = adapters.adapters[i].path != nullptr ? env->NewStringUTF(adapters.adapters[i].path) : nullptr;
        jfloat scale = static_cast<jfloat>(adapters.adapters[i].scale);
        
        jobject adapterObj = env->NewObject(loraAdapterClass, constructor, path, scale);
        
        if (adapterObj != nullptr) {
            env->SetObjectArrayElement(resultArray, i, adapterObj);
            env->DeleteLocalRef(adapterObj);
        }
        
        if (path != nullptr) {
            env->DeleteLocalRef(path);
        }
    }
    
    llama_mobile_free_lora_adapters_c(&adapters);
    env->DeleteLocalRef(loraAdapterClass);
    
    return resultArray;
}

// Generates a response in conversation mode
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_generateResponse(JNIEnv* env, jclass clazz, jlong contextHandle, jstring userMessage, jint maxTokens) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cUserMessage = getStringUTFChars(env, userMessage);
    if (cUserMessage == nullptr) {
        return nullptr;
    }
    
    char* responseText = llama_mobile_generate_response_c(context, cUserMessage, maxTokens);
    
    releaseStringUTFChars(env, userMessage, cUserMessage);
    
    if (responseText == nullptr) {
        return nullptr;
    }
    
    jobject responseResult = createConversationResult(env, responseText, 0, 0, 0);
    free(responseText);
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    return responseResult;
}

// Clears the current conversation context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_clearConversation(JNIEnv* env, jclass clazz, jlong contextHandle) {
    if (contextHandle == 0) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_clear_conversation_c(context);
}

// Checks if a conversation is currently active
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_isConversationActive(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return llama_mobile_is_conversation_active_c(context) ? JNI_TRUE : JNI_FALSE;
}

// Gets the context window size
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getContextWindowSize(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return 0;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return static_cast<jint>(llama_mobile_get_n_ctx_c(context));
}

// Gets the embedding dimension
JNIEXPORT jint JNICALL Java_com_llamamobile_LlamaMobile_getEmbeddingDimension(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle <= 0) {
        return 0;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return static_cast<jint>(llama_mobile_get_n_embd_c(context));
}

// Gets the model description
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_getModelDescription(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* description = llama_mobile_get_model_desc_c(context);
    if (description == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(description);
    free((void*)description);
    
    return result;
}

// Gets the model size in bytes
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_getModelSize(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return 0L;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return static_cast<jlong>(llama_mobile_get_model_size_c(context));
}

// Gets the number of model parameters
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_getModelParametersCount(JNIEnv* env, jclass clazz, jlong contextHandle) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return 0L;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    return static_cast<jlong>(llama_mobile_get_model_params_c(context));
}

// Releases the context and all associated resources
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(JNIEnv* env, jclass clazz, jlong contextHandle) {
    if (contextHandle == 0) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_free_context_c(context);
}

// Downloads a model
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadModel(JNIEnv* env, jclass clazz, jobject downloadParamsObj, jobject progressCallback) {
    if (downloadParamsObj == nullptr) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    jclass downloadParamsClass = env->GetObjectClass(downloadParamsObj);
    if (downloadParamsClass == nullptr) {
        return nullptr;
    }
    
    jfieldID repoIdField = env->GetFieldID(downloadParamsClass, "repoId", "Ljava/lang/String;");
    jfieldID filenameField = env->GetFieldID(downloadParamsClass, "filename", "Ljava/lang/String;");
    jfieldID destinationPathField = env->GetFieldID(downloadParamsClass, "destinationPath", "Ljava/lang/String;");
    jfieldID bearerTokenField = env->GetFieldID(downloadParamsClass, "bearerToken", "Ljava/lang/String;");
    jfieldID offlineField = env->GetFieldID(downloadParamsClass, "offline", "Z");
    
    if (repoIdField == nullptr || filenameField == nullptr || destinationPathField == nullptr || bearerTokenField == nullptr || offlineField == nullptr) {
        env->DeleteLocalRef(downloadParamsClass);
        return nullptr;
    }
    
    jstring repoId = static_cast<jstring>(env->GetObjectField(downloadParamsObj, repoIdField));
    jstring filename = static_cast<jstring>(env->GetObjectField(downloadParamsObj, filenameField));
    jstring destinationPath = static_cast<jstring>(env->GetObjectField(downloadParamsObj, destinationPathField));
    jstring bearerToken = static_cast<jstring>(env->GetObjectField(downloadParamsObj, bearerTokenField));
    jboolean offline = env->GetBooleanField(downloadParamsObj, offlineField);
    
    env->DeleteLocalRef(downloadParamsClass);
    
    const char* repoIdStr = getStringUTFChars(env, repoId);
    const char* filenameStr = getStringUTFChars(env, filename);
    const char* destinationPathStr = getStringUTFChars(env, destinationPath);
    const char* bearerTokenStr = getStringUTFChars(env, bearerToken);
    
    llama_mobile_download_result_c_t result = llama_mobile_download_hf_file_c(
        repoIdStr, filenameStr, destinationPathStr, bearerTokenStr, offline, 
        progressCallback != nullptr ? downloadProgressCallbackWrapper : nullptr, 
        progressCallback);
    
    releaseStringUTFChars(env, repoId, repoIdStr);
    releaseStringUTFChars(env, filename, filenameStr);
    releaseStringUTFChars(env, destinationPath, destinationPathStr);
    releaseStringUTFChars(env, bearerToken, bearerTokenStr);
    
    if (repoId != nullptr) env->DeleteLocalRef(repoId);
    if (filename != nullptr) env->DeleteLocalRef(filename);
    if (destinationPath != nullptr) env->DeleteLocalRef(destinationPath);
    if (bearerToken != nullptr) env->DeleteLocalRef(bearerToken);
    
    if (!result.success) {
        return nullptr;
    }
    
    jclass downloadResultClass = env->FindClass("com/llamamobile/LlamaMobile$DownloadResult");
    if (downloadResultClass == nullptr) {
        llama_mobile_free_download_result_c(&result);
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(downloadResultClass, "<init>", "(ZLjava/lang/String;Ljava/lang/String;)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(downloadResultClass);
        llama_mobile_free_download_result_c(&result);
        return nullptr;
    }
    
    jstring localPath = result.local_path != nullptr ? env->NewStringUTF(result.local_path) : nullptr;
    jstring errorMessage = result.error_message != nullptr ? env->NewStringUTF(result.error_message) : nullptr;
    jboolean success = result.success ? JNI_TRUE : JNI_FALSE;
    
    jobject resultObj = env->NewObject(downloadResultClass, constructor, success, localPath, errorMessage);
    
    llama_mobile_free_download_result_c(&result);
    
    if (localPath != nullptr) env->DeleteLocalRef(localPath);
    if (errorMessage != nullptr) env->DeleteLocalRef(errorMessage);
    env->DeleteLocalRef(downloadResultClass);
    
    return resultObj;
}

// Downloads a file from Hugging Face
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadHfFile(JNIEnv* env, jclass clazz, jstring repoId, jstring fileName, jstring localPath, jstring bearerToken, jboolean offline, jobject progressCallback) {
    if (repoId == nullptr || fileName == nullptr || localPath == nullptr) {
        return nullptr;
    }
    
    if (env->ExceptionCheck()) {
        return nullptr;
    }
    
    const char* repoIdStr = getStringUTFChars(env, repoId);
    const char* fileNameStr = getStringUTFChars(env, fileName);
    const char* localPathStr = getStringUTFChars(env, localPath);
    const char* bearerTokenStr = getStringUTFChars(env, bearerToken);
    
    llama_mobile_download_result_c_t result = llama_mobile_download_hf_file_c(
        repoIdStr, fileNameStr, localPathStr, bearerTokenStr, offline, 
        progressCallback != nullptr ? downloadProgressCallbackWrapper : nullptr, 
        progressCallback);
    
    releaseStringUTFChars(env, repoId, repoIdStr);
    releaseStringUTFChars(env, fileName, fileNameStr);
    releaseStringUTFChars(env, localPath, localPathStr);
    releaseStringUTFChars(env, bearerToken, bearerTokenStr);
    
    if (!result.success) {
        return nullptr;
    }
    
    jclass downloadResultClass = env->FindClass("com/llamamobile/LlamaMobile$DownloadResult");
    if (downloadResultClass == nullptr) {
        llama_mobile_free_download_result_c(&result);
        return nullptr;
    }
    
    jmethodID constructor = env->GetMethodID(downloadResultClass, "<init>", "(ZLjava/lang/String;Ljava/lang/String;)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(downloadResultClass);
        llama_mobile_free_download_result_c(&result);
        return nullptr;
    }
    
    jstring resultLocalPath = result.local_path != nullptr ? env->NewStringUTF(result.local_path) : nullptr;
    jstring errorMessage = result.error_message != nullptr ? env->NewStringUTF(result.error_message) : nullptr;
    jboolean success = result.success ? JNI_TRUE : JNI_FALSE;
    
    jobject resultObj = env->NewObject(downloadResultClass, constructor, success, resultLocalPath, errorMessage);
    
    llama_mobile_free_download_result_c(&result);
    
    if (resultLocalPath != nullptr) env->DeleteLocalRef(resultLocalPath);
    if (errorMessage != nullptr) env->DeleteLocalRef(errorMessage);
    env->DeleteLocalRef(downloadResultClass);
    
    return resultObj;
}

// JNI initialization function
JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    g_jvm = vm;
    return JNI_VERSION_1_6;
}

// JNI cleanup function
JNIEXPORT void JNI_OnUnload(JavaVM* vm, void* reserved) {
    g_jvm = nullptr;
}

#ifdef __cplusplus
}
#endif
