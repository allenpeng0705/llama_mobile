@echo off
setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "REACT_NATIVE_SDK_DIR=%ROOT_DIR%\llama_mobile-react-native-SDK"
set "EXAMPLE_APP_DIR=%REACT_NATIVE_SDK_DIR%\example"

REM Parse command line arguments
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if /i "%~1"=="help" goto :show_help
if not "%~1"=="" (
    echo Unknown parameter: %~1
    echo Use --help for usage information
    exit /b 1
)

REM Proceed to main build process after successful argument parsing
goto :start_build

REM Show help message - defined after the main build logic to prevent unintended execution
:show_help
    echo Usage: %~nx0 [OPTIONS]
    echo.
    echo Builds the llama_mobile React Native SDK and optionally the example app.
    echo.
    echo Options:
    echo   -h, --help             Show this help message and exit
    exit /b 0

REM Main build process starts here
:start_build
REM Check if node and npm are installed
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo node could not be found, please install Node.js from https://nodejs.org/
    exit /b 1
)

where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo npm could not be found, please install Node.js from https://nodejs.org/
    exit /b 1
)

for /f "tokens=*" %%i in ('node --version') do set "NODE_VERSION=%%i"
echo Using Node.js: %NODE_VERSION%

for /f "tokens=*" %%i in ('npm --version') do set "NPM_VERSION=%%i"
echo Using npm: %NPM_VERSION%

REM Check if the React Native SDK directory exists
if not exist "%REACT_NATIVE_SDK_DIR%" (
    echo ✗ Error: React Native SDK directory not found at %REACT_NATIVE_SDK_DIR%!
    exit /b 1
)

REM Check if the example app directory exists
if not exist "%EXAMPLE_APP_DIR%" (
    echo ✗ Error: Example app directory not found at %EXAMPLE_APP_DIR%!
    exit /b 1
)

REM Function to copy iOS SDK into React Native SDK
:copy_ios_sdk_to_plugin
    echo === Copying iOS SDK into React Native SDK ===
    
    REM iOS SDK is not supported on Windows
    echo ⚠ iOS SDK cannot be built or copied on Windows
    echo ⚠ iOS framework will not be available in the React Native SDK
    echo ⚠ React Native SDK will only work for Android on Windows
    echo.
    goto :eof

REM Function to copy Android SDK into React Native SDK
:copy_android_sdk_to_plugin
    echo === Copying Android SDK into React Native SDK ===
    
    set "REACT_NATIVE_ANDROID_DIR=%REACT_NATIVE_SDK_DIR%\android"
    set "ANDROID_SDK_DIR=%ROOT_DIR%\llama_mobile-android-SDK"
    
    REM Copy JNI libraries
    echo - Copying Android JNI libraries... 
    set "REACT_NATIVE_JNI_LIBS_DIR=%REACT_NATIVE_ANDROID_DIR%\src\main\jniLibs"
    set "ANDROID_JNI_LIBS_DIR=%ANDROID_SDK_DIR%\src\main\jniLibs"
    
    if not exist "%REACT_NATIVE_JNI_LIBS_DIR%" mkdir "%REACT_NATIVE_JNI_LIBS_DIR%"
    if exist "%REACT_NATIVE_JNI_LIBS_DIR%\*" del /q /s "%REACT_NATIVE_JNI_LIBS_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_JNI_LIBS_DIR%" "%REACT_NATIVE_JNI_LIBS_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android JNI libraries
        exit /b 1
    )
    
    REM Copy JNI C++ files
    echo - Copying Android JNI C++ files... 
    set "REACT_NATIVE_CPP_DIR=%REACT_NATIVE_ANDROID_DIR%\src\main\cpp"
    set "ANDROID_CPP_DIR=%ANDROID_SDK_DIR%\src\main\cpp"
    
    if not exist "%REACT_NATIVE_CPP_DIR%" mkdir "%REACT_NATIVE_CPP_DIR%"
    if exist "%REACT_NATIVE_CPP_DIR%\*" del /q /s "%REACT_NATIVE_CPP_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_CPP_DIR%" "%REACT_NATIVE_CPP_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android JNI C++ files
        exit /b 1
    )
    
    REM Copy Java files
    echo - Copying Android Java files... 
    set "REACT_NATIVE_JAVA_DIR=%REACT_NATIVE_ANDROID_DIR%\src\main\java\com\llamamobile\sdk"
    set "ANDROID_JAVA_DIR=%ANDROID_SDK_DIR%\src\main\java\com\llamamobile\sdk"
    
    if not exist "%REACT_NATIVE_JAVA_DIR%" mkdir "%REACT_NATIVE_JAVA_DIR%"
    if exist "%REACT_NATIVE_JAVA_DIR%\*" del /q /s "%REACT_NATIVE_JAVA_DIR%\*" >nul 2>nul
    
    xcopy /s /e /i /y "%ANDROID_JAVA_DIR%" "%REACT_NATIVE_JAVA_DIR%" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android Java files
        exit /b 1
    )
    
    REM Copy assets/grammars folder
    echo - Copying Android assets/grammars folder... 
    set "REACT_NATIVE_ASSETS_DIR=%REACT_NATIVE_ANDROID_DIR%\src\main\assets"
    set "ANDROID_ASSETS_DIR=%ANDROID_SDK_DIR%\src\main\assets"
    
    if not exist "%REACT_NATIVE_ASSETS_DIR%\grammars" mkdir "%REACT_NATIVE_ASSETS_DIR%\grammars"
    
    xcopy /s /e /i /y "%ANDROID_ASSETS_DIR%\grammars" "%REACT_NATIVE_ASSETS_DIR%\grammars" >nul 2>nul
    if %errorlevel% leq 1 (
        echo   ✓
    ) else (
        echo   ✗
        echo Failed to copy Android assets/grammars folder
        exit /b 1
    )
    goto :eof

REM Function to build the React Native SDK
:build_sdk
    echo === Building llama_mobile React Native SDK ===
    
    pushd "%REACT_NATIVE_SDK_DIR%"
    
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
        echo Please ensure the Android build script exists before building the React Native SDK
        popd
        exit /b 1
    )
    
    REM Copy SDKs into React Native SDK to make it self-contained
    call :copy_ios_sdk_to_plugin
    call :copy_android_sdk_to_plugin
    
    REM Install dependencies
    echo Installing React Native SDK dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ✗ React Native SDK dependencies installation failed!
        popd
        exit /b 1
    )
    echo ✓ React Native SDK dependencies installed successfully
    
    popd
    echo === React Native SDK build completed successfully! ===
    echo SDK is available at: %REACT_NATIVE_SDK_DIR%
    goto :eof

REM Function to build the example app
:build_example
    echo === Building llama_mobile React Native example app ===
    
    if not exist "%EXAMPLE_APP_DIR%" (
        echo ✗ Error: Example app directory not found at %EXAMPLE_APP_DIR%!
        exit /b 1
    )
    
    pushd "%EXAMPLE_APP_DIR%"
    
    REM Install dependencies
    echo Installing example app dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ✗ Example app dependencies installation failed!
        popd
        exit /b 1
    )
    echo ✓ Example app dependencies installed successfully
    
    REM Link dependencies (if needed)
    echo Linking dependencies...
    npx react-native link
    if %errorlevel% neq 0 (
        echo ✗ Dependency linking failed!
        echo This might be expected for newer React Native versions that use autolinking
    )
    
    REM Build the example app for Android (iOS not supported on Windows)
    echo Building example app for Android...
    npx react-native run-android --mode=debug
    if %errorlevel% neq 0 (
        echo ✗ Android example app build failed!
        popd
        exit /b 1
    )
    echo ✓ Android example app built successfully
    
    popd
    echo === React Native example app build completed successfully! ===
    echo Example app is available at: %EXAMPLE_APP_DIR%
    echo Run the example app with: npx react-native run-android
    goto :eof

REM Execute both SDK build and example app build
call :build_sdk
call :build_example

exit /b 0
