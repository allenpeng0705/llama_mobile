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
    bool use_metal = false;                ///< Whether to use Metal for iOS
    bool use_neon = false;                 ///< Whether to use Neon for Android

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
};

} // namespace llama_mobile

#endif // LLAMA_MOBILE_MNN_H
