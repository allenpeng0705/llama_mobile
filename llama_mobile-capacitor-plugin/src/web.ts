// web.ts — llama_mobile v2 Capacitor plugin web stub (M7)
//
// The llama_mobile native core has no WebAssembly/Web backend, so every method
// fails fast with an explicit "not supported on web" error (no silent no-op).

import { WebPlugin } from '@capacitor/core';
import type {
  LlamaEngineConfig,
  LlamaGenerationResult,
  LlamaMobileBridge,
  LlamaMobileBridgeRequest,
  LlamaModelInfo,
} from './definitions';

export class LlamaMobileWeb extends WebPlugin implements LlamaMobileBridge {
  private unsupported(): never {
    throw new Error('llama_mobile is not supported on web (native core only)');
  }

  libraryVersion(): Promise<string> {
    return Promise.reject(this.unsupported());
  }
  open(_options: LlamaEngineConfig): Promise<{ value: number }> {
    return Promise.reject(this.unsupported());
  }
  generate(
    _options: { handle: number } & LlamaMobileBridgeRequest,
  ): Promise<LlamaGenerationResult> {
    return Promise.reject(this.unsupported());
  }
  abort(_options: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  modelInfo(_options: { handle: number }): Promise<LlamaModelInfo> {
    return Promise.reject(this.unsupported());
  }
  initMultimodal(_options: { handle: number; mmprojPath: string }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  tokenize(_options: { handle: number; text: string }): Promise<{ value: number[] }> {
    return Promise.reject(this.unsupported());
  }
  detokenize(_options: { handle: number; tokens: number[] }): Promise<{ value: string }> {
    return Promise.reject(this.unsupported());
  }
  embed(_options: { handle: number; texts: string[] }): Promise<{ value: number[][] }> {
    return Promise.reject(this.unsupported());
  }
  close(_options: { handle: number }): Promise<void> {
    return Promise.reject(this.unsupported());
  }
  releaseMultimodal(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  multimodalEnabled(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  supportsVision(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  supportsAudio(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  ttsInit(_o: { handle: number; vocoderPath: string }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  ttsSpeak(_o: { handle: number; text: string; sampleRate?: number; speed?: number }): Promise<{ value: number[] }> {
    return Promise.reject(this.unsupported());
  }
  ttsRelease(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
  ttsEnabled(_o: { handle: number }): Promise<{ value: boolean }> {
    return Promise.reject(this.unsupported());
  }
}
