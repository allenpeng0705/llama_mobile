#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile iOS framework and copies it to the Swift SDK."
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  --enable-kleidiai  Enable KleidiAI for ARM optimization (disabled by default)"
    exit 0
}

# Parse command line arguments
# ENABLE_KLEIDIAI="false"
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help 
            ;;
        # --enable-kleidiai)
        #     ENABLE_KLEIDIAI="true"
        #     shift
        #     ;;
        *) 
            echo "Unknown parameter: $1" ; show_help 
            ;;
    esac
done

if ! command -v cmake &> /dev/null; then
  echo "✗ cmake could not be found, please install it"
  exit 1
fi

# Function to copy framework to SDK
function copy_to_sdk() {
    echo "=== Updating llama_mobile iOS SDK with latest framework ==="

    # Check if necessary directories exist
    if [ ! -d "$ROOT_DIR/llama_mobile-ios" ]; then
        echo "✗ Error: llama_mobile-ios directory not found!"
        exit 1
    fi

    if [ ! -d "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework" ]; then
        echo "✗ Error: llama_mobile.xcframework not found in llama_mobile-ios directory!"
        echo "Please build the iOS framework first using: $0"
        exit 1
    fi

    # Create Frameworks directory if it doesn't exist
    echo -n "Creating Frameworks directory... "
    if mkdir -p "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks"; then
        echo "✓"
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
    else
        echo "✗"
        echo "Failed to copy framework to SDK"
        exit 1
    fi

    echo "✓ Framework update completed successfully!"
    echo "The latest llama_mobile.xcframework has been copied to llama_mobile-ios-SDK/Frameworks/"
}

function cp_headers() {
  # Create main directories
  HEADER_DIR="$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$1/llama_mobile.framework/Headers"
  
  if ! mkdir -p "$HEADER_DIR"; then
    echo "✗ Failed to create header directory: $HEADER_DIR"
    exit 1
  fi
  
  # Copy the public API headers
  for header in "llama_mobile_unified.h" "llama_mobile_ffi.h" "llama_mobile_api.h" "llama_mobile_mnn.h"; do
    if ! cp "$ROOT_DIR/lib/$header" "$HEADER_DIR/"; then
      echo "✗ Failed to copy header: $header"
      exit 1
    fi
  done

  # Recursively copy all llama_cpp headers while preserving folder structure
  LLAMA_CPP_HEADER_DIR="$HEADER_DIR/llama_cpp/"
  if ! rsync -av "$ROOT_DIR/lib/llama_cpp/" "$LLAMA_CPP_HEADER_DIR" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"; then
    echo "✗ Failed to copy llama_cpp headers"
    exit 1
  fi
  
  # Copy external library headers to the root Headers directory for proper <angled> include support
  
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
}

function build_framework() {
  # Parameters:
  # $1: system_name (iOS/tvOS)
  # $2: architectures
  # $3: sysroot
  # $4: output_path
  # $5: build_dir

  if ! cd "$5"; then
    echo "✗ Failed to change to build directory: $5"
    exit 1
  fi

  # Configure CMake
  echo -n "Configuring CMake for $4... "
  
  # Set KleidiAI option
  # KLEIDIAI_OPTION="-DMNN_KLEIDIAI=OFF"
  # if [ "$ENABLE_KLEIDIAI" = "true" ]; then
  #   KLEIDIAI_OPTION="-DMNN_KLEIDIAI=ON"
  # fi
  
  if ! cmake "$ROOT_DIR/llama_mobile-ios" \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=$1 \
    -DCMAKE_OSX_ARCHITECTURES="$2" \
    -DCMAKE_OSX_SYSROOT=$3 \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DCMAKE_IOS_INSTALL_COMBINED=YES \
    -DMNN_USE_NEON=OFF \
    -DMNN_USE_SSE=OFF; then
    echo "✗"
    echo "CMake configuration failed!"
    exit 1
  fi
  echo "✓"

  # Build
  echo -n "Building framework for $4... "
  NUM_CORES=$(sysctl -n hw.logicalcpu)
  
  if ! cmake --build . --config Release -j $NUM_CORES -v; then
    echo "✗"
    echo "Build failed!"
    exit 1
  fi
  echo "✓"

  # Setup framework directory
  DEST_DIR="$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$4"
  FRAMEWORK_SRC="Release-$3/llama_mobile.framework"
  FRAMEWORK_DEST="$DEST_DIR/llama_mobile.framework"

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

  # Code sign the framework
  echo -n "Signing the framework... "
  if codesign --force --deep --sign "Apple Development" "$FRAMEWORK_DEST"; then
    echo "✓"
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
fi

# Check if metallib files exist, generate if needed
echo -n "Checking for required metallib files... "
METALLIB_FILE="$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib"
SIM_METALLIB_FILE="$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib"

if [ ! -f "$METALLIB_FILE" ] || [ ! -f "$SIM_METALLIB_FILE" ]; then
  echo "✗"
  echo "Missing metallib files. Generating..."
  
  if ! cd "$ROOT_DIR/lib/llama_cpp"; then
    echo "✗ Failed to change to llama_cpp directory"
    exit 1
  fi
  
  # Generate iPhoneOS metallib with compatible Metal language version and deployment target
  echo -n "Generating iPhoneOS metallib... "
  METAL_COMMAND="xcrun --sdk iphoneos metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 -std=ios-metal2.3 -mtargetos=ios13.0"
  METALLIB_COMMAND="xcrun --sdk iphoneos metallib ggml-metal.air -o ggml-llama.metallib"
  
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
  
  if $SIM_METAL_COMMAND && $SIM_METALLIB_COMMAND; then
    rm ggml-metal.air
    echo "✓"
  else
    echo "✗"
    echo "Failed to generate simulator metallib"
    exit 1
  fi
  
  cd - > /dev/null
else
  echo "✓"
fi

t0=$(date +%s)

# Build the framework
# Clean existing xcframework to ensure we start fresh
rm -rf "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework"
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

# Fix Info.plist encoding issues
# Convert all Info.plist files in the xcframework to XML format (UTF-8 compatible)
echo -n "Fixing Info.plist encoding... "
find "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework" -name "*.plist" -exec plutil -convert xml1 {} \;
echo "✓"

# Copy the framework to SDK
copy_to_sdk

t1=$(date +%s)
echo "Complete!"
echo "Total time: $((t1 - t0)) seconds"
echo "xcframework is available at: $ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework"
echo "The project is configured to use this xcframework directly via absolute path reference."
