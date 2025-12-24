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

int main(int argc, char** argv) {
    std::string model_path;
    const std::string models_dir = "../../../lib/models";
    
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
    llama_mobile_init_params_t init_params = {
        .model_path = model_path.c_str(),
        .n_ctx = 2048,
        .n_batch = 512,
        .n_gpu_layers = 0,
        .n_threads = 4,
        .use_mmap = true,
        .use_mlock = false,
        .embedding = false,
        .temperature = 0.7,
        .top_k = 40,
        .top_p = 0.95,
        .penalty_repeat = 1.1,
    };

    printf("Initializing context...\n");
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    printf("Context initialized successfully!\n\n");

    // Step 2: Generate completion
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
    printf("Stopped due to: %s\n", 
           result.stopped_eos ? "EOS token" : 
           result.stopped_word ? "stop sequence" : 
           result.stopped_limit ? "token limit" : "unknown");

    // Step 3: Free resources
    llama_mobile_free_completion_result(&result);
    llama_mobile_free(ctx);
    
    printf("\nAll resources freed. Example completed successfully!\n");
    
    return 0;
}