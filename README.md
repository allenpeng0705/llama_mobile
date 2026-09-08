# llama_mobile

```
    _______________________
   /                       \
  /   ████████  ████████   \
 |    ██      ██      ██    |
 |    ██  LLAMA MOBILE ██    |
 |    ██      ██      ██    |
 |    ████████  ████████    |
 |                           |
 |  ╔════════════════════╗   |
 |  ║    AI ON THE GO    ║   |
 |  ║                     ║   |
 |  ║  • iOS & Android    ║   |
 |  ║  • Flutter          ║   |
 |  ║  • Capacitor        ║   |
 |  ╚════════════════════╝   |
 |                           |
 |       🧠 📱 🚀          |
  \_________________________/
        /\
       /  \
      /____\
```

A lightweight, high-performance framework for running AI models on mobile devices, based on llama.cpp and designed for cross-platform compatibility across iOS, Android, Flutter, and Capacitor. **Version: 2.0.0** (API v2 — the v1 public API was removed on the v2 branch; see [MIGRATION](docs/MIGRATION.md)).

## Project Overview

llama_mobile is a mobile-first AI framework that brings llama.cpp to iOS, Android, Flutter, and Capacitor through one canonical v2 C API (`lib/llama_mobile_v2.h`) and matching per-SDK wrappers (`LlamaEngine` on every platform). The v1 public surface (`llama_mobile_api.h`/`*_c`, `LlamaMobile` facades) has been fully removed; the `v1.x` git tag preserves the old line.

## Major Features (v2)

- **Local LLM inference**: prompt and chat-message generation with per-request `abort(request_id)` (thread-safe, single-flight per context)
- **Structured output**: real JSON-schema→grammar in both raw and chat modes
- **Typed media**: PATH / URI (`file://`, `data:;base64`) / BYTES in generate and media-aware tokenize
- **Batch embeddings**; tokenize/detokenize; model info/stats
- **Multimodal module** (mmproj attach + vision/media generation), **LoRA**, **TTS** lifecycle + full-text `speak` (owner-signed contract → PCM)
- **Download manager + model registry** with checksums (SHA-256)
- **Logit-bias**, per-context logging, version/capabilities
- **Threading contract (§8)**: every operation has sync + async forms (Dart/TS are async-only)
- **Hardware acceleration**: Metal (iOS), Vulkan on compatible Android devices (CPU fallback always available), Neon SIMD

## Project Structure

```
llama_mobile/
├── lib/                        # v2 core (llama_mobile_v2.h/.cpp + engine + tests)
├── llama_mobile-ios/           # iOS native framework output
├── llama_mobile-ios-SDK/       # iOS Swift SDK (LlamaEngine) + example
├── llama_mobile-android/       # Android native libraries
├── llama_mobile-android-SDK/   # Android SDK (Java + Kotlin LlamaEngine) + example
├── llama_mobile-flutter-SDK/   # Flutter plugin (Dart LlamaEngine)
├── llama_mobile-capacitor-plugin/  # Capacitor plugin (TS LlamaEngine; native only)
├── models/  grammars/  examples/  scripts/  docs/
└── README.md
```

Key docs: [MIGRATION](docs/MIGRATION.md) · [API contract](docs/api-contract-v2.md) · [Release checklist](docs/RELEASE-v2.0.md) · [TTS review](docs/TTS-v2-review.md) · [Branch status / review guide](docs/V2-BRANCH-STATUS.md) / [CHANGES-REVIEW](docs/CHANGES-REVIEW.md).

## Supported Platforms

| SDK | Directory | Notes |
|---|---|---|
| iOS (Swift) | `llama_mobile-ios-SDK/` | `LlamaEngine` — sync/async/stream/abort; Metal |
| Android (Java + Kotlin) | `llama_mobile-android-SDK/` | `LlamaEngine` — sync/`CompletableFuture`/coroutines; Vulkan (when built) |
| Flutter (Dart) | `llama_mobile-flutter-SDK/` | `LlamaEngine` async-only |
| Capacitor (TS) | `llama_mobile-capacitor-plugin/` | `LlamaEngine` async-only; **native only** (no web core) |

## Supported Models

Standard GGUF language models, chat models, embedding models, vision-Language (VLM + mmproj), and TTS (OuteTTS-family main + WavTokenizer vocoder). See `models/README.md`.

## Getting Started

- [iOS SDK README](llama_mobile-ios-SDK/README.md)
- [Android SDK README](llama_mobile-android-SDK/README.md)
- [Flutter SDK README](llama_mobile-flutter-SDK/README.md)
- [Capacitor plugin README](llama_mobile-capacitor-plugin/README.md)
- [Native core / build scripts](scripts/README.md) and host conformance suites under `lib/tests/` (`scripts/build-tests-run.sh`)

## Building the Project

Platform build scripts live in `scripts/` (`build-lib.sh`, `build-ios-framework.sh`, `build-ios-SDK.sh`, `build-android-lib.sh`, `build-macos-lib.sh`, …). Versioning across all SDKs is driven by `lib/llama_mobile_version.h` + `scripts/update_version.sh` (currently 2.0.0).

## Contributing & License

Contributions welcome (see per-component CONTRIBUTING/README). This project is licensed under the MIT License (see LICENSE).

## Acknowledgments

- Based on [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Inspired by the growing ecosystem of mobile AI solutions
