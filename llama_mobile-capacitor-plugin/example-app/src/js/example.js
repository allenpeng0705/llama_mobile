// example.js — llama_mobile v2 Capacitor demo (LlamaEngine wrapper).
//
// v2 rewrite of the old v1 example (initContext/contextHandle are gone; the
// v2 API is LlamaEngine.open/generate/abort/modelInfo/embed/close, async-only).
// Chat and embedding are separate engines because one engine = one model with
// one active generation (§8).

import { LlamaEngine } from 'llama-mobile-capacitor-plugin';

// Chat models for the picker; the embedding section always uses the
// Qwen3-Embedding fixture.
const chatModels = [
  "SmolLM-360M-Instruct.Q6_K.gguf",
  "fine-tuned-smolLM2-360M-with-LoRA-on-camel-ai-physics-f16.gguf",
  "Qwen3-1.7B-Q4_K_M.gguf",
];
const EMBEDDING_MODEL = "Qwen3-Embedding-0.6B-Q8_0.gguf";

let chatEngine = null;
let busy = false;

// ------------------------------------------------------------------- helpers

function showStatus(elementId, message, type) {
  const el = document.getElementById(elementId);
  el.textContent = message;
  el.className = `status ${type}`;
  el.style.display = 'block';
}

function appendLog(line) {
  const log = document.getElementById('chatLog');
  if (log.textContent === 'No model loaded yet.') log.textContent = '';
  log.textContent += line + '\n';
  log.scrollTop = log.scrollHeight;
}

function modelPathFor(modelName) {
  if (Capacitor.platform === 'ios') return `models/${modelName}`;
  if (Capacitor.platform === 'android') {
    return `/storage/emulated/0/Download/models/${modelName}`;
  }
  throw new Error('Unsupported platform (web has no native core)');
}

function populateModelSelect() {
  const select = document.getElementById('modelSelect');
  chatModels.forEach((model) => {
    const option = document.createElement('option');
    option.value = model;
    option.textContent = model;
    select.appendChild(option);
  });
}

// ------------------------------------------------------------------- chat

async function loadModel() {
  if (chatEngine) {
    await chatEngine.close();
    chatEngine = null;
  }
  const name = document.getElementById('modelSelect').value;
  showStatus('loadStatus', `Loading ${name} …`, 'info');
  document.getElementById('loadBtn').disabled = true;
  try {
    const engine = await LlamaEngine.open({
      modelPath: modelPathFor(name),
      nCtx: 2048,
      chat: true,
      embedding: false,
    });
    chatEngine = engine;
    const info = await engine.modelInfo();
    appendLog(`Loaded: ${info.description || name} (n_ctx=${info.nCtx})`);
    showStatus(
      'loadStatus',
      `Loaded ${name} — ask anything.`,
      'success',
    );
    document.getElementById('sendBtn').disabled = false;
    document.getElementById('embedBtn').disabled = false;
  } catch (error) {
    console.error('Load failed:', error);
    showStatus('loadStatus', `Load failed: ${error.message}`, 'error');
  } finally {
    document.getElementById('loadBtn').disabled = false;
  }
}

async function send() {
  const engine = chatEngine;
  if (!engine) return;
  const input = document.getElementById('promptInput');
  const text = input.value.trim();
  if (!text || busy) return;
  input.value = '';
  busy = true;
  appendLog(`Q: ${text}`);
  document.getElementById('sendBtn').disabled = true;
  document.getElementById('stopBtn').disabled = false;
  showStatus('chatStatus', 'Generating…', 'info');
  try {
    const result = await engine.generate({
      messages: [{ role: 'user', content: text }],
      maxTokens: 256,
      sampling: { temperature: 0.8 },
    });
    if (result.stopReason === 3 /* Aborted */) {
      appendLog('A: [stopped]');
    } else {
      appendLog(`A: ${result.text}`);
    }
    appendLog(`— done (${result.generatedTokens} tokens, reason ${result.stopReason})`);
    showStatus('chatStatus', '', 'info');
  } catch (error) {
    console.error('Generate failed:', error);
    showStatus('chatStatus', `Error: ${error.message}`, 'error');
  } finally {
    busy = false;
    document.getElementById('sendBtn').disabled = false;
    document.getElementById('stopBtn').disabled = true;
  }
}

async function stop() {
  const engine = chatEngine;
  if (!engine) return;
  try {
    const ok = await engine.abort();
    if (ok) appendLog('abort requested');
  } catch (error) {
    showStatus('chatStatus', `Abort error: ${error.message}`, 'error');
  }
}

// --------------------------------------------------------------- embedding

async function generateEmbedding() {
  const text = document.getElementById('embeddingText').value.trim();
  if (!text) return;
  showStatus('embeddingStatus', 'Loading embedding model + embedding…', 'info');
  document.getElementById('embedBtn').disabled = true;
  let engine = null;
  try {
    engine = await LlamaEngine.open({
      modelPath: modelPathFor(EMBEDDING_MODEL),
      nCtx: 512,
      embedding: true,
      chat: false,
    });
    const rows = await engine.embed([text]);
    const embedding = rows[0] || [];
    const dim = embedding.length;
    let output = `Embedding Dimension: ${dim}\n`;
    if (dim > 0) {
      const head = embedding.slice(0, 10).map((v) => v.toFixed(6)).join(', ');
      const tail = embedding.slice(-10).map((v) => v.toFixed(6)).join(', ');
      output += `First 10 values: [${head}]\n`;
      output += `Last 10 values: [${tail}]\n`;
      output += `Min: ${Math.min(...embedding).toFixed(6)}\n`;
      output += `Max: ${Math.max(...embedding).toFixed(6)}\n`;
      const mean = embedding.reduce((a, b) => a + b, 0) / dim;
      output += `Mean: ${mean.toFixed(6)}\n`;
      if (embedding.every((v) => v === 0)) {
        output += '\n⚠️ WARNING: all embedding values are zero!\n';
      }
    }
    const resultEl = document.getElementById('embeddingResult');
    resultEl.textContent = output;
    resultEl.style.display = 'block';
    showStatus('embeddingStatus', 'Embedding generated successfully!', 'success');
  } catch (error) {
    console.error('Embedding failed:', error);
    showStatus('embeddingStatus', `Failed: ${error.message}`, 'error');
  } finally {
    if (engine) await engine.close();
    document.getElementById('embedBtn').disabled = false;
  }
}

// ------------------------------------------------------------------- boot

document.addEventListener('DOMContentLoaded', () => {
  populateModelSelect();
  document.getElementById('loadBtn').addEventListener('click', loadModel);
  document.getElementById('sendBtn').addEventListener('click', send);
  document.getElementById('stopBtn').addEventListener('click', stop);
  document.getElementById('embedBtn').addEventListener('click', generateEmbedding);
  LlamaEngine.libraryVersion()
    .then((v) => appendLog(`llama_mobile v2 — LlamaEngine demo (lib ${v})`))
    .catch(() => appendLog('llama_mobile v2 — LlamaEngine demo'));
});
