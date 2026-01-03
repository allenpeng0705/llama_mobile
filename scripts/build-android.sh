#!/bin/bash -e

# Script to build the llama_mobile Android library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to root directory for consistent path references
cd "$ROOT_DIR"

# Show help message
show_help() {
    echo "Usage: ./build-android.sh [OPTIONS]"
    echo ""
    echo "Builds the llama_mobile Android library with cross-platform support."
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message and exit"
    echo "  --abi=ABI1,ABI2         Specify which ABIs to build (default: arm64-v8a,x86_64)"
    echo "  --ndk-version=VERSION   Use specific NDK version (default: 29.0.14206865)"
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
    exit 0
}

# Default values

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;
        --abi=*) ABIS="${1#*=}" ;;
        --ndk-version=*) NDK_VERSION="${1#*=}" ;;
        *) echo "Unknown parameter: $1" && show_help ;;
    esac
done

# Simple logging function
log_message() {
    echo "[$(date '+%H:%M:%S')] $1"
}

script_progress() {
    log_message "[PROGRESS] $1"
}

echo "=== Building llama_mobile Android library ==="

# Check if necessary directories exist
echo -n "Checking for lib directory... "
if [ ! -d "./lib" ]; then
    echo "✗"
    echo "Error: lib directory not found at $ROOT_DIR/lib!"
    echo "Please ensure you're in the correct directory and the lib folder exists."
    exit 1
fi
echo "✓"

# NDK and CMake configuration
NDK_VERSION=29.0.14206865
ANDROID_PLATFORM=android-21
CMAKE_BUILD_TYPE=Release



# Set default ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME not set, trying to detect from system..."
    
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
        echo "❌ Unsupported operating system: $OS"
        exit 1
    fi
    
    # Check common paths first (fast and reliable)
    for path in "${COMMON_PATHS[@]}"; do
        if [ -d "$path" ]; then
            ANDROID_HOME=$path
            echo "✅ Detected ANDROID_HOME: $ANDROID_HOME"
            break
        fi
    done
    
    # Final check: if still not found, prompt user
    if [ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
        echo "❌ Failed to auto-detect ANDROID_HOME"
        echo ""
        echo "Please set the ANDROID_HOME environment variable manually:"
        echo ""
        echo "On macOS/Linux:"
        echo "  export ANDROID_HOME=/path/to/your/android/sdk"
        echo "  ./scripts/build-android.sh"
        echo ""
        echo "On Windows (Git Bash):"
        echo "  export ANDROID_HOME=C:/path/to/your/android/sdk"
        echo "  ./scripts/build-android.sh"
        echo ""
        echo "Or set it permanently in your shell configuration:"
        echo "  (e.g., add to ~/.bashrc, ~/.zshrc, or ~/.profile)"
        echo ""
        exit 1
    fi
fi

# Verify ANDROID_HOME exists
if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ ANDROID_HOME path does not exist: $ANDROID_HOME"
    echo "Please set ANDROID_HOME to a valid Android SDK path."
    exit 1
fi

echo "Using ANDROID_HOME: $ANDROID_HOME"
CMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/$NDK_VERSION/build/cmake/android.toolchain.cmake

# Check if NDK is installed
echo -n "Checking for NDK $NDK_VERSION... "
if [ ! -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]; then
    echo "✗"
    echo "Error: NDK $NDK_VERSION not found at $ANDROID_HOME/ndk/$NDK_VERSION!"
    echo "Available NDK versions: $(ls -la $ANDROID_HOME/ndk/ 2>/dev/null || echo 'None found')"
    echo "Please install NDK $NDK_VERSION or update the NDK_VERSION in this script."
    exit 1
fi
echo "✓"

# Check if cmake is installed
echo -n "Checking for cmake... "
if ! command -v cmake &> /dev/null; then
    echo "✗"
    echo "Error: cmake not found!"
    echo "Please install cmake using your system package manager."
    echo "On macOS: brew install cmake"
    echo "On Ubuntu: sudo apt install cmake"
    echo "On Windows: choco install cmake"
    exit 1
fi
echo "✓"

# Set the number of CPU cores for parallel build
echo -n "Detecting CPU cores for parallel build... "
n_cpu=1
if uname -a | grep -q "Darwin"; then
    n_cpu=$(sysctl -n hw.logicalcpu 2>/dev/null || echo 1)
elif uname -a | grep -q "Linux"; then
    n_cpu=$(nproc 2>/dev/null || echo 1)
fi

echo "✓"
echo "Using $n_cpu cores for build"

# Create the llama_mobile-android directory if it doesn't exist
    echo -n "Creating necessary directories... "
for dir in "./llama_mobile-android/src/main/jniLibs" "./llama_mobile-android/src/main/cpp" "./llama_mobile-android/src/main/java/com/llamamobile"; do
    if ! mkdir -p "$dir"; then
        echo "✗"
        echo "Error: Failed to create directory $dir!"
        echo "Please check your permissions and try again."
        exit 1
    fi
    echo "✓"
done

# Set default ABIs if not specified
if [ -z "$ABIS" ]; then
    ABIS="arm64-v8a,x86_64"
fi

# Build for each specified ABI
echo -n "Building for ABIs: $ABIS... "
IFS=',' read -ra ABI_LIST <<< "$ABIS"
echo "✓"

for ABI in "${ABI_LIST[@]}"; do
    echo "\n=== Building for $ABI ==="
    BUILD_DIR=./build-android-$ABI
    
    # Remove old build directory
    echo -n "Cleaning old build directory... "
    if [ -d "$BUILD_DIR" ]; then

        if ! rm -rf "$BUILD_DIR"; then
            echo "✗"
            echo "Error: Failed to remove old build directory $BUILD_DIR!"
            echo "Please check your permissions and try again."
            exit 1
        fi
    fi
    echo "✓"
    
    # Create build directory
    echo -n "Creating build directory... "
    if ! mkdir -p "$BUILD_DIR"; then
        echo "✗"
        echo "Error: Failed to create build directory $BUILD_DIR!"
        exit 1
    fi
    echo "✓"
    
    # Add platform-specific flags
    if [ "$ABI" = "arm64-v8a" ]; then
        PLATFORM_FLAGS="-DGGML_NO_POSIX_MADVISE=ON"

    else
        PLATFORM_FLAGS=""
    fi
    
    # Configure CMake
    echo -n "Configuring CMake for $ABI... "
    CMAKE_COMMAND="cmake -S ./lib -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE=\"$CMAKE_TOOLCHAIN_FILE\" \
        -DANDROID_ABI=\"$ABI\" \
        -DANDROID_PLATFORM=\"$ANDROID_PLATFORM\" \
        -DCMAKE_BUILD_TYPE=\"$CMAKE_BUILD_TYPE\" \
        -DANDROID_STL=c++_shared \
        -DBUILD_SHARED_LIBS=ON \
        $PLATFORM_FLAGS"
    

    
    if ! eval "$CMAKE_COMMAND"; then
        echo "✗"
        echo "Error: CMake configuration failed for $ABI!"
        echo "Please check the error messages above and try again."
        echo "Common issues: Invalid ABI, missing NDK components, or incorrect ANDROID_HOME."
        exit 1
    fi
    echo "✓"
    
    # Build the library
    echo -n "Building library for $ABI... "
    BUILD_COMMAND="cmake --build $BUILD_DIR --config \"$CMAKE_BUILD_TYPE\" -j \"$n_cpu\""

    
    if ! eval "$BUILD_COMMAND"; then
        echo "✗"
        echo "Error: Build failed for $ABI!"
        echo "Please check the error messages above and try again."
        exit 1
    fi
    echo "✓"
    
    # Copy the library
    echo -n "Copying $ABI library... "
    SOURCE_LIB="$BUILD_DIR/output/lib/libllama_mobile_core.so"
    DEST_DIR="./llama_mobile-android/src/main/jniLibs/$ABI"
    DEST_LIB="$DEST_DIR/libllama_mobile.so"
    
    if [ ! -f "$SOURCE_LIB" ]; then
        echo "✗"
        echo "Error: Built library not found at $SOURCE_LIB!"
        echo "Build may have succeeded but library file is missing."
        exit 1
    fi
    
    if ! mkdir -p "$DEST_DIR"; then
        echo "✗"
        echo "Error: Failed to create destination directory $DEST_DIR!"
        exit 1
    fi
    
    if ! cp "$SOURCE_LIB" "$DEST_LIB"; then
        echo "✗"
        echo "Error: Failed to copy library from $SOURCE_LIB to $DEST_LIB!"
        exit 1
    fi
    echo "✓"
    
    # Clean up build directory
    echo -n "Cleaning up build directory... "
    if ! rm -rf "$BUILD_DIR"; then
        echo "✗"
        echo "Warning: Failed to clean up build directory $BUILD_DIR!"
        echo "You may need to delete it manually."
    else
        echo "✓"
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

set(CMAKE_CXX_STANDARD 17)
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

create_file "./llama_mobile-android/src/main/cpp/CMakeLists.txt" "$CMAKE_CONTENT"

# Create JNI wrapper implementation
cat > ./llama_mobile-android/src/main/cpp/llama_mobile_jni.cpp << EOL
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
JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_generateCompletion(
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
    
    char *result = llama_mobile_generate_completion_c(reinterpret_cast<void*>(contextHandle), &params);
    
    // Release prompt string
    releaseStringUTFChars(env, nullptr, prompt);
    
    if (result == nullptr) {
        return nullptr;
    }
    
    jstring javaResult = env->NewStringUTF(result);
    free(result);
    
    return javaResult;
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
cat > ./llama_mobile-android/src/main/AndroidManifest.xml << EOL
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.llamamobile">

    <uses-sdk
        android:minSdkVersion="21"
        android:targetSdkVersion="34" />
</manifest>
EOL

# Create Kotlin wrapper class
cat > ./llama_mobile-android/src/main/java/com/llamamobile/LlamaMobile.kt << EOL
package com.llamamobile

/**
 * LlamaMobile Android Library
 * 
 * This class provides a Kotlin wrapper around the llama_mobile C library, 
 * allowing Android applications to interact with llama models.
 */
object LlamaMobile {
    
    /**
     * Cache type enum
     */
    enum class CacheType {
        NONE,
        MEMORY
    }
    
    /**
     * Initialization parameters for creating a llama context
     * 
     * @property modelPath Path to the llama model file
     * @property nCtx Size of the context window (default: 512)
     * @property chatTemplate Chat template to use (optional)
     * @property cacheType Cache type to use (default: MEMORY)
     */
    data class InitParams(
        val modelPath: String,
        val nCtx: Int = 512,
        val chatTemplate: String? = null,
        val cacheType: CacheType = CacheType.MEMORY
    )
    
    /**
     * Completion parameters for generating text
     * 
     * @property prompt Input prompt for text generation
     * @property temperature Temperature for sampling (default: 0.8)
     * @property maxTokens Maximum number of tokens to generate (default: 100)
     */
    data class CompletionParams(
        val prompt: String,
        val temperature: Float = 0.8f,
        val maxTokens: Int = 100
    )
    
    /**
     * Loads the native libraries
     */
    init {
        System.loadLibrary("llama_mobile")
        System.loadLibrary("llama_mobile_jni")
    }
    
    /**
     * Initializes a new llama context
     * 
     * @param params Initialization parameters
     * @return Context handle, or 0 if initialization failed
     */
    external fun initContext(params: InitParams): Long
    
    /**
     * Generates text completion
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param params Completion parameters
     * @return Generated text, or null if generation failed
     */
    external fun generateCompletion(contextHandle: Long, params: CompletionParams): String?
    
    /**
     * Releases a llama context
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseContext(contextHandle: Long)
}
EOL

# Create build.gradle for the library
cat > ./llama_mobile-android/build.gradle << EOL
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
cat > ./llama_mobile-android/settings.gradle << EOL
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

echo "=== Android library build completed successfully! ==="
echo "The llama_mobile Android library has been built and placed in ./llama_mobile-android/"

# Make llama_mobile-Android-SDK self-contained
    echo "=== Making llama_mobile-Android-SDK self-contained ==="
    
    # Copy native libraries to SDK
    echo -n "Copying native libraries to SDK... "
    if mkdir -p ./llama_mobile-Android-SDK/src/main/jniLibs && cp -r ./llama_mobile-android/src/main/jniLibs/* ./llama_mobile-Android-SDK/src/main/jniLibs/; then
        echo "✓"
    else
        echo "✗"
        echo "Error: Failed to copy native libraries to SDK!"
        exit 1
    fi
    
    # Copy JNI bindings to SDK
    echo -n "Copying JNI bindings to SDK... "
    if mkdir -p ./llama_mobile-Android-SDK/src/main/cpp && cp ./llama_mobile-android/src/main/cpp/* ./llama_mobile-Android-SDK/src/main/cpp/; then
        echo "✓"
    else
        echo "✗"
        echo "Error: Failed to copy JNI bindings to SDK!"
        exit 1
    fi
    
    # Copy Kotlin wrapper to SDK
    echo -n "Copying Kotlin wrapper to SDK... "
    if mkdir -p ./llama_mobile-Android-SDK/src/main/java/com/llamamobile && cp ./llama_mobile-android/src/main/java/com/llamamobile/LlamaMobile.kt ./llama_mobile-Android-SDK/src/main/java/com/llamamobile/; then
        echo "✓"
    else
        echo "✗"
        echo "Error: Failed to copy Kotlin wrapper to SDK!"
        exit 1
    fi
    
    # Update SDK's CMakeLists.txt to use relative paths
    echo -n "Updating SDK CMakeLists.txt... "
    SDK_CMAKE_CONTENT="cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android_sdk LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
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
    \"\${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib\"
    \"\${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp\"
    \"\${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu\"
)

# Import the pre-built llama_mobile library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION \${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/\${ANDROID_ABI}/libllama_mobile.so
)

# Create a JNI wrapper
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link libraries
target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)
"
    
    if echo "$SDK_CMAKE_CONTENT" > ./llama_mobile-Android-SDK/src/main/cpp/CMakeLists.txt; then
        echo "✓"
    else
        echo "✗"
        echo "Error: Failed to update SDK CMakeLists.txt!"
        exit 1
    fi
    
    echo "=== Android SDK is now self-contained! ==="
    echo "You can now run: ./build-android.sh to rebuild the library and SDK"