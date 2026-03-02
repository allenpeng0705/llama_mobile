cmake_minimum_required(VERSION 3.14)
project(llama_mobile_core)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(LLAMA_USE_CURL "Use libcurl for download support" OFF)
option(LLAMA_USE_HTTPLIB "Use cpp-httplib for download support" ON)

option(GGML_OPENCL "Enable OpenCL backend for GPU support (Android)" OFF)
option(GGML_VULKAN "Enable Vulkan backend for GPU support (Android)" OFF)
option(GGML_OPENMP "Enable OpenMP support" OFF)
option(GGML_OPENCL_EMBED_KERNELS "Embed OpenCL kernels in the binary" ON)
option(GGML_VULKAN_EMBED_KERNELS "Embed Vulkan shaders in the binary" ON)

option(LLAMA_BUILD_COMMON "Build common utils library" ON)
option(LLAMA_BUILD_TOOLS "Build tools including mtmd" ON)

add_subdirectory(llama.cpp-master)

set(LLAMA_MOBILE_CORE_SOURCES
    llama_mobile_context.cpp
    llama_mobile_loader.cpp
    llama_mobile_completion.cpp
    llama_mobile_utils.cpp
    llama_mobile_embedding.cpp
    llama_mobile_lora.cpp
    llama_mobile_ffi.cpp
    llama_mobile_api.cpp
    llama_mobile_tokenization.cpp
    llama_mobile_multimodal.cpp
    llama_mobile_tts.cpp
    llama_mobile_bench.cpp
    llama_mobile_chat.cpp
)

add_library(llama_mobile_core_static STATIC ${LLAMA_MOBILE_CORE_SOURCES})
target_link_libraries(llama_mobile_core_static PUBLIC llama ggml common mtmd)
target_include_directories(llama_mobile_core_static PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/common
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/ggml/include
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/vendor
    ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/tools/mtmd
)
set_target_properties(llama_mobile_core_static PROPERTIES
    OUTPUT_NAME "llama_mobile_core"
)

# Don't combine - we'll use all individual libraries

if(BUILD_SHARED_LIBS)
    add_library(llama_mobile_core_shared SHARED ${LLAMA_MOBILE_CORE_SOURCES})
    target_link_libraries(llama_mobile_core_shared PUBLIC llama ggml common mtmd)
    target_include_directories(llama_mobile_core_shared PUBLIC 
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/include
        ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/common
        ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/ggml/include
        ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/vendor
        ${CMAKE_CURRENT_SOURCE_DIR}/llama.cpp-master/tools/mtmd
    )
    set_target_properties(llama_mobile_core_shared PROPERTIES
        OUTPUT_NAME "llama_mobile_core"
    )
endif()

message(STATUS "")
message(STATUS "llama_mobile build configuration:")
message(STATUS "  BUILD_SHARED_LIBS:    ${BUILD_SHARED_LIBS}")
message(STATUS "  GGML_OPENCL:          ${GGML_OPENCL}")
message(STATUS "  GGML_VULKAN:          ${GGML_VULKAN}")
message(STATUS "")
