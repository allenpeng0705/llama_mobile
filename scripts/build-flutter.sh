#!/bin/bash -e

# ============================================================================
# FLUTTER BUILD SCRIPT
# This script uses variables from config.env and provides auto-detection
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(FLUTTER_HOME|FLUTTER_BUILD_TYPE|CMAKE_PATH|CMAKE_JOBS|IOS_BUILD_TYPE|ANDROID_BUILD_TYPE|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Local variables with defaults from centralized config
FLUTTER_HOME=${FLUTTER_HOME:-""}                    # Path to Flutter SDK
FLUTTER_BUILD_TYPE=${FLUTTER_BUILD_TYPE:-"release"} # release or debug

# Build behavior flags with defaults
NO_CLEAN=${NO_CLEAN:-false}                # Skip cleaning build directories
KEEP_BUILD=${KEEP_BUILD:-false}            # Keep intermediate build files
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
DEFAULT_FLUTTER_BUILD_TYPE="release"
if [ -z "$FLUTTER_BUILD_TYPE" ]; then
    update_config_env "FLUTTER_BUILD_TYPE" "$DEFAULT_FLUTTER_BUILD_TYPE"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_SDK_DIR="$ROOT_DIR/llama_mobile-flutter-SDK"
EXAMPLE_APP_DIR="$ROOT_DIR/examples/flutterSDKExample"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile Flutter plugin and optionally the example app."
    echo ""
    echo "Build variables can be configured in scripts/config.env:"
    echo "  - FLUTTER_HOME: Path to Flutter SDK"
    echo "  - FLUTTER_BUILD_TYPE: release or debug"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        *) echo "Unknown parameter: $1" ; show_help ;;
    esac
    shift
done

# Check if flutter is installed
if [ -n "$FLUTTER_HOME" ]; then
  # Add Flutter SDK to PATH if FLUTTER_HOME is set
  export PATH="$FLUTTER_HOME/bin:$PATH"
fi

if ! command -v flutter &> /dev/null; then
  echo "flutter could not be found."
  if [ -z "$FLUTTER_HOME" ]; then
    echo "Please set FLUTTER_HOME in scripts/config.env or install Flutter SDK from https://flutter.dev/docs/get-started/install"
  else
    echo "Please check that FLUTTER_HOME ($FLUTTER_HOME) is set correctly"
  fi
  exit 1
fi

echo "Using Flutter: $(flutter --version | head -n 1)"



# Check if the Flutter plugin directory exists
if [ ! -d "$FLUTTER_SDK_DIR" ]; then
    echo "✗ Error: Flutter plugin directory not found at $FLUTTER_SDK_DIR!"
    exit 1
fi

# Check if the example app directory exists
if [ ! -d "$EXAMPLE_APP_DIR" ]; then
    echo "✗ Error: Example app directory not found at $EXAMPLE_APP_DIR!"
    exit 1
fi

# Function to copy iOS SDK into Flutter plugin
function copy_ios_sdk_to_plugin() {
    echo "=== Copying iOS SDK into Flutter plugin ==="
    
    # Create Frameworks directory in Flutter plugin
    FLUTTER_IOS_FRAMEWORKS_DIR="$FLUTTER_SDK_DIR/ios/Frameworks"
    mkdir -p "$FLUTTER_IOS_FRAMEWORKS_DIR"
    
    # Remove old framework if it exists
    if [ -d "$FLUTTER_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework" ]; then
        echo -n "Removing old iOS framework... "
        rm -rf "$FLUTTER_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework"
        echo "✓"
    fi
    
    # Copy new framework from iOS SDK
    echo -n "Copying iOS framework to Flutter plugin... "
    if cp -R "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks/llama_mobile.xcframework" "$FLUTTER_IOS_FRAMEWORKS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy iOS framework to Flutter plugin"
        exit 1
    fi
}

# Function to copy Android SDK into Flutter plugin
function copy_android_sdk_to_plugin() {
    echo "=== Copying Android SDK into Flutter plugin ==="
    
    FLUTTER_ANDROID_DIR="$FLUTTER_SDK_DIR/android"
    ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"
    
    # Copy JNI libraries
    echo -n "Copying Android JNI libraries... "
    FLUTTER_JNI_LIBS_DIR="$FLUTTER_ANDROID_DIR/src/main/jniLibs"
    ANDROID_JNI_LIBS_DIR="$ANDROID_SDK_DIR/src/main/jniLibs"
    
    mkdir -p "$FLUTTER_JNI_LIBS_DIR"
    rm -rf "$FLUTTER_JNI_LIBS_DIR/*"
    
    if cp -R "$ANDROID_JNI_LIBS_DIR/"* "$FLUTTER_JNI_LIBS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android JNI libraries"
        exit 1
    fi
    
    # Copy JNI C++ files
    echo -n "Copying Android JNI C++ files... "
    FLUTTER_CPP_DIR="$FLUTTER_ANDROID_DIR/src/main/cpp"
    ANDROID_CPP_DIR="$ANDROID_SDK_DIR/src/main/cpp"
    
    mkdir -p "$FLUTTER_CPP_DIR"
    rm -rf "$FLUTTER_CPP_DIR/*"
    
    if cp -R "$ANDROID_CPP_DIR/"* "$FLUTTER_CPP_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android JNI C++ files"
        exit 1
    fi
    
    # Copy Kotlin/Java files
    echo -n "Copying Android Kotlin/Java files... "
    FLUTTER_JAVA_DIR="$FLUTTER_ANDROID_DIR/src/main/java"
    ANDROID_JAVA_DIR="$ANDROID_SDK_DIR/src/main/java"
    
    mkdir -p "$FLUTTER_JAVA_DIR"
    rm -rf "$FLUTTER_JAVA_DIR/*"
    
    if cp -R "$ANDROID_JAVA_DIR/"* "$FLUTTER_JAVA_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android Kotlin/Java files"
        exit 1
    fi
    
    # Copy assets/grammars folder
    echo -n "Copying Android assets/grammars folder... "
    FLUTTER_ASSETS_DIR="$FLUTTER_ANDROID_DIR/src/main/assets"
    ANDROID_ASSETS_DIR="$ANDROID_SDK_DIR/src/main/assets"
    
    mkdir -p "$FLUTTER_ASSETS_DIR/grammars"
    if cp -R "$ANDROID_ASSETS_DIR/grammars/"* "$FLUTTER_ASSETS_DIR/grammars/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android assets/grammars folder"
        exit 1
    fi
}

# Function to build the Flutter plugin
function build_plugin() {
    echo "=== Building llama_mobile Flutter plugin ==="
    
    cd "$FLUTTER_SDK_DIR"
    
    # Build iOS SDK dependency first
    if [ -f "$SCRIPT_DIR/build-ios.sh" ]; then
        echo "Building iOS SDK dependency first"
        if "$SCRIPT_DIR/build-ios.sh"; then
            echo "✓ iOS SDK built successfully"
        else
            echo "✗ iOS SDK build failed!"
            exit 1
        fi
    else
        echo "✗ Error: iOS build script not found at $SCRIPT_DIR/build-ios.sh"
        echo "Please ensure the iOS build script exists before building the Flutter plugin"
        exit 1
    fi
    
    # Build Android SDK dependency first
    if [ -f "$SCRIPT_DIR/build-android.sh" ]; then
        echo "Building Android SDK dependency..."
        if "$SCRIPT_DIR/build-android.sh"; then
            echo "✓ Android SDK built successfully"
        else
            echo "✗ Android SDK build failed!"
            exit 1
        fi
    else
        echo "✗ Error: Android build script not found at $SCRIPT_DIR/build-android.sh"
        echo "Please ensure the Android build script exists before building the Flutter plugin"
        exit 1
    fi
    
    # Copy SDKs into Flutter plugin to make it self-contained
    copy_ios_sdk_to_plugin
    copy_android_sdk_to_plugin
    
    # Get dependencies
    echo "Getting Flutter dependencies..."
    if flutter pub get; then
        echo "✓ Flutter dependencies resolved successfully"
    else
        echo "✗ Flutter dependencies resolution failed!"
        exit 1
    fi
    
    # Verify the plugin can be built by analyzing it
    echo "Analyzing plugin code..."
    if flutter analyze; then
        echo "✓ Plugin code analyzed successfully"
    else
        echo "✗ Plugin code analysis failed!"
        exit 1
    fi
    
    echo "=== Flutter plugin build completed successfully! ==="
    echo "Plugin is available at: $FLUTTER_SDK_DIR"
}

# Function to build the example app
function build_example() {
    echo "=== Building llama_mobile Flutter example app ==="
    
    cd "$EXAMPLE_APP_DIR"
    
    # Get dependencies
    echo "Getting example app dependencies..."
    if flutter pub get; then
        echo "✓ Example app dependencies resolved successfully"
    else
        echo "✗ Example app dependencies resolution failed!"
        exit 1
    fi
    
    # Build the example app for iOS
    echo "Building example app for iOS..."
    if flutter build ios --no-codesign; then
        echo "✓ iOS example app built successfully"
    else
        echo "✗ iOS example app build failed!"
        exit 1
    fi
    
    # Build the example app for Android
    echo "Building example app for Android..."
    if flutter build apk --debug; then
        echo "✓ Android example app built successfully"
    else
        echo "✗ Android example app build failed!"
        exit 1
    fi
    
    echo "=== Flutter example app build completed successfully! ==="
    echo "Example app is available at: $EXAMPLE_APP_DIR"
    echo "Run the example app with: flutter run"
}

# Execute both plugin build and example app build
build_plugin
build_example