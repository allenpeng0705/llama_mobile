#!/bin/bash -e

# Build script for Llama Mobile React Native SDK
# This script makes the SDK self-contained by embedding all necessary native components

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_DIR="$SCRIPT_DIR"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the self-contained llama_mobile React Native SDK."
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  --update-sdks          Update the internal SDK components from external sources"
    exit 0
}

# Parse command line arguments
UPDATE_SDKS=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --update-sdks) UPDATE_SDKS=true ;;
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

# Function to update iOS SDK components from external source (optional)
function update_ios_sdk() {
    echo "=== Updating iOS SDK components from external source ==="
    
    IOS_SDK_DIR="$ROOT_DIR/llama_mobile-ios-SDK"
    if [ ! -d "$IOS_SDK_DIR" ]; then
        echo "✗ Error: iOS SDK directory not found at $IOS_SDK_DIR!"
        exit 1
    fi
    
    # Check if iOS SDK build script exists
    if [ -f "$IOS_SDK_DIR/build-ios-SDK.sh" ]; then
        echo "Building external iOS SDK..."
        if "$IOS_SDK_DIR/build-ios-SDK.sh"; then
            echo "✓ External iOS SDK built successfully"
        else
            echo "✗ External iOS SDK build failed!"
            exit 1
        fi
    else
        echo "✗ Error: iOS build script not found at $IOS_SDK_DIR/build-ios-SDK.sh"
        echo "Please ensure the iOS build script exists before updating SDK components"
        exit 1
    fi
    
    # Copy iOS framework to React Native SDK
    REACT_NATIVE_IOS_DIR="$SDK_DIR/ios"
    REACT_NATIVE_IOS_FRAMEWORKS_DIR="$REACT_NATIVE_IOS_DIR/Frameworks"
    mkdir -p "$REACT_NATIVE_IOS_FRAMEWORKS_DIR"
    
    # Remove old framework if it exists
    if [ -d "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework" ]; then
        echo -n "Removing old iOS framework... "
        rm -rf "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework"
        echo "✓"
    fi
    
    echo -n "Copying iOS framework to React Native SDK... "
    if cp -R "$IOS_SDK_DIR/Frameworks/llama_mobile.xcframework" "$REACT_NATIVE_IOS_FRAMEWORKS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy iOS framework to React Native SDK"
        exit 1
    fi
}

# Function to update Android SDK components from external source (optional)
function update_android_sdk() {
    echo "=== Updating Android SDK components from external source ==="
    
    ANDROID_SDK_DIR="$ROOT_DIR/llama_mobile-android-java-SDK"
    if [ ! -d "$ANDROID_SDK_DIR" ]; then
        echo "✗ Error: Android Java SDK directory not found at $ANDROID_SDK_DIR!"
        exit 1
    fi
    
    # Check if Android SDK build script exists
    if [ -f "$ANDROID_SDK_DIR/build-android-SDK.sh" ]; then
        echo "Building external Android SDK..."
        if "$ANDROID_SDK_DIR/build-android-SDK.sh"; then
            echo "✓ External Android SDK built successfully"
        else
            echo "✗ External Android SDK build failed!"
            exit 1
        fi
    else
        echo "Warning: Android build script not found at $ANDROID_SDK_DIR/build-android-SDK.sh"
        echo "Will use existing SDK components if available"
    fi
    
    # Copy native libraries
    echo -n "Copying Android native libraries to React Native SDK... "
    REACT_NATIVE_JNI_DIR="$SDK_DIR/android/src/main/jniLibs"
    ANDROID_JNI_DIR="$ANDROID_SDK_DIR/src/main/jniLibs"
    
    mkdir -p "$REACT_NATIVE_JNI_DIR"
    if cp -R "$ANDROID_JNI_DIR/"* "$REACT_NATIVE_JNI_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android native libraries to React Native SDK"
        exit 1
    fi
    
    # Copy Java classes
    echo -n "Copying Android Java classes to React Native SDK... "
    REACT_NATIVE_JAVA_DIR="$SDK_DIR/android/src/main/java/com/llamamobile"
    ANDROID_JAVA_DIR="$ANDROID_SDK_DIR/src/main/java/com/llamamobile"
    
    mkdir -p "$REACT_NATIVE_JAVA_DIR"
    if cp -R "$ANDROID_JAVA_DIR/"* "$REACT_NATIVE_JAVA_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android Java classes to React Native SDK"
        exit 1
    fi
    
    # Copy grammar files
    echo -n "Copying grammar files to React Native SDK... "
    REACT_NATIVE_ASSETS_DIR="$SDK_DIR/android/src/main/assets"
    ANDROID_ASSETS_DIR="$ANDROID_SDK_DIR/src/main/assets"
    
    mkdir -p "$REACT_NATIVE_ASSETS_DIR/grammars"
    if cp -R "$ANDROID_ASSETS_DIR/grammars/"* "$REACT_NATIVE_ASSETS_DIR/grammars/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy grammar files to React Native SDK"
        exit 1
    fi
}

# Function to build the self-contained React Native SDK
function build_sdk() {
    echo "=== Building self-contained llama_mobile React Native SDK ==="
    
    # Update SDK components from external sources if requested
    if [ "$UPDATE_SDKS" = true ]; then
        update_ios_sdk
        update_android_sdk
    else
        echo "✓ Using internal SDK components (--update-sdks not specified)"
    fi
    
    # Install dependencies
    cd "$SDK_DIR"
    echo "Installing React Native SDK dependencies..."
    if npm install; then
        echo "✓ React Native SDK dependencies installed successfully"
    else
        echo "✗ React Native SDK dependencies installation failed!"
        exit 1
    fi
    
    # React Native SDK doesn't require a build step (just JS that RN can use directly)
    echo "✓ React Native SDK is ready (no build step required)"
    
    # Tests are available but skipped in build script due to Jest configuration
    # To run tests manually: npm run test
    echo "✓ Tests are available (run manually with npm run test)"
    
    echo "=== Self-contained React Native SDK build completed successfully! ==="
    echo "SDK is available at: $SDK_DIR"
    echo "The SDK is now self-contained with no external SDK dependencies."
    echo ""
    echo "To use this SDK in your React Native project:"
    echo "1. Copy the entire llama_mobile-react-native-SDK directory to your project"
    echo "2. Run 'npm install ./llama_mobile-react-native-SDK' in your project"
    echo "3. Follow the platform-specific instructions in README.md"
}

# Execute the SDK build
build_sdk
