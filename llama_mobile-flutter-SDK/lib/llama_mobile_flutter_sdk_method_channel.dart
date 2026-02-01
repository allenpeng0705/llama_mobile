import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'llama_mobile_flutter_sdk_platform_interface.dart';

/// An implementation of [LlamaMobileFlutterSdkPlatform] that uses method channels.
class MethodChannelLlamaMobileFlutterSdk extends LlamaMobileFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('llama_mobile_flutter_sdk');

  /// Event channels for streaming
  @visibleForTesting
  final tokenEventChannel = const EventChannel(
    'llama_mobile_flutter_sdk/token',
  );

  @visibleForTesting
  final progressEventChannel = const EventChannel(
    'llama_mobile_flutter_sdk/progress',
  );

  @override
  Future<void> setLogLevel(int level) async {
    await methodChannel.invokeMethod<void>('setLogLevel', {'level': level});
  }

  @override
  Future<Map<String, dynamic>?> initContext(Map<String, dynamic> params) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'initContext',
      params,
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> initContextAsync(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'initContextAsync',
      params,
    );
    return result;
  }

  @override
  Future<bool> freeContext(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeContext', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> freeContextAsync(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeContextAsync', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>?> generateCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateCompletion',
      {'contextHandle': contextHandle, 'params': params},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateCompletionAsync(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateCompletionAsync',
      {'contextHandle': contextHandle, 'params': params},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateMultimodalCompletion(
    int contextHandle,
    Map<String, dynamic> params,
    List<String> mediaPaths,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateMultimodalCompletion',
      {
        'contextHandle': contextHandle,
        'params': params,
        'mediaPaths': mediaPaths,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateMultimodalCompletionAsync(
    int contextHandle,
    Map<String, dynamic> params,
    List<String> mediaPaths,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateMultimodalCompletionAsync',
      {
        'contextHandle': contextHandle,
        'params': params,
        'mediaPaths': mediaPaths,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateConversation(
    int contextHandle,
    Map<String, dynamic> params,
    List<Map<String, String?>> chatMessages,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateConversation',
      {
        'contextHandle': contextHandle,
        'params': params,
        'chatMessages': chatMessages,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateConversationAsync(
    int contextHandle,
    Map<String, dynamic> params,
    List<Map<String, String?>> chatMessages,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateConversationAsync',
      {
        'contextHandle': contextHandle,
        'params': params,
        'chatMessages': chatMessages,
      },
    );
    return result;
  }

  @override
  Future<String?> formatChatMessages(
    int contextHandle,
    List<Map<String, String?>> messages,
    String? chatTemplate,
  ) async {
    final result = await methodChannel
        .invokeMethod<String>('formatChatMessages', {
          'contextHandle': contextHandle,
          'messages': messages,
          'chatTemplate': chatTemplate,
        });
    return result;
  }

  @override
  Future<String?> formatChatMessagesAsync(
    int contextHandle,
    List<Map<String, String?>> messages,
    String? chatTemplate,
  ) async {
    final result = await methodChannel
        .invokeMethod<String>('formatChatMessagesAsync', {
          'contextHandle': contextHandle,
          'messages': messages,
          'chatTemplate': chatTemplate,
        });
    return result;
  }

  @override
  Future<Map<String, dynamic>?> loadTTSModel(
    int contextHandle,
    String modelPath,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'loadTTSModel',
      {
        'contextHandle': contextHandle,
        'modelPath': modelPath,
        'params': params,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> loadTTSModelAsync(
    int contextHandle,
    String modelPath,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'loadTTSModelAsync',
      {
        'contextHandle': contextHandle,
        'modelPath': modelPath,
        'params': params,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateAudio(
    int contextHandle,
    String text,
  ) async {
    print(
      "[DEBUG] Dart: generateAudio called - contextHandle: $contextHandle, text: $text",
    );

    try {
      print("[DEBUG] Dart: Invoking method channel for generateAudio");
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateAudio',
        {'contextHandle': contextHandle, 'text': text},
      );

      print("[DEBUG] Dart: generateAudio result received: $result");

      if (result != null) {
        print(
          "[DEBUG] Dart: TTS Audio Generated successfully, audioData length: ${result['audioData']?.length}",
        );
      } else {
        print("[DEBUG] Dart: TTS Audio Generated NULL");
      }
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateAudio: $e");
      rethrow;
    }
  }

  @override
  Future<bool> freeTTSModel(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeTTSModel', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> freeTTSModelAsync(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeTTSModelAsync', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> saveAudioToWav(
    int contextHandle,
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('saveAudioToWav', {
      'contextHandle': contextHandle,
      'filePath': filePath,
      'audioData': audioData,
      'sampleRate': sampleRate,
    });
    return result ?? false;
  }

  @override
  Future<bool> initMultimodal(
    int contextHandle,
    String mmprojPath,
    bool useGpu,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('initMultimodal', {
      'contextHandle': contextHandle,
      'mmprojPath': mmprojPath,
      'useGpu': useGpu,
    });
    return result ?? false;
  }

  @override
  Future<bool> initMultimodalAsync(
    int contextHandle,
    String mmprojPath,
    bool useGpu,
  ) async {
    final result = await methodChannel.invokeMethod<bool>(
      'initMultimodalAsync',
      {
        'contextHandle': contextHandle,
        'mmprojPath': mmprojPath,
        'useGpu': useGpu,
      },
    );
    return result ?? false;
  }

  @override
  Future<void> releaseMultimodal(int contextHandle) async {
    await methodChannel.invokeMethod<void>('releaseMultimodal', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<void> releaseMultimodalAsync(int contextHandle) async {
    await methodChannel.invokeMethod<void>('releaseMultimodalAsync', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<bool> initVocoder(int contextHandle, String vocoderModelPath) async {
    final result = await methodChannel.invokeMethod<bool>('initVocoder', {
      'contextHandle': contextHandle,
      'vocoderModelPath': vocoderModelPath,
    });
    return result ?? false;
  }

  @override
  Future<bool> initVocoderAsync(
    int contextHandle,
    String vocoderModelPath,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('initVocoderAsync', {
      'contextHandle': contextHandle,
      'vocoderModelPath': vocoderModelPath,
    });
    return result ?? false;
  }

  @override
  Future<void> releaseVocoder(int contextHandle) async {
    await methodChannel.invokeMethod<void>('releaseVocoder', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<void> releaseVocoderAsync(int contextHandle) async {
    await methodChannel.invokeMethod<void>('releaseVocoderAsync', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<void> clearConversation(int contextHandle) async {
    await methodChannel.invokeMethod<void>('clearConversation', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<bool> isConversationActive(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>(
      'isConversationActive',
      {'contextHandle': contextHandle},
    );
    return result ?? false;
  }

  @override
  Future<void> removeLoraAdapters(int contextHandle) async {
    await methodChannel.invokeMethod<void>('removeLoraAdapters', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<void> removeLoraAdaptersAsync(int contextHandle) async {
    await methodChannel.invokeMethod<void>('removeLoraAdaptersAsync', {
      'contextHandle': contextHandle,
    });
  }

  @override
  Future<List<double>?> generateAudioFromText(
    int contextHandle,
    String text,
    String speakerJson,
  ) async {
    final result = await methodChannel.invokeListMethod<double>(
      'generateAudioFromText',
      {
        'contextHandle': contextHandle,
        'text': text,
        'speakerJson': speakerJson,
      },
    );
    return result;
  }

  @override
  Future<String?> getFormattedAudioCompletion(
    int contextHandle,
    String speakerJson,
    String textToSpeak,
  ) async {
    final result = await methodChannel
        .invokeMethod<String>('getFormattedAudioCompletion', {
          'contextHandle': contextHandle,
          'speakerJson': speakerJson,
          'textToSpeak': textToSpeak,
        });
    return result;
  }

  @override
  Future<List<int>?> getAudioGuideTokens(
    int contextHandle,
    String textToSpeak,
  ) async {
    final result = await methodChannel.invokeListMethod<int>(
      'getAudioGuideTokens',
      {'contextHandle': contextHandle, 'textToSpeak': textToSpeak},
    );
    return result;
  }

  @override
  Future<void> setGuideTokens(int contextHandle, List<int> tokens) async {
    await methodChannel.invokeMethod<void>('setGuideTokens', {
      'contextHandle': contextHandle,
      'tokens': tokens,
    });
  }

  @override
  Future<List<double>?> decodeAudioTokens(
    int contextHandle,
    List<int> tokens,
  ) async {
    final result = await methodChannel.invokeListMethod<double>(
      'decodeAudioTokens',
      {'contextHandle': contextHandle, 'tokens': tokens},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechSync(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechSync',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeech(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeech',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechAsync(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechAsync',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStream(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechStream',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStreamAsync(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechStreamAsync',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStreamForLongText(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechStreamForLongText',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateSpeechStreamForLongTextAsync(
    int contextHandle,
    String text,
    Map<String, dynamic>? options,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateSpeechStreamForLongTextAsync',
      {'contextHandle': contextHandle, 'text': text, 'options': options},
    );
    return result;
  }

  @override
  Future<List<double>?> generateEmbedding(
    int contextHandle,
    String text,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeListMethod<double>(
      'generateEmbedding',
      {'contextHandle': contextHandle, 'text': text, 'params': params},
    );
    return result;
  }

  @override
  Future<List<int>?> tokenize(int contextHandle, String text) async {
    final result = await methodChannel.invokeListMethod<int>('tokenize', {
      'contextHandle': contextHandle,
      'text': text,
    });
    return result;
  }

  @override
  Future<String?> detokenize(int contextHandle, List<int> tokens) async {
    final result = await methodChannel.invokeMethod<String>('detokenize', {
      'contextHandle': contextHandle,
      'tokens': tokens,
    });
    return result;
  }

  @override
  Future<bool> loadLoraAdapter(
    int contextHandle,
    String adapterPath,
    double scale,
  ) async {
    final result = await methodChannel.invokeMethod<bool>('loadLoraAdapter', {
      'contextHandle': contextHandle,
      'adapterPath': adapterPath,
      'scale': scale,
    });
    return result ?? false;
  }

  @override
  Future<bool> loadLoraAdapterAsync(
    int contextHandle,
    String adapterPath,
    double scale,
  ) async {
    final result = await methodChannel.invokeMethod<bool>(
      'loadLoraAdapterAsync',
      {
        'contextHandle': contextHandle,
        'adapterPath': adapterPath,
        'scale': scale,
      },
    );
    return result ?? false;
  }

  @override
  Future<bool> freeLoraAdapter(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeLoraAdapter', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> freeLoraAdapterAsync(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>(
      'freeLoraAdapterAsync',
      {'contextHandle': contextHandle},
    );
    return result ?? false;
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<String?> loadGrammar(int contextHandle, String grammarPath) async {
    final result = await methodChannel.invokeMethod<String>('loadGrammar', {
      'contextHandle': contextHandle,
      'grammarPath': grammarPath,
    });
    return result;
  }

  @override
  Future<String?> loadGrammarAsync(
    int contextHandle,
    String grammarPath,
  ) async {
    final result = await methodChannel.invokeMethod<String>(
      'loadGrammarAsync',
      {'contextHandle': contextHandle, 'grammarPath': grammarPath},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateOpenAICompletion',
      {
        'contextHandle': contextHandle,
        'openAIJSON': openAIJSON,
        'grammar': grammar,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateOpenAICompletionAsync(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateOpenAICompletionAsync',
      {
        'contextHandle': contextHandle,
        'openAIJSON': openAIJSON,
        'grammar': grammar,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> downloadModel(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'downloadModel',
      params,
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> downloadModelAsync(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'downloadModelAsync',
      params,
    );
    return result;
  }

  @override
  Stream<String> get onTokenStream {
    return tokenEventChannel.receiveBroadcastStream().map((event) {
      if (event is String) return event;
      return event.toString();
    });
  }

  @override
  Stream<double> get onProgressStream {
    return progressEventChannel.receiveBroadcastStream().map((event) {
      if (event is double) return event;
      if (event is int) return event.toDouble();
      return 0.0;
    });
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateStreamingCompletion',
      {'contextHandle': contextHandle, 'params': params},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingCompletionAsync(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateStreamingCompletionAsync',
      {'contextHandle': contextHandle, 'params': params},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateStreamingOpenAICompletion',
      {
        'contextHandle': contextHandle,
        'openAIJSON': openAIJSON,
        'grammar': grammar,
      },
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingOpenAICompletionAsync(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateStreamingOpenAICompletionAsync',
      {
        'contextHandle': contextHandle,
        'openAIJSON': openAIJSON,
        'grammar': grammar,
      },
    );
    return result;
  }

  @override
  Future<bool> stopCompletion(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('stopCompletion', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<List<Map<String, dynamic>>?> getLoadedLoraAdapters(
    int contextHandle,
  ) async {
    final result = await methodChannel.invokeListMethod<Map<String, dynamic>>(
      'getLoadedLoraAdapters',
      {'contextHandle': contextHandle},
    );
    return result;
  }

  @override
  Future<int?> getContextWindowSize(int contextHandle) async {
    final result = await methodChannel.invokeMethod<int>(
      'getContextWindowSize',
      {'contextHandle': contextHandle},
    );
    return result;
  }

  @override
  Future<int?> getEmbeddingDimension(int contextHandle) async {
    final result = await methodChannel.invokeMethod<int>(
      'getEmbeddingDimension',
      {'contextHandle': contextHandle},
    );
    return result;
  }

  @override
  Future<String?> getModelDescription(int contextHandle) async {
    final result = await methodChannel.invokeMethod<String>(
      'getModelDescription',
      {'contextHandle': contextHandle},
    );
    return result;
  }

  @override
  Future<int?> getModelSize(int contextHandle) async {
    final result = await methodChannel.invokeMethod<int>('getModelSize', {
      'contextHandle': contextHandle,
    });
    return result;
  }

  @override
  Future<int?> getModelParametersCount(int contextHandle) async {
    final result = await methodChannel.invokeMethod<int>(
      'getModelParametersCount',
      {'contextHandle': contextHandle},
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> downloadHfFile(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'downloadHfFile',
      params,
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>?> downloadHfFileAsync(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'downloadHfFileAsync',
      params,
    );
    return result;
  }

  @override
  Future<bool> isMultimodalEnabled(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>(
      'isMultimodalEnabled',
      {'contextHandle': contextHandle},
    );
    return result ?? false;
  }

  @override
  Future<bool> supportsVision(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('supportsVision', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> supportsAudio(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('supportsAudio', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<bool> isVocoderEnabled(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('isVocoderEnabled', {
      'contextHandle': contextHandle,
    });
    return result ?? false;
  }

  @override
  Future<int?> getTTSType(int contextHandle) async {
    final result = await methodChannel.invokeMethod<int>('getTTSType', {
      'contextHandle': contextHandle,
    });
    return result;
  }
}
