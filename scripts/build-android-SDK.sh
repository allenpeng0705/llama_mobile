#!/bin/bash -e

# ============================================================================
# ANDROID SDK BUILD SCRIPT
# Takes pre-built Android libraries from llama_mobile-android and creates clean Android SDKs
# Output:
# - llama_mobile/llama_mobile-android-SDK/ (Kotlin SDK)
# - llama_mobile/llama_mobile-android-java-SDK/ (Java SDK)
# ============================================================================

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp="$(date '+%H:%M:%S')"
    echo "[$timestamp] [$level] $message"
}

# Directory paths
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PREBUILT_DIR="$ROOT_DIR/llama_mobile-android"
KOTLIN_SDK_DIR="$ROOT_DIR/llama_mobile-android-SDK"
JAVA_SDK_DIR="$ROOT_DIR/llama_mobile-android-java-SDK"

# Main script execution

log_message "INFO" "Starting Android SDK build process..."

# Check if pre-built libraries exist
if [ ! -d "$PREBUILT_DIR/libs" ]; then
    log_message "ERROR" "Pre-built libraries not found at $PREBUILT_DIR/libs"
    log_message "INFO" "Please ensure llama_mobile-android contains the pre-built libraries"
    exit 1
fi

log_message "INFO" "Found pre-built libraries at $PREBUILT_DIR/libs"

# Temporarily preserve Kotlin and Java SDK files
TEMP_DIR=""

# Kotlin SDK preservation
TEMP_KOTLIN=""
TEMP_KOTLIN_JNI_CPP=""
TEMP_KOTLIN_JNI_CMAKELISTS=""
TEMP_KOTLIN_UNIT_TESTS=""
TEMP_KOTLIN_INSTRUMENTED_TESTS=""
TEMP_KOTLIN_COMPREHENSIVE_TESTS=""
TEMP_KOTLIN_README=""

# Java SDK preservation
TEMP_JAVA=""
TEMP_JAVA_JNI_CPP=""
TEMP_JAVA_JNI_CMAKELISTS=""
TEMP_JAVA_UNIT_TESTS=""
TEMP_JAVA_INSTRUMENTED_TESTS=""
TEMP_JAVA_COMPREHENSIVE_TESTS=""
TEMP_JAVA_README=""

# Create temporary directory
TEMP_DIR="$(mktemp -d)"

# Preserve Kotlin SDK files if they exist
if [ -d "$KOTLIN_SDK_DIR" ]; then
    # Preserve Kotlin wrapper
    if [ -f "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.kt" ]; then
        TEMP_KOTLIN="$TEMP_DIR/LlamaMobile.kt"
        cp "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.kt" "$TEMP_KOTLIN"
        log_message "INFO" "Preserved existing Kotlin wrapper temporarily"
    fi
    
    # Preserve JNI implementation
    if [ -f "$KOTLIN_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp" ]; then
        TEMP_KOTLIN_JNI_CPP="$TEMP_DIR/kotlin_jni.cpp"
        cp "$KOTLIN_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp" "$TEMP_KOTLIN_JNI_CPP"
        log_message "INFO" "Preserved existing Kotlin JNI implementation temporarily"
    fi
    
    # Preserve CMakeLists.txt
    if [ -f "$KOTLIN_SDK_DIR/src/main/cpp/CMakeLists.txt" ]; then
        TEMP_KOTLIN_JNI_CMAKELISTS="$TEMP_DIR/kotlin_cmakelists.txt"
        cp "$KOTLIN_SDK_DIR/src/main/cpp/CMakeLists.txt" "$TEMP_KOTLIN_JNI_CMAKELISTS"
        log_message "INFO" "Preserved existing Kotlin JNI CMakeLists.txt temporarily"
    fi
    
    # Preserve Kotlin unit tests
    if [ -f "$KOTLIN_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.kt" ]; then
        TEMP_KOTLIN_UNIT_TESTS="$TEMP_DIR/LlamaMobileUnitTests.kt"
        cp "$KOTLIN_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.kt" "$TEMP_KOTLIN_UNIT_TESTS"
        log_message "INFO" "Preserved existing Kotlin unit tests temporarily"
    fi
    
    # Preserve Kotlin instrumented tests
    if [ -f "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt" ]; then
        TEMP_KOTLIN_INSTRUMENTED_TESTS="$TEMP_DIR/LlamaMobileInstrumentedTests.kt"
        cp "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt" "$TEMP_KOTLIN_INSTRUMENTED_TESTS"
        log_message "INFO" "Preserved existing Kotlin instrumented tests temporarily"
    fi
    
    # Preserve Kotlin comprehensive tests
    if [ -f "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt" ]; then
        TEMP_KOTLIN_COMPREHENSIVE_TESTS="$TEMP_DIR/LlamaMobileComprehensiveTests.kt"
        cp "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt" "$TEMP_KOTLIN_COMPREHENSIVE_TESTS"
        log_message "INFO" "Preserved existing Kotlin comprehensive tests temporarily"
    fi
    
    # Preserve Kotlin README.md
    if [ -f "$KOTLIN_SDK_DIR/README.md" ]; then
        TEMP_KOTLIN_README="$TEMP_DIR/KotlinREADME.md"
        cp "$KOTLIN_SDK_DIR/README.md" "$TEMP_KOTLIN_README"
        log_message "INFO" "Preserved existing Kotlin README.md temporarily"
    fi
fi

# Preserve Java SDK files if they exist
if [ -d "$JAVA_SDK_DIR" ]; then
    # Preserve Java wrapper
    if [ -f "$JAVA_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
        TEMP_JAVA="$TEMP_DIR/LlamaMobile.java"
        cp "$JAVA_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java" "$TEMP_JAVA"
        log_message "INFO" "Preserved existing Java wrapper temporarily"
    fi
    
    # Preserve JNI implementation
    if [ -f "$JAVA_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp" ]; then
        TEMP_JAVA_JNI_CPP="$TEMP_DIR/java_jni.cpp"
        cp "$JAVA_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp" "$TEMP_JAVA_JNI_CPP"
        log_message "INFO" "Preserved existing Java JNI implementation temporarily"
    fi
    
    # Preserve CMakeLists.txt
    if [ -f "$JAVA_SDK_DIR/src/main/cpp/CMakeLists.txt" ]; then
        TEMP_JAVA_JNI_CMAKELISTS="$TEMP_DIR/java_cmakelists.txt"
        cp "$JAVA_SDK_DIR/src/main/cpp/CMakeLists.txt" "$TEMP_JAVA_JNI_CMAKELISTS"
        log_message "INFO" "Preserved existing Java JNI CMakeLists.txt temporarily"
    fi
       
    # Preserve Java comprehensive tests if they exist
    if [ -f "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.java" ]; then
        TEMP_JAVA_COMPREHENSIVE_TESTS="$TEMP_DIR/LlamaMobileComprehensiveTests.java"
        cp "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.java" "$TEMP_JAVA_COMPREHENSIVE_TESTS"
        log_message "INFO" "Preserved existing Java comprehensive tests temporarily"
    fi
    
    # Preserve Java README.md
    if [ -f "$JAVA_SDK_DIR/README.md" ]; then
        TEMP_JAVA_README="$TEMP_DIR/JavaREADME.md"
        cp "$JAVA_SDK_DIR/README.md" "$TEMP_JAVA_README"
        log_message "INFO" "Preserved existing Java README.md temporarily"
    fi
fi

# Preserve README.md files if they exist
PRESERVED_KOTLIN_README=""
PRESERVED_JAVA_README=""

if [ -f "$KOTLIN_SDK_DIR/README.md" ]; then
    PRESERVED_KOTLIN_README="$TEMP_DIR/KotlinREADME.md"
    cp "$KOTLIN_SDK_DIR/README.md" "$PRESERVED_KOTLIN_README"
    log_message "INFO" "Preserved existing Kotlin README.md"
fi

if [ -f "$JAVA_SDK_DIR/README.md" ]; then
    PRESERVED_JAVA_README="$TEMP_DIR/JavaREADME.md"
    cp "$JAVA_SDK_DIR/README.md" "$PRESERVED_JAVA_README"
    log_message "INFO" "Preserved existing Java README.md"
fi

# Handle Kotlin SDK cleanup
if [ -d "$KOTLIN_SDK_DIR" ]; then
    # Clean up existing Kotlin SDK directory without backup
    log_message "INFO" "Removing existing Kotlin SDK directory"
    rm -rf "$KOTLIN_SDK_DIR"
fi

# Handle Java SDK cleanup
if [ -d "$JAVA_SDK_DIR" ]; then
    # Clean up existing Java SDK directory without backup
    log_message "INFO" "Removing existing Java SDK directory"
    rm -rf "$JAVA_SDK_DIR"
fi

# Create clean SDK directory structures for both Kotlin and Java
log_message "INFO" "Creating clean SDK directory structures..."

# Create Kotlin SDK directories
log_message "INFO" "Creating Kotlin SDK directories..."
mkdir -p "$KOTLIN_SDK_DIR/src/main/jniLibs/arm64-v8a"
mkdir -p "$KOTLIN_SDK_DIR/src/main/jniLibs/x86_64"
mkdir -p "$KOTLIN_SDK_DIR/src/main/assets/grammars"
mkdir -p "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile"
mkdir -p "$KOTLIN_SDK_DIR/src/main/cpp"
mkdir -p "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile"


# Create Java SDK directories
log_message "INFO" "Creating Java SDK directories..."
mkdir -p "$JAVA_SDK_DIR/src/main/jniLibs/arm64-v8a"
mkdir -p "$JAVA_SDK_DIR/src/main/jniLibs/x86_64"
mkdir -p "$JAVA_SDK_DIR/src/main/assets/grammars"
mkdir -p "$JAVA_SDK_DIR/src/main/java/com/llamamobile"
mkdir -p "$JAVA_SDK_DIR/src/main/cpp"

mkdir -p "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile"


# Function to find libc++_shared.so in NDK
find_libcpp_shared() {
    local abi="$1"
    local ndk_abi_map=("arm64-v8a"="aarch64-linux-android" "x86_64"="x86_64-linux-android")
    local linux_abi="${ndk_abi_map[$abi]}"
    
    if [ -z "$linux_abi" ]; then
        log_message "ERROR" "Unsupported ABI: $abi"
        return 1
    fi
    
    # Explicitly try the newest NDK version first (29.0.14206865)
    local newest_ndk="$HOME/Library/Android/sdk/ndk/29.0.14206865"
    if [ -d "$newest_ndk" ]; then
        # Try the newer NDK path structure first (NDK 25+)
        local libcpp_path_new="$newest_ndk/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/$linux_abi/libc++_shared.so"
        if [ -f "$libcpp_path_new" ]; then
            echo "$libcpp_path_new"
            return 0
        fi
    fi
    
    # Find the latest NDK version
    local ndk_base="$HOME/Library/Android/sdk/ndk"
    if [ -d "$ndk_base" ]; then
        local latest_ndk=$(ls -d "$ndk_base"/* | sort -r | head -1)
        
        if [ -n "$latest_ndk" ]; then
            # Try the newer NDK path structure first (NDK 25+)
            local libcpp_path_new="$latest_ndk/toolchains/llvm/prebuilt/darwin-x86_64/sysroot/usr/lib/$linux_abi/libc++_shared.so"
            if [ -f "$libcpp_path_new" ]; then
                echo "$libcpp_path_new"
                return 0
            fi
            
            # Try the older NDK path structure (NDK 23 and below)
            local libcpp_path_old="$latest_ndk/sources/cxx-stl/llvm-libc++/libs/$abi/libc++_shared.so"
            if [ -f "$libcpp_path_old" ]; then
                echo "$libcpp_path_old"
                return 0
            fi
        fi
    fi
    
    # Fallback: search all NDK versions - make sure we match the actual ABI directory, not just any occurrence
    local libcpp_path=$(find "$HOME/Library/Android/sdk/ndk" -name "libc++_shared.so" -type f | grep -E "/($abi|$linux_abi)/libc\+\+_shared.so$" | sort -r | head -1)
    if [ -n "$libcpp_path" ]; then
        echo "$libcpp_path"
        return 0
    fi
    
    log_message "WARNING" "Could not find libc++_shared.so for $abi"
    return 1
}

# Copy pre-built libraries to both SDKs
log_message "INFO" "Copying pre-built libraries..."

for ABI in "arm64-v8a" "x86_64"; do
    # Verify libllama_mobile.so exists (but don't copy to jniLibs - it's imported via CMake)
    SOURCE_LIB="$PREBUILT_DIR/libs/$ABI/libllama_mobile.so"
    if [ ! -f "$SOURCE_LIB" ]; then
        log_message "ERROR" "Library not found for ABI $ABI at $SOURCE_LIB"
        exit 1
    fi
    
    log_message "INFO" "Verified $ABI library exists at $SOURCE_LIB"
    
    # Copy libc++_shared.so (required for C++ Standard Library functionality)
    SOURCE_CPP_SHARED="$PREBUILT_DIR/libs/$ABI/libc++_shared.so"
    
    # If not found in prebuilt, try to find in NDK
    if [ ! -f "$SOURCE_CPP_SHARED" ]; then
        log_message "INFO" "libc++_shared.so not found in prebuilt directory, trying to find in NDK..."
        SOURCE_CPP_SHARED="$(find_libcpp_shared "$ABI")"
        if [ $? -ne 0 ]; then
            log_message "WARNING" "Could not find libc++_shared.so for ABI $ABI. App may crash on device."
            continue
        fi
        log_message "INFO" "Found libc++_shared.so for ABI $ABI at $SOURCE_CPP_SHARED"
    fi
    
    # Copy to Kotlin SDK
    KOTLIN_DEST_CPP_SHARED="$KOTLIN_SDK_DIR/src/main/jniLibs/$ABI/libc++_shared.so"
    cp -f "$SOURCE_CPP_SHARED" "$KOTLIN_DEST_CPP_SHARED"
    log_message "INFO" "Copied $ABI libc++_shared.so to Kotlin SDK at $KOTLIN_DEST_CPP_SHARED"
    
    # Copy to Java SDK
    JAVA_DEST_CPP_SHARED="$JAVA_SDK_DIR/src/main/jniLibs/$ABI/libc++_shared.so"
    cp -f "$SOURCE_CPP_SHARED" "$JAVA_DEST_CPP_SHARED"
    log_message "INFO" "Copied $ABI libc++_shared.so to Java SDK at $JAVA_DEST_CPP_SHARED"
done

# Copy grammar files if they exist
log_message "INFO" "Copying grammar files..."

if [ -d "$PREBUILT_DIR/grammars" ]; then
    if compgen -G "$PREBUILT_DIR/grammars/*.gbnf" > /dev/null; then
        # Copy to Kotlin SDK
        cp -f "$PREBUILT_DIR/grammars"/*.gbnf "$KOTLIN_SDK_DIR/src/main/assets/grammars/"
        count=$(ls -la "$KOTLIN_SDK_DIR/src/main/assets/grammars"/*.gbnf 2>/dev/null | wc -l)
        log_message "INFO" "Copied $count grammar files to Kotlin SDK at $KOTLIN_SDK_DIR/src/main/assets/grammars"
        
        # Copy to Java SDK
        cp -f "$PREBUILT_DIR/grammars"/*.gbnf "$JAVA_SDK_DIR/src/main/assets/grammars/"
        count=$(ls -la "$JAVA_SDK_DIR/src/main/assets/grammars"/*.gbnf 2>/dev/null | wc -l)
        log_message "INFO" "Copied $count grammar files to Java SDK at $JAVA_SDK_DIR/src/main/assets/grammars"
    else
        log_message "WARN" "No grammar files (*.gbnf) found in $PREBUILT_DIR/grammars"
    fi
else
    log_message "WARN" "Grammar source directory not found at $PREBUILT_DIR/grammars"
fi

# Copy the Kotlin wrapper
log_message "INFO" "Copying Kotlin wrapper..."

# Determine the source of the Kotlin wrapper
# First check if we have a temporary copy from the previous SDK
KOTLIN_SOURCE=""
if [ -f "$TEMP_KOTLIN" ]; then
    KOTLIN_SOURCE="$TEMP_KOTLIN"
# Then check if backups are enabled and we have a backup copy
elif [ -n "$KOTLIN_BACKUP_DIR" ] && [ -d "$KOTLIN_BACKUP_DIR" ] && [ -f "$KOTLIN_BACKUP_DIR/src/main/java/com/llamamobile/LlamaMobile.kt" ]; then
    KOTLIN_SOURCE="$KOTLIN_BACKUP_DIR/src/main/java/com/llamamobile/LlamaMobile.kt"
# Finally, check if there's a reference copy in the project
elif [ -f "$ROOT_DIR/scripts/LlamaMobile.kt" ]; then
    KOTLIN_SOURCE="$ROOT_DIR/scripts/LlamaMobile.kt"
fi

if [ -n "$KOTLIN_SOURCE" ]; then
    cp -f "$KOTLIN_SOURCE" "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile/"
    log_message "INFO" "Copied Kotlin wrapper to $KOTLIN_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.kt"
fi

# Restore Kotlin JNI implementation if preserved
if [ -f "$TEMP_KOTLIN_JNI_CPP" ]; then
    mkdir -p "$KOTLIN_SDK_DIR/src/main/cpp"
    cp -f "$TEMP_KOTLIN_JNI_CPP" "$KOTLIN_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp"
    log_message "INFO" "Restored Kotlin JNI implementation from temporary storage"
fi

# Restore Kotlin CMakeLists.txt if preserved
if [ -f "$TEMP_KOTLIN_JNI_CMAKELISTS" ]; then
    mkdir -p "$KOTLIN_SDK_DIR/src/main/cpp"
    cp -f "$TEMP_KOTLIN_JNI_CMAKELISTS" "$KOTLIN_SDK_DIR/src/main/cpp/CMakeLists.txt"
    log_message "INFO" "Restored Kotlin CMakeLists.txt from temporary storage"
fi

if [ -z "$KOTLIN_SOURCE" ]; then
    # If no Kotlin wrapper found, create a basic one
    log_message "WARN" "No existing Kotlin wrapper found. Creating a basic wrapper."
    
    cat > "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.kt" << 'EOF'
package com.llamamobile

/**
 * Llama Mobile SDK wrapper for Android
 * This is a basic wrapper that needs to be implemented
 */
class LlamaMobile {
    // Placeholder for native methods
    companion object {
        init {
            System.loadLibrary("llama_mobile")
        }
    }
}
EOF
    
    log_message "INFO" "Created basic Kotlin wrapper structure"
fi

# Create the Java wrapper
log_message "INFO" "Creating Java wrapper..."

# Determine the source of the Java wrapper
# First check if we have a temporary copy from the previous SDK
JAVA_SOURCE=""
if [ -f "$TEMP_JAVA" ]; then
    JAVA_SOURCE="$TEMP_JAVA"
# Then check if backups are enabled and we have a backup copy
elif [ -n "$JAVA_BACKUP_DIR" ] && [ -d "$JAVA_BACKUP_DIR" ] && [ -f "$JAVA_BACKUP_DIR/src/main/java/com/llamamobile/LlamaMobile.java" ]; then
    JAVA_SOURCE="$JAVA_BACKUP_DIR/src/main/java/com/llamamobile/LlamaMobile.java"
fi

if [ -n "$JAVA_SOURCE" ]; then
    cp -f "$JAVA_SOURCE" "$JAVA_SDK_DIR/src/main/java/com/llamamobile/"
    log_message "INFO" "Copied Java wrapper to $JAVA_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java"
fi

# Restore Java JNI implementation if preserved
if [ -f "$TEMP_JAVA_JNI_CPP" ]; then
    mkdir -p "$JAVA_SDK_DIR/src/main/cpp"
    cp -f "$TEMP_JAVA_JNI_CPP" "$JAVA_SDK_DIR/src/main/cpp/llama_mobile_jni.cpp"
    log_message "INFO" "Restored Java JNI implementation from temporary storage"
fi

# Restore Java CMakeLists.txt if preserved
if [ -f "$TEMP_JAVA_JNI_CMAKELISTS" ]; then
    mkdir -p "$JAVA_SDK_DIR/src/main/cpp"
    cp -f "$TEMP_JAVA_JNI_CMAKELISTS" "$JAVA_SDK_DIR/src/main/cpp/CMakeLists.txt"
    log_message "INFO" "Restored Java CMakeLists.txt from temporary storage"
fi

if [ -z "$JAVA_SOURCE" ]; then
    # If no Java wrapper found, create a complete one
    log_message "INFO" "Creating complete Java wrapper..."
    
    cat > "$JAVA_SDK_DIR/src/main/java/com/llamamobile/LlamaMobile.java" << 'EOF'
package com.llamamobile;

import android.content.Context;
import java.util.List;
import java.util.ArrayList;

/**
 * Llama Mobile SDK wrapper for Android (Java)
 * Provides complete Java interface to the native llama_mobile library
 */
public class LlamaMobile {

    // Load native library
    static {
        System.loadLibrary("llama_mobile");
    }

    // ==========================
    // Initialization Parameters
    // ==========================
    public static class InitParams {
        public String modelPath;
        public int nGpuLayers;
        public int nCtx;
        public int nBatch;
        public int nThreads;
        public int nThreadsBatch;
        public boolean verbose;
        public String grammarPath;
        public boolean cacheKV;
        public int maxCacheSize;

        public InitParams(String modelPath) {
            this.modelPath = modelPath;
            this.nGpuLayers = 0;
            this.nCtx = 2048;
            this.nBatch = 512;
            this.nThreads = 4;
            this.nThreadsBatch = 4;
            this.verbose = false;
            this.grammarPath = null;
            this.cacheKV = false;
            this.maxCacheSize = 256 * 1024 * 1024; // 256MB default
        }

        public InitParams setNGpuLayers(int nGpuLayers) {
            this.nGpuLayers = nGpuLayers;
            return this;
        }

        public InitParams setNCtx(int nCtx) {
            this.nCtx = nCtx;
            return this;
        }

        public InitParams setNBatch(int nBatch) {
            this.nBatch = nBatch;
            return this;
        }

        public InitParams setNThreads(int nThreads) {
            this.nThreads = nThreads;
            return this;
        }

        public InitParams setNThreadsBatch(int nThreadsBatch) {
            this.nThreadsBatch = nThreadsBatch;
            return this;
        }

        public InitParams setVerbose(boolean verbose) {
            this.verbose = verbose;
            return this;
        }

        public InitParams setGrammarPath(String grammarPath) {
            this.grammarPath = grammarPath;
            return this;
        }

        public InitParams setCacheKV(boolean cacheKV) {
            this.cacheKV = cacheKV;
            return this;
        }

        public InitParams setMaxCacheSize(int maxCacheSize) {
            this.maxCacheSize = maxCacheSize;
            return this;
        }
    }

    // ==========================
    // Completion Parameters
    // ==========================
    public static class CompletionParams {
        public String prompt;
        public int maxTokens;
        public float temperature;
        public float topP;
        public float topK;
        public float repeatPenalty;
        public String grammar;
        public List<String> mediaPaths;
        public boolean echo;
        public boolean stream;
        public boolean verbosePrompt;

        public CompletionParams(String prompt) {
            this.prompt = prompt;
            this.maxTokens = 1024;
            this.temperature = 0.8f;
            this.topP = 0.95f;
            this.topK = 40;
            this.repeatPenalty = 1.1f;
            this.grammar = null;
            this.mediaPaths = new ArrayList<>();
            this.echo = false;
            this.stream = false;
            this.verbosePrompt = false;
        }

        public CompletionParams setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
            return this;
        }

        public CompletionParams setTemperature(float temperature) {
            this.temperature = temperature;
            return this;
        }

        public CompletionParams setTopP(float topP) {
            this.topP = topP;
            return this;
        }

        public CompletionParams setTopK(float topK) {
            this.topK = topK;
            return this;
        }

        public CompletionParams setRepeatPenalty(float repeatPenalty) {
            this.repeatPenalty = repeatPenalty;
            return this;
        }

        public CompletionParams setGrammar(String grammar) {
            this.grammar = grammar;
            return this;
        }

        public CompletionParams setMediaPaths(List<String> mediaPaths) {
            this.mediaPaths = mediaPaths;
            return this;
        }

        public CompletionParams addMediaPath(String mediaPath) {
            this.mediaPaths.add(mediaPath);
            return this;
        }

        public CompletionParams setEcho(boolean echo) {
            this.echo = echo;
            return this;
        }

        public CompletionParams setStream(boolean stream) {
            this.stream = stream;
            return this;
        }

        public CompletionParams setVerbosePrompt(boolean verbosePrompt) {
            this.verbosePrompt = verbosePrompt;
            return this;
        }
    }

    // ==========================
    // Audio Generation Parameters
    // ==========================
    public static class AudioParams {
        public String text;
        public int sampleRate;
        public int speakerId;
        public float speed;
        public float volume;
        public int maxTokens;

        public AudioParams(String text) {
            this.text = text;
            this.sampleRate = 48000;
            this.speakerId = 0;
            this.speed = 1.0f;
            this.volume = 1.0f;
            this.maxTokens = 2048;
        }

        public AudioParams setSampleRate(int sampleRate) {
            this.sampleRate = sampleRate;
            return this;
        }

        public AudioParams setSpeakerId(int speakerId) {
            this.speakerId = speakerId;
            return this;
        }

        public AudioParams setSpeed(float speed) {
            this.speed = speed;
            return this;
        }

        public AudioParams setVolume(float volume) {
            this.volume = volume;
            return this;
        }

        public AudioParams setMaxTokens(int maxTokens) {
            this.maxTokens = maxTokens;
            return this;
        }
    }

    // ==========================
    // LoRA Adapter Parameters
    // ==========================
    public static class LoraAdapter {
        public String path;
        public float scale;

        public LoraAdapter(String path) {
            this.path = path;
            this.scale = 1.0f;
        }

        public LoraAdapter setScale(float scale) {
            this.scale = scale;
            return this;
        }
    }

    // ==========================
    // Completion Result
    // ==========================
    public static class CompletionResult {
        public String text;
        public float perplexity;
        public boolean finished;
        public int tokenCount;

        public CompletionResult(String text, float perplexity, boolean finished, int tokenCount) {
            this.text = text;
            this.perplexity = perplexity;
            this.finished = finished;
            this.tokenCount = tokenCount;
        }
    }

    // ==========================
    // Native Methods
    // ==========================

    // Context management
    public static native long initContext(InitParams params);
    public static native boolean releaseContext(long context);
    public static native boolean isContextValid(long context);

    // Completion generation
    public static native CompletionResult generateCompletion(long context, CompletionParams params);

    // Embedding generation
    public static native float[] generateEmbedding(long context, String text);

    // LoRA adapter support
    public static native boolean applyLoraAdapters(long context, LoraAdapter[] adapters);
    public static native boolean removeLoraAdapters(long context);

    // Multimodal support
    public static native boolean initMultimodal(long context, String mmprojPath);
    public static native boolean releaseMultimodal(long context);

    // Text-to-Speech support
    public static native boolean initVocoder(long context, String vocoderPath);
    public static native short[] generateAudioFromText(long context, AudioParams params);
    public static native short[] generateAudioFromTokens(long context, long[] tokens, int sampleRate);
    public static native boolean releaseVocoder(long context);

    // Model management
    public static native String getModelInfo(long context);
    public static native int getMaxCtx(long context);
    public static native boolean setMaxCtx(long context, int maxCtx);
    public static native long getMemoryUsage(long context);
    public static native boolean isModelLoaded(long context);

    // Utility methods
    public static native String getLibraryVersion();
    public static native void setLogLevel(int level);
    public static native String[] listGrammars();

    // ==========================
    // Convenience Methods
    // ==========================

    // Simple completion with default parameters
    public static CompletionResult generateCompletion(long context, String prompt) {
        return generateCompletion(context, new CompletionParams(prompt));
    }

    // Simple completion with max tokens
    public static CompletionResult generateCompletion(long context, String prompt, int maxTokens) {
        return generateCompletion(context, new CompletionParams(prompt).setMaxTokens(maxTokens));
    }

    // Simple audio generation
    public static short[] generateAudioFromText(long context, String text) {
        return generateAudioFromText(context, new AudioParams(text));
    }

    // ==========================
    // Constants
    // ==========================

    // Log levels
    public static final int LOG_LEVEL_DEBUG = 0;
    public static final int LOG_LEVEL_INFO = 1;
    public static final int LOG_LEVEL_WARN = 2;
    public static final int LOG_LEVEL_ERROR = 3;
    public static final int LOG_LEVEL_SILENT = 4;

    // Default values
    public static final int DEFAULT_N_CTX = 2048;
    public static final int DEFAULT_N_GPU_LAYERS = 0;
    public static final int DEFAULT_SAMPLE_RATE = 48000;
}
EOF
    
    log_message "INFO" "Created complete Java wrapper interface"
fi

# Copy unit tests to both SDKs
log_message "INFO" "Copying unit tests..."

# Handle Kotlin unit tests
log_message "INFO" "Copying Kotlin unit tests..."
if [ -f "$TEMP_KOTLIN_UNIT_TESTS" ]; then
    cp -f "$TEMP_KOTLIN_UNIT_TESTS" "$KOTLIN_SDK_DIR/src/test/java/com/llamamobile/"
    log_message "INFO" "Copied Kotlin unit tests to $KOTLIN_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.kt"
fi


# Copy instrumented tests to both SDKs
log_message "INFO" "Copying instrumented tests..."

# Handle Kotlin instrumented tests
log_message "INFO" "Copying Kotlin instrumented tests..."
if [ -f "$TEMP_KOTLIN_INSTRUMENTED_TESTS" ]; then
    cp -f "$TEMP_KOTLIN_INSTRUMENTED_TESTS" "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/"
    log_message "INFO" "Copied Kotlin instrumented tests to $KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt"
fi

# Handle Kotlin comprehensive tests
log_message "INFO" "Copying Kotlin comprehensive tests..."
if [ -f "$TEMP_KOTLIN_COMPREHENSIVE_TESTS" ]; then
    cp -f "$TEMP_KOTLIN_COMPREHENSIVE_TESTS" "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/"
    log_message "INFO" "Copied Kotlin comprehensive tests to $KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt"
fi



# Restore Java comprehensive tests if they exist
if [ -f "$TEMP_JAVA_COMPREHENSIVE_TESTS" ]; then
    cp -f "$TEMP_JAVA_COMPREHENSIVE_TESTS" "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/"
    log_message "INFO" "Restored Java comprehensive tests from temporary storage"
fi

# Create/update AndroidManifest.xml for both SDKs
log_message "INFO" "Creating AndroidManifest.xml files..."

# Create for Kotlin SDK
cat > "$KOTLIN_SDK_DIR/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" 
    package="com.llamamobile">

    <uses-sdk
        android:minSdkVersion="21" 
        android:targetSdkVersion="34" />

    <!-- Permissions for accessing external storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="33" />
    
    <!-- For Android 14+, we need to handle files differently -->
    <!-- This is a general permission for non-media files -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
</manifest>
EOF
log_message "INFO" "Created AndroidManifest.xml for Kotlin SDK"

# Create for Java SDK
cat > "$JAVA_SDK_DIR/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" 
    package="com.llamamobile">

    <uses-sdk
        android:minSdkVersion="21" 
        android:targetSdkVersion="34" />

    <!-- Permissions for accessing external storage -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="33" />
    
    <!-- For Android 14+, we need to handle files differently -->
    <!-- This is a general permission for non-media files -->
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
</manifest>
EOF
log_message "INFO" "Created AndroidManifest.xml for Java SDK"

# Create/update build.gradle files for both SDKs
log_message "INFO" "Creating build.gradle files..."

# Create Kotlin SDK build.gradle
cat > "$KOTLIN_SDK_DIR/build.gradle" << 'EOF'
plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.llamamobile'
    compileSdk 36
    buildToolsVersion "36.1.0"

    defaultConfig {
        minSdk 21
        targetSdk 36

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
        
        ndk {
            abiFilters 'arm64-v8a', 'x86_64'
            stl "c++_shared"
            version "29.0.14206865"
        }
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
            version "3.18.1"
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
    
    // Resolve duplicate Kotlin library conflicts
    implementation(platform('org.jetbrains.kotlin:kotlin-bom:1.9.20'))
    
    // Exclude older Kotlin stdlib modules
    configurations.all {
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk7'
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk8'
    }
}
EOF
log_message "INFO" "Created build.gradle for Kotlin SDK"

# Create Java SDK build.gradle
cat > "$JAVA_SDK_DIR/build.gradle" << 'EOF'
plugins {
    id 'com.android.library'
}

android {
    namespace 'com.llamamobile'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
        
        ndk {
            abiFilters 'arm64-v8a', 'x86_64'
            stl "c++_shared"
        }
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

    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
            version "3.18.1"
        }
    }
}

dependencies {
    implementation 'androidx.core:core:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
    
    // Resolve duplicate Kotlin library conflicts
    implementation(platform('org.jetbrains.kotlin:kotlin-bom:1.9.20'))
    
    // Exclude older Kotlin stdlib modules
    configurations.all {
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk7'
        exclude group: 'org.jetbrains.kotlin', module: 'kotlin-stdlib-jdk8'
    }
}
EOF
log_message "INFO" "Created build.gradle for Java SDK"

# Create/update settings.gradle files for both SDKs
log_message "INFO" "Creating settings.gradle files..."

SETTINGS_GRADLE_CONTENT="pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id 'com.android.library' version '8.5.0'
        id 'org.jetbrains.kotlin.android' version '1.9.20'
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = \"llama_mobile\""

# Create for Kotlin SDK
echo "$SETTINGS_GRADLE_CONTENT" > "$KOTLIN_SDK_DIR/settings.gradle"
log_message "INFO" "Created settings.gradle for Kotlin SDK"

# Create for Java SDK
echo "$SETTINGS_GRADLE_CONTENT" > "$JAVA_SDK_DIR/settings.gradle"
log_message "INFO" "Created settings.gradle for Java SDK"

# Create/update gradle.properties files for both SDKs
log_message "INFO" "Creating gradle.properties files..."

GRADLE_PROPERTIES_CONTENT="# AndroidX properties
android.useAndroidX=true
# Kotlin code style for this project: \"official\" or \"obsolete\":
kotlin.code.style=official

# SDK compatibility settings
android.builder.sdkInstallPath=/Users/shileipeng/Library/Android/sdk
android.suppressUnsupportedCompileSdk=36
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8"

# Create for Kotlin SDK
echo "$GRADLE_PROPERTIES_CONTENT" > "$KOTLIN_SDK_DIR/gradle.properties"
log_message "INFO" "Created gradle.properties for Kotlin SDK"

# Create for Java SDK
echo "$GRADLE_PROPERTIES_CONTENT" > "$JAVA_SDK_DIR/gradle.properties"
log_message "INFO" "Created gradle.properties for Java SDK"

# Create consumer-rules.pro files for both SDKs
log_message "INFO" "Creating consumer-rules.pro files..."

CONSUMER_RULES_CONTENT="# Consumer rules for llama_mobile Android SDK
# Keep all public classes and methods in the SDK
dontwarn com.llamamobile.**
-keep class com.llamamobile.** { *; }
"

# Create for Kotlin SDK
echo "$CONSUMER_RULES_CONTENT" > "$KOTLIN_SDK_DIR/consumer-rules.pro"
log_message "INFO" "Created consumer-rules.pro for Kotlin SDK"

# Create for Java SDK
echo "$CONSUMER_RULES_CONTENT" > "$JAVA_SDK_DIR/consumer-rules.pro"
log_message "INFO" "Created consumer-rules.pro for Java SDK"

# Create proguard-rules.pro files for both SDKs
log_message "INFO" "Creating proguard-rules.pro files..."

PROGUARD_RULES_CONTENT="# ProGuard rules for llama_mobile Android SDK
# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Keep all public classes and methods in the SDK
dontwarn com.llamamobile.**
-keep class com.llamamobile.** { *; }
"

# Create for Kotlin SDK
echo "$PROGUARD_RULES_CONTENT" > "$KOTLIN_SDK_DIR/proguard-rules.pro"
log_message "INFO" "Created proguard-rules.pro for Kotlin SDK"

# Create for Java SDK
echo "$PROGUARD_RULES_CONTENT" > "$JAVA_SDK_DIR/proguard-rules.pro"
log_message "INFO" "Created proguard-rules.pro for Java SDK"

# Handle README.md files for both SDKs
log_message "INFO" "Checking README.md files..."

# Handle Kotlin SDK README.md
log_message "INFO" "Handling Kotlin SDK README.md..."
if [ -f "$PRESERVED_KOTLIN_README" ]; then
    # Restore the preserved Kotlin README
    cp -f "$PRESERVED_KOTLIN_README" "$KOTLIN_SDK_DIR/README.md"
    log_message "INFO" "Restored existing Kotlin README.md"
fi

# Handle Java SDK README.md
log_message "INFO" "Handling Java SDK README.md..."
if [ -f "$PRESERVED_JAVA_README" ]; then
    # Restore the preserved Java README
    cp -f "$PRESERVED_JAVA_README" "$JAVA_SDK_DIR/README.md"
    log_message "INFO" "Restored existing Java README.md"
fi



# Make the script executable
chmod +x "$0"
log_message "INFO" "Made build script executable"

# Create Gradle wrapper for both SDKs
create_gradle_wrapper() {
    local sdk_dir="$1"
    local sdk_type="$2"
    
    if [ ! -f "$sdk_dir/gradlew" ]; then
        log_message "INFO" "Creating Gradle wrapper for $sdk_type SDK..."
    cat > "$sdk_dir/gradlew" << 'EOF'
#!/bin/bash

# Copyright 2015 the original author or authors.

# Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

#      https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

##############################################################################
#
#  Gradle start up script for UN*X
#
##############################################################################

# Attempt to set APP_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ]; do
    ls="$(ls -ld "$PRG")"
    link="$(expr "$ls" : '.*-> \(.*\)$')"
    if expr "$link" : '/.*' > /dev/null; then
        PRG="$link"
    else
        PRG="$(dirname "$PRG")/$link"
    fi
done
SAVED="$PWD"

cd "$(dirname "$PRG")" >/dev/null
APP_HOME="$PWD"
cd "$SAVED" >/dev/null

APP_NAME="Gradle"
APP_BASE_NAME=$(basename "$0")

# Add default JVM options here. You can also use JAVA_OPTS and GRADLE_OPTS to pass JVM options to this script.
DEFAULT_JVM_OPTS="$(java -version 2>&1 | grep version | cut -d '"' -f 2 | sed 's/^1\./11/')"

# Use the maximum available, or set MAX_FD != -1 to use that value.
MAX_FD="maximum"

warn () {
    echo "$*"
}

die () {
    echo
    echo "$*"
    echo
    exit 1
}

# OS specific support (must be 'true' or 'false').
cygwin=false
darwin=false
msys=false
nonstop=false
case "$(uname)" in
  CYGWIN* )
    cygwin=true
    ;;
  Darwin* )
    darwin=true
    ;;
  MINGW* )
    msys=true
    ;;
  NONSTOP* )
    nonstop=true
    ;;
esac

CLASSPATH=$APP_HOME/gradle/wrapper/gradle-wrapper.jar

# Determine the Java command to use to start the JVM.
if [ -n "$JAVA_HOME" ]; then
    if [ -x "$JAVA_HOME/jre/sh/java" ]; then
        # IBM's JDK on AIX uses strange locations for the executables
        JAVACMD="$JAVA_HOME/jre/sh/java"
    else
        JAVACMD="$JAVA_HOME/bin/java"
    fi
    if [ ! -x "$JAVACMD" ]; then
        die "ERROR: JAVA_HOME is set to an invalid directory: $JAVA_HOME

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
    fi
else
    JAVACMD="java"
    which java >/dev/null 2>&1 || die "ERROR: JAVA_HOME is not set and no 'java' command could be found in your PATH.

Please set the JAVA_HOME variable in your environment to match the
location of your Java installation."
fi

# Increase the maximum file descriptors if we can.
if [ "$cygwin" = "false" ] && [ "$darwin" = "false" ] && [ "$nonstop" = "false" ]; then
    case "$(ulimit -Hn)" in
      "" )
        ;;
      * )
        MAX_FD=$(ulimit -Hn)
        ;;
    esac
    case "$(ulimit -Sn)" in
      "" )
        ;;
      * )
        MAX_NOFILES=$(ulimit -Sn)
        ;;
    esac
    if [ "$MAX_FD" = "maximum" ] || [ "$MAX_FD" = "unlimited" ]; then
        MAX_FD="unlimited"
    fi
fi

# For Darwin, add options to specify how the application appears in the dock
if $darwin; then
    GRADLE_OPTS="$GRADLE_OPTS -Xdock:name=$APP_NAME -Xdock:icon=$APP_HOME/media/gradle.icns"
fi

# For Cygwin, switch paths to Windows format before running java
if $cygwin; then
    APP_HOME=$(cygpath --path --mixed "$APP_HOME")
    CLASSPATH=$(cygpath --path --mixed "$CLASSPATH")
    JAVACMD=$(cygpath --unix "$JAVACMD")

    # We build the pattern for arguments to be converted via cygpath
    ROOTDIRSRAW=$(find -L / -maxdepth 1 -mindepth 1 -type d 2>/dev/null)
    SEP=$(echo -n "$(printf '%0.s|' {1..120})"
    ROOTDIRS=$(echo "$ROOTDIRSRAW" | sed -e 's;[^|]*|;[^/]*/;g')
    OURCYGPATTERN="(^($ROOTDIRS))"
    # Add a user-defined pattern to the cygpath arguments
    if [ "$GRADLE_CYGPATTERN" != "" ]; then
        OURCYGPATTERN="$OURCYGPATTERN|($GRADLE_CYGPATTERN)"
    fi
    # Now convert the arguments - kludge to limit ourselves to /bin/sh
    i=0
    for arg in "$@"; do
        CHECK=$(echo "$arg" | egrep -c "$OURCYGPATTERN")
        CHECK2=$(echo "$arg" | egrep -c "^-")
    if [ $CHECK -ne 0 ] && [ $CHECK2 -eq 0 ]; then
            eval "arg$i=$(cygpath --path --mixed "$arg")"
        else
            eval "arg$i=$(echo "$arg" | sed 's/ /\\ /g')"
        fi
        i=$((i+1))
    done
    case $i in
        (0) set -- ;; (1) set -- "$arg0" ;; (2) set -- "$arg0" "$arg1" ;; (3) set -- "$arg0" "$arg1" "$arg2" ;;
        (4) set -- "$arg0" "$arg1" "$arg2" "$arg3" ;; (5) set -- "$arg0" "$arg1" "$arg2" "$arg3" "$arg4" ;;
        (6) set -- "$arg0" "$arg1" "$arg2" "$arg3" "$arg4" "$arg5" ;; (7) set -- "$arg0" "$arg1" "$arg2" "$arg3" "$arg4" "$arg5" "$arg6" ;;
        (8) set -- "$arg0" "$arg1" "$arg2" "$arg3" "$arg4" "$arg5" "$arg6" "$arg7" ;; (9) set -- "$arg0" "$arg1" "$arg2" "$arg3" "$arg4" "$arg5" "$arg6" "$arg7" "$arg8" ;;
esac
fi

# Escape application args
save () {
    for i do printf %s\\0 "$i"; done
}
saved_args=$(save "$@")

# Collect all arguments for the java command, following the shell quoting and substitution rules
eval set -- $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS "-Dorg.gradle.appname=$APP_BASE_NAME" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"

# Use "xargs" to parse quoted args. We use "-n1" to chop up quoted args into pieces, as "xargs" has trouble with quoted args that contain spaces.
# This is a much safer method than "eval""
printf '%s\0' "$saved_args" | xargs -0 java $DEFAULT_JVM_OPTS $JAVA_OPTS $GRADLE_OPTS "-Dorg.gradle.appname=$APP_BASE_NAME" -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain
EOF
    
    chmod +x "$sdk_dir/gradlew"
    
    # Create gradle wrapper directory and properties
    mkdir -p "$sdk_dir/gradle/wrapper"
    
    cat > "$sdk_dir/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    
        log_message "INFO" "Created Gradle wrapper for $sdk_type SDK"
    fi
}

# Note: Gradle wrapper generation has been removed.
# Users should have Gradle installed globally or added to their PATH.

# Verify both SDK structures
log_message "INFO" "Verifying SDK structures..."

all_valid=true

# Common directories required for both SDKs
required_dirs=("src/main/jniLibs/arm64-v8a" "src/main/jniLibs/x86_64" "src/main/assets/grammars" "src/main/java/com/llamamobile")

# Verify Kotlin SDK
log_message "INFO" "Verifying Kotlin SDK structure..."
kotlin_required_files=("src/main/java/com/llamamobile/LlamaMobile.kt" "build.gradle" "settings.gradle" "gradle.properties" "README.md")

for dir in "${required_dirs[@]}"; do
    if [ -d "$KOTLIN_SDK_DIR/$dir" ]; then
        log_message "SUCCESS" "Kotlin SDK: Found directory: $dir"
    else
        log_message "ERROR" "Kotlin SDK: Missing directory: $dir"
        all_valid=false
    fi
done

for file in "${kotlin_required_files[@]}"; do
    if [ -f "$KOTLIN_SDK_DIR/$file" ]; then
        log_message "SUCCESS" "Kotlin SDK: Found file: $file"
    else
        log_message "ERROR" "Kotlin SDK: Missing file: $file"
        all_valid=false
    fi
done

# Verify Java SDK
log_message "INFO" "Verifying Java SDK structure..."
java_required_files=("src/main/java/com/llamamobile/LlamaMobile.java" "build.gradle" "settings.gradle" "gradle.properties" "README.md")

for dir in "${required_dirs[@]}"; do
    if [ -d "$JAVA_SDK_DIR/$dir" ]; then
        log_message "SUCCESS" "Java SDK: Found directory: $dir"
    else
        log_message "ERROR" "Java SDK: Missing directory: $dir"
        all_valid=false
    fi
done

for file in "${java_required_files[@]}"; do
    if [ -f "$JAVA_SDK_DIR/$file" ]; then
        log_message "SUCCESS" "Java SDK: Found file: $file"
    else
        log_message "ERROR" "Java SDK: Missing file: $file"
        all_valid=false
    fi
done

# Check for libraries in both SDKs
for ABI in "arm64-v8a" "x86_64"; do
    if [ -f "$KOTLIN_SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.so" ]; then
        log_message "SUCCESS" "Kotlin SDK: Found $ABI library"
    else
        log_message "ERROR" "Kotlin SDK: Missing $ABI library"
        all_valid=false
    fi
    
    if [ -f "$JAVA_SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.so" ]; then
        log_message "SUCCESS" "Java SDK: Found $ABI library"
    else
        log_message "ERROR" "Java SDK: Missing $ABI library"
        all_valid=false
    fi
done

# Clean up temporary files at the end
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
    log_message "INFO" "Cleaned up temporary files"
fi

# Create gradle config files for both SDKs to avoid Android Studio JDK configuration errors
log_message "INFO" "Creating Gradle configuration files..."

# Get current Java home path
JAVA_HOME_PATH=$(java -XshowSettings:properties -version 2>&1 | grep 'java.home' | awk '{print $3}')

# Create gradle config for Kotlin SDK
mkdir -p "$KOTLIN_SDK_DIR/gradle"
echo "java.home=$JAVA_HOME_PATH" > "$KOTLIN_SDK_DIR/gradle/config.properties"

# Create gradle config for Java SDK
mkdir -p "$JAVA_SDK_DIR/gradle"
echo "java.home=$JAVA_HOME_PATH" > "$JAVA_SDK_DIR/gradle/config.properties"

if [ "$all_valid" = true ]; then
    log_message "INFO" "Both Android SDKs built completed successfully!"
    log_message "INFO" ""
    log_message "INFO" "Kotlin SDK Location: $KOTLIN_SDK_DIR"
    log_message "INFO" "Java SDK Location: $JAVA_SDK_DIR"
    log_message "INFO" ""
    log_message "INFO" "To use the SDKs:"
    log_message "INFO" "1. Import the desired module (Kotlin or Java) into your Android Studio project"
    log_message "INFO" "2. Add implementation project(':llama_mobile-android-SDK') or implementation project(':llama_mobile-android-java-SDK') to your app's build.gradle"
    log_message "INFO" "3. Follow the usage examples in the README.md"
else
    log_message "ERROR" "SDK build failed with validation errors!"
    exit 1
fi
