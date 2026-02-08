#ifndef LLAMA_MOBILE_FFI_H
#define LLAMA_MOBILE_FFI_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#if defined _WIN32 || defined __CYGWIN__
  #ifdef LLAMA_MOBILE_FFI_BUILDING_DLL
    #ifdef __GNUC__
      #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((dllexport))
    #else
      #define LLAMA_MOBILE_FFI_EXPORT __declspec(dllexport)
    #endif
  #else
    #ifdef __GNUC__
      #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((dllimport))
    #else
      #define LLAMA_MOBILE_FFI_EXPORT __declspec(dllimport)
    #endif
  #endif
  #define LLAMA_MOBILE_FFI_LOCAL
#else
  #if __GNUC__ >= 4
    #define LLAMA_MOBILE_FFI_EXPORT __attribute__ ((visibility ("default")))
    #define LLAMA_MOBILE_FFI_LOCAL  __attribute__ ((visibility ("hidden")))
  #else
    #define LLAMA_MOBILE_FFI_EXPORT
    #define LLAMA_MOBILE_FFI_LOCAL
  #endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct llama_mobile_context_opaque* llama_mobile_context_handle_t;


typedef struct llama_mobile_init_params_c {
    const char* model_path;
    const char* chat_template; 
    const char* system_prompt;

    int32_t n_ctx;
    int32_t n_batch;
    int32_t n_ubatch;
    int32_t n_gpu_layers;
    int32_t n_threads;
    bool use_mmap;
    bool use_mlock;
    bool embedding; 
    int32_t pooling_type; 
    int32_t embd_normalize;
    bool flash_attn;
    const char* cache_type_k; 
    const char* cache_type_v; 
    void (*progress_callback)(float progress, void* user_data); 
    void* progress_callback_user_data;
    bool enable_chat_template;
    int32_t image_min_tokens;
} llama_mobile_init_params_c_t;

// Chat message structure for structured input
typedef struct llama_mobile_chat_message_c {
    const char* role;
    const char* content;
    const char* reasoning_content;  // For reasoning/thinking content (optional, NULL if not present)
    const char* tool_name;         // For tool calls (optional, NULL if not present)
    const char* tool_call_id;      // For tool call IDs (optional, NULL if not present)
} llama_mobile_chat_message_c;

typedef struct llama_mobile_completion_params_c {
    const char* prompt;
    int32_t n_predict; 
    int32_t n_threads; 
    int32_t seed;
    double temperature;
    int32_t top_k;
    double top_p;
    double min_p;
    double typical_p;
    int32_t penalty_last_n;
    double penalty_repeat;
    double penalty_freq;
    double penalty_present;
    int32_t mirostat;
    double mirostat_tau;
    double mirostat_eta;
    bool ignore_eos;
    int32_t n_probs; 
    const char** stop_sequences; 
    int stop_sequence_count;
    const char* grammar; 
    bool (*token_callback)(const char* token_json, void* user_data);
    void* token_callback_user_data;
    
    // New fields for chat support
    const llama_mobile_chat_message_c* chat_messages;
    int32_t chat_message_count;
    bool use_json_response;
    
    // Advanced parameters for Jinja template engine
    const char* json_schema;       // JSON schema for structured output
    const char* tools;            // JSON string defining available tools for function calling
    bool parallel_tool_calls;  // Whether to support parallel tool calls
    const char* tool_choice;       // Tool choice strategy (auto, required, none, or specific tool)

} llama_mobile_completion_params_c_t;


typedef struct llama_mobile_token_array_c {
    int32_t* tokens;
    int32_t count;
} llama_mobile_token_array_c_t;

typedef struct llama_mobile_float_array_c {
    float* values;
    int32_t count;
} llama_mobile_float_array_c_t;

typedef struct llama_mobile_completion_result_c {
    char* text; 
    int32_t tokens_predicted;
    int32_t tokens_evaluated;
    bool truncated;
    bool stopped_eos;
    bool stopped_word;
    bool stopped_limit;
    char* stopping_word; 
} llama_mobile_completion_result_c_t;

typedef struct llama_mobile_tokenize_result_c {
    llama_mobile_token_array_c_t tokens;
    bool has_media;
    char** bitmap_hashes;
    int bitmap_hash_count;
    size_t* chunk_positions;
    int chunk_position_count;
    size_t* chunk_positions_media;
    int chunk_position_media_count;
} llama_mobile_tokenize_result_c_t;

LLAMA_MOBILE_FFI_EXPORT llama_mobile_context_handle_t llama_mobile_init_context_c(const llama_mobile_init_params_c_t* params);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_context_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT int llama_mobile_completion_c(
    llama_mobile_context_handle_t handle,
    const llama_mobile_completion_params_c_t* params,
    llama_mobile_completion_result_c_t* result
);

// **MULTIMODAL COMPLETION**
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_multimodal_completion_c(
    llama_mobile_context_handle_t handle,
    const llama_mobile_completion_params_c_t* params,
    const char** media_paths,
    int media_count,
    llama_mobile_completion_result_c_t* result
);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_stop_completion_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT llama_mobile_token_array_c_t llama_mobile_tokenize_c(llama_mobile_context_handle_t handle, const char* text);

LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_detokenize_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

LLAMA_MOBILE_FFI_EXPORT llama_mobile_float_array_c_t llama_mobile_embedding_c(llama_mobile_context_handle_t handle, const char* text);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_string_c(char* str);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_token_array_c(llama_mobile_token_array_c_t arr);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_float_array_c(llama_mobile_float_array_c_t arr);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_completion_result_members_c(llama_mobile_completion_result_c_t* result);

LLAMA_MOBILE_FFI_EXPORT llama_mobile_tokenize_result_c_t llama_mobile_tokenize_with_media_c(llama_mobile_context_handle_t handle, const char* text, const char** media_paths, int media_count);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_tokenize_result_c(llama_mobile_tokenize_result_c_t* result);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_set_guide_tokens_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

LLAMA_MOBILE_FFI_EXPORT int llama_mobile_init_multimodal_c(llama_mobile_context_handle_t handle, const char* mmproj_path, bool use_gpu);

LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_multimodal_enabled_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_supports_vision_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_supports_audio_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_release_multimodal_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT int llama_mobile_init_vocoder_c(llama_mobile_context_handle_t handle, const char* vocoder_model_path);

LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_vocoder_enabled_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT int llama_mobile_get_tts_type_c(llama_mobile_context_handle_t handle);

LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_formatted_audio_completion_c(llama_mobile_context_handle_t handle, const char* speaker_json_str, const char* text_to_speak);

LLAMA_MOBILE_FFI_EXPORT llama_mobile_token_array_c_t llama_mobile_get_audio_guide_tokens_c(llama_mobile_context_handle_t handle, const char* text_to_speak);

LLAMA_MOBILE_FFI_EXPORT llama_mobile_float_array_c_t llama_mobile_decode_audio_tokens_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_save_audio_to_wav_c(llama_mobile_context_handle_t handle, const char* file_path, const float* audio_data, int32_t count, int32_t sample_rate);

LLAMA_MOBILE_FFI_EXPORT void llama_mobile_release_vocoder_c(llama_mobile_context_handle_t handle);

// **HIGH PRIORITY ADDITIONS**

// Get the model's built-in chat template
LLAMA_MOBILE_FFI_EXPORT const char* llama_mobile_get_model_chat_template_c(llama_mobile_context_handle_t handle);

typedef struct {
    const char* path;
    float scale;
} llama_mobile_lora_adapter_c_t;

typedef struct {
    llama_mobile_lora_adapter_c_t* adapters;
    int32_t count;
} llama_mobile_lora_adapters_c_t;

typedef struct {
    char* model_name;
    int64_t model_size;
    int64_t model_params;
    double pp_avg;
    double pp_std;
    double tg_avg;
    double tg_std;
} llama_mobile_bench_result_c_t;

typedef struct {
    char* text;
    int64_t time_to_first_token; // milliseconds
    int64_t total_time; // milliseconds
    int32_t tokens_generated;
} llama_mobile_conversation_result_c_t;

// **HIGH PRIORITY: Model Download Support**

// Download progress callback type
typedef void (*llama_mobile_download_progress_callback)(float progress, const char* status, int64_t downloaded_bytes, int64_t total_bytes, void* user_data);

// Download result structure
typedef struct {
    bool success;
    char* local_path;
    char* error_message;
    int64_t file_size;
} llama_mobile_download_result_c_t;

// Download parameters structure
typedef struct {
    const char* repo_id;
    const char* filename;
    const char* destination_path;
    const char* bearer_token;
    bool offline;
    llama_mobile_download_progress_callback progress_callback;
    void* progress_callback_user_data;
} llama_mobile_download_params_c_t;

// **HIGH PRIORITY: Benchmarking**
LLAMA_MOBILE_FFI_EXPORT llama_mobile_bench_result_c_t llama_mobile_bench_c(llama_mobile_context_handle_t handle, int pp, int tg, int pl, int nr);

// **HIGH PRIORITY: LoRA Adapter Support**
/**
 * @brief Apply LoRA adapters to the model.
 * 
 * @param handle Handle to the initialized context.
 * @param adapters Array of LoRA adapter configurations.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_apply_lora_adapters_c(llama_mobile_context_handle_t handle, const llama_mobile_lora_adapters_c_t* adapters);

/**
 * @brief Remove all loaded LoRA adapters.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_remove_lora_adapters_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the currently loaded LoRA adapters.
 * 
 * @param handle Handle to the initialized context.
 * @return Array of loaded LoRA adapter configurations. The result should be freed using
 *         llama_mobile_free_lora_adapters_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_lora_adapters_c_t llama_mobile_get_loaded_lora_adapters_c(llama_mobile_context_handle_t handle);

// **HIGH PRIORITY: Chat Template Support**
/**
 * @brief Validate if a chat template is compatible with the loaded model.
 * 
 * @param handle Handle to the initialized context.
 * @param use_jinja Whether to use Jinja templates.
 * @param name Name of the chat template to validate.
 * @return True if the template is compatible, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_validate_chat_template_c(llama_mobile_context_handle_t handle, bool use_jinja, const char* name);

/**
 * @brief Format chat messages using a specified chat template.
 * 
 * @param handle Handle to the initialized context.
 * @param messages JSON string containing chat messages.
 * @param chat_template Name of the chat template to use.
 * @return Formatted chat string. Must be freed using llama_mobile_free_string_c().
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_formatted_chat_c(llama_mobile_context_handle_t handle, const char* messages, const char* chat_template);

// **ADVANCED: Chat with Jinja and Tools Support**
typedef struct {
    char* prompt;
    char* json_schema;
    char* tools;
    char* tool_choice;
    bool parallel_tool_calls;
} llama_mobile_chat_result_c_t;

/**
 * @brief Format chat messages with Jinja templates and tools support.
 * 
 * @param handle Handle to the initialized context.
 * @param messages JSON string containing chat messages.
 * @param chat_template Name of the Jinja chat template to use.
 * @param json_schema JSON schema for structured outputs.
 * @param tools JSON string defining available tools.
 * @param parallel_tool_calls Whether to support parallel tool calls.
 * @param tool_choice Tool choice strategy.
 * @return Chat result structure with formatted prompt and tool information. The result's fields
 *         should be freed using llama_mobile_free_string_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_chat_result_c_t llama_mobile_get_formatted_chat_with_jinja_c(
    llama_mobile_context_handle_t handle, 
    const char* messages,
    const char* chat_template,
    const char* json_schema,
    const char* tools,
    bool parallel_tool_calls,
    const char* tool_choice
);

// **HIGH PRIORITY: Context Management**
/**
 * @brief Rewind the context to the beginning of the current conversation.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_rewind_c(llama_mobile_context_handle_t handle);

/**
 * @brief Initialize sampling parameters and context.
 * 
 * @param handle Handle to the initialized context.
 * @return true on success, false on failure.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_init_sampling_c(llama_mobile_context_handle_t handle);

// **COMPLETION CONTROL**
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_begin_completion_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_end_completion_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_load_prompt_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_load_prompt_with_media_c(llama_mobile_context_handle_t handle, const char** media_paths, int media_count);

// **TOKEN PROCESSING** (INTERNAL)
int llama_mobile_do_completion_step_c(llama_mobile_context_handle_t handle, char** token_text);
size_t llama_mobile_find_stopping_strings_c(llama_mobile_context_handle_t handle, const char* text, size_t last_token_size, int stop_type);

// **HIGH PRIORITY: Model Information**
LLAMA_MOBILE_FFI_EXPORT int32_t llama_mobile_get_n_ctx_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT int32_t llama_mobile_get_n_embd_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_model_desc_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT int64_t llama_mobile_get_model_size_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT int64_t llama_mobile_get_model_params_c(llama_mobile_context_handle_t handle);

// **CONVERSATION MANAGEMENT**
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_generate_response_c(llama_mobile_context_handle_t handle, const char* user_message, int32_t max_tokens);
LLAMA_MOBILE_FFI_EXPORT llama_mobile_conversation_result_c_t llama_mobile_continue_conversation_c(llama_mobile_context_handle_t handle, const char* user_message, int32_t max_tokens);
LLAMA_MOBILE_FFI_EXPORT llama_mobile_conversation_result_c_t llama_mobile_continue_conversation_with_callback_c(llama_mobile_context_handle_t handle, const char* user_message, int32_t max_tokens, bool (*token_callback)(const char* token, void* user_data), void* token_callback_user_data);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_clear_conversation_c(llama_mobile_context_handle_t handle);
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_conversation_active_c(llama_mobile_context_handle_t handle);

// **HIGH PRIORITY: Model Download Functions**
LLAMA_MOBILE_FFI_EXPORT llama_mobile_download_result_c_t llama_mobile_download_model_c(const llama_mobile_download_params_c_t* params);
LLAMA_MOBILE_FFI_EXPORT llama_mobile_download_result_c_t llama_mobile_download_hf_file_c(const char* repo_id, const char* filename, const char* destination_path, const char* bearer_token, bool offline, llama_mobile_download_progress_callback progress_callback, void* progress_callback_user_data);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_download_result_c(llama_mobile_download_result_c_t* result);

// Memory management functions
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_bench_result_members_c(llama_mobile_bench_result_c_t* result);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_lora_adapters_c(llama_mobile_lora_adapters_c_t* adapters);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_chat_result_members_c(llama_mobile_chat_result_c_t* result);
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_conversation_result_members_c(llama_mobile_conversation_result_c_t* result);

#ifdef __cplusplus
}
#endif

#endif