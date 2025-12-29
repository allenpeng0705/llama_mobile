cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android_sdk LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add definitions
add_definitions(
    -DNDEBUG
    -DLM_GGML_USE_CPU
    -DLM_GGML_USE_OPENCL=OFF
    -DGGML_NO_POSIX_MADVISE
)

# Include directories
include_directories(
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu"
)

# Import the pre-built llama_mobile library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
)

# Create a JNI wrapper
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link libraries
target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)

