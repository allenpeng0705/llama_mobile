#ifndef LLAMA_MOBILE_API_H
#define LLAMA_MOBILE_API_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Platform-specific export macros
#if defined _WIN32 || defined __CYGWIN__
  #ifdef LLAMA_MOBILE_BUILDING_SHARED
    #ifdef __GNUC__
      #define LLAMA_MOBILE_API __attribute__ ((dllexport))
    #else
      #define LLAMA_MOBILE_API __declspec(dllexport)
    #endif
  #else
    #ifdef __GNUC__
      #define LLAMA_MOBILE_API __attribute__ ((dllimport))
    #else
      #define LLAMA_MOBILE_API __declspec(dllimport)
    #endif
  #endif
#elif __GNUC__ >= 4
  #define LLAMA_MOBILE_API __attribute__ ((visibility ("default")))
#else
  #define LLAMA_MOBILE_API
#endif

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Opaque handle to the llama_mobile context.
 * 
 * This handle encapsulates the model state, configuration, and all necessary 
 * resources for performing inference. It should be treated as an opaque object 
 * and only accessed through the provided API functions.
 */
typedef struct llama_mobile_context_opaque* llama_mobile_context_t;

/**
 * @brief Parameters for initializing a llama_mobile context.
 * 
 * This struct contains all configuration options for loading and initializing 
 * a model. For simplified initialization, see llama_mobile_init_simple().
 */
typedef struct {
    const char* model_path;          /**< Path to the model file (required) */
    const char* chat_template;       /**< Chat template to use (optional, NULL for default) */
    int32_t n_ctx;                   /**< Context window size (default: 512) */
    int32_t n_batch;                 /**< Batch size for inference (default: 512) */
    int32_t n_gpu_layers;            /**< Number of layers to offload to GPU (default: 0) */
    int32_t n_threads;               /**< Number of CPU threads to use (default: 4) */
    bool use_mmap;                   /**< Use memory-mapped I/O for model loading (default: true) */
    bool use_mlock;                  /**< Lock model in memory (default: false) */
    bool embedding;                  /**< Enable embedding mode (default: false) */
    double temperature;              /**< Sampling temperature (default: 0.8) */
    int32_t top_k;                   /**< Top-K sampling parameter (default: 40) */
    double top_p;                    /**< Top-P sampling parameter (default: 0.95) */
    double min_p;                    /**< Min-P sampling parameter (default: 0.05) */
    double penalty_repeat;           /**< Repeat penalty (default: 1.1) */
    const char* cache_type_k;        /**< Cache type for key (optional, NULL for default) */
    const char* cache_type_v;        /**< Cache type for value (optional, NULL for default) */
    void (*progress_callback)(float progress);  /**< Model loading progress callback (optional) */
} llama_mobile_init_params_t;

/**
 * @brief Parameters for generating completions.
 * 
 * This struct contains all options for text generation. For simplified completion, 
 * see llama_mobile_completion_simple().
 */
typedef struct {
    const char* prompt;               /**< Input prompt text (required) */
    int32_t max_tokens;               /**< Maximum number of tokens to generate (default: 128) */
    double temperature;               /**< Sampling temperature (default: 0.8) */
    int32_t top_k;                    /**< Top-K sampling parameter (default: 40) */
    double top_p;                     /**< Top-P sampling parameter (default: 0.95) */
    double min_p;                     /**< Min-P sampling parameter (default: 0.05) */
    double penalty_repeat;            /**< Repeat penalty (default: 1.1) */
    const char** stop_sequences;      /**< Array of stop sequences to terminate generation (optional) */
    int stop_sequence_count;          /**< Number of stop sequences (optional, 0 for none) */
    bool (*token_callback)(const char* token);  /**< Streaming callback for generated tokens (optional) */
} llama_mobile_completion_params_t;

/**
 * @brief Result of a completion generation.
 * 
 * This struct contains the generated text and metadata about the completion process. 
 * The text field should be freed using llama_mobile_free_string() when no longer needed.
 */
typedef struct {
    char* text;                      /**< Generated text (null-terminated string) */
    int32_t tokens_generated;        /**< Number of tokens actually generated */
    int32_t tokens_evaluated;        /**< Number of tokens processed from the input prompt */
    bool truncated;                  /**< Whether the output was truncated due to context limitations */
    bool stopped_eos;                /**< Whether generation stopped due to EOS (end-of-sequence) token */
    bool stopped_word;               /**< Whether generation stopped due to hitting a stop sequence */
    bool stopped_limit;              /**< Whether generation stopped due to reaching max_tokens limit */
} llama_mobile_completion_result_t;

/**
 * @brief Array of tokens used for tokenization/detokenization.
 * 
 * This struct contains an array of token IDs. The tokens array should be freed 
 * using llama_mobile_free_token_array() when no longer needed.
 */
typedef struct {
    int32_t* tokens;                 /**< Array of token IDs */
    int32_t count;                   /**< Number of tokens in the array */
} llama_mobile_token_array_t;

/**
 * @brief Array of float values used for embeddings.
 * 
 * This struct contains an array of floating-point embedding values. The values 
 * array should be freed using llama_mobile_free_float_array() when no longer needed.
 */
typedef struct {
    float* values;                   /**< Array of float values */
    int32_t count;                   /**< Number of values in the array */
} llama_mobile_float_array_t;

/**
 * @brief LoRA adapter configuration.
 * 
 * This struct defines a LoRA (Low-Rank Adaptation) adapter to be applied to the model.
 */
typedef struct {
    const char* path;                /**< Path to the LoRA adapter file */
    float scale;                     /**< LoRA adapter scale factor (typically 1.0) */
} llama_mobile_lora_adapter_t;

/**
 * @brief Result of a conversation generation.
 * 
 * This struct contains the generated response text and timing information for 
 * conversational interactions. The text field should be freed using 
 * llama_mobile_free_string() when no longer needed.
 */
typedef struct {
    char* text;                      /**< Generated response text (null-terminated string) */
    int64_t time_to_first_token;     /**< Time to generate first token in milliseconds */
    int64_t total_time;              /**< Total generation time in milliseconds */
    int32_t tokens_generated;        /**< Number of tokens generated in the response */
} llama_mobile_conversation_result_t;

/**
 * @brief Initialize a new llama_mobile context with detailed configuration.
 * 
 * @param params Pointer to initialization parameters struct. Must contain at least
 *               the model_path field. All other fields will use default values if not specified.
 * @return Handle to the initialized context, or NULL on failure. The returned handle
 *         must be freed using llama_mobile_free() when no longer needed.
 */
LLAMA_MOBILE_API llama_mobile_context_t llama_mobile_init(
    const llama_mobile_init_params_t* params);

/**
 * @brief Simplified initialization of a llama_mobile context.
 * 
 * This function provides a simplified interface for initializing a model with
 * common default values for most parameters. For advanced configuration, use
 * llama_mobile_init() with a params struct.
 * 
 * @param model_path Path to the model file (required).
 * @param n_ctx Context window size (default: 2048).
 * @param n_gpu_layers Number of layers to offload to GPU (default: 0).
 * @param n_threads Number of CPU threads to use (default: 4).
 * @param progress_callback Optional progress callback for model loading.
 * @return Handle to the initialized context, or NULL on failure.
 */
LLAMA_MOBILE_API llama_mobile_context_t llama_mobile_init_simple(
    const char* model_path,
    int32_t n_ctx,
    int32_t n_gpu_layers,
    int32_t n_threads,
    void (*progress_callback)(float progress));

/**
 * @brief Free a llama_mobile context and all associated resources.
 * 
 * This function releases all memory, model resources, and other allocated objects
 * associated with the given context. After calling this function, the context
 * handle should no longer be used.
 * 
 * @param ctx Context handle to free.
 */
LLAMA_MOBILE_API void llama_mobile_free(llama_mobile_context_t ctx);

/**
 * @brief Generate a completion from a prompt with detailed configuration.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param params Pointer to completion parameters struct.
 * @param result Output parameter to store the completion result. The result should be
 *               freed using llama_mobile_free_completion_result() when no longer needed.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    llama_mobile_completion_result_t* result);

/**
 * @brief Simplified completion generation from a prompt.
 * 
 * This function provides a simplified interface for generating text completions
 * with common default values. For advanced configuration, use llama_mobile_completion()
 * with a params struct.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param prompt Input prompt text.
 * @param max_tokens Maximum number of tokens to generate.
 * @param temperature Sampling temperature (0.0 for greedy sampling, 0.8-1.0 for typical usage).
 * @param token_callback Optional streaming callback for generated tokens.
 * @param result Output parameter to store the completion result.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_completion_simple(
    llama_mobile_context_t ctx,
    const char* prompt,
    int32_t max_tokens,
    double temperature,
    bool (*token_callback)(const char* token),
    llama_mobile_completion_result_t* result);

/**
 * @brief Generate a completion with multimodal input (images/audio).
 * 
 * This function allows generating completions from a combination of text prompt
 * and media files (images or audio). The multimodal support must be initialized
 * first using llama_mobile_init_multimodal().
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param params Pointer to completion parameters struct.
 * @param media_paths Array of paths to media files (images/audio).
 * @param media_count Number of media files in the media_paths array.
 * @param result Output parameter to store the completion result.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_multimodal_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    const char** media_paths,
    int media_count,
    llama_mobile_completion_result_t* result);

/**
 * @brief Stop an ongoing completion generation.
 * 
 * This function interrupts any currently running completion generation process.
 * It is safe to call this function from a different thread than the one running
 * the completion.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 */
LLAMA_MOBILE_API void llama_mobile_stop_completion(llama_mobile_context_t ctx);

/**
 * @brief Tokenize a text string into an array of token IDs.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param text Text string to tokenize.
 * @return Array of token IDs. The returned array should be freed using
 *         llama_mobile_free_token_array() when no longer needed.
 */
LLAMA_MOBILE_API llama_mobile_token_array_t llama_mobile_tokenize(
    llama_mobile_context_t ctx,
    const char* text);

/**
 * @brief Detokenize an array of token IDs back to a text string.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param tokens Array of token IDs to detokenize.
 * @param count Number of tokens in the tokens array.
 * @return Detokenized text string. The returned string should be freed using
 *         llama_mobile_free_string() when no longer needed.
 */
LLAMA_MOBILE_API char* llama_mobile_detokenize(
    llama_mobile_context_t ctx,
    const int32_t* tokens,
    int32_t count);

/**
 * @brief Generate embeddings for a text string.
 * 
 * This function computes dense vector embeddings for the input text. Embedding
 * mode must be enabled during initialization (either by setting embedding=true
 * in params or using the default in embedding mode functions).
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param text Text string to generate embeddings for.
 * @return Array of float values representing the embeddings. The returned array
 *         should be freed using llama_mobile_free_float_array() when no longer needed.
 */
LLAMA_MOBILE_API llama_mobile_float_array_t llama_mobile_embedding(
    llama_mobile_context_t ctx,
    const char* text);

/**
 * @brief Apply LoRA adapters to the model.
 * 
 * LoRA (Low-Rank Adaptation) adapters allow fine-tuning a model without modifying
 * the base model weights. This function applies one or more LoRA adapters to
 * the current model context.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param adapters Array of LoRA adapter configurations.
 * @param count Number of adapters in the adapters array.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_apply_lora_adapters(
    llama_mobile_context_t ctx,
    const llama_mobile_lora_adapter_t* adapters,
    int count);

/**
 * @brief Remove all loaded LoRA adapters.
 * 
 * This function removes any previously applied LoRA adapters, restoring the
 * model to its original state.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 */
LLAMA_MOBILE_API void llama_mobile_remove_lora_adapters(llama_mobile_context_t ctx);

/**
 * @brief Initialize multimodal support (vision/audio) for the model.
 * 
 * This function enables the model to process image and audio inputs in addition
 * to text. The multimodal projection file must be compatible with the loaded model.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param mmproj_path Path to the multimodal projection file.
 * @param use_gpu Whether to use GPU acceleration for multimodal processing.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_init_multimodal(
    llama_mobile_context_t ctx,
    const char* mmproj_path,
    bool use_gpu);

/**
 * @brief Simplified initialization of multimodal support.
 * 
 * This function provides a simplified interface for enabling multimodal support
 * with a default GPU setting. For explicit GPU control, use llama_mobile_init_multimodal().
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param mmproj_path Path to the multimodal projection file.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_init_multimodal_simple(
    llama_mobile_context_t ctx,
    const char* mmproj_path);

/**
 * @brief Check if multimodal support is enabled for the current context.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @return True if multimodal support is enabled, false otherwise.
 */
LLAMA_MOBILE_API bool llama_mobile_is_multimodal_enabled(llama_mobile_context_t ctx);

/**
 * @brief Release multimodal resources.
 * 
 * This function releases all resources associated with multimodal support.
 * After calling this function, multimodal features will no longer be available
 * until llama_mobile_init_multimodal() is called again.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 */
LLAMA_MOBILE_API void llama_mobile_release_multimodal(llama_mobile_context_t ctx);

/**
 * @brief Generate a response in a conversational context.
 * 
 * This function maintains a persistent conversation context, allowing for natural
 * back-and-forth interactions. Each call appends the user message to the conversation
 * history and generates an appropriate response.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param user_message User's message to add to the conversation.
 * @param max_tokens Maximum number of tokens to generate in the response.
 * @param result Output parameter to store the conversation result.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_generate_response(
    llama_mobile_context_t ctx,
    const char* user_message,
    int32_t max_tokens,
    llama_mobile_conversation_result_t* result);

/**
 * @brief Simplified response generation in a conversational context.
 * 
 * This function provides a simplified interface for generating conversational responses
 * with common default values. For advanced configuration, use llama_mobile_generate_response().
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 * @param user_message User's message to add to the conversation.
 * @param max_tokens Maximum number of tokens to generate in the response (default: 128).
 * @param result Output parameter to store the conversation result.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_API int llama_mobile_generate_response_simple(
    llama_mobile_context_t ctx,
    const char* user_message,
    int32_t max_tokens,
    llama_mobile_conversation_result_t* result);

/**
 * @brief Clear the current conversation context.
 * 
 * This function resets the conversation history, removing all previous messages.
 * After calling this function, llama_mobile_generate_response() will start with
 * a fresh conversation context.
 * 
 * @param ctx Context handle obtained from llama_mobile_init() or llama_mobile_init_simple().
 */
LLAMA_MOBILE_API void llama_mobile_clear_conversation(llama_mobile_context_t ctx);

/**
 * @brief Free a string allocated by the library.
 * 
 * This function should be used to free any string returned by the library's API
 * functions, such as text fields in result structs or return values from
 * detokenization functions.
 * 
 * @param str String to free. Can be NULL, in which case the function does nothing.
 */
LLAMA_MOBILE_API void llama_mobile_free_string(char* str);

/**
 * @brief Free a token array allocated by the library.
 * 
 * This function should be used to free token arrays returned by functions like
 * llama_mobile_tokenize().
 * 
 * @param arr Token array to free. The array's internal tokens pointer will be freed.
 */
LLAMA_MOBILE_API void llama_mobile_free_token_array(llama_mobile_token_array_t arr);

/**
 * @brief Free a float array allocated by the library.
 * 
 * This function should be used to free float arrays returned by functions like
 * llama_mobile_embedding().
 * 
 * @param arr Float array to free. The array's internal values pointer will be freed.
 */
LLAMA_MOBILE_API void llama_mobile_free_float_array(llama_mobile_float_array_t arr);

/**
 * @brief Free the members of a completion result.
 * 
 * This function frees the dynamically allocated fields of a completion result,
 * but does not free the result struct itself (which should be handled by the caller).
 * 
 * @param result Completion result to free members of. Can be NULL, in which case
 *               the function does nothing.
 */
LLAMA_MOBILE_API void llama_mobile_free_completion_result(llama_mobile_completion_result_t* result);

/**
 * @brief Free the members of a conversation result.
 * 
 * This function frees the dynamically allocated fields of a conversation result,
 * but does not free the result struct itself (which should be handled by the caller).
 * 
 * @param result Conversation result to free members of. Can be NULL, in which case
 *               the function does nothing.
 */
LLAMA_MOBILE_API void llama_mobile_free_conversation_result(llama_mobile_conversation_result_t* result);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_MOBILE_API_H