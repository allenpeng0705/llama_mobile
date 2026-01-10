#ifndef LLAMA_MOBILE_PRIVATE_H
#define LLAMA_MOBILE_PRIVATE_H

// Platform-specific visibility macros for private APIs
#if defined _WIN32 || defined __CYGWIN__
  #define LLAMA_MOBILE_PRIVATE
#elif __GNUC__ >= 4
  #define LLAMA_MOBILE_PRIVATE __attribute__ ((visibility ("hidden")))
#else
  #define LLAMA_MOBILE_PRIVATE
#endif

// Include necessary headers
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// Include public API to reuse public types
#include "llama_mobile_api.h"

// Forward declarations from llama_cpp
struct llama_context;
struct llama_model;
struct llama_batch;
typedef int llama_token;

// Private internal types

/**
 * @brief Internal context structure for the llama_mobile library.
 * 
 * This is the actual implementation of the opaque llama_mobile_context_t handle.
 * It should not be exposed to external users.
 */
struct llama_mobile_context_private {
    // Model and context pointers
    llama_model *model;
    llama_context *ctx;
    
    // Context configuration
    int n_ctx;
    int n_batch;
    int n_gpu_layers;
    int n_threads;
    
    // Sampling parameters
    double temperature;
    int top_k;
    double top_p;
    double min_p;
    double penalty_repeat;
    
    // Generation state
    bool is_generating;
    bool is_interrupted;
    int n_past;
    int n_remain;
    
    // Buffers
    uint8_t *buf_decode;
    size_t buf_decode_len;
    
    // Stop conditions
    const char **stop_sequences;
    int stop_sequence_count;
    
    // Grammar support
    const char *grammar;
    void *grammar_parser;
    
    // Multimodal support (internal)
    struct {
        void *mtmd_ctx;
        bool use_gpu;
    } mm;
    
    // Vocoder (TTS) support (internal)
    struct {
        llama_model *model;
        llama_context *ctx;
        int type;
    } vocoder;
};

// Private internal functions

/**
 * @brief Convert an internal context pointer to the public opaque handle.
 */
#define llama_mobile_context_cast(ctx) ((llama_mobile_context_t)(ctx))

/**
 * @brief Convert the public opaque handle to an internal context pointer.
 */
#define llama_mobile_context_unwrap(ctx) ((struct llama_mobile_context_private*)(ctx))

/**
 * @brief Internal function to initialize the llama_cpp library.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_init_internal(const char* model_path, struct llama_mobile_context_private** ctx_out);

/**
 * @brief Internal function to load model weights.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_load_model_weights(struct llama_mobile_context_private* ctx, const char* model_path);

/**
 * @brief Internal function to initialize context for inference.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_init_context(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to process a batch of tokens.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_process_tokens(struct llama_mobile_context_private* ctx, struct llama_batch* batch);

/**
 * @brief Internal function to sample the next token.
 */
LLAMA_MOBILE_PRIVATE llama_token llama_mobile_sample_next_token(struct llama_mobile_context_private* ctx, float* logits);

/**
 * @brief Internal function to check for stop sequences.
 */
LLAMA_MOBILE_PRIVATE bool llama_mobile_check_stop_sequences(struct llama_mobile_context_private* ctx, const char* text);

/**
 * @brief Internal function to free generation state.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_free_generation_state(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to initialize grammar support.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_init_grammar(struct llama_mobile_context_private* ctx, const char* grammar_path);

/**
 * @brief Internal function to free grammar resources.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_free_grammar(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to load model weights into memory.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_load_model_weights(struct llama_mobile_context_private* ctx, const char* model_path);

/**
 * @brief Internal function to create and configure the llama context.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_create_context(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to process a batch of tokens.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_process_batch(struct llama_mobile_context_private* ctx, struct llama_batch* batch, bool is_prompt);

/**
 * @brief Internal function to generate a single token.
 */
LLAMA_MOBILE_PRIVATE llama_token llama_mobile_generate_token(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to apply sampling to the logits.
 */
LLAMA_MOBILE_PRIVATE llama_token llama_mobile_sample_token(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to check for stop conditions.
 */
LLAMA_MOBILE_PRIVATE bool llama_mobile_check_stop_conditions(struct llama_mobile_context_private* ctx, const char* text);

/**
 * @brief Internal function to initialize the grammar parser.
 */
LLAMA_MOBILE_PRIVATE void* llama_mobile_init_grammar(const char* grammar);

/**
 * @brief Internal function to update the grammar parser with a new token.
 */
LLAMA_MOBILE_PRIVATE bool llama_mobile_update_grammar(void* parser, llama_token token);

/**
 * @brief Internal function to free the grammar parser.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_free_grammar(void* parser);

/**
 * @brief Internal function to log debug messages.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_log(const char* level, const char* function, int line, const char* format, ...);

/**
 * @brief Internal function to compute embeddings for tokenized input.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_compute_embeddings(struct llama_mobile_context_private* ctx, const int32_t* tokens, int32_t token_count, float** embeddings_out, int32_t* embedding_dim_out);

/**
 * @brief Internal function to load and apply LoRA adapters.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_load_lora(struct llama_mobile_context_private* ctx, const char* path, float scale);

/**
 * @brief Internal function to initialize multimodal support.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_init_multimodal_internal(struct llama_mobile_context_private* ctx, const char* mmproj_path, bool use_gpu);

/**
 * @brief Internal function to process multimodal inputs.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_process_multimodal(struct llama_mobile_context_private* ctx, const char** media_paths, int media_count);

/**
 * @brief Internal function to release multimodal resources.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_release_multimodal_internal(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to initialize the vocoder.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_init_vocoder_internal(struct llama_mobile_context_private* ctx, const char* vocoder_path, int type);

/**
 * @brief Internal function to decode audio tokens.
 */
LLAMA_MOBILE_PRIVATE int llama_mobile_decode_audio(struct llama_mobile_context_private* ctx, const int32_t* tokens, int32_t token_count, float** audio_out, int32_t* audio_len_out);

/**
 * @brief Internal function to release vocoder resources.
 */
LLAMA_MOBILE_PRIVATE void llama_mobile_release_vocoder_internal(struct llama_mobile_context_private* ctx);

/**
 * @brief Internal function to benchmark the model.
 */
LLAMA_MOBILE_PRIVATE char* llama_mobile_benchmark_internal(struct llama_mobile_context_private* ctx, int pp, int tg, int pl, int nr);

#endif // LLAMA_MOBILE_PRIVATE_H
