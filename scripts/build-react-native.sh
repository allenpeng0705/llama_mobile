#!/bin/bash -e

# ============================================================================
# REACT NATIVE BUILD SCRIPT
# This script uses variables from config.env and provides auto-detection
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(NODE_PATH|NPM_PATH|YARN_PATH|FLUTTER_HOME|FLUTTER_BUILD_TYPE|CMAKE_PATH|CMAKE_JOBS|IOS_BUILD_TYPE|ANDROID_BUILD_TYPE|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Local variables with defaults from centralized config
NODE_PATH=${NODE_PATH:-""}                       # Path to Node.js executable
NPM_PATH=${NPM_PATH:-""}                        # Path to npm executable
YARN_PATH=${YARN_PATH:-""}                       # Path to Yarn executable

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
REACT_NATIVE_SDK_DIR="$ROOT_DIR/llama_mobile-react-native-SDK"
EXAMPLE_APP_DIR="$REACT_NATIVE_SDK_DIR/example"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile React Native SDK and optionally the example app."
    echo ""
    echo "Build variables can be configured in scripts/config.env:"
    echo "  - NODE_PATH: Path to Node.js executable"
    echo "  - NPM_PATH: Path to npm executable"
    echo "  - YARN_PATH: Path to Yarn executable"
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

# Check if node and npm are installed
if [ -n "$NODE_PATH" ]; then
  # Add Node.js to PATH if NODE_PATH is set
  NODE_DIR=$(dirname "$NODE_PATH")
  export PATH="$NODE_DIR:$PATH"
fi

if [ -n "$NPM_PATH" ]; then
  # Add npm to PATH if NPM_PATH is set
  NPM_DIR=$(dirname "$NPM_PATH")
  export PATH="$NPM_DIR:$PATH"
fi

if [ -n "$YARN_PATH" ]; then
  # Add Yarn to PATH if YARN_PATH is set
  YARN_DIR=$(dirname "$YARN_PATH")
  export PATH="$YARN_DIR:$PATH"
fi

if ! command -v node &> /dev/null; then
  echo "node could not be found."
  if [ -z "$NODE_PATH" ]; then
    echo "Please set NODE_PATH in scripts/config.env or install Node.js from https://nodejs.org/"
  else
    echo "Please check that NODE_PATH ($NODE_PATH) is set correctly"
  fi
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "npm could not be found."
  if [ -z "$NPM_PATH" ]; then
    echo "Please set NPM_PATH in scripts/config.env or install Node.js from https://nodejs.org/"
  else
    echo "Please check that NPM_PATH ($NPM_PATH) is set correctly"
  fi
  exit 1
fi

echo "Using Node.js: $(node --version)"
echo "Using npm: $(npm --version)"

if command -v yarn &> /dev/null; then
  echo "Using Yarn: $(yarn --version)"
fi

# Check if the React Native SDK directory exists
if [ ! -d "$REACT_NATIVE_SDK_DIR" ]; then
    echo "✗ Error: React Native SDK directory not found at $REACT_NATIVE_SDK_DIR!"
    exit 1
fi

# Check if the example app directory exists
if [ ! -d "$EXAMPLE_APP_DIR" ]; then
    echo "✗ Error: Example app directory not found at $EXAMPLE_APP_DIR!"
    exit 1
fi

# Function to copy iOS SDK into React Native SDK
function copy_ios_sdk_to_plugin() {
    echo "=== Copying iOS SDK into React Native SDK ==="
    
    REACT_NATIVE_IOS_DIR="$REACT_NATIVE_SDK_DIR/ios"
    
    # Create Frameworks directory in React Native SDK
    REACT_NATIVE_IOS_FRAMEWORKS_DIR="$REACT_NATIVE_IOS_DIR/Frameworks"
    mkdir -p "$REACT_NATIVE_IOS_FRAMEWORKS_DIR"
    
    # Remove old framework if it exists
    if [ -d "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework" ]; then
        echo -n "Removing old iOS framework... "
        rm -rf "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework"
        echo "✓"
    fi
    
    # Copy new framework from iOS SDK
    echo -n "Copying iOS framework to React Native SDK... "
    if cp -R "$ROOT_DIR/llama_mobile-ios-SDK/Frameworks/llama_mobile.xcframework" "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy iOS framework to React Native SDK"
        exit 1
    fi
}

# Function to copy Android SDK into React Native SDK
function copy_android_sdk_to_plugin() {
    echo "=== Copying Android SDK into React Native SDK ==="
    
    REACT_NATIVE_ANDROID_DIR="$REACT_NATIVE_SDK_DIR/android"
    ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"
    
    # Copy JNI libraries
    echo -n "Copying Android JNI libraries... "
    REACT_NATIVE_JNI_LIBS_DIR="$REACT_NATIVE_ANDROID_DIR/src/main/jniLibs"
    ANDROID_JNI_LIBS_DIR="$ANDROID_SDK_DIR/src/main/jniLibs"
    
    mkdir -p "$REACT_NATIVE_JNI_LIBS_DIR"
    rm -rf "$REACT_NATIVE_JNI_LIBS_DIR/*"
    
    if cp -R "$ANDROID_JNI_LIBS_DIR/"* "$REACT_NATIVE_JNI_LIBS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android JNI libraries"
        exit 1
    fi
    
    # Copy JNI C++ files
    echo -n "Copying Android JNI C++ files... "
    REACT_NATIVE_CPP_DIR="$REACT_NATIVE_ANDROID_DIR/src/main/cpp"
    ANDROID_CPP_DIR="$ANDROID_SDK_DIR/src/main/cpp"
    
    mkdir -p "$REACT_NATIVE_CPP_DIR"
    rm -rf "$REACT_NATIVE_CPP_DIR/*"
    
    if cp -R "$ANDROID_CPP_DIR/"* "$REACT_NATIVE_CPP_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android JNI C++ files"
        exit 1
    fi
    
    # Copy Java files
    echo -n "Copying Android Java files... "
    REACT_NATIVE_JAVA_DIR="$REACT_NATIVE_ANDROID_DIR/src/main/java/com/llamamobile/sdk"
    ANDROID_JAVA_DIR="$ANDROID_SDK_DIR/src/main/java/com/llamamobile/sdk"
    
    mkdir -p "$REACT_NATIVE_JAVA_DIR"
    rm -rf "$REACT_NATIVE_JAVA_DIR/*"
    
    if cp -R "$ANDROID_JAVA_DIR/"* "$REACT_NATIVE_JAVA_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android Java files"
        exit 1
    fi
    
    # Copy assets/grammars folder
    echo -n "Copying Android assets/grammars folder... "
    REACT_NATIVE_ASSETS_DIR="$REACT_NATIVE_ANDROID_DIR/src/main/assets"
    ANDROID_ASSETS_DIR="$ANDROID_SDK_DIR/src/main/assets"
    
    mkdir -p "$REACT_NATIVE_ASSETS_DIR/grammars"
    if cp -R "$ANDROID_ASSETS_DIR/grammars/"* "$REACT_NATIVE_ASSETS_DIR/grammars/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android assets/grammars folder"
        exit 1
    fi
}

# Function to build the React Native SDK
function build_sdk() {
    echo "=== Building llama_mobile React Native SDK ==="
    
    cd "$REACT_NATIVE_SDK_DIR"
    
    # Build iOS SDK dependency first (if on macOS)
    if [[ "$(uname)" == "Darwin" ]]; then
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
            echo "Please ensure the iOS build script exists before building the React Native SDK"
            exit 1
        fi
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
        echo "Please ensure the Android build script exists before building the React Native SDK"
        exit 1
    fi
    
    # Copy SDKs into React Native SDK to make it self-contained
    if [[ "$(uname)" == "Darwin" ]]; then
        copy_ios_sdk_to_plugin
    fi
    copy_android_sdk_to_plugin
    
    # Install dependencies
    echo "Installing React Native SDK dependencies..."
    if npm install; then
        echo "✓ React Native SDK dependencies installed successfully"
    else
        echo "✗ React Native SDK dependencies installation failed!"
        exit 1
    fi
    
    echo "=== React Native SDK build completed successfully! ==="
    echo "SDK is available at: $REACT_NATIVE_SDK_DIR"
}

# Function to build the example app
function build_example() {
    echo "=== Building llama_mobile React Native example app ==="
    
    if [ ! -d "$EXAMPLE_APP_DIR" ]; then
        echo "✗ Error: Example app directory not found at $EXAMPLE_APP_DIR!"
        exit 1
    fi
    
    cd "$EXAMPLE_APP_DIR"
    
    # Install dependencies
    echo "Installing example app dependencies..."
    if npm install; then
        echo "✓ Example app dependencies installed successfully"
    else
        echo "✗ Example app dependencies installation failed!"
        exit 1
    fi
    
    # Link dependencies (if needed)
    echo "Linking dependencies..."
    if npx react-native link; then
        echo "✓ Dependencies linked successfully"
    else
        echo "⚠ Dependency linking failed - this might be expected for newer React Native versions"
    fi
    
    # Build the example app for iOS if on macOS
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "Building example app for iOS..."
        if npx react-native run-ios --mode debug --no-packager; then
            echo "✓ iOS example app built successfully"
        else
            echo "✗ iOS example app build failed!"
            exit 1
        fi
    fi
    
    # Build the example app for Android
    echo "Building example app for Android..."
    if npx react-native run-android --mode debug --no-packager; then
        echo "✓ Android example app built successfully"
    else
        echo "✗ Android example app build failed!"
        exit 1
    fi
    
    echo "=== React Native example app build completed successfully! ==="
    echo "Example app is available at: $EXAMPLE_APP_DIR"
    echo "Run the example app with: npx react-native run-ios/run-android"
}

# Execute both SDK build and example app build
build_sdk
build_example