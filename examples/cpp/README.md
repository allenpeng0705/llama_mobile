# llama_mobile C++ Examples

This folder contains independent C++ examples for using the llama_mobile library. Each example demonstrates different functionalities of the library.

## Available Models

The models are located in the `lib/models` directory:
- `Qwen3-0.6B-Q5_K_M.gguf` - A small 0.6B parameter model suitable for testing
- `Qwen3-4B-Q5_K_M.gguf` - A larger 4B parameter model with better performance

## Building the Examples

To build the examples, run the provided build script:

```bash
cd examples/cpp
./build.sh
```

This will compile all the examples and generate executable files in the `build` directory.

## Running the Examples

Each example accepts a model path as a command line argument. You can use the models from `lib/models` by providing the correct path.

### 1. Simple API Example

This example demonstrates the basic usage of the llama_mobile API:

```bash
cd examples/cpp/build
./llama_mobile_api_example ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

### 2. Conversation FFI Example

This example shows how to use the conversation API:

```bash
cd examples/cpp/build
./llama_mobile_conversation_ffi
```

By default, this example uses the `Qwen3-0.6B-Q5_K_M.gguf` model from `lib/models`. You can specify a different model:

```bash
cd examples/cpp/build
./llama_mobile_conversation_ffi /path/to/your/model.gguf
```

### 3. LLM Example

This example demonstrates the core LLM functionality:

```bash
cd examples/cpp/build
./llama_mobile_llm ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

### 4. Embedding Example

This example shows how to generate embeddings:

```bash
cd examples/cpp/build
./llama_mobile_embed ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

### 5. VLM Example

This example demonstrates Vision Language Model capabilities:

```bash
cd examples/cpp/build
./llama_mobile_vlm ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

### 6. VLM FFI Example

This example shows how to use the VLM API through FFI:

```bash
cd examples/cpp/build
./llama_mobile_vlm_ffi ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

### 7. TTS Example

This example demonstrates Text-to-Speech functionality:

```bash
cd examples/cpp/build
./llama_mobile_tts ../../../../lib/models/Qwen3-0.6B-Q5_K_M.gguf
```

## Example Descriptions

### Simple API Example (`llama_mobile_api_example`)
- Demonstrates basic model initialization and text generation
- Shows how to use the streaming token callback
- Provides a simple interface to test the core functionality

### Conversation FFI Example (`llama_mobile_conversation_ffi`)
- Shows how to use the conversation management API
- Demonstrates multi-turn conversations
- Includes performance metrics tracking

### LLM Example (`llama_mobile_llm`)
- Demonstrates advanced LLM functionality
- Shows how to use different sampling parameters
- Includes prompt engineering examples

### Embedding Example (`llama_mobile_embed`)
- Demonstrates how to generate text embeddings
- Shows how to compare text similarity using embeddings

### VLM Examples (`llama_mobile_vlm`, `llama_mobile_vlm_ffi`)
- Demonstrate Vision Language Model capabilities
- Show how to process images and text together
- Can answer questions about images

### TTS Example (`llama_mobile_tts`)
- Demonstrates Text-to-Speech functionality
- Shows how to generate audio from text

## Customization

Each example can be customized by modifying the source code. Key parameters you might want to adjust:

- `n_ctx`: Context window size
- `n_gpu_layers`: Number of layers to offload to GPU (0 for CPU only)
- `n_threads`: Number of CPU threads to use
- `temperature`: Sampling temperature
- `top_k`/`top_p`: Sampling parameters

## Troubleshooting

1. **Model loading errors**: Ensure you're providing the correct path to the model file
2. **Performance issues**: Adjust `n_threads` and `n_gpu_layers` based on your hardware
3. **Memory issues**: Reduce `n_ctx` if you're running out of memory
4. **Build errors**: Make sure you have the required dependencies installed

For more detailed information about the API, refer to the `llama_mobile_api.h` header file in the `lib` directory.