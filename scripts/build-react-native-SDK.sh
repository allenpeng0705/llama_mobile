#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REACT_NATIVE_SDK_DIR="$ROOT_DIR/llama_mobile-react-native-SDK"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Updates the llama_mobile React Native SDK without compiling iOS/Android SDKs."
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
if ! command -v node &> /dev/null; then
  echo "node could not be found, please install Node.js from https://nodejs.org/"
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echo "npm could not be found, please install Node.js from https://nodejs.org/"
  exit 1
fi

echo "Using Node.js: $(node --version)"
echo "Using npm: $(npm --version)"

# Check if the React Native SDK directory exists
if [ ! -d "$REACT_NATIVE_SDK_DIR" ]; then
    echo "✗ Error: React Native SDK directory not found at $REACT_NATIVE_SDK_DIR!"
    exit 1
fi

# Function to copy iOS SDK into React Native SDK
function copy_ios_sdk_to_plugin() {
    echo "=== Copying iOS SDK into React Native SDK ==="
    
    REACT_NATIVE_IOS_DIR="$REACT_NATIVE_SDK_DIR/ios"
    
    # Check if iOS SDK exists
    if [ ! -d "$ROOT_DIR/llama_mobile-ios-SDK" ]; then
        echo "✗ Error: iOS SDK directory not found at $ROOT_DIR/llama_mobile-ios-SDK!"
        echo "Please build the iOS SDK first using build-ios.sh"
        exit 1
    fi
    
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
    
    # Check if Android SDK exists
    if [ ! -d "$ANDROID_SDK_DIR" ]; then
        echo "✗ Error: Android SDK directory not found at $ANDROID_SDK_DIR!"
        echo "Please build the Android SDK first using build-android.sh"
        exit 1
    fi
    
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

# Function to update the React Native SDK
function update_sdk() {
    echo "=== Updating llama_mobile React Native SDK ==="
    
    cd "$REACT_NATIVE_SDK_DIR"
    
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
    
    echo "=== React Native SDK update completed successfully! ==="
    echo "SDK is available at: $REACT_NATIVE_SDK_DIR"
    echo "Note: iOS/Android SDKs were not compiled - this script only updates the React Native wrapper"
}

# Execute the SDK update
update_sdk