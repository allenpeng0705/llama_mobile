// definitions.ts — llama_mobile v2 Capacitor plugin definitions (M7)
//
// Threading contract (docs/api-contract-v2.md §8): TypeScript/Capacitor is
// async-only; none of these calls block the JS thread. The native side keeps
// one active generation per engine (single-flight) and `abort` is thread-safe.

export interface LlamaEngineConfig {
  modelPath: string;
  engine?: number; // 0=AUTO 1=CPU 2=METAL 3=VULKAN 4=OPENCL
  nGpuLayers?: number;
  nCtx?: number; // default 2048
  nBatch?: number; // default 512
  nUBatch?: number; // default 512
  nThreads?: number; // 0 = auto
  useMmap?: boolean;
  useMlock?: boolean;
  embedding?: boolean;
  flashAttention?: boolean;
  chat?: boolean; // enable chat template
  kvCacheTypeK?: string | null;
  kvCacheTypeV?: string | null;
  chatTemplate?: string | null;
  systemPrompt?: string | null;
}

export interface LlamaSampling {
  seed?: number;
  temperature?: number; // default 0.8
  topK?: number; // default 40
  topP?: number; // default 0.95
  minP?: number; // default 0.05
  typicalP?: number; // default 1.0
  penaltyRepeat?: number; // default 1.1
  penaltyLastN?: number; // default 64
  penaltyFreq?: number;
  penaltyPresent?: number;
  mirostat?: number;
  mirostatTau?: number;
  mirostatEta?: number;
  ignoreEos?: boolean;
}

export interface LlamaChatMessage {
  role: string;
  content: string;
}

/** Exactly one of `prompt` or `messages` is used; image paths for vision. */
export interface LlamaGenerationRequest {
  prompt?: string;
  messages?: LlamaChatMessage[];
  mediaPaths?: string[];
  sampling?: LlamaSampling;
  maxTokens?: number; // default 128
  stopSequences?: string[];
  grammar?: string | null;
  jsonSchema?: string | null;
}

/** stopReason mirrors llama_mobile_stop_reason_t. */
export enum LlamaStopReason {
  Eos = 0,
  Word = 1,
  Length = 2,
  Aborted = 3,
  Error = 4,
}

export interface LlamaGenerationResult {
  text: string;
  stopReason: LlamaStopReason;
  promptTokens: number;
  generatedTokens: number;
}

export interface LlamaModelInfo {
  nCtx: number;
  nEmbd: number;
  modelSizeBytes: number;
  nParams: number;
  description: string;
}

/**
 * Low-level bridge: handle-based methods implemented by the native plugins.
 * Most apps should use the `LlamaEngine` wrapper from index.ts instead.
 */
export interface LlamaMobileBridge {
  libraryVersion(): Promise<string>;
  open(config: LlamaEngineConfig): Promise<number>;
  generate(
    handle: number,
    request: LlamaGenerationRequest,
  ): Promise<LlamaGenerationResult>;
  abort(handle: number): Promise<boolean>;
  modelInfo(handle: number): Promise<LlamaModelInfo>;
  initMultimodal(handle: number, mmprojPath: string): Promise<boolean>;
  tokenize(handle: number, text: string): Promise<number[]>;
  detokenize(handle: number, tokens: number[]): Promise<string>;
  embed(handle: number, texts: string[]): Promise<number[][]>;
  close(handle: number): Promise<void>;
}
