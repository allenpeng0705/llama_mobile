#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if ! command -v cmake &> /dev/null; then
  echo "cmake could not be found, please install it"
  exit 1
fi

function cp_headers() {
  mkdir -p "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$1/llama_mobile.framework/Headers"
  # Only copy the public API header, not all internal headers
  cp "$ROOT_DIR/lib/llama_mobile_api.h" "$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$1/llama_mobile.framework/Headers/"
}

function build_framework() {
  # Parameters:
  # $1: system_name (iOS/tvOS)
  # $2: architectures
  # $3: sysroot
  # $4: output_path
  # $5: build_dir

  cd "$5"

  # Configure CMake
  cmake "$ROOT_DIR/llama_mobile-ios" \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=$1 \
    -DCMAKE_OSX_ARCHITECTURES="$2" \
    -DCMAKE_OSX_SYSROOT=$3 \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DCMAKE_IOS_INSTALL_COMBINED=YES

  # Build
  cmake --build . --config Release -j $(sysctl -n hw.logicalcpu)

  # Setup framework directory
  DEST_DIR="$ROOT_DIR/llama_mobile-ios/llama_mobile.xcframework/$4"
  FRAMEWORK_SRC="Release-$3/llama_mobile.framework"
  FRAMEWORK_DEST="$DEST_DIR/llama_mobile.framework"

  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"

  # Copy the built framework to the destination
  if [ -d "$FRAMEWORK_SRC" ]; then
    cp -R "$FRAMEWORK_SRC" "$FRAMEWORK_DEST"
  else
    echo "Error: Expected framework not found at $FRAMEWORK_SRC"
    exit 1
  fi

  mkdir -p "$FRAMEWORK_DEST/Headers"

  # Copy headers and metallib
  cp_headers $4
  if [[ "$4" == *"-simulator" ]]; then
    cp "$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib" "$FRAMEWORK_DEST/ggml-llama-sim.metallib"
  else
    cp "$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib" "$FRAMEWORK_DEST/ggml-llama.metallib"
  fi

  rm -rf ./*
  cd ..
}


# Check if Metal toolchain is available, download if needed
echo "Checking Metal toolchain availability..."
if ! xcrun --sdk iphoneos metal -v &> /dev/null; then
  echo "Metal toolchain not found. Downloading..."
  if xcodebuild -downloadComponent MetalToolchain; then
    echo "✓ Metal toolchain downloaded successfully"
  else
    echo "✗ Failed to download Metal toolchain. Please install it manually."
    exit 1
  fi
else
  echo "✓ Metal toolchain is already available"
fi

# Check if metallib files exist, generate if needed
echo "Checking for required metallib files..."
if [ ! -f "$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib" ] || [ ! -f "$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib" ]; then
  echo "Missing metallib files. Generating..."
  cd "$ROOT_DIR/lib/llama_cpp"
  
  # Generate iPhoneOS metallib
  if xcrun --sdk iphoneos metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 && xcrun --sdk iphoneos metallib ggml-metal.air -o ggml-llama.metallib; then
    rm ggml-metal.air
    echo "✓ iPhoneOS metallib generated"
  else
    echo "✗ Failed to generate iPhoneOS metallib"
    exit 1
  fi
  
  # Generate simulator metallib
  if xcrun --sdk iphonesimulator metal -c ggml-metal.metal -o ggml-metal.air -DGGML_METAL_USE_BF16=1 && xcrun --sdk iphonesimulator metallib ggml-metal.air -o ggml-llama-sim.metallib; then
    rm ggml-metal.air
    echo "✓ Simulator metallib generated"
  else
    echo "✗ Failed to generate simulator metallib"
    exit 1
  fi
  
  cd - > /dev/null
else
  echo "✓ Required metallib files already exist"
fi

t0=$(date +%s)

rm -rf build-ios
mkdir -p build-ios

# Build iOS frameworks
build_framework "iOS" "arm64;x86_64" "iphonesimulator" "ios-arm64_x86_64-simulator" "build-ios"
build_framework "iOS" "arm64" "iphoneos" "ios-arm64" "build-ios"
rm -rf build-ios

rm -rf build-tvos
mkdir -p build-tvos

# Build tvOS frameworks
build_framework "tvOS" "arm64;x86_64" "appletvsimulator" "tvos-arm64_x86_64-simulator" "build-tvos"
build_framework "tvOS" "arm64" "appletvos" "tvos-arm64" "build-tvos"
rm -rf build-tvos

t1=$(date +%s)
echo "Total time: $((t1 - t0)) seconds"
