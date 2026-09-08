#!/bin/bash

# Shell script to update the SDK/library versions across all SDKs to match
# llama_mobile_version.h (single source of truth: LLAMA_MOBILE_VERSION_STRING).

# Get project root directory (absolute, so the script works from any cwd)
project_root=$(cd "$(dirname "$0")/.." && pwd)

# Read version from llama_mobile_version.h
version_header="$project_root/lib/llama_mobile_version.h"
version_string=$(grep "#define LLAMA_MOBILE_VERSION_STRING" "$version_header" | awk -F'"' '{print $2}')

echo "Updating all SDKs to version $version_string"
echo "=" $(printf "=%.0s" {1..48})

# 1. Update iOS SDK (podspec)
echo "1. Updating iOS SDK version..."
ios_podspec="$project_root/llama_mobile-ios-SDK/llama_mobile.podspec"
# The iOS podspec already reads the version from llama_mobile_version.h, so we just verify it.
echo "   iOS SDK podspec is configured to read version from header file"

# 2. Update Flutter SDK
echo "2. Updating Flutter SDK version..."

# Update Flutter pubspec.yaml (keep an optional +build suffix if present)
pubspec="$project_root/llama_mobile-flutter-SDK/pubspec.yaml"
sed -E -i '' "s/^(version: )[0-9]+\.[0-9]+\.[0-9]+/\1$version_string/" "$pubspec"
echo "   Updated Flutter pubspec.yaml to $version_string"

# Update Flutter Android build.gradle
android_build="$project_root/llama_mobile-flutter-SDK/android/build.gradle"
sed -E -i '' "s/^(version = \")[0-9]+\.[0-9]+\.[0-9]+(\")/\1$version_string\2/" "$android_build"
echo "   Updated Flutter Android build.gradle to $version_string"

# Update Flutter iOS podspec(s) (s.version must match pubspec for publishing)
for flutter_podspec in \
    "$project_root/llama_mobile-flutter-SDK/ios/llama_mobile_flutter_sdk.podspec" \
    "$project_root/llama_mobile-flutter-SDK/llama_mobile_flutter_sdk.podspec"; do
    if [ -f "$flutter_podspec" ]; then
        sed -E -i '' "s/^(  s\.version[[:space:]]*=[[:space:]]*)[\"'][^\"']*[\"']/\1'$version_string'/" "$flutter_podspec"
        echo "   Updated $flutter_podspec to $version_string"
    fi
done

# 3. Update Capacitor plugin
echo "3. Updating Capacitor plugin version..."

# Update Capacitor package.json (JSON key). package-lock.json is regenerated
# by `npm install` from package.json, so it is intentionally left untouched
# (blanket-replacing it would rewrite third-party dependency versions).
capacitor_package="$project_root/llama_mobile-capacitor-plugin/package.json"
if [ -f "$capacitor_package" ]; then
    sed -E -i '' "s/(\"version\": \")[0-9]+\.[0-9]+\.[0-9]+/\1$version_string/" "$capacitor_package"
    echo "   Updated package.json to $version_string"
fi
# The Capacitor podspec derives s.version from package.json automatically.

# 4. Update Android SDK
echo "4. Updating Android SDK version..."

# Update Android SDK build.gradle
android_sdk_build="$project_root/llama_mobile-android-SDK/build.gradle"
sed -E -i '' "s/^(version = \")[0-9]+\.[0-9]+\.[0-9]+(\")/\1$version_string\2/" "$android_sdk_build"
echo "   Updated Android SDK build.gradle to $version_string"

echo "=" $(printf "=%.0s" {1..48})
echo "All SDKs updated successfully to version $version_string!"
