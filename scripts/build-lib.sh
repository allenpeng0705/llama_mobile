#!/bin/bash

# ============================================================================
# CORE LIBRARY BUILD SCRIPT
# This script uses variables from config.env and provides auto-detection
# Only builds the core library, not tests
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(CMAKE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|CC|CXX|SDK_PATH|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables with defaults from centralized config
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLAMA_MOBILE_DIR="$PROJECT_ROOT/lib"
BUILD_DIR="$LLAMA_MOBILE_DIR/build"
OUTPUT_DIR="$BUILD_DIR/output"
SDK_PATH="$SDK_PATH"
CMAKE_ARGS=""
BUILD_TYPE=${CMAKE_BUILD_TYPE:-"Release"}
NUM_JOBS=${CMAKE_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}

# Build behavior flags with defaults
NO_CLEAN=${NO_CLEAN:-false}                # Skip cleaning build directories
KEEP_BUILD=${KEEP_BUILD:-false}            # Keep intermediate build files
VERBOSE=${VERBOSE:-false}                  # Show verbose output

# Function to update config.env with detected values
update_config_env() {
    local var_name=$1
    local var_value=$2
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "^${var_name}=" "$CONFIG_FILE"; then
            # Update existing variable
            sed -i '' "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$CONFIG_FILE"
        else
            # Add new variable
            echo "${var_name}=\"${var_value}\"" >> "$CONFIG_FILE"
        fi
    fi
}

# Update config.env with reasonable defaults if they're not set
if [ -z "$CMAKE_BUILD_TYPE" ]; then
    update_config_env "CMAKE_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$CMAKE_JOBS" ]; then
    update_config_env "CMAKE_JOBS" "$NUM_JOBS"
fi

if [ -z "$NO_CLEAN" ]; then
    update_config_env "NO_CLEAN" "$NO_CLEAN"
fi

if [ -z "$KEEP_BUILD" ]; then
    update_config_env "KEEP_BUILD" "$KEEP_BUILD"
fi

if [ -z "$VERBOSE" ]; then
    update_config_env "VERBOSE" "$VERBOSE"
fi

# Override with CC and CXX from config if available
if [ -n "$CC" ]; then
    export CC
fi
if [ -n "$CXX" ]; then
    export CXX
fi

# Function to display usage information
show_usage() {
    echo -e "${BLUE}Usage: $0 [options]${NC}"
    echo ""
    echo "Build variables can be configured in scripts/config.env:"
    echo "  - CMAKE_PATH: Path to CMake executable"
    echo "  - CMAKE_BUILD_TYPE: Release or Debug build"
    echo "  - CMAKE_JOBS: Number of parallel build jobs"
    echo "  - CC: C compiler path"
    echo "  - CXX: C++ compiler path"
    echo "  - SDK_PATH: Custom SDK path"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -b, --build-dir      Custom build directory (default: $BUILD_DIR)"
    echo "  -o, --output-dir     Custom output directory (default: $OUTPUT_DIR)"
    echo "  -s, --sdk-path       Custom SDK path (default: auto-detected)"
    echo "  -j, --jobs           Number of build jobs (default: $NUM_JOBS)"
    echo "  -d, --debug          Build in debug mode"
    echo "  -c, --clean          Clean build directory before building"
    echo "  --no-clean           Skip cleaning build directory"
    echo "  --cmake-args         Additional CMake arguments"
    echo ""
    echo "Note: This script only builds the core library (llama_mobile_core_lib)."
    echo "      Use build-tests-run.sh to build and run tests."
    echo ""
    echo "Examples:"
    echo "  $0 -j 8 --debug"
    echo "  $0 --sdk-path /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
    echo "  $0 --cmake-args '-DBUILD_SHARED_LIBS=ON'"
    exit 0
}

# Parse command line arguments
parse_args() {
    local clean_build=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                ;;
            -b|--build-dir)
                BUILD_DIR="$2"
                OUTPUT_DIR="$BUILD_DIR/output"
                shift 2
                ;;
            -o|--output-dir)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -s|--sdk-path)
                SDK_PATH="$2"
                shift 2
                ;;
            -j|--jobs)
                NUM_JOBS="$2"
                shift 2
                ;;
            -d|--debug)
                BUILD_TYPE="Debug"
                shift
                ;;
            -c|--clean)
                clean_build=true
                shift
                ;;
            --no-clean)
                clean_build=false
                shift
                ;;
            --cmake-args)
                CMAKE_ARGS="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                ;;
        esac
    done
    
    # Set clean_build variable for use in main flow
    export CLEAN_BUILD=$clean_build
}

# Validate build environment
validate_environment() {
    echo -e "${BLUE}=== llama_mobile Core Library Build Script ===${NC}"
    echo -e "${BLUE}Validating build environment...${NC}"
    
    # Check for necessary tools
    local tools=(xcodebuild clang cmake make)
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${RED}✗ $tool not found!${NC}"
            case $tool in
                xcodebuild)
                    echo -e "${YELLOW}ℹ Please install Xcode from the App Store.${NC}"
                    ;;
                clang)
                    echo -e "${YELLOW}ℹ Make sure Xcode Command Line Tools are installed.${NC}"
                    echo -e "${YELLOW}ℹ Try running: xcode-select --install${NC}"
                    ;;
                cmake)
                    echo -e "${YELLOW}ℹ Please install CMake (brew install cmake).${NC}"
                    ;;
                make)
                    echo -e "${YELLOW}ℹ Please install make (usually comes with Xcode Command Line Tools).${NC}"
                    ;;
            esac
            exit 1
        fi
    done
    
    # Print tool versions
    echo -e "${GREEN}✓ Xcode: $(xcodebuild -version | head -n 1)${NC}"
    echo -e "${GREEN}✓ Compiler: $(clang --version | head -n 1)${NC}"
    echo -e "${GREEN}✓ CMake: $(cmake --version | head -n 1)${NC}"
    echo -e "${GREEN}✓ Make: $(make --version | head -n 1)${NC}"
    
    # Get SDK path if not provided
    if [ -z "$SDK_PATH" ]; then
        SDK_PATH=$(xcrun --show-sdk-path)
        if [ -z "$SDK_PATH" ]; then
            echo -e "${RED}✗ Could not determine SDK path!${NC}"
            echo -e "${YELLOW}ℹ Try specifying it with --sdk-path.${NC}"
            exit 1
        fi
    fi
    
    # Validate SDK path
    if [ ! -d "$SDK_PATH" ]; then
        echo -e "${RED}✗ Invalid SDK path: $SDK_PATH${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ SDK Path: $SDK_PATH${NC}"
    
    # Test C++ header availability
    echo -e "${BLUE}Testing C++ header availability...${NC}"
    local test_file="test_cpp_headers.cpp"
    cat > "$test_file" << 'EOF'
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
#include <memory>

int main() {
    return 0;
}
EOF
    
    if clang++ -std=c++17 -isysroot "$SDK_PATH" "$test_file" -o "${test_file%.cpp}"; then
        echo -e "${GREEN}✓ C++ headers found successfully${NC}"
        rm -f "$test_file" "${test_file%.cpp}"
    else
        echo -e "${RED}✗ Failed to find C++ headers!${NC}"
        echo -e "${YELLOW}ℹ Make sure Xcode Command Line Tools are properly installed.${NC}"
        echo -e "${YELLOW}ℹ Try running: xcode-select --reset${NC}"
        rm -f "$test_file"
        exit 1
    fi
}

# Clean old build
clean_build() {
    if [ "$CLEAN_BUILD" = true ]; then
        echo -e "${YELLOW}Cleaning old build...${NC}"
        if [ -d "$BUILD_DIR" ]; then
            rm -rf "$BUILD_DIR"
            echo -e "${GREEN}✓ Old build cleaned${NC}"
        else
            echo -e "${YELLOW}ℹ No existing build directory found${NC}"
        fi
    else
        echo -e "${YELLOW}Skipping build directory cleaning${NC}"
    fi
}

# Build the core library only
build_core_library() {
    echo -e "${BLUE}Building llama_mobile core library ($BUILD_TYPE)...${NC}"
    echo -e "${BLUE}Build directory: $BUILD_DIR${NC}"
    echo -e "${BLUE}Output directory: $OUTPUT_DIR${NC}"
    echo -e "${BLUE}Using $NUM_JOBS build jobs${NC}"
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Run CMake with configuration
    echo -e "${BLUE}Running CMake configuration...${NC}"
    local cmake_command="CMAKE_OSX_SYSROOT=\"$SDK_PATH\" cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE $CMAKE_ARGS .."
    echo -e "${BLUE}Command: $cmake_command${NC}"
    
    if eval "$cmake_command"; then
        echo -e "${GREEN}✓ CMake configuration completed${NC}"
    else
        echo -e "${RED}✗ CMake configuration failed${NC}"
        exit 1
    fi
    
    # Build the llama_mobile core library
    echo -e "${BLUE}Building llama_mobile core library...${NC}"
    if make llama_mobile_core_static -j"$NUM_JOBS"; then
        echo -e "${GREEN}✓ llama_mobile core library built successfully${NC}"
    else
        echo -e "${RED}✗ llama_mobile core library build failed${NC}"
        exit 1
    fi
}



# Display summary
show_summary() {
    echo -e "${BLUE}=== Build Summary ===${NC}"
    echo -e "${GREEN}✓ Core library build completed successfully${NC}"
    echo -e "${BLUE}Build type:${NC} $BUILD_TYPE"
    echo -e "${BLUE}Build directory:${NC} $BUILD_DIR"
    echo -e "${BLUE}Output directory:${NC} $OUTPUT_DIR"
    echo -e "${BLUE}SDK path:${NC} $SDK_PATH"
    echo -e "${BLUE}=====================${NC}"
    echo -e "${YELLOW}Note: To build and run tests, use: bash scripts/build-tests-run.sh${NC}"
}

# Main execution flow
main() {
    parse_args "$@"
    validate_environment
    clean_build
    build_core_library
    show_summary
}

# Run the main function
main "$@"
