#!/bin/bash

# Shell script to update version across all SDKs based on llama_mobile_version.h

# Get project root directory
project_root=$(dirname "$(dirname "$0")")

# Read version from llama_mobile_version.h
version_header="$project_root/lib/llama_mobile_version.h"
version_string=$(grep "#define LLAMA_MOBILE_VERSION_STRING" "$version_header" | awk -F'"' '{print $2}')

echo "Updating all SDKs to version $version_string"
echo "=" $(printf "=%.0s" {1..48})

# 1. Update iOS SDK (podspec)
echo "1. Updating iOS SDK version..."
ios_podspec="$project_root/llama_mobile-ios-SDK/llama_mobile.podspec"
# The iOS podspec already has logic to read from the header file, so we just verify it
echo "   iOS SDK podspec is configured to read version from header file"

# 2. Update Flutter SDK
echo "2. Updating Flutter SDK version..."

# Update Flutter pubspec.yaml
pubspec="$project_root/llama_mobile-flutter-SDK/pubspec.yaml"
sed -i '' "s/version: .*/version: $version_string/" "$pubspec"
echo "   Updated Flutter pubspec.yaml to $version_string"

# Update Flutter Android build.gradle
android_build="$project_root/llama_mobile-flutter-SDK/android/build.gradle"
sed -i '' '/^version = /s/"[^"]*"/"'"$version_string"'"/' "$android_build"
echo "   Updated Flutter Android build.gradle to $version_string"

# 3. Update Capacitor plugin
echo "3. Updating Capacitor plugin version..."

# Update Capacitor package.json
capacitor_package="$project_root/llama_mobile-capacitor-plugin/package.json"
sed -i '' "s/version: .*/version: $version_string/" "$capacitor_package"
echo "   Updated Capacitor package.json to $version_string"

# 4. Update Android SDK
echo "4. Updating Android SDK version..."

# Update Android SDK build.gradle
android_sdk_build="$project_root/llama_mobile-android-SDK/build.gradle"
sed -i '' '/^version = /s/"[^"]*"/"'"$version_string"'"/' "$android_sdk_build"
echo "   Updated Android SDK build.gradle to $version_string"

echo "=" $(printf "=%.0s" {1..48})
echo "All SDKs updated successfully to version $version_string!"
