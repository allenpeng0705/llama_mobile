@echo off
setlocal enabledelayedexpansion

REM ============================================================================
REM CAPACITOR BUILD SCRIPT
REM This script uses variables from config.env and provides auto-detection
REM ============================================================================

REM Color definitions for better output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Get the script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."
set "CAPACITOR_PLUGIN_DIR=%ROOT_DIR%\llama_mobile-capacitor-plugin"
set "EXAMPLE_APP_DIR=%CAPACITOR_PLUGIN_DIR%\example-app"

REM Load centralized configuration from config.env
set "CONFIG_FILE=%SCRIPT_DIR%config.env"
if exist "!CONFIG_FILE!" (
    REM Extract all relevant variables from config.env
    for /f "tokens=1,2 delims==" %%a in ('findstr /r "^NODE_\|^NPM_\|^YARN_\|^FLUTTER_\|^CMAKE_\|^IOS_\|^ANDROID_\|^CAPACITOR_\|^NO_CLEAN\|^KEEP_BUILD\|^VERBOSE" "!CONFIG_FILE!"') do (
        set "%%a=%%~b"
    )
)

REM Local variables with defaults from centralized config
set "NODE_PATH=!NODE_PATH!"
set "NPM_PATH=!NPM_PATH!"
set "YARN_PATH=!YARN_PATH!"
set "CAPACITOR_BUILD_TYPE=!CAPACITOR_BUILD_TYPE:-release=release!"
set "CAPACITOR_BUILD_TYPE=!CAPACITOR_BUILD_TYPE:-"=!"
if "!CAPACITOR_BUILD_TYPE!" equ "" set "CAPACITOR_BUILD_TYPE=release"

REM Build behavior flags with defaults
if "!NO_CLEAN!" equ "" set "NO_CLEAN=false"
if "!KEEP_BUILD!" equ "" set "KEEP_BUILD=false"
if "!VERBOSE!" equ "" set "VERBOSE=false"

REM Update config.env with reasonable defaults if they're not set
if exist "!CONFIG_FILE!" (
    if "!CAPACITOR_BUILD_TYPE!" equ "" (
        echo Updating config.env with CAPACITOR_BUILD_TYPE=%CAPACITOR_BUILD_TYPE%
        findstr /v "^CAPACITOR_BUILD_TYPE=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo CAPACITOR_BUILD_TYPE="%CAPACITOR_BUILD_TYPE%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!NO_CLEAN!" equ "" (
        echo Updating config.env with NO_CLEAN=%NO_CLEAN%
        findstr /v "^NO_CLEAN=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo NO_CLEAN="%NO_CLEAN%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!KEEP_BUILD!" equ "" (
        echo Updating config.env with KEEP_BUILD=%KEEP_BUILD%
        findstr /v "^KEEP_BUILD=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo KEEP_BUILD="%KEEP_BUILD%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!VERBOSE!" equ "" (
        echo Updating config.env with VERBOSE=%VERBOSE%
        findstr /v "^VERBOSE=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo VERBOSE="%VERBOSE%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
)

REM Show help message
:show_help
    echo %BLUE%Usage: %~nx0 [OPTIONS]%NC%
    echo.
    echo Builds the self-contained llama_mobile Capacitor plugin.
    echo.
    echo Build variables can be configured in scripts/config.env:
    echo  - NODE_PATH: Path to Node.js executable
    echo  - NPM_PATH: Path to npm executable
    echo  - YARN_PATH: Path to Yarn executable
    echo  - CAPACITOR_BUILD_TYPE: release or debug
    echo.
    echo Options:
    echo  -h, --help             Show this help message and exit
    echo  --update-sdks          Update the internal SDK components from external sources
    echo  --force                Force update SDK components
    exit /b 0

REM Parse command line arguments
set "UPDATE_SDKS=false"
set "FORCE=false"

:parse_args
    if "%~1" equ "-h" goto show_help
    if "%~1" equ "--help" goto show_help
    if "%~1" equ "--update-sdks" set "UPDATE_SDKS=true" & shift & goto parse_args
    if "%~1" equ "--force" set "FORCE=true" & shift & goto parse_args
    if "%~1" neq "" (
        echo %RED%Unknown parameter: %~1%NC%
        goto show_help
    )

REM Check if node and npm are installed
if not "!NODE_PATH!" == "" (
    REM Add Node.js to PATH if NODE_PATH is set
    for %%i in (!NODE_PATH!) do set "NODE_DIR=%%~dpi"
    set "PATH=!NODE_DIR!;%PATH%"
)

if not "!NPM_PATH!" == "" (
    REM Add npm to PATH if NPM_PATH is set
    for %%i in (!NPM_PATH!) do set "NPM_DIR=%%~dpi"
    set "PATH=!NPM_DIR!;%PATH%"
)

if not "!YARN_PATH!" == "" (
    REM Add Yarn to PATH if YARN_PATH is set
    for %%i in (!YARN_PATH!) do set "YARN_DIR=%%~dpi"
    set "PATH=!YARN_DIR!;%PATH%"
)

where node >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%node could not be found.%NC%
    if "!NODE_PATH!" == "" (
        echo Please set NODE_PATH in scripts/config.env or install Node.js from https://nodejs.org/
    ) else (
        echo Please check that NODE_PATH (!NODE_PATH!) is set correctly
    )
    exit /b 1
)

where npm >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%npm could not be found.%NC%
    if "!NPM_PATH!" == "" (
        echo Please set NPM_PATH in scripts/config.env or install Node.js from https://nodejs.org/
    ) else (
        echo Please check that NPM_PATH (!NPM_PATH!) is set correctly
    )
    exit /b 1
)

echo Using Node.js: 
node --version

echo Using npm: 
npm --version

where yarn >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo Using Yarn: 
    yarn --version
)

REM Check if the Capacitor plugin directory exists
if not exist "!CAPACITOR_PLUGIN_DIR!" (
    echo %RED%✗ Error: Capacitor plugin directory not found at !CAPACITOR_PLUGIN_DIR!%NC%
    exit /b 1
)

REM Check if the example app directory exists
if not exist "!EXAMPLE_APP_DIR!" (
    echo %RED%✗ Error: Example app directory not found at !EXAMPLE_APP_DIR!%NC%
    exit /b 1
)

REM Function to update iOS SDK from external source (optional)
:update_ios_sdk
    echo === Updating iOS SDK from external source ===
    
    if exist "!ROOT_DIR!\llama_mobile-ios-SDK\build-ios-SDK.sh" (
        echo Building external iOS SDK...
        echo %YELLOW%Note: iOS SDK build on Windows is not supported.%NC%
        echo %YELLOW%Skipping iOS SDK update.%NC%
    ) else (
        echo %RED%✗ Error: iOS build script not found at !ROOT_DIR!\llama_mobile-ios-SDK\build-ios-SDK.sh%NC%
        echo Please ensure the iOS build script exists before updating SDK components
    )
    
    goto :eof

REM Function to update Android SDK components from external source (optional)
:update_android_sdk
    echo === Updating Android SDK components from external source ===
    
    set "ANDROID_JAVA_SDK_DIR=%ROOT_DIR%\llama_mobile-android-java-SDK"
    if not exist "!ANDROID_JAVA_SDK_DIR!" (
        echo %RED%✗ Error: Android Java SDK directory not found at !ANDROID_JAVA_SDK_DIR!%NC%
        exit /b 1
    )
    
    REM Copy Java classes
    echo Updating Android Java classes...
    set "CAPACITOR_JAVA_DIR=%CAPACITOR_PLUGIN_DIR%\android\src\main\java\com\llamamobile"
    set "ANDROID_JAVA_DIR=%ANDROID_JAVA_SDK_DIR%\src\main\java\com\llamamobile"
    
    mkdir "!CAPACITOR_JAVA_DIR!" >nul 2>&1
    xcopy "!ANDROID_JAVA_DIR!" "!CAPACITOR_JAVA_DIR!" /E /Y /Q
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Android Java classes copied successfully%NC%
    ) else (
        echo %RED%✗ Failed to copy Android Java classes to Capacitor plugin%NC%
        exit /b 1
    )
    
    REM Copy native libraries
    echo Updating Android native libraries...
    set "CAPACITOR_JNI_DIR=%CAPACITOR_PLUGIN_DIR%\android\src\main\jniLibs"
    set "ANDROID_JNI_DIR=%ANDROID_JAVA_SDK_DIR%\src\main\jniLibs"
    
    mkdir "!CAPACITOR_JNI_DIR!" >nul 2>&1
    xcopy "!ANDROID_JNI_DIR!" "!CAPACITOR_JNI_DIR!" /E /Y /Q
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Android native libraries copied successfully%NC%
    ) else (
        echo %RED%✗ Failed to copy Android native libraries to Capacitor plugin%NC%
        exit /b 1
    )
    
    REM Copy grammar files
    echo Updating grammar files...
    set "CAPACITOR_ASSETS_DIR=%CAPACITOR_PLUGIN_DIR%\android\src\main\assets"
    set "ANDROID_ASSETS_DIR=%ANDROID_JAVA_SDK_DIR%\src\main\assets"
    
    mkdir "!CAPACITOR_ASSETS_DIR!\grammars" >nul 2>&1
    xcopy "!ANDROID_ASSETS_DIR!\grammars" "!CAPACITOR_ASSETS_DIR!\grammars" /E /Y /Q
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Grammar files copied successfully%NC%
    ) else (
        echo %RED%✗ Failed to copy grammar files to Capacitor plugin%NC%
        exit /b 1
    )
    
    goto :eof

REM Function to build the Capacitor plugin
:build_plugin
    echo === Building self-contained llama_mobile Capacitor plugin ===
    
    REM Update SDK components from external sources if requested
    if "!UPDATE_SDKS!" equ "true" (
        call :update_ios_sdk
        call :update_android_sdk
    ) else (
        echo %GREEN%✓ Using internal SDK components (--update-sdks not specified)%NC%
    )
    
    REM Build the Capacitor plugin
    pushd "!CAPACITOR_PLUGIN_DIR!"
    
    REM Get dependencies
    echo Getting Capacitor plugin dependencies...
    call npm install
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Capacitor plugin dependencies resolved successfully%NC%
    ) else (
        echo %RED%✗ Capacitor plugin dependencies resolution failed!%NC%
        popd
        exit /b 1
    )
    
    REM Verify the plugin can be built by running build command
    echo Building Capacitor plugin...
    call npm run build
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Capacitor plugin built successfully%NC%
    ) else (
        echo %RED%✗ Capacitor plugin build failed!%NC%
        popd
        exit /b 1
    )
    
    REM Verify Android build
    echo Verifying Android build...
    pushd android
    call gradlew clean build -x test
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Android build verified successfully%NC%
    ) else (
        echo %RED%✗ Android build verification failed!%NC%
        popd
        popd
        exit /b 1
    )
    popd
    popd
    
    echo %GREEN%=== Self-contained Capacitor plugin build completed successfully! ===%NC%
    echo Plugin is available at: !CAPACITOR_PLUGIN_DIR!
    echo The plugin is now self-contained with no external SDK dependencies.
    
    goto :eof

REM Function to build the example app
:build_example
    echo === Building llama_mobile Capacitor example app ===
    
    pushd "!EXAMPLE_APP_DIR!"
    
    REM Get dependencies
    echo Getting example app dependencies...
    call npm install
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Example app dependencies resolved successfully%NC%
    ) else (
        echo %RED%✗ Example app dependencies resolution failed!%NC%
        popd
        exit /b 1
    )
    
    REM Build the example app for web (quick verification)
    echo Building example app for web...
    call npm run build
    if %ERRORLEVEL% equ 0 (
        echo %GREEN%✓ Web example app built successfully%NC%
    ) else (
        echo %RED%✗ Web example app build failed!%NC%
        popd
        exit /b 1
    )
    
    popd
    
    echo %GREEN%=== Capacitor example app build completed successfully! ===%NC%
    echo Example app is available at: !EXAMPLE_APP_DIR!
    echo Run the example app with: npx cap run [ios^|android]
    
    goto :eof

REM Execute both plugin build and example app build
call :build_plugin
call :build_example

echo.
echo %GREEN%All Capacitor build tasks completed successfully!%NC%
