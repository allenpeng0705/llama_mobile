// test_v2_download.cpp — v2 download manager + model registry conformance.
// No model required: registry runs against a temp LLAMA_MOBILE_MODELS_DIR and
// the download test exercises the offline/failure path (unreachable host).
// Exits non-zero on any failure.

#include "../llama_mobile_v2.h"
#include <atomic>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <string>
#include <thread>
#include <unistd.h>

static int failures = 0;
#define CHECK(cond, msg) do { \
    if (!(cond)) { std::printf("FAIL: %s\n", msg); ++failures; } \
    else { std::printf("ok:   %s\n", msg); } \
} while (0)

int main() {
    // Isolated registry dir for this process.
    auto dir = std::filesystem::temp_directory_path() /
               ("llm_v2_dl_test_" + std::to_string(::getpid()));
    std::error_code ec;
    std::filesystem::remove_all(dir, ec);
    std::filesystem::create_directories(dir, ec);
    setenv("LLAMA_MOBILE_MODELS_DIR", dir.c_str(), 1);

    // ---- registry: list / verify / remove ---------------------------------
    {
        // Seed a fake model file.
        std::ofstream f((dir / "alpha.gguf").string(), std::ios::binary);
        f << "abc";
        f.close();
        // sha256("abc")
        static const char * ABC_SHA = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";

        llama_mobile_model_entry_t * entries = nullptr;
        size_t count = 0;
        CHECK(llama_mobile_models_list(&entries, &count) == LLAMA_MOBILE_OK,
              "models_list OK");
        bool found = false;
        for (size_t i = 0; i < count; ++i) {
            if (std::strcmp(entries[i].name, "alpha.gguf") == 0 && entries[i].size_bytes == 3) {
                found = true;
            }
        }
        CHECK(found, "models_list sees alpha.gguf (size 3)");
        llama_mobile_models_list_free(entries, count);

        std::string p = (dir / "alpha.gguf").string();
        CHECK(llama_mobile_models_verify(p.c_str(), ABC_SHA) == LLAMA_MOBILE_OK,
              "models_verify correct sha256 OK");
        CHECK(llama_mobile_models_verify(p.c_str(), "deadbeef") == LLAMA_MOBILE_ERR_CHECKSUM,
              "models_verify wrong sha256 -> CHECKSUM");
        CHECK(llama_mobile_models_remove("alpha.gguf") == LLAMA_MOBILE_OK,
              "models_remove OK");
        CHECK(llama_mobile_models_remove("../evil") == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
              "models_remove rejects path traversal");
        entries = nullptr;
        count = 0;
        CHECK(llama_mobile_models_list(&entries, &count) == LLAMA_MOBILE_OK,
              "models_list after remove OK");
        bool still = false;
        for (size_t i = 0; i < count; ++i) {
            if (std::strcmp(entries[i].name, "alpha.gguf") == 0) still = true;
        }
        CHECK(!still, "models_list no longer lists removed model");
        llama_mobile_models_list_free(entries, count);
    }

    // ---- download: offline failure path + cancel validation ---------------
    {
        std::string dest = (dir / "dl").string();
        llama_mobile_download_request_t req;
        memset(&req, 0, sizeof(req));
        req.url_or_repo = "http://127.0.0.1:1/no-such-model.gguf";
        req.destination_dir = dest.c_str();

        struct Sink {
            std::atomic<bool> done{false};
            llama_mobile_download_state_t state = LLAMA_MOBILE_DL_QUEUED;
        } sink;
        llama_mobile_download_cb cb2 = [](const llama_mobile_download_event_t * ev, void * ud) {
            auto * s = static_cast<Sink *>(ud);
            if (ev->state == LLAMA_MOBILE_DL_DONE || ev->state == LLAMA_MOBILE_DL_FAILED ||
                ev->state == LLAMA_MOBILE_DL_CANCELLED) {
                s->state = ev->state;
                s->done.store(true);
            }
        };

        uint64_t rid = 0;
        llama_mobile_status_t st = llama_mobile_download_start(&req, cb2, &sink, &rid);
        CHECK(st == LLAMA_MOBILE_OK, "download_start OK (offline target)");
        CHECK(rid > 0, "download_start assigns request id");

        for (int i = 0; i < 100 && !sink.done.load(); ++i) {
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        }
        CHECK(sink.done.load(), "download reaches a terminal event");
        CHECK(sink.state == LLAMA_MOBILE_DL_FAILED,
              "offline download ends FAILED");

        CHECK(llama_mobile_download_cancel(rid + 999) == LLAMA_MOBILE_ERR_INVALID_ARGUMENT,
              "download_cancel unknown id -> INVALID_ARGUMENT");
        // Make sure the worker thread is finished before teardown.
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }

    std::filesystem::remove_all(dir, ec);
    std::printf("failures=%d\n", failures);
    return failures == 0 ? 0 : 1;
}
