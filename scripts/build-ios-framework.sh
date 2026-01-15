#!/bin/bash -e

# ============================================================================
# IOS NATIVE FRAMEWORK BUILD SCRIPT
# Builds low-level iOS framework (no Swift bindings)
# Output: llama_mobile/llama_mobile-ios/llama_mobile.xcframework
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
OUTPUT_DIR="$ROOT_DIR/llama_mobile-ios"
FRAMEWORK_NAME="llama_mobile"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

log_message "[INFO] === Building llama_mobile iOS Native Framework ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Simulator arches: $SIMULATOR_ARCHES"
log_message "[INFO] Device arches: $DEVICE_ARCHES"
log_message "[INFO] Output: $XCFRAMEWORK_PATH"

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

# Clean output directory
script_progress "Cleaning output directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
log_message "[SUCCESS] Output directory cleaned"

# Build function for a specific target
build_target() {
    local SYSTEM_NAME="$1"
    local ARCHES="$2"
    local SYSROOT="$3"
    local OUTPUT_SUBDIR="$4"
    local BUILD_DIR="$5"
    
    script_progress "Building for $OUTPUT_SUBDIR..."
    
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
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH="NO"
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "CMake configuration failed for $OUTPUT_SUBDIR!"
    fi
    
    # Build only the static library target (more reliable for iOS)
    cmake --build . --config "$BUILD_TYPE" --target llama_mobile_core_static -j $(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
    
    if [[ $? -ne 0 ]]; then
        handle_error 1 "Build failed for $OUTPUT_SUBDIR!"
    fi
    
    # Create framework structure - find the static library
    local LIB_PATH="$BUILD_DIR/build/llama_mobile_core_lib.build/$BUILD_TYPE-$SYSROOT/libllama_mobile_core_lib.a"
    if [[ ! -f "$LIB_PATH" ]]; then
        LIB_PATH=$(find "$BUILD_DIR" -name "libllama_mobile_core_lib.a" | head -1)
        if [[ -z "$LIB_PATH" ]]; then
            handle_error 1 "Could not find the built static library!"
        fi
    fi
    
    local DEST_PATH="$XCFRAMEWORK_PATH/$OUTPUT_SUBDIR/$FRAMEWORK_NAME.framework"
    mkdir -p "$DEST_PATH/Headers"
    
    # Copy the static library and rename it to match framework expectations
    cp "$LIB_PATH" "$DEST_PATH/$FRAMEWORK_NAME"
    
    # Copy headers
    cp "$ROOT_DIR/lib/llama_mobile_api.h" "$DEST_PATH/Headers/"
    cp "$ROOT_DIR/lib/llama_mobile_ffi.h" "$DEST_PATH/Headers/"
    
    # Copy all llama_cpp headers recursively
    mkdir -p "$DEST_PATH/Headers/llama_cpp"
    rsync -av "$ROOT_DIR/lib/llama_cpp/" "$DEST_PATH/Headers/llama_cpp/" --include="*.h" --include="*.hpp" --include="*/" --exclude="*"
    
    # Copy grammars folder
    if [[ -d "$ROOT_DIR/lib/grammars" ]]; then
        mkdir -p "$DEST_PATH/grammars"
        cp "$ROOT_DIR/lib/grammars"/* "$DEST_PATH/grammars/" 2>/dev/null || true
    fi
    
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
        
        # Compile simulator-specific metallib (if needed)
        if [[ "$OUTPUT_SUBDIR" != *"simulator"* ]]; then
            xcrun -sdk iphonesimulator metal -I. -std=metal3.1 -mios-version-min=17.0 ggml-metal.metal -o ggml-llama-sim.metallib 2>/dev/null || true
        fi
        
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
    
    log_message "[SUCCESS] Built $OUTPUT_SUBDIR framework"
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
    script_progress "Combining simulator architectures..."
    
    # Create combined simulator directory
    COMBINED_SIM_DIR="$XCFRAMEWORK_PATH/ios-$(echo $SIMULATOR_ARCHES | tr ' ' '_')-simulator"
    mkdir -p "$COMBINED_SIM_DIR"
    
    # Copy first simulator framework as base
    FIRST_SIM_ARCH=$(echo $SIMULATOR_ARCHES | awk '{print $1}')
    cp -R "$XCFRAMEWORK_PATH/ios-${FIRST_SIM_ARCH}-simulator/$FRAMEWORK_NAME.framework" "$COMBINED_SIM_DIR/"
    
    # Combine binary files
    SIM_BINARIES=()
    for ARCH in $SIMULATOR_ARCHES; do
        SIM_BINARIES+=("$XCFRAMEWORK_PATH/ios-${ARCH}-simulator/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME")
    done
    
    lipo -create "${SIM_BINARIES[@]}" -output "$COMBINED_SIM_DIR/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"
    
    # Clean up individual simulator directories
    for ARCH in $SIMULATOR_ARCHES; do
        rm -rf "$XCFRAMEWORK_PATH/ios-${ARCH}-simulator"
    done
    
    log_message "[SUCCESS] Combined simulator architectures"
fi

# Create XCFramework using xcodebuild
script_progress "Creating final XCFramework..."

# Get all framework paths
FRAMEWORK_PATHS=()
for DIR in "$XCFRAMEWORK_PATH"/*; do
    if [[ -d "$DIR" ]]; then
        FRAMEWORK_PATHS+=("-framework" "$DIR/$FRAMEWORK_NAME.framework")
    fi
done

# Use xcodebuild to create proper XCFramework
TEMP_XCFRAMEWORK="$OUTPUT_DIR/$FRAMEWORK_NAME-temp.xcframework"
xcodebuild -create-xcframework "${FRAMEWORK_PATHS[@]}" -output "$TEMP_XCFRAMEWORK"

# Replace with new XCFramework
rm -rf "$XCFRAMEWORK_PATH"
mv "$TEMP_XCFRAMEWORK" "$XCFRAMEWORK_PATH"

# Fix Info.plist encoding
log_message "[INFO] Fixing Info.plist encoding..."
find "$XCFRAMEWORK_PATH" -name "*.plist" -exec plutil -convert xml1 {} \;

# Add RequiredFrameworks and RequiredLibraries to XCFramework Info.plist
log_message "[INFO] Adding required dependencies to XCFramework Info.plist..."
XCFRAMEWORK_INFO_PLIST="$XCFRAMEWORK_PATH/Info.plist"

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

# Clean up any temporary build directories
rm -rf "$ROOT_DIR/build-ios-*"

# Verify the build
script_progress "Verifying framework..."

# Check XCFramework structure
if [[ -d "$XCFRAMEWORK_PATH" ]]; then
    log_message "[SUCCESS] XCFramework structure created at $XCFRAMEWORK_PATH"
    log_message "[INFO] Contains: $(ls -la "$XCFRAMEWORK_PATH" | grep ^d | awk '{print $9}')"
else
    handle_error 1 "XCFramework not found at expected location!"
fi

# Check framework contents
for VARIANT in "$XCFRAMEWORK_PATH"/*; do
    if [[ -d "$VARIANT" ]]; then
        FRAMEWORK="$VARIANT/$FRAMEWORK_NAME.framework"
        if [[ -f "$FRAMEWORK/$FRAMEWORK_NAME" ]]; then
            ARCHES=$(lipo -info "$FRAMEWORK/$FRAMEWORK_NAME" | grep -o "architecture.*" | cut -d ' ' -f 2-)
            log_message "[INFO] $(basename "$VARIANT"): $ARCHES"
        fi
    fi
done

log_message "[SUCCESS] === Build completed successfully! ==="
log_message "[INFO] Native iOS framework: $XCFRAMEWORK_PATH"
log_message "[INFO] This framework contains no Swift bindings and can be used for Flutter, React Native, etc."
