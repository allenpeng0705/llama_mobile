// llama_mobile_jni.cpp — v2 JNI bridge for the Android SDK (M5)
//
// Implements the native functions declared in LlamaEngine.kt (object `Native`,
// class com.llamamobile.Native). Every call speaks only the v2 C API
// (llama_mobile_v2.h); the v1 API was fully removed on the v2 branch.
//
// Threading: a generation is single-flight per context (enforced by the v2
// core). `abort()` may be called from any thread while a generation runs: the
// JNI layer learns the request id as soon as the core writes it at generation
// start (we pass a pointer to a shared slot), then calls llama_mobile_abort.
//
// Error reporting: failures set a thread-local last status code which the
// wrapper reads right after the failing call on the same thread.

#include <jni.h>
#include <string>
#include <vector>
#include <cstring>
#include <atomic>
#include <thread>
#include <chrono>

#include "llama_mobile_v2.h"

namespace {

// One engine = one native context.
struct EngineWrap {
    llama_mobile_context_t ctx = nullptr;
    volatile uint64_t rid_slot = 0;     // core writes the request id here at entry
    std::atomic<bool> running{false};
};

thread_local int t_last_error = 0;

inline void setError(llama_mobile_status_t s) { t_last_error = (int) s; }

EngineWrap * wrap(jlong h) {
    return reinterpret_cast<EngineWrap *>(h);
}

// ---------- small JNI helpers ------------------------------------------------

std::string toCpp(JNIEnv * env, jstring s) {
    if (!s) return std::string();
    const char * utf = env->GetStringUTFChars(s, nullptr);
    if (!utf) return std::string();
    std::string out(utf);
    env->ReleaseStringUTFChars(s, utf);
    return out;
}

jstring toJava(JNIEnv * env, const char * s) {
    if (!s) return nullptr;
    return env->NewStringUTF(s);
}

std::vector<std::string> arrayToCpp(JNIEnv * env, jobjectArray arr) {
    std::vector<std::string> out;
    if (!arr) return out;
    jsize n = env->GetArrayLength(arr);
    out.reserve((size_t) n);
    for (jsize i = 0; i < n; ++i) {
        auto s = (jstring) env->GetObjectArrayElement(arr, i);
        out.push_back(toCpp(env, s));
        env->DeleteLocalRef(s);
    }
    return out;
}

jobjectArray stringsToJava(JNIEnv * env, const std::vector<std::string> & v) {
    jclass strCls = env->FindClass("java/lang/String");
    jobjectArray arr = env->NewObjectArray((jsize) v.size(), strCls, nullptr);
    for (size_t i = 0; i < v.size(); ++i) {
        env->SetObjectArrayElement(arr, (jsize) i, env->NewStringUTF(v[i].c_str()));
    }
    return arr;
}

// Forward the token callback object method: `onToken(String): Boolean`.
class TokenCb {
public:
    TokenCb(JNIEnv * env, jobject cb) {
        if (!cb) return;
        m_env = env;
        m_cb = env->NewGlobalRef(cb);
        jclass cls = env->GetObjectClass(cb);
        m_mid = env->GetMethodID(cls, "onToken", "(Ljava/lang/String;)Z");
        if (!m_mid) { env->ExceptionClear(); }
    }
    ~TokenCb() { if (m_cb) m_env->DeleteGlobalRef(m_cb); }
    bool ok() const { return m_cb != nullptr && m_mid != nullptr; }
    bool call(const char * token) {
        if (!ok()) return true;
        jstring t = m_env->NewStringUTF(token);
        jboolean cont = m_env->CallBooleanMethod(m_cb, m_mid, t);
        m_env->DeleteLocalRef(t);
        if (m_env->ExceptionCheck()) {
            m_env->ExceptionClear();
            return false;
        }
        return cont != JNI_FALSE;
    }
private:
    JNIEnv * m_env = nullptr;
    jobject m_cb = nullptr;
    jmethodID m_mid = nullptr;
};

bool tokenBridge(const char * token, void * ud) {
    if (!ud) return true;
    return static_cast<TokenCb *>(ud)->call(token);
}

} // namespace

// ============================================================================
// JNI exports (com.llamamobile.Native — declared in LlamaEngine.kt)
// ============================================================================

extern "C" JNIEXPORT jstring JNICALL
Java_com_llamamobile_Native_version(JNIEnv * env, jobject) {
    const llama_mobile_version_info_t * v = llama_mobile_version();
    if (!v || !v->string) return env->NewStringUTF("");
    return env->NewStringUTF(v->string);
}

extern "C" JNIEXPORT jint JNICALL
Java_com_llamamobile_Native_lastError(JNIEnv *, jobject) {
    return (jint) t_last_error;
}

extern "C" JNIEXPORT jlong JNICALL
Java_com_llamamobile_Native_create(
    JNIEnv * env, jobject,
    jstring modelPath, jstring chatTemplate, jstring systemPrompt,
    jint nCtx, jint nBatch, jint nUBatch, jint nThreads, jint nGpuLayers,
    jboolean useMmap, jboolean useMlock, jboolean embedding,
    jboolean flashAttention, jboolean chat,
    jstring cacheTypeK, jstring cacheTypeV, jint imageMinTokens) {

    std::string path = toCpp(env, modelPath);
    if (path.empty()) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return 0; }

    llama_mobile_context_config_t cfg;
    llama_mobile_context_config_init(&cfg);
    std::string tmpl = toCpp(env, chatTemplate);
    std::string sys = toCpp(env, systemPrompt);
    std::string k = toCpp(env, cacheTypeK);
    std::string v = toCpp(env, cacheTypeV);
    // All referenced C strings must stay alive through context_create.
    cfg.model_path = path.c_str();
    if (!tmpl.empty()) cfg.chat_template = tmpl.c_str();
    if (!sys.empty()) cfg.system_prompt = sys.c_str();
    cfg.n_ctx = nCtx;
    cfg.n_batch = nBatch;
    cfg.n_ubatch = nUBatch;
    cfg.n_threads = nThreads;
    cfg.n_gpu_layers = nGpuLayers;
    uint32_t flags = 0;
    if (useMmap) flags |= LLAMA_MOBILE_CTX_MMAP;
    if (useMlock) flags |= LLAMA_MOBILE_CTX_MLOCK;
    if (embedding) flags |= LLAMA_MOBILE_CTX_EMBEDDING;
    if (flashAttention) flags |= LLAMA_MOBILE_CTX_FLASH_ATTN;
    if (chat) flags |= LLAMA_MOBILE_CTX_CHAT;
    cfg.flags = flags;
    if (!k.empty()) cfg.kv_cache_type_k = k.c_str();
    if (!v.empty()) cfg.kv_cache_type_v = v.c_str();
    cfg.image_min_tokens = imageMinTokens;

    llama_mobile_context_t out = nullptr;
    llama_mobile_status_t st = llama_mobile_context_create(&cfg, &out);
    if (st != LLAMA_MOBILE_OK || !out) {
        setError(st);
        return 0;
    }

    EngineWrap * w = new (std::nothrow) EngineWrap();
    if (!w) {
        llama_mobile_context_destroy(&out);
        setError(LLAMA_MOBILE_ERR_OOM);
        return 0;
    }
    w->ctx = out;
    return (jlong) w;
}

extern "C" JNIEXPORT void JNICALL
Java_com_llamamobile_Native_destroy(JNIEnv *, jobject, jlong h) {
    EngineWrap * w = wrap(h);
    if (!w) return;
    if (w->ctx) llama_mobile_context_destroy(&w->ctx);
    delete w;
}

extern "C" JNIEXPORT jlongArray JNICALL
Java_com_llamamobile_Native_modelInfo(JNIEnv * env, jobject, jlong h) {
    EngineWrap * w = wrap(h);
    if (!w || !w->ctx) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }
    llama_mobile_model_info_t info;
    memset(&info, 0, sizeof(info));
    llama_mobile_status_t st = llama_mobile_model_info(w->ctx, &info);
    if (st != LLAMA_MOBILE_OK) { setError(st); return nullptr; }
    jlongArray arr = env->NewLongArray(4);
    jlong vals[4] = { info.n_ctx, info.n_embd, info.model_size_bytes, info.n_params };
    env->SetLongArrayRegion(arr, 0, 4, vals);
    llama_mobile_model_info_free(&info);
    return arr;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_llamamobile_Native_modelDesc(JNIEnv * env, jobject, jlong h) {
    EngineWrap * w = wrap(h);
    if (!w || !w->ctx) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }
    llama_mobile_model_info_t info;
    memset(&info, 0, sizeof(info));
    llama_mobile_status_t st = llama_mobile_model_info(w->ctx, &info);
    if (st != LLAMA_MOBILE_OK) { setError(st); return nullptr; }
    jstring out = info.description ? env->NewStringUTF(info.description) : nullptr;
    llama_mobile_model_info_free(&info);
    return out;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_llamamobile_Native_initMultimodal(JNIEnv * env, jobject, jlong h,
                                           jstring mmprojPath) {
    EngineWrap * w = wrap(h);
    if (!w || !w->ctx) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return JNI_FALSE; }
    std::string path = toCpp(env, mmprojPath);
    if (path.empty()) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return JNI_FALSE; }
    llama_mobile_status_t st = llama_mobile_multimodal_init(w->ctx, path.c_str());
    return st == LLAMA_MOBILE_OK ? JNI_TRUE : JNI_FALSE;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_llamamobile_Native_generate(
    JNIEnv * env, jobject, jlong h,
    jstring prompt, jobjectArray roles, jobjectArray contents,
    jlong seed, jfloat temperature, jint topK, jfloat topP, jfloat minP,
    jfloat typicalP, jfloat penaltyRepeat, jint penaltyLastN,
    jfloat penaltyFreq, jfloat penaltyPresent,
    jint mirostat, jfloat mirostatTau, jfloat mirostatEta, jboolean ignoreEos,
    jint maxTokens, jobjectArray stopSequences, jstring grammar,
    jstring jsonSchema, jobjectArray mediaPaths, jobject tokenCb,
    jlongArray metaOut) {

    EngineWrap * w = wrap(h);
    if (!w || !w->ctx) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }
    if (w->running.load()) { setError(LLAMA_MOBILE_ERR_ALREADY_RUNNING); return nullptr; }

    std::string promptStr = toCpp(env, prompt);
    auto roleVec = arrayToCpp(env, roles);
    auto contentVec = arrayToCpp(env, contents);
    auto stopVec = arrayToCpp(env, stopSequences);
    std::string grammarStr = toCpp(env, grammar);
    std::string schemaStr = toCpp(env, jsonSchema);
    auto mediaVec = arrayToCpp(env, mediaPaths);

    bool hasMessages = !roleVec.empty() && roleVec.size() == contentVec.size();
    if (!hasMessages && promptStr.empty()) {
        setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT);
        return nullptr;
    }

    llama_mobile_generate_params_t p;
    llama_mobile_generate_params_init(&p);

    // Message mode: the vectors own the strings; the v2 call only borrows them,
    // and it is made while they are still alive (single call, same scope).
    std::vector<llama_mobile_message_t> msgs;
    if (hasMessages) {
        msgs.reserve(roleVec.size());
        for (size_t i = 0; i < roleVec.size(); ++i) {
            llama_mobile_message_t m;
            memset(&m, 0, sizeof(m));
            m.role = roleVec[i].c_str();
            m.content = contentVec[i].c_str();
            msgs.push_back(m);
        }
        p.messages = msgs.data();
        p.n_messages = msgs.size();
    } else {
        p.prompt = promptStr.c_str();
    }
    p.sampling.seed = (int32_t) seed;
    p.sampling.temperature = temperature;
    p.sampling.top_k = topK;
    p.sampling.top_p = topP;
    p.sampling.min_p = minP;
    p.sampling.typical_p = typicalP;
    p.sampling.penalty_repeat = penaltyRepeat;
    p.sampling.penalty_last_n = penaltyLastN;
    p.sampling.penalty_freq = penaltyFreq;
    p.sampling.penalty_present = penaltyPresent;
    p.sampling.mirostat = mirostat;
    p.sampling.mirostat_tau = mirostatTau;
    p.sampling.mirostat_eta = mirostatEta;
    p.sampling.ignore_eos = ignoreEos != JNI_FALSE;
    p.max_tokens = maxTokens;

    std::vector<const char *> stops;
    for (auto & s : stopVec) stops.push_back(s.c_str());
    if (!stops.empty()) {
        p.stop_sequences = stops.data();
        p.n_stop_sequences = stops.size();
    }
    if (!grammarStr.empty()) p.grammar = grammarStr.c_str();
    if (!schemaStr.empty()) p.json_schema = schemaStr.c_str();

    // Media: PATH-only entries.
    std::vector<llama_mobile_media_t> mediaMsgs;
    if (!mediaVec.empty()) {
        mediaMsgs.reserve(mediaVec.size());
        for (auto & mp : mediaVec) {
            llama_mobile_media_t m;
            memset(&m, 0, sizeof(m));
            m.kind = LLAMA_MOBILE_MEDIA_PATH;
            m.path = mp.c_str();
            mediaMsgs.push_back(m);
        }
        p.media = mediaMsgs.data();
        p.n_media = mediaMsgs.size();
    }

    TokenCb cb(env, tokenCb);
    llama_mobile_token_cb cCb = cb.ok() ? tokenBridge : nullptr;

    w->rid_slot = 0;
    w->running.store(true);
    llama_mobile_generate_result_t res;
    memset(&res, 0, sizeof(res));
    llama_mobile_status_t st = llama_mobile_generate(w->ctx, &p, cCb, cb.ok() ? &cb : nullptr,
                                                     (uint64_t *) &w->rid_slot, &res);
    const uint64_t rid = w->rid_slot;
    w->running.store(false);

    if (metaOut) {
        jlong meta[4] = {
            (jlong) rid,
            (jlong) (st == LLAMA_MOBILE_OK ? (int) res.stop_reason : (int) LLAMA_MOBILE_STOP_ERROR),
            (jlong) res.usage.prompt_tokens,
            (jlong) res.usage.generated_tokens,
        };
        env->SetLongArrayRegion(metaOut, 0, 4, meta);
    }

    if (st != LLAMA_MOBILE_OK) {
        setError(st);
        llama_mobile_generate_result_free(&res);
        return nullptr;
    }
    jstring out = nullptr;
    if (res.text) {
        out = env->NewStringUTF(res.text);
    }
    llama_mobile_generate_result_free(&res);
    return out;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_com_llamamobile_Native_abort(JNIEnv *, jobject, jlong h) {
    EngineWrap * w = wrap(h);
    if (!w || !w->ctx) return JNI_FALSE;
    if (!w->running.load()) return JNI_FALSE;
    // The core writes the request id at generation start; wait briefly for it.
    for (int i = 0; i < 2000; ++i) {
        uint64_t rid = w->rid_slot;
        if (rid != 0) {
            llama_mobile_status_t st = llama_mobile_abort(w->ctx, rid);
            return st == LLAMA_MOBILE_OK ? JNI_TRUE : JNI_FALSE;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
    }
    return JNI_FALSE;
}

extern "C" JNIEXPORT jintArray JNICALL
Java_com_llamamobile_Native_tokenize(JNIEnv * env, jobject, jlong h, jstring text) {
    EngineWrap * w = wrap(h);
    std::string str = toCpp(env, text);
    if (!w || !w->ctx || str.empty()) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }
    llama_mobile_tokenize_result_t r;
    memset(&r, 0, sizeof(r));
    llama_mobile_status_t st = llama_mobile_tokenize(w->ctx, str.c_str(), nullptr, 0, &r);
    if (st != LLAMA_MOBILE_OK || !r.tokens) { setError(st); return nullptr; }
    jintArray arr = env->NewIntArray((jsize) r.n_tokens);
    env->SetIntArrayRegion(arr, 0, (jsize) r.n_tokens, reinterpret_cast<const jint *>(r.tokens));
    llama_mobile_tokenize_result_free(&r);
    return arr;
}

extern "C" JNIEXPORT jstring JNICALL
Java_com_llamamobile_Native_detokenize(JNIEnv * env, jobject, jlong h, jintArray tokens) {
    EngineWrap * w = wrap(h);
    if (!w || !w->ctx || !tokens) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }
    jsize n = env->GetArrayLength(tokens);
    std::vector<int32_t> toks((size_t) n);
    env->GetIntArrayRegion(tokens, 0, n, reinterpret_cast<jint *>(toks.data()));
    char * text = nullptr;
    llama_mobile_status_t st = llama_mobile_detokenize(w->ctx, toks.data(), (size_t) n, &text);
    if (st != LLAMA_MOBILE_OK || !text) { setError(st); return nullptr; }
    jstring out = env->NewStringUTF(text);
    llama_mobile_free_text(text);
    return out;
}

extern "C" JNIEXPORT jobjectArray JNICALL
Java_com_llamamobile_Native_embed(JNIEnv * env, jobject, jlong h, jobjectArray texts) {
    EngineWrap * w = wrap(h);
    auto textVec = arrayToCpp(env, texts);
    if (!w || !w->ctx || textVec.empty()) { setError(LLAMA_MOBILE_ERR_INVALID_ARGUMENT); return nullptr; }

    std::vector<const char *> ptrs;
    ptrs.reserve(textVec.size());
    for (auto & t : textVec) ptrs.push_back(t.c_str());

    llama_mobile_embed_result_t res;
    memset(&res, 0, sizeof(res));
    llama_mobile_status_t st = llama_mobile_embed(w->ctx, ptrs.data(), ptrs.size(), &res);
    if (st != LLAMA_MOBILE_OK || !res.values) { setError(st); return nullptr; }

    jclass floatArrCls = env->FindClass("[F");
    jobjectArray rows = env->NewObjectArray((jsize) res.n_texts, floatArrCls, nullptr);
    for (size_t i = 0; i < res.n_texts; ++i) {
        jfloatArray row = env->NewFloatArray((jsize) res.dim);
        env->SetFloatArrayRegion(row, 0, (jsize) res.dim,
                                 reinterpret_cast<const jfloat *>(res.values + i * res.dim));
        env->SetObjectArrayElement(rows, (jsize) i, row);
        env->DeleteLocalRef(row);
    }
    llama_mobile_embed_result_free(&res);
    return rows;
}
