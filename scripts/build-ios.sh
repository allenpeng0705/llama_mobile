#!/bin/bash -e

# ============================================================================
# IOS BUILD VARIABLES
# These variables can be modified to customize the build process
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(IOS_BUILD_TYPE|IOS_SIMULATOR_ARCHES|IOS_DEVICE_ARCHES|XCODE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Local variables with defaults from centralized config
BUILD_TYPE=${IOS_BUILD_TYPE:-"Release"}          # Release or Debug build
SIMULATOR_ARCHES=${IOS_SIMULATOR_ARCHES:-"arm64 x86_64"} # Simulator architectures to build
DEVICE_ARCHES=${IOS_DEVICE_ARCHES:-"arm64"}          # Device architectures to build
ANDROID_PLATFORM="android-21"  # Minimum Android API level (for Android cross-compilation)

# Build behavior flags with defaults
NO_CLEAN=${NO_CLEAN:-false}                # Skip cleaning build directories
KEEP_BUILD=${KEEP_BUILD:-false}            # Keep intermediate build files
VERBOSE=${VERBOSE:-false}                  # Show verbose output

# Build paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
METAL_LIB_DIR="$ROOT_DIR/lib/llama_cpp"
OUTPUT_DIR="$ROOT_DIR/llama_mobile-ios-SDK"

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
if [ -z "$IOS_BUILD_TYPE" ]; then
    update_config_env "IOS_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$IOS_SIMULATOR_ARCHES" ]; then
    update_config_env "IOS_SIMULATOR_ARCHES" "$SIMULATOR_ARCHES"
fi

if [ -z "$IOS_DEVICE_ARCHES" ]; then
    update_config_env "IOS_DEVICE_ARCHES" "$DEVICE_ARCHES"
fi

if [ -z "$CMAKE_BUILD_TYPE" ]; then
    update_config_env "CMAKE_BUILD_TYPE" "$BUILD_TYPE"
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

# ============================================================================
# SCRIPT SETUP - DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
# ============================================================================

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Enhanced logging function
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
    
    echo -e "${color}[$(date '+%H:%M:%S')] [${level}] $message${NC}"
}

# Script progress function
script_progress() {
    log_message "[INFO] $1"
}

# Error handling function
handle_error() {
    local exit_code=$1
    local message="$2"
    log_message "[ERROR] $message"
    log_message "[ERROR] Build failed with exit code: $exit_code"
    exit $exit_code
}

# Show help message
show_help() {
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Builds the llama_mobile iOS framework as a standalone SDK."
    echo ""
    echo "Build variables can be configured in scripts/config.env:"
    echo "  - IOS_BUILD_TYPE: Release or Debug build"
    echo "  - IOS_SIMULATOR_ARCHES: Simulator architectures"
    echo "  - IOS_DEVICE_ARCHES: Device architectures"
    echo "  - XCODE_PATH: Path to Xcode application"
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  --build-type=TYPE  Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --verbose          Show verbose output"
    echo ""
    echo "Required Dependencies:"
    echo "  - Xcode with Command Line Tools"
    echo "  - CMake (version 3.16 or higher)"
    echo ""
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --build-type=*) BUILD_TYPE="${1#*=}" ;;
        --verbose) VERBOSE=true ;;
        *) log_message "[ERROR] Unknown parameter: $1" ; show_help ;;
    esac
    shift

done

# Check for required dependencies
script_progress "Checking for required dependencies..."

# Check CMake
if ! command -v cmake &> /dev/null; then
  handle_error 1 "cmake could not be found. Please install it using: brew install cmake"
fi
log_message "[SUCCESS] Found CMake"

# Check Xcode command line tools
if ! command -v xcodebuild &> /dev/null; then
  handle_error 1 "Xcode command line tools could not be found. Please install Xcode and run: xcode-select --install"
fi
log_message "[SUCCESS] Found Xcode command line tools"

# Detect Xcode path if not set in config
if [ -z "$XCODE_PATH" ]; then
  script_progress "Xcode path not set, trying to detect..."
  XCODE_PATH=$(xcode-select -print-path 2>/dev/null || echo "")
  if [ -n "$XCODE_PATH" ]; then
    log_message "[SUCCESS] Detected Xcode path: $XCODE_PATH"
  else
    log_message "[WARN] Could not detect Xcode path. Using system defaults."
  fi
fi

# Check xcrun
if ! command -v xcrun &> /dev/null; then
  handle_error 1 "xcrun could not be found. Please ensure Xcode is installed properly."
fi
log_message "[SUCCESS] Found xcrun"

# Check lipo
if ! command -v lipo &> /dev/null; then
  handle_error 1 "lipo could not be found. Please ensure Xcode is installed properly."
fi
log_message "[SUCCESS] Found lipo"

log_message "[SUCCESS] All required dependencies found"

function cp_headers() {
  # Parameters:
  # $1: framework variant (e.g., ios-arm64-simulator)
  
  # Create main directories
  HEADER_DIR="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/$1/llama_mobile.framework/Headers"
  
  script_progress "Copying headers to $HEADER_DIR..."
  
  if ! mkdir -p "$HEADER_DIR"; then
    handle_error 1 "Failed to create header directory: $HEADER_DIR"
  fi
  
  # Copy the public API headers
  for header in "llama_mobile_ffi.h" "llama_mobile_api.h"; do
    if ! cp "$ROOT_DIR/lib/$header" "$HEADER_DIR/"; then
      handle_error 1 "Failed to copy header: $header"
    fi
  done

  # Recursively copy all llama_cpp headers while preserving folder structure
  LLAMA_CPP_HEADER_DIR="$HEADER_DIR/llama_cpp/"
  if ! rsync -av "$ROOT_DIR/lib/llama_cpp/" "$LLAMA_CPP_HEADER_DIR" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"; then
    handle_error 1 "Failed to copy llama_cpp headers"
  fi
  
  # Copy external library headers to the root Headers directory for proper <angled> include support
  
  # nlohmann headers
  NLOHMANN_DIR="$HEADER_DIR/nlohmann/"
  if ! mkdir -p "$NLOHMANN_DIR"; then
    handle_error 1 "Failed to create nlohmann directory"
  fi
  if ! cp "$ROOT_DIR/lib/llama_cpp/nlohmann"/*.hpp "$NLOHMANN_DIR"; then
    handle_error 1 "Failed to copy nlohmann headers"
  fi
  
  # minja headers
  MINJA_DIR="$HEADER_DIR/minja/"
  if ! mkdir -p "$MINJA_DIR"; then
    handle_error 1 "Failed to create minja directory"
  fi
  if ! cp "$ROOT_DIR/lib/llama_cpp/minja"/*.hpp "$MINJA_DIR"; then
    handle_error 1 "Failed to copy minja headers"
  fi
  
  log_message "[SUCCESS] Headers copied successfully"
}

function build_framework() {
  # Parameters:
  # $1: system_name (iOS/tvOS)
  # $2: architectures
  # $3: sysroot
  # $4: output_path
  # $5: build_dir

  if ! cd "$5"; then
    handle_error 1 "Failed to change to build directory: $5"
  fi

  # Configure CMake
  script_progress "Configuring CMake for $4..."
  
  if ! cmake "$ROOT_DIR/llama_mobile-ios-SDK" \
    -GXcode \
    -DCMAKE_SYSTEM_NAME=$1 \
    -DCMAKE_OSX_ARCHITECTURES="$2" \
    -DCMAKE_OSX_SYSROOT=$3 \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
    -DCMAKE_IOS_INSTALL_COMBINED=YES; then
    handle_error 1 "CMake configuration failed for $4!"
  fi
  log_message "[SUCCESS] CMake configuration completed for $4"

  # Build
  script_progress "Building framework for $4..."
  
  if ! cmake --build . --config $BUILD_TYPE -j $NUM_CORES; then
    handle_error 1 "Build failed for $4!"
  fi
  log_message "[SUCCESS] Framework built successfully for $4"

  # Setup framework directory
  DEST_DIR="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/$4"
  FRAMEWORK_SRC="$BUILD_TYPE-$3/llama_mobile.framework"
  FRAMEWORK_DEST="$DEST_DIR/llama_mobile.framework"

  script_progress "Preparing destination directory..."
  if ! rm -rf "$DEST_DIR" || ! mkdir -p "$DEST_DIR"; then
    handle_error 1 "Failed to prepare destination directory: $DEST_DIR"
  fi
  log_message "[SUCCESS] Destination directory prepared: $DEST_DIR"

  # Copy the built framework to the destination
  script_progress "Copying built framework..."
  if [ -d "$FRAMEWORK_SRC" ]; then
    if ! cp -R "$FRAMEWORK_SRC" "$FRAMEWORK_DEST"; then
      handle_error 1 "Failed to copy framework from $FRAMEWORK_SRC to $FRAMEWORK_DEST"
    fi
    log_message "[SUCCESS] Framework copied successfully"
  else
    handle_error 1 "Expected framework not found at $FRAMEWORK_SRC"
  fi

  # Copy headers and metallib
  cp_headers $4

  script_progress "Copying metallib file..."
  if [[ "$4" == *"-simulator" ]]; then
    METALLIB_SRC="$ROOT_DIR/lib/llama_cpp/ggml-llama-sim.metallib"
    METALLIB_DEST="$FRAMEWORK_DEST/ggml-llama-sim.metallib"
  else
    METALLIB_SRC="$ROOT_DIR/lib/llama_cpp/ggml-llama.metallib"
    METALLIB_DEST="$FRAMEWORK_DEST/ggml-llama.metallib"
  fi
  
  if ! cp "$METALLIB_SRC" "$METALLIB_DEST"; then
    handle_error 1 "Failed to copy metallib file from $METALLIB_SRC to $METALLIB_DEST"
  fi
  log_message "[SUCCESS] Metallib file copied successfully"
  
  # Copy grammar files
  script_progress "Copying grammar files..."
  GRAMMAR_SRC_DIR="$ROOT_DIR/lib/grammars"
  GRAMMAR_DEST_DIR="$FRAMEWORK_DEST/grammars"
  
  if ! mkdir -p "$GRAMMAR_DEST_DIR"; then
    handle_error 1 "Failed to create grammar directory: $GRAMMAR_DEST_DIR"
  fi
  
  if ! cp "$GRAMMAR_SRC_DIR"/*.gbnf "$GRAMMAR_DEST_DIR/"; then
    handle_error 1 "Failed to copy grammar files from $GRAMMAR_SRC_DIR to $GRAMMAR_DEST_DIR"
  fi
  log_message "[SUCCESS] Grammar files copied successfully"
  
  # Create Modules directory with module map
  script_progress "Creating module map..."
  MODULE_DIR="$FRAMEWORK_DEST/Modules"
  if ! mkdir -p "$MODULE_DIR"; then
    handle_error 1 "Failed to create Modules directory: $MODULE_DIR"
  fi
  
  MODULE_MAP="$MODULE_DIR/module.modulemap"
  cat > "$MODULE_MAP" << EOL
framework module llama_mobile {
    umbrella header "llama_mobile_api.h"
    
    export *
    module * { export * }
}
EOL
  
  if [ $? -ne 0 ]; then
    handle_error 1 "Failed to create module map: $MODULE_MAP"
  fi
  log_message "[SUCCESS] Module map created successfully"

  # Code sign the framework
  script_progress "Signing the framework..."
  if codesign --force --deep --sign "Apple Development" "$FRAMEWORK_DEST"; then
    log_message "[SUCCESS] Framework signed successfully"
  else
    log_message "[WARN] Framework signing failed. Manual signing may be required."
    log_message "[WARN] Try running: codesign --force --deep --sign 'Apple Development' '$FRAMEWORK_DEST'"
  fi

  if ! cd ..; then
    handle_error 1 "Failed to change back to parent directory"
  fi
  
  script_progress "Cleaning up build directory..."
  if ! rm -rf "$5"; then
    log_message "[WARN] Failed to clean up build directory: $5"
    log_message "[WARN] You may need to delete it manually."
  else
    log_message "[SUCCESS] Build directory cleaned up: $5"
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
rm -rf "$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework"

# Build iOS simulator framework - build each architecture separately then combine
# Build arm64 simulator
rm -rf "$ROOT_DIR/build-ios-simulator-arm64"
mkdir -p "$ROOT_DIR/build-ios-simulator-arm64"
build_framework "iOS" "arm64" "iphonesimulator" "ios-arm64-simulator" "$ROOT_DIR/build-ios-simulator-arm64"

# Build x86_64 simulator
rm -rf "$ROOT_DIR/build-ios-simulator-x86_64"
mkdir -p "$ROOT_DIR/build-ios-simulator-x86_64"
build_framework "iOS" "x86_64" "iphonesimulator" "ios-x86_64-simulator" "$ROOT_DIR/build-ios-simulator-x86_64"

# Combine the two simulator architectures into one
SIMULATOR_ARM64_FRAMEWORK="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/ios-arm64-simulator/llama_mobile.framework"
SIMULATOR_X86_64_FRAMEWORK="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/ios-x86_64-simulator/llama_mobile.framework"
SIMULATOR_COMBINED_DIR="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/ios-arm64_x86_64-simulator"
SIMULATOR_COMBINED_FRAMEWORK="$SIMULATOR_COMBINED_DIR/llama_mobile.framework"

# Create combined directory
rm -rf "$SIMULATOR_COMBINED_DIR"
mkdir -p "$SIMULATOR_COMBINED_DIR"
cp -R "$SIMULATOR_ARM64_FRAMEWORK" "$SIMULATOR_COMBINED_FRAMEWORK"

# Use lipo to combine the binary files
LIPO="$(xcrun -find lipo)"
"$LIPO" -create "$SIMULATOR_ARM64_FRAMEWORK/llama_mobile" "$SIMULATOR_X86_64_FRAMEWORK/llama_mobile" -output "$SIMULATOR_COMBINED_FRAMEWORK/llama_mobile"

# Clean up individual architecture directories
rm -rf "$ROOT_DIR/build-ios-simulator-arm64"
rm -rf "$ROOT_DIR/build-ios-simulator-x86_64"

# Remove individual simulator framework directories
rm -rf "$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/ios-arm64-simulator"
rm -rf "$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework/ios-x86_64-simulator"

# Build iOS device framework
rm -rf "$ROOT_DIR/build-ios-device"
mkdir -p "$ROOT_DIR/build-ios-device"
build_framework "iOS" "arm64" "iphoneos" "ios-arm64" "$ROOT_DIR/build-ios-device"
rm -rf "$ROOT_DIR/build-ios-device"

# Skip tvOS build for now
# rm -rf build-tvos
# mkdir -p build-tvos

# Build tvOS frameworks
# build_framework "tvOS" "arm64;x86_64" "appletvsimulator" "tvos-arm64_x86_64-simulator" "build-tvos"
# build_framework "tvOS" "arm64" "appletvos" "tvos-arm64" "build-tvos"
# rm -rf build-tvos

# Create XCFramework using xcodebuild
XCFRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework"
SIMULATOR_FRAMEWORK="$XCFRAMEWORK_DIR/ios-arm64_x86_64-simulator/llama_mobile.framework"
DEVICE_FRAMEWORK="$XCFRAMEWORK_DIR/ios-arm64/llama_mobile.framework"

# Fix Info.plist encoding issues
# Convert all Info.plist files in the xcframework to XML format (UTF-8 compatible)
echo -n "Fixing Info.plist encoding... "
find "$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework" -name "*.plist" -exec plutil -convert xml1 {} \;
echo "✓"

# Remove UIRequiredDeviceCapabilities from simulator Info.plist files to fix build issues
echo -n "Fixing simulator UIRequiredDeviceCapabilities... "
SIMULATOR_INFO_PLISTS=$(find "$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework" -path "*simulator*" -name "Info.plist")
for plist in $SIMULATOR_INFO_PLISTS; do
  /usr/libexec/PlistBuddy -c "Delete :UIRequiredDeviceCapabilities" "$plist" 2>/dev/null || true
done
echo "✓"

# Use xcodebuild to create XCFramework
# First, clean up the existing XCFramework structure but keep the frameworks
echo -n "Recreating XCFramework with proper Info.plist... "
TEMP_XCFRAMEWORK="$ROOT_DIR/llama_mobile-ios-SDK/llama_mobile_temp.xcframework"

xcodebuild -create-xcframework \
  -framework "$SIMULATOR_FRAMEWORK" \
  -framework "$DEVICE_FRAMEWORK" \
  -output "$TEMP_XCFRAMEWORK"

# Replace the old XCFramework with the new one
if [ -d "$TEMP_XCFRAMEWORK" ]; then
  rm -rf "$XCFRAMEWORK_DIR"
  mv "$TEMP_XCFRAMEWORK" "$XCFRAMEWORK_DIR"
  echo "✓"
else
  echo "✗"
  echo "Warning: Failed to recreate XCFramework with xcodebuild, keeping manually created structure"
fi



t1=$(date +%s)
echo "Complete!"
echo "Total time: $((t1 - t0)) seconds"
echo "xcframework is available at: $ROOT_DIR/llama_mobile-ios-SDK/llama_mobile.xcframework"
echo ""
echo "=== LlamaMobile iOS SDK is ready to use! ==="
echo "- Add as Swift Package: Drag llama_mobile-ios-SDK directory to your Xcode project"
echo "- Or use Swift Package Manager: Open Package.swift in Xcode"
echo "- Or manually copy llama_mobile.xcframework to your project"
