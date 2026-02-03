import React from 'react';
import { ModelInfo } from '../types';

interface MoreProps {
  // Model configuration
  modelPath: string;
  setModelPath: (path: string) => void;
  mmprojModelPath: string;
  setMmprojModelPath: (path: string) => void;
  vocoderModelPath: string;
  setVocoderModelPath: (path: string) => void;
  loraPath: string;
  setLoraPath: (path: string) => void;
  selectedGrammar: string | null;
  setSelectedGrammar: (grammar: string | null) => void;
  enableEmbedding: boolean;
  setEnableEmbedding: (enabled: boolean) => void;
  nGpuLayers: number;
  setNGpuLayers: (layers: number) => void;
  nThreads: number;
  setNThreads: (threads: number) => void;
  nCtx: number;
  setNCtx: (ctx: number) => void;
  loraScale: number;
  setLoraScale: (scale: number) => void;
  
  // New switches
  customTemplate: boolean;
  setCustomTemplate: (value: boolean) => void;
  chatMode: boolean;
  setChatMode: (value: boolean) => void;
  
  // Download settings
  hfRepoId: string;
  setHfRepoId: (repoId: string) => void;
  hfFilename: string;
  setHfFilename: (filename: string) => void;
  hfBearerToken: string;
  setHfBearerToken: (token: string) => void;
  
  // Status
  availableModels: ModelInfo[];
  availableMmprojModels: ModelInfo[];
  availableVocoderModels: ModelInfo[];
  availableLoraModels: ModelInfo[];
  availableGrammars: string[];
  isModelInitialized: boolean;
  isDownloading: boolean;
  downloadProgress: number;
  downloadStatus: string;
  downloadError: string;
  
  // Actions
  initializeModel: () => void;
  unloadModel: () => void;
  applyLora: () => void;
  removeLora: () => void;
  downloadModel: () => void;
}

const More: React.FC<MoreProps> = ({
  // Model configuration
  modelPath,
  setModelPath,
  mmprojModelPath,
  setMmprojModelPath,
  vocoderModelPath,
  setVocoderModelPath,
  loraPath,
  setLoraPath,
  selectedGrammar,
  setSelectedGrammar,
  enableEmbedding,
  setEnableEmbedding,
  nGpuLayers,
  setNGpuLayers,
  nThreads,
  setNThreads,
  nCtx,
  setNCtx,
  loraScale,
  setLoraScale,
  
  // New switches
  customTemplate,
  setCustomTemplate,
  chatMode,
  setChatMode,
  
  // Download settings
  hfRepoId,
  setHfRepoId,
  hfFilename,
  setHfFilename,
  hfBearerToken,
  setHfBearerToken,
  
  // Status
  availableModels,
  availableMmprojModels,
  availableVocoderModels,
  availableLoraModels,
  availableGrammars,
  isModelInitialized,
  isDownloading,
  downloadProgress,
  downloadStatus,
  downloadError,
  
  // Actions
  initializeModel,
  unloadModel,
  applyLora,
  removeLora,
  downloadModel
}) => {
  return (
    <div className="settings-container">
      {/* Model Configuration Section */}
      <div className="setting-section">
        <h3>Model Configuration</h3>
        
        {/* Main Model Picker */}
        <div className="setting-item">
          <label>Select Main Model:</label>
          <div className="picker-container">
            <select 
              value={modelPath}
              onChange={(e) => {
                console.log('Main model selected:', e.target.value);
                setModelPath(e.target.value);
              }}
              disabled={isModelInitialized}
              className="model-picker"
            >
              {availableModels.map((model) => (
                <option key={model.path} value={model.path}>
                  {model.name}
                </option>
              ))}
              {availableModels.length === 0 && (
                <option value="">No models found</option>
              )}
            </select>
          </div>
        </div>
        
        {/* MMProj Model Picker */}
        <div className="setting-item">
          <label>Select MMProj Model:</label>
          <div className="picker-container">
            <select 
              value={mmprojModelPath}
              onChange={(e) => {
                console.log('MMProj model selected:', e.target.value);
                setMmprojModelPath(e.target.value);
              }}
              disabled={isModelInitialized}
              className="model-picker"
            >
              {availableMmprojModels.map((model) => (
                <option key={model.path} value={model.path}>
                  {model.name}
                </option>
              ))}
            </select>
          </div>
        </div>
        
        {/* Vocoder Model Picker */}
        <div className="setting-item">
          <label>Select Vocoder Model:</label>
          <div className="picker-container">
            <select 
              value={vocoderModelPath}
              onChange={(e) => setVocoderModelPath(e.target.value)}
              disabled={isModelInitialized}
              className="model-picker"
            >
              {availableVocoderModels.map((model) => (
                <option key={model.path} value={model.path}>
                  {model.name}
                </option>
              ))}
            </select>
          </div>
        </div>
        
        {/* LoRA Model Picker */}
        <div className="setting-item">
          <label>Select LoRA Model:</label>
          <div className="picker-container">
            <select 
              value={loraPath}
              onChange={(e) => setLoraPath(e.target.value)}
              disabled={isModelInitialized}
              className="model-picker"
            >
              {availableLoraModels.map((model) => (
                <option key={model.path} value={model.path}>
                  {model.name}
                </option>
              ))}
            </select>
          </div>
        </div>
        
        {/* Grammar Picker */}
        <div className="setting-item">
          <label>Select Grammar:</label>
          <div className="picker-container">
            <select 
              value={selectedGrammar || ''}
              onChange={(e) => setSelectedGrammar(e.target.value || null)}
              disabled={isModelInitialized}
              className="model-picker"
            >
              <option value="">Empty</option>
              {availableGrammars.map((grammar, index) => (
                <option key={index} value={grammar}>
                  {grammar}
                </option>
              ))}
            </select>
          </div>
        </div>
        
        {/* Embedding Toggle */}
        <div className="setting-item">
          <label>
            <input 
              type="checkbox"
              checked={enableEmbedding}
              onChange={(e) => setEnableEmbedding(e.target.checked)}
              disabled={isModelInitialized}
            />
            Enable Embedding
          </label>
        </div>
        
        {/* Custom Template Toggle */}
        <div className="setting-item">
          <label>
            <input 
              type="checkbox"
              checked={customTemplate}
              onChange={(e) => setCustomTemplate(e.target.checked)}
              disabled={isModelInitialized}
            />
            Custom Template
          </label>
        </div>
        
        {/* Chat Mode Toggle */}
        <div className="setting-item">
          <label>
            <input 
              type="checkbox"
              checked={chatMode}
              onChange={(e) => setChatMode(e.target.checked)}
              disabled={isModelInitialized}
            />
            Chat Mode
          </label>
        </div>
        
        {/* GPU Layers */}
        <div className="setting-item">
          <label>GPU Layers: {nGpuLayers}</label>
          <input 
            value={nGpuLayers}
            onChange={(e) => setNGpuLayers(parseInt(e.target.value))}
            type="range"
            min={0}
            max={16}
            step={1}
            disabled={isModelInitialized}
          />
        </div>
        
        {/* Threads */}
        <div className="setting-item">
          <label>Threads: {nThreads}</label>
          <input 
            value={nThreads}
            onChange={(e) => setNThreads(parseInt(e.target.value))}
            type="range"
            min={1}
            max={8}
            step={1}
            disabled={isModelInitialized}
          />
        </div>
        
        {/* Context Size */}
        <div className="setting-item">
          <label>Context Size: {nCtx}</label>
          <input 
            value={nCtx}
            onChange={(e) => setNCtx(parseInt(e.target.value))}
            type="range"
            min={512}
            max={4096}
            step={512}
            disabled={isModelInitialized}
          />
        </div>
      </div>
      
      {/* Model Actions Section */}
      <div className="setting-section">
        <h3>Model Actions</h3>
        <button 
          onClick={initializeModel} 
          className="primary-button"
          disabled={isModelInitialized || !modelPath}
        >
          {isModelInitialized ? 'Reinitialize Model' : 'Initialize Model'}
        </button>
        {isModelInitialized && (
          <button 
            onClick={unloadModel} 
            className="danger-button"
          >
            Unload Model
          </button>
        )}
      </div>
      
      {/* Model Status Section */}
      {isModelInitialized && (
        <div className="setting-section">
          <h3>Model Status</h3>
          <div className="status-message success">
            Model loaded successfully!
          </div>
        </div>
      )}
      
      {/* LoRA Configuration Section */}
      <div className="setting-section">
        <h3>LoRA Configuration</h3>
        <div className="setting-item">
          <label>LoRA Scale:</label>
          <input 
            value={loraScale}
            onChange={(e) => setLoraScale(parseFloat(e.target.value))}
            type="number"
            min={0.1}
            max={2.0}
            step={0.1}
          />
        </div>
        <button 
          onClick={applyLora} 
          className="primary-button"
        >
          Apply LoRA Adapter
        </button>
        <button 
          onClick={removeLora} 
          className="secondary-button"
        >
          Remove LoRA Adapter
        </button>
      </div>
      
      {/* Download Section */}
      <div className="setting-section">
        <h3>Download Model from Hugging Face</h3>
        
        {/* Hugging Face Repo ID */}
        <div className="setting-item">
          <label>Repository ID:</label>
          <input 
            type="text"
            value={hfRepoId}
            onChange={(e) => setHfRepoId(e.target.value)}
            disabled={isDownloading}
            placeholder="e.g., meta-llama/Llama-3.2-1B-Instruct"
          />
        </div>
        
        {/* Hugging Face Filename */}
        <div className="setting-item">
          <label>Filename:</label>
          <input 
            type="text"
            value={hfFilename}
            onChange={(e) => setHfFilename(e.target.value)}
            disabled={isDownloading}
            placeholder="e.g., Llama-3.2-1B-Instruct.Q4_K_M.gguf"
          />
        </div>
        
        {/* Hugging Face Bearer Token (optional) */}
        <div className="setting-item">
          <label>Bearer Token (optional):</label>
          <input 
            type="text"
            value={hfBearerToken}
            onChange={(e) => setHfBearerToken(e.target.value)}
            disabled={isDownloading}
            placeholder="Your Hugging Face API token"
          />
        </div>
        
        {/* Download Status */}
        {downloadStatus && (
          <div className="setting-item">
            <label>Status:</label>
            <div className="status-message">{downloadStatus}</div>
          </div>
        )}
        
        {/* Download Progress */}
        {isDownloading && (
          <div className="setting-item">
            <label>Progress:</label>
            <div className="progress-bar-container">
              <div 
                className="progress-bar"
                style={{ width: `${downloadProgress * 100}%` }}
              ></div>
            </div>
            <div className="progress-text">
              {(downloadProgress * 100).toFixed(0)}%
            </div>
          </div>
        )}
        
        {/* Download Error */}
        {downloadError && (
          <div className="setting-item">
            <label>Error:</label>
            <div className="error-message">{downloadError}</div>
          </div>
        )}
        
        {/* Download Button */}
        <button 
          onClick={downloadModel}
          className="primary-button"
          disabled={isDownloading || !hfRepoId || !hfFilename}
        >
          {isDownloading ? 'Downloading...' : 'Download Model'}
        </button>
      </div>
    </div>
  );
};

export default More;