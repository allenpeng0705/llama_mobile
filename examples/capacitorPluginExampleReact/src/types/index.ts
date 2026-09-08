// Shared types for the v2 (LlamaEngine) Capacitor example app.
export interface Message {
  role: string; // 'user' | 'assistant'
  content: string;
}

export interface LogEntry {
  role: 'q' | 'a' | 'sys' | 'err';
  text: string;
}
