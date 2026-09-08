// llama_mobile_v2.cpp
//
// v2.0 C API implementation (canonical surface: llama_mobile_v2.h).
//
// The v2 layer is implemented DIRECTLY on the internal C++ engine
// (namespace llama_mobile, class llama_mobile_context in llama_mobile.h).
// The v1 public surfaces (llama_mobile_ffi.h *_c and llama_mobile_api.h *_t)
// have been fully purged; this translation unit no longer references them.
// Semantics were ported 1:1 from the deleted llama_mobile_ffi.cpp function
// bodies (see docs/v1-purge-workplan.md "porting map").
//
// Where the v2 IDL declares a semantic that the engine cannot yet express
// (typed media bytes, per-request abort isolation beyond the single-flight
// state machine, batch logprobs, download manager/registry, TTS full-text
// speak), the function returns an explicit status (usually
// LLAMA_MOBILE_ERR_UNSUPPORTED) with a comment — never a silent no-op.
// TTS speak is deliberately deferred to the reviewed TTS workflow design
// (docs/tts-current-workflow.md); tts_init/enable/release preserve the
// current behavior via the engine vocoder path.

#include "llama_mobile_v2.h"
#include "llama_mobile.h"
#include "llama.cpp-master/common/json.h"
#include "llama.cpp-master/common/json-schema-to-grammar.h"

#include <cstring>
#include <cstdio>
#include <map>
#include <mutex>
#include <cstdlib>
#include <new>
#include <string>
#include <vector>

// ---------------------------------------------------------------------------
// Process-wide bookkeeping (single-flight generations, log level/callback)
// ---------------------------------------------------------------------------

namespace {

using engine_t = llama_mobile::llama_mobile_context;

struct v2_ctx_state {
    uint64_t next_request = 1;
    bool     active = false;
    bool     abort_requested = false;
    uint64_t active_request = 0;
};

std::mutex g_state_mtx;
std::map<llama_mobile_context_t, v2_ctx_state *> g_states;

// log level + callback (process-wide; engine logs to stdout/stderr via the
// llama_mobile_verbose flag through llama_mobile::log).
int  g_log_level = LLAMA_MOBILE_LOG_INFO;
llama_mobile_log_cb g_log_cb = nullptr;
void * g_log_ud = nullptr;

v2_ctx_state * get_state(llama_mobile_context_t ctx) {
    std::lock_guard<std::mutex> lk(g_state_mtx);
    auto it = g_states.find(ctx);
    return it == g_states.end() ? nullptr : it->second;
}

void put_state(llama_mobile_context_t ctx, v2_ctx_state * st) {
    std::lock_guard<std::mutex> lk(g_state_mtx);
    g_states[ctx] = st;
}

void erase_state(llama_mobile_context_t ctx) {
    std::lock_guard<std::mutex> lk(g_state_mtx);
    auto it = g_states.find(ctx);
    if (it != g_states.end()) {
        delete it->second;
        g_states.erase(it);
    }
}

// v2 load-progress callback is bool(*)(float, void*) => continue flag.
// The engine (through llama.cpp's model loader) expects the same signature;
// we still route through a stack bridge so the user callback sees the raw
// progress values. Like the old v1 bridge, the return value is ignored and
// loading always continues (the callback is a progress *report* here).
struct progress_bridge {
    bool (*cb)(float, void *);
    void * ud;
};
bool progress_trampoline(float progress, void * ud) {
    if (ud) {
        progress_bridge * b = static_cast<progress_bridge *>(ud);
        if (b->cb) {
            b->cb(progress, b->ud);
        }
    }
    return true; // continue loading
}

// Single-flight guard.
struct generation_guard {
    v2_ctx_state * st;
    uint64_t request;
    explicit generation_guard(v2_ctx_state * s) : st(s), request(0) {
        st->abort_requested = false;
        st->active = true;
        st->active_request = st->next_request++;
        request = st->active_request;
    }
    ~generation_guard() {
        if (st) {
            st->active = false;
            st->active_request = 0;
        }
    }
    generation_guard(const generation_guard &) = delete;
};

engine_t * get_engine(llama_mobile_context_t ctx) {
    return reinterpret_cast<engine_t *>(ctx);
}

// Allocates a NUL-terminated char* copy (caller frees with free()).
char * cpp_str_to_c(const std::string & str) {
    char * out = (char *) malloc(str.size() + 1);
    if (out) {
        std::memcpy(out, str.c_str(), str.size() + 1);
    }
    return out;
}

// Port of ffi.cpp c_str_array_to_vector.
std::vector<std::string> c_str_array_to_vector(const char ** arr, int count) {
    std::vector<std::string> vec;
    if (arr != nullptr) {
        for (int i = 0; i < count; ++i) {
            if (arr[i] != nullptr) {
                vec.push_back(arr[i]);
            }
        }
    }
    return vec;
}

} // namespace

// ---------------------------------------------------------------------------
// Identity, version, status, logging
// ---------------------------------------------------------------------------

const llama_mobile_version_info_t * llama_mobile_version(void) {
    static const llama_mobile_version_info_t v = {
        LLAMA_MOBILE_VERSION_MAJOR,
        LLAMA_MOBILE_VERSION_MINOR,
        LLAMA_MOBILE_VERSION_PATCH,
        LLAMA_MOBILE_VERSION_STRING,
        LLAMA_MOBILE_API_VERSION,
    };
    return &v;
}

const char * llama_mobile_status_string(llama_mobile_status_t status) {
    switch (status) {
        case LLAMA_MOBILE_OK:                    return "ok";
        case LLAMA_MOBILE_ERR_INVALID_ARGUMENT:  return "invalid argument";
        case LLAMA_MOBILE_ERR_SAMPLER_INIT:      return "sampler initialization failed";
        case LLAMA_MOBILE_ERR_GENERATION:        return "generation failed";
        case LLAMA_MOBILE_ERR_MODEL_LOAD:        return "model load failed";
        case LLAMA_MOBILE_ERR_MODEL_NOT_FOUND:   return "model not found";
        case LLAMA_MOBILE_ERR_IO:                return "I/O error";
        case LLAMA_MOBILE_ERR_UNSUPPORTED:       return "unsupported";
        case LLAMA_MOBILE_ERR_OOM:               return "out of memory";
        case LLAMA_MOBILE_ERR_CONTEXT_FULL:      return "context full";
        case LLAMA_MOBILE_ERR_ABORTED:           return "aborted";
        case LLAMA_MOBILE_ERR_NOT_INITIALIZED:   return "not initialized";
        case LLAMA_MOBILE_ERR_NETWORK:           return "network error";
        case LLAMA_MOBILE_ERR_CHECKSUM:          return "checksum mismatch";
        case LLAMA_MOBILE_ERR_ALREADY_RUNNING:   return "already running";
        default:                                 return "unknown status";
    }
}

llama_mobile_status_t llama_mobile_capabilities(llama_mobile_capabilities_t * out) {
    if (!out) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    memset(out, 0, sizeof(*out));
    out->supports_embeddings = true;
    out->supports_lora = true;
    out->supports_vision = true;  // when an mmproj is attached
    out->supports_audio_input = true;
    out->supports_tts = true;     // vocoder path available (full speak: see TTS note)
    out->default_n_ctx = 2048;
    // device memory/name are left 0/NULL unless the backend exposes them here.
    return LLAMA_MOBILE_OK;
}

llama_mobile_status_t llama_mobile_log_set_level(int level) {
    g_log_level = level;
    // Port of llama_mobile_set_verbose_logging_c: the engine's verbose flag
    // gates VERBOSE-level messages in llama_mobile::log (llama_mobile_utils.cpp).
    llama_mobile_verbose = (level <= LLAMA_MOBILE_LOG_DEBUG);
    return LLAMA_MOBILE_OK;
}

llama_mobile_status_t llama_mobile_log_set_callback(llama_mobile_log_cb cb, void * user_data) {
    g_log_cb = cb;
    g_log_ud = user_data;
    return LLAMA_MOBILE_OK;
}

// ---------------------------------------------------------------------------
// Default-value initializers
// ---------------------------------------------------------------------------

void llama_mobile_context_config_init(llama_mobile_context_config_t * config) {
    if (!config) return;
    memset(config, 0, sizeof(*config));
    config->engine = LLAMA_MOBILE_ENGINE_AUTO;
    config->n_gpu_layers = 0;
    config->n_ctx = 2048;         // 0 = model default
    config->n_batch = 512;
    config->n_ubatch = 512;
    config->n_threads = 0;        // 0 = auto
    config->flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_CHAT;
    config->image_min_tokens = -1;
}

void llama_mobile_sampling_init(llama_mobile_sampling_t * s) {
    if (!s) return;
    memset(s, 0, sizeof(*s));
    s->seed = -1;
    s->temperature = 0.8f;
    s->top_k = 40;
    s->top_p = 0.95f;
    s->min_p = 0.05f;
    s->typical_p = 1.0f;
    s->penalty_repeat = 1.1f;
    s->penalty_last_n = 64;
    s->mirostat_tau = 5.0f;
    s->mirostat_eta = 0.1f;
}

void llama_mobile_generate_params_init(llama_mobile_generate_params_t * p) {
    if (!p) return;
    memset(p, 0, sizeof(*p));
    llama_mobile_sampling_init(&p->sampling);
    p->max_tokens = 128;          // -1 = no explicit limit
    p->tool_choice = nullptr;     // leave NULL; consumers may set "auto" etc.
}

void llama_mobile_tts_params_init(llama_mobile_tts_params_t * p) {
    if (!p) return;
    memset(p, 0, sizeof(*p));
    p->sample_rate = 24000;
    p->speed = 1.0f;
    p->voice = LLAMA_MOBILE_TTS_VOICE_DEFAULT;
}

// ---------------------------------------------------------------------------
// Context lifecycle
// ---------------------------------------------------------------------------

llama_mobile_status_t llama_mobile_context_create(
        const llama_mobile_context_config_t * config,
        llama_mobile_context_t * out_ctx) {
    if (!config || !out_ctx || !config->model_path) {
        return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    }

    engine_t * engine = nullptr;
    try {
        // Explicitly initialize the llama backend once (port of init_context_c).
        static bool backend_initialized = false;
        if (!backend_initialized) {
            llama_backend_init();
            backend_initialized = true;
        }

        engine = new engine_t();

        common_params cpp_params;
        cpp_params.model.path = config->model_path;
        if (config->chat_template) {
            cpp_params.chat_template = config->chat_template;
        }
        if (config->system_prompt) {
            cpp_params.system_prompt = config->system_prompt;
        }
        cpp_params.n_ctx = config->n_ctx;
        cpp_params.n_batch = config->n_batch;
        cpp_params.n_ubatch = config->n_ubatch;
        // engine select (port of llama_mobile_context_create's mapping)
        if (config->engine == LLAMA_MOBILE_ENGINE_CPU) {
            cpp_params.n_gpu_layers = 0;
        } else {
            cpp_params.n_gpu_layers = config->n_gpu_layers;
        }
        cpp_params.cpuparams.n_threads = config->n_threads;
        // llama.cpp now expresses mmap/mlock as a single load_mode enum
        const bool use_mmap  = (config->flags & LLAMA_MOBILE_CTX_MMAP) != 0;
        const bool use_mlock = (config->flags & LLAMA_MOBILE_CTX_MLOCK) != 0;
        if (use_mmap && use_mlock) {
            cpp_params.load_mode = LLAMA_LOAD_MODE_MMAP_MLOCK;
        } else if (use_mmap) {
            cpp_params.load_mode = LLAMA_LOAD_MODE_MMAP;
        } else if (use_mlock) {
            cpp_params.load_mode = LLAMA_LOAD_MODE_MLOCK;
        } else {
            cpp_params.load_mode = LLAMA_LOAD_MODE_NONE;
        }
        cpp_params.embedding = (config->flags & LLAMA_MOBILE_CTX_EMBEDDING) != 0;
        // Port of init_context_c: v1 params struct carried pooling_type and
        // embd_normalize (both zeroed by the v2 bridge), so the engine always
        // saw LLAMA_POOLING_TYPE_UNSPECIFIED and embd_normalize == 0.
        cpp_params.pooling_type = LLAMA_POOLING_TYPE_UNSPECIFIED;
        cpp_params.embd_normalize = 0;
        // llama.cpp master's automatic context fitting (fit_params) probes
        // device memory by constructing throwaway contexts; it is not usable
        // from an embedded/mobile host. The caller configures n_ctx/n_batch/
        // n_gpu_layers explicitly instead.
        cpp_params.fit_params = false;
        engine->enable_chat_template = (config->flags & LLAMA_MOBILE_CTX_CHAT) != 0;
        cpp_params.image_min_tokens = config->image_min_tokens;

        if (config->kv_cache_type_k) {
            try {
                cpp_params.cache_type_k = llama_mobile::kv_cache_type_from_str(config->kv_cache_type_k);
            } catch (const std::exception &) {
                delete engine;
                return LLAMA_MOBILE_ERR_MODEL_LOAD;
            }
        }
        if (config->kv_cache_type_v) {
            try {
                cpp_params.cache_type_v = llama_mobile::kv_cache_type_from_str(config->kv_cache_type_v);
            } catch (const std::exception &) {
                delete engine;
                return LLAMA_MOBILE_ERR_MODEL_LOAD;
            }
        }

        // Load-progress bridge (v2 bool cb -> loader trampoline). Stack bridge
        // is safe: llama.cpp invokes it synchronously during loadModel().
        progress_bridge bridge;
        bridge.cb = config->load_progress_cb;
        bridge.ud = config->load_progress_user_data;
        if (config->load_progress_cb) {
            cpp_params.load_progress_callback = progress_trampoline;
            cpp_params.load_progress_callback_user_data = &bridge;
        }

        if (!engine->loadModel(cpp_params)) {
            delete engine;
            return LLAMA_MOBILE_ERR_MODEL_LOAD;
        }
    } catch (...) {
        if (engine) delete engine;
        return LLAMA_MOBILE_ERR_MODEL_LOAD;
    }

    llama_mobile_context_t ctx = reinterpret_cast<llama_mobile_context_t>(engine);
    v2_ctx_state * st = new (std::nothrow) v2_ctx_state();
    if (!st) {
        delete engine;
        return LLAMA_MOBILE_ERR_OOM;
    }
    put_state(ctx, st);

    *out_ctx = ctx;
    return LLAMA_MOBILE_OK;
}

llama_mobile_status_t llama_mobile_context_destroy(llama_mobile_context_t * ctx) {
    if (!ctx || !*ctx) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    erase_state(*ctx);
    delete get_engine(*ctx);
    *ctx = nullptr;
    return LLAMA_MOBILE_OK;
}

llama_mobile_status_t llama_mobile_model_info(llama_mobile_context_t ctx,
                                              llama_mobile_model_info_t * out) {
    if (!ctx || !out) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    engine_t * engine = get_engine(ctx);
    memset(out, 0, sizeof(*out));
    // Port of get_n_ctx_c / get_n_embd_c / get_model_size_c /
    // get_model_params_c / get_model_desc_c (ffi.cpp ~1476-1518).
    out->n_ctx = engine->n_ctx;
    if (engine->model) {
        out->n_embd = llama_model_n_embd(engine->model);
        out->model_size_bytes = llama_model_size(engine->model);
        out->n_params = llama_model_n_params(engine->model);
        char model_desc[128];
        llama_model_desc(engine->model, model_desc, sizeof(model_desc));
        out->description = cpp_str_to_c(model_desc); // owned -> model_info_free
    }
    // borrowed; engine owns the string
    out->chat_template = engine->model ? llama_model_chat_template(engine->model, nullptr) : nullptr;
    return LLAMA_MOBILE_OK;
}

// Frees the owned `description` inside `info` (chat_template is borrowed).
void llama_mobile_model_info_free(llama_mobile_model_info_t * info) {
    if (info && info->description) {
        free((void *) info->description);
        info->description = nullptr;
    }
}

llama_mobile_status_t llama_mobile_context_stats(llama_mobile_context_t ctx,
                                                 llama_mobile_context_stats_t * out) {
    if (!ctx || !out) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    memset(out, 0, sizeof(*out));
    // KV usage is not exposed by the engine; report 0 (unknown) and keep the
    // API honest.
    out->kv_usage = 0.0f;
    out->context_bytes = 0;
    engine_t * engine = get_engine(ctx);
    out->model_bytes = engine->model ? (uint64_t) llama_model_size(engine->model) : 0;
    return LLAMA_MOBILE_OK;
}

// ---------------------------------------------------------------------------
// Multimodal module (media: PATH supported; BYTES/URI deferred)
// ---------------------------------------------------------------------------

llama_mobile_status_t llama_mobile_multimodal_init(llama_mobile_context_t ctx,
                                                   const char * mmproj_path) {
    if (!ctx || !mmproj_path) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    // Port of llama_mobile_init_multimodal_c(handle, path, use_gpu=true).
    bool ok = false;
    try {
        ok = get_engine(ctx)->initMultimodal(mmproj_path, true);
    } catch (...) {
        ok = false;
    }
    return ok ? LLAMA_MOBILE_OK : LLAMA_MOBILE_ERR_MODEL_LOAD;
}
llama_mobile_status_t llama_mobile_multimodal_release(llama_mobile_context_t ctx) {
    if (!ctx) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    try {
        get_engine(ctx)->releaseMultimodal();
    } catch (...) {
    }
    return LLAMA_MOBILE_OK;
}
bool llama_mobile_multimodal_is_enabled(llama_mobile_context_t ctx) {
    if (!ctx) return false;
    try {
        return get_engine(ctx)->isMultimodalEnabled();
    } catch (...) {
        return false;
    }
}
bool llama_mobile_multimodal_supports_vision(llama_mobile_context_t ctx) {
    if (!ctx) return false;
    try {
        return get_engine(ctx)->isMultimodalSupportVision();
    } catch (...) {
        return false;
    }
}
bool llama_mobile_multimodal_supports_audio(llama_mobile_context_t ctx) {
    if (!ctx) return false;
    try {
        return get_engine(ctx)->isMultimodalSupportAudio();
    } catch (...) {
        return false;
    }
}

// Convert a JSON schema to inline GBNF grammar (llama.cpp common utility).
static llama_mobile_status_t schema_to_grammar(const char * schema, std::string & out) {
    try {
        out = json_schema_to_grammar(common_json::parse(schema), false);
        return LLAMA_MOBILE_OK;
    } catch (...) {
        return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    }
}

// ---------------------------------------------------------------------------
// Generate (single-flight; per-request abort)
// ---------------------------------------------------------------------------

static llama_mobile_stop_reason_t to_stop_reason(bool aborted,
                                                 bool stopped_eos,
                                                 bool stopped_word,
                                                 bool stopped_limit,
                                                 bool truncated) {
    if (aborted) return LLAMA_MOBILE_STOP_ABORTED;
    if (stopped_eos) return LLAMA_MOBILE_STOP_EOS;
    if (stopped_word) return LLAMA_MOBILE_STOP_WORD;
    if (stopped_limit || truncated) return LLAMA_MOBILE_STOP_LENGTH;
    return LLAMA_MOBILE_STOP_LENGTH;
}

// Runs one generation on the engine. `with_media` selects the multimodal
// loadPrompt path (port of llama_mobile_completion_c vs
// llama_mobile_multimodal_completion_c). Returns:
//    0                    success (result may be an abort/early stop)
//   -2                    sampler init failed
//   -3/-4                 engine exception (std::exception / unknown)
static int run_generation(engine_t * engine,
                          const llama_mobile_generate_params_t * p,
                          llama_mobile_token_cb on_token,
                          void * token_user_data,
                          const std::vector<const char *> & media_paths,
                          bool with_media) {
    if (!engine || !engine->ctx || !engine->model) {
        return -1;
    }

    try {
        engine->rewind();

        engine->params.prompt = p->prompt ? p->prompt : "";
        // v2 keeps v1 thread semantics: 0 = engine default (from context_create).
        engine->params.n_predict = p->max_tokens;
        engine->params.sampling.seed = p->sampling.seed;
        engine->params.sampling.temp = p->sampling.temperature;
        engine->params.sampling.top_k = p->sampling.top_k;
        engine->params.sampling.top_p = p->sampling.top_p;
        engine->params.sampling.min_p = p->sampling.min_p;
        engine->params.sampling.typ_p = p->sampling.typical_p;
        engine->params.sampling.penalty_last_n = p->sampling.penalty_last_n;
        engine->params.sampling.penalty_repeat = p->sampling.penalty_repeat;
        engine->params.sampling.penalty_freq = p->sampling.penalty_freq;
        engine->params.sampling.penalty_present = p->sampling.penalty_present;
        engine->params.sampling.mirostat = p->sampling.mirostat;
        engine->params.sampling.mirostat_tau = p->sampling.mirostat_tau;
        engine->params.sampling.mirostat_eta = p->sampling.mirostat_eta;
        engine->params.sampling.ignore_eos = p->sampling.ignore_eos;
        engine->params.sampling.n_probs = 0; // v1 core exposes no logprobs
        if (p->sampling.n_logit_biases > 0) {
            return -1; // engine core has no logit-bias support (v2: UNSUPPORTED)
        }
        engine->params.antiprompt = c_str_array_to_vector(p->stop_sequences, (int) p->n_stop_sequences);
        // Grammar: fill_generate_params wired p->grammar; llama_mobile_generate
        // overrides it with the json_schema-derived grammar when present, so the
        // caller passes the effective grammar string here (NULL = none).
        if (p->grammar) {
            engine->params.sampling.grammar = common_grammar(COMMON_GRAMMAR_TYPE_USER, p->grammar);
        }

        if (!with_media) {
            // Port of completion_c: json_schema/tools/parallel_tool_calls/
            // tool_choice are copied into the engine for the chat-template
            // (Jinja + tools) path. multimodal_completion_c never touched
            // them, so media runs keep the engine's previous values.
            engine->json_schema = p->json_schema ? p->json_schema : "";
            engine->tools = p->tools ? p->tools : "";
            engine->parallel_tool_calls = p->parallel_tool_calls;
            engine->tool_choice = p->tool_choice ? p->tool_choice : "";
        }

        // Handle chat messages if provided (stored in engine).
        engine->chat_messages.clear();
        if (p->messages && p->n_messages > 0) {
            for (size_t i = 0; i < p->n_messages; ++i) {
                const auto & msg = p->messages[i];
                if (msg.role && msg.content) {
                    common_chat_msg chat_msg;
                    chat_msg.role = msg.role;
                    chat_msg.content = msg.content;
                    chat_msg.reasoning_content = "";   // v2 messages carry none
                    chat_msg.tool_name = msg.tool_name ? msg.tool_name : "";
                    chat_msg.tool_call_id = msg.tool_call_id ? msg.tool_call_id : "";
                    engine->chat_messages.push_back(chat_msg);
                }
            }
        }

        // Set JSON response flag (stored in engine); v2 never requests the
        // OpenAI-like JSON envelope.
        engine->use_json_response = false;

        if (!engine->initSampling()) {
            return -2;
        }
        engine->beginCompletion();

        if (with_media) {
            std::vector<std::string> media_vec;
            for (const char * mpath : media_paths) {
                if (mpath) media_vec.push_back(mpath);
            }
            engine->loadPrompt(media_vec);
        } else {
            engine->loadPrompt();
        }

        while (engine->has_next_token && !engine->is_interrupted) {
            const llama_mobile::completion_token_output token_with_probs = engine->doCompletion();

            if (token_with_probs.tok == -1 && !engine->has_next_token) {
                break;
            }

            if (token_with_probs.tok != -1 && on_token) {
                std::string token_text = common_token_to_piece(engine->ctx, token_with_probs.tok);
                bool continue_completion = on_token(token_text.c_str(), token_user_data);
                if (!continue_completion) {
                    engine->is_interrupted = true;
                    break;
                }
            }
        }

        // Results (no JSON wrapping: engine->use_json_response == false).
        engine->is_predicting = false;
        return 0;
    } catch (const std::exception &) {
        engine->is_predicting = false;
        engine->is_interrupted = true;
        return -3;
    } catch (...) {
        engine->is_predicting = false;
        engine->is_interrupted = true;
        return -4;
    }
}

llama_mobile_status_t llama_mobile_generate(
        llama_mobile_context_t ctx,
        const llama_mobile_generate_params_t * params,
        llama_mobile_token_cb on_token,
        void * token_user_data,
        uint64_t * out_request_id,
        llama_mobile_generate_result_t * out_result) {
    if (!ctx || !params) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    if (!params->prompt && (!params->messages || params->n_messages == 0)) {
        return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    }

    v2_ctx_state * st = get_state(ctx);
    if (!st) return LLAMA_MOBILE_ERR_NOT_INITIALIZED;
    if (st->active) return LLAMA_MOBILE_ERR_ALREADY_RUNNING;

    generation_guard guard(st);
    if (out_request_id) *out_request_id = guard.request;

    engine_t * engine = get_engine(ctx);

    // Real structured output: convert json_schema -> GBNF grammar (raw-prompt
    // mode). Message+tools mode keeps the engine chat/tool handling and reports
    // unsupported here until the message+tools structured-output path is wired.
    std::string schema_grammar;
    const char * effective_grammar = params->grammar;
    if (params->json_schema && params->json_schema[0]) {
        if (params->messages && params->n_messages > 0) {
            return LLAMA_MOBILE_ERR_UNSUPPORTED;
        }
        llama_mobile_status_t s = schema_to_grammar(params->json_schema, schema_grammar);
        if (s != LLAMA_MOBILE_OK) return s;
        effective_grammar = schema_grammar.c_str();
    }

    // Media: only PATH supported at this stage.
    std::vector<const char *> media_paths;
    for (size_t i = 0; i < params->n_media; ++i) {
        const llama_mobile_media_t & m = params->media[i];
        if (m.kind != LLAMA_MOBILE_MEDIA_PATH || !m.path) {
            return LLAMA_MOBILE_ERR_UNSUPPORTED;
        }
        media_paths.push_back(m.path);
    }

    // fill_generate_params port: the engine core has no logit-bias support.
    if (params->sampling.n_logit_biases > 0) {
        return LLAMA_MOBILE_ERR_UNSUPPORTED;
    }

    llama_mobile_generate_params_t effective = *params;
    effective.grammar = effective_grammar;

    int rc;
    if (!media_paths.empty()) {
        rc = run_generation(engine, &effective, on_token, token_user_data,
                            media_paths, /*with_media=*/true);
    } else {
        rc = run_generation(engine, &effective, on_token, token_user_data,
                            media_paths, /*with_media=*/false);
    }

    if (rc != 0) {
        // -1 = unsupported input (logit bias handled above; engine not loaded)
        // -2 = sampler init failed; -3/-4 = exceptions -> generation failed.
        return st->abort_requested ? LLAMA_MOBILE_ERR_ABORTED : LLAMA_MOBILE_ERR_GENERATION;
    }

    if (out_result) {
        memset(out_result, 0, sizeof(*out_result));
        out_result->text = cpp_str_to_c(engine->generated_text);
        out_result->stop_reason = to_stop_reason(st->abort_requested,
                                                 engine->stopped_eos,
                                                 engine->stopped_word,
                                                 engine->stopped_limit,
                                                 engine->truncated);
        out_result->usage.prompt_tokens = 0;             // not exposed by the engine completion
        out_result->usage.generated_tokens = (int32_t) engine->num_tokens_predicted;
        out_result->usage.time_to_first_token_ms = 0;
        out_result->usage.total_ms = 0;
        out_result->token_probs = nullptr;
        out_result->n_token_probs = 0;
        // Contract: a cancelled call completes with stop_reason == ABORTED in
        // the result and a success status.
        return LLAMA_MOBILE_OK;
    }
    return st->abort_requested ? LLAMA_MOBILE_ERR_ABORTED : LLAMA_MOBILE_OK;
}

void llama_mobile_generate_result_free(llama_mobile_generate_result_t * r) {
    if (!r) return;
    if (r->text) {
        llama_mobile_free_text(r->text);
        r->text = nullptr;
    }
    if (r->token_probs) {
        free(r->token_probs);
        r->token_probs = nullptr;
        r->n_token_probs = 0;
    }
}

llama_mobile_status_t llama_mobile_abort(llama_mobile_context_t ctx, uint64_t request_id) {
    if (!ctx) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    v2_ctx_state * st = get_state(ctx);
    if (!st) return LLAMA_MOBILE_ERR_NOT_INITIALIZED;
    if (!st->active || st->active_request != request_id) {
        return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    }
    st->abort_requested = true;
    // Port of llama_mobile_stop_completion_c.
    get_engine(ctx)->is_interrupted = true;
    return LLAMA_MOBILE_OK;
}

// ---------------------------------------------------------------------------
// Embeddings (batch implemented as a loop over the single-text engine)
// ---------------------------------------------------------------------------

void llama_mobile_embed_result_free(llama_mobile_embed_result_t * r) {
    if (r) {
        if (r->values) {
            free(r->values);
            r->values = nullptr;
        }
        r->n_texts = 0;
        r->dim = 0;
    }
}

// Port of llama_mobile_embedding_c: validates the engine is in embedding mode
// and runs one text through llama_mobile_context::getEmbedding.
static std::vector<float> engine_embedding(engine_t * engine, const char * text) {
    if (!engine || !text || !engine->ctx || !engine->model || !engine->params.embedding) {
        return {};
    }
    common_params embd_params;
    embd_params.prompt = text;
    embd_params.embd_normalize = engine->params.embd_normalize;
    return engine->getEmbedding(embd_params);
}

llama_mobile_status_t llama_mobile_embed(llama_mobile_context_t ctx,
                                         const char * const * texts,
                                         size_t n_texts,
                                         llama_mobile_embed_result_t * out) {
    if (!ctx || (!texts && n_texts > 0) || !out) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    if (n_texts == 0) {
        memset(out, 0, sizeof(*out));
        return LLAMA_MOBILE_OK;
    }
    engine_t * engine = get_engine(ctx);
    // two-pass: first learn the dimension, then fill rows
    const std::vector<float> first = engine_embedding(engine, texts[0]);
    if (first.empty()) return LLAMA_MOBILE_ERR_GENERATION;
    const size_t dim = first.size();

    float * all = (float *) calloc(n_texts * dim, sizeof(float));
    if (!all) return LLAMA_MOBILE_ERR_OOM;
    for (size_t i = 0; i < n_texts; ++i) {
        const std::vector<float> e = engine_embedding(engine, texts[i]);
        if (e.size() != dim) {
            free(all);
            return LLAMA_MOBILE_ERR_GENERATION;
        }
        memcpy(all + i * dim, e.data(), dim * sizeof(float));
    }
    out->values = all;
    out->n_texts = n_texts;
    out->dim = dim;
    return LLAMA_MOBILE_OK;
}

// ---------------------------------------------------------------------------
// Tokenize / detokenize (media positions deferred)
// ---------------------------------------------------------------------------

void llama_mobile_tokenize_result_free(llama_mobile_tokenize_result_t * r) {
    if (r) {
        if (r->tokens) free(r->tokens);
        if (r->media_positions) free(r->media_positions);
        memset(r, 0, sizeof(*r));
    }
}

llama_mobile_status_t llama_mobile_tokenize(llama_mobile_context_t ctx,
                                            const char * text,
                                            const llama_mobile_media_t * media,
                                            size_t n_media,
                                            llama_mobile_tokenize_result_t * out) {
    if (!ctx || !text || !out) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    if (n_media > 0) {
        // Media-aware tokenization at the v2 layer is part of the v2.0 media
        // work (engine tokenize() supports it once multimodal is enabled).
        return LLAMA_MOBILE_ERR_UNSUPPORTED;
    }
    engine_t * engine = get_engine(ctx);
    if (!engine->ctx) return LLAMA_MOBILE_ERR_GENERATION;

    try {
        // Port of llama_mobile_tokenize_c: tokenize without BOS/add-special.
        const std::vector<llama_token> tokens_vec = ::common_tokenize(engine->ctx, text, false, true);
        if (tokens_vec.empty()) return LLAMA_MOBILE_ERR_GENERATION;
        memset(out, 0, sizeof(*out));
        out->tokens = (int32_t *) malloc(tokens_vec.size() * sizeof(int32_t));
        if (!out->tokens) return LLAMA_MOBILE_ERR_OOM;
        for (size_t i = 0; i < tokens_vec.size(); ++i) {
            out->tokens[i] = (int32_t) tokens_vec[i];
        }
        out->n_tokens = tokens_vec.size();
        out->has_media = false;
        return LLAMA_MOBILE_OK;
    } catch (...) {
        return LLAMA_MOBILE_ERR_GENERATION;
    }
}

llama_mobile_status_t llama_mobile_detokenize(llama_mobile_context_t ctx,
                                              const int32_t * tokens,
                                              size_t n_tokens,
                                              char ** out_text) {
    if (!ctx || (!tokens && n_tokens > 0) || !out_text) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    engine_t * engine = get_engine(ctx);
    if (!tokens || n_tokens == 0 || !engine->ctx) {
        *out_text = cpp_str_to_c(""); // port of detokenize_c's empty result
        return LLAMA_MOBILE_OK;
    }
    try {
        std::vector<llama_token> tokens_vec;
        tokens_vec.reserve(n_tokens);
        for (size_t i = 0; i < n_tokens; ++i) tokens_vec.push_back((llama_token) tokens[i]);
        const std::string text = llama_mobile::tokens_to_str(engine->ctx,
                                                             tokens_vec.cbegin(),
                                                             tokens_vec.cend());
        *out_text = cpp_str_to_c(text);
        return LLAMA_MOBILE_OK;
    } catch (...) {
        *out_text = cpp_str_to_c("");
        return LLAMA_MOBILE_OK;
    }
}

// ---------------------------------------------------------------------------
// LoRA
// ---------------------------------------------------------------------------

llama_mobile_status_t llama_mobile_lora_load(llama_mobile_context_t ctx,
                                             const llama_mobile_lora_t * adapters,
                                             size_t count) {
    if (!ctx || (!adapters && count > 0)) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    engine_t * engine = get_engine(ctx);
    std::vector<common_adapter_lora_info> lora_adapters;
    lora_adapters.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        common_adapter_lora_info adapter;
        adapter.path = adapters[i].path ? adapters[i].path : "";
        adapter.scale = adapters[i].scale;
        lora_adapters.push_back(adapter);
    }
    int rc = -1;
    try {
        rc = engine->applyLoraAdapters(lora_adapters);
    } catch (...) {
        rc = -1;
    }
    return rc == 0 ? LLAMA_MOBILE_OK : LLAMA_MOBILE_ERR_GENERATION;
}

llama_mobile_status_t llama_mobile_lora_remove(llama_mobile_context_t ctx) {
    if (!ctx) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    try {
        get_engine(ctx)->removeLoraAdapters();
    } catch (...) {
    }
    return LLAMA_MOBILE_OK;
}

llama_mobile_status_t llama_mobile_lora_list(llama_mobile_context_t ctx,
                                             llama_mobile_lora_t ** out_adapters,
                                             size_t * out_count) {
    if (!ctx || !out_adapters || !out_count) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    std::vector<common_adapter_lora_info> loaded;
    try {
        loaded = get_engine(ctx)->getLoadedLoraAdapters();
    } catch (...) {
        loaded.clear();
    }
    const size_t n = loaded.size();
    llama_mobile_lora_t * arr = (llama_mobile_lora_t *) calloc(n > 0 ? n : 1, sizeof(llama_mobile_lora_t));
    if (!arr) return LLAMA_MOBILE_ERR_OOM;
    for (size_t i = 0; i < n; ++i) {
        arr[i].path = cpp_str_to_c(loaded[i].path);
        arr[i].scale = loaded[i].scale;
    }
    *out_adapters = arr;
    *out_count = n;
    return LLAMA_MOBILE_OK;
}

void llama_mobile_lora_list_free(llama_mobile_lora_t * adapters, size_t count) {
    if (!adapters) return;
    for (size_t i = 0; i < count; ++i) {
        free((void *) adapters[i].path);
    }
    free(adapters);
}

// ---------------------------------------------------------------------------
// TTS module — preserves the engine vocoder lifecycle; full-text speak is
// deferred to the reviewed TTS workflow design (docs/tts-current-workflow.md).
// ---------------------------------------------------------------------------

llama_mobile_status_t llama_mobile_tts_init(llama_mobile_context_t ctx,
                                            const char * vocoder_model_path) {
    if (!ctx || !vocoder_model_path) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    bool ok = false;
    try {
        ok = get_engine(ctx)->initVocoder(vocoder_model_path);
    } catch (...) {
        ok = false;
    }
    return ok ? LLAMA_MOBILE_OK : LLAMA_MOBILE_ERR_MODEL_LOAD;
}

llama_mobile_status_t llama_mobile_tts_speak(llama_mobile_context_t ctx,
                                             const llama_mobile_tts_params_t * params,
                                             llama_mobile_usage_t * out_usage,
                                             int16_t ** out_pcm, size_t * out_pcm_len) {
    (void) ctx; (void) params; (void) out_usage; (void) out_pcm; (void) out_pcm_len;
    // Deliberately not implemented: full-text speak must follow the TTS
    // workflow review (docs/tts-current-workflow.md).
    return LLAMA_MOBILE_ERR_UNSUPPORTED;
}

void llama_mobile_tts_pcm_free(int16_t * pcm) {
    free(pcm);
}

llama_mobile_status_t llama_mobile_tts_release(llama_mobile_context_t ctx) {
    if (!ctx) return LLAMA_MOBILE_ERR_INVALID_ARGUMENT;
    try {
        get_engine(ctx)->releaseVocoder();
    } catch (...) {
    }
    return LLAMA_MOBILE_OK;
}

bool llama_mobile_tts_is_enabled(llama_mobile_context_t ctx) {
    if (!ctx) return false;
    try {
        return get_engine(ctx)->isVocoderEnabled();
    } catch (...) {
        return false;
    }
}

// ---------------------------------------------------------------------------
// Ownership helpers
// ---------------------------------------------------------------------------

void llama_mobile_free_text(char * text) {
    free(text);
}
