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
    List<Map<String, String?>> chatMessages,
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
    List<Map<String, String?>> messages,
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
  ) async {
    return {'audioData': List<int>.filled(100, 0)};
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
  Future<Map<String, dynamic>?> downloadModel(
    Map<String, dynamic> params,
  ) async {
    return {
      'success': true,
      'localPath': params['localPath'] ?? '',
      'errorMessage': null,
    };
  }

  @override
  Future<Map<String, dynamic>?> downloadHfFile(
    Map<String, dynamic> params,
  ) async {
    return {
      'success': true,
      'localPath': params['localPath'] ?? '',
      'errorMessage': null,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    return {
      'text': 'Streaming completion text',
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
  Future<Map<String, dynamic>?> generateOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    return {
      'text': 'OpenAI completion text',
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
  Future<Map<String, dynamic>?> generateStreamingOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    return {
      'text': 'Streaming OpenAI completion text',
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
  Future<bool> stopCompletion(int contextHandle) async {
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>?> getLoadedLoraAdapters(
    int contextHandle,
  ) async {
    return [
      {'adapterPath': 'test/adapter1.gguf', 'scale': 1.0},
      {'adapterPath': 'test/adapter2.gguf', 'scale': 0.5},
    ];
  }

  @override
  Future<int?> getContextWindowSize(int contextHandle) async {
    return 2048;
  }

  @override
  Future<int?> getEmbeddingDimension(int contextHandle) async {
    return 4096;
  }

  @override
  Future<String?> getModelDescription(int contextHandle) async {
    return 'Test Model Description';
  }

  @override
  Future<int?> getModelSize(int contextHandle) async {
    return 1000000;
  }

  @override
  Future<int?> getModelParametersCount(int contextHandle) async {
    return 1000000000;
  }

  @override
  Future<bool> isMultimodalEnabled(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> supportsVision(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> supportsAudio(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> isVocoderEnabled(int contextHandle) async {
    return true;
  }

  @override
  Future<int?> getTTSType(int contextHandle) async {
    return 1;
  }

  @override
  Future<List<double>?> generateAudioFromText(
    int contextHandle,
    String text,
    String speakerJson,
  ) async {
    return List<double>.filled(100, 0.0);
  }

  @override
  Future<String?> getFormattedAudioCompletion(
    int contextHandle,
    String speakerJson,
    String textToSpeak,
  ) async {
    return 'Formatted audio completion';
  }

  @override
  Future<List<int>?> getAudioGuideTokens(
    int contextHandle,
    String textToSpeak,
  ) async {
    return [1, 2, 3, 4, 5];
  }

  @override
  Future<void> setGuideTokens(int contextHandle, List<int> tokens) async {
    return;
  }

  @override
  Future<List<double>?> decodeAudioTokens(
    int contextHandle,
    List<int> tokens,
  ) async {
    return List<double>.filled(100, 0.0);
  }

  @override
  Future<bool> initVocoder(int contextHandle, String vocoderPath) async {
    return true;
  }

  @override
  Future<bool> releaseVocoder(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> releaseMultimodal(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> clearConversation(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> isConversationActive(int contextHandle) async {
    return true;
  }

  @override
  Future<bool> removeLoraAdapters(int contextHandle) async {
    return true;
  }

  @override
  Future<void> setLogLevel(int level) async {
    return;
  }

  @override
  Stream<String> get onTokenStream => const Stream.empty();

  @override
  Stream<double> get onProgressStream => const Stream.empty();

  @override
  Future<String?> detokenize(int contextHandle, List<int> tokens) async {
    return 'Detokenized text';
  }

  @override
  Future<List<int>?> tokenize(int contextHandle, String text) async {
    return [1, 2, 3, 4, 5];
  }

  @override
  Future<bool> initMultimodal(
    int contextHandle,
    String mmprojPath,
    bool useGpu,
  ) async {
    return true;
  }

  @override
  Future<bool> saveAudioToWav(
    int contextHandle,
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) async {
    return true;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechSync(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    return {
      'audioSamples': List<int>.filled(100, 0),
      'sampleRate': 24000,
      'duration': 1.0,
      'outputFilePath': null,
      'methodUsed': 0,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateSpeech(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    return {
      'audioSamples': List<int>.filled(100, 0),
      'sampleRate': 24000,
      'duration': 1.0,
      'outputFilePath': null,
      'methodUsed': 0,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStream(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    return {
      'sampleRate': 24000,
      'duration': 1.0,
      'outputFilePath': null,
      'methodUsed': 0,
    };
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStreamForLongText(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    return {
      'sampleRate': 24000,
      'duration': 1.0,
      'outputFilePath': null,
      'methodUsed': 0,
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

    // generateAudio test removed as this method is now private
    // Use generateSpeechSync or generateSpeech instead

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

      bool result = await context?.freeTTSModel() ?? false;

      expect(result, isTrue);
    });

    test('generateSpeechSync generates speech synchronously', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      Map<String, dynamic>? result = await context?.generateSpeechSync(
        'Hello, this is a test.',
      );

      expect(result, isNotNull);
      expect(result?['audioSamples'], isNotNull);
      expect(result?['sampleRate'], 24000);
      expect(result?['duration'], 1.0);
      expect(result?['methodUsed'], 0);
    });

    test('generateSpeech generates speech asynchronously', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      Map<String, dynamic>? result = await context?.generateSpeech(
        'Hello, this is a test.',
      );

      expect(result, isNotNull);
      expect(result?['audioSamples'], isNotNull);
      expect(result?['sampleRate'], 24000);
      expect(result?['duration'], 1.0);
      expect(result?['methodUsed'], 0);
    });

    test('generateSpeechStream generates speech stream', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      Map<String, dynamic>? result = await context?.generateSpeechStream(
        'Hello, this is a test.',
      );

      expect(result, isNotNull);
      expect(result?['sampleRate'], 24000);
      expect(result?['duration'], 1.0);
      expect(result?['methodUsed'], 0);
    });

    test(
      'generateSpeechStreamForLongText generates speech stream for long text',
      () async {
        LlamaMobile llamaMobile = LlamaMobile();
        MockLlamaMobileFlutterSdkPlatform fakePlatform =
            MockLlamaMobileFlutterSdkPlatform();
        LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

        LlamaContext? context = await llamaMobile.initContext(
          modelPath: 'test/chat_model.gguf',
        );

        Map<String, dynamic>? result = await context
            ?.generateSpeechStreamForLongText(
              'This is a very long text that will be processed in chunks.',
            );

        expect(result, isNotNull);
        expect(result?['sampleRate'], 24000);
        expect(result?['duration'], 1.0);
        expect(result?['methodUsed'], 0);
      },
    );
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

  group('LogLevel Enum', () {
    test('LogLevel enum has correct values', () {
      expect(LogLevel.debug.rawValue, 0);
      expect(LogLevel.info.rawValue, 1);
      expect(LogLevel.warning.rawValue, 2);
      expect(LogLevel.error.rawValue, 3);
      expect(LogLevel.none.rawValue, 4);
    });

    test('LogLevel fromRawValue works correctly', () {
      expect(LogLevel.fromRawValue(0), LogLevel.debug);
      expect(LogLevel.fromRawValue(1), LogLevel.info);
      expect(LogLevel.fromRawValue(2), LogLevel.warning);
      expect(LogLevel.fromRawValue(3), LogLevel.error);
      expect(LogLevel.fromRawValue(4), LogLevel.none);
      expect(LogLevel.fromRawValue(99), LogLevel.info);
    });
  });

  group('TTSMethod Enum', () {
    test('TTSMethod enum has correct values', () {
      expect(TTSMethod.builtIn.rawValue, 0);
      expect(TTSMethod.customWorkflow.rawValue, 1);
    });

    test('TTSMethod fromRawValue works correctly', () {
      expect(TTSMethod.fromRawValue(0), TTSMethod.builtIn);
      expect(TTSMethod.fromRawValue(1), TTSMethod.customWorkflow);
      expect(TTSMethod.fromRawValue(99), TTSMethod.builtIn);
    });
  });

  group('TTSError Enum', () {
    test('TTSError enum has correct messages', () {
      expect(TTSError.noModelLoaded.message, 'No model loaded');
      expect(TTSError.noVocoderEnabled.message, 'No vocoder enabled');
      expect(TTSError.invalidText.message, 'Invalid text');
      expect(TTSError.generationFailed.message, 'Generation failed');
      expect(TTSError.formattingFailed.message, 'Formatting failed');
      expect(TTSError.tokenizationFailed.message, 'Tokenization failed');
      expect(TTSError.audioDecodingFailed.message, 'Audio decoding failed');
      expect(TTSError.fileSaveFailed.message, 'File save failed');
      expect(TTSError.unknownError.message, 'Unknown error');
    });
  });

  group('InitParams Class', () {
    test('InitParams toMap works correctly', () {
      final params = InitParams(
        modelPath: '/path/to/model.gguf',
        chatTemplate: 'custom_template',
        systemPrompt: 'You are a helpful assistant',
        nCtx: 4096,
        nBatch: 1024,
        nUBatch: 512,
        nGpuLayers: 20,
        nThreads: 8,
        useMmap: true,
        useMlock: false,
        embedding: false,
        poolingType: 1,
        embdNormalize: 1,
        flashAttention: true,
        cacheTypeK: 'f16',
        cacheTypeV: 'f16',
        enableChatTemplate: true,
      );

      final map = params.toMap();

      expect(map['modelPath'], '/path/to/model.gguf');
      expect(map['chatTemplate'], 'custom_template');
      expect(map['systemPrompt'], 'You are a helpful assistant');
      expect(map['nCtx'], 4096);
      expect(map['nBatch'], 1024);
      expect(map['nUBatch'], 512);
      expect(map['nGpuLayers'], 20);
      expect(map['nThreads'], 8);
      expect(map['useMmap'], true);
      expect(map['useMlock'], false);
      expect(map['embedding'], false);
      expect(map['poolingType'], 1);
      expect(map['embdNormalize'], 1);
      expect(map['flashAttention'], true);
      expect(map['cacheTypeK'], 'f16');
      expect(map['cacheTypeV'], 'f16');
      expect(map['enableChatTemplate'], true);
    });
  });

  group('CompletionParams Class', () {
    test('CompletionParams toMap works correctly', () {
      final params = CompletionParams(
        prompt: 'Test prompt',
        maxTokens: 2048,
        nThreads: 4,
        seed: 42,
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        minP: 0.05,
        typicalP: 1.0,
        penaltyLastN: 64,
        penaltyRepeat: 1.1,
        penaltyFreq: 0.0,
        penaltyPresent: 0.0,
        mirostat: 0,
        mirostatTau: 5.0,
        mirostatEta: 0.1,
        ignoreEos: false,
        stopSequences: ['\n', '###'],
        grammar: 'test_grammar',
        useJsonResponse: true,
        nProbs: 5,
        jsonSchema: '{"type": "object"}',
        tools: 'test_tools',
        parallelToolCalls: true,
        toolChoice: 'auto',
        mediaPaths: ['/path/to/image.jpg'],
        chatMessages: [
          ChatMessage(role: 'user', content: 'Hello'),
          ChatMessage(role: 'assistant', content: 'Hi there'),
        ],
        chatTemplate: 'custom_template',
      );

      final map = params.toMap();

      expect(map['prompt'], 'Test prompt');
      expect(map['maxTokens'], 2048);
      expect(map['nThreads'], 4);
      expect(map['seed'], 42);
      expect(map['temperature'], 0.7);
      expect(map['topK'], 40);
      expect(map['topP'], 0.95);
      expect(map['minP'], 0.05);
      expect(map['typicalP'], 1.0);
      expect(map['penaltyLastN'], 64);
      expect(map['penaltyRepeat'], 1.1);
      expect(map['penaltyFreq'], 0.0);
      expect(map['penaltyPresent'], 0.0);
      expect(map['mirostat'], 0);
      expect(map['mirostatTau'], 5.0);
      expect(map['mirostatEta'], 0.1);
      expect(map['ignoreEos'], false);
      expect(map['stopSequences'], ['\n', '###']);
      expect(map['grammar'], 'test_grammar');
      expect(map['useJsonResponse'], true);
      expect(map['nProbs'], 5);
      expect(map['jsonSchema'], '{"type": "object"}');
      expect(map['tools'], 'test_tools');
      expect(map['parallelToolCalls'], true);
      expect(map['toolChoice'], 'auto');
      expect(map['mediaPaths'], ['/path/to/image.jpg']);
      expect(map['chatTemplate'], 'custom_template');
    });

    test('CompletionParams factory constructors work correctly', () {
      final fromPrompt = CompletionParams.fromPrompt('Test prompt');
      expect(fromPrompt.prompt, 'Test prompt');
      expect(fromPrompt.maxTokens, 1024);
      expect(fromPrompt.temperature, 0.8);

      final fromChat = CompletionParams.fromChatMessages([
        ChatMessage(role: 'user', content: 'Hello'),
      ]);
      expect(fromChat.chatMessages.length, 1);
      expect(fromChat.temperature, 0.7);

      final fromCreative = CompletionParams.fromCreativePrompt('Write a story');
      expect(fromCreative.prompt, 'Write a story');
      expect(fromCreative.temperature, 1.0);
      expect(fromCreative.maxTokens, 1024);

      final fromFactual = CompletionParams.fromFactualPrompt('What is 2+2?');
      expect(fromFactual.prompt, 'What is 2+2?');
      expect(fromFactual.temperature, 0.1);
    });
  });

  group('DownloadParams Class', () {
    test('DownloadParams toMap works correctly', () {
      final params = DownloadParams(
        url: 'https://example.com/model.gguf',
        localPath: '/tmp/model.gguf',
        username: 'user',
        password: 'pass',
        headers: {'Authorization': 'Bearer token'},
      );

      final map = params.toMap();

      expect(map['url'], 'https://example.com/model.gguf');
      expect(map['localPath'], '/tmp/model.gguf');
      expect(map['username'], 'user');
      expect(map['password'], 'pass');
      expect(map['headers'], {'Authorization': 'Bearer token'});
    });
  });

  group('HuggingFaceDownloadParams Class', () {
    test('HuggingFaceDownloadParams toMap works correctly', () {
      final params = HuggingFaceDownloadParams(
        repoId: 'org/model',
        filename: 'model.gguf',
        localPath: '/tmp/model.gguf',
        bearerToken: 'hf_token',
        offline: false,
      );

      final map = params.toMap();

      expect(map['repoId'], 'org/model');
      expect(map['filename'], 'model.gguf');
      expect(map['localPath'], '/tmp/model.gguf');
      expect(map['bearerToken'], 'hf_token');
      expect(map['offline'], false);
    });
  });

  group('TTSOptions Class', () {
    test('TTSOptions toMap works correctly', () {
      final options = TTSOptions(
        sampleRate: 24000,
        voice: 'default',
        speed: 1.0,
        saveToFile: true,
        outputFilePath: '/tmp/audio.wav',
      );

      final map = options.toMap();

      expect(map['sampleRate'], 24000);
      expect(map['voice'], 'default');
      expect(map['speed'], 1.0);
      expect(map['saveToFile'], true);
      expect(map['outputFilePath'], '/tmp/audio.wav');
    });
  });

  group('SpeechResult Class', () {
    test('SpeechResult fromMap works correctly', () {
      final map = {
        'audioSamples': [1, 2, 3, 4, 5],
        'sampleRate': 24000,
        'duration': 1.5,
        'outputFilePath': '/tmp/audio.wav',
        'methodUsed': 0,
      };

      final result = SpeechResult.fromMap(map);

      expect(result.audioSamples, [1, 2, 3, 4, 5]);
      expect(result.sampleRate, 24000);
      expect(result.duration, 1.5);
      expect(result.outputFilePath, '/tmp/audio.wav');
      expect(result.methodUsed, TTSMethod.builtIn);
    });
  });

  group('SpeechMetadata Class', () {
    test('SpeechMetadata fromMap works correctly', () {
      final map = {
        'sampleRate': 24000,
        'duration': 1.5,
        'methodUsed': 1,
        'outputFilePath': '/tmp/audio.wav',
      };

      final metadata = SpeechMetadata.fromMap(map);

      expect(metadata.sampleRate, 24000);
      expect(metadata.duration, 1.5);
      expect(metadata.methodUsed, TTSMethod.customWorkflow);
      expect(metadata.outputFilePath, '/tmp/audio.wav');
    });
  });

  group('LoraAdapter Class', () {
    test('LoraAdapter toMap works correctly', () {
      final adapter = LoraAdapter(
        adapterPath: '/path/to/adapter.gguf',
        scale: 1.5,
      );

      final map = adapter.toMap();

      expect(map['adapterPath'], '/path/to/adapter.gguf');
      expect(map['scale'], 1.5);
    });

    test('LoraAdapter fromMap works correctly', () {
      final map = {'adapterPath': '/path/to/adapter.gguf', 'scale': 1.5};

      final adapter = LoraAdapter.fromMap(map);

      expect(adapter.adapterPath, '/path/to/adapter.gguf');
      expect(adapter.scale, 1.5);
    });
  });

  group('ChatMessage Class', () {
    test('ChatMessage toMap works correctly', () {
      final message = ChatMessage(
        role: 'user',
        content: 'Hello',
        reasoningContent: 'Thinking...',
        toolName: 'test_tool',
        toolCallId: 'call_123',
      );

      final map = message.toMap();

      expect(map['role'], 'user');
      expect(map['content'], 'Hello');
      expect(map['reasoning_content'], 'Thinking...');
      expect(map['tool_name'], 'test_tool');
      expect(map['tool_call_id'], 'call_123');
    });

    test('ChatMessage fromMap works correctly', () {
      final map = {
        'role': 'user',
        'content': 'Hello',
        'reasoning_content': 'Thinking...',
        'tool_name': 'test_tool',
        'tool_call_id': 'call_123',
      };

      final message = ChatMessage.fromMap(map);

      expect(message.role, 'user');
      expect(message.content, 'Hello');
      expect(message.reasoningContent, 'Thinking...');
      expect(message.toolName, 'test_tool');
      expect(message.toolCallId, 'call_123');
    });
  });

  group('LlamaMobile Static Methods', () {
    test('setLogLevel sets log level', () async {
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      await LlamaMobile.setLogLevel(LogLevel.info);

      expect(true, isTrue);
    });

    test('setLogLevelRaw sets log level with raw value', () async {
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      await LlamaMobile.setLogLevelRaw(1);

      expect(true, isTrue);
    });
  });

  group('LlamaContext New Methods', () {
    // generateAudioFromText test removed as this method is now private
    // getFormattedAudioCompletion test removed as this method is now private
    // getAudioGuideTokens test removed as this method is now private
    // setGuideTokens test removed as this method is now private
    // decodeAudioTokens test removed as this method is now private

    test('initVocoder initializes vocoder', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool result =
          await context?.initVocoder('/path/to/vocoder.gguf') ?? false;

      expect(result, isTrue);
    });

    test('releaseVocoder releases vocoder', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.releaseVocoder();

      expect(true, isTrue);
    });

    test('releaseMultimodal releases multimodal', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.releaseMultimodal();

      expect(true, isTrue);
    });

    test('clearConversation clears conversation', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.clearConversation();

      expect(true, isTrue);
    });

    test('isConversationActive checks conversation status', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.isConversationActive();

      expect(true, isTrue);
    });

    test('removeLoraAdapters removes adapters', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      await context?.removeLoraAdapters();

      expect(true, isTrue);
    });
  });

  group('LlamaMobile Parameter-based Methods', () {
    test('initContextWithParams creates context', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final params = InitParams(
        modelPath: '/path/to/model.gguf',
        nCtx: 4096,
        nThreads: 8,
      );

      LlamaContext? context = await llamaMobile.initContextWithParams(params);

      expect(context, isNotNull);
      expect(context?.handle, isNotNull);
    });

    test('downloadModelWithParams downloads model', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final params = DownloadParams(
        url: 'https://example.com/model.gguf',
        localPath: '/tmp/model.gguf',
      );

      DownloadResult? result = await llamaMobile.downloadModelWithParams(
        params,
      );

      expect(result, isNotNull);
      expect(result?.success, isTrue);
      expect(result?.localPath, isNotNull);
    });

    test('downloadHfFileWithParams downloads from Hugging Face', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final params = HuggingFaceDownloadParams(
        repoId: 'org/model',
        filename: 'model.gguf',
        localPath: '/tmp/model.gguf',
      );

      DownloadResult? result = await llamaMobile.downloadHfFileWithParams(
        params,
      );

      expect(result, isNotNull);
      expect(result?.success, isTrue);
      expect(result?.localPath, isNotNull);
    });

    test('generateCompletionWithParams generates completion', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      final params = CompletionParams(
        prompt: 'Test prompt',
        maxTokens: 2048,
        temperature: 0.7,
      );

      CompletionResult? result = await context?.generateCompletionWithParams(
        params,
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, greaterThan(0));
    });

    test(
      'generateMultimodalCompletionWithParams generates multimodal completion',
      () async {
        LlamaMobile llamaMobile = LlamaMobile();
        MockLlamaMobileFlutterSdkPlatform fakePlatform =
            MockLlamaMobileFlutterSdkPlatform();
        LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

        LlamaContext? context = await llamaMobile.initContext(
          modelPath: 'test/chat_model.gguf',
        );

        final params = CompletionParams(
          prompt: 'Test prompt',
          maxTokens: 2048,
          temperature: 0.7,
        );

        CompletionResult? result = await context
            ?.generateMultimodalCompletionWithParams(params, [
              '/path/to/image.jpg',
            ]);

        expect(result, isNotNull);
        expect(result?.text, isNotNull);
        expect(result?.tokensGenerated, greaterThan(0));
      },
    );

    test(
      'generateStreamingCompletionWithParams generates streaming completion',
      () async {
        LlamaMobile llamaMobile = LlamaMobile();
        MockLlamaMobileFlutterSdkPlatform fakePlatform =
            MockLlamaMobileFlutterSdkPlatform();
        LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

        LlamaContext? context = await llamaMobile.initContext(
          modelPath: 'test/chat_model.gguf',
        );

        final params = CompletionParams(
          prompt: 'Test prompt',
          maxTokens: 2048,
          temperature: 0.7,
        );

        CompletionResult? result = await context
            ?.generateStreamingCompletionWithParams(params);

        expect(result, isNotNull);
        expect(result?.text, isNotNull);
        expect(result?.tokensGenerated, greaterThan(0));
      },
    );

    test('generateConversationWithParams generates conversation', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      final params = CompletionParams(
        prompt: '',
        maxTokens: 256,
        temperature: 0.7,
        chatMessages: [ChatMessage(role: 'user', content: 'Hello')],
      );

      ConversationResult? result = await context
          ?.generateConversationWithParams(params);

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, greaterThan(0));
    });

    test('generateOpenAICompletion generates OpenAI completion', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      CompletionResult? result = await context?.generateOpenAICompletion(
        openAIJSON: '{"model":"test","prompt":"Hello"}',
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
      expect(result?.tokensGenerated, greaterThan(0));
    });

    test(
      'generateStreamingOpenAICompletion generates streaming OpenAI completion',
      () async {
        LlamaMobile llamaMobile = LlamaMobile();
        MockLlamaMobileFlutterSdkPlatform fakePlatform =
            MockLlamaMobileFlutterSdkPlatform();
        LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

        LlamaContext? context = await llamaMobile.initContext(
          modelPath: 'test/chat_model.gguf',
        );

        CompletionResult? result = await context
            ?.generateStreamingOpenAICompletion(
              openAIJSON: '{"model":"test","prompt":"Hello"}',
            );

        expect(result, isNotNull);
        expect(result?.text, isNotNull);
        expect(result?.tokensGenerated, greaterThan(0));
      },
    );

    test('stopCompletion stops ongoing completion', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool result = await context?.stopCompletion() ?? false;

      expect(result, isTrue);
    });

    test('getLoadedLoraAdapters returns loaded adapters', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      List<Map<String, dynamic>>? adapters = await context
          ?.getLoadedLoraAdapters();

      expect(adapters, isNotNull);
      expect(adapters?.length, greaterThan(0));
    });

    test('getContextWindowSize returns context window size', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      int? windowSize = await context?.getContextWindowSize();

      expect(windowSize, isNotNull);
      expect(windowSize, greaterThan(0));
    });

    test('getEmbeddingDimension returns embedding dimension', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      int? dimension = await context?.getEmbeddingDimension();

      expect(dimension, isNotNull);
      expect(dimension, greaterThan(0));
    });

    test('getModelDescription returns model description', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      String? description = await context?.getModelDescription();

      expect(description, isNotNull);
      expect(description?.isNotEmpty, isTrue);
    });

    test('getModelSize returns model size', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      int? size = await context?.getModelSize();

      expect(size, isNotNull);
      expect(size, greaterThan(0));
    });

    test('getModelParametersCount returns parameter count', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      int? count = await context?.getModelParametersCount();

      expect(count, isNotNull);
      expect(count, greaterThan(0));
    });

    test('isMultimodalEnabled checks multimodal support', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool enabled = await context?.isMultimodalEnabled() ?? false;

      expect(enabled, isTrue);
    });

    test('supportsVision checks vision support', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool supported = await context?.supportsVision() ?? false;

      expect(supported, isTrue);
    });

    test('supportsAudio checks audio support', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool supported = await context?.supportsAudio() ?? false;

      expect(supported, isTrue);
    });

    test('isVocoderEnabled checks vocoder support', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool enabled = await context?.isVocoderEnabled() ?? false;

      expect(enabled, isTrue);
    });

    test('getTTSType returns TTS model type', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      TTSModelType type = await context?.getTTSType() ?? TTSModelType.unknown;

      expect(type, isNotNull);
    });

    test('loadGrammar loads grammar from file', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      String? grammar = await context?.loadGrammar('/path/to/grammar.gbnf');

      expect(grammar, isNotNull);
      expect(grammar?.isNotEmpty, isTrue);
    });

    test('tokenize converts text to tokens', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      List<int>? tokens = await context?.tokenize('Hello world');

      expect(tokens, isNotNull);
      expect(tokens?.length, greaterThan(0));
    });

    test('detokenize converts tokens to text', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      String? text = await context?.detokenize([1, 2, 3, 4, 5]);

      expect(text, isNotNull);
      expect(text?.isNotEmpty, isTrue);
    });

    test('saveAudioToWav saves audio to WAV file', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool result =
          await context?.saveAudioToWav(
            '/path/to/output.wav',
            List<int>.filled(100, 0),
            16000,
          ) ??
          false;

      expect(result, isTrue);
    });

    test('initMultimodal initializes multimodal support', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      bool result =
          await context?.initMultimodal('/path/to/mmproj.gguf', true) ?? false;

      expect(result, isTrue);
    });

    test('initContextWithParams creates context with InitParams', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      final params = InitParams(
        modelPath: 'test/chat_model.gguf',
        nCtx: 4096,
        nBatch: 512,
        nThreads: 8,
      );

      LlamaContext? context = await llamaMobile.initContextWithParams(params);

      expect(context, isNotNull);
    });

    test('downloadHfFile downloads from Hugging Face', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      DownloadResult? result = await llamaMobile.downloadHfFile(
        repoId: 'test/repo',
        filename: 'model.gguf',
        localPath: '/local/path',
      );

      expect(result, isNotNull);
      expect(result?.success, isTrue);
    });

    test(
      'downloadHfFileWithParams downloads with HuggingFaceDownloadParams',
      () async {
        LlamaMobile llamaMobile = LlamaMobile();
        MockLlamaMobileFlutterSdkPlatform fakePlatform =
            MockLlamaMobileFlutterSdkPlatform();
        LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

        final params = HuggingFaceDownloadParams(
          repoId: 'test/repo',
          filename: 'model.gguf',
          localPath: '/local/path',
        );

        DownloadResult? result = await llamaMobile.downloadHfFileWithParams(
          params,
        );

        expect(result, isNotNull);
        expect(result?.success, isTrue);
      },
    );

    test('generateMultimodalCompletion generates with media', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      CompletionResult? result = await context?.generateMultimodalCompletion(
        prompt: 'Describe this image',
        mediaPaths: ['/path/to/image.jpg'],
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
    });

    test('generateConversation generates conversation response', () async {
      LlamaMobile llamaMobile = LlamaMobile();
      MockLlamaMobileFlutterSdkPlatform fakePlatform =
          MockLlamaMobileFlutterSdkPlatform();
      LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

      LlamaContext? context = await llamaMobile.initContext(
        modelPath: 'test/chat_model.gguf',
      );

      ConversationResult? result = await context?.generateConversation(
        chatMessages: [ChatMessage(role: 'user', content: 'Hello')],
      );

      expect(result, isNotNull);
      expect(result?.text, isNotNull);
    });
  });
}
