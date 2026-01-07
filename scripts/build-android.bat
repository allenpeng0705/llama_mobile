@echo off
setlocal enabledelayedexpansion

set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

:: Default values
set "NDK_VERSION=29.0.14206865"
set "ABIS=arm64-v8a,x86_64"

:: Check for help argument first
for %%a in (%*) do (
    if /i "%%a"=="-h" (
        goto :show_help
    )
    if /i "%%a"=="--help" (
        goto :show_help
    )
)

:: Parse command line arguments
:parse_args
if "%~1"=="" goto :end_parse_args

if /i "%~1"=="--abi" (
    if not "%~2"=="" (
        set "ABIS=%~2"
        shift
        shift
        goto :parse_args
    ) else (
        echo ^[%RED%[ERROR] Missing value for --abi parameter^[%NC%
        exit /b 1
    )
) else if "%~1"=="--abi="* (
    set "ABIS=%~1:--abi=%%"
    shift
    goto :parse_args
)

if /i "%~1"=="--ndk-version" (
    if not "%~2"=="" (
        set "NDK_VERSION=%~2"
        shift
        shift
        goto :parse_args
    ) else (
        echo ^[%RED%[ERROR] Missing value for --ndk-version parameter^[%NC%
        exit /b 1
    )
) else if "%~1"=="--ndk-version="* (
    set "NDK_VERSION=%~1:--ndk-version=%%"
    shift
    goto :parse_args
)

:: Unknown parameter
if not "%~1"=="" (
    echo ^[%RED%[ERROR] Unknown parameter: %~1^[%NC%
    goto :show_help
)

:end_parse_args

:: Continue with the actual build process
goto :continue_build

:: Show help message
:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Builds the llama_mobile Android library with cross-platform support.
echo.
echo Options:
echo   -h, --help              Show this help message and exit
echo   --abi=ABI1,ABI2         Specify which ABIs to build (default: %ABIS%)
echo   --ndk-version=VERSION   Use specific NDK version (default: %NDK_VERSION%)
echo.
echo ANDROID_HOME Configuration:
echo   The script automatically detects ANDROID_HOME from common SDK paths:
echo   - %%USERPROFILE%%\AppData\Local\Android\Sdk
echo   - %%USERPROFILE%%\Android\Sdk
echo.
echo   If detection fails, set it manually:
echo     set ANDROID_HOME=C:\path\to\sdk && %~nx0
exit /b 0

:: Continue with the actual build process
:continue_build
echo === Building llama_mobile Android library ===

set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%.."

:: Check if env.bat exists and run it
if exist "%SCRIPT_DIR%env.bat" (
    call "%SCRIPT_DIR%env.bat"
    if %errorlevel% neq 0 (
        echo ^[%RED%[FAIL] Environment configuration failed^[%NC%
        exit /b 1
    )
)

:: Set default ANDROID_HOME if not set
if not defined ANDROID_HOME (
    echo ANDROID_HOME not set, trying to detect from system...
    
    :: Common Android SDK paths on Windows
    set "COMMON_PATHS=%USERPROFILE%\AppData\Local\Android\Sdk;%USERPROFILE%\Android\Sdk"
    
    set "ANDROID_HOME_FOUND="
    
    :: Parse the list of paths
    for %%p in (%COMMON_PATHS%) do (
        if exist "%%p" (
            set "ANDROID_HOME=%%p"
            set "ANDROID_HOME_FOUND=1"
            echo ✅ Detected ANDROID_HOME: !ANDROID_HOME!
            goto :end_android_home_detection
        )
    )
    
    :end_android_home_detection
    if not defined ANDROID_HOME_FOUND (
        echo ❌ Failed to auto-detect ANDROID_HOME
        echo Please set the ANDROID_HOME environment variable manually:
        echo   set ANDROID_HOME=C:\path\to\your\android\sdk
        echo   %~nx0
        exit /b 1
    )
)

if not exist "%ANDROID_HOME%" (
    echo ❌ ANDROID_HOME path does not exist: %ANDROID_HOME%
    exit /b 1
)

echo Using ANDROID_HOME: %ANDROID_HOME%

set "ANDROID_PLATFORM=android-21"
set "CMAKE_BUILD_TYPE=Release"

:check_lib_dir
echo ^| Checking for lib directory... ^|
if not exist "%ROOT_DIR%\lib" (
    echo ^| ^[%RED%✗^[%NC% lib directory not found at %ROOT_DIR%\lib
    echo ^| ^[%RED%[FAIL] Please ensure you're in the correct directory and the lib folder exists.^[%NC%
    exit /b 1
)
echo ^| ^[%GREEN%✓^[%NC%

:check_ndk
echo ^| Checking for NDK %NDK_VERSION%... ^|
if not exist "%ANDROID_HOME%\ndk\%NDK_VERSION%" (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] NDK %NDK_VERSION% not found at %ANDROID_HOME%\ndk\%NDK_VERSION%!^[%NC%
    echo ^| Available NDK versions:
    if exist "%ANDROID_HOME%\ndk\" dir /b "%ANDROID_HOME%\ndk\" 2>nul
    exit /b 1
)
echo ^| ^[%GREEN%✓^[%NC%

set "CMAKE_TOOLCHAIN_FILE=%ANDROID_HOME%\ndk\%NDK_VERSION%\build\cmake\android.toolchain.cmake"

:check_cmake
echo ^| Checking for cmake... ^|
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] cmake not found!^[%NC%
    echo ^| Please install cmake using your system package manager or download from https://cmake.org/
    exit /b 1
)
echo ^| ^[%GREEN%✓^[%NC%

:check_nmake
echo ^| Checking for nmake... ^|
nmake /? >nul 2>&1
if %errorlevel% neq 0 (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] nmake not found!^[%NC%
    echo ^| Please make sure Visual Studio is installed with C++ workload.
    exit /b 1
)
echo ^| ^[%GREEN%✓^[%NC%

:setup_dirs
set "GRAMMAR_SRC_DIR=%ROOT_DIR%\lib\grammars"
set "GRAMMAR_DEST_DIR1=%ROOT_DIR%\llama_mobile-android\src\main\assets\grammars"
set "GRAMMAR_DEST_DIR2=%ROOT_DIR%\llama_mobile-Android-SDK\src\main\assets\grammars"

echo ^| Creating necessary directories... ^|
set "dirs_to_create=%ROOT_DIR%\llama_mobile-android\src\main\jniLibs %ROOT_DIR%\llama_mobile-android\src\main\cpp %ROOT_DIR%\llama_mobile-android\src\main\java\com\llamamobile %GRAMMAR_DEST_DIR1% %ROOT_DIR%\llama_mobile-Android-SDK\src\main\jniLibs %ROOT_DIR%\llama_mobile-Android-SDK\src\main\cpp %ROOT_DIR%\llama_mobile-Android-SDK\src\main\java\com\llamamobile %GRAMMAR_DEST_DIR2%"

set "all_created=true"
for %%d in (%dirs_to_create%) do (
    if not exist "%%d" (
        mkdir "%%d" >nul 2>&1
        if !errorlevel! neq 0 (
            set "all_created=false"
        )
    )
)

if "!all_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create one or more directories!^[%NC%
    echo ^| Please check your permissions and try again.
    exit /b 1
)

:copy_grammars
echo ^| Copying grammar files to assets... ^|
if exist "%GRAMMAR_SRC_DIR%\*.gbnf" (
    set "all_copied=true"
    for %%F in ("%GRAMMAR_SRC_DIR%\*.gbnf") do (
        copy "%%F" "%GRAMMAR_DEST_DIR1%\" >nul || set "all_copied=false"
        copy "%%F" "%GRAMMAR_DEST_DIR2%\" >nul || set "all_copied=false"
    )
    if "!all_copied!" == "true" (
        echo ^| ^[%GREEN%✓^[%NC%
    ) else (
        echo ^| ^[%RED%✗^[%NC%
        echo ^| ^[%RED%[FAIL] Failed to copy grammar files to one or more destinations!^[%NC%
        exit /b 1
    )
) else (
    echo ^| ^[%YELLOW%[INFO] Grammar source directory not found at %GRAMMAR_SRC_DIR%^[%NC%
)

echo -n Building for ABIs: %ABIS%... 

:build_abis
echo.
echo ^| Building for ABIs: %ABIS%... ^|
echo ^| ^[%GREEN%✓^[%NC%

:: Split ABIS into individual ABI entries
for %%a in (%ABIS:,= %%) do (
    echo.
    echo === Building for %%a ===
    
    set "CURRENT_ABI=%%a"
    set "BUILD_DIR=%ROOT_DIR%\build-android-%%a"
    
    :: Clean up old build directory
    echo ^| Cleaning old build directory... ^|
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo ^| ^[%RED%✗^[%NC%
            echo ^| ^[%RED%[FAIL] Failed to remove old build directory %BUILD_DIR%!^[%NC%
            echo ^| Please check your permissions and try again.
            exit /b 1
        )
    )
    echo ^| ^[%GREEN%✓^[%NC%
    
    :: Create build directory
    echo ^| Creating build directory... ^|
    mkdir "%BUILD_DIR%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo ^| ^[%RED%✗^[%NC%
        echo ^| ^[%RED%[FAIL] Failed to create build directory %BUILD_DIR%!^[%NC%
        exit /b 1
    )
    echo ^| ^[%GREEN%✓^[%NC%
    
    :: Configure platform-specific flags
    set "PLATFORM_FLAGS="
    if "%%a" == "arm64-v8a" set "PLATFORM_FLAGS=-DGGML_NO_POSIX_MADVISE=ON"
    
    echo ^| Configuring CMake for %%a... ^|
    cmake -S "%ROOT_DIR%\lib" -B "%BUILD_DIR%" -G "NMake Makefiles" -DCMAKE_TOOLCHAIN_FILE="%CMAKE_TOOLCHAIN_FILE%" -DANDROID_ABI="%%a" -DANDROID_PLATFORM="%ANDROID_PLATFORM%" -DCMAKE_BUILD_TYPE="%CMAKE_BUILD_TYPE%" -DANDROID_STL=c++_shared -DBUILD_SHARED_LIBS=ON %PLATFORM_FLAGS%
    if !errorlevel! neq 0 (
        echo ^| ^[%RED%✗^[%NC%
        echo ^| ^[%RED%[FAIL] CMake configuration failed for %%a!^[%NC%
        echo ^| Please check the error messages above and try again.
        echo ^| Common issues: Invalid ABI, missing NDK components, or incorrect ANDROID_HOME.
        exit /b 1
    )
    echo ^| ^[%GREEN%✓^[%NC%
    
    echo ^| Building library for %%a... ^|
    cmake --build "%BUILD_DIR%" --config "%CMAKE_BUILD_TYPE%"
    if !errorlevel! neq 0 (
        echo ^| ^[%RED%✗^[%NC%
        echo ^| ^[%RED%[FAIL] Build failed for %%a!^[%NC%
        echo ^| Please check the error messages above and try again.
        exit /b 1
    )
    echo ^| ^[%GREEN%✓^[%NC%
    
    set "SOURCE_LIB=%BUILD_DIR%\output\lib\libllama_mobile_core.so"
    set "DEST_DIR1=%ROOT_DIR%\llama_mobile-android\src\main\jniLibs\%%a"
    set "DEST_DIR2=%ROOT_DIR%\llama_mobile-Android-SDK\src\main\jniLibs\%%a"
    
    echo ^| Copying %%a library... ^|
    if exist "%SOURCE_LIB%" (
        set "all_copied=true"
        
        :: Create destination directories if they don't exist
        if not exist "%DEST_DIR1%" (
            mkdir "%DEST_DIR1%" >nul 2>&1 || set "all_copied=false"
        )
        if not exist "%DEST_DIR2%" (
            mkdir "%DEST_DIR2%" >nul 2>&1 || set "all_copied=false"
        )
        
        :: Copy the libraries
        copy "%SOURCE_LIB%" "%DEST_DIR1%\libllama_mobile.so" >nul || set "all_copied=false"
        copy "%SOURCE_LIB%" "%DEST_DIR2%\libllama_mobile.so" >nul || set "all_copied=false"
        
        if "!all_copied!" == "true" (
            echo ^| ^[%GREEN%✓^[%NC%
        ) else (
            echo ^| ^[%RED%✗^[%NC%
            echo ^| ^[%RED%[FAIL] Failed to copy library to one or more destinations!^[%NC%
            exit /b 1
        )
    ) else (
        echo ^| ^[%RED%✗^[%NC%
        echo ^| ^[%RED%[FAIL] Built library not found at %SOURCE_LIB%!^[%NC%
        echo ^| Build may have succeeded but library file is missing.
        exit /b 1
    )
    
    echo ^| Cleaning up build directory... ^|
    if exist "%BUILD_DIR%" (
        rmdir /s /q "%BUILD_DIR%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo ^| ^[%RED%✗^[%NC%
            echo ^| ^[%RED%[FAIL] Failed to clean up build directory %BUILD_DIR%!^[%NC%
        ) else (
            echo ^| ^[%GREEN%✓^[%NC%
        )
    ) else (
        echo ^| ^[%GREEN%✓^[%NC%
    )
)

:create_cmakelists
echo ^| Creating CMakeLists.txt files... ^|

set "CMAKE_FILE1=%ROOT_DIR%\llama_mobile-android\src\main\cpp\CMakeLists.txt"

set "file_created=true"
(
  echo cmake_minimum_required(VERSION 3.16)
  echo project(llama_mobile_android LANGUAGES CXX C)
  echo.
  echo set(CMAKE_CXX_STANDARD 20)
  echo set(CMAKE_CXX_STANDARD_REQUIRED ON)
  echo.
  echo # Add definitions
  echo add_definitions(
  echo     -DNDEBUG
  echo     -DLM_GGML_USE_CPU
  echo     -DLM_GGML_USE_OPENCL=OFF
  echo     -DGGML_NO_POSIX_MADVISE
  echo )
  echo.
  echo # Include directories
  echo include_directories(
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib"
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp"
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu"
  echo )
  echo.
  echo # Import the pre-built llama_mobile library
  echo add_library(llama_mobile SHARED IMPORTED)
  echo set_target_properties(llama_mobile PROPERTIES
  echo     IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
  echo )
  echo.
  echo # Create a JNI wrapper
  echo add_library(llama_mobile_jni SHARED
  echo     llama_mobile_jni.cpp
  echo )
  echo.
  echo # Link libraries
  echo target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)
) > "%CMAKE_FILE1%" || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create CMakeLists.txt files!^[%NC%
    exit /b 1
)

:create_jni_wrapper
echo ^| Creating JNI wrapper implementation... ^|

set "JNI_FILE1=%ROOT_DIR%\llama_mobile-android\src\main\cpp\llama_mobile_jni.cpp"

set "file_created=true"
(
  echo // JNI wrapper for llama_mobile Android library
  echo #include ^<jni.h^>
  echo #include ^<string^>
  echo #include ^<cstring^>
  echo.
  echo // Include the llama_mobile headers
  echo #include "llama_mobile_api.h"
  echo.
  echo #ifdef __cplusplus
  echo extern "C" {
  echo #endif
  echo.
  echo // JNI helper function to convert jstring to const char*
  echo static const char* getStringUTFChars(JNIEnv* env, jstring str) {
  echo     if (str == nullptr) {
  echo         return nullptr;
  echo     }
  echo     return env->GetStringUTFChars(str, nullptr);
  echo }
  echo.
  echo // JNI helper function to release const char*
  echo static void releaseStringUTFChars(JNIEnv* env, jstring str, const char* cStr) {
  echo     if (str != nullptr && cStr != nullptr) {
  echo         env->ReleaseStringUTFChars(str, cStr);
  echo     }
  echo }
  echo.
  echo // Helper function to extract InitParams from Java object
  echo static bool extractInitParams(JNIEnv* env, jobject initParamsObj, llama_mobile_init_params_c_t& params, const char*& modelPath, const char*& chatTemplate) {
  echo     jclass paramsClass = env->GetObjectClass(initParamsObj);
  echo     if (paramsClass == nullptr) {
  echo         return false;
  echo     }
  echo     
  echo     // Get fields
  echo     jfieldID modelPathField = env->GetFieldID(paramsClass, "modelPath", "Ljava/lang/String;");
  echo     jfieldID nCtxField = env->GetFieldID(paramsClass, "nCtx", "I");
  echo     jfieldID chatTemplateField = env->GetFieldID(paramsClass, "chatTemplate", "Ljava/lang/String;");
  echo     jfieldID cacheTypeField = env->GetFieldID(paramsClass, "cacheType", "Lcom/llamamobile/LlamaMobile$CacheType;");
  echo     
  echo     if (modelPathField == nullptr || nCtxField == nullptr || chatTemplateField == nullptr || cacheTypeField == nullptr) {
  echo         env->DeleteLocalRef(paramsClass);
  echo         return false;
  echo     }
  echo     
  echo     // Extract values
  echo     jstring modelPathStr = (jstring)env->GetObjectField(initParamsObj, modelPathField);
  echo     jint nCtx = env->GetIntField(initParamsObj, nCtxField);
  echo     jstring chatTemplateStr = (jstring)env->GetObjectField(initParamsObj, chatTemplateField);
  echo     jobject cacheTypeObj = env->GetObjectField(initParamsObj, cacheTypeField);
  echo     
  echo     // Get cache type enum value
  echo     jint cacheType = 0; // Default to NONE
  echo     if (cacheTypeObj != nullptr) {
  echo         jclass cacheTypeClass = env->GetObjectClass(cacheTypeObj);
  echo         jmethodID ordinalMethod = env->GetMethodID(cacheTypeClass, "ordinal", "()I");
  echo         if (ordinalMethod != nullptr) {
  echo             cacheType = env->CallIntMethod(cacheTypeObj, ordinalMethod);
  echo         }
  echo         env->DeleteLocalRef(cacheTypeClass);
  echo     }
  echo     
  echo     // Convert strings
  echo     modelPath = getStringUTFChars(env, modelPathStr);
  echo     chatTemplate = getStringUTFChars(env, chatTemplateStr);
  echo     
  echo     // Set params
  echo     params.model_path = modelPath;
  echo     params.n_ctx = nCtx;
  echo     params.chat_template = chatTemplate;
  echo     params.cache_type = cacheType;
  echo     params.progress_callback = nullptr;
  echo     
  echo     env->DeleteLocalRef(paramsClass);
  echo     env->DeleteLocalRef(modelPathStr);
  echo     env->DeleteLocalRef(chatTemplateStr);
  echo     env->DeleteLocalRef(cacheTypeObj);
  echo     
  echo     return true;
  echo }
  echo.
  echo // Extract CompletionParams from Java object
  echo static bool extractCompletionParams(JNIEnv* env, jobject completionParamsObj, llama_mobile_completion_params_c_t& params, const char*& prompt) {
  echo     jclass paramsClass = env->GetObjectClass(completionParamsObj);
  echo     if (paramsClass == nullptr) {
  echo         return false;
  echo     }
  echo     
  echo     // Get fields
  echo     jfieldID promptField = env->GetFieldID(paramsClass, "prompt", "Ljava/lang/String;");
  echo     jfieldID temperatureField = env->GetFieldID(paramsClass, "temperature", "F");
  echo     jfieldID maxTokensField = env->GetFieldID(paramsClass, "maxTokens", "I");
  echo     
  echo     if (promptField == nullptr || temperatureField == nullptr || maxTokensField == nullptr) {
  echo         env->DeleteLocalRef(paramsClass);
  echo         return false;
  echo     }
  echo     
  echo     // Extract values
  echo     jstring promptStr = (jstring)env->GetObjectField(completionParamsObj, promptField);
  echo     jfloat temperature = env->GetFloatField(completionParamsObj, temperatureField);
  echo     jint maxTokens = env->GetIntField(completionParamsObj, maxTokensField);
  echo     
  echo     // Convert string
  echo     prompt = getStringUTFChars(env, promptStr);
  echo     
  echo     // Set params
  echo     params.prompt = prompt;
  echo     params.temperature = temperature;
  echo     params.max_new_tokens = maxTokens;
  echo     
  echo     env->DeleteLocalRef(paramsClass);
  echo     env->DeleteLocalRef(promptStr);
  echo     
  echo     return true;
  echo }
  echo.
  echo // Initialize context
  echo JNIEXPORT jlong JNICALL Java_com_llamamobile_LlamaMobile_initContext(
  echo     JNIEnv *env, jobject thiz, jobject initParamsObj) {
  echo     
  echo     llama_mobile_init_params_c_t params = {};
  echo     const char* modelPath = nullptr;
  echo     const char* chatTemplate = nullptr;
  echo     
  echo     if (!extractInitParams(env, initParamsObj, params, modelPath, chatTemplate)) {
  echo         return 0;
  echo     }
  echo     
  echo     if (modelPath == nullptr) {
  echo         return 0;
  echo     }
  echo     
  echo     void *context = llama_mobile_init_context_c(&params);
  echo     
  echo     // Release strings
  echo     releaseStringUTFChars(env, nullptr, modelPath);
  echo     releaseStringUTFChars(env, nullptr, chatTemplate);
  echo     
  echo     return reinterpret_cast<jlong>(context);
  echo }
  echo.
  echo // Generate completion
  echo JNIEXPORT jstring JNICALL Java_com_llamamobile_LlamaMobile_generateCompletion(
  echo     JNIEnv *env, jobject thiz, jlong contextHandle, jobject completionParamsObj) {
  echo     
  echo     if (contextHandle == 0) {
  echo         return nullptr;
  echo     }
  echo     
  echo     llama_mobile_completion_params_c_t params = {};
  echo     const char* prompt = nullptr;
  echo     
  echo     if (!extractCompletionParams(env, completionParamsObj, params, prompt)) {
  echo         return nullptr;
  echo     }
  echo     
  echo     if (prompt == nullptr) {
  echo         return nullptr;
  echo     }
  echo     
  echo     char *result = llama_mobile_generate_completion_c(reinterpret_cast<void*>(contextHandle), &params);
  echo     
  echo     // Release prompt string
  echo     releaseStringUTFChars(env, nullptr, prompt);
  echo     
  echo     if (result == nullptr) {
  echo         return nullptr;
  echo     }
  echo     
  echo     jstring javaResult = env->NewStringUTF(result);
  echo     free(result);
  echo     
  echo     return javaResult;
  echo }
  echo.
  echo // Release context
  echo JNIEXPORT void JNICALL Java_com_llamamobile_LlamaMobile_releaseContext(
  echo     JNIEnv *env, jobject thiz, jlong contextHandle) {
  echo     
  echo     if (contextHandle != 0) {
  echo         llama_mobile_release_context_c(reinterpret_cast<void*>(contextHandle));
  echo     }
  echo }
  echo.
  echo #ifdef __cplusplus
  echo }
  echo #endif
) > "%JNI_FILE1%" || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create JNI wrapper files!^[%NC%
    exit /b 1
)

:create_androidmanifest
echo ^| Creating AndroidManifest.xml... ^|

set "MANIFEST_FILE=%ROOT_DIR%\llama_mobile-android\src\main\AndroidManifest.xml"

set "file_created=true"
(
  echo ^<?xml version="1.0" encoding="utf-8"?^>
  echo ^<manifest xmlns:android="http://schemas.android.com/apk/res/android"
  echo     package="com.llamamobile"^>
  echo.
  echo     ^<uses-sdk
  echo         android:minSdkVersion="21"
  echo         android:targetSdkVersion="34" /^>
  echo ^</manifest^>
) > "%MANIFEST_FILE%" || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create AndroidManifest.xml!^[%NC%
    exit /b 1
)

:create_kotlin_wrapper
echo ^| Creating Kotlin wrapper class... ^|

set "KOTLIN_FILE1=%ROOT_DIR%\llama_mobile-android\src\main\java\com\llamamobile\LlamaMobile.kt"

set "file_created=true"
(
  echo package com.llamamobile
  echo.
  echo /**
  echo  * LlamaMobile Android Library
  echo  * 
  echo  * This class provides a Kotlin wrapper around the llama_mobile C library, 
  echo  * allowing Android applications to interact with llama models.
  echo  */
  echo object LlamaMobile {
  echo     
  echo     /**
  echo      * Cache type enum
  echo      */
  echo     enum class CacheType {
  echo         NONE,
  echo         MEMORY
  echo     }
  echo     
  echo     /**
  echo      * Initialization parameters for creating a llama context
  echo      * 
  echo      * @property modelPath Path to the llama model file
  echo      * @property nCtx Size of the context window (default: 512)
  echo      * @property chatTemplate Chat template to use (optional)
  echo      * @property cacheType Cache type to use (default: MEMORY)
  echo      */
  echo     data class InitParams(
  echo         val modelPath: String,
  echo         val nCtx: Int = 512,
  echo         val chatTemplate: String? = null,
  echo         val cacheType: CacheType = CacheType.MEMORY
  echo     )
  echo     
  echo     /**
  echo      * Completion parameters for generating text
  echo      * 
  echo      * @property prompt Input prompt for text generation
  echo      * @property temperature Temperature for sampling (default: 0.8)
  echo      * @property maxTokens Maximum number of tokens to generate (default: 100)
  echo      */
  echo     data class CompletionParams(
  echo         val prompt: String,
  echo         val temperature: Float = 0.8f,
  echo         val maxTokens: Int = 100
  echo     )
  echo     
  echo     /**
  echo      * Loads the native libraries
  echo      */
  echo     init {
  echo         System.loadLibrary("llama_mobile")
  echo         System.loadLibrary("llama_mobile_jni")
  echo     }
  echo     
  echo     /**
  echo      * Initializes a new llama context
  echo      * 
  echo      * @param params Initialization parameters
  echo      * @return Context handle, or 0 if initialization failed
  echo      */
  echo     external fun initContext(params: InitParams): Long
  echo     
  echo     /**
  echo      * Generates text completion
  echo      * 
  echo      * @param contextHandle Context handle obtained from initContext
  echo      * @param params Completion parameters
  echo      * @return Generated text, or null if generation failed
  echo      */
  echo     external fun generateCompletion(contextHandle: Long, params: CompletionParams): String?
  echo     
  echo     /**
  echo      * Releases a llama context
  echo      * 
  echo      * @param contextHandle Context handle obtained from initContext
  echo      */
  echo     external fun releaseContext(contextHandle: Long)
  echo }
) > "%KOTLIN_FILE1%" || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create Kotlin wrapper files!^[%NC%
    exit /b 1
)

:create_build_gradle
echo ^| Creating build.gradle for the library... ^|

set "BUILD_GRADLE_CONTENT=plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.llamamobile'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
            version "3.22.1"
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
"

set "BUILD_GRADLE_FILE=%ROOT_DIR%\llama_mobile-android\build.gradle"

>":"BUILD_GRADLE_FILE:" (
  echo plugins {
  echo     id 'com.android.library'
  echo     id 'org.jetbrains.kotlin.android'
  echo }
  echo.
  echo android {
  echo     namespace 'com.llamamobile'
  echo     compileSdk 34
  echo.
  echo     defaultConfig {
  echo         minSdk 21
  echo         targetSdk 34
  echo.
  echo         testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
  echo         consumerProguardFiles "consumer-rules.pro"
  echo     }
  echo.
  echo     buildTypes {
  echo         release {
  echo             minifyEnabled false
  echo             proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
  echo         }
  echo     }
  echo     compileOptions {
  echo         sourceCompatibility JavaVersion.VERSION_1_8
  echo         targetCompatibility JavaVersion.VERSION_1_8
  echo     }
  echo     kotlinOptions {
  echo         jvmTarget = '1.8'
  echo     }
  echo     externalNativeBuild {
  echo         cmake {
  echo             path "src/main/cpp/CMakeLists.txt"
  echo             version "3.22.1"
  echo         }
  echo     }
  echo }
  echo.
  echo dependencies {
  echo     implementation 'androidx.core:core-ktx:1.12.0'
  echo     implementation 'androidx.appcompat:appcompat:1.6.1'
  echo     testImplementation 'junit:junit:4.13.2'
  echo     androidTestImplementation 'androidx.test.ext:junit:1.1.5'
  echo     androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
  echo }
) || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create build.gradle!^[%NC%
    exit /b 1
)

:create_settings_gradle
echo -n Creating settings.gradle for the library... 

set "SETTINGS_GRADLE_CONTENT=pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "llama_mobile"
"

set "SETTINGS_GRADLE_FILE=%ROOT_DIR%\llama_mobile-android\settings.gradle"

>":"SETTINGS_GRADLE_FILE:" (
  echo pluginManagement {
  echo     repositories {
  echo         google()
  echo         mavenCentral()
  echo         gradlePluginPortal()
  echo     }
  echo }
  echo dependencyResolutionManagement {
  echo     repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  echo     repositories {
  echo         google()
  echo         mavenCentral()
  echo     }
  echo }
  echo rootProject.name = "llama_mobile"
)

echo ^| ^[%GREEN%✓^[%NC%

:finalize_sdk
echo.
echo ^| Making llama_mobile-Android-SDK self-contained... ^|

set "SDK_SRC_DIR=%ROOT_DIR%\llama_mobile-android"
set "SDK_DEST_DIR=%ROOT_DIR%\llama_mobile-Android-SDK"

echo ^| Ensuring SDK directories exist... ^|
set "dirs_to_create_sdk=%SDK_DEST_DIR%\src\main\jniLibs %SDK_DEST_DIR%\src\main\cpp %SDK_DEST_DIR%\src\main\java\com\llamamobile %SDK_DEST_DIR%\src\main\assets\grammars %SDK_DEST_DIR%\src\main"

set "all_created=true"
for %%d in (%dirs_to_create_sdk%) do (
    if not exist "%%d" (
        mkdir "%%d" >nul 2>&1 || set "all_created=false"
    )
)

if "!all_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create SDK directories!^[%NC%
    echo ^| Please check your permissions and try again.
    exit /b 1
)

echo ^| Copying main library files to SDK... ^|

set "all_copied=true"

:: Update SDK's CMakeLists.txt with correct project name
echo ^| Updating SDK CMakeLists.txt... ^|
set "SDK_CMAKE_CONTENT=cmake_minimum_required(VERSION 3.16)
project(llama_mobile_android_sdk LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add definitions
add_definitions(
    -DNDEBUG
    -DLM_GGML_USE_CPU
    -DLM_GGML_USE_OPENCL=OFF
    -DGGML_NO_POSIX_MADVISE
)

# Include directories
include_directories(
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu"
)

# Import the pre-built llama_mobile library
add_library(llama_mobile SHARED IMPORTED)
set_target_properties(llama_mobile PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
)

# Create a JNI wrapper
add_library(llama_mobile_jni SHARED
    llama_mobile_jni.cpp
)

# Link libraries
target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)
"

set "SDK_CMAKE_FILE=%SDK_DEST_DIR%\src\main\cpp\CMakeLists.txt"

set "file_created=true"
(
  echo cmake_minimum_required(VERSION 3.16)
  echo project(llama_mobile_android_sdk LANGUAGES CXX C)
  echo.
  echo set(CMAKE_CXX_STANDARD 20)
  echo set(CMAKE_CXX_STANDARD_REQUIRED ON)
  echo.
  echo # Add definitions
  echo add_definitions(
  echo     -DNDEBUG
  echo     -DLM_GGML_USE_CPU
  echo     -DLM_GGML_USE_OPENCL=OFF
  echo     -DGGML_NO_POSIX_MADVISE
  echo )
  echo.
  echo # Include directories
  echo include_directories(
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib"
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp"
  echo     "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../lib/llama_cpp/ggml-cpu"
  echo )
  echo.
  echo # Import the pre-built llama_mobile library
  echo add_library(llama_mobile SHARED IMPORTED)
  echo set_target_properties(llama_mobile PROPERTIES
  echo     IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}/libllama_mobile.so
  echo )
  echo.
  echo # Create a JNI wrapper
  echo add_library(llama_mobile_jni SHARED
  echo     llama_mobile_jni.cpp
  echo )
  echo.
  echo # Link libraries
  echo target_link_libraries(llama_mobile_jni PRIVATE llama_mobile)
) > "%SDK_CMAKE_FILE%" || set "file_created=false"

if "!file_created!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to update SDK CMakeLists.txt!^[%NC%
    exit /b 1
)

:: Copy JNI wrapper
copy "%SDK_SRC_DIR%\src\main\cpp\llama_mobile_jni.cpp" "%SDK_DEST_DIR%\src\main\cpp\llama_mobile_jni.cpp" >nul || set "all_copied=false"

:: Copy AndroidManifest.xml
copy "%SDK_SRC_DIR%\src\main\AndroidManifest.xml" "%SDK_DEST_DIR%\src\main\AndroidManifest.xml" >nul || set "all_copied=false"

:: Copy Kotlin wrapper
copy "%SDK_SRC_DIR%\src\main\java\com\llamamobile\LlamaMobile.kt" "%SDK_DEST_DIR%\src\main\java\com\llamamobile\LlamaMobile.kt" >nul || set "all_copied=false"

if "!all_copied!" == "true" (
    echo ^| ^[%GREEN%✓^[%NC%
) else (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to copy files to SDK!^[%NC%
    echo ^| Please check your permissions and try again.
    exit /b 1
)

:create_sdk_build_files
echo ^| Creating build files for SDK... ^|

:: Create build.gradle for SDK
set "SDK_BUILD_GRADLE_CONTENT=plugins {
    id 'com.android.library'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.llamamobile'
    compileSdk 34

    defaultConfig {
        minSdk 21
        targetSdk 34

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles "consumer-rules.pro"
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = '1.8'
    }
    externalNativeBuild {
        cmake {
            path "src/main/cpp/CMakeLists.txt"
            version "3.22.1"
        }
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
"

set "SDK_BUILD_GRADLE_FILE=%SDK_DEST_DIR%\build.gradle"

set "file_created=true"
(
  echo plugins {
  echo     id 'com.android.library'
  echo     id 'org.jetbrains.kotlin.android'
  echo }
  echo.
  echo android {
  echo     namespace 'com.llamamobile'
  echo     compileSdk 34
  echo.
  echo     defaultConfig {
  echo         minSdk 21
  echo         targetSdk 34
  echo.
  echo         testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
  echo         consumerProguardFiles "consumer-rules.pro"
  echo     }
  echo.
  echo     buildTypes {
  echo         release {
  echo             minifyEnabled false
  echo             proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
  echo         }
  echo     }
  echo     compileOptions {
  echo         sourceCompatibility JavaVersion.VERSION_1_8
  echo         targetCompatibility JavaVersion.VERSION_1_8
  echo     }
  echo     kotlinOptions {
  echo         jvmTarget = '1.8'
  echo     }
  echo     externalNativeBuild {
  echo         cmake {
  echo             path "src/main/cpp/CMakeLists.txt"
  echo             version "3.22.1"
  echo         }
  echo     }
  echo }
  echo.
  echo dependencies {
  echo     implementation 'androidx.core:core-ktx:1.12.0'
  echo     implementation 'androidx.appcompat:appcompat:1.6.1'
  echo     testImplementation 'junit:junit:4.13.2'
  echo     androidTestImplementation 'androidx.test.ext:junit:1.1.5'
  echo     androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
  echo }
) > "%SDK_BUILD_GRADLE_FILE%" || set "file_created=false"

if "!file_created!" == "false" (
    echo ^| ^[%RED%✗^[%NC%
    echo ^| ^[%RED%[FAIL] Failed to create SDK build.gradle!^[%NC%
    exit /b 1
)

:: Create settings.gradle for SDK
set "SDK_SETTINGS_GRADLE_FILE=%SDK_DEST_DIR%\settings.gradle"

(
  echo pluginManagement {
  echo     repositories {
  echo         google()
  echo         mavenCentral()
  echo         gradlePluginPortal()
  echo     }
  echo }
  echo dependencyResolutionManagement {
  echo     repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
  echo     repositories {
  echo         google()
  echo         mavenCentral()
  echo     }
  echo }
  echo rootProject.name = "llama_mobile_sdk"
) > "%SDK_SETTINGS_GRADLE_FILE%"

echo ^| ^[%GREEN%✓^[%NC%

echo.
echo ^[%GREEN%=== Android build completed successfully ===^[%NC%
echo ^[%GREEN%The llama_mobile Android library and SDK have been built successfully!^[%NC%
echo ^[%GREEN%Library: %ROOT_DIR%\llama_mobile-android^[%NC%
echo ^[%GREEN%SDK: %ROOT_DIR%\llama_mobile-Android-SDK^[%NC%

endlocal