#ifndef LLAMA_MOBILE_API_H
#define LLAMA_MOBILE_API_H

// Platform-specific export macros for shared library builds
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
  #define LLAMA_MOBILE_LOCAL
#elif __GNUC__ >= 4
  #define LLAMA_MOBILE_API __attribute__ ((visibility ("default")))
  #define LLAMA_MOBILE_LOCAL  __attribute__ ((visibility ("hidden")))
#else
  #define LLAMA_MOBILE_API
  #define LLAMA_MOBILE_LOCAL
#endif

// FFI-specific export macros
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

// Include necessary system headers
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>

// Include FFI headers for C API functions
#include "llama_mobile_ffi.h"

// Forward declarations
struct mtmd_context;

// C++ Interface (from llama_mobile.h)
#ifdef __cplusplus

#include <sstream>
#include <iostream>
#include <chrono>
#include "llama_cpp/chat.h"
#include "llama_cpp/common.h"
#include "llama_cpp/ggml.h"
#include "llama_cpp/gguf.h"
#include "llama_cpp/llama.h"
#include "llama_cpp/llama-impl.h"
#include "llama_cpp/sampling.h"
#if defined(__ANDROID__)
#include <android/log.h>
#endif

namespace llama_mobile {

/**
 * @brief Convert a single token to a properly formatted string for output.
 * 
 * This function handles special tokens and formatting rules specific to the model's output.
 * 
 * @param ctx Pointer to the llama context
 * @param token The token to convert
 * @return Formatted string representation of the token
 */
std::string tokens_to_output_formatted_string(const llama_context *ctx, const llama_token token);

/**
 * @brief Convert a range of tokens to a string.
 * 
 * This function detokenizes a range of tokens from begin to end (exclusive) into a string.
 * 
 * @param ctx Pointer to the llama context
 * @param begin Iterator pointing to the first token
 * @param end Iterator pointing past the last token
 * @return String representation of the token range
 */
std::string tokens_to_str(llama_context *ctx, const std::vector<llama_token>::const_iterator begin, const std::vector<llama_token>::const_iterator end);

/**
 * @brief Convert a string representation of a KV cache type to the corresponding lm_ggml_type.
 * 
 * This function maps string identifiers like "f16" or "q4_0" to their respective lm_ggml_type values.
 * 
 * @param s String representation of the KV cache type
 * @return Corresponding lm_ggml_type, or a default type if the string is invalid
 */
lm_ggml_type kv_cache_type_from_str(const std::string & s);

/**
 * @brief Types of stopping conditions for text generation.
 */
enum stop_type
{
    STOP_FULL,    ///< Stop when a full stop sequence is encountered
    STOP_PARTIAL, ///< Stop when a partial stop sequence match is found
};

/**
 * @brief Types of Text-to-Speech (TTS) models supported.
 */
enum tts_type {
    TTS_UNKNOWN = -1,       ///< Unknown or unsupported TTS type
    TTS_OUTETTS_V0_2 = 1,   ///< OutE TTS model version 0.2
    TTS_OUTETTS_V0_3 = 2,   ///< OutE TTS model version 0.3
};

/**
 * @brief Result structure for a single completion token generation.
 */
struct completion_token_output
{
    /**
     * @brief Structure representing a token and its probability.
     */
    struct token_prob
    {
        llama_token tok; ///< The token ID
        float prob;      ///< The probability of this token being generated
    };

    std::vector<token_prob> probs; ///< List of top probability tokens
    llama_token tok;               ///< The actually selected token
};

/**
 * @brief Result structure for a full conversation turn.
 */
struct conversation_result {
    std::string text;                     ///< Generated response text
    std::chrono::milliseconds time_to_first_token; ///< Time taken to generate the first token
    std::chrono::milliseconds total_time; ///< Total generation time
    int tokens_generated;                 ///< Number of tokens generated in the response
};

/**
 * @brief Result structure for tokenization, including multimodal support.
 */
struct llama_mobile_tokenize_result {
    std::vector<llama_token> tokens;           ///< Generated tokens
    bool has_media = false;                    ///< Whether the input contained media
    std::vector<std::string> bitmap_hashes;    ///< Hashes of processed media
    std::vector<size_t> chunk_pos;             ///< Positions of text chunks
    std::vector<size_t> chunk_pos_media;       ///< Positions of media chunks
};

/**
 * @brief Main context class for the llama_mobile library.
 * 
 * This class encapsulates all the state and functionality needed to load models, 
 * generate text completions, handle conversations, and manage multimodal inputs.
 */
struct llama_mobile_context {
    // Prediction state
    bool is_predicting = false;            ///< Whether the model is currently generating text
    bool is_interrupted = false;           ///< Whether generation has been interrupted
    bool has_next_token = false;           ///< Whether there's a next token available
    std::string generated_text;            ///< Accumulated generated text
    std::vector<completion_token_output> generated_token_probs; ///< Token probabilities for generated text

    // Token counters
    size_t num_prompt_tokens = 0;          ///< Number of tokens in the current prompt
    size_t num_tokens_predicted = 0;       ///< Number of tokens generated in current completion
    size_t n_past = 0;                     ///< Number of tokens processed so far
    size_t n_remain = 0;                   ///< Number of tokens remaining to generate

    // Embedding and parameters
    std::vector<llama_token> embd;         ///< Current token embeddings
    common_params params;                  ///< Model and inference parameters
    common_init_result_ptr llama_init;     ///< Result of model initialization

    // Model and context pointers
    llama_model *model = nullptr;          ///< Pointer to the loaded model
    float loading_progress = 0;            ///< Model loading progress (0.0-1.0)
    bool is_load_interrupted = false;      ///< Whether model loading was interrupted

    llama_context *ctx = nullptr;          ///< Pointer to the llama context
    common_sampler *ctx_sampling = nullptr; ///< Sampling context
    common_chat_templates_ptr templates;   ///< Chat templates for conversational AI

    // Context configuration
    int n_ctx;                             ///< Size of the context window

    // Stopping conditions
    bool truncated = false;                ///< Whether the output was truncated
    bool stopped_eos = false;              ///< Whether generation stopped due to EOS token
    bool stopped_word = false;             ///< Whether generation stopped due to stop word
    bool stopped_limit = false;            ///< Whether generation stopped due to token limit
    std::string stopping_word;             ///< The stop word that triggered stopping
    bool incomplete = false;               ///< Whether the generation was incomplete

    // LoRA adapters
    std::vector<common_adapter_lora_info> lora; ///< Loaded LoRA adapters

    // Guide tokens
    bool context_full = false;             ///< Whether the context window is full
    std::vector<llama_token> guide_tokens; ///< Tokens to guide generation
    bool next_token_uses_guide_token = false; ///< Whether to use guide tokens for next token

    // Multimodal support
    struct llama_mobile_context_mtmd {
        mtmd_context* mtmd_ctx = nullptr;  ///< Multimodal context pointer
    };
    llama_mobile_context_mtmd *mtmd_wrapper = nullptr; ///< Multimodal wrapper
    bool has_multimodal = false;           ///< Whether multimodal support is enabled
    std::vector<std::string> mtmd_bitmap_past_hashes; ///< Hashes of past media

    // Vocoder (TTS) support
    struct llama_mobile_context_vocoder {
        common_init_result_ptr init_result; ///< Vocoder initialization result
        llama_model *model = nullptr;       ///< Vocoder model pointer
        llama_context *ctx = nullptr;       ///< Vocoder context
        tts_type type = TTS_UNKNOWN;        ///< Type of TTS model
    };
    llama_mobile_context_vocoder *vocoder_wrapper = nullptr; ///< Vocoder wrapper
    bool has_vocoder = false;              ///< Whether vocoder is enabled
    std::vector<llama_token> audio_tokens; ///< Generated audio tokens

    // Conversation management state
    bool conversation_active = false;      ///< Whether a conversation is active
    std::string last_chat_template = ""; ///< Last used chat template

    ~llama_mobile_context();

    /**
     * @brief Rewind the context to the beginning of the current conversation.
     */
    void rewind();

    /**
     * @brief Initialize the sampling parameters and context.
     * 
     * @return true on success, false on failure
     */
    bool initSampling();

    /**
     * @brief Load a model from disk using the provided parameters.
     * 
     * @param params_ Model loading and initialization parameters
     * @return true on success, false on failure
     */
    bool loadModel(common_params &params_);

    /**
     * @brief Validate if a chat template is compatible with the loaded model.
     * 
     * @param use_jinja Whether to use Jinja templates
     * @param name Name of the chat template to validate
     * @return true if the template is compatible, false otherwise
     */
    bool validateModelChatTemplate(bool use_jinja, const char *name) const;

    /**
     * @brief Format chat messages using Jinja templates, supporting tools and JSON schema.
     * 
     * @param messages JSON string containing chat messages
     * @param chat_template Name of the chat template to use
     * @param json_schema JSON schema for structured outputs
     * @param tools JSON string defining available tools
     * @param parallel_tool_calls Whether to support parallel tool calls
     * @param tool_choice Tool choice strategy
     * @return Formatted chat parameters for generation
     */
    common_chat_params getFormattedChatWithJinja(
      const std::string &messages,
      const std::string &chat_template,
      const std::string &json_schema,
      const std::string &tools,
      const bool &parallel_tool_calls,
      const std::string &tool_choice
    ) const;

    /**
     * @brief Format chat messages using a specified chat template.
     * 
     * @param messages JSON string containing chat messages
     * @param chat_template Name of the chat template to use
     * @return Formatted chat string
     */
    std::string getFormattedChat(
      const std::string &messages,
      const std::string &chat_template
    ) const;
    
    /**
     * @brief Truncate a prompt to fit within the context window.
     * 
     * @param prompt_tokens Vector of tokens to truncate
     */
    void truncatePrompt(std::vector<llama_token> &prompt_tokens);

    /**
     * @brief Load the current prompt into the model for generation.
     */
    void loadPrompt();

    /**
     * @brief Load a prompt with media attachments into the model.
     * 
     * @param media_paths Vector of paths to media files
     */
    void loadPrompt(const std::vector<std::string> &media_paths);

    /**
     * @brief Set guide tokens to influence generation.
     * 
     * @param tokens Vector of guide tokens
     */
    void setGuideTokens(const std::vector<llama_token> &tokens);
   
    /**
     * @brief Begin a new completion generation process.
     */
    void beginCompletion();

    /**
     * @brief End the current completion generation process.
     */
    void endCompletion();
    
    /**
     * @brief Generate the next token in the completion.
     * 
     * @return Result containing the generated token and its probabilities
     */
    completion_token_output nextToken();
   
    /**
     * @brief Check if the text contains any stop sequences.
     * 
     * @param text Text to check
     * @param last_token_size Size of the last token
     * @param type Type of stop condition to check for
     * @return Position of the stop sequence if found, or std::string::npos
     */
    size_t findStoppingStrings(const std::string &text, const size_t last_token_size, const stop_type type);
   
    /**
     * @brief Perform a single completion step.
     * 
     * @return Result containing the generated token and its probabilities
     */
    completion_token_output doCompletion();
   
    /**
     * @brief Generate embeddings for the input text.
     * 
     * @param embd_params Embedding generation parameters
     * @return Vector of floating-point embeddings
     */
    std::vector<float> getEmbedding(common_params &embd_params);
    
    /**
     * @brief Run benchmark tests on the loaded model.
     * 
     * @param pp Prompt processing batch size
     * @param tg Token generation batch size
     * @param pl Prompt length for benchmarking
     * @param nr Number of runs to average
     * @return JSON string containing benchmark results
     */
    std::string bench(int pp, int tg, int pl, int nr);
   
    /**
     * @brief Apply LoRA adapters to the loaded model.
     * 
     * @param lora Vector of LoRA adapter configurations
     * @return 0 on success, negative error code on failure
     */
    int applyLoraAdapters(std::vector<common_adapter_lora_info> lora);
   
    /**
     * @brief Remove all loaded LoRA adapters from the model.
     */
    void removeLoraAdapters();
    
    /**
     * @brief Get information about currently loaded LoRA adapters.
     * 
     * @return Vector of loaded LoRA adapters
     */
    std::vector<common_adapter_lora_info> getLoadedLoraAdapters();

    /**
     * @brief Tokenize text with optional media attachments.
     * 
     * @param text Text to tokenize
     * @param media_paths Vector of paths to media files
     * @return Tokenization result with optional media information
     */
    llama_mobile_tokenize_result tokenize(const std::string &text, const std::vector<std::string> &media_paths);

    /**
     * @brief Initialize multimodal support for the model.
     * 
     * @param mmproj_path Path to the multimodal projection file
     * @param use_gpu Whether to use GPU acceleration for multimodal processing
     * @return true on success, false on failure
     */
    bool initMultimodal(const std::string &mmproj_path, bool use_gpu);
    
    /**
     * @brief Check if multimodal support is enabled.
     * 
     * @return true if enabled, false otherwise
     */
    bool isMultimodalEnabled() const;
    
    /**
     * @brief Check if the model supports vision input.
     * 
     * @return true if vision is supported, false otherwise
     */
    bool isMultimodalSupportVision() const;
    
    /**
     * @brief Check if the model supports audio input.
     * 
     * @return true if audio is supported, false otherwise
     */
    bool isMultimodalSupportAudio() const;
    
    /**
     * @brief Release multimodal resources.
     */
    void releaseMultimodal();
    
    /**
     * @brief Process media files and integrate them with the prompt.
     * 
     * @param prompt Text prompt to process with media
     * @param media_paths Vector of paths to media files
     */
    void processMedia(const std::string &prompt, const std::vector<std::string> &media_paths);

    /**
     * @brief Initialize the vocoder for text-to-speech functionality.
     * 
     * @param vocoder_model_path Path to the vocoder model file
     * @return true on success, false on failure
     */
    bool initVocoder(const std::string &vocoder_model_path);
    
    /**
     * @brief Check if vocoder (TTS) support is enabled.
     * 
     * @return true if enabled, false otherwise
     */
    bool isVocoderEnabled() const;
    
    /**
     * @brief Get the type of TTS model currently loaded.
     * 
     * @return TTS model type
     */
    tts_type getTTSType() const;
    
    /**
     * @brief Format text for audio completion with speaker information.
     * 
     * @param speaker_json_str JSON string with speaker configuration
     * @param text_to_speak Text to convert to speech
     * @return Formatted audio completion string
     */
    std::string getFormattedAudioCompletion(const std::string &speaker_json_str, const std::string &text_to_speak);
    
    /**
     * @brief Get guide tokens for audio completion.
     * 
     * @param text_to_speak Text to convert to speech
     * @return Vector of guide tokens for audio generation
     */
    std::vector<llama_token> getAudioCompletionGuideTokens(const std::string &text_to_speak);
    
    /**
     * @brief Decode audio tokens into raw audio data.
     * 
     * @param tokens Audio tokens to decode
     * @return Vector of floating-point audio samples
     */
    std::vector<float> decodeAudioTokens(const std::vector<llama_token> &tokens);
    
    /**
     * @brief Release vocoder (TTS) resources.
     */
    void releaseVocoder();

    // High-level conversation management API
    /**
     * @brief Generate a response to a user message in a conversation.
     * 
     * @param user_message User's message
     * @param max_tokens Maximum number of tokens to generate
     * @return Generated response text
     */
    std::string generateResponse(const std::string &user_message, int max_tokens = 200);
    
    /**
     * @brief Continue a conversation with a user message, returning detailed timing information.
     * 
     * @param user_message User's message
     * @param max_tokens Maximum number of tokens to generate
     * @return Conversation result with timing and token information
     */
    conversation_result continueConversation(const std::string &user_message, int max_tokens = 200);
    
    /**
     * @brief Clear the current conversation history.
     */
    void clearConversation();
    
    /**
     * @brief Check if a conversation is currently active.
     * 
     * @return true if active, false otherwise
     */
    bool isConversationActive() const;
};

extern bool llama_mobile_verbose;

#if LLAMA_MOBILE_VERBOSE != 1
#define LOG_VERBOSE(MSG, ...)
#else
#define LOG_VERBOSE(MSG, ...)                                       \
    do                                                              \
    {                                                               \
        if (llama_mobile_verbose)                                        \
        {                                                           \
            log("VERBOSE", __func__, __LINE__, MSG, ##__VA_ARGS__); \
        }                                                           \
    } while (0)
#endif

#define LOG_ERROR(MSG, ...) log("ERROR", __func__, __LINE__, MSG, ##__VA_ARGS__)

#define LOG_WARNING(MSG, ...) log("WARNING", __func__, __LINE__, MSG, ##__VA_ARGS__)

#define LOG_INFO(MSG, ...) log("INFO", __func__, __LINE__, MSG, ##__VA_ARGS__)

void log(const char *level, const char *function, int line, const char *format, ...);

void llama_batch_clear(llama_batch *batch);

void llama_batch_add(llama_batch *batch, llama_token id, llama_pos pos, const std::vector<llama_seq_id>& seq_ids, bool logits);

size_t common_part(const std::vector<llama_token> &a, const std::vector<llama_token> &b);

bool ends_with(const std::string &str, const std::string &suffix);

size_t find_partial_stop_string(const std::string &stop, const std::string &text);

} // namespace llama_mobile

#endif // __cplusplus

// C API Interface (from llama_mobile_api.h)
#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Global verbosity flag for debug logging.
 * 
 * Set this to true to enable verbose debug logging from the llama_mobile library.
 */
extern bool llama_mobile_verbose;

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

// FFI Interface (from llama_mobile_ffi.h)

/**
 * @brief FFI-specific context handle.
 * 
 * This handle encapsulates the model state, configuration, and all necessary 
 * resources for performing inference through the FFI interface. It should be 
 * treated as an opaque object and only accessed through the provided FFI functions.
 */
typedef struct llama_mobile_context_opaque* llama_mobile_context_handle_t;



/**
 * @brief Initialize a new llama_mobile context through the FFI interface.
 * 
 * @param params Pointer to initialization parameters struct. Must contain at least
 *               the model_path field. All other fields will use default values if not specified.
 * @return Handle to the initialized context, or NULL on failure. The returned handle
 *         must be freed using llama_mobile_free_context_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_context_handle_t llama_mobile_init_context_c(const llama_mobile_init_params_c_t* params);

/**
 * @brief Free a llama_mobile context and all associated resources through the FFI interface.
 * 
 * @param handle Handle to the context to free. The handle should no longer be used after this call.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_context_c(llama_mobile_context_handle_t handle);

/**
 * @brief Generate a completion from a prompt through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param params Pointer to completion parameters struct.
 * @param result Output parameter to store the completion result. The result should be
 *               freed using llama_mobile_free_completion_result_members_c() when no longer needed.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_completion_c(
    llama_mobile_context_handle_t handle,
    const llama_mobile_completion_params_c_t* params,
    llama_mobile_completion_result_c_t* result
);

// **MULTIMODAL COMPLETION**
/**
 * @brief Generate a completion with multimodal input (images/audio) through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param params Pointer to completion parameters struct.
 * @param media_paths Array of paths to media files (images/audio).
 * @param media_count Number of media files in the media_paths array.
 * @param result Output parameter to store the completion result.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_multimodal_completion_c(
    llama_mobile_context_handle_t handle,
    const llama_mobile_completion_params_c_t* params,
    const char** media_paths,
    int media_count,
    llama_mobile_completion_result_c_t* result
);

/**
 * @brief Stop an ongoing completion generation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_stop_completion_c(llama_mobile_context_handle_t handle);

/**
 * @brief Tokenize a text string into an array of token IDs through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param text Text string to tokenize.
 * @return Array of token IDs. The returned array should be freed using
 *         llama_mobile_free_token_array_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_token_array_c_t llama_mobile_tokenize_c(llama_mobile_context_handle_t handle, const char* text);

/**
 * @brief Detokenize an array of token IDs back to a text string through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param tokens Array of token IDs to detokenize.
 * @param count Number of tokens in the tokens array.
 * @return Detokenized text string. The returned string should be freed using
 *         llama_mobile_free_string_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_detokenize_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

/**
 * @brief Generate embeddings for a text string through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param text Text string to generate embeddings for.
 * @return Array of float values representing the embeddings. The returned array
 *         should be freed using llama_mobile_free_float_array_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_float_array_c_t llama_mobile_embedding_c(llama_mobile_context_handle_t handle, const char* text);

/**
 * @brief Free a string allocated by the FFI interface.
 * 
 * @param str String to free. Can be NULL, in which case the function does nothing.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_string_c(char* str);

/**
 * @brief Free a token array allocated by the FFI interface.
 * 
 * @param arr Token array to free. The array's internal tokens pointer will be freed.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_token_array_c(llama_mobile_token_array_c_t arr);

/**
 * @brief Free a float array allocated by the FFI interface.
 * 
 * @param arr Float array to free. The array's internal values pointer will be freed.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_float_array_c(llama_mobile_float_array_c_t arr);

/**
 * @brief Free the members of a completion result allocated by the FFI interface.
 * 
 * @param result Completion result to free members of. Can be NULL, in which case
 *               the function does nothing.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_completion_result_members_c(llama_mobile_completion_result_c_t* result);

/**
 * @brief Tokenize text with optional media attachments through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param text Text string to tokenize.
 * @param media_paths Array of paths to media files (images/audio).
 * @param media_count Number of media files in the media_paths array.
 * @return Tokenization result with optional media information. The result should be
 *         freed using llama_mobile_free_tokenize_result_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_tokenize_result_c_t llama_mobile_tokenize_with_media_c(llama_mobile_context_handle_t handle, const char* text, const char** media_paths, int media_count);

/**
 * @brief Free a tokenization result allocated by the FFI interface.
 * 
 * @param result Tokenization result to free. All internal dynamically allocated fields will be freed.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_tokenize_result_c(llama_mobile_tokenize_result_c_t* result);

/**
 * @brief Set guide tokens to influence generation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param tokens Array of token IDs to use as guides.
 * @param count Number of tokens in the tokens array.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_set_guide_tokens_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

/**
 * @brief Initialize multimodal support (vision/audio) through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param mmproj_path Path to the multimodal projection file.
 * @param use_gpu Whether to use GPU acceleration for multimodal processing.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_init_multimodal_c(llama_mobile_context_handle_t handle, const char* mmproj_path, bool use_gpu);

/**
 * @brief Check if multimodal support is enabled through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return True if multimodal support is enabled, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_multimodal_enabled_c(llama_mobile_context_handle_t handle);

/**
 * @brief Check if the model supports vision input through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return True if vision is supported, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_supports_vision_c(llama_mobile_context_handle_t handle);

/**
 * @brief Check if the model supports audio input through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return True if audio is supported, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_supports_audio_c(llama_mobile_context_handle_t handle);

/**
 * @brief Release multimodal resources through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_release_multimodal_c(llama_mobile_context_handle_t handle);

/**
 * @brief Initialize the vocoder (TTS) for text-to-speech functionality through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param vocoder_model_path Path to the vocoder model file.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_init_vocoder_c(llama_mobile_context_handle_t handle, const char* vocoder_model_path);

/**
 * @brief Check if the vocoder (TTS) is enabled through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return True if vocoder is enabled, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_vocoder_enabled_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the type of TTS model currently loaded through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return TTS model type (see tts_type enum).
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_get_tts_type_c(llama_mobile_context_handle_t handle);

/**
 * @brief Format text for audio completion with speaker information through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param speaker_json_str JSON string with speaker configuration.
 * @param text_to_speak Text to convert to speech.
 * @return Formatted audio completion string. Must be freed using llama_mobile_free_string_c().
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_formatted_audio_completion_c(llama_mobile_context_handle_t handle, const char* speaker_json_str, const char* text_to_speak);

/**
 * @brief Get guide tokens for audio completion through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param text_to_speak Text to convert to speech.
 * @return Vector of guide tokens for audio generation. Must be freed using llama_mobile_free_token_array_c().
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_token_array_c_t llama_mobile_get_audio_guide_tokens_c(llama_mobile_context_handle_t handle, const char* text_to_speak);

/**
 * @brief Decode audio tokens into raw audio data through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param tokens Audio tokens to decode.
 * @param count Number of tokens in the tokens array.
 * @return Vector of floating-point audio samples. Must be freed using llama_mobile_free_float_array_c().
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_float_array_c_t llama_mobile_decode_audio_tokens_c(llama_mobile_context_handle_t handle, const int32_t* tokens, int32_t count);

/**
 * @brief Release vocoder (TTS) resources through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_release_vocoder_c(llama_mobile_context_handle_t handle);

// **HIGH PRIORITY ADDITIONS**

// LoRA adapter structs are defined in llama_mobile_ffi.h

// Benchmark result struct is defined in llama_mobile_ffi.h

// Conversation result struct is defined in llama_mobile_ffi.h

// **HIGH PRIORITY: Benchmarking**
/**
 * @brief Run benchmark tests on the loaded model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param pp Prompt processing batch size.
 * @param tg Token generation batch size.
 * @param pl Prompt length for benchmarking.
 * @param nr Number of runs to average.
 * @return Benchmark results structure. The result should be freed using
 *         llama_mobile_free_bench_result_members_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_bench_result_c_t llama_mobile_bench_c(llama_mobile_context_handle_t handle, int pp, int tg, int pl, int nr);

// **HIGH PRIORITY: LoRA Adapter Support**
/**
 * @brief Apply LoRA adapters to the model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param adapters Array of LoRA adapter configurations.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_apply_lora_adapters_c(llama_mobile_context_handle_t handle, const llama_mobile_lora_adapters_c_t* adapters);

/**
 * @brief Remove all loaded LoRA adapters through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_remove_lora_adapters_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the currently loaded LoRA adapters through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Array of loaded LoRA adapter configurations. The result should be freed using
 *         llama_mobile_free_lora_adapters_c() when no longer needed.
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_lora_adapters_c_t llama_mobile_get_loaded_lora_adapters_c(llama_mobile_context_handle_t handle);

// **HIGH PRIORITY: Chat Template Support**
/**
 * @brief Validate if a chat template is compatible with the loaded model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param use_jinja Whether to use Jinja templates.
 * @param name Name of the chat template to validate.
 * @return True if the template is compatible, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_validate_chat_template_c(llama_mobile_context_handle_t handle, bool use_jinja, const char* name);

/**
 * @brief Format chat messages using a specified chat template through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param messages JSON string containing chat messages.
 * @param chat_template Name of the chat template to use.
 * @return Formatted chat string. Must be freed using llama_mobile_free_string_c().
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_formatted_chat_c(llama_mobile_context_handle_t handle, const char* messages, const char* chat_template);

// **ADVANCED: Chat with Jinja and Tools Support**
// Chat result struct is defined in llama_mobile_ffi.h

/**
 * @brief Format chat messages with Jinja templates and tools support through the FFI interface.
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
 * @brief Rewind the context to the beginning of the current conversation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_rewind_c(llama_mobile_context_handle_t handle);

/**
 * @brief Initialize sampling parameters and context through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return true on success, false on failure.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_init_sampling_c(llama_mobile_context_handle_t handle);

// **COMPLETION CONTROL**
/**
 * @brief Begin a new completion generation process through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_begin_completion_c(llama_mobile_context_handle_t handle);

/**
 * @brief End the current completion generation process through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_end_completion_c(llama_mobile_context_handle_t handle);

/**
 * @brief Load the current prompt into the model for generation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
/**
 * @brief Load the current prompt into the model for generation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_load_prompt_c(llama_mobile_context_handle_t handle);

/**
 * @brief Load the current prompt with media attachments into the model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param media_paths Array of paths to media files (images/audio).
 * @param media_count Number of media files in the media_paths array.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_load_prompt_with_media_c(llama_mobile_context_handle_t handle, const char** media_paths, int media_count);

// **TOKEN PROCESSING**

/**
 * @brief Perform a single completion step and generate the next token through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param token_text Output parameter to receive the generated token text.
 *                   Must be freed using llama_mobile_free_string_c() when no longer needed.
 * @return 0 on success, negative error code on failure.
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_do_completion_step_c(llama_mobile_context_handle_t handle, char** token_text);

/**
 * @brief Check if the text contains any stop sequences through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param text Text to check for stop sequences.
 * @param last_token_size Size of the last token in the text.
 * @param stop_type Type of stop condition to check for (see stop_type enum).
 * @return Position of the stop sequence if found, or std::string::npos.
 */
LLAMA_MOBILE_FFI_EXPORT size_t llama_mobile_find_stopping_strings_c(llama_mobile_context_handle_t handle, const char* text, size_t last_token_size, int stop_type);

// **HIGH PRIORITY: Model Information**

/**
 * @brief Get the size of the context window through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Size of the context window in tokens.
 */
LLAMA_MOBILE_FFI_EXPORT int32_t llama_mobile_get_n_ctx_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the dimension of the model's embeddings through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Dimension of the model's embeddings.
 */
LLAMA_MOBILE_FFI_EXPORT int32_t llama_mobile_get_n_embd_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get a description of the loaded model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Model description string. Must be freed using llama_mobile_free_string_c().
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_get_model_desc_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the size of the loaded model in bytes through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Model size in bytes.
 */
LLAMA_MOBILE_FFI_EXPORT int64_t llama_mobile_get_model_size_c(llama_mobile_context_handle_t handle);

/**
 * @brief Get the number of parameters in the loaded model through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return Number of model parameters.
 */
LLAMA_MOBILE_FFI_EXPORT int64_t llama_mobile_get_model_params_c(llama_mobile_context_handle_t handle);

// **CONVERSATION MANAGEMENT**

/**
 * @brief Generate a response to a user message in a conversation through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param user_message User's message to add to the conversation.
 * @param max_tokens Maximum number of tokens to generate in the response.
 * @return Generated response text. Must be freed using llama_mobile_free_string_c().
 */
LLAMA_MOBILE_FFI_EXPORT char* llama_mobile_generate_response_c(llama_mobile_context_handle_t handle, const char* user_message, int32_t max_tokens);

/**
 * @brief Continue a conversation with detailed timing information through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @param user_message User's message to add to the conversation.
 * @param max_tokens Maximum number of tokens to generate in the response.
 * @return Conversation result structure with response text and timing information.
 *         The result should be freed using llama_mobile_free_conversation_result_members_c().
 */
LLAMA_MOBILE_FFI_EXPORT llama_mobile_conversation_result_c_t llama_mobile_continue_conversation_c(llama_mobile_context_handle_t handle, const char* user_message, int32_t max_tokens);

/**
 * @brief Clear the current conversation context through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_clear_conversation_c(llama_mobile_context_handle_t handle);

/**
 * @brief Check if a conversation is currently active through the FFI interface.
 * 
 * @param handle Handle to the initialized context.
 * @return True if a conversation is active, false otherwise.
 */
LLAMA_MOBILE_FFI_EXPORT bool llama_mobile_is_conversation_active_c(llama_mobile_context_handle_t handle);

// Memory management functions

/**
 * @brief Free the members of a benchmark result allocated by the FFI interface.
 * 
 * @param result Benchmark result to free members of. The struct itself is not freed,
 *               only the dynamically allocated fields like model_name.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_bench_result_members_c(llama_mobile_bench_result_c_t* result);

/**
 * @brief Free the members of a LoRA adapters array allocated by the FFI interface.
 * 
 * @param adapters LoRA adapters array to free members of. The struct itself is not freed,
 *                 only the dynamically allocated adapters array.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_lora_adapters_c(llama_mobile_lora_adapters_c_t* adapters);

/**
 * @brief Free the members of a chat result allocated by the FFI interface.
 * 
 * @param result Chat result to free members of. The struct itself is not freed,
 *               only the dynamically allocated fields like prompt, json_schema, tools, and tool_choice.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_chat_result_members_c(llama_mobile_chat_result_c_t* result);

/**
 * @brief Free the members of a conversation result allocated by the FFI interface.
 * 
 * @param result Conversation result to free members of. The struct itself is not freed,
 *               only the dynamically allocated text field.
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_conversation_result_members_c(llama_mobile_conversation_result_c_t* result);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_MOBILE_API_H
