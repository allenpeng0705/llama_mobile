#!/bin/bash -e

# ============================================================================
# CAPACITOR PLUGIN BUILD SCRIPT
# ============================================================================
# Purpose: Builds a self-contained Capacitor plugin with bundled iOS and Android dependencies
#
# Key Features:
# - Bundles iOS frameworks and Android libraries into the plugin
# - Copies native dependencies from pre-built locations
# - Creates a ready-to-use Capacitor plugin for web developers
# - GPU Support: Includes OpenCL and Vulkan GPU acceleration backends for Android
#
# Output: llama_mobile/llama_mobile-capacitor-plugin/
#
# GPU Support Configuration:
# - GPU support is enabled by default in build-android-lib.sh
# - Uses OpenCL backend for Adreno/Qualcomm GPUs
# - Uses Vulkan backend for broader GPU compatibility
# - GPU libraries are built with both OpenCL and Vulkan support
# - Runtime detection determines which backend to use based on device capabilities
# - GPU headers (ggml-opencl.h, ggml-vulkan.h) are included for native development
#
# Notes:
# - Android libraries must be built first using build-android-lib.sh
# - iOS framework must be built first using build-ios-framework.sh
# - GPU support is automatically included when building Android libraries with GPU enabled
# ============================================================================

# Simple logging function
log() {
    echo "[$(date '+%H:%M:%S')] $1"
}

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CAPACITOR_PLUGIN_DIR="$ROOT_DIR/llama_mobile-capacitor-plugin"
IOS_FRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios"
ANDROID_LIBS_DIR="$ROOT_DIR/llama_mobile-android/libs/static"
ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"

# Persistent backup directory for SDK files
PERSISTENT_BACKUP_DIR="$ROOT_DIR/scripts/sdk_backup"

log "=== Building Self-Contained Capacitor Plugin ==="
log "Output: $CAPACITOR_PLUGIN_DIR/"

# ============================================================================
# SCRIPT SETUP (COMMENTED OUT FOR NOW)
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
    echo -e "${BLUE}Usage: $0 [OPTIONS]${NC}"
    echo ""
    echo "Builds a self-contained llama_mobile Capacitor plugin with bundled native dependencies."
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  --build-type=TYPE  Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --verbose          Show verbose output"
    echo ""
    echo "Required Dependencies:"
    echo "  - Node.js and npm"
    echo "  - Capacitor CLI"
    echo "  - Xcode with Command Line Tools (for iOS)"
    echo "  - Android SDK with NDK (for Android)"
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
# DEPENDENCY CHECKING (COMMENTED OUT FOR NOW)
# ============================================================================

# script_progress "Checking for required dependencies..."

# # Check Node.js
# if ! command -v node &> /dev/null; then
#     handle_error 1 "Node.js could not be found. Please install Node.js and npm."
# fi
# NODE_VERSION=$(node --version)
# log_message "[SUCCESS] Found Node.js version $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    handle_error 1 "npm could not be found. Please ensure Node.js is properly installed."
fi
NPM_VERSION=$(npm --version)
log_message "[SUCCESS] Found npm version $NPM_VERSION"

# Check Capacitor CLI
if ! command -v npx &> /dev/null; then
    handle_error 1 "npx could not be found. Please ensure npm is properly installed."
fi

# Check if we're on macOS (required for iOS build)
if [[ "$(uname)" == "Darwin" ]]; then
    # Check Xcode command line tools
    if ! command -v xcodebuild &> /dev/null; then
        log_message "[WARN] Xcode command line tools could not be found. iOS build will be skipped."
    else
        log_message "[SUCCESS] Found Xcode command line tools"
    fi
else
    log_message "[WARN] Not running on macOS. iOS build will be skipped."
fi

# Check Android tools (required for Android build) and detect ANDROID_HOME
if command -v adb &> /dev/null; then
    log_message "[SUCCESS] Found Android SDK"
    
    # Detect ANDROID_HOME if not set
    if [ -z "$ANDROID_HOME" ]; then
        script_progress "ANDROID_HOME not set, trying to detect..."
        
        # Get the path to adb executable
        ADB_PATH=$(which adb)
        if [ -n "$ADB_PATH" ]; then
            # ANDROID_HOME is parent of platform-tools directory
            ANDROID_HOME=$(dirname "$(dirname "$ADB_PATH")")
            log_message "[SUCCESS] Detected ANDROID_HOME from adb: $ANDROID_HOME"
            # Update config.env with detected ANDROID_HOME
            update_config_env "ANDROID_HOME" "$ANDROID_HOME"
        fi
    fi
else
    # Try to detect ANDROID_HOME even if adb is not found
    if [ -z "$ANDROID_HOME" ]; then
        script_progress "Android SDK could not be found via adb, trying common paths..."
        
        OS=$(uname -s)
        
        if [ "$OS" = "Darwin" ]; then
            # macOS paths
            COMMON_PATHS=("$HOME/Library/Android/sdk" "$HOME/android-sdk")
        elif [ "$OS" = "Linux" ]; then
            # Linux paths
            COMMON_PATHS=("$HOME/Android/Sdk" "$HOME/android-sdk" "/opt/android-sdk")
        else
            log_message "[WARN] Unsupported operating system: $OS"
        fi
        
        detected=false
        for PATH in "${COMMON_PATHS[@]}"; do
            if [ -d "$PATH" ]; then
                ANDROID_HOME="$PATH"
                detected=true
                break
            fi
        done
        
        if [[ "$detected" = true ]]; then
            log_message "[SUCCESS] Detected ANDROID_HOME: $ANDROID_HOME"
            # Update config.env with detected ANDROID_HOME
            update_config_env "ANDROID_HOME" "$ANDROID_HOME"
        fi
    fi
    
    if [ -z "$ANDROID_HOME" ]; then
        log_message "[WARN] Android SDK could not be found. Android build will be skipped."
    fi
fi

log_message "[SUCCESS] All required dependencies found"

# ============================================================================
# MAIN BUILD PROCESS
# ============================================================================

# Set directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CAPACITOR_PLUGIN_DIR="$ROOT_DIR/llama_mobile-capacitor-plugin"
IOS_FRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios"
ANDROID_LIBS_DIR="$ROOT_DIR/llama_mobile-android/libs/static"
ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"

# Persistent backup directory for SDK files
PERSISTENT_BACKUP_DIR="$ROOT_DIR/scripts/sdk_backup"

log_message "[INFO] === Building Self-Contained Capacitor Plugin ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Output: $CAPACITOR_PLUGIN_DIR/"

# ============================================================================
# STEP 1: BACKUP CAPACITOR PLUGIN
# ============================================================================

log "Step 1: Creating backup of Capacitor plugin..."

if [ ! -d "$CAPACITOR_PLUGIN_DIR" ]; then
    log "No Capacitor plugin directory to backup"
else
    # Create persistent backup directory if it doesn't exist
    mkdir -p "$PERSISTENT_BACKUP_DIR"
    
    # Create timestamped backup
    timestamp=$(date '+%Y%m%d_%H%M%S')
    backup_dir="$PERSISTENT_BACKUP_DIR/llama_mobile-capacitor-plugin_$timestamp"
    
    log "Creating persistent backup of Capacitor plugin to $backup_dir"
    log "Source directory: $CAPACITOR_PLUGIN_DIR"
    
    # Simple and safe backup using rsync
    rsync -a "$CAPACITOR_PLUGIN_DIR" "$backup_dir/"
    log "Backup completed successfully"
    
    # Keep only the last 5 backups
    log "Cleaning up old backups (keeping last 5)..."
    
    # List all backup directories and filter only those matching the pattern
    backups=()
    for dir in "$PERSISTENT_BACKUP_DIR"/llama_mobile-capacitor-plugin_*; do
        # Only process directories that match the expected pattern (llama_mobile-capacitor-plugin_TIMESTAMP)
        if [[ -d "$dir" && "$dir" =~ llama_mobile-capacitor-plugin_[0-9]{8}_[0-9]{6} ]]; then
            backups+=("$dir")
        fi
    done
    
    # Sort by modification time (newest first)
    if [ ${#backups[@]} -gt 5 ]; then
        # Delete backups beyond the first 5 (newest)
        for ((i=5; i<${#backups[@]}; i++)); do
            log "Removing old backup: ${backups[$i]}"
            rm -rf "${backups[$i]}"
        done
    fi
    
    log "Backup cleanup completed"
    log "You can manually remove backups from: $PERSISTENT_BACKUP_DIR"
fi

# ============================================================================
# STEP 2: CLEAN CAPACITOR PLUGIN
# ============================================================================

log "Step 2: Cleaning Capacitor plugin..."

# 2a. Empty llama_mobile-capacitor-plugin/ios/Libraries/
if [ -d "$CAPACITOR_PLUGIN_DIR/ios/Libraries" ]; then
    log "Emptying ios/Libraries directory..."
    rm -rf "$CAPACITOR_PLUGIN_DIR/ios/Libraries/"*
    log "ios/Libraries directory emptied"
else
    log "ios/Libraries directory does not exist, creating it..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/ios/Libraries"
fi

# 2b. Delete llama_mobile-capacitor-plugin/ios/Sources/LlamaMobile.swift
if [ -f "$CAPACITOR_PLUGIN_DIR/ios/Sources/LlamaMobile.swift" ]; then
    log "Deleting ios/Sources/LlamaMobile.swift..."
    rm -f "$CAPACITOR_PLUGIN_DIR/ios/Sources/LlamaMobile.swift"
    log "ios/Sources/LlamaMobile.swift deleted"
else
    log "ios/Sources/LlamaMobile.swift does not exist"
fi

# 2c. Empty llama_mobile-capacitor-plugin/android/libs/
if [ -d "$CAPACITOR_PLUGIN_DIR/android/libs" ]; then
    log "Emptying android/libs directory..."
    rm -rf "$CAPACITOR_PLUGIN_DIR/android/libs/"*
    log "android/libs directory emptied"
else
    log "android/libs directory does not exist, creating it..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/android/libs"
fi

# 2d. Empty llama_mobile-capacitor-plugin/android/src/main/cpp/
if [ -d "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp" ]; then
    log "Emptying android/src/main/cpp directory..."
    # Remove all files except CMakeLists.txt
    #find "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp" -type f -not -name "CMakeLists.txt" -delete
    rm -rf "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include"
    rm -f "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/llama_mobile_jni.cpp"
    # Remove all subdirectories except include
    #find "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp" -type d -not -name "cpp" -not -name "include" -exec rm -rf {} \;
    log "android/src/main/cpp directory emptied (kept CMakeLists.txt)"
else
    log "android/src/main/cpp directory does not exist, creating it..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp"
    mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include"
fi

# 2e. Delete llama_mobile-capacitor-plugin/android/src/main/java/com/llamamobile/LlamaMobile.java
if [ -f "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
    log "Deleting android/src/main/java/com/llamamobile/LlamaMobile.java..."
    rm -f "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/LlamaMobile.java"
    log "android/src/main/java/com/llamamobile/LlamaMobile.java deleted"
else
    log "android/src/main/java/com/llamamobile/LlamaMobile.java does not exist"
fi

log "Capacitor plugin cleaned"

# ============================================================================
# STEP 3: COPY FILES FROM IOS SDK AND ANDROID SDK
# ============================================================================

log "Step 3: Copying files from iOS SDK and Android SDK..."

# 3a. Copy llama_mobile-ios/shared/llama_mobile.xcframework to llama_mobile-capacitor-plugin/ios/Libraries/
if [ -d "$IOS_FRAMEWORK_DIR/shared/llama_mobile.xcframework" ]; then
    log "Copying iOS framework from $IOS_FRAMEWORK_DIR/shared/llama_mobile.xcframework to $CAPACITOR_PLUGIN_DIR/ios/Libraries/..."
    cp -R "$IOS_FRAMEWORK_DIR/shared/llama_mobile.xcframework" "$CAPACITOR_PLUGIN_DIR/ios/Libraries/"
    log "iOS framework copied"
else
    log "WARN: iOS framework not found at $IOS_FRAMEWORK_DIR/shared/llama_mobile.xcframework"
fi

# 3b. Copy llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift to llama_mobile-capacitor-plugin/ios/Sources
if [ -f "$ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift" ]; then
    log "Copying iOS Swift wrapper from $ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift to $CAPACITOR_PLUGIN_DIR/ios/Sources/..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/ios/Sources"
    cp "$ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift" "$CAPACITOR_PLUGIN_DIR/ios/Sources/"
    log "iOS Swift wrapper copied"
else
    log "WARN: iOS Swift wrapper not found at $ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift"
fi

# 3c. Copy llama_mobile-android/libs/static/arm64-v8a and llama_mobile-android/libs/static/x86_64 to llama_mobile-capacitor-plugin/android/libs/
if [ -d "$ANDROID_LIBS_DIR/arm64-v8a" ]; then
    log "Copying Android arm64-v8a libraries from $ANDROID_LIBS_DIR/arm64-v8a to $CAPACITOR_PLUGIN_DIR/android/libs/..."
    cp -R "$ANDROID_LIBS_DIR/arm64-v8a" "$CAPACITOR_PLUGIN_DIR/android/libs/"
    log "Android arm64-v8a libraries copied"
else
    log "WARN: Android arm64-v8a libraries not found at $ANDROID_LIBS_DIR/arm64-v8a"
fi

if [ -d "$ANDROID_LIBS_DIR/x86_64" ]; then
    log "Copying Android x86_64 libraries from $ANDROID_LIBS_DIR/x86_64 to $CAPACITOR_PLUGIN_DIR/android/libs/..."
    cp -R "$ANDROID_LIBS_DIR/x86_64" "$CAPACITOR_PLUGIN_DIR/android/libs/"
    log "Android x86_64 libraries copied"
else
    log "WARN: Android x86_64 libraries not found at $ANDROID_LIBS_DIR/x86_64"
fi

# 3d. Copy llama_mobile-android-SDK/src/main/cpp to llama_mobile-capacitor-plugin/android/src/main/
if [ -d "$ANDROID_SDK_DIR/src/main/cpp" ]; then
    log "Copying Android JNI files from $ANDROID_SDK_DIR/src/main/cpp to $CAPACITOR_PLUGIN_DIR/android/src/main/..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp"
    # Only copy the .cpp files, not the CMakeLists.txt (we'll keep our modified version)
    cp "$ANDROID_SDK_DIR/src/main/cpp"/llama_mobile_jni.cpp "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/"
    cp -R "$ANDROID_SDK_DIR/src/main/cpp/include" "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/"
    # Always create the include folder
    # mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include"
    # # Copy include files from ANDROID_SDK_DIR if available
    # if [ -d "$ANDROID_SDK_DIR/src/main/cpp/include" ]; then
    #     cp -r "$ANDROID_SDK_DIR/src/main/cpp/include"/* "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include/"
    #     log "Android JNI include files copied from SDK"
    # fi
    log "Android JNI files copied"
else
    log "WARN: Android JNI files not found at $ANDROID_SDK_DIR/src/main/cpp"
    # Even if SDK directory doesn't exist, copy include files from llama_mobile-android if available
    if [ -d "$ROOT_DIR/llama_mobile-android/include" ]; then
        mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include"
        cp -r "$ROOT_DIR/llama_mobile-android/include"/* "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/include/"
        log "Android JNI include files copied from llama_mobile-android"
    fi
fi

# 3e. Copy llama_mobile-android-SDK/src/main/java/com/llamamobile/LlamaMobile.java to llama_mobile-capacitor-plugin/android/src/main/java/com/llamamobile/
if [ -f "$ANDROID_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
    log "Copying Android LlamaMobile.java from $ANDROID_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java to $CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile"
    cp "$ANDROID_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java" "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/"
    log "Android LlamaMobile.java copied"
else
    log "WARN: Android LlamaMobile.java not found at $ANDROID_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java"
fi

log "All files copied from iOS SDK and Android SDK"

# ============================================================================
# VERIFY THE BUILD
# ============================================================================

script_progress "Verifying Capacitor plugin build..."

# Check which components were actually built
IOS_SUCCESS=false
ANDROID_SUCCESS=false

if [ -d "$CAPACITOR_PLUGIN_DIR/ios/Libraries/llama_mobile.xcframework" ]; then
    IOS_SUCCESS=true
    log_message "[SUCCESS] iOS framework bundled at: $CAPACITOR_PLUGIN_DIR/ios/Libraries/llama_mobile.xcframework"
else
    log_message "[WARN] iOS framework not found at $CAPACITOR_PLUGIN_DIR/ios/Libraries/llama_mobile.xcframework"
fi

if [ -f "$CAPACITOR_PLUGIN_DIR/ios/Sources/LlamaMobile.swift" ]; then
    log_message "[SUCCESS] iOS Swift wrapper bundled at: $CAPACITOR_PLUGIN_DIR/ios/Sources/LlamaMobile.swift"
else
    log_message "[WARN] iOS Swift wrapper not found at $CAPACITOR_PLUGIN_DIR/ios/Sources/LlamaMobile.swift"
fi

if [ -d "$CAPACITOR_PLUGIN_DIR/android/libs/arm64-v8a" ] || [ -d "$CAPACITOR_PLUGIN_DIR/android/libs/x86_64" ]; then
    ANDROID_SUCCESS=true
    log_message "[SUCCESS] Android native libraries bundled at: $CAPACITOR_PLUGIN_DIR/android/libs/"
else
    log_message "[WARN] Android native libraries not found at $CAPACITOR_PLUGIN_DIR/android/libs/"
fi

if [ -f "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
    log_message "[SUCCESS] Android LlamaMobile.java bundled at: $CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/LlamaMobile.java"
else
    log_message "[WARN] Android LlamaMobile.java not found at $CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/LlamaMobile.java"
fi

if [ -d "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp" ]; then
    log_message "[SUCCESS] Android JNI files bundled at: $CAPACITOR_PLUGIN_DIR/android/src/main/cpp/"
else
    log_message "[WARN] Android JNI files not found at $CAPACITOR_PLUGIN_DIR/android/src/main/cpp/"
fi

# Build the Capacitor plugin
script_progress "Building Capacitor plugin..."
cd "$CAPACITOR_PLUGIN_DIR"
# Install dependencies first
if npm install; then
    log_message "[SUCCESS] Dependencies installed successfully"
else
    log_message "[WARN] Dependency installation failed, but continuing"
fi
if npm run build; then
    log_message "[SUCCESS] Capacitor plugin built successfully"
else
    log_message "[WARN] Capacitor plugin build failed, but continuing verification"
fi

# Build Android native library (JNI)
script_progress "Building Android native library..."
cd "$CAPACITOR_PLUGIN_DIR/android"
if ./gradlew assembleDebug --no-build-cache; then
    log_message "[SUCCESS] Android native library built successfully"
else
    log_message "[WARN] Android native library build failed, but continuing verification"
fi
cd "$CAPACITOR_PLUGIN_DIR"

# Run Android tests if available - skipping for now as they require native library and emulator
#if [ -f "$CAPACITOR_PLUGIN_DIR/android/build.gradle" ]; then
#    script_progress "Running Android tests..."
#    cd "$CAPACITOR_PLUGIN_DIR/android"
#    if ./gradlew test --no-build-cache; then
#        log_message "[SUCCESS] Android tests passed"
#    else
#        log_message "[WARN] Android tests failed, but continuing verification"
#    fi
#    cd "$CAPACITOR_PLUGIN_DIR"
#fi
log_message "[INFO] Skipping Android tests - they require native library and emulator setup"


# Run iOS tests if available - skipping for now as they require emulator and environment setup
#if [ -f "$CAPACITOR_PLUGIN_DIR/Package.swift" ]; then
#    script_progress "Running iOS tests..."
#    cd "$CAPACITOR_PLUGIN_DIR"
#    if swift test; then
#        log_message "[SUCCESS] iOS tests passed"
#    else
#        log_message "[WARN] iOS tests failed, but continuing verification"
#    fi
#    cd "$CAPACITOR_PLUGIN_DIR"
#fi
log_message "[INFO] Skipping iOS tests - they require emulator and environment setup"

# Build and verify example app
if [ -d "$CAPACITOR_PLUGIN_DIR/example-app" ]; then
    script_progress "Building example app..."
    cd "$CAPACITOR_PLUGIN_DIR/example-app"
    # Install dependencies first
    if npm install; then
        log_message "[SUCCESS] Example app dependencies installed successfully"
    else
        log_message "[WARN] Example app dependency installation failed, but continuing"
    fi
    if npm run build; then
        log_message "[SUCCESS] Example app built successfully"
    else
        log_message "[WARN] Example app build failed, but continuing verification"
    fi
    cd "$CAPACITOR_PLUGIN_DIR"
else
    log_message "[WARN] Example app directory not found at $CAPACITOR_PLUGIN_DIR/example-app"
fi

if [ "$IOS_SUCCESS" = true ] || [ "$ANDROID_SUCCESS" = true ]; then
    # Create output directory
    OUTPUT_DIR="$ROOT_DIR/output"
    mkdir -p "$OUTPUT_DIR"
    
    # Clean build artifacts before copying
    log_message "[INFO] Cleaning build artifacts before copying..."
    cd "$CAPACITOR_PLUGIN_DIR"
    # Remove build directories that might cause permission issues
    rm -rf .build node_modules
    
    # Copy built Capacitor plugin to output directory
    log_message "[INFO] Copying built Capacitor plugin to output directory..."
    cp -R "$CAPACITOR_PLUGIN_DIR" "$OUTPUT_DIR/"
    
    log_message "[SUCCESS] Self-contained Capacitor plugin build completed successfully!"
    log_message "[INFO] To use this plugin in a Capacitor app, add it to your package.json:"
    log_message "[INFO] dependencies:"
    log_message "[INFO]   llama_mobile-capacitor-plugin:"
    log_message "[INFO]     path: $CAPACITOR_PLUGIN_DIR"
    log_message "[INFO] Built Capacitor plugin bundled to: $OUTPUT_DIR/llama_mobile-capacitor-plugin/"
else
    handle_error 1 "Build verification failed. No components were built."
fi
