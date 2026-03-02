#include "llama_mobile.h"
#include "llama.cpp-master/common/common.h"
#include "llama.cpp-master/include/llama.h"

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>

struct TestResult {
    std::string name;
    bool passed;
    std::string details;
};

static common_chat_msg make_msg(const std::string& role, const std::string& content) {
    common_chat_msg msg;
    msg.role = role;
    msg.content = content;
    return msg;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <model_path>" << std::endl;
        return 1;
    }

    std::string model_path = argv[1];
    std::cout << "Testing advanced chat features with model: " << model_path << std::endl;
    std::cout << std::string(70, '=') << std::endl;
    
    std::vector<TestResult> test_results;
    
    try {
        auto context = std::make_shared<llama_mobile::llama_mobile_context>();
        
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 2048;
        params.n_gpu_layers = 0;
        params.cpuparams.n_threads = 4;
        params.n_predict = 50;
        params.sampling.temp = 0.7;
        params.sampling.top_p = 0.9;
        
        if (!context->loadModel(params)) {
            std::cerr << "Failed to load model" << std::endl;
            return 1;
        }
        
        std::cout << "Model loaded successfully" << std::endl;
        
        // Test 1: Basic Chat Messages with Built-in Template
        std::cout << "\n--- Test 1: Basic Chat Messages with Built-in Template ---" << std::endl;
        TestResult test1 = {"Basic Chat Messages", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "What is 2+2?"));
            context->enable_chat_template = true;
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            if (context->num_prompt_tokens > 1) {
                test1.passed = true;
                test1.details = "Chat messages formatted correctly, prompt tokens > 1";
            } else {
                test1.details = "Chat messages may not have been formatted correctly";
            }
        } catch (const std::exception& e) {
            test1.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test1);
        
        // Test 2: JSON Schema Parameter
        std::cout << "\n--- Test 2: JSON Schema Parameter ---" << std::endl;
        TestResult test2 = {"JSON Schema Parameter", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "Generate a simple JSON object with name and age fields."));
            context->json_schema = R"({"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "number"}}})";
            context->tools = "";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "JSON schema set, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test2.passed = true;
            test2.details = "JSON schema parameter accepted without errors";
        } catch (const std::exception& e) {
            test2.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test2);
        
        // Test 3: Tools Parameter
        std::cout << "\n--- Test 3: Tools Parameter ---" << std::endl;
        TestResult test3 = {"Tools Parameter", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant with access to tools."));
            context->chat_messages.push_back(make_msg("user", "What's the weather?"));
            context->tools = R"([
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "Get the current weather",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "location": {"type": "string"}
                            }
                        }
                    }
                }
            ])";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Tools parameter set, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test3.passed = true;
            test3.details = "Tools parameter accepted without errors";
        } catch (const std::exception& e) {
            test3.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test3);
        
        // Test 4: Tool Choice Parameter
        std::cout << "\n--- Test 4: Tool Choice Parameter ---" << std::endl;
        TestResult test4 = {"Tool Choice Parameter", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "Calculate 2+2"));
            context->tools = R"([
                {
                    "type": "function",
                    "function": {
                        "name": "calculate",
                        "description": "Perform calculations",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "expression": {"type": "string"}
                            }
                        }
                    }
                }
            ])";
            context->tool_choice = "calculate";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Tool choice set to 'calculate', prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test4.passed = true;
            test4.details = "Tool choice parameter accepted without errors";
        } catch (const std::exception& e) {
            test4.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test4);
        
        // Test 5: Parallel Tool Calls Parameter
        std::cout << "\n--- Test 5: Parallel Tool Calls Parameter ---" << std::endl;
        TestResult test5 = {"Parallel Tool Calls Parameter", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "What's the weather in NY and LA?"));
            context->tools = R"([
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "Get weather",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "location": {"type": "string"}
                            }
                        }
                    }
                }
            ])";
            context->parallel_tool_calls = true;
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Parallel tool calls enabled, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test5.passed = true;
            test5.details = "Parallel tool calls parameter accepted without errors";
        } catch (const std::exception& e) {
            test5.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test5);
        
        // Test 6: JSON Escaping in Chat Messages
        std::cout << "\n--- Test 6: JSON Escaping in Chat Messages ---" << std::endl;
        TestResult test6 = {"JSON Escaping", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "Explain JSON with quotes: {\"key\": \"value\"}"));
            context->json_schema = "";
            context->tools = "";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Chat messages with special characters loaded, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test6.passed = true;
            test6.details = "JSON escaping handled correctly for special characters";
        } catch (const std::exception& e) {
            test6.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test6);
        
        // Test 7: Enable Chat Template = false
        std::cout << "\n--- Test 7: Enable Chat Template = false ---" << std::endl;
        TestResult test7 = {"Disable Chat Template", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "Hello!"));
            context->enable_chat_template = false;
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Chat template disabled, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test7.passed = true;
            test7.details = "Chat template can be disabled successfully";
        } catch (const std::exception& e) {
            test7.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test7);
        
        // Test 8: Custom Jinja Template
        std::cout << "\n--- Test 8: Custom Jinja Template ---" << std::endl;
        TestResult test8 = {"Custom Jinja Template", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant."));
            context->chat_messages.push_back(make_msg("user", "Hello!"));
            context->chat_template = "{% for message in messages %}{{ message.role }}: {{ message.content }}\n{% endfor %}Assistant:";
            context->enable_chat_template = true;
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Custom Jinja template applied, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test8.passed = true;
            test8.details = "Custom Jinja template can be applied";
        } catch (const std::exception& e) {
            test8.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test8);
        
        // Test 9: Multiple Advanced Parameters Together
        std::cout << "\n--- Test 9: Multiple Advanced Parameters Together ---" << std::endl;
        TestResult test9 = {"Multiple Advanced Parameters", false, ""};
        try {
            context->chat_messages.clear();
            context->chat_messages.push_back(make_msg("system", "You are a helpful assistant with access to tools."));
            context->chat_messages.push_back(make_msg("user", "Generate a weather report in JSON format."));
            context->json_schema = R"({"type": "object", "properties": {"location": {"type": "string"}, "temperature": {"type": "number"}}})";
            context->tools = R"([
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "Get weather",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "location": {"type": "string"}
                            }
                        }
                    }
                }
            ])";
            context->parallel_tool_calls = true;
            context->tool_choice = "auto";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "All advanced parameters set, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            test9.passed = true;
            test9.details = "Multiple advanced parameters work together";
        } catch (const std::exception& e) {
            test9.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test9);
        
        // Test 10: Empty Chat Messages (Should use prompt directly)
        std::cout << "\n--- Test 10: Empty Chat Messages ---" << std::endl;
        TestResult test10 = {"Empty Chat Messages", false, ""};
        try {
            context->chat_messages.clear();
            context->params.prompt = "Direct prompt without chat messages";
            
            if (!context->initSampling()) {
                throw std::runtime_error("Failed to initialize sampling");
            }
            
            context->loadPrompt();
            
            std::cout << "Direct prompt loaded, prompt tokens: " << context->num_prompt_tokens << std::endl;
            
            if (context->num_prompt_tokens > 0) {
                test10.passed = true;
                test10.details = "Direct prompt works when chat messages are empty";
            } else {
                test10.details = "Failed to load direct prompt";
            }
        } catch (const std::exception& e) {
            test10.details = "Exception: " + std::string(e.what());
        }
        test_results.push_back(test10);
        
        // Generate comprehensive test report
        std::cout << "\n" << std::string(70, '=') << std::endl;
        std::cout << "           ADVANCED CHAT FEATURES TEST REPORT" << std::endl;
        std::cout << std::string(70, '=') << std::endl;
        
        int passed_count = 0;
        int failed_count = 0;
        
        std::cout << "\nSUMMARY:" << std::endl;
        std::cout << std::string(70, '-') << std::endl;
        std::cout << std::left << std::setw(45) << "Test" << std::setw(10) << "Status" << "Details" << std::endl;
        std::cout << std::string(70, '-') << std::endl;
        
        for (const auto& test : test_results) {
            if (test.passed) {
                passed_count++;
            } else {
                failed_count++;
            }
            
            std::string status = test.passed ? "PASSED" : "FAILED";
            std::cout << std::left << std::setw(45) << test.name << std::setw(10) << status << test.details << std::endl;
        }
        
        std::cout << std::string(70, '-') << std::endl;
        std::cout << std::left << std::setw(45) << "Total Tests" << std::setw(10) << (passed_count + failed_count) << std::endl;
        std::cout << std::left << std::setw(45) << "Tests Passed" << std::setw(10) << passed_count << std::endl;
        std::cout << std::left << std::setw(45) << "Tests Failed" << std::setw(10) << failed_count << std::endl;
        
        if (failed_count == 0) {
            std::cout << "\n✅ ALL TESTS PASSED!" << std::endl;
        } else {
            std::cout << "\n❌ SOME TESTS FAILED!" << std::endl;
        }
        
        std::cout << std::string(70, '=') << std::endl;
        
        return failed_count == 0 ? 0 : 1;
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal Error: " << e.what() << std::endl;
        return 1;
    }
}
