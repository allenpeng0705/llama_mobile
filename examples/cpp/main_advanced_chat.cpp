#include "../lib/llama_mobile_ffi.h"
#include <iostream>
#include <string>
#include <vector>
#include <filesystem>

namespace fs = std::filesystem;

void progress_callback(float progress) {
    std::cout << "Loading model: " << (progress * 100.0f) << "%\r";
    std::cout.flush();
}

bool token_callback(const char* token) {
    std::cout << token;
    std::cout.flush();
    return true;
}

int main(int argc, char* argv[]) {
    std::string model_path = "";
    
    // Parse command-line arguments
    if (argc > 1) {
        // First argument is a model path
        model_path = argv[1];
    }
    
    // If no model path specified, try to find one
    if (model_path.empty()) {
        // Use local Qwen3 model by default with absolute path
        model_path = "/Users/shileipeng/Documents/mygithub/llama_mobile/models/Qwen3-1.7B-Q4_K_M.gguf";
        
        // Check if the specific model exists, otherwise try any GGUF file in the models directory
        if (!fs::exists(model_path)) {
            std::cout << "Model file not found: " << model_path << std::endl;
            std::cout << "Searching for any GGUF file in the models directory..." << std::endl;
            
            std::string models_dir = "/Users/shileipeng/Documents/mygithub/llama_mobile/models";
            
            if (fs::exists(models_dir)) {
                bool found = false;
                for (const auto& entry : fs::directory_iterator(models_dir)) {
                    if (entry.is_regular_file() && entry.path().extension() == ".gguf") {
                        model_path = entry.path().string();
                        std::cout << "Found model: " << model_path << std::endl;
                        found = true;
                        break;
                    }
                }
                
                if (!found) {
                    std::cerr << "\n❌ ERROR: No GGUF files found in models directory: " << models_dir << std::endl;
                    std::cerr << "Please download at least one LLM model in GGUF format.\n" << std::endl;
                    std::cerr << "Example command:" << std::endl;
                    std::cerr << "  cd " << models_dir << std::endl;
                    std::cerr << "  wget https://huggingface.co/BAAI/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf\n" << std::endl;
                    return 1;
                }
            } else {
                std::cerr << "\n❌ ERROR: Models directory not found: " << models_dir << std::endl;
                std::cerr << "Please create this directory and place GGUF model files there.\n" << std::endl;
                std::cerr << "Example commands:" << std::endl;
                std::cerr << "  mkdir -p " << models_dir << std::endl;
                std::cerr << "  cd " << models_dir << std::endl;
                std::cerr << "  wget https://huggingface.co/BAAI/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf\n" << std::endl;
                return 1;
            }
        }
    }
    
    std::cout << "Advanced Chat Features Example" << std::endl;
    std::cout << "=============================" << std::endl;
    std::cout << "Model: " << model_path << std::endl << std::endl;

    // Initialize model with chat template enabled
    llama_mobile_init_params_c_t init_params = {0};
    init_params.model_path = model_path.c_str();
    init_params.n_ctx = 2048;
    init_params.n_batch = 512;
    init_params.n_ubatch = 512;
    init_params.n_gpu_layers = 0;
    init_params.n_threads = 4;
    init_params.progress_callback = progress_callback;
    init_params.enable_chat_template = true;

    std::cout << "Initializing model..." << std::endl;
    llama_mobile_context_handle_t ctx = llama_mobile_init_context_c(&init_params);

    if (ctx == nullptr) {
        std::cerr << "Failed to initialize model" << std::endl;
        return 1;
    }

    std::cout << "\nModel initialized successfully!" << std::endl << std::endl;
/*
    // Example 1: Basic Chat with Messages
    std::cout << "=== Example 1: Basic Chat with Messages ===" << std::endl;
    {
        llama_mobile_chat_message_c messages[] = {
            {"system", "You are a helpful assistant."},
            {"user", "What is 2+2?"}
        };

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = messages;
        completion_params.chat_message_count = 2;
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;
        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            llama_mobile_free_completion_result_members_c(&result);
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }

    // Example 2: Chat with JSON Schema
    std::cout << "\n=== Example 2: Chat with JSON Schema ===" << std::endl;
    {
        llama_mobile_chat_message_c messages[] = {
            {"system", "You are a helpful assistant."},
            {"user", "Generate a simple JSON object with name and age fields."}
        };

        const char* json_schema = R"({"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "number"}}})";

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = messages;
        completion_params.chat_message_count = 2;
        completion_params.json_schema = json_schema;
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;

        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            llama_mobile_free_completion_result_members_c(&result);
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }

    // Example 3: Chat with Tools
    std::cout << "\n=== Example 3: Chat with Tools ===" << std::endl;
    {
        llama_mobile_chat_message_c messages[] = {
            {"system", "You are a helpful assistant with access to tools."},
            {"user", "What's the weather in New York?"}
        };

        const char* tools = R"([
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Get the current weather for a location",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "The city and state, e.g. San Francisco, CA"
                            }
                        },
                        "required": ["location"]
                    }
                }
            }
        ])";

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = messages;
        completion_params.chat_message_count = 2;
        completion_params.tools = tools;
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;
        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            llama_mobile_free_completion_result_members_c(&result);
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }

    // Example 4: Chat with Tool Choice
    std::cout << "\n=== Example 4: Chat with Tool Choice ===" << std::endl;
    {
        llama_mobile_chat_message_c messages[] = {
            {"system", "You are a helpful assistant."},
            {"user", "Calculate 15 * 3"}
        };

        const char* tools = R"([
            {
                "type": "function",
                "function": {
                    "name": "calculate",
                    "description": "Perform mathematical calculations",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "expression": {
                                "type": "string",
                                "description": "Mathematical expression to evaluate"
                            }
                        },
                        "required": ["expression"]
                    }
                }
            }
        ])";
        const char* tool_choice = "calculate";

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = messages;
        completion_params.chat_message_count = 2;
        completion_params.tools = tools;
        completion_params.tool_choice = tool_choice;
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;
        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            llama_mobile_free_completion_result_members_c(&result);
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }

    // Example 5: Chat with Parallel Tool Calls
    std::cout << "\n=== Example 5: Chat with Parallel Tool Calls ===" << std::endl;
    {
        llama_mobile_chat_message_c messages[] = {
            {"system", "You are a helpful assistant."},
            {"user", "What's the weather in New York and Los Angeles?"}
        };

        const char* tools = R"([
            {
                "type": "function",
                "function": {
                    "name": "get_weather",
                    "description": "Get the current weather for a location",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "location": {
                                "type": "string",
                                "description": "The city and state"
                            }
                        },
                        "required": ["location"]
                    }
                }
            }
        ])";

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = messages;
        completion_params.chat_message_count = 2;
        completion_params.tools = tools;
        completion_params.parallel_tool_calls = true;
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;
        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            llama_mobile_free_completion_result_members_c(&result);
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }
*/
    // Example 6: Multi-turn Conversation
    std::cout << "\n=== Example 6: Multi-turn Conversation ===" << std::endl;
    {
        static const char* system_msg = "You are a helpful assistant.";
        static const char* user1_msg = "My name is Alice.";
        static const char* assistant1_msg = "Nice to meet you, Alice! How can I help you today?";
        static const char* user2_msg = "What's my name?";
        static const char* user3_msg = "How old am I?";
        
        std::vector<llama_mobile_chat_message_c> conversation = {
            {"system", system_msg},
            {"user", user1_msg},
            {"assistant", assistant1_msg},
            {"user", user2_msg}
        };

        llama_mobile_completion_params_c_t completion_params = {0};
        completion_params.chat_messages = conversation.data();
        completion_params.chat_message_count = conversation.size();
        completion_params.n_predict = 1024;
        completion_params.temperature = 0.7;
        completion_params.token_callback = token_callback;
        const char* stop_sequences[] = {"<|im_end|>"};
        completion_params.stop_sequences = stop_sequences;
        completion_params.stop_sequence_count = 1;

        llama_mobile_completion_result_c_t result;
        int status = llama_mobile_completion_c(ctx, &completion_params, &result);

        if (status == 0 && result.text) {
            std::cout << "\n\nResponse: " << result.text << std::endl;
            
            // Add assistant's response to conversation
            char* assistant2_msg_copy = new char[strlen(result.text) + 1];
            strcpy(assistant2_msg_copy, result.text);
            conversation.push_back({"assistant", assistant2_msg_copy});
            
            // Continue conversation
            conversation.push_back({"user", user3_msg});
            
            std::cout << "\nUser: " << user3_msg << std::endl;
            
            completion_params.chat_messages = conversation.data();
            completion_params.chat_message_count = conversation.size();
            
            status = llama_mobile_completion_c(ctx, &completion_params, &result);
            
            if (status == 0 && result.text) {
                std::cout << "Response: " << result.text << std::endl;
                llama_mobile_free_completion_result_members_c(&result);
            }
            
            // Free the copied assistant message
            delete[] conversation[4].content;
        } else {
            std::cerr << "Completion failed with status: " << status << std::endl;
        }
    }

    // Cleanup
    std::cout << "\n=== Cleanup ===" << std::endl;
    llama_mobile_free_context_c(ctx);
    std::cout << "Context freed successfully" << std::endl;

    std::cout << "\n=== All Examples Completed ===" << std::endl;
    return 0;
}
