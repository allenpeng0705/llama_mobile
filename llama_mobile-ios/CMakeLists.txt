cmake_minimum_required(VERSION 3.16)
project(llama_mobile VERSION 1.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# iOS specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET 13.0)
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)

# Set default values for version and commit
if(NOT GGML_VERSION)
    set(GGML_VERSION "0.0.0")
endif()

if(NOT GGML_BUILD_COMMIT)
    set(GGML_BUILD_COMMIT "unknown")
endif()

# Add KleidiAI option with default OFF
#option(MNN_KLEIDIAI "Enable KleidiAI for ARM optimization" OFF)

# Dependencies and compile options
add_definitions(
    -DNDEBUG
    -DO3
    -DLM_GGML_USE_CPU
    -DLM_GGML_USE_ACCELERATE
    -DLM_GGML_USE_METAL
    -DLM_GGML_METAL_USE_BF16
    # MNN compile definitions
    -DMNN_BUILD_SHARED_LIBS=OFF
    # Don't use Android logcat for iOS builds
    # -DMNN_USE_LOGCAT=false
    -DMNN_METAL
    -DMNN_USE_METAL
    -DLM_MNN_SUPPORT=1
    #-DMNN_KLEIDIAI=${MNN_KLEIDIAI}
    # Ensure C++ types are available
    -D__STDC_LIMIT_MACROS
    -D__STDC_FORMAT_MACROS
    -D__STDC_CONSTANT_MACROS
    # Explicitly disable NEON and SSE by default for all architectures
    -DMNN_USE_NEON=0
    -DMNN_USE_SSE=0
)

# Architecture-specific settings
set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64")

# For fat libraries (arm64 + x86_64), we need to handle NEON carefully
# MNN uses conditional compilation in their source files with #ifdef MNN_USE_NEON
# We'll let the Xcode build system handle this with per-architecture flags

# Set the source directory to the lib/ directory for llama_mobile files
# and lib/llama_cpp for llama.cpp files
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib)
set(LLAMA_CPP_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp)

# Collect MNN source files using GLOB
file(GLOB MNN_CORE_SOURCES "${SOURCE_DIR}/MNN/source/core/*.cpp")
file(GLOB MNN_CV_SOURCES "${SOURCE_DIR}/MNN/source/cv/*.cpp")
file(GLOB MNN_MATH_SOURCES "${SOURCE_DIR}/MNN/source/math/*.cpp")
file(GLOB MNN_UTILS_SOURCES "${SOURCE_DIR}/MNN/source/utils/*.cpp")
file(GLOB MNN_SHAPE_SOURCES "${SOURCE_DIR}/MNN/source/shape/*.cpp")
file(GLOB MNN_GEOMETRY_SOURCES "${SOURCE_DIR}/MNN/source/geometry/*.cpp")
file(GLOB MNN_CPU_SOURCES "${SOURCE_DIR}/MNN/source/backend/cpu/*.cpp" "${SOURCE_DIR}/MNN/source/backend/cpu/*.c")
file(GLOB MNN_CPU_ARM_SOURCES "${SOURCE_DIR}/MNN/source/backend/cpu/arm/*.cpp" "${SOURCE_DIR}/MNN/source/backend/cpu/arm/*.c" "${SOURCE_DIR}/MNN/source/backend/cpu/arm/*.S" "${SOURCE_DIR}/MNN/source/backend/cpu/arm/arm32/*.S" "${SOURCE_DIR}/MNN/source/backend/cpu/arm/arm64/*.S")

# Include x86 and x86_x64 sources for iOS builds since we support both arm64 and x86_64 architectures
file(GLOB MNN_CPU_X86_SOURCES "${SOURCE_DIR}/MNN/source/backend/cpu/x86/*.cpp" "${SOURCE_DIR}/MNN/source/backend/cpu/x86/*.c" "${SOURCE_DIR}/MNN/source/backend/cpu/x86/*.cc")

# Only include specific x86_x64 base files, not the entire directory
set(MNN_CPU_X86_X64_BASE_SOURCES
    "${SOURCE_DIR}/MNN/source/backend/cpu/x86_x64/FunctionDispatcher.cpp"
    "${SOURCE_DIR}/MNN/source/backend/cpu/x86_x64/cpu_id.cc"
)

# Collect compute sources first
file(GLOB MNN_CPU_COMPUTE_SOURCES "${SOURCE_DIR}/MNN/source/backend/cpu/compute/*.cpp")

# Only include base x86_x64 sources (no SSE)
set(MNN_CPU_X86_X64_SOURCES
    ${MNN_CPU_X86_X64_BASE_SOURCES}
)



file(GLOB MNN_EXPRESS_SOURCES "${SOURCE_DIR}/MNN/express/*.cpp")
file(GLOB MNN_EXPRESS_MODULE_SOURCES "${SOURCE_DIR}/MNN/express/module/*.cpp")
file(GLOB_RECURSE MNN_LLM_SOURCES "${SOURCE_DIR}/MNN/transformers/llm/engine/src/*.cpp")

# Keep all compute files since we're not using SSE optimized versions

# Exclude KleidiAI files from ARM sources (they will be added separately if enabled)
list(FILTER MNN_CPU_ARM_SOURCES EXCLUDE REGEX "mnn_kleidiai\.(cpp|c)$|mnn_kleidiai_util\.(cpp|c)$")

# Add KleidiAI source files if enabled
# if(MNN_KLEIDIAI)
#     message(STATUS "Including KleidiAI source files for iOS")
#     list(APPEND MNN_CPU_ARM_SOURCES "${SOURCE_DIR}/MNN/source/backend/cpu/arm/mnn_kleidiai.cpp" "${SOURCE_DIR}/MNN/source/backend/cpu/arm/mnn_kleidiai_util.cpp")
# endif()

# Define public headers - expose all necessary API headers
set(PUBLIC_HEADERS
    ${SOURCE_DIR}/llama_mobile_unified.h
    ${SOURCE_DIR}/llama_mobile_ffi.h
    ${SOURCE_DIR}/llama_mobile_api.h
    ${SOURCE_DIR}/llama_mobile_mnn.h
)

# Create library target
add_library(llama_mobile SHARED
    ${SOURCE_DIR}/llama_mobile_context.cpp
    ${SOURCE_DIR}/llama_mobile_loader.cpp
    ${SOURCE_DIR}/llama_mobile_completion.cpp
    ${SOURCE_DIR}/llama_mobile_utils.cpp
    ${SOURCE_DIR}/llama_mobile_embedding.cpp
    ${SOURCE_DIR}/llama_mobile_lora.cpp
    ${SOURCE_DIR}/llama_mobile_tokenization.cpp
    ${SOURCE_DIR}/llama_mobile_multimodal.cpp
    ${SOURCE_DIR}/llama_mobile_tts.cpp
    ${SOURCE_DIR}/llama_mobile_bench.cpp
    ${SOURCE_DIR}/llama_mobile_chat.cpp
    ${SOURCE_DIR}/llama_mobile_ffi.cpp
    ${SOURCE_DIR}/llama_mobile_api.cpp
    ${SOURCE_DIR}/llama_mobile_mnn.cpp
    ${LLAMA_CPP_DIR}/llama.cpp
    ${LLAMA_CPP_DIR}/llama-mmap.cpp
    ${LLAMA_CPP_DIR}/llama-memory.cpp
    ${LLAMA_CPP_DIR}/llama-memory-hybrid.cpp
    ${LLAMA_CPP_DIR}/llama-memory-recurrent.cpp
    ${LLAMA_CPP_DIR}/llama-io.cpp
    ${LLAMA_CPP_DIR}/llama-cparams.cpp
    ${LLAMA_CPP_DIR}/llama-hparams.cpp
    ${LLAMA_CPP_DIR}/llama-model.cpp
    ${LLAMA_CPP_DIR}/llama-model-loader.cpp
    ${LLAMA_CPP_DIR}/llama-model-saver.cpp
    ${LLAMA_CPP_DIR}/llama-kv-cache.cpp
    ${LLAMA_CPP_DIR}/llama-kv-cache-iswa.cpp
    ${LLAMA_CPP_DIR}/llama-context.cpp
    ${LLAMA_CPP_DIR}/llama-chat.cpp
    ${LLAMA_CPP_DIR}/llama-batch.cpp
    ${LLAMA_CPP_DIR}/llama-arch.cpp
    ${LLAMA_CPP_DIR}/llama-adapter.cpp
    ${LLAMA_CPP_DIR}/llama-sampling.cpp
    ${LLAMA_CPP_DIR}/llama-grammar.cpp
    ${LLAMA_CPP_DIR}/llama-vocab.cpp
    ${LLAMA_CPP_DIR}/llama-impl.cpp
    ${LLAMA_CPP_DIR}/llama-graph.cpp
    ${LLAMA_CPP_DIR}/ggml.c
    ${LLAMA_CPP_DIR}/ggml-alloc.c
    ${LLAMA_CPP_DIR}/ggml-backend.cpp
    ${LLAMA_CPP_DIR}/ggml-quants.c
    ${LLAMA_CPP_DIR}/ggml-opt.cpp
    ${LLAMA_CPP_DIR}/ggml-threading.cpp
    ${LLAMA_CPP_DIR}/ggml-backend-reg.cpp
    ${LLAMA_CPP_DIR}/gguf.cpp
    ${LLAMA_CPP_DIR}/common.cpp
    ${LLAMA_CPP_DIR}/chat.cpp
    ${LLAMA_CPP_DIR}/log.cpp
    ${LLAMA_CPP_DIR}/sampling.cpp
    ${LLAMA_CPP_DIR}/peg-parser.cpp
    ${LLAMA_CPP_DIR}/json-schema-to-grammar.cpp
    ${LLAMA_CPP_DIR}/chat-parser.cpp
    ${LLAMA_CPP_DIR}/chat-parser-xml-toolcall.cpp
    ${LLAMA_CPP_DIR}/chat-peg-parser.cpp
    ${LLAMA_CPP_DIR}/regex-partial.cpp
    ${LLAMA_CPP_DIR}/json-partial.cpp
    ${LLAMA_CPP_DIR}/version.cpp
    ${LLAMA_CPP_DIR}/models/pangu-embedded.cpp
    ${LLAMA_CPP_DIR}/models/openai-moe-iswa.cpp
    ${LLAMA_CPP_DIR}/models/gemma-embedding.cpp
    ${LLAMA_CPP_DIR}/models/wavtokenizer-dec.cpp
    ${LLAMA_CPP_DIR}/models/afmoe.cpp
    ${LLAMA_CPP_DIR}/models/apertus.cpp
    ${LLAMA_CPP_DIR}/models/arcee.cpp
    ${LLAMA_CPP_DIR}/models/arctic.cpp
    ${LLAMA_CPP_DIR}/models/arwkv7.cpp
    ${LLAMA_CPP_DIR}/models/baichuan.cpp
    ${LLAMA_CPP_DIR}/models/bailingmoe.cpp
    ${LLAMA_CPP_DIR}/models/bailingmoe2.cpp
    ${LLAMA_CPP_DIR}/models/bert.cpp
    ${LLAMA_CPP_DIR}/models/bitnet.cpp
    ${LLAMA_CPP_DIR}/models/bloom.cpp
    ${LLAMA_CPP_DIR}/models/chameleon.cpp
    ${LLAMA_CPP_DIR}/models/chatglm.cpp
    ${LLAMA_CPP_DIR}/models/codeshell.cpp
    ${LLAMA_CPP_DIR}/models/cogvlm.cpp
    ${LLAMA_CPP_DIR}/models/cohere2-iswa.cpp
    ${LLAMA_CPP_DIR}/models/command-r.cpp
    ${LLAMA_CPP_DIR}/models/dbrx.cpp
    ${LLAMA_CPP_DIR}/models/deci.cpp
    ${LLAMA_CPP_DIR}/models/deepseek.cpp
    ${LLAMA_CPP_DIR}/models/deepseek2.cpp
    ${LLAMA_CPP_DIR}/models/dots1.cpp
    ${LLAMA_CPP_DIR}/models/dream.cpp
    ${LLAMA_CPP_DIR}/models/ernie4-5-moe.cpp
    ${LLAMA_CPP_DIR}/models/ernie4-5.cpp
    ${LLAMA_CPP_DIR}/models/exaone.cpp
    ${LLAMA_CPP_DIR}/models/exaone4.cpp
    ${LLAMA_CPP_DIR}/models/falcon-h1.cpp
    ${LLAMA_CPP_DIR}/models/falcon.cpp
    ${LLAMA_CPP_DIR}/models/gemma.cpp
    ${LLAMA_CPP_DIR}/models/gemma2-iswa.cpp
    ${LLAMA_CPP_DIR}/models/gemma3.cpp
    ${LLAMA_CPP_DIR}/models/gemma3n-iswa.cpp
    ${LLAMA_CPP_DIR}/models/glm4-moe.cpp
    ${LLAMA_CPP_DIR}/models/glm4.cpp
    ${LLAMA_CPP_DIR}/models/gpt2.cpp
    ${LLAMA_CPP_DIR}/models/gptneox.cpp
    ${LLAMA_CPP_DIR}/models/granite-hybrid.cpp
    ${LLAMA_CPP_DIR}/models/granite.cpp
    ${LLAMA_CPP_DIR}/models/graph-context-mamba.cpp
    ${LLAMA_CPP_DIR}/models/grok.cpp
    ${LLAMA_CPP_DIR}/models/grovemoe.cpp
    ${LLAMA_CPP_DIR}/models/hunyuan-dense.cpp
    ${LLAMA_CPP_DIR}/models/hunyuan-moe.cpp
    ${LLAMA_CPP_DIR}/models/internlm2.cpp
    ${LLAMA_CPP_DIR}/models/jais.cpp
    ${LLAMA_CPP_DIR}/models/jamba.cpp
    ${LLAMA_CPP_DIR}/models/lfm2.cpp
    ${LLAMA_CPP_DIR}/models/llada-moe.cpp
    ${LLAMA_CPP_DIR}/models/llada.cpp
    ${LLAMA_CPP_DIR}/models/llama-iswa.cpp
    ${LLAMA_CPP_DIR}/models/llama.cpp
    ${LLAMA_CPP_DIR}/models/mamba.cpp
    ${LLAMA_CPP_DIR}/models/minicpm3.cpp
    ${LLAMA_CPP_DIR}/models/minimax-m2.cpp
    ${LLAMA_CPP_DIR}/models/mistral3.cpp
    ${LLAMA_CPP_DIR}/models/modern-bert.cpp
    ${LLAMA_CPP_DIR}/models/mpt.cpp
    ${LLAMA_CPP_DIR}/models/nemotron-h.cpp
    ${LLAMA_CPP_DIR}/models/nemotron.cpp
    ${LLAMA_CPP_DIR}/models/neo-bert.cpp
    ${LLAMA_CPP_DIR}/models/olmo.cpp
    ${LLAMA_CPP_DIR}/models/olmo2.cpp
    ${LLAMA_CPP_DIR}/models/olmoe.cpp
    ${LLAMA_CPP_DIR}/models/openelm.cpp
    ${LLAMA_CPP_DIR}/models/orion.cpp
    ${LLAMA_CPP_DIR}/models/phi2.cpp
    ${LLAMA_CPP_DIR}/models/phi3.cpp
    ${LLAMA_CPP_DIR}/models/plamo.cpp
    ${LLAMA_CPP_DIR}/models/plamo2.cpp
    ${LLAMA_CPP_DIR}/models/plm.cpp
    ${LLAMA_CPP_DIR}/models/qwen.cpp
    ${LLAMA_CPP_DIR}/models/qwen2.cpp
    ${LLAMA_CPP_DIR}/models/qwen2moe.cpp
    ${LLAMA_CPP_DIR}/models/qwen2vl.cpp
    ${LLAMA_CPP_DIR}/models/qwen3.cpp
    ${LLAMA_CPP_DIR}/models/qwen3moe.cpp
    ${LLAMA_CPP_DIR}/models/qwen3next.cpp
    ${LLAMA_CPP_DIR}/models/qwen3vl-moe.cpp
    ${LLAMA_CPP_DIR}/models/qwen3vl.cpp
    ${LLAMA_CPP_DIR}/models/refact.cpp
    ${LLAMA_CPP_DIR}/models/rnd1.cpp
    ${LLAMA_CPP_DIR}/models/rwkv6-base.cpp
    ${LLAMA_CPP_DIR}/models/rwkv6.cpp
    ${LLAMA_CPP_DIR}/models/rwkv6qwen2.cpp
    ${LLAMA_CPP_DIR}/models/rwkv7-base.cpp
    ${LLAMA_CPP_DIR}/models/rwkv7.cpp
    ${LLAMA_CPP_DIR}/models/seed-oss.cpp
    ${LLAMA_CPP_DIR}/models/smallthinker.cpp
    ${LLAMA_CPP_DIR}/models/smollm3.cpp
    ${LLAMA_CPP_DIR}/models/stablelm.cpp
    ${LLAMA_CPP_DIR}/models/starcoder.cpp
    ${LLAMA_CPP_DIR}/models/starcoder2.cpp
    ${LLAMA_CPP_DIR}/models/t5-dec.cpp
    ${LLAMA_CPP_DIR}/models/t5-enc.cpp
    ${LLAMA_CPP_DIR}/models/xverse.cpp
    ${LLAMA_CPP_DIR}/unicode.cpp
    ${LLAMA_CPP_DIR}/unicode-data.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu.c
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-quants.c
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-traits.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/unary-ops.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/binary-ops.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/sgemm.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/vec.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ops.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-aarch64-feats.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-aarch64-quants.c
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-aarch64-repack.cpp
    ${LLAMA_CPP_DIR}/ggml-cpu/ggml-cpu-generic-repack.cpp
    ${LLAMA_CPP_DIR}/ggml-metal.m
    ${LLAMA_CPP_DIR}/ggml-metal-context.m
    ${LLAMA_CPP_DIR}/ggml-metal-device.m
    ${LLAMA_CPP_DIR}/ggml-metal-device.cpp
    ${LLAMA_CPP_DIR}/ggml-metal-ops.cpp
    ${LLAMA_CPP_DIR}/ggml-metal-common.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-helper.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-audio.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/clip.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/cogvlm.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/conformer.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/glm4v.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/internvl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/kimivl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/llama4.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/llava.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/minicpmv.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/pixtral.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/qwen2vl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/qwen3vl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/siglip.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/whisper-enc.cpp

    # MNN source files - collected using file(GLOB) above
    ${MNN_CORE_SOURCES}
    ${MNN_CV_SOURCES}
    ${MNN_MATH_SOURCES}
    ${MNN_UTILS_SOURCES}
    ${MNN_SHAPE_SOURCES}
    ${MNN_GEOMETRY_SOURCES}
    ${MNN_CPU_SOURCES}
    ${MNN_CPU_X86_SOURCES}
    ${MNN_CPU_X86_X64_SOURCES}
    ${MNN_EXPRESS_SOURCES}
    ${MNN_EXPRESS_MODULE_SOURCES}
    ${MNN_CPU_COMPUTE_SOURCES}
    ${MNN_LLM_SOURCES}

    # Only include ARM sources for ARM64 architectures
    ${MNN_CPU_ARM_SOURCES}

    # MNN Metal backend sources for Apple platforms
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalBackend.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalUnary.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalRaster.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalScale.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalSoftmax.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalReduction.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalReLU6.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalPReLU.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalROIPooling.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalMatMul.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalPooling.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalLoop.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalOPRegister.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalLayerNorm.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalFuse.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalInterp.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalGridSample.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalDeconvolution.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalExecution.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalEltwise.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalKVCacheManager.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalConvolutionWinograd.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalConvolutionCommon.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalConvolutionDepthwise.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalConvolution.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalConvolution1x1.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalCast.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalBinary.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalAttention.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/MetalArgMax.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/AllShader.cpp
    ${SOURCE_DIR}/MNN/source/backend/metal/ShaderMap.cpp
    ${SOURCE_DIR}/MNN/source/backend/metal/MNNMetalContext.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/render/MetalRenderOpRegister.mm
    ${SOURCE_DIR}/MNN/source/backend/metal/render/MetalRasterAndInterpolate.mm
)

# Add LM_GGML_VERSION and LM_GGML_COMMIT specifically to the target
target_compile_definitions(llama_mobile PRIVATE
    -DLM_GGML_VERSION="0.0.0"
    -DLM_GGML_COMMIT="unknown"
)

# Setup include directories, use both lib/ and lib/llama_cpp directories
target_include_directories(llama_mobile
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/ggml-cpu>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/tools/mtmd>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/source>

        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/express>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/tools/cpp>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/schema/current>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/transformers/llm/engine/include>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/3rd_party>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/3rd_party/half>
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/../lib/MNN/3rd_party/flatbuffers/include>
        $<INSTALL_INTERFACE:include>
)

# Link required frameworks
target_link_libraries(llama_mobile PRIVATE
    "-framework Accelerate"
    "-framework Foundation"
    "-framework Metal"
    "-framework MetalKit"
)

# Set C++17 standard for all C++ files including .cc files
target_compile_options(llama_mobile PRIVATE
    $<$<COMPILE_LANGUAGE:CXX>:-std=c++17>
)

# Explicitly set C++17 for .cc files
source_group("Source Files\\cc" FILES ${MNN_CPU_X86_X64_SOURCES} ${MNN_CPU_X86_SOURCES})
set_source_files_properties(${MNN_CPU_X86_X64_SOURCES} ${MNN_CPU_X86_SOURCES} PROPERTIES
    COMPILE_LANGUAGE CXX
    COMPILE_FLAGS "-std=c++17"
)





# Set properties for framework
set_target_properties(llama_mobile PROPERTIES
    MACOSX_FRAMEWORK_IDENTIFIER "com.llamamobile"
    MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.0
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0.0
    MACOSX_FRAMEWORK_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
    FRAMEWORK TRUE
    FRAMEWORK_VERSION 1.0.0
    VERSION 1.0.0
    PUBLIC_HEADER "${PUBLIC_HEADERS}"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC NO
    XCODE_ATTRIBUTE_DEFINE_MODULE YES
    XCODE_ATTRIBUTE_MACH_O_TYPE mh_dylib
)

# Add Xcode-specific settings (no SSE exclusion needed anymore)
if(APPLE AND CMAKE_GENERATOR STREQUAL "Xcode")
    
    # No SSE files to exclude anymore since we're using compute sources for all architectures
    
    # No need to exclude compute files from x86_64 builds anymore
    set(COMPUTE_X86_64_EXCLUDE "")
    foreach(COMPUTE_FILE ${MNN_CPU_COMPUTE_SOURCES})
        if(COMPUTE_FILE MATCHES ".*/CommonOptFunction\.cpp$" OR 
           COMPUTE_FILE MATCHES ".*/ImageProcessFunction\.cpp$" OR 
           COMPUTE_FILE MATCHES ".*/Int8FunctionsOpt\.cpp$")
            file(RELATIVE_PATH REL_FILE ${CMAKE_CURRENT_SOURCE_DIR} ${COMPUTE_FILE})
            set(COMPUTE_X86_64_EXCLUDE "${COMPUTE_X86_64_EXCLUDE}${REL_FILE} ")
        endif()
    endforeach()
    
    # No need to exclude any files anymore - all compute sources are used for all architectures
endif()

# Custom command to ensure headers are copied to the framework
add_custom_command(
    TARGET llama_mobile POST_BUILD
    COMMAND mkdir -p "$<TARGET_FILE_DIR:llama_mobile>/Headers"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${PUBLIC_HEADERS} "$<TARGET_FILE_DIR:llama_mobile>/Headers/"
    # Copy metallib files
    COMMAND cp -f "${CMAKE_CURRENT_SOURCE_DIR}/../lib/llama_cpp/ggml-llama-sim.metallib" "$<TARGET_FILE_DIR:llama_mobile>/"
    COMMENT "Copying public headers and metallib to framework"
)
