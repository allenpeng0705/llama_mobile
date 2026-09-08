// main_dual_purpose.cpp — llama_mobile v2 dual-context example (C API).
//
// Shows the v2 threading contract (§8) from C++:
//   * two contexts in one process (a chat engine + an embedding engine) run
//     independently — the same pattern aiNotes uses on-device;
//   * one engine = one active generation: a second generate on the same
//     context while the first is in flight fails fast with
//     LLAMA_MOBILE_ERR_ALREADY_RUNNING (-14);
//   * abort() from another thread stops the running generation.
//
// Usage: ./llama_mobile_dual_purpose <chat.gguf> [embedding.gguf]
//   (defaults: SmolLM-360M chat + Qwen3-Embedding under ../../models)
#include <atomic>
#include <chrono>
#include <iostream>
#include <string>
#include <thread>

#include "llama_mobile_v2.h"
#include "utils.h"

static bool noop_token(const char *, void *) { return true; }

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string chat_model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/SmolLM-360M-Instruct.Q6_K.gguf");
    const std::string embed_model = lmex::arg_or(
        argc, argv, 2, dir.empty() ? "" : dir + "/Qwen3-Embedding-0.6B-Q8_0.gguf");

    // --- chat context -------------------------------------------------------
    llama_mobile_context_config_t chat_cfg;
    llama_mobile_context_config_init(&chat_cfg);
    chat_cfg.model_path = chat_model.c_str();
    chat_cfg.n_ctx = 1024;
    chat_cfg.engine = LLAMA_MOBILE_ENGINE_CPU;
    chat_cfg.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_CHAT;

    llama_mobile_context_t chat = nullptr;
    llama_mobile_status_t st = llama_mobile_context_create(&chat_cfg, &chat);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "chat context failed: " << llama_mobile_status_string(st) << "\n";
        return 1;
    }

    // --- embedding context (separate model) ---------------------------------
    llama_mobile_context_t emb = nullptr;
    if (lmex::file_exists(embed_model)) {
        llama_mobile_context_config_t emb_cfg;
        llama_mobile_context_config_init(&emb_cfg);
        emb_cfg.model_path = embed_model.c_str();
        emb_cfg.n_ctx = 512;
        emb_cfg.engine = LLAMA_MOBILE_ENGINE_CPU;
        emb_cfg.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_EMBEDDING;
        st = llama_mobile_context_create(&emb_cfg, &emb);
        if (st == LLAMA_MOBILE_OK) {
            const char * texts[] = {"one", "two"};
            llama_mobile_embed_result_t r;
            if (llama_mobile_embed(emb, texts, 2, &r) == LLAMA_MOBILE_OK) {
                std::cout << "embedding context OK (dim=" << r.dim << ")\n";
                llama_mobile_embed_result_free(&r);
            }
        } else {
            std::cout << "embedding context unavailable: "
                      << llama_mobile_status_string(st) << "\n";
        }
    }

    // --- single-flight: second generate while one runs -> -14 ---------------
    llama_mobile_message_t msgs[] = {
        {"user", "Write a long essay about llamas.", nullptr, nullptr, nullptr},
    };
    llama_mobile_generate_params_t p;
    llama_mobile_generate_params_init(&p);
    p.messages = msgs;
    p.n_messages = 1;
    p.max_tokens = 2000;
    p.sampling.ignore_eos = true;

    std::atomic<bool> first_started(false);
    auto signal_first = [](const char *, void * ud) -> bool {
        static_cast<std::atomic<bool> *>(ud)->store(true);
        return true;
    };

    uint64_t rid = 0;
    llama_mobile_generate_result_t res;
    std::thread generator([&]() {
        st = llama_mobile_generate(chat, &p, signal_first, &first_started, &rid, &res);
    });

    while (!first_started.load()) std::this_thread::sleep_for(std::chrono::milliseconds(5));

    // While the first generation is active, a second call must fail fast.
    llama_mobile_generate_result_t dup;
    llama_mobile_status_t dup_st = llama_mobile_generate(
        chat, &p, noop_token, nullptr, nullptr, &dup);
    std::cout << "second concurrent generate -> "
              << llama_mobile_status_string(dup_st)
              << (dup_st == LLAMA_MOBILE_ERR_ALREADY_RUNNING ? "  ✓ single-flight" : "") << "\n";

    // Abort the running generation (thread-safe request-scoped).
    llama_mobile_abort(chat, rid);
    generator.join();
    std::cout << "first generation stopped with reason="
              << (res.stop_reason == LLAMA_MOBILE_STOP_ABORTED ? "aborted" : "other")
              << "\n";
    llama_mobile_generate_result_free(&res);

    if (emb) llama_mobile_context_destroy(&emb);
    llama_mobile_context_destroy(&chat);
    return 0;
}
