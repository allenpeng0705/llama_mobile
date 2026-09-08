// main_llm.cpp — llama_mobile v2 chat example (llama_mobile_v2.h C API).
//
// Demonstrates the v2 generation contract:
//   * context create with the chat flag (LLAMA_MOBILE_CTX_CHAT),
//   * structured chat messages (system/user/assistant),
//   * token streaming via the on_token callback,
//   * request-scoped abort from another thread (stopReason == ABORTED),
//   * modelInfo/context stats, status handling + usage timings.
//
// Usage: ./llama_mobile_llm [model.gguf] [prompt]
//   (defaults: any chat GGUF under ../../models, "Write a short story about
//   a llama that learns to code.")
#include <atomic>
#include <chrono>
#include <cstdio>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#include "llama_mobile_v2.h"
#include "utils.h"

static std::string stop_name(llama_mobile_stop_reason_t r) {
    switch (r) {
        case LLAMA_MOBILE_STOP_EOS:    return "eos";
        case LLAMA_MOBILE_STOP_WORD:   return "stop-word";
        case LLAMA_MOBILE_STOP_LENGTH: return "max-tokens";
        case LLAMA_MOBILE_STOP_ABORTED:return "aborted";
        default:                       return "error";
    }
}

// Prints one token and returns true to keep streaming.
static bool on_token(const char * token, void * user_data) {
    auto * stop_after = static_cast<std::atomic<int> *>(user_data);
    int n = stop_after->fetch_sub(1) - 1;   // countdown of remaining tokens
    if (token) std::fputs(token, stdout);
    std::fflush(stdout);
    return n > 0;  // false requests abort after `stop_after` more tokens
}

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/SmolLM-360M-Instruct.Q6_K.gguf");
    const std::string prompt = lmex::arg_or(
        argc, argv, 2, "Write a short story about a llama that learns to code.");

    if (!lmex::file_exists(model)) {
        std::cerr << "model not found: " << model << "\n"
                  << "usage: " << argv[0] << " [model.gguf] [prompt]\n";
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

    llama_mobile_model_info_t info;
    if (llama_mobile_model_info(ctx, &info) == LLAMA_MOBILE_OK) {
        std::cout << "model: " << info.description << " (" << info.n_params
                  << " params, n_ctx=" << info.n_ctx << ")\n";
    }

    // --- 1) structured chat, streaming -------------------------------------
    const llama_mobile_message_t msgs[] = {
        {"system", "You are a helpful, concise assistant.", nullptr, nullptr, nullptr},
        {"user", prompt.c_str(), nullptr, nullptr, nullptr},
    };
    llama_mobile_generate_params_t p;
    llama_mobile_generate_params_init(&p);
    p.messages = msgs;
    p.n_messages = 2;
    p.max_tokens = 96;
    p.sampling.temperature = 0.7f;

    std::atomic<int> budget(64);  // abort after ~64 streamed tokens
    uint64_t request_id = 0;
    std::cout << "\nQ: " << prompt << "\nA: ";
    llama_mobile_generate_result_t res;
    st = llama_mobile_generate(ctx, &p, on_token, &budget, &request_id, &res);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "\ngenerate failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_context_destroy(&ctx);
        return 1;
    }
    std::cout << "\n[stop=" << stop_name(res.stop_reason)
              << ", prompt=" << res.usage.prompt_tokens
              << ", gen=" << res.usage.generated_tokens
              << ", ttft=" << res.usage.time_to_first_token_ms
              << "ms, total=" << res.usage.total_ms << "ms]\n";
    llama_mobile_generate_result_free(&res);

    // --- 2) request-scoped abort from a second thread ----------------------
    // Start a long generation (ignore EOS) and abort it after ~1.2 s.
    llama_mobile_message_t msgs2[] = {
        {"user", "Write a very long essay about the history of llamas.", nullptr, nullptr, nullptr},
    };
    llama_mobile_generate_params_t p2;
    llama_mobile_generate_params_init(&p2);
    p2.messages = msgs2;
    p2.n_messages = 1;
    p2.max_tokens = 2000;
    p2.sampling.ignore_eos = true;

    std::cout << "\nStarting an unbounded generation, aborting it from a thread…\n";
    llama_mobile_generate_result_t res2;
    uint64_t rid2 = 0;
    std::atomic<bool> started(false);
    std::thread abort_thread([&]() {
        // Wait until the C API has published the request id, then abort.
        while (!started.load()) std::this_thread::sleep_for(std::chrono::milliseconds(10));
        std::this_thread::sleep_for(std::chrono::milliseconds(120)); // let it run
        llama_mobile_status_t as = llama_mobile_abort(ctx, rid2);
        std::cout << "[abort(rid=" << rid2 << ") returned "
                  << llama_mobile_status_string(as) << "]\n";
    });

    // Custom streaming: signal `started` once the first token flows (the
    // request id is already valid by then — llama_mobile_v2 sets it before
    // any token is produced).
    auto first_token = [](const char * t, void * ud) -> bool {
        auto * started = static_cast<std::atomic<bool> *>(ud);
        started->store(true);
        if (t) std::fputs(t, stdout);
        return true;
    };
    llama_mobile_status_t gen2_st = LLAMA_MOBILE_ERR_GENERATION;
    std::thread generator([&]() {
        gen2_st = llama_mobile_generate(ctx, &p2, first_token, &started, &rid2, &res2);
    });
    abort_thread.join();
    generator.join();
    std::cout << "\n[gen2 status=" << llama_mobile_status_string(gen2_st)
              << ", stop=" << stop_name(res2.stop_reason)
              << ", gen=" << res2.usage.generated_tokens << "]\n";
    llama_mobile_generate_result_free(&res2);

    // --- 3) context health --------------------------------------------------
    llama_mobile_context_stats_t stats;
    if (llama_mobile_context_stats(ctx, &stats) == LLAMA_MOBILE_OK) {
        std::cout << "KV usage: " << (int) (stats.kv_usage * 100) << "%\n";
    }

    llama_mobile_context_destroy(&ctx);
    return 0;
}
