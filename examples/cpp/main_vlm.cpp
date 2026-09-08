// main_vlm.cpp — llama_mobile v2 multimodal (vision) example (C API).
//
// Opens a vision LLM (e.g. SmolVLM-256M-Instruct), attaches an mmproj with
// llama_mobile_multimodal_init, then generates a caption for an image passed
// either as a path or a data: base64 URI (LLAMA_MOBILE_MEDIA_PATH/URI).
//
// Usage: ./llama_mobile_vlm <vision.gguf> <mmproj.gguf> <image path-or-data-URI>
//   (defaults: SmolVLM-256M-Instruct + mmproj-SmolVLM + models/img/image.jpg)
#include <iostream>
#include <string>

#include "llama_mobile_v2.h"
#include "utils.h"

int main(int argc, char ** argv) {
    const std::string dir = lmex::find_model_dir();
    const std::string model = lmex::arg_or(
        argc, argv, 1, dir.empty() ? "" : dir + "/SmolVLM-256M-Instruct-Q8_0.gguf");
    const std::string mmproj = lmex::arg_or(
        argc, argv, 2, dir.empty() ? "" : dir + "/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf");
    const std::string image = lmex::arg_or(
        argc, argv, 3, dir.empty() ? "" : dir + "/img/image.jpg");

    if (!lmex::file_exists(model) || !lmex::file_exists(mmproj)) {
        std::cerr << "usage: " << argv[0] << " <vision.gguf> <mmproj.gguf> <image>\n";
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

    st = llama_mobile_multimodal_init(ctx, mmproj.c_str());
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "multimodal_init failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_context_destroy(&ctx);
        return 1;
    }
    std::cout << "vision enabled: "
              << (llama_mobile_multimodal_supports_vision(ctx) ? "yes" : "no") << "\n";

    llama_mobile_media_t media;
    media.kind = LLAMA_MOBILE_MEDIA_PATH;
    media.path = image.c_str();
    media.bytes = nullptr;
    media.bytes_len = 0;
    media.mime = nullptr;

    llama_mobile_generate_params_t p;
    llama_mobile_generate_params_init(&p);
    p.prompt = "Describe this picture in one short sentence.";
    p.max_tokens = 48;
    p.sampling.temperature = 0;
    p.media = &media;
    p.n_media = 1;

    llama_mobile_generate_result_t res;
    uint64_t rid = 0;
    st = llama_mobile_generate(ctx, &p, nullptr, nullptr, &rid, &res);
    if (st != LLAMA_MOBILE_OK) {
        std::cerr << "vision generate failed: " << llama_mobile_status_string(st) << "\n";
        llama_mobile_multimodal_release(ctx);
        llama_mobile_context_destroy(&ctx);
        return 1;
    }
    std::cout << "image: " << image << "\ncaption: " << res.text << "\n";
    llama_mobile_generate_result_free(&res);

    llama_mobile_multimodal_release(ctx);
    llama_mobile_context_destroy(&ctx);
    return 0;
}
