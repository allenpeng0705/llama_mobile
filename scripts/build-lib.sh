#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== llama_mobile Build Script ===${NC}"

# Define paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/build"
OUTPUT_DIR="$BUILD_DIR/output"

# Clean old build
clean_build() {
    echo -e "${YELLOW}Cleaning old build...${NC}"
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        echo -e "${GREEN}✓ Old build cleaned${NC}"
    else
        echo -e "${YELLOW}ℹ No existing build directory found${NC}"
    fi
}

# Build the project
build_project() {
    echo -e "${BLUE}Building llama_mobile...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Run CMake and make with MNN flags - disable NEON and SSE to avoid linker errors
    cmake .. -DMNN_BUILD_SHARED_LIBS=OFF -DMNN_BUILD_LLM=ON -DMNN_USE_NEON=OFF -DMNN_USE_SSE=OFF -DMNN_LOW_MEMORY=ON
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ CMake configuration failed${NC}"
        exit 1
    fi
    
    make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc)
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Build completed successfully${NC}"
}

# Main execution flow
clean_build
build_project

echo -e "${BLUE}=== Build script completed ===${NC}"