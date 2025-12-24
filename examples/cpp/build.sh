mkdir -p build
cd build
cmake ..
make

ln -sf ../../../lib/ggml-llama.metallib default.metallib

echo "Build completed successfully!"
echo "To run examples, use:"
echo "  ./build/llama_mobile_conversation_ffi"
echo "  ./build/llama_mobile_api_example"
echo "  ./build/llama_mobile_benchmark"
echo "  ./build/llama_mobile_embed"
echo "  ./build/llama_mobile_llm"
echo "  ./build/llama_mobile_tts"
echo "  ./build/llama_mobile_vlm"
echo "  ./build/llama_mobile_vlm_ffi"