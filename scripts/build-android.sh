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
    echo "  The script automatically detects ANDROID_HOME from:"
    echo "  - Android Studio preferences (macOS/Linux)"
    echo "  - Windows registry (Windows Git Bash)"
    echo "  - Emulator preferences (macOS)"
    echo "  - Common SDK paths based on OS"
    echo ""
    echo "  If detection fails, set it manually:"
    echo "    # macOS/Linux: export ANDROID_HOME=/path/to/sdk && ./scripts/build-android.sh"
    echo "    # Windows Git Bash: export ANDROID_HOME=C:/path/to/sdk && ./scripts/build-android.sh"
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help) show_help ;;    
        --abi=*) ABIS="${1#*=}" ;;    
        --ndk-version=*) NDK_VERSION="${1#*=}" ;;    
        *) echo "Unknown parameter: $1" && show_help ;;    
esac
done

echo "=== Building llama_mobile Android library ==="

# Check if necessary directories exist
if [ ! -d "./lib" ]; then
    echo "Error: lib directory not found!"
    exit 1
fi

# NDK and CMake configuration
NDK_VERSION=29.0.14206865
ANDROID_PLATFORM=android-21
CMAKE_BUILD_TYPE=Release

# Set default ANDROID_HOME if not set
if [ -z "$ANDROID_HOME" ]; then
    echo "ANDROID_HOME not set, trying to detect from system..."
    
    # Platform-specific detection
    if [ "$(uname -s)" = "Darwin" ]; then
        # macOS
        echo "Detecting on macOS..."
        
        # Try to detect from Android Studio preferences
        if [ -f ~/Library/Application\ Support/Google/AndroidStudio*/options/jdk.table.xml ]; then
            AS_CONFIG=$(ls -1 ~/Library/Application\ Support/Google/AndroidStudio*/options/jdk.table.xml | sort -r | head -1)
            if [ -n "$AS_CONFIG" ]; then
                echo "Found Android Studio config: $AS_CONFIG"
                SDK_PATH=$(grep -A 10 "Android SDK" "$AS_CONFIG" | grep -o '"[^"/]*\/Android\/sdk"' | sed 's/"//g')
                if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
                    ANDROID_HOME=$SDK_PATH
                    echo "✅ Detected ANDROID_HOME from Android Studio: $ANDROID_HOME"
                fi
            fi
        fi
        
        # Try to detect from emulator preferences
        if [ -z "$ANDROID_HOME" ] && [ -f ~/Library/Preferences/com.android.Emulator.plist ]; then
            echo "Checking emulator preferences..."
            SDK_PATH=$(defaults read ~/Library/Preferences/com.android.Emulator.plist 2>/dev/null | grep -o '"[^"/]*\/Android\/sdk"' | sed 's/"//g')
            if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
                ANDROID_HOME=$SDK_PATH
                echo "✅ Detected ANDROID_HOME from emulator preferences: $ANDROID_HOME"
            fi
        fi
        
        # Fall back to default macOS path
        if [ -z "$ANDROID_HOME" ]; then
            DEFAULT_SDK=~/Library/Android/sdk
            if [ -d "$DEFAULT_SDK" ]; then
                ANDROID_HOME=$DEFAULT_SDK
                echo "✅ Using default macOS ANDROID_HOME path: $ANDROID_HOME"
            fi
        fi
        
    elif [ "$(uname -s)" = "Linux" ]; then
        # Linux
        echo "Detecting on Linux..."
        
        # Try to detect from Android Studio preferences
        if [ -f ~/.config/Google/AndroidStudio*/options/jdk.table.xml ]; then
            AS_CONFIG=$(ls -1 ~/.config/Google/AndroidStudio*/options/jdk.table.xml | sort -r | head -1)
            if [ -n "$AS_CONFIG" ]; then
                echo "Found Android Studio config: $AS_CONFIG"
                SDK_PATH=$(grep -A 10 "Android SDK" "$AS_CONFIG" | grep -o '"[^"/]*\/Android\/Sdk"' | sed 's/"//g')
                if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
                    ANDROID_HOME=$SDK_PATH
                    echo "✅ Detected ANDROID_HOME from Android Studio: $ANDROID_HOME"
                fi
            fi
        fi
        
        # Try common Linux paths
        COMMON_PATHS=("$HOME/Android/Sdk" "$HOME/android-sdk" "/opt/android-sdk")
        for path in "${COMMON_PATHS[@]}"; do
            if [ -z "$ANDROID_HOME" ] && [ -d "$path" ]; then
                ANDROID_HOME=$path
                echo "✅ Using common Linux ANDROID_HOME path: $ANDROID_HOME"
                break
            fi
        done
        
    elif [ "$(uname -s)" = "MINGW32_NT" ] || [ "$(uname -s)" = "MINGW64_NT" ]; then
        # Windows (Git Bash)
        echo "Detecting on Windows..."
        
        # Try to detect from registry
        if command -v reg &> /dev/null; then
            SDK_PATH=$(reg query "HKEY_CURRENT_USER\Software\Android SDK Tools" /v Path 2>/dev/null | grep -o '[A-Z]:\\\\[^ ]*' | head -1)
            if [ -n "$SDK_PATH" ] && [ -d "$SDK_PATH" ]; then
                ANDROID_HOME=$SDK_PATH
                echo "✅ Detected ANDROID_HOME from Windows registry: $ANDROID_HOME"
            fi
        fi
        
        # Try common Windows paths
        COMMON_PATHS=("$USERPROFILE/AppData/Local/Android/Sdk" "$USERPROFILE/Android/Sdk")
        for path in "${COMMON_PATHS[@]}"; do
            if [ -z "$ANDROID_HOME" ] && [ -d "$path" ]; then
                ANDROID_HOME=$path
                echo "✅ Using common Windows ANDROID_HOME path: $ANDROID_HOME"
                break
            fi
        done
    fi
    
    # Final check: if still not found, prompt user
    if [ -z "$ANDROID_HOME" ] || [ ! -d "$ANDROID_HOME" ]; then
        echo "❌ Failed to auto-detect ANDROID_HOME"
        echo ""
        echo "Please set the ANDROID_HOME environment variable manually:"
        echo ""
        echo "On macOS/Linux:"
        echo "  export ANDROID_HOME=/path/to/your/android/sdk"
        echo "  ./build-android.sh"
        echo ""
        echo "On Windows (Git Bash):"
        echo "  export ANDROID_HOME=C:/path/to/your/android/sdk"
        echo "  ./build-android.sh"
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
if [ ! -d "$ANDROID_HOME/ndk/$NDK_VERSION" ]; then
    echo "Error: NDK $NDK_VERSION not found!"
    echo "Available NDK versions: $(ls -la $ANDROID_HOME/ndk/)"
    echo "Please install NDK $NDK_VERSION or update the NDK_VERSION in this script."
    exit 1
fi

# Check if cmake is installed
if ! command -v cmake &> /dev/null; then
    echo "Error: cmake not found!"
    echo "Please install cmake."
    exit 1
fi

# Set the number of CPU cores for parallel build
n_cpu=1
if uname -a | grep -q "Darwin"; then
    n_cpu=$(sysctl -n hw.logicalcpu)
elif uname -a | grep -q "Linux"; then
    n_cpu=$(nproc)
fi

echo "Using $n_cpu cores for build"

# Create the llama_mobile-Android directory if it doesn't exist
mkdir -p ./llama_mobile-Android/src/main/jniLibs
mkdir -p ./llama_mobile-Android/src/main/cpp
mkdir -p ./llama_mobile-Android/src/main/java/com/llamamobile

# Set default ABIs if not specified
if [ -z "$ABIS" ]; then
    ABIS="arm64-v8a,x86_64"
fi

# Build for each specified ABI
echo "Building for ABIs: $ABIS"
IFS=',' read -ra ABI_LIST <<< "$ABIS"

for ABI in "${ABI_LIST[@]}"; do
    BUILD_DIR=./build-android-$ABI
    
    if [ -d "$BUILD_DIR" ]; then
        echo "Removing old build directory for $ABI..."
        rm -rf $BUILD_DIR
    fi
    
    echo "Building for $ABI..."
    
    # Add platform-specific flags
    if [ "$ABI" = "arm64-v8a" ]; then
        PLATFORM_FLAGS="-DGGML_NO_POSIX_MADVISE=ON"
    else
        PLATFORM_FLAGS=""
    fi
    
    cmake -S ./lib -B $BUILD_DIR \
        -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
        -DANDROID_ABI="$ABI" \
        -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
        -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
        -DANDROID_STL=c++_shared \
        -DBUILD_SHARED_LIBS=ON \
        $PLATFORM_FLAGS
    
    cmake --build $BUILD_DIR --config "$CMAKE_BUILD_TYPE" -j "$n_cpu"
    
    echo "Copying $ABI library..."
    mkdir -p ./llama_mobile-Android/src/main/jniLibs/$ABI
    cp $BUILD_DIR/output/lib/libllama_mobile_core.so ./llama_mobile-Android/src/main/jniLibs/$ABI/libllama_mobile.so
    
    # Clean up build directory
    rm -rf $BUILD_DIR
done

# Make the script executable
chmod +x ./build-android.sh

# Create CMakeLists.txt for the Android library
cat > ./llama_mobile-Android/src/main/cpp/CMakeLists.txt << EOL
cmake_minimum_required(VERSION 3.16)
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
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu"
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
EOL

# Create JNI wrapper implementation
cat > ./llama_mobile-Android/src/main/cpp/llama_mobile_jni.cpp << EOL
// JNI wrapper for llama_mobile Android library
#include <jni.h>
#include <string>
#include <cstring>

// Include the llama_mobile headers
#include "llama_mobile_unified.h"

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
cat > ./llama_mobile-Android/src/main/AndroidManifest.xml << EOL
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.llamamobile">

    <uses-sdk
        android:minSdkVersion="21"
        android:targetSdkVersion="34" />
</manifest>
EOL

# Create Kotlin wrapper class
cat > ./llama_mobile-Android/src/main/java/com/llamamobile/LlamaMobile.kt << EOL
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
cat > ./llama_mobile-Android/build.gradle << EOL
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
cat > ./llama_mobile-Android/settings.gradle << EOL
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
echo "The llama_mobile Android library has been built and placed in ./llama_mobile-Android/"
echo "You can now run: ./build-android.sh to rebuild the library"