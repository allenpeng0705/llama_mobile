cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Set C++ standard library to static to avoid libc++_shared.so dependency
set(ANDROID_STL c++_static)

# Add include directories for llama_mobile headers
include_directories(
    ${CMAKE_SOURCE_DIR}/include
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

# GPU Support Note:
# OpenCL and Vulkan libraries are loaded at runtime using dlopen() by llama.cpp.
# The pre-built libllama_mobile.a includes GPU support but has undefined symbols.
# We link against stub libraries at build time to satisfy the linker.
# The actual GPU libraries on the device will be used at runtime.

# Find OpenCL library (use stub if available, otherwise skip)
# First check for system OpenCL
find_library(opencl-lib OpenCL)
if(opencl-lib)
    message(STATUS "Found system OpenCL library: ${opencl-lib}")
else()
    # Check for our stub library
    set(OPENCL_STUB_PATH "${CMAKE_SOURCE_DIR}/../../../libs/stubs/${ANDROID_ABI}/libOpenCL.a")
    if(EXISTS ${OPENCL_STUB_PATH})
        message(STATUS "Found OpenCL stub library: ${OPENCL_STUB_PATH}")
        add_library(OpenCL STATIC IMPORTED)
        set_target_properties(OpenCL PROPERTIES
            IMPORTED_LOCATION ${OPENCL_STUB_PATH}
        )
        set(opencl-lib OpenCL)
    else()
        message(STATUS "OpenCL library not found, will rely on runtime loading")
    endif()
endif()

# Use our Vulkan stub library instead of system Vulkan
# The system Vulkan library in NDK doesn't have all the required functions
set(VULKAN_STUB_PATH "${CMAKE_SOURCE_DIR}/../../../libs/stubs/${ANDROID_ABI}/libvulkan_stub.a")
if(EXISTS ${VULKAN_STUB_PATH})
    message(STATUS "Found Vulkan stub library: ${VULKAN_STUB_PATH}")
    add_library(vulkan_stub STATIC IMPORTED)
    set_target_properties(vulkan_stub PROPERTIES
        IMPORTED_LOCATION ${VULKAN_STUB_PATH}
    )
    set(vulkan-lib vulkan_stub)
else()
    # Fall back to system Vulkan if stub not found
    find_library(vulkan-lib vulkan)
    if(vulkan-lib)
        message(STATUS "Found system Vulkan library: ${vulkan-lib}")
    else()
        message(STATUS "Vulkan library not found, will rely on runtime loading")
    endif()
endif()

# Add linker flags for 16 KB page alignment
target_link_options(llama_mobile_jni PRIVATE
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384
)

# Allow undefined symbols for runtime loading of GPU libraries
# This is necessary because GPU libraries (OpenCL, Vulkan) are loaded at runtime
# using dlopen() and the symbols are resolved dynamically
target_link_options(llama_mobile_jni PRIVATE
    -Wl,--no-undefined-version
    -Wl,--allow-shlib-undefined
    -Wl,--unresolved-symbols=ignore-in-shared-libs
)

# Link the libraries
# Order matters: llama_mobile must come before system libraries
# Use --whole-archive to ensure all symbols from static library are included
set(LINK_LIBRARIES
    -Wl,--whole-archive
    llama_mobile
    -Wl,--no-whole-archive
    ${log-lib}
    ${android-lib}
)

# Add GPU libraries if found
if(vulkan-lib)
    list(APPEND LINK_LIBRARIES ${vulkan-lib})
endif()

if(opencl-lib)
    list(APPEND LINK_LIBRARIES ${opencl-lib})
endif()

target_link_libraries(llama_mobile_jni ${LINK_LIBRARIES})
