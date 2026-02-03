// Shared types for the application

// Message type for chat
interface Message {
  role: 'user' | 'assistant';
  content: string;
}

// Model information type
interface ModelInfo {
  name: string;
  path: string;
}

// Export all types
export type { Message, ModelInfo };