@echo off
setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

echo ^[%BLUE%=== llama_mobile Build Script ===^[%NC%

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "LLAMA_MOBILE_DIR=%PROJECT_ROOT%\lib"
set "BUILD_DIR=%LLAMA_MOBILE_DIR%\build_windows"
set "OUTPUT_DIR=%BUILD_DIR%\output"

if exist "%SCRIPT_DIR%env.bat" (
    call "%SCRIPT_DIR%env.bat"
    if %errorlevel% neq 0 (
        echo ^[%RED%[FAIL] Environment configuration failed^[%NC%
        exit /b 1
    )
)

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

:clean_build
echo ^[%YELLOW%Cleaning old build...^[%NC%
if exist "%BUILD_DIR%" (
    rmdir /s /q "%BUILD_DIR%" >nul 2>&1
    echo ^[%GREEN%[OK] Old build cleaned^[%NC%
) else (
    echo ^[%YELLOW%[INFO] No existing build directory found^[%NC%
)

:build_project
echo ^[%BLUE%]Building llama_mobile...^[%NC%]
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cd /d "%BUILD_DIR%"

echo ^[%BLUE%]Running CMake...^[%NC%]
cmake .. -G "NMake Makefiles" -DBUILD_SHARED_LIBS=OFF -DCMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe"

if %errorlevel% neq 0 (
    echo ^[%RED%][FAIL] CMake configuration failed^[%NC%]
    exit /b 1
)

echo ^[%BLUE%Building static library...^[%NC%
cmake --build . --config Release --target llama_mobile_core_static

if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] Build failed^[%NC%
    exit /b 1
)

echo ^[%GREEN%[OK] Build completed successfully^[%NC%

:copy_grammars
echo ^[%BLUE%Copying grammar files...^[%NC%
set "GRAMMAR_SRC_DIR=%LLAMA_MOBILE_DIR%\grammars"
set "GRAMMAR_DEST_DIR=%OUTPUT_DIR%\grammars"

if not exist "%GRAMMAR_DEST_DIR%" mkdir "%GRAMMAR_DEST_DIR%"

if exist "%GRAMMAR_SRC_DIR%\*.gbnf" (
    for %%F in ("%GRAMMAR_SRC_DIR%\*.gbnf") do (
        copy "%%F" "%GRAMMAR_DEST_DIR%\" >nul
    )
    if %errorlevel% equ 0 (
        echo ^[%GREEN%[OK] Grammar files copied successfully^[%NC%
    ) else (
        echo ^[%RED%[FAIL] Failed to copy grammar files^[%NC%
        exit /b 1
    )
) else (
    echo ^[%YELLOW%[INFO] Grammar source directory not found, skipping grammar files^[%NC%
)

echo ^[%BLUE%=== Build script completed ===^[%NC%

endlocal
