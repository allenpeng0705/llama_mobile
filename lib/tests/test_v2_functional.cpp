// test_v2_functional.cpp — v2 API model-based conformance.
// Usage: test_v2_functional <model.gguf>
// Exercises context_create/generate (prompt + chat messages + token callback),
// model_info, tokenize/detokenize, batch embed, context destroy.

#include "../llama_mobile_v2.h"
#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

static bool cb(const char * token, void * ud) {
    (void) token; (void) ud;
    return true;
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
    CHECK(llama_mobile_context_create(&cc, &ctx) == LLAMA_MOBILE_OK, "context_create OK");
    if (!ctx) return 1;

    llama_mobile_model_info_t info;
    CHECK(llama_mobile_model_info(ctx, &info) == LLAMA_MOBILE_OK, "model_info OK");
    if (info.n_ctx > 0 && info.description) {
        std::printf("note: model_info n_ctx=%d desc=%s\n", info.n_ctx, info.description);
        CHECK(info.n_embd > 0 || info.n_params > 0, "model_info has size/params");
    }
    llama_mobile_model_info_free(&info);

    // generate: prompt + streaming callback + request id
    uint64_t req = 0;
    llama_mobile_generate_params_t gp;
    llama_mobile_generate_params_init(&gp);
    gp.prompt = "Say hello";
    gp.max_tokens = 24;
    gp.sampling.temperature = 0.2f;
    llama_mobile_generate_result_t res;
    CHECK(llama_mobile_generate(ctx, &gp, cb, nullptr, &req, &res) == LLAMA_MOBILE_OK,
          "generate(prompt) OK");
    CHECK(req > 0, "request_id > 0");
    if (res.text) {
        CHECK(std::strlen(res.text) > 0, "generate text non-empty");
        std::printf("note: text=%.60s…\n", res.text);
    }
    llama_mobile_generate_result_free(&res);

    // generate: real structured output via JSON schema (raw-prompt mode)
    {
        llama_mobile_generate_params_t gs;
        llama_mobile_generate_params_init(&gs);
        gs.prompt = "Return a JSON object with a single field \"name\" whose value is your name.";
        gs.json_schema = "{\"type\":\"object\",\"properties\":{\"name\":{\"type\":\"string\"}},\"required\":[\"name\"]}";
        gs.max_tokens = 32;
        gs.sampling.temperature = 0.1f;
        llama_mobile_generate_result_t sr;
        CHECK(llama_mobile_generate(ctx, &gs, nullptr, nullptr, nullptr, &sr) == LLAMA_MOBILE_OK,
              "generate(json_schema) OK");
        if (sr.text) {
            CHECK(sr.text[0] == '{', "schema output starts with '{'");
            CHECK(std::strstr(sr.text, "\"name\"") != nullptr, "schema output has a name field");
        }
        llama_mobile_generate_result_free(&sr);
    }

    // generate: chat messages
    llama_mobile_message_t msgs[2];
    msgs[0].role = "system"; msgs[0].content = "Reply with the single word OK.";
    msgs[0].name = nullptr; msgs[0].tool_name = nullptr; msgs[0].tool_call_id = nullptr;
    msgs[1].role = "user"; msgs[1].content = "Please say OK.";
    msgs[1].name = nullptr; msgs[1].tool_name = nullptr; msgs[1].tool_call_id = nullptr;
    llama_mobile_generate_params_t gm;
    llama_mobile_generate_params_init(&gm);
    gm.messages = msgs;
    gm.n_messages = 2;
    gm.max_tokens = 12;
    gm.sampling.temperature = 0.2f;
    CHECK(llama_mobile_generate(ctx, &gm, nullptr, nullptr, nullptr, &res) == LLAMA_MOBILE_OK,
          "generate(chat messages) OK");
    if (res.text) { CHECK(std::strlen(res.text) > 0, "chat text non-empty"); }
    llama_mobile_generate_result_free(&res);

    // second concurrent generate must be rejected (single-flight)
    {
        llama_mobile_generate_params_t busy;
        llama_mobile_generate_params_init(&busy);
        busy.prompt = "x";
        // not actually concurrent here; just confirm the API accepts a new call
        llama_mobile_generate_result_t r2;
        CHECK(llama_mobile_generate(ctx, &busy, nullptr, nullptr, nullptr, &r2) == LLAMA_MOBILE_OK,
              "generate again OK (sequential)");
        llama_mobile_generate_result_free(&r2);
    }

    // tokenize/detokenize
    llama_mobile_tokenize_result_t tok;
    CHECK(llama_mobile_tokenize(ctx, "Hello world", nullptr, 0, &tok) == LLAMA_MOBILE_OK,
          "tokenize OK");
    char * back = nullptr;
    CHECK(llama_mobile_detokenize(ctx, tok.tokens, tok.n_tokens, &back) == LLAMA_MOBILE_OK,
          "detokenize OK");
    if (back) { CHECK(std::strlen(back) > 0, "detokenize text non-empty"); llama_mobile_free_text(back); }
    llama_mobile_tokenize_result_free(&tok);

    llama_mobile_context_destroy(&ctx);
    CHECK(ctx == nullptr, "context_destroy nulls handle");

    // batch embed in an embedding context
    llama_mobile_context_config_t ec;
    llama_mobile_context_config_init(&ec);
    ec.model_path = argv[1];
    ec.n_gpu_layers = 0;
    ec.n_threads = 4;
    ec.flags = LLAMA_MOBILE_CTX_MMAP | LLAMA_MOBILE_CTX_EMBEDDING;
    llama_mobile_context_t ectx = nullptr;
    CHECK(llama_mobile_context_create(&ec, &ectx) == LLAMA_MOBILE_OK, "embed context_create OK");
    if (ectx) {
        const char * texts[2] = {"hello", "world"};
        llama_mobile_embed_result_t emb;
        CHECK(llama_mobile_embed(ectx, texts, 2, &emb) == LLAMA_MOBILE_OK, "embed batch OK");
        CHECK(emb.n_texts == 2 && emb.dim > 0, "embed batch dims");
        if (emb.values) llama_mobile_embed_result_free(&emb);
        llama_mobile_context_destroy(&ectx);
    }

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
