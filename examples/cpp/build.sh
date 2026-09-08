#!/bin/bash
# Builds the v2 C++ examples (llama_mobile_v2.h C API) for the host.
set -e
cd "$(dirname "$0")"
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j"$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)"

echo
echo "Build complete. Run from repo root (models/ has the fixtures):"
echo "  ./examples/cpp/build/llama_mobile_llm        models/SmolLM-360M-Instruct.Q6_K.gguf"
echo "  ./examples/cpp/build/llama_mobile_embed      models/Qwen3-Embedding-0.6B-Q8_0.gguf"
echo "  ./examples/cpp/build/llama_mobile_tts        models/OuteTTS-0.2-500M-Q6_K.gguf models/WavTokenizer-Large-75-F16.gguf [out.wav]"
echo "  ./examples/cpp/build/llama_mobile_vlm        models/SmolVLM-256M-Instruct-Q8_0.gguf models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf models/img/image.jpg"
echo "  ./examples/cpp/build/llama_mobile_dual_purpose models/SmolLM-360M-Instruct.Q6_K.gguf"
echo "  ./examples/cpp/build/llama_mobile_api_example models/SmolLM-360M-Instruct.Q6_K.gguf"
echo "  ./examples/cpp/build/llama_mobile_benchmark  models/SmolLM-360M-Instruct.Q6_K.gguf 3 64"
