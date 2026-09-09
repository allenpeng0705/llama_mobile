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
 * Wire shape of a generate request sent to the native plugins. Chat messages
 * travel as parallel `roles`/`contents` arrays (exactly what every native
 * parser reads); the high-level [LlamaGenerationRequest] uses `messages` and
 * the [LlamaEngine] wrapper converts between the two. `prompt` is optional —
 * a chat request simply omits it (never coerce a missing prompt to "").
 */
export interface LlamaMobileBridgeRequest {
  prompt?: string;
  roles?: string[];
  contents?: string[];
  mediaPaths?: string[];
  sampling?: LlamaSampling;
  maxTokens?: number;
  stopSequences?: string[];
  grammar?: string | null;
  jsonSchema?: string | null;
}

/**
 * Low-level bridge: handle-based methods implemented by the native plugins.
 * Every method takes a single options object (Capacitor's native calling
 * convention) and scalar/list results are wrapped in `{ value: … }`; the
 * high-level `LlamaEngine` wrapper (index.ts) unwraps them.
 */
export interface LlamaMobileBridge {
  libraryVersion(): Promise<string>;
  open(options: LlamaEngineConfig): Promise<{ value: number }>;
  generate(
    options: { handle: number } & LlamaMobileBridgeRequest,
  ): Promise<LlamaGenerationResult>;
  abort(options: { handle: number }): Promise<{ value: boolean }>;
  modelInfo(options: { handle: number }): Promise<LlamaModelInfo>;
  initMultimodal(options: {
    handle: number;
    mmprojPath: string;
  }): Promise<{ value: boolean }>;
  tokenize(options: { handle: number; text: string }): Promise<{ value: number[] }>;
  detokenize(options: { handle: number; tokens: number[] }): Promise<{ value: string }>;
  embed(options: { handle: number; texts: string[] }): Promise<{ value: number[][] }>;
  close(options: { handle: number }): Promise<void>;
  releaseMultimodal(options: { handle: number }): Promise<{ value: boolean }>;
  multimodalEnabled(options: { handle: number }): Promise<{ value: boolean }>;
  supportsVision(options: { handle: number }): Promise<{ value: boolean }>;
  supportsAudio(options: { handle: number }): Promise<{ value: boolean }>;
  ttsInit(options: {
    handle: number;
    vocoderPath: string;
  }): Promise<{ value: boolean }>;
  ttsSpeak(options: {
    handle: number;
    text: string;
    sampleRate?: number;
    speed?: number;
  }): Promise<{ value: number[] }>;
  ttsRelease(options: { handle: number }): Promise<{ value: boolean }>;
  ttsEnabled(options: { handle: number }): Promise<{ value: boolean }>;
}
