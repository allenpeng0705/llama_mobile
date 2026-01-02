#ifndef LLAMA_MOBILE_MNN_H
#define LLAMA_MOBILE_MNN_H

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

// Include necessary system headers
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#include <vector>
#include <string>
#include <chrono>

// MNN includes
#include "MNN/Interpreter.hpp"
#include "MNN/MNNDefine.h"
#include "MNN/ImageProcess.hpp"
#include "MNN/Tensor.hpp"
#include "MNN/transformers/llm/engine/include/llm/llm.hpp"

namespace llama_mobile {



/**
 * @brief Types of stopping conditions for text generation.
 */
enum stop_type
{
    STOP_FULL,    ///< Stop when a full stop sequence is encountered
    STOP_PARTIAL, ///< Stop when a partial stop sequence match is found
};

/**
 * @brief Types of TTS implementation to use.
 */
enum tts_type
{
    TTS_BERTVITS2, ///< BERT-VITS2 TTS implementation
};

/**
 * @brief Types of LoRA adapter update strategies.
 */
enum lora_adapter_update_strategy
{
    ADAPTER_UPDATE_EMBEDDING,       ///< Update embedding layer
    ADAPTER_UPDATE_ATTN,             ///< Update attention layers
    ADAPTER_UPDATE_ATTN_OUT,         ///< Update attention output layers
    ADAPTER_UPDATE_FFN_GATE,         ///< Update FFN gate layers
    ADAPTER_UPDATE_FFN_UP,           ///< Update FFN up layers
    ADAPTER_UPDATE_FFN_DOWN,         ///< Update FFN down layers
    ADAPTER_UPDATE_ALL,              ///< Update all supported layers
};

/**
 * @brief Configuration for a single LoRA adapter.
 */
struct lora_adapter_t
{
    const char* name;                ///< Name of the adapter
    const char* path;                ///< Path to the adapter file
    float r;                         ///< Rank of the adapter
    float alpha;                     ///< Scaling factor for the adapter
    float dropout;                   ///< Dropout rate for the adapter
    bool freeze;                     ///< Whether to freeze the adapter weights
    uint32_t update_strategy;        ///< Bitmask of update strategies from lora_adapter_update_strategy
    const char* layers;              ///< Comma-separated list of layers to apply the adapter to
};

/**
 * @brief Structure representing an image part of a multimodal prompt.
 */
struct prompt_image_part
{
    void* image_data;                ///< Raw image data
    int width;                       ///< Image width
    int height;                      ///< Image height
    int channels;                    ///< Number of color channels (e.g., 3 for RGB)
};

/**
 * @brief Structure representing an audio part of a multimodal prompt.
 */
struct prompt_audio_part
{
    const char* file_path;           ///< Path to audio file
    float* waveform;                 ///< Raw audio waveform data
    size_t waveform_size;            ///< Size of waveform data in samples
};

/**
 * @brief Structure for a multimodal prompt containing text, images, and audio.
 */
struct multimodal_prompt
{
    const char* prompt_template;     ///< Template for the prompt
    prompt_image_part* images;       ///< Array of images
    size_t image_count;              ///< Number of images
    prompt_audio_part* audios;       ///< Array of audio parts
    size_t audio_count;              ///< Number of audio parts
};

/**
 * @brief Structure representing an embedding vector.
 */
struct embedding_result
{
    float* data;                     ///< Embedding vector data
    size_t dimension;                ///< Dimension of the embedding
    float similarity_threshold;      ///< Similarity threshold for comparisons
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
        int tok;  ///< The token ID
        float prob; ///< The probability of this token being generated
    };

    std::vector<token_prob> probs; ///< List of top probability tokens
    int tok;                     ///< The actually selected token
    std::string token_str;       ///< String representation of the token
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
 * @brief Main context class for MNN integration in llama_mobile library.
 * 
 * This class encapsulates all the state and functionality needed to load models,
 * generate text completions, and handle conversations using MNN engine.
 */
struct mnn_mobile_context {
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

    // Model and context pointers
    std::shared_ptr<MNN::Interpreter> interpreter = nullptr; ///< MNN interpreter
    MNN::Session* session = nullptr;                         ///< MNN session
    std::shared_ptr<MNN::Transformer::Llm> llm = nullptr;    ///< MNN LLM transformer
    std::shared_ptr<MNN::Transformer::Embedding> embedding_model = nullptr; ///< MNN Embedding model
    bool model_loaded = false;                               ///< Whether model is loaded
    float loading_progress = 0;                              ///< Model loading progress (0.0-1.0)
    bool is_load_interrupted = false;                        ///< Whether model loading was interrupted

    // Context configuration
    int n_ctx;                             ///< Size of the context window
    int n_threads = 4;                     ///< Number of threads to use

    // Stopping conditions
    bool truncated = false;                ///< Whether the output was truncated
    bool stopped_eos = false;              ///< Whether generation stopped due to EOS token
    bool stopped_word = false;             ///< Whether generation stopped due to stop word
    bool stopped_limit = false;            ///< Whether generation stopped due to token limit
    std::string stopping_word;             ///< The stop word that triggered stopping
    bool incomplete = false;               ///< Whether the generation was incomplete

    // Generation parameters
    float temperature = 0.8f;              ///< Sampling temperature
    float top_p = 0.95f;                   ///< Top-p sampling parameter
    float top_k = 40.0f;                   ///< Top-k sampling parameter
    float repetition_penalty = 1.0f;       ///< Repetition penalty

    // Conversation management state
    bool conversation_active = false;      ///< Whether a conversation is active
    std::vector<std::string> conversation_history; ///< Conversation history

    // MNN-specific parameters
    std::string model_path;                ///< Path to the MNN model file
    std::string config_path;               ///< Path to configuration file
    bool use_metal = false;                ///< Whether to use Metal for iOS
    bool use_neon = false;                 ///< Whether to use Neon for Android

    // LoRA adapter state
    std::vector<lora_adapter_t> adapters;  ///< List of applied LoRA adapters
    std::vector<std::shared_ptr<MNN::Transformer::Llm>> lora_models; ///< LoRA model instances

    // TTS state
    void* tts_sdk = nullptr;               ///< TTS SDK instance
    tts_type current_tts_type;             ///< Current TTS implementation type
    std::string tts_config_folder;         ///< Path to TTS configuration folder

    ~mnn_mobile_context();

    /**
     * @brief Rewind the context to the beginning of the current conversation.
     */
    void rewind();

    /**
     * @brief Load a model from disk using the provided parameters.
     * 
     * @param model_path Path to the MNN model file
     * @param n_ctx Context window size
     * @param n_threads Number of threads to use
     * @param use_metal Whether to use Metal acceleration (iOS only)
     * @param use_neon Whether to use Neon acceleration (Android only)
     * @return true on success, false on failure
     */
    bool loadModel(const std::string &model_path, int n_ctx = 2048, int n_threads = 4, bool use_metal = false, bool use_neon = false);

    /**
     * @brief Load an embedding model from disk.
     * 
     * @param config_path Path to the embedding model configuration file
     * @param n_threads Number of threads to use
     * @return true on success, false on failure
     */
    bool loadEmbeddingModel(const std::string &config_path, int n_threads = 4);

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

    /**
     * @brief Set generation parameters.
     * 
     * @param temperature Sampling temperature (0.0-2.0)
     * @param top_p Top-p sampling parameter (0.0-1.0)
     * @param top_k Top-k sampling parameter (1-100)
     * @param repetition_penalty Repetition penalty (0.0-2.0)
     */
    void setGenerationParams(float temperature, float top_p, float top_k, float repetition_penalty);

    // Embedding API
    /**
     * @brief Generate an embedding for text.
     * 
     * @param text Text to generate embedding for
     * @return Embedding result containing the vector and metadata
     */
    embedding_result generateEmbedding(const std::string &text);

    /**
     * @brief Calculate the cosine similarity between two embeddings.
     * 
     * @param embedding1 First embedding
     * @param embedding2 Second embedding
     * @return Cosine similarity value (-1.0 to 1.0)
     */
    float calculateCosineSimilarity(const embedding_result &embedding1, const embedding_result &embedding2);

    /**
     * @brief Calculate the distance between two embeddings.
     * 
     * @param embedding1 First embedding
     * @param embedding2 Second embedding
     * @return Distance value
     */
    float calculateDistance(const embedding_result &embedding1, const embedding_result &embedding2);

    // Multimodal API
    /**
     * @brief Generate a response to a multimodal prompt.
     * 
     * @param prompt Multimodal prompt with text, images, and audio
     * @param max_tokens Maximum number of tokens to generate
     * @return Generated response text
     */
    std::string generateMultimodalResponse(const multimodal_prompt &prompt, int max_tokens = 200);

    /**
     * @brief Tokenize a multimodal prompt.
     * 
     * @param prompt Multimodal prompt to tokenize
     * @return Vector of token IDs
     */
    std::vector<int> tokenizeMultimodal(const multimodal_prompt &prompt);

    // LoRA API
    /**
     * @brief Apply a LoRA adapter to the model.
     * 
     * @param adapter LoRA adapter configuration
     * @return true on success, false on failure
     */
    bool applyLoraAdapter(const lora_adapter_t &adapter);

    /**
     * @brief Apply multiple LoRA adapters to the model.
     * 
     * @param adapters Array of LoRA adapter configurations
     * @param adapter_count Number of adapters in the array
     * @return true on success, false on failure
     */
    bool applyLoraAdapters(const lora_adapter_t *adapters, size_t adapter_count);

    /**
     * @brief Remove all applied LoRA adapters from the model.
     */
    void removeLoraAdapters();

    /**
     * @brief Remove a specific LoRA adapter by name.
     * 
     * @param name Name of the adapter to remove
     * @return true on success, false if adapter not found
     */
    bool removeLoraAdapter(const std::string &name);

    // TTS API
    /**
     * @brief Initialize the TTS system with the specified implementation.
     * 
     * @param config_folder Path to TTS configuration folder
     * @param type Type of TTS implementation to use
     * @return true on success, false on failure
     */
    bool initTTS(const std::string &config_folder, tts_type type = TTS_BERTVITS2);

    /**
     * @brief Generate audio from text using TTS.
     * 
     * @param text Text to synthesize
     * @param output_file Path to save the generated audio file
     * @return true on success, false on failure
     */
    bool generateAudioFromText(const std::string &text, const std::string &output_file);

    /**
     * @brief Generate audio waveform data from text using TTS.
     * 
     * @param text Text to synthesize
     * @param sample_rate Output sample rate (will be set by the function)
     * @param audio_data Output vector to store audio data
     * @return true on success, false on failure
     */
    bool generateAudioWaveform(const std::string &text, int &sample_rate, std::vector<float> &audio_data);
};

} // namespace llama_mobile

#endif // LLAMA_MOBILE_MNN_H
