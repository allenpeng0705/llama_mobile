// Image.tsx — v2 (LlamaEngine) vision tab: load a vision GGUF + mmproj
// (initMultimodal), then generate a caption for a local image via mediaPaths.
import { useState } from 'react';
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';
import { modelPathFor, errMessage } from '../utils';

const VISION_MODEL = 'SmolVLM-256M-Instruct-Q8_0.gguf';
const MMPROJ_MODEL = 'mmproj-SmolVLM-256M-Instruct-Q8_0.gguf';

export default function Image() {
  const [engine, setEngine] = useState<LlamaEngine | null>(null);
  const [busy, setBusy] = useState(false);
  const [imagePath, setImagePath] = useState('');
  const [prompt, setPrompt] = useState('Describe this picture in a few words.');
  const [log, setLog] = useState('');
  const [status, setStatus] = useState('');

  const push = (line: string) => setLog((prev) => `${prev}${prev ? '\n' : ''}${line}`);

  const load = async () => {
    setBusy(true);
    setStatus('Loading vision model + mmproj…');
    try {
      const eng = await LlamaEngine.open({
        modelPath: modelPathFor(VISION_MODEL),
        nCtx: 2048,
        chat: true,
        embedding: false,
      });
      const ok = await eng.initMultimodal(modelPathFor(MMPROJ_MODEL));
      if (!ok) throw new Error('initMultimodal returned false');
      await engine?.close();
      setEngine(eng);
      push('Vision model + mmproj loaded.');
      setStatus('Ready — enter an image path and prompt below.');
    } catch (e) {
      setStatus(`Load failed: ${errMessage(e)}`);
    } finally {
      setBusy(false);
    }
  };

  const ask = async () => {
    const img = imagePath.trim();
    const q = prompt.trim();
    if (!engine || !img || !q || busy) return;
    setBusy(true);
    push(`Q(${img}): ${q}`);
    try {
      const r = await engine.generate({
        prompt: q,
        mediaPaths: [img],
        maxTokens: 64,
      });
      push(`A: ${r.text}`);
    } catch (e) {
      push(`Error: ${errMessage(e)}`);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="embeddings-container">
      <button className="primary-button" onClick={load} disabled={busy}>
        {engine ? 'Reload vision model' : 'Load vision model + mmproj'}
      </button>
      <input
        className="chat-input"
        value={imagePath}
        onChange={(e) => setImagePath(e.target.value)}
        placeholder="Absolute path to an image on the device"
      />
      <textarea
        className="chat-input"
        value={prompt}
        onChange={(e) => setPrompt(e.target.value)}
        rows={2}
      />
      <button className="primary-button" onClick={ask} disabled={!engine || busy}>
        Generate
      </button>
      {log && <pre className="embeddings-result">{log}</pre>}
      {status && <div className="status-message">{status}</div>}
    </div>
  );
}
