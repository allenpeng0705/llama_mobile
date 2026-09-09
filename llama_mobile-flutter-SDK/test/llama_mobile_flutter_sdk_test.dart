// Pure-Dart unit tests for the v2 API surface.
//
// Two layers:
//  * Pure model tests (enums, serialization) — no platform channel.
//  * Channel-mock tests — the v2 method channel
//    `llama_mobile_flutter_sdk/v2` is faked with a
//    TestDefaultBinaryMessenger handler, so the wrapper's decode paths
//    (open/generate/tokenize/detokenize/embed/modelInfo/abort/close) and its
//    PlatformException → LlamaException mapping are exercised without a device.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('llama_mobile_flutter_sdk/v2');

  // ---------- pure model tests (no channel) ----------

  test('status codes mirror v2 IDL', () {
    expect(LlamaStatus.ok.code, 0);
    expect(LlamaStatus.alreadyRunning.code, -14);
    expect(LlamaStatus.fromCode(-14), LlamaStatus.alreadyRunning);
    expect(LlamaStatus.fromCode(12345), LlamaStatus.generation);
  });

  test('request serializes messages + sampling', () {
    final req = LlamaGenerationRequest(
      messages: const [
        LlamaChatMessage('user', 'What is 2+2?'),
      ],
      maxTokens: 32,
    );
    final json = req.toJson();
    expect(json['maxTokens'], 32);
    expect((json['roles'] as List).first, 'user');
    expect((json['contents'] as List).first, 'What is 2+2?');
    expect((json['sampling'] as Map)['temperature'], 0.8);
  });

  test('config serializes context flags', () {
    final c = LlamaEngineConfig(modelPath: '/tmp/m.gguf')
      ..nCtx = 4096
      ..embedding = true;
    final json = c.toJson();
    expect(json['modelPath'], '/tmp/m.gguf');
    expect(json['nCtx'], 4096);
    expect(json['embedding'], true);
  });

  test('request serializes mediaPaths + jsonSchema + stopSequences', () {
    final req = LlamaGenerationRequest(
      prompt: 'look',
      mediaPaths: const ['/a.jpg'],
      stopSequences: const ['\n'],
      jsonSchema: '{"type":"object"}',
      maxTokens: 8,
    );
    final json = req.toJson();
    expect(json['mediaPaths'], ['/a.jpg']);
    expect(json['stopSequences'], ['\n']);
    expect(json['jsonSchema'], '{"type":"object"}');
  });

  // ---------- channel-mock tests ----------

  void mockChannel(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('libraryVersion reads the native version string', () async {
    mockChannel((call) async {
      expect(call.method, 'version');
      return '2.0.0';
    });
    expect(await LlamaEngine.libraryVersion(), '2.0.0');
  });

  test('open decodes the handle; generate decodes result + stopReason',
      () async {
    mockChannel((call) async {
      switch (call.method) {
        case 'open':
          return 42;
        case 'generate':
          return {
            'text': 'hello',
            'stopReason': 0, // eos
            'promptTokens': 3,
            'generatedTokens': 5,
          };
        default:
          return null;
      }
    });
    final engine = await LlamaEngine.open(
      LlamaEngineConfig(modelPath: '/tmp/m.gguf'),
    );
    final r = await engine.generate(LlamaGenerationRequest(prompt: 'hi'));
    expect(r.text, 'hello');
    expect(r.stopReason, LlamaStopReason.eos);
    expect(r.usage.generatedTokens, 5);
  });

  test('open failure maps PlatformException code to LlamaException', () async {
    mockChannel((call) async {
      if (call.method == 'open') {
        throw PlatformException(code: '-4', message: 'model load failed');
      }
      return null;
    });
    await expectLater(
      LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf')),
      throwsA(isA<LlamaException>()
          .having((e) => e.status, 'status', LlamaStatus.modelLoad)),
    );
  });

  test('generate failure maps alreadyRunning (-14)', () async {
    mockChannel((call) async {
      if (call.method == 'open') return 7;
      if (call.method == 'generate') {
        throw PlatformException(code: '-14', message: 'busy');
      }
      return null;
    });
    final engine =
        await LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf'));
    await expectLater(
      engine.generate(LlamaGenerationRequest(prompt: 'hi')),
      throwsA(isA<LlamaException>()
          .having((e) => e.status, 'status', LlamaStatus.alreadyRunning)),
    );
  });

  test('zero handle from open maps to LlamaException.modelLoad', () async {
    mockChannel((call) async {
      if (call.method == 'open') return 0; // 0 handle → load failure
      return null;
    });
    await expectLater(
      LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf')),
      throwsA(isA<LlamaException>()
          .having((e) => e.status, 'status', LlamaStatus.modelLoad)),
    );
  });

  test('tokenize/detokenize decode integer arrays and strings', () async {
    mockChannel((call) async {
      if (call.method == 'open') return 7;
      if (call.method == 'tokenize') {
        expect((call.arguments as Map)['handle'], 7);
        expect((call.arguments as Map)['text'], 'hi there');
        return [12, 34, 56];
      }
      if (call.method == 'detokenize') {
        final args = call.arguments as Map;
        expect(args['handle'], 7);
        expect((args['tokens'] as List).cast<int>(), [12, 34, 56]);
        return 'hi there';
      }
      return null;
    });
    final engine =
        await LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf'));
    final tokens = await engine.tokenize('hi there');
    expect(tokens, [12, 34, 56]);
    expect(await engine.detokenize(tokens), 'hi there');
  });

  test('embed decodes rows of doubles', () async {
    mockChannel((call) async {
      if (call.method == 'open') return 9;
      if (call.method == 'embed') {
        final args = call.arguments as Map;
        expect(args['handle'], 9);
        expect((args['texts'] as List), ['a', 'b']);
        return [
          [0.1, 0.2],
          [0.3, 0.4],
        ];
      }
      return null;
    });
    final engine =
        await LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/e.gguf'));
    final rows = await engine.embed(['a', 'b']);
    expect(rows.length, 2);
    expect(rows[0], [0.1, 0.2]);
    expect(rows[1], [0.3, 0.4]);
  });

  test('modelInfo decodes info fields; initMultimodal/abort/close pass handle',
      () async {
    final calls = <String>[];
    mockChannel((call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'open':
          return 3;
        case 'modelInfo':
          return {
            'nCtx': 2048,
            'nEmbd': 1024,
            'modelSizeBytes': 123,
            'nParams': 456,
            'description': 'test model',
          };
        case 'initMultimodal':
          expect((call.arguments as Map)['mmprojPath'], '/tmp/mmproj.gguf');
          return true;
        case 'abort':
          expect((call.arguments as Map)['handle'], 3);
          return true;
        default:
          return null;
      }
    });
    final engine = await LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf'));
    final info = await engine.modelInfo();
    expect(info.nCtx, 2048);
    expect(info.nEmbd, 1024);
    expect(info.modelSizeBytes, 123);
    expect(info.nParams, 456);
    expect(info.description, 'test model');
    expect(await engine.initMultimodal('/tmp/mmproj.gguf'), isTrue);
    expect(await engine.abort(), isTrue);
    await engine.close();
    expect(calls, containsAll(['open', 'modelInfo', 'initMultimodal', 'abort', 'close']));
  });
  test('tts + multimodal methods decode through the channel', () async {
    mockChannel((call) async {
      if (call.method == 'open') return 3;
      if (call.method == 'ttsSpeak') {
        final a = call.arguments as Map;
        expect(a['handle'], 3);
        expect(a['text'], 'hi');
        expect(a['sampleRate'], 48000);
        return [0, 1, -2];
      }
      if (call.method == 'ttsEnabled') return true;
      if (call.method == 'supportsVision') return true;
      if (call.method == 'multimodalEnabled') return false;
      if (call.method == 'releaseMultimodal') return true;
      return null;
    });
    final engine =
        await LlamaEngine.open(LlamaEngineConfig(modelPath: '/tmp/m.gguf'));
    final pcm = await engine.ttsSpeak('hi', sampleRate: 48000);
    expect(pcm, [0, 1, -2]);
    expect(await engine.ttsEnabled(), isTrue);
    expect(await engine.supportsVision(), isTrue);
    expect(await engine.multimodalEnabled(), isFalse);
    expect(await engine.releaseMultimodal(), isTrue);
  });
}
