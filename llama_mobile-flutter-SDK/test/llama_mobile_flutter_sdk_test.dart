import 'package:flutter_test/flutter_test.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk_platform_interface.dart';
import 'package:llama_mobile_flutter_sdk/llama_mobile_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLlamaMobileFlutterSdkPlatform
    with MockPlatformInterfaceMixin
    implements LlamaMobileFlutterSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<bool> loadModel(ModelConfig config) => Future.value(true);

  @override
  Future<String> generateCompletion(GenerationConfig config) =>
      Future.value('Mock completion');

  @override
  Future<void> release() => Future.value();

  @override
  Future<bool> initialize(InitParams params) => Future.value(true);

  @override
  Future<String> generate(CompletionParams params) =>
      Future.value('Mock completion');

  @override
  Future<String?> getGrammarContent(GrammarName grammarName) =>
      Future.value('Mock grammar content');

  @override
  Future<CompletionResult> generateResponse(CompletionParams params) {
    return Future.value(
      CompletionResult(
        text: 'Mock completion',
        tokensGenerated: 10,
        tokensEvaluated: 5,
        truncated: false,
        stoppedEos: true,
        stoppedWord: false,
        stoppedLimit: false,
      ),
    );
  }

  @override
  Future<String> streamCompletion(
    CompletionParams params,
    Function(String) onToken,
  ) => Future.value('Mock streamed completion');

  @override
  Future<void> stopCompletion() => Future.value();

  @override
  Future<List<int>> tokenize(String text) => Future.value([1, 2, 3, 4, 5]);

  @override
  Future<String> detokenize(List<int> tokens) =>
      Future.value('Mock detokenized text');

  @override
  Future<List<double>> generateEmbeddings() => Future.value([0.1, 0.2, 0.3]);

  @override
  Future<List<double>> generateEmbeddingsForPrompt(String prompt) =>
      Future.value([0.1, 0.2, 0.3]);

  @override
  Future<bool> initMultimodal() => Future.value(true);

  @override
  Future<bool> initTTS(String ttsPath, TTSModelType modelType) =>
      Future.value(true);

  @override
  Future<String> generateAudio(TTSParams params) =>
      Future.value('/mock/audio/path.mp3');

  @override
  Future<bool> applyLoraAdapters(List<LoraAdapter> adapters) =>
      Future.value(true);

  @override
  Future<String> createConversation(ConversationParams params) =>
      Future.value('mock-conversation-id');

  @override
  Future<String> generateConversationResponse(
    String conversationId,
    CompletionParams params,
  ) => Future.value('Mock conversation response');

  @override
  Future<String> streamConversationResponse(
    String conversationId,
    CompletionParams params,
    Function(String) onToken,
  ) => Future.value('Mock streamed conversation response');

  @override
  Future<List<Map<String, dynamic>>> getConversationHistory(
    String conversationId,
  ) {
    return Future.value([
      {'role': 'user', 'content': 'Hello'},
      {'role': 'assistant', 'content': 'Hi there!'},
    ]);
  }

  @override
  Future<void> clearConversation(String conversationId) => Future.value();

  @override
  Future<bool> downloadModel(
    DownloadParams params,
    Function(double) onProgress,
  ) => Future.value(true);

  @override
  Future<String> getVersion() => Future.value('1.0.0');
}

void main() {
  final LlamaMobileFlutterSdkPlatform initialPlatform =
      LlamaMobileFlutterSdkPlatform.instance;

  test('$MethodChannelLlamaMobileFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLlamaMobileFlutterSdk>());
  });

  test('getPlatformVersion', () async {
    LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin = LlamaMobileFlutterSdk();
    MockLlamaMobileFlutterSdkPlatform fakePlatform =
        MockLlamaMobileFlutterSdkPlatform();
    LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

    expect(await llamaMobileFlutterSdkPlugin.getPlatformVersion(), '42');
  });

  group('Completion Tests', () {
    test('generateResponse', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.generateResponse(
        CompletionParams(prompt: 'Hello'),
      );
      expect(result.text, 'Mock completion');
      expect(result.tokensGenerated, 10);
      expect(result.stoppedEos, true);
    });

    test('streamCompletion', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.streamCompletion(
        CompletionParams(prompt: 'Hello'),
        (token) {},
      );
      expect(result, 'Mock streamed completion');
    });

    test('stopCompletion', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      await llamaMobileFlutterSdkPlugin.stopCompletion();
      // Test passes if no exception is thrown
    });
  });

  group('Tokenization Tests', () {
    test('tokenize', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.tokenize('Hello');
      expect(result, [1, 2, 3, 4, 5]);
    });

    test('detokenize', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.detokenize([1, 2, 3]);
      expect(result, 'Mock detokenized text');
    });
  });

  group('Embeddings Tests', () {
    test('generateEmbeddings', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.generateEmbeddings();
      expect(result, [0.1, 0.2, 0.3]);
    });

    test('generateEmbeddingsForPrompt', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin
          .generateEmbeddingsForPrompt('Hello');
      expect(result, [0.1, 0.2, 0.3]);
    });
  });

  group('Multimodal & TTS Tests', () {
    test('initMultimodal', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.initMultimodal();
      expect(result, true);
    });

    test('initTTS', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.initTTS(
        '/mock/tts/path',
        TTSModelType.outETTSv02,
      );
      expect(result, true);
    });

    test('generateAudio', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.generateAudio(
        TTSParams(text: 'Hello', voice: 'en-US'),
      );
      expect(result, '/mock/audio/path.mp3');
    });
  });

  group('LoRA Tests', () {
    test('applyLoraAdapters', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final adapters = [LoraAdapter(path: '/mock/lora/path', scale: 0.8)];
      final result = await llamaMobileFlutterSdkPlugin.applyLoraAdapters(
        adapters,
      );
      expect(result, true);
    });
  });

  group('Conversation Tests', () {
    test('createConversation', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.createConversation(
        ConversationParams(
          systemPrompt: 'You are a helpful assistant',
          chatTemplate: 'default',
        ),
      );
      expect(result, 'mock-conversation-id');
    });

    test('generateConversationResponse', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin
          .generateConversationResponse(
            'mock-conversation-id',
            CompletionParams(prompt: 'Hello'),
          );
      expect(result, 'Mock conversation response');
    });

    test('streamConversationResponse', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin
          .streamConversationResponse(
            'mock-conversation-id',
            CompletionParams(prompt: 'Hello'),
            (token) {},
          );
      expect(result, 'Mock streamed conversation response');
    });

    test('getConversationHistory', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.getConversationHistory(
        'mock-conversation-id',
      );
      expect(result.length, 2);
      expect(result[0]['role'], 'user');
      expect(result[1]['role'], 'assistant');
    });

    test('clearConversation', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      await llamaMobileFlutterSdkPlugin.clearConversation(
        'mock-conversation-id',
      );
      // Test passes if no exception is thrown
    });
  });

  group('Download Tests', () {
    test('downloadModel', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.downloadModel(
        DownloadParams(
          url: 'https://example.com/model.gguf',
          destinationPath: '/mock/destination',
          expectedSizeMb: 100,
        ),
        (progress) {},
      );
      expect(result, true);
    });
  });

  group('Version Tests', () {
    test('getVersion', () async {
      LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin =
          LlamaMobileFlutterSdk();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final result = await llamaMobileFlutterSdkPlugin.getVersion();
      expect(result, '1.0.0');
    });
  });
}
