// example.js — llama_mobile v2 Capacitor demo (LlamaEngine wrapper).
//
// v2 rewrite of the old v1 example (initContext/contextHandle are gone; the
// v2 API is LlamaEngine.open/generate/abort/modelInfo/embed/close, async-only).
// Chat and embedding are separate engines because one engine = one model with
// one active generation (§8).

import { LlamaEngine } from 'llama-mobile-capacitor-plugin';

try { const m = document.getElementById('bootmark'); if (m) m.textContent = 'JS-module-ok'; } catch (e) {}

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

// Capacitor 8 removed the `Capacitor.platform` property; use getPlatform() when
// present and fall back to the legacy property for older Capacitor versions.
function nativePlatform() {
  if (typeof Capacitor.getPlatform === 'function') return Capacitor.getPlatform();
  return Capacitor.platform;
}

function modelPathFor(modelName) {
  const platform = nativePlatform();
  if (platform === 'ios' || platform === 'android') {
    // Both native plugins resolve bundle-relative "models/x" themselves:
    // iOS against Bundle.main resources, Android by extracting the packaged
    // web-asset models into app storage.
    return `models/${modelName}`;
  }
  throw new Error(
    `Unsupported platform (${platform || 'unknown'} — web has no native core)`,
  );
}

// Run on the accelerator: Metal on iOS, Vulkan on Android. The native engines
// honor engine + nGpuLayers; CPU-only TTS is impractically slow on device.
function gpuOpenOptions(base) {
  const platform = nativePlatform();
  if (platform === 'ios') return { ...base, engine: 2, nGpuLayers: 99 };
  if (platform === 'android') return { ...base, engine: 3, nGpuLayers: 99 };
  return base;
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
    const engine = await LlamaEngine.open(
      gpuOpenOptions({
        modelPath: modelPathFor(name),
        nCtx: 2048,
        chat: true,
        embedding: false,
      }),
    );
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
    engine = await LlamaEngine.open(
      gpuOpenOptions({
        modelPath: modelPathFor(EMBEDDING_MODEL),
        nCtx: 512,
        embedding: true,
        chat: false,
      }),
    );
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
    .then((v) => { appendLog(`llama_mobile v2 — LlamaEngine demo (lib ${v})`); mark('version '+v); })
    .catch((e) => { appendLog('llama_mobile v2 — LlamaEngine demo'); mark('ver-err '+e); });
  // Manual mode: user drives Load/Send/Stop/Embed. Sweep available on demand.
  const sb = document.createElement('button');
  sb.textContent = 'Run Auto Sweep';
  sb.style.cssText = 'position:fixed;bottom:10px;right:10px;z-index:99998;';
  document.body.appendChild(sb);
  sb.onclick = () => runSweep().catch(() => appendLog('[cap] sweep aborted'));
});

const sweepModels = {
  chat: 'SmolLM-360M-Instruct.Q6_K.gguf',
  embed: 'Qwen3-Embedding-0.6B-Q8_0.gguf',
  vision: 'SmolVLM-256M-Instruct-Q8_0.gguf',
  mmproj: 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf',
  image: 'image.jpg',
  tts: 'OuteTTS-0.2-500M-Q6_K.gguf',
  vocoder: 'WavTokenizer-Large-75-F16.gguf',
};

function mark(t){ try { const m=document.getElementById('bootmark'); if(m){ m.textContent = t; } } catch(e){} }

async function runSweep() {
  const step = async (label, body) => {
    try {
      const msg = await body();
      appendLog(`[cap] ${label} OK — ${msg}`);
    } catch (e) {
      appendLog(`[cap] ${label} FAILED — ${e.message || e}`);
    }
  };
  await step('1/4 chat', async () => {
    const e = await LlamaEngine.open(gpuOpenOptions({ modelPath: modelPathFor(sweepModels.chat), nCtx: 2048, chat: true }));
    const r = await e.generate({ messages: [{ role: 'user', content: 'Say hello in one short sentence.' }], maxTokens: 24, sampling: { temperature: 0 } });
    await e.close();
    return r.text;
  });
  await step('2/4 embed', async () => {
    const e = await LlamaEngine.open(gpuOpenOptions({ modelPath: modelPathFor(sweepModels.embed), nCtx: 512, embedding: true }));
    const rows = await e.embed(['hello llama']);
    await e.close();
    return `dim=${rows[0].length}`;
  });
  await step('3/4 vision', async () => {
    const e = await LlamaEngine.open(gpuOpenOptions({ modelPath: modelPathFor(sweepModels.vision), nCtx: 2048, chat: true }));
    const ok = await e.initMultimodal(modelPathFor(sweepModels.mmproj));
    if (!ok) throw new Error('initMultimodal false');
    const r = await e.generate({ prompt: 'Describe this picture in a few words.', mediaPaths: [modelPathFor(sweepModels.image)], maxTokens: 32, sampling: { temperature: 0 } });
    await e.close();
    return r.text;
  });
  await step('4/4 tts', async () => {
    const e = await LlamaEngine.open(gpuOpenOptions({ modelPath: modelPathFor(sweepModels.tts), nCtx: 4096, chat: false }));
    const ok = await e.ttsInit(modelPathFor(sweepModels.vocoder));
    if (!ok) throw new Error('ttsInit false');
    const pcm = await e.ttsSpeak('Hello from capacitor on device speech.', 24000, 1.0);
    await e.ttsRelease();
    await e.close();
    return `pcm=${pcm.length}`;
  });
  appendLog('[cap] ALL APIS DONE');
}
