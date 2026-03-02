#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <cstdlib>
#include <cassert>
#include <cstring>
#include <thread>
#include <chrono>
#include <iomanip>
#include <filesystem>

#include "utils.h"
#include "../../lib/llama_mobile.h"

// Include nlohmann json for proper JSON handling
#include "llama.cpp-master/vendor/nlohmann/json.hpp"
using json = nlohmann::ordered_json;

namespace fs = std::filesystem;

struct GenerationResult {
    std::string text;
    std::chrono::milliseconds time_to_first_token;
    std::chrono::milliseconds total_time;
    int tokens_generated;
};

void addStopSequences(llama_mobile::llama_mobile_context& context) {
    context.params.antiprompt.push_back("<|im_end|>");
}

GenerationResult generateText(llama_mobile::llama_mobile_context& context, const std::string& prompt, int max_tokens = 100) {
    auto start_time = std::chrono::high_resolution_clock::now();
    
    context.rewind();
    addStopSequences(context);
    
    context.params.prompt = prompt;
    context.params.n_predict = max_tokens;
    
    if (!context.initSampling()) {
        std::cerr << "Failed to initialize sampling" << std::endl;
        return {"", std::chrono::milliseconds(0), std::chrono::milliseconds(0), 0};
    }
    
    context.beginCompletion();
    context.loadPrompt();
    
    bool first_token = true;
    std::chrono::high_resolution_clock::time_point first_token_time;
    int tokens_generated = 0;
    
    while (context.has_next_token && !context.is_interrupted) {
        auto token_output = context.doCompletion();
        if (token_output.tok == -1) break;
        
        if (first_token) {
            first_token_time = std::chrono::high_resolution_clock::now();
            first_token = false;
        }
        tokens_generated++;
    }
    
    auto end_time = std::chrono::high_resolution_clock::now();
    
    auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
    auto ttft = first_token ? std::chrono::milliseconds(0) : 
                std::chrono::duration_cast<std::chrono::milliseconds>(first_token_time - start_time);
    
    return {context.generated_text, ttft, total_time, tokens_generated};
}

void demonstrateBasicGeneration(llama_mobile::llama_mobile_context& context) {
    std::cout << "\n=== Basic Text Generation Demo ===" << std::endl;
    
    // Show both approaches for comparison
    std::cout << "\n--- Traditional Approach ---" << std::endl;
    std::vector<std::string> prompts = {
        "The future of artificial intelligence is",
        "Write a short story about a robot who discovers emotions:"
    };
    
    for (const auto& prompt : prompts) {
        std::cout << "\nPrompt: " << prompt << std::endl;
        std::cout << "Response: " << generateText(context, prompt, 100).text << std::endl;
        std::cout << std::string(60, '-') << std::endl;
    }
    
    // Clear and show new conversation API
    context.clearConversation();
    
    std::cout << "\n--- New Conversation API ---" << std::endl;
    std::vector<std::string> messages = {
        "Hello! How are you?",
        "What can you help me with?",
        "Tell me a fun fact about space"
    };
    
    for (const auto& message : messages) {
        std::cout << "\nUser: " << message << std::endl;
        auto start = std::chrono::high_resolution_clock::now();
        
        auto result = context.continueConversation(message, 150);
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
        
        std::cout << "Bot: " << result.text << std::endl;
        
        std::cout << "(TTFT: " << result.time_to_first_token.count() << "ms, "
                  << "Total: " << result.total_time.count() << "ms, "
                  << "Tokens: " << result.tokens_generated;
        
        if (result.tokens_generated > 0 && result.total_time.count() > 0) {
            float tokens_per_second = (float)result.tokens_generated * 1000.0f / result.total_time.count();
            std::cout << ", Speed: " << std::fixed << std::setprecision(1) << tokens_per_second << " tok/s";
        }
        
        if (context.isConversationActive()) {
            std::cout << ", Conversation Active";
        }
        std::cout << ")" << std::endl;
        std::cout << std::string(60, '-') << std::endl;
    }
}

void demonstrateChatMode(llama_mobile::llama_mobile_context& context) {
    std::cout << "\n=== Interactive Chat Demo ===" << std::endl;
    std::cout << "Type 'quit' to exit, 'clear' to reset conversation" << std::endl;
    
    std::string input;
    
    while (true) {
        std::cout << "\nYou: ";
        std::getline(std::cin, input);
        
        if (input == "quit" || input == "exit") {
            break;
        }
        
        if (input == "clear") {
            context.clearConversation();
            std::cout << "Conversation cleared." << std::endl;
            continue;
        }
        
        if (input.empty()) continue;
        
        auto start_time = std::chrono::high_resolution_clock::now();
        
        auto result = context.continueConversation(input, 200);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto total_time = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        std::cout << "Bot: " << result.text << std::endl;
        std::cout << "(TTFT: " << result.time_to_first_token.count() << "ms, "
                  << "Total: " << result.total_time.count() << "ms, "
                  << "Tokens: " << result.tokens_generated;
        
        if (result.tokens_generated > 0 && result.total_time.count() > 0) {
            float tokens_per_second = (float)result.tokens_generated * 1000.0f / result.total_time.count();
            std::cout << ", Speed: " << std::fixed << std::setprecision(1) << tokens_per_second << " tok/s";
        }
        std::cout << ")" << std::endl;
    }
}

void demonstrateSamplingVariations(llama_mobile::llama_mobile_context& context) {
    std::cout << "\n=== Sampling Variations Demo ===" << std::endl;
    
    const std::string prompt = "Write a creative opening line for a science fiction novel:";
    
    struct SamplingConfig {
        std::string name;
        float temperature;
        int top_k;
        float top_p;
        float repeat_penalty;
    };
    
    std::vector<SamplingConfig> configs = {
        {"Conservative", 0.3f, 20, 0.8f, 1.05f},
        {"Balanced", 0.7f, 40, 0.9f, 1.1f},
        {"Creative", 1.0f, 60, 0.95f, 1.15f},
        {"Wild", 1.3f, 80, 0.98f, 1.2f}
    };
    
    for (const auto& config : configs) {
        std::cout << "\n" << config.name << " sampling (temp=" << config.temperature 
                  << ", top_k=" << config.top_k << ", top_p=" << config.top_p << "):" << std::endl;
        
        // Configure sampling parameters
        context.params.sampling.temp = config.temperature;
        context.params.sampling.top_k = config.top_k;
        context.params.sampling.top_p = config.top_p;
        context.params.sampling.penalty_repeat = config.repeat_penalty;
        
        auto result = generateText(context, prompt, 80);
        std::cout << "Response: " << result.text << std::endl;
        std::cout << std::string(60, '-') << std::endl;
    }
}

int main(int argc, char **argv) {
    std::cout << "\n=== LLama Mobile LLM Example ===" << std::endl;

    // Step 1: Determine the model path
    std::string model_path;
    std::string demo_mode = "";
    
    // Parse command-line arguments
    if (argc > 1) {
        // Check if the first argument is a model path or demo mode
        std::string first_arg = argv[1];
        if (first_arg == "chat" || first_arg == "sampling" || first_arg == "basic") {
            demo_mode = first_arg;
        } else {
            // First argument is a model path
            model_path = first_arg;
            if (argc > 2) {
                demo_mode = argv[2];
            }
        }
    }
    
    // If no model path specified, try to find one
    if (model_path.empty()) {
        // Use local Qwen3 model by default with absolute path
        model_path = "/Users/shileipeng/Documents/mygithub/llama_mobile/models/Qwen3-1.7B-Q4_K_M.gguf";
        
        // Check if the specific model exists, otherwise try any GGUF file in the models directory
        if (!fs::exists(model_path)) {
            std::cout << "Model file not found: " << model_path << std::endl;
            std::cout << "Searching for any GGUF file in the models directory..." << std::endl;
            
            std::string models_dir = "/Users/shileipeng/Documents/mygithub/llama_mobile/models";
            
            if (fs::exists(models_dir)) {
                bool found = false;
                for (const auto& entry : fs::directory_iterator(models_dir)) {
                    if (entry.is_regular_file() && entry.path().extension() == ".gguf") {
                        model_path = entry.path().string();
                        std::cout << "Found model: " << model_path << std::endl;
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    std::cerr << "\n❌ ERROR: No GGUF files found in models directory: " << models_dir << std::endl;
                    std::cerr << "Please download at least one LLM model in GGUF format.\n" << std::endl;
                    std::cerr << "Example command:" << std::endl;
                    std::cerr << "  cd " << models_dir << std::endl;
                    std::cerr << "  wget https://huggingface.co/BAAI/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf\n" << std::endl;
                    return 1;
                }
            } else {
                std::cerr << "\n❌ ERROR: Models directory not found: " << models_dir << std::endl;
                std::cerr << "Please create this directory and place GGUF model files there.\n" << std::endl;
                std::cerr << "Example commands:" << std::endl;
                std::cerr << "  mkdir -p " << models_dir << std::endl;
                std::cerr << "  cd " << models_dir << std::endl;
                std::cerr << "  wget https://huggingface.co/BAAI/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf\n" << std::endl;
                return 1;
            }
        }
    }
    
    // Step 2: Verify the model file exists
    if (!fs::exists(model_path)) {
        std::cerr << "\n❌ ERROR: Model file not found: " << model_path << std::endl;
        std::cerr << "Please check the path and try again.\n" << std::endl;
        return 1;
    }
    
    std::cout << "Using model: " << model_path << std::endl;
    
    try {
        llama_mobile::llama_mobile_context context;
        
        // Configure model parameters
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 4096;
        params.n_batch = 512;
        params.n_gpu_layers = 99; // Use GPU acceleration
        params.cpuparams.n_threads = std::thread::hardware_concurrency();
        
        // Cache optimization parameters
        params.n_cache_reuse = 256; // Enable cache reuse with 256 token chunks
        params.n_keep = 32;         // Keep first 32 tokens during context shifts
        
        // Default sampling parameters
        params.sampling.temp = 0.7f;
        params.sampling.top_k = 40;
        params.sampling.top_p = 0.9f;
        params.sampling.penalty_repeat = 1.1f;
        
        // Configure stop tokens
        params.antiprompt.push_back("<|im_end|>");
        
        std::cout << "Loading model..." << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "\n❌ ERROR: Failed to load model: " << model_path << std::endl;
            std::cerr << "Possible reasons:" << std::endl;
            std::cerr << "  1. The file is not a valid GGUF LLM model" << std::endl;
            std::cerr << "  2. The model is corrupted" << std::endl;
            std::cerr << "  3. The model is not compatible with the current implementation" << std::endl;
            std::cerr << "  4. Insufficient memory to load the model\n" << std::endl;
            return 1;
        }
        
        std::cout << "Model loaded successfully!" << std::endl;
        
        // Run different demonstrations
        if (demo_mode == "chat") {
            demonstrateChatMode(context);
        } else if (demo_mode == "sampling") {
            demonstrateSamplingVariations(context);
        } else if (demo_mode == "basic") {
            demonstrateBasicGeneration(context);
        } else {
            std::cout << "\nAvailable demos:" << std::endl;
            std::cout << "  ./llama_mobile_llm [model_path] basic    - Compare traditional vs new conversation API" << std::endl;
            std::cout << "  ./llama_mobile_llm [model_path] chat     - Interactive chat with optimized KV caching" << std::endl;
            std::cout << "  ./llama_mobile_llm [model_path] sampling - Different sampling strategies" << std::endl;
            std::cout << "  ./llama_mobile_llm [model_path]          - Run basic demo with specified model" << std::endl;
            std::cout << "\nNew Conversation API Features:" << std::endl;
            std::cout << "  - Automatic KV cache optimization" << std::endl;
            std::cout << "  - Consistent TTFT regardless of conversation length" << std::endl;
            std::cout << "  - Simple context.continueConversation(message) interface" << std::endl;
            std::cout << "  - Built-in conversation state management" << std::endl;
            std::cout << "\nRunning basic demo by default...\n" << std::endl;
            
            demonstrateBasicGeneration(context);
        }
        
    } catch (const std::exception& e) {
        std::cerr << "\n❌ ERROR: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}