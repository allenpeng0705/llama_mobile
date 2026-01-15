@echo off

REM ============================================================================
REM ANDROID SDK BUILD SCRIPT (WINDOWS)
REM Takes pre-built Android libraries from llama_mobile-android and creates clean Android SDKs
REM Output:
REM - llama_mobile/llama_mobile-android-SDK/ (Kotlin SDK)
REM - llama_mobile/llama_mobile-android-java-SDK/ (Java SDK)
REM ============================================================================

setlocal enabledelayedexpansion

REM Function to log messages
:log_message
set "LEVEL=%~1"
set "MESSAGE=%~2"
set "TIMESTAMP=%time:~0,8%"
echo [%TIMESTAMP%] [%LEVEL%] %MESSAGE%
goto :eof

REM Directory paths
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\"
set "PREBUILT_DIR=%ROOT_DIR%llama_mobile-android"
set "KOTLIN_SDK_DIR=%ROOT_DIR%llama_mobile-android-SDK"
set "JAVA_SDK_DIR=%ROOT_DIR%llama_mobile-android-java-SDK"

REM Main script execution
call :log_message "INFO" "Starting Android SDK build process..."

REM Check if pre-built libraries exist
if not exist "%PREBUILT_DIR%\libs" (
    call :log_message "ERROR" "Pre-built libraries not found at %PREBUILT_DIR%\libs"
    call :log_message "INFO" "Please ensure llama_mobile-android contains the pre-built libraries"
    exit /b 1
)

call :log_message "INFO" "Found pre-built libraries at %PREBUILT_DIR%\libs"

REM Create temporary directory for file preservation
set "TEMP_DIR=%TEMP%\llama_mobile_sdk_build"
rd /s /q "%TEMP_DIR%" 2>nul
mkdir "%TEMP_DIR%" 2>nul

REM Initialize temporary file variables
set "TEMP_KOTLIN="
set "TEMP_KOTLIN_JNI_CPP="
set "TEMP_KOTLIN_JNI_CMAKELISTS="
set "TEMP_KOTLIN_UNIT_TESTS="
set "TEMP_KOTLIN_INSTRUMENTED_TESTS="
set "TEMP_KOTLIN_COMPREHENSIVE_TESTS="
set "TEMP_KOTLIN_README="
set "TEMP_JAVA="
set "TEMP_JAVA_JNI_CPP="
set "TEMP_JAVA_JNI_CMAKELISTS="
set "TEMP_JAVA_UNIT_TESTS="
set "TEMP_JAVA_INSTRUMENTED_TESTS="
set "TEMP_JAVA_COMPREHENSIVE_TESTS="
set "TEMP_JAVA_README="

REM Preserve Kotlin SDK files if they exist
if exist "%KOTLIN_SDK_DIR%" (
    REM Preserve Kotlin wrapper
    if exist "%KOTLIN_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.kt" (
        set "TEMP_KOTLIN=%TEMP_DIR%\LlamaMobile.kt"
        copy "%KOTLIN_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.kt" "%TEMP_KOTLIN%" >nul
        call :log_message "INFO" "Preserved existing Kotlin wrapper temporarily"
    )
    
    REM Preserve JNI implementation
    if exist "%KOTLIN_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" (
        set "TEMP_KOTLIN_JNI_CPP=%TEMP_DIR%\kotlin_jni.cpp"
        copy "%KOTLIN_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" "%TEMP_KOTLIN_JNI_CPP%" >nul
        call :log_message "INFO" "Preserved existing Kotlin JNI implementation temporarily"
    )
    
    REM Preserve CMakeLists.txt
    if exist "%KOTLIN_SDK_DIR%\src\main\cpp\CMakeLists.txt" (
        set "TEMP_KOTLIN_JNI_CMAKELISTS=%TEMP_DIR%\kotlin_cmakelists.txt"
        copy "%KOTLIN_SDK_DIR%\src\main\cpp\CMakeLists.txt" "%TEMP_KOTLIN_JNI_CMAKELISTS%" >nul
        call :log_message "INFO" "Preserved existing Kotlin JNI CMakeLists.txt temporarily"
    )
    
    REM Preserve Kotlin unit tests
    if exist "%KOTLIN_SDK_DIR%\src\test\java\com\llamamobile\LlamaMobileUnitTests.kt" (
        set "TEMP_KOTLIN_UNIT_TESTS=%TEMP_DIR%\LlamaMobileUnitTests.kt"
        copy "%KOTLIN_SDK_DIR%\src\test\java\com\llamamobile\LlamaMobileUnitTests.kt" "%TEMP_KOTLIN_UNIT_TESTS%" >nul
        call :log_message "INFO" "Preserved existing Kotlin unit tests temporarily"
    )
    
    REM Preserve Kotlin instrumented tests
    if exist "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileInstrumentedTests.kt" (
        set "TEMP_KOTLIN_INSTRUMENTED_TESTS=%TEMP_DIR%\LlamaMobileInstrumentedTests.kt"
        copy "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileInstrumentedTests.kt" "%TEMP_KOTLIN_INSTRUMENTED_TESTS%" >nul
        call :log_message "INFO" "Preserved existing Kotlin instrumented tests temporarily"
    )
    
    REM Preserve Kotlin comprehensive tests
    if exist "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.kt" (
        set "TEMP_KOTLIN_COMPREHENSIVE_TESTS=%TEMP_DIR%\LlamaMobileComprehensiveTests.kt"
        copy "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.kt" "%TEMP_KOTLIN_COMPREHENSIVE_TESTS%" >nul
        call :log_message "INFO" "Preserved existing Kotlin comprehensive tests temporarily"
    )
    
    REM Preserve Kotlin README.md
    if exist "%KOTLIN_SDK_DIR%\README.md" (
        set "TEMP_KOTLIN_README=%TEMP_DIR%\KotlinREADME.md"
        copy "%KOTLIN_SDK_DIR%\README.md" "%TEMP_KOTLIN_README%" >nul
        call :log_message "INFO" "Preserved existing Kotlin README.md temporarily"
    )
)

REM Preserve Java SDK files if they exist
if exist "%JAVA_SDK_DIR%" (
    REM Preserve Java wrapper
    if exist "%JAVA_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.java" (
        set "TEMP_JAVA=%TEMP_DIR%\LlamaMobile.java"
        copy "%JAVA_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.java" "%TEMP_JAVA%" >nul
        call :log_message "INFO" "Preserved existing Java wrapper temporarily"
    )
    
    REM Preserve JNI implementation
    if exist "%JAVA_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" (
        set "TEMP_JAVA_JNI_CPP=%TEMP_DIR%\java_jni.cpp"
        copy "%JAVA_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" "%TEMP_JAVA_JNI_CPP%" >nul
        call :log_message "INFO" "Preserved existing Java JNI implementation temporarily"
    )
    
    REM Preserve CMakeLists.txt
    if exist "%JAVA_SDK_DIR%\src\main\cpp\CMakeLists.txt" (
        set "TEMP_JAVA_JNI_CMAKELISTS=%TEMP_DIR%\java_cmakelists.txt"
        copy "%JAVA_SDK_DIR%\src\main\cpp\CMakeLists.txt" "%TEMP_JAVA_JNI_CMAKELISTS%" >nul
        call :log_message "INFO" "Preserved existing Java JNI CMakeLists.txt temporarily"
    )
    
    REM Preserve Java comprehensive tests if they exist
    if exist "%JAVA_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.java" (
        set "TEMP_JAVA_COMPREHENSIVE_TESTS=%TEMP_DIR%\LlamaMobileComprehensiveTests.java"
        copy "%JAVA_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.java" "%TEMP_JAVA_COMPREHENSIVE_TESTS%" >nul
        call :log_message "INFO" "Preserved existing Java comprehensive tests temporarily"
    )
    
    REM Preserve Java README.md
    if exist "%JAVA_SDK_DIR%\README.md" (
        set "TEMP_JAVA_README=%TEMP_DIR%\JavaREADME.md"
        copy "%JAVA_SDK_DIR%\README.md" "%TEMP_JAVA_README%" >nul
        call :log_message "INFO" "Preserved existing Java README.md temporarily"
    )
)

REM Handle Kotlin SDK cleanup
if exist "%KOTLIN_SDK_DIR%" (
    call :log_message "INFO" "Removing existing Kotlin SDK directory"
    rd /s /q "%KOTLIN_SDK_DIR%" 2>nul
)

REM Handle Java SDK cleanup
if exist "%JAVA_SDK_DIR%" (
    call :log_message "INFO" "Removing existing Java SDK directory"
    rd /s /q "%JAVA_SDK_DIR%" 2>nul
)

REM Create clean SDK directory structures for both Kotlin and Java
call :log_message "INFO" "Creating clean SDK directory structures..."

REM Create Kotlin SDK directories
call :log_message "INFO" "Creating Kotlin SDK directories..."
mkdir "%KOTLIN_SDK_DIR%\src\main\jniLibs\arm64-v8a" 2>nul
mkdir "%KOTLIN_SDK_DIR%\src\main\jniLibs\x86_64" 2>nul
mkdir "%KOTLIN_SDK_DIR%\src\main\assets\grammars" 2>nul
mkdir "%KOTLIN_SDK_DIR%\src\main\java\com\llamamobile" 2>nul
mkdir "%KOTLIN_SDK_DIR%\src\main\cpp" 2>nul
mkdir "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile" 2>nul

REM Create Java SDK directories
call :log_message "INFO" "Creating Java SDK directories..."
mkdir "%JAVA_SDK_DIR%\src\main\jniLibs\arm64-v8a" 2>nul
mkdir "%JAVA_SDK_DIR%\src\main\jniLibs\x86_64" 2>nul
mkdir "%JAVA_SDK_DIR%\src\main\assets\grammars" 2>nul
mkdir "%JAVA_SDK_DIR%\src\main\java\com\llamamobile" 2>nul
mkdir "%JAVA_SDK_DIR%\src\main\cpp" 2>nul
mkdir "%JAVA_SDK_DIR%\src\androidTest\java\com\llamamobile" 2>nul

REM Function to find libc++_shared.so in NDK
:find_libcpp_shared
set "abi=%~1"
set "libcpp_path="

REM Define NDK ABI mapping
if "%abi%" equ "arm64-v8a" (
    set "linux_abi=aarch64-linux-android"
) else if "%abi%" equ "x86_64" (
    set "linux_abi=x86_64-linux-android"
) else (
    call :log_message "ERROR" "Unsupported ABI: %abi%"
    exit /b 1
)

REM Try common NDK paths on Windows
set "common_ndk_paths=%ANDROID_HOME%\ndk\29.0.14206865;%ANDROID_HOME%\ndk\28.0.0;%ANDROID_HOME%\ndk\27.0.1"

for %%n in (%common_ndk_paths%) do (
    if exist "%%n" (
        REM Try newer NDK path structure first (NDK 25+)
        set "libcpp_path_new=%%n\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\%linux_abi%\libc++_shared.so"
        if exist "!libcpp_path_new!" (
            set "libcpp_path=!libcpp_path_new!"
            echo !libcpp_path!
            exit /b 0
        )
        
        REM Try older NDK path structure
        set "libcpp_path_old=%%n\sources\cxx-stl\llvm-libc++\libs\%abi%\libc++_shared.so"
        if exist "!libcpp_path_old!" (
            set "libcpp_path=!libcpp_path_old!"
            echo !libcpp_path!
            exit /b 0
        )
    )
)

REM If not found, try to find the latest NDK version
if exist "%ANDROID_HOME%\ndk" (
    for /f "delims=" %%d in ('dir /b /ad "%ANDROID_HOME%\ndk" ^| sort /r') do (
        set "latest_ndk=%ANDROID_HOME%\ndk\%%d"
        goto :check_latest_ndk
    )
)

:check_latest_ndk
if exist "!latest_ndk!" (
    set "libcpp_path_new=!latest_ndk!\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\%linux_abi%\libc++_shared.so"
    if exist "!libcpp_path_new!" (
        set "libcpp_path=!libcpp_path_new!"
        echo !libcpp_path!
        exit /b 0
    )
    
    set "libcpp_path_old=!latest_ndk!\sources\cxx-stl\llvm-libc++\libs\%abi%\libc++_shared.so"
    if exist "!libcpp_path_old!" (
        set "libcpp_path=!libcpp_path_old!"
        echo !libcpp_path!
        exit /b 0
    )
)

call :log_message "ERROR" "Could not find libc++_shared.so for ABI %abi%"
exit /b 1
goto :eof

REM Copy pre-built libraries for all ABIs
call :log_message "INFO" "Copying pre-built libraries..."

for %%a in (arm64-v8a x86_64) do (
    if exist "%PREBUILT_DIR%\libs\%%a\libllama_mobile.so" (
        copy "%PREBUILT_DIR%\libs\%%a\libllama_mobile.so" "%KOTLIN_SDK_DIR%\src\main\jniLibs\%%a\libllama_mobile.so" >nul
        copy "%PREBUILT_DIR%\libs\%%a\libllama_mobile.so" "%JAVA_SDK_DIR%\src\main\jniLibs\%%a\libllama_mobile.so" >nul
        call :log_message "SUCCESS" "Copied libllama_mobile.so for %%a"
    )
)

REM Copy grammar files to both SDKs
if exist "%PREBUILT_DIR%\grammars" (
    call :log_message "INFO" "Copying grammar files..."
    xcopy /s /i /y "%PREBUILT_DIR%\grammars\*.gbnf" "%KOTLIN_SDK_DIR%\src\main\assets\grammars" >nul 2>nul
    xcopy /s /i /y "%PREBUILT_DIR%\grammars\*.gbnf" "%JAVA_SDK_DIR%\src\main\assets\grammars" >nul 2>nul
    call :log_message "SUCCESS" "Copied grammar files to both SDKs"
)

REM Restore preserved files
call :log_message "INFO" "Restoring preserved files..."

REM Restore Kotlin SDK files
if exist "%TEMP_KOTLIN%" (
    copy "%TEMP_KOTLIN%" "%KOTLIN_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.kt" >nul
    call :log_message "INFO" "Restored Kotlin wrapper"
)

if exist "%TEMP_KOTLIN_JNI_CPP%" (
    copy "%TEMP_KOTLIN_JNI_CPP%" "%KOTLIN_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" >nul
    call :log_message "INFO" "Restored Kotlin JNI implementation"
)

if exist "%TEMP_KOTLIN_JNI_CMAKELISTS%" (
    copy "%TEMP_KOTLIN_JNI_CMAKELISTS%" "%KOTLIN_SDK_DIR%\src\main\cpp\CMakeLists.txt" >nul
    call :log_message "INFO" "Restored Kotlin JNI CMakeLists.txt"
)

if exist "%TEMP_KOTLIN_UNIT_TESTS%" (
    copy "%TEMP_KOTLIN_UNIT_TESTS%" "%KOTLIN_SDK_DIR%\src\test\java\com\llamamobile\LlamaMobileUnitTests.kt" >nul
    call :log_message "INFO" "Restored Kotlin unit tests"
)

if exist "%TEMP_KOTLIN_INSTRUMENTED_TESTS%" (
    copy "%TEMP_KOTLIN_INSTRUMENTED_TESTS%" "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileInstrumentedTests.kt" >nul
    call :log_message "INFO" "Restored Kotlin instrumented tests"
)

if exist "%TEMP_KOTLIN_COMPREHENSIVE_TESTS%" (
    copy "%TEMP_KOTLIN_COMPREHENSIVE_TESTS%" "%KOTLIN_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.kt" >nul
    call :log_message "INFO" "Restored Kotlin comprehensive tests"
)

if exist "%TEMP_KOTLIN_README%" (
    copy "%TEMP_KOTLIN_README%" "%KOTLIN_SDK_DIR%\README.md" >nul
    call :log_message "INFO" "Restored Kotlin README.md"
)

REM Restore Java SDK files
if exist "%TEMP_JAVA%" (
    copy "%TEMP_JAVA%" "%JAVA_SDK_DIR%\src\main\java\com\llamamobile\LlamaMobile.java" >nul
    call :log_message "INFO" "Restored Java wrapper"
)

if exist "%TEMP_JAVA_JNI_CPP%" (
    copy "%TEMP_JAVA_JNI_CPP%" "%JAVA_SDK_DIR%\src\main\cpp\llama_mobile_jni.cpp" >nul
    call :log_message "INFO" "Restored Java JNI implementation"
)

if exist "%TEMP_JAVA_JNI_CMAKELISTS%" (
    copy "%TEMP_JAVA_JNI_CMAKELISTS%" "%JAVA_SDK_DIR%\src\main\cpp\CMakeLists.txt" >nul
    call :log_message "INFO" "Restored Java JNI CMakeLists.txt"
)

if exist "%TEMP_JAVA_COMPREHENSIVE_TESTS%" (
    copy "%TEMP_JAVA_COMPREHENSIVE_TESTS%" "%JAVA_SDK_DIR%\src\androidTest\java\com\llamamobile\LlamaMobileComprehensiveTests.java" >nul
    call :log_message "INFO" "Restored Java comprehensive tests"
)

if exist "%TEMP_JAVA_README%" (
    copy "%TEMP_JAVA_README%" "%JAVA_SDK_DIR%\README.md" >nul
    call :log_message "INFO" "Restored Java README.md"
)

REM Clean up temporary directory
call :log_message "INFO" "Cleaning up temporary files..."
rd /s /q "%TEMP_DIR%" 2>nul

REM Verify the build
call :log_message "INFO" "Verifying SDK build..."

REM Check if libraries were copied correctly
set "libraries_copied=false"
for %%a in (arm64-v8a x86_64) do (
    if exist "%KOTLIN_SDK_DIR%\src\main\jniLibs\%%a\libllama_mobile.so" (
        set "libraries_copied=true"
    )
    if exist "%JAVA_SDK_DIR%\src\main\jniLibs\%%a\libllama_mobile.so" (
        set "libraries_copied=true"
    )
)

if "%libraries_copied%" equ "true" (
    call :log_message "SUCCESS" "Android SDK build completed successfully!"
    call :log_message "INFO" "Kotlin SDK: %KOTLIN_SDK_DIR%"
    call :log_message "INFO" "Java SDK: %JAVA_SDK_DIR%"
) else (
    call :log_message "ERROR" "Android SDK build failed: No libraries found in the output directories"
    exit /b 1
)

exit /b 0
