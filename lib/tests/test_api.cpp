#include <iostream>
#include <vector>
#include <string>
#include <dirent.h>
#include <cstring>
#include <iomanip>
#include <unistd.h>
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#endif
#include "../llama_mobile_api.h"

// Test result structure
struct TestResult {
    std::string name;
    bool passed;
    std::string details;
};

// Forward declarations
std::vector<std::string> list_models(const std::string& models_dir);
std::string select_model(const std::vector<std::string>& models);
void progress_callback(float progress);
bool token_callback(const char* token);

// Helper function to get executable directory
std::string get_executable_dir() {
    char buffer[2048]; // Increase buffer size to avoid overflow
    std::string path;
    
#if defined(__linux__)
    ssize_t len = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
    if (len != -1) {
        buffer[len] = '\0';
        path = buffer;
    }
#elif defined(__APPLE__)
    uint32_t size = sizeof(buffer);
    if (_NSGetExecutablePath(buffer, &size) == 0) {
        // _NSGetExecutablePath already null-terminates on success
        path = buffer;
        // Resolve symlinks if needed
        char resolved_path[2048];
        if (realpath(path.c_str(), resolved_path) != nullptr) {
            path = resolved_path;
        }
    }
#endif
    
    if (!path.empty()) {
        size_t last_slash = path.find_last_of("/");
        if (last_slash != std::string::npos) {
            return path.substr(0, last_slash);
        }
    }
    return "";
}

int main(int argc, char* argv[]) {
    std::vector<TestResult> test_results;
    
    std::string model_path;
    
    // Check if model path is provided as command-line argument
    if (argc > 1) {
        model_path = argv[1];
        std::cout << "Using model path from command line: " << model_path << "\n";
    } else {
        // Determine models directory relative to executable location
        std::string executable_dir = get_executable_dir();
        std::string models_dir = executable_dir + "/../../models";
        std::cout << "Executable directory: " << executable_dir << std::endl;
        std::cout << "Models directory: " << models_dir << std::endl;
        std::cout << "Executable directory: " << executable_dir << std::endl;
        std::cout << "Models directory: " << models_dir << std::endl;
        
        // List available models
        std::vector<std::string> models = list_models(models_dir);
        if (models.empty()) {
            std::cerr << "No models found in '" << models_dir << "' directory.\n";
            std::cerr << "Please place model files (.gguf) in the 'models' directory.\n";
            return 1;
        }
        
        // Let user select a model
        model_path = select_model(models);
    }
    std::cout << "Selected model: " << model_path << "\n";
    
    // Initialize model with embedding mode enabled (using full init API)
    std::cout << "Initializing model...\n";
    llama_mobile_init_params_t params = {0};
    params.model_path = model_path.c_str();
    params.n_ctx = 2048;
    params.n_gpu_layers = 20;  // Re-enable GPU with 20 layers offloaded to Metal
    params.n_threads = 4;
    params.progress_callback = progress_callback;
    params.embedding = false;  // Disable global embedding mode
    params.use_mmap = true;
    params.n_batch = 512;
    
    std::cout << "Calling llama_mobile_init...\n";
    llama_mobile_context_t ctx = llama_mobile_init(&params);
    
    std::cout << "llama_mobile_init returned: " << (void*)ctx << "\n";
    
    if (ctx == nullptr) {
        std::cerr << "Failed to initialize model\n";
        return 1;
    }
    std::cout << "Model initialized successfully\n";
    
    // Test 1: Completion API
    std::cout << "\n--- Testing Completion API ---\n";
    const char* prompt = "Hello, world!";
    llama_mobile_completion_result_t result;
    
    int status = llama_mobile_completion_simple(
        ctx,
        prompt,
        128,    // max_tokens
        0.8,    // temperature
        token_callback,
        &result
    );
    
    TestResult completion_result = {"Completion API", false, ""};
    if (status == 0 && result.text) {
        std::cout << "\nFull completion result: " << result.text << "\n";
        completion_result.passed = true;
        completion_result.details = "Generated completion successfully";
        llama_mobile_free_completion_result(&result);
    } else {
        std::cerr << "Completion failed with status: " << status << "\n";
        completion_result.details = "Failed with status: " + std::to_string(status);
    }
    test_results.push_back(completion_result);
    

    
    // Test 3: Tokenization API
    std::cout << "\n--- Testing Tokenization API ---\n";
    const char* tokenize_prompt = "Testing tokenization API.";
    
    TestResult tokenization_result = {"Tokenization API", false, ""};
    llama_mobile_token_array_t tokens = llama_mobile_tokenize(ctx, tokenize_prompt);
    if (tokens.tokens && tokens.count > 0) {
        std::cout << "Tokenization successful. Token count: " << tokens.count << "\n";
        std::cout << "Tokens: ";
        for (int i = 0; i < tokens.count; i++) {
            std::cout << tokens.tokens[i] << " ";
        }
        std::cout << "\n";
        
        // Test detokenization
        bool detokenization_success = false;
        char* detokenized = llama_mobile_detokenize(ctx, tokens.tokens, tokens.count);
        if (detokenized) {
            std::cout << "Detokenized text: " << detokenized << "\n";
            llama_mobile_free_string(detokenized);
            detokenization_success = true;
        }
        
        tokenization_result.passed = detokenization_success;
        tokenization_result.details = "Token count: " + std::to_string(tokens.count) + ", Detokenization: " + (detokenization_success ? "success" : "failed");
        
        llama_mobile_free_token_array(tokens);
    } else {
        std::cerr << "Tokenization failed\n";
        tokenization_result.details = "Failed to tokenize text";
    }
    test_results.push_back(tokenization_result);
    
    // Test 4: Conversation API
    std::cout << "\n--- Testing Conversation API ---\n";
    const char* user_message = "Tell me a short joke.";
    llama_mobile_conversation_result_t conv_result;
    
    TestResult conversation_result = {"Conversation API", false, ""};
    status = llama_mobile_generate_response_simple(
        ctx,
        user_message,
        128,    // max_tokens
        &conv_result
    );
    
    if (status == 0 && conv_result.text) {
        std::cout << "Conversation response: " << conv_result.text << "\n";
        conversation_result.passed = true;
        conversation_result.details = "Generated response successfully";
        llama_mobile_free_conversation_result(&conv_result);
    } else {
        std::cerr << "Conversation API failed with status: " << status << "\n";
        conversation_result.details = "Failed with status: " + std::to_string(status);
    }
    test_results.push_back(conversation_result);
    
    // Test 5: Clear Conversation API
    std::cout << "\n--- Testing Clear Conversation API ---\n";
    TestResult clear_conv_result = {"Clear Conversation API", false, ""};
    llama_mobile_clear_conversation(ctx);
    // Clear conversation is void, so assume success
    clear_conv_result.passed = true;
    clear_conv_result.details = "Conversation cleared successfully";
    std::cout << "Conversation cleared successfully\n";
    test_results.push_back(clear_conv_result);
    
    // Test 6: Try conversation again after clearing
    std::cout << "\n--- Testing Conversation API Again After Clear ---\n";
    const char* new_message = "What's the weather like?";
    llama_mobile_conversation_result_t new_conv_result;
    
    TestResult conv_after_clear_result = {"Conversation API After Clear", false, ""};
    status = llama_mobile_generate_response_simple(
        ctx,
        new_message,
        128,    // max_tokens
        &new_conv_result
    );
    
    if (status == 0 && new_conv_result.text) {
        std::cout << "New conversation response: " << new_conv_result.text << "\n";
        conv_after_clear_result.passed = true;
        conv_after_clear_result.details = "Generated response successfully after clear";
        llama_mobile_free_conversation_result(&new_conv_result);
    } else {
        std::cerr << "Conversation API failed after clear with status: " << status << "\n";
        conv_after_clear_result.details = "Failed with status: " + std::to_string(status);
    }
    test_results.push_back(conv_after_clear_result);
    
    // Cleanup original context before embedding tests
    std::cout << "\n--- Cleaning up original context ---\n";
    llama_mobile_free(ctx);
    std::cout << "Original context freed successfully\n";
    
    // Test 2: Embedding API with separate context
    std::cout << "\n--- Testing Embedding API with embedding mode enabled ---\n";
    
    // Create new context with embedding mode enabled
    std::cout << "Initializing new context with embedding mode enabled...\n";
    llama_mobile_init_params_t embed_params = {0};
    embed_params.model_path = model_path.c_str();
    embed_params.n_ctx = 2048;
    embed_params.n_gpu_layers = -1;  // Disable GPU
    embed_params.n_threads = 4;
    embed_params.progress_callback = progress_callback;
    embed_params.embedding = true;  // Enable embedding mode specifically for embedding tests
    embed_params.use_mmap = true;
    embed_params.n_batch = 512;
    
    llama_mobile_context_t embed_ctx = llama_mobile_init(&embed_params);
    
    if (embed_ctx == nullptr) {
        std::cerr << "Failed to initialize embedding context\n";
        TestResult embedding_result = {"Embedding API", false, "Failed to initialize embedding context"};
        test_results.push_back(embedding_result);
    } else {
        std::cout << "Embedding context initialized successfully\n";
        
        const char* embed_prompt = "This is a test sentence for embedding.";
        TestResult embedding_result = {"Embedding API", false, ""};
        
        llama_mobile_float_array_t embedding = llama_mobile_embedding(embed_ctx, embed_prompt);
        if (embedding.values && embedding.count > 0) {
            std::cout << "Embedding generated successfully. Dimension: " << embedding.count << "\n";
            std::cout << "First 5 values: ";
            for (int i = 0; i < std::min(5, (int)embedding.count); i++) {
                std::cout << embedding.values[i] << " ";
            }
            std::cout << "\n";
            embedding_result.passed = true;
            embedding_result.details = "Generated embedding with dimension: " + std::to_string(embedding.count);
            llama_mobile_free_float_array(embedding);
        } else {
            std::cerr << "Embedding failed\n";
            embedding_result.details = "Failed to generate embedding";
        }
        
        test_results.push_back(embedding_result);
        
        // Cleanup embedding context
        std::cout << "\n--- Cleaning up embedding context ---\n";
        llama_mobile_free(embed_ctx);
        std::cout << "Embedding context freed successfully\n";
    }
    
    // Generate comprehensive test report
    std::cout << "\n" << std::string(60, '=') << "\n";
    std::cout << "            LLAMA MOBILE API TEST REPORT\n";
    std::cout << std::string(60, '=') << "\n";
    
    int passed_count = 0;
    int failed_count = 0;
    
    // Summary table
    std::cout << "\nSUMMARY:\n";
    std::cout << "----------------------------------------------------------------------------\n";
    std::cout << std::left << std::setw(40) << "Test" << std::setw(15) << "Status" << "Details" << "\n";
    std::cout << "----------------------------------------------------------------------------\n";
    
    for (const auto& test : test_results) {
        if (test.passed) {
            passed_count++;
        } else {
            failed_count++;
        }
        
        std::string status = test.passed ? "PASSED" : "FAILED";
        std::cout << std::left << std::setw(40) << test.name << std::setw(15) << status << test.details << "\n";
    }
    
    std::cout << "----------------------------------------------------------------------------\n";
    std::cout << std::left << std::setw(40) << "Total Tests" << std::setw(15) << (passed_count + failed_count) << "\n";
    std::cout << std::left << std::setw(40) << "Tests Passed" << std::setw(15) << passed_count << "\n";
    std::cout << std::left << std::setw(40) << "Tests Failed" << std::setw(15) << failed_count << "\n";
    
    if (failed_count == 0) {
        std::cout << "\n✅ ALL TESTS PASSED!\n";
    } else {
        std::cout << "\n❌ SOME TESTS FAILED!\n";
    }
    
    std::cout << std::string(60, '=') << "\n";
    
    return failed_count == 0 ? 0 : 1;
}

// Helper functions
std::vector<std::string> list_models(const std::string& models_dir) {
    std::vector<std::string> models;
    DIR* dir = opendir(models_dir.c_str());
    
    if (dir) {
        struct dirent* entry;
        while ((entry = readdir(dir)) != nullptr) {
            if (entry->d_type == DT_REG) {
                std::string filename = entry->d_name;
                if (filename.size() >= 5 && filename.substr(filename.size() - 5) == ".gguf") {
                    models.push_back(models_dir + "/" + filename);
                }
            }
        }
        closedir(dir);
    }
    
    return models;
}

std::string select_model(const std::vector<std::string>& models) {
    std::cout << "Available models:\n";
    for (size_t i = 0; i < models.size(); i++) {
        std::cout << "  " << i + 1 << ". " << models[i] << "\n";
    }
    
    int choice;
    while (true) {
        std::cout << "Enter your choice (1-" << models.size() << "): ";
        std::cin >> choice;
        
        if (choice >= 1 && choice <= static_cast<int>(models.size())) {
            return models[choice - 1];
        }
        
        std::cout << "Invalid choice. Please try again.\n";
    }
}

void progress_callback(float progress) {
    std::cout << "Progress: " << (progress * 100.0f) << "%\r";
    std::cout.flush();
}

bool token_callback(const char* token) {
    std::cout << token;
    std::cout.flush();
    return true;  // Continue generation
}
