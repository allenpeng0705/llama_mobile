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
  Future<bool> saveAudioToWavAsync(
    int contextHandle,
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) async {
    final result = await methodChannel
        .invokeMethod<bool>('saveAudioToWavAsync', {
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
    print(
      "[DEBUG] Dart: generateEmbedding called - contextHandle: $contextHandle, text: $text, params: $params",
    );

    try {
      print("[DEBUG] Dart: Invoking method channel for generateEmbedding");
      final result = await methodChannel.invokeListMethod<double>(
        'generateEmbedding',
        {'contextHandle': contextHandle, 'text': text, 'params': params},
      );

      print(
        "[DEBUG] Dart: generateEmbedding result received: ${result != null ? 'Success, length: ${result.length}' : 'Null'}",
      );
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateEmbedding: $e");
      rethrow;
    }
  }

  @override
  Future<List<double>?> generateEmbeddingAsync(
    int contextHandle,
    String text,
    Map<String, dynamic> params,
  ) async {
    print(
      "[DEBUG] Dart: generateEmbeddingAsync called - contextHandle: $contextHandle, text: $text, params: $params",
    );

    try {
      print("[DEBUG] Dart: Invoking method channel for generateEmbeddingAsync");
      final result = await methodChannel.invokeListMethod<double>(
        'generateEmbeddingAsync',
        {'contextHandle': contextHandle, 'text': text, 'params': params},
      );

      print(
        "[DEBUG] Dart: generateEmbeddingAsync result received: ${result != null ? 'Success, length: ${result.length}' : 'Null'}",
      );
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateEmbeddingAsync: $e");
      rethrow;
    }
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
    print(
      "[DEBUG] Dart: generateStreamingCompletion called - contextHandle: $contextHandle, params: $params",
    );
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateStreamingCompletion',
        {'contextHandle': contextHandle, 'params': params},
      );
      print("[DEBUG] Dart: generateStreamingCompletion result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateStreamingCompletion: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingCompletionAsync(
    int contextHandle,
    Map<String, dynamic> params,
  ) async {
    print(
      "[DEBUG] Dart: generateStreamingCompletionAsync called - contextHandle: $contextHandle, params: $params",
    );
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateStreamingCompletionAsync',
        {'contextHandle': contextHandle, 'params': params},
      );
      print("[DEBUG] Dart: generateStreamingCompletionAsync result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateStreamingCompletionAsync: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    print(
      "[DEBUG] Dart: generateStreamingOpenAICompletion called - contextHandle: $contextHandle, openAIJSON: $openAIJSON, grammar: $grammar",
    );
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateStreamingOpenAICompletion',
        {
          'contextHandle': contextHandle,
          'openAIJSON': openAIJSON,
          'grammar': grammar,
        },
      );
      print("[DEBUG] Dart: generateStreamingOpenAICompletion result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in generateStreamingOpenAICompletion: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> generateStreamingOpenAICompletionAsync(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) async {
    print(
      "[DEBUG] Dart: generateStreamingOpenAICompletionAsync called - contextHandle: $contextHandle, openAIJSON: $openAIJSON, grammar: $grammar",
    );
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateStreamingOpenAICompletionAsync',
        {
          'contextHandle': contextHandle,
          'openAIJSON': openAIJSON,
          'grammar': grammar,
        },
      );
      print(
        "[DEBUG] Dart: generateStreamingOpenAICompletionAsync result: $result",
      );
      return result;
    } catch (e) {
      print(
        "[DEBUG] Dart: Error in generateStreamingOpenAICompletionAsync: $e",
      );
      rethrow;
    }
  }

  @override
  Future<bool> stopCompletion(int contextHandle) async {
    print(
      "[DEBUG] Dart: stopCompletion called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<bool>('stopCompletion', {
        'contextHandle': contextHandle,
      });
      print("[DEBUG] Dart: stopCompletion result: $result");
      return result ?? false;
    } catch (e) {
      print("[DEBUG] Dart: Error in stopCompletion: $e");
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getLoadedLoraAdapters(
    int contextHandle,
  ) async {
    print(
      "[DEBUG] Dart: getLoadedLoraAdapters called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeListMethod<Map<String, dynamic>>(
        'getLoadedLoraAdapters',
        {'contextHandle': contextHandle},
      );
      print(
        "[DEBUG] Dart: getLoadedLoraAdapters result length: ${result?.length}",
      );
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getLoadedLoraAdapters: $e");
      rethrow;
    }
  }

  @override
  Future<int?> getContextWindowSize(int contextHandle) async {
    print(
      "[DEBUG] Dart: getContextWindowSize called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<int>(
        'getContextWindowSize',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: getContextWindowSize result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getContextWindowSize: $e");
      rethrow;
    }
  }

  @override
  Future<int?> getEmbeddingDimension(int contextHandle) async {
    print(
      "[DEBUG] Dart: getEmbeddingDimension called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<int>(
        'getEmbeddingDimension',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: getEmbeddingDimension result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getEmbeddingDimension: $e");
      rethrow;
    }
  }

  @override
  Future<String?> getModelDescription(int contextHandle) async {
    print(
      "[DEBUG] Dart: getModelDescription called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<String>(
        'getModelDescription',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: getModelDescription result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getModelDescription: $e");
      rethrow;
    }
  }

  @override
  Future<int?> getModelSize(int contextHandle) async {
    print("[DEBUG] Dart: getModelSize called - contextHandle: $contextHandle");
    try {
      final result = await methodChannel.invokeMethod<int>('getModelSize', {
        'contextHandle': contextHandle,
      });
      print("[DEBUG] Dart: getModelSize result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getModelSize: $e");
      rethrow;
    }
  }

  @override
  Future<int?> getModelParametersCount(int contextHandle) async {
    print(
      "[DEBUG] Dart: getModelParametersCount called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<int>(
        'getModelParametersCount',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: getModelParametersCount result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getModelParametersCount: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> downloadHfFile(
    Map<String, dynamic> params,
  ) async {
    print("[DEBUG] Dart: downloadHfFile called - params: $params");
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'downloadHfFile',
        params,
      );
      print("[DEBUG] Dart: downloadHfFile result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in downloadHfFile: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> downloadHfFileAsync(
    Map<String, dynamic> params,
  ) async {
    print("[DEBUG] Dart: downloadHfFileAsync called - params: $params");
    try {
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'downloadHfFileAsync',
        params,
      );
      print("[DEBUG] Dart: downloadHfFileAsync result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in downloadHfFileAsync: $e");
      rethrow;
    }
  }

  @override
  Future<bool> isMultimodalEnabled(int contextHandle) async {
    print(
      "[DEBUG] Dart: isMultimodalEnabled called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'isMultimodalEnabled',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: isMultimodalEnabled result: $result");
      return result ?? false;
    } catch (e) {
      print("[DEBUG] Dart: Error in isMultimodalEnabled: $e");
      rethrow;
    }
  }

  @override
  Future<bool> supportsVision(int contextHandle) async {
    print(
      "[DEBUG] Dart: supportsVision called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<bool>('supportsVision', {
        'contextHandle': contextHandle,
      });
      print("[DEBUG] Dart: supportsVision result: $result");
      return result ?? false;
    } catch (e) {
      print("[DEBUG] Dart: Error in supportsVision: $e");
      rethrow;
    }
  }

  @override
  Future<bool> supportsAudio(int contextHandle) async {
    print("[DEBUG] Dart: supportsAudio called - contextHandle: $contextHandle");
    try {
      final result = await methodChannel.invokeMethod<bool>('supportsAudio', {
        'contextHandle': contextHandle,
      });
      print("[DEBUG] Dart: supportsAudio result: $result");
      return result ?? false;
    } catch (e) {
      print("[DEBUG] Dart: Error in supportsAudio: $e");
      rethrow;
    }
  }

  @override
  Future<bool> isVocoderEnabled(int contextHandle) async {
    print(
      "[DEBUG] Dart: isVocoderEnabled called - contextHandle: $contextHandle",
    );
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'isVocoderEnabled',
        {'contextHandle': contextHandle},
      );
      print("[DEBUG] Dart: isVocoderEnabled result: $result");
      return result ?? false;
    } catch (e) {
      print("[DEBUG] Dart: Error in isVocoderEnabled: $e");
      rethrow;
    }
  }

  @override
  Future<int?> getTTSType(int contextHandle) async {
    print("[DEBUG] Dart: getTTSType called - contextHandle: $contextHandle");
    try {
      final result = await methodChannel.invokeMethod<int>('getTTSType', {
        'contextHandle': contextHandle,
      });
      print("[DEBUG] Dart: getTTSType result: $result");
      return result;
    } catch (e) {
      print("[DEBUG] Dart: Error in getTTSType: $e");
      rethrow;
    }
  }
}
