#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <ctime>

#include "utils.h"
#include "../../lib/llama_mobile.h"

int main(int argc, char **argv) {
    // Local VLM models from lib/models
    const std::string local_model_path = "../../../lib/models/SmolVLM-256M-Instruct-Q8_0.gguf";
    const std::string local_mmproj_path = "../../../lib/models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf";
    const std::string image_path = "../files/image.jpg";

    // Fallback download URLs if local models are not available
    const std::string default_model_url = "https://huggingface.co/ggml-org/SmolVLM-256M-Instruct-GGUF/resolve/main/SmolVLM-256M-Instruct-Q8_0.gguf";
    const std::string default_model_filename = "SmolVLM-256M-Instruct-Q8_0.gguf";
    const std::string default_mmproj_url = "https://huggingface.co/ggml-org/SmolVLM-256M-Instruct-GGUF/resolve/main/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf";
    const std::string default_mmproj_filename = "mmproj-SmolVLM-256M-Instruct-Q8_0.gguf";

    std::string model_path = "";
    std::string mmproj_path = "";

    // Parse command-line arguments
    if (argc > 1) {
        model_path = argv[1];
        if (argc > 2) {
            mmproj_path = argv[2];
        }
    }

    // Determine which model paths to use
    std::string final_model_path;
    std::string final_mmproj_path;
    
    if (!model_path.empty()) {
        // User provided a model path
        final_model_path = model_path;
    } else if (fileExists(local_model_path)) {
        // Local model exists
        final_model_path = local_model_path;
    } else {
        // Fallback to downloaded model
        final_model_path = default_model_filename;
        if (!downloadFile(default_model_url, default_model_filename, "VLM model")) {
            return 1;
        }
    }
    
    if (!mmproj_path.empty()) {
        // User provided a projector path
        final_mmproj_path = mmproj_path;
    } else if (fileExists(local_mmproj_path)) {
        // Local projector exists
        final_mmproj_path = local_mmproj_path;
    } else {
        // Fallback to downloaded projector
        final_mmproj_path = default_mmproj_filename;
        if (!downloadFile(default_mmproj_url, default_mmproj_filename, "Multimodal projector")) {
            return 1;
        }
    }

    if (!fileExists(image_path)) {
        std::cerr << "Image file not found: " << image_path << std::endl;
        return 1;
    }

    std::cout << "\n=== Cactus Core API VLM Example ===" << std::endl;

    try {
        llama_mobile::llama_mobile_context context;

        common_params params;
        params.model.path = final_model_path;
        params.n_ctx = 2048;
        params.n_batch = 32;
        params.n_gpu_layers = 99;
        params.cpuparams.n_threads = 4;

        std::cout << "Loading model: " << final_model_path << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "Failed to load model" << std::endl;
            return 1;
        }

        std::cout << "Initializing multimodal with projector: " << final_mmproj_path << std::endl;
        if (!context.initMultimodal(final_mmproj_path, true)) {  // Enable GPU acceleration for CLIP
            std::cerr << "Failed to initialize multimodal" << std::endl;
            return 1;
        }

        std::cout << "Vision support: " << (context.isMultimodalSupportVision() ? "Yes" : "No") << std::endl;

        // Function to prompt and get response using proper chat template
        auto prompt_and_respond = [&](const std::string& prompt, const std::vector<std::string>& media_paths = {}, int max_tokens = 50) {
            std::cout << "\n" << std::string(80, '=') << std::endl;
            std::cout << "PROMPT: " << prompt << std::endl;
            if (!media_paths.empty()) {
                std::cout << "MEDIA: " << media_paths.size() << " file(s)" << std::endl;
            }
            std::cout << std::string(80, '-') << std::endl;


            
            // Format the prompt using proper chat template
            std::string formatted_prompt;
            try {
                if (!media_paths.empty()) {
                    std::string messages = R"([{"role": "user", "content": [{"type": "image"}, {"type": "text", "text": ")" + prompt + R"("}]}])";
                    formatted_prompt = context.getFormattedChat(messages, "");
                } else {
                    std::string messages = R"([{"role": "user", "content": [{"type": "text", "text": ")" + prompt + R"("}]}])";
                    formatted_prompt = context.getFormattedChat(messages, "");
                }
            } catch (const std::exception& e) {
                std::cerr << "Warning: Chat template formatting failed (" << e.what() << "), using raw prompt" << std::endl;
                formatted_prompt = prompt;
            }
            
            context.params.prompt = formatted_prompt;
            context.params.n_predict = max_tokens;

            if (!context.initSampling()) {
                std::cerr << "Failed to initialize sampling" << std::endl;
                return false;
            }

        context.rewind();
        context.beginCompletion();
        context.loadPrompt(media_paths);

        while (context.has_next_token && !context.is_interrupted) {
            auto token_output = context.doCompletion();
            if (token_output.tok == -1) break;
        }

            std::cout << "RESPONSE: " << context.generated_text << std::endl;
            
            return true;
        };

        // Test sequence: language, image, language, language, image, image
        std::cout << "\nStarting multi-turn conversation test..." << std::endl;
        if (!prompt_and_respond("Hello! Can you tell me what you are?")) return 1;
        if (!prompt_and_respond("Describe what you see in this image.", {image_path})) return 1;
        if (!prompt_and_respond("What are the main colors you observed?")) return 1;
        if (!prompt_and_respond("Can you write a short poem about vision?")) return 1;
        if (!prompt_and_respond("What emotions or mood does this image convey?", {image_path})) return 1;
        if (!prompt_and_respond("If you had to give this image a title, what would it be?", {image_path})) return 1;
        std::cout << "\nMulti-turn conversation test completed!" << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}