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

# Validate build environment
validate_environment() {
    echo -e "${BLUE}Validating build environment...${NC}"
    
    # Check Xcode installation
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}✗ Xcode not found! Please install Xcode.${NC}"
        exit 1
    fi
    
    # Check compiler
    if ! command -v clang &> /dev/null; then
        echo -e "${RED}✗ Clang compiler not found!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Xcode found: $(xcodebuild -version | head -n 1)${NC}"
    echo -e "${GREEN}✓ Compiler: $(clang --version | head -n 1)${NC}"
    
    # Get current SDK path automatically
    SDK_PATH=$(xcrun --show-sdk-path)
    if [ -z "$SDK_PATH" ]; then
        echo -e "${RED}✗ Could not determine SDK path!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ SDK Path: $SDK_PATH${NC}"
    
    # Test C++ header availability
    echo -e "${BLUE}Testing C++ header availability...${NC}"
    cat > test_cpp_headers.cpp << 'EOF'
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <memory>

int main() {
    return 0;
}
EOF
    
    if clang++ -std=c++17 -isysroot "$SDK_PATH" test_cpp_headers.cpp -o test_cpp_headers; then
        echo -e "${GREEN}✓ C++ headers found successfully${NC}"
        rm -f test_cpp_headers.cpp test_cpp_headers
    else
        echo -e "${RED}✗ Failed to find C++ headers!${NC}"
        echo -e "${YELLOW}ℹ Make sure Xcode Command Line Tools are installed.${NC}"
        echo -e "${YELLOW}ℹ Try running: xcode-select --install${NC}"
        rm -f test_cpp_headers.cpp
        exit 1
    fi
}

# Export SDK_PATH for use in build function
export SDK_PATH

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
    
    # Run CMake with explicit SDK path
    CMAKE_OSX_SYSROOT="$SDK_PATH" cmake ..
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

# Copy grammar files to output directory
copy_grammars() {
    echo -e "${BLUE}Copying grammar files...${NC}"
    GRAMMAR_SRC_DIR="$LLAMA_MOBILE_DIR/grammars"
    GRAMMAR_DEST_DIR="$OUTPUT_DIR/grammars"
    
    mkdir -p "$GRAMMAR_DEST_DIR"
    
    if [ -d "$GRAMMAR_SRC_DIR" ]; then
        cp "$GRAMMAR_SRC_DIR"/*.gbnf "$GRAMMAR_DEST_DIR/"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Grammar files copied successfully${NC}"
        else
            echo -e "${RED}✗ Failed to copy grammar files${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}ℹ Grammar source directory not found, skipping grammar files${NC}"
    fi
}

# Main execution flow
validate_environment
clean_build
build_project
copy_grammars

echo -e "${BLUE}=== Build script completed ===${NC}"