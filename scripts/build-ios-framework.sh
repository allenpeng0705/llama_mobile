#!/bin/bash -e

# ============================================================================
# IOS NATIVE FRAMEWORK BUILD SCRIPT
# Builds low-level iOS framework (no Swift bindings)
# Output: llama_mobile/llama_mobile-ios
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    export $(grep -E '^(IOS_BUILD_TYPE|IOS_SIMULATOR_ARCHES|IOS_DEVICE_ARCHES|XCODE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Variables with defaults
BUILD_TYPE=${IOS_BUILD_TYPE:-"Release"}          # Release or Debug build
SIMULATOR_ARCHES=${IOS_SIMULATOR_ARCHES:-"arm64 x86_64"} # Simulator architectures
DEVICE_ARCHES=${IOS_DEVICE_ARCHES:-"arm64"}          # Device architectures
XCODE_PATH=${XCODE_PATH:-""}                     # Path to Xcode application

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
if [ -z "$IOS_BUILD_TYPE" ]; then
    update_config_env "IOS_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$IOS_SIMULATOR_ARCHES" ]; then
    update_config_env "IOS_SIMULATOR_ARCHES" "$SIMULATOR_ARCHES"
fi

if [ -z "$IOS_DEVICE_ARCHES" ]; then
    update_config_env "IOS_DEVICE_ARCHES" "$DEVICE_ARCHES"
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
    
    echo -e "${color}[$(date '+%H:%M:%S')] [${level}] $message${NC}"
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
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Builds low-level llama_mobile iOS framework (no Swift bindings)."
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  --build-type=TYPE  Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --debug            Build with Debug configuration (same as --build-type=Debug)"
    echo "  --static           Build only static library framework"
    echo "  --shared           Build only shared library framework"
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
        --debug) BUILD_TYPE="Debug" ;;
        --verbose) VERBOSE=true ;;
        *) log_message "[ERROR] Unknown parameter: $1" ; show_help ;;
    esac
    shift

done

# ============================================================================
# DEPENDENCY CHECKING
# ============================================================================

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
    # Update config.env with detected Xcode path
    update_config_env "XCODE_PATH" "$XCODE_PATH"
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

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Main output directory (llama_mobile-ios at root)
MAIN_OUTPUT_DIR="$ROOT_DIR/llama_mobile-ios"

# Static and shared directories (self-contained)
STATIC_OUTPUT_DIR="$MAIN_OUTPUT_DIR/static"
SHARED_OUTPUT_DIR="$MAIN_OUTPUT_DIR/shared"

# Include directories (each library type has its own)
STATIC_INCLUDE_DIR="$STATIC_OUTPUT_DIR/include"
SHARED_INCLUDE_DIR="$SHARED_OUTPUT_DIR/include"

# Library output directories
STATIC_LIBS_DIR="$STATIC_OUTPUT_DIR/libs"
SHARED_XCFRAMEWORK_PATH="$SHARED_OUTPUT_DIR/llama_mobile.xcframework"

FRAMEWORK_NAME="llama_mobile"

log_message "[INFO] === Building llama_mobile iOS Native Framework ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Simulator architectures: $SIMULATOR_ARCHES"
log_message "[INFO] Device architectures: $DEVICE_ARCHES"
log_message "[INFO] Output directory: $MAIN_OUTPUT_DIR"
log_message "[INFO] Static libraries: $STATIC_LIBS_DIR"
log_message "[INFO] Shared XCFramework: $SHARED_XCFRAMEWORK_PATH"
log_message "[INFO] Static libs: $STATIC_LIBS_DIR"
log_message "[INFO] Shared XCFramework: $SHARED_XCFRAMEWORK_PATH"

# Check dependencies
script_progress "Checking dependencies..."

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

# Save persistent files if they exist
README_PATH="$MAIN_OUTPUT_DIR/README.md"
README_BACKUP="$ROOT_DIR/temp-README.md"

STATIC_CMAKE_PATH="$STATIC_OUTPUT_DIR/CMakeLists.txt"
STATIC_CMAKE_BACKUP="$ROOT_DIR/temp-static-CMakeLists.txt"

SHARED_CMAKE_PATH="$SHARED_OUTPUT_DIR/CMakeLists.txt"
SHARED_CMAKE_BACKUP="$ROOT_DIR/temp-shared-CMakeLists.txt"

# Save README.md
if [ -f "$README_PATH" ]; then
    log_message "[INFO] Saving existing README.md"
    cp "$README_PATH" "$README_BACKUP"
fi

# Save static CMakeLists.txt
if [ -f "$STATIC_CMAKE_PATH" ]; then
    log_message "[INFO] Saving existing static CMakeLists.txt"
    cp "$STATIC_CMAKE_PATH" "$STATIC_CMAKE_BACKUP"
fi

# Save shared CMakeLists.txt
if [ -f "$SHARED_CMAKE_PATH" ]; then
    log_message "[INFO] Saving existing shared CMakeLists.txt"
    cp "$SHARED_CMAKE_PATH" "$SHARED_CMAKE_BACKUP"
fi

# Clean output directory
script_progress "Cleaning output directory..."
rm -rf "$MAIN_OUTPUT_DIR"

# Create static library directories
mkdir -p "$STATIC_LIBS_DIR"
mkdir -p "$STATIC_INCLUDE_DIR"

# Create shared library directories
mkdir -p "$SHARED_OUTPUT_DIR"

# Restore README.md
if [ -f "$README_BACKUP" ]; then
    log_message "[INFO] Restoring README.md"
    cp "$README_BACKUP" "$README_PATH"
    rm "$README_BACKUP"
fi

# Restore static CMakeLists.txt
if [ -f "$STATIC_CMAKE_BACKUP" ]; then
    log_message "[INFO] Restoring static CMakeLists.txt"
    cp "$STATIC_CMAKE_BACKUP" "$STATIC_CMAKE_PATH"
    rm "$STATIC_CMAKE_BACKUP"
fi

# Restore shared CMakeLists.txt
if [ -f "$SHARED_CMAKE_BACKUP" ]; then
    log_message "[INFO] Restoring shared CMakeLists.txt"
    cp "$SHARED_CMAKE_BACKUP" "$SHARED_CMAKE_PATH"
    rm "$SHARED_CMAKE_BACKUP"
fi

log_message "[SUCCESS] Output directory cleaned and created"

# Build function for a specific target
build_target() {
    local SYSTEM_NAME="$1"
    local ARCHES="$2"
    local SYSROOT="$3"
    local OUTPUT_SUBDIR="$4"
    local BUILD_DIR_BASE="$5"
    
    # Build static library
    build_library "$SYSTEM_NAME" "$ARCHES" "$SYSROOT" "$OUTPUT_SUBDIR" "$BUILD_DIR_BASE-static" "static"
    
    # Build shared library (framework)
    build_shared_framework "$SYSTEM_NAME" "$ARCHES" "$SYSROOT" "$OUTPUT_SUBDIR" "$BUILD_DIR_BASE-shared"
}

# Build function for a specific library type
build_library() {
    local SYSTEM_NAME="$1"
    local ARCHES="$2"
    local SYSROOT="$3"
    local OUTPUT_SUBDIR="$4"
    local BUILD_DIR="$5"
    local LIB_TYPE="$6"
    
    script_progress "Building $LIB_TYPE library for $OUTPUT_SUBDIR..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure CMake for iOS with Xcode project
    cmake "$ROOT_DIR/lib" \
        -GXcode \
        -DCMAKE_SYSTEM_NAME="$SYSTEM_NAME" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHES" \
        -DCMAKE_OSX_SYSROOT="$SYSROOT" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
        -DCMAKE_IOS_INSTALL_COMBINED=YES \
        -DCMAKE_XCODE_ATTRIBUTE_SDKROOT="$SYSROOT" \
        -DCMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET="17.0" \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH="NO" \
        -DLLAMA_USE_CURL=OFF \
        -DLLAMA_USE_HTTPLIB=OFF
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "CMake configuration failed for $LIB_TYPE library $OUTPUT_SUBDIR!"
    fi
    
    # Build the static library target
    cmake --build . --config "$BUILD_TYPE" --target llama_mobile_core_static -j $(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "Static library build failed for $OUTPUT_SUBDIR!"
    fi
    
    # Find the static library
    local LIB_PATH=$(find "$BUILD_DIR" -name "libllama_mobile_core*.a" | head -1)
    if [[ -z "$LIB_PATH" ]]; then
        handle_error 1 "Could not find the built static library!"
    fi
    
    # Copy the static library
    local STATIC_DEST_DIR="$STATIC_LIBS_DIR/$OUTPUT_SUBDIR"
    local STATIC_DEST_LIB="$STATIC_DEST_DIR/libllama_mobile.a"
    mkdir -p "$STATIC_DEST_DIR"
    cp "$LIB_PATH" "$STATIC_DEST_LIB"
    log_message "[SUCCESS] Built static library: $STATIC_DEST_LIB"
    
    # Clean up
    cd "$ROOT_DIR"
    rm -rf "$BUILD_DIR"
    
    log_message "[SUCCESS] Built static library for $OUTPUT_SUBDIR"
}

# Build function for shared framework
build_shared_framework() {
    local SYSTEM_NAME="$1"
    local ARCHES="$2"
    local SYSROOT="$3"
    local OUTPUT_SUBDIR="$4"
    local BUILD_DIR="$5"
    
    script_progress "Building shared framework for $OUTPUT_SUBDIR..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Create temporary framework output directory
    local TEMP_FRAMEWORK_DIR="$ROOT_DIR/temp-frameworks/$OUTPUT_SUBDIR"
    mkdir -p "$TEMP_FRAMEWORK_DIR"
    
    # Configure CMake for iOS with Xcode project
    cmake "$ROOT_DIR/lib" \
        -GXcode \
        -DCMAKE_SYSTEM_NAME="$SYSTEM_NAME" \
        -DCMAKE_OSX_ARCHITECTURES="$ARCHES" \
        -DCMAKE_OSX_SYSROOT="$SYSROOT" \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO \
        -DCMAKE_IOS_INSTALL_COMBINED=YES \
        -DCMAKE_XCODE_ATTRIBUTE_SDKROOT="$SYSROOT" \
        -DCMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET="17.0" \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH="NO"
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "CMake configuration failed for shared framework $OUTPUT_SUBDIR!"
    fi
    
    # Build the static library target (we'll create framework from this)
    cmake --build . --config "$BUILD_TYPE" --target llama_mobile_core_static -j $(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "Shared framework build failed for $OUTPUT_SUBDIR!"
    fi
    
    # Find the static library
    local LIB_PATH=$(find "$BUILD_DIR" -name "libllama_mobile_core*.a" | head -1)
    if [[ -z "$LIB_PATH" ]]; then
        handle_error 1 "Could not find the built library for framework!"
    fi
    
    # Create framework structure
    local DEST_PATH="$TEMP_FRAMEWORK_DIR/$FRAMEWORK_NAME.framework"
    mkdir -p "$DEST_PATH/Headers"
    
    # Copy the library and rename it to match framework expectations
    cp "$LIB_PATH" "$DEST_PATH/$FRAMEWORK_NAME"
    
    # Copy headers
    cp "$ROOT_DIR/lib/llama_mobile_api.h" "$DEST_PATH/Headers/"
    cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$DEST_PATH/Headers/"
    
    # Copy all llama_cpp headers recursively
    mkdir -p "$DEST_PATH/Headers/llama_cpp"
    rsync -av "$ROOT_DIR/lib/llama_cpp/" "$DEST_PATH/Headers/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"
    
    # Copy Metal files
    if [[ -f "$ROOT_DIR/lib/llama_cpp/ggml-metal.metal" ]]; then
        cp "$ROOT_DIR/lib/llama_cpp/ggml-metal.metal" "$DEST_PATH/"
    fi
    
    # Compile Metal files into metallib
    if [[ -f "$DEST_PATH/ggml-metal.metal" && -x "$(which xcrun)" && -f "$DEST_PATH/Headers/llama_cpp/ggml-common.h" ]]; then
        # Copy necessary headers for Metal compilation
        cp "$DEST_PATH/Headers/llama_cpp/ggml-common.h" "$DEST_PATH/"
        cp "$DEST_PATH/Headers/llama_cpp/ggml-metal-impl.h" "$DEST_PATH/"
        
        # Get the correct SDK path based on target
        if [[ "$OUTPUT_SUBDIR" == *"simulator"* ]]; then
            METAL_SDK="iphonesimulator"
        else
            METAL_SDK="iphoneos"
        fi
        
        # Compile device-specific metallib with proper include paths
        cd "$DEST_PATH"
        xcrun -sdk $METAL_SDK metal -I. -std=metal3.1 -mios-version-min=17.0 ggml-metal.metal -o ggml-llama.metallib 2>/dev/null || true
        
        # Clean up copied headers
        rm -f "$DEST_PATH/ggml-common.h" "$DEST_PATH/ggml-metal-impl.h"
    fi
    
    # Check for compiled metallib files in build directory as fallback
    METAL_DIR="$BUILD_DIR"
    if [[ -d "$METAL_DIR" ]]; then
        # Copy any metallib files found
        find "$METAL_DIR" -name "*.metallib" -exec cp {} "$DEST_PATH/" \; 2>/dev/null || true
    fi
    
    # Create Modules directory and module.modulemap
    mkdir -p "$DEST_PATH/Modules"
    cat > "$DEST_PATH/Modules/module.modulemap" << EOF
framework module llama_mobile {
    umbrella header "llama_mobile_api.h"
    
    export *
    module * { export * }
    
    link "llama_mobile"
}
EOF
    
    # Create Info.plist for the framework
    cat > "$DEST_PATH/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.llamamobile</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
    <key>UIDeviceFamily</key>
    <array>
        <integer>1</integer>
        <integer>2</integer>
    </array>
</dict>
</plist>
EOF
    
    # Clean up
    cd "$ROOT_DIR"
    rm -rf "$BUILD_DIR"
    
    log_message "[SUCCESS] Built shared framework: $DEST_PATH"
}

# Build simulator variants
for ARCH in $SIMULATOR_ARCHES; do
    build_target "iOS" "$ARCH" "iphonesimulator" "ios-${ARCH}-simulator" "$ROOT_DIR/build-ios-simulator-${ARCH}"
done

# Build device variants
for ARCH in $DEVICE_ARCHES; do
    build_target "iOS" "$ARCH" "iphoneos" "ios-${ARCH}" "$ROOT_DIR/build-ios-device-${ARCH}"
done

# Combine simulator architectures if needed
if [[ $(echo $SIMULATOR_ARCHES | wc -w) -gt 1 ]]; then
    script_progress "Combining simulator architectures for shared framework..."
    
    # Create combined simulator directory
    COMBINED_SIM_DIR="$ROOT_DIR/temp-frameworks/ios-$(echo $SIMULATOR_ARCHES | tr ' ' '_')-simulator"
    mkdir -p "$COMBINED_SIM_DIR"
    
    # Copy first simulator framework as base
    FIRST_SIM_ARCH=$(echo $SIMULATOR_ARCHES | awk '{print $1}')
    cp -R "$ROOT_DIR/temp-frameworks/ios-${FIRST_SIM_ARCH}-simulator/$FRAMEWORK_NAME.framework" "$COMBINED_SIM_DIR/"
    
    # Combine binary files
    SIM_BINARIES=()
    for ARCH in $SIMULATOR_ARCHES; do
        SIM_BINARIES+=("$ROOT_DIR/temp-frameworks/ios-${ARCH}-simulator/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME")
    done
    
    lipo -create "${SIM_BINARIES[@]}" -output "$COMBINED_SIM_DIR/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"
    
    # Clean up individual simulator directories
    for ARCH in $SIMULATOR_ARCHES; do
        rm -rf "$ROOT_DIR/temp-frameworks/ios-${ARCH}-simulator"
    done
    
    log_message "[SUCCESS] Combined simulator architectures for shared framework"
fi

# Create XCFramework using xcodebuild
script_progress "Creating final XCFramework..."

# Get all framework paths
FRAMEWORK_PATHS=()
for DIR in "$ROOT_DIR/temp-frameworks"/*; do
    if [[ -d "$DIR" && -d "$DIR/$FRAMEWORK_NAME.framework" ]]; then
        FRAMEWORK_PATHS+=("-framework" "$DIR/$FRAMEWORK_NAME.framework")
    fi
done

# Use xcodebuild to create proper XCFramework
rm -rf "$SHARED_XCFRAMEWORK_PATH"
xcodebuild -create-xcframework "${FRAMEWORK_PATHS[@]}" -output "$SHARED_XCFRAMEWORK_PATH"

# Clean up temporary frameworks
rm -rf "$ROOT_DIR/temp-frameworks"

# Recreate include directory for static library (shared has everything in xcframework)
mkdir -p "$STATIC_INCLUDE_DIR"

# Fix Info.plist encoding
log_message "[INFO] Fixing Info.plist encoding..."
find "$SHARED_XCFRAMEWORK_PATH" -name "*.plist" -exec plutil -convert xml1 {} \;

# Add RequiredFrameworks and RequiredLibraries to XCFramework Info.plist
log_message "[INFO] Adding required dependencies to XCFramework Info.plist..."
XCFRAMEWORK_INFO_PLIST="$SHARED_XCFRAMEWORK_PATH/Info.plist"

# Get the number of AvailableLibraries entries
LIBRARY_COUNT=$(/usr/libexec/PlistBuddy -c "Print :AvailableLibraries:" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null | grep -c "Dict")

if [[ $LIBRARY_COUNT -gt 0 ]]; then
    for ((INDEX=0; INDEX<LIBRARY_COUNT; INDEX++)); do
        # Add RequiredFrameworks
        /usr/libexec/PlistBuddy -c "Add :AvailableLibraries:$INDEX:RequiredFrameworks array" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :AvailableLibraries:$INDEX:RequiredFrameworks:0 string 'Accelerate'" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :AvailableLibraries:$INDEX:RequiredFrameworks:1 string 'Metal'" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null || true
        
        # Add RequiredLibraries
        /usr/libexec/PlistBuddy -c "Add :AvailableLibraries:$INDEX:RequiredLibraries array" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null || true
        /usr/libexec/PlistBuddy -c "Add :AvailableLibraries:$INDEX:RequiredLibraries:0 string 'libc++'" "$XCFRAMEWORK_INFO_PLIST" 2>/dev/null || true
    done
    log_message "[INFO] Added dependencies to $LIBRARY_COUNT library variants"
else
    log_message "[WARN] No AvailableLibraries found in XCFramework Info.plist"
fi

log_message "[INFO] Added Accelerate framework and libc++ as required dependencies"

# Copy header files to include directories
script_progress "Copying header files..."

# Copy headers to static include directory
cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$STATIC_INCLUDE_DIR/"
cp "$ROOT_DIR/lib/llama_mobile_api.h" "$STATIC_INCLUDE_DIR/"
mkdir -p "$STATIC_INCLUDE_DIR/llama_cpp"
rsync -av "$ROOT_DIR/lib/llama_cpp/" "$STATIC_INCLUDE_DIR/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"

log_message "[SUCCESS] Header files copied"

# Create CMakeLists.txt for easy integration (only if they don't exist)
script_progress "Checking CMakeLists.txt files..."

# Create CMakeLists.txt for static library if it doesn't exist
if [ ! -f "$STATIC_OUTPUT_DIR/CMakeLists.txt" ]; then
    cat > "$STATIC_OUTPUT_DIR/CMakeLists.txt" << 'EOL'
cmake_minimum_required(VERSION 3.16)
project(llama_mobile_ios_static LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/llama_cpp
)

# Import the pre-built static libraries
set(LLAMA_MOBILE_ABIS arm64 x86_64)

foreach(ABI ${LLAMA_MOBILE_ABIS})
    add_library(llama_mobile_static_${ABI} STATIC IMPORTED)
    set_target_properties(llama_mobile_static_${ABI} PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/ios-${ABI}-simulator/libllama_mobile.a
        OSX_ARCHITECTURES ${ABI}
    )
endforeach()

# Main static library target for linking
add_library(llama_mobile_static STATIC IMPORTED)
set_target_properties(llama_mobile_static PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/ios-${CMAKE_OSX_ARCHITECTURES}-simulator/libllama_mobile.a
)
EOL
    log_message "[SUCCESS] CMakeLists.txt created for static library"
else
    log_message "[INFO] CMakeLists.txt already exists for static library, skipping generation"
fi

# Create CMakeLists.txt for shared library (xcframework) if it doesn't exist
if [ ! -f "$SHARED_OUTPUT_DIR/CMakeLists.txt" ]; then
    cat > "$SHARED_OUTPUT_DIR/CMakeLists.txt" << 'EOL'
cmake_minimum_required(VERSION 3.16)
project(llama_mobile_ios_shared LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CXX_STANDARD_REQUIRED ON)

# Add the xcframework - headers are included within the XCFramework bundle
set(XCFRAMEWORK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/llama_mobile.xcframework")

if(EXISTS "${XCFRAMEWORK_PATH}")
    # For iOS, add the xcframework
    if(IOS)
        add_library(llama_mobile SHARED IMPORTED)
        set_target_properties(llama_mobile PROPERTIES
            FRAMEWORK "${XCFRAMEWORK_PATH}"
            IMPORTED_LOCATION "${XCFRAMEWORK_PATH}/ios-arm64/llama_mobile.framework/llama_mobile"
        )
        target_link_libraries(llama_mobile INTERFACE
            "-framework Accelerate"
            "-framework Metal"
        )
    endif()
else()
    message(WARNING "XCFramework not found at ${XCFRAMEWORK_PATH}")
endif()
EOL
    log_message "[SUCCESS] CMakeLists.txt created for shared library"
else
    log_message "[INFO] CMakeLists.txt already exists for shared library, skipping generation"
fi

# Preserve README.md files if they exist
if [ -f "$MAIN_OUTPUT_DIR/README.md" ]; then
    log_message "[INFO] README.md already exists, preserving it"
fi

# Clean up any temporary build directories
script_progress "Cleaning up temporary build directories..."
rm -rf "$ROOT_DIR/build-ios-*"

# Verify the build
script_progress "Verifying build..."

# Check if static libraries were built
for ARCH in $SIMULATOR_ARCHES $DEVICE_ARCHES; do
    # Determine the correct subdirectory based on architecture type
    if [[ "$ARCH" == "x86_64" ]]; then
        SUB_DIR="ios-${ARCH}-simulator"
        # Check static library
        STATIC_LIB_PATH="$STATIC_LIBS_DIR/$SUB_DIR/libllama_mobile.a"
        if [ -f "$STATIC_LIB_PATH" ]; then
            log_message "[SUCCESS] Static library: $STATIC_LIB_PATH ($(ls -lh "$STATIC_LIB_PATH" | awk '{print $5}'))"
            log_message "[INFO]   Architecture: $(lipo -info "$STATIC_LIB_PATH" | grep -o "architecture.*" | cut -d ' ' -f 2-)"
        fi
    elif [[ "$ARCH" == "arm64" ]]; then
        # For arm64, check both simulator and device
        for SUB_DIR in "ios-${ARCH}-simulator" "ios-${ARCH}"; do
            # Check static library
            STATIC_LIB_PATH="$STATIC_LIBS_DIR/$SUB_DIR/libllama_mobile.a"
            if [ -f "$STATIC_LIB_PATH" ]; then
                log_message "[SUCCESS] Static library: $STATIC_LIB_PATH ($(ls -lh "$STATIC_LIB_PATH" | awk '{print $5}'))"
                log_message "[INFO]   Architecture: $(lipo -info "$STATIC_LIB_PATH" | grep -o "architecture.*" | cut -d ' ' -f 2-)"
            fi
        done
    else
        # For other architectures, just check the standard subdirectory
        SUB_DIR="ios-${ARCH}"
        # Check static library
        STATIC_LIB_PATH="$STATIC_LIBS_DIR/$SUB_DIR/libllama_mobile.a"
        if [ -f "$STATIC_LIB_PATH" ]; then
            log_message "[SUCCESS] Static library: $STATIC_LIB_PATH ($(ls -lh "$STATIC_LIB_PATH" | awk '{print $5}'))"
            log_message "[INFO]   Architecture: $(lipo -info "$STATIC_LIB_PATH" | grep -o "architecture.*" | cut -d ' ' -f 2-)"
        fi
    fi
done

# Check if xcframework was created
if [ -d "$SHARED_XCFRAMEWORK_PATH" ]; then
    log_message "[SUCCESS] XCFramework created at: $SHARED_XCFRAMEWORK_PATH"
    log_message "[INFO] Contains: $(ls -la "$SHARED_XCFRAMEWORK_PATH" | grep ^d | awk '{print $9}')"
    
    # Check framework contents
    for VARIANT in "$SHARED_XCFRAMEWORK_PATH"/*; do
        if [[ -d "$VARIANT" ]]; then
            FRAMEWORK="$VARIANT/$FRAMEWORK_NAME.framework"
            if [[ -f "$FRAMEWORK/$FRAMEWORK_NAME" ]]; then
                ARCHES=$(lipo -info "$FRAMEWORK/$FRAMEWORK_NAME" | grep -o "architecture.*" | cut -d ' ' -f 2-)
                log_message "[INFO] $(basename "$VARIANT"): $ARCHES"
                
                # Check for Metal files
                if [[ -f "$FRAMEWORK/ggml-llama.metallib" ]]; then
                    log_message "[INFO]   Metal library: ggml-llama.metallib ($(ls -lh "$FRAMEWORK/ggml-llama.metallib" | awk '{print $5}'))"
                fi
                
                # Check for headers
                if [[ -d "$FRAMEWORK/Headers" ]]; then
                    HEADER_COUNT=$(find "$FRAMEWORK/Headers" -type f \( -name "*.h" -o -name "*.hpp" \) | wc -l)
                    log_message "[INFO]   Headers: $HEADER_COUNT files"
                fi
            fi
        fi
    done
else
    log_message "[ERROR] XCFramework not found at expected location!"
fi

# Check header files
if [ -f "$STATIC_INCLUDE_DIR/llama_mobile_api.h" ]; then
    log_message "[SUCCESS] Static header files copied to: $STATIC_INCLUDE_DIR"
else
    log_message "[ERROR] Static header files not found!"
fi

# Note: Shared framework (XCFramework) contains all headers and resources internally
log_message "[INFO] Shared XCFramework contains headers and resources internally"

log_message "[SUCCESS] === Build completed successfully! ==="
log_message "[INFO] iOS native libraries are available at:"
log_message "[INFO] - Static Library: $STATIC_OUTPUT_DIR"
log_message "[INFO] - Shared Library (XCFramework): $SHARED_XCFRAMEWORK_PATH"
log_message ""
log_message "[INFO] These libraries contain no Swift bindings and can be used with:"
log_message "[INFO] - Flutter via FFI"
log_message "[INFO] - React Native via FFI"
log_message "[INFO] - Direct iOS integration"
log_message ""
log_message "[INFO] Static libraries (libllama_mobile.a) are self-contained"
log_message "[INFO] Shared library (llama_mobile.xcframework) includes:"
log_message "[INFO]   - Framework binaries for multiple architectures"
log_message "[INFO]   - Headers (llama_cpp and llama_mobile API)"
log_message "[INFO]   - Metal support (ggml-llama.metallib)"
log_message "[INFO]   - Modules and Info.plist"
log_message "[INFO] Note: Both static and shared libraries support Metal for iOS"
