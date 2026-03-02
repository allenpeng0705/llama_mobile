#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <fstream>
#include <sstream>
#include <random>
#include <iomanip>
#include <chrono>
#if defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

#include "../llama_mobile_api.h"
#include "../llama.cpp-master/vendor/nlohmann/json.hpp"

using json = nlohmann::json;

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

// Helper function to parse input (either plain text or JSON)
bool parse_input(const std::string& input, std::string& prompt, llama_mobile_completion_params_t& params) {
    // Initialize default values
    params = {0};
    params.prompt = nullptr;
    params.n_predict = 200;
    params.temperature = 0.8;
    params.top_k = 40;
    params.top_p = 0.95;
    params.min_p = 0.05;
    params.typical_p = 1.0;
    params.penalty_last_n = 64;
    params.penalty_repeat = 1.1;
    params.penalty_freq = 0.0;
    params.penalty_present = 0.0;
    params.mirostat = 0;
    params.mirostat_tau = 5.0;
    params.mirostat_eta = 0.1;
    params.ignore_eos = false;
    // Set default stop sequences to prevent model from generating additional conversation turns
    // Include more comprehensive patterns to handle different whitespace and model-specific behaviors
    static const char* default_stop_sequences[] = {
        "\n\n", "<|im_end|>", "<|endoftext|>",
        "\nUser:", "User:", "\n\tUser:", "\tUser:",
        "\nAssistant:", "Assistant:", "\n\tAssistant:", "\tAssistant:",
        "\nHuman:", "Human:", "\nSystem:", "System:",
        "\nBot:", "Bot:", "\nAI:", "AI:"
    };
    params.stop_sequences = default_stop_sequences;
    params.stop_sequence_count = 18;
    params.grammar = nullptr;
    params.use_json_response = true;
    params.token_callback = nullptr;

    // Check if input is likely JSON (starts with '{' and ends with '}')
    if (!input.empty() && input.front() == '{' && input.back() == '}') {
        try {
            // Parse as JSON
            json input_json = json::parse(input);

            // Extract prompt
            if (input_json.contains("prompt")) {
                prompt = input_json["prompt"].get<std::string>();
            } else if (input_json.contains("messages")) {
                // Handle chat completion format
                std::vector<json> messages = input_json["messages"].get<std::vector<json>>();
                std::stringstream ss;
                for (const auto& msg : messages) {
                    std::string role = msg["role"].get<std::string>();
                    std::string content = msg["content"].get<std::string>();
                    ss << role << ": " << content << "\n";
                }
                ss << "Assistant: ";
                prompt = ss.str();
            } else {
                std::cerr << "Error: JSON input must contain either 'prompt' or 'messages' field" << std::endl;
                return false;
            }

            // Extract optional parameters
            if (input_json.contains("max_tokens")) {
                params.n_predict = input_json["max_tokens"].get<int32_t>();
            }
            if (input_json.contains("temperature")) {
                params.temperature = input_json["temperature"].get<double>();
            }
            if (input_json.contains("top_k")) {
                params.top_k = input_json["top_k"].get<int32_t>();
            }
            if (input_json.contains("top_p")) {
                params.top_p = input_json["top_p"].get<double>();
            }
            if (input_json.contains("min_p")) {
                params.min_p = input_json["min_p"].get<double>();
            }
            if (input_json.contains("frequency_penalty")) {
                params.penalty_freq = input_json["frequency_penalty"].get<double>();
            }
            if (input_json.contains("presence_penalty")) {
                params.penalty_present = input_json["presence_penalty"].get<double>();
            }
            if (input_json.contains("repeat_penalty")) {
                params.penalty_repeat = input_json["repeat_penalty"].get<double>();
            }
            if (input_json.contains("stop")) {
                // Handle stop parameter (could be string or array)
                if (input_json["stop"].is_array()) {
                    std::vector<std::string> stop_strings = input_json["stop"].get<std::vector<std::string>>();
                    if (!stop_strings.empty()) {
                        // Allocate memory for stop sequences
                        const char** stop_array = new const char*[stop_strings.size()];
                        for (size_t i = 0; i < stop_strings.size(); ++i) {
                            stop_array[i] = stop_strings[i].c_str();
                        }
                        params.stop_sequences = stop_array;
                        params.stop_sequence_count = static_cast<int>(stop_strings.size());
                    }
                } else if (input_json["stop"].is_string()) {
                    std::string stop_string = input_json["stop"].get<std::string>();
                    if (!stop_string.empty()) {
                        // Allocate memory for single stop sequence
                        const char** stop_array = new const char*[1];
                        stop_array[0] = stop_string.c_str();
                        params.stop_sequences = stop_array;
                        params.stop_sequence_count = 1;
                    }
                }
            }

            return true;
        } catch (const json::parse_error& e) {
            std::cerr << "Error parsing JSON input: " << e.what() << std::endl;
            return false;
        } catch (const std::exception& e) {
            std::cerr << "Error processing JSON input: " << e.what() << std::endl;
            return false;
        }
    } else {
        // Treat as plain text prompt
        prompt = "You are a helpful assistant. User: " + input + " Assistant: ";
        return true;
    }
}

// Helper function to free stop sequences allocated during parsing
void free_stop_sequences(llama_mobile_completion_params_t& params) {
    // No need to free default stop sequences (they're static)
    // Only delete if stop_sequence_count is positive and not our default count
    if (params.stop_sequences && params.stop_sequence_count != 18 && params.stop_sequence_count != 40) {
        delete[] params.stop_sequences;
        params.stop_sequences = nullptr;
    }
}

int main(int argc, char* argv[]) {
    std::cout << "=== Llama Mobile Chat Example with OpenAI-compatible JSON Input ===\n";
    std::cout << "Enter text (plain or JSON format, type 'quit' or 'exit' to end):\n";
    
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
    
    llama_mobile_context_t ctx = llama_mobile_init(&params);
    
    if (ctx == nullptr) {
        std::cerr << "Failed to initialize Llama Mobile" << std::endl;
        return 1;
    }
    
    std::cout << "Model loaded successfully!\n\n";
    
    // Build conversation history as structured messages
    struct ChatMessage {
        std::string role;
        std::string content;
    };
    
    std::vector<ChatMessage> chat_history;
    
    // Default system prompt
    ChatMessage system_msg = {"system", "You are a helpful assistant."};
    chat_history.push_back(system_msg);
    
    std::string user_input;
    std::cout << "Type 'quit' or 'exit' to end the chat.\n";
    
    try {
        while (true) {
            // Get user input
            std::cout << "\nInput: ";
            
            // Clear any previous error flags
            std::cin.clear();
            
            // Ignore newline from previous input only if we're not at the end
            if (!std::cin.eof() && std::cin.peek() == '\n') {
                std::cin.ignore();
            }
            
            // Read first line
            if (!std::getline(std::cin, user_input)) {
                // Handle EOF or input error
                if (std::cin.eof()) {
                    std::cout << "\n[EOF received, ending chat]" << std::endl;
                } else {
                    std::cerr << "\n[Error reading input]" << std::endl;
                }
                break;
            }
            
            // If input starts with '{', continue reading until we get a matching '}'
            if (!user_input.empty() && user_input.front() == '{') {
                int brace_count = 1;
                for (char c : user_input) {
                    if (c == '{') brace_count++;
                    if (c == '}') brace_count--;
                }
                
                // Continue reading until we have balanced braces
                std::string line;
                while (brace_count > 1 && std::getline(std::cin, line)) {
                    if (line == "quit" || line == "exit") {
                        brace_count = 0;
                        user_input.clear();
                        break;
                    }
                    user_input += "\n" + line;
                    for (char c : line) {
                        if (c == '{') brace_count++;
                        if (c == '}') brace_count--;
                    }
                }
            }
            
            if (user_input == "quit" || user_input == "exit") {
                break;
            }
            
            if (user_input.empty()) {
                std::cout << "Please enter a non-empty message." << std::endl;
                continue;
            }
            
            std::string prompt;
            llama_mobile_completion_params_t params;
            
            // Handle input - either JSON or plain text
            bool is_json_input = !user_input.empty() && user_input.front() == '{' && user_input.back() == '}';
            
            if (is_json_input) {
                // Parse JSON input
                if (!parse_input(user_input, prompt, params)) {
                    std::cout << "Failed to parse input. Please try again." << std::endl;
                    continue;
                }
                
                // Update chat history from JSON messages
                try {
                    json input_json = json::parse(user_input);
                    if (input_json.contains("messages")) {
                        std::vector<json> messages = input_json["messages"].get<std::vector<json>>();
                        chat_history.clear();
                        for (const auto& msg : messages) {
                            ChatMessage chat_msg;
                            chat_msg.role = msg["role"].get<std::string>();
                            chat_msg.content = msg["content"].get<std::string>();
                            chat_history.push_back(chat_msg);
                        }
                    }
                } catch (...) {
                    // Ignore JSON parsing errors for history update - we already handled the prompt parsing
                }
            } else {
                // Plain text input - add to chat history
                ChatMessage user_msg = {"user", user_input};
                chat_history.push_back(user_msg);
                
                // Format prompt from chat history
                std::stringstream ss;
                for (const auto& msg : chat_history) {
                    ss << msg.role << ": " << msg.content << "\n";
                }
                ss << "Assistant: ";
                prompt = ss.str();
                
                // Set default params for plain text input
                params = {0};
                params.n_predict = 200;
                params.temperature = 0.8;
                params.top_k = 40;
                params.top_p = 0.95;
                params.min_p = 0.05;
                params.typical_p = 1.0;
                params.penalty_last_n = 64;
                params.penalty_repeat = 1.1;
                params.penalty_freq = 0.0;
                params.penalty_present = 0.0;
                params.mirostat = 0;
                params.mirostat_tau = 5.0;
                params.mirostat_eta = 0.1;
                params.ignore_eos = false;
                
                // Use the comprehensive default stop sequences
                static const char* default_stop_sequences[] = {
                    "\n\n", "<|im_end|>", "<|endoftext|>",
                    "\nUser:", "User:", "\n\tUser:", "\tUser:",
                    "\nAssistant:", "Assistant:", "\n\tAssistant:", "\tAssistant:",
                    "\nHuman:", "Human:", "\nSystem:", "System:",
                    "\nBot:", "Bot:", "\nAI:", "AI:",
                    "\nuser:", "user:", "\n\tuser:", "\tuser:",
                    "\nassistant:", "assistant:", "\n\tassistant:", "\tassistant:",
                    "\nlife purpose", "\nThe user's message", "\nThe assistant's response",
                    "\nOkay, let me", "\nI will follow", "\nIn the previous example",
                    "\nIn this case", "\nHowever, in", "\nNow, the user",
                    "\nSince there's", "\nThe current user input",
                    "\nThe assistant should", "\nLooking at the response",
                    "\n谢谢你提问", "\n当然，每个生命", "\n你也可以思考"
                };
                params.stop_sequences = default_stop_sequences;
                params.stop_sequence_count = 40;
                params.grammar = nullptr;
                params.use_json_response = true;
                params.token_callback = nullptr;
            }
            
            // Set the prompt
            params.prompt = prompt.c_str();
            
            // Print raw input details
            std::cout << "\n=== RAW INPUT DETAILS ===" << std::endl;
            std::cout << "Input: " << user_input << std::endl;
            
            // Print JSON input format (even for plain text)
            json input_json;
            input_json["model"] = "qwen3 1.7B Q4_K - Medium";
            json messages = json::array();
            for (const auto& msg : chat_history) {
                json message;
                message["role"] = msg.role;
                message["content"] = msg.content;
                messages.push_back(message);
            }
            input_json["messages"] = messages;
            std::cout << "JSON Input Format: " << input_json.dump(2) << std::endl;
            
            std::cout << "Processed prompt: " << prompt << std::endl;
            
            // Generate response
            std::cout << "\nGenerating response..." << std::endl;
            std::cout << "Response: ";
            std::cout.flush();
            
            llama_mobile_completion_result_t result;
            int status = llama_mobile_completion(ctx, &params, &result);
            
            // Print the complete result
            std::cout << std::endl;
            
            // Print raw output details
            std::cout << "=== RAW OUTPUT DETAILS ===" << std::endl;
            std::cout << "Status: " << status << std::endl;
            if (status == 0 && result.text) {
                std::cout << "JSON Output: " << result.text << std::endl;
            } else {
                std::cout << "Error: No response text received" << std::endl;
            }
            
            if (status == 0) {
                if (result.text) {
                    // Parse JSON response to extract only the text from choices
                    std::string response_text = "";
                    try {
                        // Convert result.text to string first
                        std::string raw_response(result.text);
                        std::string cleaned_response = raw_response;
                        
                        // Fix malformed ID field like "cmpl-"916430" to "cmpl-916430"
                        size_t id_pos = cleaned_response.find("\"id\":\"");
                        if (id_pos != std::string::npos) {
                            size_t id_end_pos = cleaned_response.find("\"", id_pos + 6);
                            if (id_end_pos != std::string::npos && id_end_pos + 1 < cleaned_response.size()) {
                                if (cleaned_response[id_end_pos + 1] == '"') {
                                    // Remove the extra quote
                                    cleaned_response.erase(id_end_pos, 1);
                                }
                            }
                        }
                        
                        // Fix duplicate model fields by removing the empty one
                        size_t empty_model_pos = cleaned_response.find("\"model\":\"\",");
                        if (empty_model_pos != std::string::npos) {
                            cleaned_response.erase(empty_model_pos, 16); // Remove "model":"",
                        }
                        
                        // Fix trailing garbage after JSON object
                        size_t last_bracket_pos = cleaned_response.rfind("}");
                        if (last_bracket_pos != std::string::npos && last_bracket_pos + 1 < cleaned_response.size()) {
                            // Check if there's invalid content after the last closing bracket
                            if (cleaned_response.substr(last_bracket_pos + 1).find_first_not_of("\r\n ") != std::string::npos) {
                                cleaned_response = cleaned_response.substr(0, last_bracket_pos + 1);
                            }
                        }
                        
                        // Now try to parse the cleaned JSON
                        json response_json = json::parse(cleaned_response);
                        if (response_json.contains("choices") && !response_json["choices"].empty()) {
                            const json& first_choice = response_json["choices"][0];
                            if (first_choice.contains("text")) {
                                response_text = first_choice["text"].get<std::string>();
                            }
                        }
                    } catch (const json::parse_error& e) {
                        std::cerr << "Error parsing JSON response: " << e.what() << std::endl;
                        
                        // Try a simple string manipulation approach
                        std::string raw_response(result.text);
                        size_t text_start = raw_response.find("\"text\":\"");
                        if (text_start != std::string::npos) {
                            text_start += 8; // Skip "text":"
                            size_t text_end = raw_response.find("\"", text_start);
                            if (text_end != std::string::npos) {
                                response_text = raw_response.substr(text_start, text_end - text_start);
                                std::cout << "Extracted text using simple substring." << std::endl;
                            } else {
                                // Fallback to raw text if all else fails
                                response_text = raw_response;
                            }
                        } else {
                            // Fallback to raw text if all else fails
                            response_text = raw_response;
                        }
                    } catch (const std::exception& e) {
                        std::cerr << "Error processing JSON response: " << e.what() << std::endl;
                        // Fallback to raw text if JSON processing fails
                        response_text = result.text;
                    }
                    
                    // Remove stop sequences from the response text for cleaner output
                    // List of stop sequences to remove
                    const std::vector<std::string> stop_sequences_to_remove = {
                        "\n\n", "<|im_end|>", "<|endoftext|>",
                        "\nUser:", "User:", "\n\tUser:", "\tUser:",
                        "\nAssistant:", "Assistant:", "\n\tAssistant:", "\tAssistant:",
                        "\nHuman:", "Human:", "\nSystem:", "System:",
                        "\nBot:", "Bot:", "\nAI:", "AI:",
                        "\nuser:", "user:", "\n\tuser:", "\tuser:",
                        "\nassistant:", "assistant:", "\n\tassistant:", "\tassistant:",
                        "\nlife purpose", "\nThe user's message", "\nThe assistant's response",
                        "\nOkay, let me", "\nI will follow", "\nIn the previous example",
                        "\nIn this case", "\nHowever, in", "\nNow, the user",
                        "\nSince there's", "\nThe current user input",
                        "\nThe assistant should", "\nLooking at the response",
                        "\n谢谢你提问", "\n当然，每个生命", "\n你也可以思考"
                    };
                    
                    // Remove stop sequences from the end of the response
                    std::string cleaned_response_text = response_text;
                    
                    bool sequences_removed = true;
                    while (sequences_removed) {
                        sequences_removed = false;
                        
                        for (const auto& stop_seq : stop_sequences_to_remove) {
                            if (cleaned_response_text.size() >= stop_seq.size() &&
                                cleaned_response_text.substr(cleaned_response_text.size() - stop_seq.size()) == stop_seq) {
                                // Remove the stop sequence from the end
                                cleaned_response_text = cleaned_response_text.substr(0, cleaned_response_text.size() - stop_seq.size());
                                sequences_removed = true;
                                
                                // Remove any trailing whitespace after removing the stop sequence
                                while (!cleaned_response_text.empty() && isspace(cleaned_response_text.back())) {
                                    cleaned_response_text.pop_back();
                                }
                                
                                // Break and restart the loop to check all sequences again
                                break;
                            }
                        }
                    }
                    
                    // Display the extracted response text
                    std::cout << "\n=== PARSED OUTPUT ===\n";
                    std::cout << "Extracted Text from Choices: " << response_text << std::endl;
                    if (cleaned_response_text != response_text) {
                        std::cout << "Cleaned Text (stop sequences removed): " << cleaned_response_text << std::endl;
                    }
                    std::cout << "\n=== ASSISTANT RESPONSE ===\n";
                    std::cout << cleaned_response_text << std::endl;
                    
                    // Add assistant response to chat history (use cleaned text without stop sequences)
                    ChatMessage assistant_msg = {"assistant", cleaned_response_text};
                    chat_history.push_back(assistant_msg);
                    
                    llama_mobile_free_string(result.text);
                } else {
                    std::cerr << "[No response generated]" << std::endl;
                }
            } else {
                std::cerr << "[Failed to generate response (status: " << status << ")]" << std::endl;
            }
            
            // Free any allocated stop sequences
            free_stop_sequences(params);
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
