# llama_mobile

A lightweight, high-performance framework for running AI models on mobile devices, based on llama.cpp and designed for cross-platform compatibility across iOS, Android, Flutter, ReactNative, and web-based applications via Capacitor.

## Project Overview

llama_mobile is a mobile-first AI framework that brings the power of llama.cpp to various mobile platforms and development frameworks. The project focuses on providing native SDKs and plugins for seamless integration of large language models (LLMs) into mobile and web applications.

## Architecture

### Core Components

- **lib/**: Main library directory containing:
  - **lib/tests/**: Tests for the C/C++ source code
  - **lib/llama_cpp/**: Core llama.cpp implementation
  - Mobile-specific adaptations and optimizations
  - Various GGUF models (normal, embedding, VLM, multimodal)

- **llama_mobile-ios/**: iOS framework project folder
- **llama_mobile-android/**: Android library project folder
- **llama_mobile-android-SDK/**: Android SDK wrapper project folder
- **llama_mobile-flutter-SDK/**: Flutter plugin project folder
- **scripts/**: Build and utility scripts
- **CMakeLists.txt**: Build configuration for the core library

### Planned Components

- **llama_mobile_reactnative/**: ReactNative plugin
- **llama_mobile_capacitor/**: Capacitor plugin for web-based apps

## Build Scripts

The project contains various build scripts:

- **build_and_run_lib_test.sh**: Builds the core library and tests, then runs them
- **build-ios.sh**: Builds the iOS framework based on the core library
- **build-android.sh**: Builds the Android library and SDK
- **build-flutter.sh**: Builds the Flutter plugin
- (Planned) **build-reactnative.sh**: Builds the ReactNative plugin

## Getting Started

### Build Core Library

```bash
# Build core library
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### Build iOS Framework

```bash
# Build iOS framework
./build-ios.sh
```

### Build Android Library and SDK

```bash
# Build Android library and SDK
./build-android.sh
```

### Build and Run Tests

```bash
# Build and run tests
./scripts/build_and_run_lib_test.sh
```

## Current Status

The project is currently in active development with the following components completed:

- ✅ Core C++ library (based on llama.cpp)
- ✅ iOS framework
- ✅ Android library (llama_mobile-android)
- ✅ Android SDK wrapper (llama_mobile-android-SDK)
- ✅ Basic test infrastructure
- ✅ Build scripts for core library, iOS, Android, and Flutter
- ✅ Example apps for iOS, Android, and Flutter
- ✅ Flutter plugin (llama_mobile-flutter-SDK)

Planned development:

- ⏳ ReactNative plugin
- ⏳ Capacitor plugin

## Supported Models

The framework supports various GGUF model types:

- Standard language models
- Embedding models
- Vision-Language Models (VLM)
- Multimodal models

## Integration Plans

The framework currently supports integration with:

1. **Native Applications**: 
   - iOS apps via `llama_mobile_ios` framework
   - Android apps via `llama_mobile-android` library and `llama_mobile-android-SDK` wrapper

2. **Cross-Platform Frameworks**:
   - ✅ Flutter via Flutter plugin (`llama_mobile-flutter-SDK`)
   - ⏳ ReactNative via ReactNative plugin

3. **Web-Based Applications** (Planned):
   - Capacitor plugin for web apps using native iOS/Android SDKs

## Contributing

Contributions are welcome! Please feel free to:

- Submit bug fixes
- Propose new features
- Improve documentation
- Add support for additional platforms

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp) by Georgi Gerganov
- Built with inspiration from various mobile AI frameworks

## Roadmap

1. ✅ Create Flutter plugin
2. Create ReactNative plugin
3. Develop Capacitor plugin for web apps
4. Add comprehensive documentation and examples
5. Optimize performance for mobile devices
6. Expand model support and compatibility

Stay tuned for updates as we continue to develop and expand the framework!

## Building Instructions

### Prerequisites

#### Common Requirements
- CMake 3.20 or later
- Python 3.x (for some utility scripts)

#### iOS Build Requirements
- macOS with Xcode installed
- iOS 13.0+ deployment target for mobile apps

#### Android Build Requirements
- Android Studio installed
- Java Development Kit (JDK) 8 or later
- Android SDK (API level 21 or higher)
- Android NDK version 29.0.14206865 (required for building native libraries)
- Set ANDROID_HOME environment variable pointing to your Android SDK directory

### Core Library

```bash
# Build core library
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

### iOS Framework

The iOS framework requires precompiled Metal libraries for optimal performance. The build process handles this automatically.

```bash
# Build iOS framework with precompiled Metal libraries
./scripts/build-ios.sh
```

#### Metal Library Compilation Details

The iOS framework relies on precompiled Metal shader libraries (`ggml-llama.metallib` for devices and `ggml-llama-sim.metallib` for simulators). These are automatically generated during the build process with:

- **Metal Language Version**: `ios-metal2.3` (compatible with iOS 13.0+)
- **Deployment Target**: iOS 14.0 (compatible with the core library requirements)

The build script (`scripts/build-ios.sh`) handles:
1. Compiling Metal shaders from `lib/llama_cpp/ggml-metal.metal`
2. Generating device and simulator-specific metallib files
3. Assembling the `llama_mobile.xcframework`
4. Copying necessary resources

#### Verifying Metal Libraries

To verify the deployment target of the generated metallib files:

```bash
# Check device metallib deployment target
strings lib/llama_cpp/ggml-llama.metallib | grep -i "apple-ios"

# Check simulator metallib deployment target
strings lib/llama_cpp/ggml-llama-sim.metallib | grep -i "apple-ios"
```

### iOS Example App

To run the iOS example app:

1. Open `examples/iOSFrameworkExample/iOSFrameworkExample.xcodeproj` in Xcode
2. Select a target device or simulator
3. Build and run the project

### Future Building Instructions (Planned)

#### Android Library and SDK

Before building for Android, you need to ensure your development environment is properly configured:

#### Finding SDK and NDK Paths from Android Studio

You can find your SDK and NDK paths directly from Android Studio:

1. **Open Android Studio Preferences/Settings**:
   - On macOS: Android Studio → Preferences
   - On Windows/Linux: File → Settings

2. **Find Android SDK Path**:
   - Navigate to: Appearance & Behavior → System Settings → Android SDK
   - Your SDK path is displayed at the top of the window
   - Example: `/Users/yourname/Library/Android/sdk` (macOS)

3. **Find NDK Path**:
   - Still in the Android SDK settings, select the "SDK Tools" tab
   - Check the "Show Package Details" box
   - Expand the "NDK (Side by side)" section
   - Installed NDK versions are shown with their paths
   - You can also see the overall NDK location at the top
   - Example: `/Users/yourname/Library/Android/sdk/ndk/29.0.14206865`

#### Setting ANDROID_HOME

The build script will attempt to automatically detect your Android SDK path from common locations:
- macOS: `~/Library/Android/sdk` or `~/android-sdk`
- Linux: `~/Android/Sdk`, `~/android-sdk`, or `/opt/android-sdk`
- Windows (Git Bash): `%USERPROFILE%/AppData/Local/Android/Sdk` or `%USERPROFILE%/Android/Sdk`

If automatic detection fails, set ANDROID_HOME manually:

### Temporary Setting (Current Terminal Session Only)

```bash
# On macOS/Linux

export ANDROID_HOME=/path/to/your/android/sdk
./scripts/build-android.sh

# On Windows (Git Bash)
export ANDROID_HOME=C:/path/to/your/android/sdk
./scripts/build-android.sh
```

### Permanent Setting

#### On macOS/Linux

**For Bash shell:**
1. Open `~/.bash_profile` or `~/.bashrc` in a text editor
2. Add the line: `export ANDROID_HOME=/path/to/your/android/sdk`
3. Save the file
4. Run: `source ~/.bash_profile` or `source ~/.bashrc` to apply changes

**For Zsh shell (default on macOS Catalina and later):**
1. Open `~/.zshrc` in a text editor
2. Add the line: `export ANDROID_HOME=/path/to/your/android/sdk`
3. Save the file
4. Run: `source ~/.zshrc` to apply changes

**To verify the setting:**
```bash
echo $ANDROID_HOME
```
This should display the path to your Android SDK directory.

#### Setting NDK Path

The build script uses NDK version 29.0.14206865 by default. If you need to use a different NDK version, you can specify it:

```bash
# Build Android library with a specific NDK version
./scripts/build-android.sh --ndk-version=29.0.14206865
```

#### Building Android Library

```bash
# Build Android library and SDK
./scripts/build-android.sh
```

### Arm Neon Support for Android

llama_mobile fully supports Arm Neon SIMD (Single Instruction, Multiple Data) technology for Android devices, providing significant performance improvements for AI model inference on Arm-based architectures.

#### Key Features

- **Default Enabled**: Neon support is automatically enabled for `arm64-v8a` builds when using the Android NDK toolchain
- **Runtime Detection**: Neon capabilities are detected at runtime using Android's `getauxval()` system call
- **Optimized Operations**: Various performance-critical operations including matrix multiplication, tensor operations, and quantization/dequantization are optimized using Neon instructions
- **AArch64 Architecture**: Neon is guaranteed to be available on all AArch64 (ARM64) devices, and the framework leverages this guarantee for optimal performance

#### Neon Detection and Usage

The framework automatically detects and uses Neon capabilities:

1. **Hardware Feature Detection**: The code checks for Neon and related extensions (dotprod, fp16, i8mm) at runtime
2. **Optimized Path Selection**: For each supported operation, the fastest available implementation (Neon vs. generic) is selected
3. **Fallback Support**: In cases where specific Neon extensions are not available, the framework gracefully falls back to generic implementations

#### Performance Benefits

Using Neon acceleration provides significant performance improvements:
- **2-4x faster** matrix multiplication operations
- **30-50% overall performance boost** for AI model inference
- **Reduced battery consumption** due to faster computation

#### Verifying Neon Support

Neon support is automatically enabled and used by the framework. The build process includes optimized Neon code paths for all supported operations.

#### Flutter Plugin
```bash
# Flutter build script
./scripts/build-flutter.sh
```

#### ReactNative Plugin
```bash
# Planned ReactNative build script
./scripts/build-reactnative.sh
```

#### Capacitor Plugin
```bash
# Planned Capacitor build script
./scripts/build-capacitor.sh
```

## Integration Guide

### iOS Integration

1. Add `llama_mobile.xcframework` to your Xcode project
2. Link against required system frameworks (Metal, MetalKit)
3. Import the framework in your code:
   ```swift
   import llama_mobile
   ```
4. Initialize the library and load models as needed

### Android Integration

1. Add the `llama_mobile-android` library as a module dependency in your Android Studio project
2. Add the following to your `settings.gradle`:
   ```gradle
   include ':llama_mobile'
   project(':llama_mobile').projectDir = new File('../path/to/llama_mobile/llama_mobile-android')
   ```
3. Add the dependency to your app's `build.gradle`:
   ```gradle
   dependencies {
       implementation project(':llama_mobile')
   }
   ```
4. Import the library in your Kotlin code:
   ```kotlin
   import com.llamamobile.LlamaMobile
   ```
5. Initialize the library and load models as needed

### Flutter Integration

#### Flutter Setup Prerequisites

Before using the Flutter plugin, ensure Flutter is properly installed and configured:

1. **Install Flutter SDK:**
   - Download the Flutter SDK from [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
   - Extract the SDK to a location like `/Users/yourname/flutter` (macOS/Linux) or `C:\flutter` (Windows)

2. **Set up Flutter PATH:**
   
   **For macOS/Linux:**
   - **Bash shell:** Add to `~/.bash_profile` or `~/.bashrc`:
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - **Zsh shell:** Add to `~/.zshrc`:
     ```bash
   export PATH="/path/to/flutter/bin:$PATH"
     ```
   - Run `source ~/.bashrc` or `source ~/.zshrc` to apply changes

   **For Windows:**
   - Add `C:\flutter\bin` to your system PATH environment variable

3. **Verify Flutter installation:**
   ```bash
flutter doctor
   ```
   Fix any issues reported by `flutter doctor` before proceeding

4. **Ensure minimum Flutter version:**
   - This plugin requires Flutter 3.0.0 or later
   - Check your Flutter version:
     ```bash
flutter --version
     ```

#### Integrating the Flutter Plugin

1. Add the `llama_mobile_flutter_sdk` to your Flutter project's `pubspec.yaml`:
   ```yaml
dependencies:
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
```

2. Import the library in your Dart code:
   ```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
```

3. Initialize the SDK and load a model:
   ```dart
final llamaSdk = LlamaMobileFlutterSdk();
final config = ModelConfig(modelPath: 'path/to/model.gguf');
final success = await llamaSdk.loadModel(config);
```

4. Generate completions:
   ```dart
final generationConfig = GenerationConfig(prompt: 'Hello,');
final completion = await llamaSdk.generateCompletion(generationConfig);
print(completion);
```

5. Release resources when done:
   ```dart
await llamaSdk.release();
```

### Future Integrations (Planned)

- **ReactNative**: JavaScript/TypeScript wrapper around native modules
- **Capacitor**: Web-compatible plugin for cross-platform web apps

## Using the SDKs in New Projects

### iOS Swift App

#### Step 1: Create a New iOS Project
1. Open Xcode and select "Create a new Xcode project"
2. Choose "iOS" → "App"
3. Enter your project details:
   - Product Name: `LlamaMobileDemo`
   - Team: Select your development team
   - Interface: `Storyboard` or `SwiftUI`
   - Language: `Swift`
   - Minimum Deployment: `iOS 13.0` or later
4. Save the project to your desired location

#### Step 2: Add the Self-Contained SDK
1. In Xcode, right-click on your project in the Project Navigator and select "Add Files to LlamaMobileDemo..."
2. Navigate to `/path/to/llama_mobile/llama_mobile-ios/llama_mobile.xcframework`
3. Select the xcframework and ensure:
   - "Copy items if needed" is checked
   - Your target is selected under "Add to targets"
4. Click "Add"

#### Step 3: Configure Project Settings
1. Select your project in the Project Navigator
2. Go to the "Build Phases" tab
3. Under "Link Binary With Libraries", verify `llama_mobile.xcframework` is listed
4. Add required system frameworks:
   - Click the "+" button
   - Add `Metal.framework`
   - Add `MetalKit.framework`
   - Add `Accelerate.framework`

#### Step 4: Add Required Permissions
1. Open `Info.plist`
2. Add the following keys:
   - For local file access: `Privacy - File Provider Domain Usage Description`
   - For model downloads: `Privacy - Network Usage Description`

#### Step 5: Basic Usage Example

```swift
import UIKit
import llama_mobile

class ViewController: UIViewController {
    private var modelPath: String?
    private var modelHandle: UnsafeMutableRawPointer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLlamaMobile()
    }
    
    func setupLlamaMobile() {
        // Initialize the library
        llama_mobile_init()
        
        // Copy a model from bundle to documents directory
        copyModelToDocuments()
    }
    
    func copyModelToDocuments() {
        guard let modelURL = Bundle.main.url(forResource: "your-model", withExtension: "gguf") else {
            print("Model not found in bundle")
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent("your-model.gguf")
        
        if !FileManager.default.fileExists(atPath: destinationURL.path) {
            do {
                try FileManager.default.copyItem(at: modelURL, to: destinationURL)
                modelPath = destinationURL.path
                loadModel()
            } catch {
                print("Failed to copy model: \(error)")
            }
        } else {
            modelPath = destinationURL.path
            loadModel()
        }
    }
    
    func loadModel() {
        guard let modelPath = modelPath else { return }
        
        // Set model parameters
        var params = llama_mobile_params()
        params.n_threads = 4
        params.n_gpu_layers = 4
        
        // Load the model
        let result = llama_mobile_load_model(modelPath, &params)
        if result != nil {
            modelHandle = result
            print("Model loaded successfully")
            generateText()
        } else {
            print("Failed to load model")
        }
    }
    
    func generateText() {
        guard let modelHandle = modelHandle else { return }
        
        // Set generation parameters
        var genParams = llama_mobile_gen_params()
        genParams.max_new_tokens = 100
        genParams.temperature = 0.7
        
        // Generate text
        let prompt = "Hello, how are you?"
        var output = ""
        
        let callback: llama_mobile_token_callback = { token_ptr, user_data in
            if let token_ptr = token_ptr {
                let token = String(cString: token_ptr)
                output += token
                print(token, terminator: "")
            }
            return 0
        }
        
        llama_mobile_generate(modelHandle, prompt, &genParams, callback, nil)
        print("\nGeneration complete: \(output)")
    }
    
    deinit {
        // Cleanup
        if let modelHandle = modelHandle {
            llama_mobile_free_model(modelHandle)
        }
        llama_mobile_cleanup()
    }
}
```

### Android App

#### Step 1: Create a New Android Project
1. Open Android Studio
2. Select "New Project"
3. Choose "Empty Activity"
4. Enter your project details:
   - Name: `LlamaMobileDemo`
   - Package name: `com.example.llamamobiledemo`
   - Save location: Your desired location
   - Language: `Kotlin`
   - Minimum SDK: `API 21` or later
5. Click "Finish"

#### Step 2: Add the Self-Contained SDK
1. Create a `libs` directory in your app module if it doesn't exist:
   - Right-click on `app` → "New" → "Directory"
   - Name it `libs`
2. Copy the self-contained SDK files:
   - Navigate to `/path/to/llama_mobile/llama_mobile-android-SDK/`
   - Copy the `llama_mobile.aar` file to your app's `libs` directory

#### Step 3: Configure Project Settings
1. Open `app/build.gradle.kts` (or `app/build.gradle`)
2. Add the following to the `dependencies` block:
   ```gradle
   implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
   implementation("androidx.appcompat:appcompat:1.6.1")
   implementation("com.google.android.material:material:1.9.0")
   implementation("androidx.constraintlayout:constraintlayout:2.1.4")
   ```
3. Ensure the `android` block includes:
   ```gradle
   compileOptions {
       sourceCompatibility = JavaVersion.VERSION_1_8
       targetCompatibility = JavaVersion.VERSION_1_8
   }
   kotlinOptions {
       jvmTarget = "1.8"
   }
   ```
4. Sync your project with Gradle files

#### Step 4: Add Required Permissions
1. Open `app/src/main/AndroidManifest.xml`
2. Add the following permissions above the `<application>` tag:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
   ```
3. For Android 6.0+ (API 23+), you'll need to request runtime permissions

#### Step 5: Basic Usage Example

```kotlin
import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.llamamobile.sdk.LlamaMobileSdk
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream

class MainActivity : AppCompatActivity() {
    private lateinit var llamaSdk: LlamaMobileSdk
    private lateinit var generateButton: Button
    private lateinit var resultText: TextView
    private var modelPath: String? = null
    
    private val REQUEST_PERMISSIONS = 1001
    private val requiredPermissions = arrayOf(
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    )
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        generateButton = findViewById(R.id.generateButton)
        resultText = findViewById(R.id.resultText)
        
        llamaSdk = LlamaMobileSdk()
        
        // Request permissions
        if (checkPermissions()) {
            setupModel()
        } else {
            requestPermissions()
        }
        
        generateButton.setOnClickListener {
            generateText()
        }
    }
    
    private fun checkPermissions(): Boolean {
        return requiredPermissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }
    
    private fun requestPermissions() {
        ActivityCompat.requestPermissions(this, requiredPermissions, REQUEST_PERMISSIONS)
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_PERMISSIONS) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                setupModel()
            }
        }
    }
    
    private fun setupModel() {
        // Copy model from assets to internal storage
        try {
            val inputStream: InputStream = assets.open("your-model.gguf")
            val outputFile = File(filesDir, "your-model.gguf")
            val outputStream = FileOutputStream(outputFile)
            
            val buffer = ByteArray(1024)
            var bytesRead: Int
            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
            }
            
            inputStream.close()
            outputStream.close()
            
            modelPath = outputFile.absolutePath
            loadModel()
            
        } catch (e: IOException) {
            e.printStackTrace()
            resultText.text = "Failed to copy model: \${e.message}"
        }
    }
    
    private fun loadModel() {
        try {
            if (modelPath != null) {
                val success = llamaSdk.loadModel(modelPath!!)
                if (success) {
                    resultText.text = "Model loaded successfully!"
                } else {
                    resultText.text = "Failed to load model"
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
            resultText.text = "Error loading model: \${e.message}"
        }
    }
    
    private fun generateText() {
        try {
            val prompt = "Hello, how are you?"
            val result = llamaSdk.generateText(prompt, 100, 0.7f)
            resultText.text = "Generated: \n\$result"
        } catch (e: Exception) {
            e.printStackTrace()
            resultText.text = "Error generating text: \${e.message}"
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        llamaSdk.release()
    }
}
```

### Flutter App

#### Step 1: Create a New Flutter Project
1. Open your terminal and run:
   ```bash
   flutter create llama_mobile_demo
   cd llama_mobile_demo
   ```
2. Open the project in your preferred IDE (VS Code or Android Studio)

#### Step 2: Add the Self-Contained Plugin
1. Open `pubspec.yaml` in your Flutter project
2. Add the plugin dependency:
   ```yaml
dependencies:
  flutter:
    sdk: flutter
  llama_mobile_flutter_sdk:
    path: /path/to/llama_mobile/llama_mobile-flutter-SDK
  path_provider: ^2.1.1
  permission_handler: ^11.3.1
```
3. Run `flutter pub get` to install dependencies

#### Step 3: Configure Platform-Specific Settings

##### iOS Configuration
1. Open `ios/Runner/Info.plist`
2. Add required permissions:
   ```xml
   <key>NSDocumentDirectoryUsageDescription</key>
   <string>Access to documents directory for model storage</string>
   <key>NSNetworkUsageDescription</key>
   <string>Network access for model downloads</string>
   ```

##### Android Configuration
1. Open `android/app/src/main/AndroidManifest.xml`
2. Add required permissions:
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
   ```

#### Step 4: Basic Usage Example

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Llama Mobile Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Llama Mobile Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LlamaMobileFlutterSdk _llamaSdk = LlamaMobileFlutterSdk();
  bool _isModelLoaded = false;
  String _result = '';
  bool _isGenerating = false;
  String _modelPath = '';

  @override
  void initState() {
    super.initState();
    _setupModel();
  }

  Future<void> _setupModel() async {
    // Request permissions
    if (Platform.isAndroid) {
      await Permission.storage.request();
      await Permission.manageExternalStorage.request();
    }

    // Copy model from assets to app directory
    await _copyModelFromAssets();
    
    // Load the model
    await _loadModel();
  }

  Future<void> _copyModelFromAssets() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final destination = File('\${directory.path}/your-model.gguf');

      if (!await destination.exists()) {
        final byteData = await rootBundle.load('assets/your-model.gguf');
        await destination.writeAsBytes(byteData.buffer.asUint8List());
      }

      setState(() {
        _modelPath = destination.path;
      });
    } catch (e) {
      setState(() {
        _result = 'Error copying model: \$e';
      });
    }
  }

  Future<void> _loadModel() async {
    try {
      if (_modelPath.isNotEmpty) {
        final config = ModelConfig(
          modelPath: _modelPath,
          nThreads: 4,
          nGpuLayers: 4,
        );

        final success = await _llamaSdk.loadModel(config);
        setState(() {
          _isModelLoaded = success;
          _result = success ? 'Model loaded successfully!' : 'Failed to load model';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error loading model: \$e';
      });
    }
  }

  Future<void> _generateText() async {
    if (!_isModelLoaded || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _result = 'Generating...';
    });

    try {
      final generationConfig = GenerationConfig(
        prompt: 'Hello, how are you today?',
        maxNewTokens: 100,
        temperature: 0.7,
        topP: 0.9,
      );

      final completion = await _llamaSdk.generateCompletion(generationConfig);
      setState(() {
        _result = 'Generated:\n\$completion';
      });
    } catch (e) {
      setState(() {
        _result = 'Error generating text: \$e';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  @override
  void dispose() {
    _llamaSdk.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Model Status: \${_isModelLoaded ? 'Loaded' : 'Not Loaded'}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isModelLoaded ? _generateText : null,
                child: _isGenerating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Generate Text'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Adding Model Files

For all platforms, you'll need to add your GGUF model files:

#### iOS
1. Drag your `your-model.gguf` file into Xcode
2. Select "Copy items if needed" and add to your target

#### Android
1. Create an `assets` directory in `app/src/main/` if it doesn't exist
2. Copy your `your-model.gguf` file into the `assets` directory

#### Flutter
1. Create an `assets` directory at the root of your Flutter project
2. Add your `your-model.gguf` file to the `assets` directory
3. Update `pubspec.yaml` to include the asset:
   ```yaml
   flutter:
     assets:
       - assets/your-model.gguf
   ```

### Error Handling Best Practices

1. **Model Loading Errors:**
   - Check if the model file exists and is accessible
   - Verify model format is compatible (GGUF)
   - Ensure sufficient device resources (memory, storage)

2. **Inference Errors:**
   - Handle timeouts for long-running generation tasks
   - Implement progress callbacks to provide user feedback
   - Catch exceptions related to insufficient memory

3. **Permission Issues:**
   - Always request necessary permissions before accessing files
   - Provide clear error messages when permissions are denied
   - Follow platform-specific permission guidelines

## Troubleshooting

### Metal Library Deployment Target Errors

If you encounter errors like:
```
This library is using a deployment target (0x00020008) that is not supported on this OS
```

This indicates incompatible Metal library deployment targets. The build script ensures compatibility by:
- Using `ios-metal2.3` language version (iOS 13.0+ compatible)
- Setting explicit deployment targets for both device and simulator builds

### Build Script Issues

Ensure all dependencies are installed and that you're running the scripts from the project root directory.
