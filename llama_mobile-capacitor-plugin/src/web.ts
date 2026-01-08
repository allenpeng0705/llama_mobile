import { WebPlugin } from '@capacitor/core';

import type { LlamaMobilePlugin } from './definitions';

export class LlamaMobileWeb extends WebPlugin implements LlamaMobilePlugin {
  async initialize(): Promise<{ success: boolean }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async generate(): Promise<{ output: string }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async getGrammarContent(): Promise<{ content: string }> {
    throw new Error('LlamaMobile is not supported on web');
  }

  async release(): Promise<void> {
    throw new Error('LlamaMobile is not supported on web');
  }
}
