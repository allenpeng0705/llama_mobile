cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/llama_cpp
)

# Import the pre-built libraries
set(LLAMA_MOBILE_ABIS arm64-v8a x86_64)

# Shared libraries
foreach(ABI ${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_shared_${ABI} SHARED IMPORTED)
    set_target_properties(llama_mobile_shared_${ABI} PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/shared/${ABI}/libllama_mobile.so
        ANDROID_ABI ${ABI}
    )
endforeach()

# Static libraries
foreach(ABI ${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_static_${ABI} STATIC IMPORTED)
    set_target_properties(llama_mobile_static_${ABI} PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/static/${ABI}/libllama_mobile.a
        ANDROID_ABI ${ABI}
    )
endforeach()

# Main library targets for linking
# Shared library target
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/shared/${ANDROID_ABI}/libllama_mobile.so
)

# Static library target
add_library(llama_mobile_static STATIC IMPORTED)
set_target_properties(llama_mobile_static PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/static/${ANDROID_ABI}/libllama_mobile.a
)
