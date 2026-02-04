import { WebPlugin, PluginListenerHandle } from '@capacitor/core';
import type { 
  LlamaMobileCapacitorPlugin, 
  TTSModelType,
  InitParams,
  CompletionParams,
  CompletionResult,
  ConversationResult,
  SpeechResult,
  SpeechMetadata,
  DownloadParams,
  DownloadHfFileParams,
  DownloadResult,
  LoraAdapter
} from './definitions';

export class LlamaMobileCapacitorPluginWeb extends WebPlugin implements LlamaMobileCapacitorPlugin {
  constructor() {
    super();
  }

  async initContext(_options: InitParams): Promise<{ contextHandle: number }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async releaseContext(_options: { contextHandle: number }): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateCompletion(_options: { contextHandle: number; params: CompletionParams }): Promise<CompletionResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateOpenAICompletion(_options: { contextHandle: number; openAIJSON: string; grammar?: string; stopSequences?: string[] }): Promise<CompletionResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async stopCompletion(_options: { contextHandle: number }): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async loadGrammar(_options: { filePath: string }): Promise<{ grammar: string }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async initVocoder(_options: any): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async releaseVocoder(_options: any): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async isVocoderEnabled(_options: any): Promise<{ enabled: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getTTSType(_options: any): Promise<{ type: TTSModelType }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateSpeechAsync(_options: { contextHandle: number; text: string; sampleRate?: number; method?: any; speakerJson?: string }): Promise<SpeechResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateSpeech(_options: { contextHandle: number; text: string; sampleRate?: number; method?: any }): Promise<SpeechResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateSpeechStream(_options: { contextHandle: number; text: string; sampleRate?: number; method?: any }): Promise<SpeechMetadata> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateSpeechStreamForLongTextAsync(_options: { contextHandle: number; text: string; sampleRate?: number; method?: any }): Promise<SpeechMetadata> {
    throw new Error('LlamaMobile is not available on web');
  }

  async saveAudioToWav(_options: { contextHandle: number; filePath: string; audioData: number[]; sampleRate: number }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async playAudio(_options: { audioData: number[]; sampleRate?: number }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async playAudioFromFile(_options: { filePath: string }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async initMultimodal(_options: { contextHandle: number; mmprojPath: string; useGpu?: boolean }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async releaseMultimodal(_options: { contextHandle: number }): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async isMultimodalEnabled(_options: { contextHandle: number }): Promise<{ enabled: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async supportsVision(_options: { contextHandle: number }): Promise<{ supported: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async supportsAudio(_options: { contextHandle: number }): Promise<{ supported: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async applyLoraAdapters(_options: { contextHandle: number; adapters: LoraAdapter[] }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async removeLoraAdapters(_options: { contextHandle: number }): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getLoadedLoraAdapters(_options: { contextHandle: number }): Promise<{ adapters: LoraAdapter[] }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateResponse(_options: { contextHandle: number; userMessage: string; maxTokens?: number; enableStreaming?: boolean }): Promise<ConversationResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async clearConversation(_options: { contextHandle: number }): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }

  async isConversationActive(_options: { contextHandle: number }): Promise<{ active: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async generateEmbeddings(_options: { contextHandle: number; text: string }): Promise<{ embedding: number[] }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async tokenize(_options: { contextHandle: number; text: string }): Promise<{ tokens: number[] }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async detokenize(_options: { contextHandle: number; tokens: number[] }): Promise<{ text: string }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getContextWindowSize(_options: { contextHandle: number }): Promise<{ size: number }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getEmbeddingDimension(_options: { contextHandle: number }): Promise<{ dimension: number }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getModelDescription(_options: { contextHandle: number }): Promise<{ description: string }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getModelSize(_options: { contextHandle: number }): Promise<{ size: number }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getModelParametersCount(_options: { contextHandle: number }): Promise<{ count: number }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async downloadModel(_options: DownloadParams): Promise<DownloadResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async downloadHfFile(_options: DownloadHfFileParams): Promise<DownloadResult> {
    throw new Error('LlamaMobile is not available on web');
  }

  async setChatTemplate(_options: { contextHandle: number; chatTemplate: string }): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async getModelChatTemplate(_options: { contextHandle: number }): Promise<{ chatTemplate: string }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async formatChatMessages(_options: { contextHandle: number; messagesJson: string; chatTemplate?: string }): Promise<{ formattedPrompt: string }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async listFiles(_options: { directory: string }): Promise<{ files: string[] }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async listModels(): Promise<{ models: Array<{ name: string; path: string }> }> {
    throw new Error('LlamaMobile is not available on web');
  }

  async addListener(eventName: 'token' | 'progress', listenerFunc: any): Promise<PluginListenerHandle> {
    throw new Error('LlamaMobile is not available on web');
  }

  async removeAllListeners(): Promise<void> {
    throw new Error('LlamaMobile is not available on web');
  }
}
