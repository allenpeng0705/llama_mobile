// main_embed.cpp — llama_mobile v2 embedding example (C API).
//
// Opens an embedding GGUF with LLAMA_MOBILE_CTX_EMBEDDING, embeds several
// texts in one batch, and reports dimension + cosine similarities.
//
// Usage: ./llama_mobile_embed [embedding_model.gguf]
//   (defaults to Qwen3-Embedding-0.6B-Q8_0.gguf under ../../models)
#include <cstdio>
#include <iostream>
#include <string>
#include <vector>

#include "llama_mobile_v2.h"
#include "utils.h"

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/Qwen3-Embedding-0.6B-Q8_0.gguf");

    if (!lmex::file_exists(model)) {
        std::cerr << "embedding model not found: " << model << "\n"
                  << "usage: " << argv[0] << " [embedding_model.gguf]\n";
        return 2;
    }

    llama_mobile_context_config_t cfg;
    llama_mobile_context_config_init(&cfg);
    cfg.model_path = model.c_str();
    cfg.n_ctx = 512;
    cfg.engine = LLAMA_MOBILE_ENGINE_CPU;
    cfg.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_EMBEDDING;

    llama_mobile_context_t ctx = nullptr;
    llama_mobile_status_t st = llama_mobile_context_create(&cfg, &ctx);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "context create failed: " << llama_mobile_status_string(st)
                  << "\n";
        return 1;
    }

    llama_mobile_model_info_t info;
    if (llama_mobile_model_info(ctx, &info) == LLAMA_MOBILE_OK) {
        std::cout << "model: " << info.description
                  << " (n_embd=" << info.n_embd << ")\n";
    }

    const char * texts[] = {
        "A cat sitting on a windowsill.",
        "A dog running in a park.",
        "The weather today is sunny and warm.",
    };

    llama_mobile_embed_result_t out;
    st = llama_mobile_embed(ctx, texts, 3, &out);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "embed failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_context_destroy(&ctx);
        return 1;
    }

    std::vector<std::vector<float>> rows(out.n_texts);
    for (size_t r = 0; r < out.n_texts; ++r) {
        rows[r].assign(out.values + r * out.dim, out.values + (r + 1) * out.dim);
    }
    std::cout << "dim=" << out.dim << ", rows=" << out.n_texts << "\n";
    std::cout << "first row head: ";
    for (size_t i = 0; i < std::min<size_t>(out.dim, 8); ++i) {
        std::printf("%+.4f ", rows[0][i]);
    }
    std::cout << "\n";
    llama_mobile_embed_result_free(&out);

    std::cout << "cosine(0,1) = " << lmex::dot(rows[0], rows[1]) /
                                         (lmex::norm(rows[0]) * lmex::norm(rows[1]))
              << "\n";
    std::cout << "cosine(0,2) = " << lmex::dot(rows[0], rows[2]) /
                                         (lmex::norm(rows[0]) * lmex::norm(rows[2]))
              << "\n";

    llama_mobile_context_destroy(&ctx);
    return 0;
}
