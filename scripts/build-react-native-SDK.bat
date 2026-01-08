@echo off
setlocal enabledelayedexpansion

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "REACT_NATIVE_SDK_DIR=%ROOT_DIR%\llama_mobile-react-native-SDK"

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
    echo Updates the llama_mobile React Native SDK without compiling iOS/Android SDKs.
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

REM Function to copy iOS SDK into React Native SDK
:copy_ios_sdk_to_plugin
    echo === Copying iOS SDK into React Native SDK ===
    
    REM iOS SDK is not supported on Windows
    echo ⚠ iOS SDK cannot be copied on Windows
    echo ⚠ iOS framework will not be available in the React Native SDK
    echo ⚠ React Native SDK will only work for Android on Windows
    echo.
    goto :eof

REM Function to copy Android SDK into React Native SDK
:copy_android_sdk_to_plugin
    echo === Copying Android SDK into React Native SDK ===
    
    set "REACT_NATIVE_ANDROID_DIR=%REACT_NATIVE_SDK_DIR%\android"
    set "ANDROID_SDK_DIR=%ROOT_DIR%\llama_mobile-android-SDK"
    
    REM Check if Android SDK exists
    if not exist "%ANDROID_SDK_DIR%" (
        echo ✗ Error: Android SDK directory not found at %ANDROID_SDK_DIR%!
        echo Please build the Android SDK first using build-android.bat
        exit /b 1
    )
    
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

REM Function to update the React Native SDK
:update_sdk
    echo === Updating llama_mobile React Native SDK ===
    
    pushd "%REACT_NATIVE_SDK_DIR%"
    
    REM Check if iOS SDK exists (macOS only)
    if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
        echo ⚠ iOS SDK checking skipped on Windows
    )
    
    REM Check if Android SDK exists
    if not exist "%ANDROID_SDK_DIR%" (
        echo ✗ Error: Android SDK directory not found at %ANDROID_SDK_DIR%!
        echo Please build the Android SDK first using build-android.bat
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
    echo === React Native SDK update completed successfully! ===
    echo SDK is available at: %REACT_NATIVE_SDK_DIR%
    echo Note: iOS/Android SDKs were not compiled - this script only updates the React Native wrapper
    goto :eof

REM Execute the SDK update
call :update_sdk

exit /b 0