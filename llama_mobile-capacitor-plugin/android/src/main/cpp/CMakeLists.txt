cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Set C++ standard library to static to avoid libc++_shared.so dependency
set(ANDROID_STL c++_static)

# Add include directories for llama_mobile headers
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Define path to pre-built llama_mobile library
set(LLAMA_MOBILE_LIB_PATH "${CMAKE_SOURCE_DIR}/../../../libs")

# Add pre-built static libraries
add_library(llama_mobile_core STATIC IMPORTED)
set_target_properties(llama_mobile_core PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libllama_mobile_core.a
)

add_library(llama STATIC IMPORTED)
set_target_properties(llama PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libllama.a
)

add_library(ggml STATIC IMPORTED)
set_target_properties(ggml PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libggml.a
)

add_library(ggml-base STATIC IMPORTED)
set_target_properties(ggml-base PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libggml-base.a
)

add_library(ggml-cpu STATIC IMPORTED)
set_target_properties(ggml-cpu PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libggml-cpu.a
)

add_library(common STATIC IMPORTED)
set_target_properties(common PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libcommon.a
)

add_library(mtmd STATIC IMPORTED)
set_target_properties(mtmd PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libmtmd.a
)

add_library(ggml-vulkan STATIC IMPORTED)
set_target_properties(ggml-vulkan PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libggml-vulkan.a
)

add_library(cpp-httplib STATIC IMPORTED)
set_target_properties(cpp-httplib PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libcpp-httplib.a
)

# Add the JNI implementation library
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link the JNI library with the pre-built llama_mobile library
find_library(log-lib log)
find_library(android-lib android)
find_library(vulkan-lib vulkan)

# GPU Support Note:
# Vulkan is a system library on Android (libvulkan.so) and must be linked.
# minSdk = 28 ensures Vulkan 1.1+ symbols are available in the NDK stub.
# OpenCL is not linked since we build with Vulkan-only support.

# Add linker flags for 16 KB page alignment
target_link_options(llama_mobile_jni PRIVATE
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384
)

# Link the libraries
# Order matters: dependencies must come after dependents
# Use --whole-archive to ensure all symbols from static libraries are included
target_link_libraries(llama_mobile_jni
    -Wl,--whole-archive
    llama_mobile_core
    llama
    ggml
    ggml-cpu
    ggml-base
    common
    mtmd
    ggml-vulkan
    cpp-httplib
    -Wl,--no-whole-archive
    ${log-lib}
    ${android-lib}
    ${vulkan-lib}
)
