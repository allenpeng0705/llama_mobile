#!/bin/bash

# Script to update the llama_mobile.xcframework in the iOS SDK directory

set -e

# Directories
ROOT_DIR="$(pwd)"
IOS_FRAMEWORK_DIR="${ROOT_DIR}/llama_mobile-ios"
SDK_FRAMEWORKS_DIR="${ROOT_DIR}/llama_mobile-ios-SDK/Frameworks"
XCFRAMEWORK_NAME="llama_mobile.xcframework"

# Check if we're in the right directory
echo "Checking current directory..."
if [[ ! -d "${IOS_FRAMEWORK_DIR}" ]] || [[ ! -d "${ROOT_DIR}/llama_mobile-ios-SDK" ]]; then
    echo "Error: Please run this script from the root directory of the llama_mobile repository"
    exit 1
fi

# Check if the XCFramework exists in the iOS framework directory
echo "Checking if XCFramework exists..."
if [[ ! -d "${IOS_FRAMEWORK_DIR}/${XCFRAMEWORK_NAME}" ]]; then
    echo "Error: XCFramework not found at ${IOS_FRAMEWORK_DIR}/${XCFRAMEWORK_NAME}"
    echo "Please build the iOS framework first by running ./build-ios.sh"
    exit 1
fi

# Create Frameworks directory in SDK if it doesn't exist
echo "Preparing SDK Frameworks directory..."
mkdir -p "${SDK_FRAMEWORKS_DIR}"

# Remove old XCFramework if it exists
if [[ -d "${SDK_FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}" ]]; then
    echo "Removing old XCFramework..."
    rm -rf "${SDK_FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}"
fi

# Copy new XCFramework
echo "Copying latest XCFramework..."
cp -r "${IOS_FRAMEWORK_DIR}/${XCFRAMEWORK_NAME}" "${SDK_FRAMEWORKS_DIR}/"

# Make the script executable
echo "Making script executable..."
chmod +x "${ROOT_DIR}/build-ios-SDK.sh"

# Verify the copy was successful
echo "Verifying copy..."
if [[ -d "${SDK_FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}" ]]; then
    echo "✓ Success: XCFramework updated in the iOS SDK"
    echo "Location: ${SDK_FRAMEWORKS_DIR}/${XCFRAMEWORK_NAME}"
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
