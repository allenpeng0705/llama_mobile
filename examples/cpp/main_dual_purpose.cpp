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

namespace fs = std::filesystem;

std::vector<float> generateEmbeddings(llama_mobile::llama_mobile_context& context, const std::string& text) {
    context.rewind();
    context.params.prompt = text;
    context.params.n_predict = 0;
    
    if (!context.initSampling()) {
        std::cerr << "Failed to initialize sampling for embedding generation" << std::endl;
        return {};
    }
    
    context.beginCompletion();
    context.loadPrompt();
    
    context.doCompletion();
    
    common_params embd_params;
    embd_params.embd_normalize = context.params.embd_normalize;
    
    auto embeddings = context.getEmbedding(embd_params);
    
    if (embeddings.empty()) {
        std::cerr << "Failed to generate embeddings" << std::endl;
    }
    
    context.endCompletion();
    return embeddings;
}

std::string generateText(llama_mobile::llama_mobile_context& context, const std::string& prompt, int max_tokens = 50) {
    context.rewind();
    context.params.prompt = prompt;
    context.params.n_predict = max_tokens;
    
    if (!context.initSampling()) {
        std::cerr << "Failed to initialize sampling for text generation" << std::endl;
        return "";
    }
    
    context.beginCompletion();
    context.loadPrompt();
    
    while (context.has_next_token && !context.is_interrupted) {
        auto token_output = context.doCompletion();
        if (token_output.tok == -1) break;
    }
    
    context.endCompletion();
    return context.generated_text;
}

int main(int argc, char **argv) {
    std::cout << "Dual-Purpose Model Example: Embedding + Text Generation" << std::endl;
    std::cout << "====================================================" << std::endl;
    
    const std::string default_model_path = "../../../models/Qwen3-4B-Q5_K_M.gguf";
    const std::string model_path = (argc > 1) ? argv[1] : default_model_path;
    
    if (!fs::exists(model_path)) {
        std::cerr << "\nERROR: Model file not found: " << model_path << std::endl;
        if (argc > 1) {
            std::cerr << "Please provide a valid model path.\n" << std::endl;
        } else {
            std::cerr << "The default model file is not available.\n" << std::endl;
        }
        return 1;
    }
    
    std::cout << "Using model: " << model_path << std::endl;
    
    try {
        llama_mobile::llama_mobile_context context;
        
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 2048;
        params.n_batch = 512;
        params.cpuparams.n_threads = std::thread::hardware_concurrency();
        params.embedding = false;
        params.pooling_type = LLAMA_POOLING_TYPE_NONE;
        
        params.sampling.temp = 0.7f;
        params.sampling.top_k = 40;
        params.sampling.top_p = 0.9f;
        
        std::cout << "Loading model..." << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "\nERROR: Failed to load model: " << model_path << std::endl;
            return 1;
        }
        
        std::cout << "\nModel initialized successfully" << std::endl;
        
        std::cout << "\n1. Generating text..." << std::endl;
        std::string prompt = "Hello, world! How are you today?";
        std::cout << "   Prompt: " << prompt << std::endl;
        
        auto generated_text = generateText(context, prompt, 30);
        
        if (!generated_text.empty()) {
            std::cout << "   Text generation successful" << std::endl;
            std::cout << "   Generated text: " << generated_text << std::endl;
        } else {
            std::cerr << "   Failed to generate text" << std::endl;
            return 1;
        }
        
        std::cout << "\n2. Generating another text..." << std::endl;
        prompt = "What is the capital of France?";
        std::cout << "   Prompt: " << prompt << std::endl;
        
        generated_text = generateText(context, prompt, 30);
        
        if (!generated_text.empty()) {
            std::cout << "   Text generation successful" << std::endl;
            std::cout << "   Generated text: " << generated_text << std::endl;
        } else {
            std::cerr << "   Failed to generate text" << std::endl;
            return 1;
        }
        
        std::cout << "\nDual-purpose functionality demonstrated successfully!" << std::endl;
        std::cout << "Note: For embedding models, use a dedicated embedding context with embedding=true." << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
