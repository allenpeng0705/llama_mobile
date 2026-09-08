# llama_mobile Android SDK (v2) — Java & Kotlin

The v2 Android SDK exposes one engine type — `com.llamamobile.LlamaEngine` —
implemented in Kotlin but fully usable from **Java and Kotlin** (Kotlin
`@JvmStatic` factories + `CompletableFuture` async APIs; bean-style `Config`).
It talks to the v2 native core (`lib/llama_mobile_v2.h`) through the bundled
JNI layer. The v1 `LlamaMobile`/`LlamaContext` APIs were removed on the v2
branch (see `docs/v1-purge-workplan.md`).

Version: 2.0.0 (see root `lib/llama_mobile_version.h`).

## Add it
Include this module (`llama_mobile-android-SDK`) in your Gradle build (it
bundles `libllama_mobile_jni.so` for arm64-v8a + x86_64 and the v2 static core).

## Kotlin

```kotlin
import com.llamamobile.*

val config = LlamaEngine.Config().apply {
    modelPath = "/models/model.gguf"
    nCtx = 2048
}
// Async open (never blocks the UI thread):
val engine = LlamaEngine.openAsync(config).get()          // or use coroutines:
// val engine = withContext(Dispatchers.Default) { LlamaEngine.open(config) }

val result = engine.generateAsync(
    LlamaGenerationRequest(
        messages = listOf(LlamaChatMessage("user", "Hello!")),
        maxTokens = 128,
    ),
).get()                                                    // + .thenApply on UI

// Token stream (callback on the engine executor):
engine.generateAsync(req, TokenCallback { token -> print(token); true })

engine.abort()          // thread-safe, stops the running generation
val info = engine.modelInfo()
engine.close()
```

## Java

```java
import com.llamamobile.LlamaEngine;

LlamaEngine.Config config = new LlamaEngine.Config();
config.setModelPath("/models/model.gguf");
config.setNCtx(2048);

LlamaEngine engine = LlamaEngine.open(config);          // blocking — off the main thread
LlamaGenerationRequest req = new LlamaGenerationRequest();
req.setMessages(List.of(new LlamaChatMessage("user", "Hello!")));
req.setMaxTokens(128);

LlamaGenerationResult r = engine.generate(req, null);   // blocking form
// Non-blocking: engine.generateAsync(req, null).thenAccept(r -> …);
engine.abort();
engine.close();
```

## Notes
- Threading contract (§8): use the `*Async`/`CompletableFuture`/coroutine forms
  from UI code; blocking forms are for background threads.
- One engine = one active generation (`LlamaException` with status
  `ALREADY_RUNNING`); `abort()` is thread-safe.
- Embeddings require opening with `embedding = true` (`engine.embed(list)`);
  multimodal images require `engine.initMultimodal(mmproj)` then
  `request.mediaPaths`.
- Also available: `tokenize(text)`, `detokenize(tokens)`, `modelInfo()`.

## Tests
- Kotlin instrumented suite: `LlamaEngineTests.kt` (10 tests — §8 sync/async,
  streaming + thread-safe abort, single-flight, idempotent close, GPU/Vulkan
  smoke, plus `modelInfo` fields, tokenize/detokenize round-trip and a real
  `embed` on the Qwen3-Embedding fixture).
- Pure-Java interop: `LlamaEngineJavaTest.java` (3 tests, incl. model-backed
  `modelInfo` + tokenize from Java).
- Run everything with `scripts/android-run-instrumented.sh` from the repo root:
  it pushes `SmolLM-360M-Instruct.Q6_K.gguf` **and** the embedding model into
  the test app's own external dir, then runs `connectedDebugAndroidTest`.
  Verified green (13/13) on a Pixel 9 Pro Fold (Android 17).

## Native libs
Bundled static cores: CPU by default; Vulkan-enabled artifacts when built with
the Vulkan SDK (repo root `scripts/build-android-lib.sh`, `GGML_VULKAN=ON`).
`build.gradle` also exposes `publishToMavenLocal` (AAR/POM/module, 2.0.0).

- See `docs/MIGRATION.md` and `lib/llama_mobile_v2.h` for the full contract.
