#!/bin/bash

# Generate Xcode project directly in the SDK directory with iOS configuration

echo "🔧 Generating Xcode project for iOS in llama_mobile-ios-SDK directory..."

# Remove any existing CMake-generated files (optional but recommended)
rm -rf CMakeFiles
rm -f CMakeCache.txt
rm -f cmake_install.cmake
rm -f Makefile
rm -f *.xcodeproj
rm -rf Debug Release build

# Run CMake to generate the Xcode project for iOS only (iPhone/iPad)
cmake . -GXcode \
    -DCMAKE_OSX_SYSROOT=iphoneos \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
    -DCMAKE_XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY="1,2" \
    -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=NO \
    -DCMAKE_XCODE_ATTRIBUTE_SUPPORTED_PLATFORMS="iphoneos iphonesimulator" \
    -DCMAKE_XCODE_ATTRIBUTE_VALID_ARCHS="arm64" \
    -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=YES

echo "✅ iOS Xcode project generated successfully!"
echo "📁 Project location: $(pwd)/llama_mobile.xcodeproj"
echo "📱 Configured for iPhone and iPad (device family 1,2)"
echo "💡 Use: open llama_mobile.xcodeproj to open it in Xcode"
