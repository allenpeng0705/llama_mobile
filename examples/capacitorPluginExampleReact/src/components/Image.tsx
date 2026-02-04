import React from 'react';

interface ImageProps {
  selectedImage: string | null;
  selectedImagePath: string | null;
  multimodalText: string;
  multimodalResult: string;
  setMultimodalText: (text: string) => void;
  selectImage: () => void;
  generateMultimodalCompletion: () => void;
  isModelInitialized: boolean;
  isMultimodalEnabled: boolean;
}

const Image: React.FC<ImageProps> = ({
  selectedImage,
  selectedImagePath,
  multimodalText,
  multimodalResult,
  setMultimodalText,
  selectImage,
  generateMultimodalCompletion,
  isModelInitialized,
  isMultimodalEnabled
}) => {
  return (
    <div className="settings-container" style={{ paddingBottom: '80px' }}>
      {!isModelInitialized ? (
        <div className="model-not-initialized">
          <h3>Model Not Initialized</h3>
          <p>Please go to the "More" tab to select and initialize a model first.</p>
        </div>
      ) : (
        <>
          <div className="setting-section">
            <h3>Image Input</h3>
            <div className="setting-item">
              <button 
                onClick={selectImage}
                className="primary-button"
                disabled={!isModelInitialized}
              >
                {selectedImage ? 'Change Image' : 'Select Image'}
              </button>
            </div>
            {selectedImage && (
              <div className="setting-item">
                <img 
                  src={selectedImage} 
                  alt="Selected" 
                  style={{ maxWidth: '100%', maxHeight: '300px', borderRadius: '8px' }}
                />
              </div>
            )}
          </div>
          
          <div className="setting-section">
            <h3>Text Input</h3>
            <div className="setting-item">
              <textarea 
                value={multimodalText}
                onChange={(e) => setMultimodalText(e.target.value)}
                placeholder="Enter text prompt..."
                rows={8}
                style={{ width: '100%', minWidth: '100%', maxWidth: '100%' }}
                disabled={!isModelInitialized || !isMultimodalEnabled}
              ></textarea>
            </div>
            <button 
              onClick={generateMultimodalCompletion}
              className="primary-button"
              style={{ marginTop: '16px', width: '100%' }}
              disabled={
                !isModelInitialized || 
                !isMultimodalEnabled || 
                !selectedImagePath || 
                !multimodalText.trim()
              }
            >
              Generate Completion
            </button>
          </div>
          
          {multimodalResult && (
            <div className="setting-section">
              <h3>Completion Result</h3>
              <div className="embeddings-result">
                <pre>{multimodalResult}</pre>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default Image;