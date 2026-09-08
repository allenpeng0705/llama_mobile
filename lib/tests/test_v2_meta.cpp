// test_v2_meta.cpp — v2 API conformance (no model).
// Verifies version/status/defaults/init/invalid-arg behavior of the v2 IDL
// (lib/llama_mobile_v2.h). Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <cstdio>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

int main() {
    std::printf("=== v2 meta tests (no model) ===\n");

    // Version/API level
    const llama_mobile_version_info_t * v = llama_mobile_version();
    CHECK(v && v->api_version == LLAMA_MOBILE_API_VERSION && v->api_version == 2,
          "version()->api_version == 2");
    CHECK(v && v->string && v->string[0], "version string present");

    // Status strings for the full v2 enum
    CHECK(llama_mobile_status_string(LLAMA_MOBILE_OK) != nullptr, "status OK");
    CHECK(llama_mobile_status_string(LLAMA_MOBILE_ERR_OOM) != nullptr, "status OOM");
    CHECK(llama_mobile_status_string(LLAMA_MOBILE_ERR_ABORTED) != nullptr, "status ABORTED");
    CHECK(llama_mobile_status_string(LLAMA_MOBILE_ERR_ALREADY_RUNNING) != nullptr,
          "status ALREADY_RUNNING");
    CHECK(llama_mobile_status_string((llama_mobile_status_t) 999) != nullptr,
          "status unknown non-null");

    // Defaults
    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    CHECK(cc.engine == LLAMA_MOBILE_ENGINE_AUTO, "config engine default AUTO");
    CHECK(cc.n_ctx == 2048, "config n_ctx default 2048");
    CHECK(cc.n_batch == 512 && cc.n_ubatch == 512, "config batch defaults 512");
    CHECK(cc.flags & LLAMA_MOBILE_CTX_MMAP, "config flags include MMAP");
    CHECK(cc.model_path == nullptr, "config model_path default NULL");

    llama_mobile_sampling_t sp;
    llama_mobile_sampling_init(&sp);
    CHECK(sp.seed == -1 && sp.temperature == 0.8f && sp.top_k == 40 && sp.top_p == 0.95f,
          "sampling defaults (seed/temp/top-k/p)");
    CHECK(sp.typical_p == 1.0f && sp.penalty_repeat == 1.1f && sp.mirostat == 0,
          "sampling defaults (typical/penalty/mirostat)");

    llama_mobile_generate_params_t gp;
    llama_mobile_generate_params_init(&gp);
    CHECK(gp.max_tokens == 128, "generate max_tokens default 128");
    CHECK(gp.prompt == nullptr && gp.messages == nullptr, "generate inputs default NULL");

    llama_mobile_tts_params_t tts;
    llama_mobile_tts_params_init(&tts);
    CHECK(tts.sample_rate == 24000 && tts.speed == 1.0f, "tts defaults");

    // Invalid-arg / lifecycle guards
    llama_mobile_context_t ctx = (llama_mobile_context_t) 1;
    CHECK(llama_mobile_context_create(nullptr, &ctx) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "context_create(NULL config) -> INVALID");
    CHECK(llama_mobile_context_destroy(nullptr) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "context_destroy(NULL) -> INVALID");
    llama_mobile_context_t nil = nullptr;
    CHECK(llama_mobile_context_destroy(&nil) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "context_destroy(&null ctx) -> INVALID");
    ctx = nullptr;

    llama_mobile_model_info_t mi;
    CHECK(llama_mobile_model_info(nullptr, &mi) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "model_info(NULL ctx) -> INVALID");
    CHECK(llama_mobile_context_stats(nullptr, nullptr) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "context_stats(NULL) -> INVALID");
    CHECK(llama_mobile_generate(nullptr, nullptr, nullptr, nullptr, nullptr, nullptr)
              == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "generate(NULL) -> INVALID");
    CHECK(llama_mobile_embed(nullptr, nullptr, 0, nullptr) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "embed(NULL) -> INVALID");
    CHECK(llama_mobile_tokenize(nullptr, "x", nullptr, 0, nullptr)
              == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "tokenize(NULL) -> INVALID");
    CHECK(llama_mobile_detokenize(nullptr, nullptr, 0, nullptr)
              == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "detokenize(NULL) -> INVALID");
    CHECK(llama_mobile_lora_load(nullptr, nullptr, 0) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "lora_load(NULL) -> INVALID");
    CHECK(llama_mobile_tts_init(nullptr, "x") == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
          "tts_init(NULL) -> INVALID");
    int16_t * pcm = nullptr;
    CHECK(llama_mobile_tts_speak(nullptr, nullptr, nullptr, &pcm, nullptr)
              == LLAMA_MOBILE_ERR_UNSUPPORTED,
          "tts_speak deferred -> UNSUPPORTED (no crash)");

    llama_mobile_capabilities_t caps;
    CHECK(llama_mobile_capabilities(&caps) == LLAMA_MOBILE_OK, "capabilities OK");
    CHECK(caps.supports_embeddings, "capabilities embeddings");

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
