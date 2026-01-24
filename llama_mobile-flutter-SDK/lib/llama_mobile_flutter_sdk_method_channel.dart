import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'llama_mobile_flutter_sdk_platform_interface.dart';

/// An implementation of [LlamaMobileFlutterSdkPlatform] that uses method channels.
class MethodChannelLlamaMobileFlutterSdk extends LlamaMobileFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('llama_mobile_flutter_sdk');

  @override
  Future<Map<String, dynamic>?> initContext(Map<String, dynamic> params) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'initContext',
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
  Future<Map<String, dynamic>?> generateConversation(
    int contextHandle,
    Map<String, dynamic> params,
    List<Map<String, String>> chatMessages,
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
  Future<String?> formatChatMessages(
    int contextHandle,
    List<Map<String, String>> messages,
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
  Future<Map<String, dynamic>?> generateAudio(
    int contextHandle,
    String text,
  ) async {
    print("[DEBUG] Dart: generateAudio called - contextHandle: $contextHandle, text: $text");
    
    try {
      print("[DEBUG] Dart: Invoking method channel for generateAudio");
      final result = await methodChannel.invokeMapMethod<String, dynamic>(
        'generateAudio',
        {'contextHandle': contextHandle, 'text': text},
      );
      
      print("[DEBUG] Dart: generateAudio result received: $result");
      
      if (result != null) {
        print("[DEBUG] Dart: TTS Audio Generated successfully, audioData length: ${result['audioData']?.length}");
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
  Future<bool> freeLoraAdapter(int contextHandle) async {
    final result = await methodChannel.invokeMethod<bool>('freeLoraAdapter', {
      'contextHandle': contextHandle,
    });
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
  Future<bool> setChatTemplate(int contextHandle, String? template) async {
    final result = await methodChannel.invokeMethod<bool>('setChatTemplate', {
      'contextHandle': contextHandle,
      'template': template,
    });
    return result ?? false;
  }

  @override
  Future<String?> loadGrammar(int contextHandle, String grammarName) async {
    final result = await methodChannel.invokeMethod<String>('loadGrammar', {
      'contextHandle': contextHandle,
      'grammarName': grammarName,
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
  Future<Map<String, dynamic>?> downloadModel(
    Map<String, dynamic> params,
  ) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'downloadModel',
      params,
    );
    return result;
  }
}
