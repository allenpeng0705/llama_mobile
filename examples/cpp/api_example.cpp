// api_example.cpp — llama_mobile v2 API tour (C API).
//
// Walks the v2 surface that needs no/little model setup: version/capabilities,
// status table, logging, model registry, plus an optional one-shot chat when a
// model path is supplied. Mirror of the API docs in lib/llama_mobile_v2.h.
//
// Usage: ./llama_mobile_api_example [chat.gguf]
#include <cstdio>
#include <string>

#include "llama_mobile_v2.h"
#include "utils.h"

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();

    // 1) Identity ------------------------------------------------------------
    const llama_mobile_version_info_t * ver = llama_mobile_version();
    std::printf("llama_mobile %s  (api v%d)\n", ver->string, ver->api_version);

    // 2) Status strings ------------------------------------------------------
    const llama_mobile_status_t codes[] = {
        LLAMA_MOBILE_OK, LLAMA_MOBILE_ERR_INVALID_ARGUMENT, LLAMA_MOBILE_ERR_GENERATION,
        LLAMA_MOBILE_ERR_MODEL_NOT_FOUND, LLAMA_MOBILE_ERR_ALREADY_RUNNING,
        LLAMA_MOBILE_ERR_ABORTED, LLAMA_MOBILE_ERR_NOT_INITIALIZED,
    };
    std::printf("status names:");
    for (auto c : codes) std::printf(" %s", llama_mobile_status_string(c));
    std::printf("\n");

    // 3) Capabilities --------------------------------------------------------
    llama_mobile_capabilities_t caps;
    if (llama_mobile_capabilities(&caps) == LLAMA_MOBILE_OK) {
        std::printf("caps: vision=%d tts=%d embeddings=%d lora=%d default_n_ctx=%u\n",
                    caps.supports_vision, caps.supports_tts, caps.supports_embeddings,
                    caps.supports_lora, caps.default_n_ctx);
        if (caps.device_name) std::printf("device: %s\n", caps.device_name);
    }

    // 4) Logging -------------------------------------------------------------
    llama_mobile_log_set_level(LLAMA_MOBILE_LOG_WARN);

    // 5) Model registry (may be empty on a fresh host) -----------------------
    llama_mobile_model_entry_t * entries = nullptr;
    size_t count = 0;
    if (llama_mobile_models_list(&entries, &count) == LLAMA_MOBILE_OK) {
        std::printf("registry: %zu model(s)\n", count);
        for (size_t i = 0; i < count; ++i) {
            std::printf("  %s (%lld bytes) %s\n", entries[i].name,
                        (long long) entries[i].size_bytes, entries[i].path);
        }
        llama_mobile_models_list_free(entries, count);
    }

    // 6) Optional one-shot chat ----------------------------------------------
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/SmolLM-360M-Instruct.Q6_K.gguf");
    if (!model.empty() && lmex::file_exists(model)) {
        llama_mobile_context_config_t cfg;
        llama_mobile_context_config_init(&cfg);
        cfg.model_path = model.c_str();
        cfg.n_ctx = 1024;
        cfg.engine = LLAMA_MOBILE_ENGINE_CPU;
        cfg.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_CHAT;
        llama_mobile_context_t ctx = nullptr;
        llama_mobile_status_t st = llama_mobile_context_create(&cfg, &ctx);
        if (st == LLAMA_MOBILE_OK) {
            llama_mobile_model_info_t info;
            if (llama_mobile_model_info(ctx, &info) == LLAMA_MOBILE_OK) {
                std::printf("model: %s\n", info.description);
            }
            llama_mobile_message_t msgs[] = {
                {"user", "Say 'API tour complete' in 5 words or fewer.", nullptr, nullptr, nullptr},
            };
            llama_mobile_generate_params_t p;
            llama_mobile_generate_params_init(&p);
            p.messages = msgs;
            p.n_messages = 1;
            p.max_tokens = 24;
            p.sampling.temperature = 0;
            llama_mobile_generate_result_t r;
            uint64_t rid = 0;
            st = llama_mobile_generate(ctx, &p, nullptr, nullptr, &rid, &r);
            if (st == LLAMA_MOBILE_OK) {
                std::printf("chat: %s\n", r.text);
                llama_mobile_generate_result_free(&r);
            }
            llama_mobile_context_destroy(&ctx);
        } else {
            std::printf("model open failed: %s\n", llama_mobile_status_string(st));
        }
    } else {
        std::printf("(no model arg — pass one to also run the chat tour)\n");
    }
    return 0;
}
