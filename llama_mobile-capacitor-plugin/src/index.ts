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
    return bridge.open(config).then(h => new LlamaEngine(h));
  }

  /** One generation. Rejects with an error whose `code` is the v2 status when
   *  another generation is already running on this engine. */
  generate(
    request: import('./definitions').LlamaGenerationRequest,
  ): Promise<import('./definitions').LlamaGenerationResult> {
    return bridge.generate(this.handle, request);
  }

  /** Thread-safe abort of the currently running generation. */
  abort(): Promise<boolean> {
    return bridge.abort(this.handle);
  }

  modelInfo(): Promise<import('./definitions').LlamaModelInfo> {
    return bridge.modelInfo(this.handle);
  }

  initMultimodal(mmprojPath: string): Promise<boolean> {
    return bridge.initMultimodal(this.handle, mmprojPath);
  }

  tokenize(text: string): Promise<number[]> {
    return bridge.tokenize(this.handle, text);
  }

  detokenize(tokens: number[]): Promise<string> {
    return bridge.detokenize(this.handle, tokens);
  }

  embed(texts: string[]): Promise<number[][]> {
    return bridge.embed(this.handle, texts);
  }

  close(): Promise<void> {
    return bridge.close(this.handle);
  }
}
