// JNI wrapper for llama_mobile Android library - Java version
#include <jni.h>
#include <string>
#include <cstring>
#include <vector>

// Include the llama_mobile headers
#include "llama_mobile_api.h"
#include "llama_mobile_ffi.h"

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
static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate, const char*& systemPrompt) {
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
    jfieldID nUBatchField = env->GetFieldID(paramsClass, "nUbatch", "I");
    jfieldID nGpuLayersField = env->GetFieldID(paramsClass, "nGpuLayers", "I");
    jfieldID nThreadsField = env->GetFieldID(paramsClass, "nThreads", "I");
    jfieldID useMmapField = env->GetFieldID(paramsClass, "useMmap", "Z");
    jfieldID useMlockField = env->GetFieldID(paramsClass, "useMlock", "Z");
    jfieldID embeddingField = env->GetFieldID(paramsClass, "embedding", "Z");
    jfieldID poolingTypeField = env->GetFieldID(paramsClass, "poolingType", "I");
    jfieldID embdNormalizeField = env->GetFieldID(paramsClass, "embdNormalize", "I");
    jfieldID flashAttnField = env->GetFieldID(paramsClass, "flashAttn", "Z");
    jfieldID cacheTypeKField = env->GetFieldID(paramsClass, "cacheTypeK", "Ljava/lang/String;");
    jfieldID cacheTypeVField = env->GetFieldID(paramsClass, "cacheTypeV", "Ljava/lang/String;");
    jfieldID cacheTypeField = env->GetFieldID(paramsClass, "cacheType", "Lcom/llamamobile/LlamaMobile$CacheType;");
    
    if (modelPathField == nullptr || nCtxField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
    jint nCtx = env->GetIntField(initParamsObj, nCtxField);
    jstring chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
    jstring systemPromptStr = (jstring)env->GetObjectField(initParamsObj, systemPromptField);
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
    jstring cacheTypeKStr = (cacheTypeKField != nullptr) ? (jstring)env->GetObjectField(initParamsObj, cacheTypeKField) : nullptr;
    jstring cacheTypeVStr = (cacheTypeVField != nullptr) ? (jstring)env->GetObjectField(initParamsObj, cacheTypeVField) : nullptr;
    
    // Get cache type enum value
    jint cacheType = 0; // Default to NONE
    if (cacheTypeField != nullptr) {
        jobject cacheTypeObj = env->GetObjectField(initParamsObj, cacheTypeField);
        if (cacheTypeObj != nullptr) {
            jclass cacheTypeClass = env->GetObjectClass(cacheTypeObj);
            jmethodID ordinalMethod = env->GetMethodID(cacheTypeClass, "ordinal", "()I");
            if (ordinalMethod != nullptr) {
                cacheType = env->CallIntMethod(cacheTypeObj, ordinalMethod);
            }
            env->DeleteLocalRef(cacheTypeClass);
            env->DeleteLocalRef(cacheTypeObj);
        }
    }
    
    // Convert strings
    modelPath = getStringUTFChars(env, modelPathStr);
    chatTemplate = (chatTemplateField != nullptr) ? getStringUTFChars(env, chatTemplateStr) : nullptr;
    systemPrompt = (systemPromptField != nullptr) ? getStringUTFChars(env, systemPromptStr) : nullptr;
    const char* cacheTypeK = (cacheTypeKField != nullptr && cacheTypeKStr != nullptr) ? getStringUTFChars(env, cacheTypeKStr) : nullptr;
    const char* cacheTypeV = (cacheTypeVField != nullptr && cacheTypeVStr != nullptr) ? getStringUTFChars(env, cacheTypeVStr) : nullptr;
    
    // Debug model path
    // printf("[JNI-JAVA] Model path: %s\n", modelPath ? modelPath : "null");
    
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
    params.progress_callback = nullptr;
    
    // Debug embedding parameter
    // printf("[JNI-JAVA] Embedding parameter set to: %d\n", embedding);
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(modelPathStr);
    if (chatTemplateStr != nullptr) env->DeleteLocalRef(chatTemplateStr);
    if (systemPromptStr != nullptr) env->DeleteLocalRef(systemPromptStr);
    if (cacheTypeKStr != nullptr) env->DeleteLocalRef(cacheTypeKStr);
    if (cacheTypeVStr != nullptr) env->DeleteLocalRef(cacheTypeVStr);
    
    return true;
}

// Extract CompletionParams from Java object
static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt, const char*& grammar, std::vector<std::string>& mediaPaths) {
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
    
    if (promptField == nullptr || temperatureField == nullptr || maxTokensField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
    jfloat temperature = env->GetFloatField(completionParamsObj, temperatureField);
    jint maxTokens = env->GetIntField(completionParamsObj, maxTokensField);
    jint nThreads = (nThreadsField != nullptr) ? env->GetIntField(completionParamsObj, nThreadsField) : 4;
    jint seed = (seedField != nullptr) ? env->GetIntField(completionParamsObj, seedField) : -1;
    jint topK = (topKField != nullptr) ? env->GetIntField(completionParamsObj, topKField) : 40;
    jdouble topP = (topPField != nullptr) ? env->GetDoubleField(completionParamsObj, topPField) : 0.9;
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
    jstring grammarStr = (grammarField != nullptr) ? (jstring)env->GetObjectField(completionParamsObj, grammarField) : nullptr;
    
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
                        
                        if (roleField != nullptr && contentField != nullptr) {
                            jstring roleStr = (jstring)env->GetObjectField(chatMessageObj, roleField);
                            jstring contentStr = (jstring)env->GetObjectField(chatMessageObj, contentField);
                            
                            const char* role = getStringUTFChars(env, roleStr);
                            const char* content = getStringUTFChars(env, contentStr);
                            
                            if (role != nullptr && content != nullptr) {
                                chatMessages.push_back({strdup(role), strdup(content), nullptr, nullptr, nullptr});
                            }
                            
                            releaseStringUTFChars(env, roleStr, role);
                            releaseStringUTFChars(env, contentStr, content);
                            env->DeleteLocalRef(roleStr);
                            env->DeleteLocalRef(contentStr);
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
    
    // Extract chatTemplate (not used in C API yet)
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    if (chatTemplateField != nullptr) {
        jstring chatTemplateStr = (jstring)env->GetObjectField(completionParamsObj, chatTemplateField);
        if (chatTemplateStr != nullptr) {
            const char* chatTemplate = getStringUTFChars(env, chatTemplateStr);
            // Note: chatTemplate is not currently passed to C API as it doesn't support it
            // The template is handled in the Java layer
            releaseStringUTFChars(env, chatTemplateStr, chatTemplate);
            env->DeleteLocalRef(chatTemplateStr);
        }
    }
    
    // Convert strings
    prompt = getStringUTFChars(env, promptStr);
    grammar = (grammarField != nullptr && grammarStr != nullptr) ? getStringUTFChars(env, grammarStr) : nullptr;
    
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
        }
        
        // Assign to the const pointer
        params.chat_messages = temp_messages;
        params.chat_message_count = static_cast<int32_t>(chatMessages.size());
    }
    
    // Set JSON response flag
    params.use_json_response = useJsonResponse;
    
    // Set stop sequences
    if (!stopSequences.empty()) {
        params.stop_sequences = new const char*[stopSequences.size() + 1];
        for (size_t i = 0; i < stopSequences.size(); i++) {
            params.stop_sequences[i] = strdup(stopSequences[i].c_str());
        }
        params.stop_sequences[stopSequences.size()] = nullptr;
    }
    

    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(promptStr);
    if (grammarStr != nullptr) env->DeleteLocalRef(grammarStr);
    
    return true;
}

// Create CompletionResult Java object from C struct
static jobject createCompletionResult(JNIEnv* env, const llama_mobile_completion_result_c_t& result) {
    // Find the CompletionResult class
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$CompletionResult");
    if (resultClass == nullptr) {
        return nullptr;
    }
    
    // Get the constructor
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(Ljava/lang/String;IIZZZZLjava/lang/String;)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    // Create the Java object
    jstring text = result.text ? env->NewStringUTF(result.text) : env->NewStringUTF("");
    jstring stoppingWord = result.stopping_word ? env->NewStringUTF(result.stopping_word) : nullptr;
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
    env->DeleteLocalRef(resultClass);
    
    return completionResult;
}

// Create ConversationResult Java object
static jobject createConversationResult(JNIEnv* env, const char* text, long timeToFirstToken, long totalTime, int tokensGenerated) {
    // Find the ConversationResult class
    jclass resultClass = env->FindClass("com/llamamobile/LlamaMobile$ConversationResult");
    if (resultClass == nullptr) {
        return nullptr;
    }
    
    // Get the constructor
    jmethodID constructor = env->GetMethodID(resultClass, "<init>", "(Ljava/lang/String;JJI)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(resultClass);
        return nullptr;
    }
    
    // Create the Java object
    jstring textStr = env->NewStringUTF(text);
    jobject conversationResult = env->NewObject(resultClass, constructor,
        textStr,
        (jlong)timeToFirstToken,
        (jlong)totalTime,
        (jint)tokensGenerated);
    
    env->DeleteLocalRef(textStr);
    env->DeleteLocalRef(resultClass);
    
    return conversationResult;
}

// JNI method implementations

// Initializes a new context for the model
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(JNIEnv* env, jclass clazz, jobject initParamsObj) {
    llama_mobile_init_params_c_t params;
    const char* modelPath = nullptr;
    const char* chatTemplate = nullptr;
    const char* systemPrompt = nullptr;
    
    // Debug logging
    printf("[JNI-JAVA] Java_com_llamamobile_LlamaMobile_initContext called\n");
    
    if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate, systemPrompt)) {
        printf("[JNI-JAVA] extractInitParams failed\n");
        return 0;
    }
    
    // Debug FFI call
    printf("[JNI-JAVA] Calling llama_mobile_init_context_c with model_path: %s\n", params.model_path);
    
    llama_mobile_context_handle_t context = llama_mobile_init_context_c(&params);
    
    printf("[JNI-JAVA] llama_mobile_init_context_c returned: %p\n", context);
    
    // Release the strings
    jclass paramsClass = env->GetObjectClass(initParamsObj);
    releaseStringUTFChars(env, (jstring)env->GetObjectField(initParamsObj, env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;")), modelPath);
    
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    if (chatTemplateField != nullptr && chatTemplate != nullptr) {
        releaseStringUTFChars(env, (jstring)env->GetObjectField(initParamsObj, chatTemplateField), chatTemplate);
    }
    
    jfieldID systemPromptField = env->GetFieldID(paramsClass, "systemPrompt", "Ljava/lang/String;");
    if (systemPromptField != nullptr && systemPrompt != nullptr) {
        releaseStringUTFChars(env, (jstring)env->GetObjectField(initParamsObj, systemPromptField), systemPrompt);
    }
    
    jfieldID cacheTypeKField = env->GetFieldID(paramsClass, "cacheTypeK", "Ljava/lang/String;");
    if (cacheTypeKField != nullptr) {
        jstring cacheTypeKStr = (jstring)env->GetObjectField(initParamsObj, cacheTypeKField);
        if (cacheTypeKStr != nullptr) {
            const char* cacheTypeK = getStringUTFChars(env, cacheTypeKStr);
            if (cacheTypeK != nullptr) {
                releaseStringUTFChars(env, cacheTypeKStr, cacheTypeK);
            }
            env->DeleteLocalRef(cacheTypeKStr);
        }
    }
    
    jfieldID cacheTypeVField = env->GetFieldID(paramsClass, "cacheTypeV", "Ljava/lang/String;");
    if (cacheTypeVField != nullptr) {
        jstring cacheTypeVStr = (jstring)env->GetObjectField(initParamsObj, cacheTypeVField);
        if (cacheTypeVStr != nullptr) {
            const char* cacheTypeV = getStringUTFChars(env, cacheTypeVStr);
            if (cacheTypeV != nullptr) {
                releaseStringUTFChars(env, cacheTypeVStr, cacheTypeV);
            }
            env->DeleteLocalRef(cacheTypeVStr);
        }
    }
    
    env->DeleteLocalRef(paramsClass);
    
    return reinterpret_cast<jlong>(context);
}

// Generates completion text based on the given prompt and parameters
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_nativeGenerateCompletion(JNIEnv* env, jclass cls, jlong contextHandle, jobject completionParamsObj) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    llama_mobile_completion_params_c_t params;
    const char* prompt = nullptr;
    const char* grammar = nullptr;
    std::vector<std::string> mediaPaths;
    
    if (!extractCompletionParams(env, completionParamsObj, params, prompt, grammar, mediaPaths)) {
        return nullptr;
    }
    
    llama_mobile_completion_result_c_t result = {
        .text = nullptr,
        .tokens_predicted = 0,
        .tokens_evaluated = 0,
        .truncated = false,
        .stopped_eos = false,
        .stopped_word = false,
        .stopped_limit = false,
        .stopping_word = nullptr
    };
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
    
    // Release strings
    jclass paramsClass = env->GetObjectClass(completionParamsObj);
    releaseStringUTFChars(env, (jstring)env->GetObjectField(completionParamsObj, env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;")), prompt);
    
    jfieldID grammarField = env->GetFieldID(paramsClass, "grammar", "Ljava/lang/String;");
    if (grammarField != nullptr && grammar != nullptr) {
        releaseStringUTFChars(env, (jstring)env->GetObjectField(completionParamsObj, grammarField), grammar);
    }
    
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
        }
        delete[] params.chat_messages;
    }
    

    
    env->DeleteLocalRef(paramsClass);
    
    if (ret != 0) {
        return nullptr;
    }
    
    jobject completionResult = createCompletionResult(env, result);
    llama_mobile_free_completion_result_members_c(&result);
    
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
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cText = getStringUTFChars(env, text);
    if (cText == nullptr) {
        return nullptr;
    }
    
    // We'll need to use the FFI tokenize function
    llama_mobile_token_array_c_t tokens = llama_mobile_tokenize_c(context, cText);
    
    releaseStringUTFChars(env, text, cText);
    
    // Convert to jintArray
    jintArray result = env->NewIntArray(tokens.count);
    if (result != nullptr) {
        env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    }
    
    // Free the tokens
    llama_mobile_free_token_array_c(tokens);
    
    return result;
}

// Detokenizes token IDs back to a text string
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_detokenize(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    // Get the token array
    jsize length = env->GetArrayLength(tokens);
    jint* tokenArray = env->GetIntArrayElements(tokens, nullptr);
    if (tokenArray == nullptr) {
        return nullptr;
    }
    
    // Convert to C token array
    std::vector<int32_t> cTokens(length);
    for (jsize i = 0; i < length; ++i) {
        cTokens[i] = static_cast<int32_t>(tokenArray[i]);
    }
    
    // Use FFI detokenize function
    char* text = llama_mobile_detokenize_c(context, cTokens.data(), cTokens.size());
    
    env->ReleaseIntArrayElements(tokens, tokenArray, JNI_ABORT);
    
    if (text == nullptr) {
        return nullptr;
    }
    
    jstring result = env->NewStringUTF(text);
    free(text);
    
    return result;
}

// Generates embeddings for the given text
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_generateEmbeddings(JNIEnv* env, jclass clazz, jlong contextHandle, jstring text) {
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cText = getStringUTFChars(env, text);
    if (cText == nullptr) {
        return nullptr;
    }
    
    // Use FFI embeddings function
    llama_mobile_float_array_c_t embeddings = llama_mobile_embedding_c(context, cText);
    
    releaseStringUTFChars(env, text, cText);
    
    if (embeddings.values == nullptr) {
        return nullptr;
    }
    
    // Convert to jfloatArray
    jfloatArray result = env->NewFloatArray(embeddings.count);
    if (result != nullptr) {
        env->SetFloatArrayRegion(result, 0, embeddings.count, embeddings.values);
    }
    
    // Free the embeddings
    free(embeddings.values);
    
    return result;
}

// Initializes multimodal support
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_initMultimodal(JNIEnv* env, jclass clazz, jlong contextHandle, jstring mmprojPath, jboolean useGpu) {
    // Check if context is invalid
    if (contextHandle == 0) {
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
    // Check if context or messages are invalid
    if (contextHandle == 0 || messagesJson == nullptr) {
        return nullptr;
    }
    
    const char* messages_c = env->GetStringUTFChars(messagesJson, nullptr);
    const char* template_c = chatTemplate != nullptr ? env->GetStringUTFChars(chatTemplate, nullptr) : nullptr;
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    char* formatted_prompt = llama_mobile_get_formatted_chat_c(context, messages_c, template_c);
    
    env->ReleaseStringUTFChars(messagesJson, messages_c);
    if (chatTemplate != nullptr) {
        env->ReleaseStringUTFChars(chatTemplate, template_c);
    }
    
    if (formatted_prompt != nullptr) {
        jstring result = env->NewStringUTF(formatted_prompt);
        llama_mobile_free_string_c(formatted_prompt);
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
    // Check if context is invalid
    if (contextHandle == 0) {
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
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    // Get the TTSModelType enum class
    jclass ttsModelTypeClass = env->FindClass("com/llamamobile/LlamaMobile$TTSModelType");
    if (ttsModelTypeClass == nullptr) {
        return nullptr;
    }
    
    // Get the enum values field
    jfieldID valuesField = env->GetStaticFieldID(ttsModelTypeClass, "$VALUES", "[Lcom/llamamobile/LlamaMobile$TTSModelType;");
    if (valuesField == nullptr) {
        env->DeleteLocalRef(ttsModelTypeClass);
        return nullptr;
    }
    
    // Get the enum array
    jobjectArray enumValues = (jobjectArray)env->GetStaticObjectField(ttsModelTypeClass, valuesField);
    if (enumValues == nullptr) {
        env->DeleteLocalRef(ttsModelTypeClass);
        return nullptr;
    }
    
    // Get the index based on context
    int index;
    if (contextHandle == 0) {
        // For invalid context, return UNKNOWN which is index 0
        index = 0;
    } else {
        llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
        int ttsType = static_cast<int>(llama_mobile_get_tts_type_c(context));
        // Map TTS type to enum index
        switch (ttsType) {
            case 1: index = 1; break;  // OUT_ETTS_V02
            case 2: index = 2; break;  // OUT_ETTS_V03
            default: index = 0; break; // UNKNOWN
        }
    }
    
    // Get the enum object at the calculated index
    jobject enumValue = env->GetObjectArrayElement(enumValues, index);
    if (enumValue != nullptr) {
        // Create a local reference to return
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
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cTextToSpeak = getStringUTFChars(env, textToSpeak);
    if (cTextToSpeak == nullptr) {
        return nullptr;
    }
    
    // Use FFI function that returns tokens directly
    llama_mobile_token_array_c_t tokens = llama_mobile_get_audio_guide_tokens_c(context, cTextToSpeak);
    
    releaseStringUTFChars(env, textToSpeak, cTextToSpeak);
    
    if (tokens.tokens == nullptr) {
        return nullptr;
    }
    
    // Convert to jintArray
    jintArray result = env->NewIntArray(tokens.count);
    if (result != nullptr) {
        env->SetIntArrayRegion(result, 0, tokens.count, reinterpret_cast<jint*>(tokens.tokens));
    }
    
    // Free the tokens
    llama_mobile_free_token_array_c(tokens);
    
    return result;
}

// Decodes audio tokens
JNIEXPORT jfloatArray JNICALL Java_com_llamamobile_LlamaMobile_decodeAudioTokens(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    // Get the token array
    jsize length = env->GetArrayLength(tokens);
    jint* tokenArray = env->GetIntArrayElements(tokens, nullptr);
    if (tokenArray == nullptr) {
        return nullptr;
    }
    
    // Convert to C token array
    std::vector<int32_t> cTokens(length);
    for (jsize i = 0; i < length; ++i) {
        cTokens[i] = static_cast<int32_t>(tokenArray[i]);
    }
    
    // Use FFI decode audio tokens function
    llama_mobile_float_array_c_t audioData = llama_mobile_decode_audio_tokens_c(context, cTokens.data(), cTokens.size());
    
    env->ReleaseIntArrayElements(tokens, tokenArray, JNI_ABORT);
    
    if (audioData.values == nullptr) {
        return nullptr;
    }
    
    // Convert to jfloatArray
    jfloatArray result = env->NewFloatArray(audioData.count);
    if (result != nullptr) {
        env->SetFloatArrayRegion(result, 0, audioData.count, audioData.values);
    }
    
    // Free the audio data
    llama_mobile_free_float_array_c(audioData);
    
    return result;
}

// Sets guide tokens for audio generation
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_setGuideTokens(JNIEnv* env, jclass clazz, jlong contextHandle, jintArray tokens) {
    // Check if context is invalid
    if (contextHandle == 0 || tokens == nullptr) {
        return;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    // Get the tokens array
    jsize tokenCount = env->GetArrayLength(tokens);
    jint* tokenValues = env->GetIntArrayElements(tokens, nullptr);
    
    if (tokenValues == nullptr) {
        return;
    }
    
    // Create a vector of tokens
    std::vector<int32_t> tokenVector;
    tokenVector.reserve(tokenCount);
    
    for (jsize i = 0; i < tokenCount; i++) {
        tokenVector.push_back(static_cast<int32_t>(tokenValues[i]));
    }
    
    // Call the FFI set guide tokens function
    llama_mobile_set_guide_tokens_c(context, tokenVector.data(), tokenVector.size());
    
    // Release the tokens array
    env->ReleaseIntArrayElements(tokens, tokenValues, JNI_ABORT);
}

// Saves audio samples to WAV file
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_saveAudioToWav(JNIEnv* env, jclass clazz, jlong contextHandle, jstring filePath, jfloatArray audioData, jint sampleRate) {
    // Check if context is invalid
    if (contextHandle == 0 || filePath == nullptr || audioData == nullptr) {
        return JNI_FALSE;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    // Get the file path
    const char* cFilePath = getStringUTFChars(env, filePath);
    if (cFilePath == nullptr) {
        return JNI_FALSE;
    }
    
    // Get the audio data
    jsize dataCount = env->GetArrayLength(audioData);
    jfloat* dataValues = env->GetFloatArrayElements(audioData, nullptr);
    
    if (dataValues == nullptr) {
        releaseStringUTFChars(env, filePath, cFilePath);
        return JNI_FALSE;
    }
    
    // Create a vector of audio data
    std::vector<float> audioVector;
    audioVector.reserve(dataCount);
    
    for (jsize i = 0; i < dataCount; i++) {
        audioVector.push_back(static_cast<float>(dataValues[i]));
    }
    
    // Call the FFI save audio to WAV function
    bool result = llama_mobile_save_audio_to_wav_c(context, cFilePath, audioVector.data(), audioVector.size(), sampleRate);
    
    // Release resources
    env->ReleaseFloatArrayElements(audioData, dataValues, JNI_ABORT);
    releaseStringUTFChars(env, filePath, cFilePath);
    
    return result ? JNI_TRUE : JNI_FALSE;
}

// Releases vocoder resources
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseVocoder(JNIEnv* env, jclass clazz, jlong contextHandle) {
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_release_vocoder_c(context);
}

// Applies LoRA adapters
JNIEXPORT jboolean JNICALL Java_com_llamamobile_LlamaMobile_applyLoraAdapters(JNIEnv* env, jclass clazz, jlong contextHandle, jobjectArray adaptersArray) {
    if (contextHandle == 0 || adaptersArray == nullptr) {
        return JNI_FALSE;
    }

    // Get the context
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    if (!context) {
        return JNI_FALSE;
    }

    // Get the number of adapters
    jsize adapterCount = env->GetArrayLength(adaptersArray);
    if (adapterCount == 0) {
        return JNI_FALSE;
    }

    // Extract adapter information
    llama_mobile_lora_adapter_t* adapters = new llama_mobile_lora_adapter_t[adapterCount];
    if (!adapters) {
        return JNI_FALSE;
    }

    // Get LoraAdapter class
    jclass loraAdapterClass = env->FindClass("com/llamamobile/LlamaMobile$LoraAdapter");
    if (!loraAdapterClass) {
        delete[] adapters;
        return JNI_FALSE;
    }

    // Get field IDs
    jfieldID pathField = env->GetFieldID(loraAdapterClass, "path", "Ljava/lang/String;");
    jfieldID scaleField = env->GetFieldID(loraAdapterClass, "scale", "F");
    if (!pathField || !scaleField) {
        env->DeleteLocalRef(loraAdapterClass);
        delete[] adapters;
        return JNI_FALSE;
    }

    // Extract each adapter
    std::vector<jstring> pathStrings;
    for (int i = 0; i < adapterCount; i++) {
        // Get the LoraAdapter object
        jobject adapterObj = env->GetObjectArrayElement(adaptersArray, i);
        if (!adapterObj) {
            continue;
        }

        // Get path
        jstring pathStr = static_cast<jstring>(env->GetObjectField(adapterObj, pathField));
        if (pathStr) {
            pathStrings.push_back(pathStr);
            const char* path = env->GetStringUTFChars(pathStr, nullptr);
            if (path) {
                adapters[i].path = path;
            }
        }

        // Get scale
        adapters[i].scale = env->GetFloatField(adapterObj, scaleField);

        env->DeleteLocalRef(adapterObj);
    }

    // Call the FFI function
    int result = llama_mobile_apply_lora_adapters(context, adapters, adapterCount);

    // Clean up
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
    // This would require complex code to create LoRA adapter objects
    // For now, return null as not implemented
    return nullptr;
}

// Generates a response in conversation mode
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_generateResponse(JNIEnv* env, jclass clazz, jlong contextHandle, jstring userMessage, jint maxTokens) {
    // Check if context is invalid
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    
    const char* cUserMessage = getStringUTFChars(env, userMessage);
    if (cUserMessage == nullptr) {
        return nullptr;
    }
    
    // Use FFI generate response function
    char* responseText = llama_mobile_generate_response_c(context, cUserMessage, maxTokens);
    
    releaseStringUTFChars(env, userMessage, cUserMessage);
    
    if (responseText == nullptr) {
        return nullptr;
    }
    
    // Create ConversationResult object - using dummy time and token values since function now only returns text
    jobject responseResult = createConversationResult(env, responseText, 0, 0, 0);
    free(responseText);
    
    return responseResult;
}

// Clears the current conversation context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_clearConversation(JNIEnv* env, jclass clazz, jlong contextHandle) {
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
    llama_mobile_context_handle_t context = reinterpret_cast<llama_mobile_context_handle_t>(contextHandle);
    llama_mobile_free_context_c(context);
}

// Gets grammar content from assets
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_grammarContent(JNIEnv* env, jclass clazz, jobject context, jint grammarName) {
    // Map GrammarName enum values to file names
    const char* grammar_files[] = {
        "arithmetic.gbnf",  // ARITHMETIC = 0
        "c.gbnf",           // C = 1
        "chess.gbnf",       // CHESS = 2
        "english.gbnf",     // ENGLISH = 3
        "japanese.gbnf",    // JAPANESE = 4
        "json.gbnf",        // JSON = 5
        "json_arr.gbnf",    // JSON_ARR = 6
        "list.gbnf"         // LIST = 7
    };

    // Check if grammarName is within valid range
    if (grammarName < 0 || grammarName >= sizeof(grammar_files) / sizeof(grammar_files[0])) {
        return nullptr;
    }

    // Get AssetManager from context
    jclass contextClass = env->GetObjectClass(context);
    jmethodID getAssetsMethod = env->GetMethodID(contextClass, "getAssets", "()Landroid/content/res/AssetManager;");
    jobject assetManagerObj = env->CallObjectMethod(context, getAssetsMethod);

    if (assetManagerObj == nullptr) {
        return nullptr;
    }

    // Get AssetManager class and open method
    jclass assetManagerClass = env->GetObjectClass(assetManagerObj);
    jmethodID openMethod = env->GetMethodID(assetManagerClass, "open", "(Ljava/lang/String;)Ljava/io/InputStream;");

    // Construct grammar file path
    const char* grammarFile = grammar_files[grammarName];
    jstring grammarFilePath = env->NewStringUTF(grammarFile);
    jobject inputStreamObj = env->CallObjectMethod(assetManagerObj, openMethod, grammarFilePath);

    if (inputStreamObj == nullptr) {
        env->DeleteLocalRef(grammarFilePath);
        env->DeleteLocalRef(assetManagerObj);
        env->DeleteLocalRef(assetManagerClass);
        env->DeleteLocalRef(contextClass);
        return nullptr;
    }

    // Read the input stream
    jclass inputStreamClass = env->GetObjectClass(inputStreamObj);
    jmethodID availableMethod = env->GetMethodID(inputStreamClass, "available", "()I");
    jmethodID readMethod = env->GetMethodID(inputStreamClass, "read", "([B)I");
    jmethodID closeMethod = env->GetMethodID(inputStreamClass, "close", "()V");

    // Get available bytes
    jint available = env->CallIntMethod(inputStreamObj, availableMethod);
    if (available <= 0) {
        env->CallVoidMethod(inputStreamObj, closeMethod);
        env->DeleteLocalRef(grammarFilePath);
        env->DeleteLocalRef(assetManagerObj);
        env->DeleteLocalRef(assetManagerClass);
        env->DeleteLocalRef(inputStreamObj);
        env->DeleteLocalRef(inputStreamClass);
        env->DeleteLocalRef(contextClass);
        return nullptr;
    }

    // Create byte array and read data
    jbyteArray buffer = env->NewByteArray(available);
    env->CallIntMethod(inputStreamObj, readMethod, buffer);

    // Close the input stream
    env->CallVoidMethod(inputStreamObj, closeMethod);

    // Convert byte array to string
    jstring grammarContent = env->NewStringUTF((const char*)env->GetByteArrayElements(buffer, nullptr));

    // Clean up
    env->ReleaseByteArrayElements(buffer, env->GetByteArrayElements(buffer, nullptr), JNI_ABORT);
    env->DeleteLocalRef(buffer);
    env->DeleteLocalRef(grammarFilePath);
    env->DeleteLocalRef(assetManagerObj);
    env->DeleteLocalRef(assetManagerClass);
    env->DeleteLocalRef(inputStreamObj);
    env->DeleteLocalRef(inputStreamClass);
    env->DeleteLocalRef(contextClass);

    return grammarContent;
}

// Downloads a model
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadModel(JNIEnv* env, jclass clazz, jobject downloadParamsObj, jobject progressCallback) {
    // This would require complex code to handle downloading and progress callbacks
    // For now, return null as not implemented
    return nullptr;
}

// Downloads a file from Hugging Face
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_downloadHfFile(JNIEnv* env, jclass clazz, jstring repoId, jstring fileName, jstring localPath, jobject progressCallback, jstring token) {
    // This would require complex code to handle downloading and progress callbacks
    // For now, return null as not implemented
    return nullptr;
}

#ifdef __cplusplus
}
#endif
