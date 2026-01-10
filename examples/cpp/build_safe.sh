#!/bin/bash

# Robust build script for llama_mobile examples
# Automatically detects correct SDK path and handles common build issues

set -e

echo "=== Llama Mobile Build Script ==="
echo "Date: $(date)"

# Step 1: Validate environment
echo "\n1. Validating build environment..."

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode not found! Please install Xcode."
    exit 1
fi

# Check compiler
echo "✓ Xcode found: $(xcodebuild -version | head -n 1)"
echo "✓ Compiler: $(clang --version | head -n 1)"

# Get current SDK path automatically
SDK_PATH=$(xcrun --show-sdk-path)
if [ -z "$SDK_PATH" ]; then
    echo "❌ Could not determine SDK path!"
    exit 1
fi
echo "✓ SDK Path: $SDK_PATH"

# Test C++ headers
echo "\n2. Testing C++ header availability..."
cat > test_cpp_headers.cpp << 'EOF'
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <memory>

int main() {
    std::stringstream ss; 
    ss << "C++ headers test: ✓ All headers found!";
    std::cout << ss.str() << std::endl;
    return 0;
}
EOF

if clang++ -std=c++17 -isysroot "$SDK_PATH" test_cpp_headers.cpp -o test_cpp_headers; then
    ./test_cpp_headers
    rm -f test_cpp_headers test_cpp_headers.cpp
else
    echo "❌ Failed to compile C++ test program!"
    echo "   Check if Xcode Command Line Tools are installed: xcode-select --install"
    rm -f test_cpp_headers.cpp
    exit 1
fi

# Step 2: Prepare build directory
echo "\n3. Preparing build directory..."
rm -rf build
mkdir -p build
cd build

# Step 3: Run CMake with correct SDK
echo "\n4. Configuring CMake with SDK path: $SDK_PATH"
cmake -DCMAKE_OSX_SYSROOT="$SDK_PATH" ..

# Step 4: Build
echo "\n5. Building examples..."
make -j$(sysctl -n hw.ncpu)

# Step 5: Finalize
echo "\n=== Build Complete! ==="
echo "Examples built in: $(pwd)"
echo "To run: ./llama_mobile_api_example"
