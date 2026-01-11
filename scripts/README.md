# Llama Mobile Build Scripts

This directory contains build scripts for the Llama Mobile project, supporting multiple platforms and SDKs. These scripts automate the build process and ensure consistent builds across different environments.

## Overview

| Script Name | Description | Platform |
|-------------|-------------|----------|
| `build-lib.sh` / `build-lib.bat` | Build the core library | macOS / Windows |
| `build-android.sh` / `build-android.bat` | Build Android SDK | macOS / Windows |
| `build-ios.sh` / `build-ios.bat` | Build iOS SDK | macOS / Windows |
| `build-flutter.sh` / `build-flutter.bat` | Build Flutter SDK | macOS / Windows |
| `build-capacitor.sh` | Build Capacitor plugin | macOS / Linux |
| `build-react-native.sh` / `build-react-native.bat` | Build React Native SDK | macOS / Windows |
| `env.bat` | Windows environment variables | Windows |

## Prerequisites

### macOS

- **Xcode** (with Command Line Tools)
- **CMake** (version 3.16 or higher)
- **Homebrew** (recommended for package management)
- **Node.js** (for Capacitor and React Native)
- **Android Studio** (for Android builds)

### Windows

- **Visual Studio** (2019 or newer with C++ workload)
- **CMake** (version 3.16 or higher)
- **Node.js** (for Capacitor and React Native)
- **Android Studio** (for Android builds)
- **Git Bash** (recommended for running shell scripts)

## Installation

### macOS

1. Install Xcode from the App Store
2. Install Command Line Tools:
   ```bash
   xcode-select --install
   ```
3. Install CMake via Homebrew:
   ```bash
   brew install cmake
   ```
4. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/llama_mobile.git
   cd llama_mobile
   ```

### Windows

1. Install Visual Studio 2019/2022 with C++ workload
2. Install CMake from https://cmake.org/download/
3. Install Node.js from https://nodejs.org/
4. Clone the repository using Git Bash:
   ```bash
   git clone https://github.com/yourusername/llama_mobile.git
   cd llama_mobile
   ```
5. Configure environment variables in `scripts/env.bat` (optional)

## Configuration

### Environment Variables

#### macOS

Create a `.env` file in the root directory with the following variables:

```bash
# Android build variables
ANDROID_HOME=/Users/yourusername/Library/Android/sdk
NDK_HOME=/Users/yourusername/Library/Android/sdk/ndk/25.1.8937393
```

#### Windows

Edit the `scripts/env.bat` file with your configuration:

```batch
@echo off

REM Android SDK path
set ANDROID_HOME=C:\Users\yourusername\AppData\Local\Android\Sdk

REM NDK path
set NDK_HOME=C:\Users\yourusername\AppData\Local\Android\Sdk\ndk\25.1.8937393

REM Visual Studio version (2019 or 2022)
set VS_VERSION=2022
```

## Usage

### Core Library Build

#### macOS

```bash
cd scripts
./build-lib.sh [options]
```

#### Windows

```batch
cd scripts
build-lib.bat [options]
```

##### Options

- `-h, --help` - Show help message
- `-b, --build-dir` - Custom build directory
- `-o, --output-dir` - Custom output directory
- `-s, --sdk-path` - Custom SDK path (macOS only)
- `-t, --build-type` - Build type: Release or Debug
- `-j, --jobs` - Number of build jobs
- `-c, --clean` - Clean build directory before building
- `--no-clean` - Skip cleaning build directory
- `--cmake-args` - Additional CMake arguments
- `--rc-compiler` - Path to RC compiler (Windows only)

### Android SDK Build

#### macOS

```bash
cd scripts
./build-android.sh [options]
```

#### Windows

```batch
cd scripts
build-android.bat [options]
```

### iOS SDK Build

#### macOS

```bash
cd scripts
./build-ios.sh [options]
```

#### Windows

```batch
cd scripts
build-ios.bat [options]
```

### Flutter SDK Build

#### macOS

```bash
cd scripts
./build-flutter.sh [options]
```

#### Windows

```batch
cd scripts
build-flutter.bat [options]
```

### Capacitor Plugin Build

```bash
cd scripts
./build-capacitor.sh [options]
```

### React Native SDK Build

#### macOS

```bash
cd scripts
./build-react-native.sh [options]
```

#### Windows

```batch
cd scripts
build-react-native.bat [options]
```

## Examples

### macOS Examples

```bash
# Build core library in debug mode with 8 jobs
./build-lib.sh -d -j 8

# Build Android SDK with custom NDK path
./build-android.sh --ndk-path /Users/user/Library/Android/sdk/ndk/26.0.10792818

# Build iOS SDK with custom SDK path
./build-ios.sh --sdk-path /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.0.sdk
```

### Windows Examples

```batch
# Build core library in debug mode
build-lib.bat -t Debug

# Build Android SDK with custom NDK path
build-android.bat --ndk-path "C:\Android\Sdk\ndk\26.0.10792818"

# Build React Native SDK with custom Node.js path
build-react-native.bat --node-path "C:\Program Files\nodejs\node.exe"
```

## Troubleshooting

### macOS

#### Xcode Command Line Tools Not Found

```bash
xcode-select --install
xcode-select --reset
```

#### CMake Configuration Failed

Ensure CMake is installed and in your PATH:
```bash
brew install cmake
export PATH="/usr/local/bin:$PATH"
```

### Windows

#### Visual Studio Environment Not Detected

Run the script from a Visual Studio Developer Command Prompt or set the `VSINSTALLDIR` environment variable:

```batch
set VSINSTALLDIR=C:\Program Files\Microsoft Visual Studio\2022\Community
```

#### RC Compiler Not Found

Provide the path to the RC compiler:

```batch
build-lib.bat --rc-compiler "C:\Program Files (x86)\Windows Kits\10\bin\10.0.22000.0\x64\rc.exe"
```

#### Android Build Failed

Ensure ANDROID_HOME and NDK_HOME are set correctly in `env.bat`:

```batch
set ANDROID_HOME=C:\Users\yourusername\AppData\Local\Android\Sdk
set NDK_HOME=%ANDROID_HOME%\ndk\25.1.8937393
```

## Build Output

Build artifacts are stored in platform-specific directories:

- **Core Library**: `lib/build/` (macOS), `lib/build_windows/` (Windows)
- **Android SDK**: `llama_mobile-android-sdk/`
- **iOS SDK**: `llama_mobile-ios-sdk/`
- **Flutter SDK**: `llama_mobile-flutter-sdk/`
- **Capacitor Plugin**: `llama_mobile-capacitor-plugin/`
- **React Native SDK**: `llama_mobile-react-native-sdk/`

## Contributing

When adding new scripts or modifying existing ones, follow these guidelines:

1. Maintain consistency across similar scripts (e.g., `build-*.sh` and `build-*.bat`)
2. Add proper error handling and user feedback
3. Support command line arguments for flexibility
4. Document new scripts in this README.md
5. Test scripts on both macOS and Windows

## License

See the [LICENSE](https://github.com/yourusername/llama_mobile/blob/main/LICENSE) file in the project root.