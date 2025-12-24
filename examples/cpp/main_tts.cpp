#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <cstdlib>
#include <cassert>
#include <cstring>
#include <thread>

#include "utils.h"
#include "../../lib/llama_mobile.h"

void writeWavFile(const std::string& filename, const std::vector<float>& audio_data, int sample_rate = 24000) {
    std::ofstream file(filename, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "Failed to open file for writing: " << filename << std::endl;
        return;
    }

    int num_samples = audio_data.size();
    int byte_rate = sample_rate * 2; // 16-bit mono
    int data_size = num_samples * 2;
    int file_size = 36 + data_size;

    // WAV header
    file.write("RIFF", 4);
    file.write(reinterpret_cast<const char*>(&file_size), 4);
    file.write("WAVE", 4);
    file.write("fmt ", 4);
    
    int fmt_size = 16;
    short audio_format = 1; // PCM
    short num_channels = 1; // Mono
    short bits_per_sample = 16;
    short block_align = num_channels * bits_per_sample / 8;
    
    file.write(reinterpret_cast<const char*>(&fmt_size), 4);
    file.write(reinterpret_cast<const char*>(&audio_format), 2);
    file.write(reinterpret_cast<const char*>(&num_channels), 2);
    file.write(reinterpret_cast<const char*>(&sample_rate), 4);
    file.write(reinterpret_cast<const char*>(&byte_rate), 4);
    file.write(reinterpret_cast<const char*>(&block_align), 2);
    file.write(reinterpret_cast<const char*>(&bits_per_sample), 2);
    
    file.write("data", 4);
    file.write(reinterpret_cast<const char*>(&data_size), 4);
    
    // Convert float audio data to 16-bit PCM
    for (float sample : audio_data) {
        short pcm_sample = static_cast<short>(std::max(-32768.0f, std::min(32767.0f, sample * 32767.0f)));
        file.write(reinterpret_cast<const char*>(&pcm_sample), 2);
    }
    
    file.close();
    std::cout << "Audio saved to " << filename << std::endl;
}

int main(int argc, char **argv) {
    // Local TTS models from lib/models
    const std::string local_model_path = "../../lib/models/OuteTTS-0.2-500M-Q6_K.gguf";
    const std::string local_vocoder_path = "../../lib/models/WavTokenizer-Large-75-F16.gguf";
    
    // Fallback download URLs if local models are not available
    const std::string default_model_url = "https://huggingface.co/OuteAI/OuteTTS-0.2-500M-GGUF/resolve/main/OuteTTS-0.2-500M-Q6_K.gguf";
    const std::string default_model_filename = "OuteTTS-0.2-500M-Q6_K.gguf";
    const std::string default_vocoder_model_url = "https://huggingface.co/ggml-org/WavTokenizer/resolve/main/WavTokenizer-Large-75-F16.gguf";
    const std::string default_vocoder_model_filename = "WavTokenizer-Large-75-F16.gguf";
    
    std::string model_path = "";
    std::string vocoder_model_path = "";
    std::string text_to_speak = "This is a test run of the text to speech system for llama_mobile, I hope you enjoy it as much as I do, thank you";
    
    // Parse command-line arguments
    int arg_index = 1;
    if (argc > 1) {
        // Check if first argument is a model path
        std::string first_arg = argv[arg_index];
        if (first_arg.find(".gguf") != std::string::npos) {
            model_path = first_arg;
            arg_index++;
            
            // Check if second argument is a vocoder model path
            if (argc > arg_index && std::string(argv[arg_index]).find(".gguf") != std::string::npos) {
                vocoder_model_path = argv[arg_index];
                arg_index++;
            }
        }
        
        // Get text from remaining arguments if provided
        if (argc > arg_index) {
            text_to_speak = "";
            for (int i = arg_index; i < argc; i++) {
                if (i > arg_index) text_to_speak += " ";
                text_to_speak += argv[i];
            }
        }
    }

    // Determine which model paths to use
    std::string final_model_path;
    std::string final_vocoder_path;
    
    if (!model_path.empty()) {
        // User provided a model path
        final_model_path = model_path;
    } else if (fileExists(local_model_path)) {
        // Local model exists
        final_model_path = local_model_path;
    } else {
        // Fallback to downloaded model
        final_model_path = default_model_filename;
        if (!downloadFile(default_model_url, default_model_filename, "TTS Model")) {
            return 1;
        }
    }
    
    if (!vocoder_model_path.empty()) {
        // User provided a vocoder path
        final_vocoder_path = vocoder_model_path;
    } else if (fileExists(local_vocoder_path)) {
        // Local vocoder exists
        final_vocoder_path = local_vocoder_path;
    } else {
        // Fallback to downloaded vocoder
        final_vocoder_path = default_vocoder_model_filename;
        if (!downloadFile(default_vocoder_model_url, default_vocoder_model_filename, "Vocoder Model")) {
            return 1;
        }
    }

    try {
        // Load TTS model
        common_params params;
        params.model.path = final_model_path;
        params.n_ctx = 2048;
        params.n_batch = 512;
        params.n_gpu_layers = 99; // Enable GPU acceleration
        params.cpuparams.n_threads = std::thread::hardware_concurrency();
        
        // TTS-specific settings
        params.n_predict = 500;
        params.sampling.temp = 0.7f;
        params.sampling.top_k = 40;
        params.sampling.top_p = 0.9f;

        llama_mobile::llama_mobile_context context;
        
        std::cout << "Loading TTS model: " << final_model_path << std::endl;
        if (!context.loadModel(params)) {
            std::cerr << "Failed to load TTS model." << std::endl;
            return 1;
        }

        std::cout << "Loading vocoder model: " << final_vocoder_path << std::endl;
        if (!context.initVocoder(final_vocoder_path)) {
            std::cerr << "Failed to load vocoder model." << std::endl;
            return 1;
        }

        if (!context.initSampling()) {
            std::cerr << "Failed to initialize sampling context." << std::endl;
            return 1;
        }

        std::cout << "Generating TTS prompt..." << std::endl;
        std::string formatted_prompt = context.getFormattedAudioCompletion("", text_to_speak);
        context.params.prompt = formatted_prompt;
        
        std::cout << "Getting guide tokens..." << std::endl;
        std::vector<llama_token> guide_tokens = context.getAudioCompletionGuideTokens(text_to_speak);
        context.setGuideTokens(guide_tokens);
        
        std::cout << "Starting TTS generation..." << std::endl;
        context.beginCompletion();
        context.loadPrompt();

        std::vector<llama_token> audio_tokens;
        int max_tokens = 500;
        int generated_tokens = 0;
        
        while (context.has_next_token && !context.is_interrupted && generated_tokens < max_tokens) {
            const auto token_output = context.doCompletion();
            generated_tokens++;
            
            // Check if token is in audio range (151672-155772)
            if (token_output.tok >= 151672 && token_output.tok <= 155772) {
                audio_tokens.push_back(token_output.tok);
            }
            
            // Check for end token
            if (token_output.tok == 151668) { // <|audio_end|>
                std::cout << "Found audio end token" << std::endl;
                break;
            }
        }

        std::cout << "Generated " << audio_tokens.size() << " audio tokens" << std::endl;
        
        if (audio_tokens.empty()) {
            std::cerr << "No audio tokens generated!" << std::endl;
            return 1;
        }

        std::cout << "Decoding audio tokens..." << std::endl;
        std::vector<float> audio_data = context.decodeAudioTokens(audio_tokens);
        
        if (audio_data.empty()) {
            std::cerr << "Failed to decode audio tokens!" << std::endl;
            return 1;
        }

        std::cout << "Generated " << audio_data.size() << " audio samples" << std::endl;
        
        std::string output_filename = "../files/output.wav";
        writeWavFile(output_filename, audio_data);
        
        std::cout << "TTS generation complete! Audio saved to " << output_filename << std::endl;
        std::cout << "You can play it with: aplay " << output_filename << " (Linux) or open " << output_filename << " (macOS)" << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}