#!/bin/bash -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLUTTER_SDK_DIR="$ROOT_DIR/llama_mobile-flutter-SDK"
EXAMPLE_APP_DIR="$ROOT_DIR/examples/flutter_sdk_example"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile Flutter plugin and optionally the example app."
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -v, --verbose          Show verbose output for debugging"
    echo "  --build-only           Only build the Flutter plugin (default behavior)"
    echo "  --example-only         Only build the example app"
    echo "  --build-and-example    Build both the plugin and the example app"
    exit 0
}

# Default behavior: build only the plugin
BUILD_ONLY=true
EXAMPLE_ONLY=false
BUILD_AND_EXAMPLE=false
VERBOSE=false

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        -v|--verbose) VERBOSE=true ;;
        --build-only) BUILD_ONLY=true ; EXAMPLE_ONLY=false ; BUILD_AND_EXAMPLE=false ;;
        --example-only) BUILD_ONLY=false ; EXAMPLE_ONLY=true ; BUILD_AND_EXAMPLE=false ;;
        --build-and-example) BUILD_ONLY=false ; EXAMPLE_ONLY=false ; BUILD_AND_EXAMPLE=true ;;
        *) echo "Unknown parameter: $1" ; show_help ;;
    esac
    shift

done

# Check if flutter is installed
if ! command -v flutter &> /dev/null; then
  echo "flutter could not be found, please install Flutter SDK from https://flutter.dev/docs/get-started/install"
  exit 1
fi

echo "Using Flutter: $(flutter --version | head -n 1)"

# Show directory structure for debugging
if [ "$VERBOSE" = true ]; then
    echo "=== Debug Information ==="
    echo "Script directory: $SCRIPT_DIR"
    echo "Root directory: $ROOT_DIR"
    echo "Flutter SDK directory: $FLUTTER_SDK_DIR"
    echo "Example app directory: $EXAMPLE_APP_DIR"
    echo "iOS build script: $SCRIPT_DIR/build-ios.sh"
    echo "Android build script: $SCRIPT_DIR/build-android.sh"
    echo "======================="
fi

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

# Function to build the Flutter plugin
function build_plugin() {
    echo "=== Building llama_mobile Flutter plugin ==="
    
    cd "$FLUTTER_SDK_DIR"
    
    # Build iOS SDK dependency first
    if [ -f "$SCRIPT_DIR/build-ios.sh" ]; then
        echo "Building iOS SDK dependency..."
        if "$SCRIPT_DIR/build-ios.sh" --build-and-copy; then
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

# Execute based on command line options
if $EXAMPLE_ONLY; then
    # Only build the example app
    build_example
    exit 0
fi

if $BUILD_ONLY || $BUILD_AND_EXAMPLE; then
    # Build the plugin
    build_plugin
fi

# If build-and-example option was selected, build the example app
if $BUILD_AND_EXAMPLE; then
    build_example
fi

if [ $BUILD_ONLY = false ] && [ $EXAMPLE_ONLY = false ] && [ $BUILD_AND_EXAMPLE = false ]; then
    # Default: build only
    echo "No action specified, defaulting to --build-only"
    build_plugin
fi