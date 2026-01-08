cmake_minimum_required(VERSION 3.18.1)

project(llama_mobile_react_native_sdk)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add the core API source files
file(GLOB_RECURSE CORE_SOURCES
    ${CMAKE_SOURCE_DIR}/../../lib/*.cpp
    ${CMAKE_SOURCE_DIR}/../../lib/llama_cpp/*.cpp
    ${CMAKE_SOURCE_DIR}/../../lib/llama_cpp/*.c
)

# Exclude unnecessary files
list(FILTER CORE_SOURCES EXCLUDE REGEX ".*tests/.*")
list(FILTER CORE_SOURCES EXCLUDE REGEX ".*grammars/.*")

# Create the core library
add_library(llama_mobile STATIC ${CORE_SOURCES})

# Create the JNI bridge library
add_library(llama_mobile_jni SHARED
    src/main/jni/llama_mobile_jni.cpp
)

# Include directories
include_directories(
    src/main/jni
    ../../lib
)

# Link against the core library
find_library(log-lib log)
find_library(jnigraphics-lib jnigraphics)

# Link libraries
target_link_libraries(llama_mobile_jni
    llama_mobile
    ${log-lib}
    ${jnigraphics-lib}
)
