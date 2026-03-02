#!/bin/bash

# ============================================================================
# ANDROID NATIVE LIBRARY BUILD SCRIPT
# Builds low-level Android libraries (no Kotlin/Java bindings)
# Output: llama_mobile/llama_mobile-android/libs/
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    export $(grep -E '^(ANDROID_HOME|NDK_PATH|ANDROID_PLATFORM|ANDROID_BUILD_TYPE|ANDROID_ABIS|CMAKE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Variables with defaults
ANDROID_HOME=${ANDROID_HOME:-""}              # Path to Android SDK root directory
NDK_PATH=${NDK_PATH:-""}                     # Path to Android NDK
ANDROID_PLATFORM=${ANDROID_PLATFORM:-"android-28"} # Minimum Android API level (28 for Vulkan 1.1)
BUILD_TYPE=${ANDROID_BUILD_TYPE:-"Release"}    # Release or Debug build
ABIS=${ANDROID_ABIS:-"arm64-v8a,x86_64"}       # Target ABIs to build for
NUM_JOBS=${CMAKE_JOBS:-""}                    # Number of parallel build jobs

# GPU Backend flags (Vulkan enabled by default for Android)
# OpenCL is optional and disabled by default
ENABLE_GPU=${ENABLE_GPU:-"true"}              # Enable GPU support by default
GGML_OPENCL=${GGML_OPENCL:-"OFF"}             # Disable OpenCL backend by default
GGML_VULKAN=${GGML_VULKAN:-"ON"}              # Enable Vulkan backend by default (requires Vulkan SDK)

# VULKAN SDK INSTALLATION:
# Vulkan is required for GPU acceleration on Android.
# Please install Vulkan SDK using one of these methods:
#
# macOS (using Homebrew):
#   brew install vulkan-sdk
#
# Linux (Ubuntu/Debian):
#   sudo apt-get install vulkan-sdk
#
# Windows:
#   Download from https://vulkan.lunarg.com/sdk/home
#
# After installation, this script will attempt to detect the Vulkan headers
# in common locations like /opt/homebrew/include and /usr/local/include.


# Debug log to verify NDK_PATH
log_message "[DEBUG] NDK_PATH from config.env: $NDK_PATH"

# Build behavior flags
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
if [ -z "$ANDROID_BUILD_TYPE" ]; then
    update_config_env "ANDROID_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$ANDROID_ABIS" ]; then
    update_config_env "ANDROID_ABIS" "$ABIS"
fi

if [ -z "$ANDROID_PLATFORM" ]; then
    update_config_env "ANDROID_PLATFORM" "$ANDROID_PLATFORM"
fi

if [ -z "$VERBOSE" ]; then
    update_config_env "VERBOSE" "$VERBOSE"
fi

# ============================================================================
# SCRIPT SETUP
# ============================================================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_message() {
    local level="INFO"
    local color="${BLUE}"
    local message="$1"
    
    if [[ "$message" =~ ^\[(ERROR|WARN|INFO|SUCCESS)\] ]]; then
        level="${BASH_REMATCH[1]}"
        message="${message:$((${#level} + 2))}"
        
        case "$level" in
            ERROR) color="${RED}" ;;
            WARN) color="${YELLOW}" ;;
            INFO) color="${BLUE}" ;;
            SUCCESS) color="${GREEN}" ;;
        esac
    fi
    
    echo -e "${color}[\$(date '+%H:%M:%S')] [${level}] $message${NC}"
}

script_progress() {
    log_message "[INFO] $1"
}

verbose_output() {
    if [[ "$VERBOSE" == true ]]; then
        log_message "[INFO] $1"
    fi
}

handle_error() {
    local exit_code=$1
    local message="$2"
    log_message "[ERROR] $message"
    log_message "[ERROR] Build failed with exit code: $exit_code"
    exit $exit_code
}

# Show help message
show_help() {
    echo -e "${BLUE}Usage: ./build-android-lib.sh [OPTIONS]${NC}"
    echo ""
    echo "Builds low-level llama_mobile Android static libraries (no Kotlin/Java bindings)."
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  --abi=ABI1,ABI2         Specify which ABIs to build (default: $ABIS)"
    echo "  --ndk-path=PATH         Path to Android NDK"
    echo "  --build-type=TYPE       Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --platform=PLATFORM     Android platform (default: $ANDROID_PLATFORM)"
    echo "  --debug                 Build with Debug configuration (same as --build-type=Debug)"
    echo "  --verbose               Show verbose output"
    echo ""
    echo "GPU Backend Options:"
    echo "  --no-gpu                Disable GPU support (default: enabled)"
    echo "  --opencl                Enable OpenCL backend (default: enabled)"
    echo "  --no-opencl             Disable OpenCL backend"
    echo "  --vulkan                Enable Vulkan backend (default: enabled)"
    echo "  --no-vulkan             Disable Vulkan backend"
    echo ""
    echo "Notes:"
    echo "  - Only static libraries are built (libllama_mobile.a)"
    echo "  - Both OpenCL and Vulkan backends are enabled by default"
    echo "  - Vulkan requires Vulkan SDK installed on the build host"
    echo "  - GPU libraries are loaded at runtime using dlopen()"
    echo "  - Backend selection happens at runtime based on device capabilities"
    echo ""
    echo "ANDROID_HOME Configuration:"
    echo "  The script automatically detects ANDROID_HOME from common SDK paths."
    echo ""
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --abi=*) ABIS="${1#*=}" ;;
        --ndk-path=*) NDK_PATH="${1#*=}" ;;
        --build-type=*) BUILD_TYPE="${1#*=}" ;;
        --platform=*) ANDROID_PLATFORM="${1#*=}" ;;
        --debug) BUILD_TYPE="Debug" ;;
        --verbose) VERBOSE=true ;;
        --no-gpu) ENABLE_GPU="false" ;;
        --opencl) GGML_OPENCL="ON" ;;
        --no-opencl) GGML_OPENCL="OFF" ;;
        --vulkan) GGML_VULKAN="ON" ;;
        --no-vulkan) GGML_VULKAN="OFF" ;;
        *) log_message "[ERROR] Unknown parameter: $1" ; show_help ;;
    esac
    shift
done

# Disable GPU backends if GPU support is disabled
if [[ "$ENABLE_GPU" == "false" ]]; then
    GGML_OPENCL="OFF"
    GGML_VULKAN="OFF"
    log_message "[INFO] GPU support disabled"
else
    log_message "[INFO] GPU support enabled (OpenCL: $GGML_OPENCL, Vulkan: $GGML_VULKAN)"
fi

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/llama_mobile-android"
LIBS_DIR="$OUTPUT_DIR/libs"
INCLUDE_DIR="$OUTPUT_DIR/include"

log_message "[INFO] === Building llama_mobile Android Native Libraries ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Target ABIs: $ABIS"
log_message "[INFO] Output: $LIBS_DIR"

# Check if lib directory exists
script_progress "Checking for lib directory..."
if [ ! -d "$ROOT_DIR/lib" ]; then
    handle_error 1 "lib directory not found! Please ensure you're in the correct directory."
fi
log_message "[SUCCESS] lib directory found"

# Detect ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    script_progress "ANDROID_HOME not set, trying to detect..."
    
    OS=$(uname -s)
    
    if [ "$OS" = "Darwin" ]; then
        # macOS paths
        COMMON_PATHS=("$HOME/Library/Android/sdk" "$HOME/android-sdk")
    elif [ "$OS" = "Linux" ]; then
        # Linux paths
        COMMON_PATHS=("$HOME/Android/Sdk" "$HOME/android-sdk" "/opt/android-sdk")
    else
        handle_error 1 "Unsupported operating system: $OS"
    fi
    
    detected=false
    for PATH in "${COMMON_PATHS[@]}"; do
        if [ -d "$PATH" ]; then
            ANDROID_HOME="$PATH"
            detected=true
            break
        fi
    done
    
    if [[ "$detected" = false ]]; then
        handle_error 1 "ANDROID_HOME not found! Please set it manually."
    fi
    
    log_message "[SUCCESS] Detected ANDROID_HOME: $ANDROID_HOME"
    # Update config.env with detected ANDROID_HOME
    update_config_env "ANDROID_HOME" "$ANDROID_HOME"
fi

# Detect NDK_PATH if not set
if [ -z "$NDK_PATH" ]; then
    script_progress "NDK_PATH not set, trying to detect..."
    
    if [ -d "$ANDROID_HOME/ndk" ]; then
        # Get the latest NDK version - simpler approach
        NDK_PATH=""
        for dir in "$ANDROID_HOME/ndk"/*; do
            if [ -d "$dir" ] && [[ "$dir" != "$ANDROID_HOME/ndk" ]]; then
                NDK_PATH="$dir"
                break
            fi
        done
        if [ -z "$NDK_PATH" ]; then
            handle_error 1 "NDK versions found but could not determine path!"
        fi
    else
        handle_error 1 "NDK not found! Please install it via Android Studio SDK Manager."
    fi
    
    log_message "[SUCCESS] Detected NDK_PATH: $NDK_PATH"
    # Update config.env with detected NDK_PATH
    update_config_env "NDK_PATH" "$NDK_PATH"
fi

# Set CMake variables
CMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake"
CMAKE_BUILD_TYPE="$BUILD_TYPE"

# Clean only specific directories to preserve persistent files
script_progress "Cleaning specific directories..."
if [ -d "$OUTPUT_DIR" ]; then
    # Remove only the directories that need to be refreshed
    rm -rf "$LIBS_DIR" "$INCLUDE_DIR"
    log_message "[INFO] Cleaned specific directories in: $OUTPUT_DIR"
else
    log_message "[INFO] Output directory not found, will create it"
fi

# Create output directories
script_progress "Creating output directories..."
# Create directory for static libraries only
STATIC_LIBS_DIR="$LIBS_DIR/static"
mkdir -p "$STATIC_LIBS_DIR" "$INCLUDE_DIR"
log_message "[SUCCESS] Output directories created"

# Copy header files to include directory
script_progress "Copying header files..."
cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$INCLUDE_DIR/" 2>/dev/null || true
cp "$ROOT_DIR/lib/llama_mobile_api.h" "$INCLUDE_DIR/" 2>/dev/null || true

# Copy headers from llama.cpp-master
mkdir -p "$INCLUDE_DIR/llama_cpp"
rsync -av "$ROOT_DIR/lib/llama.cpp-master/ggml/include/" "$INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"
rsync -av "$ROOT_DIR/lib/llama.cpp-master/include/" "$INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"
rsync -av "$ROOT_DIR/lib/llama.cpp-master/common/" "$INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"

# Copy third-party headers
rsync -av "$ROOT_DIR/lib/llama.cpp-master/vendor/" "$INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"

log_message "[SUCCESS] Header files copied"

# Build for each ABI
script_progress "Building for each ABI..."
IFS=',' read -ra ABI_LIST <<< "$ABIS"

for ABI in "${ABI_LIST[@]}"; do
    log_message "[INFO] 
=== Building for $ABI ==="
    
    # Add platform-specific flags
    PLATFORM_FLAGS=""
    if [ "$ABI" = "arm64-v8a" ]; then
        PLATFORM_FLAGS="-DGGML_NO_POSIX_MADVISE=ON"
    fi
    
    # Skip building shared library when GPU support is enabled (OpenCL linking issues)
    
    # Build static library
    log_message "[INFO] Building static library for $ABI..."
    STATIC_BUILD_DIR="$ROOT_DIR/build-android-native-static-$ABI"
    rm -rf "$STATIC_BUILD_DIR"
    mkdir -p "$STATIC_BUILD_DIR"
    
    # Configure CMake for static library
    script_progress "Configuring CMake for static library ($ABI)..."
    
    # Build GPU flags for static library
    STATIC_GPU_FLAGS=""
    if [[ "$ENABLE_GPU" == "true" ]]; then
        STATIC_GPU_FLAGS="-DGGML_OPENCL=$GGML_OPENCL -DGGML_VULKAN=$GGML_VULKAN"
        
        # Add Vulkan include path if Vulkan is enabled
        if [[ "$GGML_VULKAN" == "ON" ]]; then
            # Try to find Vulkan SDK on the system
            VULKAN_INCLUDE_FOUND=false
            if [[ -d "/opt/homebrew/include" ]]; then
                STATIC_GPU_FLAGS="$STATIC_GPU_FLAGS -DCMAKE_CXX_FLAGS=\"-I/opt/homebrew/include\" -DCMAKE_C_FLAGS=\"-I/opt/homebrew/include\""
                VULKAN_INCLUDE_FOUND=true
            elif [[ -d "/usr/local/include" ]]; then
                STATIC_GPU_FLAGS="$STATIC_GPU_FLAGS -DCMAKE_CXX_FLAGS=\"-I/usr/local/include\" -DCMAKE_C_FLAGS=\"-I/usr/local/include\""
                VULKAN_INCLUDE_FOUND=true
            fi
            
            if [[ "$VULKAN_INCLUDE_FOUND" == false ]]; then
                log_message "[WARNING] Vulkan headers not found! Please install Vulkan SDK first."
                log_message "[WARNING] See instructions at the top of this script."
            fi
        fi
        log_message "[INFO] GPU flags for static library: $STATIC_GPU_FLAGS"
    fi
    
    STATIC_CMAKE_COMMAND="cmake -S $ROOT_DIR/lib -B $STATIC_BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE=\"$CMAKE_TOOLCHAIN_FILE\" \
        -DANDROID_ABI=\"$ABI\" \
        -DANDROID_PLATFORM=\"$ANDROID_PLATFORM\" \
        -DCMAKE_BUILD_TYPE=\"$CMAKE_BUILD_TYPE\" \
        -DANDROID_STL=c++_static \
        -DBUILD_SHARED_LIBS=OFF \
        -DLLAMA_USE_HTTPLIB=OFF \
        -DGGML_OPENMP=OFF \
        $PLATFORM_FLAGS \
        $STATIC_GPU_FLAGS"
    
    verbose_output "Static library CMake command: $STATIC_CMAKE_COMMAND"
    
    if ! eval "$STATIC_CMAKE_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|CMake Error|CMake Warning)" || true; fi); then
        handle_error 1 "CMake configuration failed for static library ($ABI)!"
    fi
    
    # Build static library
    script_progress "Building static library for $ABI..."
    NUM_JOBS=${NUM_JOBS:-4}
    STATIC_BUILD_COMMAND="cmake --build $STATIC_BUILD_DIR --config \"$CMAKE_BUILD_TYPE\" -j $NUM_JOBS"
    
    verbose_output "Static library build command: $STATIC_BUILD_COMMAND"
    
    if ! eval "$STATIC_BUILD_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|FAILED|FAILED_LINK|Build failed)" || true; fi); then
        handle_error 1 "Static library build failed for $ABI!"
    fi
    
    # Copy ALL individual static libraries
    STATIC_DEST_DIR="$STATIC_LIBS_DIR/$ABI"
    mkdir -p "$STATIC_DEST_DIR"
    
    # List of all static libraries we need to copy
    STATIC_LIBS=(
        "libllama_mobile_core.a"
        "llama.cpp-master/src/libllama.a"
        "llama.cpp-master/common/libcommon.a"
        "llama.cpp-master/ggml/src/libggml.a"
        "llama.cpp-master/ggml/src/libggml-base.a"
        "llama.cpp-master/ggml/src/libggml-cpu.a"
        "llama.cpp-master/tools/mtmd/libmtmd.a"
        "llama.cpp-master/vendor/cpp-httplib/libcpp-httplib.a"
    )
    
    # Add Vulkan library if Vulkan is enabled
    if [[ "$GGML_VULKAN" == "ON" ]]; then
        STATIC_LIBS+=("llama.cpp-master/ggml/src/ggml-vulkan/libggml-vulkan.a")
    fi
    
    # Copy all the libraries
    ALL_COPIED=true
    for LIB in "${STATIC_LIBS[@]}"; do
        LIB_PATH="$STATIC_BUILD_DIR/$LIB"
        if [ -f "$LIB_PATH" ]; then
            LIB_NAME=$(basename "$LIB")
            cp "$LIB_PATH" "$STATIC_DEST_DIR/"
            log_message "[SUCCESS] Copied $LIB_NAME to $STATIC_DEST_DIR"
        else
            log_message "[ERROR] Could not find $LIB at $LIB_PATH"
            ALL_COPIED=false
        fi
    done
    
    if [[ "$ALL_COPIED" == false ]]; then
        handle_error 1 "Some static libraries were not found!"
    fi
    
    # Clean up static library build directory
    # rm -rf "$STATIC_BUILD_DIR"
done

# Create CMakeLists.txt for easy integration only if it doesn't exist
script_progress "Checking for existing CMakeLists.txt..."
if [ ! -f "$OUTPUT_DIR/CMakeLists.txt" ]; then
    script_progress "Creating CMakeLists.txt for integration..."
    cat > "$OUTPUT_DIR/CMakeLists.txt" << EOL
cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(
    \${CMAKE_CURRENT_SOURCE_DIR}/include
    \${CMAKE_CURRENT_SOURCE_DIR}/include/llama_cpp
)

# Import the pre-built libraries (static only)
set(LLAMA_MOBILE_ABIS arm64-v8a x86_64)

# Static libraries
foreach(ABI \${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_static_\${ABI} STATIC IMPORTED)
    set_target_properties(llama_mobile_static_\${ABI} PROPERTIES
        IMPORTED_LOCATION \${CMAKE_CURRENT_SOURCE_DIR}/libs/static/\${ABI}/libllama_mobile.a
        ANDROID_ABI \${ABI}
    )
endforeach()

# Main library target for linking (static only)
add_library(llama_mobile_static STATIC IMPORTED)
set_target_properties(llama_mobile_static PROPERTIES
    IMPORTED_LOCATION \${CMAKE_CURRENT_SOURCE_DIR}/libs/static/\${ANDROID_ABI}/libllama_mobile.a
)
EOL
    log_message "[SUCCESS] CMakeLists.txt created for integration"
else
    log_message "[INFO] CMakeLists.txt already exists, preserving it"
fi

# Clean up any remaining build directories
script_progress "Cleaning up temporary build directories..."
rm -rf "$ROOT_DIR/build-android-native-*"

# Verify the build
script_progress "Verifying build..."

# List of all static libraries we need to check
STATIC_LIBS=(
    "libllama_mobile_core.a"
    "libllama.a"
    "libcommon.a"
    "libggml.a"
    "libggml-base.a"
    "libggml-cpu.a"
    "libmtmd.a"
    "libcpp-httplib.a"
    "libggml-vulkan.a"
)

# Check if static libraries were built
for ABI in "${ABI_LIST[@]}"; do
    log_message "[INFO] Checking libraries for $ABI..."
    ALL_FOUND=true
    for LIB in "${STATIC_LIBS[@]}"; do
        STATIC_LIB_PATH="$STATIC_LIBS_DIR/$ABI/$LIB"
        if [ -f "$STATIC_LIB_PATH" ]; then
            log_message "[SUCCESS] Found: $STATIC_LIB_PATH ($(ls -lh "$STATIC_LIB_PATH" | awk '{print $5}'))"
        else
            log_message "[ERROR] Not found: $STATIC_LIB_PATH"
            ALL_FOUND=false
        fi
    done
    
    if [[ "$ALL_FOUND" == false ]]; then
        handle_error 1 "Some libraries missing for $ABI!"
    fi
done

log_message "[SUCCESS] === Build completed successfully! ==="
log_message "[INFO] Android native libraries are available at:"
log_message "[INFO] - Static Libraries: $STATIC_LIBS_DIR"
log_message "[INFO] - Headers: $INCLUDE_DIR"
log_message "[INFO] - Integration: $OUTPUT_DIR/CMakeLists.txt"
log_message ""
log_message "[INFO] These libraries contain no Kotlin/Java bindings and can be used with:"
log_message "[INFO] - Flutter via FFI"
log_message "[INFO] - React Native via JNI"
log_message "[INFO] - Direct NDK integration"
log_message ""
log_message "[INFO] Static libraries (libllama_mobile.a) include GPU support (OpenCL and Vulkan)"
log_message "[INFO] GPU libraries are loaded at runtime using dlopen()"
