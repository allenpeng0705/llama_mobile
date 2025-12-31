import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'llama_mobile_flutter_sdk_method_channel.dart';

/// Data class for model configuration
class ModelConfig {
  final String modelPath;
  final int contextSize;
  final bool useMemoryCache;
  final String inferenceEngine;

  ModelConfig({
    required this.modelPath,
    this.contextSize = 1024,
    this.useMemoryCache = true,
    this.inferenceEngine = 'llama.cpp',
  });

  Map<String, dynamic> toJson() => {
        'modelPath': modelPath,
        'contextSize': contextSize,
        'useMemoryCache': useMemoryCache,
        'inferenceEngine': inferenceEngine,
      };
}

/// Data class for generation configuration
class GenerationConfig {
  final String prompt;
  final double temperature;
  final int maxTokens;

  GenerationConfig({
    required this.prompt,
    this.temperature = 0.8,
    this.maxTokens = 100,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'temperature': temperature,
        'maxTokens': maxTokens,
      };
}

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<bool> loadModel(ModelConfig config) {
    throw UnimplementedError('loadModel() has not been implemented.');
  }

  Future<String> generateCompletion(GenerationConfig config) {
    throw UnimplementedError('generateCompletion() has not been implemented.');
  }

  Future<void> release() {
    throw UnimplementedError('release() has not been implemented.');
  }
}
