# llama_mobile Flutter SDK (v2)

The llama_mobile Flutter SDK exposes the v2 API (`lib/llama_mobile_v2.h`) to Flutter
through a single async Dart class, **`LlamaEngine`**. The v1 Dart surface
(`LlamaMobile`, platform-interface + method-channel split, downloader helpers) was
removed on the v2 branch (see `docs/v1-purge-workplan.md` and `docs/MIGRATION.md`).
Version: **2.0.0**.

## Quick start

```dart
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: '/models/model.gguf'));

final result = await engine.generate(LlamaGenerationRequest(
  messages: [LlamaChatMessage('user', 'What is 2+2?')],
  maxTokens: 128,
));
print(result.text); // LlamaGenerationResult { text, stopReason, usage }

await engine.abort();   // thread-safe: stops the running generation
await engine.close();   // idempotent
```

Dart is async-only (§8): none of these calls block the UI isolate; generation is
single-flight per engine (a concurrent call throws `LlamaException.alreadyRunning`).

## API surface

```dart
// Engine (instance of LlamaEngine)
engine.generate(LlamaGenerationRequest(   // prompt OR messages
  prompt: '…', messages: const [], mediaPaths: const ['/img.jpg'],
  sampling: LlamaSampling()..temperature = 0.7, maxTokens: 256,
  stopSequences: const [], grammar: null, jsonSchema: null,
));
engine.initMultimodal('/models/mmproj.gguf');  // vision: attach mmproj
engine.embed(['text a', 'text b']);            // requires embedding: true at open
engine.tokenize('hello');                      // List<int>
engine.detokenize([...]);                      // String
engine.modelInfo();                            // LlamaModelInfo
engine.abort();
engine.close();
LlamaEngine.libraryVersion();                  // '2.0.0'
```

Errors are typed `LlamaException` (status enum mirrors `llama_mobile_status_t`:
`alreadyRunning` -14, `aborted` -10, …).

## Project structure

```
llama_mobile-flutter-SDK/
├── lib/llama_mobile_flutter_sdk.dart   # v2 LlamaEngine (async) over method channel v2
├── android/                            # Android plugin: handler + LlamaEngine.kt + JNI + libs
├── ios/                                # iOS plugin: LlamaMobileFlutterSdkPlugin + LlamaEngine.swift + xcframework
├── example/                            # Chat demo app (v2)
├── test/                               # Pure-Dart unit tests
├── pubspec.yaml  CHANGELOG.md  README.md
```

## Native requirements & builds

- Android: arm64-v8a + x86_64 static core bundled in `android/src/main/jniLibs`
  (CPU build by default; Vulkan-enabled libs when built with the Vulkan SDK —
  CMake links `ggml-vulkan` only when present).
- iOS: vendored `ios/LlamaMobile/llama_mobile.xcframework` (v2 module).
- Rebuild native artifacts via the repo root `scripts/` (build-ios-framework,
  build-android-lib) then re-copy; see the root README.

Verify locally:
```bash
flutter pub get
flutter analyze          # no issues
flutter test             # pure-Dart v2 tests
cd example && flutter build apk --debug          # Android plugin + JNI
cd example && flutter build ios --no-codesign --debug   # iOS plugin + wrapper
```

## Threading contract (docs/api-contract-v2.md §8)

Async-only on Dart; one active generation per engine (single-flight); `abort()`
is thread-safe; results surface `stopReason` (`eos/word/length/aborted/error`).

## More docs

- `../docs/MIGRATION.md` (v1→v2) · `../docs/api-contract-v2.md` · `../CHANGELOG.md`
- Root `../README.md` for the full repo layout and build matrix.
