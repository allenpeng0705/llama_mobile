// More.tsx — v2 (LlamaEngine) model-introspection tab: modelInfo +
// tokenize/detokenize on an opened engine. TTS/LoRA are not yet exposed by the
// v2 Capacitor wrapper (they live at the core/iOS/Android level in v2.0).
import { useState } from 'react';
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';
import { modelPathFor, errMessage } from '../utils';

const MODEL = 'SmolLM-360M-Instruct.Q6_K.gguf';

export default function More() {
  const [busy, setBusy] = useState(false);
  const [text, setText] = useState('Hello llama mobile v2');
  const [log, setLog] = useState('');
  const [status, setStatus] = useState('');

  const inspect = async () => {
    setBusy(true);
    setStatus('Loading model…');
    let engine: LlamaEngine | null = null;
    try {
      engine = await LlamaEngine.open({
        modelPath: modelPathFor(MODEL),
        nCtx: 2048,
        chat: true,
        embedding: false,
      });
      const info = await engine.modelInfo();
      const tokens = await engine.tokenize(text);
      const round = await engine.detokenize(tokens);
      setLog(
        `description: ${info.description}\n` +
          `n_ctx=${info.nCtx}  n_embd=${info.nEmbd}\n` +
          `size=${info.modelSizeBytes} bytes  params=${info.nParams}\n\n` +
          `tokenize("${text}") → ${tokens.length} tokens\n` +
          `detokenize → "${round}"`,
      );
      setStatus('Done');
    } catch (e) {
      setStatus(`Failed: ${errMessage(e)}`);
    } finally {
      await engine?.close();
      setBusy(false);
    }
  };

  return (
    <div className="settings-container">
      <div className="setting-section">
        <h3>Introspection</h3>
        <div className="status-message">
          modelInfo + tokenize/detokenize via the v2 wrapper. Uses {MODEL}.
        </div>
        <textarea
          className="chat-input"
          value={text}
          onChange={(e) => setText(e.target.value)}
          rows={2}
        />
        <button className="primary-button" onClick={inspect} disabled={busy}>
          Inspect
        </button>
        {log && <pre className="embeddings-result">{log}</pre>}
        {status && <div className="status-message">{status}</div>}
      </div>
    </div>
  );
}
