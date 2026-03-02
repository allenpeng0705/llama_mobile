cmake_minimum_required(VERSION 3.10)
project(llama_mobile_examples)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(LLAMA_BUILD_COMMON "Build common utils library" ON)
option(LLAMA_BUILD_TOOLS "Build tools including mtmd" ON)

add_subdirectory(../../lib ${CMAKE_BINARY_DIR}/llama_mobile_core_build)

set(EXAMPLE_INCLUDE_DIRS
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama.cpp-master/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama.cpp-master/common
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama.cpp-master/ggml/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama.cpp-master/vendor
    ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama.cpp-master/tools/mtmd
)

add_executable(llama_mobile_vlm main_vlm.cpp)
target_include_directories(llama_mobile_vlm PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_vlm PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_vlm_ffi main_vlm_ffi.cpp)
target_include_directories(llama_mobile_vlm_ffi PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_vlm_ffi PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_embed main_embed.cpp)
target_include_directories(llama_mobile_embed PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_embed PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_llm main_llm.cpp)
target_include_directories(llama_mobile_llm PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_llm PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_tts main_tts.cpp)
target_include_directories(llama_mobile_tts PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_tts PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_conversation_ffi main_conversation_ffi.cpp)
target_include_directories(llama_mobile_conversation_ffi PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_conversation_ffi PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_api_example api_example.cpp)
target_include_directories(llama_mobile_api_example PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_api_example PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_dual_purpose main_dual_purpose.cpp)
target_include_directories(llama_mobile_dual_purpose PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_dual_purpose PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_benchmark benchmark_example.cpp)
target_include_directories(llama_mobile_benchmark PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_benchmark PRIVATE llama_mobile_core_static llama ggml common mtmd)

add_executable(llama_mobile_advanced_chat main_advanced_chat.cpp)
target_include_directories(llama_mobile_advanced_chat PRIVATE ${EXAMPLE_INCLUDE_DIRS})
target_link_libraries(llama_mobile_advanced_chat PRIVATE llama_mobile_core_static llama ggml common mtmd)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(METAL_LIBRARY Metal)
    find_library(METALKIT_LIBRARY MetalKit)

    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        foreach(TARGET llama_mobile_vlm llama_mobile_vlm_ffi llama_mobile_embed llama_mobile_llm llama_mobile_tts llama_mobile_conversation_ffi llama_mobile_api_example llama_mobile_dual_purpose llama_mobile_benchmark llama_mobile_advanced_chat)
            target_link_libraries(${TARGET} PUBLIC ${FOUNDATION_LIBRARY} ${ACCELERATE_FRAMEWORK})
        endforeach()
    endif()
    
    if(METAL_LIBRARY AND METALKIT_LIBRARY)
        foreach(TARGET llama_mobile_vlm llama_mobile_vlm_ffi llama_mobile_embed llama_mobile_llm llama_mobile_tts llama_mobile_conversation_ffi llama_mobile_api_example llama_mobile_dual_purpose llama_mobile_benchmark llama_mobile_advanced_chat)
            target_link_libraries(${TARGET} PUBLIC ${METAL_LIBRARY} ${METALKIT_LIBRARY})
        endforeach()
    endif()
endif()
