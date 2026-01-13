#include <iostream>
#include <string>
#include <filesystem>
#include "../llama_mobile_api.h"

using namespace std;
using namespace std::filesystem;

int main(int argc, char* argv[]) {
    cout << "Minimal Llama Mobile Test\n";
    
    if (argc != 2) {
        cerr << "Usage: " << argv[0] << " <model_path>\n";
        return 1;
    }
    
    string model_path = argv[1];
    cout << "Model: " << path(model_path).filename() << endl;
    
    // Initialize
    llama_mobile_init_params_t init_params = {0};
    init_params.model_path = model_path.c_str();
    init_params.n_ctx = 2048;
    init_params.n_gpu_layers = 20;
    init_params.n_threads = 4;
    
    llama_mobile_context_t ctx = llama_mobile_init(&init_params);
    if (!ctx) {
        cerr << "Failed to initialize llama_mobile\n";
        return 1;
    }
    
    cout << "Model loaded successfully!\n";
    
    // Simple prompt
    string prompt = "Hello, how are you?";
    cout << "Prompt: " << prompt << endl;
    
    // Generate
    llama_mobile_completion_params_t comp_params = {0};
    comp_params.prompt = prompt.c_str();
    comp_params.max_tokens = 50;
    comp_params.temperature = 0.8;
    comp_params.top_k = 40;
    comp_params.top_p = 0.95;
    
    llama_mobile_completion_result_t result;
    int status = llama_mobile_completion(ctx, &comp_params, &result);
    
    if (status == 0 && result.text) {
        cout << "Response: " << result.text << endl;
        llama_mobile_free_string(result.text);
    } else {
        cout << "Failed to generate response (status: " << status << ")\n";
    }
    
    // Cleanup
    llama_mobile_free(ctx);
    
    cout << "Test completed.\n";
    return 0;
}