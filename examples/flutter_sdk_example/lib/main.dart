// flutter_sdk_example — llama_mobile v2 (LlamaEngine) example app.
//
// v2 rewrite of the old v1 multi-screen demo (LlamaMobile facade removed on the
// v2 branch). Ported to the v2 wrapper surface that the Flutter SDK exposes:
//   open/generate/abort/modelInfo/tokenize/detokenize/embed/initMultimodal.
// The Dart wrapper is async-only (§8) — none of these calls block the UI.
// TTS and LoRA live at the core/iOS/Android level in v2.0, so this example
// covers Chat, Embeddings, Vision (multimodal) and Model introspection.

import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LlamaEngine v2 — Flutter SDK Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('LlamaEngine v2 — Flutter'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.chat_bubble), text: 'Chat'),
                Tab(icon: Icon(Icons.text_fields), text: 'Embed'),
                Tab(icon: Icon(Icons.image), text: 'Vision'),
                Tab(icon: Icon(Icons.info_outline), text: 'Model'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _ChatTab(),
              _EmbedTab(),
              _VisionTab(),
              _ModelTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _LogBox extends StatelessWidget {
  const _LogBox({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller,
        readOnly: true,
        maxLines: null,
        expands: true,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }
}

void _log(TextEditingController c, String line) {
  c.text = '${c.text}${c.text.isEmpty ? '' : '\n'}$line';
}

// ------------------------------------------------------------------ Chat tab

class _ChatTab extends StatefulWidget {
  const _ChatTab();
  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final _modelPath = TextEditingController(text: '/path/to/chat/model.gguf');
  final _prompt = TextEditingController();
  final _logCtrl = TextEditingController();
  LlamaEngine? _engine;
  bool _busy = false;

  @override
  void dispose() {
    _engine?.close();
    _modelPath.dispose();
    _prompt.dispose();
    _logCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final path = _modelPath.text.trim();
    if (path.isEmpty) return;
    _setBusy(true);
    _log(_logCtrl, 'Loading $path …');
    try {
      final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: path));
      final info = await engine.modelInfo();
      await _engine?.close();
      _engine = engine;
      _log(_logCtrl,
          'Loaded: ${info.description.isNotEmpty ? info.description : path}');
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Load failed: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _send() async {
    final engine = _engine;
    if (engine == null) return;
    final text = _prompt.text.trim();
    if (text.isEmpty || _busy) return;
    _prompt.clear();
    _setBusy(true);
    _log(_logCtrl, 'Q: $text');
    try {
      final r = await engine.generate(LlamaGenerationRequest(
        messages: [LlamaChatMessage('user', text)],
        maxTokens: 256,
      ));
      if (r.stopReason == LlamaStopReason.aborted) {
        _log(_logCtrl, 'A: [stopped]');
      } else {
        _log(_logCtrl, 'A: ${r.text}');
      }
      _log(_logCtrl, '— ${r.usage.generatedTokens} tokens, reason '
          '${r.stopReason.name}');
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Error: $e');
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _stop() async {
    final ok = await _engine?.abort() ?? false;
    if (ok) _log(_logCtrl, 'abort requested');
  }

  void _setBusy(bool busy) => setState(() => _busy = busy);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Card(
          title: 'Model',
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _modelPath,
                  decoration: const InputDecoration(
                      labelText: 'Chat model .gguf path',
                      border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _busy ? null : _load,
                child: Text(_engine == null ? 'Load' : 'Reload'),
              ),
            ],
          ),
        ),
        _Card(
          title: 'Chat (single-shot generate; Stop aborts)',
          child: Column(
            children: [
              _LogBox(controller: _logCtrl),
              const SizedBox(height: 8),
              TextField(
                controller: _prompt,
                decoration: const InputDecoration(
                    hintText: 'Message', border: OutlineInputBorder()),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  FilledButton(
                    onPressed: (_busy || _engine == null) ? null : _send,
                    child: const Text('Send'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _busy ? _stop : null,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Embed tab

class _EmbedTab extends StatefulWidget {
  const _EmbedTab();
  @override
  State<_EmbedTab> createState() => _EmbedTabState();
}

class _EmbedTabState extends State<_EmbedTab> {
  final _modelPath =
      TextEditingController(text: '/path/to/embedding/model.gguf');
  final _text = TextEditingController(text: 'Hello llama mobile v2');
  final _logCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _modelPath.dispose();
    _text.dispose();
    _logCtrl.dispose();
    super.dispose();
  }

  Future<void> _embed() async {
    final path = _modelPath.text.trim();
    final text = _text.text.trim();
    if (path.isEmpty || text.isEmpty) return;
    setState(() => _busy = true);
    LlamaEngine? engine;
    try {
      engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: path)
        ..embedding = true);
      final rows = await engine.embed([text]);
      if (rows.isEmpty || rows.first.isEmpty) {
        _log(_logCtrl, 'Empty embedding result');
      } else {
        final v = rows.first;
        final head = v.take(8).map((x) => x.toStringAsFixed(4)).join(', ');
        _log(_logCtrl,
            'dim=${v.length}\nhead=[$head]\nmin=${v.reduce((a, b) => a < b ? a : b).toStringAsFixed(4)} '
            'max=${v.reduce((a, b) => a > b ? a : b).toStringAsFixed(4)}');
      }
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Embed failed: $e');
    } finally {
      await engine?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Card(
          title: 'Embeddings (opens its own engine with embedding = true)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _modelPath,
                decoration: const InputDecoration(
                    labelText: 'Embedding model .gguf path',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _text,
                decoration: const InputDecoration(
                    labelText: 'Text', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _embed,
                child: const Text('Embed'),
              ),
              const SizedBox(height: 8),
              _LogBox(controller: _logCtrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Vision tab

class _VisionTab extends StatefulWidget {
  const _VisionTab();
  @override
  State<_VisionTab> createState() => _VisionTabState();
}

class _VisionTabState extends State<_VisionTab> {
  final _modelPath = TextEditingController(text: '/path/to/vision/model.gguf');
  final _mmproj = TextEditingController(text: '/path/to/mmproj.gguf');
  final _image = TextEditingController(text: '/path/to/image.jpg');
  final _prompt =
      TextEditingController(text: 'Describe this picture in a few words.');
  final _logCtrl = TextEditingController();
  LlamaEngine? _engine;
  bool _busy = false;
  bool _ready = false;

  @override
  void dispose() {
    _engine?.close();
    for (final c in [_modelPath, _mmproj, _image, _prompt, _logCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final path = _modelPath.text.trim();
    final mm = _mmproj.text.trim();
    if (path.isEmpty || mm.isEmpty) return;
    setState(() => _busy = true);
    try {
      final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: path));
      final ok = await engine.initMultimodal(mm);
      if (!ok) throw LlamaException(LlamaStatus.unsupported, 'initMultimodal');
      await _engine?.close();
      _engine = engine;
      setState(() => _ready = true);
      _log(_logCtrl, 'Vision model + mmproj loaded.');
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Load failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ask() async {
    final engine = _engine;
    if (engine == null) return;
    final img = _image.text.trim();
    final prompt = _prompt.text.trim();
    if (img.isEmpty || prompt.isEmpty || _busy) return;
    setState(() => _busy = true);
    _log(_logCtrl, 'Q($img): $prompt');
    try {
      final r = await engine.generate(LlamaGenerationRequest(
        prompt: prompt,
        mediaPaths: [img],
        maxTokens: 64,
      ));
      _log(_logCtrl, 'A: ${r.text}');
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Card(
          title: 'Vision model + mmproj',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _modelPath,
                  decoration: const InputDecoration(
                      labelText: 'Vision model .gguf',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: _mmproj,
                  decoration: const InputDecoration(
                      labelText: 'mmproj .gguf', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _busy ? null : _load,
                  child: Text(_ready ? 'Reload' : 'Load')),
            ],
          ),
        ),
        _Card(
          title: 'Ask about an image',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _image,
                  decoration: const InputDecoration(
                      labelText: 'Image path',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: _prompt,
                  decoration: const InputDecoration(
                      labelText: 'Prompt', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: (_busy || !_ready) ? null : _ask,
                  child: const Text('Generate')),
              const SizedBox(height: 8),
              _LogBox(controller: _logCtrl),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Model tab

class _ModelTab extends StatefulWidget {
  const _ModelTab();
  @override
  State<_ModelTab> createState() => _ModelTabState();
}

class _ModelTabState extends State<_ModelTab> {
  final _modelPath = TextEditingController(text: '/path/to/model.gguf');
  final _text = TextEditingController(text: 'Hello llama mobile v2');
  final _logCtrl = TextEditingController();
  LlamaEngine? _engine;
  bool _busy = false;

  @override
  void dispose() {
    _engine?.close();
    _modelPath.dispose();
    _text.dispose();
    _logCtrl.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final path = _modelPath.text.trim();
    if (path.isEmpty) return;
    setState(() => _busy = true);
    try {
      final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: path));
      await _engine?.close();
      _engine = engine;
      final info = await engine.modelInfo();
      _log(_logCtrl,
          'description: ${info.description}\n'
          'n_ctx=${info.nCtx}  n_embd=${info.nEmbd}\n'
          'size=${info.modelSizeBytes} bytes  params=${info.nParams}');
      final tokens = await engine.tokenize(_text.text);
      final round = await engine.detokenize(tokens);
      _log(_logCtrl,
          'tokenize("${_text.text}") → ${tokens.length} tokens\n'
          'detokenize → "$round"');
    } on LlamaException catch (e) {
      _log(_logCtrl, 'Failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _Card(
          title: 'Introspection (modelInfo + tokenize/detokenize)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: _modelPath,
                  decoration: const InputDecoration(
                      labelText: 'Model .gguf path',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(
                  controller: _text,
                  decoration: const InputDecoration(
                      labelText: 'Text to tokenize',
                      border: OutlineInputBorder())),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: _busy ? null : _open,
                  child: const Text('Inspect')),
              const SizedBox(height: 8),
              _LogBox(controller: _logCtrl),
            ],
          ),
        ),
      ],
    );
  }
}
