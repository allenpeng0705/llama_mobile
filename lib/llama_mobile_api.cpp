#include "llama_mobile_api.h"
#include "llama_mobile_ffi.h"

#include <cstring>

// Helper function to convert API params to FFI params
static llama_mobile_init_params_c_t convert_init_params(const llama_mobile_init_params_t* api_params) {
    llama_mobile_init_params_c_t ffi_params = {0};
    
    if (api_params) {
        ffi_params.model_path = api_params->model_path;
        ffi_params.chat_template = api_params->chat_template;
        ffi_params.system_prompt = api_params->system_prompt;
        ffi_params.n_ctx = api_params->n_ctx;
        ffi_params.n_batch = api_params->n_batch;
        ffi_params.n_ubatch = (api_params->n_batch > 0) ? api_params->n_batch : 512; // Set n_ubatch to match n_batch or default
        ffi_params.n_gpu_layers = api_params->n_gpu_layers;
        ffi_params.n_threads = api_params->n_threads;
        ffi_params.use_mmap = api_params->use_mmap;
        ffi_params.use_mlock = api_params->use_mlock;
        ffi_params.embedding = api_params->embedding;
        ffi_params.pooling_type = api_params->pooling_type;
        ffi_params.embd_normalize = api_params->embd_normalize;
        ffi_params.flash_attn = api_params->flash_attn;
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
        ffi_params.n_predict = api_params->n_predict;
        ffi_params.n_threads = api_params->n_threads;
        ffi_params.seed = api_params->seed;
        ffi_params.temperature = api_params->temperature;
        ffi_params.top_k = api_params->top_k;
        ffi_params.top_p = api_params->top_p;
        ffi_params.min_p = api_params->min_p;
        ffi_params.typical_p = api_params->typical_p;
        ffi_params.penalty_last_n = api_params->penalty_last_n;
        ffi_params.penalty_repeat = api_params->penalty_repeat;
        ffi_params.penalty_freq = api_params->penalty_freq;
        ffi_params.penalty_present = api_params->penalty_present;
        ffi_params.mirostat = api_params->mirostat;
        ffi_params.mirostat_tau = api_params->mirostat_tau;
        ffi_params.mirostat_eta = api_params->mirostat_eta;
        ffi_params.ignore_eos = api_params->ignore_eos;
        ffi_params.n_probs = api_params->n_probs;
        ffi_params.stop_sequences = api_params->stop_sequences;
        ffi_params.stop_sequence_count = api_params->stop_sequence_count;
        ffi_params.grammar = api_params->grammar;
        ffi_params.token_callback = api_params->token_callback;
        
        // New fields for chat support
        ffi_params.chat_messages = api_params->chat_messages;
        ffi_params.chat_message_count = api_params->chat_message_count;
        ffi_params.use_json_response = api_params->use_json_response;
        
        // Advanced parameters for Jinja template engine
        ffi_params.json_schema = api_params->json_schema;
        ffi_params.tools = api_params->tools;
        ffi_params.parallel_tool_calls = api_params->parallel_tool_calls;
        ffi_params.tool_choice = api_params->tool_choice;
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

llama_mobile_context_t llama_mobile_init(const llama_mobile_init_params_t* params) {
    llama_mobile_init_params_c_t ffi_params = convert_init_params(params);
    return (llama_mobile_context_t) llama_mobile_init_context_c(&ffi_params);
}



void llama_mobile_free(llama_mobile_context_t ctx) {
    llama_mobile_free_context_c((llama_mobile_context_handle_t) ctx);
}

int llama_mobile_completion(
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



int llama_mobile_multimodal_completion(
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

void llama_mobile_stop_completion(llama_mobile_context_t ctx) {
    llama_mobile_stop_completion_c((llama_mobile_context_handle_t) ctx);
}

llama_mobile_token_array_t llama_mobile_tokenize(
    llama_mobile_context_t ctx,
    const char* text) {
    
    llama_mobile_token_array_c_t ffi_result = llama_mobile_tokenize_c(
        (llama_mobile_context_handle_t) ctx,
        text);
    
    return convert_token_array(ffi_result);
}

char* llama_mobile_detokenize(
    llama_mobile_context_t ctx,
    const int32_t* tokens,
    int32_t count) {
    
    return llama_mobile_detokenize_c(
        (llama_mobile_context_handle_t) ctx,
        tokens,
        count);
}

llama_mobile_float_array_t llama_mobile_embedding(
    llama_mobile_context_t ctx,
    const char* text) {
    
    llama_mobile_float_array_c_t ffi_result = llama_mobile_embedding_c(
        (llama_mobile_context_handle_t) ctx,
        text);
    
    return convert_float_array(ffi_result);
}

int llama_mobile_apply_lora_adapters(
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

void llama_mobile_remove_lora_adapters(llama_mobile_context_t ctx) {
    llama_mobile_remove_lora_adapters_c((llama_mobile_context_handle_t) ctx);
}

int llama_mobile_init_multimodal(
    llama_mobile_context_t ctx,
    const char* mmproj_path,
    bool use_gpu) {
    
    return llama_mobile_init_multimodal_c(
        (llama_mobile_context_handle_t) ctx,
        mmproj_path,
        use_gpu);
}



bool llama_mobile_is_multimodal_enabled(llama_mobile_context_t ctx) {
    return llama_mobile_is_multimodal_enabled_c((llama_mobile_context_handle_t) ctx);
}

void llama_mobile_release_multimodal(llama_mobile_context_t ctx) {
    llama_mobile_release_multimodal_c((llama_mobile_context_handle_t) ctx);
}

int llama_mobile_generate_response(
    llama_mobile_context_t ctx,
    const char* user_message,
    int32_t max_tokens,
    bool (*token_callback)(const char* token),
    llama_mobile_conversation_result_t* result) {
    
    if (!ctx || !user_message || !result) {
        return -1;
    }
    
    llama_mobile_conversation_result_c_t ffi_result;
    
    if (token_callback != nullptr) {
        ffi_result = llama_mobile_continue_conversation_with_callback_c(
            (llama_mobile_context_handle_t) ctx,
            user_message,
            max_tokens,
            token_callback);
    } else {
        ffi_result = llama_mobile_continue_conversation_c(
            (llama_mobile_context_handle_t) ctx,
            user_message,
            max_tokens);
    }
    
    convert_conversation_result(&ffi_result, result);
    return 0;
}



void llama_mobile_clear_conversation(llama_mobile_context_t ctx) {
    llama_mobile_clear_conversation_c((llama_mobile_context_handle_t) ctx);
}

void llama_mobile_free_string(char* str) {
    llama_mobile_free_string_c(str);
}

void llama_mobile_free_token_array(llama_mobile_token_array_t arr) {
    llama_mobile_token_array_c_t ffi_arr = {0};
    ffi_arr.tokens = arr.tokens;
    ffi_arr.count = arr.count;
    llama_mobile_free_token_array_c(ffi_arr);
}

void llama_mobile_free_float_array(llama_mobile_float_array_t arr) {
    llama_mobile_float_array_c_t ffi_arr = {0};
    ffi_arr.values = arr.values;
    ffi_arr.count = arr.count;
    llama_mobile_free_float_array_c(ffi_arr);
}

void llama_mobile_free_completion_result(llama_mobile_completion_result_t* result) {
    if (result) {
        llama_mobile_completion_result_c_t ffi_result = {0};
        ffi_result.text = result->text;
        llama_mobile_free_completion_result_members_c(&ffi_result);
        result->text = nullptr;
    }
}

void llama_mobile_free_conversation_result(llama_mobile_conversation_result_t* result) {
    if (result) {
        llama_mobile_conversation_result_c_t ffi_result = {0};
        ffi_result.text = result->text;
        llama_mobile_free_conversation_result_members_c(&ffi_result);
        result->text = nullptr;
    }
}

// Helper function to convert API download params to FFI download params
static llama_mobile_download_params_c_t convert_download_params(const llama_mobile_download_params_t* api_params) {
    llama_mobile_download_params_c_t ffi_params = {0};
    
    if (api_params) {
        ffi_params.repo_id = api_params->repo_id;
        ffi_params.filename = api_params->filename;
        ffi_params.destination_path = api_params->destination_path;
        ffi_params.bearer_token = api_params->bearer_token;
        ffi_params.offline = api_params->offline;
        ffi_params.progress_callback = api_params->progress_callback;
    }
    
    return ffi_params;
}

// Helper function to convert FFI download result to API download result
static llama_mobile_download_result_t convert_download_result(llama_mobile_download_result_c_t ffi_result) {
    llama_mobile_download_result_t api_result = {0};
    api_result.success = ffi_result.success;
    api_result.local_path = ffi_result.local_path;
    api_result.error_message = ffi_result.error_message;
    api_result.file_size = ffi_result.file_size;
    return api_result;
}

// TTS (Text-to-Speech) Functions

int llama_mobile_init_vocoder(llama_mobile_context_t ctx, const char* vocoder_model_path) {
    return llama_mobile_init_vocoder_c(
        (llama_mobile_context_handle_t) ctx,
        vocoder_model_path);
}

bool llama_mobile_is_vocoder_enabled(llama_mobile_context_t ctx) {
    return llama_mobile_is_vocoder_enabled_c((llama_mobile_context_handle_t) ctx);
}

int llama_mobile_get_tts_type(llama_mobile_context_t ctx) {
    return llama_mobile_get_tts_type_c((llama_mobile_context_handle_t) ctx);
}

const char* llama_mobile_get_model_chat_template(llama_mobile_context_t ctx) {
    return llama_mobile_get_model_chat_template_c((llama_mobile_context_handle_t) ctx);
}

llama_mobile_token_array_t llama_mobile_get_audio_guide_tokens(llama_mobile_context_t ctx, const char* text_to_speak) {
    llama_mobile_token_array_c_t ffi_result = llama_mobile_get_audio_guide_tokens_c(
        (llama_mobile_context_handle_t) ctx,
        text_to_speak);
    return convert_token_array(ffi_result);
}

llama_mobile_float_array_t llama_mobile_decode_audio_tokens(llama_mobile_context_t ctx, const int32_t* tokens, int32_t count) {
    llama_mobile_float_array_c_t ffi_result = llama_mobile_decode_audio_tokens_c(
        (llama_mobile_context_handle_t) ctx,
        tokens,
        count);
    return convert_float_array(ffi_result);
}

bool llama_mobile_save_audio_to_wav(llama_mobile_context_t ctx, const char* file_path, const float* audio_data, int32_t count, int32_t sample_rate) {
    return llama_mobile_save_audio_to_wav_c(
        (llama_mobile_context_handle_t) ctx,
        file_path,
        audio_data,
        count,
        sample_rate);
}

void llama_mobile_release_vocoder(llama_mobile_context_t ctx) {
    llama_mobile_release_vocoder_c((llama_mobile_context_handle_t) ctx);
}

// Model Download Functions

llama_mobile_download_result_t llama_mobile_download_model(const llama_mobile_download_params_t* params) {
    if (!params) {
        llama_mobile_download_result_t empty_result = {0};
        return empty_result;
    }
    
    llama_mobile_download_params_c_t ffi_params = convert_download_params(params);
    llama_mobile_download_result_c_t ffi_result = llama_mobile_download_model_c(&ffi_params);
    return convert_download_result(ffi_result);
}

llama_mobile_download_result_t llama_mobile_download_hf_file(
    const char* repo_id,
    const char* filename,
    const char* destination_path,
    const char* bearer_token,
    bool offline,
    llama_mobile_download_progress_callback progress_callback) {
    
    llama_mobile_download_result_c_t ffi_result = llama_mobile_download_hf_file_c(
        repo_id,
        filename,
        destination_path,
        bearer_token,
        offline,
        progress_callback);
    
    return convert_download_result(ffi_result);
}

void llama_mobile_free_download_result(llama_mobile_download_result_t* result) {
    if (result) {
        llama_mobile_download_result_c_t ffi_result = {0};
        ffi_result.local_path = result->local_path;
        ffi_result.error_message = result->error_message;
        llama_mobile_free_download_result_c(&ffi_result);
        result->local_path = nullptr;
        result->error_message = nullptr;
    }
}

#ifdef __cplusplus
}
#endif