import React from 'react';

interface EmbedProps {
  embeddingText: string;
  setEmbeddingText: (text: string) => void;
  generateEmbeddings: () => void;
  embeddings: number[];
  isModelInitialized: boolean;
}

const Embed: React.FC<EmbedProps> = ({
  embeddingText,
  setEmbeddingText,
  generateEmbeddings,
  embeddings,
  isModelInitialized
}) => {
  return (
    <div className="embeddings-container">
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
              value={embeddingText}
              onChange={(e) => setEmbeddingText(e.target.value)}
              placeholder="Enter text to generate embeddings..."
              rows={5}
            ></textarea>
          </div>
          
          <button 
            onClick={generateEmbeddings} 
            className="primary-button"
            disabled={!isModelInitialized || !embeddingText.trim()}
          >
            Generate Embeddings
          </button>
          
          {embeddings.length > 0 && (
            <div className="embeddings-result">
              <h3>Embeddings (first 10 dimensions):</h3>
              <pre>{embeddings.slice(0, 10).map(e => e.toFixed(6)).join(', ')}</pre>
              <p>Total dimensions: {embeddings.length}</p>
            </div>
          )}
        </>
      )}
    </div>
  );
};

export default Embed;