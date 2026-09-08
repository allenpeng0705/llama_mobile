// App.tsx — llama_mobile v2 (LlamaEngine) Capacitor example shell.
//
// v2 rewrite of the v1 demo (initContext/contextHandle are gone). Each tab
// manages its own LlamaEngine over the async-only v2 wrapper; TTS is not yet
// in the wrapper (core/iOS/Android level in v2.0), so tabs are
// Chat / Embed / Vision / Introspection.
import { useEffect, useState } from 'react';
import { LlamaEngine } from 'llama-mobile-capacitor-plugin';
import './App.css';
import Chat from './components/Chat';
import Embed from './components/Embed';
import Image from './components/Image';
import More from './components/More';
import { errMessage } from './utils';

type TabId = 'chat' | 'embed' | 'image' | 'more';

const TABS: { id: TabId; label: string; icon: string }[] = [
  { id: 'chat', label: 'Chat', icon: '💬' },
  { id: 'embed', label: 'Embed', icon: '📐' },
  { id: 'image', label: 'Vision', icon: '🖼️' },
  { id: 'more', label: 'Model', icon: '🔍' },
];

export default function App() {
  const [tab, setTab] = useState<TabId>('chat');
  const [version, setVersion] = useState('');

  useEffect(() => {
    LlamaEngine.libraryVersion()
      .then(setVersion)
      .catch((e) => setVersion(`? (${errMessage(e)})`));
  }, []);

  return (
    <div className="app-container">
      <header className="app-header">
        <h1>LlamaEngine v2 — Capacitor (React)</h1>
        <span className="status-message">lib {version}</span>
      </header>
      <div className="tabs">
        {TABS.map((t) => (
          <button
            key={t.id}
            className={`tab-button${tab === t.id ? ' active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            <span className="tab-icon">{t.icon}</span>
            {t.label}
          </button>
        ))}
      </div>
      <div className="tab-content">
        {tab === 'chat' && <Chat />}
        {tab === 'embed' && <Embed />}
        {tab === 'image' && <Image />}
        {tab === 'more' && <More />}
      </div>
    </div>
  );
}
