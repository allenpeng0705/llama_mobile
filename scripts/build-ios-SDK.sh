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

# Function to print final summary
print_final_summary() {
    local status="$1"
    local sdk_name="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo ""
    echo "============================================================================"
    echo "                    BUILD SUMMARY - $timestamp"
    echo "============================================================================"
    echo ""
    echo "SDK: $sdk_name"
    echo "Status: $status"
    echo "Message: $message"
    echo ""
    
    if [ "$status" = "SUCCESS" ]; then
        echo "✓ Build completed successfully!"
        echo ""
        echo "Output Locations:"
        echo "  SDK Directory: $SDK_DIR"
        echo "  Framework Bundle: $SDK_DIR/${FRAMEWORK_NAME}Bundle"
        echo "  XCFramework: $SDK_DIR/$XCFRAMEWORK_NAME"
        echo "  Swift Wrapper: $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
        echo "  Centralized Output: $OUTPUT_SDK_DIR/${FRAMEWORK_NAME}Bundle"
        echo ""
        echo "Next Steps:"
        echo "  1. Use bundle from output directory for easy integration"
        echo "  2. Drag and drop ${FRAMEWORK_NAME}Bundle into your Xcode project"
        echo "  3. Ensure XCFramework is added to your target's Frameworks, Libraries, and Embedded Content"
        echo "  4. Import LlamaMobile in your Swift files"
        echo "  5. Run build-flutter-SDK.sh to build Flutter SDK"
        echo "  6. Run build-capacitor-plugin.sh to build Capacitor plugin"
        echo ""
    else
        echo "✗ Build failed!"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check error messages above for specific issues"
        echo "  2. Ensure pre-built framework exists at $SHARED_DIR/$XCFRAMEWORK_NAME"
        echo "  3. Run ./scripts/build-ios-framework.sh to rebuild iOS framework"
        echo "  4. Verify Swift wrapper exists at $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
        echo "  5. Check XCFramework contains required platforms (ios-arm64, ios-arm64-simulator)"
        echo ""
    fi
    
    echo "============================================================================"
    echo ""
}

# Directory paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FRAMEWORK_DIR="$ROOT_DIR/llama_mobile-ios"
SHARED_DIR="$FRAMEWORK_DIR/shared"
SDK_DIR="$ROOT_DIR/llama_mobile-ios-SDK"
FRAMEWORK_NAME="llama_mobile"
XCFRAMEWORK_NAME="${FRAMEWORK_NAME}.xcframework"
OUTPUT_DIR="$ROOT_DIR/output"
OUTPUT_SDK_DIR="$OUTPUT_DIR/llama_mobile-iOS-SDK"

# Persistent backup directory for SDK files
PERSISTENT_BACKUP_DIR="$ROOT_DIR/scripts/sdk_backup"

# Function to create persistent backup of SDK directories
create_persistent_backup() {
    local sdk_dir="$1"
    local sdk_name="$2"
    
    if [ ! -d "$sdk_dir" ]; then
        log_message "INFO" "No $sdk_name SDK directory to backup"
        return 0
    fi
    
    # Create persistent backup directory if it doesn't exist
    mkdir -p "$PERSISTENT_BACKUP_DIR"
    
    # Create timestamped backup
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_dir="$PERSISTENT_BACKUP_DIR/llama_mobile-ios-SDK_$timestamp"
    
    log_message "INFO" "Creating persistent backup of $sdk_name SDK to $backup_dir"
    cp -r "$sdk_dir" "$backup_dir"
    
    # Keep only the last 5 backups
    #ls -t "$PERSISTENT_BACKUP_DIR/llama_mobile-ios-SDK_"* 2>/dev/null | tail -n +6 | xargs rm -rf 2>/dev/null || true
    
    log_message "INFO" "Persistent backup created successfully"
    log_message "INFO" "You can manually remove backups from: $PERSISTENT_BACKUP_DIR"
}

# Function to validate SDK structure and buildability
validate_sdk() {
    local sdk_dir="$1"
    
    log_message "INFO" "Validating SDK structure and buildability..."
    
    # Check if Package.swift exists
    if [ ! -f "$sdk_dir/Package.swift" ]; then
        log_message "ERROR" "Package.swift not found in SDK directory"
        return 1
    fi
    
    # Check if Tests directory exists
    if [ ! -d "$sdk_dir/Tests" ]; then
        log_message "ERROR" "Tests directory not found in SDK directory"
        return 1
    fi
    
    # Check if Swift wrapper exists
    if [ ! -f "$sdk_dir/Sources/LlamaMobile/LlamaMobile.swift" ]; then
        log_message "ERROR" "Swift wrapper not found at Sources/LlamaMobile/LlamaMobile.swift"
        return 1
    fi
    
    # Check if XCFramework exists
    if [ ! -d "$sdk_dir/$XCFRAMEWORK_NAME" ]; then
        log_message "ERROR" "XCFramework not found at $sdk_dir/$XCFRAMEWORK_NAME"
        return 1
    fi
    
    # Determine platform
    local os_name=$(uname)
    
    if [ "$os_name" = "Darwin" ]; then
        # Running on macOS, validate XCFramework structure
        log_message "INFO" "Running on macOS, validating XCFramework structure..."
        
        # Check if XCFramework contains required platforms
        if [ ! -d "$sdk_dir/$XCFRAMEWORK_NAME/ios-arm64" ]; then
            log_message "ERROR" "XCFramework missing ios-arm64 platform"
            return 1
        fi
        
        if [ ! -d "$sdk_dir/$XCFRAMEWORK_NAME/ios-arm64-simulator" ]; then
            log_message "ERROR" "XCFramework missing ios-arm64-simulator platform"
            return 1
        fi
        
        log_message "SUCCESS" "XCFramework contains required platforms"
    else
        # Running on non-macOS, just validate structure
        log_message "INFO" "Running on non-macOS platform, validating structure only"
    fi
    
    # Check for test files
    if [ ! -f "$sdk_dir/Tests/LlamaMobileTests/LlamaMobileTests.swift" ]; then
        log_message "ERROR" "Test file not found at Tests/LlamaMobileTests/LlamaMobileTests.swift"
        cd "$ROOT_DIR"
        return 1
    fi
    
    log_message "SUCCESS" "SDK validation completed successfully"
    log_message "INFO" "Note: Full test execution requires Xcode with iOS simulator"
    log_message "INFO" "Tests may fail because they require actual model files at specific paths"
    
    cd "$ROOT_DIR"
    return 0
}

# Function to create a proper framework bundle with Swift wrapper
create_framework_bundle() {
    local sdk_dir="$1"
    local framework_name="$2"
    local bundle_dir="$sdk_dir/${framework_name}Bundle"
    
    log_message "INFO" "Creating framework bundle at $bundle_dir"
    
    # Create bundle directory structure
    mkdir -p "$bundle_dir"
    mkdir -p "$bundle_dir/Frameworks"
    mkdir -p "$bundle_dir/Sources"
    
    # Copy XCFramework to bundle
    cp -R "$sdk_dir/$XCFRAMEWORK_NAME" "$bundle_dir/Frameworks/"
    
    # Copy Swift wrapper to bundle
    if [ -d "$sdk_dir/Sources/LlamaMobile" ]; then
        cp -R "$sdk_dir/Sources/LlamaMobile" "$bundle_dir/Sources/"
        log_message "INFO" "Copied Swift wrapper to bundle"
    else
        log_message "WARNING" "Swift wrapper directory not found, skipping copy"
    fi
    
    # Copy CocoaPod spec if it exists
    if [ -f "$sdk_dir/llama_mobile.podspec" ]; then
        cp "$sdk_dir/llama_mobile.podspec" "$bundle_dir/"
        log_message "INFO" "Copied CocoaPod spec to bundle"
    else
        log_message "WARNING" "CocoaPod spec not found, skipping copy"
    fi
    
    # Copy README if it exists
    if [ -f "$sdk_dir/README.md" ]; then
        cp "$sdk_dir/README.md" "$bundle_dir/"
        log_message "INFO" "Copied README to bundle"
    else
        # Create README for bundle if it doesn't exist
        cat > "$bundle_dir/README.md" << EOF
# llama_mobile iOS Framework Bundle

This bundle contains both the llama_mobile XCFramework and the Swift wrapper for easy integration into your iOS projects.

## Contents

- **Frameworks/**: Contains the llama_mobile.xcframework with native implementations
- **Sources/**: Contains the Swift wrapper for a friendly API

## Integration Steps

1. Drag and drop the ${framework_name}Bundle folder into your Xcode project
2. Ensure the XCFramework is added to your target's Frameworks, Libraries, and Embedded Content
3. Add the Swift wrapper files to your project
4. Import LlamaMobile in your Swift files
5. Use the API as documented in the Swift wrapper

## Requirements

- iOS 15.0+
- Xcode 14.0+
EOF
        log_message "INFO" "Created README for bundle"
    fi

    log_message "INFO" "Created framework bundle with Swift wrapper"
}

# Function to copy SDK to output directory
copy_to_output() {
    local sdk_dir="$1"
    local output_sdk_dir="$2"
    local bundle_name="$3"
    
    log_message "INFO" "Copying SDK bundle to output directory: $output_sdk_dir"
    
    # Remove existing output SDK directory if it exists
    if [ -d "$output_sdk_dir" ]; then
        rm -rf "$output_sdk_dir"
        log_message "INFO" "Removed existing output SDK directory"
    fi
    
    # Create output SDK directory
    mkdir -p "$output_sdk_dir"
    
    # Copy only the bundle directory (self-contained for manual distribution)
    local bundle_dir="$sdk_dir/${bundle_name}"
    if [ -d "$bundle_dir" ]; then
        cp -R "$bundle_dir" "$output_sdk_dir/"
        log_message "SUCCESS" "SDK bundle copied to output directory: $output_sdk_dir/${bundle_name}"
    else
        log_message "ERROR" "Bundle directory not found at $bundle_dir"
        print_final_summary "FAILED" "iOS SDK" "Bundle directory not found"
        return 1
    fi
}

# Main script execution

log_message "INFO" "Starting iOS SDK build process..."

# Check if framework exists
if [ ! -d "$SHARED_DIR/$XCFRAMEWORK_NAME" ]; then
    log_message "ERROR" "Framework not found at $SHARED_DIR/$XCFRAMEWORK_NAME"
    log_message "INFO" "Please run build-ios-framework.sh first to build the iOS framework"
    print_final_summary "FAILED" "iOS SDK" "Pre-built framework not found"
    exit 1
fi

log_message "INFO" "Found pre-built framework at $SHARED_DIR/$XCFRAMEWORK_NAME"

# Create persistent backup of SDK directory before cleaning
log_message "INFO" "Creating persistent backup of SDK directory..."
create_persistent_backup "$SDK_DIR" "iOS"

# Create SDK directory if it doesn't exist
if [ ! -d "$SDK_DIR" ]; then
    log_message "INFO" "Creating SDK directory at $SDK_DIR"
    mkdir -p "$SDK_DIR"
    
    # Create Sources directory for Swift wrapper
    mkdir -p "$SDK_DIR/Sources/LlamaMobile"
    
    # Create Tests directory
    mkdir -p "$SDK_DIR/Tests/LlamaMobileTests"
    
    log_message "INFO" "SDK directory structure created. Please add your persistent files (LlamaMobile.swift, Package.swift, README.md) manually."
fi

# Clean only the XCFramework directory while preserving other files
log_message "INFO" "Cleaning only the XCFramework directory..."
if [ -d "$SDK_DIR/$XCFRAMEWORK_NAME" ]; then
    rm -rf "$SDK_DIR/$XCFRAMEWORK_NAME"
    log_message "INFO" "Removed existing XCFramework"
fi

# Also clean any existing framework bundle
if [ -d "$SDK_DIR/${FRAMEWORK_NAME}Bundle" ]; then
    rm -rf "$SDK_DIR/${FRAMEWORK_NAME}Bundle"
    log_message "INFO" "Removed existing framework bundle"
fi

# Copy the framework to SDK directory
log_message "INFO" "Copying framework to SDK directory..."
cp -R "$SHARED_DIR/$XCFRAMEWORK_NAME" "$SDK_DIR/"

# Verify the Swift wrapper exists
if [ ! -f "$SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift" ]; then
    log_message "ERROR" "Swift wrapper not found at $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
    print_final_summary "FAILED" "iOS SDK" "Swift wrapper not found"
    exit 1
fi

# Validate SDK structure and buildability before creating the framework bundle
if ! validate_sdk "$SDK_DIR"; then
    log_message "ERROR" "SDK validation failed. Aborting framework bundle creation."
    print_final_summary "FAILED" "iOS SDK" "SDK validation failed"
    exit 1
fi

# Create framework bundle with Swift wrapper
create_framework_bundle "$SDK_DIR" "$FRAMEWORK_NAME"

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

# Copy SDK to output directory
copy_to_output "$SDK_DIR" "$OUTPUT_SDK_DIR" "${FRAMEWORK_NAME}Bundle"

log_message "INFO" "iOS SDK build completed successfully!"
log_message "INFO" ""
log_message "INFO" "SDK Location: $SDK_DIR"
log_message "INFO" "Output Bundle Location: $OUTPUT_SDK_DIR/${FRAMEWORK_NAME}Bundle"
log_message "INFO" "Framework: $SDK_DIR/$XCFRAMEWORK_NAME"
log_message "INFO" "Swift Wrapper: $SDK_DIR/Sources/LlamaMobile/LlamaMobile.swift"
log_message "INFO" "Framework Bundle: $SDK_DIR/${FRAMEWORK_NAME}Bundle"
log_message "INFO" ""
log_message "INFO" "To use the SDK in your project:"
log_message "INFO" "Use the bundle from output directory:"
log_message "INFO" "1. Copy $OUTPUT_SDK_DIR/${FRAMEWORK_NAME}Bundle to your project"
log_message "INFO" "2. Drag and drop the ${FRAMEWORK_NAME}Bundle folder into your Xcode project"
log_message "INFO" "3. Ensure the XCFramework is added to your target's Frameworks, Libraries, and Embedded Content"
log_message "INFO" "4. Add the Swift wrapper files to your project"
log_message "INFO" "5. Import LlamaMobile in your Swift files"
log_message "INFO" ""
log_message "INFO" "For development, use the full SDK at: $SDK_DIR"
log_message "INFO" ""

# Print final success summary
print_final_summary "SUCCESS" "iOS SDK" "All validations passed and framework bundle created successfully"

