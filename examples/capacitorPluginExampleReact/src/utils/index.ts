// Shared utilities for the v2 (LlamaEngine) Capacitor example.

interface CapacitorShim {
  getPlatform?: () => string;
  platform?: string;
}

function platform(): string {
  const cap = (window as unknown as { Capacitor?: CapacitorShim }).Capacitor;
  if (!cap) return 'web';
  return cap.getPlatform ? cap.getPlatform() : cap.platform ?? 'web';
}

/** Maps a bundled model name to the platform path used by the native cores. */
export function modelPathFor(modelName: string): string {
  switch (platform()) {
    case 'ios':
      return `models/${modelName}`;
    case 'android':
      return `/storage/emulated/0/Download/models/${modelName}`;
    default:
      throw new Error('llama_mobile has no web core — run on a device');
  }
}

export function isNative(): boolean {
  return platform() !== 'web';
}

export function errMessage(e: unknown): string {
  if (e instanceof Error) return e.message;
  return String(e);
}

export const stopReasonName = (r: number): string =>
  ['eos', 'stop-word', 'max-tokens', 'aborted', 'error'][r] ?? 'error';
