#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>
#include <fstream>
#include <sstream>
#include <random>
#include <iomanip>
#include <chrono>
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

#include "../llama_mobile_api.h"

using namespace std;
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
bool token_callback(const char* token, void* user_data) {
    if (token && token[0] != '\0') {
        std::cout << token;
        std::cout.flush();  // Ensure immediate output
    }
    return true;  // Continue generation
}

// Helper function to check for key press without blocking
int kbhit() {
    struct termios oldt, newt;
    int ch;
    int oldf;

    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);

    ch = getchar();

    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    fcntl(STDIN_FILENO, F_SETFL, oldf);

    if(ch != EOF) {
        ungetc(ch, stdin);
        return 1;
    }

    return 0;
}

// Helper function to getch
int getch() {
    struct termios oldt, newt;
    int ch;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    ch = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    return ch;
}

int main(int argc, char* argv[]) {
    std::cout << "=== Llama Mobile Conversation Test ===\n";
    std::cout << "Test the conversation API features\n";
    std::cout << "Commands:\n";
    std::cout << "  Type messages to continue the conversation\n";
    std::cout << "  Ctrl+K: Clear the current conversation\n";
    std::cout << "  Ctrl+I: Check if conversation is active\n";
    std::cout << "  Type 'quit' or 'exit' to end the test\n";
    
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
    llama_mobile_init_params_t params = {0};
    params.model_path = model_path.c_str();
    params.n_ctx = 2048;
    params.n_gpu_layers = 20;
    params.n_threads = 4;
    params.progress_callback = nullptr;
    params.embedding = false;
    params.use_mmap = true;
    params.n_batch = 512;
    params.enable_chat_template = true;
    
    llama_mobile_context_t ctx = llama_mobile_init(&params);
    
    if (ctx == nullptr) {
        std::cerr << "Failed to initialize Llama Mobile" << std::endl;
        return 1;
    }
    
    std::cout << "Model loaded successfully!\n\n";
    std::cout << "Conversation started. Type your first message:\n\n";
    
    std::string user_input;
    
    try {
        while (true) {
            // Check for keyboard shortcuts
            if (kbhit()) {
                int c = getch();
                
                // Check for Ctrl+K (clear conversation)
                if (c == 11) {  // ASCII for Ctrl+K
                    std::cout << "\n=== Clearing conversation ===\n";
                    llama_mobile_clear_conversation(ctx);
                    std::cout << "Conversation cleared. New conversation started.\n\n";
                    continue;
                }
                
                // Check for Ctrl+I (check conversation status)
                if (c == 9) {  // ASCII for Ctrl+I
                    // Check conversation status by trying a simple query
                    // Note: There's no direct API for is_conversation_active in corelib
                    // So we'll test by checking if a new conversation starts fresh
                    std::cout << "\n=== Checking conversation status ===\n";
                    
                    // Try a simple test message
                    llama_mobile_conversation_result_t test_result;
                    int status = llama_mobile_generate_response(
                        ctx,
                        "Hello",
                        50,
                        nullptr,  // No callback for this test
                        nullptr,
                        &test_result
                    );
                    
                    if (status == 0 && test_result.text) {
                        std::string response = test_result.text;
                        llama_mobile_free_conversation_result(&test_result);
                        
                        // If response is a typical greeting, conversation is active
                        if (response.find("Hello") != std::string::npos || 
                            response.find("hi") != std::string::npos ||
                            response.find("Hey") != std::string::npos) {
                            std::cout << "Conversation is active.\n";
                        } else {
                            std::cout << "Conversation status: A response was generated.\n";
                        }
                    } else {
                        std::cout << "Conversation status: Failed to generate test response.\n";
                    }
                    
                    std::cout << "=== Status check complete ===\n\n";
                    continue;
                }
            }
            
            // Get user input
            std::cout << "You: ";
            std::getline(std::cin, user_input);
            
            if (user_input == "quit" || user_input == "exit") {
                break;
            }
            
            if (user_input.empty()) {
                std::cout << "Please enter a non-empty message.\n";
                continue;
            }
            
            // Generate response
            std::cout << "Assistant: ";
            std::cout.flush();
            
            llama_mobile_conversation_result_t result;
            int status = llama_mobile_generate_response(
                ctx,
                user_input.c_str(),
                200,  // Max tokens
                token_callback,  // Use streaming callback
                nullptr,
                &result
            );
            
            std::cout << std::endl;
            
            if (status == 0) {
                if (result.text) {
                    // We already displayed the response via streaming
                    llama_mobile_free_conversation_result(&result);
                } else {
                    std::cerr << "[No response generated]" << std::endl;
                }
            } else {
                std::cerr << "[Failed to generate response (status: " << status << ")]" << std::endl;
            }
            
            std::cout << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "\n[Unexpected error: " << e.what() << "]" << std::endl;
    }
    
    // Cleanup
    llama_mobile_free(ctx);
    
    std::cout << "\nConversation test ended. Goodbye!\n";
    
    return 0;
}
