#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

#include "../llama_mobile_api.h"

namespace fs = std::filesystem;

// Helper function to get executable directory
std::string get_executable_dir() {
    char buffer[1024];
    std::string path;
    
#if defined(__linux__)
    ssize_t len = readlink("/proc/self/exe", buffer, sizeof(buffer) - 1);
    if (len != -1) {
        buffer[len] = '\0';
        path = buffer;
    }
#elif defined(__APPLE__)
    uint32_t size = sizeof(buffer);
    if (_NSGetExecutablePath(buffer, &size) == 0) {
        buffer[size] = '\0';
        path = buffer;
        // Resolve symlinks if needed
        char resolved_path[1024];
        if (realpath(path.c_str(), resolved_path) != nullptr) {
            path = resolved_path;
        }
    }
#endif
    
    if (!path.empty()) {
        size_t last_slash = path.find_last_of("/");
        if (last_slash != std::string::npos) {
            return path.substr(0, last_slash);
        }
    }
    return "";
}

std::vector<std::string> find_gguf_models(const std::string& directory) {
    std::vector<std::string> models;
    
    try {
        for (const auto& entry : fs::directory_iterator(directory)) {
            if (entry.is_regular_file() && entry.path().extension() == ".gguf") {
                models.push_back(entry.path().string());
            }
        }
    } catch (const fs::filesystem_error& e) {
        std::cerr << "Error accessing models directory: " << e.what() << std::endl;
    }
    
    return models;
}

std::string select_model() {
    // Determine models directory relative to executable location
    std::string executable_dir = get_executable_dir();
    std::string models_dir = executable_dir + "/../../models";
    std::vector<std::string> models = find_gguf_models(models_dir);
    
    if (models.empty()) {
        std::cerr << "No .gguf models found in " << models_dir << std::endl;
        return "";
    }
    
    std::cout << "Available models:\n";
    for (size_t i = 0; i < models.size(); ++i) {
        std::cout << "[" << i + 1 << "] " << fs::path(models[i]).filename() << std::endl;
    }
    
    int choice;
    while (true) {
        std::cout << "\nSelect a model (1-" << models.size() << "): ";
        std::cin >> choice;
        
        if (choice >= 1 && choice <= static_cast<int>(models.size())) {
            break;
        }
        
        std::cout << "Invalid choice. Please try again.\n";
        std::cin.clear();
        std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');
    }
    
    return models[choice - 1];
}

// Streaming token callback function
bool token_callback(const char* token) {
    if (token && token[0] != '\0') {
        std::cout << token;
        std::cout.flush();  // Ensure immediate output
    }
    return true;  // Continue generation
}

int main(int argc, char* argv[]) {
    std::cout << "=== Llama Mobile Chat Example with Streaming ===\n";
    
    // Select model - either from command line or interactive selection
    std::string model_path;
    if (argc > 1) {
        model_path = argv[1];
        std::cout << "Using model from command line: " << fs::path(model_path).filename() << std::endl;
    } else {
        model_path = select_model();
        if (model_path.empty()) {
            return 1;
        }
    }
    
    std::cout << "\nLoading model: " << fs::path(model_path).filename() << std::endl;
    
    // Initialize Llama Mobile
    llama_mobile_context_t ctx = llama_mobile_init_simple(
        model_path.c_str(),
        2048,    // n_ctx
        20,      // n_gpu_layers (enable GPU)
        4,       // n_threads
        nullptr  // progress_callback
    );
    
    if (ctx == nullptr) {
        std::cerr << "Failed to initialize Llama Mobile" << std::endl;
        return 1;
    }
    
    std::cout << "Model loaded successfully!\n\n";
    
    // Build conversation history
    std::string conversation_history = "";
    
    std::string user_input;
    std::cout << "Type 'quit' or 'exit' to end the chat.\n";
    
    try {
        while (true) {
            // Get user input
            std::cout << "\nYou: ";
            
            // Clear any previous error flags
            std::cin.clear();
            
            // Ignore newline from previous input only if we're not at the end
            if (!std::cin.eof() && std::cin.peek() == '\n') {
                std::cin.ignore();
            }
            
            if (!std::getline(std::cin, user_input)) {
                // Handle EOF or input error
                if (std::cin.eof()) {
                    std::cout << "\n[EOF received, ending chat]" << std::endl;
                } else {
                    std::cerr << "\n[Error reading input]" << std::endl;
                }
                break;
            }
            
            if (user_input == "quit" || user_input == "exit") {
                break;
            }
            
            if (user_input.empty()) {
                std::cout << "Please enter a non-empty message." << std::endl;
                continue;
            }
            
            // Build the conversation prompt
            if (conversation_history.empty()) {
                // First interaction - add system prompt
                conversation_history = "<system>You are a helpful assistant. Respond naturally to user queries.</system>\n";
            }
            conversation_history += "<user>" + user_input + "</user>\n<assistant>";
            
            // Generate response with streaming
            std::cout << "\nAssistant: ";
            std::cout.flush();
            
            // Use completion with streaming
            llama_mobile_completion_result_t result;
            int status = llama_mobile_completion_simple(
                ctx,
                conversation_history.c_str(),
                200,  // max_tokens
                0.8,  // temperature
                token_callback,  // streaming callback
                &result
            );
            
            std::cout << std::endl;  // Add newline after streaming completes
            
            if (status == 0) {
                if (result.text) {
                    // Append the full response to conversation history
                    conversation_history += result.text;
                    conversation_history += "</assistant>\n";
                    llama_mobile_free_string(result.text);
                } else {
                    std::cerr << "[No response generated]" << std::endl;
                }
            } else {
                std::cerr << "[Failed to generate response (status: " << status << ")]" << std::endl;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "\n[Unexpected error: " << e.what() << "]" << std::endl;
    } catch (...) {
        std::cerr << "\n[Unknown error occurred]" << std::endl;
    }
    
    // Cleanup
    llama_mobile_free(ctx);
    
    std::cout << "\nChat ended. Goodbye!\n";
    
    return 0;
}
