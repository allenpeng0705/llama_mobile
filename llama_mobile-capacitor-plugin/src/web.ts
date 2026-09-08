// web.ts — llama_mobile v2 Capacitor plugin web stub (M7)
//
// The llama_mobile native core has no WebAssembly/Web backend, so every method
// fails fast with an explicit "not supported on web" error (no silent no-op).

import { WebPlugin } from '@capacitor/core';
import type {
  LlamaEngineConfig,
  LlamaGenerationRequest,
  LlamaGenerationResult,
  LlamaMobileBridge,
  LlamaModelInfo,
} from './definitions';

export class LlamaMobileWeb extends WebPlugin implements LlamaMobileBridge {
  private unsupported(): never {
    throw new Error('llama_mobile is not supported on web (native core only)');
  }

  libraryVersion(): Promise<string> {
    return Promise.reject(this.unsupported());
  }
  open(_config: LlamaEngineConfig): Promise<number> {
    return Promise.reject(this.unsupported());
  }
  generate(
    _handle: number,
    _request: LlamaGenerationRequest,
  ): Promise<LlamaGenerationResult> {
    return Promise.reject(this.unsupported());
  }
  abort(_handle: number): Promise<boolean> {
    return Promise.reject(this.unsupported());
  }
  modelInfo(_handle: number): Promise<LlamaModelInfo> {
    return Promise.reject(this.unsupported());
  }
  initMultimodal(_handle: number, _mmprojPath: string): Promise<boolean> {
    return Promise.reject(this.unsupported());
  }
  tokenize(_handle: number, _text: string): Promise<number[]> {
    return Promise.reject(this.unsupported());
  }
  detokenize(_handle: number, _tokens: number[]): Promise<string> {
    return Promise.reject(this.unsupported());
  }
  embed(_handle: number, _texts: string[]): Promise<number[][]> {
    return Promise.reject(this.unsupported());
  }
  close(_handle: number): Promise<void> {
    return Promise.reject(this.unsupported());
  }
}
