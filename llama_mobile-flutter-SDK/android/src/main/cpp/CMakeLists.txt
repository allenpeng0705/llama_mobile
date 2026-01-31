cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Set C++ standard library to static to avoid libc++_shared.so dependency
set(ANDROID_STL c++_static)

# Add include directories for llama_mobile headers
include_directories(
    ../../../include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Define path to pre-built llama_mobile library
set(LLAMA_MOBILE_LIB_PATH "${CMAKE_SOURCE_DIR}/../../../src/main/jniLibs")

# Add pre-built llama_mobile library
add_library(llama_mobile STATIC IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libllama_mobile.a
)

# Add the JNI implementation library
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link the JNI library with the pre-built llama_mobile library
find_library(log-lib log)
find_library(android-lib android)

# Add linker flags for 16 KB page alignment
target_link_options(llama_mobile_jni PRIVATE
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384
)

# Link the libraries
target_link_libraries(
    llama_mobile_jni
    llama_mobile
    ${log-lib}
    ${android-lib}
)
