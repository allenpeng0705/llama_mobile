// test_v2_multimodal.cpp — v2 multimodal (vision) module conformance.
// Usage: test_v2_multimodal <vision_model.gguf> <mmproj.gguf> <image file>
// Migrated from the deleted v1 test_core_multimodal.cpp, expressed with ONLY
// the v2 API: attach the mmproj, enable queries, and generate with PATH media
// (the engine appends the mtmd media marker automatically).
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
    if (argc < 4) {
        std::fprintf(stderr, "usage: %s <vision_model.gguf> <mmproj.gguf> <image>\n", argv[0]);
        return 2;
    }
    const std::string model_path = argv[1];
    const std::string mmproj_path = argv[2];
    const std::string image_path  = argv[3];

    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    cc.model_path = model_path.c_str();
    cc.n_ctx = 4096;
    cc.n_gpu_layers = 0; // host CPU
    cc.n_threads = 4;

    llama_mobile_context_t ctx = nullptr;
    CHECK(llama_mobile_context_create(&cc, &ctx) == LLAMA_MOBILE_OK,
          "context_create(vision model) OK");
    if (!ctx) return 1;

    CHECK(llama_mobile_multimodal_init(ctx, mmproj_path.c_str()) == LLAMA_MOBILE_OK,
          "multimodal_init OK");
    CHECK(llama_mobile_multimodal_is_enabled(ctx), "multimodal_is_enabled true");
    CHECK(llama_mobile_multimodal_supports_vision(ctx), "multimodal_supports_vision true");
    std::printf("note: supports_audio=%d\n", llama_mobile_multimodal_supports_audio(ctx) ? 1 : 0);

    llama_mobile_media_t media;
    media.kind = LLAMA_MOBILE_MEDIA_PATH;
    media.path = image_path.c_str();
    media.bytes = nullptr;
    media.bytes_len = 0;
    media.mime = nullptr;

    llama_mobile_generate_params_t gp;
    llama_mobile_generate_params_init(&gp);
    // The engine appends the mtmd media marker ("<__media__>") automatically.
    gp.prompt = "Describe what you see in this image in one short sentence.";
    gp.max_tokens = 48;
    gp.sampling.temperature = 0.2f;
    gp.media = &media;
    gp.n_media = 1;

    llama_mobile_generate_result_t res;
    llama_mobile_status_t s = llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &res);
    CHECK(s == LLAMA_MOBILE_OK && res.text && res.text[0] != '\0',
          "generate(with image media) returns text");
    if (s == LLAMA_MOBILE_OK && res.text) {
        std::printf("note: multimodal text: %.120s…\n", res.text);
        llama_mobile_generate_result_free(&res);
    }

    CHECK(llama_mobile_multimodal_release(ctx) == LLAMA_MOBILE_OK, "multimodal_release OK");
    CHECK(!llama_mobile_multimodal_is_enabled(ctx), "multimodal disabled after release");

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
