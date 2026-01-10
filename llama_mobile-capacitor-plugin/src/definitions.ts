export enum GrammarName {
  arithmetic = 'arithmetic',
  c = 'c',
  chess = 'chess',
  english = 'english',
  japanese = 'japanese',
  json = 'json',
  jsonArr = 'jsonArr',
  list = 'list',
}

export interface InitParams {
  modelPath: string;
  nCtx?: number;
  nGpuLayers?: number;
  nThreads?: number;
  nBatch?: number;
  nUbatch?: number;
  useMmap?: boolean;
  useMlock?: boolean;
  chatTemplate?: string;
  systemPrompt?: string;
  embedding?: boolean;
  poolingType?: number;
  embdNormalize?: boolean;
  flashAttn?: boolean;
  cacheTypeK?: string;
  cacheTypeV?: string;
}

export interface CompletionParams {
  prompt: string;
  maxTokens?: number;
  temperature?: number;
  topK?: number;
  topP?: number;
  minP?: number;
  typicalP?: number;
  seed?: number;
  nThreads?: number;
  penaltyLastN?: number;
  penaltyRepeat?: number;
  penaltyFreq?: number;
  penaltyPresent?: number;
  mirostat?: number;
  mirostatTau?: number;
  mirostatEta?: number;
  ignoreEos?: boolean;
  stopSequences?: string[];
  grammar?: string;
}

export interface CompletionResult {
  output: string;
  tokensGenerated: number;
  tokensEvaluated: number;
  truncated: boolean;
  stoppedEos: boolean;
  stoppedWord: boolean;
  stoppedLimit: boolean;
}

export interface LoraAdapter {
  path: string;
  scale: number;
}

export interface ConversationResult {
  text: string;
  timeToFirstToken: number;
  totalTime: number;
  tokensGenerated: number;
}

export interface LlamaMobilePlugin {
  // Model management
  initialize(params: InitParams): Promise<{ success: boolean }>;
  release(): Promise<void>;

  // Text generation
  generate(params: CompletionParams): Promise<CompletionResult>;
  multimodalCompletion(params: CompletionParams, mediaPaths: string[]): Promise<CompletionResult>;
  stopCompletion(): Promise<void>;

  // Tokenization
  tokenize(text: string): Promise<{ tokens: number[] }>;
  detokenize(tokens: number[]): Promise<{ text: string }>;

  // Embeddings
  generateEmbeddings(text: string): Promise<{ embeddings: number[] }>;

  // LoRA adapters
  applyLoraAdapters(adapters: LoraAdapter[]): Promise<{ success: boolean }>;
  removeLoraAdapters(): Promise<void>;

  // Multimodal support
  initMultimodal(mmprojPath: string, useGpu: boolean): Promise<{ success: boolean }>;
  isMultimodalEnabled(): Promise<{ enabled: boolean }>;
  releaseMultimodal(): Promise<void>;

  // Conversation management
  generateResponse(userMessage: string, maxTokens: number): Promise<ConversationResult>;
  clearConversation(): Promise<void>;

  // Grammar
  getGrammarContent(options: { grammarName: GrammarName }): Promise<{ content: string }>;
}
