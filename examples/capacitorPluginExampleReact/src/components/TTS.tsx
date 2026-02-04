import React from 'react';

interface TTSProps {
  ttsText: string;
  setTtsText: (text: string) => void;
  generateAudio: () => void;
  playAudio: () => void;
  audioSamples: number[];
  audioFilePath: string;
  isPlaying: boolean;
  isGeneratingAudio: boolean;
  isModelInitialized: boolean;
  isVocoderInitialized: boolean;
}

const TTS: React.FC<TTSProps> = ({
  ttsText,
  setTtsText,
  generateAudio,
  playAudio,
  audioSamples,
  audioFilePath,
  isPlaying,
  isGeneratingAudio,
  isModelInitialized,
  isVocoderInitialized
}) => {
  return (
    <div className="tts-container">
      {!isModelInitialized ? (
        <div className="model-not-initialized">
          <h3>Model Not Initialized</h3>
          <p>Please go to the "More" tab to select and initialize a model first.</p>
        </div>
      ) : (
        <>
          <div className="setting-item">
            <label>Input Text:</label>
            <textarea 
              value={ttsText}
              onChange={(e) => setTtsText(e.target.value)}
              placeholder="Enter text to convert to speech..."
              rows={5}
              disabled={!isModelInitialized || isGeneratingAudio}
            ></textarea>
          </div>
          
          <button 
            onClick={generateAudio} 
            className="primary-button"
            disabled={!isModelInitialized || !isVocoderInitialized || !ttsText.trim() || isGeneratingAudio}
          >
            {isGeneratingAudio ? 'Generating Audio...' : 'Generate Audio'}
          </button>
          
          {audioSamples.length > 0 && (
            <div className="tts-actions">
              <button 
                onClick={playAudio} 
                className="primary-button"
                disabled={isPlaying}
              >
                {isPlaying ? 'Playing...' : 'Play Audio'}
              </button>
            </div>
          )}
          
          {audioSamples.length > 0 && (
            <div className="status-message success">
              Audio generated and saved to: {audioFilePath}
            </div>
          )}
          
          {isVocoderInitialized && (
            <div className="status-message success">
              Vocoder initialized successfully
            </div>
          )}
          
          {isModelInitialized && !isVocoderInitialized && (
            <div className="status-message warning">
              Vocoder not initialized. Please select a vocoder model in the "More" tab.
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default TTS;