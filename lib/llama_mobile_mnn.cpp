#include "llama_mobile_mnn.h"
#include <random>
#include <algorithm>
#include <sstream>

#if defined(__ANDROID__)
#include <android/log.h>
#define LOG_TAG "llama_mobile_mnn"
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#else
#define LOGD(...) printf("DEBUG: " __VA_ARGS__); printf("\n")
#define LOGE(...) printf("ERROR: " __VA_ARGS__); printf("\n")
#endif

namespace llama_mobile {

mnn_mobile_context::~mnn_mobile_context() {
    if (session != nullptr) {
        interpreter->releaseSession(session);
        session = nullptr;
    }
    interpreter.reset();
}

void mnn_mobile_context::rewind() {
    n_past = 0;
    generated_text.clear();
    generated_token_probs.clear();
    is_predicting = false;
    is_interrupted = false;
    has_next_token = false;
    truncated = false;
    stopped_eos = false;
    stopped_word = false;
    stopped_limit = false;
    incomplete = false;
}

bool mnn_mobile_context::loadModel(const std::string &model_path, int n_ctx, int n_threads, bool use_metal, bool use_neon) {
    this->model_path = model_path;
    this->n_ctx = n_ctx;
    this->n_threads = n_threads;
    this->use_metal = use_metal;
    this->use_neon = use_neon;

    try {
        loading_progress = 0.1f;
        
        // Create MNN schedule config
        MNN::ScheduleConfig config;
        config.numThread = n_threads;
        
        // Set platform-specific options
        if (use_metal) {
            // Enable Metal backend for iOS
            auto backendConfig = new MNN::BackendConfig;
            backendConfig->precision = MNN::BackendConfig::Precision_Low;
            backendConfig->power = MNN::BackendConfig::Power_High;
            backendConfig->memory = MNN::BackendConfig::Memory_Normal;
            config.backendConfig = backendConfig;
            config.type = MNN_FORWARD_METAL;
        } else if (use_neon) {
            // Enable Neon backend for Android
            config.type = MNN_FORWARD_CPU;
            // Neon is enabled by default on supported ARM CPUs in MNN
        } else {
            // Default to CPU backend
            config.type = MNN_FORWARD_CPU;
        }

        loading_progress = 0.3f;
        
        // Create interpreter
        interpreter = std::shared_ptr<MNN::Interpreter>(MNN::Interpreter::createFromFile(model_path.c_str()));
        if (interpreter == nullptr) {
            LOGE("Failed to create MNN interpreter from file: %s", model_path.c_str());
            if (use_metal && config.backendConfig) {
                delete config.backendConfig;
            }
            return false;
        }

        loading_progress = 0.6f;
        
        // Create session
        session = interpreter->createSession(config);
        
        // Clean up backend config
        if (config.backendConfig) {
            delete config.backendConfig;
        }
        
        if (session == nullptr) {
            LOGE("Failed to create MNN session");
            interpreter.reset();
            return false;
        }

        loading_progress = 1.0f;
        model_loaded = true;
        
        LOGD("MNN model loaded successfully: %s", model_path.c_str());
        LOGD("Context size: %d, Threads: %d, Metal: %d, Neon: %d", n_ctx, n_threads, use_metal, use_neon);
        
        return true;
    } catch (const std::exception &e) {
        LOGE("Exception loading MNN model: %s", e.what());
        return false;
    }
}

void mnn_mobile_context::beginCompletion() {
    if (!model_loaded) {
        LOGE("Cannot begin completion: model not loaded");
        return;
    }

    is_predicting = true;
    is_interrupted = false;
    has_next_token = true;
    generated_text.clear();
    generated_token_probs.clear();
    n_past = 0;
    n_remain = n_ctx;
    truncated = false;
    stopped_eos = false;
    stopped_word = false;
    stopped_limit = false;
    incomplete = false;
}

void mnn_mobile_context::endCompletion() {
    is_predicting = false;
    has_next_token = false;
}

completion_token_output mnn_mobile_context::nextToken() {
    completion_token_output result;
    
    if (!is_predicting || is_interrupted || !has_next_token) {
        has_next_token = false;
        return result;
    }

    try {
        // Get input and output tensors
        auto inputTensor = interpreter->getSessionInput(session, nullptr);
        auto outputTensor = interpreter->getSessionOutput(session, nullptr);
        
        if (inputTensor == nullptr || outputTensor == nullptr) {
            LOGE("Failed to get input/output tensors");
            has_next_token = false;
            return result;
        }

        // Create a random token for demonstration (replace with actual MNN inference)
        // In a real implementation, you would:
        // 1. Prepare the input (prompt tokens + past context)
        // 2. Run the inference
        // 3. Process the output logits to generate the next token
        
        std::random_device rd;
        std::mt19937 gen(rd());
        std::uniform_int_distribution<> token_dist(1000, 20000);
        std::uniform_real_distribution<> prob_dist(0.7f, 0.99f);
        
        int generated_token = token_dist(gen);
        float token_prob = prob_dist(gen);
        
        // Simulate token probabilities
        std::vector<completion_token_output::token_prob> probs;
        probs.resize(5);
        probs[0].tok = generated_token;
        probs[0].prob = token_prob;
        
        for (int i = 1; i < 5; ++i) {
            probs[i].tok = token_dist(gen);
            probs[i].prob = token_prob * (0.5f - i * 0.1f);
        }
        
        // Sort probabilities in descending order
        std::sort(probs.begin(), probs.end(), [](const auto &a, const auto &b) {
            return a.prob > b.prob;
        });
        
        result.tok = generated_token;
        result.probs = probs;
        result.token_str = std::string(1, static_cast<char>('a' + (generated_token % 26)));
        
        // Update state
        generated_text += result.token_str;
        generated_token_probs.push_back(result);
        n_past++;
        n_remain--;
        
        // Check stopping conditions
        if (n_remain <= 0) {
            stopped_limit = true;
            has_next_token = false;
        } else if (generated_token == 2) { // EOS token
            stopped_eos = true;
            has_next_token = false;
        } else {
            // Simulate 10% chance to stop generating
            std::uniform_real_distribution<> stop_dist(0.0f, 1.0f);
            if (stop_dist(gen) > 0.9f) {
                has_next_token = false;
            }
        }
        
    } catch (const std::exception &e) {
        LOGE("Exception in nextToken: %s", e.what());
        has_next_token = false;
    }
    
    return result;
}

size_t mnn_mobile_context::findStoppingStrings(const std::string &text, const size_t last_token_size, const stop_type type) {
    // Simple implementation - replace with proper stop string handling
    if (type == STOP_FULL && text.find(stopping_word) != std::string::npos) {
        stopped_word = true;
        return text.find(stopping_word);
    }
    return std::string::npos;
}

completion_token_output mnn_mobile_context::doCompletion() {
    if (!is_predicting || is_interrupted) {
        has_next_token = false;
        completion_token_output empty;
        return empty;
    }
    
    return nextToken();
}

std::string mnn_mobile_context::generateResponse(const std::string &user_message, int max_tokens) {
    conversation_result result = continueConversation(user_message, max_tokens);
    return result.text;
}

conversation_result mnn_mobile_context::continueConversation(const std::string &user_message, int max_tokens) {
    conversation_result result;
    
    if (!model_loaded) {
        LOGE("Cannot continue conversation: model not loaded");
        return result;
    }
    
    auto start_time = std::chrono::high_resolution_clock::now();
    auto first_token_time = start_time;
    bool first_token_generated = false;
    
    try {
        // Add user message to conversation history
        if (conversation_active) {
            conversation_history.push_back("User: " + user_message);
        } else {
            conversation_history.clear();
            conversation_history.push_back("User: " + user_message);
            conversation_active = true;
        }
        
        // Begin completion
        beginCompletion();
        
        int tokens_generated = 0;
        
        // Generate tokens until stop condition
        while (has_next_token && tokens_generated < max_tokens && !is_interrupted) {
            completion_token_output token_result = doCompletion();
            
            if (token_result.tok != 0) {
                tokens_generated++;
                
                if (!first_token_generated) {
                    first_token_time = std::chrono::high_resolution_clock::now();
                    first_token_generated = true;
                }
            }
            
            if (stopped_eos || stopped_word || stopped_limit) {
                break;
            }
        }
        
        endCompletion();
        
        // Add assistant response to conversation history
        conversation_history.push_back("Assistant: " + generated_text);
        
        // Calculate timing information
        auto end_time = std::chrono::high_resolution_clock::now();
        std::chrono::milliseconds total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        std::chrono::milliseconds time_to_first_token = first_token_generated ? 
            std::chrono::duration_cast<std::chrono::milliseconds>(first_token_time - start_time) : 
            total_time;
        
        result.text = generated_text;
        result.time_to_first_token = time_to_first_token;
        result.total_time = total_time;
        result.tokens_generated = tokens_generated;
        
    } catch (const std::exception &e) {
        LOGE("Exception in continueConversation: %s", e.what());
        result.text = "Error generating response: " + std::string(e.what());
    }
    
    return result;
}

void mnn_mobile_context::clearConversation() {
    conversation_history.clear();
    conversation_active = false;
    rewind();
}

bool mnn_mobile_context::isConversationActive() const {
    return conversation_active;
}

void mnn_mobile_context::setGenerationParams(float temperature, float top_p, float top_k, float repetition_penalty) {
    this->temperature = temperature;
    this->top_p = top_p;
    this->top_k = top_k;
    this->repetition_penalty = repetition_penalty;
    
    // Note: These parameters would be applied during actual token sampling in a real implementation
    // Since our current implementation uses random token generation, these parameters aren't used yet
}

} // namespace llama_mobile
