# CMakeLists.txt for llama_mobile JNI implementation

cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Add the include directories for the llama_mobile headers
include_directories(
    /Users/shileipeng/Documents/mygithub/llama_mobile/llama_mobile-android/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Define the path to the pre-built llama_mobile library
set(LLAMA_MOBILE_LIB_PATH "${CMAKE_SOURCE_DIR}/../jniLibs")

# Add the pre-built llama_mobile library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libllama_mobile.so
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
