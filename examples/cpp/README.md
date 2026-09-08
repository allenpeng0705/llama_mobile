# llama_mobile v2 C++ examples

Independent host examples for the canonical v2 C API in
[`lib/llama_mobile_v2.h`](../../lib/llama_mobile_v2.h). The v1 examples
(`llama_mobile_api.h` / `llama_mobile_ffi.h`, conversation/vlm FFI binaries)
were removed with the rest of the v1 surface — every demo below is written
against the v2 C API that the SDKs wrap 1:1.

Each binary takes its model(s) from `argv`. With no arguments they default to
fixtures under `models/` at the repo root (set `LLAMA_MOBILE_MODELS_DIR` to
override).

| Binary | Source | Demonstrates |
|---|---|---|
| `llama_mobile_llm` | `main_llm.cpp` | context create (chat), structured messages, token streaming callback, **request-scoped abort from another thread** (`stopReason == aborted`), `modelInfo`/`context_stats` |
| `llama_mobile_embed` | `main_embed.cpp` | `LLAMA_MOBILE_CTX_EMBEDDING`, batch `embed`, dimension + cosine similarity |
| `llama_mobile_tts` | `main_tts.cpp` | `tts_init` (vocoder), full-text `tts_speak` (PCM + usage), optional WAV export |
| `llama_mobile_vlm` | `main_vlm.cpp` | `multimodal_init` (mmproj), image-in-prompt generation via media paths |
| `llama_mobile_dual_purpose` | `main_dual_purpose.cpp` | two contexts (chat + embedding) in one process; **single-flight**: a second concurrent generate fails with `-14 ALREADY_RUNNING`; abort |
| `llama_mobile_api_example` | `api_example.cpp` | version/capabilities/status/logging/model-registry tour + optional one-shot chat |
| `llama_mobile_benchmark` | `benchmark_example.cpp` | repeated greedy generations, tokens/s + latency from `usage` |

## Build

```bash
cd examples/cpp
./build.sh
```

## Run (from the repo root — `models/` holds the fixtures)

```bash
./examples/cpp/build/llama_mobile_llm        models/SmolLM-360M-Instruct.Q6_K.gguf
./examples/cpp/build/llama_mobile_embed      models/Qwen3-Embedding-0.6B-Q8_0.gguf
./examples/cpp/build/llama_mobile_tts        models/OuteTTS-0.2-500M-Q6_K.gguf \
                                             models/WavTokenizer-Large-75-F16.gguf /tmp/tts.wav
./examples/cpp/build/llama_mobile_vlm        models/SmolVLM-256M-Instruct-Q8_0.gguf \
                                             models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf \
                                             models/img/image.jpg
./examples/cpp/build/llama_mobile_dual_purpose models/SmolLM-360M-Instruct.Q6_K.gguf
./examples/cpp/build/llama_mobile_api_example  models/SmolLM-360M-Instruct.Q6_K.gguf
./examples/cpp/build/llama_mobile_benchmark    models/SmolLM-360M-Instruct.Q6_K.gguf 3 64
```

## Notes

- The examples compile and link `lib/llama_mobile_core_static` (same core that
  ships in the iOS/Android SDKs).
- Threading contract (§8): the C core is synchronous; `abort(ctx, request_id)`
  is thread-safe while a generation is in flight, and a second concurrent
  generation on one context fails fast with `LLAMA_MOBILE_ERR_ALREADY_RUNNING`.
