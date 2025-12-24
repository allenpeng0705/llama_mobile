#!/bin/bash

# Get the script's directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Using latest master branch for compatibility
LLAMA_CPP_DIR="$PROJECT_ROOT/llama.cpp"
BACKUP_DIR="$PROJECT_ROOT/lib/llama_cpp_backup_$(date +%Y%m%d_%H%M%S)"

# Function to clean up backup
# cleanup_backup() {
#     if [ -d "$BACKUP_DIR" ]; then
#         rm -rf "$BACKUP_DIR"
#         echo "Backup directory removed: $BACKUP_DIR"
#     fi
# }

# Set script to exit on error but don't remove backup on failure
set -e

# Define trap handler function first
trap_handler() {
    if [ $? -ne 0 ]; then
        echo "PATCH FAILED: Backup directory preserved for manual restore: $BACKUP_DIR"
    fi
}

# Use a trap function that will check the actual exit code when triggered
trap 'trap_handler' EXIT

# Backup existing lib/llama_cpp if it exists
if [ -d "$PROJECT_ROOT/lib/llama_cpp" ]; then
    echo "Creating backup of lib/llama_cpp to $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$PROJECT_ROOT/lib/llama_cpp"/* "$BACKUP_DIR" 2>/dev/null || true
fi

# Clean up lib/llama_cpp directory except the patches folder
if [ -d "$PROJECT_ROOT/lib/llama_cpp" ]; then
    echo "Cleaning up lib/llama_cpp directory except patches folder..."
    # Remove all files/directories except patches (explicitly exclude . and the parent directory)
    find "$PROJECT_ROOT/lib/llama_cpp" -maxdepth 1 -mindepth 1 -name "*" ! -name "patches" ! -name "minja" -exec rm -rf {} +
fi

# Ensure lib/llama_cpp directory and subdirectories exist
mkdir -p "$PROJECT_ROOT/lib/llama_cpp"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/models"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/miniaudio"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/minja"
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/nlohmann"

rm -rf "$LLAMA_CPP_DIR"

git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$LLAMA_CPP_DIR"

cp "$LLAMA_CPP_DIR/include/llama.h" "$PROJECT_ROOT/lib/llama_cpp/llama.h"
cp "$LLAMA_CPP_DIR/include/llama-cpp.h" "$PROJECT_ROOT/lib/llama_cpp/llama-cpp.h"

cp "$LLAMA_CPP_DIR/ggml/include/ggml.h" "$PROJECT_ROOT/lib/llama_cpp/ggml.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-alloc.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-alloc.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-backend.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-backend.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-cpu.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-cpp.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpp.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-opt.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-opt.h"
cp "$LLAMA_CPP_DIR/ggml/include/ggml-metal.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.h"
cp "$LLAMA_CPP_DIR/ggml/include/gguf.h" "$PROJECT_ROOT/lib/llama_cpp/gguf.h"

# Copy all Metal-related files
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-device.m" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.m"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-device.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-device.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-context.m" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-context.m"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-context.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-context.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-common.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-common.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-common.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-common.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-ops.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-ops.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-ops.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-ops.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal-impl.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-impl.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal.metal" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.metal"

# Keep the original ggml-metal.m name for backward compatibility
cp "$LLAMA_CPP_DIR/ggml/src/ggml-metal/ggml-metal.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.m"

cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/ggml-cpu.c" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu.c"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/ggml-cpu.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/ggml-cpu-impl.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-impl.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/common.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/common.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch-fallback.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/arch-fallback.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/quants.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/quants.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/quants.c" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-quants.c"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/traits.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/traits.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/traits.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-traits.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/repack.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/repack.h"

# Copy ARM/AArch64 files if they exist
ARM_ARCH_DIR="$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch/arm"
if [ -d "$ARM_ARCH_DIR" ]; then
    # Copy all ARM arch files
    if [ -f "$ARM_ARCH_DIR/quants.c" ]; then
        cp "$ARM_ARCH_DIR/quants.c" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-quants.c"
    fi
    if [ -f "$ARM_ARCH_DIR/cpu-feats.cpp" ]; then
        cp "$ARM_ARCH_DIR/cpu-feats.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-feats.cpp"
    fi
    if [ -f "$ARM_ARCH_DIR/repack.cpp" ]; then
        cp "$ARM_ARCH_DIR/repack.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-repack.cpp"
    fi
else
    # Fallback to old structure if arm directory doesn't exist
    # Try old aarch64 directory structure
    if [ -f "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch/aarch64.h" ]; then
        cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch/aarch64.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.h"
    fi
    if [ -f "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch/aarch64.cpp" ]; then
        cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/arch/aarch64.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.cpp"
    elif [ -f "$LLAMA_CPP_DIR/ggml/src/ggml-cpu-aarch64.h" ]; then
        cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu-aarch64.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.h"
    elif [ -f "$LLAMA_CPP_DIR/ggml/src/ggml-cpu-aarch64.cpp" ]; then
        cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu-aarch64.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.cpp"
    fi
fi

cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/unary-ops.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/unary-ops.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/unary-ops.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/unary-ops.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/binary-ops.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/binary-ops.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/binary-ops.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/binary-ops.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/vec.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/vec.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/vec.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/vec.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/simd-mappings.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/simd-mappings.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/ops.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ops.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/ops.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ops.cpp"

cp -r "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/amx" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/"

cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/llamafile/sgemm.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/sgemm.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-cpu/llamafile/sgemm.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/sgemm.cpp"

cp "$LLAMA_CPP_DIR/ggml/src/ggml.c" "$PROJECT_ROOT/lib/llama_cpp/ggml.c"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-impl.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-impl.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-alloc.c" "$PROJECT_ROOT/lib/llama_cpp/ggml-alloc.c"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-backend.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-backend.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-backend-impl.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-backend-impl.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-backend-reg.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-backend-reg.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-common.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-common.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-opt.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-opt.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-quants.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.h"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-quants.c" "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.c"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-threading.cpp" "$PROJECT_ROOT/lib/llama_cpp/ggml-threading.cpp"
cp "$LLAMA_CPP_DIR/ggml/src/ggml-threading.h" "$PROJECT_ROOT/lib/llama_cpp/ggml-threading.h"
cp "$LLAMA_CPP_DIR/ggml/src/gguf.cpp" "$PROJECT_ROOT/lib/llama_cpp/gguf.cpp"

cp "$LLAMA_CPP_DIR/src/llama.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama.cpp"
cp "$LLAMA_CPP_DIR/src/llama-chat.h" "$PROJECT_ROOT/lib/llama_cpp/llama-chat.h"
cp "$LLAMA_CPP_DIR/src/llama-chat.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-chat.cpp"
cp "$LLAMA_CPP_DIR/src/llama-context.h" "$PROJECT_ROOT/lib/llama_cpp/llama-context.h"
cp "$LLAMA_CPP_DIR/src/llama-context.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-context.cpp"
cp "$LLAMA_CPP_DIR/src/llama-mmap.h" "$PROJECT_ROOT/lib/llama_cpp/llama-mmap.h"
cp "$LLAMA_CPP_DIR/src/llama-mmap.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-mmap.cpp"
cp "$LLAMA_CPP_DIR/src/llama-kv-cache.h" "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache.h"
cp "$LLAMA_CPP_DIR/src/llama-kv-cache.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache.cpp"
cp "$LLAMA_CPP_DIR/src/llama-kv-cache-iswa.h" "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache-iswa.h"
cp "$LLAMA_CPP_DIR/src/llama-kv-cells.h" "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cells.h"
cp "$LLAMA_CPP_DIR/src/llama-model-loader.h" "$PROJECT_ROOT/lib/llama_cpp/llama-model-loader.h"
cp "$LLAMA_CPP_DIR/src/llama-model-loader.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-model-loader.cpp"
cp "$LLAMA_CPP_DIR/src/llama-model-saver.h" "$PROJECT_ROOT/lib/llama_cpp/llama-model-saver.h"
cp "$LLAMA_CPP_DIR/src/llama-model-saver.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-model-saver.cpp"
cp "$LLAMA_CPP_DIR/src/llama-model.h" "$PROJECT_ROOT/lib/llama_cpp/llama-model.h"
cp "$LLAMA_CPP_DIR/src/llama-model.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-model.cpp"
cp "$LLAMA_CPP_DIR/src/llama-adapter.h" "$PROJECT_ROOT/lib/llama_cpp/llama-adapter.h"
cp "$LLAMA_CPP_DIR/src/llama-adapter.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-adapter.cpp"
cp "$LLAMA_CPP_DIR/src/llama-arch.h" "$PROJECT_ROOT/lib/llama_cpp/llama-arch.h"
cp "$LLAMA_CPP_DIR/src/llama-arch.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-arch.cpp"
cp "$LLAMA_CPP_DIR/src/llama-batch.h" "$PROJECT_ROOT/lib/llama_cpp/llama-batch.h"
cp "$LLAMA_CPP_DIR/src/llama-batch.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-batch.cpp"
cp "$LLAMA_CPP_DIR/src/llama-cparams.h" "$PROJECT_ROOT/lib/llama_cpp/llama-cparams.h"
cp "$LLAMA_CPP_DIR/src/llama-cparams.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-cparams.cpp"
cp "$LLAMA_CPP_DIR/src/llama-hparams.h" "$PROJECT_ROOT/lib/llama_cpp/llama-hparams.h"
cp "$LLAMA_CPP_DIR/src/llama-hparams.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-hparams.cpp"
cp "$LLAMA_CPP_DIR/src/llama-impl.h" "$PROJECT_ROOT/lib/llama_cpp/llama-impl.h"
cp "$LLAMA_CPP_DIR/src/llama-impl.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-impl.cpp"


cp "$LLAMA_CPP_DIR/src/llama-vocab.h" "$PROJECT_ROOT/lib/llama_cpp/llama-vocab.h"
cp "$LLAMA_CPP_DIR/src/llama-vocab.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-vocab.cpp"
cp "$LLAMA_CPP_DIR/src/llama-grammar.h" "$PROJECT_ROOT/lib/llama_cpp/llama-grammar.h"
cp "$LLAMA_CPP_DIR/src/llama-grammar.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-grammar.cpp"
cp "$LLAMA_CPP_DIR/src/llama-sampling.h" "$PROJECT_ROOT/lib/llama_cpp/llama-sampling.h"
cp "$LLAMA_CPP_DIR/src/llama-sampling.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-sampling.cpp"

cp "$LLAMA_CPP_DIR/src/unicode.h" "$PROJECT_ROOT/lib/llama_cpp/unicode.h"
cp "$LLAMA_CPP_DIR/src/unicode.cpp" "$PROJECT_ROOT/lib/llama_cpp/unicode.cpp"
cp "$LLAMA_CPP_DIR/src/unicode-data.h" "$PROJECT_ROOT/lib/llama_cpp/unicode-data.h"
cp "$LLAMA_CPP_DIR/src/unicode-data.cpp" "$PROJECT_ROOT/lib/llama_cpp/unicode-data.cpp"

cp "$LLAMA_CPP_DIR/src/llama-graph.h" "$PROJECT_ROOT/lib/llama_cpp/llama-graph.h"
cp "$LLAMA_CPP_DIR/src/llama-graph.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-graph.cpp"
cp "$LLAMA_CPP_DIR/src/llama-io.h" "$PROJECT_ROOT/lib/llama_cpp/llama-io.h"
cp "$LLAMA_CPP_DIR/src/llama-io.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-io.cpp"
cp "$LLAMA_CPP_DIR/src/llama-memory.h" "$PROJECT_ROOT/lib/llama_cpp/llama-memory.h"
cp "$LLAMA_CPP_DIR/src/llama-memory.cpp" "$PROJECT_ROOT/lib/llama_cpp/llama-memory.cpp"
cp "$LLAMA_CPP_DIR/src/llama-memory-hybrid.h" "$PROJECT_ROOT/lib/llama_cpp/llama-memory-hybrid.h"
cp "$LLAMA_CPP_DIR/src/llama-memory-recurrent.h" "$PROJECT_ROOT/lib/llama_cpp/llama-memory-recurrent.h"


cp "$LLAMA_CPP_DIR/common/log.h" "$PROJECT_ROOT/lib/llama_cpp/log.h"
cp "$LLAMA_CPP_DIR/common/log.cpp" "$PROJECT_ROOT/lib/llama_cpp/log.cpp"
cp "$LLAMA_CPP_DIR/common/common.h" "$PROJECT_ROOT/lib/llama_cpp/common.h"
cp "$LLAMA_CPP_DIR/common/common.cpp" "$PROJECT_ROOT/lib/llama_cpp/common.cpp"
cp "$LLAMA_CPP_DIR/common/sampling.h" "$PROJECT_ROOT/lib/llama_cpp/sampling.h"
cp "$LLAMA_CPP_DIR/common/sampling.cpp" "$PROJECT_ROOT/lib/llama_cpp/sampling.cpp"
cp "$LLAMA_CPP_DIR/common/json-schema-to-grammar.h" "$PROJECT_ROOT/lib/llama_cpp/json-schema-to-grammar.h"
cp "$LLAMA_CPP_DIR/common/json-schema-to-grammar.cpp" "$PROJECT_ROOT/lib/llama_cpp/json-schema-to-grammar.cpp"

# Copy json.hpp if it exists in common directory, otherwise look in ggml directory
# if [ -f ./llama.cpp/common/json.hpp ]; then
#     cp ./llama.cpp/common/json.hpp ./lib/llama_cpp/json.hpp
# elif [ -f ./llama.cpp/ggml/include/json.hpp ]; then
#     cp ./llama.cpp/ggml/include/json.hpp ./lib/llama_cpp/json.hpp
# elif [ -f ./llama.cpp/ggml/src/json.hpp ]; then
#     cp ./llama.cpp/ggml/src/json.hpp ./lib/llama_cpp/json.hpp
# fi

# Copy chat files
cp "$LLAMA_CPP_DIR/common/chat.h" "$PROJECT_ROOT/lib/llama_cpp/chat.h"
cp "$LLAMA_CPP_DIR/common/chat.cpp" "$PROJECT_ROOT/lib/llama_cpp/chat.cpp"
# Copy chat-peg-parser files if they exist
cp "$LLAMA_CPP_DIR/common/base64.hpp" "$PROJECT_ROOT/lib/llama_cpp/base64.hpp"
cp "$LLAMA_CPP_DIR/common/arg.h" "$PROJECT_ROOT/lib/llama_cpp/arg.h"
cp "$LLAMA_CPP_DIR/common/arg.cpp" "$PROJECT_ROOT/lib/llama_cpp/arg.cpp"
cp "$LLAMA_CPP_DIR/common/http.h" "$PROJECT_ROOT/lib/llama_cpp/http.h"
cp "$LLAMA_CPP_DIR/common/download.h" "$PROJECT_ROOT/lib/llama_cpp/download.h"
cp "$LLAMA_CPP_DIR/common/download.cpp" "$PROJECT_ROOT/lib/llama_cpp/download.cpp"
cp "$LLAMA_CPP_DIR/common/chat-peg-parser.h" "$PROJECT_ROOT/lib/llama_cpp/chat-peg-parser.h"
cp "$LLAMA_CPP_DIR/common/chat-peg-parser.cpp" "$PROJECT_ROOT/lib/llama_cpp/chat-peg-parser.cpp"
cp "$LLAMA_CPP_DIR/common/chat-parser.h" "$PROJECT_ROOT/lib/llama_cpp/chat-parser.h"
cp "$LLAMA_CPP_DIR/common/chat-parser.cpp" "$PROJECT_ROOT/lib/llama_cpp/chat-parser.cpp"
cp "$LLAMA_CPP_DIR/common/chat-parser-xml-toolcall.h" "$PROJECT_ROOT/lib/llama_cpp/chat-parser-xml-toolcall.h"
cp "$LLAMA_CPP_DIR/common/chat-parser-xml-toolcall.cpp" "$PROJECT_ROOT/lib/llama_cpp/chat-parser-xml-toolcall.cpp"
cp "$LLAMA_CPP_DIR/common/console.h" "$PROJECT_ROOT/lib/llama_cpp/console.h"
cp "$LLAMA_CPP_DIR/common/console.cpp" "$PROJECT_ROOT/lib/llama_cpp/console.cpp"
cp "$LLAMA_CPP_DIR/common/json-partial.h" "$PROJECT_ROOT/lib/llama_cpp/json-partial.h"
cp "$LLAMA_CPP_DIR/common/json-partial.cpp" "$PROJECT_ROOT/lib/llama_cpp/json-partial.cpp"
cp "$LLAMA_CPP_DIR/common/llguidance.cpp" "$PROJECT_ROOT/lib/llama_cpp/llguidance.cpp"
cp "$LLAMA_CPP_DIR/common/ngram-cache.h" "$PROJECT_ROOT/lib/llama_cpp/ngram-cache.h"
cp "$LLAMA_CPP_DIR/common/ngram-cache.cpp" "$PROJECT_ROOT/lib/llama_cpp/ngram-cache.cpp"
cp "$LLAMA_CPP_DIR/common/preset.h" "$PROJECT_ROOT/lib/llama_cpp/preset.h"
cp "$LLAMA_CPP_DIR/common/preset.cpp" "$PROJECT_ROOT/lib/llama_cpp/preset.cpp"
cp "$LLAMA_CPP_DIR/common/regex-partial.h" "$PROJECT_ROOT/lib/llama_cpp/regex-partial.h"
cp "$LLAMA_CPP_DIR/common/regex-partial.cpp" "$PROJECT_ROOT/lib/llama_cpp/regex-partial.cpp"
cp "$LLAMA_CPP_DIR/common/speculative.h" "$PROJECT_ROOT/lib/llama_cpp/speculative.h"
cp "$LLAMA_CPP_DIR/common/speculative.cpp" "$PROJECT_ROOT/lib/llama_cpp/speculative.cpp"
# Don't overwrite src/unicode.h with common/unicode.h - src version has full Unicode functionality
# cp ./llama.cpp/common/unicode.h ./lib/llama_cpp/unicode.h
# cp ./llama.cpp/common/unicode.cpp ./lib/llama_cpp/unicode.cpp

# Copy peg parser files if they exist
if [ -f "$LLAMA_CPP_DIR/common/peg-parser.h" ]; then
    cp "$LLAMA_CPP_DIR/common/peg-parser.h" "$PROJECT_ROOT/lib/llama_cpp/peg-parser.h"
fi
if [ -f "$LLAMA_CPP_DIR/common/peg-parser.cpp" ]; then
    cp "$LLAMA_CPP_DIR/common/peg-parser.cpp" "$PROJECT_ROOT/lib/llama_cpp/peg-parser.cpp"
fi

# Copy minja files if they exist
if [ -f "$LLAMA_CPP_DIR/vendor/minja/minja.hpp" ]; then
    cp "$LLAMA_CPP_DIR/vendor/minja/minja.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/minja.hpp"
    cp "$LLAMA_CPP_DIR/vendor/minja/chat-template.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/chat-template.hpp"
elif [ -f "$LLAMA_CPP_DIR/common/minja/minja.hpp" ]; then
    cp "$LLAMA_CPP_DIR/common/minja/minja.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/minja.hpp"
    cp "$LLAMA_CPP_DIR/common/minja/chat-template.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/chat-template.hpp"
else
    # If minja doesn't exist in vendor or common, try other locations
    if [ -f "$LLAMA_CPP_DIR/examples/minja/minja.hpp" ]; then
        cp "$LLAMA_CPP_DIR/examples/minja/minja.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/minja.hpp"
        cp "$LLAMA_CPP_DIR/examples/minja/chat-template.hpp" "$PROJECT_ROOT/lib/llama_cpp/minja/chat-template.hpp"
    fi
fi
cp "$LLAMA_CPP_DIR/vendor/nlohmann/json.hpp" "$PROJECT_ROOT/lib/llama_cpp/nlohmann/json.hpp"
cp "$LLAMA_CPP_DIR/vendor/nlohmann/json_fwd.hpp" "$PROJECT_ROOT/lib/llama_cpp/nlohmann/json_fwd.hpp"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd.cpp" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd.cpp"
cp "$LLAMA_CPP_DIR/tools/mtmd/clip.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/clip.cpp" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip.cpp"
cp "$LLAMA_CPP_DIR/tools/mtmd/clip-impl.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-impl.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/clip-graph.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-graph.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd-helper.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-helper.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd-helper.cpp" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-helper.cpp"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd-audio.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-audio.h"
cp "$LLAMA_CPP_DIR/tools/mtmd/mtmd-audio.cpp" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-audio.cpp"
cp "$LLAMA_CPP_DIR/tools/mtmd/clip-model.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-model.h"
# Copy mtmd audio files if they exist
if [ -f "$LLAMA_CPP_DIR/vendor/miniaudio/miniaudio.h" ]; then
    mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/miniaudio"
    cp "$LLAMA_CPP_DIR/vendor/miniaudio/miniaudio.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/miniaudio/miniaudio.h"
fi
# Copy stb_image.h from vendor directory
if [ -f "$LLAMA_CPP_DIR/vendor/stb/stb_image.h" ]; then
    mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb"
    cp "$LLAMA_CPP_DIR/vendor/stb/stb_image.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb/stb_image.h"
elif [ -f "$LLAMA_CPP_DIR/common/stb_image.h" ]; then
    mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb"
    cp "$LLAMA_CPP_DIR/common/stb_image.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb/stb_image.h"
elif [ -f "$LLAMA_CPP_DIR/ggml/src/stb_image.h" ]; then
    mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb"
    cp "$LLAMA_CPP_DIR/ggml/src/stb_image.h" "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb/stb_image.h"
fi

# Copy mtmd models directory and its contents
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models"
if [ -d "$LLAMA_CPP_DIR/tools/mtmd/models" ]; then
    cp "$LLAMA_CPP_DIR/tools/mtmd/models"/*.h "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/" 2>/dev/null || true
    cp "$LLAMA_CPP_DIR/tools/mtmd/models"/*.cpp "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/" 2>/dev/null || true
fi

# Copy models directory and its contents
mkdir -p "$PROJECT_ROOT/lib/llama_cpp/models"
cp "$LLAMA_CPP_DIR/src/models/models.h" "$PROJECT_ROOT/lib/llama_cpp/models/models.h"
cp "$LLAMA_CPP_DIR/src/models"/*.cpp "$PROJECT_ROOT/lib/llama_cpp/models/" 2>/dev/null || true

files_add_lm_prefix=(
  "$PROJECT_ROOT/lib/llama_cpp/llama-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-impl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-vocab.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-vocab.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-grammar.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-grammar.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-sampling.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-sampling.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-adapter.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-adapter.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-arch.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-arch.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-batch.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-batch.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-chat.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-chat.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-context.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-context.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cache-iswa.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model-loader.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model-loader.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model-saver.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model-saver.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-model.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-mmap.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-mmap.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-hparams.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-hparams.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-cparams.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-cparams.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-graph.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-graph.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-io.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-io.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-memory.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-memory.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-memory-hybrid.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama-memory-recurrent.h"
  "$PROJECT_ROOT/lib/llama_cpp/log.h"
  "$PROJECT_ROOT/lib/llama_cpp/log.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama.h"
  "$PROJECT_ROOT/lib/llama_cpp/llama.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-cpp.h"
  "$PROJECT_ROOT/lib/llama_cpp/sampling.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/sampling.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/sgemm.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/sgemm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/common.h"
  "$PROJECT_ROOT/lib/llama_cpp/common.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/json-schema-to-grammar.h"
  "$PROJECT_ROOT/lib/llama_cpp/json-schema-to-grammar.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/chat.h"
  "$PROJECT_ROOT/lib/llama_cpp/chat.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/base64.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/chat-parser.h"
  "$PROJECT_ROOT/lib/llama_cpp/chat-parser.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/chat-peg-parser.h"
  "$PROJECT_ROOT/lib/llama_cpp/chat-peg-parser.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/chat-parser-xml-toolcall.h"
  "$PROJECT_ROOT/lib/llama_cpp/chat-parser-xml-toolcall.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/console.h"
  "$PROJECT_ROOT/lib/llama_cpp/console.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/arg.h"
  "$PROJECT_ROOT/lib/llama_cpp/arg.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/http.h"
  "$PROJECT_ROOT/lib/llama_cpp/download.h"
  "$PROJECT_ROOT/lib/llama_cpp/download.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/json-partial.h"
  "$PROJECT_ROOT/lib/llama_cpp/json-partial.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/json.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/llguidance.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ngram-cache.h"
  "$PROJECT_ROOT/lib/llama_cpp/ngram-cache.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/preset.h"
  "$PROJECT_ROOT/lib/llama_cpp/preset.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/regex-partial.h"
  "$PROJECT_ROOT/lib/llama_cpp/regex-partial.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/speculative.h"
  "$PROJECT_ROOT/lib/llama_cpp/speculative.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/unicode.h"
  "$PROJECT_ROOT/lib/llama_cpp/unicode.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/unicode-data.h"
  "$PROJECT_ROOT/lib/llama_cpp/unicode-data.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/peg-parser.h"
  "$PROJECT_ROOT/lib/llama_cpp/peg-parser.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-common.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml.c"
  "$PROJECT_ROOT/lib/llama_cpp/gguf.h"
  "$PROJECT_ROOT/lib/llama_cpp/gguf.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpp.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-opt.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-opt.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.m"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.metal"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-device.m"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-context.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-context.m"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-common.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-common.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-ops.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-metal-ops.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-alloc.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-alloc.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-backend.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-backend.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-backend-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-backend-reg.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-feats.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-quants.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64-repack.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-aarch64.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-quants.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-quants.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-traits.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ggml-cpu-traits.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/quants.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/traits.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/repack.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/common.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-threading.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-threading.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx/amx.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx/amx.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx/mmq.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx/mmq.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/amx/common.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/unary-ops.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/unary-ops.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/binary-ops.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/binary-ops.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/vec.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/vec.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/simd-mappings.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/arch-fallback.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ops.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu/ops.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-impl.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-graph.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/clip-model.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-helper.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-helper.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-audio.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/mtmd-audio.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/miniaudio/miniaudio.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/stb/stb_image.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/models.h"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/cogvlm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/conformer.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/glm4v.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/internvl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/kimivl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/llama4.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/llava.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/minicpmv.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/pixtral.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/qwen2vl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/qwen3vl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/siglip.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/tools/mtmd/models/whisper-enc.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/minja/minja.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/minja/chat-template.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/nlohmann/json.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/nlohmann/json_fwd.hpp"
  "$PROJECT_ROOT/lib/llama_cpp/llama-kv-cells.h"
  "$PROJECT_ROOT/lib/llama_cpp/models/models.h"
  "$PROJECT_ROOT/lib/llama_cpp/models/afmoe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/apertus.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/arcee.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/arctic.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/arwkv7.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/baichuan.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/bailingmoe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/bailingmoe2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/bert.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/bitnet.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/bloom.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/chameleon.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/chatglm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/codeshell.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/cogvlm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/cohere2-iswa.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/command-r.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/dbrx.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/deci.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/deepseek.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/deepseek2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/dots1.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/dream.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/ernie4-5-moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/ernie4-5.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/exaone.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/exaone4.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/falcon-h1.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/falcon.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gemma-embedding.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gemma.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gemma2-iswa.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gemma3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gemma3n-iswa.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/glm4-moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/glm4.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gpt2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/gptneox.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/granite-hybrid.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/granite.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/graph-context-mamba.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/grok.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/grovemoe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/hunyuan-dense.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/hunyuan-moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/internlm2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/jais.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/jamba.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/lfm2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/llada-moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/llada.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/llama-iswa.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/llama.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/mamba.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/minicpm3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/minimax-m2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/mistral3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/modern-bert.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/mpt.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/nemotron-h.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/nemotron.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/neo-bert.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/olmo.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/olmo2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/olmoe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/openai-moe-iswa.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/openelm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/orion.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/pangu-embedded.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/phi2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/phi3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/plamo.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/plamo2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/plm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen2moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen2vl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen3moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen3next.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen3vl-moe.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/qwen3vl.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/refact.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rnd1.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rwkv6-base.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rwkv6.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rwkv6qwen2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rwkv7-base.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/rwkv7.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/seed-oss.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/smallthinker.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/smollm3.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/stablelm.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/starcoder.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/starcoder2.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/t5-dec.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/t5-enc.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/wavtokenizer-dec.cpp"
  "$PROJECT_ROOT/lib/llama_cpp/models/xverse.cpp"
)

OS=$(uname)
for file in "${files_add_lm_prefix[@]}"; do
  # Check if file exists before processing
  if [ -f "$file" ]; then
    if [ "$OS" = "Darwin" ]; then
      # First remove any existing LM_ prefixes to avoid duplicates
      sed -i '' 's/LM_GGML_/GGML_/g' "$file"
      sed -i '' 's/lm_ggml_/ggml_/g' "$file"
      sed -i '' 's/LM_GGUF_/GGUF_/g' "$file"
      sed -i '' 's/lm_gguf_/gguf_/g' "$file"
      # Now add the LM_ prefixes
      sed -i '' 's/GGML_/LM_GGML_/g' "$file"
      sed -i '' 's/ggml_/lm_ggml_/g' "$file"
      sed -i '' 's/GGUF_/LM_GGUF_/g' "$file"
      sed -i '' 's/gguf_/lm_gguf_/g' "$file"
      sed -i '' 's/GGMLMetalClass/LMGGMLMetalClass/g' "$file"
      # Clean up any accidental multiple prefixes
      sed -i '' 's/LM_LM_LM_GGML_/LM_GGML_/g' "$file"
      sed -i '' 's/LM_LM_GGML_/LM_GGML_/g' "$file"
      sed -i '' 's/lm_lm_lm_ggml_/lm_ggml_/g' "$file"
      sed -i '' 's/lm_lm_ggml_/lm_ggml_/g' "$file"
      sed -i '' 's/LM_LM_LM_GGUF_/LM_GGUF_/g' "$file"
      sed -i '' 's/LM_LM_GGUF_/LM_GGUF_/g' "$file"
      sed -i '' 's/lm_lm_lm_gguf_/lm_gguf_/g' "$file"
      sed -i '' 's/lm_lm_gguf_/lm_gguf_/g' "$file"
    else
      # First remove any existing LM_ prefixes to avoid duplicates
      sed -i 's/LM_GGML_/GGML_/g' "$file"
      sed -i 's/lm_ggml_/ggml_/g' "$file"
      sed -i 's/LM_GGUF_/GGUF_/g' "$file"
      sed -i 's/lm_gguf_/gguf_/g' "$file"
      # Now add the LM_ prefixes
      sed -i 's/GGML_/LM_GGML_/g' "$file"
      sed -i 's/ggml_/lm_ggml_/g' "$file"
      sed -i 's/GGUF_/LM_GGUF_/g' "$file"
      sed -i 's/gguf_/lm_gguf_/g' "$file"
      sed -i 's/GGMLMetalClass/LMGGMLMetalClass/g' "$file"
      # Clean up any accidental multiple prefixes
      sed -i 's/LM_LM_LM_GGML_/LM_GGML_/g' "$file"
      sed -i 's/LM_LM_GGML_/LM_GGML_/g' "$file"
      sed -i 's/lm_lm_lm_ggml_/lm_ggml_/g' "$file"
      sed -i 's/lm_lm_ggml_/lm_ggml_/g' "$file"
      sed -i 's/LM_LM_LM_GGUF_/LM_GGUF_/g' "$file"
      sed -i 's/LM_LM_GGUF_/LM_GGUF_/g' "$file"
      sed -i 's/lm_lm_lm_gguf_/lm_gguf_/g' "$file"
      sed -i 's/lm_lm_gguf_/lm_gguf_/g' "$file"
    fi
  else
    echo "Optional file not found, skipping: $file"
  fi
done

files_iq_add_lm_prefix=(
  "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.h"
  "$PROJECT_ROOT/lib/llama_cpp/ggml-quants.c"
  "$PROJECT_ROOT/lib/llama_cpp/ggml.c"
)

for file in "${files_iq_add_lm_prefix[@]}"; do 
  # Check if file exists before processing
  if [ -f "$file" ]; then
    if [ "$OS" = "Darwin" ]; then
      # Only add prefix if not already present
      sed -i '' 's/\biq2xs_init_impl\b/lm_iq2xs_init_impl/g' "$file"
      sed -i '' 's/\biq2xs_free_impl\b/lm_iq2xs_free_impl/g' "$file"
      sed -i '' 's/\biq3xs_init_impl\b/lm_iq3xs_init_impl/g' "$file"
      sed -i '' 's/\biq3xs_free_impl\b/lm_iq3xs_free_impl/g' "$file"
      # Remove any accidental multiple prefixes
      sed -i '' 's/lm_lm_lm_iq/lm_iq/g' "$file"
      sed -i '' 's/lm_lm_iq/lm_iq/g' "$file"
    else
      # Only add prefix if not already present
      sed -i 's/\biq2xs_init_impl\b/lm_iq2xs_init_impl/g' "$file"
      sed -i 's/\biq2xs_free_impl\b/lm_iq2xs_free_impl/g' "$file"
      sed -i 's/\biq3xs_init_impl\b/lm_iq3xs_init_impl/g' "$file"
      sed -i 's/\biq3xs_free_impl\b/lm_iq3xs_free_impl/g' "$file"
      # Remove any accidental multiple prefixes
      sed -i 's/lm_lm_lm_iq/lm_iq/g' "$file"
      sed -i 's/lm_lm_iq/lm_iq/g' "$file"
    fi
  else
    echo "Optional file not found, skipping: $file"
  fi
done

echo "Replacement completed successfully!"



# Apply patches (optional - don't fail if patches don't apply)
patches_dir="$PROJECT_ROOT/lib/llama_cpp/patches"
if [ -d "$patches_dir" ]; then
    # Change to lib/llama_cpp directory to apply patches correctly
    original_dir="$(pwd)"
    cd "$PROJECT_ROOT/lib/llama_cpp"
    
    for patch_file in "$patches_dir"/*.patch; do
        if [ -f "$patch_file" ]; then
            echo "Applying $patch_file..."
            # Apply with non-interactive mode using -p0 since patches are relative to lib/llama_cpp
            patch --batch --silent -p0 < "$patch_file" 2>/dev/null || \
            echo "WARNING: Patch $patch_file failed to apply (may be incompatible with current branch)"
        fi
    done
    
    # Remove any .orig files created by patch
    rm -rf "$PROJECT_ROOT/lib/llama_cpp"/*.orig "$PROJECT_ROOT/lib/llama_cpp/ggml-cpu"/*.orig 2>/dev/null
    
    # Change back to original directory
    cd "$original_dir"
fi

# No need to verify duplicate prefixes since we completely clean the directory first
echo "SUCCESS: Patch process completed without duplicate prefix verification!"

if [ "$OS" = "Darwin" ]; then
  echo "Attempting Metal shader compilation..."
  
  if cd "$LLAMA_CPP_DIR/ggml/src/ggml-metal" 2>/dev/null; then
    ln -sf ../ggml-common.h . 2>/dev/null

    # Compile Metal shaders for iPhoneOS (optional)
    if xcrun --sdk iphoneos metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 2>/dev/null; then
      if xcrun --sdk iphoneos metallib ggml-metal.air -o ggml-llama.metallib 2>/dev/null; then
            rm ggml-metal.air
            mv ./ggml-llama.metallib "$PROJECT_ROOT/lib/llama_cpp/ggml-llama.metallib" 2>/dev/null
        echo "✓ iPhoneOS Metal shader compilation completed"
      fi
    else
      echo "⚠ iPhoneOS Metal shader compilation failed (missing toolchain or errors)"
    fi

    # Compile Metal shaders for simulator (optional)
    if xcrun --sdk iphonesimulator metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 2>/dev/null; then
      if xcrun --sdk iphonesimulator metallib ggml-metal.air -o ggml-llama.metallib 2>/dev/null; then
            rm ggml-metal.air
            mv ./ggml-llama.metallib "$PROJECT_ROOT/lib/llama_cpp/ggml-llama-sim.metallib" 2>/dev/null
        echo "✓ Simulator Metal shader compilation completed"
      fi
    else
      echo "⚠ Simulator Metal shader compilation failed (missing toolchain or errors)"
    fi

    rm ggml-common.h 2>/dev/null
    cd -
  else
    echo "⚠ Metal directory not found"
  fi
  
  echo "Metal support configuration completed"
fi

echo ""
echo "====================================="
echo "PATCH PROCESS COMPLETED SUCCESSFULLY!"
echo "====================================="
echo ""
echo "Next steps to verify the build:"
echo "1. Build the library: cd lib/build && cmake .. && make -j4"
echo "2. Run tests: cd lib/build/tests && make && ./run_tests"
echo ""
echo "If you encounter issues, you can manually restore from backup:"
echo "cp -r $BACKUP_DIR/* lib/llama_cpp/"
echo ""
echo "Metal support has been enabled for iOS/Apple devices."

# Clean up cloned llama.cpp directory
# if [ -d "$LLAMA_CPP_DIR" ]; then
#    echo "Cleaning up cloned llama.cpp directory..."
#    rm -rf "$LLAMA_CPP_DIR"
#    echo "✓ Cloned llama.cpp directory removed"
# fi
