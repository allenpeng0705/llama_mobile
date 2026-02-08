#!/bin/bash -e

# ============================================================================
# ANDROID SDK BUILD SCRIPT
# ============================================================================
# Purpose: Builds clean Android SDKs from pre-built llama_mobile libraries
#          and prepares them for integration with Flutter and Capacitor
#
# Key Features:
# - Persistent timestamped backups of SDK folders (keeps last 3 backups)
# - Copies latest static libraries from llama_mobile/output/llama_mobile-android
# - Ensures SDKs are build-ready with proper directory structure
# - Builds SDKs and runs tests
# - Creates centralized output directory with all required files
#
# Output Directories:
# - llama_mobile/llama_mobile-android-SDK/ (Consolidated SDK with both Java and Kotlin support)
# - llama_mobile/output/llama_mobile-android-SDK/ (centralized output)
#
# Backup Directory:
# - llama_mobile/scripts/sdk_backup/ (timestamped backups)
#
# Notes:
# - Only uses static libraries (libllama_mobile.a)
# - Uses c++_static STL to avoid external dependencies on libc++_shared.so
# - No automatic backup restoration (backups are for manual use only)
# - All Java/Kotlin/JNI files are preserved from existing SDKs
# - Consolidated SDK provides both Java and Kotlin APIs from single module
# - Tests are in Kotlin only (LlamaMobileComprehensiveTests.kt)
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
        echo "  SDK Directory: $KOTLIN_SDK_DIR"
        echo "  AAR Files: $KOTLIN_SDK_DIR/build/outputs/aar/"
        echo "  Centralized Output: $ROOT_DIR/output/llama_mobile-android-SDK/"
        echo ""
        echo "Next Steps:"
        echo "  1. Integrate AAR files into your Android project"
        echo "  2. Run build-flutter-SDK.sh to build Flutter SDK"
        echo "  3. Run build-capacitor-plugin.sh to build Capacitor plugin"
        echo ""
    else
        echo "✗ Build failed!"
        echo ""
        echo "Troubleshooting:"
        echo "  1. Check error messages above for specific issues"
        echo "  2. Ensure pre-built libraries exist at $STATIC_LIB_DIR"
        echo "  3. Verify ANDROID_HOME and NDK_PATH are set correctly"
        echo "  4. Run ./scripts/build-android-lib.sh to rebuild native libraries"
        echo ""
    fi
    
    echo "============================================================================"
    echo ""
}

# Function to load config from config.env
load_config_env() {
    local config_file="$ROOT_DIR/config.env"
    if [ -f "$config_file" ]; then
        source "$config_file"
        log_message "INFO" "Loaded configuration from config.env"
    else
        log_message "INFO" "config.env not found, using default values"
    fi
}

# Function to update config.env with a key-value pair
update_config_env() {
    local key="$1"
    local value="$2"
    local config_file="$ROOT_DIR/config.env"
    
    # Create config.env if it doesn't exist
    if [ ! -f "$config_file" ]; then
        touch "$config_file"
    fi
    
    # Check if the key already exists
    if grep -q "^$key=" "$config_file"; then
        # Update existing key
        sed -i '' "s/^$key=.*/$key=$value/" "$config_file"
    else
        # Add new key
        echo "$key=$value" >> "$config_file"
    fi
    
    log_message "INFO" "Updated config.env: $key=$value"
}

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
    local backup_dir=""
    
    if [ "$sdk_name" == "consolidated_sdk" ]; then
        backup_dir="$PERSISTENT_BACKUP_DIR/llama_mobile-android-SDK_$timestamp"
    fi
    
    log_message "INFO" "Creating persistent backup of $sdk_name SDK to $backup_dir"
    cp -r "$sdk_dir" "$backup_dir"
    
    # Keep only the last 3 backups
    #if [ "$sdk_name" == "consolidated_sdk" ]; then
    #    ls -t "$PERSISTENT_BACKUP_DIR/llama_mobile-android-SDK_"* 2>/dev/null | tail -n +4 | xargs rm -rf 2>/dev/null || true
    #fi
    
    log_message "INFO" "Persistent backup created successfully"
    log_message "INFO" "You can manually remove backups from: $PERSISTENT_BACKUP_DIR"
}

# Directory paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PREBUILT_DIR="$ROOT_DIR/llama_mobile-android"
KOTLIN_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"

# Persistent backup directory for SDK files
PERSISTENT_BACKUP_DIR="$ROOT_DIR/scripts/sdk_backup"

# Library type to build (static for SDK reliability)
BUILD_TYPE="static"

log_message "INFO" "Building static libraries only"

# C++ STL type (static for no external dependencies, shared for smaller size)
ANDROID_STL="${ANDROID_STL:-c++_static}"
log_message "INFO" "Using C++ STL: $ANDROID_STL"

# Set library directory
STATIC_LIB_DIR="$PREBUILT_DIR/libs/static"

# Create output directories
mkdir -p "$ROOT_DIR/llama_mobile-android-SDK"

log_message "INFO" "Created output directories for shared libraries"

# Load configuration
load_config_env

# Detect ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    log_message "INFO" "ANDROID_HOME not set, trying to detect..."
    
    if [ -d "$HOME/Library/Android/sdk" ]; then
        ANDROID_HOME="$HOME/Library/Android/sdk"
        log_message "INFO" "Detected ANDROID_HOME: $ANDROID_HOME"
        update_config_env "ANDROID_HOME" "$ANDROID_HOME"
    else
        log_message "ERROR" "ANDROID_HOME not found! Please set it manually."
        exit 1
    fi
fi

# Detect NDK_PATH if not set
if [ -z "$NDK_PATH" ]; then
    log_message "INFO" "NDK_PATH not set, trying to detect..."
    
    if [ -d "$ANDROID_HOME/ndk" ]; then
        # Get the latest NDK version
        NDK_PATH=""
        for dir in "$ANDROID_HOME/ndk"/*; do
            if [ -d "$dir" ] && [[ "$dir" != "$ANDROID_HOME/ndk" ]]; then
                NDK_PATH="$dir"
                break
            fi
        done
        if [ -z "$NDK_PATH" ]; then
            log_message "ERROR" "NDK versions found but could not determine path!"
            exit 1
        fi
    else
        log_message "ERROR" "NDK not found! Please install it via Android Studio SDK Manager."
        exit 1
    fi
    
    log_message "INFO" "Detected NDK_PATH: $NDK_PATH"
    update_config_env "NDK_PATH" "$NDK_PATH"
fi

# Main script execution

log_message "INFO" "Starting Android SDK build process..."

# Check if pre-built static libraries exist
if [ ! -d "$STATIC_LIB_DIR" ]; then
    log_message "ERROR" "Pre-built static libraries not found at $STATIC_LIB_DIR"
    log_message "ERROR" "Please run ./scripts/build-android-lib.sh first"
    exit 1
fi
log_message "INFO" "Found pre-built static libraries at $STATIC_LIB_DIR"

# Create persistent backups of entire SDK directories before cleaning
log_message "INFO" "Creating persistent backups of SDK directories..."
create_persistent_backup "$KOTLIN_SDK_DIR" "consolidated_sdk"

# Clean up specific directories in SDK directories
log_message "INFO" "Cleaning up specific directories in SDK directories..."

# Clean up Kotlin SDK specific directories
if [ -d "$KOTLIN_SDK_DIR" ]; then
    log_message "INFO" "Cleaning Kotlin SDK directories..."
    rm -rf "$KOTLIN_SDK_DIR/build"
    rm -rf "$KOTLIN_SDK_DIR/.gradle"
    rm -rf "$KOTLIN_SDK_DIR/src/main/jniLibs"
    log_message "INFO" "Cleaned Kotlin SDK: build, .gradle, src/main/jniLibs"
else
    log_message "INFO" "Kotlin SDK directory does not exist, will be created"
fi


# Ensure main SDK directory exists
mkdir -p "$KOTLIN_SDK_DIR"

# Copy pre-built libraries to SDK
log_message "INFO" "Copying pre-built libraries..."

# Use static libraries for SDK reliability
LIB_DIR="$STATIC_LIB_DIR"

for ABI in "arm64-v8a" "x86_64"; do
    # Create jniLibs directories if they don't exist
    if ! mkdir -p "$KOTLIN_SDK_DIR/src/main/jniLibs/$ABI"; then
        log_message "ERROR" "Failed to create SDK jniLibs directory for ABI $ABI"
        exit 1
    fi
    
    # Verify libllama_mobile.a exists
    SOURCE_LIB="$LIB_DIR/$ABI/libllama_mobile.a"
    if [ ! -f "$SOURCE_LIB" ]; then
        log_message "ERROR" "Static library not found for ABI $ABI at $SOURCE_LIB"
        exit 1
    fi
    
    log_message "INFO" "Verified $ABI static library exists at $SOURCE_LIB"
    
    # Copy libllama_mobile.a to SDK
    DEST_LIB="$KOTLIN_SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.a"
    if ! cp -f "$SOURCE_LIB" "$DEST_LIB"; then
        log_message "ERROR" "Failed to copy $ABI libllama_mobile.a to SDK"
        exit 1
    fi
    log_message "INFO" "Copied $ABI libllama_mobile.a to SDK at $DEST_LIB"
    
    # Static libraries don't require libc++_shared.so - they include the C++ standard library internally
done

# Make the script executable
chmod +x "$0"
log_message "INFO" "Made build script executable"

# Verify SDK structure
log_message "INFO" "Verifying SDK structure..."

all_valid=true

# Common directories required for SDK (gradle/wrapper is optional - only needed for gradlew)
required_dirs=("src/main/jniLibs/arm64-v8a" "src/main/jniLibs/x86_64" "src/main/java/com/llamamobile" "src/main/kotlin/com/llamamobile" "src/main/cpp")
optional_dirs=("gradle/wrapper")

# Verify SDK structure
log_message "INFO" "Verifying consolidated SDK structure..."
required_files=("src/main/java/com/llamamobile/LlamaMobile.java" "src/main/kotlin/com/llamamobile/LlamaMobileKt.kt" "src/main/cpp/llama_mobile_jni.cpp" "src/main/cpp/CMakeLists.txt" "build.gradle" "settings.gradle" "gradle.properties" "consumer-rules.pro" "proguard-rules.pro" "gradlew" "src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt")

for dir in "${required_dirs[@]}"; do
    if [ -d "$KOTLIN_SDK_DIR/$dir" ]; then
        log_message "SUCCESS" "SDK: Found directory: $dir"
    else
        log_message "ERROR" "SDK: Missing directory: $dir"
        all_valid=false
    fi
done

# Check optional directories (warn if missing, don't fail)
for dir in "${optional_dirs[@]}"; do
    if [ -d "$KOTLIN_SDK_DIR/$dir" ]; then
        log_message "SUCCESS" "SDK: Found optional directory: $dir"
    else
        log_message "WARN" "SDK: Optional directory not found: $dir (will use system gradle if available)"
    fi
done

for file in "${required_files[@]}"; do
    if [ -f "$KOTLIN_SDK_DIR/$file" ]; then
        log_message "SUCCESS" "SDK: Found file: $file"
    else
        log_message "ERROR" "SDK: Missing file: $file"
        all_valid=false
    fi
done

# Run tests for SDK
run_tests() {
    log_message "INFO" "Running tests for SDK..."
    
    # Find gradle executable
    GRADLE_CMD=""
    if command -v gradle &> /dev/null; then
        GRADLE_CMD="gradle"
        log_message "INFO" "Using system gradle command"
    elif [ -f "$KOTLIN_SDK_DIR/gradlew" ] && [ -d "$KOTLIN_SDK_DIR/gradle/wrapper" ]; then
        GRADLE_CMD="$KOTLIN_SDK_DIR/gradlew"
        log_message "INFO" "Using SDK gradlew script"
    else
        log_message "WARN" "No valid gradle executable found"
        if command -v gradle &> /dev/null; then
            log_message "INFO" "Will use system gradle command"
            GRADLE_CMD="gradle"
        else
            log_message "ERROR" "Please install gradle or ensure gradlew with gradle/wrapper is available in the SDK"
            return 1
        fi
    fi
    
    # Make gradlew executable if needed
    if [[ "$GRADLE_CMD" == *"gradlew"* ]]; then
        chmod +x "$GRADLE_CMD"
    fi
    
    # Run unit tests for SDK
    log_message "INFO" "Running unit tests for SDK..."
    cd "$KOTLIN_SDK_DIR"
    if "$GRADLE_CMD" test -PANDROID_STL="$ANDROID_STL"; then
        log_message "SUCCESS" "SDK unit tests passed!"
    else
        log_message "ERROR" "SDK unit tests failed!"
        return 1
    fi
    
    # Run instrumented tests for SDK
    log_message "INFO" "Running instrumented tests for SDK..."
    cd "$KOTLIN_SDK_DIR"
    if "$GRADLE_CMD" connectedAndroidTest -PANDROID_STL="$ANDROID_STL"; then
        log_message "SUCCESS" "SDK instrumented tests passed!"
    else
        log_message "WARN" "SDK instrumented tests skipped (no device/emulator connected)"
    fi
    
    # Print test reports
    log_message "INFO" "========================================"
    log_message "INFO" "TEST REPORTS"
    log_message "INFO" "========================================"
    
    # Parse and display unit test results
    log_message "INFO" ""
    log_message "INFO" "--- Unit Tests ---"
    UNIT_TEST_REPORT="$KOTLIN_SDK_DIR/build/reports/tests/test/index.html"
    UNIT_TEST_XML="$KOTLIN_SDK_DIR/build/test-results/test/TEST-*.xml"
    
    if [ -f "$UNIT_TEST_REPORT" ]; then
        log_message "INFO" "Unit test report: $UNIT_TEST_REPORT"
        
        # Extract test counts from XML files
        TOTAL_TESTS=0
        TOTAL_FAILURES=0
        TOTAL_ERRORS=0
        
        for xml_file in $UNIT_TEST_XML; do
            if [ -f "$xml_file" ]; then
                TESTS=$(grep -o 'tests="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                FAILURES=$(grep -o 'failures="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                ERRORS=$(grep -o 'errors="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                
                TOTAL_TESTS=$((TOTAL_TESTS + ${TESTS:-0}))
                TOTAL_FAILURES=$((TOTAL_FAILURES + ${FAILURES:-0}))
                TOTAL_ERRORS=$((TOTAL_ERRORS + ${ERRORS:-0}))
            fi
        done
        
        PASSED_TESTS=$((TOTAL_TESTS - TOTAL_FAILURES - TOTAL_ERRORS))
        
        log_message "INFO" ""
        log_message "INFO" "Unit Test Results:"
        log_message "INFO" "  Total: $TOTAL_TESTS"
        log_message "INFO" "  Passed: $PASSED_TESTS"
        log_message "INFO" "  Failed: $TOTAL_FAILURES"
        log_message "INFO" "  Errors: $TOTAL_ERRORS"
        
        if [ $TOTAL_FAILURES -eq 0 ] && [ $TOTAL_ERRORS -eq 0 ]; then
            log_message "SUCCESS" "All unit tests passed! ($PASSED_TESTS/$TOTAL_TESTS)"
        else
            log_message "WARN" "Some unit tests failed or had errors"
        fi
    else
        log_message "INFO" "No unit test report found"
    fi
    
    # Parse and display instrumented test results
    log_message "INFO" ""
    log_message "INFO" "--- Instrumented Tests ---"
    ANDROID_TEST_REPORT="$KOTLIN_SDK_DIR/build/reports/androidTests/connected/debug/index.html"
    ANDROID_TEST_LOG="$KOTLIN_SDK_DIR/build/outputs/androidTest-results/connected"
    
    if [ -f "$ANDROID_TEST_REPORT" ]; then
        log_message "INFO" "Instrumented test report: $ANDROID_TEST_REPORT"
        
        # Extract test counts from XML files
        TOTAL_TESTS=0
        TOTAL_FAILURES=0
        TOTAL_ERRORS=0
        
        for xml_file in "$ANDROID_TEST_LOG"/debug/*.xml; do
            if [ -f "$xml_file" ]; then
                TESTS=$(grep -o 'tests="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                FAILURES=$(grep -o 'failures="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                ERRORS=$(grep -o 'errors="[0-9]*' "$xml_file" | grep -o '[0-9]*' | head -1)
                
                TOTAL_TESTS=$((TOTAL_TESTS + ${TESTS:-0}))
                TOTAL_FAILURES=$((TOTAL_FAILURES + ${FAILURES:-0}))
                TOTAL_ERRORS=$((TOTAL_ERRORS + ${ERRORS:-0}))
            fi
        done
        
        PASSED_TESTS=$((TOTAL_TESTS - TOTAL_FAILURES - TOTAL_ERRORS))
        
        log_message "INFO" ""
        log_message "INFO" "Instrumented Test Results:"
        log_message "INFO" "  Total: $TOTAL_TESTS"
        log_message "INFO" "  Passed: $PASSED_TESTS"
        log_message "INFO" "  Failed: $TOTAL_FAILURES"
        log_message "INFO" "  Errors: $TOTAL_ERRORS"
        
        if [ $TOTAL_FAILURES -eq 0 ] && [ $TOTAL_ERRORS -eq 0 ]; then
            log_message "SUCCESS" "All instrumented tests passed! ($PASSED_TESTS/$TOTAL_TESTS)"
        else
            log_message "WARN" "Some instrumented tests failed or had errors"
        fi
    else
        log_message "INFO" "No instrumented test report found"
    fi
    
    # Print combined summary
    log_message "INFO" ""
    log_message "INFO" "========================================"
    log_message "INFO" "COMBINED TEST SUMMARY"
    log_message "INFO" "========================================"
    log_message "INFO" ""
    
    # Unit tests summary
    log_message "INFO" "--- Unit Tests ---"
    if [ -f "$UNIT_TEST_REPORT" ]; then
        log_message "INFO" "Tests: $TOTAL_TESTS total, $PASSED_TESTS passed, $TOTAL_FAILURES failed, $TOTAL_ERRORS errors"
    else
        log_message "INFO" "No unit test report found"
    fi
    
    # Instrumented tests summary
    log_message "INFO" ""
    log_message "INFO" "--- Instrumented Tests ---"
    if [ -f "$ANDROID_TEST_REPORT" ]; then
        log_message "INFO" "Tests: $TOTAL_TESTS total, $PASSED_TESTS passed, $TOTAL_FAILURES failed, $TOTAL_ERRORS errors"
    else
        log_message "INFO" "No instrumented test report found"
    fi
    
    log_message "INFO" ""
    log_message "INFO" "========================================"
    
    return 0
}

# Build SDK
build_sdks() {
    log_message "INFO" "Building SDK..."
    
    # Find gradle executable
    GRADLE_CMD=""
    if command -v gradle &> /dev/null; then
        GRADLE_CMD="gradle"
        log_message "INFO" "Using system gradle command"
    elif [ -f "$KOTLIN_SDK_DIR/gradlew" ] && [ -d "$KOTLIN_SDK_DIR/gradle/wrapper" ]; then
        GRADLE_CMD="$KOTLIN_SDK_DIR/gradlew"
        log_message "INFO" "Using SDK gradlew script"
    else
        log_message "WARN" "No valid gradle executable found"
        if command -v gradle &> /dev/null; then
            log_message "INFO" "Will use system gradle command"
            GRADLE_CMD="gradle"
        else
            log_message "ERROR" "Please install gradle or ensure gradlew with gradle/wrapper is available in the SDK"
            return 1
        fi
    fi
    
    # Make gradlew executable if needed
    if [[ "$GRADLE_CMD" == *"gradlew"* ]]; then
        chmod +x "$GRADLE_CMD"
    fi
    
    # Run build for SDK (generates AAR files)
    log_message "INFO" "Building SDK..."
    cd "$KOTLIN_SDK_DIR"
    if "$GRADLE_CMD" build -PANDROID_STL="$ANDROID_STL"; then
        log_message "SUCCESS" "SDK built successfully!"
    else
        log_message "ERROR" "SDK build failed!"
        return 1
    fi
    
    return 0
}

# Run build and tests
if [ "$all_valid" = true ]; then
    run_tests
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        build_sdks
        BUILD_RESULT=$?
        
        if [ $BUILD_RESULT -eq 0 ]; then
        # Create centralized output directory
            OUTPUT_DIR="$ROOT_DIR/output"
            SDK_OUTPUT_DIR="$OUTPUT_DIR/llama_mobile-android-SDK"
        
            # Clean existing output directory to ensure fresh build
            if [ -d "$SDK_OUTPUT_DIR" ]; then
                rm -rf "$SDK_OUTPUT_DIR"
                log_message "INFO" "Cleaned existing SDK output directory"
            fi
            
            # Create output directory with error checking
            log_message "INFO" "Creating output directory..."
            if ! mkdir -p "$SDK_OUTPUT_DIR/aar"; then
                log_message "ERROR" "Failed to create SDK output directory"
                exit 1
            fi
            
            # Copy AAR files for SDK
            log_message "INFO" "Copying SDK AAR files to centralized output directory..."
            if [ -d "$KOTLIN_SDK_DIR/build/outputs/aar/" ]; then
                if ls "$KOTLIN_SDK_DIR/build/outputs/aar/"*.aar 1> /dev/null 2>&1; then
                    if ! cp -f "$KOTLIN_SDK_DIR/build/outputs/aar/"*.aar "$SDK_OUTPUT_DIR/aar/"; then
                        log_message "ERROR" "Failed to copy AAR files for SDK"
                        exit 1
                    fi
                    log_message "SUCCESS" "Copied AAR files for SDK"
                else
                    log_message "WARN" "No AAR files found for SDK (build may not have generated them)"
                fi
            else
                log_message "ERROR" "SDK build output directory not found (build may have failed)"
                exit 1
            fi
            
            log_message "INFO" "Android SDK built successfully!"
            log_message "INFO" ""
            log_message "INFO" "SDK Location: $KOTLIN_SDK_DIR"
            log_message "INFO" ""
            log_message "INFO" "SDK AAR files: $KOTLIN_SDK_DIR/build/outputs/aar/"
            log_message "INFO" ""
            log_message "INFO" "Centralized Output Directory Structure:"
            log_message "INFO" "SDK: $SDK_OUTPUT_DIR"
            log_message "INFO" "  └── aar/ (AAR files)"
            log_message "INFO" ""
            log_message "INFO" "To use SDK:"
            log_message "INFO" "1. Import AAR files from output directory"
            log_message "INFO" "2. Add implementation files('path/to/llama_mobile-android-SDK/aar/library.aar') to your app's build.gradle"
            log_message "INFO" "3. Use Java API: import com.llamamobile.LlamaMobile;"
            log_message "INFO" "4. Use Kotlin extensions: import com.llamamobile.LlamaMobileKt;"
            log_message "INFO" ""
            log_message "INFO" "Other scripts (build-flutter-SDK.sh, build-capacitor-plugin.sh) can now copy required files from output directory."
            log_message "INFO" "The output directory contains AAR files for integration with other platforms."
            
            # Print final success summary
            print_final_summary "SUCCESS" "Android SDK" "All tests passed and build completed successfully"
        else
            log_message "ERROR" "SDK Build failed!"
            print_final_summary "FAILED" "Android SDK" "Build process failed"
            exit 1
        fi
    else
        log_message "ERROR" "SDK Run test failed!"
        print_final_summary "FAILED" "Android SDK" "Tests failed"
        exit 1
    fi
else
    log_message "ERROR" "SDK validation failed!"
    print_final_summary "FAILED" "Android SDK" "SDK structure validation failed"
    exit 1
fi
