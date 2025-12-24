#include "llama_cpp/common.h"
#include <iostream>

int main(int argc, char** argv) {
    try {
        std::cout << "Starting direct test...\n";
        
        common_params params;
    params.model.path = "../../lib/models/SmolLM-360M-Instruct.Q6_K.gguf"; // Relative path from build/output to lib/models
        params.n_ctx = 2048;
        params.n_batch = 512;
        params.n_gpu_layers = 20; // Enable GPU with Metal
        params.cpuparams.n_threads = 4;
        params.use_mmap = true;
        params.embedding = false;
        
        std::cout << "Creating common_init_from_params...\n";
        auto init_result = common_init_from_params(params);
        
        if (!init_result) {
            std::cerr << "common_init_from_params returned null\n";
            return 1;
        }
        
        std::cout << "Model loaded successfully!\n";
        
        // Test basic model functionality
        std::cout << "Testing model context...\n";
        auto model = init_result->model();
        auto ctx = init_result->context();
        
        if (!model || !ctx) {
            std::cerr << "Model or context is null\n";
            return 1;
        }
        
        std::cout << "Model context is valid\n";
        
        // Test a simple tokenization
        std::string prompt = "Hello, world!";
        std::vector<llama_token> tokens;
        // Get vocabulary from model
        const struct llama_vocab * vocab = llama_model_get_vocab(model);
        if (!vocab) {
            std::cerr << "Failed to get vocabulary from model\n";
        } else {
            // Resize vector to hold tokens
            tokens.resize(100);
            int n_tokens = llama_tokenize(vocab, prompt.c_str(), prompt.size(), tokens.data(), tokens.size(), true, false);
            std::cout << "Tokenization test: " << n_tokens << " tokens generated\n";
        }
        
        std::cout << "Direct test completed successfully!\n";
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "Unknown exception\n";
        return 1;
    }
}