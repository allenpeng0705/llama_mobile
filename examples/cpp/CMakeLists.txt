cmake_minimum_required(VERSION 3.10)
project(llama_mobile_examples)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# v2 examples link the same core that ships in the SDKs: lib/CMakeLists builds
# llama_mobile_core_static from lib/llama_mobile_v2.cpp (the canonical C API in
# lib/llama_mobile_v2.h). The demos only include ../../lib.
option(LLAMA_BUILD_COMMON "Build common utils library" ON)
option(LLAMA_BUILD_TOOLS "Build tools including mtmd" ON)
# Match the host core test build: no llama.cpp tools (they pull in Metal-only
# tuning sources), mtmd enabled for the multimodal path.
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "Build tools including mtmd" FORCE)
set(LLAMA_BUILD_MTMD ON CACHE BOOL "Build mtmd support" FORCE)

add_subdirectory(../../lib ${CMAKE_BINARY_DIR}/llama_mobile_core_build)

set(EXAMPLE_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/../../lib)

function(llama_mobile_example name)
    add_executable(${name} ${ARGN})
    target_include_directories(${name} PRIVATE ${EXAMPLE_INCLUDE_DIRS})
    target_link_libraries(${name} PRIVATE llama_mobile_core_static llama ggml llama-common mtmd)
endfunction()

llama_mobile_example(llama_mobile_llm   main_llm.cpp)
llama_mobile_example(llama_mobile_embed main_embed.cpp)
llama_mobile_example(llama_mobile_tts   main_tts.cpp)
llama_mobile_example(llama_mobile_vlm   main_vlm.cpp)
llama_mobile_example(llama_mobile_dual_purpose main_dual_purpose.cpp)
llama_mobile_example(llama_mobile_api_example api_example.cpp)
llama_mobile_example(llama_mobile_benchmark  benchmark_example.cpp)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        foreach(TARGET llama_mobile_llm llama_mobile_embed llama_mobile_tts llama_mobile_vlm
                        llama_mobile_dual_purpose llama_mobile_api_example llama_mobile_benchmark)
            target_link_libraries(${TARGET} PUBLIC ${FOUNDATION_LIBRARY} ${ACCELERATE_FRAMEWORK})
        endforeach()
    endif()
endif()
