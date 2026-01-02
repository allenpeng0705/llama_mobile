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
│   └── llama_mobile_api.h  # Main API header file
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
