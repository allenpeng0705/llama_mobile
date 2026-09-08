# llama-mobile-capacitor-plugin (v2)

Capacitor plugin for llama_mobile **v2** (`lib/llama_mobile_v2.h`): on-device LLM
inference for iOS and Android through a single async TS class, **`LlamaEngine`**.
The v1 plugin surface (`LlamaMobileCapacitorPlugin.initContext/generateCompletion/…`)
was removed on the v2 branch (see `docs/MIGRATION.md`). Native bridge name:
`LlamaMobile` (registered via `registerPlugin('LlamaMobile')`). Version: **2.0.0**.

## Platform requirements

- **iOS**: iOS 15+, Xcode — native only (no web core; web calls fail fast).
- **Android**: minSdk 28+, arm64-v8a + x86_64 static core bundled (CPU default;
  Vulkan-enabled when built with the Vulkan SDK).

## Quick start

```typescript
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';

// Open a model (async — never blocks JS)
const engine = await LlamaEngine.open({ modelPath: '/models/model.gguf', nCtx: 2048 });

const result = await engine.generate({
  messages: [{ role: 'user', content: 'What is 2+2?' }],
  maxTokens: 128,
});
console.log(result.text, result.stopReason, result.promptTokens, result.generatedTokens);

await engine.abort();  // thread-safe stop of the running generation
await engine.close();
```

## API

`LlamaEngine` methods (async-only, §8):

- `static open(config)` → engine; `static libraryVersion()` → `'2.0.0'`
- `generate(request)` — prompt or messages (+ `mediaPaths`, sampling, stopSequences, grammar/jsonSchema)
- `abort()` / `modelInfo()` / `close()`
- `tokenize(text): number[]` / `detokenize(tokens): string` / `embed(texts): number[][]`
- `initMultimodal(mmprojPath)` — attach an mmproj, then use `mediaPaths` for vision
- Web platform stub rejects with “not supported on web”.

Types: `LlamaEngineConfig`, `LlamaSampling`, `LlamaChatMessage`,
`LlamaGenerationRequest`, `LlamaGenerationResult` (with `LlamaStopReason`),
`LlamaModelInfo` — see `src/definitions.ts`.

## Build & verify

```bash
npm install
npx tsc --noEmit          # typecheck
npm run build             # dist bundle
# native:
cd android && ./gradlew assembleDebug     # Android plugin (Kotlin/JNI)
cd ios && xcodebuild -scheme LlamaMobileCapacitorPlugin \
  -destination 'generic/platform=iOS Simulator' build   # iOS Swift plugin
```

Publishing is done with `npm publish` (version 2.0.0; `package.json`/lock synced).
Native cores are rebuilt from the llama_mobile repo root (`scripts/build-android-lib.sh`,
`scripts/build-ios-framework.sh`) and copied into `android/libs` / `ios/Libraries`.

## More docs

`../docs/MIGRATION.md` · `../docs/api-contract-v2.md` · root `../README.md`.
