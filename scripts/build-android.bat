@echo off
setlocal enabledelayedexpansion

REM Color definitions for better output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Get the script directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."

REM Change to root directory
cd /d "%ROOT_DIR%" || (
    echo %RED%✗ Failed to change to root directory: %ROOT_DIR%%NC%
    exit /b 1
)

REM Load centralized configuration from config.env
set "CONFIG_FILE=%SCRIPT_DIR%config.env"
if exist "!CONFIG_FILE!" (
    REM Extract all relevant variables from config.env
    for /f "tokens=1,2 delims==" %%a in ('findstr /r "^ANDROID_\|^CMAKE_\|^NO_CLEAN\|^KEEP_BUILD\|^VERBOSE" "!CONFIG_FILE!"') do (
        set "%%a=%%~b"
    )
)

REM Default values from centralized config
set "ANDROID_HOME=!ANDROID_HOME!"
set "NDK_VERSION=!NDK_VERSION:-29.0.14206865=29.0.14206865!"
set "NDK_VERSION=!NDK_VERSION:-"=!"
set "ABIS=!ANDROID_ABIS:-arm64-v8a,x86_64=arm64-v8a,x86_64!"
set "ABIS=!ABIS:-"=!"
set "BUILD_TYPE=!ANDROID_BUILD_TYPE:-Release=Release!"
set "BUILD_TYPE=!BUILD_TYPE:-"=!"
set "ANDROID_PLATFORM=!ANDROID_PLATFORM:-android-21=android-21!"
set "ANDROID_PLATFORM=!ANDROID_PLATFORM:-"=!"
set "NUM_JOBS=!CMAKE_JOBS!"
set "NUM_JOBS=!NUM_JOBS:-"=!"

REM Local defaults if centralized config is not set
if "!NDK_VERSION!" equ "" set "NDK_VERSION=29.0.14206865"
if "!ABIS!" equ "" set "ABIS=arm64-v8a,x86_64"
if "!BUILD_TYPE!" equ "" set "BUILD_TYPE=Release"
if "!ANDROID_PLATFORM!" equ "" set "ANDROID_PLATFORM=android-21"
if "!NUM_JOBS!" equ "" set "NUM_JOBS="

REM Build behavior flags with defaults
if "!NO_CLEAN!" equ "" set "NO_CLEAN=false"
if "!KEEP_BUILD!" equ "" set "KEEP_BUILD=false"
if "!VERBOSE!" equ "" set "VERBOSE=false"

REM Update config.env with reasonable defaults if they're not set
if exist "!CONFIG_FILE!" (
    if "!ANDROID_BUILD_TYPE!" equ "" (
        echo Updating config.env with ANDROID_BUILD_TYPE=%BUILD_TYPE%
        findstr /v "^ANDROID_BUILD_TYPE=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo ANDROID_BUILD_TYPE="%BUILD_TYPE%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!ANDROID_ABIS!" equ "" (
        echo Updating config.env with ANDROID_ABIS=%ABIS%
        findstr /v "^ANDROID_ABIS=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo ANDROID_ABIS="%ABIS%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!ANDROID_PLATFORM!" equ "" (
        echo Updating config.env with ANDROID_PLATFORM=%ANDROID_PLATFORM%
        findstr /v "^ANDROID_PLATFORM=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo ANDROID_PLATFORM="%ANDROID_PLATFORM%" >> "!CONFIG_FILE!.tmp"
        move /y "!CONFIG_FILE!.tmp" "!CONFIG_FILE!" > nul
    )
    if "!CMAKE_BUILD_TYPE!" equ "" (
        echo Updating config.env with CMAKE_BUILD_TYPE=%BUILD_TYPE%
        findstr /v "^CMAKE_BUILD_TYPE=" "!CONFIG_FILE!" > "!CONFIG_FILE!.tmp"
        echo CMAKE_BUILD_TYPE="%BUILD_TYPE%" >> "!CONFIG_FILE!.tmp"
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
    echo Builds the llama_mobile Android library with cross-platform support.
    echo.
    echo Options:
    echo   -h, --help              Show this help message and exit
    echo   --abi=ABI1,ABI2         Specify which ABIs to build (default: !ABIS!)
    echo   --ndk-version=VERSION   Use specific NDK version (default: !NDK_VERSION!)
    echo   --build-type=TYPE       Build type: Release or Debug (default: !BUILD_TYPE!)
    echo   -j, --jobs=N            Number of build jobs (default: auto-detected)
    echo   --no-clean              Skip cleaning build directories before building
    echo   --keep-build            Keep intermediate build files after completion
    echo   --verbose               Show verbose output
    echo.
    echo ANDROID_HOME Configuration:
    echo   The script automatically detects ANDROID_HOME from common SDK paths:
    echo   - %USERPROFILE%\AppData\Local\Android\Sdk
    echo   - %USERPROFILE%\Android\Sdk
    echo   - C:\Android\Sdk
    echo.
    echo   If detection fails, set it manually:
    echo     set ANDROID_HOME=C:\path\to\sdk && %~nx0
    echo.
    echo   Or edit the config.env file in the scripts directory to set permanently:
    echo     scripts\config.env
    echo     ANDROID_HOME=C:\path\to\your\android\sdk
    echo.
    exit /b 0

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
    ) else if "!1:~0,12!" equ "--build-type=" (
        set "BUILD_TYPE=!1:~12!"
    ) else if "!1:~0,3!" equ "-j=" (
        set "NUM_JOBS=!1:~3!"
    ) else if "!1:~0,8!" equ "--jobs=" (
        set "NUM_JOBS=!1:~8!"
    ) else if "!1!" equ "--no-clean" (
        set "NO_CLEAN=true"
    ) else if "!1!" equ "--keep-build" (
        set "KEEP_BUILD=true"
    ) else if "!1!" equ "--verbose" (
        set "VERBOSE=true"
    ) else (
        echo %RED%Unknown parameter: %1%NC%
        goto show_help
    )
    shift
    goto parse_args
)

REM Enhanced logging functions
:log_message
    set "level=INFO"
    set "color=%BLUE%"
    set "message=%~1"
    
    rem Check if message starts with a log level
    if not "!message!" == "!message:[ERROR]=!" ( set "level=ERROR" && set "color=%RED%" ) else if not "!message!" == "!message:[WARN]=!" ( set "level=WARN" && set "color=%YELLOW%" ) else if not "!message!" == "!message:[SUCCESS]=!" ( set "level=SUCCESS" && set "color=%GREEN%" ) else if not "!message!" == "!message:[INFO]=!" ( set "level=INFO" && set "color=%BLUE%" )
    
    rem Extract message without level if present
    if not "!message:~0,5!" == "[!level!]" ( set "message=[!level!] !message!" )
    
    echo %color%[%time%] !message!%NC%
    goto :eof

:script_progress
    call :log_message "[INFO] %~1"
    goto :eof

:verbose_output
    if "%VERBOSE%" == "true" call :log_message "[INFO] %~1"
    goto :eof

:handle_error
    set "exit_code=%~1"
    set "message=%~2"
    call :log_message "[ERROR] %message%"
    call :log_message "[ERROR] Build failed with exit code: %exit_code%"
    exit /b %exit_code%
    goto :eof

REM Start script
call :log_message "[INFO] === Building llama_mobile Android library ==="
call :log_message "[INFO] Build type: %BUILD_TYPE%"
call :log_message "[INFO] Target ABIs: %ABIS%"
call :log_message "[INFO] NDK version: %NDK_VERSION%"

REM Check if lib directory exists
call :script_progress "Checking for lib directory..."
if not exist "lib" (
    call :handle_error 1 "lib directory not found at %ROOT_DIR%\lib! Please ensure you're in the correct directory and the lib folder exists."
)
call :log_message "[SUCCESS] lib directory found"

REM Set default ANDROID_HOME if not set
if "%ANDROID_HOME%" equ "" (
    call :script_progress "ANDROID_HOME not set, trying to detect from system..."
    
    REM Windows-specific paths - check common locations
    set "COMMON_PATHS=%USERPROFILE%\AppData\Local\Android\Sdk;%USERPROFILE%\Android\Sdk;C:\Android\Sdk"
    
    set "detected_path="
    for %%p in (!COMMON_PATHS!) do (
        call :verbose_output "Checking if %%p exists..."
        if exist "%%p" (
            set "detected_path=%%p"
            goto android_home_detected
        )
    )
    
    :android_home_detected
    if not "!detected_path!" equ "" (
        set "ANDROID_HOME=!detected_path!"
        call :log_message "[SUCCESS] Detected ANDROID_HOME: %ANDROID_HOME%"
    ) else (
        call :log_message "[ERROR] Failed to auto-detect ANDROID_HOME"
        echo.
        echo Please set the ANDROID_HOME environment variable manually:
        echo.
        echo On Windows Command Prompt:
        echo   set ANDROID_HOME=C:\path\to\your\android\sdk && scripts\%~nx0
        echo.
        echo On Git Bash:
        echo   export ANDROID_HOME=C:/path/to/your/android/sdk && ./scripts/%~nx0
        echo.
        echo Or set it permanently in your system environment variables.
        echo.
        exit /b 1
    )
) else (
    rem Verify ANDROID_HOME exists
    if not exist "%ANDROID_HOME%" (
        call :handle_error 1 "ANDROID_HOME path does not exist: %ANDROID_HOME%. Please set ANDROID_HOME to a valid Android SDK path."
    )
    call :log_message "[INFO] Using ANDROID_HOME from environment: %ANDROID_HOME%"
)

REM Check for NDK
set "NDK_PATH=%ANDROID_HOME%\ndk\%NDK_VERSION%"
call :script_progress "Checking for NDK %NDK_VERSION%..."
if not exist "!NDK_PATH!" (
    call :log_message "[ERROR] NDK %NDK_VERSION% not found at !NDK_PATH!"
    
    rem Show available NDK versions if any
    set "NDK_DIR=%ANDROID_HOME%\ndk"
    if exist "!NDK_DIR!" (
        call :log_message "[INFO] Available NDK versions:"
        dir "!NDK_DIR!" /b /a:d 2>nul
    ) else (
        call :log_message "[INFO] No NDK directory found at !NDK_DIR!"
    )
    
    call :log_message "[ERROR] Please install NDK %NDK_VERSION% via Android Studio SDK Manager or use --ndk-version option to specify a different version."
    exit /b 1
)
call :log_message "[SUCCESS] NDK %NDK_VERSION% found"

REM Set up build environment
set "CMAKE_TOOLCHAIN_FILE=%NDK_PATH%\build\cmake\android.toolchain.cmake"
if "!ANDROID_PLATFORM!" equ "" set "ANDROID_PLATFORM=android-21"
set "CMAKE_BUILD_TYPE=%BUILD_TYPE%"

REM Check if CMake is installed
call :script_progress "Checking for CMake..."
cmake --version >nul 2>&1
if errorlevel 1 (
    call :handle_error 1 "CMake not found! Please install CMake and add it to your PATH."
)
cmake --version | findstr /r "version" | call :log_message "[SUCCESS] Found CMake: %%~0"

REM Get number of CPU cores for parallel build
call :script_progress "Detecting CPU cores for parallel build..."
if "%NUM_JOBS%" equ "" (
    for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfLogicalProcessors /value') do set "n_cpu=%%i"
    if not defined n_cpu set "n_cpu=4"
    set "NUM_JOBS=%n_cpu%"
)
call :log_message "[SUCCESS] Using %NUM_JOBS% cores for build"

REM Create necessary directories for all SDKs
call :script_progress "Creating necessary directories..."

set "SDK_LIST=llama_mobile-android-SDK llama_mobile-android-java-SDK llama_mobile-react-native-SDK"
set "DIR_LIST=src\main\jniLibs src\main\cpp src\main\assets\grammars"

set "all_created=true"
for %%s in (%SDK_LIST%) do (
    for %%d in (!DIR_LIST!) do (
        set "full_dir=%%s\%%d"
        call :verbose_output "Creating directory: !full_dir!"
        mkdir "!full_dir!" 2>nul || (
            call :log_message "[ERROR] Failed to create directory !full_dir!"
            call :log_message "[ERROR] Please check your permissions and try again."
            set "all_created=false"
        )
    )
)

if "!all_created!" equ "true" (
    call :log_message "[SUCCESS] All directories created successfully"
) else (
    call :handle_error 1 "Failed to create some directories."
)

REM Copy grammar files to assets for all SDKs
call :script_progress "Copying grammar files to assets..."
set "GRAMMAR_SRC_DIR=lib\grammars"

if exist "!GRAMMAR_SRC_DIR!" (
    rem Check if there are any grammar files to copy
    dir "!GRAMMAR_SRC_DIR!\*.gbnf" >nul 2>&1
    if errorlevel 1 (
        call :log_message "[WARN] No grammar files (*.gbnf) found in !GRAMMAR_SRC_DIR!"
    ) else (
        set "all_copied=true"
        
        rem Copy to all SDKs
        for %%s in (%SDK_LIST%) do (
            set "dest_dir=%%s\src\main\assets\grammars"
            call :verbose_output "Copying grammar files to: !dest_dir!"
            xcopy /y "!GRAMMAR_SRC_DIR!\*.gbnf" "!dest_dir!\" 2>nul || (
                call :log_message "[ERROR] Failed to copy grammar files to !dest_dir!"
                set "all_copied=false"
            )
        )
        
        if "!all_copied!" equ "true" (
            call :log_message "[SUCCESS] Grammar files copied successfully"
        ) else (
            call :handle_error 1 "Failed to copy grammar files to some SDKs."
        )
    )
) else (
    call :log_message "[WARN] Grammar source directory not found at !GRAMMAR_SRC_DIR!"
    call :log_message "[WARN] Grammar files will not be included in the build."
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
    set "BUILD_COMMAND=cmake --build !BUILD_DIR! --config "!CMAKE_BUILD_TYPE!" -j !NUM_JOBS!"
    
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