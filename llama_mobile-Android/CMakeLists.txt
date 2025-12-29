cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Android specific settings
set(ANDROID_ABI "arm64-v8a")
set(ANDROID_PLATFORM "android-21")
set(ANDROID_STL "c++_shared")

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
    -DLM_GGML_USE_CPU
    -DLM_GGML_VERSION="${GGML_VERSION}"
    -DLM_GGML_COMMIT="${GGML_BUILD_COMMIT}"
    -DGGML_NO_POSIX_MADVISE # Disable POSIX madvise for Android compatibility
)

# Set the source directory to the lib/ directory for llama_mobile files
# and lib/llama_cpp for llama.cpp files
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib)
set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp)

# Define public headers - expose all necessary API headers
set(PUBLIC_HEADERS
    ${SOURCE_DIR}/llama_mobile_unified.h
    ${SOURCE_DIR}/llama_mobile_ffi.h
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
    ${LLAMA_CPP_DIR}/llama.cpp
    ${LLAMA_CPP_DIR}/llama-mmap.cpp
    ${LLAMA_CPP_DIR}/llama-memory.cpp
    ${LLAMA_CPP_DIR}/llama-memory-hybrid.cpp
    ${LLAMA_CPP_DIR}/llama-memory-recurrent.cpp
    ${LLAMA_CPP_DIR}/llama-io.cpp
    ${LLAMA_CPP_DIR}/llama-cparams.cpp
    ${LLAMA_CPP_DIR}/llama-hparams.cpp
    ${LLAMA_CPP_DIR}/llama-model.cpp
    ${LLAMA_CPP_DIR}/llama-model-loader.cpp
    ${LLAMA_CPP_DIR}/llama-model-saver.cpp
    ${LLAMA_CPP_DIR}/llama-kv-cache.cpp
    ${LLAMA_CPP_DIR}/llama-kv-cache-iswa.cpp
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
    ${LLAMA_CPP_DIR}/peg-parser.cpp
    ${LLAMA_CPP_DIR}/json-schema-to-grammar.cpp
    ${LLAMA_CPP_DIR}/chat-parser.cpp
    ${LLAMA_CPP_DIR}/chat-parser-xml-toolcall.cpp
    ${LLAMA_CPP_DIR}/chat-peg-parser.cpp
    ${LLAMA_CPP_DIR}/regex-partial.cpp
    ${LLAMA_CPP_DIR}/json-partial.cpp
    ${LLAMA_CPP_DIR}/version.cpp
)

# Setup include directories, use both lib/ and lib/llama_cpp directories
target_include_directories(llama_mobile
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/ggml-cpu>
        $<INSTALL_INTERFACE:include>
)

# Android specific setup
set_target_properties(llama_mobile PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}"
)

# Add JNI wrapper
add_library(llama_mobile_jni SHARED
    src/main/cpp/llama_mobile_jni.cpp
)

# Setup JNI include directories
target_include_directories(llama_mobile_jni
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/../lib
        ${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp
)

# Link the main library to JNI wrapper
target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)

# Set JNI wrapper output directory
set_target_properties(llama_mobile_jni PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/src/main/jniLibs/${ANDROID_ABI}"
)