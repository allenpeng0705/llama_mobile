@echo off
REM ============================================================================
REM Windows Build Environment Configuration for llama_mobile
REM
REM Before running any build scripts, you need to set up your development
REM environment. This file helps configure the necessary paths.
REM
REM Usage:
REM   call env.bat
REM   scripts\build-lib.bat
REM   scripts\build-android.bat
REM
REM Alternatively, set the environment variables manually in your system.
REM ============================================================================

echo Configuring Windows build environment...

REM ---------------------------------------------------------------------------
REM 1. Android NDK and SDK Configuration
REM ---------------------------------------------------------------------------
if not defined ANDROID_HOME (
    if exist "C:\Users\%USERNAME%\AppData\Local\Android\Sdk" (
        set "ANDROID_HOME=C:\Users\%USERNAME%\AppData\Local\Android\Sdk"
    ) else if exist "C:\Android\Sdk" (
        set "ANDROID_HOME=C:\Android\Sdk"
    ) else (
        echo [WARN] ANDROID_HOME not found. Please set it manually.
        echo Please set ANDROID_HOME manually before running builds.
        goto :android_config_done
    )
)

:android_config_done
if defined ANDROID_HOME (
    if exist "%ANDROID_HOME%" (
        echo [OK] ANDROID_HOME: %ANDROID_HOME%
    ) else (
        echo [WARN] ANDROID_HOME path does not exist: %ANDROID_HOME%
        set "ANDROID_HOME="
    )
)

REM NDK Version (update this to match your installed NDK version)
set "NDK_VERSION=29.0.14206865"
set "ANDROID_PLATFORM=android-21"

REM ---------------------------------------------------------------------------
REM 2. CMake Configuration
REM ---------------------------------------------------------------------------
cmake --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] CMake is available
) else (
    echo [WARN] CMake not found. Please add CMake to your PATH.
)

REM ---------------------------------------------------------------------------
REM 3. Visual Studio / NMake Configuration
REM ---------------------------------------------------------------------------
set "NMAKE_PATH="

REM Try to find Visual Studio 2025 (uses folder name "18")
if exist "C:\Program Files\Microsoft Visual Studio\2025\Community\VC\Tools\MSVC\" (
    for /d %%I in ("C:\Program Files\Microsoft Visual Studio\2025\Community\VC\Tools\MSVC\*") do (
        if exist "%%I\bin\HostX64\x64\nmake.exe" (
            set "VS_YEAR=2025"
            set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2025\Community"
            set "NMAKE_PATH=%%I\bin\HostX64\x64"
            goto :vs_found
        )
    )
)

REM Try to find Visual Studio 2025 using folder name "18"
if exist "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\" (
    for /d %%I in ("C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\*") do (
        if exist "%%I\bin\HostX64\x64\nmake.exe" (
            set "VS_YEAR=2025"
            set "VS_PATH=C:\Program Files\Microsoft Visual Studio\18\Community"
            set "NMAKE_PATH=%%I\bin\HostX64\x64"
            goto :vs_found
        )
    )
)

REM Try to find Visual Studio 2022
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\" (
    for /d %%I in ("C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\*") do (
        if exist "%%I\bin\Hostx64\x64\nmake.exe" (
            set "VS_YEAR=2022"
            set "VS_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community"
            set "NMAKE_PATH=%%I\bin\Hostx64\x64"
            goto :vs_found
        )
    )
)

REM Try to find Visual Studio 2019
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\" (
    for /d %%I in ("C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\*") do (
        if exist "%%I\bin\Hostx64\x64\nmake.exe" (
            set "VS_YEAR=2019"
            set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community"
            set "NMAKE_PATH=%%I\bin\Hostx64\x64"
            goto :vs_found
        )
    )
)

:vs_found
if defined NMAKE_PATH (
    if exist "%NMAKE_PATH%\nmake.exe" (
        set "PATH=%NMAKE_PATH%;%PATH%"
        echo [OK] NMake found: %NMAKE_PATH%
    ) else (
        echo [WARN] NMake not found at %NMAKE_PATH%
    )
) else (
    echo [WARN] Visual Studio not detected.
)

REM Initialize Visual Studio build environment (sets up LIB, INCLUDE, etc.)
if defined VS_PATH (
    echo [INFO] Initializing Visual Studio build environment...
    if exist "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" (
        call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64
        if %errorlevel% equ 0 (
            echo [OK] Visual Studio build environment initialized
        ) else (
            echo [WARN] Failed to initialize Visual Studio build environment
        )
    ) else if exist "%VS_PATH%\VC\Tools\MSVC\vcvarsall.bat" (
        call "%VS_PATH%\VC\Tools\MSVC\vcvarsall.bat" x64
        if %errorlevel% equ 0 (
            echo [OK] Visual Studio build environment initialized
        ) else (
            echo [WARN] Failed to initialize Visual Studio build environment
        )
    ) else (
        echo [WARN] vcvarsall.bat not found
    )
)

REM Add Windows SDK to PATH for rc.exe and other tools
if exist "C:\Program Files (x86)\Windows Kits\10\bin\x64" (
    set "PATH=C:\Program Files (x86)\Windows Kits\10\bin\x64;%PATH%"
    echo [OK] Windows SDK tools added to PATH
)

REM ---------------------------------------------------------------------------
REM 4. Python Configuration (optional, for tests)
REM ---------------------------------------------------------------------------
python --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Python is available
) else (
    echo [WARN] Python not found (optional, for running tests)
)

REM ---------------------------------------------------------------------------
REM 5. Summary
REM ---------------------------------------------------------------------------
echo.
echo Environment Summary:
if defined ANDROID_HOME (
    echo   ANDROID_HOME: %ANDROID_HOME%
)
if defined NMAKE_PATH (
    echo   Visual Studio: %VS_YEAR% Community
    echo   NMake Path: %NMAKE_PATH%
)
echo   NDK Version: %NDK_VERSION%
echo   Target Android Platform: %ANDROID_PLATFORM%
echo.
echo Environment configuration complete!
echo.
echo To build for Android:
echo   call env.bat
echo   call scripts\build-android.bat
echo.
echo To build for Windows:
echo   call env.bat
echo   call scripts\build-lib.bat
echo.
