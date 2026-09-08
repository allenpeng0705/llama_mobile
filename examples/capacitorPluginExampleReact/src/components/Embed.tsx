// Embed.tsx — v2 (LlamaEngine) embeddings tab: opens the Qwen3-Embedding
// engine transiently (embedding = true), embeds a text, reports the vector.
import { useState } from 'react';
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';
import { modelPathFor, errMessage } from '../utils';

const EMBED_MODEL = 'Qwen3-Embedding-0.6B-Q8_0.gguf';

export default function Embed() {
  const [text, setText] = useState('Hello from llama mobile v2');
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState('');
  const [status, setStatus] = useState('');

  const run = async () => {
    const t = text.trim();
    if (!t || busy) return;
    setBusy(true);
    setStatus('Embedding…');
    let engine: LlamaEngine | null = null;
    try {
      engine = await LlamaEngine.open({
        modelPath: modelPathFor(EMBED_MODEL),
        nCtx: 512,
        embedding: true,
        chat: false,
      });
      const rows = await engine.embed([t]);
      const v = rows[0] ?? [];
      if (v.length === 0) {
        setResult('Empty embedding result');
        return;
      }
      const head = v.slice(0, 8).map((x) => x.toFixed(4)).join(', ');
      const min = Math.min(...v);
      const max = Math.max(...v);
      setResult(`dim=${v.length}\nhead=[${head}]\nmin=${min.toFixed(4)} max=${max.toFixed(4)}`);
      setStatus('Done');
    } catch (e) {
      setStatus(`Embedding failed: ${errMessage(e)}`);
    } finally {
      await engine?.close();
      setBusy(false);
    }
  };

  return (
    <div className="embeddings-container">
      <div className="status-message">
        Opens its own engine on {EMBED_MODEL} with <code>embedding = true</code>,
        then releases it.
      </div>
      <textarea
        className="chat-input"
        value={text}
        onChange={(e) => setText(e.target.value)}
        rows={3}
      />
      <button className="primary-button" onClick={run} disabled={busy}>
        Embed
      </button>
      {result && <pre className="embeddings-result">{result}</pre>}
      {status && <div className="status-message">{status}</div>}
    </div>
  );
}
