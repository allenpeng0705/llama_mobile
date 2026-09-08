// test_v2_multimodal.cpp — v2 multimodal (vision) module conformance.
// Usage: test_v2_multimodal <vision_model.gguf> <mmproj.gguf> <image file>
// Migrated from the deleted v1 test_core_multimodal.cpp, expressed with ONLY
// the v2 API: attach the mmproj, enable queries, and generate with PATH media
// (the engine appends the mtmd media marker automatically).
// Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>
#include <cctype>

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

    // ---- Media BYTES / URI (file://) materialization ----------------------
    std::vector<unsigned char> bytes;
    FILE * f = std::fopen(image_path.c_str(), "rb");
    if (f) {
        unsigned char buf[65536];
        size_t n;
        while ((n = std::fread(buf, 1, sizeof(buf), f)) > 0) {
            bytes.insert(bytes.end(), buf, buf + n);
        }
        std::fclose(f);
    }
    CHECK(!bytes.empty(), "read image bytes for BYTES media test");

    llama_mobile_media_t media_b;
    media_b.kind = LLAMA_MOBILE_MEDIA_BYTES;
    media_b.path = nullptr;
    media_b.bytes = bytes.data();
    media_b.bytes_len = bytes.size();
    media_b.mime = "image/jpeg";

    gp.prompt = "Describe this picture in a few words.";
    gp.max_tokens = 24;
    gp.sampling.temperature = 0.2f;
    gp.media = &media_b;
    gp.n_media = 1;
    s = llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &res);
    CHECK(s == LLAMA_MOBILE_OK && res.text && res.text[0] != '\0',
          "generate with BYTES media returns text");
    if (s == LLAMA_MOBILE_OK && res.text) {
        std::printf("note: bytes-media text: %.120s…\n", res.text);
        llama_mobile_generate_result_free(&res);
    }

    // Media-aware tokenize with BYTES: has_media + per-chunk positions.
    llama_mobile_tokenize_result_t tr;
    memset(&tr, 0, sizeof(tr));
    s = llama_mobile_tokenize(ctx, "A picture.", &media_b, 1, &tr);
    CHECK(s == LLAMA_MOBILE_OK, "tokenize with BYTES media OK");
    CHECK(s == LLAMA_MOBILE_OK && tr.has_media, "tokenize media has_media true");
    CHECK(s == LLAMA_MOBILE_OK && tr.n_media_positions == 1,
          "tokenize media reports one chunk position");
    CHECK(s == LLAMA_MOBILE_OK && tr.n_tokens > 0, "tokenize media returns tokens");
    if (s == LLAMA_MOBILE_OK) llama_mobile_tokenize_result_free(&tr);

    // data:image base64 URI form (decode path in resolve_media).
    {
        static const char * b64tbl = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        std::string b64;
        for (size_t i = 0; i < bytes.size(); i += 3) {
            unsigned b0 = bytes[i];
            unsigned b1 = i + 1 < bytes.size() ? bytes[i + 1] : 0;
            unsigned b2 = i + 2 < bytes.size() ? bytes[i + 2] : 0;
            b64 += b64tbl[b0 >> 2];
            b64 += b64tbl[((b0 & 3) << 4) | (b1 >> 4)];
            b64 += i + 1 < bytes.size() ? b64tbl[((b1 & 15) << 2) | (b2 >> 6)] : '=';
            b64 += i + 2 < bytes.size() ? b64tbl[b2 & 63] : '=';
        }
        std::string uri = "data:image/jpeg;base64," + b64;
        llama_mobile_media_t media_d;
        media_d.kind = LLAMA_MOBILE_MEDIA_URI;
        media_d.path = uri.c_str();
        media_d.bytes = nullptr;
        media_d.bytes_len = 0;
        media_d.mime = nullptr;
        gp.prompt = "Describe this picture in a few words.";
        gp.max_tokens = 24;
        gp.media = &media_d;
        gp.n_media = 1;
        llama_mobile_generate_result_t dr;
        llama_mobile_status_t ds = llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &dr);
        CHECK(ds == LLAMA_MOBILE_OK && dr.text && dr.text[0] != '\0',
              "generate with data: URI media returns text");
        if (ds == LLAMA_MOBILE_OK && dr.text) llama_mobile_generate_result_free(&dr);
    }

    // URI file:// path form.
    std::string uri = std::string("file://") + image_path;
    llama_mobile_media_t media_u;
    media_u.kind = LLAMA_MOBILE_MEDIA_URI;
    media_u.path = uri.c_str();
    media_u.bytes = nullptr;
    media_u.bytes_len = 0;
    media_u.mime = nullptr;
    gp.prompt = "Describe this picture in a few words.";
    gp.max_tokens = 24;
    gp.media = &media_u;
    gp.n_media = 1;
    s = llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &res);
    CHECK(s == LLAMA_MOBILE_OK && res.text && res.text[0] != '\0',
          "generate with file:// URI media returns text");
    if (s == LLAMA_MOBILE_OK && res.text) {
        llama_mobile_generate_result_free(&res);
    }

    CHECK(llama_mobile_multimodal_release(ctx) == LLAMA_MOBILE_OK, "multimodal_release OK");
    CHECK(!llama_mobile_multimodal_is_enabled(ctx), "multimodal disabled after release");

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
