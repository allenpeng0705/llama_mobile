#!/bin/bash -e

# ============================================================================
# CAPACITOR BUILD SCRIPT
# This script uses variables from config.env and provides auto-detection
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(NODE_PATH|NPM_PATH|YARN_PATH|FLUTTER_HOME|FLUTTER_BUILD_TYPE|CMAKE_PATH|CMAKE_JOBS|IOS_BUILD_TYPE|ANDROID_BUILD_TYPE|CAPACITOR_BUILD_TYPE|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Local variables with defaults from centralized config
NODE_PATH=${NODE_PATH:-""}                       # Path to Node.js executable
NPM_PATH=${NPM_PATH:-""}                        # Path to npm executable
YARN_PATH=${YARN_PATH:-""}                       # Path to Yarn executable
CAPACITOR_BUILD_TYPE=${CAPACITOR_BUILD_TYPE:-"release"} # release or debug

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
if [ -z "$CAPACITOR_BUILD_TYPE" ]; then
    update_config_env "CAPACITOR_BUILD_TYPE" "release"
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
CAPACITOR_PLUGIN_DIR="$ROOT_DIR/llama_mobile-capacitor-plugin"
EXAMPLE_APP_DIR="$CAPACITOR_PLUGIN_DIR/example-app"

# Show help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Builds the self-contained llama_mobile Capacitor plugin."
    echo ""
    echo "Build variables can be configured in scripts/config.env:"
    echo "  - NODE_PATH: Path to Node.js executable"
    echo "  - NPM_PATH: Path to npm executable"
    echo "  - YARN_PATH: Path to Yarn executable"
    echo "  - CAPACITOR_BUILD_TYPE: release or debug"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  --update-sdks          Update the internal SDK components from external sources"
    echo "  --force                Force update SDK components"
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
    
    if [ -f "$ROOT_DIR/llama_mobile-ios-SDK/build-ios-SDK.sh" ]; then
        echo "Building external iOS SDK..."
        if "$ROOT_DIR/llama_mobile-ios-SDK/build-ios-SDK.sh"; then
            echo "✓ External iOS SDK built successfully"
        else
            echo "✗ External iOS SDK build failed!"
            exit 1
        fi
    else
        echo "✗ Error: iOS build script not found at $ROOT_DIR/llama_mobile-ios-SDK/build-ios-SDK.sh"
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
