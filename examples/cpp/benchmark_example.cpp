#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <iostream>
#include <dirent.h>
#include <cstring>
#include <algorithm>
#include <chrono>
#include <iomanip>

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

// Simple token callback that just counts tokens (no output)
bool silent_token_callback(const char* token) {
    // Do nothing, just count the token
    return true;
}

// Benchmark configuration
struct BenchmarkConfig {
    std::string model_path;
    int n_gpu_layers; // 0 for CPU-only, -1 for all layers on GPU
    int n_threads;
    int n_ctx;
    int n_batch;
    int max_tokens;
    std::string prompt;
};

// Benchmark results
struct BenchmarkResults {
    double prompt_processing_time; // in seconds
    double token_generation_time;  // in seconds
    int tokens_generated;
    double tokens_per_second;      // tokens/sec
    double total_time;             // in seconds
    bool metal_enabled;
};

// Progress callback for model loading
void progress_callback(float progress) {
    printf("Model loading progress: %.1f%%\r", progress * 100.0f);
    fflush(stdout);
}

// Run a single benchmark test
BenchmarkResults run_benchmark(const BenchmarkConfig& config) {
    BenchmarkResults results;
    results.metal_enabled = (config.n_gpu_layers != 0);
    
    // Initialize context with all fields zeroed out
    llama_mobile_init_params_t init_params = {0};
    init_params.model_path = config.model_path.c_str();
    init_params.n_ctx = config.n_ctx;
    init_params.n_batch = config.n_batch;
    init_params.n_gpu_layers = config.n_gpu_layers;
    init_params.n_threads = config.n_threads;
    init_params.use_mmap = true;
    init_params.use_mlock = false;
    init_params.embedding = false;
    init_params.temperature = 0.7;
    init_params.top_k = 40;
    init_params.top_p = 0.95;
    init_params.penalty_repeat = 1.1;
    init_params.progress_callback = progress_callback;

    // Initialize the context and warm up
    printf("Initializing context with %s...\n", results.metal_enabled ? "Metal enabled" : "CPU only");
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        results.tokens_generated = -1;
        return results;
    }

    // Warm up with a short completion
    printf("Warming up...\n");
    llama_mobile_completion_params_t warmup_params = {
        .prompt = "Hello",
        .max_tokens = 10,
        .temperature = 0.7,
        .top_k = 40,
        .top_p = 0.95,
        .min_p = 0.05,
        .penalty_repeat = 1.1,
        .token_callback = silent_token_callback,
    };
    
    llama_mobile_completion_result_t warmup_result;
    int status = llama_mobile_completion(ctx, &warmup_params, &warmup_result);
    llama_mobile_free_completion_result(&warmup_result);
    
    if (status != 0) {
        fprintf(stderr, "Warm up failed\n");
        llama_mobile_free(ctx);
        results.tokens_generated = -1;
        return results;
    }

    // Run the actual benchmark
    printf("Running benchmark...\n");
    llama_mobile_completion_params_t benchmark_params = {
        .prompt = config.prompt.c_str(),
        .max_tokens = config.max_tokens,
        .temperature = 0.7,
        .top_k = 40,
        .top_p = 0.95,
        .min_p = 0.05,
        .penalty_repeat = 1.1,
        .token_callback = silent_token_callback,
    };
    
    llama_mobile_completion_result_t benchmark_result;
    
    auto start_time = std::chrono::high_resolution_clock::now();
    status = llama_mobile_completion(ctx, &benchmark_params, &benchmark_result);
    auto end_time = std::chrono::high_resolution_clock::now();
    
    if (status != 0) {
        fprintf(stderr, "Benchmark completion failed\n");
        llama_mobile_free(ctx);
        results.tokens_generated = -1;
        return results;
    }
    
    // Calculate timings
    results.total_time = std::chrono::duration<double>(end_time - start_time).count();
    results.tokens_generated = benchmark_result.tokens_generated;
    
    if (results.tokens_generated > 0) {
        results.tokens_per_second = results.tokens_generated / results.total_time;
    } else {
        results.tokens_per_second = 0.0;
    }
    
    // Clean up
    llama_mobile_free_completion_result(&benchmark_result);
    llama_mobile_free(ctx);
    
    return results;
}

// Display benchmark results
void display_results(const std::vector<BenchmarkResults>& results) {
    printf("\n=== Benchmark Results ===\n");
    printf("+------------------+-------------+---------------+------------------+\n");
    printf("| Configuration    | Total Time  | Tokens/Second | Tokens Generated |\n");
    printf("+------------------+-------------+---------------+------------------+\n");
    
    for (const auto& result : results) {
        if (result.tokens_generated == -1) {
            printf("| %-16s | Failed      | Failed        | Failed           |\n", 
                   result.metal_enabled ? "Metal Enabled" : "CPU Only");
        } else {
            printf("| %-16s | %8.2fs    | %11.2f | %16d |\n", 
                   result.metal_enabled ? "Metal Enabled" : "CPU Only",
                   result.total_time,
                   result.tokens_per_second,
                   result.tokens_generated);
        }
    }
    
    printf("+------------------+-------------+---------------+------------------+\n");
    
    // Calculate and display performance improvement if we have both results
    if (results.size() == 2) {
        const auto& cpu_result = results[0].metal_enabled ? results[1] : results[0];
        const auto& metal_result = results[0].metal_enabled ? results[0] : results[1];
        
        if (cpu_result.tokens_per_second > 0 && metal_result.tokens_per_second > 0) {
            double improvement = ((metal_result.tokens_per_second - cpu_result.tokens_per_second) / cpu_result.tokens_per_second) * 100.0;
            printf("\nPerformance Improvement with Metal: %.2f%% faster\n", improvement);
        }
    }
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
    
    printf("\n=== llama_mobile Performance Benchmark ===\n");
    printf("Model path: %s\n\n", model_path.c_str());
    
    // Benchmark configuration
    BenchmarkConfig config = {
        .model_path = model_path,
        .n_gpu_layers = -1,  // All layers on GPU for Metal
        .n_threads = 4,
        .n_ctx = 2048,
        .n_batch = 512,
        .max_tokens = 200,
        .prompt = "Write a short paragraph about artificial intelligence and its impact on society.",
    };
    
    printf("Benchmark Configuration:\n");
    printf("- Context size: %d\n", config.n_ctx);
    printf("- Batch size: %d\n", config.n_batch);
    printf("- Threads: %d\n", config.n_threads);
    printf("- Max tokens: %d\n", config.max_tokens);
    printf("- Prompt length: %zu characters\n\n", config.prompt.size());
    
    // Run benchmarks
    std::vector<BenchmarkResults> results;
    
    // 1. Run with Metal disabled (CPU only) first
    config.n_gpu_layers = 0;  // CPU only
    results.push_back(run_benchmark(config));
    printf("\n");
    
    // 2. Run with Metal enabled if requested
    config.n_gpu_layers = -1; // All layers on GPU
    results.push_back(run_benchmark(config));
    printf("\n");
    
    
    // Display results
    display_results(results);
    
    printf("\n=== Benchmark Completed ===\n");
    printf("Note: Results may vary based on hardware, model size, and system load.\n");
    
    return 0;
}
