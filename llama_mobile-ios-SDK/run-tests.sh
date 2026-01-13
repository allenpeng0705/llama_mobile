#!/bin/bash

# Simple script to help run LlamaMobile iOS SDK tests

echo "=== LlamaMobile iOS SDK Test Runner ==="
echo ""

# Check if we have the framework
if [ ! -d "llama_mobile.xcframework" ]; then
    echo "❌ ERROR: llama_mobile.xcframework not found in SDK directory"
    echo "Please make sure you've built the framework first using:"
    echo "  ./scripts/build-ios-framework.sh"
    echo "  ./scripts/build-ios-SDK.sh"
    exit 1
fi

echo "✅ Found llama_mobile.xcframework"
echo ""

# Check if we have the Package.swift file
echo "=== Creating Package.swift for testing ==="
if [ ! -f "Package.swift" ]; then
    cat > Package.swift << 'EOF'
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LlamaMobile",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "LlamaMobile",
            targets: ["LlamaMobile"]
        ),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "llama_mobile",
            path: "./llama_mobile.xcframework"
        ),
        .target(
            name: "LlamaMobile",
            dependencies: ["llama_mobile"],
            path: "Sources/LlamaMobile"
        ),
        .testTarget(
            name: "LlamaMobileTests",
            dependencies: ["LlamaMobile"]
        )
    ]
)
EOF
    echo "✅ Created Package.swift"
fi

echo ""
echo "=== Running tests ==="
echo "Note: Tests may fail because they require actual model files at specific paths"
echo "      You can modify test paths in Tests/LlamaMobileTests/LlamaMobileTests.swift"
echo ""

# Try to run tests - iOS simulator destination is required for this framework
# Note: We need to use xcodebuild for proper iOS destination support
echo "⚠️  Note: Swift CLI doesn't support iOS destinations directly"
echo "   For best results, use Xcode to run tests with iOS simulator"

echo ""
echo "Attempting to build for iOS simulator..."
# Try a basic build to verify the package configuration
if swift build --triple arm64-apple-ios15.0-simulator 2>&1; then
    echo "✅ Build successful for iOS simulator"
    echo ""
    echo "📱 To run tests, open the project in Xcode and run tests on iOS simulator"
else
    echo "⚠️  Build encountered issues (expected - requires proper iOS simulator setup)"
    echo "   Please use Xcode for running tests"
fi

echo ""
echo "=== Test run complete ==="
echo ""
echo "If tests fail with 'No such module' errors, you can also try:"
echo "  - Creating an Xcode project using 'swift package generate-xcodeproj'"
echo "  - Opening the generated .xcodeproj file in Xcode"
echo "  - Running tests from Xcode UI"
echo ""
echo "For more information, see the README.md file"
