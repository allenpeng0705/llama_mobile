# llama_mobile Library

A unified library interface for running LLaMA models on mobile and embedded devices, providing C++, C, and FFI interfaces for cross-platform compatibility.

## Overview

The llama_mobile library provides a comprehensive interface for:
- Loading and running LLaMA models
- Text generation and completion
- Conversational AI
- Multimodal processing (vision/audio)
- Text-to-Speech (TTS)
- LoRA adapter support
- Benchmarking capabilities

## Using the Library

### Output Folder Structure

After building the library, you'll find the following structure in the output folder:

```
output/
├── include/
│   └── llama_mobile_api.h   # Main API header file
├── lib/
│   ├── libllama_mobile.a       # Static library
│   └── libllama_mobile.so      # Shared library (platform-specific extension)
└── ggml-metal.metal            # Metal shader file (for Apple platforms)
```

### Metal Support on Apple Devices

The library includes Metal support for Apple devices, providing GPU acceleration for faster inference.

#### Building with Metal Support

To build the library with Metal support enabled:

```bash
# macOS
mkdir -p build
cd build
cmake .. -DLM_GGML_USE_METAL=1
make -j8
```

#### Configuring Metal in Your Application

When initializing the library, you need to specify the path to the Metal shader file:

```cpp
// C++
llama_mobile_init_params_t params;
params.model_path = "/path/to/model.gguf";
params.n_ctx = 2048;
params.n_gpu_layers = 10; // Number of layers to offload to GPU
params.metal_path = "/path/to/ggml-metal.metal"; // Path to the Metal shader file

// C
llama_mobile_init_params_t params = {
    .model_path = "/path/to/model.gguf",
    .n_ctx = 2048,
    .n_gpu_layers = 10,
    .metal_path = "/path/to/ggml-metal.metal"
};

// FFI
llama_mobile_init_params_c_t params = {
    .model_path = "/path/to/model.gguf",
    .n_ctx = 2048,
    .n_gpu_layers = 10,
    .metal_path = "/path/to/ggml-metal.metal"
};
```

#### Metal Shader File Location

Ensure the `ggml-metal.metal` file from the output folder is bundled with your application and accessible at runtime.

#### GPU Layer Offloading

The `n_gpu_layers` parameter controls how many model layers are offloaded to the GPU:
- Set to `0` to disable GPU acceleration entirely
- Set to a positive number (e.g., `10`) to offload that many layers to the GPU
- Set to a negative number (e.g., `-1`) to offload all layers to the GPU

#### Performance Tips

- Use Metal on Apple Silicon devices for best performance
- Experiment with the number of GPU layers to find the optimal balance between memory usage and speed
- Ensure your device has sufficient GPU memory for the number of layers you're offloading
- The Metal shader file must be accessible at runtime (not just at build time)

### Including the Header

To use the library in your project, include the unified header file:

```cpp
// C++
#include "llama_mobile_api.h"

// C
#include "llama_mobile_api.h"
```

### Linking the Library

#### Static Linking

Link against the static library:

```bash
# Linux/macOS
g++ -o your_app your_app.cpp -I/path/to/output/include -L/path/to/output/lib -llama_mobile

# Windows
cl.exe /EHsc your_app.cpp /I"C:\path\to\output\include" /link /LIBPATH:"C:\path\to\output\lib" llama_mobile.lib
```

#### Dynamic Linking

Link against the shared library:

```bash
# Linux
g++ -o your_app your_app.cpp -I/path/to/output/include -L/path/to/output/lib -llama_mobile
LD_LIBRARY_PATH=/path/to/output/lib ./your_app

# macOS
g++ -o your_app your_app.cpp -I/path/to/output/include -L/path/to/output/lib -llama_mobile
DYLD_LIBRARY_PATH=/path/to/output/lib ./your_app

# Windows
cl.exe /EHsc your_app.cpp /I"C:\path\to\output\include" /link /LIBPATH:"C:\path\to\output\lib" llama_mobile.lib
```

## Basic Usage Examples

### C++ Interface

```cpp
#include "llama_mobile_api.h"

int main() {
    // Initialize the context
    llama_mobile_init_params_t params;
    params.model_path = "/path/to/model.gguf";
    params.n_ctx = 2048;
    params.n_gpu_layers = 4;
    
    llama_mobile_context_t ctx = llama_mobile_init(&params);
    if (!ctx) {
        std::cerr << "Failed to initialize context" << std::endl;
        return 1;
    }
    
    // Generate a completion
    llama_mobile_completion_params_t completion_params;
    completion_params.prompt = "Hello, how are you?";
    completion_params.max_tokens = 100;
    completion_params.temperature = 0.8;
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(ctx, &completion_params, &result);
    
    if (status == 0) {
        std::cout << "Generated text: " << result.text << std::endl;
        llama_mobile_free_completion_result(&result);
    }
    
    // Clean up
    llama_mobile_free(ctx);
    
    return 0;
}
```

### C Interface

```c
#include "llama_mobile_api.h"

int main() {
    // Initialize the context
    llama_mobile_init_params_t params = {
        .model_path = "/path/to/model.gguf",
        .n_ctx = 2048,
        .n_gpu_layers = 4
    };
    
    llama_mobile_context_t ctx = llama_mobile_init(&params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    
    // Generate a completion
    llama_mobile_completion_params_t completion_params = {
        .prompt = "Hello, how are you?",
        .max_tokens = 100,
        .temperature = 0.8
    };
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(ctx, &completion_params, &result);
    
    if (status == 0) {
        printf("Generated text: %s\n", result.text);
        llama_mobile_free_completion_result(&result);
    }
    
    // Clean up
    llama_mobile_free(ctx);
    
    return 0;
}
```

### FFI Interface

```c
#include "llama_mobile_api.h"

int main() {
    // Initialize the context
    llama_mobile_init_params_c_t params = {
        .model_path = "/path/to/model.gguf",
        .n_ctx = 2048,
        .n_gpu_layers = 4
    };
    
    llama_mobile_context_handle_t handle = llama_mobile_init_context_c(&params);
    if (!handle) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    
    // Generate a completion
    llama_mobile_completion_params_c_t completion_params = {
        .prompt = "Hello, how are you?",
        .n_predict = 100,
        .temperature = 0.8
    };
    
    llama_mobile_completion_result_c_t result;
    int status = llama_mobile_completion_c(handle, &completion_params, &result);
    
    if (status == 0) {
        printf("Generated text: %s\n", result.text);
        llama_mobile_free_completion_result_members_c(&result);
    }
    
    // Clean up
    llama_mobile_free_context_c(handle);
    
    return 0;
}
```

## Key Features

### Model Loading
- Support for GGUF format models
- GPU acceleration (partial layer offloading)
- Memory-mapped I/O for efficient loading
- Loading progress callback

### Text Generation
- Configurable sampling parameters (temperature, top-k, top-p, min-p)
- Stop sequences
- Token streaming
- Constrained generation with grammars

### Conversational AI
- Chat templates
- Conversation history management
- Streaming responses
- Jinja template support

### Multimodal Support
- Vision processing (images)
- Audio processing
- Media integration with text

### Text-to-Speech
- OutE TTS models support
- Speaker configuration
- Audio token generation

### LoRA Adapters
- Apply multiple LoRA adapters
- Remove adapters
- Query loaded adapters

### Benchmarking
- Prompt processing performance
- Token generation performance
- Model size and parameter information


## Standard API Documentation (llama_mobile_api.h)

The `llama_mobile_api.h` header provides a comprehensive API for integrating LLaMA models into mobile and embedded applications. This API is designed for compatibility with various backends and provides C++, C, and FFI interfaces for cross-platform usage.

### Core Structures

#### Context and Handle

```cpp
// Opaque handle to the llama_mobile context (C API)
typedef struct llama_mobile_context_opaque* llama_mobile_context_t;

// Main context class (C++ API)
struct llama_mobile_context {
    // Prediction state
    bool is_predicting = false;            ///< Whether the model is currently generating text
    bool is_interrupted = false;           ///< Whether generation has been interrupted
    bool has_next_token = false;           ///< Whether there's a next token available
    std::string generated_text;            ///< Accumulated generated text
    std::vector<completion_token_output> generated_token_probs; ///< Token probabilities
    
    // Token counters
    size_t num_prompt_tokens = 0;          ///< Number of tokens in the current prompt
    size_t num_tokens_predicted = 0;       ///< Number of tokens generated in current completion
    size_t n_past = 0;                     ///< Number of tokens processed so far
    size_t n_remain = 0;                   ///< Number of tokens remaining to generate
    
    // Embedding and parameters
    std::vector<llama_token> embd;         ///< Current token embeddings
    common_params params;                  ///< Model and inference parameters
    common_init_result_ptr llama_init;     ///< Result of model initialization
    
    // Model and context pointers
    llama_model *model = nullptr;          ///< Pointer to the loaded model
    float loading_progress = 0;            ///< Model loading progress (0.0-1.0)
    bool is_load_interrupted = false;      ///< Whether model loading was interrupted
    llama_context *ctx = nullptr;          ///< Pointer to the llama context
    common_sampler *ctx_sampling = nullptr; ///< Sampling context
    common_chat_templates_ptr templates;   ///< Chat templates for conversational AI
    
    // Configuration
    int n_ctx;                             ///< Context window size
    int n_threads;                         ///< Number of CPU threads to use
    
    // Generation parameters
    float temperature;                     ///< Sampling temperature (0.8f default)
    float top_p;                           ///< Top-p sampling parameter (0.95f default)
    float top_k;                           ///< Top-k sampling parameter (40.0f default)
    float repetition_penalty;              ///< Repetition penalty (1.0f default)
    
    // Stopping conditions
    bool truncated = false;                ///< Whether the output was truncated
    bool stopped_eos = false;              ///< Whether generation stopped due to EOS token
    bool stopped_word = false;             ///< Whether generation stopped due to stop word
    bool stopped_limit = false;            ///< Whether generation stopped due to token limit
    std::string stopping_word;             ///< The stop word that triggered stopping
    bool incomplete = false;               ///< Whether the generation was incomplete
    
    // LoRA adapters
    std::vector<common_adapter_lora_info> lora; ///< Loaded LoRA adapters
    
    // Guide tokens
    bool context_full = false;             ///< Whether the context window is full
    std::vector<llama_token> guide_tokens; ///< Tokens to guide generation
    bool next_token_uses_guide_token = true; ///< Whether to use guide tokens for next token
    
    // Multimodal support
    struct llama_mobile_context_mtmd {
        mtmd_context* mtmd_ctx = nullptr;  ///< Multimodal context pointer
    };
    llama_mobile_context_mtmd *mtmd_wrapper = nullptr; ///< Multimodal wrapper
    bool has_multimodal = false;           ///< Whether multimodal support is enabled
    std::vector<std::string> mtmd_bitmap_past_hashes; ///< Hashes of past media
    
    // Vocoder (TTS) support
    struct llama_mobile_context_vocoder {
        common_init_result_ptr init_result; ///< Vocoder initialization result
        llama_model *model = nullptr;       ///< Vocoder model pointer
        llama_context *ctx = nullptr;       ///< Vocoder context
        tts_type type = TTS_UNKNOWN;        ///< Type of TTS model
    };
    llama_mobile_context_vocoder *vocoder_wrapper = nullptr; ///< Vocoder wrapper
    bool has_vocoder = false;              ///< Whether vocoder is enabled
    std::vector<llama_token> audio_tokens; ///< Generated audio tokens
    
    // Conversation management
    bool conversation_active = false;      ///< Whether a conversation is active
};

#### Token Probability Structures

The `completion_token_output` struct provides detailed information about token generation:

```cpp
struct completion_token_output
{
    /**
     * @brief Structure representing a token and its probability.
     */
    struct token_prob
    {
        llama_token tok; ///< The token ID
        float prob;      ///< The probability of this token being generated
    };

    std::vector<token_prob> probs; ///< List of top probability tokens
    llama_token tok;               ///< The actually selected token
};
```

This structure is used to:
1. Record the actually selected token (`tok`)
2. Store a list of top probability tokens (`probs`) that could have been selected
3. Provide debugging and analysis capabilities for token generation decisions

#### Initialization Parameters

```cpp
typedef struct {
    const char* model_path;          // Path to the model file (required)
    const char* chat_template;       // Chat template to use (optional)
    int32_t n_ctx;                   // Context window size (default: 512)
    int32_t n_gpu_layers;            // Number of layers to offload to GPU (default: 0)
    int32_t n_threads;               // Number of CPU threads (default: 4)
    bool use_mmap;                   // Use memory-mapped I/O (default: true)
    bool embedding;                  // Enable embedding mode (default: false)
    double temperature;              // Sampling temperature (default: 0.8)
    double top_p;                    // Top-P sampling (default: 0.95)
    double penalty_repeat;           // Repetition penalty (default: 1.1)
    void (*progress_callback)(float progress);  // Loading progress callback
} llama_mobile_init_params_t;
```

#### Completion Parameters

```cpp
typedef struct {
    const char* prompt;               // Input prompt text
    int32_t max_tokens;               // Maximum tokens to generate (default: 128)
    double temperature;               // Sampling temperature
    double top_p;                     // Top-P sampling
    double penalty_repeat;            // Repetition penalty
    const char** stop_sequences;      // Array of stop sequences
    int stop_sequence_count;          // Number of stop sequences
    bool (*token_callback)(const char* token);  // Streaming callback
} llama_mobile_completion_params_t;
```

#### Result Structures

```cpp
typedef struct {
    char* text;                      // Generated text
    int32_t tokens_generated;        // Number of tokens generated
    int32_t tokens_evaluated;        // Number of tokens processed from input
    bool truncated;                  // Whether output was truncated
    bool stopped_eos;                // Stopped due to EOS token
    bool stopped_word;               // Stopped due to stop sequence
    bool stopped_limit;              // Stopped due to max_tokens limit
} llama_mobile_completion_result_t;

typedef struct {
    char* text;                      // Generated response text
    int64_t time_to_first_token;     // Time to generate first token (ms)
    int64_t total_time;              // Total generation time (ms)
    int32_t tokens_generated;        // Number of tokens in response
} llama_mobile_conversation_result_t;

typedef struct {
    int32_t* tokens;                 // Array of generated tokens
    int32_t token_count;             // Number of tokens generated
    bool has_media;                  // Whether the input contained media
    char** bitmap_hashes;            // Array of hashes for processed media
    int32_t bitmap_hash_count;       // Number of media hashes
    int32_t* chunk_pos;              // Positions of text chunks
    int32_t chunk_pos_count;         // Number of text chunk positions
    int32_t* chunk_pos_media;        // Positions of media chunks
    int32_t chunk_pos_media_count;   // Number of media chunk positions
} llama_mobile_tokenize_result_c_t;```

The C++ API has a similar `llama_mobile_tokenize_result` struct with the following fields:

```cpp
struct llama_mobile_tokenize_result {
    std::vector<llama_token> tokens;       ///< Generated tokens
    bool has_media = false;                ///< Whether the input contained media
    std::vector<std::string> bitmap_hashes;///< Hashes of processed media
    std::vector<size_t> chunk_pos;         ///< Positions of text chunks
    std::vector<size_t> chunk_pos_media;   ///< Positions of media chunks
};
```

#### Key Enumerations

```cpp
// TTS implementation types
enum tts_type {
    TTS_UNKNOWN = -1,       ///< Unknown or unsupported TTS type
    TTS_OUTETTS_V0_2 = 1,   ///< OutE TTS model version 0.2
    TTS_OUTETTS_V0_3 = 2,   ///< OutE TTS model version 0.3
};
```

### Key Functions

#### Context Management

```cpp
// Initialize a new context with detailed configuration
llama_mobile_context_t llama_mobile_init(
    const llama_mobile_init_params_t* params);

// Simplified context initialization
llama_mobile_context_t llama_mobile_init_simple(
    const char* model_path,          // Path to model file
    int32_t n_ctx,                   // Context window size
    int32_t n_gpu_layers,            // GPU layers to offload
    int32_t n_threads,               // CPU threads to use
    void (*progress_callback)(float progress));  // Loading callback

// Free the context and all resources
void llama_mobile_free(llama_mobile_context_t ctx);
```

#### Text Generation

```cpp
// Generate a completion with detailed configuration
int llama_mobile_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    llama_mobile_completion_result_t* result);

// Simplified completion generation
int llama_mobile_completion_simple(
    llama_mobile_context_t ctx,
    const char* prompt,              // Input prompt
    int32_t max_tokens,              // Maximum tokens to generate
    double temperature,              // Sampling temperature
    bool (*token_callback)(const char* token),  // Streaming callback
    llama_mobile_completion_result_t* result);

// Stop an ongoing completion generation
void llama_mobile_stop_completion(llama_mobile_context_t ctx);
```

#### Conversational AI

```cpp
// Generate a conversational response
int llama_mobile_generate_response(
    llama_mobile_context_t ctx,
    const char* user_message,        // User's message
    int32_t max_tokens,              // Maximum response tokens
    llama_mobile_conversation_result_t* result);

// Simplified conversational response
int llama_mobile_generate_response_simple(
    llama_mobile_context_t ctx,
    const char* user_message,        // User's message
    int32_t max_tokens,              // Maximum response tokens
    llama_mobile_conversation_result_t* result);

// Clear conversation history
void llama_mobile_clear_conversation(llama_mobile_context_t ctx);
```

#### Multimodal Support

```cpp
// Initialize multimodal support
int llama_mobile_init_multimodal(
    llama_mobile_context_t ctx,
    const char* mmproj_path,         // Path to multimodal projection file
    bool use_gpu);                   // Use GPU acceleration

// Simplified multimodal initialization
int llama_mobile_init_multimodal_simple(
    llama_mobile_context_t ctx,
    const char* mmproj_path);        // Path to multimodal projection file

// Generate a completion with multimodal inputs
int llama_mobile_multimodal_completion(
    llama_mobile_context_t ctx,
    const llama_mobile_completion_params_t* params,
    const char** media_paths,        // Array of media file paths
    int media_count,                 // Number of media files
    llama_mobile_completion_result_t* result);
```

#### Embeddings

```cpp
// Generate embeddings for text
llama_mobile_float_array_t llama_mobile_embedding(
    llama_mobile_context_t ctx,
    const char* text);               // Text to generate embeddings for
```

#### LoRA Adapters

```cpp
// LoRA adapter configuration
typedef struct {
    const char* path;                // Path to LoRA adapter
    float scale;                     // LoRA scale factor
} llama_mobile_lora_adapter_t;

// Apply LoRA adapters
int llama_mobile_apply_lora_adapters(
    llama_mobile_context_t ctx,
    const llama_mobile_lora_adapter_t* adapters,  // Array of adapters
    int count);                      // Number of adapters

// Remove all LoRA adapters
void llama_mobile_remove_lora_adapters(llama_mobile_context_t ctx);
```

#### Memory Management

```cpp
// Free a string allocated by the library
void llama_mobile_free_string(char* str);

// Free a completion result
void llama_mobile_free_completion_result(llama_mobile_completion_result_t* result);

// Free a conversation result
void llama_mobile_free_conversation_result(llama_mobile_conversation_result_t* result);

// Free token arrays
void llama_mobile_free_token_array(llama_mobile_token_array_t arr);

// Free float arrays (embeddings)
void llama_mobile_free_float_array(llama_mobile_float_array_t arr);
```

### Standard API Usage Examples

#### Basic Text Generation (C API)

```c
#include "llama_mobile_api.h"

int main() {
    // Initialize the context
    llama_mobile_init_params_t init_params = {
        .model_path = "/path/to/model.gguf",
        .n_ctx = 2048,
        .n_gpu_layers = 4,
        .n_threads = 4
    };
    
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    
    // Generate a completion
    llama_mobile_completion_params_t completion_params = {
        .prompt = "Explain quantum computing in simple terms",
        .max_tokens = 150,
        .temperature = 0.7,
        .top_p = 0.9
    };
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(ctx, &completion_params, &result);
    
    if (status == 0) {
        printf("Generated text: %s\n", result.text);
        llama_mobile_free_completion_result(&result);
    } else {
        fprintf(stderr, "Completion failed with error code %d\n", status);
    }
    
    // Clean up
    llama_mobile_free(ctx);
    
    return 0;
}
```

#### Conversational AI (C++ API)

```cpp
#include "llama_mobile_api.h"

int main() {
    // Initialize with simplified parameters
    llama_mobile_context_t ctx = llama_mobile_init_simple(
        "/path/to/model.gguf",
        2048,  // Context window size
        4,     // GPU layers
        4,     // CPU threads
        nullptr // No progress callback
    );
    
    if (!ctx) {
        std::cerr << "Failed to initialize context" << std::endl;
        return 1;
    }
    
    // Generate responses in a conversation
    const char* user_messages[] = {
        "What is the capital of France?",
        "What's the population?",
        "What are some famous landmarks there?"
    };
    
    for (const char* msg : user_messages) {
        llama_mobile_conversation_result_t result;
        int status = llama_mobile_generate_response_simple(ctx, msg, 100, &result);
        
        if (status == 0) {
            std::cout << "User: " << msg << std::endl;
            std::cout << "Bot: " << result.text << std::endl;
            std::cout << "------------------------" << std::endl;
            llama_mobile_free_conversation_result(&result);
        }
    }
    
    // Clear conversation history
    llama_mobile_clear_conversation(ctx);
    
    // Clean up
    llama_mobile_free(ctx);
    
    return 0;
}
```

#### Multimodal Example (C API)

```c
#include "llama_mobile_api.h"

int main() {
    // Initialize context
    llama_mobile_init_params_t init_params = {
        .model_path = "/path/to/multimodal_model.gguf",
        .n_ctx = 2048
    };
    
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        fprintf(stderr, "Failed to initialize context\n");
        return 1;
    }
    
    // Initialize multimodal support
    if (llama_mobile_init_multimodal_simple(ctx, "/path/to/mmproj-model.gguf") != 0) {
        fprintf(stderr, "Failed to initialize multimodal support\n");
        llama_mobile_free(ctx);
        return 1;
    }
    
    // Generate completion with image
    const char* media_paths[] = {"/path/to/image.jpg"};
    llama_mobile_completion_params_t params = {
        .prompt = "Describe this image:",
        .max_tokens = 100
    };
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_multimodal_completion(
        ctx, &params, media_paths, 1, &result);
    
    if (status == 0) {
        printf("Image description: %s\n", result.text);
        llama_mobile_free_completion_result(&result);
    }
    
    // Clean up
    llama_mobile_free(ctx);
    
    return 0;
}
```



## Adding More Interfaces

To extend the library with new interfaces, follow these steps:

### 1. Define the Interface in the Unified Header

Add new functions, structs, or enums to `llama_mobile_api.h` in the appropriate section:

- **C++ Interface**: Add to the `llama_mobile` namespace
- **C Interface**: Add to the `extern "C"` block
- **FFI Interface**: Add FFI-specific functions with `_c` suffix

### 2. Implement the Functionality

Implement the new functionality in the corresponding source files:
- Core implementation in C++ source files
- C API wrappers in `llama_mobile_api.cpp`
- FFI bindings in `llama_mobile_ffi.cpp`

### 3. Add Documentation

Add comprehensive Doxygen-style comments:

```cpp
/**
 * @brief Brief description of the function.
 * 
 * Detailed description explaining what the function does.
 * 
 * @param param1 Description of parameter 1
 * @param param2 Description of parameter 2
 * @return Description of return value
 */
LLAMA_MOBILE_API int llama_mobile_new_function(llama_mobile_context_t ctx, int param1, const char* param2);
```

### 4. Add Memory Management (If Needed)

For FFI interface, add proper memory management functions:

```cpp
/**
 * @brief Free resources allocated by llama_mobile_new_function.
 * 
 * @param result Result structure to free
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_new_result_c(llama_mobile_new_result_c_t* result);
```

### 5. Update the Build System

Ensure the new source files are included in the build system configuration.

### Example: Adding a New Interface

#### Step 1: Add to Header

```cpp
// In llama_mobile_api.h

// C++ Interface
namespace llama_mobile {
    /**
     * @brief Calculate perplexity for a given text.
     * 
     * @param ctx Pointer to the llama context
     * @param text Text to calculate perplexity for
     * @return Perplexity score
     */
    double calculate_perplexity(llama_context *ctx, const std::string &text);
}

// C Interface
typedef struct {
    double score;     /**< Perplexity score */
    int tokens_count; /**< Number of tokens processed */
} llama_mobile_perplexity_result_t;

/**
 * @brief Calculate perplexity for a given text.
 * 
 * @param ctx Context handle
 * @param text Text to calculate perplexity for
 * @param result Output parameter to store the result
 * @return 0 on success, negative error code on failure
 */
LLAMA_MOBILE_API int llama_mobile_calculate_perplexity(
    llama_mobile_context_t ctx,
    const char* text,
    llama_mobile_perplexity_result_t* result);

// FFI Interface
typedef struct {
    double score;     /**< Perplexity score */
    int32_t tokens_count; /**< Number of tokens processed */
} llama_mobile_perplexity_result_c_t;

/**
 * @brief Calculate perplexity for a given text through FFI.
 * 
 * @param handle Context handle
 * @param text Text to calculate perplexity for
 * @param result Output parameter to store the result
 * @return 0 on success, negative error code on failure
 */
LLAMA_MOBILE_FFI_EXPORT int llama_mobile_calculate_perplexity_c(
    llama_mobile_context_handle_t handle,
    const char* text,
    llama_mobile_perplexity_result_c_t* result);

/**
 * @brief Free the members of a perplexity result.
 * 
 * @param result Perplexity result to free
 */
LLAMA_MOBILE_FFI_EXPORT void llama_mobile_free_perplexity_result_members_c(llama_mobile_perplexity_result_c_t* result);
```

#### Step 2: Implement the Functionality

```cpp
// In llama_mobile.cpp
namespace llama_mobile {
    double calculate_perplexity(llama_context *ctx, const std::string &text) {
        // Implementation
    }
}

// In llama_mobile_api.cpp
int llama_mobile_calculate_perplexity(
    llama_mobile_context_t ctx,
    const char* text,
    llama_mobile_perplexity_result_t* result) {
    // Implementation
}

// In llama_mobile_ffi.cpp
int llama_mobile_calculate_perplexity_c(
    llama_mobile_context_handle_t handle,
    const char* text,
    llama_mobile_perplexity_result_c_t* result) {
    // Implementation
}

void llama_mobile_free_perplexity_result_members_c(llama_mobile_perplexity_result_c_t* result) {
    // Implementation
}
```

## Build Instructions

For detailed build instructions, refer to the main project README.

## License

Refer to the main project license file.
