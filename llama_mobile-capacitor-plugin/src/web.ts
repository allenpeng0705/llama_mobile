import { WebPlugin } from '@capacitor/core';

import type { LlamaMobilePlugin } from './definitions';

export class LlamaMobileWeb extends WebPlugin implements LlamaMobilePlugin {
  // Model management
  async initialize(): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async release(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Text generation
  async generate(): Promise<{
    output: string;
    tokensGenerated: number;
    tokensEvaluated: number;
    truncated: boolean;
    stoppedEos: boolean;
    stoppedWord: boolean;
    stoppedLimit: boolean;
  }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async multimodalCompletion(): Promise<{
    output: string;
    tokensGenerated: number;
    tokensEvaluated: number;
    truncated: boolean;
    stoppedEos: boolean;
    stoppedWord: boolean;
    stoppedLimit: boolean;
  }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async stopCompletion(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Tokenization
  async tokenize(): Promise<{ tokens: number[] }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async detokenize(): Promise<{ text: string }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Embeddings
  async generateEmbeddings(): Promise<{ embeddings: number[] }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // LoRA adapters
  async applyLoraAdapters(): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async removeLoraAdapters(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Multimodal support
  async initMultimodal(): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async isMultimodalEnabled(): Promise<{ enabled: boolean }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async releaseMultimodal(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Conversation management
  async generateResponse(): Promise<{
    text: string;
    timeToFirstToken: number;
    totalTime: number;
    tokensGenerated: number;
  }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async clearConversation(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }

  // Grammar
  async getGrammarContent(): Promise<{ content: string }> {
    throw new Error('LlamaMobile is not supported on web');
  }
}
