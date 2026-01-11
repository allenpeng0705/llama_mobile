@echo off
setlocal enabledelayedexpansion

REM Color definitions for better output
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM Default configuration
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%.."
set "LLAMA_MOBILE_DIR=%PROJECT_ROOT%\lib"
set "BUILD_DIR=%LLAMA_MOBILE_DIR%\build_windows"
set "OUTPUT_DIR=%BUILD_DIR%\output"
set "CLEAN_BUILD=1"
set "CMAKE_ARGS="

REM Load centralized configuration from config.env
set "CONFIG_FILE=%SCRIPT_DIR%config.env"
if exist "!CONFIG_FILE!" (
    echo ^[%BLUE%Loading configuration from config.env...^[%NC%
    REM Extract all relevant variables from config.env
    for /f "tokens=1,2 delims==" %%a in ('findstr /r "^CMAKE_\|^RC_COMPILER\|^CC\|^CXX\|^SDK_PATH\|^NO_CLEAN\|^KEEP_BUILD\|^VERBOSE" "!CONFIG_FILE!"') do (
        set "%%a=%%~b"
    )
    echo ^[%GREEN%[OK] Configuration loaded^[%NC%
)

REM Set defaults from centralized config or use local defaults
set "BUILD_TYPE=!CMAKE_BUILD_TYPE:-Release=Release!"
set "BUILD_TYPE=!BUILD_TYPE:-"=!"
if "!BUILD_TYPE!" equ "" set "BUILD_TYPE=Release"

set "RC_COMPILER=!RC_COMPILER!"
set "RC_COMPILER=!RC_COMPILER:-"=!"

set "SDK_PATH=!SDK_PATH!"
set "SDK_PATH=!SDK_PATH:-"=!"

REM Build behavior flags with defaults
if "!NO_CLEAN!" equ "" set "NO_CLEAN=false"
if "!KEEP_BUILD!" equ "" set "KEEP_BUILD=false"
if "!VERBOSE!" equ "" set "VERBOSE=false"

REM Override with CC and CXX from config if available
if "!CC!" neq "" set "CC=!CC!"
if "!CXX!" neq "" set "CXX=!CXX!"

REM Update config.env with reasonable defaults if they're not set
if exist "!CONFIG_FILE!" (
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

REM Function to display usage information
:show_usage
echo ^[%BLUE%Usage: %~nx0 [options]^[%NC%
echo.
echo Build variables can be configured in scripts/config.env:
echo   - CMAKE_PATH: Path to CMake executable
echo   - CMAKE_BUILD_TYPE: Release or Debug build
echo   - CMAKE_JOBS: Number of parallel build jobs
echo   - RC_COMPILER: Path to Resource compiler
echo   - CC: C compiler path
echo   - CXX: C++ compiler path
echo.
echo Options:
echo   -h, --help           Show this help message
echo   -b, --build-dir      Custom build directory (default: %BUILD_DIR%)
echo   -o, --output-dir     Custom output directory (default: %OUTPUT_DIR%)
echo   -t, --build-type     Build type: Release or Debug (default: %BUILD_TYPE%)
echo   -c, --clean          Clean build directory before building (default: yes)
echo   --no-clean           Skip cleaning build directory
echo   --cmake-args         Additional CMake arguments
echo   --rc-compiler        Path to RC compiler (default: auto-detected)
echo.
echo Examples:
echo   %~nx0 -t Debug
echo   %~nx0 --build-dir "C:\custom\build\dir"
echo   %~nx0 --cmake-args "-DBUILD_SHARED_LIBS=ON"
exit /b 0

REM Parse command line arguments
:parse_args
if %~z0 == 0 goto :end_parse_args

:loop_args
if "%~1" == "" goto :end_parse_args

if "%~1" == "-h" goto :show_usage
if "%~1" == "--help" goto :show_usage

if "%~1" == "-b" (set "BUILD_DIR=%~2" & set "OUTPUT_DIR=%~2\output" & shift & shift & goto :loop_args)
if "%~1" == "--build-dir" (set "BUILD_DIR=%~2" & set "OUTPUT_DIR=%~2\output" & shift & shift & goto :loop_args)

if "%~1" == "-o" (set "OUTPUT_DIR=%~2" & shift & shift & goto :loop_args)
if "%~1" == "--output-dir" (set "OUTPUT_DIR=%~2" & shift & shift & goto :loop_args)

if "%~1" == "-t" (set "BUILD_TYPE=%~2" & shift & shift & goto :loop_args)
if "%~1" == "--build-type" (set "BUILD_TYPE=%~2" & shift & shift & goto :loop_args)

if "%~1" == "-c" (set "CLEAN_BUILD=1" & shift & goto :loop_args)
if "%~1" == "--clean" (set "CLEAN_BUILD=1" & shift & goto :loop_args)
if "%~1" == "--no-clean" (set "CLEAN_BUILD=0" & shift & goto :loop_args)

if "%~1" == "--cmake-args" (set "CMAKE_ARGS=%~2" & shift & shift & goto :loop_args)
if "%~1" == "--rc-compiler" (set "RC_COMPILER=%~2" & shift & shift & goto :loop_args)

echo ^[%RED%[ERROR] Unknown option: %~1^[%NC%
goto :show_usage

:end_parse_args

REM Load environment variables from env.bat if it exists
if exist "%SCRIPT_DIR%env.bat" (
    echo ^[%BLUE%Loading environment configuration...^[%NC%
    call "%SCRIPT_DIR%env.bat"
    if %errorlevel% neq 0 (
        echo ^[%RED%[FAIL] Environment configuration failed^[%NC%
        echo ^[%YELLOW%[INFO] Please check %SCRIPT_DIR%env.bat for configuration issues^[%NC%
        exit /b 1
    )
)

echo ^[%BLUE%=== llama_mobile Windows Build Script ===^[%NC%

:check_visual_studio
echo ^[%BLUE%Checking for Visual Studio...^[%NC%

REM Check if Visual Studio environment variables are set
if defined VSINSTALLDIR (
    echo ^[%GREEN%[OK] Visual Studio found at %VSINSTALLDIR%^[%NC%
) else (
    echo ^[%YELLOW%[INFO] Visual Studio environment not detected^[%NC%
    echo ^[%YELLOW%[INFO] Please run this script from a Visual Studio Developer Command Prompt^[%NC%
    echo ^[%YELLOW%[INFO] Alternatively, you can manually set VSINSTALLDIR environment variable^[%NC%
    echo ^[%YELLOW%[INFO] Example: set VSINSTALLDIR=C:\Program Files^\Microsoft Visual Studio^\2022\Community^[%NC%
)

:check_cmake
echo ^[%BLUE%Checking for cmake...^[%NC%
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] cmake not found^[%NC%
    echo ^[%YELLOW%[INFO] Please install CMake from https://cmake.org/download/^[%NC%
    echo ^[%YELLOW%[INFO] Make sure cmake is added to your PATH environment variable^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK] cmake found^[%NC%

:check_nmake
echo ^[%BLUE%Checking for nmake...^[%NC%
nmake /? >nul 2>&1
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] nmake not found^[%NC%
    echo ^[%YELLOW%[INFO] Please make sure Visual Studio is installed with C++ workload^[%NC%
    echo ^[%YELLOW%[INFO] Run this script from a Visual Studio Developer Command Prompt^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK] nmake found^[%NC%

REM Try to detect RC compiler if not provided
:if_rc_compiler_not_set
if not "%RC_COMPILER%" == "" goto :rc_compiler_detected

echo ^[%BLUE%Detecting RC compiler...^[%NC%

REM Try to find RC compiler in Windows SDK
for /f "tokens=*" %%a in ('where rc.exe 2^>nul') do (
    set "RC_COMPILER=%%a"
    goto :rc_compiler_detected
)

REM Try common Windows SDK paths
set "SDK_PATHS="
set "SDK_PATHS=%SDK_PATHS% "C:\Program Files (x86)\Windows Kits\10\bin\x64""
set "SDK_PATHS=%SDK_PATHS% "C:\Program Files (x86)\Windows Kits\10\bin\x86""
set "SDK_PATHS=%SDK_PATHS% "C:\Program Files (x86)\Windows Kits\11\bin\x64""
set "SDK_PATHS=%SDK_PATHS% "C:\Program Files (x86)\Windows Kits\11\bin\x86""

for %%p in (%SDK_PATHS%) do (
    if exist "%%p\rc.exe" (
        set "RC_COMPILER=%%p\rc.exe"
        goto :rc_compiler_detected
    )
)

echo ^[%RED%[FAIL] RC compiler not found^[%NC%
echo ^[%YELLOW%[INFO] Please provide RC compiler path using --rc-compiler option^[%NC%
echo ^[%YELLOW%[INFO] Example: --rc-compiler "C:\Program Files (x86)\Windows Kits\10\bin\x64\rc.exe"^[%NC%
exit /b 1

:rc_compiler_detected
echo ^[%GREEN%[OK] RC compiler found at %RC_COMPILER%^[%NC%

:clean_build
if %CLEAN_BUILD% equ 1 (
    echo ^[%YELLOW%Cleaning old build...^[%NC%
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%" >nul 2>&1
        if %errorlevel% equ 0 (
            echo ^[%GREEN%[OK] Old build cleaned^[%NC%
        ) else (
            echo ^[%YELLOW%[WARN] Could not clean build directory. Some files may be in use.^[%NC%
        )
    ) else (
        echo ^[%YELLOW%[INFO] No existing build directory found^[%NC%
    )
) else (
    echo ^[%YELLOW%[INFO] Skipping build directory cleaning^[%NC%
)

:build_project
echo ^[%BLUE%Building llama_mobile (%BUILD_TYPE%)...^[%NC%
echo ^[%BLUE%Build directory: %BUILD_DIR%^[%NC%
echo ^[%BLUE%Output directory: %OUTPUT_DIR%^[%NC%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cd /d "%BUILD_DIR%" 2>nul
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] Could not change to build directory^[%NC%
    exit /b 1
)

echo ^[%BLUE%Running CMake configuration...^[%NC%
set "CMAKE_COMMAND=cmake .. -G "NMake Makefiles" -DCMAKE_BUILD_TYPE=%BUILD_TYPE% -DCMAKE_RC_COMPILER="%RC_COMPILER%" %CMAKE_ARGS%"
echo ^[%BLUE%Command: !CMAKE_COMMAND!^[%NC%

!CMAKE_COMMAND!
if %errorlevel% neq 0 (
    echo ^[%RED%[FAIL] CMake configuration failed^[%NC%
    echo ^[%YELLOW%[INFO] Please check CMake output for errors^[%NC%
    exit /b 1
)
echo ^[%GREEN%[OK] CMake configuration completed^[%NC%

echo ^[%BLUE%Building project...^[%NC%
cmake --build . --config %BUILD_TYPE% --target llama_mobile_core_static
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
    set "GRAMMAR_COUNT=0"
    for %%F in ("%GRAMMAR_SRC_DIR%\*.gbnf") do (
        copy "%%F" "%GRAMMAR_DEST_DIR%\" >nul
        if !errorlevel! equ 0 (
            set /a GRAMMAR_COUNT+=1
        ) else (
            echo ^[%YELLOW%[WARN] Failed to copy %%~nxF^[%NC%
        )
    )
    echo ^[%GREEN%[OK] Successfully copied %GRAMMAR_COUNT% grammar files^[%NC%
) else (
    echo ^[%YELLOW%[INFO] No grammar files found in %GRAMMAR_SRC_DIR%^[%NC%
)

:show_summary
echo ^[%BLUE%=== Build Summary ===^[%NC%
echo ^[%GREEN%[OK] Build completed successfully^[%NC%
echo ^[%BLUE%Build type: %BUILD_TYPE%^[%NC%
echo ^[%BLUE%Build directory: %BUILD_DIR%^[%NC%
echo ^[%BLUE%Output directory: %OUTPUT_DIR%^[%NC%
echo ^[%BLUE%RC compiler: %RC_COMPILER%^[%NC%
echo ^[%BLUE%=== Build script completed ===^[%NC%

endlocal

:end
