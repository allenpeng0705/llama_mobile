// End-to-end smoke of the v2 Flutter SDK: the LlamaEngine plugin opens a real
// GGUF and runs one chat generation, proving the Dart → plugin → llama_mobile
// core chain loads a model and works on the current platform.
//
// Model source:
//  * On the host/simulator the repo fixture at <repo>/models is used directly
//    when present (simulators share the host filesystem);
//  * on a real device the small SmolLM fixture bundled under
//    assets/models/ is copied to a temp file first (Flutter assets are not
//    plain filesystem paths on iOS).
//
// GPU: nGpuLayers > 0 exercises the Metal backend on a real iPhone; 0 on
// simulator. Override the model with LLAMA_MOBILE_TEST_MODEL (a filesystem
// path) when needed.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'dart:io';
import 'dart:typed_data';

const _assetModel = 'assets/models/SmolLM-360M-Instruct.Q6_K.gguf';

Future<String> _resolveModelPath() async {
  final env = Platform.environment['LLAMA_MOBILE_TEST_MODEL'];
  if (env != null && env.isNotEmpty && await File(env).exists()) return env;
  const host =
      '/Users/shileipeng/Documents/mygithub/llama_mobile/models/SmolLM-360M-Instruct.Q6_K.gguf';
  if (await File(host).exists()) return host;
  // Device: unpack the bundled asset into a temp file.
  final bytes = (await rootBundle.load(_assetModel)).buffer;
  final data = bytes.asUint8List();
  final dir = await Directory.systemTemp.createTemp('llama_smoke');
  final f = File('${dir.path}/model.gguf');
  await f.writeAsBytes(data, flush: true);
  return f.path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LlamaEngine opens a model and chats',
      (WidgetTester tester) async {
    final model = await _resolveModelPath();
    expect(model.isNotEmpty, isTrue, reason: 'no test model available');

    final config = LlamaEngineConfig(modelPath: model)
      ..nGpuLayers = Platform.isIOS && !Platform.isAndroid ? 99 : 0;
    final engine = await LlamaEngine.open(config);
    final info = await engine.modelInfo();
    expect(info.nParams, greaterThan(0), reason: 'model loaded');
    expect(info.description, isNotEmpty);

    final result = await engine.generate(LlamaGenerationRequest(
      messages: const [LlamaChatMessage('user', 'What is 2+2?')],
      maxTokens: 32,
      sampling: LlamaSampling()..temperature = 0,
    ));
    expect(result.text, isNotEmpty,
        reason: 'generation returned text: "${result.text}"');
    expect(result.stopReason, isNot(LlamaStopReason.error));
    await engine.close();
  });
}
