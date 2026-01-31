#!/bin/bash -e

# ============================================================================
# CAPACITOR PLUGIN BUILD SCRIPT
# Builds a self-contained Capacitor plugin with bundled iOS and Android dependencies
# Output: llama_mobile/llama_mobile-capacitor-plugin/
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    export $(grep -E '^(ANDROID_HOME|NDK_PATH|IOS_BUILD_TYPE|ANDROID_BUILD_TYPE|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Variables with defaults
BUILD_TYPE=${ANDROID_BUILD_TYPE:-"Release"}        # Release or Debug build (applies to both iOS and Android)

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

if [ -z "$IOS_BUILD_TYPE" ]; then
    update_config_env "IOS_BUILD_TYPE" "$BUILD_TYPE"
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
# DEPENDENCY CHECKING
# ============================================================================

script_progress "Checking for required dependencies..."

# Check Node.js
if ! command -v node &> /dev/null; then
    handle_error 1 "Node.js could not be found. Please install Node.js and npm."
fi
NODE_VERSION=$(node --version)
log_message "[SUCCESS] Found Node.js version $NODE_VERSION"

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
ANDROID_LIBS_DIR="$ROOT_DIR/output/llama_mobile-android/libs"
ANDROID_SDK_OUTPUT_DIR="$ROOT_DIR/output/llama_mobile-android-java-SDK"

log_message "[INFO] === Building Self-Contained Capacitor Plugin ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Output: $CAPACITOR_PLUGIN_DIR/"

# Clean Capacitor plugin
script_progress "Cleaning Capacitor plugin..."
cd "$CAPACITOR_PLUGIN_DIR"
npm install
log_message "[SUCCESS] Capacitor plugin cleaned"

# Build iOS framework if needed
if [[ "$(uname)" == "Darwin" ]] && command -v xcodebuild &> /dev/null; then
    if [ ! -d "$IOS_FRAMEWORK_DIR/llama_mobile.xcframework" ]; then
        script_progress "Building iOS framework..."
        "$SCRIPT_DIR/build-ios-framework.sh" --build-type="$BUILD_TYPE" ${VERBOSE:+--verbose}
        log_message "[SUCCESS] iOS framework built"
    else
        log_message "[INFO] iOS framework already exists, skipping build"
    fi
    
    # Copy iOS framework to Capacitor plugin
    script_progress "Copying iOS framework to Capacitor plugin..."
    mkdir -p "$CAPACITOR_PLUGIN_DIR/ios/Libraries"
    cp -R "$IOS_FRAMEWORK_DIR/llama_mobile.xcframework" "$CAPACITOR_PLUGIN_DIR/ios/Libraries/"
    log_message "[SUCCESS] iOS framework copied to Capacitor plugin"
fi

# Build Android libraries if needed
if [ ! -d "$ANDROID_LIBS_DIR" ] || [ -z "$(ls -A "$ANDROID_LIBS_DIR")" ]; then
    script_progress "Building Android libraries..."
    "$SCRIPT_DIR/build-android-lib.sh" --build-type="$BUILD_TYPE" ${VERBOSE:+--verbose}
    log_message "[SUCCESS] Android libraries built"
else
    log_message "[INFO] Android libraries already exist, skipping build"
fi

# Copy Android libraries to Capacitor plugin
script_progress "Copying Android libraries to Capacitor plugin..."
mkdir -p "$CAPACITOR_PLUGIN_DIR/android/libs"
cp -R "$ANDROID_LIBS_DIR/"* "$CAPACITOR_PLUGIN_DIR/android/libs/"
log_message "[SUCCESS] Android libraries copied to Capacitor plugin"

# Copy Android source files to Capacitor plugin from output directory
script_progress "Copying Android source files to Capacitor plugin..."
mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile"
if [ -d "$ANDROID_SDK_OUTPUT_DIR/src/main/java/com/llamamobile" ]; then
    cp -R "$ANDROID_SDK_OUTPUT_DIR/src/main/java/com/llamamobile/"* "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/"
    log_message "[SUCCESS] Android source files copied to Capacitor plugin from output directory"
else
    log_message "[WARN] Android SDK output directory not found, skipping source file copy"
fi

# Copy JNI files to Capacitor plugin from output directory
script_progress "Copying Android JNI files to Capacitor plugin..."
mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp"
if [ -d "$ANDROID_SDK_OUTPUT_DIR/src/main/cpp" ]; then
    cp -R "$ANDROID_SDK_OUTPUT_DIR/src/main/cpp/"* "$CAPACITOR_PLUGIN_DIR/android/src/main/cpp/"
    log_message "[SUCCESS] Android JNI files copied to Capacitor plugin from output directory"
else
    log_message "[WARN] JNI files not found in output directory, skipping JNI file copy"
fi

# Copy Android assets to Capacitor plugin from output directory
script_progress "Copying Android assets to Capacitor plugin..."
mkdir -p "$CAPACITOR_PLUGIN_DIR/android/src/main/assets/grammars"
if [ -d "$ANDROID_SDK_OUTPUT_DIR/src/main/assets/grammars" ]; then
    cp -R "$ANDROID_SDK_OUTPUT_DIR/src/main/assets/grammars/"* "$CAPACITOR_PLUGIN_DIR/android/src/main/assets/grammars/"
    log_message "[SUCCESS] Android assets copied to Capacitor plugin from output directory"
else
    log_message "[WARN] Android assets not found in output directory, skipping asset copy"
fi

# Build Android SDK if needed
if [ ! -d "$ROOT_DIR/llama_mobile-android-java-SDK/src/main/java/com/llamamobile/" ] || [ ! -f "$ROOT_DIR/llama_mobile-android-java-SDK/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
    script_progress "Building Android SDK..."
    "$SCRIPT_DIR/build-android-SDK.sh" ${VERBOSE:+--verbose}
    log_message "[SUCCESS] Android SDK built"
else
    log_message "[INFO] Android SDK already exists, skipping build"
fi

# Verify the build
script_progress "Verifying Capacitor plugin build..."

# Check which components were actually built
IOS_SUCCESS=false
ANDROID_SUCCESS=false

if [ -d "$CAPACITOR_PLUGIN_DIR/ios/Libraries/llama_mobile.xcframework" ]; then
    IOS_SUCCESS=true
    log_message "[SUCCESS] iOS framework bundled at: $CAPACITOR_PLUGIN_DIR/ios/Libraries/llama_mobile.xcframework"
fi

if [ -d "$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile" ]; then
    ANDROID_SUCCESS=true
    log_message "[SUCCESS] Android source files bundled at: $CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile/"
fi

if [ "$IOS_SUCCESS" = true ] || [ "$ANDROID_SUCCESS" = true ]; then
    log_message "[SUCCESS] Self-contained Capacitor plugin build completed successfully!"
    log_message "[INFO] To use this plugin in a Capacitor app, add it to your package.json:"
    log_message "[INFO] dependencies:"
    log_message "[INFO]   llama_mobile-capacitor-plugin:"
    log_message "[INFO]     path: $CAPACITOR_PLUGIN_DIR"
else
    handle_error 1 "Build verification failed. No components were built."
fi
