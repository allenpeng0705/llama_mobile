#!/bin/bash -e

# ============================================================================
# IOS SDK BUILD SCRIPT
# Takes pre-built iOS framework from llama_mobile-ios and creates iOS SDK
# Output: llama_mobile/llama_mobile-ios-SDK/
# ============================================================================

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%H:%M:%S')"
    echo "[$timestamp] [$level] $message"
}

# Directory paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios"
SDK_DIR="$ROOT_DIR/llama_mobile-ios-SDK"
FRAMEWORK_NAME="llama_mobile"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"

# Main script execution

log_message "INFO" "Starting iOS SDK build process..."

# Check if framework exists
if [ ! -d "$FRAMEWORK_DIR/$XCFRAMEWORK_NAME" ]; then
    log_message "ERROR" "Framework not found at $FRAMEWORK_DIR/$XCFRAMEWORK_NAME"
    log_message "INFO" "Please run build-ios-framework.sh first to build the iOS framework"
    exit 1
fi

log_message "INFO" "Found pre-built framework at $FRAMEWORK_DIR/$XCFRAMEWORK_NAME"

# Create SDK directory if it doesn't exist
if [ ! -d "$SDK_DIR" ]; then
    log_message "INFO" "Creating SDK directory at $SDK_DIR"
    mkdir -p "$SDK_DIR"
fi

# Clean SDK directory
log_message "INFO" "Cleaning SDK directory..."
rm -rf "$SDK_DIR/$XCFRAMEWORK_NAME"
rm -rf "$SDK_DIR/.build" 2>/dev/null
rm -rf "$SDK_DIR/build" 2>/dev/null
rm -f "$SDK_DIR/CMakeCache.txt" 2>/dev/null
rm -rf "$SDK_DIR/CMakeFiles" 2>/dev/null
rm -f "$SDK_DIR/cmake_install.cmake" 2>/dev/null
rm -f "$SDK_DIR/Makefile" 2>/dev/null
rm -f "$SDK_DIR/*.xcodeproj" 2>/dev/null

# Copy the framework to SDK directory
log_message "INFO" "Copying framework to SDK directory..."
cp -R "$FRAMEWORK_DIR/$XCFRAMEWORK_NAME" "$SDK_DIR/"

# Verify the Swift wrapper exists
if [ ! -f "$SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift" ]; then
    log_message "ERROR" "Swift wrapper not found at $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
    exit 1
fi

# Create a simple test to verify the SDK structure
log_message "INFO" "Verifying SDK structure..."

# Check framework structure
if [ -f "$SDK_DIR/$XCFRAMEWORK_NAME/ios-arm64/$FRAMEWORK_NAME.framework/Headers/llama_mobile_api.h" ] && \
   [ -f "$SDK_DIR/$XCFRAMEWORK_NAME/ios-arm64-simulator/$FRAMEWORK_NAME.framework/Headers/llama_mobile_api.h" ]; then
    log_message "SUCCESS" "Framework headers are accessible"
else
    log_message "ERROR" "Framework headers not found"
    exit 1
fi

# Check Swift wrapper
if grep -q "import llama_mobile" "$SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"; then
    log_message "SUCCESS" "Swift wrapper properly imports llama_mobile module"
else
    log_message "ERROR" "Swift wrapper does not import llama_mobile module"
    exit 1
fi

# Verify the framework has the correct dependency information
log_message "INFO" "Verifying framework dependencies..."

if grep -q "RequiredFrameworks" "$SDK_DIR/$XCFRAMEWORK_NAME/Info.plist" && grep -q "Accelerate" "$SDK_DIR/$XCFRAMEWORK_NAME/Info.plist" && grep -q "Metal" "$SDK_DIR/$XCFRAMEWORK_NAME/Info.plist" && grep -q "libc++" "$SDK_DIR/$XCFRAMEWORK_NAME/Info.plist"; then
    log_message "SUCCESS" "Framework has correct dependency information (Accelerate, Metal, libc++)"
else
    log_message "WARNING" "Framework is missing dependency information. Ensure build-ios-framework.sh was run with dependency updates."
fi

log_message "INFO" "iOS SDK build completed successfully!"
log_message "INFO" ""
log_message "INFO" "SDK Location: $SDK_DIR"
log_message "INFO" "Framework: $SDK_DIR/$XCFRAMEWORK_NAME"
log_message "INFO" "Swift Wrapper: $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
log_message "INFO" ""
log_message "INFO" "To use the SDK in your project:"
log_message "INFO" "1. Add the llama_mobile.xcframework to your Xcode project"
log_message "INFO" "2. Add the LlamaMobile.swift file to your project"
log_message "INFO" "3. Import LlamaMobile in your Swift files"
log_message "INFO" "4. Use the existing API structure from LlamaMobile.swift"
log_message "INFO" ""
