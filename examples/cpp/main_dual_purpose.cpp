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

// Helper function to generate embeddings
std::vector<float> generateEmbeddings(llama_mobile::llama_mobile_context& context, const std::string& text) {
    context.rewind();
    context.params.prompt = text;
    context.params.n_predict = 0; // Only want embeddings, no generation
    
    if (!context.initSampling()) {
        std::cerr << "Failed to initialize sampling for embedding generation" << std::endl;
        return {};
    }
    
    context.beginCompletion();
    context.loadPrompt();
    
    // Process the prompt to get embeddings
    context.doCompletion();
    
    // Create embedding parameters
    common_params embd_params;
    embd_params.embd_normalize = context.params.embd_normalize;
    
    // Get embeddings for the prompt
    auto embeddings = context.getEmbedding(embd_params);
    
    if (embeddings.empty()) {
        std::cerr << "Failed to generate embeddings" << std::endl;
    }
    
    return embeddings;
}

// Helper function to generate text
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
    
    // Process tokens for text generation
    while (context.has_next_token && !context.is_interrupted) {
        auto token_output = context.doCompletion();
        if (token_output.tok == -1) break;
    }
    
    // Return the accumulated generated text
    return context.generated_text;
}

int main(int argc, char **argv) {
    std::cout << "Dual-Purpose Model Example: Embedding + Text Generation" << std::endl;
    std::cout << "====================================================" << std::endl;
    
    // Default model path - use the specified Qwen3-4B-Q5_K_M.gguf model
    const std::string default_model_path = "../../models/Qwen3-4B-Q5_K_M.gguf";
    
    // Use provided model path if argument is given, otherwise use the default
    const std::string model_path = (argc > 1) ? argv[1] : default_model_path;
    
    // Check if the model file exists
    if (!fs::exists(model_path)) {
        std::cerr << "\n❌ ERROR: Model file not found: " << model_path << std::endl;
        if (argc > 1) {
            std::cerr << "Please provide a valid model path.\n" << std::endl;
        } else {
            std::cerr << "The default model file is not available.\n" << std::endl;
        }
        return 1;
    }
    
    std::cout << "Using model: " << model_path << std::endl;
    
    try {
        // Create context object
        llama_mobile::llama_mobile_context context;
        
        // Configure model parameters
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 2048;
        params.n_batch = 512;
        params.cpuparams.n_threads = std::thread::hardware_concurrency();
        params.embedding = true; // Enable embedding functionality
        params.pooling_type = LLAMA_POOLING_TYPE_MEAN; // Mean pooling
        
        // Configure sampling parameters
        params.sampling.temp = 0.7f;
        params.sampling.top_k = 40;
        params.sampling.top_p = 0.9f;
        
        std::cout << "Loading model..." << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "\n❌ ERROR: Failed to load model: " << model_path << std::endl;
            return 1;
        }
        
        std::cout << "\n✅ Model initialized successfully with embedding enabled" << std::endl;
        
        // 1. Generate embeddings
        std::cout << "\n1. Generating embeddings for: \"Hello, world!\"" << std::endl;
        auto embeddings = generateEmbeddings(context, "Hello, world!");
        
        if (!embeddings.empty()) {
            std::cout << "   ✅ Embeddings generated successfully" << std::endl;
            std::cout << "   Embedding dimension: " << embeddings.size() << std::endl;
            std::cout << "   First 5 embedding values: " << std::fixed << std::setprecision(4);
            for (size_t i = 0; i < 5 && i < embeddings.size(); ++i) {
                std::cout << embeddings[i] << ((i < 4) ? ", " : "");
            }
            std::cout << std::endl;
        } else {
            std::cerr << "   ❌ Failed to generate embeddings" << std::endl;
            return 1;
        }
        
        // 2. Generate text from the same model instance
        std::cout << "\n2. Generating text from the same model instance..." << std::endl;
        std::string prompt = "Hello, world! How are you today?";
        std::cout << "   Prompt: " << prompt << std::endl;
        
        auto generated_text = generateText(context, prompt, 30);
        
        if (!generated_text.empty()) {
            std::cout << "   ✅ Text generation successful" << std::endl;
            std::cout << "   Generated text: " << generated_text << std::endl;
        } else {
            std::cerr << "   ❌ Failed to generate text" << std::endl;
            return 1;
        }
        
        // 3. Generate embeddings for another text
        std::cout << "\n3. Generating embeddings for another text: \"Goodbye, world!\"" << std::endl;
        auto embeddings2 = generateEmbeddings(context, "Goodbye, world!");
        
        if (!embeddings2.empty()) {
            std::cout << "   ✅ Embeddings generated successfully" << std::endl;
            std::cout << "   Embedding dimension: " << embeddings2.size() << std::endl;
        } else {
            std::cerr << "   ❌ Failed to generate embeddings" << std::endl;
            return 1;
        }
        
        std::cout << "\n🎉 Dual-purpose functionality demonstrated successfully!" << std::endl;
        std::cout << "The same model can be used for both embedding generation and text generation." << std::endl;
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
