#!/bin/bash

mkdir -p build
cd build
cmake ..
cmake --build . -j$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)

echo "Build completed successfully!"
echo "To run examples, use:"
echo "  ./build/llama_mobile_conversation_ffi <model_path>"
echo "  ./build/llama_mobile_api_example <model_path>"
echo "  ./build/llama_mobile_benchmark <model_path>"
echo "  ./build/llama_mobile_embed <model_path>"
echo "  ./build/llama_mobile_llm <model_path>"
echo "  ./build/llama_mobile_tts <model_path> <vocoder_path>"
echo "  ./build/llama_mobile_vlm <model_path> <mmproj_path> <image_path>"
echo "  ./build/llama_mobile_vlm_ffi <model_path> <mmproj_path> <image_path>"
echo "  ./build/llama_mobile_dual_purpose <model_path>"
echo "  ./build/llama_mobile_advanced_chat <model_path>"
