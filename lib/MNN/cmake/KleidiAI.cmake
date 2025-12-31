# ------------------------------------------------------------------------------
# Function: download_kleidiai_and_collect_sources
#
# Description:
#   Downloads the KleidiAI source code and collects relevant source files.
#   If the download fails, the function will not terminate the configuration
#   process but will return empty lists for the source files.
#
# Exposed Variables (via PARENT_SCOPE):
#   - MNN_SOURCES_KLEIDIAI : List of general KleidiAI source files.
#   - KLEIDIAI_FILES_SME2  : List of KleidiAI source files specific to SME2 architecture.
#
# Usage:
#   include(KleidiAI.cmake)
#   download_kleidiai_and_collect_sources()
#   Use MNN_SOURCES_KLEIDIAI and KLEIDIAI_FILES_SME2 in subsequent build steps.
# ------------------------------------------------------------------------------
function (download_kleidiai_and_collect_sources)
    message(STATUS "ENTERING download_kleidiai_and_collect_sources() function")
    set(MNN_SOURCES_KLEIDIAI "" PARENT_SCOPE)
    set(KLEIDIAI_FILES_SME2 "" PARENT_SCOPE)

    # Disable the KleidiAI tests
    set(KLEIDIAI_BUILD_TESTS OFF)

    set(KLEIDIAI_COMMIT_SHA "1.14.0")

    # Use local KleidiAI source from 3rd_party directory
    set(_kleidiai_src_dir "${CMAKE_CURRENT_LIST_DIR}/../3rd_party/kleidiai")
    
    # Fallback to user-provided path if local source doesn't exist
    if(DEFINED KLEIDIAI_SRC_DIR AND EXISTS "${KLEIDIAI_SRC_DIR}")
        set(_kleidiai_src_dir "${KLEIDIAI_SRC_DIR}")
    elseif(NOT EXISTS "${_kleidiai_src_dir}/kai")
        message(WARNING "KleidiAI source tree not found at expected location: ${_kleidiai_src_dir}/kai. Building without KleidiAI.")
        return()
    endif()
    
    set(KLEIDIAI_SRC_DIR
        "${_kleidiai_src_dir}"
        CACHE PATH "Path to KleidiAI source (local or provided)" FORCE)
    message(STATUS "Using KleidiAI source from: ${KLEIDIAI_SRC_DIR}")

    list(APPEND MNN_SOURCES_KLEIDIAI ${CMAKE_CURRENT_LIST_DIR}/mnn_kleidiai.cpp)
    list(APPEND MNN_SOURCES_KLEIDIAI ${CMAKE_CURRENT_LIST_DIR}/mnn_kleidiai_util.cpp)

    include_directories(
        ${KLEIDIAI_SRC_DIR}/
        ${KLEIDIAI_SRC_DIR}/kai/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32p_f32p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16p_f16p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f32_f32p_f32p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f16_f16p_f16p/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/dwconv/pack/
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/dwconv/dwconv_f32_f32_f32p/)

    file(GLOB kleidiai_pack_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_lhs_quant_pack_qsi8d32pscalef32_f16_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_lhs_quant_pack_qsi8d32pscalef32_f32_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_nxk_qsi4cxps1s0_qsu4cxs1s0_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_nxk_qai4c32p_qau4c32s0s1_f32_f32_f32_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_lhs_quant_pack_qai8dxp_f32.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_nxk_qsi4cxp_qs4cxs1s0.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_kxn_x16p32x1b_x16_x16_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_kxn_x16p32x1b_x16_x16_neon_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_kxn_x32p16x1b_x32_x32_neon.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_kxn_x32p16x1b_x32_x32_neon_asm.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${kleidiai_pack_sources})

    file(GLOB matmul_clamp_f32_qai8dxp_qsi4cxp_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*dotprod.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*i8mm.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*dotprod_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*i8mm_asm.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f32_qai8dxp_qsi4cxp_sources})

    file(GLOB matmul_clamp_f16_qsi8d32p_qai4c32p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*dotprod.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*i8mm.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*dotprod_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*i8mm_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*1x4*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*1x8*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*4x4*.c"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f16_qsi8d32p_qai4c32p_sources})

    file(GLOB matmul_clamp_f32_qsi8d32p_qai4c32p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*dotprod.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*i8mm.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*dotprod_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*i8mm_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*1x4*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*1x8*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*4x4*.c"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f32_qsi8d32p_qai4c32p_sources})

    file(GLOB sme_pack_sources
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/*_sme.c
        ${KLEIDIAI_SRC_DIR}/kai/*_sme_asm.S
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/*_sme_asm.S
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_nxk_qai4c32ps1s0nrx4_qau4c32s0s1_f32_f32_f32_neon.c
        ${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/pack/kai_rhs_pack_nxk_qai4c32ps1s0nrx4_qau4c32s1s0_f32_f32_f32_neon.c

    )
    list(APPEND KLEIDIAI_FILES_SME2 ${sme_pack_sources})

    file(GLOB matmul_clamp_f32_f32p_f32p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32p_f32p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32p_f32p/*mopa_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f32_f32p_f32p_sources})

    # Include f32 matmul files for both SME2 and Neon
    file(GLOB matmul_clamp_f32_f32_f32p_sme2_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*sme2_mla.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*sme2_mla_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f32_f32_f32p_sme2_sources})

    file(GLOB matmul_clamp_f32_f32_f32p_neon_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*neon_mla*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*neon_mla*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*cortexa55*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*cortexa55*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*bias*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p/*bias*.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f32_f32_f32p_neon_sources})

    file(GLOB matmul_clamp_f16_f16p_f16p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16p_f16p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16p_f16p/*mopa_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f16_f16p_f16p_sources})

    # Include f16 matmul files for both SME2 and Neon
    file(GLOB matmul_clamp_f16_f16_f16p_sme2_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*sme2_dot.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*sme2_dot_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f16_f16_f16p_sme2_sources})

    file(GLOB matmul_clamp_f16_f16_f16p_neon_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*neon_mla*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*neon_mla*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*cortexa55*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*cortexa55*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*bias*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p/*bias*.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f16_f16_f16p_neon_sources})

    # Include i8mm/dotprod kernels for 8-bit integer matrix multiplication
    file(GLOB matmul_clamp_f16_qsi8d32p_qai4c32p_neon_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p*qai4c32p*/*neon_dotprod.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p*qai4c32p*/*neon_dotprod_asm.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f16_qsi8d32p_qai4c32p_neon_sources})

    file(GLOB matmul_clamp_f32_qai8dxp_qsi4cxp_dotprod_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp*qsi4cxp*/*neon_dotprod.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp*qsi4cxp*/*neon_dotprod_asm.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${matmul_clamp_f32_qai8dxp_qsi4cxp_dotprod_sources})

    # Include rhs_pack directories for packing operations
    file(GLOB rhs_pack_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/rhs_pack*/*neon*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/rhs_pack*/*neon*.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/rhs_pack*/*neon*_asm.S"
    )
    list(APPEND MNN_SOURCES_KLEIDIAI ${rhs_pack_sources})

    file(GLOB matmul_clamp_f32_qai8dxp_qsi4cxp_sme_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*mopa_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*sdot.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp/*sdot_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f32_qai8dxp_qsi4cxp_sme_sources})

    file(GLOB imatmul_clamp_f32_f32p_f32p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f32_f32p_f32p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f32_f32p_f32p/*mopa_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${imatmul_clamp_f32_f32p_f32p_sources})

    file(GLOB imatmul_clamp_f16_f16p_f16p_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f16_f16p_f16p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/imatmul_clamp_f16_f16p_f16p/*mopa_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${imatmul_clamp_f16_f16p_f16p_sources})

    file(GLOB matmul_clamp_f16_qsi8d32p_qai4c32p_sme2_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*mopa_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*dot.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p/*dot_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f16_qsi8d32p_qai4c32p_sme2_sources})

    file(GLOB matmul_clamp_f32_qsi8d32p_qai4c32p_sme2_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*mopa.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*mopa_asm.S"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*dot.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p/*dot_asm.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${matmul_clamp_f32_qsi8d32p_qai4c32p_sme2_sources})

    file(GLOB dwconv_pack_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/dwconv/pack/*.c"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${dwconv_pack_sources})

    file(GLOB dwconv_f32_f32_f32p_sme2_sources
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/dwconv/dwconv_f32_f32_f32p/*.c"
        "${KLEIDIAI_SRC_DIR}/kai/ukernels/dwconv/dwconv_f32_f32_f32p/*.S"
    )
    list(APPEND KLEIDIAI_FILES_SME2 ${dwconv_f32_f32_f32p_sme2_sources})

    set_source_files_properties(
        ${MNN_SOURCES_KLEIDIAI}
        PROPERTIES COMPILE_OPTIONS
            "-fno-tree-vectorize;-march=armv8.2-a+i8mm+dotprod+sve+sve2+fp16")
    set_source_files_properties(
        ${KLEIDIAI_FILES_SME2}
        PROPERTIES COMPILE_OPTIONS
                   "-fno-tree-vectorize;-march=armv8.2-a+sve+sve2")

    # Debug: Check if assembly files are in the list
    message(STATUS "Debug - Checking assembly files in MNN_SOURCES_KLEIDIAI:")
    foreach(src_file ${MNN_SOURCES_KLEIDIAI})
        if(src_file MATCHES "\\.S$")
            message(STATUS "Found assembly file: ${src_file}")
        endif()
    endforeach()
    
    set(MNN_SOURCES_KLEIDIAI "${MNN_SOURCES_KLEIDIAI}" PARENT_SCOPE)
    set(KLEIDIAI_FILES_SME2 "${KLEIDIAI_FILES_SME2}" PARENT_SCOPE)

    # Define macro to indicate KleidiAI is enabled (only on aarch64 and when MNN_KLEIDIAI is ON)
    if(MNN_KLEIDIAI AND CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64)")
        add_definitions(-DMNN_KLEIDIAI_ENABLED=1)
    endif()
    
    message(STATUS "EXITING download_kleidiai_and_collect_sources() function")
    message(STATUS "MNN_SOURCES_KLEIDIAI size: ${CMAKE_CURRENT_LIST_DIR}/kai ${MNN_SOURCES_KLEIDIAI}")
endfunction()
