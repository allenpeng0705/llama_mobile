@echo off

REM ============================================================================
REM ANDROID NATIVE LIBRARY BUILD SCRIPT (WINDOWS)
REM Builds low-level Android libraries (no Kotlin/Java bindings)
REM Output: llama_mobile/llama_mobile-android/libs/
REM ============================================================================

setlocal enabledelayedexpansion

REM Load centralized configuration from config.env
set CONFIG_FILE=%~dp0config.env
if exist "%CONFIG_FILE%" (
    for /f "tokens=1* delims==" %%a in ('type "%CONFIG_FILE%" ^| findstr /v "^#" ^| findstr "ANDROID_HOME\|NDK_PATH\|ANDROID_PLATFORM\|ANDROID_BUILD_TYPE\|ANDROID_ABIS\|CMAKE_PATH\|CMAKE_BUILD_TYPE\|CMAKE_JOBS\|VERBOSE"') do (
        set "%%a=%%b"
    )
)

REM Variables with defaults
set "ANDROID_HOME=%ANDROID_HOME%"
set "NDK_PATH=%NDK_PATH%"
set "ANDROID_PLATFORM=%ANDROID_PLATFORM:~0,9%%%" & if "%ANDROID_PLATFORM%" equ "%ANDROID_PLATFORM:~0,9%%%" set "ANDROID_PLATFORM=android-21"
set "BUILD_TYPE=%ANDROID_BUILD_TYPE%" & if "%BUILD_TYPE%" equ "" set "BUILD_TYPE=Release"
set "ABIS=%ANDROID_ABIS%" & if "%ABIS%" equ "" set "ABIS=arm64-v8a,x86_64"
set "NUM_JOBS=%CMAKE_JOBS%" & if "%NUM_JOBS%" equ "" set "NUM_JOBS=4"
set "VERBOSE=%VERBOSE%" & if "%VERBOSE%" equ "" set "VERBOSE=false"

REM Debug log to verify NDK_PATH
echo [DEBUG] NDK_PATH from config.env: %NDK_PATH%

REM Function to update config.env with detected values
:update_config_env
set "VAR_NAME=%~1"
set "VAR_VALUE=%~2"
if exist "%CONFIG_FILE%" (
    findstr /B /I "%VAR_NAME%=" "%CONFIG_FILE%" >nul
    if %errorlevel% equ 0 (
        REM Update existing variable
        for /f "tokens=*" %%l in ('type "%CONFIG_FILE%" ^| findstr /v /B /I "%VAR_NAME%="') do (
            echo %%l>>"%CONFIG_FILE%.tmp"
        )
        echo %VAR_NAME%="%VAR_VALUE%">>"%CONFIG_FILE%.tmp"
        move /y "%CONFIG_FILE%.tmp" "%CONFIG_FILE%" >nul
    ) else (
        REM Add new variable
        echo %VAR_NAME%="%VAR_VALUE%">>"%CONFIG_FILE%"
    )
)
 goto :eof

REM Update config.env with reasonable defaults if they're not set
if "%ANDROID_BUILD_TYPE%" equ "" call :update_config_env "ANDROID_BUILD_TYPE" "%BUILD_TYPE%"
if "%ANDROID_ABIS%" equ "" call :update_config_env "ANDROID_ABIS" "%ABIS%"
if "%ANDROID_PLATFORM%" equ "" call :update_config_env "ANDROID_PLATFORM" "%ANDROID_PLATFORM%"
if "%VERBOSE%" equ "" call :update_config_env "VERBOSE" "%VERBOSE%"

REM ============================================================================
REM SCRIPT SETUP
REM ============================================================================

REM Logging functions
:log_message
set "LEVEL=%~1"
set "MESSAGE=%~2"
set "TIMESTAMP=%time:~0,8%"
echo [%TIMESTAMP%] [%LEVEL%] %MESSAGE%
goto :eof

:script_progress
call :log_message "INFO" %~1
goto :eof

:verbose_output
if "%VERBOSE%" equ "true" call :log_message "INFO" %~1
goto :eof

:handle_error
set "EXIT_CODE=%~1"
set "MESSAGE=%~2"
call :log_message "ERROR" %MESSAGE%
call :log_message "ERROR" Build failed with exit code: %EXIT_CODE%
exit /b %EXIT_CODE%
goto :eof

REM Show help message
:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Builds low-level llama_mobile Android libraries (no Kotlin/Java bindings).
echo.
echo Options:
echo   -h, --help              Show this help message and exit
echo   --abi=ABI1,ABI2         Specify which ABIs to build (default: %ABIS%)
echo   --ndk-path=PATH         Path to Android NDK
echo   --build-type=TYPE       Build type: Release or Debug (default: %BUILD_TYPE%)
echo   --platform=PLATFORM     Android platform (default: %ANDROID_PLATFORM%)
echo   --verbose               Show verbose output
echo.
echo ANDROID_HOME Configuration:
echo   The script automatically detects ANDROID_HOME from common SDK paths.
echo.
exit /b 0
goto :eof

REM Parse command line arguments
for %%a in (%*) do (
    if "%%~a" equ "-h" goto show_help
    if "%%~a" equ "--help" goto show_help
    if "%%~a" equ "--verbose" set "VERBOSE=true"
    if "%%~a" equ "--build-type=Release" set "BUILD_TYPE=Release"
    if "%%~a" equ "--build-type=Debug" set "BUILD_TYPE=Debug"
    if "%%~a" equ "--platform=android-21" set "ANDROID_PLATFORM=android-21"
    if "%%~a" equ "--platform=android-24" set "ANDROID_PLATFORM=android-24"
    if "%%~a" equ "--platform=android-28" set "ANDROID_PLATFORM=android-28"
    if "%%~a" equ "--platform=android-30" set "ANDROID_PLATFORM=android-30"
    if "%%~a" equ "--platform=android-31" set "ANDROID_PLATFORM=android-31"
    if "%%~a" equ "--platform=android-32" set "ANDROID_PLATFORM=android-32"
    if "%%~a" equ "--platform=android-33" set "ANDROID_PLATFORM=android-33"
    if "%%~a" equ "--platform=android-34" set "ANDROID_PLATFORM=android-34"
    if "%%~a" equ "--platform=android-35" set "ANDROID_PLATFORM=android-35"
    if "%%~a" equ "--abi=arm64-v8a" set "ABIS=arm64-v8a"
    if "%%~a" equ "--abi=x86_64" set "ABIS=x86_64"
    if "%%~a" equ "--abi=arm64-v8a,x86_64" set "ABIS=arm64-v8a,x86_64"
    if "%%~a" equ "--abi=x86_64,arm64-v8a" set "ABIS=x86_64,arm64-v8a"
    if "%%~a" equ "--abi=armeabi-v7a" set "ABIS=armeabi-v7a"
    if "%%~a" equ "--abi=arm64-v8a,armeabi-v7a" set "ABIS=arm64-v8a,armeabi-v7a"
    if "%%~a" equ "--abi=arm64-v8a,x86" set "ABIS=arm64-v8a,x86"
    if "%%~a" equ "--abi=arm64-v8a,x86_64,x86" set "ABIS=arm64-v8a,x86_64,x86"
    if "%%~a" equ "--abi=arm64-v8a,x86_64,x86,armeabi-v7a" set "ABIS=arm64-v8a,x86_64,x86,armeabi-v7a"
    for /f "tokens=2 delims==" %%b in ("%%~a") do (
        if "%%~a" equ "--ndk-path=%%~b" set "NDK_PATH=%%~b"
    )
)

REM ============================================================================
REM MAIN BUILD PROCESS
REM ============================================================================

REM Set directories
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\"
set "OUTPUT_DIR=%ROOT_DIR%llama_mobile-android"
set "LIBS_DIR=%OUTPUT_DIR%\libs"
set "INCLUDE_DIR=%OUTPUT_DIR%\include"
set "GRAMMARS_DIR=%OUTPUT_DIR%\grammars"

call :log_message "INFO" "=== Building llama_mobile Android Native Libraries ==="
call :log_message "INFO" "Build type: %BUILD_TYPE%"
call :log_message "INFO" "Target ABIs: %ABIS%"
call :log_message "INFO" "Output: %LIBS_DIR%"

REM Check if lib directory exists
call :script_progress "Checking for lib directory..."
if not exist "%ROOT_DIR%lib" (
    call :handle_error 1 "lib directory not found! Please ensure you're in the correct directory."
)
call :log_message "SUCCESS" "lib directory found"

REM Detect ANDROID_HOME if not set
if "%ANDROID_HOME%" equ "" (
    call :script_progress "ANDROID_HOME not set, trying to detect..."
    
    REM Windows paths
    set "COMMON_PATHS=%USERPROFILE%\AppData\Local\Android\Sdk;%USERPROFILE%\Android\Sdk;%USERPROFILE%\android-sdk"
    
    set "detected=false"
    for %%p in (%COMMON_PATHS%) do (
        if exist "%%p" (
            set "ANDROID_HOME=%%p"
            set "detected=true"
            goto :detect_home_done
        )
    )
    
    :detect_home_done
    if "!detected!" equ "false" (
        call :handle_error 1 "ANDROID_HOME not found! Please set it manually."
    )
    
    call :log_message "SUCCESS" "Detected ANDROID_HOME: %ANDROID_HOME%"
    call :update_config_env "ANDROID_HOME" "%ANDROID_HOME%"
)

REM Detect NDK_PATH if not set
if "%NDK_PATH%" equ "" (
    call :script_progress "NDK_PATH not set, trying to detect..."
    
    if exist "%ANDROID_HOME%\ndk" (
        REM Get the latest NDK version
        set "latest_ndk="
        for /f "delims=" %%d in ('dir /b /ad "%ANDROID_HOME%\ndk" ^| sort /r') do (
            set "latest_ndk=%%d"
            goto :find_latest_ndk
        )
        
        :find_latest_ndk
        if not "!latest_ndk!" equ "" (
            set "NDK_PATH=%ANDROID_HOME%\ndk\!latest_ndk!"
        ) else (
            call :handle_error 1 "NDK versions found but could not determine path!"
        )
    ) else (
        call :handle_error 1 "NDK not found! Please install it via Android Studio SDK Manager."
    )
    
    call :log_message "SUCCESS" "Detected NDK_PATH: %NDK_PATH%"
    call :update_config_env "NDK_PATH" "%NDK_PATH%"
)

REM Set CMake variables
set "CMAKE_TOOLCHAIN_FILE=%NDK_PATH%\build\cmake\android.toolchain.cmake"
set "CMAKE_BUILD_TYPE=%BUILD_TYPE%"

REM Create output directories
call :script_progress "Creating output directories..."
mkdir "%LIBS_DIR%" 2>nul
mkdir "%INCLUDE_DIR%" 2>nul
mkdir "%GRAMMARS_DIR%" 2>nul
call :log_message "SUCCESS" "Output directories created"

REM Copy header files to include directory
call :script_progress "Copying header files..."
copy "%ROOT_DIR%lib\llama_mobile_ffi.h" "%INCLUDE_DIR%" >nul
copy "%ROOT_DIR%lib\llama_mobile_api.h" "%INCLUDE_DIR%" >nul
mkdir "%INCLUDE_DIR%\llama_cpp" 2>nul
xcopy /s /i /y "%ROOT_DIR%lib\llama_cpp\*.h" "%INCLUDE_DIR%\llama_cpp" >nul 2>nul
call :log_message "SUCCESS" "Header files copied"

REM Copy grammar files to assets directory
call :script_progress "Copying grammar files..."
if exist "%ROOT_DIR%lib\grammars" (
    copy "%ROOT_DIR%lib\grammars\*.gbnf" "%GRAMMARS_DIR%" >nul 2>nul || true
    call :log_message "SUCCESS" "Grammar files copied"
) else (
    call :log_message "WARN" "No grammar files found"
)

REM Build for each ABI
call :script_progress "Building for each ABI..."
for %%a in (%ABIS%) do (
    set "ABI=%%a"
    call :log_message "INFO" "=== Building for !ABI! ==="
    
    REM Create build directory
    set "BUILD_DIR=%ROOT_DIR%build-android-native-!ABI!"
    rd /s /q "!BUILD_DIR!" 2>nul
    mkdir "!BUILD_DIR!" 2>nul
    
    REM Add platform-specific flags
    set "PLATFORM_FLAGS="
    if "!ABI!" equ "arm64-v8a" (
        set "PLATFORM_FLAGS=-DGGML_NO_POSIX_MADVISE=ON"
    )
    
    REM Configure CMake
    call :script_progress "Configuring CMake for !ABI!..."
    set "CMAKE_COMMAND=cmake -S "%ROOT_DIR%lib" -B "!BUILD_DIR!" ^
        -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" ^
        -DANDROID_ABI="!ABI!" ^
        -DANDROID_PLATFORM="%ANDROID_PLATFORM%" ^
        -DCMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%" ^
        -DANDROID_STL=c++_shared ^
        -DBUILD_SHARED_LIBS=ON ^
        !PLATFORM_FLAGS!"
    
    call :verbose_output "CMake command: !CMAKE_COMMAND!"
    
    if not "%VERBOSE%" equ "true" (
        !CMAKE_COMMAND! 2>&1 | findstr /i "error\|warning\|CMake Error\|CMake Warning"
    ) else (
        !CMAKE_COMMAND!
    )
    
    if errorlevel 1 (
        call :handle_error 1 "CMake configuration failed for !ABI!"
    )
    
    REM Build
    call :script_progress "Building library for !ABI!..."
    set "DETECTED_NUM_JOBS=%NUM_JOBS%"
    if "%DETECTED_NUM_JOBS%" equ "" (
        for /f %%j in ('wmic cpu get NumberOfLogicalProcessors ^| findstr /b /v NumberOf') do (
            set "DETECTED_NUM_JOBS=%%j"
        )
        if "!DETECTED_NUM_JOBS!" equ "" set "DETECTED_NUM_JOBS=4"
    )
    
    set "BUILD_COMMAND=cmake --build "!BUILD_DIR!" --config "%CMAKE_BUILD_TYPE%" -j !DETECTED_NUM_JOBS!"
    
    call :verbose_output "Build command: !BUILD_COMMAND!"
    
    if not "%VERBOSE%" equ "true" (
        !BUILD_COMMAND! 2>&1 | findstr /i "error\|warning\|FAILED\|FAILED_LINK\|Build failed"
    ) else (
        !BUILD_COMMAND!
    )
    
    if errorlevel 1 (
        call :handle_error 1 "Build failed for !ABI!"
    )
    
    REM Copy the built library
    set "DEST_DIR=%LIBS_DIR%\!ABI!"
    set "DEST_LIB=%DEST_DIR%\libllama_mobile.so"
    
    REM Find the actual built library
    set "SOURCE_LIB="
    if exist "!BUILD_DIR!\libllama_mobile_core.so" (
        set "SOURCE_LIB=!BUILD_DIR!\libllama_mobile_core.so"
    ) else if exist "!BUILD_DIR!\lib\libllama_mobile_core.so" (
        set "SOURCE_LIB=!BUILD_DIR!\lib\libllama_mobile_core.so"
    ) else if exist "!BUILD_DIR!\Release\libllama_mobile_core.so" (
        set "SOURCE_LIB=!BUILD_DIR!\Release\libllama_mobile_core.so"
    ) else if exist "!BUILD_DIR!\Debug\libllama_mobile_core.so" (
        set "SOURCE_LIB=!BUILD_DIR!\Debug\libllama_mobile_core.so"
    ) else (
        for /r "!BUILD_DIR!" %%f in (libllama_mobile_core.so) do (
            set "SOURCE_LIB=%%f"
            goto :find_lib_done
        )
    )
    
    :find_lib_done
    if not "!SOURCE_LIB!" equ "" (
        mkdir "!DEST_DIR!" 2>nul
        copy "!SOURCE_LIB!" "!DEST_LIB!" >nul
        call :log_message "SUCCESS" "Built !DEST_LIB!"
    ) else (
        call :log_message "ERROR" "Could not find built library for !ABI!"
    )
    
    REM Clean up
    rd /s /q "!BUILD_DIR!" 2>nul
)

REM Create CMakeLists.txt for easy integration
call :script_progress "Creating CMakeLists.txt for integration..."
(
    echo cmake_minimum_required(VERSION 3.16)
    echo project(llama_mobile_android LANGUAGES CXX C)
    echo.
    echo set(CMAKE_CXX_STANDARD 17)
    echo set(CMAKE_CXX_STANDARD_REQUIRED ON)
    echo.
    echo ^# Include directories
    echo include_directories(
    echo     ${CMAKE_CURRENT_SOURCE_DIR}/include
    echo     ${CMAKE_CURRENT_SOURCE_DIR}/include/llama_cpp
    echo )
    echo.
    echo ^# Import the pre-built libraries
    echo set(LLAMA_MOBILE_ABIS arm64-v8a x86_64)
    echo.
    echo foreach(ABI ${LLAMA_MOBILE_ABIS})
    echo     add_library(llama_mobile_${ABI} SHARED IMPORTED)
    echo     set_target_properties(llama_mobile_${ABI} PROPERTIES
    echo         IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ABI}/libllama_mobile.so
    echo         ANDROID_ABI ${ABI}
    echo     )
    echo endforeach()
    echo.
    echo ^# Main library target for linking
    echo add_library(llama_mobile SHARED IMPORTED)
    echo set_target_properties(llama_mobile PROPERTIES
    echo     IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${ANDROID_ABI}/libllama_mobile.so
    echo )
) > "%OUTPUT_DIR%\CMakeLists.txt"

call :log_message "SUCCESS" "CMakeLists.txt created for integration"

REM Clean up any remaining build directories
call :script_progress "Cleaning up temporary build directories..."
for /d %%d in ("%ROOT_DIR%build-android-native-*") do (
    rd /s /q "%%~fd" 2>nul
)

REM Verify the build
call :script_progress "Verifying build..."

REM Check if libraries were built
for %%a in (%ABIS%) do (
    set "LIB_PATH=%LIBS_DIR%\%%a\libllama_mobile.so"
    if exist "!LIB_PATH!" (
        for %%f in ("!LIB_PATH!") do (
            set "FILE_SIZE=%%~zf"
        )
        call :log_message "SUCCESS" "!LIB_PATH!: !FILE_SIZE! bytes"
    ) else (
        call :log_message "ERROR" "Library not found: !LIB_PATH!"
    )
)

call :log_message "SUCCESS" "Android native library build completed successfully!"

endlocal
exit /b 0
