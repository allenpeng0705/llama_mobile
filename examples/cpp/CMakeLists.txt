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

add_subdirectory(../../llama_mobile ${CMAKE_BINARY_DIR}/llama_mobile_core_build)

# Create separate executables for each example
add_executable(llama_mobile_vlm main_vlm.cpp)
add_executable(llama_mobile_vlm_ffi main_vlm_ffi.cpp)
add_executable(llama_mobile_embed main_embed.cpp)
add_executable(llama_mobile_llm main_llm.cpp)
add_executable(llama_mobile_tts main_tts.cpp)
add_executable(llama_mobile_conversation_ffi main_conversation_ffi.cpp)
add_executable(llama_mobile_api_example simple_api_example.cpp)

# Link each executable to the core library
target_link_libraries(llama_mobile_vlm PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_vlm_ffi PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_embed PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_llm PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_tts PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_conversation_ffi PRIVATE llama_mobile_core_lib)
target_link_libraries(llama_mobile_api_example PRIVATE llama_mobile_core_lib)