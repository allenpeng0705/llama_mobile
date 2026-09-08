# Changelog

## [2.0.0] — llama_mobile API v2 (branch)

### Breaking
- **V1 public API removed** on the v2 branch: `llama_mobile_api.h` (`*_t`),
  `llama_mobile_ffi.h` (`*_c`), v1 Swift/Java/Kotlin/Dart/TS wrapper surfaces,
  v1 C tests and facade (`LlamaMobile`, `LlamaContext`, etc.). See
  `docs/v1-purge-workplan.md` and `docs/MIGRATION.md`. The `v1.x` tag keeps the
  old line.
- One canonical IDL: `lib/llama_mobile_v2.h` (`LLAMA_MOBILE_API_VERSION = 2`),
  typed `llama_mobile_status_t` (0..-14), context + separate module inits
  (multimodal/tts/lora), single-flight `generate` + thread-safe
  `abort(request_id)`, real defaults via `<type>_init()`.
- Version across all SDKs/libs: **2.0.0** (`scripts/update_version.sh`).

### Added (v2 core, host-verified)
- Context lifecycle, model info/stats, generate (prompt **and** chat messages,
  media PATH/URI/BYTES incl. `file://` + `data:;base64`), JSON-schema→grammar
  structured output in **chat mode too**, **logit-bias**, tokenize/detokenize
  (media-aware with chunk positions), batch embeddings, multimodal module,
  TTS lifecycle (full-text `speak` pending owner review — `docs/TTS-v2-review.md`),
  LoRA, **download manager + model registry** (`download_start/cancel`,
  `models_list/remove/verify` with bundled SHA-256), logging, version/caps.
- Conformance suites: `test_v2_meta/functional/threads/streaming/lora/
  multimodal/tts/download` + `test_chat_template`/`direct_test` (all green).

### SDKs (core flows + wrapper parity)
- **iOS Swift `LlamaEngine`**: sync/async/stream/abort, model info,
  tokenize/detokenize/embed, multimodal init; v2 xcframework + SwiftPM
  lib/tests; example app.
- **Android `LlamaEngine`** (Kotlin impl, Java-usable — verified by a pure-Java
  instrumented test): sync + `CompletableFuture` + coroutines, abort, model info,
  tokenize/detokenize/embed, multimodal.
- **Flutter** `LlamaEngine` (async): open/generate/abort/modelInfo/close,
  tokenize/detokenize/embed, initMultimodal + mediaPaths; Android + iOS plugins.
- **Capacitor** `LlamaEngine` (TS) with Android + iOS native bridges (iOS
  SwiftPM `xcodebuild` green).
- aiNotes migrated to the v2 SDK (`flutter analyze` 0 errors); vision path
  re-enabled via the new multimodal/media surfaces.

### Added later (owner-signed)
- TTS full-text `speak` implemented per the signed-off contract
  (`docs/TTS-v2-review.md`): formatted audio prompt → guide tokens → greedy
  audio-code generation → vocoder decode → caller-owned int16 PCM with
  sample-rate/speed handling. Host-verified with OuteTTS + WavTokenizer
  fixtures (test_v2_tts, failures=0).

### Pending (owner/environment)
- Vulkan-enabled Android libs (Vulkan SDK install in progress).
- Physical-device QA and the atomic v2.0 release/rollout
  (`docs/RELEASE-v2.0.md`).
