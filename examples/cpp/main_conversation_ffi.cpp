#include <iostream>
#include <string>
#include <vector>
#include <iomanip>
#include <chrono>
#include <dirent.h>
#include <cstring>
#include <algorithm>

#include "utils.h"
#include "../../lib/llama_mobile_ffi.h"

// Function to list available GGUF models in lib/models (excluding embedding folder)
std::vector<std::string> list_available_models(const std::string& models_dir) {
    std::vector<std::string> models;
    DIR* dir;
    struct dirent* entry;

    if ((dir = opendir(models_dir.c_str())) != NULL) {
        while ((entry = readdir(dir)) != NULL) {
            if (entry->d_type == DT_REG) { // Regular file
                std::string filename = entry->d_name;
                if (filename.size() >= 5 && filename.substr(filename.size() - 5) == ".gguf") {
                    models.push_back(filename);
                }
            }
        }
        closedir(dir);
    }

    // Sort models alphabetically
    std::sort(models.begin(), models.end());
    return models;
}

void print_performance_metrics(const llama_mobile_conversation_result_c_t& result) {
    std::cout << "[PERFORMANCE] TTFT: " << result.time_to_first_token << "ms, "
              << "Total: " << result.total_time << "ms, "
              << "Tokens: " << result.tokens_generated;
    
    if (result.tokens_generated > 0 && result.total_time > 0) {
        float tokens_per_second = (float)result.tokens_generated * 1000.0f / result.total_time;
        std::cout << ", Speed: " << std::fixed << std::setprecision(1) 
                  << tokens_per_second << " tok/s";
    }
    std::cout << std::endl;
}

bool conversation_demo(llama_mobile_context_handle_t handle) {
    std::cout << "\n=== Conversation Management Demo ===" << std::endl;
    
    std::vector<std::string> messages = {
        "Hello! How are you today?",
        "What can you help me with?", 
        "Tell me a fun fact about space",
        "Can you explain that in simpler terms?",
        "Thank you for the explanation!"
    };
    
    for (size_t i = 0; i < messages.size(); ++i) {
        std::cout << "\nTurn " << (i + 1) << ":" << std::endl;
        std::cout << "User: " << messages[i] << std::endl;
        
        auto start_time = std::chrono::high_resolution_clock::now();
        
        llama_mobile_conversation_result_c_t result = llama_mobile_continue_conversation_c(handle, messages[i].c_str(), 150);
        
        auto end_time = std::chrono::high_resolution_clock::now();
        auto js_overhead = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time);
        
        if (!result.text) {
            std::cerr << "Failed to get response for message: " << messages[i] << std::endl;
            return false;
        }
        
        std::cout << "Assistant: " << result.text << std::endl;
        print_performance_metrics(result);
        std::cout << "[TIMING] C++ FFI overhead: " << (js_overhead.count() - result.total_time) << "ms" << std::endl;
        
        // Check conversation status
        bool is_active = llama_mobile_is_conversation_active_c(handle);
        std::cout << "[STATUS] Conversation active: " << (is_active ? "Yes" : "No") << std::endl;
        
        llama_mobile_free_conversation_result_members_c(&result);
        
        std::cout << std::string(60, '-') << std::endl;
    }
    
    return true;
}

bool simple_response_demo(llama_mobile_context_handle_t handle) {
    std::cout << "\n=== Simple Response Demo ===" << std::endl;
    
    std::vector<std::string> prompts = {
        "Write a haiku about programming",
        "What is the meaning of life?",
        "Explain quantum computing in one sentence"
    };
    
    for (const auto& prompt : prompts) {
        std::cout << "\nPrompt: " << prompt << std::endl;
        
        char* response = llama_mobile_generate_response_c(handle, prompt.c_str(), 100);
        
        if (!response) {
            std::cerr << "Failed to generate response" << std::endl;
            return false;
        }
        
        std::cout << "Response: " << response << std::endl;
        llama_mobile_free_string_c(response);
        
        std::cout << std::string(50, '-') << std::endl;
    }
    
    return true;
}

int main(int argc, char **argv) {
    const std::string model_url = "https://huggingface.co/QuantFactory/SmolLM-360M-Instruct-GGUF/resolve/main/SmolLM-360M-Instruct.Q6_K.gguf";
    const std::string model_filename = "SmolLM-360M-Instruct.Q6_K.gguf";
    const std::string models_dir = "../../../lib/models";
    std::string final_model_path;
    bool is_demo_mode = false;
    std::string demo_mode;
    
    // First, check if the first argument is a demo mode
    if (argc > 1) {
        std::string first_arg = argv[1];
        if (first_arg == "chat" || first_arg == "sampling" || first_arg == "basic" || first_arg == "simple" || first_arg == "conversation") {
            is_demo_mode = true;
            demo_mode = first_arg;
        } else if (first_arg.find(".gguf") == std::string::npos) {
            // Not a model path, assume demo mode
            is_demo_mode = true;
            demo_mode = first_arg;
        }
    }
    
    // Download the fallback model if it doesn't exist in current directory
    std::cout << "Checking for fallback model..." << std::endl;
    if (!downloadFile(model_url, model_filename, "SmolLM Model")) {
        std::cerr << "Warning: Failed to download fallback model, but will continue with available models." << std::endl;
    }
    
    // Determine which model path to use
    if (argc > 1 && !is_demo_mode) {
        // User-provided model path
        final_model_path = argv[1];
    } else {
        // List available models from both lib/models and current directory
        std::cout << "\n=== Available Models ===\n";
        
        // Get models from lib/models
        std::vector<std::string> models = list_available_models(models_dir);
        std::vector<std::string> model_paths;
        
        // Add models from lib/models
        for (const auto& model : models) {
            model_paths.push_back(models_dir + "/" + model);
        }
        
        // Check if fallback model exists in current directory and add it
        if (fileExists(model_filename)) {
            models.push_back(model_filename);
            model_paths.push_back(model_filename);
        }
        
        if (models.empty()) {
            std::cerr << "No GGUF models found!" << std::endl;
            return 1;
        }
        
        // Display available models
        for (size_t i = 0; i < models.size(); ++i) {
            std::cout << i + 1 << ". " << models[i] << std::endl;
        }
        
        // Get user selection
        std::cout << "\nSelect a model by number: ";
        int selection;
        std::cin >> selection;
        
        if (selection < 1 || selection > static_cast<int>(models.size())) {
            std::cerr << "Invalid selection\n";
            return 1;
        }
        
        // Use the selected model path
        final_model_path = model_paths[selection - 1];
    }
    
    std::cout << "\n=== Cactus Conversation FFI Example ===" << std::endl;
    std::cout << "Using model: " << final_model_path << std::endl;
    
    try {
        // Initialize context using FFI
        llama_mobile_init_params_c_t init_params = {};
        init_params.model_path = final_model_path.c_str();
        init_params.chat_template = nullptr;
        init_params.n_ctx = 2048;
        init_params.n_batch = 512;
        init_params.n_ubatch = 512;
        init_params.n_gpu_layers = 99; // Use GPU acceleration
        init_params.n_threads = 4;
        init_params.use_mmap = true;
        init_params.use_mlock = false;
        init_params.embedding = false;
        init_params.pooling_type = 0;
        init_params.embd_normalize = 2;
        init_params.flash_attn = false;
        init_params.cache_type_k = nullptr;
        init_params.cache_type_v = nullptr;
        init_params.progress_callback = nullptr;

        std::cout << "Loading model: " << final_model_path << std::endl;
        llama_mobile_context_handle_t handle = llama_mobile_init_context_c(&init_params);
        if (!handle) {
            std::cerr << "Failed to load model" << std::endl;
            return 1;
        }

        std::cout << "Model loaded successfully!" << std::endl;
        
        // Get model information
        char* model_desc = llama_mobile_get_model_desc_c(handle);
        int32_t n_ctx = llama_mobile_get_n_ctx_c(handle);
        std::cout << "Model: " << (model_desc ? model_desc : "Unknown") << std::endl;
        std::cout << "Context size: " << n_ctx << std::endl;
        llama_mobile_free_string_c(model_desc);
        
        // Run different demos based on the demo mode
        if (demo_mode == "simple") {
            if (!simple_response_demo(handle)) {
                llama_mobile_free_context_c(handle);
                return 1;
            }
        } else if (demo_mode == "conversation") {
            if (!conversation_demo(handle)) {
                llama_mobile_free_context_c(handle);
                return 1;
            }
        } else {
            std::cout << "\nAvailable demos:" << std::endl;
            std::cout << "  ./conversation_ffi simple       - Simple generateResponse demo" << std::endl;
            std::cout << "  ./conversation_ffi conversation - Full conversation management demo" << std::endl;
            std::cout << "\nNew Conversation API Features:" << std::endl;
            std::cout << "  - Automatic KV cache optimization" << std::endl;
            std::cout << "  - Consistent TTFT across conversation turns" << std::endl;
            std::cout << "  - Built-in performance timing" << std::endl;
            std::cout << "  - Simple conversation state management" << std::endl;
            std::cout << "\nRunning conversation demo by default...\n" << std::endl;
            
            if (!conversation_demo(handle)) {
                llama_mobile_free_context_c(handle);
                return 1;
            }
        }
        
        // Clear conversation and test state
        std::cout << "\nClearing conversation..." << std::endl;
        llama_mobile_clear_conversation_c(handle);
        bool is_active = llama_mobile_is_conversation_active_c(handle);
        std::cout << "Conversation active after clear: " << (is_active ? "Yes" : "No") << std::endl;

        // Clean up
        llama_mobile_free_context_c(handle);
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
} 