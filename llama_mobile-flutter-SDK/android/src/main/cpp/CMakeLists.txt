cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Set C++ standard library to static to avoid libc++_shared.so dependency
set(ANDROID_STL c++_static)

# Add include directories for llama_mobile headers
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Define path to pre-built llama_mobile libraries
set(LLAMA_MOBILE_LIB_PATH "${CMAKE_SOURCE_DIR}/../../../src/main/jniLibs")

# Add all pre-built static libraries
set(STATIC_LIBS
    llama_mobile_core
    llama
    common
    ggml
    ggml-base
    ggml-cpu
    mtmd
    cpp-httplib
    ggml-vulkan
)

foreach(LIB_NAME ${STATIC_LIBS})
    add_library(${LIB_NAME} STATIC IMPORTED)
    set_target_properties(${LIB_NAME} PROPERTIES
        IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/lib${LIB_NAME}.a
    )
endforeach()

# Add the JNI implementation library
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link the JNI library with all pre-built static libraries
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
# Order matters: link dependencies in order (llama_mobile_core first, then its dependencies)
# Use --whole-archive to ensure all symbols from all static libraries are included
target_link_libraries(llama_mobile_jni
    -Wl,--whole-archive
    ${STATIC_LIBS}
    -Wl,--no-whole-archive
    ${log-lib}
    ${android-lib}
    ${vulkan-lib}
)
