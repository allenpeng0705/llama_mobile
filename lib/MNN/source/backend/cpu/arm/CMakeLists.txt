IF(NOT DEFINED ARCHS)
  set(ARCHS ${CMAKE_SYSTEM_PROCESSOR})
ENDIF()
FILE(GLOB MNN_AArch32_SRC ${CMAKE_CURRENT_LIST_DIR}/arm32/*.[sS])
FILE(GLOB MNN_AArch64_SRC ${CMAKE_CURRENT_LIST_DIR}/arm64/*.[sS])

FILE(GLOB MNN_NEON_SRC ${CMAKE_CURRENT_LIST_DIR}/CommonOptFunctionNeon.cpp)
if (MNN_SUPPORT_BF16)
    FILE(GLOB MNN_NEON_SRC ${MNN_NEON_SRC} ${CMAKE_CURRENT_LIST_DIR}/CommonNeonBF16.cpp)
    FILE(GLOB MNN_AArch32_SRC ${MNN_AArch32_SRC} ${CMAKE_CURRENT_LIST_DIR}/arm32/bf16/*.[sS])
    FILE(GLOB MNN_AArch64_SRC ${MNN_AArch64_SRC} ${CMAKE_CURRENT_LIST_DIR}/arm64/bf16/*.[sS])
endif()

if (MNN_LOW_MEMORY)
    if (MNN_USE_NEON)
        FILE(GLOB MNN_AArch64_SRC ${MNN_AArch64_SRC} ${CMAKE_CURRENT_LIST_DIR}/arm64/low_memory/*.[sS])
    endif()
endif()

if (MNN_CPU_WEIGHT_DEQUANT_GEMM)
    if (MNN_USE_NEON)
        FILE(GLOB MNN_AArch64_SRC ${MNN_AArch64_SRC} ${CMAKE_CURRENT_LIST_DIR}/arm64/normal_memory/*.[sS])
    endif()
endif()

# Check for iOS architectures using CMAKE_OSX_ARCHITECTURES
set(IS_ARM64 FALSE)
set(IS_ARMV7 FALSE)

message(STATUS "CMAKE_OSX_ARCHITECTURES: ${CMAKE_OSX_ARCHITECTURES}")
message(STATUS "CMAKE_SYSTEM_PROCESSOR: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "ARCHS: ${ARCHS}")
message(STATUS "MNN_USE_NEON: ${MNN_USE_NEON}")

# Check for iOS architectures
if(CMAKE_OSX_ARCHITECTURES)
    message(STATUS "Processing CMAKE_OSX_ARCHITECTURES: ${CMAKE_OSX_ARCHITECTURES}")
    # Check if arm64 is in the list (works for semicolon-separated lists)
    string(FIND "${CMAKE_OSX_ARCHITECTURES}" "arm64" ARM64_POS)
    if(ARM64_POS GREATER_EQUAL 0)
        set(IS_ARM64 TRUE)
        message(STATUS "Detected arm64 architecture in CMAKE_OSX_ARCHITECTURES")
    endif()
    
    # Check if armv7 is in the list
    string(FIND "${CMAKE_OSX_ARCHITECTURES}" "armv7" ARMV7_POS)
    if(ARMV7_POS GREATER_EQUAL 0)
        set(IS_ARMV7 TRUE)
        message(STATUS "Detected armv7 architecture in CMAKE_OSX_ARCHITECTURES")
    endif()
endif()

# Ensure ARM64 detection works for iOS simulator builds with arm64 architecture
if(CMAKE_OSX_SYSROOT MATCHES "iphonesimulator")
    if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
        set(IS_ARM64 TRUE)
        message(STATUS "Detected arm64 architecture in iOS simulator build")
    endif()
endif()

# Also check traditional processor detection for non-iOS builds or override if needed
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^aarch64" OR ARCHS MATCHES "arm64" OR ARCHS MATCHES "ARM64")
    set(IS_ARM64 TRUE)
    message(STATUS "Detected arm64 via traditional processor detection")
endif()

if(CMAKE_SYSTEM_PROCESSOR MATCHES "^armv7" OR ARCHS MATCHES "^armv7(;armv7s)?")
    set(IS_ARMV7 TRUE)
    message(STATUS "Detected armv7 via traditional processor detection")
endif()

# Special case for iOS where CMAKE_SYSTEM_PROCESSOR might be set to arm64 but detection needs confirmation
if(CMAKE_OSX_SYSROOT MATCHES "iphoneos" OR CMAKE_OSX_SYSROOT MATCHES "iphonesimulator")
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
        set(IS_ARM64 TRUE)
        message(STATUS "Detected iOS arm64 build")
    endif()
endif()

message(STATUS "Final IS_ARM64: ${IS_ARM64}, IS_ARMV7: ${IS_ARMV7}")

if(IS_ARMV7 AND MNN_USE_NEON)
    message(STATUS "Enabling AArch32 Assemblies (NEON only)")
    
    set(MNN_ARM32_SRCS ${MNN_AArch32_SRC})
    list(APPEND MNN_ARM32_SRCS ${MNN_NEON_SRC})
    add_definitions(-DMNN_USE_NEON)
    
    add_library(MNNARM32 OBJECT ${MNN_ARM32_SRCS})
    target_include_directories(MNNARM32 PRIVATE ${CMAKE_CURRENT_LIST_DIR}/)
    list(APPEND MNN_OBJECTS_TO_LINK $<TARGET_OBJECTS:MNNARM32>)
    list(APPEND MNN_TARGETS MNNARM32)
    target_compile_options(MNNARM32 PRIVATE -D__arm__)
    if (MNN_SUPPORT_BF16)
        target_compile_options(MNNARM32 PRIVATE -DMNN_SUPPORT_BF16)
    endif()
elif(IS_ARM64 AND MNN_USE_NEON)
    message(STATUS "Enabling AArch64 Assemblies (NEON only)")

    if (MNN_KLEIDIAI)
       include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/KleidiAI.cmake)
       download_kleidiai_and_collect_sources()
       if(MNN_KLEIDIAI_DEFAULT_ON)
           add_definitions(-DMNN_DEFAULT_USE_KLEIDIAI)
        endif()
    endif()

    if (MNN_SME2)
        add_definitions(-DMNN_SME2)
        FILE(GLOB MNN_SME2_AArch64_SRC ${MNN_SME2_AArch64_SRC} ${CMAKE_CURRENT_LIST_DIR}/arm64/sme2_asm/*.[sS])
        #set_source_files_properties(${MNN_SME2_AArch64_SRC} PROPERTIES COMPILE_OPTIONS "-fno-tree-vectorize;-march=armv8.6-a+sve+sve2+sme+sme2+fp16")
        set_source_files_properties(${MNN_SME2_SRCS_ASM_FP16} PROPERTIES COMPILE_OPTIONS "-fno-tree-vectorize;-march=armv8.2-a+fp16")
    endif()
    
    set(MNN_ARM64_SRCS ${MNN_AArch64_SRC} ${MNN_SOURCES_KLEIDIAI} ${KLEIDIAI_FILES_SME2} ${MNN_SME2_AArch64_SRC})
    list(APPEND MNN_ARM64_SRCS ${MNN_NEON_SRC})
    add_definitions(-DMNN_USE_NEON)
    
    add_library(MNNARM64 OBJECT ${MNN_ARM64_SRCS})
    target_include_directories(MNNARM64 PRIVATE ${CMAKE_CURRENT_LIST_DIR}/)
    list(APPEND MNN_OBJECTS_TO_LINK $<TARGET_OBJECTS:MNNARM64>)
    list(APPEND MNN_TARGETS MNNARM64)
    target_compile_options(MNNARM64 PRIVATE -D__aarch64__)
    if (MNN_SUPPORT_BF16)
        target_compile_options(MNNARM64 PRIVATE -DMNN_SUPPORT_BF16)
    endif()
else()
    if(IS_ARMV7 OR IS_ARM64)
        message(STATUS "Skipping ARM Assemblies (MNN_USE_NEON=OFF)")
    else()
        # Building fat binary requires multiple separate builds and lipo-by-hand under CMake's design
        message(STATUS "Skipping ARM Assemblies (Not ARM architecture)")
    endif()
endif()
