// Chat.tsx — v2 (LlamaEngine) chat tab: load a chat GGUF, send one-shot
// generate requests, abort a running generation. Async-only wrapper.
import { useState } from 'react';
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';
import type { LlamaModelInfo } from 'llama-mobile-capacitor-plugin';
import { modelPathFor, errMessage, stopReasonName } from '../utils';

interface Entry {
  kind: 'q' | 'a' | 'sys' | 'err';
  text: string;
}

const CHAT_MODELS = [
  'SmolLM-360M-Instruct.Q6_K.gguf',
  'Qwen3-1.7B-Q4_K_M.gguf',
];

export default function Chat() {
  const [model, setModel] = useState(CHAT_MODELS[0]);
  const [engine, setEngine] = useState<LlamaEngine | null>(null);
  const [info, setInfo] = useState<LlamaModelInfo | null>(null);
  const [entries, setEntries] = useState<Entry[]>([]);
  const [prompt, setPrompt] = useState('');
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('');

  const push = (kind: Entry['kind'], text: string) =>
    setEntries((prev) => [...prev, { kind, text }]);

  const load = async () => {
    setBusy(true);
    setStatus(`Loading ${model} …`);
    try {
      const path = modelPathFor(model);
      const eng = await LlamaEngine.open({
        modelPath: path,
        nCtx: 2048,
        chat: true,
        embedding: false,
      });
      await engine?.close();
      setEngine(eng);
      const mi = await eng.modelInfo();
      setInfo(mi);
      push('sys', `Loaded ${model} (n_ctx=${mi.nCtx}) — ask anything.`);
      setStatus('Ready');
    } catch (e) {
      setStatus(`Load failed: ${errMessage(e)}`);
    } finally {
      setBusy(false);
    }
  };

  const send = async () => {
    const text = prompt.trim();
    if (!engine || !text || busy) return;
    setPrompt('');
    setBusy(true);
    push('q', text);
    try {
      const r = await engine.generate({
        messages: [{ role: 'user', content: text }],
        maxTokens: 256,
        sampling: { temperature: 0.8 },
      });
      if (r.stopReason === 3) {
        push('a', '[stopped]');
      } else {
        push('a', r.text);
      }
      push('sys', `— ${r.generatedTokens} tokens, reason ${stopReasonName(r.stopReason)}`);
    } catch (e) {
      push('err', `Error: ${errMessage(e)}`);
    } finally {
      setBusy(false);
    }
  };

  const stop = async () => {
    if (!engine) return;
    try {
      const ok = await engine.abort();
      if (ok) push('sys', 'abort requested');
    } catch (e) {
      push('err', `Abort failed: ${errMessage(e)}`);
    }
  };

  return (
    <div className="chat-container">
      <div className="model-picker">
        <label>Chat model:</label>
        <select value={model} onChange={(e) => setModel(e.target.value)}>
          {CHAT_MODELS.map((m) => (
            <option key={m} value={m}>
              {m}
            </option>
          ))}
        </select>
        <button className="primary-button" onClick={load} disabled={busy}>
          {engine ? 'Reload' : 'Load'}
        </button>
      </div>
      {info && (
        <div className="status-message">
          {info.description} — n_ctx {info.nCtx}
        </div>
      )}
      <div className="chat-messages">
        {entries.map((e, i) => (
          <div key={i} className={`message ${e.kind}`}>
            {e.text}
          </div>
        ))}
      </div>
      <div className="chat-input">
        <input
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && send()}
          placeholder="Message…"
          disabled={!engine || busy}
        />
        <button className="primary-button" onClick={send} disabled={!engine || busy}>
          Send
        </button>
        <button className="secondary-button" onClick={stop} disabled={!busy}>
          Stop
        </button>
      </div>
      {status && <div className="status-message">{status}</div>}
    </div>
  );
}
