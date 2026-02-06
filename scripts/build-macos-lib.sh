#!/bin/bash -e

# ============================================================================
# MACOS LIBRARY BUILD SCRIPT
# Builds static library for macOS
# Output: llama_mobile/output/mac_libs
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    export $(grep -E '^(MACOS_BUILD_TYPE|MACOS_ARCHES|XCODE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Variables with defaults
BUILD_TYPE=${MACOS_BUILD_TYPE:-"Release"}          # Release or Debug build
ARCHES=${MACOS_ARCHES:-"arm64"}         # macOS architectures (universal binary)
XCODE_PATH=${XCODE_PATH:-""}                     # Path to Xcode application

# Build behavior flags
VERBOSE=${VERBOSE:-false}                          # Show verbose output

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
if [ -z "$MACOS_BUILD_TYPE" ]; then
    update_config_env "MACOS_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$MACOS_ARCHES" ]; then
    update_config_env "MACOS_ARCHES" "$ARCHES"
fi

if [ -z "$VERBOSE" ]; then
    update_config_env "VERBOSE" "$VERBOSE"
fi

# Colors for output
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
    
    echo -e "${color}[$(date '+%H:%M:%S')] [${level}] $message${NC}" >&2
}

script_progress() {
    log_message "[INFO] $1"
}

handle_error() {
    local exit_code="$1"
    local message="$2"
    
    log_message "[ERROR] $message"
    exit "$exit_code"
}

# Parse command line arguments
for arg in "$@"; do
    case "$arg" in
        --debug)
            BUILD_TYPE="Debug"
            ;;
        --release)
            BUILD_TYPE="Release"
            ;;
        --arches=*)
            ARCHES="${arg#*=}"
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --static-only)
            # This is now the default behavior
            ;;
        --shared-only)
            # Shared library build is disabled
            log_message "[ERROR] Shared library build is disabled. Use build-macos-static.sh instead."
            exit 1
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--debug] [--release] [--arches=<arch1,arch2>] [--verbose]"
            exit 1
            ;;
    esac
done

# Check for required dependencies
script_progress "Checking for required dependencies..."

if ! command -v cmake &> /dev/null; then
    handle_error 1 "CMake not found. Please install CMake."
fi

if ! xcode-select -p &> /dev/null; then
    handle_error 1 "Xcode command line tools not found. Please install them."
fi

if ! command -v xcrun &> /dev/null; then
    handle_error 1 "xcrun not found. Please ensure Xcode is installed properly."
fi

if ! command -v lipo &> /dev/null; then
    handle_error 1 "lipo not found. Please ensure Xcode is installed properly."
fi

log_message "[SUCCESS] Found CMake"
log_message "[SUCCESS] Found Xcode command line tools"
log_message "[SUCCESS] Found xcrun"
log_message "[SUCCESS] Found lipo"
log_message "[SUCCESS] All required dependencies found"

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Main output directory (llama_mobile/output/mac_libs)
OUTPUT_DIR="$ROOT_DIR/output/mac_libs"

# Static library directories
STATIC_INCLUDE_DIR="$OUTPUT_DIR/include"
STATIC_LIB_DIR="$OUTPUT_DIR/lib"
STATIC_METAL_DIR="$OUTPUT_DIR/metal"

log_message "[INFO] === Building llama_mobile macOS Static Library ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Architectures: $ARCHES"
log_message "[INFO] Output directory: $OUTPUT_DIR"

# Clean output directory
script_progress "Cleaning output directory..."
rm -rf "$OUTPUT_DIR"

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$STATIC_INCLUDE_DIR"
mkdir -p "$STATIC_LIB_DIR"
mkdir -p "$STATIC_METAL_DIR"

log_message "[SUCCESS] Output directory cleaned and created"

# Build function for a specific architecture
build_arch() {
    local ARCH="$1"
    local BUILD_DIR="$2"
    
    script_progress "Building static library for macOS-$ARCH..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure CMake for macOS
    cmake "$ROOT_DIR/lib" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
        -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
        -DLLAMA_USE_CURL=OFF \
        -DLLAMA_USE_HTTPLIB=OFF
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "CMake configuration failed for static library macOS-$ARCH!"
    fi
    
    # Build static library
    cmake --build . --config "$BUILD_TYPE" --target llama_mobile_core_static -j $(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "Build failed for static library macOS-$ARCH!"
    fi
    
    # Find the built library
    local LIB_PATH="$BUILD_DIR/output/lib/libllama_mobile_core.a"
    
    if [[ ! -f "$LIB_PATH" ]]; then
        handle_error 1 "Could not find built static library for macOS-$ARCH!"
    fi
    
    # Clean up
    cd "$ROOT_DIR"
    
    log_message "[SUCCESS] Built static library for macOS-$ARCH"
    printf "%s\n" "$LIB_PATH"
}

# Build static libraries for all architectures
STATIC_LIBS=()
for ARCH in $ARCHES; do
    BUILD_DIR="$ROOT_DIR/build-macos-static-$ARCH"
    LIB_PATH=$(build_arch "$ARCH" "$BUILD_DIR" | tail -1)
    STATIC_LIBS+=("$LIB_PATH")
done

# Create universal static library
script_progress "Creating universal static library..."
if [[ ${#STATIC_LIBS[@]} -gt 1 ]]; then
    lipo -create "${STATIC_LIBS[@]}" -output "$STATIC_LIB_DIR/libllama_mobile.a"
    log_message "[SUCCESS] Created universal static library: $STATIC_LIB_DIR/libllama_mobile.a"
else
    rsync -a "${STATIC_LIBS[0]}" "$STATIC_LIB_DIR/libllama_mobile.a"
    log_message "[SUCCESS] Copied static library: $STATIC_LIB_DIR/libllama_mobile.a"
fi

# Copy headers to static include directory
script_progress "Copying headers to static directory..."
cp "$ROOT_DIR/lib/llama_mobile_api.h" "$STATIC_INCLUDE_DIR/"
cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$STATIC_INCLUDE_DIR/"
cp "$ROOT_DIR/lib/llama_mobile_version.h" "$STATIC_INCLUDE_DIR/"

# Copy all llama_cpp headers recursively
mkdir -p "$STATIC_INCLUDE_DIR/llama_cpp"
cd "$ROOT_DIR/lib/llama_cpp"
find . -name "*.h" -o -name "*.hpp" | while read file; do
    target_dir="$STATIC_INCLUDE_DIR/llama_cpp/$(dirname "$file")"
    mkdir -p "$target_dir"
    cp "$file" "$target_dir/"
done
cd "$ROOT_DIR"

log_message "[SUCCESS] Headers copied to static directory"

# Copy Metal files to static directory
script_progress "Copying Metal files to static directory..."
if [[ -f "$ROOT_DIR/lib/llama_cpp/ggml-metal.metal" ]]; then
    cp "$ROOT_DIR/lib/llama_cpp/ggml-metal.metal" "$STATIC_METAL_DIR/"
    
    # Compile Metal files into metallib
    if [[ -x "$(which xcrun)" ]]; then
        cd "$STATIC_METAL_DIR"
        xcrun -sdk macosx metal -I"$STATIC_INCLUDE_DIR" -I"$STATIC_INCLUDE_DIR/llama_cpp" -std=metal3.1 -mmacosx-version-min=10.15 ggml-metal.metal -o ggml-llama.metallib
        cd "$ROOT_DIR"
    fi
    
    log_message "[SUCCESS] Metal files copied to static directory"
else
    log_message "[WARN] No Metal files found"
fi

# Create README.md
cat > "$OUTPUT_DIR/README.md" << 'ENDOFFILE'
# LlamaMobile macOS Static Library

This directory contains pre-built LlamaMobile static library for macOS.

## Structure

```
output/mac_libs/
├── include/         # Header files
├── lib/            # Static library (.a)
└── metal/          # Metal shader files
```

## Quick Start

### Method 1: Drag and Drop (Easiest)

1. Open your Xcode project
2. Drag `output/mac_libs` folder into your project navigator
3. In dialog that appears:
   - Uncheck "Copy items if needed"
   - Select "Create folder references" (blue folder icon)
4. Add to your target

### Method 2: Manual Setup

1. Add library to your project:
   - Go to **Build Settings** > **Other Linker Flags**
   - Add: `-l$(PROJECT_DIR)/output/mac_libs/lib/libllama_mobile.a`

2. Add header search path:
   - Go to **Build Settings** > **Header Search Paths**
   - Add: `$(PROJECT_DIR)/output/mac_libs/include`

3. Link required frameworks:
   - Go to **Build Phases** > **Link Binary With Libraries**
   - Add: `Foundation`, `Accelerate`, `Metal`

4. Add Metal files to bundle (optional, for GPU acceleration):
   - Go to **Build Phases** > **Copy Bundle Resources**
   - Add: `output/mac_libs/metal/ggml-llama.metallib`

## Example Code

```c++
#include <llama_mobile_api.h>

// Initialize context
llama_context_params params = llama_context_default_params();
llama_context* ctx = llama_init_from_file("model.gguf", params);

// Generate completion
llama_completion_params comp_params = llama_completion_default_params();
llama_completion_result result = llama_completion(ctx, &comp_params);

// Clean up
llama_free(ctx);
```

## Build Information

- Build Type: BUILD_TYPE_PLACEHOLDER
- Architectures: ARCHES_PLACEHOLDER
- Minimum macOS version: 10.15
- Library version: 1.0.0

## Dependencies

The library requires to link against these system frameworks:
- Foundation
- Accelerate
- Metal

## Troubleshooting

### Linker Errors

If you get linker errors like "undefined reference to...":

1. Make sure you've added the library to "Other Linker Flags"
2. Make sure you've linked to required frameworks (Foundation, Accelerate, Metal)
3. Check that the library path is correct

### Header Not Found

If you get "llama_mobile_api.h file not found":

1. Make sure you've added the include directory to "Header Search Paths"
2. Check that the include path is correct
3. Try using angle brackets: `#include <llama_mobile_api.h>`

### Metal Not Working

If GPU acceleration is not working:

1. Make sure you've added `ggml-llama.metallib` to "Copy Bundle Resources"
2. Check that Metal is supported on your Mac
3. Verify that the metallib file is included in your app bundle

## Advanced Usage

### Custom Build Options

You can customize the build by modifying the script parameters:

```bash
# Build for specific architecture only
./scripts/build-macos-lib.sh --arches=arm64

# Build in debug mode
./scripts/build-macos-lib.sh --debug

# Build in release mode (default)
./scripts/build-macos-lib.sh --release

# Build with verbose output
./scripts/build-macos-lib.sh --verbose
```

### Using with CMake

If you're using CMake, add this to your `CMakeLists.txt`:

```cmake
# Add static library
add_library(llama_mobile STATIC IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/output/mac_libs/lib/libllama_mobile.a
    INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/output/mac_libs/include
)

# Link to your target
target_link_libraries(your_target PRIVATE llama_mobile)
target_link_libraries(your_target PRIVATE "-framework Foundation")
target_link_libraries(your_target PRIVATE "-framework Accelerate")
target_link_libraries(your_target PRIVATE "-framework Metal")
```

## Support

For more information and documentation, visit:
- GitHub: https://github.com/llama-mobile/llama_mobile
- Issues: https://github.com/llama-mobile/llama_mobile/issues

## License

This library follows the same license as llama.cpp.
ENDOFFILE

# Replace variables in README.md
if [ -f "$OUTPUT_DIR/README.md" ]; then
    sed -i '' "s|BUILD_TYPE_PLACEHOLDER|$BUILD_TYPE|g" "$OUTPUT_DIR/README.md"
    sed -i '' "s|ARCHES_PLACEHOLDER|$ARCHES|g" "$OUTPUT_DIR/README.md"
fi

log_message "[SUCCESS] README.md created"

# Clean up build directories
script_progress "Cleaning up build directories..."
rm -rf "$ROOT_DIR/build-macos-static-*"

log_message "[SUCCESS] Build directories cleaned up"

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "========================================"
echo ""
echo "Output directory: $OUTPUT_DIR"
echo ""
echo "Static library: $STATIC_LIB_DIR/libllama_mobile.a"
echo "Headers: $STATIC_INCLUDE_DIR/"
echo "Metal files: $STATIC_METAL_DIR/"
echo ""
echo "To use in your macOS app:"
echo "1. Drag the $OUTPUT_DIR folder into your Xcode project"
echo "2. Link to required frameworks: Foundation, Accelerate, Metal"
echo "3. Include headers: #include <llama_mobile_api.h>"
echo ""
echo "Done!"