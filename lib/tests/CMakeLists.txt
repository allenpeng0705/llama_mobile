cmake_minimum_required(VERSION 3.10)
project(llama_mobile_tests)

find_package(Threads REQUIRED)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(LLAMA_BUILD_COMMON "Build common utils library" ON)
# llama.cpp tools (examples/bench/tuning) must stay OFF when llama.cpp is included
# as a subproject: those targets reference top-level CMAKE_SOURCE_DIR paths and fail
# to compile (e.g. tools/tuning cannot find ggml-metal-tuning.h). Only mtmd is needed.
option(LLAMA_BUILD_TOOLS "Build llama.cpp tools" OFF)
option(LLAMA_BUILD_MTMD "Build tools/mtmd library standalone" ON)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master ${CMAKE_CURRENT_BINARY_DIR}/llama.cpp-master)

# Engine + v2 C API sources. The v1 public layers (llama_mobile_ffi.cpp /
# llama_mobile_api.cpp) were purged; only the internal engine and the v2
# implementation remain.
set(LLAMA_MOBILE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_context.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_completion.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_chat.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_tts.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_tokenization.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_bench.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_embedding.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_lora.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_utils.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_multimodal.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_loader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_v2.cpp
)

set(LLAMA_MOBILE_INCLUDE_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master/common
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master/ggml/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master/vendor
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master/tools/mtmd
)

add_library(llama_mobile_test_lib STATIC ${LLAMA_MOBILE_SOURCES})
target_include_directories(llama_mobile_test_lib PUBLIC ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_test_lib PUBLIC llama llama-common llama-common-base ggml mtmd vendor-hash)

# v2 conformance suites (keep green)
add_executable(test_v2_threads test_v2_threads.cpp)
target_include_directories(test_v2_threads PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_threads PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash Threads::Threads)
target_compile_definitions(test_v2_threads PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_v2_meta test_v2_meta.cpp)
target_include_directories(test_v2_meta PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_meta PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_meta PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_v2_functional test_v2_functional.cpp)
target_include_directories(test_v2_functional PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_functional PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_functional PRIVATE LLAMA_MOBILE_VERBOSE=0)

# v2 module suites migrated from the deleted v1 test_core_* programs
add_executable(test_v2_streaming test_v2_streaming.cpp)
target_include_directories(test_v2_streaming PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_streaming PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_streaming PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_v2_lora test_v2_lora.cpp)
target_include_directories(test_v2_lora PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_lora PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_lora PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_v2_multimodal test_v2_multimodal.cpp)
target_include_directories(test_v2_multimodal PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_multimodal PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_multimodal PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_v2_tts test_v2_tts.cpp)
target_include_directories(test_v2_tts PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_v2_tts PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_v2_tts PRIVATE LLAMA_MOBILE_VERBOSE=0)

# Engine-level host suites (use llama_mobile.h internals only; no v1 C API)
add_executable(direct_test direct_test.cpp)
target_include_directories(direct_test PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(direct_test PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(direct_test PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_chat_template test_chat_template.cpp)
target_include_directories(test_chat_template PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_chat_template PRIVATE llama_mobile_test_lib llama llama-common llama-common-base ggml mtmd vendor-hash)
target_compile_definitions(test_chat_template PRIVATE LLAMA_MOBILE_VERBOSE=0)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(METAL_LIBRARY Metal)
    find_library(METALKIT_LIBRARY MetalKit)

    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        foreach(TARGET direct_test test_chat_template test_v2_meta test_v2_functional test_v2_threads test_v2_streaming test_v2_lora test_v2_multimodal test_v2_tts)
            target_link_libraries(${TARGET} PUBLIC ${FOUNDATION_LIBRARY} ${ACCELERATE_FRAMEWORK})
        endforeach()
    endif()
    
    if(METAL_LIBRARY AND METALKIT_LIBRARY)
        foreach(TARGET direct_test test_chat_template test_v2_meta test_v2_functional test_v2_threads test_v2_streaming test_v2_lora test_v2_multimodal test_v2_tts)
            target_link_libraries(${TARGET} PUBLIC ${METAL_LIBRARY} ${METALKIT_LIBRARY})
        endforeach()
    endif()
endif()
