// test_v2_tts.cpp — v2 TTS vocoder lifecycle conformance (host).
// Usage: test_v2_tts <main_model.gguf> <vocoder_model.gguf>
// Migrated from the deleted v1 test_core_tts.cpp, expressed with ONLY the v2
// API: exercises vocoder load via the engine direct loader, enable queries,
// the deferred full-text speak contract, and teardown.
// Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <cstdio>
#include <string>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

int main(int argc, char ** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <main_model.gguf> <vocoder_model.gguf>\n", argv[0]);
        return 2;
    }
    const std::string main_model = argv[1];
    const std::string vocoder_model = argv[2];

    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    cc.model_path = main_model.c_str();
    cc.n_gpu_layers = 0; // host CPU
    cc.n_threads = 4;
    cc.n_ctx = 2048;

    llama_mobile_context_t ctx = nullptr;
    if (llama_mobile_context_create(&cc, &ctx) != LLAMA_MOBILE_OK) {
        std::fprintf(stderr, "context_create(main model) failed\n");
        return 1;
    }

    CHECK(!llama_mobile_tts_is_enabled(ctx), "tts disabled before init");

    llama_mobile_status_t init_status = llama_mobile_tts_init(ctx, vocoder_model.c_str());
    CHECK(init_status == LLAMA_MOBILE_OK, "tts_init succeeds");
    if (init_status != LLAMA_MOBILE_OK) {
        llama_mobile_context_destroy(&ctx);
        std::printf("failures=%d\n", failures);
        return failures == 0 ? 0 : 1;
    }

    CHECK(llama_mobile_tts_is_enabled(ctx), "tts enabled after init");

    // Full-text speak is deferred by design (docs/tts-current-workflow.md).
    llama_mobile_tts_params_t tp;
    llama_mobile_tts_params_init(&tp);
    tp.text = "hi";
    int16_t * pcm = nullptr;
    size_t pcm_len = 0;
    llama_mobile_usage_t usage;
    CHECK(llama_mobile_tts_speak(ctx, &tp, &usage, &pcm, &pcm_len) == LLAMA_MOBILE_ERR_UNSUPPORTED,
          "tts_speak deferred -> UNSUPPORTED");
    CHECK(pcm == nullptr, "no pcm returned by deferred tts_speak");

    CHECK(llama_mobile_tts_release(ctx) == LLAMA_MOBILE_OK, "tts_release OK");
    CHECK(!llama_mobile_tts_is_enabled(ctx), "tts disabled after release");

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
