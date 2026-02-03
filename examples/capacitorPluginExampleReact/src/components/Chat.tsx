import React, { useRef, useEffect } from 'react';
import { Message } from '../types';

interface ChatProps {
  messages: Message[];
  inputMessage: string;
  setInputMessage: (message: string) => void;
  sendMessage: () => void;
  isModelInitialized: boolean;
  isGenerating: boolean;
  generatedText: string;
  streaming: boolean;
  setStreaming: (value: boolean) => void;
  jsonResponse: boolean;
  setJsonResponse: (value: boolean) => void;
}

const Chat: React.FC<ChatProps> = ({
  messages,
  inputMessage,
  setInputMessage,
  sendMessage,
  isModelInitialized,
  isGenerating,
  generatedText,
  streaming,
  setStreaming,
  jsonResponse,
  setJsonResponse
}) => {
  const chatMessagesRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom when messages change
  useEffect(() => {
    if (chatMessagesRef.current) {
      chatMessagesRef.current.scrollTop = chatMessagesRef.current.scrollHeight;
    }
  }, [messages, isGenerating, generatedText]);

  return (
    <div className="chat-container">
      {!isModelInitialized ? (
        <div className="model-not-initialized">
          <h3>Model Not Initialized</h3>
          <p>Please go to the "More" tab to select and initialize a model first.</p>
        </div>
      ) : (
        <>
          <div className="chat-messages" ref={chatMessagesRef}>
            {messages.map((message, index) => (
              <div 
                key={index}
                className={`message ${message.role}`}
              >
                <div className="message-content">{message.content}</div>
              </div>
            ))}
            {isGenerating && (
              <div className="message assistant">
                <div className="message-content">
                  {generatedText}
                  <span className="typing-indicator">...</span>
                </div>
              </div>
            )}
          </div>
          
          {/* Chat Settings Switches */}
          <div className="chat-settings">
            <div className="chat-switch">
              <label>
                <input 
                  type="checkbox"
                  checked={streaming}
                  onChange={(e) => setStreaming(e.target.checked)}
                  disabled={isGenerating}
                />
                Streaming
              </label>
            </div>
            <div className="chat-switch">
              <label>
                <input 
                  type="checkbox"
                  checked={jsonResponse}
                  onChange={(e) => setJsonResponse(e.target.checked)}
                  disabled={isGenerating}
                />
                JSON Response
              </label>
            </div>
          </div>
          
          <div className="chat-input">
            <input 
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
              placeholder="Type your message..."
              disabled={!isModelInitialized || isGenerating}
            />
            <button 
              onClick={sendMessage}
              disabled={!isModelInitialized || isGenerating || !inputMessage.trim()}
            >
              Send
            </button>
          </div>
        </>
      )}
    </div>
  );
};

export default Chat;