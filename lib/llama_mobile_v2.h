// llama_mobile v2 — CANONICAL C API (DRAFT for review — M2 freeze candidate)
//
// This header is the single source of truth (IDL) for llama_mobile v2.0.
// All platform SDKs (Swift/Java-Kotlin/Flutter/Capacitor) must project this
// surface 1:1. It is a DESIGN DRAFT: nothing here is implemented or wired yet,
// and the v1 API (llama_mobile_api.h) remains the shipping contract until the
// v2.0 release.
//
// Version this file with LLAMA_MOBILE_API_VERSION 2.
//
// Conventions used everywhere:
//   * functions return llama_mobile_status_t (never bare int/bool for errors)
//   * params structs are POD + <type>_init() that applies documented defaults
//   * strings are UTF-8, NUL-terminated; multi-value inputs are pointer+count
//   * `owned` results are freed with the matching llama_mobile_free_* function
//   * borrowed results (const) must not be freed
//   * all text generation goes through llama_mobile_generate (prompt OR messages)
//   * module add-ons (multimodal / tts / lora) are separate init calls on a context
//   * one active generation/download per context; abort is request-scoped
//
// Threading contract (this C core): the API is synchronous/blocking by design
// and runs on the calling thread. Guarantees: llama_mobile_abort() is callable
// from any thread while a generation is in flight; load-progress and log
// callbacks run on the thread performing the work; concurrent operations on one
// context fail fast with LLAMA_MOBILE_ERR_ALREADY_RUNNING. Platform SDKs wrap
// this with a documented sync + async surface so app UI threads are never
// blocked (see docs/api-contract-v2.md §8).

#ifndef LLAMA_MOBILE_V2_H
#define LLAMA_MOBILE_V2_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#include "llama_mobile_version.h"

#define LLAMA_MOBILE_API_VERSION 2

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// 1. Status codes (one enum everywhere)
// ---------------------------------------------------------------------------
typedef enum llama_mobile_status_t {
    LLAMA_MOBILE_OK                     =  0,
    LLAMA_MOBILE_ERR_INVALID_ARGUMENT   = -1,
    LLAMA_MOBILE_ERR_SAMPLER_INIT       = -2,
    LLAMA_MOBILE_ERR_GENERATION         = -3,
    LLAMA_MOBILE_ERR_MODEL_LOAD         = -4,
    LLAMA_MOBILE_ERR_MODEL_NOT_FOUND    = -5,
    LLAMA_MOBILE_ERR_IO                 = -6,
    LLAMA_MOBILE_ERR_UNSUPPORTED        = -7,
    LLAMA_MOBILE_ERR_OOM                = -8,
    LLAMA_MOBILE_ERR_CONTEXT_FULL       = -9,
    LLAMA_MOBILE_ERR_ABORTED            = -10,  // generation/download cancelled
    LLAMA_MOBILE_ERR_NOT_INITIALIZED    = -11,  // module not loaded / context closed
    LLAMA_MOBILE_ERR_NETWORK            = -12,
    LLAMA_MOBILE_ERR_CHECKSUM           = -13,
    LLAMA_MOBILE_ERR_ALREADY_RUNNING    = -14,  // a generation is already active
} llama_mobile_status_t;

// Human-readable name for a status; returns borrowed static string.
const char * llama_mobile_status_string(llama_mobile_status_t status);

// ---------------------------------------------------------------------------
// 2. Identity, version & capabilities
// ---------------------------------------------------------------------------
typedef struct llama_mobile_version_info_t {
    int         major;          // LLAMA_MOBILE_VERSION_MAJOR
    int         minor;
    int         patch;
    const char* string;         // "2.0.0"
    int         api_version;    // == LLAMA_MOBILE_API_VERSION (2)
} llama_mobile_version_info_t;

// Borrowed static version info; never freed.
const llama_mobile_version_info_t * llama_mobile_version(void);

// Engines selectable per context.
typedef enum llama_mobile_engine_t {
    LLAMA_MOBILE_ENGINE_AUTO,     // best available backend for the device
    LLAMA_MOBILE_ENGINE_CPU,
    LLAMA_MOBILE_ENGINE_METAL,    // Apple
    LLAMA_MOBILE_ENGINE_VULKAN,
    LLAMA_MOBILE_ENGINE_OPENCL,
} llama_mobile_engine_t;

typedef struct llama_mobile_capabilities_t {
    bool supports_vision;          // an mmproj can be attached
    bool supports_audio_input;     // audio media accepted
    bool supports_tts;             // vocoder/TTS path available
    bool supports_embeddings;
    bool supports_lora;
    uint32_t default_n_ctx;        // engine default context (0 = model)
    uint64_t available_memory_bytes; // reported device memory (0 = unknown)
    const char * device_name;      // borrowed, e.g. "Apple M-series" / "Adreno"
} llama_mobile_capabilities_t;

// Fills caps; never fails (unsupported => 0/false). Context optional.
llama_mobile_status_t llama_mobile_capabilities(llama_mobile_capabilities_t * out_caps);

// ---------------------------------------------------------------------------
// 3. Context lifecycle (one model per context; modules added separately)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_context_opaque * llama_mobile_context_t;

typedef struct llama_mobile_context_config_t {
    const char * model_path;          // required; GGUF file
    llama_mobile_engine_t engine;     // default AUTO
    int32_t n_gpu_layers;             // -1 = all, 0 = CPU, default 0
    int32_t n_ctx;                    // 0 = model default, default 2048
    int32_t n_batch;                  // default 512
    int32_t n_ubatch;                 // default 512
    int32_t n_threads;                // 0 = auto, default 0
    uint32_t flags;                   // bitmask below
    const char * kv_cache_type_k;     // NULL = f16
    const char * kv_cache_type_v;
    const char * chat_template;       // NULL = model's built-in
    const char * system_prompt;
    int32_t image_min_tokens;         // -1 = model default
    // Load progress 0..1; invoked on the loading thread; return false to abort.
    bool (*load_progress_cb)(float progress, void * user_data);
    void * load_progress_user_data;
    // Optional log sink for this context (levels below); NULL = default logger.
    void (*log_cb)(int level, const char * message, void * user_data);
    void * log_user_data;
} llama_mobile_context_config_t;

enum {
    LLAMA_MOBILE_CTX_MMAP       = 1 << 0,
    LLAMA_MOBILE_CTX_MLOCK      = 1 << 1,
    LLAMA_MOBILE_CTX_EMBEDDING  = 1 << 2,
    LLAMA_MOBILE_CTX_FLASH_ATTN = 1 << 3,
    LLAMA_MOBILE_CTX_CHAT       = 1 << 4, // enable chat template use
};
void llama_mobile_context_config_init(llama_mobile_context_config_t * config);

// Creates the context and loads the model (+ chat template). Blocking.
// Reports progress through config.load_progress_cb.
llama_mobile_status_t llama_mobile_context_create(
        const llama_mobile_context_config_t * config,
        llama_mobile_context_t * out_ctx);

// Closes the context and all modules; safe to call once (idempotent-ish: second
// call with the same pointer is a no-op because handle is set NULL by caller).
llama_mobile_status_t llama_mobile_context_destroy(llama_mobile_context_t * ctx);

// Model introspection (borrowed strings must not be freed).
typedef struct llama_mobile_model_info_t {
    int32_t  n_ctx;                 // context actually created
    int32_t  n_embd;                // embedding dim (0 if not applicable)
    int64_t  model_size_bytes;
    int64_t  n_params;
    const char * description;       // borrowed
    const char * chat_template;     // borrowed
} llama_mobile_model_info_t;
llama_mobile_status_t llama_mobile_model_info(llama_mobile_context_t ctx,
                                              llama_mobile_model_info_t * out);
// Frees the owned `description` inside `info` (chat_template is borrowed).
void llama_mobile_model_info_free(llama_mobile_model_info_t * info);

// KV context usage (0..1 fraction) — for health/UX ("context %d%% full").
typedef struct llama_mobile_context_stats_t {
    float kv_usage;                 // 0..1
    uint64_t context_bytes;         // allocated context memory (0 = unknown)
    uint64_t model_bytes;           // resident model memory (0 = unknown)
} llama_mobile_context_stats_t;
llama_mobile_status_t llama_mobile_context_stats(llama_mobile_context_t ctx,
                                                 llama_mobile_context_stats_t * out);

// ---------------------------------------------------------------------------
// 4. Media (typed multimodal input)
// ---------------------------------------------------------------------------
typedef enum llama_mobile_media_kind_t {
    LLAMA_MOBILE_MEDIA_PATH,        // const char* path in `path`
    LLAMA_MOBILE_MEDIA_URI,         // file:// or data:image/...;base64,... in `path`
    LLAMA_MOBILE_MEDIA_BYTES,       // `bytes`/`bytes_len` raw content
} llama_mobile_media_kind_t;

typedef struct llama_mobile_media_t {
    llama_mobile_media_kind_t kind;
    const char * path;              // used for PATH/URI
    const uint8_t * bytes;          // used for BYTES
    size_t bytes_len;
    const char * mime;              // optional hint, e.g. "image/jpeg"
} llama_mobile_media_t;

// Module add-on for vision/audio models (mmproj). D4: separate init call.
llama_mobile_status_t llama_mobile_multimodal_init(llama_mobile_context_t ctx,
                                                   const char * mmproj_path);
llama_mobile_status_t llama_mobile_multimodal_release(llama_mobile_context_t ctx);
bool llama_mobile_multimodal_is_enabled(llama_mobile_context_t ctx);
bool llama_mobile_multimodal_supports_vision(llama_mobile_context_t ctx);
bool llama_mobile_multimodal_supports_audio(llama_mobile_context_t ctx);

// ---------------------------------------------------------------------------
// 5. Sampling (grouped; shared by generate & chat)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_sampling_t {
    int32_t  seed;              // -1 = random
    float    temperature;       // 0 = greedy
    int32_t  top_k;             // <=0 = vocab size
    float    top_p;             // 1.0 = disabled
    float    min_p;             // 0.0 = disabled
    float    typical_p;         // 1.0 = disabled
    float    penalty_repeat;    // 1.0 = disabled
    int32_t  penalty_last_n;    // 0 = disabled
    float    penalty_freq;
    float    penalty_present;
    int32_t  mirostat;          // 0/1/2
    float    mirostat_tau;
    float    mirostat_eta;
    bool     ignore_eos;
    // optional logit biases: token->bias pairs, count = n_logit_biases
    const int32_t * logit_bias_tokens;
    const float   * logit_bias_values;
    size_t          n_logit_biases;
} llama_mobile_sampling_t;
void llama_mobile_sampling_init(llama_mobile_sampling_t * s);

// ---------------------------------------------------------------------------
// 6. Messages (structured chat; roles below) & tools (JSON strings)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_message_t {
    const char * role;          // "system" | "user" | "assistant" | "tool"
    const char * content;       // text content (may be NULL for tool results w/ name)
    const char * name;          // optional participant name
    const char * tool_name;     // assistant tool call name
    const char * tool_call_id;  // tool result id
} llama_mobile_message_t;

// ---------------------------------------------------------------------------
// 7. Generate (the one generation verb)
// ---------------------------------------------------------------------------
typedef enum llama_mobile_stop_reason_t {
    LLAMA_MOBILE_STOP_EOS,
    LLAMA_MOBILE_STOP_WORD,
    LLAMA_MOBILE_STOP_LENGTH,
    LLAMA_MOBILE_STOP_ABORTED,
    LLAMA_MOBILE_STOP_ERROR,
} llama_mobile_stop_reason_t;

typedef struct llama_mobile_generate_params_t {
    // Input: exactly one of these two is used.
    const char * prompt;                          // raw-text mode
    const llama_mobile_message_t * messages;      // chat mode
    size_t n_messages;

    llama_mobile_sampling_t sampling;             // use llama_mobile_sampling_init
    int32_t max_tokens;                           // default 128; -1 = no limit
    const char ** stop_sequences;   // NUL-terminated UTF-8 strings
    size_t n_stop_sequences;
    const char * grammar;                         // inline GBNF content
    const char * json_schema;                     // schema -> grammar internally
    const char * tools;                           // OpenAI tools JSON (optional)
    bool     parallel_tool_calls;
    const char * tool_choice;                     // "auto"|"required"|"none"|name
    const llama_mobile_media_t * media;           // multimodal inputs
    size_t n_media;
    bool     logprobs;                            // request per-token probs (Wave B; field reserved)
} llama_mobile_generate_params_t;
void llama_mobile_generate_params_init(llama_mobile_generate_params_t * p);

typedef struct llama_mobile_usage_t {
    int32_t prompt_tokens;
    int32_t generated_tokens;
    int64_t time_to_first_token_ms;
    int64_t total_ms;
} llama_mobile_usage_t;

typedef struct llama_mobile_token_prob_t {
    int32_t token;
    float   prob;
} llama_mobile_token_prob_t;

typedef struct llama_mobile_generate_result_t {
    char * text;                          // owned; free with llama_mobile_free_text
    llama_mobile_stop_reason_t stop_reason;
    llama_mobile_usage_t usage;
    // logprobs (owned arrays) — Wave B; always empty in v2.0
    llama_mobile_token_prob_t * token_probs;
    size_t n_token_probs;
} llama_mobile_generate_result_t;
void llama_mobile_generate_result_free(llama_mobile_generate_result_t * r);

// Stream callback: called once per generated token (text pieces). Return true
// to continue, false to abort (result stop_reason == ABORTED). Optional.
typedef bool (*llama_mobile_token_cb)(const char * token, void * user_data);

// request_id_out is set immediately and identifies the generation for abort();
// it is valid until the call returns. result may be NULL when streaming.
llama_mobile_status_t llama_mobile_generate(
        llama_mobile_context_t ctx,
        const llama_mobile_generate_params_t * params,
        llama_mobile_token_cb on_token,
        void * token_user_data,
        uint64_t * out_request_id,
        llama_mobile_generate_result_t * out_result);

// Aborts the generation/download identified by request_id (thread-safe; safe
// from any thread). Returns OK if a matching active request was aborted.
llama_mobile_status_t llama_mobile_abort(llama_mobile_context_t ctx,
                                         uint64_t request_id);

// ---------------------------------------------------------------------------
// 8. Embeddings (batch-capable)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_embed_result_t {
    float * values;             // n_texts rows x dim floats (row-major)
    size_t  n_texts;
    size_t  dim;
} llama_mobile_embed_result_t;
void llama_mobile_embed_result_free(llama_mobile_embed_result_t * r);

llama_mobile_status_t llama_mobile_embed(llama_mobile_context_t ctx,
                                         const char * const * texts,
                                         size_t n_texts,
                                         llama_mobile_embed_result_t * out);

// ---------------------------------------------------------------------------
// 9. Tokenize / detokenize (media-aware optional)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_tokenize_result_t {
    int32_t * tokens;           // owned
    size_t n_tokens;
    // Media chunk positions, when media was supplied (mirrors mtmd):
    size_t * media_positions;   // token indices where each media chunk starts
    size_t n_media_positions;
    bool has_media;
} llama_mobile_tokenize_result_t;
void llama_mobile_tokenize_result_free(llama_mobile_tokenize_result_t * r);

llama_mobile_status_t llama_mobile_tokenize(llama_mobile_context_t ctx,
                                            const char * text,
                                            const llama_mobile_media_t * media,
                                            size_t n_media,
                                            llama_mobile_tokenize_result_t * out);
llama_mobile_status_t llama_mobile_detokenize(llama_mobile_context_t ctx,
                                              const int32_t * tokens,
                                              size_t n_tokens,
                                              char ** out_text); // owned

// ---------------------------------------------------------------------------
// 10. LoRA (module on the context)
// ---------------------------------------------------------------------------
typedef struct llama_mobile_lora_t {
    const char * path;
    float scale;                // default 1.0
} llama_mobile_lora_t;

llama_mobile_status_t llama_mobile_lora_load(llama_mobile_context_t ctx,
                                             const llama_mobile_lora_t * adapters,
                                             size_t count);
llama_mobile_status_t llama_mobile_lora_remove(llama_mobile_context_t ctx);
// owned array, count == n
llama_mobile_status_t llama_mobile_lora_list(llama_mobile_context_t ctx,
                                             llama_mobile_lora_t ** out_adapters,
                                             size_t * out_count); // free w/ lora_list_free
void llama_mobile_lora_list_free(llama_mobile_lora_t * adapters, size_t count);

// ---------------------------------------------------------------------------
// 11. TTS (module on the context)
//
// IMPORTANT (product caution): the existing TTS workflow is customized and works;
// any change to TTS APIs or the speak pipeline is designed and reviewed together
// with that workflow (see docs/tts-current-workflow.md) before it ships.
// Wave A = init + full-text speak (returns audio); incremental PCM streaming is
// reserved (Wave B) — the pcm_cb field below is optional and unused until then.
// ---------------------------------------------------------------------------
typedef enum llama_mobile_tts_voice_t {
    LLAMA_MOBILE_TTS_VOICE_DEFAULT = 0,
} llama_mobile_tts_voice_t;

// PCM stream callback: 16-bit mono samples at sample_rate; return false to stop.
// Wave B (v2.1); reserved in v2.0.
typedef bool (*llama_mobile_pcm_cb)(const int16_t * pcm, size_t n_samples,
                                    void * user_data);

typedef struct llama_mobile_tts_params_t {
    const char * text;
    int32_t sample_rate;        // default 24000
    float speed;                // default 1.0
    llama_mobile_tts_voice_t voice;
    llama_mobile_pcm_cb pcm_cb; // Wave B; NULL in v2.0
    void * pcm_user_data;
    const char * speaker_json;  // optional speaker profile content
} llama_mobile_tts_params_t;
void llama_mobile_tts_params_init(llama_mobile_tts_params_t * p);

// Full-text synthesis: text -> 16-bit PCM (returns audio on `out`); speaker
// profile, sample rate and speed honored. Same workflow as today's wrapper TTS.
llama_mobile_status_t llama_mobile_tts_init(llama_mobile_context_t ctx,
                                            const char * vocoder_model_path);
llama_mobile_status_t llama_mobile_tts_speak(llama_mobile_context_t ctx,
                                             const llama_mobile_tts_params_t * params,
                                             llama_mobile_usage_t * out_usage,
                                             int16_t ** out_pcm, size_t * out_pcm_len);
void llama_mobile_tts_pcm_free(int16_t * pcm);
llama_mobile_status_t llama_mobile_tts_release(llama_mobile_context_t ctx);
bool llama_mobile_tts_is_enabled(llama_mobile_context_t ctx);

// ---------------------------------------------------------------------------
// 12. Download manager + model registry
// ---------------------------------------------------------------------------
typedef enum llama_mobile_download_state_t {
    LLAMA_MOBILE_DL_QUEUED,
    LLAMA_MOBILE_DL_RUNNING,
    LLAMA_MOBILE_DL_DONE,
    LLAMA_MOBILE_DL_FAILED,
    LLAMA_MOBILE_DL_CANCELLED,
} llama_mobile_download_state_t;

typedef struct llama_mobile_download_request_t {
    const char * url_or_repo;   // direct URL or "owner/repo"
    const char * filename;      // repo file (ignored for direct URLs)
    const char * revision;      // HF revision (default "main"); NULL ok
    const char * destination_dir;   // required
    const char * bearer_token;  // optional
    bool resume;                // resume partial file if present
    const char * checksum_sha256; // optional verification
} llama_mobile_download_request_t;

typedef struct llama_mobile_download_event_t {
    uint64_t request_id;
    llama_mobile_download_state_t state;
    float progress;                 // 0..1 (bytes when total known)
    int64_t downloaded_bytes;
    int64_t total_bytes;            // -1 unknown
    const char * message;           // borrowed detail (error text when failed)
} llama_mobile_download_event_t;

typedef void (*llama_mobile_download_cb)(const llama_mobile_download_event_t * ev,
                                         void * user_data);

llama_mobile_status_t llama_mobile_download_start(
        const llama_mobile_download_request_t * req,
        llama_mobile_download_cb cb, void * cb_user_data,
        uint64_t * out_request_id);
llama_mobile_status_t llama_mobile_download_cancel(uint64_t request_id);

// Model registry (downloaded/imported models on the device).
typedef struct llama_mobile_model_entry_t {
    const char * name;          // borrowed registry name
    const char * path;          // borrowed absolute path
    int64_t size_bytes;
} llama_mobile_model_entry_t;
llama_mobile_status_t llama_mobile_models_list(llama_mobile_model_entry_t ** out,
                                               size_t * out_count); // free w/ models_list_free
void llama_mobile_models_list_free(llama_mobile_model_entry_t * entries, size_t count);
llama_mobile_status_t llama_mobile_models_remove(const char * name);
llama_mobile_status_t llama_mobile_models_verify(const char * path,
                                                 const char * expected_sha256);

// ---------------------------------------------------------------------------
// 13. Logging (levels consistent across SDKs) & ownership helpers
// ---------------------------------------------------------------------------
enum {
    LLAMA_MOBILE_LOG_DEBUG = 0,
    LLAMA_MOBILE_LOG_INFO,
    LLAMA_MOBILE_LOG_WARN,
    LLAMA_MOBILE_LOG_ERROR,
    LLAMA_MOBILE_LOG_NONE,
};
llama_mobile_status_t llama_mobile_log_set_level(int level);
// Register a process-wide log callback (NULL restores the default logger).
typedef void (*llama_mobile_log_cb)(int level, const char * message, void * user_data);
llama_mobile_status_t llama_mobile_log_set_callback(llama_mobile_log_cb cb,
                                                    void * user_data);

void llama_mobile_free_text(char * text);                 // frees owned char*
// (module result free helpers are declared next to their result types above)

#ifdef __cplusplus
}
#endif

#endif // LLAMA_MOBILE_V2_H
