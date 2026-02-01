#!/bin/bash -e

# Version sync script for Flutter SDK

VERSION_FILE="$(dirname "$0")/../lib/llama_mobile_version.h"
PUBSPEC_FILE="$(dirname "$0")/../llama_mobile-flutter-SDK/pubspec.yaml"

if [ ! -f "$VERSION_FILE" ]; then
    echo "ERROR: Version file not found: $VERSION_FILE"
    exit 1
fi

if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "ERROR: pubspec.yaml not found: $PUBSPEC_FILE"
    exit 1
fi

MAJOR=$(grep "^#define LLAMA_MOBILE_VERSION_MAJOR" "$VERSION_FILE" | awk '{print $3}')
MINOR=$(grep "^#define LLAMA_MOBILE_VERSION_MINOR" "$VERSION_FILE" | awk '{print $3}')
PATCH=$(grep "^#define LLAMA_MOBILE_VERSION_PATCH" "$VERSION_FILE" | awk '{print $3}')

VERSION_STRING="${MAJOR}.${MINOR}.${PATCH}"

echo "Extracted version from llama_mobile_version.h: $VERSION_STRING"
sed -i '' 's/^version: .*/version: $VERSION_STRING/' "$PUBSPEC_FILE"

echo "Updated pubspec.yaml version to: $VERSION_STRING"
echo "SUCCESS: Version sync complete"
