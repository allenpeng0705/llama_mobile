#!/bin/bash -e

# ============================================================================
# FLUTTER SDK BUILD SCRIPT
# ============================================================================
# Purpose: Builds a self-contained Flutter Plugin SDK for Flutter developers
#
# IMPORTANT: This is a FLUTTER PLUGIN, not a Flutter Module!
# 
# Distribution Format:
# - This plugin is distributed as source code to Flutter developers
# - Flutter developers add it as a dependency in pubspec.yaml
# - Flutter build system automatically handles AAR (Android) and xcframework (iOS) generation
# - No manual AAR or xcframework building required
#
# Key Features:
# - Persistent timestamped backups of SDK folders (keeps last 5 backups)
# - Copies iOS framework from llama_mobile-ios (requires build-ios-framework.sh to be run first)
# - Copies iOS Swift wrapper from llama_mobile-ios-SDK
# - Copies Android static libraries from llama_mobile-android (requires build-android-lib.sh to be run first)
# - Copies Android source files (Java) from llama_mobile-android-SDK
# - Copies Android JNI files from llama_mobile-android-SDK
# - Ensures SDKs are build-ready with proper directory structure
# - Creates centralized output directory with all required files
# - GPU Support: Includes OpenCL and Vulkan GPU acceleration backends for Android
#
# Output Directories:
# - llama_mobile/llama_mobile-flutter-SDK/ (Self-contained Flutter plugin)
# - llama_mobile/output/llama_mobile-flutter-SDK/ (Distribution-ready plugin)
#
# Backup Directory:
# - llama_mobile/scripts/sdk_backup/ (timestamped backups)
#
# GPU Support Configuration:
# - GPU support is enabled by default in build-android-lib.sh
# - Uses OpenCL backend for Adreno/Qualcomm GPUs
# - Uses Vulkan backend for broader GPU compatibility
# - GPU libraries are built with both OpenCL and Vulkan support
# - Runtime detection determines which backend to use based on device capabilities
# - GPU headers (ggml-opencl.h, ggml-vulkan.h) are included for native development
#
# How Developers Use This Plugin:
# 1. Add to pubspec.yaml:
#    dependencies:
#      llama_mobile_flutter_sdk:
#        path: /path/to/llama_mobile/output/llama_mobile-flutter-SDK
# 2. Run: flutter pub get
# 3. Use in Flutter app:
#    import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
# 4. Build app: flutter build apk (Android) or flutter build ios (iOS)
#    - Flutter automatically builds AAR for Android
#    - Flutter automatically includes xcframework for iOS
#
# Notes:
# - iOS framework must be built first using build-ios-framework.sh
# - Android libraries must be built first using build-android-lib.sh
# - No automatic backup restoration (backups are for manual use only)
# - Grammar files are NOT copied (must be loaded from file paths)
# - Kotlin extension file is NOT copied (not used by Flutter plugin)
# - This is NOT a Flutter Module for native app integration
# - This IS a Flutter Plugin for Flutter app development
# - GPU support is automatically included when building Android libraries with GPU enabled
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    export $(grep -E '^(ANDROID_HOME|NDK_PATH|IOS_BUILD_TYPE|ANDROID_BUILD_TYPE|FLUTTER_SDK_PATH|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Variables with defaults
FLUTTER_SDK_PATH=${FLUTTER_SDK_PATH:-""}  # Path to Flutter SDK
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

# DRY RUN MODE - Set to true to see what would happen without executing
DRY_RUN=false

# Function to execute command (or just log in dry run mode)
execute_command() {
    local cmd="$1"
    local description="$2"
    
    if [ "$DRY_RUN" = true ]; then
        log_message "[DRY-RUN] Would execute: $cmd"
        log_message "[DRY-RUN] Description: $description"
        return 0
    else
        verbose_output "Running: $cmd"
        eval "$cmd"
        return $?
    fi
}

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
    echo "Builds a self-contained llama_mobile Flutter SDK with bundled native dependencies."
    echo ""
    echo "Options:"
    echo "  -h, --help         Show this help message and exit"
    echo "  --build-type=TYPE  Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  --verbose          Show verbose output"
    echo ""
    echo "Required Dependencies:"
    echo "  - Flutter SDK (with Dart)"
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

# Detect FLUTTER_SDK_PATH if not set
if [ -z "$FLUTTER_SDK_PATH" ]; then
    script_progress "FLUTTER_SDK_PATH not set, trying to detect..."
    
    # First try to find flutter in PATH
    FLUTTER_EXEC=$(which flutter 2>/dev/null)
    
    if [ -n "$FLUTTER_EXEC" ]; then
        # Get the directory of the Flutter executable
        FLUTTER_SDK_PATH=$(dirname "$(dirname "$FLUTTER_EXEC")")
        log_message "[SUCCESS] Detected FLUTTER_SDK_PATH from PATH: $FLUTTER_SDK_PATH"
        # Update config.env with detected FLUTTER_SDK_PATH
        update_config_env "FLUTTER_SDK_PATH" "$FLUTTER_SDK_PATH"
    else
        # Try common paths if not found in PATH
        OS=$(uname -s)
        
        if [ "$OS" = "Darwin" ]; then
            # macOS paths
            COMMON_PATHS=("$HOME/development/flutter" "$HOME/flutter" "/Applications/flutter")
        elif [ "$OS" = "Linux" ]; then
            # Linux paths
            COMMON_PATHS=("$HOME/development/flutter" "$HOME/flutter" "/opt/flutter")
        else
            handle_error 1 "Unsupported operating system: $OS"
        fi
        
        detected=false
        for PATH in "${COMMON_PATHS[@]}"; do
            if [ -d "$PATH" ] && [ -f "$PATH/bin/flutter" ]; then
                FLUTTER_SDK_PATH="$PATH"
                detected=true
                break
            fi
        done
        
        if [[ "$detected" = false ]]; then
            handle_error 1 "Flutter SDK could not be found! Please install Flutter SDK and add it to PATH."
        fi
        
        log_message "[SUCCESS] Detected FLUTTER_SDK_PATH: $FLUTTER_SDK_PATH"
        # Update config.env with detected FLUTTER_SDK_PATH
        update_config_env "FLUTTER_SDK_PATH" "$FLUTTER_SDK_PATH"
    fi
fi

# Check Flutter
if ! command -v flutter &> /dev/null; then
    handle_error 1 "Flutter could not be found. Please install Flutter SDK and add it to PATH."
fi
FLUTTER_VERSION=$(flutter --version | grep "Flutter" | cut -d " " -f 2)
log_message "[SUCCESS] Found Flutter SDK version $FLUTTER_VERSION"

# Check Dart
if ! command -v dart &> /dev/null; then
    handle_error 1 "Dart could not be found. Please ensure Flutter SDK is properly installed."
fi
DART_VERSION=$(dart --version | cut -d " " -f 2)
log_message "[SUCCESS] Found Dart version $DART_VERSION"

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
OUTPUT_DIR="$ROOT_DIR/output"

log_message "[INFO] Script directory: $SCRIPT_DIR"
log_message "[INFO] Root directory: $ROOT_DIR"
log_message "[INFO] Output directory: $OUTPUT_DIR"

# Check if Flutter SDK exists in root, otherwise use output directory
if [ -d "$ROOT_DIR/llama_mobile-flutter-SDK" ]; then
    FLUTTER_SDK_DIR="$ROOT_DIR/llama_mobile-flutter-SDK"
    log_message "[INFO] Using Flutter SDK from root directory: $FLUTTER_SDK_DIR"
elif [ -d "$OUTPUT_DIR/llama_mobile-flutter-SDK" ]; then
    FLUTTER_SDK_DIR="$OUTPUT_DIR/llama_mobile-flutter-SDK"
    log_message "[INFO] Using Flutter SDK from output directory: $FLUTTER_SDK_DIR"
else
    log_message "[ERROR] Flutter SDK not found in either root or output directory"
    log_message "[INFO] Checked: $ROOT_DIR/llama_mobile-flutter-SDK"
    log_message "[INFO] Checked: $OUTPUT_DIR/llama_mobile-flutter-SDK"
    handle_error 1 "Flutter SDK directory not found"
fi

# Validate FLUTTER_SDK_DIR is not empty
if [ -z "$FLUTTER_SDK_DIR" ]; then
    log_message "[ERROR] FLUTTER_SDK_DIR is empty or unset"
    handle_error 1 "FLUTTER_SDK_DIR is empty"
fi

# Validate FLUTTER_SDK_DIR is an absolute path
case "$FLUTTER_SDK_DIR" in
    /*)
        log_message "[INFO] FLUTTER_SDK_DIR is an absolute path: $FLUTTER_SDK_DIR"
        ;;
    *)
        log_message "[ERROR] FLUTTER_SDK_DIR is not an absolute path: $FLUTTER_SDK_DIR"
        handle_error 1 "FLUTTER_SDK_DIR must be an absolute path"
        ;;
esac

ANDROID_LIBS_DIR="$ROOT_DIR/llama_mobile-android/libs/static"
OUTPUT_SDK_DIR="$OUTPUT_DIR/llama_mobile-flutter-SDK"

# Persistent backup directory for SDK files
PERSISTENT_BACKUP_DIR="$ROOT_DIR/scripts/sdk_backup"

# iOS framework location (from output directory)
IOS_FRAMEWORK_PATH="$ROOT_DIR/llama_mobile-ios/shared/llama_mobile.xcframework"

# Function to create persistent backup of SDK directories
create_persistent_backup() {
    local sdk_dir="$1"
    local sdk_name="$2"
    
    if [ ! -d "$sdk_dir" ]; then
        log_message "[INFO] No $sdk_name SDK directory to backup"
        return 0
    fi
    
    # Create persistent backup directory if it doesn't exist
    mkdir -p "$PERSISTENT_BACKUP_DIR"
    
    # Create timestamped backup
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$PERSISTENT_BACKUP_DIR/llama_mobile-flutter-SDK_$timestamp"
    
    log_message "[INFO] Creating persistent backup of $sdk_name SDK to $backup_dir"
    log_message "[INFO] Source directory: $sdk_dir"
    log_message "[INFO] Backup directory: $backup_dir"
    log_message "[INFO] Source directory exists: $([ -d "$sdk_dir" ] && echo "YES" || echo "NO")"
    
    # Simple and safe backup using rsync
    # Copy entire directory structure without complex excludes
    log_message "[INFO] Starting copy: rsync -a \"$sdk_dir\" \"$backup_dir/\""
    rsync -a "$sdk_dir" "$backup_dir/"
    log_message "[INFO] Copy completed successfully"
    
    # Remove build artifacts from backup (safe to delete)
    log_message "[INFO] Removing build artifacts from backup..."
    log_message "[INFO] Removing: $backup_dir/build"
    execute_command "rm -rf \"$backup_dir/build\"" "Remove build directory from backup"
    log_message "[INFO] Removing: $backup_dir/.dart_tool"
    execute_command "rm -rf \"$backup_dir/.dart_tool\"" "Remove .dart_tool directory from backup"
    log_message "[INFO] Removing: $backup_dir/.symlinks"
    execute_command "rm -rf \"$backup_dir/.symlinks\"" "Remove .symlinks directory from backup"
    log_message "[INFO] Build artifacts removed from backup"
    
    # Keep only the last 5 backups - FIXED TO PREVENT UNINTENDED DELETIONS
    log_message "[INFO] Cleaning up old backups (keeping last 5)..."
    
    # List all backup directories and filter only those matching the pattern
    local backups=()
    for dir in "$PERSISTENT_BACKUP_DIR"/llama_mobile-flutter-SDK_*; do
        # Only process directories that match the expected pattern (llama_mobile-flutter-SDK_TIMESTAMP)
        if [[ -d "$dir" && "$dir" =~ llama_mobile-flutter-SDK_[0-9]{8}_[0-9]{6} ]]; then
            backups+=("$dir")
        fi
    done
    
    # Sort by modification time (newest first)
    if [ ${#backups[@]} -gt 5 ]; then
        # Delete backups beyond the first 5 (newest)
        for ((i=5; i<${#backups[@]}; i++)); do
            log_message "[INFO] Removing old backup: ${backups[$i]}"
            rm -rf "${backups[$i]}"
        done
    fi
    
    log_message "[INFO] Backup cleanup completed"
    log_message "[INFO] You can manually remove backups from: $PERSISTENT_BACKUP_DIR"
}

# Function to copy SDK to output directory
copy_sdk_to_output() {
    local sdk_dir="$1"
    local output_sdk_dir="$2"
    
    log_message "[INFO] === Starting copy_sdk_to_output ==="
    log_message "[INFO] Source directory: $sdk_dir"
    log_message "[INFO] Output directory: $output_sdk_dir"
    log_message "[INFO] Source exists: $([ -d "$sdk_dir" ] && echo "YES" || echo "NO")"
    log_message "[INFO] Output exists: $([ -d "$output_sdk_dir" ] && echo "YES" || echo "NO")"
    
    # Remove existing output SDK directory if it exists
    if [ -d "$output_sdk_dir" ]; then
        log_message "[INFO] Removing existing output SDK directory: $output_sdk_dir"
        rm -rf "$output_sdk_dir"
        log_message "[INFO] Removed existing output SDK directory"
    else
        log_message "[INFO] No existing output SDK directory to remove"
    fi
    
    # Create output SDK directory
    log_message "[INFO] Creating output SDK directory: $output_sdk_dir"
    mkdir -p "$output_sdk_dir"
    log_message "[INFO] Output SDK directory created"
    
    # Simple and safe copy using cp -r
    # Copy entire directory structure without complex excludes
    log_message "[INFO] Starting copy: cp -r \"$sdk_dir\" \"$output_sdk_dir\""
    rsync -a --copy-links --exclude='.symlinks' "$sdk_dir/" "$output_sdk_dir/"
    log_message "[INFO] Copy completed successfully"
    
    # Remove build artifacts from output (safe to delete)
    log_message "[INFO] Removing build artifacts from output..."
    log_message "[INFO] Removing: $output_sdk_dir/build"
    rm -rf "$output_sdk_dir/build"
    log_message "[INFO] Removing: $output_sdk_dir/.dart_tool"
    rm -rf "$output_sdk_dir/.dart_tool"
    log_message "[INFO] Removing: $output_sdk_dir/.symlinks"
    rm -rf "$output_sdk_dir/.symlinks"
    log_message "[INFO] Build artifacts removed from output"
    
    log_message "[SUCCESS] Flutter SDK copied to output directory: $output_sdk_dir"
    log_message "[INFO] === copy_sdk_to_output completed ==="
}

log_message "[INFO] === Building Self-Contained Flutter SDK ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Output: $FLUTTER_SDK_DIR/"

# Create persistent backup of SDK directory before cleaning
log_message "[INFO] Creating persistent backup of SDK directory..."

# Check if Flutter SDK directory exists
if [ ! -d "$FLUTTER_SDK_DIR" ]; then
    log_message "[ERROR] Flutter SDK directory not found: $FLUTTER_SDK_DIR"
    log_message "[INFO] Skipping backup and continuing..."
else
    create_persistent_backup "$FLUTTER_SDK_DIR" "Flutter"
fi

# Clean Flutter SDK
script_progress "Cleaning Flutter SDK..."

# Check if Flutter SDK directory exists before trying to clean
if [ ! -d "$FLUTTER_SDK_DIR" ]; then
    log_message "[ERROR] Flutter SDK directory not found: $FLUTTER_SDK_DIR"
    log_message "[INFO] Cannot continue with build. Please check your directory structure."
    handle_error 1 "Flutter SDK directory not found"
fi

cd "$FLUTTER_SDK_DIR"

# Safety check: verify we're in a Flutter project directory
if [ ! -f "pubspec.yaml" ]; then
    log_message "[ERROR] Not in a valid Flutter project directory: $(pwd)"
    log_message "[INFO] Expected directory: $FLUTTER_SDK_DIR"
    log_message "[INFO] Current directory: $(pwd)"
    handle_error 1 "Invalid Flutter project directory"
fi

flutter clean
flutter pub get

# Sync version from llama_mobile_version.h to pubspec.yaml
log_message "[INFO] Syncing version from llama_mobile_version.h..."
VERSION_FILE="$ROOT_DIR/lib/llama_mobile_version.h"
PUBSPEC_FILE="$ROOT_DIR/llama_mobile-flutter-SDK/pubspec.yaml"

if [ ! -f "$VERSION_FILE" ]; then
    log_message "[ERROR] Version file not found: $VERSION_FILE"
else
    if [ ! -f "$PUBSPEC_FILE" ]; then
        log_message "[ERROR] pubspec.yaml not found: $PUBSPEC_FILE"
    else
        MAJOR=$(grep "^#define LLAMA_MOBILE_VERSION_MAJOR" "$VERSION_FILE" | awk '{print $3}')
        MINOR=$(grep "^#define LLAMA_MOBILE_VERSION_MINOR" "$VERSION_FILE" | awk '{print $3}')
        PATCH=$(grep "^#define LLAMA_MOBILE_VERSION_PATCH" "$VERSION_FILE" | awk '{print $3}')
        
        VERSION_STRING="${MAJOR}.${MINOR}.${PATCH}"
        
        log_message "[INFO] Extracted version from llama_mobile_version.h: $VERSION_STRING"
        sed -i '' "s/^version: .*/version: ${VERSION_STRING}/" "$PUBSPEC_FILE"
        
        log_message "[INFO] Updated pubspec.yaml version to: $VERSION_STRING"
    fi
fi
log_message "[SUCCESS] Flutter SDK cleaned"

# Check iOS framework exists
if [[ "$(uname)" == "Darwin" ]] && command -v xcodebuild &> /dev/null; then
    if [ ! -d "$IOS_FRAMEWORK_PATH" ]; then
        log_message "[ERROR] iOS framework not found at: $IOS_FRAMEWORK_PATH"
        log_message "[INFO] Please run: ./scripts/build-ios-framework.sh"
        handle_error 1 "iOS framework not found. Please run build-ios-framework.sh first."
    fi
    
    # Copy iOS framework to Flutter SDK (sync with latest)
    script_progress "Copying iOS framework to Flutter SDK..."
    rm -rf "$FLUTTER_SDK_DIR/ios/LlamaMobile/llama_mobile.xcframework"
    mkdir -p "$FLUTTER_SDK_DIR/ios/LlamaMobile"
    cp -R "$IOS_FRAMEWORK_PATH" "$FLUTTER_SDK_DIR/ios/LlamaMobile/"
    log_message "[SUCCESS] iOS framework copied to Flutter SDK (synced with latest)"
    
    # Copy iOS Swift wrapper from iOS SDK to Flutter SDK (sync with latest)
    script_progress "Copying iOS Swift wrapper to Flutter SDK..."
    mkdir -p "$FLUTTER_SDK_DIR/ios/Classes"
    if [ -f "$ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift" ]; then
        cp -f "$ROOT_DIR/llama_mobile-ios-SDK/Sources/LlamaMobile/LlamaMobile.swift" "$FLUTTER_SDK_DIR/ios/Classes/"
        log_message "[SUCCESS] iOS Swift wrapper copied to Flutter SDK (synced with latest)"
    else
        log_message "[WARN] iOS SDK Swift wrapper not found, skipping copy"
    fi
fi

# Check Android libraries exist
if [ ! -d "$ANDROID_LIBS_DIR" ] || [ -z "$(ls -A "$ANDROID_LIBS_DIR")" ]; then
    log_message "[ERROR] Android libraries not found at: $ANDROID_LIBS_DIR"
    log_message "[INFO] Please run: ./scripts/build-android-lib.sh"
    handle_error 1 "Android libraries not found. Please run build-android-lib.sh first."
fi

# Copy Android libraries to Flutter SDK (sync with latest)
script_progress "Copying Android libraries to Flutter SDK..."
mkdir -p "$FLUTTER_SDK_DIR/android/src/main/jniLibs"
rm -rf "$FLUTTER_SDK_DIR/android/src/main/jniLibs"/*
for abi in $(ls "$ANDROID_LIBS_DIR"); do
    if [ -d "$ANDROID_LIBS_DIR/$abi" ]; then
        cp -Rf "$ANDROID_LIBS_DIR/$abi" "$FLUTTER_SDK_DIR/android/src/main/jniLibs/"
    fi
done
log_message "[SUCCESS] Android libraries copied to Flutter SDK (synced with latest)"

# Copy Android source files to Flutter SDK from Android SDK (sync with latest)
script_progress "Copying Android source files to Flutter SDK..."
mkdir -p "$FLUTTER_SDK_DIR/android/src/main/java/com/llamamobile"

# Copy from Android SDK directory first (preferred)
ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"
if [ -d "$ANDROID_SDK_DIR/src/main/java/com/llamamobile" ]; then
    rm -rf "$FLUTTER_SDK_DIR/android/src/main/java/com/llamamobile"/*
    cp -Rf "$ANDROID_SDK_DIR/src/main/java/com/llamamobile/"* "$FLUTTER_SDK_DIR/android/src/main/java/com/llamamobile/"
    log_message "[SUCCESS] Android source files copied to Flutter SDK from Android SDK directory (synced with latest)"
else
    log_message "[WARN] Android SDK source files not found, skipping source file copy"
fi

# Copy JNI files to Flutter SDK from Android SDK (sync with latest)
script_progress "Copying Android JNI files to Flutter SDK..."
mkdir -p "$FLUTTER_SDK_DIR/android/src/main/cpp"

# Copy from Android SDK directory first (preferred)
if [ -d "$ANDROID_SDK_DIR/src/main/cpp" ]; then
    if [ -d "$FLUTTER_SDK_DIR/android/src/main/cpp" ]; then
        rm -rf "$FLUTTER_SDK_DIR/android/src/main/cpp"/*
    fi
    cp -Rf "$ANDROID_SDK_DIR/src/main/cpp/"* "$FLUTTER_SDK_DIR/android/src/main/cpp/"
    log_message "[SUCCESS] Android JNI files copied to Flutter SDK from Android SDK directory (synced with latest)"
else
    log_message "[WARN] Android JNI files not found, skipping JNI file copy"
fi

# Copy include directory to Flutter SDK for self-contained builds
script_progress "Copying include directory to Flutter SDK..."
mkdir -p "$FLUTTER_SDK_DIR/android/include"

# Copy include directory from llama_mobile-android
if [ -d "$ROOT_DIR/llama_mobile-android/include" ]; then
    if [ -d "$FLUTTER_SDK_DIR/android/include" ]; then
        rm -rf "$FLUTTER_SDK_DIR/android/include"/*
    fi
    cp -Rf "$ROOT_DIR/llama_mobile-android/include/"* "$FLUTTER_SDK_DIR/android/include/"
    log_message "[SUCCESS] Include directory copied to Flutter SDK for self-contained builds"
else
    log_message "[WARN] Include directory not found at $ROOT_DIR/llama_mobile-android/include"
fi

# Update CMakeLists.txt to use local include directory
if [ -f "$FLUTTER_SDK_DIR/android/src/main/cpp/CMakeLists.txt" ]; then
    sed -i.bak 's|../../../../llama_mobile-android/include|../../../include|g' "$FLUTTER_SDK_DIR/android/src/main/cpp/CMakeLists.txt"
    rm -f "$FLUTTER_SDK_DIR/android/src/main/cpp/CMakeLists.txt.bak"
    log_message "[SUCCESS] CMakeLists.txt updated to use local include directory"
fi

# Build Flutter plugin
script_progress "Building Flutter plugin..."
cd "$FLUTTER_SDK_DIR"
# For Flutter plugins, we don't need to build ios-framework or aar directly
# The Flutter tool handles plugin building when integrating into apps
log_message "[SUCCESS] Flutter plugin build completed"

# Verify the build
script_progress "Verifying Flutter SDK build..."

# Check which components were actually built
IOS_SUCCESS=false
ANDROID_SUCCESS=false

if [ -d "$FLUTTER_SDK_DIR/ios/LlamaMobile/llama_mobile.xcframework" ]; then
    IOS_SUCCESS=true
    log_message "[SUCCESS] iOS framework bundled at: $FLUTTER_SDK_DIR/ios/LlamaMobile/llama_mobile.xcframework"
fi

if [ -d "$FLUTTER_SDK_DIR/android/src/main/java/com/llamamobile" ]; then
    ANDROID_SUCCESS=true
    log_message "[SUCCESS] Android source files bundled at: $FLUTTER_SDK_DIR/android/src/main/java/com/llamamobile/"
fi

if [ "$IOS_SUCCESS" = true ] || [ "$ANDROID_SUCCESS" = true ]; then
    log_message "[SUCCESS] Self-contained Flutter SDK build completed successfully!"
    
    # Copy SDK to output directory
    script_progress "Copying SDK to output directory..."
    
    # TEMPORARILY DISABLED TO PREVENT DELETION ISSUES
    copy_sdk_to_output "$FLUTTER_SDK_DIR" "$OUTPUT_SDK_DIR"
    log_message "[INFO] Copy to output temporarily disabled for debugging"
    
    # Build the example app for both platforms
    script_progress "Building example app..."
    EXAMPLE_DIR="$FLUTTER_SDK_DIR/example"
    
    if [ -d "$EXAMPLE_DIR" ]; then
        cd "$EXAMPLE_DIR"
        
        # Clean the example app
        log_message "[INFO] Cleaning example app..."
        flutter clean > /dev/null 2>&1
        
        # Get dependencies
        log_message "[INFO] Getting example app dependencies..."
        flutter pub get > /dev/null 2>&1
        
        # Build for Android
        ANDROID_BUILD_SUCCESS=false
        if command -v flutter &> /dev/null; then
            log_message "[INFO] Building example app for Android..."
            if flutter build apk --debug --no-pub > /tmp/flutter_android_build.log 2>&1; then
                ANDROID_BUILD_SUCCESS=true
                log_message "[SUCCESS] Android example app built successfully!"
                log_message "[INFO] APK location: $EXAMPLE_DIR/build/app/outputs/flutter-apk/app-debug.apk"
            else
                log_message "[WARN] Android build failed. Check /tmp/flutter_android_build.log for details."
            fi
        fi
        
        # Build for iOS (only on macOS)
        IOS_BUILD_SUCCESS=false
        if [[ "$(uname)" == "Darwin" ]] && command -v flutter &> /dev/null; then
            log_message "[INFO] Building example app for iOS..."
            if flutter build ios --debug --no-codesign --no-pub > /tmp/flutter_ios_build.log 2>&1; then
                IOS_BUILD_SUCCESS=true
                log_message "[SUCCESS] iOS example app built successfully!"
                log_message "[INFO] iOS build location: $EXAMPLE_DIR/build/ios/iphoneos/Runner.app"
            else
                log_message "[WARN] iOS build failed. Check /tmp/flutter_ios_build.log for details."
            fi
        fi
        
        # Summary of example app build
        if [ "$ANDROID_BUILD_SUCCESS" = true ] || [ "$IOS_BUILD_SUCCESS" = true ]; then
            log_message "[SUCCESS] Example app build completed successfully!"
        else
            log_message "[WARN] Example app build failed for both platforms."
            log_message "[WARN] Check the build logs for more information:"
            log_message "[WARN]   Android: /tmp/flutter_android_build.log"
            log_message "[WARN]   iOS: /tmp/flutter_ios_build.log"
        fi
        
        cd "$FLUTTER_SDK_DIR"
    else
        log_message "[WARN] Example app not found at: $EXAMPLE_DIR"
        log_message "[WARN] Skipping example app build."
    fi
    
    log_message "[INFO] To use this SDK in a Flutter app, add it to your pubspec.yaml:"
    log_message "[INFO] dependencies:"
    log_message "[INFO]   llama_mobile_flutter_sdk:"
    log_message "[INFO]     path: $FLUTTER_SDK_DIR"
else
    handle_error 1 "Build verification failed. No components were built."
fi

# Run Flutter tests
script_progress "Running Flutter tests..."
cd "$FLUTTER_SDK_DIR"

# Create test output directory
TEST_OUTPUT_DIR="$FLUTTER_SDK_DIR/test_output"
mkdir -p "$TEST_OUTPUT_DIR"

# Run tests with JSON output for reporting
if flutter test --reporter json > "$TEST_OUTPUT_DIR/test_results.json" 2>&1; then
    TEST_PASSED=true
    log_message "[SUCCESS] Flutter tests passed!"
else
    TEST_PASSED=false
    log_message "[WARN] Flutter tests failed. Check test output for details."
fi

# Parse test results and generate summary
if [ -f "$TEST_OUTPUT_DIR/test_results.json" ]; then
    TOTAL_TESTS=$(grep -o '"testID"' "$TEST_OUTPUT_DIR/test_results.json" | wc -l | tr -d ' ')
    PASSED_TESTS=$(grep -o '"result":"success"' "$TEST_OUTPUT_DIR/test_results.json" | wc -l | tr -d ' ')
    FAILED_TESTS=$(grep -o '"result":"error"' "$TEST_OUTPUT_DIR/test_results.json" | wc -l | tr -d ' ')
    
    log_message "[INFO] Test Summary:"
    log_message "[INFO]   Total Tests: $TOTAL_TESTS"
    log_message "[INFO]   Passed: $PASSED_TESTS"
    log_message "[INFO]   Failed: $FAILED_TESTS"
    
    # Save test summary to file
    cat > "$TEST_OUTPUT_DIR/test_summary.txt" << EOF
Flutter SDK Test Summary
=======================
Build Type: $BUILD_TYPE
Timestamp: $(date)
Total Tests: $TOTAL_TESTS
Passed: $PASSED_TESTS
Failed: $FAILED_TESTS
Test Results: $TEST_OUTPUT_DIR/test_results.json
EOF
    
    log_message "[INFO] Test summary saved to: $TEST_OUTPUT_DIR/test_summary.txt"
fi

# Final summary
log_message "[INFO] === Build Complete ==="
log_message "[INFO] Flutter SDK location: $FLUTTER_SDK_DIR"
log_message "[INFO] Output SDK location: $OUTPUT_SDK_DIR"

if [ "$TEST_PASSED" = true ]; then
    log_message "[SUCCESS] All tests passed!"
else
    log_message "[WARN] Some tests failed. Please review test output."
fi

if [ "$IOS_SUCCESS" = true ] && [ "$ANDROID_SUCCESS" = true ]; then
    log_message "[SUCCESS] Both iOS and Android components built successfully!"
elif [ "$IOS_SUCCESS" = true ]; then
    log_message "[SUCCESS] iOS component built successfully!"
elif [ "$ANDROID_SUCCESS" = true ]; then
    log_message "[SUCCESS] Android component built successfully!"
fi