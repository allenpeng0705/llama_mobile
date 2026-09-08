// benchmark_example.cpp — llama_mobile v2 host benchmark (C API).
//
// Runs `iterations` greedy generations of `max_tokens` each on the same chat
// context and reports tokens/sec + latency from llama_mobile_usage_t.
//
// Usage: ./llama_mobile_benchmark [model.gguf] [iterations=3] [max_tokens=64]
#include <chrono>
#include <cstdio>
#include <iostream>
#include <string>

#include "llama_mobile_v2.h"
#include "utils.h"

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/SmolLM-360M-Instruct.Q6_K.gguf");
    const int iterations = std::stoi(lmex::arg_or(argc, argv, 2, "3"));
    const int max_tokens = std::stoi(lmex::arg_or(argc, argv, 3, "64"));

    if (!lmex::file_exists(model)) {
        std::cerr << "model not found: " << model << "\n";
        return 2;
    }

    llama_mobile_context_config_t cfg;
    llama_mobile_context_config_init(&cfg);
    cfg.model_path = model.c_str();
    cfg.n_ctx = 2048;
    cfg.engine = LLAMA_MOBILE_ENGINE_CPU;
    cfg.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_CHAT;

    llama_mobile_context_t ctx = nullptr;
    llama_mobile_status_t st = llama_mobile_context_create(&cfg, &ctx);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "context create failed: " << llama_mobile_status_string(st) << "\n";
        return 1;
    }

    llama_mobile_message_t msgs[] = {
        {"user", "Write a paragraph about the history of computing.", nullptr, nullptr, nullptr},
    };
    llama_mobile_generate_params_t p;
    llama_mobile_generate_params_init(&p);
    p.messages = msgs;
    p.n_messages = 1;
    p.max_tokens = max_tokens;
    p.sampling.temperature = 0;

    long long total_gen = 0;
    double total_ms = 0;
    for (int i = 0; i < iterations; ++i) {
        llama_mobile_generate_result_t r;
        uint64_t rid = 0;
        const auto t0 = std::chrono::steady_clock::now();
        st = llama_mobile_generate(ctx, &p, nullptr, nullptr, &rid, &r);
        const auto t1 = std::chrono::steady_clock::now();
        if (st != LLAMA_MOBILE_OK) {
            std::cerr << "generate #" << i << " failed: "
                      << llama_mobile_status_string(st) << "\n";
            llama_mobile_context_destroy(&ctx);
            return 1;
        }
        const double wall = std::chrono::duration<double, std::milli>(t1 - t0).count();
        total_gen += r.usage.generated_tokens;
        total_ms += wall;
        std::printf("iter %d: %d tokens in %.0f ms (%.1f tok/s)\n", i,
                    r.usage.generated_tokens, wall,
                    r.usage.generated_tokens > 0
                        ? r.usage.generated_tokens / (wall / 1000.0)
                        : 0.0);
        llama_mobile_generate_result_free(&r);
    }

    if (total_ms > 0) {
        std::printf("avg: %.1f tok/s over %d iterations\n",
                    total_gen / (total_ms / 1000.0), iterations);
    }
    llama_mobile_context_destroy(&ctx);
    return 0;
}
