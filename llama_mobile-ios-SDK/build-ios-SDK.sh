#!/bin/bash

# Build script for Llama Mobile iOS SDK
# This script copies the latest llama_mobile.xcframework from llama_mobile-ios to the SDK directory

set -e

echo "=== Llama Mobile iOS SDK Build Script ==="

# Define paths
SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SDK_DIR/.." && pwd)"
FRAMEWORK_DIR="$SDK_DIR/Frameworks"
SOURCE_FRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios"
SOURCE_FRAMEWORK_PATH="$SOURCE_FRAMEWORK_DIR/llama_mobile.xcframework"
DEST_FRAMEWORK_PATH="$FRAMEWORK_DIR/llama_mobile.xcframework"
XCFRAMEWORK_NAME="llama_mobile.xcframework"

# Check if required directories exist
echo "Checking required directories..."
if [[ ! -d "${SOURCE_FRAMEWORK_DIR}" ]]; then
    echo "Error: iOS framework directory not found at ${SOURCE_FRAMEWORK_DIR}"
    exit 1
fi

# Check if the XCFramework exists in the iOS framework directory
echo "Checking if XCFramework exists..."
if [[ ! -d "${SOURCE_FRAMEWORK_PATH}" ]]; then
    echo "Error: XCFramework not found at ${SOURCE_FRAMEWORK_PATH}"
    echo "Please build the iOS framework first by running ./scripts/build-ios.sh"
    exit 1
fi

# Create Frameworks directory in SDK if it doesn't exist
echo "Preparing SDK Frameworks directory..."
mkdir -p "${FRAMEWORK_DIR}"

# Remove old XCFramework if it exists
if [[ -d "${DEST_FRAMEWORK_PATH}" ]]; then
    echo "Removing old XCFramework..."
    rm -rf "${DEST_FRAMEWORK_PATH}"
fi

# Copy the latest framework
echo "Copying latest framework from $SOURCE_FRAMEWORK_PATH to $DEST_FRAMEWORK_PATH..."
cp -R "$SOURCE_FRAMEWORK_PATH" "$DEST_FRAMEWORK_PATH"

# Verify the copy was successful
echo "Verifying copy..."
if [[ -d "${DEST_FRAMEWORK_PATH}" ]]; then
    echo "✓ Success: XCFramework updated in the iOS SDK"
    echo "Location: ${DEST_FRAMEWORK_PATH}"
else
    echo "✗ Error: XCFramework copy failed"
    exit 1
fi

# Check if the example app can see the framework
echo "Checking example app framework path..."
EXAMPLE_FRAMEWORK_PATH="${ROOT_DIR}/examples/iOSSDKExample/llama_mobile.xcframework"
if [[ -L "${EXAMPLE_FRAMEWORK_PATH}" ]]; then
    echo "✓ Example app has symlink to framework"
else
    echo "⚠ Example app does not have symlink to framework"
    echo "You may need to update the example app's framework reference manually"
fi

echo ""
echo "SDK update complete!"
echo "The llama_mobile-ios-SDK now uses the latest XCFramework from llama_mobile-ios."
echo ""
echo "=== Build Complete ==="
