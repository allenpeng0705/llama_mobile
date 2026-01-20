import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'llama_mobile_flutter_sdk_method_channel.dart';

abstract class LlamaMobileFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a LlamaMobileFlutterSdkPlatform.
  LlamaMobileFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static LlamaMobileFlutterSdkPlatform _instance = MethodChannelLlamaMobileFlutterSdk();

  /// The default instance of [LlamaMobileFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelLlamaMobileFlutterSdk].
  static LlamaMobileFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LlamaMobileFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(LlamaMobileFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Core initialization methods
  Future<Map<String, dynamic>?> initContext(Map<String, dynamic> params) {
    throw UnimplementedError('initContext() has not been implemented.');
  }

  Future<bool> freeContext(int contextHandle) {
    throw UnimplementedError('freeContext() has not been implemented.');
  }

  // Completion methods
  Future<Map<String, dynamic>?> generateCompletion(int contextHandle, Map<String, dynamic> params) {
    throw UnimplementedError('generateCompletion() has not been implemented.');
  }

  Future<Map<String, dynamic>?> generateMultimodalCompletion(int contextHandle, Map<String, dynamic> params, List<String> mediaPaths) {
    throw UnimplementedError('generateMultimodalCompletion() has not been implemented.');
  }

  // Chat methods
  Future<Map<String, dynamic>?> generateConversation(int contextHandle, Map<String, dynamic> params, List<Map<String, String>> chatMessages) {
    throw UnimplementedError('generateConversation() has not been implemented.');
  }

  Future<String?> formatChatMessages(int contextHandle, List<Map<String, String>> messages, String? chatTemplate) {
    throw UnimplementedError('formatChatMessages() has not been implemented.');
  }

  // TTS methods
  Future<Map<String, dynamic>?> loadTTSModel(int contextHandle, String modelPath, Map<String, dynamic> params) {
    throw UnimplementedError('loadTTSModel() has not been implemented.');
  }

  Future<Map<String, dynamic>?> generateAudio(int contextHandle, String text, Map<String, dynamic> params) {
    throw UnimplementedError('generateAudio() has not been implemented.');
  }

  Future<bool> freeTTSModel(int contextHandle) {
    throw UnimplementedError('freeTTSModel() has not been implemented.');
  }

  // Embedding methods
  Future<List<double>?> generateEmbedding(int contextHandle, String text, Map<String, dynamic> params) {
    throw UnimplementedError('generateEmbedding() has not been implemented.');
  }

  // LoRA methods
  Future<bool> loadLoraAdapter(int contextHandle, String adapterPath, double scale) {
    throw UnimplementedError('loadLoraAdapter() has not been implemented.');
  }

  Future<bool> freeLoraAdapter(int contextHandle) {
    throw UnimplementedError('freeLoraAdapter() has not been implemented.');
  }

  // Utility methods
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> setChatTemplate(int contextHandle, String? template) {
    throw UnimplementedError('setChatTemplate() has not been implemented.');
  }

  Future<String?> loadGrammar(int contextHandle, String grammarName) {
    throw UnimplementedError('loadGrammar() has not been implemented.');
  }

  // Download methods
  Future<Map<String, dynamic>?> downloadModel(Map<String, dynamic> params) {
    throw UnimplementedError('downloadModel() has not been implemented.');
  }
}
