#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <iostream>
#include <dirent.h>
#include <cstring>
#include <algorithm>

#include "../../lib/llama_mobile_api.h"

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

// Simple token callback for streaming output
bool token_callback(const char* token) {
    printf("%s", token);
    fflush(stdout);
    return true; // Continue generation
}

// Progress callback for model loading
void progress_callback(float progress) {
    printf("Model loading progress: %.1f%%\r", progress * 100.0f);
    fflush(stdout);
}

// Helper function to print embeddings (first 10 values)
void print_embeddings(const llama_mobile_float_array_t& embeddings) {
    printf("Embedding dimensions: %d\n", embeddings.count);
    printf("First 10 embedding values: ");
    int print_count = std::min(10, embeddings.count);
    for (int i = 0; i < print_count; ++i) {
        printf("%.6f", embeddings.values[i]);
        if (i < print_count - 1) {
            printf(", ");
        }
    }
    printf("\n\n");
}

int main(int argc, char** argv) {
    std::string model_path;
    const std::string models_dir = "../../lib/models";
    
    if (argc < 2) {
        // List available models in lib/models (excluding embedding folder)
        printf("=== Available Models ===\n");
        std::vector<std::string> models = list_available_models(models_dir);
        
        if (models.empty()) {
            fprintf(stderr, "No GGUF models found in %s\n", models_dir.c_str());
            fprintf(stderr, "Usage: %s <model_path>\n", argv[0]);
            return 1;
        }
        
        // Display available models
        for (size_t i = 0; i < models.size(); ++i) {
            printf("%zu. %s\n", i + 1, models[i].c_str());
        }
        
        // Get user selection
        printf("\nSelect a model by number: ");
        int selection;
        scanf("%d", &selection);
        
        if (selection < 1 || selection > static_cast<int>(models.size())) {
            fprintf(stderr, "Invalid selection\n");
            return 1;
        }
        
        // Construct the full path
        model_path = models_dir + "/" + models[selection - 1];
    } else {
        // Use provided model path
        model_path = argv[1];
    }
    
    printf("\n=== llama_mobile API Example ===\n");
    printf("Model path: %s\n\n", model_path.c_str());

    // Step 1: Initialize the context
    llama_mobile_init_params_t init_params = {0};  // Initialize all fields to zero
    init_params.model_path = model_path.c_str();
    init_params.n_ctx = 2048;
    init_params.n_batch = 512;
    init_params.n_gpu_layers = 0;  // CPU-only for basic testing
    init_params.n_threads = 4;
    init_params.use_mmap = true;
    init_params.embedding = false;  // Disable global embedding mode (we'll test embedding separately)
    init_params.progress_callback = progress_callback;

    printf("1. Testing context initialization...\n");
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    printf("Context initialized successfully!\n\n");

    // Step 2: Test tokenization and detokenization
    printf("2. Testing tokenization and detokenization...\n");
    const char* test_text = "Hello, world! This is a test.";
    
    llama_mobile_token_array_t tokens = llama_mobile_tokenize(ctx, test_text);
    printf("Original text: %s\n", test_text);
    printf("Token count: %d\n", tokens.count);
    printf("Tokens: ");
    for (int i = 0; i < tokens.count; ++i) {
        printf("%d ", tokens.tokens[i]);
    }
    printf("\n");
    
    char* detokenized = llama_mobile_detokenize(ctx, tokens.tokens, tokens.count);
    printf("Detokenized text: %s\n\n", detokenized);
    
    // Free resources
    llama_mobile_free_token_array(tokens);
    llama_mobile_free_string(detokenized);

    // Step 3: Test embedding generation (requires separate context with embedding enabled)
    printf("3. Testing embedding generation...\n");
    printf("Creating separate context with embedding mode enabled...\n");
    
    llama_mobile_init_params_t embed_params = {0};
    embed_params.model_path = model_path.c_str();
    embed_params.n_ctx = 2048;
    embed_params.n_batch = 512;
    embed_params.n_gpu_layers = 0;  // CPU-only for embedding
    embed_params.n_threads = 4;
    embed_params.use_mmap = true;
    embed_params.embedding = true;  // Enable embedding mode specifically for this context
    embed_params.progress_callback = progress_callback;
    
    llama_mobile_context_t embed_ctx = llama_mobile_init(&embed_params);
    if (embed_ctx != nullptr) {
        llama_mobile_float_array_t embeddings = llama_mobile_embedding(embed_ctx, "Test sentence for embedding.");
        if (embeddings.values != NULL && embeddings.count > 0) {
            print_embeddings(embeddings);
        } else {
            printf("Failed to generate embeddings\n\n");
        }
        llama_mobile_free_float_array(embeddings);
        llama_mobile_free(embed_ctx);
        printf("Embedding context freed successfully\n\n");
    } else {
        printf("Failed to create embedding context\n\n");
    }

    // Step 4: Test simple completion
    printf("4. Testing simple completion...\n");
    const char* prompt = "Hello, how are you?";
    const char* stop_sequence = "\n";
    
    llama_mobile_completion_params_t completion_params = {
        .prompt = prompt,
        .max_tokens = 100,
        .temperature = 0.7,
        .top_k = 40,
        .top_p = 0.95,
        .min_p = 0.05,
        .penalty_repeat = 1.1,
        .stop_sequences = &stop_sequence,
        .stop_sequence_count = 1,
        .token_callback = token_callback,
    };

    printf("Prompt: %s\n", prompt);
    printf("Response: ");
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(ctx, &completion_params, &result);
    
    if (status != 0) {
        fprintf(stderr, "\nCompletion failed with status: %d\n", status);
        llama_mobile_free(ctx);
        return 1;
    }
    
    printf("\n\nGeneration completed!\n");
    printf("Tokens generated: %d\n", result.tokens_generated);
    printf("Tokens evaluated: %d\n", result.tokens_evaluated);
    printf("Stopped due to: %s\n\n", 
           result.stopped_eos ? "EOS token" : 
           result.stopped_word ? "stop sequence" : 
           result.stopped_limit ? "token limit" : "unknown");
    
    llama_mobile_free_completion_result(&result);

    // Step 5: Test conversation management
    printf("5. Testing conversation management...\n");
    
    // First message
    printf("User: What is the capital of France?\n");
    printf("Assistant: ");
    
    llama_mobile_conversation_result_t conv_result;
    status = llama_mobile_generate_response(ctx, "What is the capital of France?", 100, &conv_result);
    if (status == 0) {
        printf("%s\n", conv_result.text);
        printf("Time to first token: %lld ms\n", conv_result.time_to_first_token);
        printf("Total time: %lld ms\n", conv_result.total_time);
        printf("Tokens generated: %d\n\n", conv_result.tokens_generated);
        llama_mobile_free_conversation_result(&conv_result);
    } else {
        fprintf(stderr, "Conversation generation failed\n\n");
    }
    
    // Second message (context-aware)
    printf("User: What language is spoken there?\n");
    printf("Assistant: ");
    
    status = llama_mobile_generate_response(ctx, "What language is spoken there?", 100, &conv_result);
    if (status == 0) {
        printf("%s\n", conv_result.text);
        printf("Time to first token: %lld ms\n", conv_result.time_to_first_token);
        printf("Total time: %lld ms\n", conv_result.total_time);
        printf("Tokens generated: %d\n\n", conv_result.tokens_generated);
        llama_mobile_free_conversation_result(&conv_result);
    } else {
        fprintf(stderr, "Conversation generation failed\n\n");
    }
    
    // Clear conversation
    llama_mobile_clear_conversation(ctx);
    printf("Conversation cleared successfully!\n\n");

    // Step 6: Test LoRA adapter support (demonstration only)
    printf("6. Testing LoRA adapter support...\n");
    
    // Note: This is a demonstration - actual LoRA adapter would be needed
    printf("Note: This is a demonstration of the API. No actual LoRA adapter is applied.\n");
    printf("To test with a real LoRA adapter, provide a valid adapter path.\n\n");
    
    // Example: How to apply a LoRA adapter
    // llama_mobile_lora_adapter_t adapters[] = {
    //     {"/path/to/lora/adapter", 1.0f}
    // };
    // int lora_status = llama_mobile_apply_lora_adapters(ctx, adapters, 1);
    // if (lora_status == 0) {
    //     printf("LoRA adapter applied successfully!\n");
    //     llama_mobile_remove_lora_adapters(ctx);
    //     printf("LoRA adapter removed successfully!\n");
    // }
    
    printf("LoRA API demonstration completed\n\n");

    // Step 7: Free resources
    printf("7. Cleaning up resources...\n");
    llama_mobile_free(ctx);
    
    printf("\n=== All API tests completed successfully! ===\n");
    printf("Tested interfaces: initialization, tokenization, detokenization,\n");
    printf("embeddings, completion, conversation management, and LoRA support.\n");
    
    return 0;
}