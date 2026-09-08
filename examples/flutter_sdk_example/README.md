# flutter_sdk_example — llama_mobile v2 (LlamaEngine)

Flutter example migrated to the v2 Flutter SDK wrapper (`LlamaEngine`,
async-only). The old v1 `LlamaMobile` facade demo was removed on the v2 branch.

Four tabs matching the v2 wrapper surface:

- **Chat** — load a chat GGUF, single-shot `generate`, `abort` a running call.
- **Embed** — opens its own engine with `embedding = true`, batch-embeds one
  text, shows dimension/statistics, then releases the engine.
- **Vision** — load a vision model + `initMultimodal(mmproj)`, then generate a
  caption for an image via `mediaPaths`.
- **Model** — `modelInfo` + `tokenize`/`detokenize` round-trip.

TTS and LoRA are not yet exposed by the v2 Flutter wrapper (they live at the
core/iOS/Android level in v2.0).

Run:

```bash
flutter run          # device with a GGUF path entered in the UI
flutter analyze      # clean
flutter test         # widget smoke (tabs render)
```
