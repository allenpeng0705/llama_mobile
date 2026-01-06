@echo off
setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo ^[%BLUE%=== Building llama_mobile Android library ===^[%NC%

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."

if exist "%SCRIPT_DIR%env.bat" (
    call "%SCRIPT_DIR%env.bat"
    if %errorlevel% neq 0 (
        echo ^[%RED%[FAIL] Environment configuration failed^[%NC%
        exit /b 1
    )
)

if not defined ANDROID_HOME (
    echo ^[%RED%[FAIL] ANDROID_HOME is not set^[%NC%
    echo Please run scripts\env.bat first or set ANDROID_HOME manually.
    exit /b 1
)

if not exist "%ANDROID_HOME%" (
    echo ^[%RED%[FAIL] ANDROID_HOME path does not exist: %ANDROID_HOME%^[%NC%
    exit /b 1
)

set "CMAKE_BUILD_TYPE=Release"
set "ABIS=arm64-v8a,x86_64"

:check_lib_dir
echo ^[%BLUE%Checking for lib directory...^[%NC%
if not exist "%ROOT_DIR%\lib" (
    echo ^[%RED%[FAIL] lib directory not found at %ROOT_DIR%\lib^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

:check_ndk
echo ^[%BLUE%Checking for NDK %NDK_VERSION%...^[%NC%
if not exist "%ANDROID_HOME%\ndk\%NDK_VERSION%" (
    echo ^[%RED%[FAIL] NDK %NDK_VERSION% not found at %ANDROID_HOME%\ndk\%NDK_VERSION%^[%NC%
    echo Available NDK versions:
    if exist "%ANDROID_HOME%\ndk\" dir /b "%ANDROID_HOME%\ndk\" 2>nul
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

set "CMAKE_TOOLCHAIN_FILE=%ANDROID_HOME%\ndk\%NDK_VERSION%\build\cmake\android.toolchain.cmake"

:check_cmake
echo ^[%BLUE%Checking for cmake...^[%NC%
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] cmake not found^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

:check_nmake
echo ^[%BLUE%Checking for nmake...^[%NC%
nmake /? >nul 2>&1
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] nmake not found^[%NC%
    echo Please make sure Visual Studio is installed with C++ workload.
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

:setup_dirs
set "GRAMMAR_SRC_DIR=%ROOT_DIR%\lib\grammars"
set "GRAMMAR_DEST_DIR=%ROOT_DIR%\llama_mobile-android\src\main\assets\grammars"

echo ^[%BLUE%Creating necessary directories...^[%NC%
if not exist "%ROOT_DIR%\llama_mobile-android\src\main\jniLibs" mkdir "%ROOT_DIR%\llama_mobile-android\src\main\jniLibs" >nul 2>&1
if not exist "%ROOT_DIR%\llama_mobile-android\src\main\cpp" mkdir "%ROOT_DIR%\llama_mobile-android\src\main\cpp" >nul 2>&1
if not exist "%ROOT_DIR%\llama_mobile-android\src\main\java\com\llamamobile" mkdir "%ROOT_DIR%\llama_mobile-android\src\main\java\com\llamamobile" >nul 2>&1
if not exist "%GRAMMAR_DEST_DIR%" mkdir "%GRAMMAR_DEST_DIR%" >nul 2>&1
echo ^[%GREEN%[OK]^[%NC%

:copy_grammars
echo ^[%BLUE%Copying grammar files to assets...^[%NC%
if exist "%GRAMMAR_SRC_DIR%\*.gbnf" (
    for %%F in ("%GRAMMAR_SRC_DIR%\*.gbnf") do (
        copy "%%F" "%GRAMMAR_DEST_DIR%\" >nul
    )
    echo ^[%GREEN%[OK]^[%NC%
) else (
    echo ^[%YELLOW%[INFO] Grammar source directory not found at %GRAMMAR_SRC_DIR%^[%NC%
)

echo ^[%BLUE%Building for ABIs: %ABIS%^[%NC%

:build_arm64_v8a
echo.
echo ^[%BLUE%=== Building for arm64-v8a ===^[%NC%

set "BUILD_DIR=%ROOT_DIR%\build-android-arm64-v8a"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" >nul 2>&1
mkdir "%BUILD_DIR%" >nul 2>&1

echo ^[%BLUE%Configuring CMake for arm64-v8a...^[%NC%
cmake -S "%ROOT_DIR%\lib" -B "%BUILD_DIR%" -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" -DANDROID_ABI="arm64-v8a" -DANDROID_PLATFORM="%ANDROID_PLATFORM%" -DCMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%" -DANDROID_STL=c++_shared -DBUILD_SHARED_LIBS=ON
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] CMake configuration failed for arm64-v8a^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

echo ^[%BLUE%Building library for arm64-v8a...^[%NC%
cmake --build "%BUILD_DIR%" --config "%CMAKE_BUILD_TYPE%"
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] Build failed for arm64-v8a^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

set "SOURCE_LIB=%BUILD_DIR%\output\lib\libllama_mobile_core.so"
set "DEST_DIR=%ROOT_DIR%\llama_mobile-android\src\main\jniLibs\arm64-v8a"
set "DEST_LIB=%DEST_DIR%\libllama_mobile.so"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%" >nul 2>&1

echo ^[%BLUE%Copying arm64-v8a library...^[%NC%
if exist "%SOURCE_LIB%" (
    copy "%SOURCE_LIB%" "%DEST_LIB%" >nul
    echo ^[%GREEN%[OK]^[%NC%
) else (
    echo ^[%RED%[FAIL] Built library not found at %SOURCE_LIB%^[%NC%
    exit /b 1
)

echo ^[%BLUE%Cleaning up build directory...^[%NC%
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" >nul 2>&1
echo ^[%GREEN%[OK]^[%NC%

:build_x86_64
echo.
echo ^[%BLUE%=== Building for x86_64 ===^[%NC%

set "BUILD_DIR=%ROOT_DIR%\build-android-x86_64"
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" >nul 2>&1
mkdir "%BUILD_DIR%" >nul 2>&1

echo ^[%BLUE%Configuring CMake for x86_64...^[%NC%
cmake -S "%ROOT_DIR%\lib" -B "%BUILD_DIR%" -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" -DANDROID_ABI="x86_64" -DANDROID_PLATFORM="%ANDROID_PLATFORM%" -DCMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%" -DANDROID_STL=c++_shared -DBUILD_SHARED_LIBS=ON
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] CMake configuration failed for x86_64^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

echo ^[%BLUE%Building library for x86_64...^[%NC%
cmake --build "%BUILD_DIR%" --config "%CMAKE_BUILD_TYPE%"
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] Build failed for x86_64^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK]^[%NC%

set "SOURCE_LIB=%BUILD_DIR%\output\lib\libllama_mobile_core.so"
set "DEST_DIR=%ROOT_DIR%\llama_mobile-android\src\main\jniLibs\x86_64"
set "DEST_LIB=%DEST_DIR%\libllama_mobile.so"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%" >nul 2>&1

echo ^[%BLUE%Copying x86_64 library...^[%NC%
if exist "%SOURCE_LIB%" (
    copy "%SOURCE_LIB%" "%DEST_LIB%" >nul
    echo ^[%GREEN%[OK]^[%NC%
) else (
    echo ^[%RED%[FAIL] Built library not found at %SOURCE_LIB%^[%NC%
    exit /b 1
)

echo ^[%BLUE%Cleaning up build directory...^[%NC%
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%" >nul 2>&1
echo ^[%GREEN%[OK]^[%NC%

echo.
echo ^[%GREEN%=== Android build completed successfully ===^[%NC%

endlocal
