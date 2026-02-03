import { WebPlugin } from '@capacitor/core';
import type { LlamaMobileCapacitorPlugin } from './definitions';

export class LlamaMobileCapacitorPluginWeb extends WebPlugin implements LlamaMobileCapacitorPlugin {
  constructor() {
    super();
  }

  async initContext(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async releaseContext(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateCompletion(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateOpenAICompletion(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async stopCompletion(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async loadGrammar(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async initVocoder(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async releaseVocoder(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async isVocoderEnabled(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getTTSType(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateAudioFromText(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateSpeech(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateSpeechSync(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateSpeechStream(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateSpeechStreamForLongText(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async saveAudioToWav(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async playAudio(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async initMultimodal(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async releaseMultimodal(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async isMultimodalEnabled(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async supportsVision(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async supportsAudio(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async applyLoraAdapters(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async removeLoraAdapters(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getLoadedLoraAdapters(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateResponse(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async clearConversation(_options: any): Promise<void> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async isConversationActive(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async generateEmbeddings(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async tokenize(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async detokenize(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getContextWindowSize(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getEmbeddingDimension(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getModelDescription(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getModelSize(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getModelParametersCount(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async downloadModel(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async downloadHfFile(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async setChatTemplate(_options: any): Promise<{ success: boolean; }> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async getModelChatTemplate(_options: any): Promise<{ chatTemplate: string }> {
    throw this.unavailable('LlamaMobile is not available on web');
  }

  async formatChatMessages(_options: any): Promise<any> {
    throw this.unavailable('LlamaMobile is not available on web');
  }
}
