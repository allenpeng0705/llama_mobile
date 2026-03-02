cmake_minimum_required(VERSION 3.10)
project(llama_mobile_tests)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

option(LLAMA_BUILD_COMMON "Build common utils library" ON)
option(LLAMA_BUILD_TOOLS "Build tools including mtmd" ON)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/../llama.cpp-master ${CMAKE_CURRENT_BINARY_DIR}/llama.cpp-master)

set(LLAMA_MOBILE_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_context.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_completion.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_chat.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_tts.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_api.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_ffi.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_tokenization.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_bench.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_embedding.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_lora.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_utils.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_multimodal.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_mobile_loader.cpp
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
target_link_libraries(llama_mobile_test_lib PUBLIC llama ggml common mtmd)

add_executable(test_api test_api.cpp)
target_include_directories(test_api PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_api PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_api PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(chat_example chat_example.cpp)
target_include_directories(chat_example PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(chat_example PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(chat_example PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(direct_test direct_test.cpp)
target_include_directories(direct_test PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(direct_test PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(direct_test PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_streaming test_streaming.cpp)
target_include_directories(test_streaming PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_streaming PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_streaming PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_download test_download.cpp)
target_include_directories(test_download PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_download PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_download PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_chat_template test_chat_template.cpp)
target_include_directories(test_chat_template PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_chat_template PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_chat_template PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_advanced_chat test_advanced_chat.cpp)
target_include_directories(test_advanced_chat PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_advanced_chat PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_advanced_chat PRIVATE LLAMA_MOBILE_VERBOSE=0)

add_executable(test_conversation test_conversation.cpp)
target_include_directories(test_conversation PRIVATE ${LLAMA_MOBILE_INCLUDE_DIRS})
target_link_libraries(test_conversation PRIVATE llama_mobile_test_lib llama ggml common mtmd)
target_compile_definitions(test_conversation PRIVATE LLAMA_MOBILE_VERBOSE=0)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(METAL_LIBRARY Metal)
    find_library(METALKIT_LIBRARY MetalKit)

    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        foreach(TARGET test_api chat_example direct_test test_streaming test_download test_chat_template test_advanced_chat test_conversation)
            target_link_libraries(${TARGET} PUBLIC ${FOUNDATION_LIBRARY} ${ACCELERATE_FRAMEWORK})
        endforeach()
    endif()
    
    if(METAL_LIBRARY AND METALKIT_LIBRARY)
        foreach(TARGET test_api chat_example direct_test test_streaming test_download test_chat_template test_advanced_chat test_conversation)
            target_link_libraries(${TARGET} PUBLIC ${METAL_LIBRARY} ${METALKIT_LIBRARY})
        endforeach()
    endif()
endif()
