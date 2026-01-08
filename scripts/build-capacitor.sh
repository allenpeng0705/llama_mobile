#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CAPACITOR_PLUGIN_DIR="$ROOT_DIR/llama_mobile-capacitor-plugin"
EXAMPLE_APP_DIR="$CAPACITOR_PLUGIN_DIR/example-app"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the self-contained llama_mobile Capacitor plugin."
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

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  echo "npm could not be found, please install Node.js from https://nodejs.org/"
  exit 1
fi

echo "Using npm: $(npm --version)"

# Check if the Capacitor plugin directory exists
if [ ! -d "$CAPACITOR_PLUGIN_DIR" ]; then
    echo "✗ Error: Capacitor plugin directory not found at $CAPACITOR_PLUGIN_DIR!"
    exit 1
fi

# Check if the example app directory exists
if [ ! -d "$EXAMPLE_APP_DIR" ]; then
    echo "✗ Error: Example app directory not found at $EXAMPLE_APP_DIR!"
    exit 1
fi

# Function to update iOS SDK from external source (optional)
function update_ios_sdk() {
    echo "=== Updating iOS SDK from external source ==="
    
    if [ -f "$SCRIPT_DIR/build-ios-SDK.sh" ]; then
        echo "Building external iOS SDK..."
        if "$SCRIPT_DIR/build-ios-SDK.sh"; then
            echo "✓ External iOS SDK built successfully"
        else
            echo "✗ External iOS SDK build failed!"
            exit 1
        fi
    else
        echo "✗ Error: iOS build script not found at $SCRIPT_DIR/build-ios-SDK.sh"
        echo "Please ensure the iOS build script exists before updating SDK components"
        exit 1
    fi
    
    # Copy new framework from iOS SDK
    IOS_SDK_DIR="$ROOT_DIR/llama_mobile-ios-SDK"
    if [ ! -d "$IOS_SDK_DIR" ]; then
        echo "✗ Error: iOS SDK directory not found at $IOS_SDK_DIR!"
        exit 1
    fi
    
    # Create Frameworks directory in Capacitor plugin
    CAPACITOR_IOS_FRAMEWORKS_DIR="$CAPACITOR_PLUGIN_DIR/ios/Frameworks"
    mkdir -p "$CAPACITOR_IOS_FRAMEWORKS_DIR"
    
    # Remove old framework if it exists
    if [ -d "$CAPACITOR_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework" ]; then
        echo -n "Removing old iOS framework... "
        rm -rf "$CAPACITOR_IOS_FRAMEWORKS_DIR/llama_mobile.xcframework"
        echo "✓"
    fi
    
    echo -n "Copying iOS framework to Capacitor plugin... "
    if cp -R "$IOS_SDK_DIR/Frameworks/llama_mobile.xcframework" "$CAPACITOR_IOS_FRAMEWORKS_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy iOS framework to Capacitor plugin"
        exit 1
    fi
}

# Function to update Android SDK components from external source (optional)
function update_android_sdk() {
    echo "=== Updating Android SDK components from external source ==="
    
    ANDROID_JAVA_SDK_DIR="$ROOT_DIR/llama_mobile-android-java-SDK"
    if [ ! -d "$ANDROID_JAVA_SDK_DIR" ]; then
        echo "✗ Error: Android Java SDK directory not found at $ANDROID_JAVA_SDK_DIR!"
        exit 1
    fi
    
    # Copy Java classes
    echo -n "Copying Android Java classes to Capacitor plugin... "
    CAPACITOR_JAVA_DIR="$CAPACITOR_PLUGIN_DIR/android/src/main/java/com/llamamobile"
    ANDROID_JAVA_DIR="$ANDROID_JAVA_SDK_DIR/src/main/java/com/llamamobile"
    
    mkdir -p "$CAPACITOR_JAVA_DIR"
    if cp -R "$ANDROID_JAVA_DIR/"* "$CAPACITOR_JAVA_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android Java classes to Capacitor plugin"
        exit 1
    fi
    
    # Copy native libraries
    echo -n "Copying Android native libraries to Capacitor plugin... "
    CAPACITOR_JNI_DIR="$CAPACITOR_PLUGIN_DIR/android/src/main/jniLibs"
    ANDROID_JNI_DIR="$ANDROID_JAVA_SDK_DIR/src/main/jniLibs"
    
    mkdir -p "$CAPACITOR_JNI_DIR"
    if cp -R "$ANDROID_JNI_DIR/"* "$CAPACITOR_JNI_DIR/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy Android native libraries to Capacitor plugin"
        exit 1
    fi
    
    # Copy grammar files
    echo -n "Copying grammar files to Capacitor plugin... "
    CAPACITOR_ASSETS_DIR="$CAPACITOR_PLUGIN_DIR/android/src/main/assets"
    ANDROID_ASSETS_DIR="$ANDROID_JAVA_SDK_DIR/src/main/assets"
    
    mkdir -p "$CAPACITOR_ASSETS_DIR/grammars"
    if cp -R "$ANDROID_ASSETS_DIR/grammars/"* "$CAPACITOR_ASSETS_DIR/grammars/"; then
        echo "✓"
    else
        echo "✗"
        echo "Failed to copy grammar files to Capacitor plugin"
        exit 1
    fi
}

# Function to build the Capacitor plugin
function build_plugin() {
    echo "=== Building self-contained llama_mobile Capacitor plugin ==="
    
    # Update SDK components from external sources if requested
    if [ "$UPDATE_SDKS" = true ]; then
        update_ios_sdk
        update_android_sdk
    else
        echo "✓ Using internal SDK components (--update-sdks not specified)"
    fi
    
    # Build the Capacitor plugin
    cd "$CAPACITOR_PLUGIN_DIR"
    
    # Get dependencies
    echo "Getting Capacitor plugin dependencies..."
    if npm install; then
        echo "✓ Capacitor plugin dependencies resolved successfully"
    else
        echo "✗ Capacitor plugin dependencies resolution failed!"
        exit 1
    fi
    
    # Verify the plugin can be built by running build command
    echo "Building Capacitor plugin..."
    if npm run build; then
        echo "✓ Capacitor plugin built successfully"
    else
        echo "✗ Capacitor plugin build failed!"
        exit 1
    fi
    
    # Verify Android build
    echo "Verifying Android build..."
    cd android
    if ./gradlew clean build -x test; then
        echo "✓ Android build verified successfully"
    else
        echo "✗ Android build verification failed!"
        exit 1
    fi
    cd ..
    
    echo "=== Self-contained Capacitor plugin build completed successfully! ==="
    echo "Plugin is available at: $CAPACITOR_PLUGIN_DIR"
    echo "The plugin is now self-contained with no external SDK dependencies."
}

# Function to build the example app
function build_example() {
    echo "=== Building llama_mobile Capacitor example app ==="
    
    cd "$EXAMPLE_APP_DIR"
    
    # Get dependencies
    echo "Getting example app dependencies..."
    if npm install; then
        echo "✓ Example app dependencies resolved successfully"
    else
        echo "✗ Example app dependencies resolution failed!"
        exit 1
    fi
    
    # Build the example app for web (quick verification)
    echo "Building example app for web..."
    if npm run build; then
        echo "✓ Web example app built successfully"
    else
        echo "✗ Web example app build failed!"
        exit 1
    fi
    
    echo "=== Capacitor example app build completed successfully! ==="
    echo "Example app is available at: $EXAMPLE_APP_DIR"
    echo "Run the example app with: npx cap run [ios|android]"
}

# Execute both plugin build and example app build
build_plugin
build_example
