import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'llama_mobile_flutter_sdk_platform_interface.dart';

/// An implementation of [LlamaMobileFlutterSdkPlatform] that uses method channels.
class MethodChannelLlamaMobileFlutterSdk extends LlamaMobileFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('llama_mobile_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<bool> loadModel(ModelConfig config) async {
    final success = await methodChannel.invokeMethod<bool>(
      'loadModel',
      config.toJson(),
    );
    return success ?? false;
  }

  @override
  Future<bool> initialize(InitParams params) async {
    final success = await methodChannel.invokeMethod<bool>(
      'initialize',
      params.toJson(),
    );
    return success ?? false;
  }

  @override
  Future<String> generateCompletion(GenerationConfig config) async {
    final result = await methodChannel.invokeMethod<String>(
      'generateCompletion',
      config.toJson(),
    );
    return result ?? '';
  }

  @override
  Future<String> generate(CompletionParams params) async {
    final result = await methodChannel.invokeMethod<String>(
      'generate',
      params.toJson(),
    );
    return result ?? '';
  }

  @override
  Future<String?> getGrammarContent(GrammarName grammarName) async {
    final content = await methodChannel.invokeMethod<String>(
      'getGrammarContent',
      {'grammarName': grammarName.name},
    );
    return content;
  }

  @override
  Future<void> release() async {
    await methodChannel.invokeMethod<void>('release');
  }

  @override
  Future<CompletionResult> generateResponse(CompletionParams params) async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'generateResponse',
      params.toJson(),
    );
    if (result == null) {
      throw Exception('Failed to generate response');
    }
    return CompletionResult(
      text: result['text'] as String,
      tokensGenerated: result['tokensGenerated'] as int,
      tokensEvaluated: result['tokensEvaluated'] as int,
      truncated: result['truncated'] as bool,
      stoppedEos: result['stoppedEos'] as bool,
      stoppedWord: result['stoppedWord'] as bool,
      stoppedLimit: result['stoppedLimit'] as bool,
    );
  }

  @override
  Future<String> streamCompletion(
    CompletionParams params,
    Function(String) onToken,
  ) async {
    // Note: Stream handling requires event channels, not method channels
    // This is a placeholder implementation
    final result = await methodChannel.invokeMethod<String>(
      'streamCompletion',
      params.toJson(),
    );
    return result ?? '';
  }

  @override
  Future<void> stopCompletion() async {
    await methodChannel.invokeMethod<void>('stopCompletion');
  }

  @override
  Future<List<int>> tokenize(String text) async {
    final result = await methodChannel.invokeListMethod<int>('tokenize', {
      'text': text,
    });
    return result ?? [];
  }

  @override
  Future<String> detokenize(List<int> tokens) async {
    final result = await methodChannel.invokeMethod<String>('detokenize', {
      'tokens': tokens,
    });
    return result ?? '';
  }

  @override
  Future<List<double>> generateEmbeddings() async {
    final result = await methodChannel.invokeListMethod<double>(
      'generateEmbeddings',
    );
    return result ?? [];
  }

  @override
  Future<List<double>> generateEmbeddingsForPrompt(String prompt) async {
    final result = await methodChannel.invokeListMethod<double>(
      'generateEmbeddingsForPrompt',
      {'prompt': prompt},
    );
    return result ?? [];
  }

  @override
  Future<bool> initMultimodal() async {
    final success = await methodChannel.invokeMethod<bool>('initMultimodal');
    return success ?? false;
  }

  @override
  Future<bool> initTTS(String ttsPath, TTSModelType modelType) async {
    final success = await methodChannel.invokeMethod<bool>('initTTS', {
      'ttsPath': ttsPath,
      'modelType': modelType.index,
    });
    return success ?? false;
  }

  @override
  Future<String> generateAudio(TTSParams params) async {
    final result = await methodChannel.invokeMethod<String>(
      'generateAudio',
      params.toJson(),
    );
    return result ?? '';
  }

  @override
  Future<bool> applyLoraAdapters(List<LoraAdapter> adapters) async {
    final success = await methodChannel.invokeMethod<bool>(
      'applyLoraAdapters',
      {'adapters': adapters.map((adapter) => adapter.toJson()).toList()},
    );
    return success ?? false;
  }

  @override
  Future<String> createConversation(ConversationParams params) async {
    final result = await methodChannel.invokeMethod<String>(
      'createConversation',
      params.toJson(),
    );
    return result ?? '';
  }

  @override
  Future<String> generateConversationResponse(
    String conversationId,
    CompletionParams params,
  ) async {
    final result = await methodChannel.invokeMethod<String>(
      'generateConversationResponse',
      {'conversationId': conversationId, 'params': params.toJson()},
    );
    return result ?? '';
  }

  @override
  Future<String> streamConversationResponse(
    String conversationId,
    CompletionParams params,
    Function(String) onToken,
  ) async {
    // Note: Stream handling requires event channels, not method channels
    // This is a placeholder implementation
    final result = await methodChannel.invokeMethod<String>(
      'streamConversationResponse',
      {'conversationId': conversationId, 'params': params.toJson()},
    );
    return result ?? '';
  }

  @override
  Future<List<Map<String, dynamic>>> getConversationHistory(
    String conversationId,
  ) async {
    final result = await methodChannel.invokeListMethod<Map<String, dynamic>>(
      'getConversationHistory',
      {'conversationId': conversationId},
    );
    return result ?? [];
  }

  @override
  Future<void> clearConversation(String conversationId) async {
    await methodChannel.invokeMethod<void>('clearConversation', {
      'conversationId': conversationId,
    });
  }

  @override
  Future<bool> downloadModel(
    DownloadParams params,
    Function(double) onProgress,
  ) async {
    // Note: Progress callbacks require event channels, not method channels
    // This is a placeholder implementation
    final success = await methodChannel.invokeMethod<bool>(
      'downloadModel',
      params.toJson(),
    );
    return success ?? false;
  }

  @override
  Future<String> getVersion() async {
    final version = await methodChannel.invokeMethod<String>('getVersion');
    return version ?? '';
  }
}
