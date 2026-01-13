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
ANDROID_PLATFORM=${ANDROID_PLATFORM:-"android-21"} # Minimum Android API level
BUILD_TYPE=${ANDROID_BUILD_TYPE:-"Release"}    # Release or Debug build
ABIS=${ANDROID_ABIS:-"arm64-v8a,x86_64"}       # Target ABIs to build for
NUM_JOBS=${CMAKE_JOBS:-""}                    # Number of parallel build jobs

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
    echo "Builds low-level llama_mobile Android libraries (no Kotlin/Java bindings)."
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  --abi=ABI1,ABI2         Specify which ABIs to build (default: $ABIS)"
    echo "  --ndk-path=PATH         Path to Android NDK"
    echo "  --build-type=TYPE       Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --platform=PLATFORM     Android platform (default: $ANDROID_PLATFORM)"
    echo "  --verbose               Show verbose output"
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
        --verbose) VERBOSE=true ;;
        *) log_message "[ERROR] Unknown parameter: $1" ; show_help ;;
    esac
    shift
done

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/llama_mobile-android"
LIBS_DIR="$OUTPUT_DIR/libs"
INCLUDE_DIR="$OUTPUT_DIR/include"
GRAMMARS_DIR="$OUTPUT_DIR/grammars"

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

# Create output directories
script_progress "Creating output directories..."
mkdir -p "$LIBS_DIR" "$INCLUDE_DIR" "$GRAMMARS_DIR"
log_message "[SUCCESS] Output directories created"

# Copy header files to include directory
script_progress "Copying header files..."
cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$INCLUDE_DIR/"
cp "$ROOT_DIR/lib/llama_mobile_api.h" "$INCLUDE_DIR/"
mkdir -p "$INCLUDE_DIR/llama_cpp"
rsync -av "$ROOT_DIR/lib/llama_cpp/" "$INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"
log_message "[SUCCESS] Header files copied"

# Copy grammar files to assets directory
script_progress "Copying grammar files..."
if [ -d "$ROOT_DIR/lib/grammars" ]; then
    cp "$ROOT_DIR/lib/grammars"/*.gbnf "$GRAMMARS_DIR/" 2>/dev/null || true
    log_message "[SUCCESS] Grammar files copied"
else
    log_message "[WARN] No grammar files found"
fi

# Build for each ABI
script_progress "Building for each ABI..."
IFS=',' read -ra ABI_LIST <<< "$ABIS"

for ABI in "${ABI_LIST[@]}"; do
    log_message "[INFO] 
=== Building for $ABI ==="
    
    # Create build directory
    BUILD_DIR="$ROOT_DIR/build-android-native-$ABI"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    
    # Add platform-specific flags
    PLATFORM_FLAGS=""
    if [ "$ABI" = "arm64-v8a" ]; then
        PLATFORM_FLAGS="-DGGML_NO_POSIX_MADVISE=ON"
    fi
    
    # Configure CMake
    script_progress "Configuring CMake for $ABI..."
    CMAKE_COMMAND="cmake -S $ROOT_DIR/lib -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE=\"$CMAKE_TOOLCHAIN_FILE\" \
        -DANDROID_ABI=\"$ABI\" \
        -DANDROID_PLATFORM=\"$ANDROID_PLATFORM\" \
        -DCMAKE_BUILD_TYPE=\"$CMAKE_BUILD_TYPE\" \
        -DANDROID_STL=c++_shared \
        -DBUILD_SHARED_LIBS=ON \
        $PLATFORM_FLAGS"
    
    verbose_output "CMake command: $CMAKE_COMMAND"
    
    if ! eval "$CMAKE_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|CMake Error|CMake Warning)" || true; fi); then
        handle_error 1 "CMake configuration failed for $ABI!"
    fi
    
    # Build
    script_progress "Building library for $ABI..."
    # Use NUM_JOBS from config.env if set, otherwise detect automatically based on OS
    DETECTED_NUM_JOBS="$NUM_JOBS"
    if [ -z "$DETECTED_NUM_JOBS" ]; then
        if [ "$(uname)" = "Darwin" ]; then
            # macOS
            DETECTED_NUM_JOBS=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
        elif [ "$(uname)" = "Linux" ]; then
            # Linux
            DETECTED_NUM_JOBS=$(nproc 2>/dev/null || echo 4)
        else
            # Default
            DETECTED_NUM_JOBS=4
        fi
    fi
    BUILD_COMMAND="cmake --build $BUILD_DIR --config \"$CMAKE_BUILD_TYPE\" -j \"$DETECTED_NUM_JOBS\""
    
    verbose_output "Build command: $BUILD_COMMAND"
    
    if ! eval "$BUILD_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|FAILED|FAILED_LINK|Build failed)" || true; fi); then
        handle_error 1 "Build failed for $ABI!"
    fi
    
    # Copy the built library
    DEST_DIR="$LIBS_DIR/$ABI"
    DEST_LIB="$DEST_DIR/libllama_mobile.so"
    
    # Find the actual built library
    SOURCE_LIB=""
    # Check standard locations
    if [ -f "$BUILD_DIR/libllama_mobile_core.so" ]; then
        SOURCE_LIB="$BUILD_DIR/libllama_mobile_core.so"
    elif [ -f "$BUILD_DIR/lib/libllama_mobile_core.so" ]; then
        SOURCE_LIB="$BUILD_DIR/lib/libllama_mobile_core.so"
    elif [ -f "$BUILD_DIR/Release/libllama_mobile_core.so" ]; then
        SOURCE_LIB="$BUILD_DIR/Release/libllama_mobile_core.so"
    elif [ -f "$BUILD_DIR/Debug/libllama_mobile_core.so" ]; then
        SOURCE_LIB="$BUILD_DIR/Debug/libllama_mobile_core.so"
    else
        # Search the build directory
        SOURCE_LIB=$(find "$BUILD_DIR" -name "libllama_mobile_core.so" 2>/dev/null | head -1)
    fi
    
    if [ -n "$SOURCE_LIB" ]; then
        mkdir -p "$DEST_DIR"
        cp "$SOURCE_LIB" "$DEST_LIB"
        log_message "[SUCCESS] Built $DEST_LIB"
    else
        log_message "[ERROR] Could not find built library for $ABI!"
    fi
    
    # Clean up
    rm -rf "$BUILD_DIR"
done

# Create CMakeLists.txt for easy integration
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

# Import the pre-built libraries
set(LLAMA_MOBILE_ABIS arm64-v8a x86_64)

foreach(ABI \${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_\${ABI} SHARED IMPORTED)
    set_target_properties(llama_mobile_\${ABI} PROPERTIES
        IMPORTED_LOCATION \${CMAKE_CURRENT_SOURCE_DIR}/libs/\${ABI}/libllama_mobile.so
        ANDROID_ABI \${ABI}
    )
endforeach()

# Main library target for linking
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION \${CMAKE_CURRENT_SOURCE_DIR}/libs/\${ANDROID_ABI}/libllama_mobile.so
)
EOL

log_message "[SUCCESS] CMakeLists.txt created for integration"

# Clean up any remaining build directories
script_progress "Cleaning up temporary build directories..."
rm -rf "$ROOT_DIR/build-android-native-*"

# Verify the build
script_progress "Verifying build..."

# Check if libraries were built
for ABI in "${ABI_LIST[@]}"; do
    LIB_PATH="$LIBS_DIR/$ABI/libllama_mobile.so"
    if [ -f "$LIB_PATH" ]; then
        log_message "[SUCCESS] $LIB_PATH: $(ls -lh "$LIB_PATH" | awk '{print $5}')"
        log_message "[INFO]   Architecture: $(file "$LIB_PATH" | grep -o "ARM aarch64\|x86-64")"
    else
        log_message "[ERROR] Library not found: $LIB_PATH"
    fi
done

log_message "[SUCCESS] === Build completed successfully! ==="
log_message "[INFO] Android native libraries are available at:"
log_message "[INFO] - Libraries: $LIBS_DIR"
log_message "[INFO] - Headers: $INCLUDE_DIR"
log_message "[INFO] - Grammars: $GRAMMARS_DIR"
log_message "[INFO] - Integration: $OUTPUT_DIR/CMakeLists.txt"
log_message ""
log_message "[INFO] These libraries contain no Kotlin/Java bindings and can be used with:"
log_message "[INFO] - Flutter via FFI"
log_message "[INFO] - React Native via JNI"
log_message "[INFO] - Direct NDK integration"
