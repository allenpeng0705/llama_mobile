// direct_test.cpp
// Loads a model+context through llama_mobile's direct loader
// (llama_mobile_load_context_direct), bypassing llama.cpp's
// common_init_from_params (unstable when embedded; see llama_mobile_loader.cpp).
// Usage: direct_test [model.gguf]   (defaults to the SmolLM fixture)

#include "llama_mobile.h"
#include <iostream>
#include <string>

int main(int argc, char** argv) {
    try {
        std::cout << "Starting direct test...\n";

        common_params params; // NOLINT - intentionally POD defaults
        params.model.path = argc > 1 ? argv[1] : "../../../models/SmolLM-360M-Instruct.Q6_K.gguf";
        params.n_ctx = 2048;
        params.n_batch = 512;
        params.n_gpu_layers = 0; // CPU only for host tests
        params.cpuparams.n_threads = 4;
        params.load_mode = LLAMA_LOAD_MODE_AUTO;
        params.fit_params = false; // auto-fit probing unsupported when embedded
        params.no_extra_bufts = true; // avoid CPU repack extra-buft instability
        params.warmup = false;
        params.embedding = false;

        std::cout << "Creating model/context via direct loader...\n";

        llama_model * model = nullptr;
        llama_context * ctx = nullptr;
        if (!llama_mobile::llama_mobile_load_context_direct(params, &model, &ctx)) {
            std::cerr << "direct loader returned failure\n";
            return 1;
        }
        std::cout << "Model loaded successfully!\n";

        if (!model || !ctx) {
            std::cerr << "Model or context is null\n";
            return 1;
        }
        std::cout << "Model context is valid\n";

        // Test a simple tokenization using the model vocab
        std::string prompt = "Hello, world!";
        const llama_vocab * vocab = llama_model_get_vocab(model);
        if (!vocab) {
            std::cerr << "Failed to get vocabulary from model\n";
            return 1;
        }
        auto tokens = common_tokenize(vocab, prompt, true, false);
        std::cout << "Tokenization test: " << tokens.size() << " tokens generated\n";
        if (tokens.empty()) {
            std::cerr << "Tokenization produced no tokens\n";
            return 1;
        }

        llama_free(ctx);
        llama_free_model(model);

        std::cout << "Direct test completed successfully!\n";
        return 0;

    } catch (const std::exception& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        return 1;
    } catch (...) {
        std::cerr << "Unknown exception\n";
        return 1;
    }
}
