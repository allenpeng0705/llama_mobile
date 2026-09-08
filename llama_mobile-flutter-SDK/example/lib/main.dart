import 'package:flutter/material.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LlamaEngine (v2) Flutter Example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _modelPath = TextEditingController();
  final _prompt = TextEditingController();
  final _log = StringBuffer();
  late final TextEditingController _logCtrl;
  LlamaEngine? _engine;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _logCtrl = TextEditingController();
    _append('llama_mobile v2 — LlamaEngine demo');
  }

  @override
  void dispose() {
    _engine?.close();
    _modelPath.dispose();
    _prompt.dispose();
    _logCtrl.dispose();
    super.dispose();
  }

  void _append(String line) {
    _log.writeln(line);
    _logCtrl.text = _log.toString();
  }

  Future<void> _load() async {
    final path = _modelPath.text.trim();
    if (path.isEmpty) {
      _append('Set a .gguf model path first');
      return;
    }
    setState(() => _busy = true);
    _append('Loading $path …');
    try {
      final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: path));
      final info = await engine.modelInfo();
      _engine = engine;
      _append('Loaded: ${info.description.isNotEmpty ? info.description : path}');
    } on LlamaException catch (e) {
      _append('Load failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final engine = _engine;
    if (engine == null) {
      _append('Load a model first');
      return;
    }
    final text = _prompt.text.trim();
    if (text.isEmpty) return;
    _prompt.clear();
    setState(() => _busy = true);
    _append('Q: $text');
    try {
      final result = await engine.generate(LlamaGenerationRequest(
        messages: [LlamaChatMessage('user', text)],
        maxTokens: 128,
      ));
      if (result.stopReason == LlamaStopReason.aborted) {
        _append('[stopped]');
      }
      _append('A: ${result.text}');
      _append('— done (${result.usage.generatedTokens} tokens)');
    } on LlamaException catch (e) {
      _append('Error: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final ok = await _engine?.abort() ?? false;
    _append(ok ? 'abort requested' : 'nothing running');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('LlamaEngine v2 — Flutter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _modelPath,
                    decoration: const InputDecoration(
                      hintText: '/path/to/model.gguf',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : _load,
                  child: Text(_engine == null ? 'Load' : 'Reload'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _logCtrl,
                readOnly: true,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _prompt,
              decoration: const InputDecoration(
                hintText: 'Message',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (_busy || _engine == null) ? null : _send,
                    child: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? _stop : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
