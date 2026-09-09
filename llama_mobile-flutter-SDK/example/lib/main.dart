import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

/// Self-run device smoke (temporary): when a bundled fixture exists
/// (assets/models/…), the example loads it with GPU layers and chats once on
/// startup, printing the result into the log so a real device can be verified
/// without the flutter tool attaching.
Future<File?> _assetToTemp(String asset) async {
  try {
    final data = (await rootBundle.load(asset)).buffer.asUint8List();
    final dir = await Directory.systemTemp.createTemp('llama');
    final f = File('${dir.path}/${asset.split('/').last}');
    await f.writeAsBytes(data, flush: true);
    return f;
  } catch (_) {
    return null;
  }
}

Future<void> _runBundledModelSmoke(_HomePageState page) async {
  final gpu = Platform.isIOS ? 99 : (Platform.isAndroid ? 60 : 0);
  Future<void> step(String label, Future<void> Function() body) async {
    try {
      await body();
      page._append('[smoke] $label OK');
    } catch (e) {
      page._append('[smoke] $label FAILED: $e');
    }
  }

  // 1/4 chat (existing bundled SmolLM)
  await step('1/4 chat', () async {
    final model = await _assetToTemp('assets/models/SmolLM-360M-Instruct.Q6_K.gguf');
    if (model == null) throw Exception('no smolLM asset');
    page._append('[smoke] loading chat (GPU $gpu)…');
    final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: model.path)
      ..nGpuLayers = gpu);
    try {
      final info = await engine.modelInfo();
      final r = await engine.generate(LlamaGenerationRequest(
        messages: const [LlamaChatMessage('user', 'Say hello in one short sentence.')],
        maxTokens: 24,
        sampling: LlamaSampling()..temperature = 0,
      ));
      page._append('[smoke] chat reply: ${r.text} (${info.description})');
    } finally {
      await engine.close();
    }
  });

  // 2/4 embed
  await step('2/4 embed', () async {
    final model = await _assetToTemp('assets/models/Qwen3-Embedding-0.6B-Q8_0.gguf');
    if (model == null) throw Exception('no embed asset');
    final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: model.path)
      ..nGpuLayers = gpu
      ..embedding = true);
    try {
      final rows = await engine.embed(['hello llama']);
      page._append('[smoke] embed dim=${rows.first.length}');
    } finally {
      await engine.close();
    }
  });

  // 3/4 vision
  await step('3/4 vision', () async {
    final model = await _assetToTemp('assets/models/SmolVLM-256M-Instruct-Q8_0.gguf');
    final mm = await _assetToTemp('assets/models/mmproj-SmolVLM-256M-Instruct-Q8_0.gguf');
    final img = await _assetToTemp('assets/models/image.jpg');
    if (model == null || mm == null || img == null) throw Exception('no vision assets');
    final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: model.path)
      ..nGpuLayers = gpu);
    try {
      final ok = await engine.initMultimodal(mm.path);
      if (!ok) throw Exception('initMultimodal false');
      final r = await engine.generate(LlamaGenerationRequest(
        prompt: 'Describe this picture in a few words.',
        mediaPaths: [img.path],
        maxTokens: 32,
        sampling: LlamaSampling()..temperature = 0,
      ));
      page._append('[smoke] vision: ${r.text}');
    } finally {
      await engine.close();
    }
  });

  // 4/4 TTS
  await step('4/4 tts', () async {
    final model = await _assetToTemp('assets/models/OuteTTS-0.2-500M-Q6_K.gguf');
    final voc = await _assetToTemp('assets/models/WavTokenizer-Large-75-F16.gguf');
    if (model == null || voc == null) throw Exception('no tts assets');
    final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: model.path)
      ..nGpuLayers = gpu);
    try {
      final ok = await engine.ttsInit(voc.path);
      if (!ok) throw Exception('ttsInit false');
      final pcm = await engine.ttsSpeak('Hello from flutter on device speech.');
      page._append('[smoke] tts pcm=${pcm.length}');
      await engine.ttsRelease();
    } finally {
      await engine.close();
    }
  });

  page._append('[smoke] ALL APIS DONE');
}

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
    // Temporary self-run device smoke (bundled fixture); no-op when the
    // fixture is absent (normal example usage stays interactive).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runBundledModelSmoke(this));
    });
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
