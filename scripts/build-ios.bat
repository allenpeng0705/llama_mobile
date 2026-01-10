@echo off
setlocal enabledelayedexpansion

REM Get the script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."

REM Change to root directory
cd /d "%ROOT_DIR%" || (echo ✗ Failed to change to root directory & exit /b 1)

REM Show help message
:show_help
    echo Usage: %~nx0 [OPTIONS]
    echo.
    echo Builds the llama_mobile iOS framework and copies it to the SDKs.
    echo.
    echo Options:
    echo   -h, --help         Show this help message and exit
    echo.
    echo Note: iOS framework building requires macOS and Xcode.
    echo This script on Windows can only copy pre-built frameworks to SDKs.
    echo.
    exit /b 0

REM Parse command line arguments
if "%1" equ "-h" goto show_help
if "%1" equ "--help" goto show_help
if "%1" equ "help" goto show_help
if not "%1" equ "" (
    echo Unknown parameter: %1
    goto show_help
)

REM Check for macOS - iOS build requires macOS
ver | findstr /i "Windows" >nul
if %ERRORLEVEL% equ 0 (
    echo ✗ iOS framework building is not supported on Windows.
    echo iOS development requires macOS and Xcode tools.
    echo.
    echo However, this script can copy a pre-built iOS framework to the SDKs if it exists.
    echo.
)

REM Check if CMake is available (for information only)
where cmake >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Note: cmake could not be found. This is expected on Windows for iOS builds.
)

REM Function to copy framework to SDKs
:copy_to_sdk
    echo === Updating llama_mobile iOS SDKs with latest framework ===
    echo.

    REM Check if necessary directories exist
    if not exist "%ROOT_DIR%\llama_mobile-ios-SDK" (
        echo ✗ Error: llama_mobile-ios-SDK directory not found!
        exit /b 1
    )

    if not exist "%ROOT_DIR%\llama_mobile-ios-SDK\llama_mobile.xcframework" (
        echo ✗ Error: llama_mobile.xcframework not found in llama_mobile-ios-SDK directory!
        echo Please build the iOS framework first on macOS using: build-ios.sh
        exit /b 1
    )

    REM Define SDK destinations
    set "SDK_DESTINATIONS[0]=%ROOT_DIR%\llama_mobile-ios-SDK\Frameworks"
    set "SDK_DESTINATIONS[1]=%ROOT_DIR%\llama_mobile-react-native-SDK\ios\Frameworks"
    set "SDK_COUNT=2"

    for /l %%i in (0,1,%SDK_COUNT%-1) do (
        set "DEST_DIR=!SDK_DESTINATIONS[%%i]!"
        for %%d in (!DEST_DIR!) do set "PARENT_DIR=%%~pnd"
        for %%d in (!PARENT_DIR!) do set "SDK_NAME=%%~nxd"

        echo Creating Frameworks directory in !SDK_NAME!...
        mkdir "!DEST_DIR!" 2>nul || (
            echo ✗ Failed to create directory: !DEST_DIR!
            exit /b 1
        )
        echo ✓

        REM Remove old framework if it exists
        if exist "!DEST_DIR!\llama_mobile.xcframework" (
            echo Removing old framework from !SDK_NAME!...
            rmdir /s /q "!DEST_DIR!\llama_mobile.xcframework" 2>nul || (
                echo ✗ Failed to remove old framework
                exit /b 1
            )
            echo ✓
        )

        REM Copy latest framework to SDK
        echo Copying latest framework to !SDK_NAME!...
        xcopy /e /i /y "%ROOT_DIR%\llama_mobile-ios-SDK\llama_mobile.xcframework" "!DEST_DIR!\llama_mobile.xcframework" >nul 2>&1 || (
            echo ✗ Failed to copy framework to !DEST_DIR!
            exit /b 1
        )
        echo ✓
    )

    echo.
    echo ✓ Framework update completed successfully!
    echo The latest llama_mobile.xcframework has been copied to all iOS SDKs.
    echo.
    goto :eof

REM Main script execution
call :copy_to_sdk

endlocal
exit /b 0