#ifndef LLAMA_MOBILE_MNN_H
#define LLAMA_MOBILE_MNN_H

#include <sstream>
#include <iostream>
#include <chrono>
#include <string>
#include <vector>
#include <memory>
#include <map>

#include "MNN/transformers/llm/engine/include/llm/llm.hpp"

#if defined(__ANDROID__)
#include <android/log.h>
#endif

namespace llama_mobile {

namespace mnn {

using ChatMessage = std::pair<std::string, std::string>; // <role, content>
using ChatMessages = std::vector<ChatMessage>;

struct MNN_PUBLIC PromptImagePart {
    MNN::Express::VARP image_data;
    int width;
    int height;
};

struct MNN_PUBLIC MultimodalPrompt {
    std::string prompt_template;
    std::map<std::string, PromptImagePart> images;
};

enum class LlmStatus {
    RUNNING = 0,
    NORMAL_FINISHED = 1,
    MAX_TOKENS_FINISHED = 2,
    USER_CANCEL = 3,
    INTERNAL_ERROR = 4,
};

struct completion_token_output {
    struct token_prob {
        int tok;
        float prob;
    };

    std::vector<token_prob> probs;
    int tok;
};

struct conversation_result {
    std::string text;
    std::chrono::milliseconds time_to_first_token;
    std::chrono::milliseconds total_time;
    int tokens_generated;
};

struct llama_mobile_mnn_context {
    bool is_predicting = false;
    bool is_interrupted = false;
    bool has_next_token = false;
    std::string generated_text;
    std::vector<completion_token_output> generated_token_probs;

    size_t num_prompt_tokens = 0;
    size_t num_tokens_predicted = 0;

    MNN::Transformer::Llm* llm = nullptr;
    bool is_load_interrupted = false;

    // Configuration parameters
    std::string config_path;
    int n_ctx = 2048;
    int n_threads = 4;
    int n_gpu_layers = 0;
    bool use_mmap = true;
    bool use_mlock = false;

    // Generation status
    bool truncated = false;
    bool stopped_eos = false;
    bool stopped_word = false;
    bool stopped_limit = false;
    std::string stopping_word;
    bool incomplete = false;

    // Conversation management state
    bool conversation_active = false;
    std::string last_chat_template = "";
    std::vector<int> history_tokens;

    ~llama_mobile_mnn_context();

    void rewind();

    bool loadModel(const std::string& config_path, int n_ctx = 2048, int n_threads = 4, int n_gpu_layers = 0);

    std::string getFormattedChat(const std::string& messages, const std::string& chat_template) const;

    void beginCompletion();
    void endCompletion();
    completion_token_output nextToken();

    // High-level conversation management API
    std::string generateResponse(const std::string& user_message, int max_tokens = 200);
    conversation_result continueConversation(const std::string& user_message, int max_tokens = 200);
    void clearConversation();
    bool isConversationActive() const;

    // Tokenization and embedding
    std::vector<int> tokenize(const std::string& text);
    std::string detokenize(const std::vector<int>& tokens);
    std::vector<float> getEmbedding(const std::string& text);

    // Multimodal support
    bool processImage(const std::string& image_path);
    void releaseImages();

    // Configuration
    void setTemperature(float temperature);
    void setTopK(int top_k);
    void setTopP(float top_p);
    void setPenaltyRepeat(float penalty_repeat);

    // Status checking
    LlmStatus getStatus() const;
    bool isLoaded() const;
};

// Configuration struct for MNN LLM initialization
struct mnn_init_params {
    std::string config_path;
    std::string chat_template;
    int n_ctx = 2048;
    int n_threads = 4;
    int n_gpu_layers = 0;
    bool use_mmap = true;
    bool use_mlock = false;
    void (*progress_callback)(float progress);
};

// Configuration struct for completion/generation
struct mnn_completion_params {
    std::string prompt;
    int max_tokens = 128;
    float temperature = 0.8;
    int top_k = 40;
    float top_p = 0.95;
    float min_p = 0.05;
    float penalty_repeat = 1.1;
    const char** stop_sequences = nullptr;
    int stop_sequence_count = 0;
    bool (*token_callback)(const char* token);
};

} // namespace mnn

} // namespace llama_mobile

#endif /* LLAMA_MOBILE_MNN_H */