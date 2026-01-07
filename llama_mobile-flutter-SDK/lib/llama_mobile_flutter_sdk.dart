
import 'llama_mobile_flutter_sdk_platform_interface.dart';

class LlamaMobileFlutterSdk {
  /// Returns the platform version.
  Future<String?> getPlatformVersion() {
    return LlamaMobileFlutterSdkPlatform.instance.getPlatformVersion();
  }

  /// Legacy method for backward compatibility
  Future<bool> loadModel(ModelConfig config) {
    return LlamaMobileFlutterSdkPlatform.instance.loadModel(config);
  }

  /// Initialize the model with the specified parameters
  Future<bool> initialize(InitParams params) {
    return LlamaMobileFlutterSdkPlatform.instance.initialize(params);
  }

  /// Legacy method for backward compatibility
  Future<String> generateCompletion(GenerationConfig config) {
    return LlamaMobileFlutterSdkPlatform.instance.generateCompletion(config);
  }

  /// Generate text completion with the specified parameters
  Future<String> generate(CompletionParams params) {
    return LlamaMobileFlutterSdkPlatform.instance.generate(params);
  }

  /// Get the content of a built-in grammar
  Future<String?> getGrammarContent(GrammarName grammarName) {
    return LlamaMobileFlutterSdkPlatform.instance.getGrammarContent(grammarName);
  }

  /// Releases the loaded model and frees resources.
  Future<void> release() {
    return LlamaMobileFlutterSdkPlatform.instance.release();
  }
}
