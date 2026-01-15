#!/bin/bash

# ============================================================================
# ANDROID BUILD SCRIPT
# This script uses variables from config.env and provides auto-detection
# ============================================================================

# Load centralized configuration from config.env
CONFIG_FILE="$(dirname "$0")/config.env"
if [ -f "$CONFIG_FILE" ]; then
    # Extract all relevant variables from config.env, excluding comments
    # Use sed to remove comments after variable assignments
    export $(grep -E '^(ANDROID_HOME|NDK_PATH|ANDROID_PLATFORM|ANDROID_BUILD_TYPE|ANDROID_ABIS|CMAKE_PATH|CMAKE_BUILD_TYPE|CMAKE_JOBS|NO_CLEAN|KEEP_BUILD|VERBOSE)=' "$CONFIG_FILE" | sed 's/\s*#.*$//' | xargs)
fi

# Local variables with defaults from centralized config
ANDROID_HOME=${ANDROID_HOME:-""}              # Path to Android SDK root directory
NDK_PATH=${NDK_PATH:-""}                     # Path to Android NDK
ANDROID_PLATFORM=${ANDROID_PLATFORM:-"android-21"} # Minimum Android API level
BUILD_TYPE=${ANDROID_BUILD_TYPE:-"Release"}    # Release or Debug build
ABIS=${ANDROID_ABIS:-"arm64-v8a,x86_64"}       # Target ABIs to build for
NUM_JOBS=${CMAKE_JOBS:-""}                    # Number of parallel build jobs

# Build behavior flags with defaults
NO_CLEAN=${NO_CLEAN:-false}                # Skip cleaning build directories
KEEP_BUILD=${KEEP_BUILD:-false}            # Keep intermediate build files
VERBOSE=${VERBOSE:-false}                  # Show verbose output

# Function to update config.env with detected values
update_config_env() {
    local var_name=$1
    local var_value=$2
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "^${var_name}=" "$CONFIG_FILE"; then
            # Update existing variable
            sed -i '' "s|^${var_name}=.*|${var_name}=\"${var_value}\"|" "$CONFIG_FILE"
        else
            # Add new variable
            echo "${var_name}=\"${var_value}\"" >> "$CONFIG_FILE"
        fi
    fi
}

# Update config.env with reasonable defaults if they're not set
if [ -z "$ANDROID_BUILD_TYPE" ]; then
    update_config_env "ANDROID_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$ANDROID_ABIS" ]; then
    update_config_env "ANDROID_ABIS" "$ABIS"
fi

if [ -z "$ANDROID_PLATFORM" ]; then
    update_config_env "ANDROID_PLATFORM" "$ANDROID_PLATFORM"
fi

if [ -z "$CMAKE_BUILD_TYPE" ]; then
    update_config_env "CMAKE_BUILD_TYPE" "$BUILD_TYPE"
fi

if [ -z "$NO_CLEAN" ]; then
    update_config_env "NO_CLEAN" "$NO_CLEAN"
fi

if [ -z "$KEEP_BUILD" ]; then
    update_config_env "KEEP_BUILD" "$KEEP_BUILD"
fi

if [ -z "$VERBOSE" ]; then
    update_config_env "VERBOSE" "$VERBOSE"
fi
CMAKE_ARGS=""                                  # Additional CMake arguments

# ============================================================================
# SCRIPT SETUP - DO NOT MODIFY BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
# ============================================================================

# Color definitions for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script to build the llama_mobile Android library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to root directory for consistent path references
cd "$ROOT_DIR" || {
    echo -e "${RED}✗ Failed to change to root directory: $ROOT_DIR${NC}"
    exit 1
}

# Show help message
show_help() {
    echo -e "${BLUE}Usage: ./build-android.sh [OPTIONS]${NC}"
    echo ""
    echo "Builds the llama_mobile Android library with cross-platform support."
    echo ""
    echo "All build variables can be found at the top of this script."
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  --abi=ABI1,ABI2         Specify which ABIs to build (default: $ABIS)"
    echo "  --ndk-version=VERSION   Use specific NDK version (default: $NDK_VERSION)"
    echo "  --build-type=TYPE       Build type: Release or Debug (default: $BUILD_TYPE)"
    echo "  -j, --jobs=N            Number of build jobs (default: auto-detected)"
    echo "  --no-clean              Skip cleaning build directories before building"
    echo "  --keep-build            Keep intermediate build files after completion"
    echo "  --verbose               Show verbose output"
    echo "  --cmake-args=ARGS       Additional CMake arguments"
    echo ""
    echo "ANDROID_HOME Configuration:"
    echo "  The script automatically detects ANDROID_HOME from common SDK paths:"
    echo "  - macOS: ~/Library/Android/sdk, ~/android-sdk"
    echo "  - Linux: ~/Android/Sdk, ~/android-sdk, /opt/android-sdk"
    echo "  - Windows: %USERPROFILE%/AppData/Local/Android/Sdk, %USERPROFILE%/Android/Sdk"
    echo ""
    echo "  If detection fails, set it manually:"
    echo "    # macOS/Linux: export ANDROID_HOME=/path/to/sdk && ./scripts/build-android.sh"
    echo "    # Windows Git Bash: export ANDROID_HOME=C:/path/to/sdk && ./scripts/build-android.sh"
    echo ""
    echo "  Or edit the config.env file in the scripts directory to set permanently:"
    echo "    scripts/config.env"
    echo "    ANDROID_HOME=/path/to/your/android/sdk"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --abi=*) ABIS="${1#*=}" ;;
        --ndk-version=*) NDK_VERSION="${1#*=}" ;;
        --build-type=*) BUILD_TYPE="${1#*=}" ;;
        -j|--jobs=*) NUM_JOBS="${1#*=}" ;;
        --no-clean) NO_CLEAN=true ;;
        --keep-build) KEEP_BUILD=true ;;
        --verbose) VERBOSE=true ;;
        --cmake-args=*) CMAKE_ARGS="${1#*=}" ;;
        *) echo -e "${RED}✗ Unknown parameter: $1${NC}" && show_help ;;
    esac
    shift
done

# Enhanced logging function
log_message() {
    local level="INFO"
    local color="${BLUE}"
    local message="$1"
    
    # Check if message starts with a log level
    if [[ "$message" =~ ^\[(ERROR|WARN|INFO|SUCCESS)\] ]]; then
        level="${BASH_REMATCH[1]}"
        message="${message:$((${#level} + 2))}"
        
        case "$level" in
            ERROR) color="${RED}" ;;
            WARN) color="${YELLOW}" ;;
            INFO) color="${BLUE}" ;;
            SUCCESS) color="${GREEN}" ;;
        esac
    fi
    
    echo -e "${color}[$(date '+%H:%M:%S')] [$level] $message${NC}"
}

# Progress message function
script_progress() {
    log_message "[INFO] $1"
}

# Verbose output function
verbose_output() {
    if [[ "$VERBOSE" == true ]]; then
        log_message "[INFO] $1"
    fi
}

# Error handling function
handle_error() {
    local exit_code=$1
    local message="$2"
    log_message "[ERROR] $message"
    log_message "[ERROR] Build failed with exit code: $exit_code"
    exit $exit_code
}

# Main script start
log_message "[INFO] === Building llama_mobile Android library ==="
log_message "[INFO] Build type: $BUILD_TYPE"
log_message "[INFO] Target ABIs: $ABIS"
log_message "[INFO] NDK version: $NDK_VERSION"

# Check if necessary directories exist
script_progress "Checking for lib directory..."
if [ ! -d "./lib" ]; then
    handle_error 1 "lib directory not found at $ROOT_DIR/lib! Please ensure you're in the correct directory and the lib folder exists."
fi
log_message "[SUCCESS] lib directory found"

# NDK and CMake configuration
CMAKE_BUILD_TYPE=$BUILD_TYPE

# Set default ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    script_progress "ANDROID_HOME not set, trying to detect from system..."
    
    # Platform-specific detection - check common paths only
    OS=$(uname -s)
    
    if [ "$OS" = "Darwin" ]; then
        # macOS
        COMMON_PATHS=("$HOME/Library/Android/sdk" "$HOME/android-sdk")
    elif [ "$OS" = "Linux" ]; then
        # Linux
        COMMON_PATHS=("$HOME/Android/Sdk" "$HOME/android-sdk" "/opt/android-sdk")
    elif [[ "$OS" = MINGW* ]]; then
        # Windows (Git Bash)
        COMMON_PATHS=("$USERPROFILE/AppData/Local/Android/Sdk" "$USERPROFILE/Android/Sdk")
    else
        handle_error 1 "Unsupported operating system: $OS"
    fi
    
    # Check common paths first (fast and reliable)
    local detected_path=""
    for path in "${COMMON_PATHS[@]}"; do
        if [ -d "$path" ]; then
            detected_path=$path
            break
        fi
    done
    
    # Final check: if still not found, prompt user
    if [ -z "$detected_path" ]; then
        log_message "[ERROR] Failed to auto-detect ANDROID_HOME"
        echo ""
        echo "Please set the ANDROID_HOME environment variable manually:"
        echo ""
        echo "On macOS/Linux:"
        echo "  export ANDROID_HOME=/path/to/your/android/sdk && ./scripts/build-android.sh"
        echo ""
        echo "On Windows (Git Bash):"
        echo "  export ANDROID_HOME=C:/path/to/your/android/sdk && ./scripts/build-android.sh"
        echo ""
        echo "Or set it permanently in your shell configuration:"
        echo "  (e.g., add to ~/.bashrc, ~/.zshrc, or ~/.profile)"
        echo ""
        exit 1
    fi
    
    ANDROID_HOME=$detected_path
    log_message "[SUCCESS] Detected ANDROID_HOME: $ANDROID_HOME"
else
    # Verify ANDROID_HOME exists
    if [ ! -d "$ANDROID_HOME" ]; then
        handle_error 1 "ANDROID_HOME path does not exist: $ANDROID_HOME. Please set ANDROID_HOME to a valid Android SDK path."
    fi
    log_message "[INFO] Using ANDROID_HOME from environment: $ANDROID_HOME"
fi

# Set CMake toolchain file
CMAKE_TOOLCHAIN_FILE="$ANDROID_HOME/ndk/$NDK_VERSION/build/cmake/android.toolchain.cmake"

# Check if NDK is installed
script_progress "Checking for NDK $NDK_VERSION..."
if [ ! -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]; then
    log_message "[ERROR] NDK $NDK_VERSION not found at $ANDROID_HOME/ndk/$NDK_VERSION!"
    log_message "[ERROR] Available NDK versions: $(ls -la "$ANDROID_HOME/ndk/" 2>/dev/null || echo 'None found')"
    log_message "[ERROR] Please install NDK $NDK_VERSION via Android Studio SDK Manager or use --ndk-version option to specify a different version."
    exit 1
fi
log_message "[SUCCESS] NDK $NDK_VERSION found"

# Check if cmake is installed
script_progress "Checking for cmake..."
if ! command -v cmake &> /dev/null; then
    handle_error 1 "cmake not found! Please install cmake using your system package manager. On macOS: brew install cmake. On Ubuntu: sudo apt install cmake. On Windows: choco install cmake."
fi
cmake_version=$(cmake --version | head -n 1)
log_message "[SUCCESS] $cmake_version found"

# Set the number of CPU cores for parallel build
script_progress "Detecting CPU cores for parallel build..."
if [ -z "$NUM_JOBS" ]; then
    if uname -a | grep -q "Darwin"; then
        NUM_JOBS=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)
    elif uname -a | grep -q "Linux"; then
        NUM_JOBS=$(nproc 2>/dev/null || echo 4)
    elif [[ "$OS" = MINGW* ]]; then
        NUM_JOBS=$(echo %NUMBER_OF_PROCESSORS% 2>/dev/null || echo 4)
    else
        NUM_JOBS=4
    fi
fi
log_message "[SUCCESS] Using $NUM_JOBS cores for build"

# Create the necessary directories for the Android library
script_progress "Creating necessary directories..."

# Create directories for both Kotlin and Java SDKs
local sdk_list=("llama_mobile-android-SDK" "llama_mobile-android-java-SDK")
local dir_list=("src/main/jniLibs" "src/main/cpp" "src/main/assets/grammars")

local all_created=true
for sdk in "${sdk_list[@]}"; do
    for dir in "${dir_list[@]}"; do
        local full_dir="./$sdk/$dir"
        verbose_output "Creating directory: $full_dir"
        if ! mkdir -p "$full_dir" 2>/dev/null; then
            log_message "[ERROR] Failed to create directory $full_dir!"
            log_message "[ERROR] Please check your permissions and try again."
            all_created=false
        fi
    done
done

if [ "$all_created" = true ]; then
    log_message "[SUCCESS] All directories created successfully"
else
    handle_error 1 "Failed to create some directories. Please check permissions."
fi

# Copy grammar files to assets for both SDKs
script_progress "Copying grammar files to assets..."

GRAMMAR_SRC_DIR="./lib/grammars"

# Copy to all SDKs
local dest_dirs=(
    "./llama_mobile-android-SDK/src/main/assets/grammars"
    "./llama_mobile-android-java-SDK/src/main/assets/grammars"
)

if [ -d "$GRAMMAR_SRC_DIR" ]; then
    # Check if there are grammar files
    if compgen -G "$GRAMMAR_SRC_DIR/*.gbnf" > /dev/null; then
        local all_copied=true
        for dest_dir in "${dest_dirs[@]}"; do
            verbose_output "Copying grammar files to: $dest_dir"
            if cp "$GRAMMAR_SRC_DIR"/*.gbnf "$dest_dir/" 2>/dev/null; then
                local count=$(ls -la "$dest_dir"/*.gbnf 2>/dev/null | wc -l)
                verbose_output "Copied $count grammar files to $dest_dir"
            else
                log_message "[ERROR] Failed to copy grammar files to $dest_dir!"
                all_copied=false
            fi
        done
        
        if [ "$all_copied" = true ]; then
            log_message "[SUCCESS] Grammar files copied successfully"
        else
            log_message "[WARN] Failed to copy grammar files to some directories."
        fi
    else
        log_message "[WARN] No grammar files (*.gbnf) found in $GRAMMAR_SRC_DIR"
    fi
else
    log_message "[WARN] Grammar source directory not found at $GRAMMAR_SRC_DIR"
    log_message "[WARN] Grammar files will not be included in the build."
fi

# Build for each specified ABI
log_message "[INFO] Building for ABIs: $ABIS"
IFS=',' read -ra ABI_LIST <<< "$ABIS"

for ABI in "${ABI_LIST[@]}"; do
    log_message "[INFO] \n=== Building for $ABI ==="
    BUILD_DIR=./build-android-$ABI
    
    # Remove old build directory if requested
    if [[ "$NO_CLEAN" = false ]]; then
        script_progress "Cleaning old build directory..."
        if [ -d "$BUILD_DIR" ]; then
            verbose_output "Removing old build directory: $BUILD_DIR"
            if ! rm -rf "$BUILD_DIR" 2>/dev/null; then
                log_message "[ERROR] Failed to remove old build directory $BUILD_DIR!"
                log_message "[ERROR] Please check your permissions and try again."
                exit 1
            fi
            log_message "[SUCCESS] Old build directory cleaned"
        else
            verbose_output "No existing build directory found: $BUILD_DIR"
            log_message "[INFO] No existing build directory to clean"
        fi
    else
        log_message "[INFO] Skipping build directory cleaning (--no-clean specified)"
    fi
    
    # Create build directory
    script_progress "Creating build directory..."
    if ! mkdir -p "$BUILD_DIR" 2>/dev/null; then
        handle_error 1 "Failed to create build directory $BUILD_DIR! Please check your permissions."
    fi
    log_message "[SUCCESS] Build directory created: $BUILD_DIR"
    
    # Add platform-specific flags
    if [ "$ABI" = "arm64-v8a" ]; then
        PLATFORM_FLAGS="-DGGML_NO_POSIX_MADVISE=ON"
    else
        PLATFORM_FLAGS=""
    fi
    verbose_output "Platform flags for $ABI: $PLATFORM_FLAGS"
    
    # Configure CMake
    script_progress "Configuring CMake for $ABI..."
    CMAKE_COMMAND="cmake -S ./lib -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE=\"$CMAKE_TOOLCHAIN_FILE\" \
        -DANDROID_ABI=\"$ABI\" \
        -DANDROID_PLATFORM=\"$ANDROID_PLATFORM\" \
        -DCMAKE_BUILD_TYPE=\"$CMAKE_BUILD_TYPE\" \
        -DANDROID_STL=c++_shared \
        -DBUILD_SHARED_LIBS=ON \
        $PLATFORM_FLAGS \
        $CMAKE_ARGS"
    
    verbose_output "CMake command: $CMAKE_COMMAND"
    
    if ! eval "$CMAKE_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|CMake Error|CMake Warning)" || true; fi); then
        handle_error 1 "CMake configuration failed for $ABI! Please check the error messages above. Common issues: Invalid ABI, missing NDK components, or incorrect ANDROID_HOME."
    fi
    log_message "[SUCCESS] CMake configuration completed for $ABI"
    
    # Build the library
    script_progress "Building library for $ABI..."
    BUILD_COMMAND="cmake --build $BUILD_DIR --config \"$CMAKE_BUILD_TYPE\" -j \"$NUM_JOBS\""
    verbose_output "Build command: $BUILD_COMMAND"
    
    if ! eval "$BUILD_COMMAND" 2>&1 | (if [ "$VERBOSE" = true ]; then cat; else grep -E "(error|warning|FAILED|FAILED_LINK|Build failed)" || true; fi); then
        handle_error 1 "Build failed for $ABI! Please check the error messages above."
    fi
    log_message "[SUCCESS] Library built successfully for $ABI"
    
    # Copy the library to both Android SDKs
    script_progress "Copying $ABI library to SDKs..."
    SOURCE_LIB="$BUILD_DIR/output/lib/libllama_mobile_core.so"
    
    if [ ! -f "$SOURCE_LIB" ]; then
        handle_error 1 "Built library not found at $SOURCE_LIB! Build may have succeeded but library file is missing."
    fi
    verbose_output "Found built library: $SOURCE_LIB"
    
    # Copy to all SDKs
    local sdk_lib_map=(
        "llama_mobile-android-SDK/src/main/jniLibs/$ABI/libllama_mobile.so"
        "llama_mobile-android-java-SDK/src/main/jniLibs/$ABI/libllama_mobile.so"
    )
    
    local all_copied=true
    for dest_lib in "${sdk_lib_map[@]}"; do
        local dest_dir=$(dirname "$dest_lib")
        verbose_output "Copying to: $dest_lib"
        
        if ! mkdir -p "$dest_dir" 2>/dev/null; then
            log_message "[ERROR] Failed to create destination directory $dest_dir!"
            all_copied=false
            continue
        fi
        
        if ! cp "$SOURCE_LIB" "$dest_lib" 2>/dev/null; then
            log_message "[ERROR] Failed to copy library from $SOURCE_LIB to $dest_lib!"
            all_copied=false
        fi
    done
    
    if [ "$all_copied" = true ]; then
        log_message "[SUCCESS] $ABI library copied to all SDKs"
    else
        handle_error 1 "Failed to copy $ABI library to some SDKs."
    fi
    
    # Clean up build directory if requested
    if [[ "$KEEP_BUILD" = false ]]; then
        script_progress "Cleaning up build directory..."
        if ! rm -rf "$BUILD_DIR" 2>/dev/null; then
            log_message "[WARN] Failed to clean up build directory $BUILD_DIR!"
            log_message "[WARN] You may need to delete it manually."
        else
            log_message "[SUCCESS] Build directory cleaned up: $BUILD_DIR"
        fi
    else
        log_message "[INFO] Keeping build directory (--keep-build specified): $BUILD_DIR"
    fi
done

# Make the script executable
echo -n "Making script executable... "
if ! chmod +x "$SCRIPT_DIR/build-android.sh"; then
    echo "✗"
    echo "Warning: Failed to make script executable!"
    echo "You may need to run: chmod +x $SCRIPT_DIR/build-android.sh"
else
    echo "✓"
fi

# Function to create a file with error checking
function create_file() {
    local file_path="$1"
    local file_name=$(basename "$file_path")
    local content="$2"
    
    echo -n "Creating $file_name... "
    
    if ! echo "$content" > "$file_path"; then
        echo "✗"
        echo "Error: Failed to create $file_path!"
        echo "Please check your permissions and try again."
        exit 1
    fi
    
    echo "✓"
}

# Create CMakeLists.txt for the Android library
CMAKE_CONTENT="cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add definitions
add_definitions(
    -DNDEBUG
    -DLM_GGML_USE_CPU
    -DLM_GGML_USE_OPENCL=OFF
    -DGGML_NO_POSIX_MADVISE
)

# Include directories
include_directories(
    \"${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib\"
    \"${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp\"
    \"${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu\"
)

# Import the pre-built llama_mobile library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
)

# Create a JNI wrapper
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link libraries
target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)
"

create_file "./llama_mobile-android-SDK/src/main/cpp/CMakeLists.txt" "$CMAKE_CONTENT"

# Create JNI wrapper implementation
cat > ./llama_mobile-android-SDK/src/main/cpp/llama_mobile_jni.cpp << EOL
// JNI wrapper for llama_mobile Android library
#include <jni.h>
#include <string>
#include <cstring>

// Include the llama_mobile headers
#include "llama_mobile_api.h"

#ifdef __cplusplus
extern "C" {
#endif

// JNI helper function to convert jstring to const char*
static const char* getStringUTFChars(JNIEnv* env, jstring str) {
    if (str == nullptr) {
        return nullptr;
    }
    return env->GetStringUTFChars(str, nullptr);
}

// JNI helper function to release const char*
static void releaseStringUTFChars(JNIEnv* env, jstring str, const char* cStr) {
    if (str != nullptr && cStr != nullptr) {
        env->ReleaseStringUTFChars(str, cStr);
    }
}

// Helper function to extract InitParams from Java object
static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate) {
    jclass paramsClass = env->GetObjectClass(initParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID modelPathField = env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;");
    jfieldID nCtxField = env->GetFieldID(paramsClass, "nCtx", "I");
    jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
    jfieldID cacheTypeField = env->GetFieldID(paramsClass, "cacheType", "Lcom/llamamobile/LlamaMobile$CacheType;");
    
    if (modelPathField == nullptr || nCtxField == nullptr || chatTemplateField == nullptr || cacheTypeField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
    jint nCtx = env->GetIntField(initParamsObj, nCtxField);
    jstring chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
    jobject cacheTypeObj = env->GetObjectField(initParamsObj, cacheTypeField);
    
    // Get cache type enum value
    jint cacheType = 0; // Default to NONE
    if (cacheTypeObj != nullptr) {
        jclass cacheTypeClass = env->GetObjectClass(cacheTypeObj);
        jmethodID ordinalMethod = env->GetMethodID(cacheTypeClass, "ordinal", "()I");
        if (ordinalMethod != nullptr) {
            cacheType = env->CallIntMethod(cacheTypeObj, ordinalMethod);
        }
        env->DeleteLocalRef(cacheTypeClass);
    }
    
    // Convert strings
    modelPath = getStringUTFChars(env, modelPathStr);
    chatTemplate = getStringUTFChars(env, chatTemplateStr);
    
    // Set params
    params.model_path = modelPath;
    params.n_ctx = nCtx;
    params.chat_template = chatTemplate;
    params.cache_type = cacheType;
    params.progress_callback = nullptr;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(modelPathStr);
    env->DeleteLocalRef(chatTemplateStr);
    env->DeleteLocalRef(cacheTypeObj);
    
    return true;
}

// Extract CompletionParams from Java object
static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt) {
    jclass paramsClass = env->GetObjectClass(completionParamsObj);
    if (paramsClass == nullptr) {
        return false;
    }
    
    // Get fields
    jfieldID promptField = env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;");
    jfieldID temperatureField = env->GetFieldID(paramsClass, "temperature", "F");
    jfieldID maxTokensField = env->GetFieldID(paramsClass, "maxTokens", "I");
    
    if (promptField == nullptr || temperatureField == nullptr || maxTokensField == nullptr) {
        env->DeleteLocalRef(paramsClass);
        return false;
    }
    
    // Extract values
    jstring promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
    jfloat temperature = env->GetFloatField(completionParamsObj, temperatureField);
    jint maxTokens = env->GetIntField(completionParamsObj, maxTokensField);
    
    // Convert string
    prompt = getStringUTFChars(env, promptStr);
    
    // Set params
    params.prompt = prompt;
    params.temperature = temperature;
    params.max_new_tokens = maxTokens;
    
    env->DeleteLocalRef(paramsClass);
    env->DeleteLocalRef(promptStr);
    
    return true;
}

// Initialize context
JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(
    JNIEnv *env, jobject thiz, jobject initParamsObj) {
    
    llama_mobile_init_params_c_t params = {};
    const char* modelPath = nullptr;
    const char* chatTemplate = nullptr;
    
    if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate)) {
        return 0;
    }
    
    if (modelPath == nullptr) {
        return 0;
    }
    
    void *context = llama_mobile_init_context_c(&params);
    
    // Release strings
    releaseStringUTFChars(env, nullptr, modelPath);
    releaseStringUTFChars(env, nullptr, chatTemplate);
    
    return reinterpret_cast<jlong>(context);
}

// Generate completion
JNIEXPORT jobject JNICALL Java_com_llamamobile_LlamaMobile_generateCompletion(
    JNIEnv *env, jobject thiz, jlong contextHandle, jobject completionParamsObj) {
    
    if (contextHandle == 0) {
        return nullptr;
    }
    
    llama_mobile_completion_params_c_t params = {};
    const char* prompt = nullptr;
    
    if (!extractCompletionParams(env, completionParamsObj, params, prompt)) {
        return nullptr;
    }
    
    if (prompt == nullptr) {
        return nullptr;
    }
    
    llama_mobile_completion_result_c_t result = {};
    int status = llama_mobile_completion_c(reinterpret_cast<void*>(contextHandle), &params, &result);
    
    // Release prompt string
    releaseStringUTFChars(env, nullptr, prompt);
    
    if (status != 0 || result.text == nullptr) {
        return nullptr;
    }
    
    // Find the CompletionResult class
    jclass completionResultClass = env->FindClass("com/llamamobile/LlamaMobile$CompletionResult");
    if (completionResultClass == nullptr) {
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    // Get the constructor
    jmethodID constructor = env->GetMethodID(completionResultClass, "<init>", "(Ljava/lang/String;IIZZZ)V");
    if (constructor == nullptr) {
        env->DeleteLocalRef(completionResultClass);
        llama_mobile_free_completion_result_members_c(&result);
        return nullptr;
    }
    
    // Create the CompletionResult object
    jstring text = env->NewStringUTF(result.text);
    jobject completionResult = env->NewObject(
        completionResultClass,
        constructor,
        text,
        result.tokens_predicted,    // tokensGenerated
        result.tokens_evaluated,    // tokensEvaluated
        result.truncated,           // truncated
        result.stopped_eos,         // stoppedEos
        result.stopped_word,        // stoppedWord
        result.stopped_limit        // stoppedLimit
    );
    
    // Release resources
    env->DeleteLocalRef(text);
    env->DeleteLocalRef(completionResultClass);
    llama_mobile_free_completion_result_members_c(&result);
    
    return completionResult;
}

// Release context
JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(
    JNIEnv *env, jobject thiz, jlong contextHandle) {
    
    if (contextHandle != 0) {
        llama_mobile_release_context_c(reinterpret_cast<void*>(contextHandle));
    }
}

#ifdef __cplusplus
}
#endif
EOL

# Create AndroidManifest.xml
cat > ./llama_mobile-android-SDK/src/main/AndroidManifest.xml << EOL
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.llamamobile">

    <uses-sdk
        android:minSdkVersion="21"
        android:targetSdkVersion="34" />
</manifest>
EOL



# Create Kotlin wrapper class - commented out since we've already manually updated it
# cat > ./llama_mobile-android-SDK/src/main/java/com/llamamobile/LlamaMobile.kt << EOL
# package com.llamamobile
#
# /**
#  * LlamaMobile Android Library
#  * 
#  * This class provides a Kotlin wrapper around the llama_mobile C library, 
#  * allowing Android applications to interact with llama models.
#  */
# object LlamaMobile {
#     
#     /**
#      * Cache type enum
#      */
#     enum class CacheType {
#         NONE,
#         MEMORY
#     }
#     
#     /**
#      * Initialization parameters for creating a llama context
#      * 
#      * @property modelPath Path to the llama model file
#      * @property nCtx Size of the context window (default: 512)
#      * @property chatTemplate Chat template to use (optional)
#      * @property cacheType Cache type to use (default: MEMORY)
#      */
#     data class InitParams(
#         val modelPath: String,
#         val nCtx: Int = 512,
#         val chatTemplate: String? = null,
#         val cacheType: CacheType = CacheType.MEMORY
#     )
#     
#     /**
#      * Completion parameters for generating text
#      * 
#      * @property prompt Input prompt for text generation
#      * @property temperature Temperature for sampling (default: 0.8)
#      * @property maxTokens Maximum number of tokens to generate (default: 100)
#      */
#     data class CompletionParams(
#         val prompt: String,
#         val temperature: Float = 0.8f,
#         val maxTokens: Int = 100
#     )
#     
#     /**
#      * Loads the native libraries
#      */
#     init {
#         System.loadLibrary("llama_mobile")
#         System.loadLibrary("llama_mobile_jni")
#     }
#     
#     /**
#      * Initializes a new llama context
#      * 
#      * @param params Initialization parameters
#      * @return Context handle, or 0 if initialization failed
#      */
#     external fun initContext(params: InitParams): Long
#     
#     /**
#      * Generates text completion
#      * 
#      * @param contextHandle Context handle obtained from initContext
#      * @param params Completion parameters
#      * @return Generated text, or null if generation failed
#      */
#     external fun generateCompletion(contextHandle: Long, params: CompletionParams): String?
#     
#     /**
#      * Releases a llama context
#      * 
#      * @param contextHandle Context handle obtained from initContext
#      */
#     external fun releaseContext(contextHandle: Long)
# }
# EOL

# Create build.gradle for the library
cat > ./llama_mobile-android-SDK/build.gradle << EOL
plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.llamamobile'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
            version "3.22.1"
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOL

# Create settings.gradle
cat > ./llama_mobile-android-SDK/settings.gradle << EOL
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "llama_mobile"
EOL

echo "=== Android libraries build completed successfully! ==="
echo "Both Kotlin and Java SDKs have been built and placed in the following directories:"
echo "- Kotlin SDK: ./llama_mobile-android-SDK/"
echo "- Java SDK: ./llama_mobile-android-java-SDK/"
echo ""
echo "To use the Kotlin SDK:"
echo "- Add as module: Import llama_mobile-android-SDK directory into your Android Studio project"
echo "- Or use as standalone SDK: Copy the llama_mobile-android-SDK directory to your project"
echo ""
echo "To use the Java SDK:"
echo "- Add as module: Import llama_mobile-android-java-SDK directory into your Android Studio project"
echo "- Or use as standalone SDK: Copy the llama_mobile-android-java-SDK directory to your project"
