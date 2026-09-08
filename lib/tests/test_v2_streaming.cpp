// test_v2_streaming.cpp — v2 streaming/ordering conformance (model-based).
// Usage: test_v2_streaming <model.gguf>
// Migrated from the deleted v1 test_streaming.cpp / test_core_functional.cpp
// "token callback" coverage, expressed with ONLY the v2 API:
//   * the token stream is delivered in order and its pieces concatenate to
//     the final result text (raw-prompt mode, no stop sequences)
//   * the callback is invoked once per generated token (== usage.generated_tokens)
//   * a callback that returns false stops generation promptly (OK status;
//     today's stop_reason mapping for a callback stop is STOP_LENGTH)
//   * a short max_tokens run reports STOP_LENGTH
// Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <cstdio>
#include <cstring>
#include <string>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

struct StreamProbe {
    std::string pieces;   // concatenated token pieces, in order
    int calls = 0;
    int stop_after = 0;   // 0 = never stop early
};

static bool stream_cb(const char * token, void * ud) {
    StreamProbe * p = static_cast<StreamProbe *>(ud);
    if (token) p->pieces += token;
    p->calls++;
    return !(p->stop_after > 0 && p->calls >= p->stop_after);
}

int main(int argc, char ** argv) {
    if (argc < 2) { std::fprintf(stderr, "usage: %s <model.gguf>\n", argv[0]); return 2; }

    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    cc.model_path = argv[1];
    cc.n_gpu_layers = 0; // host CPU
    cc.n_threads = 4;
    cc.n_ctx = 2048;

    llama_mobile_context_t ctx = nullptr;
    if (llama_mobile_context_create(&cc, &ctx) != LLAMA_MOBILE_OK) {
        std::fprintf(stderr, "context_create failed\n");
        return 1;
    }

    // 1. Streaming order: pieces concatenate to the final text.
    {
        StreamProbe probe;
        probe.stop_after = 0;
        llama_mobile_generate_params_t gp;
        llama_mobile_generate_params_init(&gp);
        gp.prompt = "Say hello";
        gp.max_tokens = 24;
        gp.sampling.temperature = 0.2f;
        llama_mobile_generate_result_t res;
        CHECK(llama_mobile_generate(ctx, &gp, stream_cb, &probe, nullptr, &res) == LLAMA_MOBILE_OK,
              "streaming generate OK");
        CHECK(probe.calls > 0, "token callback fired");
        if (res.text && !probe.pieces.empty()) {
            CHECK(probe.pieces == res.text, "concatenated pieces == final text (order)");
            CHECK(probe.calls == res.usage.generated_tokens,
                  "callback calls == usage.generated_tokens");
            std::printf("note: streamed %d pieces, text=%.50s…\n", probe.calls, res.text);
        }
        llama_mobile_generate_result_free(&res);
    }

    // 2. Callback returning false stops generation promptly (OK status).
    {
        StreamProbe probe;
        probe.stop_after = 5;
        llama_mobile_generate_params_t gp;
        llama_mobile_generate_params_init(&gp);
        gp.prompt = "Write a very long story that keeps going and going.";
        gp.max_tokens = 512;
        gp.sampling.temperature = 0.2f;
        llama_mobile_generate_result_t res;
        CHECK(llama_mobile_generate(ctx, &gp, stream_cb, &probe, nullptr, &res) == LLAMA_MOBILE_OK,
              "callback early-stop returns OK");
        CHECK(probe.calls == 5, "callback stop respected (exactly 5 pieces)");
        if (res.text) {
            CHECK(res.usage.generated_tokens <= 8, "few tokens generated after early stop");
        }
        llama_mobile_generate_result_free(&res);
    }

    // 3. Short max_tokens -> STOP_LENGTH.
    {
        llama_mobile_generate_params_t gp;
        llama_mobile_generate_params_init(&gp);
        gp.prompt = "Say hello";
        gp.max_tokens = 3;
        gp.sampling.temperature = 0.2f;
        llama_mobile_generate_result_t res;
        CHECK(llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &res) == LLAMA_MOBILE_OK,
              "short generate OK");
        CHECK(res.usage.generated_tokens == 3, "generated exactly max_tokens tokens");
        CHECK(res.stop_reason == LLAMA_MOBILE_STOP_LENGTH, "stop_reason == LENGTH at token limit");
        llama_mobile_generate_result_free(&res);
    }

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
