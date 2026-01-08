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

export interface LlamaMobilePlugin {
  initialize(params: InitParams): Promise<{ success: boolean }>;
  generate(params: CompletionParams): Promise<{ output: string }>;
  getGrammarContent(options: { grammarName: GrammarName }): Promise<{ content: string }>;
  release(): Promise<void>;
}
