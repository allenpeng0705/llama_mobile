# llama_mobile Android SDK

The llama_mobile Android SDK provides Kotlin and Java wrappers around the llama_mobile C API for easy integration into Android applications. It includes pre-built native libraries with JNI bindings and Kotlin extensions for a modern, idiomatic API.

## Project Overview

The llama_mobile Android SDK is a lightweight, high-performance library for running AI models on Android devices. It provides both Java and Kotlin interfaces around the llama_mobile native C++ library, enabling developers to integrate large language models (LLMs) into Android applications with minimal effort.

## Features

- **Dual API Support**: Both Java and Kotlin APIs for maximum flexibility
- **Kotlin Extensions**: DSL builders, coroutine support, and functional extensions
- **Pre-built Native Libraries**: Optimized C++ libraries with Neon SIMD support for ARM64
- **Model Compatibility**: Support for various GGUF model formats
- **Multimodal Support**: Text generation, embeddings, text-to-speech, and vision capabilities
- **LoRA Adapter Support**: Dynamic model fine-tuning at runtime
- **Download API**: Built-in support for downloading models from Hugging Face
- **Progress Callbacks**: Real-time progress updates for long-running operations

## Project Structure

```
llama_mobile-android-SDK/
├── src/
│   ├── main/
│   │   ├── java/                 # Java source code
│   │   │   └── com/llamamobile/
│   │   │       └── LlamaMobile.java    # Main Java API wrapper
│   │   ├── kotlin/               # Kotlin extensions
│   │   │   └── com/llamamobile/
│   │   │       └── LlamaMobileKt.kt    # Kotlin DSL and extensions
│   │   ├── jniLibs/              # Pre-built native libraries
│   │   │   ├── arm64-v8a/        # 64-bit ARM devices
│   │   │   │   └── libllama_mobile.a     # Main native library (static)
│   │   │   └── x86_64/           # x86_64 emulators
│   │   │       └── libllama_mobile.a     # Main native library (static)
│   │   ├── cpp/                  # JNI implementation
│   │   │   ├── CMakeLists.txt    # Build configuration
│   │   │   └── llama_mobile_jni.cpp # JNI bridge code
│   │   └── AndroidManifest.xml   # Android manifest file
│   └── androidTest/              # Comprehensive instrumented tests
│       └── java/com/llamamobile/
│           └── LlamaMobileComprehensiveTests.kt # SDK test cases
├── build.gradle                  # Gradle build configuration
├── settings.gradle               # Gradle settings
├── consumer-rules.pro            # ProGuard rules for SDK users
└── proguard-rules.pro            # ProGuard rules for SDK itself
```

## Building

### What is "Building" the SDK?

The llama_mobile-android-SDK is a library project that packages:
- **Pre-built native libraries** (copied from `llama_mobile-android/libs/`)
- **Java wrapper code** (LlamaMobile.java)
- **Kotlin extensions** (LlamaMobileKt.kt)

"Building" the SDK refers to compiling the Java/Kotlin wrapper and packaging everything into an AAR (Android Archive) file that can be imported into Android applications. The native C++ libraries are pre-built and simply copied during this process.

### When to Build the SDK

You typically need to build the SDK:
1. When you've updated the native libraries in `llama_mobile-android/libs/`
2. To regenerate the SDK structure after making changes to Java/Kotlin wrapper
3. To create a fresh AAR file for distribution
4. To verify that all tests pass

### How to Build the SDK

#### Using Gradle Command Line

```bash
# Navigate to SDK directory
cd llama_mobile-android-SDK

# Build debug AAR
./gradlew assembleDebug

# Build release AAR
./gradlew assembleRelease

# Build and run tests
./gradlew connectedAndroidTest
```

#### Using Android Studio

1. Open Android Studio
2. Select `File > Open` and navigate to `llama_mobile-android-SDK` directory
3. Click `Open` to load the project as a library
4. Select `Build > Make Project` (or press Cmd+F9 on macOS, Ctrl+F9 on Windows)

#### Using Build Script

```bash
# Navigate to root directory
cd llama_mobile

# Rebuild Android SDK structure
./scripts/build-android-SDK.sh
```

This script will:
1. Copy the latest pre-built static libraries from `llama_mobile-android/libs/`
2. Update the Android SDK structure with the latest files
3. Run all tests (unit and instrumented)
4. Build the SDK and generate AAR files
5. Copy AAR files to the centralized output directory

**Note**: The SDK uses `c++_static` STL to avoid external dependencies on `libc++_shared.so`. You can override this by setting the `ANDROID_STL` environment variable:

```bash
# Use c++_static (default, no external dependencies)
./scripts/build-android-SDK.sh

# Use c++_shared (smaller library size, requires libc++_shared.so)
ANDROID_STL=c++_shared ./scripts/build-android-SDK.sh
```

## Output Directory

After building, the AAR file is available at:
- **Debug AAR**: `build/outputs/aar/llama_mobile-android-SDK-debug.aar`
- **Release AAR**: `build/outputs/aar/llama_mobile-android-SDK-release.aar`

## Integration Options

### Option 1: Import as a Module in Android Studio (Recommended)

1. **Open your Android project** in Android Studio
2. **Import the SDK as a module**:
   - Select `File > New > Import Module`
   - Navigate to the `llama_mobile-android-SDK` directory
   - Click `Finish` to import
3. **Add the dependency** to your app module:
   - Open your app's `build.gradle` file
   - In the `dependencies` block, add:
     ```gradle
     dependencies {
         implementation project(':llama_mobile-android-SDK')
     }
     ```
4. **Sync your project** with Gradle

**Note**: If Android Studio's import wizard fails to recognize the SDK as a module due to AGP version mismatch, you can manually add the module reference:
1. Open `settings.gradle` and add:
   ```gradle
   include ':llama_mobile-android-SDK'
   project(':llama_mobile-android-SDK').projectDir = new File('../llama_mobile-android-SDK')
   ```
2. Open `app/build.gradle` and add:
   ```gradle
   dependencies {
       implementation project(':llama_mobile-android-SDK')
   }
   ```

### Option 2: Use AAR File

1. **Generate the AAR file**:
   - Open the SDK project in Android Studio
   - Select `Build > Make Project`
   - Find the AAR file at `build/outputs/aar/llama_mobile-android-SDK-release.aar`

2. **Add the AAR to your project**:
   - Create a `libs` directory in your app's module if it doesn't exist
   - Copy the AAR file into `app/libs/`

3. **Update your app's build.gradle**:
   ```gradle
   repositories {
       flatDir {
           dirs 'libs'
       }
   }
   
   dependencies {
       implementation(name: 'llama_mobile-android-SDK-release', ext: 'aar')
   }
   ```

4. **Sync your project** with Gradle

### Option 3: Direct Integration (For Advanced Users)

If you prefer to integrate components directly:

1. **Copy native libraries**:
   - Copy `llama_mobile-android-SDK/src/main/jniLibs/` to your app's `src/main/jniLibs/`
   - This includes `libllama_mobile.a` static library for each ABI

2. **Copy Java/Kotlin wrapper**:
   - Copy `llama_mobile-android-SDK/src/main/java/com/llamamobile/` to your app's source directory
   - Copy `llama_mobile-android-SDK/src/main/kotlin/com/llamamobile/` to your app's source directory

3. **Copy JNI implementation**:
   - Copy `llama_mobile-android-SDK/src/main/cpp/` to your app's `src/main/cpp/`

4. **Update build.gradle**:
   ```gradle
   android {
       externalNativeBuild {
           cmake {
               path "src/main/cpp/CMakeLists.txt"
           }
       }
       
       defaultConfig {
           ndk {
               abiFilters 'arm64-v8a', 'x86_64'
               stl "c++_static"
           }
       }
   }
   
   dependencies {
       implementation 'androidx.core:core-ktx:1.12.0'
       implementation 'androidx.appcompat:appcompat:1.6.1'
   }
   ```

**Note**: The SDK uses `c++_static` STL by default, which means no external `libc++_shared.so` dependency is required.

## Requirements

- **Minimum SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34 (Android 14)
- **Compile SDK**: API 34 (Android 14)
- **Kotlin**: 1.9.0+
- **Java**: 8+
- **Architecture**: arm64-v8a (recommended), x86_64 (emulators only)

## Dependencies

The SDK requires the following AndroidX libraries:

- `androidx.core:core-ktx:1.12.0`
- `androidx.appcompat:appcompat:1.6.1`

These are automatically included when using Gradle dependency management.

## Permissions

Depending on where you store your model files, you may need to add the following permissions to your app's `AndroidManifest.xml`:

```xml
<!-- For accessing models in external storage -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- For Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

**Note**: For Android 10+ (API 29+), consider using scoped storage and storing models in your app's private directory:
```kotlin
val modelDir = File(context.filesDir, "models")
modelDir.mkdirs()
val modelPath = File(modelDir, "model.gguf").absolutePath
```

## Testing

The SDK includes comprehensive instrumented tests that run on Android devices or emulators.

### Running Tests with Android Studio

#### Prerequisites
- Android Studio (latest version recommended)
- Android SDK with API levels 21-34
- Android device (USB debugging enabled) or emulator

#### Steps
1. Open the SDK project in Android Studio
2. Connect an Android device or start an emulator
3. Navigate to `src/androidTest/java/com/llamamobile/LlamaMobileComprehensiveTests.kt`
4. Right-click on the test file and select `Run 'LlamaMobileComprehensiveTests'`
5. Select your target device/emulator when prompted
6. View results in the "Run" window at the bottom

### Running Tests with Command Line

#### Prerequisites
- Android SDK with `adb` and `gradle` tools in your PATH
- Connected Android device/emulator

#### Steps
```bash
# Navigate to SDK directory
cd llama_mobile-android-SDK

# Ensure device/emulator is connected
adb devices

# Run all instrumented tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileComprehensiveTests"

# Run specific test method
./gradlew connectedAndroidTest --tests "com.llamamobile.LlamaMobileComprehensiveTests.testInitParamsConstructors"
```

### Test Configuration

The tests use internal device storage for model files. The tests automatically create the following directory structure:

```
/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/
├── models/
│   ├── SmolVLM-256M-Instruct-Q8_0.gguf           # Main model
│   ├── OuteTTS-0.2-500M-Q6_K.gguf               # TTS model
│   ├── WavTokenizer-Large-75-F16.gguf           # Vocoder model
│   ├── Qwen3-Embedding-0.6B-Q8_0.gguf       # Embedding model
│   ├── lora/
│   │   └── fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf
│   └── img/
│       └── image.jpg
└── llama_mobile_test/                            # Test output directory
```

### Placing Model Files for Testing

#### Option 1: Use Android Studio Device File Explorer
1. Connect your device/emulator
2. Go to `View > Tool Windows > Device File Explorer`
3. Navigate to `/storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/`
4. Create the `models` directory structure as shown above
5. Upload your model files to the appropriate locations

#### Option 2: Use ADB Command Line
```bash
# Create directory structure
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/lora
adb shell mkdir -p /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/img

# Upload model files
adb push ~/Documents/models/SmolVLM-256M-Instruct-Q8_0.gguf /storage/emulated/0/Android/data/com.llamamobile.llama_mobile-android-SDK/files/models/
```

### Test Results

- **Instrumented Tests**: Results are in `build/reports/androidTests/connected/index.html`
- **Test Coverage**: The SDK includes 74+ comprehensive tests covering all APIs

## Troubleshooting

### Common Issues

1. **Native Library Loading Errors**:
   - **Symptom**: `java.lang.UnsatisfiedLinkError: dalvik.system.PathClassLoader`
   - **Cause**: Native libraries not properly included in the APK
   - **Solution**: Ensure `.a` files are in the correct `jniLibs` directories for your target ABIs

2. **Module Import Issues**:
   - **Symptom**: Android Studio fails to recognize SDK as a module
   - **Cause**: Android Gradle Plugin (AGP) version mismatch
   - **Solution**: Manually add module reference in `settings.gradle` and `app/build.gradle` (see Integration Options above)

3. **Model Access Permissions**:
   - **Symptom**: `java.io.FileNotFoundException: /sdcard/...`
   - **Cause**: Missing storage permissions or scoped storage restrictions
   - **Solution**: Add required permissions to `AndroidManifest.xml` or use app's private storage directory

4. **JNI Method Not Found**:
   - **Symptom**: `java.lang.NoSuchMethodError: no static method`
   - **Cause**: JNI method signature mismatch between Java and native code
   - **Solution**: Ensure you're using the correct API version and method signatures

5. **Context Initialization Fails**:
   - **Symptom**: `initContext()` returns 0
   - **Cause**: Invalid model path, corrupted model file, or insufficient memory
   - **Solution**: Verify model file exists, is readable, and device has enough memory

6. **C++ STL Configuration Issues**:
   - **Symptom**: Build errors related to C++ standard library
   - **Cause**: Incorrect STL configuration
   - **Solution**: Ensure your app's build.gradle uses compatible STL setting:
     ```gradle
     defaultConfig {
         ndk {
             stl "c++_static"
         }
     }
     ```
   - **Note**: The SDK uses `c++_static` by default to avoid external dependencies. If you need to use `c++_shared`, ensure `libc++_shared.so` is available and all native libraries use the same STL.

### ProGuard/R8 Configuration

If you use ProGuard or R8 in your app, add the following rules to your ProGuard configuration file:

```proguard
# Keep LlamaMobile classes
-keep class com.llamamobile.** { *; }
-keepclassmembers class com.llamamobile.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
```

The SDK includes `consumer-rules.pro` that you can copy to your app's ProGuard configuration.

### Debugging

Enable verbose logging to help diagnose issues:

```kotlin
// Native library logging is controlled by build configuration
// For debug builds, you'll see more detailed logs in Logcat
adb logcat | grep llama_mobile
```

## License

The llama_mobile Android SDK is available under the MIT license. See the LICENSE file for more information.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) - A port of Facebook's LLaMA model in C/C++
- Inspired by the need for lightweight, on-device AI solutions for mobile applications
