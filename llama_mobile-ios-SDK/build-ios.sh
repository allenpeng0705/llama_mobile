#!/bin/bash

# Build script for Llama Mobile iOS SDK
# This script copies the latest llama_mobile.xcframework from llama_mobile-ios to the SDK directory

echo "=== Llama Mobile iOS SDK Build Script ==="

# Define paths
SDK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_DIR="$SDK_DIR/Frameworks"
SOURCE_FRAMEWORK_DIR="$SDK_DIR/../llama_mobile-ios"
SOURCE_FRAMEWORK_PATH="$SOURCE_FRAMEWORK_DIR/llama_mobile.xcframework"
DEST_FRAMEWORK_PATH="$FRAMEWORK_DIR/llama_mobile.xcframework"

# Check if source framework exists
if [ ! -d "$SOURCE_FRAMEWORK_PATH" ]; then
    echo "Error: Source framework not found at $SOURCE_FRAMEWORK_PATH"
    echo "Please make sure you have built the llama_mobile-ios framework first."
    exit 1
fi

# Create Frameworks directory if it doesn't exist
if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo "Creating Frameworks directory..."
    mkdir -p "$FRAMEWORK_DIR"
fi

# Remove existing framework if it exists
if [ -d "$DEST_FRAMEWORK_PATH" ]; then
    echo "Removing existing framework..."
    rm -rf "$DEST_FRAMEWORK_PATH"
fi

# Copy the latest framework
echo "Copying latest framework from $SOURCE_FRAMEWORK_PATH to $DEST_FRAMEWORK_PATH..."
cp -R "$SOURCE_FRAMEWORK_PATH" "$DEST_FRAMEWORK_PATH"

if [ $? -eq 0 ]; then
    echo "Success: Framework copied successfully!"
    echo "SDK is now ready to use."
else
    echo "Error: Failed to copy framework."
    exit 1
fi

echo "=== Build Complete ==="
