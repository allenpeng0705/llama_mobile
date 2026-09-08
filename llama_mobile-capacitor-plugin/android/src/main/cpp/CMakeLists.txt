cmake_minimum_required(VERSION 3.18.1)

project("llama_mobile_jni")

# Static C++ runtime, as with the other llama_mobile native modules.
set(ANDROID_STL c++_static)

include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Pre-built static libraries (v2 core, CPU build by default; Vulkan optional).
set(LLAMA_MOBILE_LIB_PATH "${CMAKE_SOURCE_DIR}/../../../libs")

set(STATIC_LIBS
    llama_mobile_core
    llama
    llama-common
    llama-common-base
    ggml
    ggml-base
    ggml-cpu
    vendor-hash
    mtmd
    cpp-httplib
)

# ggml-vulkan is only present when the native libs were built with Vulkan
# enabled (GGML_VULKAN=ON); link it conditionally.
if(EXISTS "${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/libggml-vulkan.a")
    list(APPEND STATIC_LIBS ggml-vulkan)
endif()

foreach(LIB_NAME ${STATIC_LIBS})
    add_library(${LIB_NAME} STATIC IMPORTED)
    set_target_properties(${LIB_NAME} PROPERTIES
        IMPORTED_LOCATION ${LLAMA_MOBILE_LIB_PATH}/${ANDROID_ABI}/lib${LIB_NAME}.a
    )
endforeach()

add_library(llama_mobile_jni SHARED llama_mobile_jni.cpp)

find_library(log-lib log)
find_library(android-lib android)
find_library(vulkan-lib vulkan)

target_link_options(llama_mobile_jni PRIVATE
    -Wl,-z,max-page-size=16384
    -Wl,-z,common-page-size=16384
)

target_link_libraries(llama_mobile_jni
    -Wl,--whole-archive
    ${STATIC_LIBS}
    -Wl,--no-whole-archive
    ${log-lib}
    ${android-lib}
    ${vulkan-lib}
)
