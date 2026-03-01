#!/bin/bash

# ============================================================================
# BUILD OPENCL STUB LIBRARY FOR ANDROID
# ============================================================================

# Load configuration
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    export $(grep -E '^(ANDROID_HOME|NDK_PATH)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STUBS_DIR="$ROOT_DIR/llama_mobile-android-SDK/libs/stubs"

# Detect NDK_PATH if not set
if [ -z "$NDK_PATH" ]; then
    echo "[ERROR] NDK_PATH not set. Please set it in config.env or ANDROID_HOME"
    exit 1
fi

echo "[INFO] Using NDK_PATH: $NDK_PATH"

# Build for each ABI
for ABI in "arm64-v8a" "x86_64"; do
    echo "[INFO] Building OpenCL stub for $ABI..."
    
    # Set up build directory
    STUB_BUILD_DIR="$ROOT_DIR/build-opencl-stub-$ABI"
    rm -rf "$STUB_BUILD_DIR"
    mkdir -p "$STUB_BUILD_DIR"
    
    # Determine toolchain based on ABI
    if [ "$ABI" = "arm64-v8a" ]; then
        TOOLCHAIN_PREFIX="aarch64-linux-android"
    elif [ "$ABI" = "x86_64" ]; then
        TOOLCHAIN_PREFIX="x86_64-linux-android"
    fi
    
    # Get compiler from NDK - use API level 24 (minSdk) or try to find available version
    CC="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/${TOOLCHAIN_PREFIX}24-clang"
    if [ ! -f "$CC" ]; then
        # Try without API level suffix (newer NDKs)
        CC="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/${TOOLCHAIN_PREFIX}-clang"
    fi
    if [ ! -f "$CC" ]; then
        echo "[ERROR] Could not find compiler for $ABI in NDK"
        exit 1
    fi
    
    echo "[INFO] Using compiler: $CC"
    
    # Compile OpenCL stub library
    if ! "$CC" -c -o "$STUB_BUILD_DIR/opencl_stub.o" "$STUBS_DIR/opencl_stub.c"; then
        echo "[ERROR] Failed to compile OpenCL stub for $ABI"
        exit 1
    fi
    
    # Create OpenCL static library
    AR="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-ar"
    if ! "$AR" rcs "$STUB_BUILD_DIR/libOpenCL.a" "$STUB_BUILD_DIR/opencl_stub.o"; then
        echo "[ERROR] Failed to create OpenCL stub library for $ABI"
        exit 1
    fi
    
    # Compile Vulkan stub library
    if ! "$CC" -c -o "$STUB_BUILD_DIR/vulkan_stub.o" "$STUBS_DIR/vulkan_stub.c"; then
        echo "[ERROR] Failed to compile Vulkan stub for $ABI"
        exit 1
    fi
    
    # Create Vulkan static library
    if ! "$AR" rcs "$STUB_BUILD_DIR/libvulkan_stub.a" "$STUB_BUILD_DIR/vulkan_stub.o"; then
        echo "[ERROR] Failed to create Vulkan stub library for $ABI"
        exit 1
    fi
    
    # Copy to SDK
    mkdir -p "$STUBS_DIR/$ABI"
    if ! cp -f "$STUB_BUILD_DIR/libOpenCL.a" "$STUBS_DIR/$ABI/libOpenCL.a"; then
        echo "[ERROR] Failed to copy OpenCL stub library for $ABI"
        exit 1
    fi
    if ! cp -f "$STUB_BUILD_DIR/libvulkan_stub.a" "$STUBS_DIR/$ABI/libvulkan_stub.a"; then
        echo "[ERROR] Failed to copy Vulkan stub library for $ABI"
        exit 1
    fi
    
    echo "[SUCCESS] Built and copied OpenCL stub library for $ABI"
    
    # Clean up
    rm -rf "$STUB_BUILD_DIR"
done

echo "[SUCCESS] All OpenCL and Vulkan stub libraries built successfully!"
echo "[INFO] Stubs are available at: $STUBS_DIR"
