// index.ts — llama_mobile v2 Capacitor plugin (M7)
//
// Public API: a `LlamaEngine` wrapper with the same semantics as the other v2
// wrappers (open/generate/abort/modelInfo/close), plus the low-level bridge.
// Web is not supported by the native core and fails fast.

import { registerPlugin } from '@capacitor/core';
import type { LlamaMobileBridge } from './definitions';

const bridge = registerPlugin<LlamaMobileBridge>('LlamaMobile', {
  web: () => import('./web').then(m => new m.LlamaMobileWeb()),
});

export * from './definitions';

/** Convenience wrapper owning one native engine handle. */
export class LlamaEngine {
  private constructor(private readonly handle: number) {}

  /** Library version reported by the native side. */
  static libraryVersion(): Promise<string> {
    return bridge.libraryVersion();
  }

  /** Opens (loads) a model context. Async by design — never blocks JS. */
  static open(config: import('./definitions').LlamaEngineConfig): Promise<LlamaEngine> {
    return bridge.open(config).then((h) => new LlamaEngine(h.value));
  }

  /** One generation. Rejects with an error whose `code` is the v2 status when
   *  another generation is already running on this engine. */
  generate(
    request: import('./definitions').LlamaGenerationRequest,
  ): Promise<import('./definitions').LlamaGenerationResult> {
    const {
      prompt,
      messages,
      mediaPaths,
      sampling,
      maxTokens,
      stopSequences,
      grammar,
      jsonSchema,
    } = request;
    const roles: string[] = [];
    const contents: string[] = [];
    for (const m of messages ?? []) {
      roles.push(m.role);
      contents.push(m.content);
    }
    // Native parsers read parallel roles/contents arrays; a chat request has
    // no prompt (never serialize an empty-string prompt that could be mistaken
    // for raw-prompt mode).
    const wire: import('./definitions').LlamaMobileBridgeRequest = {
      prompt: prompt && prompt.length > 0 ? prompt : undefined,
      roles: roles.length > 0 ? roles : undefined,
      contents: contents.length > 0 ? contents : undefined,
      mediaPaths:
        mediaPaths && mediaPaths.length > 0 ? mediaPaths : undefined,
      sampling,
      maxTokens,
      stopSequences:
        stopSequences && stopSequences.length > 0 ? stopSequences : undefined,
      grammar,
      jsonSchema,
    };
    return bridge.generate({ handle: this.handle, ...wire });
  }

  /** Thread-safe abort of the currently running generation. */
  abort(): Promise<boolean> {
    return bridge.abort({ handle: this.handle }).then((r) => r.value);
  }

  modelInfo(): Promise<import('./definitions').LlamaModelInfo> {
    return bridge.modelInfo({ handle: this.handle });
  }

  initMultimodal(mmprojPath: string): Promise<boolean> {
    return bridge.initMultimodal({ handle: this.handle, mmprojPath }).then((r) => r.value);
  }

  tokenize(text: string): Promise<number[]> {
    return bridge.tokenize({ handle: this.handle, text }).then((r) => r.value);
  }

  detokenize(tokens: number[]): Promise<string> {
    return bridge.detokenize({ handle: this.handle, tokens }).then((r) => r.value);
  }

  embed(texts: string[]): Promise<number[][]> {
    return bridge.embed({ handle: this.handle, texts }).then((r) => r.value);
  }

  close(): Promise<void> {
    return bridge.close({ handle: this.handle });
  }

  releaseMultimodal(): Promise<boolean> {
    return bridge.releaseMultimodal({ handle: this.handle }).then((r) => r.value);
  }

  multimodalEnabled(): Promise<boolean> {
    return bridge.multimodalEnabled({ handle: this.handle }).then((r) => r.value);
  }

  supportsVision(): Promise<boolean> {
    return bridge.supportsVision({ handle: this.handle }).then((r) => r.value);
  }

  supportsAudio(): Promise<boolean> {
    return bridge.supportsAudio({ handle: this.handle }).then((r) => r.value);
  }

  ttsInit(vocoderPath: string): Promise<boolean> {
    return bridge.ttsInit({ handle: this.handle, vocoderPath }).then((r) => r.value);
  }

  ttsSpeak(
    text: string,
    sampleRate?: number,
    speed?: number,
  ): Promise<number[]> {
    return bridge.ttsSpeak({ handle: this.handle, text, sampleRate, speed }).then((r) => r.value);
  }

  ttsRelease(): Promise<boolean> {
    return bridge.ttsRelease({ handle: this.handle }).then((r) => r.value);
  }

  ttsEnabled(): Promise<boolean> {
    return bridge.ttsEnabled({ handle: this.handle }).then((r) => r.value);
  }
}
