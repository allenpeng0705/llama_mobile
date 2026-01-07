@echo off
setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "FLUTTER_SDK_DIR=%ROOT_DIR%\llama_mobile-flutter-SDK"
set "EXAMPLE_APP_DIR=%ROOT_DIR%\examples\flutterSDKExample"

REM Show help message
:show_help
    echo Usage: %~nx0 [OPTIONS]
    echo.
    echo Builds the llama_mobile Flutter plugin and optionally the example app.
    echo.
    echo Options:
    echo   -h, --help             Show this help message and exit
    exit /b 0

REM Parse command line arguments
if "%~1"=="" (
    goto :start_build
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if /i "%~1"=="help" goto :show_help
REM Unknown parameter handling
echo Unknown parameter: %~1
echo Use --help for usage information
exit /b 1

:start_build
REM Check if flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo flutter could not be found, please install Flutter SDK from https://flutter.dev/docs/get-started/install
    exit /b 1
)

for /f "tokens=*" %%i in ('flutter --version ^| head -n 1') do set "FLUTTER_VERSION=%%i"
echo Using Flutter: %FLUTTER_VERSION%

REM Check if the Flutter plugin directory exists
if not exist "%FLUTTER_SDK_DIR%" (
    echo ✗ Error: Flutter plugin directory not found at %FLUTTER_SDK_DIR%!
    exit /b 1
)

REM Check if the example app directory exists
if not exist "%EXAMPLE_APP_DIR%" (
    echo ✗ Error: Example app directory not found at %EXAMPLE_APP_DIR%!
    exit /b 1
)

REM Function to copy iOS SDK into Flutter plugin
:copy_ios_sdk_to_plugin
    echo === Copying iOS SDK into Flutter plugin ===
    
    REM iOS SDK is not supported on Windows
    echo ⚠ iOS SDK cannot be built or copied on Windows
    echo ⚠ iOS framework will not be available in the Flutter plugin
    echo ⚠ Flutter plugin will only work for Android on Windows
    echo.
    goto :eof

REM Function to copy Android SDK into Flutter plugin
:copy_android_sdk_to_plugin
    echo === Copying Android SDK into Flutter plugin ===
    
    set "FLUTTER_ANDROID_DIR=%FLUTTER_SDK_DIR%\android"
    set "ANDROID_SDK_DIR=%ROOT_DIR%\llama_mobile-android-SDK"
    
    REM Copy JNI libraries
    echo - Copying Android JNI libraries... 
    set "FLUTTER_JNI_LIBS_DIR=%FLUTTER_ANDROID_DIR%\src\main\jniLibs"
    set "ANDROID_JNI_LIBS_DIR=%ANDROID_SDK_DIR%\src\main\jniLibs"
    
    if not exist "%FLUTTER_JNI_LIBS_DIR%" mkdir "%FLUTTER_JNI_LIBS_DIR%"
    if exist "%FLUTTER_JNI_LIBS_DIR%\*" del /q /s "%FLUTTER_JNI_LIBS_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_JNI_LIBS_DIR%" "%FLUTTER_JNI_LIBS_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android JNI libraries
        exit /b 1
    )
    
    REM Copy JNI C++ files
    echo - Copying Android JNI C++ files... 
    set "FLUTTER_CPP_DIR=%FLUTTER_ANDROID_DIR%\src\main\cpp"
    set "ANDROID_CPP_DIR=%ANDROID_SDK_DIR%\src\main\cpp"
    
    if not exist "%FLUTTER_CPP_DIR%" mkdir "%FLUTTER_CPP_DIR%"
    if exist "%FLUTTER_CPP_DIR%\*" del /q /s "%FLUTTER_CPP_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_CPP_DIR%" "%FLUTTER_CPP_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android JNI C++ files
        exit /b 1
    )
    
    REM Copy Kotlin/Java files
    echo - Copying Android Kotlin/Java files... 
    set "FLUTTER_JAVA_DIR=%FLUTTER_ANDROID_DIR%\src\main\java"
    set "ANDROID_JAVA_DIR=%ANDROID_SDK_DIR%\src\main\java"
    
    if not exist "%FLUTTER_JAVA_DIR%" mkdir "%FLUTTER_JAVA_DIR%"
    if exist "%FLUTTER_JAVA_DIR%\*" del /q /s "%FLUTTER_JAVA_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_JAVA_DIR%" "%FLUTTER_JAVA_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android Kotlin/Java files
        exit /b 1
    )
    
    REM Copy assets/grammars folder
    echo - Copying Android assets/grammars folder... 
    set "FLUTTER_ASSETS_DIR=%FLUTTER_ANDROID_DIR%\src\main\assets"
    set "ANDROID_ASSETS_DIR=%ANDROID_SDK_DIR%\src\main\assets"
    
    if not exist "%FLUTTER_ASSETS_DIR%\grammars" mkdir "%FLUTTER_ASSETS_DIR%\grammars"
    
    xcopy /s /e /i /y "%ANDROID_ASSETS_DIR%\grammars" "%FLUTTER_ASSETS_DIR%\grammars" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android assets/grammars folder
        exit /b 1
    )
    goto :eof

REM Function to build the Flutter plugin
:build_plugin
    echo === Building llama_mobile Flutter plugin ===
    
    pushd "%FLUTTER_SDK_DIR%"
    
    REM Build Android SDK dependency first
    if exist "%SCRIPT_DIR%\build-android.bat" (
        echo Building Android SDK dependency first
        call "%SCRIPT_DIR%\build-android.bat"
        if %errorlevel% neq 0 (
            echo ✗ Android SDK build failed!
            popd
            exit /b 1
        )
        echo ✓ Android SDK built successfully
    ) else (
        echo ✗ Error: Android build script not found at %SCRIPT_DIR%\build-android.bat
        echo Please ensure the Android build script exists before building the Flutter plugin
        popd
        exit /b 1
    )
    
    REM Copy SDKs into Flutter plugin to make it self-contained
    call :copy_ios_sdk_to_plugin
    call :copy_android_sdk_to_plugin
    
    REM Get dependencies
    echo Getting Flutter dependencies...
    flutter pub get
    if %errorlevel% neq 0 (
        echo ✗ Flutter dependencies resolution failed!
        popd
        exit /b 1
    )
    echo ✓ Flutter dependencies resolved successfully
    
    REM Verify the plugin can be built by analyzing it
    echo Analyzing plugin code...
    flutter analyze
    if %errorlevel% neq 0 (
        echo ✗ Plugin code analysis failed!
        popd
        exit /b 1
    )
    echo ✓ Plugin code analyzed successfully
    
    popd
    echo === Flutter plugin build completed successfully! ===
    echo Plugin is available at: %FLUTTER_SDK_DIR%
    goto :eof

REM Function to build the example app
:build_example
    echo === Building llama_mobile Flutter example app ===
    
    pushd "%EXAMPLE_APP_DIR%"
    
    REM Get dependencies
    echo Getting example app dependencies...
    flutter pub get
    if %errorlevel% neq 0 (
        echo ✗ Example app dependencies resolution failed!
        popd
        exit /b 1
    )
    echo ✓ Example app dependencies resolved successfully
    
    REM Build the example app for Android (iOS not supported on Windows)
    echo Building example app for Android...
    flutter build apk --debug
    if %errorlevel% neq 0 (
        echo ✗ Android example app build failed!
        popd
        exit /b 1
    )
    echo ✓ Android example app built successfully
    
    popd
    echo === Flutter example app build completed successfully! ===
    echo Example app is available at: %EXAMPLE_APP_DIR%
    echo Run the example app with: flutter run
    goto :eof

REM Execute both plugin build and example app build
call :build_plugin
call :build_example

exit /b 0