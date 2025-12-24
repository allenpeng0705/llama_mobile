cmake_minimum_required(VERSION 3.10)
project(llama_mobile_examples)

if(CMAKE_CXX_COMPILER_ID MATCHES "Clang" OR CMAKE_CXX_COMPILER_ID MATCHES "GNU")
    add_compile_options(-g -O0 -fsanitize=address -fno-omit-frame-pointer)
    link_libraries(-fsanitize=address)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

add_subdirectory(../../lib ${CMAKE_BINARY_DIR}/llama_mobile_core_build)

# Create separate executables for each example
add_executable(llama_mobile_vlm main_vlm.cpp)
add_executable(llama_mobile_vlm_ffi main_vlm_ffi.cpp)
add_executable(llama_mobile_embed main_embed.cpp)
add_executable(llama_mobile_llm main_llm.cpp)
add_executable(llama_mobile_tts main_tts.cpp)
add_executable(llama_mobile_conversation_ffi main_conversation_ffi.cpp)
add_executable(llama_mobile_api_example api_example.cpp)
add_executable(llama_mobile_benchmark benchmark_example.cpp)

# Link each executable to the core library
target_link_libraries(llama_mobile_vlm PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_vlm_ffi PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_embed PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_llm PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_tts PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_conversation_ffi PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_api_example PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_benchmark PRIVATE llama_mobile_core_lib)

# Copy Metal shader files to build directory for Apple platforms
if(APPLE)
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama_cpp/ggml-metal.metal DESTINATION ${CMAKE_BINARY_DIR})
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama_cpp/ggml-common.h DESTINATION ${CMAKE_BINARY_DIR})
    file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/../../lib/llama_cpp/ggml-metal-impl.h DESTINATION ${CMAKE_BINARY_DIR})
    
    # Try to find ggml-llama.metallib in various locations and copy it
    set(METALLIB_PATHS
        ${CMAKE_CURRENT_SOURCE_DIR}/../../llama_mobile-ios/llama_mobile.xcframework/ios-arm64/llama_mobile.framework/ggml-llama.metallib
        ${CMAKE_CURRENT_SOURCE_DIR}/../../llama_mobile-ios/llama_mobile.xcframework/ios-arm64_x86_64-simulator/llama_mobile.framework/ggml-llama-sim.metallib
        ${CMAKE_CURRENT_SOURCE_DIR}/../../cactus-flutter/ios/cactus.xcframework/ios-arm64/cactus.framework/ggml-llama.metallib
    )
    
    foreach(PATH ${METALLIB_PATHS})
        if(EXISTS ${PATH})
            message(STATUS "Found ggml-llama.metallib at: ${PATH}")
            file(COPY ${PATH} DESTINATION ${CMAKE_BINARY_DIR})
            if(NOT ${PATH} MATCHES "-sim\.metallib$")
                file(RENAME ${CMAKE_BINARY_DIR}/ggml-llama.metallib ${CMAKE_BINARY_DIR}/default.metallib)
            else()
                file(RENAME ${CMAKE_BINARY_DIR}/ggml-llama-sim.metallib ${CMAKE_BINARY_DIR}/default.metallib)
            endif()
            break()
        endif()
    endforeach()
endif()