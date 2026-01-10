#include "llama_mobile_ffi.h"
#include <iostream>
#include <string>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <chrono>

// Define mkdtemp if not available (for Windows compatibility)
#ifdef _WIN32
#include <windows.h>
#include <direct.h>
#define mkdtemp _mktemp
#else
#include <unistd.h>
#endif

// Test progress callback function
void test_download_progress_callback(float progress, const char* status, int64_t downloaded_bytes, int64_t total_bytes) {
    std::cout << "[Progress] " << status << " - " 
              << (progress * 100.0) << "% complete";
    
    if (total_bytes > 0) {
        std::cout << " (" << downloaded_bytes / (1024 * 1024) << " MB / " 
                  << total_bytes / (1024 * 1024) << " MB)";
    }
    
    std::cout << std::endl;
}

// Test helper function to create temporary directory
std::string create_temp_dir() {
    // Use C++17 filesystem to create a temporary directory
    std::filesystem::path temp_path = std::filesystem::temp_directory_path();
    temp_path /= "llama_mobile_test_";
    
    try {
        // Create unique temporary directory
        std::filesystem::path temp_dir = std::filesystem::temp_directory_path() / 
            ("llama_mobile_test_" + std::to_string(std::chrono::system_clock::now().time_since_epoch().count()));
        
        std::filesystem::create_directories(temp_dir);
        return temp_dir.string();
    } catch (const std::exception& e) {
        std::cerr << "Failed to create temporary directory: " << e.what() << std::endl;
        exit(1);
    }
}

// Test download model function
void test_download_model() {
    std::cout << "=== Testing llama_mobile_download_model_c ===" << std::endl;
    
    // Create temporary directory
    std::string temp_dir = create_temp_dir();
    std::cout << "Using temporary directory: " << temp_dir << std::endl;
    
    // Prepare download parameters with progress callback
    llama_mobile_download_params_c_t params;
    params.repo_id = "jartine/TinyLlama-1.1B-Chat-v0.4-GGUF";
    params.filename = "tinyllama-1.1b-chat-v0.4.Q2_K.gguf";
    params.destination_path = temp_dir.c_str();
    params.bearer_token = nullptr;
    params.offline = false;
    params.progress_callback = test_download_progress_callback;
    
    // Call download function
    llama_mobile_download_result_c_t result = llama_mobile_download_model_c(&params);
    
    // Check results
    std::cout << "Download result: " << (result.success ? "SUCCESS" : "FAILED") << std::endl;
    if (result.success) {
        std::cout << "Local path: " << (result.local_path ? result.local_path : "null") << std::endl;
        std::cout << "File size: " << result.file_size << " bytes" << std::endl;
    } else {
        std::cout << "Error message: " << (result.error_message ? result.error_message : "null") << std::endl;
    }
    
    // Clean up
    llama_mobile_free_download_result_c(&result);
    
    std::cout << "=== Test completed ===" << std::endl << std::endl;
}

// Test download HF file function
void test_download_hf_file() {
    std::cout << "=== Testing llama_mobile_download_hf_file_c ===" << std::endl;
    
    // Create temporary directory
    std::string temp_dir = create_temp_dir();
    std::cout << "Using temporary directory: " << temp_dir << std::endl;
    
    // Call download function with progress callback
    llama_mobile_download_result_c_t result = llama_mobile_download_hf_file_c(
        "jartine/TinyLlama-1.1B-Chat-v0.4-GGUF",
        "tinyllama-1.1b-chat-v0.4.Q2_K.gguf",
        temp_dir.c_str(),
        nullptr,
        false,
        test_download_progress_callback
    );
    
    // Check results
    std::cout << "Download result: " << (result.success ? "SUCCESS" : "FAILED") << std::endl;
    if (result.success) {
        std::cout << "Local path: " << (result.local_path ? result.local_path : "null") << std::endl;
        std::cout << "File size: " << result.file_size << " bytes" << std::endl;
    } else {
        std::cout << "Error message: " << (result.error_message ? result.error_message : "null") << std::endl;
    }
    
    // Clean up
    llama_mobile_free_download_result_c(&result);
    
    std::cout << "=== Test completed ===" << std::endl << std::endl;
}

// Test error handling
void test_error_handling() {
    std::cout << "=== Testing error handling ===" << std::endl;
    
    // Test with null params
    std::cout << "Test 1: Null download parameters" << std::endl;
    llama_mobile_download_result_c_t result1 = llama_mobile_download_model_c(nullptr);
    std::cout << "Result: " << (result1.success ? "SUCCESS" : "FAILED") << std::endl;
    std::cout << "Error: " << (result1.error_message ? result1.error_message : "none") << std::endl;
    llama_mobile_free_download_result_c(&result1);
    
    // Test with missing filename
    std::cout << "\nTest 2: Missing filename parameter" << std::endl;
    llama_mobile_download_params_c_t params;
    params.repo_id = "some/repo";
    params.filename = nullptr;  // Missing required parameter
    params.destination_path = "/tmp";
    params.bearer_token = nullptr;
    params.offline = false;
    params.progress_callback = nullptr;
    
    llama_mobile_download_result_c_t result2 = llama_mobile_download_model_c(&params);
    std::cout << "Result: " << (result2.success ? "SUCCESS" : "FAILED") << std::endl;
    std::cout << "Error: " << (result2.error_message ? result2.error_message : "none") << std::endl;
    llama_mobile_free_download_result_c(&result2);
    
    std::cout << "=== Error handling tests completed ===" << std::endl << std::endl;
}

int main() {
    // Note: Comment out actual download tests if you don't want to download files
    // test_download_model();
    // test_download_hf_file();
    test_error_handling();
    
    std::cout << "All tests completed!" << std::endl;
    return 0;
}
