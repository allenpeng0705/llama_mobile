#include "llama_mobile_ffi.h"
#include <iostream>
#include <string>
#include <filesystem>
#include <chrono>
#include <atomic>
#include <iomanip>
#include <sstream>
#include <unistd.h>

static const char* DEFAULT_BEARER_TOKEN = "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";

struct DownloadProgress {
    std::atomic<float> progress{0.0f};
    std::atomic<int64_t> downloaded_bytes{0};
    std::atomic<int64_t> total_bytes{0};
    std::string status;
    std::chrono::steady_clock::time_point start_time;
    std::chrono::steady_clock::time_point last_update;
};

std::string format_bytes(int64_t bytes) {
    const char* units[] = {"B", "KB", "MB", "GB"};
    int unit_index = 0;
    double size = static_cast<double>(bytes);
    
    while (size >= 1024.0 && unit_index < 3) {
        size /= 1024.0;
        unit_index++;
    }
    
    std::ostringstream oss;
    oss << std::fixed << std::setprecision(2) << size << " " << units[unit_index];
    return oss.str();
}

std::string format_duration(std::chrono::steady_clock::time_point start) {
    auto now = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - start).count();
    
    int seconds = duration / 1000;
    int minutes = seconds / 60;
    seconds = seconds % 60;
    
    std::ostringstream oss;
    if (minutes > 0) {
        oss << minutes << "m " << seconds << "s";
    } else {
        oss << seconds << "s";
    }
    return oss.str();
}

void display_progress_bar(float progress, int64_t downloaded_bytes, int64_t total_bytes, const std::string& status, std::chrono::steady_clock::time_point start) {
    int bar_width = 50;
    int filled = static_cast<int>(progress * bar_width);
    
    std::cout << "\r[";
    for (int i = 0; i < bar_width; i++) {
        if (i < filled) {
            std::cout << "=";
        } else if (i == filled) {
            std::cout << ">";
        } else {
            std::cout << " ";
        }
    }
    std::cout << "] " << std::fixed << std::setprecision(1) << progress * 100.0 << "% | " << status;
    
    if (total_bytes > 0) {
        std::cout << " | " << format_bytes(downloaded_bytes) << " / " << format_bytes(total_bytes);
    }
    
    std::cout << " | " << format_duration(start);
    std::cout << std::flush;
}

void test_download_progress_callback(float progress, const char* status, int64_t downloaded_bytes, int64_t total_bytes, void* user_data) {
    if (!user_data) return;
    
    DownloadProgress* progress_data = static_cast<DownloadProgress*>(user_data);
    progress_data->progress.store(progress);
    progress_data->downloaded_bytes.store(downloaded_bytes);
    progress_data->total_bytes.store(total_bytes);
    progress_data->status = status ? status : "";
    
    auto now = std::chrono::steady_clock::now();
    auto time_since_last_update = std::chrono::duration_cast<std::chrono::milliseconds>(now - progress_data->last_update).count();
    
    if (time_since_last_update >= 100 || progress >= 1.0f) {
        display_progress_bar(progress, downloaded_bytes, total_bytes, progress_data->status, progress_data->start_time);
        progress_data->last_update = now;
    }
}

bool download_from_huggingface(const std::string& repo_id, const std::string& filename, const std::string& destination_path, const std::string& bearer_token) {
    std::cout << "\n" << std::string(80, '=') << std::endl;
    std::cout << "Download from Hugging Face" << std::endl;
    std::cout << std::string(80, '=') << std::endl;
    std::cout << "Repository: " << repo_id << std::endl;
    std::cout << "File: " << filename << std::endl;
    std::cout << "Destination: " << destination_path << std::endl;
    std::cout << std::endl;
    
    DownloadProgress progress_data;
    progress_data.start_time = std::chrono::steady_clock::now();
    progress_data.last_update = progress_data.start_time;
    
    llama_mobile_download_params_c_t params;
    params.repo_id = repo_id.c_str();
    params.filename = filename.c_str();
    params.destination_path = destination_path.c_str();
    params.bearer_token = bearer_token.empty() ? nullptr : bearer_token.c_str();
    params.offline = false;
    params.progress_callback = test_download_progress_callback;
    params.progress_callback_user_data = &progress_data;
    
    llama_mobile_download_result_c_t result = llama_mobile_download_model_c(&params);
    
    std::cout << std::endl;
    
    if (result.success) {
        std::cout << "Local path: " << (result.local_path ? result.local_path : "null") << std::endl;
        std::cout << "File size: " << format_bytes(result.file_size) << std::endl;
        std::cout << "Duration: " << format_duration(progress_data.start_time) << std::endl;
        
        if (std::filesystem::exists(result.local_path)) {
            std::cout << "File verified: YES" << std::endl;
        } else {
            std::cout << "File verified: NO (file not found)" << std::endl;
        }
    } else {
        std::cout << "Error message: " << (result.error_message ? result.error_message : "null") << std::endl;
    }
    
    llama_mobile_free_download_result_c(&result);
    std::cout << std::string(80, '=') << std::endl;
    
    return result.success;
}

bool download_from_url(const std::string& url, const std::string& filename, const std::string& destination_path, const std::string& bearer_token) {
    std::cout << "\n" << std::string(80, '=') << std::endl;
    std::cout << "Download from URL" << std::endl;
    std::cout << std::string(80, '=') << std::endl;
    std::cout << "URL: " << url << std::endl;
    std::cout << "File: " << filename << std::endl;
    std::cout << "Destination: " << destination_path << std::endl;
    std::cout << std::endl;
    
    DownloadProgress progress_data;
    progress_data.start_time = std::chrono::steady_clock::now();
    progress_data.last_update = progress_data.start_time;
    
    llama_mobile_download_params_c_t params;
    params.repo_id = url.c_str();
    params.filename = filename.c_str();
    params.destination_path = destination_path.c_str();
    params.bearer_token = bearer_token.empty() ? nullptr : bearer_token.c_str();
    params.offline = false;
    params.progress_callback = test_download_progress_callback;
    params.progress_callback_user_data = &progress_data;
    
    llama_mobile_download_result_c_t result = llama_mobile_download_model_c(&params);
    
    std::cout << std::endl;
    
    if (result.success) {
        std::cout << "Local path: " << (result.local_path ? result.local_path : "null") << std::endl;
        std::cout << "File size: " << format_bytes(result.file_size) << std::endl;
        std::cout << "Duration: " << format_duration(progress_data.start_time) << std::endl;
        
        if (std::filesystem::exists(result.local_path)) {
            std::cout << "File verified: YES" << std::endl;
        } else {
            std::cout << "File verified: NO (file not found)" << std::endl;
        }
    } else {
        std::cout << "Error message: " << (result.error_message ? result.error_message : "null") << std::endl;
    }
    
    llama_mobile_free_download_result_c(&result);
    std::cout << std::string(80, '=') << std::endl;
    
    return result.success;
}

std::string get_current_directory() {
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) != nullptr) {
        return std::string(cwd);
    }
    return ".";
}

void print_usage(const char* program_name) {
    std::cout << "\nUsage: " << program_name << " [OPTION]" << std::endl;
    std::cout << "\nDownload files using Llama Mobile Download API" << std::endl;
    std::cout << "\nOptions:" << std::endl;
    std::cout << "  --hf" << std::endl;
    std::cout << "      Download from Hugging Face (pre-configured model)" << std::endl;
    std::cout << "      Repo: microsoft/Phi-3-mini-4k-instruct-gguf" << std::endl;
    std::cout << "      File: Phi-3-mini-4k-instruct-q4.gguf" << std::endl;
    std::cout << std::endl;
    std::cout << "  --url" << std::endl;
    std::cout << "      Download from direct URL (pre-configured)" << std::endl;
    std::cout << std::endl;
    std::cout << "  --help, -h" << std::endl;
    std::cout << "      Show this help message" << std::endl;
    std::cout << "\nExamples:" << std::endl;
    std::cout << "  " << program_name << " --hf" << std::endl;
    std::cout << "  " << program_name << " --url" << std::endl;
    std::cout << std::endl;
}

void show_menu() {
    std::cout << "\n" << std::string(80, '=') << std::endl;
    std::cout << "Llama Mobile Download Test" << std::endl;
    std::cout << std::string(80, '=') << std::endl;
    std::cout << "\nSelect download option:" << std::endl;
    std::cout << "\n  [1] Download from Hugging Face" << std::endl;
    std::cout << "      Repo: microsoft/Phi-3-mini-4k-instruct-gguf" << std::endl;
    std::cout << "      File: Phi-3-mini-4k-instruct-q4.gguf" << std::endl;
    std::cout << "\n  [2] Download from direct URL" << std::endl;
    std::cout << "      URL: https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf" << std::endl;
    std::cout << "\n  [q] Quit" << std::endl;
    std::cout << "\n" << std::string(80, '=') << std::endl;
    std::cout << "Enter your choice [1-2, q]: ";
}

int main(int argc, char** argv) {
    std::string destination_path = get_current_directory();
    std::string bearer_token = DEFAULT_BEARER_TOKEN;
    
    bool success = false;
    
    if (argc == 2) {
        std::string arg = argv[1];
        
        if (arg == "--hf") {
            success = download_from_huggingface(
                "microsoft/Phi-3-mini-4k-instruct-gguf",
                "Phi-3-mini-4k-instruct-q4.gguf",
                destination_path,
                bearer_token
            );
        }
        else if (arg == "--url") {
            success = download_from_url(
                "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
                "Phi-3-mini-4k-instruct-q4.gguf",
                destination_path,
                bearer_token
            );
        }
        else if (arg == "--help" || arg == "-h") {
            print_usage(argv[0]);
            return 0;
        }
        else {
            std::cerr << "Error: Unknown option '" << arg << "'" << std::endl;
            print_usage(argv[0]);
            return 1;
        }
    }
    else {
        show_menu();
        std::string choice;
        std::cin >> choice;
        
        if (choice == "1") {
            success = download_from_huggingface(
                "microsoft/Phi-3-mini-4k-instruct-gguf",
                "Phi-3-mini-4k-instruct-q4.gguf",
                destination_path,
                bearer_token
            );
        }
        else if (choice == "2") {
            success = download_from_url(
                "https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf",
                "Phi-3-mini-4k-instruct-q4.gguf",
                destination_path,
                bearer_token
            );
        }
        else if (choice == "q" || choice == "Q") {
            std::cout << "Exiting..." << std::endl;
            return 0;
        }
        else {
            std::cerr << "Invalid choice. Exiting..." << std::endl;
            return 1;
        }
    }
    
    if (success) {
        std::cout << "\nDownload completed successfully!" << std::endl;
        return 0;
    } else {
        return 1;
    }
}
