#include <stdio.h>
#include <stdbool.h>
#include "../llama_mobile_api.h"

// Streaming callback function to print tokens as they arrive
bool token_callback(const char* token, void* user_data) {
    printf("%s", token);
    fflush(stdout);
    return true; // Continue generation
}

int main() {
    printf("=== Llama Mobile Streaming API Test ===\n\n");

    // Initialize the model
    llama_mobile_init_params_t init_params = {0};
    init_params.model_path = "/Users/shileipeng/Documents/mygithub/llama_mobile/models/SmolLM-360M-Instruct.Q6_K.gguf";
    init_params.n_threads = 4;
    init_params.n_ctx = 2048;
    init_params.n_gpu_layers = 0;  // Disable GPU to avoid Metal issues
    init_params.n_batch = 512;
    init_params.use_mmap = true;

    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (ctx == NULL) {
        fprintf(stderr, "Error initializing model\n");
        return 1;
    }
    printf("Model initialized successfully.\n\n");

    // Test streaming generation
    const char* user_message = "Tell me a short story about a robot.";
    printf("User: %s\n", user_message);
    printf("Assistant (streaming): ");
    fflush(stdout);

    llama_mobile_conversation_result_t conv_result;
    int status = llama_mobile_generate_response(
        ctx,
        user_message,
        256,    // max_tokens
        token_callback, // Streaming callback
        nullptr, // token_callback_user_data
        &conv_result
    );

    printf("\n\n");
    if (status != 0) {
        fprintf(stderr, "Error generating response: %d\n", status);
        llama_mobile_free(ctx);
        return 1;
    }

    printf("=== Streaming Complete ===\n");
    if (conv_result.text) {
        printf("Full response length: %zu characters\n", strlen(conv_result.text));
    }
    printf("Status: Success\n");

    // Cleanup
    llama_mobile_free_conversation_result(&conv_result);
    llama_mobile_free(ctx);

    printf("\nTest completed successfully!\n");
    return 0;
}