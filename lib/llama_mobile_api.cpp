#include "llama_mobile_api.h"
#include "llama_mobile_ffi.h"

#include <cstring>

// Helper function to convert API params to FFI params
static llama_mobile_init_params_c_t convert_init_params(const llama_mobile_init_params_t* api_params) {
    llama_mobile_init_params_c_t ffi_params = {0};
    
    if (api_params) {
        ffi_params.model_path = api_params->model_path;
        ffi_params.chat_template = api_params->chat_template;
        ffi_params.n_ctx = api_params->n_ctx;
        ffi_params.n_batch = api_params->n_batch;
        ffi_params.n_ubatch = (api_params->n_batch > 0) ? api_params->n_batch : 512; // Set n_ubatch to match n_batch or default
        ffi_params.n_gpu_layers = api_params->n_gpu_layers;
        ffi_params.n_threads = api_params->n_threads;
        ffi_params.use_mmap = api_params->use_mmap;
        ffi_params.use_mlock = api_params->use_mlock;
        ffi_params.embedding = api_params->embedding;
        ffi_params.progress_callback = api_params->progress_callback;
        ffi_params.cache_type_k = api_params->cache_type_k;
        ffi_params.cache_type_v = api_params->cache_type_v;
    }
    
    return ffi_params;
}

// Helper function to convert API completion params to FFI completion params
static llama_mobile_completion_params_c_t convert_completion_params(const llama_mobile_completion_params_t* api_params) {
    llama_mobile_completion_params_c_t ffi_params = {0};
    
    if (api_params) {
        ffi_params.prompt = api_params->prompt;
        ffi_params.n_predict = api_params->max_tokens;
        ffi_params.temperature = api_params->temperature;
        ffi_params.top_k = api_params->top_k;
        ffi_params.top_p = api_params->top_p;
        ffi_params.min_p = api_params->min_p;
        ffi_params.penalty_repeat = api_params->penalty_repeat;
        ffi_params.stop_sequences = api_params->stop_sequences;
        ffi_params.stop_sequence_count = api_params->stop_sequence_count;
        ffi_params.token_callback = api_params->token_callback;
    }
    
    return ffi_params;
}

// Helper function to convert FFI completion result to API completion result
static void convert_completion_result(const llama_mobile_completion_result_c_t* ffi_result, llama_mobile_completion_result_t* api_result) {
    if (ffi_result && api_result) {
        api_result->text = ffi_result->text;
        api_result->tokens_generated = ffi_result->tokens_predicted;
        api_result->tokens_evaluated = ffi_result->tokens_evaluated;
        api_result->truncated = ffi_result->truncated;
        api_result->stopped_eos = ffi_result->stopped_eos;
        api_result->stopped_word = ffi_result->stopped_word;
        api_result->stopped_limit = ffi_result->stopped_limit;
    }
}

// Helper function to convert FFI token array to API token array
static llama_mobile_token_array_t convert_token_array(llama_mobile_token_array_c_t ffi_array) {
    llama_mobile_token_array_t api_array = {0};
    api_array.tokens = ffi_array.tokens;
    api_array.count = ffi_array.count;
    return api_array;
}

// Helper function to convert FFI float array to API float array
static llama_mobile_float_array_t convert_float_array(llama_mobile_float_array_c_t ffi_array) {
    llama_mobile_float_array_t api_array = {0};
    api_array.values = ffi_array.values;
    api_array.count = ffi_array.count;
    return api_array;
}

// Helper function to convert FFI conversation result to API conversation result
static void convert_conversation_result(const llama_mobile_conversation_result_c_t* ffi_result, llama_mobile_conversation_result_t* api_result) {
    if (ffi_result && api_result) {
        api_result->text = ffi_result->text;
        api_result->time_to_first_token = ffi_result->time_to_first_token;
        api_result->total_time = ffi_result->total_time;
        api_result->tokens_generated = ffi_result->tokens_generated;
    }
}

#ifdef __cplusplus
extern "C" {
#endif

LLAMA_MOBILE_API llama_mobile_context_t llama_mobile_init(const llama_mobile_init_params_t* params) {
    llama_mobile_init_params_c_t ffi_params = convert_init_params(params);
    return (llama_mobile_context_t) llama_mobile_init_context_c(&ffi_params);
}

LLAMA_MOBILE_API llama_mobile_context_t llama_mobile_init_simple(
    const char* model_path,
    int32_t n_ctx,
    int32_t n_gpu_layers,
    int32_t n_threads,
    void (*progress_callback)(float progress)) {
    
    if (!model_path) {
        return nullptr;
    }
    
    llama_mobile_init_params_t params = {0};
    params.model_path = model_path;
    params.n_ctx = (n_ctx > 0) ? n_ctx : 2048;  // Default 2048
    params.n_gpu_layers = n_gpu_layers;
    params.n_threads = (n_threads > 0) ? n_threads : 4;  // Default 4
    params.progress_callback = progress_callback;
    params.embedding = false;  // Disable embedding mode for simple init
    params.use_mmap = true;  // Sensible defaults
    params.n_batch = 512;  // Set n_batch which will be used for n_ubatch in convert_init_params
    
    return llama_mobile_init(&params);
}

LLAMA_MOBILE_API void llama_mobile_free(llama_mobile_context_t ctx) {
    llama_mobile_free_context_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API int llama_mobile_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    llama_mobile_completion_result_t* result) {
    
    if (!ctx || !params || !result) {
        return -1;
    }
    
    llama_mobile_completion_params_c_t ffi_params = convert_completion_params(params);
    llama_mobile_completion_result_c_t ffi_result = {0};
    
    int status = llama_mobile_completion_c(
        (llama_mobile_context_handle_t) ctx,
        &ffi_params,
        &ffi_result);
    
    if (status == 0) {
        convert_completion_result(&ffi_result, result);
    }
    
    return status;
}

LLAMA_MOBILE_API int llama_mobile_completion_simple(
    llama_mobile_context_t ctx,
    const char* prompt,
    int32_t max_tokens,
    double temperature,
    bool (*token_callback)(const char* token),
    llama_mobile_completion_result_t* result) {
    
    if (!ctx || !prompt || !result) {
        return -1;
    }
    
    llama_mobile_completion_params_t params = {0};
    params.prompt = prompt;
    params.max_tokens = (max_tokens > 0) ? max_tokens : 128;  // Default 128
    params.temperature = (temperature >= 0.0) ? temperature : 0.8;  // Default 0.8
    params.token_callback = token_callback;
    
    // Set sensible defaults for other sampling parameters
    params.top_k = 40;
    params.top_p = 0.95;
    params.min_p = 0.05;
    params.penalty_repeat = 1.1;
    
    return llama_mobile_completion(ctx, &params, result);
}

LLAMA_MOBILE_API int llama_mobile_multimodal_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    const char** media_paths,
    int media_count,
    llama_mobile_completion_result_t* result) {
    
    if (!ctx || !params || !result) {
        return -1;
    }
    
    llama_mobile_completion_params_c_t ffi_params = convert_completion_params(params);
    llama_mobile_completion_result_c_t ffi_result = {0};
    
    int status = llama_mobile_multimodal_completion_c(
        (llama_mobile_context_handle_t) ctx,
        &ffi_params,
        media_paths,
        media_count,
        &ffi_result);
    
    if (status == 0) {
        convert_completion_result(&ffi_result, result);
    }
    
    return status;
}

LLAMA_MOBILE_API void llama_mobile_stop_completion(llama_mobile_context_t ctx) {
    llama_mobile_stop_completion_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API llama_mobile_token_array_t llama_mobile_tokenize(
    llama_mobile_context_t ctx,
    const char* text) {
    
    llama_mobile_token_array_c_t ffi_result = llama_mobile_tokenize_c(
        (llama_mobile_context_handle_t) ctx,
        text);
    
    return convert_token_array(ffi_result);
}

LLAMA_MOBILE_API char* llama_mobile_detokenize(
    llama_mobile_context_t ctx,
    const int32_t* tokens,
    int32_t count) {
    
    return llama_mobile_detokenize_c(
        (llama_mobile_context_handle_t) ctx,
        tokens,
        count);
}

LLAMA_MOBILE_API llama_mobile_float_array_t llama_mobile_embedding(
    llama_mobile_context_t ctx,
    const char* text) {
    
    llama_mobile_float_array_c_t ffi_result = llama_mobile_embedding_c(
        (llama_mobile_context_handle_t) ctx,
        text);
    
    return convert_float_array(ffi_result);
}

LLAMA_MOBILE_API int llama_mobile_apply_lora_adapters(
    llama_mobile_context_t ctx,
    const llama_mobile_lora_adapter_t* adapters,
    int count) {
    
    if (!ctx || !adapters || count <= 0) {
        return -1;
    }
    
    llama_mobile_lora_adapters_c_t ffi_adapters = {0};
    ffi_adapters.adapters = (llama_mobile_lora_adapter_c_t*) adapters;
    ffi_adapters.count = count;
    
    return llama_mobile_apply_lora_adapters_c(
        (llama_mobile_context_handle_t) ctx,
        &ffi_adapters);
}

LLAMA_MOBILE_API void llama_mobile_remove_lora_adapters(llama_mobile_context_t ctx) {
    llama_mobile_remove_lora_adapters_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API int llama_mobile_init_multimodal(
    llama_mobile_context_t ctx,
    const char* mmproj_path,
    bool use_gpu) {
    
    return llama_mobile_init_multimodal_c(
        (llama_mobile_context_handle_t) ctx,
        mmproj_path,
        use_gpu);
}

LLAMA_MOBILE_API int llama_mobile_init_multimodal_simple(
    llama_mobile_context_t ctx,
    const char* mmproj_path) {
    
    if (!ctx || !mmproj_path) {
        return -1;
    }
    
    // Use GPU acceleration by default for multimodal processing
    return llama_mobile_init_multimodal(ctx, mmproj_path, true);
}

LLAMA_MOBILE_API bool llama_mobile_is_multimodal_enabled(llama_mobile_context_t ctx) {
    return llama_mobile_is_multimodal_enabled_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API void llama_mobile_release_multimodal(llama_mobile_context_t ctx) {
    llama_mobile_release_multimodal_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API int llama_mobile_generate_response(
    llama_mobile_context_t ctx,
    const char* user_message,
    int32_t max_tokens,
    llama_mobile_conversation_result_t* result) {
    
    if (!ctx || !user_message || !result) {
        return -1;
    }
    
    llama_mobile_conversation_result_c_t ffi_result = llama_mobile_continue_conversation_c(
        (llama_mobile_context_handle_t) ctx,
        user_message,
        max_tokens);
    
    convert_conversation_result(&ffi_result, result);
    return 0;
}

LLAMA_MOBILE_API int llama_mobile_generate_response_simple(
    llama_mobile_context_t ctx,
    const char* user_message,
    int32_t max_tokens,
    llama_mobile_conversation_result_t* result) {
    
    if (!ctx || !user_message || !result) {
        return -1;
    }
    
    // Use default max_tokens if not specified
    int32_t tokens_to_generate = (max_tokens > 0) ? max_tokens : 128;
    
    return llama_mobile_generate_response(ctx, user_message, tokens_to_generate, result);
}

LLAMA_MOBILE_API void llama_mobile_clear_conversation(llama_mobile_context_t ctx) {
    llama_mobile_clear_conversation_c((llama_mobile_context_handle_t) ctx);
}

LLAMA_MOBILE_API void llama_mobile_free_string(char* str) {
    llama_mobile_free_string_c(str);
}

LLAMA_MOBILE_API void llama_mobile_free_token_array(llama_mobile_token_array_t arr) {
    llama_mobile_token_array_c_t ffi_arr = {0};
    ffi_arr.tokens = arr.tokens;
    ffi_arr.count = arr.count;
    llama_mobile_free_token_array_c(ffi_arr);
}

LLAMA_MOBILE_API void llama_mobile_free_float_array(llama_mobile_float_array_t arr) {
    llama_mobile_float_array_c_t ffi_arr = {0};
    ffi_arr.values = arr.values;
    ffi_arr.count = arr.count;
    llama_mobile_free_float_array_c(ffi_arr);
}

LLAMA_MOBILE_API void llama_mobile_free_completion_result(llama_mobile_completion_result_t* result) {
    if (result) {
        llama_mobile_completion_result_c_t ffi_result = {0};
        ffi_result.text = result->text;
        llama_mobile_free_completion_result_members_c(&ffi_result);
        result->text = nullptr;
    }
}

LLAMA_MOBILE_API void llama_mobile_free_conversation_result(llama_mobile_conversation_result_t* result) {
    if (result) {
        llama_mobile_conversation_result_c_t ffi_result = {0};
        ffi_result.text = result->text;
        llama_mobile_free_conversation_result_members_c(&ffi_result);
        result->text = nullptr;
    }
}

#ifdef __cplusplus
}
#endif