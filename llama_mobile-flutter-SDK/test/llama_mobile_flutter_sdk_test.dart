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
  Future<Map<String, dynamic>?> initContext(Map<String, dynamic> params) async {
    return {'contextHandle': 1, 'success': true};
  }

  @override
  Future<bool> freeContext(int contextHandle) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>?> generateCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    return {
      'text': 'Generated completion text',
      'tokensGenerated': 42,
      'tokensEvaluated': 10,
      'truncated': false,
      'stoppedEos': true,
      'stoppedWord': false,
      'stoppedLimit': false,
      'stoppingWord': null,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateMultimodalCompletion(
    int contextHandle,
    Map<String, dynamic> params,
    List<String> mediaPaths,
  ) async {
    return {
      'text': 'Multimodal completion text',
      'tokensGenerated': 56,
      'tokensEvaluated': 15,
      'truncated': false,
      'stoppedEos': true,
      'stoppedWord': false,
      'stoppedLimit': false,
      'stoppingWord': null,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateConversation(
    int contextHandle,
    Map<String, dynamic> params,
    List<Map<String, String>> chatMessages,
  ) async {
    return {
      'text': 'Conversation response',
      'tokensGenerated': 33,
      'timeToFirstToken': 100,
      'totalTime': 500,
      'messages': chatMessages,
    };
  }

  @override
  Future<String?> formatChatMessages(
    int contextHandle,
    List<Map<String, String>> messages,
    String? chatTemplate,
  ) async {
    return 'Formatted chat messages';
  }

  @override
  Future<Map<String, dynamic>?> loadTTSModel(
    int contextHandle,
    String modelPath,
    Map<String, dynamic> params,
  ) async {
    return {'ttsModelLoaded': true, 'success': true};
  }

  @override
  Future<Map<String, dynamic>?> generateAudio(
    int contextHandle,
    String text,
    Map<String, dynamic> params,
  ) async {
    return {
      'audioData': List<int>.filled(100, 0),
      'sampleRate': 24000,
      'channels': 1,
      'bitDepth': 16,
    };
  }

  @override
  Future<bool> freeTTSModel(int contextHandle) async {
    return true;
  }

  @override
  Future<List<double>?> generateEmbedding(
    int contextHandle,
    String text,
    Map<String, dynamic> params,
  ) async {
    return [0.1, 0.2, 0.3, 0.4, 0.5];
  }

  @override
  Future<bool> loadLoraAdapter(
    int contextHandle,
    String adapterPath,
    double scale,
  ) async {
    return true;
  }

  @override
  Future<bool> freeLoraAdapter(int contextHandle) async {
    return true;
  }

  @override
  Future<String?> loadGrammar(int contextHandle, String grammarName) async {
    return '{grammar content}';
  }

  @override
  Future<bool> setChatTemplate(int contextHandle, String? template) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>?> downloadModel(
    Map<String, dynamic> params,
  ) async {
    return {
      'success': true,
      'localPath': params['localPath'] ?? '',
      'errorMessage': null,
    };
  }
}

void main() {
  final LlamaMobileFlutterSdkPlatform initialPlatform =
      LlamaMobileFlutterSdkPlatform.instance;

  test('$MethodChannelLlamaMobileFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLlamaMobileFlutterSdk>());
  });

  group('Context Management', () {
    test('initContext creates a new context', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/model.gguf',
      );

      expect(context, isNotNull);
      expect(context?.handle, isNotNull);
    });

    test('free releases a context', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/model.gguf',
      );

      bool result = await context?.free() ?? false;
      expect(result, isTrue);
    });
  });

  group('Completion Methods', () {
    test('generateCompletion creates completion text', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/model.gguf',
      );

      CompletionResult? result = await context?.generateCompletion(
        prompt: 'Hello',
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, isNotNull);
    });

    test('generateMultimodalCompletion processes text and images', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/multimodal_model.gguf',
      );

      CompletionResult? result = await context?.generateMultimodalCompletion(
        prompt: 'Describe this image',
        mediaPaths: ['test/image.jpg'],
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, isNotNull);
    });
  });

  group('Conversation Methods', () {
    test('generateConversation creates conversation responses', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      List<ChatMessage> messages = [
        ChatMessage(role: 'user', content: 'Hello'),
      ];

      ConversationResult? result = await context?.generateConversation(
        chatMessages: messages,
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, isNotNull);
    });

    test('formatChatMessages formats messages', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      List<ChatMessage> messages = [
        ChatMessage(role: 'user', content: 'Hello'),
        ChatMessage(role: 'assistant', content: 'Hi there!'),
      ];

      String? formatted = await context?.formatChatMessages(messages, null);

      expect(formatted, isNotNull);
    });
  });

  group('Embedding Methods', () {
    test('generateEmbedding creates embeddings', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/embedding_model.gguf',
        embedding: true,
      );

      List<double>? embedding = await context?.generateEmbedding(
        'Text to embed',
      );

      expect(embedding, isNotNull);
      expect(embedding?.length, greaterThan(0));
    });
  });

  group('LoRA Adapter Methods', () {
    test('loadLoraAdapter loads a LoRA adapter', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/base_model.gguf',
      );

      bool? result = await context?.loadLoraAdapter(
        'test/lora_adapter.gguf',
        0.75,
      );

      expect(result, isTrue);
    });

    test('freeLoraAdapter frees a LoRA adapter', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/base_model.gguf',
      );

      await context?.loadLoraAdapter('test/lora_adapter.gguf', 0.75);

      bool? result = await context?.freeLoraAdapter();

      expect(result, isTrue);
    });
  });

  group('TTS Methods', () {
    test('loadTTSModel loads a TTS model', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool? result = await context?.loadTTSModel(
        'test/tts_model.gguf',
        TTSModelType.outETTSv02,
      );

      expect(result, isTrue);
    });

    test('generateAudio creates audio from text', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.loadTTSModel(
        'test/tts_model.gguf',
        TTSModelType.outETTSv02,
      );

      AudioResult? result = await context?.generateAudio(
        'Hello, this is a test.',
      );

      expect(result, isNotNull);
      expect(result?.audioData, isNotNull);
      expect(result?.audioData?.length, greaterThan(0));
      expect(result?.sampleRate, isNotNull);
      expect(result?.channels, isNotNull);
      expect(result?.bitDepth, isNotNull);
    });

    test('freeTTSModel frees a TTS model', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.loadTTSModel(
        'test/tts_model.gguf',
        TTSModelType.outETTSv02,
      );

      bool? result = await context?.freeTTSModel();

      expect(result, isTrue);
    });
  });

  group('Download Methods', () {
    test('downloadModel downloads model file', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      DownloadResult? result = await llamaMobile.downloadModel(
        url: 'https://example.com/model.gguf',
        localPath: '/tmp/model.gguf',
      );

      expect(result, isNotNull);
      expect(result?.success, isTrue);
      expect(result?.localPath, isNotNull);
      expect(result?.errorMessage, isNull);
    });
  });
}
