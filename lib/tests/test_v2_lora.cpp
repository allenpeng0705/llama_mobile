// test_v2_lora.cpp — v2 LoRA module conformance (model-based).
// Usage: test_v2_lora <base_model.gguf> <lora_adapter.gguf>
// Migrated from the deleted v1 test_core_lora.cpp, expressed with ONLY the
// v2 API: load/list/remove adapters around plain generate calls.
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

static int do_simple_generate(llama_mobile_context_t ctx) {
    llama_mobile_generate_params_t gp;
    llama_mobile_generate_params_init(&gp);
    gp.prompt = "Say hello";
    gp.max_tokens = 16;
    gp.sampling.temperature = 0.2f;
    llama_mobile_generate_result_t res;
    llama_mobile_status_t s = llama_mobile_generate(ctx, &gp, nullptr, nullptr, nullptr, &res);
    if (s == LLAMA_MOBILE_OK) {
        llama_mobile_generate_result_free(&res);
        return 0;
    }
    return (int) s;
}

int main(int argc, char ** argv) {
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <base_model.gguf> <lora_adapter.gguf>\n", argv[0]);
        return 2;
    }
    const std::string model_path = argv[1];
    const std::string lora_path  = argv[2];

    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    cc.model_path = model_path.c_str();
    cc.n_gpu_layers = 0; // host CPU
    cc.n_threads = 4;
    cc.n_ctx = 2048;

    llama_mobile_context_t ctx = nullptr;
    if (llama_mobile_context_create(&cc, &ctx) != LLAMA_MOBILE_OK) {
        std::fprintf(stderr, "context_create(base model) failed\n");
        return 1;
    }

    // Baseline completion before LoRA
    int rc = do_simple_generate(ctx);
    CHECK(rc == 0, "generate before LoRA succeeds");

    // Apply the adapter
    llama_mobile_lora_t adapter;
    adapter.path = lora_path.c_str();
    adapter.scale = 1.0f;
    llama_mobile_status_t load_status = llama_mobile_lora_load(ctx, &adapter, 1);
    CHECK(load_status == LLAMA_MOBILE_OK, "lora_load succeeds");
    if (load_status != LLAMA_MOBILE_OK) {
        llama_mobile_context_destroy(&ctx);
        std::printf("failures=%d\n", failures);
        return failures == 0 ? 0 : 1;
    }

    // List adapters via the v2 list API
    llama_mobile_lora_t * listed = nullptr;
    size_t n = 0;
    CHECK(llama_mobile_lora_list(ctx, &listed, &n) == LLAMA_MOBILE_OK, "lora_list OK");
    CHECK(n == 1, "loaded lora adapter count == 1");
    if (listed && n == 1) {
        CHECK(listed[0].scale == 1.0f, "loaded lora scale == 1.0");
        CHECK(listed[0].path && std::strcmp(listed[0].path, lora_path.c_str()) == 0,
              "loaded lora path matches");
    }
    llama_mobile_lora_list_free(listed, n);

    // Completion while the adapter is applied
    rc = do_simple_generate(ctx);
    CHECK(rc == 0, "generate with LoRA applied succeeds");

    // Remove and complete again
    CHECK(llama_mobile_lora_remove(ctx) == LLAMA_MOBILE_OK, "lora_remove OK");
    rc = do_simple_generate(ctx);
    CHECK(rc == 0, "generate after lora_remove succeeds");

    // List again: empty
    listed = nullptr;
    n = 99;
    CHECK(llama_mobile_lora_list(ctx, &listed, &n) == LLAMA_MOBILE_OK, "lora_list (after remove) OK");
    CHECK(n == 0, "loaded lora count == 0 after remove");
    llama_mobile_lora_list_free(listed, n);

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
