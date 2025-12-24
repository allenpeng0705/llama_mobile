cmake_minimum_required(VERSION 3.10)
project(llama_mobile_tests)

# Add include directories for the test
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_cpp/ggml-cpu
    ${CMAKE_CURRENT_SOURCE_DIR}/../llama_cpp/minja

)

# Add test executable
add_executable(test_api test_api.cpp)

# Link against the core library
target_link_libraries(test_api PRIVATE llama_mobile_core_lib)

# Set C++ standard
target_compile_features(test_api PRIVATE cxx_std_17)

# Add definitions from main CMakeLists.txt
target_compile_definitions(test_api PRIVATE
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
)

# Add chat example executable
add_executable(chat_example chat_example.cpp)

# Link against the core library
target_link_libraries(chat_example PRIVATE llama_mobile_core_lib)

# Set C++ standard
target_compile_features(chat_example PRIVATE cxx_std_17)

# Add definitions from main CMakeLists.txt
target_compile_definitions(chat_example PRIVATE
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
)

# Add direct test executable (bypasses API wrapper)
add_executable(direct_test direct_test.cpp)

# Link against the core library
target_link_libraries(direct_test PRIVATE llama_mobile_core_lib)

# Set C++ standard
target_compile_features(direct_test PRIVATE cxx_std_17)

# Add definitions from main CMakeLists.txt
target_compile_definitions(direct_test PRIVATE
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(METAL_LIBRARY Metal)
    find_library(METALKIT_LIBRARY MetalKit)

    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        target_link_libraries(test_api PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
        target_link_libraries(chat_example PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
        target_link_libraries(direct_test PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
    endif()
    
    if(METAL_LIBRARY AND METALKIT_LIBRARY)
        target_link_libraries(test_api PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
        target_link_libraries(chat_example PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
        target_link_libraries(direct_test PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
    endif()
endif()
