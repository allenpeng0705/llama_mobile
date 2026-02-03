import type { PluginListenerHandle } from '@capacitor/core';

export interface LlamaMobileCapacitorPlugin {
  // Initialization
  initContext(options: InitParams): Promise<{ contextHandle: number }>;
  releaseContext(options: { contextHandle: number }): Promise<void>;
  
  // Completion
  generateCompletion(options: { contextHandle: number; params: CompletionParams }): Promise<CompletionResult>;
  generateOpenAICompletion(options: { contextHandle: number; openAIJSON: string; grammar?: string; stopSequences?: string[] }): Promise<CompletionResult>;
  stopCompletion(options: { contextHandle: number }): Promise<void>;
  loadGrammar(options: { filePath: string }): Promise<{ grammar: string }>;
  
  // TTS
  initVocoder(options: { contextHandle: number; vocoderModelPath: string }): Promise<{ success: boolean; modelType: TTSModelType }>;
  releaseVocoder(options: { contextHandle: number }): Promise<void>;
  isVocoderEnabled(options: { contextHandle: number }): Promise<{ enabled: boolean }>;
  getTTSType(options: { contextHandle: number }): Promise<{ type: TTSModelType }>;
  generateAudioFromText(options: { contextHandle: number; text: string; speakerJson?: string }): Promise<{ audio: number[] }>;
  generateSpeech(options: { contextHandle: number; text: string; sampleRate?: number; method?: TTSMethod; speakerJson?: string }): Promise<SpeechResult>;
  generateSpeechSync(options: { contextHandle: number; text: string; sampleRate?: number; method?: TTSMethod }): Promise<SpeechResult>;
  generateSpeechStream(options: { contextHandle: number; text: string; sampleRate?: number; method?: TTSMethod }): Promise<SpeechMetadata>;
  generateSpeechStreamForLongText(options: { contextHandle: number; text: string; sampleRate?: number; method?: TTSMethod }): Promise<SpeechMetadata>;
  saveAudioToWav(options: { contextHandle: number; filePath: string; audioData: number[]; sampleRate: number }): Promise<{ success: boolean }>;
  playAudio(options: { audioData: number[]; sampleRate?: number }): Promise<{ success: boolean }>;
  
  // Multimodal
  initMultimodal(options: { contextHandle: number; mmprojPath: string; useGpu?: boolean }): Promise<{ success: boolean }>;
  releaseMultimodal(options: { contextHandle: number }): Promise<void>;
  isMultimodalEnabled(options: { contextHandle: number }): Promise<{ enabled: boolean }>;
  supportsVision(options: { contextHandle: number }): Promise<{ supported: boolean }>;
  supportsAudio(options: { contextHandle: number }): Promise<{ supported: boolean }>;
  
  // LoRA
  applyLoraAdapters(options: { contextHandle: number; adapters: LoraAdapter[] }): Promise<{ success: boolean }>;
  removeLoraAdapters(options: { contextHandle: number }): Promise<void>;
  getLoadedLoraAdapters(options: { contextHandle: number }): Promise<{ adapters: LoraAdapter[] }>;
  
  // Conversation
  generateResponse(options: { contextHandle: number; userMessage: string; maxTokens: number }): Promise<ConversationResult>;
  clearConversation(options: { contextHandle: number }): Promise<void>;
  isConversationActive(options: { contextHandle: number }): Promise<{ active: boolean }>;
  
  // Embeddings
  generateEmbeddings(options: { contextHandle: number; text: string }): Promise<{ embedding: number[] }>;
  
  // Tokenization
  tokenize(options: { contextHandle: number; text: string }): Promise<{ tokens: number[] }>;
  detokenize(options: { contextHandle: number; tokens: number[] }): Promise<{ text: string }>;
  
  // Model Info
  getContextWindowSize(options: { contextHandle: number }): Promise<{ size: number }>;
  getEmbeddingDimension(options: { contextHandle: number }): Promise<{ dimension: number }>;
  getModelDescription(options: { contextHandle: number }): Promise<{ description: string }>;
  getModelSize(options: { contextHandle: number }): Promise<{ size: number }>;
  getModelParametersCount(options: { contextHandle: number }): Promise<{ count: number }>;
  
  // Download
  downloadModel(options: DownloadParams): Promise<DownloadResult>;
  downloadHfFile(options: DownloadHfFileParams): Promise<DownloadResult>;
  
  // Chat
  setChatTemplate(options: { contextHandle: number; chatTemplate: string }): Promise<{ success: boolean }>;
  getModelChatTemplate(options: { contextHandle: number }): Promise<{ chatTemplate: string }>;
  formatChatMessages(options: { contextHandle: number; messagesJson: string; chatTemplate?: string }): Promise<{ formattedPrompt: string }>;
  
  // File System
  listFiles(options: { directory: string }): Promise<{ files: string[] }>;
  listModels(): Promise<{ models: Array<{ name: string; path: string }> }>;
  
  // Listeners
  addListener(eventName: 'token', listenerFunc: (data: { token: string }) => void): Promise<PluginListenerHandle>;
  addListener(eventName: 'progress', listenerFunc: (data: { progress: number }) => void): Promise<PluginListenerHandle>;
  removeAllListeners(): Promise<void>;
}

// Types
export enum TTSModelType {
  UNKNOWN = -1,
  OUT_ETTS_V02 = 1,
  OUT_ETTS_V03 = 2
}

export enum TTSMethod {
  BUILT_IN = 'BUILT_IN',
  CUSTOM_WORKFLOW = 'CUSTOM_WORKFLOW',
  BEST = 'BEST'
}

export enum CacheType {
  NONE,
  MEMORY
}

export enum GrammarName {
  ARITHMETIC,
  C,
  CHESS,
  ENGLISH,
  JAPANESE,
  JSON,
  JSON_ARR,
  LIST
}

export interface ChatMessage {
  role: string;
  content: string;
}

export interface LoraAdapter {
  path: string;
  scale: number;
}

export interface TTSOptions {
  sampleRate?: number;
  method?: TTSMethod;
  voice?: string;
  speed?: number;
  saveToFile?: boolean;
  outputFilePath?: string;
}

export interface SpeechResult {
  audio: number[];
  sampleRate: number;
  duration: number;
  methodUsed: TTSMethod;
  outputFilePath?: string;
}

export interface SpeechMetadata {
  sampleRate: number;
  duration: number;
  methodUsed: TTSMethod;
  outputFilePath?: string;
}

export interface InitParams {
  modelPath: string;
  nCtx?: number;
  chatTemplate?: string;
  systemPrompt?: string;
  nBatch?: number;
  nUbatch?: number;
  nGpuLayers?: number;
  nThreads?: number;
  useMmap?: boolean;
  useMlock?: boolean;
  embedding?: boolean;
  poolingType?: number;
  embdNormalize?: number;
  flashAttn?: boolean;
  cacheTypeK?: string;
  cacheTypeV?: string;
  cacheType?: CacheType;
}

export interface CompletionParams {
  prompt: string;
  temperature?: number;
  maxTokens?: number;
  nThreads?: number;
  seed?: number;
  topK?: number;
  topP?: number;
  minP?: number;
  typicalP?: number;
  penaltyLastN?: number;
  penaltyRepeat?: number;
  penaltyFreq?: number;
  penaltyPresent?: number;
  mirostat?: number;
  mirostatTau?: number;
  mirostatEta?: number;
  ignoreEos?: boolean;
  nProbs?: number;
  grammar?: string;
  stopSequences?: string[];
  mediaPaths?: string[];
  chatMessages?: ChatMessage[];
  useJsonResponse?: boolean;
  chatTemplate?: string;
}

export interface CompletionResult {
  text: string;
  tokensGenerated: number;
  tokensEvaluated: number;
  truncated: boolean;
  stoppedEos: boolean;
  stoppedWord: boolean;
  stoppedLimit: boolean;
  stoppingWord?: string;
}

export interface ConversationResult {
  text: string;
  timeToFirstToken: number;
  totalTime: number;
  tokensGenerated: number;
}

export interface DownloadParams {
  url: string;
  localPath: string;
  password?: string;
  headers?: Record<string, string>;
}

export interface DownloadHfFileParams {
  repoId: string;
  filename: string;
  destinationPath: string;
  bearerToken?: string;
  offline?: boolean;
}

export interface DownloadResult {
  success: boolean;
  localPath: string;
  errorMessage?: string;
}
