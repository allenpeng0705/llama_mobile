import { LlamaMobileCapacitorPlugin } from 'llama-mobile-capacitor-plugin';

let contextHandle = null;

const models = [
  "fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf",
  "SmolLM-360M-Instruct.Q6_K.gguf",
  "mmproj-SmolVLM-256M-Instruct-Q8_0.gguf",
  "SmolVLM-256M-Instruct-Q8_0.gguf",
  "WavTokenizer-Large-75-F16.gguf",
  "OuteTTS-0.2-500M-Q6_K.gguf",
  "Qwen3-Embedding-0.6B-Q8_0.gguf",
  "Qwen3-1.7B-Q4_K_M.gguf",
];

function showStatus(elementId, message, type) {
  const element = document.getElementById(elementId);
  element.textContent = message;
  element.className = `status ${type}`;
  element.style.display = 'block';
}

function showResult(elementId, content) {
  const element = document.getElementById(elementId);
  element.textContent = content;
  element.style.display = 'block';
}

function populateModelSelect() {
  const select = document.getElementById('modelSelect');
  models.forEach(model => {
    const option = document.createElement('option');
    option.value = model;
    option.textContent = model;
    select.appendChild(option);
  });
}

window.loadModel = async () => {
  const modelSelect = document.getElementById('modelSelect');
  const modelName = modelSelect.value;
  
  showStatus('loadStatus', 'Loading model...', 'info');
  
  try {
    let modelPath;
    if (Capacitor.platform === 'ios') {
      modelPath = `models/${modelName}`;
    } else if (Capacitor.platform === 'android') {
      modelPath = `/storage/emulated/0/Download/models/${modelName}`;
    } else {
      throw new Error('Unsupported platform');
    }
    
    console.log('Loading model from:', modelPath);
    
    const result = await LlamaMobileCapacitorPlugin.initContext({
      modelPath: modelPath,
      nCtx: 2048,
      nGpuLayers: 99,
      nThreads: 4,
      nBatch: 512,
      nUBatch: 512,
      useMmap: true,
      useMlock: false,
      embedding: true,
      poolingType: 0,
      embdNormalize: 1,
      loraAdapters: [],
    });
    
    contextHandle = result.contextHandle;
    console.log('Model loaded successfully, context handle:', contextHandle);
    
    showStatus('loadStatus', `Model loaded successfully! Context: ${contextHandle}`, 'success');
    document.getElementById('embeddingBtn').disabled = false;
    
  } catch (error) {
    console.error('Failed to load model:', error);
    showStatus('loadStatus', `Failed to load model: ${error.message}`, 'error');
  }
};

window.generateEmbedding = async () => {
  if (!contextHandle) {
    showStatus('embeddingStatus', 'Please load a model first', 'error');
    return;
  }
  
  const text = document.getElementById('embeddingText').value;
  showStatus('embeddingStatus', 'Generating embedding...', 'info');
  document.getElementById('embeddingResult').style.display = 'none';
  
  try {
    console.log('Generating embedding for text:', text);
    
    const result = await LlamaMobileCapacitorPlugin.generateEmbeddings({
      contextHandle: contextHandle,
      text: text
    });
    
    console.log('Embedding generated:', result);
    
    const embedding = result.embedding;
    const dimension = embedding.length;
    
    let output = `Embedding Dimension: ${dimension}\n`;
    output += `First 10 values: [${embedding.slice(0, 10).map(v => v.toFixed(6)).join(', ')}]\n`;
    output += `Last 10 values: [${embedding.slice(-10).map(v => v.toFixed(6)).join(', ')}]\n`;
    output += `Min value: ${Math.min(...embedding).toFixed(6)}\n`;
    output += `Max value: ${Math.max(...embedding).toFixed(6)}\n`;
    output += `Mean value: ${(embedding.reduce((a, b) => a + b, 0) / embedding.length).toFixed(6)}\n`;
    
    const allZeros = embedding.every(v => v === 0);
    if (allZeros) {
      output += '\n⚠️ WARNING: All embedding values are zero! This indicates an issue with the embedding generation.';
    }
    
    showResult('embeddingResult', output);
    showStatus('embeddingStatus', allZeros ? 'Embedding generated but all values are zero!' : 'Embedding generated successfully!', allZeros ? 'error' : 'success');
    
  } catch (error) {
    console.error('Failed to generate embedding:', error);
    showStatus('embeddingStatus', `Failed to generate embedding: ${error.message}`, 'error');
  }
};

document.addEventListener('DOMContentLoaded', () => {
  populateModelSelect();
});