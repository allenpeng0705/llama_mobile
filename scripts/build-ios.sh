#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile iOS framework and optionally copies it to the Swift SDK."
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  -v, --verbose      Enable verbose output for debugging"
    echo "  --build-only       Only build the framework (default behavior)"
    echo "  --copy-only        Only copy an existing framework to the SDK"
    echo "  --build-and-copy   Build the framework and then copy it to the SDK"
    exit 0
}

# Default behavior: build only
BUILD_ONLY=true
COPY_ONLY=false
BUILD_AND_COPY=false
VERBOSE=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -v|--verbose) VERBOSE=true ;;
        --build-only) BUILD_ONLY=true ; COPY_ONLY=false ; BUILD_AND_COPY=false ;;
        --copy-only) BUILD_ONLY=false ; COPY_ONLY=true ; BUILD_AND_COPY=false ;;
        --build-and-copy) BUILD_ONLY=false ; COPY_ONLY=false ; BUILD_AND_COPY=true ;;
        *) echo "Unknown parameter: $1" ; show_help ;;
    esac
    shift


done

# Verbose logging function
verbose_log() {
    if [ "$VERBOSE" = true ]; then
        echo "[VERBOSE] $1"
    fi
}

if ! command -v cmake &> /dev/null && ( $BUILD_ONLY || $BUILD_AND_COPY ); then
  echo "✗ cmake could not be found, please install it"
  exit 1
fi

# Log initial parameters
verbose_log "Script directory: $SCRIPT_DIR"
verbose_log "Root directory: $ROOT_DIR"
verbose_log "Build mode: $(if [ $BUILD_ONLY = true ]; then echo "build-only"; elif [ $COPY_ONLY = true ]; then echo "copy-only"; else echo "build-and-copy"; fi)"
verbose_log "Verbose mode: $VERBOSE"

# Function to copy framework to SDK
function copy_to_sdk() {
    echo "=== Updating llama_mobile iOS SDK with latest framework ==="

    # Check if necessary directories exist
    if [ ! -d "$ROOT_DIR/llama_mobile-ios" ]; then
        echo "✗ Error: llama_mobile-ios directory not found!"
        verbose_log "Expected directory: $ROOT_DIR/llama_mobile-ios"
        exit 1
    fi
    verbose_log "Found llama_mobile-ios directory: $ROOT_DIR/llama_mobile-ios"

    if [ ! -d "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework" ]; then
        echo "✗ Error: llama_mobile.xcframework not found in llama_mobile-ios directory!"
        echo "Please build the iOS framework first using: $0"
        verbose_log "Expected framework path: $ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework"
        exit 1
    fi
    verbose_log "Found llama_mobile.xcframework: $ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework"

    # Create Frameworks directory if it doesn't exist
    echo -n "Creating Frameworks directory... "
    if mkdir -p "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks"; then
        echo "✓"
        verbose_log "Created directory: $ROOT_DIR/llama_mobile-ios-SDK/Frameworks"
    else
        echo "✗"
        echo "Failed to create directory: $ROOT_DIR/llama_mobile-ios-SDK/Frameworks"
        exit 1
    fi

    # Remove old framework if it exists
    if [ -d "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks/llama_mobile.xcframework" ]; then
        echo -n "Removing old framework... "
        if rm -rf "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks/llama_mobile.xcframework"; then
            echo "✓"
            verbose_log "Removed old framework: $ROOT_DIR/llama_mobile-ios-SDK/Frameworks/llama_mobile.xcframework"
        else
            echo "✗"
            echo "Failed to remove old framework"
            exit 1
        fi
    fi

    # Copy latest framework to SDK
    echo -n "Copying latest framework to SDK... "
    if cp -R "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework" "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks/"; then
        echo "✓"
        verbose_log "Copied framework to: $ROOT_DIR/llama_mobile-ios-SDK/Frameworks/"
    else
        echo "✗"
        echo "Failed to copy framework to SDK"
        exit 1
    fi

    echo "✓ Framework update completed successfully!"
    echo "The latest llama_mobile.xcframework has been copied to llama_mobile-ios-SDK/Frameworks/"
}

function cp_headers() {
  verbose_log "Copying headers for architecture: $1"
  
  # Create main directories
  HEADER_DIR="$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$1/llama_mobile.framework/Headers"
  verbose_log "Creating header directory: $HEADER_DIR"
  
  if ! mkdir -p "$HEADER_DIR"; then
    echo "✗ Failed to create header directory: $HEADER_DIR"
    exit 1
  fi
  
  # Copy the public API headers
  verbose_log "Copying public API headers"
  for header in "llama_mobile_unified.h" "llama_mobile_ffi.h" "llama_mobile_api.h"; do
    if ! cp "$ROOT_DIR/lib/$header" "$HEADER_DIR/"; then
      echo "✗ Failed to copy header: $header"
      exit 1
    fi
    verbose_log "Copied header: $header"
  done

  # Recursively copy all llama_cpp headers while preserving folder structure
  verbose_log "Copying llama_cpp headers with rsync"
  LLAMA_CPP_HEADER_DIR="$HEADER_DIR/llama_cpp/"
  if ! rsync -av "$ROOT_DIR/lib/llama_cpp/" "$LLAMA_CPP_HEADER_DIR" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"; then
    echo "✗ Failed to copy llama_cpp headers"
    exit 1
  fi
  verbose_log "Copied llama_cpp headers to: $LLAMA_CPP_HEADER_DIR"
  
  # Copy external library headers to the root Headers directory for proper <angled> include support
  verbose_log "Copying external library headers"
  
  # nlohmann headers
  NLOHMANN_DIR="$HEADER_DIR/nlohmann/"
  if ! mkdir -p "$NLOHMANN_DIR"; then
    echo "✗ Failed to create nlohmann directory"
    exit 1
  fi
  if ! cp "$ROOT_DIR/lib/llama_cpp/nlohmann"/*.hpp "$NLOHMANN_DIR"; then
    echo "✗ Failed to copy nlohmann headers"
    exit 1
  fi
  verbose_log "Copied nlohmann headers to: $NLOHMANN_DIR"
  
  # minja headers
  MINJA_DIR="$HEADER_DIR/minja/"
  if ! mkdir -p "$MINJA_DIR"; then
    echo "✗ Failed to create minja directory"
    exit 1
  fi
  if ! cp "$ROOT_DIR/lib/llama_cpp/minja"/*.hpp "$MINJA_DIR"; then
    echo "✗ Failed to copy minja headers"
    exit 1
  fi
  verbose_log "Copied minja headers to: $MINJA_DIR"
}

function build_framework() {
  # Parameters:
  # $1: system_name (iOS/tvOS)
  # $2: architectures
  # $3: sysroot
  # $4: output_path
  # $5: build_dir

  verbose_log "=== Building framework: $1, $2, $3, $4, $5 ==="
  verbose_log "Changing to build directory: $5"
  
  if ! cd "$5"; then
    echo "✗ Failed to change to build directory: $5"
    exit 1
  fi

  # Configure CMake
  echo -n "Configuring CMake for $4... "
  verbose_log "Running cmake command:"
  verbose_log "cmake $ROOT_DIR/llama_mobile-ios -GXcode -DCMAKE_SYSTEM_NAME=$1 -DCMAKE_OSX_ARCHITECTURES=$2 -DCMAKE_OSX_SYSROOT=$3 -DCMAKE_INSTALL_PREFIX=$(pwd)/install -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO -DCMAKE_IOS_INSTALL_COMBINED=YES"
  
  if ! cmake "$ROOT_DIR/llama_mobile-ios" \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=$1 \
    -DCMAKE_OSX_ARCHITECTURES="$2" \
    -DCMAKE_OSX_SYSROOT=$3 \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DCMAKE_IOS_INSTALL_COMBINED=YES; then
    echo "✗"
    echo "CMake configuration failed!"
    exit 1
  fi
  echo "✓"

  # Build
  echo -n "Building framework for $4... "
  NUM_CORES=$(sysctl -n hw.logicalcpu)
  verbose_log "Building with $NUM_CORES cores: cmake --build . --config Release -j $NUM_CORES"
  
  if ! cmake --build . --config Release -j $NUM_CORES; then
    echo "✗"
    echo "Build failed!"
    exit 1
  fi
  echo "✓"

  # Setup framework directory
  DEST_DIR="$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$4"
  FRAMEWORK_SRC="Release-$3/llama_mobile.framework"
  FRAMEWORK_DEST="$DEST_DIR/llama_mobile.framework"

  verbose_log "Setting up framework directory: $DEST_DIR"
  verbose_log "Source framework: $FRAMEWORK_SRC"
  verbose_log "Destination framework: $FRAMEWORK_DEST"

  echo -n "Preparing destination directory... "
  if ! rm -rf "$DEST_DIR" || ! mkdir -p "$DEST_DIR"; then
    echo "✗"
    echo "Failed to prepare destination directory: $DEST_DIR"
    exit 1
  fi
  echo "✓"

  # Copy the built framework to the destination
  echo -n "Copying built framework... "
  if [ -d "$FRAMEWORK_SRC" ]; then
    if ! cp -R "$FRAMEWORK_SRC" "$FRAMEWORK_DEST"; then
      echo "✗"
      echo "Failed to copy framework from $FRAMEWORK_SRC to $FRAMEWORK_DEST"
      exit 1
    fi
    echo "✓"
    verbose_log "Copied framework to: $FRAMEWORK_DEST"
  else
    echo "✗"
    echo "Error: Expected framework not found at $FRAMEWORK_SRC"
    exit 1
  fi

  # Copy headers and metallib
  echo -n "Copying headers... "
  cp_headers $4
  echo "✓"

  echo -n "Copying metallib file... "
  if [[ "$4" == *"-simulator" ]]; then
    METALLIB_SRC="$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib"
    METALLIB_DEST="$FRAMEWORK_DEST/ggml-llama-sim.metallib"
  else
    METALLIB_SRC="$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib"
    METALLIB_DEST="$FRAMEWORK_DEST/ggml-llama.metallib"
  fi
  
  verbose_log "Copying metallib from $METALLIB_SRC to $METALLIB_DEST"
  
  if ! cp "$METALLIB_SRC" "$METALLIB_DEST"; then
    echo "✗"
    echo "Failed to copy metallib file"
    exit 1
  fi
  echo "✓"
  
  # Create Modules directory with module map
  echo -n "Creating module map... "
  MODULE_DIR="$FRAMEWORK_DEST/Modules"
  if ! mkdir -p "$MODULE_DIR"; then
    echo "✗"
    echo "Failed to create Modules directory"
    exit 1
  fi
  
  MODULE_MAP="$MODULE_DIR/module.modulemap"
  cat > "$MODULE_MAP" << EOL
framework module llama_mobile {
    umbrella header "llama_mobile_unified.h"
    
    export *
    module * { export * }
}
EOL
  
  if [ $? -ne 0 ]; then
    echo "✗"
    echo "Failed to create module map"
    exit 1
  fi
  echo "✓"
  verbose_log "Created module map at: $MODULE_MAP"

  # Code sign the framework
  echo -n "Signing the framework... "
  if codesign --force --deep --sign "Apple Development" "$FRAMEWORK_DEST"; then
    echo "✓"
    verbose_log "Framework signed successfully"
  else
    echo "✗"
    echo "Note: Manual signing may be required. Try running:"
    echo "codesign --force --deep --sign 'Apple Development' '$FRAMEWORK_DEST'"
  fi

  echo -n "Cleaning up build directory... "
  if ! rm -rf ./*; then
    echo "✗"
    echo "Failed to clean up build directory"
  else
    echo "✓"
  fi
  
  verbose_log "Changing back to parent directory"
  if ! cd ..; then
    echo "✗ Failed to change back to parent directory"
    exit 1
  fi
}



# Check if Metal toolchain is available, download if needed
 echo -n "Checking Metal toolchain availability... "
if ! xcrun --sdk iphoneos metal -v &> /dev/null; then
  echo "✗"
  echo "Metal toolchain not found. Downloading..."
  if xcodebuild -downloadComponent MetalToolchain; then
    echo "✓ Metal toolchain downloaded successfully"
  else
    echo "✗ Failed to download Metal toolchain. Please install it manually."
    exit 1
  fi
else
  echo "✓"
  verbose_log "Metal toolchain version: $(xcrun --sdk iphoneos metal -v 2>&1 | head -n 1)"
fi

# Check if metallib files exist, generate if needed
echo -n "Checking for required metallib files... "
METALLIB_FILE="$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib"
SIM_METALLIB_FILE="$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib"

if [ ! -f "$METALLIB_FILE" ] || [ ! -f "$SIM_METALLIB_FILE" ]; then
  echo "✗"
  echo "Missing metallib files. Generating..."
  verbose_log "Changing to llama_cpp directory: $ROOT_DIR/lib/llama_cpp"
  
  if ! cd "$ROOT_DIR/lib/llama_cpp"; then
    echo "✗ Failed to change to llama_cpp directory"
    exit 1
  fi
  
  # Generate iPhoneOS metallib with compatible Metal language version and deployment target
  echo -n "Generating iPhoneOS metallib... "
  METAL_COMMAND="xcrun --sdk iphoneos metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 -std=ios-metal2.3 -mtargetos=ios13.0"
  METALLIB_COMMAND="xcrun --sdk iphoneos metallib ggml-metal.air -o ggml-llama.metallib"
  
  verbose_log "$METAL_COMMAND"
  verbose_log "$METALLIB_COMMAND"
  
  if $METAL_COMMAND && $METALLIB_COMMAND; then
    rm ggml-metal.air
    echo "✓"
  else
    echo "✗"
    echo "Failed to generate iPhoneOS metallib"
    exit 1
  fi
  
  # Generate simulator metallib with compatible Metal language version and deployment target
  echo -n "Generating simulator metallib... "
  SIM_METAL_COMMAND="xcrun --sdk iphonesimulator metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 -std=ios-metal2.3 -mtargetos=ios13.0"
  SIM_METALLIB_COMMAND="xcrun --sdk iphonesimulator metallib ggml-metal.air -o ggml-llama-sim.metallib"
  
  verbose_log "$SIM_METAL_COMMAND"
  verbose_log "$SIM_METALLIB_COMMAND"
  
  if $SIM_METAL_COMMAND && $SIM_METALLIB_COMMAND; then
    rm ggml-metal.air
    echo "✓"
  else
    echo "✗"
    echo "Failed to generate simulator metallib"
    exit 1
  fi
  
  verbose_log "Returning to previous directory"
  cd - > /dev/null
else
  echo "✓"
  verbose_log "Found iPhoneOS metallib: $METALLIB_FILE"
  verbose_log "Found simulator metallib: $SIM_METALLIB_FILE"
fi

t0=$(date +%s)

rm -rf build-ios
mkdir -p build-ios

# Build iOS frameworks
build_framework "iOS" "arm64;x86_64" "iphonesimulator" "ios-arm64_x86_64-simulator" "build-ios"
build_framework "iOS" "arm64" "iphoneos" "ios-arm64" "build-ios"
rm -rf build-ios

# Skip tvOS build for now
# rm -rf build-tvos
# mkdir -p build-tvos

# Build tvOS frameworks
# build_framework "tvOS" "arm64;x86_64" "appletvsimulator" "tvos-arm64_x86_64-simulator" "build-tvos"
# build_framework "tvOS" "arm64" "appletvos" "tvos-arm64" "build-tvos"
# rm -rf build-tvos

# Execute based on command line options
if $COPY_ONLY; then
    # Only copy the framework to SDK
    copy_to_sdk
    exit 0
fi

if $BUILD_ONLY || $BUILD_AND_COPY; then
    # Build the framework
    t0=$(date +%s)
    
    rm -rf build-ios
    mkdir -p build-ios
    
    # Build iOS frameworks
    build_framework "iOS" "arm64;x86_64" "iphonesimulator" "ios-arm64_x86_64-simulator" "build-ios"
    build_framework "iOS" "arm64" "iphoneos" "ios-arm64" "build-ios"
    rm -rf build-ios
    
    # Skip tvOS build for now
    # rm -rf build-tvos
    # mkdir -p build-tvos
    
    # Build tvOS frameworks
    # build_framework "tvOS" "arm64;x86_64" "appletvsimulator" "tvos-arm64_x86_64-simulator" "build-tvos"
    # build_framework "tvOS" "arm64" "appletvos" "tvos-arm64" "build-tvos"
    # rm -rf build-tvos
    
    t1=$(date +%s)
    echo "Build completed successfully!"
    echo "Total time: $((t1 - t0)) seconds"
    echo "xcframework is available at: $ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework"
    echo "The project is configured to use this xcframework directly via absolute path reference."
fi

# If build-and-copy option was selected, copy the framework to SDK
if $BUILD_AND_COPY; then
    copy_to_sdk
fi

if [ $BUILD_ONLY = false ] && [ $COPY_ONLY = false ] && [ $BUILD_AND_COPY = false ]; then
    # Default: build only
    echo "No action specified, defaulting to --build-only"
    exit 0
fi
