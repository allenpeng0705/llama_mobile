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

foreach(ABI ${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_${ABI} SHARED IMPORTED)
    set_target_properties(llama_mobile_${ABI} PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ABI}/libllama_mobile.so
        ANDROID_ABI ${ABI}
    )
endforeach()

# Main library target for linking
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libllama_mobile.so
)
