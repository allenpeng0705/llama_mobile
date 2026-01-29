#include "llama_mobile.h"
#include "llama_cpp/common.h"
#include "llama_cpp/llama.h"

#include <iostream>
#include <vector>
#include <string>
#include <iomanip>

struct TestResult {
    std::string name;
    bool passed;
    std::string details;
    int prompt_tokens;
    int generated_tokens;
};

std::string generate_completion(std::shared_ptr<llama_mobile::llama_mobile_context>& context) {
    context->beginCompletion();
    
    while (context->has_next_token && !context->is_interrupted) {
        auto token_output = context->doCompletion();
        
        // Check if we should stop immediately after each completion
        // Check both has_next_token and stopped_word to ensure we stop when stop sequence is detected
        if (token_output.tok == -1 || !context->has_next_token || context->stopped_word) {
            break;
        }
    }
    
    // Core library now handles stop sequence truncation automatically
    return context->generated_text;
}

void print_test_header(const std::string& title) {
    std::cout << "\n" << std::string(70, '=') << std::endl;
    std::cout << title << std::endl;
    std::cout << std::string(70, '=') << std::endl;
}

void print_test_separator() {
    std::cout << std::string(70, '-') << std::endl;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <model_path>" << std::endl;
        return 1;
    }

    std::string model_path = argv[1];
    print_test_header("COMPREHENSIVE CHAT TEMPLATE TEST");
    std::cout << "Model: " << model_path << std::endl;
    
    std::vector<TestResult> test_results;
    
    try {
        // Initialize the llama_mobile context
        auto context = std::make_shared<llama_mobile::llama_mobile_context>();
        
        // Set up params
        common_params params;
        params.model.path = model_path;
        params.n_ctx = 2048;
        params.n_gpu_layers = 0;
        params.cpuparams.n_threads = 4;
        params.n_predict = 1024;
        params.sampling.temp = 0.7;
        params.sampling.top_p = 0.9;
        
        if (!context->loadModel(params)) {
            std::cerr << "Failed to load model" << std::endl;
            return 1;
        }
        
        // Add stop sequence for Qwen-style templates
        context->params.antiprompt.push_back("<|im_end|>");

        
        std::cout << "Model loaded successfully" << std::endl;
        
        // Create chat messages (OpenAI format)
        std::vector<llama_chat_message> chat_messages;
        chat_messages.push_back({"system", "You are a helpful assistant."});
        chat_messages.push_back({"user", "Hello, how are you?"});
        
        
        // Custom Jinja template for testing (Qwen format)
        std::string custom_jinja_template = "{% for message in messages %}<|im_start|>{{ message.role }}\n{{ message.content }}<|im_end|>\n{% endfor %}<|im_start|>assistant\n";
        
        // Custom non-Jinja template for testing (simple format without Jinja syntax)
        std::string custom_no_jinja_template = "<|im_start|>{{ message.role }}\n{{ message.content }}<|im_end|>\n<|im_start|>assistant\n";
        
        // Test 1: Built-in template + use_json_response = true
        {
            print_test_header("Test 1: Built-in Template + JSON Response = true");
            TestResult test1 = {"Built-in Template + JSON Response = true", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = "";
                context->params.enable_chat_template = true;
                context->params.use_json_response = true;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Built-in" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test1.passed = true;
                test1.details = "Successfully generated response with built-in template and JSON wrapping";
                test1.prompt_tokens = context->num_prompt_tokens;
                test1.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test1.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test1);
        }

        // Test 2: Built-in template + use_json_response = false
        {
            print_test_header("Test 2: Built-in Template + JSON Response = false");
            TestResult test2 = {"Built-in Template + JSON Response = false", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = "";
                context->params.enable_chat_template = true;
                context->params.use_json_response = false;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Built-in" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test2.passed = true;
                test2.details = "Successfully generated response with built-in template, no JSON wrapping";
                test2.prompt_tokens = context->num_prompt_tokens;
                test2.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test2.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test2);
        }
        
        // Test 3: Custom Jinja template + use_json_response = true
        {
            print_test_header("Test 3: Custom Jinja Template + JSON Response = true");
            TestResult test3 = {"Custom Jinja Template + JSON Response = true", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = custom_jinja_template;
                context->params.enable_chat_template = true;
                context->params.use_json_response = true;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Custom Jinja" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test3.passed = true;
                test3.details = "Successfully generated response with custom Jinja template and JSON wrapping";
                test3.prompt_tokens = context->num_prompt_tokens;
                test3.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test3.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test3);
        }
        
        // Test 4: Custom Jinja template + use_json_response = false
        {
            print_test_header("Test 4: Custom Jinja Template + JSON Response = false");
            TestResult test4 = {"Custom Jinja Template + JSON Response = false", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = custom_jinja_template;
                context->params.enable_chat_template = true;
                context->params.use_json_response = false;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Custom Jinja" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test4.passed = true;
                test4.details = "Successfully generated response with custom Jinja template, no JSON wrapping";
                test4.prompt_tokens = context->num_prompt_tokens;
                test4.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test4.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test4);
            

        }
        
        // Test 5: Custom non-Jinja template + use_json_response = true
        {
            print_test_header("Test 5: Custom Non-Jinja Template + JSON Response = true");
            TestResult test5 = {"Custom Non-Jinja Template + JSON Response = true", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = custom_no_jinja_template;
                context->params.enable_chat_template = true;
                context->params.use_json_response = true;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Custom Non-Jinja" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test5.passed = true;
                test5.details = "Successfully generated response with custom non-Jinja template and JSON wrapping";
                test5.prompt_tokens = context->num_prompt_tokens;
                test5.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test5.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test5);
            

        }
        
        // Test 6: Custom non-Jinja template + use_json_response = false
        {
            print_test_header("Test 6: Custom Non-Jinja Template + JSON Response = false");
            TestResult test6 = {"Custom Non-Jinja Template + JSON Response = false", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = custom_no_jinja_template;
                context->params.enable_chat_template = true;
                context->params.use_json_response = false;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: Custom Non-Jinja" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test6.passed = true;
                test6.details = "Successfully generated response with custom non-Jinja template, no JSON wrapping";
                test6.prompt_tokens = context->num_prompt_tokens;
                test6.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test6.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test6);

        }
        
        // Test 7: enable_chat_template = false + use_json_response = true
        {
            print_test_header("Test 7: Enable Template = false + JSON Response = true");
            TestResult test7 = {"Enable Template = false + JSON Response = true", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = "";
                context->params.enable_chat_template = false;
                context->params.use_json_response = true;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: None (disabled)" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test7.passed = true;
                test7.details = "Successfully generated response with template disabled but JSON wrapping enabled";
                test7.prompt_tokens = context->num_prompt_tokens;
                test7.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test7.details = "Exception: " + std::string(e.what());
            }
            
            // Reset context for next test
            context->rewind();
            // Re-add stop sequences after rewind
            context->params.antiprompt.push_back("<|im_end|>");
            
            test_results.push_back(test7);
            
        }
        
        // Test 8: enable_chat_template = false + use_json_response = false
        {
            print_test_header("Test 8: Enable Template = false + JSON Response = false");
            TestResult test8 = {"Enable Template = false + JSON Response = false", false, "", 0, 0};
            
            try {
                context->params.chat_messages = chat_messages;
                context->params.chat_template = "";
                context->params.enable_chat_template = false;
                context->params.use_json_response = false;
                
                std::cout << "Chat messages: " << chat_messages.size() << std::endl;
                std::cout << "Template: None (disabled)" << std::endl;
                std::cout << "Enable template: " << (context->params.enable_chat_template ? "true" : "false") << std::endl;
                std::cout << "JSON response: " << (context->params.use_json_response ? "true" : "false") << std::endl;
                
                if (!context->initSampling()) {
                    throw std::runtime_error("Failed to initialize sampling");
                }
                
                context->loadPrompt();
                
                std::cout << "Prompt tokens: " << context->num_prompt_tokens << std::endl;
                
                std::string result = generate_completion(context);
                
                std::cout << "\nGenerated text:" << std::endl;
                std::cout << result << std::endl;
                
                test8.passed = true;
                test8.details = "Successfully generated response with both template and JSON wrapping disabled";
                test8.prompt_tokens = context->num_prompt_tokens;
                test8.generated_tokens = context->num_tokens_predicted;
                
            } catch (const std::exception& e) {
                test8.details = "Exception: " + std::string(e.what());
            }
            
            test_results.push_back(test8);
        }
        
        // Generate comprehensive test report
        print_test_header("TEST REPORT SUMMARY");
        
        int passed_count = 0;
        int failed_count = 0;
        
        print_test_separator();
        std::cout << std::left << std::setw(40) << "Test Name" 
                  << std::setw(10) << "Status" 
                  << std::setw(12) << "Prompt Tkns" 
                  << std::setw(12) << "Gen Tkns" 
                  << "Details" << std::endl;
        print_test_separator();
        
        for (const auto& test : test_results) {
            std::cout << std::left << std::setw(40) << test.name 
                      << std::setw(10) << (test.passed ? "PASSED" : "FAILED") 
                      << std::setw(12) << test.prompt_tokens 
                      << std::setw(12) << test.generated_tokens 
                      << test.details << std::endl;
            
            if (test.passed) {
                passed_count++;
            } else {
                failed_count++;
            }
        }
        
        print_test_separator();
        std::cout << "Total Tests: " << test_results.size() << std::endl;
        std::cout << "Tests Passed: " << passed_count << std::endl;
        std::cout << "Tests Failed: " << failed_count << std::endl;
        
        if (failed_count == 0) {
            std::cout << "\n✅ ALL TESTS PASSED!" << std::endl;
        } else {
            std::cout << "\n❌ SOME TESTS FAILED!" << std::endl;
        }
        
        print_test_header("TEST COMPLETED");
        
        return (failed_count == 0) ? 0 : 1;
        
    } catch (const std::exception& e) {
        std::cerr << "Fatal Error: " << e.what() << std::endl;
        return 1;
    }
}

