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
    echo Builds the llama_mobile Android library with cross-platform support.
    echo.
    echo Options:
    echo   -h, --help              Show this help message and exit
    echo   --abi=ABI1,ABI2         Specify which ABIs to build (default: arm64-v8a,x86_64)
    echo   --ndk-version=VERSION   Use specific NDK version (default: 29.0.14206865)
    echo.
    echo ANDROID_HOME Configuration:
    echo   The script automatically detects ANDROID_HOME from common SDK paths.
    echo   If detection fails, set it manually:
    echo     set ANDROID_HOME=C:\path\to\sdk && %~nx0
    echo.
    exit /b 0

REM Default values
set "NDK_VERSION=29.0.14206865"
set "ABIS=arm64-v8a,x86_64"

REM Parse command line arguments
:parse_args
if "%1" equ "-h" goto show_help
if "%1" equ "--help" goto show_help
if "%1" equ "help" goto show_help
if "%1" neq "" (
    if "!1:~0,6!" equ "--abi=" (
        set "ABIS=!1:~6!"
    ) else if "!1:~0,13!" equ "--ndk-version=" (
        set "NDK_VERSION=!1:~13!"
    ) else (
        echo Unknown parameter: %1
        goto show_help
    )
    shift
    goto parse_args
)

REM Simple logging function
:log_message
    echo [%time%] %1
    goto :eof

:script_progress
    call :log_message "[PROGRESS] %1"
    goto :eof

REM Start script
call :script_progress "=== Building llama_mobile Android library ==="

REM Check if lib directory exists
call :script_progress "Checking for lib directory..."
if not exist "lib" (
    echo ✗ Error: lib directory not found at %ROOT_DIR%\lib!
    echo Please ensure you're in the correct directory and the lib folder exists.
    exit /b 1
)
call :script_progress "✓ lib directory found"

REM Set default ANDROID_HOME if not set
if "%ANDROID_HOME%" equ "" (
    echo ANDROID_HOME not set, trying to detect from system...
    
    REM Windows-specific paths
    set "COMMON_PATHS=%USERPROFILE%\AppData\Local\Android\Sdk;%USERPROFILE%\Android\Sdk"
    
    for %%p in (!COMMON_PATHS!) do (
        if exist "%%p" (
            set "ANDROID_HOME=%%p"
            echo ✅ Detected ANDROID_HOME: !ANDROID_HOME!
            goto android_home_found
        )
    )
    
    echo ❌ Failed to detect ANDROID_HOME automatically.
    echo Please set it manually:
    echo   set ANDROID_HOME=C:\path\to\sdk && %~nx0
    exit /b 1
    
    :android_home_found
)

REM Check for NDK
set "NDK_PATH=%ANDROID_HOME%\ndk\%NDK_VERSION%"
if not exist "!NDK_PATH!" (
    echo ❌ NDK version %NDK_VERSION% not found at !NDK_PATH!
    echo Please install it via Android Studio SDK Manager or set a different version.
    exit /b 1
)

REM Set up build environment
set "CMAKE_TOOLCHAIN_FILE=%NDK_PATH%\build\cmake\android.toolchain.cmake"
set "ANDROID_PLATFORM=android-21"
set "CMAKE_BUILD_TYPE=Release"

REM Get number of CPU cores for parallel build
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value') do set "n_cpu=%%i"
if not defined n_cpu set "n_cpu=4"

REM Create necessary directories for all SDKs
call :script_progress "Creating necessary directories..."

set "DIRS=^"llama_mobile-android-SDK\src\main\jniLibs^" ^
^"llama_mobile-android-SDK\src\main\cpp^" ^
^"llama_mobile-android-SDK\src\main\java\com\llamamobile^" ^
^"llama_mobile-android-SDK\src\main\assets\grammars^" ^
^"llama_mobile-android-java-SDK\src\main\jniLibs^" ^
^"llama_mobile-android-java-SDK\src\main\cpp^" ^
^"llama_mobile-android-java-SDK\src\main\java\com\llamamobile^" ^
^"llama_mobile-android-java-SDK\src\main\assets\grammars^" ^
^"llama_mobile-react-native-SDK\android\src\main\jniLibs^" ^
^"llama_mobile-react-native-SDK\android\src\main\cpp^" ^
^"llama_mobile-react-native-SDK\android\src\main\java\com\llamamobile^" ^
^"llama_mobile-react-native-SDK\android\src\main\assets\grammars^""

for %%d in (!DIRS!) do (
    mkdir "%%~d" 2>nul || (
        echo ✗ Error: Failed to create directory %%~d!
        echo Please check your permissions and try again.
        exit /b 1
    )
)
call :script_progress "✓ All directories created successfully"

REM Copy grammar files to assets for all SDKs
call :script_progress "Copying grammar files to assets..."
set "GRAMMAR_SRC_DIR=lib\grammars"
set "GRAMMAR_DEST_DIRS=^"llama_mobile-android-SDK\src\main\assets\grammars^" ^
^"llama_mobile-android-java-SDK\src\main\assets\grammars^" ^
^"llama_mobile-react-native-SDK\android\src\main\assets\grammars^""

if exist "!GRAMMAR_SRC_DIR!" (
    set "all_copied=true"
    for %%d in (!GRAMMAR_DEST_DIRS!) do (
        xcopy /y "!GRAMMAR_SRC_DIR!\*.gbnf" "%%~d\" 2>nul || (
            echo ✗ Error: Failed to copy grammar files to %%~d!
            set "all_copied=false"
            goto grammar_copy_done
        )
    )
    :grammar_copy_done
    if "!all_copied!" equ "true" (
        call :script_progress "✓ Grammar files copied successfully"
    ) else (
        exit /b 1
    )
) else (
    echo ✗ Warning: Grammar source directory not found at !GRAMMAR_SRC_DIR!
    echo Grammar files will not be included.
)

REM Build for each specified ABI
call :script_progress "Building for ABIs: !ABIS!"

REM Convert ABI list to array
set "abi_list=!ABIS!"
set "abi_index=0"
:parse_abi_list
for /f "tokens=1* delims=," %%a in ("!abi_list!") do (
    set "ABIS_ARRAY[!abi_index!]=%%a"
    set /a "abi_index+=1"
    set "abi_list=%%b"
)
if not "!abi_list!" equ "" goto parse_abi_list
set "abi_count=!abi_index!"

REM Build for each ABI
for /l %%i in (0,1,!abi_count!-1) do (
    set "ABI=!ABIS_ARRAY[%%i]!"
    call :script_progress "\n=== Building for !ABI! ==="
    set "BUILD_DIR=build-android-!ABI!"
    
    REM Remove old build directory
    call :script_progress "Cleaning old build directory..."
    if exist "!BUILD_DIR!" (
        rmdir /s /q "!BUILD_DIR!" 2>nul || (
            echo ✗ Error: Failed to remove old build directory !BUILD_DIR!
            echo Please check your permissions and try again.
            exit /b 1
        )
    )
    
    REM Create build directory
    call :script_progress "Creating build directory..."
    mkdir "!BUILD_DIR!" 2>nul || (
        echo ✗ Error: Failed to create build directory !BUILD_DIR!
        exit /b 1
    )
    call :script_progress "✓"
    
    REM Add platform-specific flags
    set "PLATFORM_FLAGS="
    if "!ABI!" equ "arm64-v8a" set "PLATFORM_FLAGS=-DGGML_NO_POSIX_MADVISE=ON"
    
    REM Configure CMake
    call :script_progress "Configuring CMake for !ABI!..."
    set "CMAKE_COMMAND=cmake -S lib -B !BUILD_DIR! ^
        -DCMAKE_TOOLCHAIN_FILE="!CMAKE_TOOLCHAIN_FILE!" ^
        -DANDROID_ABI="!ABI!" ^
        -DANDROID_PLATFORM="!ANDROID_PLATFORM!" ^
        -DCMAKE_BUILD_TYPE="!CMAKE_BUILD_TYPE!" ^
        -DANDROID_STL=c++_shared ^
        -DBUILD_SHARED_LIBS=ON ^
        !PLATFORM_FLAGS!"
    
    cmd /c "!CMAKE_COMMAND!" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ✗ Error: CMake configuration failed for !ABI!
        echo Please check the error messages above and try again.
        exit /b 1
    )
    call :script_progress "✓"
    
    REM Build the library
    call :script_progress "Building library for !ABI!..."
    set "BUILD_COMMAND=cmake --build !BUILD_DIR! --config "!CMAKE_BUILD_TYPE!" -j !n_cpu!"
    
    cmd /c "!BUILD_COMMAND!" >nul 2>&1
    if %ERRORLEVEL% neq 0 (
        echo ✗ Error: Build failed for !ABI!
        echo Please check the error messages above and try again.
        exit /b 1
    )
    call :script_progress "✓"
    
    REM Copy the library to all SDKs
    call :script_progress "Copying !ABI! library..."
    set "SOURCE_LIB=!BUILD_DIR!\output\lib\libllama_mobile_core.so"
    set "DEST_DIRS=^"llama_mobile-android-SDK\src\main\jniLibs\!ABI!^" ^
^"llama_mobile-android-java-SDK\src\main\jniLibs\!ABI!^" ^
^"llama_mobile-react-native-SDK\android\src\main\jniLibs\!ABI!^""
    
    if not exist "!SOURCE_LIB!" (
        echo ✗ Error: Built library not found at !SOURCE_LIB!
        echo Build may have succeeded but library file is missing.
        exit /b 1
    )
    
    set "all_copied=true"
    for %%d in (!DEST_DIRS!) do (
        mkdir "%%~d" 2>nul || (
            echo ✗ Error: Failed to create destination directory %%~d!
            set "all_copied=false"
            goto lib_copy_done
        )
        
        set "dest_lib=%%~d\libllama_mobile.so"
        copy /y "!SOURCE_LIB!" "!dest_lib!" >nul 2>&1 || (
            echo ✗ Error: Failed to copy library from !SOURCE_LIB! to !dest_lib!
            set "all_copied=false"
            goto lib_copy_done
        )
    )
    
    :lib_copy_done
    if "!all_copied!" equ "true" (
        call :script_progress "✓"
    ) else (
        exit /b 1
    )
    
    REM Clean up build directory
    call :script_progress "Cleaning up build directory..."
    rmdir /s /q "!BUILD_DIR!" 2>nul || (
        echo ✗ Warning: Failed to clean up build directory !BUILD_DIR!
        echo You may need to delete it manually.
    )
    call :script_progress "✓"
)

call :script_progress "=== Build completed successfully! ==="
call :script_progress "Android library built and copied to all SDKs, including React Native SDK."

exit /b 0