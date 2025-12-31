#include "llama_mobile_mnn.h"
#include "llama_mobile_unified.h"
#include "MNN/expr/Module.hpp"
#include "MNN/expr/MathOp.hpp"
#include "MNN/transformers/llm/engine/src/tokenizer.hpp"
#include "MNN/transformers/llm/engine/src/llmconfig.hpp"

#include <sstream>
#include <iostream>
#include <chrono>
#include <string>
#include <vector>
#include <memory>
#include <map>

namespace llama_mobile {

namespace mnn {

llama_mobile_mnn_context::~llama_mobile_mnn_context() {
    if (llm != nullptr) {
        MNN::Transformer::Llm::destroy(llm);
        llm = nullptr;
    }
}

void llama_mobile_mnn_context::rewind() {
    is_interrupted = false;
    is_predicting = false;
    num_prompt_tokens = 0;
    num_tokens_predicted = 0;
    generated_text = "";
    generated_text.reserve(n_ctx);
    generated_token_probs.clear();
    truncated = false;
    stopped_eos = false;
    stopped_word = false;
    stopped_limit = false;
    stopping_word = "";
    incomplete = false;
    history_tokens.clear();
}

bool llama_mobile_mnn_context::loadModel(const std::string& config_path, int n_ctx_, int n_threads_, int n_gpu_layers_) {
    try {
        this->config_path = config_path;
        this->n_ctx = n_ctx_;
        this->n_threads = n_threads_;
        this->n_gpu_layers = n_gpu_layers_;

        // Create LLM instance from configuration file
        llm = MNN::Transformer::Llm::createLLM(config_path);
        if (llm == nullptr) {
            LOG_ERROR("Failed to create MNN LLM instance");
            return false;
        }

        // Load the model
        bool load_success = llm->load();
        if (!load_success) {
            LOG_ERROR("Failed to load MNN LLM model");
            MNN::Transformer::Llm::destroy(llm);
            llm = nullptr;
            return false;
        }

        LOG_INFO("MNN LLM model loaded successfully");
        return true;
    } catch (const std::exception& e) {
        LOG_ERROR("Exception while loading MNN LLM model: %s", e.what());
        if (llm != nullptr) {
            MNN::Transformer::Llm::destroy(llm);
            llm = nullptr;
        }
        return false;
    }
}

std::string llama_mobile_mnn_context::getFormattedChat(const std::string& messages, const std::string& chat_template) const {
    if (llm == nullptr) {
        LOG_ERROR("LLM not initialized");
        return "";
    }

    try {
        // Convert JSON string messages to ChatMessages
        ChatMessages chat_messages;
        // For simplicity, we'll parse the JSON here
        // In a real implementation, we'd use a proper JSON parser
        // This is a simplified version for demonstration
        chat_messages.emplace_back("user", messages);

        return llm->apply_chat_template(chat_messages);
    } catch (const std::exception& e) {
        LOG_ERROR("Error formatting chat: %s", e.what());
        return "User: " + messages + "\nAssistant: ";
    }
}

void llama_mobile_mnn_context::beginCompletion() {
    is_predicting = true;
    has_next_token = true;
    generated_text.clear();
    generated_text.reserve(n_ctx);
    generated_token_probs.clear();
    num_tokens_predicted = 0;
    truncated = false;
    stopped_eos = false;
    stopped_word = false;
    stopped_limit = false;
}

void llama_mobile_mnn_context::endCompletion() {
    is_predicting = false;
    has_next_token = false;
}

completion_token_output llama_mobile_mnn_context::nextToken() {
    completion_token_output output;
    output.tok = -1;

    if (llm == nullptr || !is_predicting) {
        return output;
    }

    try {
        // For now, we'll just return a placeholder
        // In a real implementation, we'd use the MNN LLM's generate method
        // to get the next token
        output.tok = 0;
        return output;
    } catch (const std::exception& e) {
        LOG_ERROR("Error generating next token: %s", e.what());
        has_next_token = false;
        return output;
    }
}

std::string llama_mobile_mnn_context::generateResponse(const std::string& user_message, int max_tokens) {
    auto result = continueConversation(user_message, max_tokens);
    return result.text;
}

conversation_result llama_mobile_mnn_context::continueConversation(const std::string& user_message, int max_tokens) {
    auto start_time = std::chrono::high_resolution_clock::now();
    bool first_token = true;
    std::chrono::high_resolution_clock::time_point first_token_time;
    int tokens_generated = 0;

    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
    }

    try {
        bool is_first_message = !conversation_active || history_tokens.empty();
        std::string formatted_prompt;

        if (is_first_message) {
            // First message in conversation
            ChatMessages chat_messages;
            chat_messages.emplace_back("user", user_message);
            formatted_prompt = llm->apply_chat_template(chat_messages);
            last_chat_template = formatted_prompt;
            conversation_active = true;
        } else {
            // Continuing conversation
            formatted_prompt = last_chat_template + user_message;
        }

        beginCompletion();

        // Use MNN's LLM to generate response
        std::stringstream output_stream;
        llm->response(formatted_prompt, &output_stream, nullptr, max_tokens);

        generated_text = output_stream.str();
        tokens_generated = generated_text.size() / 4; // Rough estimate, in real implementation we'd count actual tokens

        if (first_token) {
            first_token_time = std::chrono::high_resolution_clock::now();
        }

        endCompletion();

        auto end_time = std::chrono::high_resolution_clock::now();
        auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        auto ttft = first_token ? std::chrono::milliseconds(0) : 
                    std::chrono::duration_cast<std::chrono::milliseconds>(first_token_time - start_time);

        LOG_VERBOSE("MNN LLM Generated response: %s (TTFT: %dms, Total: %dms, Tokens: %d)", 
                    generated_text.c_str(), (int)ttft.count(), (int)total_time.count(), tokens_generated);

        return {generated_text, ttft, total_time, tokens_generated};
    } catch (const std::exception& e) {
        LOG_ERROR("Error generating response: %s", e.what());
        endCompletion();
        return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
    }
}

void llama_mobile_mnn_context::clearConversation() {
    history_tokens.clear();
    conversation_active = false;
    last_chat_template = "";
}

bool llama_mobile_mnn_context::isConversationActive() const {
    return conversation_active;
}

std::vector<int> llama_mobile_mnn_context::tokenize(const std::string& text) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return {};
    }

    try {
        return llm->tokenizer_encode(text);
    } catch (const std::exception& e) {
        LOG_ERROR("Error tokenizing text: %s", e.what());
        return {};
    }
}

std::string llama_mobile_mnn_context::detokenize(const std::vector<int>& tokens) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return "";
    }

    try {
        std::string result;
        for (int token : tokens) {
            result += llm->tokenizer_decode(token);
        }
        return result;
    } catch (const std::exception& e) {
        LOG_ERROR("Error detokenizing tokens: %s", e.what());
        return "";
    }
}

std::vector<float> llama_mobile_mnn_context::getEmbedding(const std::string& text) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return {};
    }

    try {
        // First tokenize the text
        std::vector<int> tokens = tokenize(text);
        if (tokens.empty()) {
            return {};
        }

        // Get embedding from MNN LLM
        MNN::Express::VARP embedding_var = llm->embedding(tokens);
        if (embedding_var == nullptr) {
            LOG_ERROR("Failed to get embedding from MNN LLM");
            return {};
        }

        // Evaluate the expression and get the tensor
        auto embedding_tensor = embedding_var->readMap<float>();
        if (embedding_tensor == nullptr) {
            LOG_ERROR("Failed to read embedding tensor");
            return {};
        }

        // Get the shape of the embedding
        std::vector<int> shape = embedding_var->getInfo()->dim;
        int size = 1;
        for (int dim : shape) {
            size *= dim;
        }

        // Convert to vector<float>
        std::vector<float> embedding(embedding_tensor, embedding_tensor + size);
        return embedding;
    } catch (const std::exception& e) {
        LOG_ERROR("Error getting embedding: %s", e.what());
        return {};
    }
}

bool llama_mobile_mnn_context::processImage(const std::string& image_path) {
    // This is a placeholder implementation
    // In a real implementation, we'd use MNN's image processing capabilities
    LOG_INFO("Processing image: %s", image_path.c_str());
    return true;
}

void llama_mobile_mnn_context::releaseImages() {
    // This is a placeholder implementation
    LOG_INFO("Releasing images");
}

void llama_mobile_mnn_context::setTemperature(float temperature) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return;
    }

    try {
        std::string config = "{\"temperature\": " + std::to_string(temperature) + "}";
        llm->set_config(config);
    } catch (const std::exception& e) {
        LOG_ERROR("Error setting temperature: %s", e.what());
    }
}

void llama_mobile_mnn_context::setTopK(int top_k) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return;
    }

    try {
        std::string config = "{\"topK\": " + std::to_string(top_k) + "}";
        llm->set_config(config);
    } catch (const std::exception& e) {
        LOG_ERROR("Error setting top_k: %s", e.what());
    }
}

void llama_mobile_mnn_context::setTopP(float top_p) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return;
    }

    try {
        std::string config = "{\"topP\": " + std::to_string(top_p) + "}";
        llm->set_config(config);
    } catch (const std::exception& e) {
        LOG_ERROR("Error setting top_p: %s", e.what());
    }
}

void llama_mobile_mnn_context::setPenaltyRepeat(float penalty_repeat) {
    if (llm == nullptr) {
        LOG_ERROR("Model not initialized");
        return;
    }

    try {
        std::string config = "{\"penalty\": " + std::to_string(penalty_repeat) + "}";
        llm->set_config(config);
    } catch (const std::exception& e) {
        LOG_ERROR("Error setting repeat penalty: %s", e.what());
    }
}

LlmStatus llama_mobile_mnn_context::getStatus() const {
    if (!isLoaded()) {
        return LlmStatus::INTERNAL_ERROR;
    }

    if (is_predicting) {
        return LlmStatus::RUNNING;
    }

    if (stopped_eos || stopped_word || stopped_limit) {
        return LlmStatus::NORMAL_FINISHED;
    }

    return LlmStatus::NORMAL_FINISHED;
}

bool llama_mobile_mnn_context::isLoaded() const {
    return llm != nullptr;
}

} // namespace mnn

} // namespace llama_mobile