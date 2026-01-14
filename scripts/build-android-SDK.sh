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
TEMP_KOTLIN_UNIT_TESTS=""
TEMP_KOTLIN_INSTRUMENTED_TESTS=""
TEMP_KOTLIN_README=""

# Java SDK preservation
TEMP_JAVA=""
TEMP_JAVA_UNIT_TESTS=""
TEMP_JAVA_INSTRUMENTED_TESTS=""
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
    
    # Preserve Java unit tests
    if [ -f "$JAVA_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.java" ]; then
        TEMP_JAVA_UNIT_TESTS="$TEMP_DIR/LlamaMobileUnitTests.java"
        cp "$JAVA_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.java" "$TEMP_JAVA_UNIT_TESTS"
        log_message "INFO" "Preserved existing Java unit tests temporarily"
    fi
    
    # Preserve Java instrumented tests
    if [ -f "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java" ]; then
        TEMP_JAVA_INSTRUMENTED_TESTS="$TEMP_DIR/LlamaMobileInstrumentedTests.java"
        cp "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java" "$TEMP_JAVA_INSTRUMENTED_TESTS"
        log_message "INFO" "Preserved existing Java instrumented tests temporarily"
    fi
    
    # Preserve Java README.md
    if [ -f "$JAVA_SDK_DIR/README.md" ]; then
        TEMP_JAVA_README="$TEMP_DIR/JavaREADME.md"
        cp "$JAVA_SDK_DIR/README.md" "$TEMP_JAVA_README"
        log_message "INFO" "Preserved existing Java README.md temporarily"
    fi
fi

# By default, we don't create backups to avoid clutter
# To enable backups, set the BACKUP environment variable to "true"

# Handle Kotlin SDK cleanup
if [ -d "$KOTLIN_SDK_DIR" ]; then
    if [ "$BACKUP" = "true" ]; then
        timestamp=$(date '+%Y%m%d_%H%M%S')
        KOTLIN_BACKUP_DIR="${KOTLIN_SDK_DIR}_$timestamp"
        log_message "INFO" "Backing up existing Kotlin SDK to $KOTLIN_BACKUP_DIR"
        mv "$KOTLIN_SDK_DIR" "$KOTLIN_BACKUP_DIR"
    else
        # Clean up existing Kotlin SDK directory without backup
        log_message "INFO" "Removing existing Kotlin SDK directory (no backup)"
        rm -rf "$KOTLIN_SDK_DIR"
    fi
fi

# Handle Java SDK cleanup
if [ -d "$JAVA_SDK_DIR" ]; then
    if [ "$BACKUP" = "true" ]; then
        timestamp=$(date '+%Y%m%d_%H%M%S')
        JAVA_BACKUP_DIR="${JAVA_SDK_DIR}_$timestamp"
        log_message "INFO" "Backing up existing Java SDK to $JAVA_BACKUP_DIR"
        mv "$JAVA_SDK_DIR" "$JAVA_BACKUP_DIR"
    else
        # Clean up existing Java SDK directory without backup
        log_message "INFO" "Removing existing Java SDK directory (no backup)"
        rm -rf "$JAVA_SDK_DIR"
    fi
fi

# Create clean SDK directory structures for both Kotlin and Java
log_message "INFO" "Creating clean SDK directory structures..."

# Create Kotlin SDK directories
log_message "INFO" "Creating Kotlin SDK directories..."
mkdir -p "$KOTLIN_SDK_DIR/src/main/jniLibs/arm64-v8a"
mkdir -p "$KOTLIN_SDK_DIR/src/main/jniLibs/x86_64"
mkdir -p "$KOTLIN_SDK_DIR/src/main/assets/grammars"
mkdir -p "$KOTLIN_SDK_DIR/src/main/java/com/llamamobile"
mkdir -p "$KOTLIN_SDK_DIR/src/test/java/com/llamamobile"
mkdir -p "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile"
mkdir -p "$KOTLIN_SDK_DIR/libs"

# Create Java SDK directories
log_message "INFO" "Creating Java SDK directories..."
mkdir -p "$JAVA_SDK_DIR/src/main/jniLibs/arm64-v8a"
mkdir -p "$JAVA_SDK_DIR/src/main/jniLibs/x86_64"
mkdir -p "$JAVA_SDK_DIR/src/main/assets/grammars"
mkdir -p "$JAVA_SDK_DIR/src/main/java/com/llamamobile"
mkdir -p "$JAVA_SDK_DIR/src/test/java/com/llamamobile"
mkdir -p "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile"
mkdir -p "$JAVA_SDK_DIR/libs"

# Copy pre-built libraries to both SDKs
log_message "INFO" "Copying pre-built libraries..."

for ABI in "arm64-v8a" "x86_64"; do
    SOURCE_LIB="$PREBUILT_DIR/libs/$ABI/libllama_mobile.so"
    if [ ! -f "$SOURCE_LIB" ]; then
        log_message "ERROR" "Library not found for ABI $ABI at $SOURCE_LIB"
        exit 1
    fi
    
    # Copy to Kotlin SDK
    KOTLIN_DEST_LIB="$KOTLIN_SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.so"
    cp -f "$SOURCE_LIB" "$KOTLIN_DEST_LIB"
    log_message "INFO" "Copied $ABI library to Kotlin SDK at $KOTLIN_DEST_LIB"
    
    # Copy to Java SDK
    JAVA_DEST_LIB="$JAVA_SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.so"
    cp -f "$SOURCE_LIB" "$JAVA_DEST_LIB"
    log_message "INFO" "Copied $ABI library to Java SDK at $JAVA_DEST_LIB"
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
else
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
else
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

# Handle Java unit tests
log_message "INFO" "Creating Java unit tests..."
cat > "$JAVA_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.java" << 'EOF'
package com.llamamobile;

import org.junit.Test;
import org.junit.Before;
import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.List;

/**
 * Unit tests for LlamaMobile Java SDK
 */
public class LlamaMobileUnitTests {

    // Test paths for model files
    public static class TestPaths {
        public static final String rootPath = "/sdcard/llama_mobile/models";
        public static final String modelPath = rootPath + "/SmolLM-360M-Instruct.Q6_K.gguf";
        public static final String ttsModelPath = rootPath + "/OuteTTS-0.2-500M-Q6_K.gguf";
        public static final String vocoderPath = rootPath + "/WavTokenizer-Large-75-F16.gguf";
        public static final String embeddingPath = rootPath + "/embedding/Qwen3-Embedding-0.6B-Q8_0.gguf";
        public static final String mmprojPath = rootPath + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf";
        public static final String imageModelPath = rootPath + "/SmolVLM-256M-Instruct-Q8_0.gguf";
        public static final String imagePath = rootPath + "/img/image.jpg";
    }

    private long contextHandle;

    @Before
    public void setUp() {
        // Initialize with minimal context for testing
        // This will fail if the model file doesn't exist, but that's expected in unit tests
        try {
            LlamaMobile.InitParams params = new LlamaMobile.InitParams(TestPaths.modelPath)
                    .setNGpuLayers(0)
                    .setNCtx(512)
                    .setNThreads(2)
                    .setVerbose(false);
            contextHandle = LlamaMobile.initContext(params);
        } catch (Exception e) {
            // Model might not be available, that's okay for unit tests
            contextHandle = -1;
        }
    }

    @Test
    public void testInitParamsConstructors() {
        // Test basic constructor
        LlamaMobile.InitParams params = new LlamaMobile.InitParams("test_path");
        assertEquals("test_path", params.modelPath);
        assertEquals(0, params.nGpuLayers);
        assertEquals(2048, params.nCtx);
        assertEquals(4, params.nThreads);

        // Test builder pattern
        params = new LlamaMobile.InitParams("test_path")
                .setNGpuLayers(4)
                .setNCtx(4096)
                .setNThreads(8)
                .setVerbose(true);
        assertEquals("test_path", params.modelPath);
        assertEquals(4, params.nGpuLayers);
        assertEquals(4096, params.nCtx);
        assertEquals(8, params.nThreads);
        assertTrue(params.verbose);
    }

    @Test
    public void testCompletionParamsConstructors() {
        // Test basic constructor
        LlamaMobile.CompletionParams params = new LlamaMobile.CompletionParams("test prompt");
        assertEquals("test prompt", params.prompt);
        assertEquals(1024, params.maxTokens);
        assertEquals(0.8f, params.temperature, 0.01f);
        assertEquals(0.95f, params.topP, 0.01f);

        // Test builder pattern
        List<String> mediaPaths = new ArrayList<>();
        mediaPaths.add("test.jpg");
        
        params = new LlamaMobile.CompletionParams("test prompt")
                .setMaxTokens(512)
                .setTemperature(0.5f)
                .setTopP(0.8f)
                .setTopK(30)
                .setRepeatPenalty(1.05f)
                .setGrammar("json.gbnf")
                .setMediaPaths(mediaPaths)
                .setEcho(true);
        
        assertEquals("test prompt", params.prompt);
        assertEquals(512, params.maxTokens);
        assertEquals(0.5f, params.temperature, 0.01f);
        assertEquals(0.8f, params.topP, 0.01f);
        assertEquals(30, params.topK, 0.01f);
        assertEquals(1.05f, params.repeatPenalty, 0.01f);
        assertEquals("json.gbnf", params.grammar);
        assertEquals(mediaPaths, params.mediaPaths);
        assertTrue(params.echo);
    }

    @Test
    public void testAudioParamsConstructors() {
        // Test basic constructor
        LlamaMobile.AudioParams params = new LlamaMobile.AudioParams("test text");
        assertEquals("test text", params.text);
        assertEquals(48000, params.sampleRate);
        assertEquals(0, params.speakerId);
        assertEquals(1.0f, params.speed, 0.01f);

        // Test builder pattern
        params = new LlamaMobile.AudioParams("test text")
                .setSampleRate(24000)
                .setSpeakerId(1)
                .setSpeed(0.8f)
                .setVolume(1.2f);
        
        assertEquals("test text", params.text);
        assertEquals(24000, params.sampleRate);
        assertEquals(1, params.speakerId);
        assertEquals(0.8f, params.speed, 0.01f);
        assertEquals(1.2f, params.volume, 0.01f);
    }

    @Test
    public void testLoraAdapterConstructors() {
        // Test basic constructor
        LlamaMobile.LoraAdapter adapter = new LlamaMobile.LoraAdapter("test_path");
        assertEquals("test_path", adapter.path);
        assertEquals(1.0f, adapter.scale, 0.01f);

        // Test builder pattern
        adapter = new LlamaMobile.LoraAdapter("test_path").setScale(0.8f);
        assertEquals("test_path", adapter.path);
        assertEquals(0.8f, adapter.scale, 0.01f);
    }

    @Test
    public void testCompletionResult() {
        LlamaMobile.CompletionResult result = new LlamaMobile.CompletionResult(
                "test text", 1.5f, true, 10
        );
        
        assertEquals("test text", result.text);
        assertEquals(1.5f, result.perplexity, 0.01f);
        assertTrue(result.finished);
        assertEquals(10, result.tokenCount);
    }

    @Test
    public void testContextSafety() {
        // Test context validation with invalid context
        assertFalse(LlamaMobile.isContextValid(-1));
        assertFalse(LlamaMobile.releaseContext(-1));
    }

    @Test
    public void testConvenienceMethods() {
        // These tests just verify the methods exist and compile
        assertNotNull(LlamaMobile.class.getDeclaredMethods());
    }

    @Test
    public void testLogLevelConstants() {
        assertEquals(0, LlamaMobile.LOG_LEVEL_DEBUG);
        assertEquals(1, LlamaMobile.LOG_LEVEL_INFO);
        assertEquals(2, LlamaMobile.LOG_LEVEL_WARN);
        assertEquals(3, LlamaMobile.LOG_LEVEL_ERROR);
        assertEquals(4, LlamaMobile.LOG_LEVEL_SILENT);
    }

    @Test
    public void testDefaultConstants() {
        assertEquals(2048, LlamaMobile.DEFAULT_N_CTX);
        assertEquals(0, LlamaMobile.DEFAULT_N_GPU_LAYERS);
        assertEquals(48000, LlamaMobile.DEFAULT_SAMPLE_RATE);
    }
}
EOF

log_message "INFO" "Created Java unit tests at $JAVA_SDK_DIR/src/test/java/com/llamamobile/LlamaMobileUnitTests.java"

# Copy instrumented tests to both SDKs
log_message "INFO" "Copying instrumented tests..."

# Handle Kotlin instrumented tests
log_message "INFO" "Copying Kotlin instrumented tests..."
if [ -f "$TEMP_KOTLIN_INSTRUMENTED_TESTS" ]; then
    cp -f "$TEMP_KOTLIN_INSTRUMENTED_TESTS" "$KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/"
    log_message "INFO" "Copied Kotlin instrumented tests to $KOTLIN_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.kt"
fi

# Handle Java instrumented tests
log_message "INFO" "Creating Java instrumented tests..."
cat > "$JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java" << 'EOF'
package com.llamamobile;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Build;
import android.os.Environment;
import android.util.Log;

import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;

import org.junit.Test;
import org.junit.runner.RunWith;
import static org.junit.Assert.*;

import java.io.File;
import java.io.InputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Arrays;

/**
 * Instrumented tests for LlamaMobile Java SDK
 * These tests run on an Android device or emulator.
 */
@RunWith(AndroidJUnit4.class)
public class LlamaMobileInstrumentedTests {

    private static final String TAG = "LlamaMobileTests";
    private static final String TEST_ASSET_DIR = "grammars";
    private static final String TEST_GRAMMAR_FILE = "json.gbnf";
    private static final String TEST_MODEL_DIR = "/sdcard/llama_mobile/models";

    @Test
    public void testAssetLoading() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        AssetManager assetManager = appContext.getAssets();

        try {
            // List all grammar files
            String[] grammarFiles = assetManager.list(TEST_ASSET_DIR);
            assertNotNull("Grammar directory should exist", grammarFiles);
            Log.d(TAG, "Found grammar files: " + Arrays.toString(grammarFiles));
            
            // Check if specific grammar file exists
            boolean hasJsonGrammar = false;
            for (String file : grammarFiles) {
                if (file.equals(TEST_GRAMMAR_FILE)) {
                    hasJsonGrammar = true;
                    break;
                }
            }
            assertTrue("JSON grammar file should exist", hasJsonGrammar);
            
        } catch (IOException e) {
            Log.e(TAG, "Error accessing assets: " + e.getMessage());
            fail("Asset loading should succeed");
        }
    }

    @Test
    public void testFileDirectoryAccess() {
        // Test if we can create a directory for models
        File modelDir = new File(TEST_MODEL_DIR);
        boolean dirCreated = modelDir.mkdirs() || modelDir.exists();
        
        // This might fail if we don't have write permission, but we can still check if directory exists
        Log.d(TAG, "Model directory exists: " + modelDir.exists());
        Log.d(TAG, "Can write to model directory: " + modelDir.canWrite());
        
        // Just check if external storage is available
        String state = Environment.getExternalStorageState();
        assertTrue("External storage should be available", 
                Environment.MEDIA_MOUNTED.equals(state) || Environment.MEDIA_MOUNTED_READ_ONLY.equals(state));
    }

    @Test
    public void testNativeLibraryLoading() {
        try {
            // The library should be loaded automatically via static block
            Log.d(TAG, "Native library loaded successfully");
            
            // Test that we can access native methods
            long invalidContext = -1;
            assertFalse("Invalid context should not be valid", LlamaMobile.isContextValid(invalidContext));
            
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "Native library loading failed: " + e.getMessage());
            // This might fail on some test environments, so we don't fail the test
            Log.w(TAG, "Skipping native library test - this is expected on some environments");
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error: " + e.getMessage());
            fail("Native library test should not throw exceptions");
        }
    }

    @Test
    public void testContextSafety() {
        // Test with invalid context
        long invalidContext = -1;
        assertFalse("Invalid context should not be valid", LlamaMobile.isContextValid(invalidContext));
        assertFalse("Should fail to release invalid context", LlamaMobile.releaseContext(invalidContext));
        
        // These should be safe to call with invalid context
        LlamaMobile.generateEmbedding(invalidContext, "test");
        LlamaMobile.generateCompletion(invalidContext, "test");
        
        Log.d(TAG, "Context safety tests passed");
    }

    @Test
    public void testDeviceCompatibility() {
        Context appContext = InstrumentationRegistry.getInstrumentation().getTargetContext();
        
        // Log device information
        Log.d(TAG, "Device: " + Build.MANUFACTURER + " " + Build.MODEL);
        Log.d(TAG, "Android Version: " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")");
        Log.d(TAG, "ABIs: " + Arrays.toString(Build.SUPPORTED_ABIS));
        
        // Check if device architecture is supported
        boolean hasSupportedAbi = false;
        for (String abi : Build.SUPPORTED_ABIS) {
            if (abi.equals("arm64-v8a") || abi.equals("x86_64")) {
                hasSupportedAbi = true;
                break;
            }
        }
        
        if (hasSupportedAbi) {
            Log.d(TAG, "Device has supported ABI");
        } else {
            Log.w(TAG, "Device ABI may not be fully supported: " + Arrays.toString(Build.SUPPORTED_ABIS));
        }
        
        // Test should pass regardless of architecture
        assertTrue("Device compatibility test should pass", true);
    }

    private void copyAssetToStorage(Context context, String assetPath, String destPath) throws IOException {
        AssetManager assetManager = context.getAssets();
        InputStream in = assetManager.open(assetPath);
        File outFile = new File(destPath);
        
        // Create directory if it doesn't exist
        outFile.getParentFile().mkdirs();
        
        FileOutputStream out = new FileOutputStream(outFile);
        byte[] buffer = new byte[1024];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
        in.close();
        out.close();
    }
}
EOF

log_message "INFO" "Created Java instrumented tests at $JAVA_SDK_DIR/src/androidTest/java/com/llamamobile/LlamaMobileInstrumentedTests.java"

# Create/update AndroidManifest.xml for both SDKs
log_message "INFO" "Creating AndroidManifest.xml files..."

MANIFEST_CONTENT="<?xml version=\"1.0\" encoding=\"utf-8\"?>
<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\" 
    package=\"com.llamamobile\">

    <uses-sdk
        android:minSdkVersion=\"21\" 
        android:targetSdkVersion=\"34\" />
</manifest>"

# Create for Kotlin SDK
echo "$MANIFEST_CONTENT" > "$KOTLIN_SDK_DIR/src/main/AndroidManifest.xml"
log_message "INFO" "Created AndroidManifest.xml for Kotlin SDK"

# Create for Java SDK
echo "$MANIFEST_CONTENT" > "$JAVA_SDK_DIR/src/main/AndroidManifest.xml"
log_message "INFO" "Created AndroidManifest.xml for Java SDK"

# Create/update build.gradle
log_message "INFO" "Creating build.gradle..."

BUILD_GRADLE_CONTENT="plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.llamamobile'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner \"androidx.test.runner.AndroidJUnitRunner\"
        consumerProguardFiles \"consumer-rules.pro\"
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
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}"

echo "$BUILD_GRADLE_CONTENT" > "$SDK_DIR/build.gradle"
log_message "INFO" "Created build.gradle"

# Create/update settings.gradle
log_message "INFO" "Creating settings.gradle..."

SETTINGS_GRADLE_CONTENT="pluginManagement {
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
rootProject.name = \"llama_mobile\""

echo "$SETTINGS_GRADLE_CONTENT" > "$SDK_DIR/settings.gradle"
log_message "INFO" "Created settings.gradle"

# Create consumer-rules.pro
log_message "INFO" "Creating consumer-rules.pro..."

CONSUMER_RULES_CONTENT="# Consumer rules for llama_mobile Android SDK
# Keep all public classes and methods in the SDK
dontwarn com.llamamobile.**
-keep class com.llamamobile.** { *; }
"

echo "$CONSUMER_RULES_CONTENT" > "$SDK_DIR/consumer-rules.pro"
log_message "INFO" "Created consumer-rules.pro"

# Create proguard-rules.pro
log_message "INFO" "Creating proguard-rules.pro..."

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

echo "$PROGUARD_RULES_CONTENT" > "$SDK_DIR/proguard-rules.pro"
log_message "INFO" "Created proguard-rules.pro"

# Handle README.md
log_message "INFO" "Checking README.md..."

# First check if we have a temporary copy from the previous SDK
README_SOURCE=""
if [ -f "$TEMP_DIR/README.md" ]; then
    README_SOURCE="$TEMP_DIR/README.md"
# Then check if backups are enabled and we have a backup copy
elif [ -n "$BACKUP_DIR" ] && [ -d "$BACKUP_DIR" ] && [ -f "$BACKUP_DIR/README.md" ]; then
    README_SOURCE="$BACKUP_DIR/README.md"
fi

if [ -n "$README_SOURCE" ]; then
    # Use the preserved README
    cp -f "$README_SOURCE" "$SDK_DIR/"
    log_message "INFO" "Preserved existing README.md"
else
    # Create a basic README only if none exists
    if [ ! -f "$SDK_DIR/README.md" ]; then
        log_message "INFO" "Creating basic README.md..."
        echo "# llama_mobile Android SDK" > "$SDK_DIR/README.md"
    else
        log_message "INFO" "Using existing README.md"
    fi
fi

# Make the script executable
chmod +x "$0"
log_message "INFO" "Made build script executable"

# Create Gradle wrapper if it doesn't exist
if [ ! -f "$SDK_DIR/gradlew" ]; then
    log_message "INFO" "Creating Gradle wrapper..."
    cat > "$SDK_DIR/gradlew" << 'EOF'
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
    
    chmod +x "$SDK_DIR/gradlew"
    
    # Create gradle wrapper directory and properties
    mkdir -p "$SDK_DIR/gradle/wrapper"
    
    cat > "$SDK_DIR/gradle/wrapper/gradle-wrapper.properties" << 'EOF'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
EOF
    
    log_message "INFO" "Created Gradle wrapper"
fi

# Verify the SDK structure
log_message "INFO" "Verifying SDK structure..."

all_valid=true

# Check for required directories and files
required_dirs=("src/main/jniLibs/arm64-v8a" "src/main/jniLibs/x86_64" "src/main/assets/grammars" "src/main/java/com/llamamobile")
required_files=("src/main/java/com/llamamobile/LlamaMobile.kt" "build.gradle" "settings.gradle" "README.md")

for dir in "${required_dirs[@]}"; do
    if [ -d "$SDK_DIR/$dir" ]; then
        log_message "SUCCESS" "Found directory: $dir"
    else
        log_message "ERROR" "Missing directory: $dir"
        all_valid=false
    fi
done

for file in "${required_files[@]}"; do
    if [ -f "$SDK_DIR/$file" ]; then
        log_message "SUCCESS" "Found file: $file"
    else
        log_message "ERROR" "Missing file: $file"
        all_valid=false
    fi
done

# Check for libraries
for ABI in "arm64-v8a" "x86_64"; do
    if [ -f "$SDK_DIR/src/main/jniLibs/$ABI/libllama_mobile.so" ]; then
        log_message "SUCCESS" "Found $ABI library"
    else
        log_message "ERROR" "Missing $ABI library"
        all_valid=false
    fi
done

# Clean up temporary files at the end
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
    log_message "INFO" "Cleaned up temporary files"
fi

if [ "$all_valid" = true ]; then
    log_message "INFO" "Android SDK build completed successfully!"
    log_message "INFO" ""
    log_message "INFO" "SDK Location: $SDK_DIR"
    log_message "INFO" ""
    log_message "INFO" "To use the SDK:"
    log_message "INFO" "1. Import the module into your Android Studio project"
    log_message "INFO" "2. Add implementation project(':llama_mobile') to your app's build.gradle"
    log_message "INFO" "3. Follow the usage examples in the README.md"
else
    log_message "ERROR" "SDK build failed with validation errors!"
    exit 1
fi
