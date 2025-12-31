cmake_minimum_required(VERSION 3.10)
project(llama_mobile_core LANGUAGES C CXX ASM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable assembly language support
if(MSVC)
    enable_language(ASM_MARMASM)
else()
    enable_language(ASM)
endif()

# Add KleidiAI option
option(MNN_KLEIDIAI "Enable KleidiAI for ARM optimization" OFF)
option(MNN_KLEIDIAI_DEFAULT_ON "Use KleidiAI kernels by default" OFF)

set(LLAMA_MOBILE_CORE_SOURCES
    llama_mobile_context.cpp
    llama_mobile_loader.cpp
    llama_mobile_completion.cpp
    llama_mobile_utils.cpp
    llama_mobile_embedding.cpp
    llama_mobile_lora.cpp
    llama_mobile_ffi.cpp
    llama_mobile_api.cpp
    llama_mobile_tokenization.cpp
    llama_mobile_multimodal.cpp
    llama_mobile_tts.cpp
    llama_mobile_bench.cpp
    llama_mobile_chat.cpp
    llama_mobile_mnn.cpp
    llama_cpp/ggml.c
    llama_cpp/ggml-alloc.c
    llama_cpp/ggml-backend.cpp
    llama_cpp/ggml-backend-reg.cpp
    llama_cpp/ggml-opt.cpp
    llama_cpp/ggml-threading.cpp
    llama_cpp/ggml-quants.c
    llama_cpp/gguf.cpp
    llama_cpp/ggml-cpu/ggml-cpu.c
    llama_cpp/ggml-cpu/ggml-cpu.cpp
    llama_cpp/ggml-cpu/ggml-cpu-aarch64-feats.cpp
    llama_cpp/ggml-cpu/ggml-cpu-aarch64-quants.c
    llama_cpp/ggml-cpu/ggml-cpu-aarch64-repack.cpp
    llama_cpp/ggml-cpu/ggml-cpu-generic-repack.cpp
    llama_cpp/ggml-cpu/ggml-cpu-quants.c
    llama_cpp/ggml-cpu/ggml-cpu-traits.cpp
    llama_cpp/ggml-cpu/amx/amx.cpp
    llama_cpp/ggml-cpu/amx/mmq.cpp
    llama_cpp/ggml-cpu/unary-ops.cpp
    llama_cpp/ggml-cpu/binary-ops.cpp
    llama_cpp/ggml-cpu/sgemm.cpp
    llama_cpp/ggml-cpu/vec.cpp
    llama_cpp/ggml-cpu/ops.cpp
    llama_cpp/log.cpp
    llama_cpp/llama-impl.cpp
    llama_cpp/llama-grammar.cpp
    llama_cpp/llama-sampling.cpp
    llama_cpp/llama-vocab.cpp
    llama_cpp/llama-adapter.cpp
    llama_cpp/llama-chat.cpp
    llama_cpp/llama-context.cpp
    llama_cpp/llama-kv-cache.cpp
    llama_cpp/llama-arch.cpp
    llama_cpp/llama-batch.cpp
    llama_cpp/llama-cparams.cpp
    llama_cpp/llama-hparams.cpp
    llama_cpp/llama.cpp
    llama_cpp/llama-model.cpp
    llama_cpp/llama-kv-cache-iswa.cpp
    llama_cpp/llama-model-loader.cpp
    llama_cpp/llama-model-saver.cpp
    llama_cpp/llama-mmap.cpp
    llama_cpp/llama-memory.cpp
    llama_cpp/llama-memory-hybrid.cpp
    llama_cpp/llama-memory-recurrent.cpp
    llama_cpp/llama-io.cpp
    llama_cpp/llama-graph.cpp
    llama_cpp/sampling.cpp
    llama_cpp/unicode-data.cpp
    llama_cpp/unicode.cpp
    llama_cpp/common.cpp
    llama_cpp/chat.cpp
    llama_cpp/json-schema-to-grammar.cpp
    llama_cpp/console.cpp
    llama_cpp/json-partial.cpp
    llama_cpp/llguidance.cpp
    llama_cpp/ngram-cache.cpp
    llama_cpp/preset.cpp
    llama_cpp/regex-partial.cpp
    llama_cpp/speculative.cpp
    llama_cpp/chat-parser.cpp
    llama_cpp/chat-peg-parser.cpp
    llama_cpp/chat-parser-xml-toolcall.cpp
    llama_cpp/peg-parser.cpp
    llama_cpp/arg.cpp
    llama_cpp/download.cpp
    llama_cpp/minja/minja.hpp
    llama_cpp/minja/chat-template.hpp
    llama_cpp/nlohmann/json.hpp
    llama_cpp/nlohmann/json_fwd.hpp
    llama_cpp/tools/mtmd/clip.cpp
    llama_cpp/tools/mtmd/mtmd.cpp
    llama_cpp/tools/mtmd/mtmd-audio.cpp
    llama_cpp/tools/mtmd/mtmd-helper.cpp
    llama_cpp/tools/mtmd/models/cogvlm.cpp
    llama_cpp/tools/mtmd/models/conformer.cpp
    llama_cpp/tools/mtmd/models/glm4v.cpp
    llama_cpp/tools/mtmd/models/internvl.cpp
    llama_cpp/tools/mtmd/models/kimivl.cpp
    llama_cpp/tools/mtmd/models/llama4.cpp
    llama_cpp/tools/mtmd/models/llava.cpp
    llama_cpp/tools/mtmd/models/minicpmv.cpp
    llama_cpp/tools/mtmd/models/pixtral.cpp
    llama_cpp/tools/mtmd/models/qwen2vl.cpp
    llama_cpp/tools/mtmd/models/qwen3vl.cpp
    llama_cpp/tools/mtmd/models/siglip.cpp
    llama_cpp/tools/mtmd/models/whisper-enc.cpp
    llama_cpp/models/afmoe.cpp
    llama_cpp/models/apertus.cpp
    llama_cpp/models/arcee.cpp
    llama_cpp/models/arctic.cpp
    llama_cpp/models/arwkv7.cpp
    llama_cpp/models/baichuan.cpp
    llama_cpp/models/bailingmoe.cpp
    llama_cpp/models/bailingmoe2.cpp
    llama_cpp/models/bert.cpp
    llama_cpp/models/bitnet.cpp
    llama_cpp/models/bloom.cpp
    llama_cpp/models/chameleon.cpp
    llama_cpp/models/chatglm.cpp
    llama_cpp/models/codeshell.cpp
    llama_cpp/models/cogvlm.cpp
    llama_cpp/models/cohere2-iswa.cpp
    llama_cpp/models/command-r.cpp
    llama_cpp/models/dbrx.cpp
    llama_cpp/models/deci.cpp
    llama_cpp/models/deepseek.cpp
    llama_cpp/models/deepseek2.cpp
    llama_cpp/models/dots1.cpp
    llama_cpp/models/dream.cpp
    llama_cpp/models/ernie4-5-moe.cpp
    llama_cpp/models/ernie4-5.cpp
    llama_cpp/models/exaone.cpp
    llama_cpp/models/exaone4.cpp
    llama_cpp/models/falcon-h1.cpp
    llama_cpp/models/falcon.cpp
    llama_cpp/models/gemma-embedding.cpp
    llama_cpp/models/gemma.cpp
    llama_cpp/models/gemma2-iswa.cpp
    llama_cpp/models/gemma3.cpp
    llama_cpp/models/gemma3n-iswa.cpp
    llama_cpp/models/glm4-moe.cpp
    llama_cpp/models/glm4.cpp
    llama_cpp/models/gpt2.cpp
    llama_cpp/models/gptneox.cpp
    llama_cpp/models/granite-hybrid.cpp
    llama_cpp/models/granite.cpp
    llama_cpp/models/graph-context-mamba.cpp
    llama_cpp/models/grok.cpp
    llama_cpp/models/grovemoe.cpp
    llama_cpp/models/hunyuan-dense.cpp
    llama_cpp/models/hunyuan-moe.cpp
    llama_cpp/models/internlm2.cpp
    llama_cpp/models/jais.cpp
    llama_cpp/models/jamba.cpp
    llama_cpp/models/lfm2.cpp
    llama_cpp/models/llada-moe.cpp
    llama_cpp/models/llada.cpp
    llama_cpp/models/llama-iswa.cpp
    llama_cpp/models/llama.cpp
    llama_cpp/models/mamba.cpp
    llama_cpp/models/minicpm3.cpp
    llama_cpp/models/minimax-m2.cpp
    llama_cpp/models/mistral3.cpp
    llama_cpp/models/modern-bert.cpp
    llama_cpp/models/mpt.cpp
    llama_cpp/models/nemotron-h.cpp
    llama_cpp/models/nemotron.cpp
    llama_cpp/models/neo-bert.cpp
    llama_cpp/models/olmo.cpp
    llama_cpp/models/olmo2.cpp
    llama_cpp/models/olmoe.cpp
    llama_cpp/models/openai-moe-iswa.cpp
    llama_cpp/models/openelm.cpp
    llama_cpp/models/orion.cpp
    llama_cpp/models/pangu-embedded.cpp
    llama_cpp/models/phi2.cpp
    llama_cpp/models/phi3.cpp
    llama_cpp/models/plamo.cpp
    llama_cpp/models/plamo2.cpp
    llama_cpp/models/plm.cpp
    llama_cpp/models/qwen.cpp
    llama_cpp/models/qwen2.cpp
    llama_cpp/models/qwen2moe.cpp
    llama_cpp/models/qwen2vl.cpp
    llama_cpp/models/qwen3.cpp
    llama_cpp/models/qwen3moe.cpp
    llama_cpp/models/qwen3next.cpp
    llama_cpp/models/qwen3vl-moe.cpp
    llama_cpp/models/qwen3vl.cpp
    llama_cpp/models/refact.cpp
    llama_cpp/models/rnd1.cpp
    llama_cpp/models/rwkv6-base.cpp
    llama_cpp/models/rwkv6.cpp
    llama_cpp/models/rwkv6qwen2.cpp
    llama_cpp/models/rwkv7-base.cpp
    llama_cpp/models/rwkv7.cpp
    llama_cpp/models/seed-oss.cpp
    llama_cpp/models/smallthinker.cpp
    llama_cpp/models/smollm3.cpp
    llama_cpp/models/stablelm.cpp
    llama_cpp/models/starcoder.cpp
    llama_cpp/models/starcoder2.cpp
    llama_cpp/models/t5-dec.cpp
    llama_cpp/models/t5-enc.cpp
    llama_cpp/models/wavtokenizer-dec.cpp
    llama_cpp/models/xverse.cpp
    llama_cpp/version.cpp

    # MNN source files - will be collected using file(GLOB) below

)

# Collect MNN source files using GLOB
file(GLOB MNN_CORE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/core/*.cpp")
file(GLOB MNN_CV_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/cv/*.cpp")
file(GLOB MNN_MATH_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/math/*.cpp")
file(GLOB MNN_UTILS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/utils/*.cpp")
file(GLOB MNN_SHAPE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/shape/*.cpp")
file(GLOB MNN_GEOMETRY_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/geometry/*.cpp")
file(GLOB MNN_CPU_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/*.c")
file(GLOB MNN_CPU_COMPUTE_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/compute/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/compute/*.c")

# Collect MNN CPU ARM sources, excluding KleidiAI files (they will be added separately if enabled)
file(GLOB MNN_CPU_ARM_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/*.S" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/arm32/*.S" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/arm64/*.S")
list(FILTER MNN_CPU_ARM_SOURCES EXCLUDE REGEX "mnn_kleidiai\\.(cpp|c)$|mnn_kleidiai_util\\.(cpp|c)$")

# Add KleidiAI source files if enabled
if(MNN_KLEIDIAI)
    message(STATUS "Including KleidiAI source files")
    
    # Add MNN's KleidiAI wrapper files
    list(APPEND MNN_CPU_ARM_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/mnn_kleidiai.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/arm/mnn_kleidiai_util.cpp")
    
    # Define preprocessor macros based on enabled features
    if(MNN_SME2)
        add_definitions(-DMNN_SME2=1)
    else()
        add_definitions(-DMNN_SME2=0)
    endif()
    
    # Add the include directories for KleidiAI
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/pack)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f32_qai8dxp_qsi4cxp)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f16_qsi8d32p_qai4c32p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f32_qsi8d32p_qai4c32p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f32_f32p_f32p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f16_f16p_f16p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f16_bf16p_bf16p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f32_f32_f32p)
    include_directories(${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/matmul_clamp_f16_f16_f16p)
    
    # Add KleidiAI core source files
    # Exclude SME2 files from general pack sources unless MNN_SME2 is enabled
    # Also filter out BF16/FP16 specific files as they require special compiler flags that may not be available
    if(MNN_SME2)
        file(GLOB KLEIDIAI_PACK_SOURCES_TMP "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/pack/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/pack/*.S")
    else()
        # Get all .c and .S files
        file(GLOB KLEIDIAI_PACK_SOURCES_TMP "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/pack/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/pack/*.S")
    endif()
    
    # Filter out files based on architecture and features
    set(KLEIDIAI_PACK_SOURCES "")
    foreach(file ${KLEIDIAI_PACK_SOURCES_TMP})
        # Always filter out SME2 files when MNN_SME2 is not enabled
        if(NOT MNN_SME2 AND (file MATCHES ".*_sme[^/]*\.(c|S)$" OR file MATCHES ".*_sme2_.*\.(c|S)$"))
            continue()
        endif()
        
        # Filter out BF16 specific files as they require special compiler flags
        if(file MATCHES "bf16")
            continue()
        endif()
        
        # Filter out files requiring I8mm extension which may not be available
        if(file MATCHES "_i8mm")
            continue()
        endif()
        
        list(APPEND KLEIDIAI_PACK_SOURCES ${file})
    endforeach()
    
    list(APPEND MNN_CPU_ARM_SOURCES ${KLEIDIAI_PACK_SOURCES})
    
    # Add specific matmul source files
    # Filter out SME2 files from matmul directories when MNN_SME2 is not enabled
    # Also filter out BF16/FP16 specific files as they require special compiler flags that may not be available
    macro(AddKleidiAIMatmulSources dir_name)
        file(GLOB KLEIDIAI_MATMUL_SOURCES_TMP "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/${dir_name}/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/matmul/${dir_name}/*.S")
        set(KLEIDIAI_MATMUL_SOURCES "")
        foreach(file ${KLEIDIAI_MATMUL_SOURCES_TMP})
            # Skip SME2 files when MNN_SME2 is not enabled
            if(NOT MNN_SME2 AND (file MATCHES ".*_sme[^/]*\.(c|S)$" OR file MATCHES ".*_sme2_.*\.(c|S)$"))
                continue()
            endif()
            
            # Skip BF16 specific files
            if(file MATCHES "bf16")
                continue()
            endif()
            
            # Skip files requiring I8mm extension which may not be available
            if(file MATCHES "_i8mm")
                continue()
            endif()
            
            list(APPEND KLEIDIAI_MATMUL_SOURCES ${file})
        endforeach()
        list(APPEND MNN_CPU_ARM_SOURCES ${KLEIDIAI_MATMUL_SOURCES})
    endmacro()
    
    AddKleidiAIMatmulSources(matmul_clamp_f32_qai8dxp_qsi4cxp)
    AddKleidiAIMatmulSources(matmul_clamp_f16_qsi8d32p_qai4c32p)
    AddKleidiAIMatmulSources(matmul_clamp_f32_qsi8d32p_qai4c32p)
    AddKleidiAIMatmulSources(matmul_clamp_f32_f32p_f32p)
    AddKleidiAIMatmulSources(matmul_clamp_f16_f16p_f16p)
    AddKleidiAIMatmulSources(matmul_clamp_f16_bf16p_bf16p)
    AddKleidiAIMatmulSources(matmul_clamp_f32_f32_f32p)
    AddKleidiAIMatmulSources(matmul_clamp_f16_f16_f16p)
    
    # Add SME2-specific files if enabled
    if(MNN_SME2)
        file(GLOB KLEIDIAI_SME2_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/ukernels/*/*_sme.c" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai/*_sme_asm.S")
        list(APPEND MNN_CPU_ARM_SOURCES ${KLEIDIAI_SME2_SOURCES})
    endif()
endif()

file(GLOB MNN_CPU_X86_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/x86/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/x86/*.c")
file(GLOB MNN_EXPRESS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/express/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/MNN/express/module/*.cpp")
file(GLOB_RECURSE MNN_LLM_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/MNN/transformers/llm/engine/src/*.cpp")

# Append MNN sources to the core sources list
list(APPEND LLAMA_MOBILE_CORE_SOURCES 
    ${MNN_CORE_SOURCES}
    ${MNN_CV_SOURCES}
    ${MNN_MATH_SOURCES}
    ${MNN_UTILS_SOURCES}
    ${MNN_SHAPE_SOURCES}
    ${MNN_GEOMETRY_SOURCES}
    ${MNN_CPU_SOURCES}
    ${MNN_CPU_COMPUTE_SOURCES}
    ${MNN_CPU_ARM_SOURCES}
    ${MNN_CPU_X86_SOURCES}
    ${MNN_EXPRESS_SOURCES}
    ${MNN_LLM_SOURCES}
)

# Add Metal sources on Apple platforms
if(APPLE)
    list(APPEND LLAMA_MOBILE_CORE_SOURCES 
        llama_cpp/ggml-metal.cpp
        llama_cpp/ggml-metal-device.m
        llama_cpp/ggml-metal-device.cpp
        llama_cpp/ggml-metal-context.m
        llama_cpp/ggml-metal-common.cpp
        llama_cpp/ggml-metal-ops.cpp
        # MNN Metal backend sources
        MNN/source/backend/metal/MetalBackend.mm
        MNN/source/backend/metal/MetalUnary.mm
        MNN/source/backend/metal/MetalRaster.mm
        MNN/source/backend/metal/MetalScale.mm
        MNN/source/backend/metal/MetalSoftmax.mm
        MNN/source/backend/metal/MetalReduction.mm
        MNN/source/backend/metal/MetalReLU6.mm
        MNN/source/backend/metal/MetalPReLU.mm
        MNN/source/backend/metal/MetalROIPooling.mm
        MNN/source/backend/metal/MetalMatMul.mm
        MNN/source/backend/metal/MetalPooling.mm
        MNN/source/backend/metal/MetalLoop.mm
        MNN/source/backend/metal/MetalOPRegister.mm
        MNN/source/backend/metal/MetalLayerNorm.mm
        MNN/source/backend/metal/MetalFuse.mm
        MNN/source/backend/metal/MetalInterp.mm
        MNN/source/backend/metal/MetalGridSample.mm
        MNN/source/backend/metal/MetalDeconvolution.mm
        MNN/source/backend/metal/MetalExecution.mm
        MNN/source/backend/metal/MetalEltwise.mm
        MNN/source/backend/metal/MetalKVCacheManager.mm
        MNN/source/backend/metal/MetalConvolutionWinograd.mm
        MNN/source/backend/metal/MetalConvolutionCommon.mm
        MNN/source/backend/metal/MetalConvolutionDepthwise.mm
        MNN/source/backend/metal/MetalConvolution.mm
        MNN/source/backend/metal/MetalConvolution1x1.mm
        MNN/source/backend/metal/MetalCast.mm
        MNN/source/backend/metal/MetalBinary.mm
        MNN/source/backend/metal/MetalAttention.mm
        MNN/source/backend/metal/MetalArgMax.mm
        MNN/source/backend/metal/AllShader.cpp
        MNN/source/backend/metal/ShaderMap.cpp
        MNN/source/backend/metal/MNNMetalContext.mm
        MNN/source/backend/metal/render/MetalRenderOpRegister.mm
        MNN/source/backend/metal/render/MetalRasterAndInterpolate.mm
    )
endif()

add_library(llama_mobile_core_lib OBJECT ${LLAMA_MOBILE_CORE_SOURCES})

# Create static library
add_library(llama_mobile_core_static STATIC $<TARGET_OBJECTS:llama_mobile_core_lib>)
set_target_properties(llama_mobile_core_static PROPERTIES OUTPUT_NAME "llama_mobile_core")

# Create shared library
add_library(llama_mobile_core_shared SHARED $<TARGET_OBJECTS:llama_mobile_core_lib>)
set_target_properties(llama_mobile_core_shared PROPERTIES OUTPUT_NAME "llama_mobile_core")

# Configure common output directory
set(OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/output")
set(LIBRARY_OUTPUT_PATH "${OUTPUT_DIR}/lib")
set(INCLUDE_OUTPUT_PATH "${OUTPUT_DIR}/include")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_PATH})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${OUTPUT_DIR})

# Apply the same include directories to both libraries
target_include_directories(llama_mobile_core_static PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/ggml-cpu>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/minja>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/tools/mtmd>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/express>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/transformers/llm/engine/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/half>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/flatbuffers/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/schema/current>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/tools/cpp>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/x86_x64>
)

target_include_directories(llama_mobile_core_shared PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/ggml-cpu>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/minja>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/tools/mtmd>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/express>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/transformers/llm/engine/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/half>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/flatbuffers/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/x86_x64>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kleidiai-1.14.0/kai>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/schema/current>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/tools/cpp>
)

target_include_directories(llama_mobile_core_lib PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/ggml-cpu>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/minja>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/tools/mtmd>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/express>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/transformers/llm/engine/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/half>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/flatbuffers/include>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/3rd_party/kleidiai/kai>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/schema/current>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/tools/cpp>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/MNN/source/backend/cpu/x86_x64>
)

if(NOT MSVC)
    target_compile_options(llama_mobile_core_lib PRIVATE -Wno-cast-qual)
endif()

# Get version information from the local ggml.h file
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/ggml.h" GGML_H_CONTENT)
string(REGEX MATCH "#define LM_GGML_VERSION ([0-9]+)" _ "${GGML_H_CONTENT}")
set(LM_GGML_VERSION "${CMAKE_MATCH_1}")

# Set a default version since we can't read from the original CMakeLists.txt
set(GGML_VERSION "2.2.0")

# Get git commit if available
find_package(Git)
if(GIT_FOUND)
    execute_process(COMMAND "${GIT_EXECUTABLE}" rev-parse --short HEAD
        WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.."
        OUTPUT_VARIABLE GGML_BUILD_COMMIT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
endif()

if(NOT GGML_BUILD_COMMIT)
    set(GGML_BUILD_COMMIT "unknown")
endif()

target_compile_definitions(llama_mobile_core_lib PUBLIC
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
    LM_GGML_VERSION="${GGML_VERSION}"
    LM_GGML_COMMIT="${GGML_BUILD_COMMIT}"
    $<$<BOOL:${GGML_NO_POSIX_MADVISE}>:GGML_NO_POSIX_MADVISE>
    # MNN compile definitions
    MNN_BUILD_SHARED_LIBS=OFF
    $<$<BOOL:${ANDROID}>:MNN_ANDROID>
    $<$<BOOL:${ANDROID}>:MNN_USE_LOGCAT>
    $<$<BOOL:${APPLE}>:MNN_METAL>
    $<$<BOOL:${APPLE}>:MNN_USE_METAL>
    # Enable NEON and KleidiAI for ARM architectures
    $<$<C_COMPILER_ID:AppleClang>:
        $<$<PLATFORM_ID:iOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON=1>
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_KLEIDIAI>
        >
        $<$<PLATFORM_ID:macOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON=1>
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_KLEIDIAI>
        >
    >
    $<$<C_COMPILER_ID:Clang>:
        $<$<PLATFORM_ID:Android>:
            $<$<STREQUAL:${ANDROID_ABI},armeabi-v7a>:MNN_USE_NEON=1>
            $<$<STREQUAL:${ANDROID_ABI},arm64-v8a>:MNN_USE_NEON=1>
            $<$<STREQUAL:${ANDROID_ABI},arm64-v8a>:MNN_KLEIDIAI>
        >
    >
    # Also enable for generic ARM compilers
    $<$<C_COMPILER_ID:ARMCC,ARMClang>:
        MNN_USE_NEON=1
        MNN_KLEIDIAI
    >
    LM_MNN_SUPPORT=1
)

target_compile_definitions(llama_mobile_core_static PUBLIC
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
    LM_GGML_VERSION="${GGML_VERSION}"
    LM_GGML_COMMIT="${GGML_BUILD_COMMIT}"
    $<$<BOOL:${GGML_NO_POSIX_MADVISE}>:GGML_NO_POSIX_MADVISE>
    # MNN compile definitions
    MNN_BUILD_SHARED_LIBS=OFF
    MNN_USE_LOGCAT=false
    $<$<BOOL:${ANDROID}>:MNN_ANDROID>
    $<$<BOOL:${APPLE}>:MNN_METAL>
    $<$<BOOL:${APPLE}>:MNN_USE_METAL>
    # Enable NEON for ARM architectures
    $<$<C_COMPILER_ID:AppleClang>:
        $<$<PLATFORM_ID:iOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON>
        >
        $<$<PLATFORM_ID:macOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON>
        >
    >
    $<$<C_COMPILER_ID:Clang>:
        $<$<PLATFORM_ID:Android>:
            $<$<STREQUAL:${ANDROID_ABI},armeabi-v7a>:MNN_USE_NEON>
            $<$<STREQUAL:${ANDROID_ABI},arm64-v8a>:MNN_USE_NEON>
        >
    >
    # Also enable for generic ARM compilers
    $<$<C_COMPILER_ID:ARMCC,ARMClang>:
        MNN_USE_NEON
    >
    LM_MNN_SUPPORT=1
)

target_compile_definitions(llama_mobile_core_shared PUBLIC
    LM_GGML_USE_CPU
    LLAMA_MOBILE_VERBOSE=0
    LM_GGML_VERSION="${GGML_VERSION}"
    LM_GGML_COMMIT="${GGML_BUILD_COMMIT}"
    $<$<BOOL:${GGML_NO_POSIX_MADVISE}>:GGML_NO_POSIX_MADVISE>
    # MNN compile definitions
    MNN_BUILD_SHARED_LIBS=OFF
    MNN_USE_LOGCAT=false
    $<$<BOOL:${ANDROID}>:MNN_ANDROID>
    $<$<BOOL:${APPLE}>:MNN_METAL>
    $<$<BOOL:${APPLE}>:MNN_USE_METAL>
    # Enable NEON for ARM architectures
    $<$<C_COMPILER_ID:AppleClang>:
        $<$<PLATFORM_ID:iOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON>
        >
        $<$<PLATFORM_ID:macOS>:
            $<$<EQUAL:${CMAKE_OSX_ARCHITECTURES},arm64>:MNN_USE_NEON>
        >
    >
    $<$<C_COMPILER_ID:Clang>:
        $<$<PLATFORM_ID:Android>:
            $<$<STREQUAL:${ANDROID_ABI},armeabi-v7a>:MNN_USE_NEON>
            $<$<STREQUAL:${ANDROID_ABI},arm64-v8a>:MNN_USE_NEON>
        >
    >
    # Also enable for generic ARM compilers
    $<$<C_COMPILER_ID:ARMCC,ARMClang>:
        MNN_USE_NEON
    >
    LM_MNN_SUPPORT=1
)

if(APPLE)
    find_library(FOUNDATION_LIBRARY Foundation)
    find_library(ACCELERATE_FRAMEWORK Accelerate)
    find_library(METAL_LIBRARY Metal)
    find_library(METALKIT_LIBRARY MetalKit)

    # Add framework include directories
    set(METAL_INCLUDE_DIRS ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    
    if(FOUNDATION_LIBRARY AND ACCELERATE_FRAMEWORK)
        target_link_libraries(llama_mobile_core_lib PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
        target_link_libraries(llama_mobile_core_static PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
        target_link_libraries(llama_mobile_core_shared PUBLIC
            ${FOUNDATION_LIBRARY}
            ${ACCELERATE_FRAMEWORK}
        )
        target_compile_definitions(llama_mobile_core_lib PUBLIC
            LM_GGML_USE_ACCELERATE
        )
        target_compile_definitions(llama_mobile_core_static PUBLIC
            LM_GGML_USE_ACCELERATE
        )
        target_compile_definitions(llama_mobile_core_shared PUBLIC
            LM_GGML_USE_ACCELERATE
        )
    endif()
    
    # Link Metal libraries on Apple platforms
    if(METAL_LIBRARY AND METALKIT_LIBRARY)
        # Add Metal framework includes
        target_include_directories(llama_mobile_core_lib PUBLIC
            ${METAL_INCLUDE_DIRS}
        )
        target_include_directories(llama_mobile_core_static PUBLIC
            ${METAL_INCLUDE_DIRS}
        )
        target_include_directories(llama_mobile_core_shared PUBLIC
            ${METAL_INCLUDE_DIRS}
        )
        
        target_link_libraries(llama_mobile_core_lib PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
        target_link_libraries(llama_mobile_core_static PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
        target_link_libraries(llama_mobile_core_shared PUBLIC
            ${METAL_LIBRARY}
            ${METALKIT_LIBRARY}
        )
        target_compile_definitions(llama_mobile_core_lib PUBLIC
            LM_GGML_USE_METAL
            LM_GGML_METAL_USE_BF16
        )
        target_compile_definitions(llama_mobile_core_static PUBLIC
            LM_GGML_USE_METAL
            LM_GGML_METAL_USE_BF16
        )
        target_compile_definitions(llama_mobile_core_shared PUBLIC
            LM_GGML_USE_METAL
            LM_GGML_METAL_USE_BF16
        )
        
        # Copy Metal shader files to output directory
        configure_file(llama_cpp/ggml-metal.metal ${OUTPUT_DIR}/ggml-metal.metal COPYONLY)
        configure_file(llama_cpp/ggml-common.h ${OUTPUT_DIR}/ggml-common.h COPYONLY)
        configure_file(llama_cpp/ggml-metal-impl.h ${OUTPUT_DIR}/ggml-metal-impl.h COPYONLY)
    endif()
endif()

# Android-specific settings
if(ANDROID)
    find_library(LOG_LIBRARY log)
    if(LOG_LIBRARY)
        target_link_libraries(llama_mobile_core_lib PUBLIC ${LOG_LIBRARY})
        target_link_libraries(llama_mobile_core_static PUBLIC ${LOG_LIBRARY})
        target_link_libraries(llama_mobile_core_shared PUBLIC ${LOG_LIBRARY})
    endif()
    
    # Always disable POSIX madvise on Android
    target_compile_definitions(llama_mobile_core_lib PUBLIC GGML_NO_POSIX_MADVISE)
    target_compile_definitions(llama_mobile_core_static PUBLIC GGML_NO_POSIX_MADVISE)
    target_compile_definitions(llama_mobile_core_shared PUBLIC GGML_NO_POSIX_MADVISE)
endif()

# Copy headers to include directory
file(MAKE_DIRECTORY ${INCLUDE_OUTPUT_PATH})
file(MAKE_DIRECTORY ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(MAKE_DIRECTORY ${INCLUDE_OUTPUT_PATH}/llama_cpp/ggml-cpu)
file(MAKE_DIRECTORY ${INCLUDE_OUTPUT_PATH}/llama_cpp/minja)
file(MAKE_DIRECTORY ${INCLUDE_OUTPUT_PATH}/llama_cpp/tools/mtmd)

# Copy main header (unified only)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_mobile_unified.h DESTINATION ${INCLUDE_OUTPUT_PATH})

# Copy llama_cpp headers
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/llama.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/llama-cpp.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/ggml.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/gguf.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/common.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/chat.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)
file(COPY ${CMAKE_CURRENT_SOURCE_DIR}/llama_cpp/sampling.h DESTINATION ${INCLUDE_OUTPUT_PATH}/llama_cpp)

# Add tests subdirectory
add_subdirectory(tests)

