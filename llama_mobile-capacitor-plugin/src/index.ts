import { registerPlugin } from '@capacitor/core';

import type { LlamaMobilePlugin } from './definitions';

const LlamaMobile = registerPlugin<LlamaMobilePlugin>('LlamaMobile', {
  web: () => import('./web').then((m) => new m.LlamaMobileWeb()),
});

export * from './definitions';
export { LlamaMobile };
