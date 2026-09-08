// test_v2_threads.cpp — v2 concurrency/abort conformance (model-based).
// Usage: test_v2_threads <model.gguf>
// Asserts the threading contract (§8.1/§8.4):
//   * abort() from another thread stops an in-flight generation
//   * a second concurrent call on the same context fails with ALREADY_RUNNING
//   * a cancelled generation completes with stop_reason == ABORTED
// Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <atomic>
#include <chrono>
#include <cstdio>
#include <string>
#include <thread>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

static bool never_stop(const char *, void *) { return true; }

int main(int argc, char ** argv) {
    if (argc < 2) { std::fprintf(stderr, "usage: %s <model.gguf>\n", argv[0]); return 2; }

    llama_mobile_context_config_t cc;
    llama_mobile_context_config_init(&cc);
    cc.model_path = argv[1];
    cc.n_gpu_layers = 0;
    cc.n_threads = 4;
    llama_mobile_context_t ctx = nullptr;
    if (llama_mobile_context_create(&cc, &ctx) != LLAMA_MOBILE_OK) {
        std::fprintf(stderr, "context_create failed\n");
        return 1;
    }

    // Start a long generation on a worker thread.
    std::atomic<int> started{0};
    llama_mobile_generate_result_t result;
    std::atomic<llama_mobile_status_t> status{LLAMA_MOBILE_ERR_GENERATION};
    uint64_t req = 0;

    std::thread worker([&] {
        llama_mobile_generate_params_t gp;
        llama_mobile_generate_params_init(&gp);
        gp.prompt = "Write a very long essay about the history of computing.";
        gp.max_tokens = 20000; // guarantee the run is still active when we abort
        gp.sampling.temperature = 0.2f;
        started.store(1);
        status.store(llama_mobile_generate(ctx, &gp, never_stop, nullptr, &req, &result));
    });

    // Wait for the worker to begin.
    while (!started.load()) { std::this_thread::sleep_for(std::chrono::milliseconds(2)); }
    std::this_thread::sleep_for(std::chrono::milliseconds(120)); // let it run

    // Second concurrent call must fail fast.
    llama_mobile_generate_params_t other;
    llama_mobile_generate_params_init(&other);
    other.prompt = "x";
    llama_mobile_generate_result_t other_res;
    llama_mobile_status_t s2 = llama_mobile_generate(ctx, &other, nullptr, nullptr, nullptr, &other_res);
    CHECK(s2 == LLAMA_MOBILE_ERR_ALREADY_RUNNING, "concurrent generate -> ALREADY_RUNNING");

    // Abort the running request from this (different) thread.
    llama_mobile_status_t sa = llama_mobile_abort(ctx, req);
    CHECK(sa == LLAMA_MOBILE_OK, "abort(active request) OK");

    worker.join();

    llama_mobile_status_t fin = status.load();
    CHECK(fin == LLAMA_MOBILE_OK, "cancelled generation returns OK (with ABORTED stop reason)");
    CHECK(result.stop_reason == LLAMA_MOBILE_STOP_ABORTED, "stop_reason == ABORTED after abort");
    llama_mobile_generate_result_free(&result);

    llama_mobile_context_destroy(&ctx);

    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
