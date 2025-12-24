cmake_minimum_required(VERSION 3.16)
project(llama_mobile VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# iOS specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)

# Set default values for version and commit
if(NOT GGML_VERSION)
    set(GGML_VERSION "0.0.0")
endif()

if(NOT GGML_BUILD_COMMIT)
    set(GGML_BUILD_COMMIT "unknown")
endif()

# Dependencies and compile options
add_definitions(
    -DNDEBUG
    -DO3
    -DLM_GGML_USE_CPU
    -DLM_GGML_USE_ACCELERATE
    -DLM_GGML_USE_METAL
    -DLM_GGML_METAL_USE_BF16
    -DLM_GGML_VERSION="${GGML_VERSION}"
    -DLM_GGML_COMMIT="${GGML_BUILD_COMMIT}"
)

# Set the source directory to the lib/ directory for llama_mobile files
# and lib/llama_cpp for llama.cpp files
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib)
set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp)

# Define public headers - only expose the main API header
set(PUBLIC_HEADERS
    ${SOURCE_DIR}/llama_mobile_api.h
)

# Create library target
add_library(llama_mobile SHARED
    ${SOURCE_DIR}/llama_mobile_context.cpp
    ${SOURCE_DIR}/llama_mobile_loader.cpp
    ${SOURCE_DIR}/llama_mobile_completion.cpp
    ${SOURCE_DIR}/llama_mobile_utils.cpp
    ${SOURCE_DIR}/llama_mobile_embedding.cpp
    ${SOURCE_DIR}/llama_mobile_lora.cpp
    ${SOURCE_DIR}/llama_mobile_tokenization.cpp
    ${SOURCE_DIR}/llama_mobile_multimodal.cpp
    ${SOURCE_DIR}/llama_mobile_tts.cpp
    ${SOURCE_DIR}/llama_mobile_bench.cpp
    ${SOURCE_DIR}/llama_mobile_chat.cpp
    ${SOURCE_DIR}/llama_mobile_ffi.cpp
    ${SOURCE_DIR}/llama_mobile_api.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-audio.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/clip.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-helper.cpp
    ${LLAMA_CPP_DIR}/llama.cpp
    ${LLAMA_CPP_DIR}/llama-mmap.cpp
    ${LLAMA_CPP_DIR}/llama-memory.cpp
    ${LLAMA_CPP_DIR}/llama-io.cpp
    ${LLAMA_CPP_DIR}/llama-cparams.cpp
    ${LLAMA_CPP_DIR}/llama-hparams.cpp
    ${LLAMA_CPP_DIR}/llama-model.cpp
    ${LLAMA_CPP_DIR}/llama-model-loader.cpp
    ${LLAMA_CPP_DIR}/llama-model-saver.cpp
    ${LLAMA_CPP_DIR}/llama-kv-cache.cpp
    ${LLAMA_CPP_DIR}/llama-context.cpp
    ${LLAMA_CPP_DIR}/llama-chat.cpp
    ${LLAMA_CPP_DIR}/llama-batch.cpp
    ${LLAMA_CPP_DIR}/llama-arch.cpp
    ${LLAMA_CPP_DIR}/llama-adapter.cpp
    ${LLAMA_CPP_DIR}/llama-sampling.cpp
    ${LLAMA_CPP_DIR}/llama-grammar.cpp
    ${LLAMA_CPP_DIR}/llama-vocab.cpp
    ${LLAMA_CPP_DIR}/llama-impl.cpp
    ${LLAMA_CPP_DIR}/llama-graph.cpp
    ${LLAMA_CPP_DIR}/ggml.c
    ${LLAMA_CPP_DIR}/ggml-alloc.c
    ${LLAMA_CPP_DIR}/ggml-backend.cpp
    ${LLAMA_CPP_DIR}/ggml-quants.c
    ${LLAMA_CPP_DIR}/ggml-opt.cpp
    ${LLAMA_CPP_DIR}/ggml-threading.cpp
    ${LLAMA_CPP_DIR}/ggml-backend-reg.cpp
    ${LLAMA_CPP_DIR}/gguf.cpp
    ${LLAMA_CPP_DIR}/common.cpp
    ${LLAMA_CPP_DIR}/chat.cpp
    ${LLAMA_CPP_DIR}/log.cpp
    ${LLAMA_CPP_DIR}/sampling.cpp
    ${LLAMA_CPP_DIR}/json-schema-to-grammar.cpp
    ${LLAMA_CPP_DIR}/unicode.cpp
    ${LLAMA_CPP_DIR}/unicode-data.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/amx/amx.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/amx/mmq.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu.c
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-quants.c
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-traits.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/unary-ops.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/binary-ops.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/sgemm.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/vec.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ops.cpp
    ${LLAMA_CPP_DIR}/ggml-metal.m
    ${LLAMA_CPP_DIR}/minja/minja.hpp
    ${LLAMA_CPP_DIR}/minja/chat-template.hpp
)

# Setup include directories, use both lib/ and lib/llama_cpp directories
target_include_directories(llama_mobile
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/ggml-cpu>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/tools/mtmd>
        $<INSTALL_INTERFACE:include>
)

# Link required frameworks
target_link_libraries(llama_mobile PRIVATE
    "-framework Accelerate"
    "-framework Foundation"
    "-framework Metal"
    "-framework MetalKit"
)

# Set properties for framework
set_target_properties(llama_mobile PROPERTIES
    MACOSX_FRAMEWORK_IDENTIFIER "com.llama_mobile"
    MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.0
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0.0
    FRAMEWORK TRUE
    FRAMEWORK_VERSION 1.0.0
    VERSION 1.0.0
    PUBLIC_HEADER "${PUBLIC_HEADERS}"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC NO
)
