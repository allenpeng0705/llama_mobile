#!/bin/bash

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== llama_mobile Library Build Script ===${NC}"

# Parse command-line arguments
#ENABLE_KLEIDIAI="false"
SKIP_TESTS="true"  # Default to skipping tests to avoid linker errors

while [[ $# -gt 0 ]]; do
    case $1 in
        --enable-kleidiai)
            ENABLE_KLEIDIAI="true"
            shift
            ;;
        --enable-tests)
            SKIP_TESTS="false"
            shift
            ;;
        *)
            echo -e "${YELLOW}Unknown argument: $1${NC}"
            echo -e "Usage: $0 [--enable-kleidiai] [--enable-tests]"
            exit 1
            ;;
    esac
done

# Define paths
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/build"

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

# Generate MNN schema headers
generate_mnn_headers() {
    echo -e "${BLUE}Generating MNN schema headers...${NC}"
    
    # Path to MNN schema generate script
    MNN_SCHEMA_DIR="$LLAMA_MOBILE_DIR/MNN/schema"
    
    if [ -f "$MNN_SCHEMA_DIR/generate.sh" ]; then
        cd "$MNN_SCHEMA_DIR"
        bash generate.sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}✗ Failed to generate MNN schema headers${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ MNN schema headers generated successfully${NC}"
    else
        echo -e "${YELLOW}ℹ MNN schema generate script not found, assuming headers are already generated${NC}"
    fi
}

# Build the library project
build_project() {
    echo -e "${BLUE}Building llama_mobile library...${NC}"
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # # Run CMake with appropriate options
    # CMAKE_OPTS=""
    # if [ "$ENABLE_KLEIDIAI" = "true" ]; then
    #     echo -e "${YELLOW}Enabling KleidiAI integration...${NC}"
    #     CMAKE_OPTS="-DMNN_KLEIDIAI=ON"
    # else
    #     echo -e "${YELLOW}Disabling KleidiAI integration...${NC}"
    #     CMAKE_OPTS="-DMNN_KLEIDIAI=OFF"
    # fi
    
    cmake .. $CMAKE_OPTS
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ CMake configuration failed${NC}"
        exit 1
    fi
    
    # Build both static and dynamic libraries when skipping tests, or all targets if tests are enabled
    if [ "$SKIP_TESTS" = "true" ]; then
        echo -e "${YELLOW}Building static library (skipping tests)...${NC}"
        make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc) llama_mobile_core_static
        
        echo -e "${YELLOW}Building dynamic library (skipping tests)...${NC}"
        make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc) llama_mobile_core_shared
    else
        echo -e "${YELLOW}Building all targets (including tests)...${NC}"
        make -j$(sysctl -n hw.ncpu 2>/dev/null || nproc)
    fi
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Library build completed successfully${NC}"
}

# Main execution flow
clean_build
generate_mnn_headers
build_project

echo -e "${BLUE}=== Library build script completed ===${NC}"
