#include "llama_mobile.h"
#include "llama_cpp/common.h"
#include "llama_cpp/llama.h"

#include <iostream>
#include <vector>
#include <string>

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <model_path>" << std::endl;
        return 1;
    }

    std::string model_path = argv[1];
    std::cout << "Testing chat template and JSON response wrapping with model: " << model_path << std::endl;
    
    try {
        // Initialize the llama_mobile context
        auto context = std::make_shared<llama_mobile::llama_mobile_context>();
        
        // Set up params
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 2048;
        params.n_gpu_layers = 0;
        params.cpuparams.n_threads = 4;
        params.n_predict = 100;
        params.sampling.temp = 0.7;
        params.sampling.top_p = 0.9;
        
        if (!context->loadModel(params)) {
            std::cerr << "Failed to load model" << std::endl;
            return 1;
        }
        
        std::cout << "Model loaded successfully" << std::endl;
        
        // Create chat messages (OpenAI format)
        std::vector<llama_chat_message> chat_messages = {
            {"system", "You are a helpful assistant."},
            {"user", "Hello, how are you?"}
        };
        
        context->params.chat_messages = chat_messages;
        context->params.use_json_response = true; // Enable JSON response wrapping
        
        std::cout << "\n=== Testing Chat Template with JSON Response ===" << std::endl;
        std::cout << "Chat messages: " << chat_messages.size() << std::endl;
        std::cout << "JSON response: " << (context->params.use_json_response ? "enabled" : "disabled") << std::endl;
        
        // Load prompt with chat template
        context->loadPrompt();
        
        // Generate completion
        context->beginCompletion();
        
        std::cout << "\nGenerating completion..." << std::endl;
        std::cout << "============================================" << std::endl;
        
        while (context->has_next_token && !context->is_interrupted) {
            auto token_output = context->doCompletion();
            
            if (token_output.tok == -1 && !context->has_next_token) {
                break;
            }
        }
        
        // Get the result
        std::string result = context->generated_text;
        
        std::cout << "\n============================================" << std::endl;
        std::cout << "Completion result:" << std::endl;
        std::cout << "--------------------------------------------" << std::endl;
        std::cout << result << std::endl;
        std::cout << "\nTokens generated: " << context->num_tokens_predicted << std::endl;
        std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
        std::cout << "\nTest completed successfully!" << std::endl;
        
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}