import { registerPlugin } from '@capacitor/core';
import type { LlamaMobileCapacitorPlugin } from './definitions';

const LlamaMobileCapacitorPlugin = registerPlugin<LlamaMobileCapacitorPlugin>('LlamaMobileCapacitorPlugin', {
  web: () => import('./web').then(m => new m.LlamaMobileCapacitorPluginWeb()),
});

export * from './definitions';
export { LlamaMobileCapacitorPlugin };
