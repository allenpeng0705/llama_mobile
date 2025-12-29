
import 'llama_mobile_flutter_sdk_platform_interface.dart';

class LlamaMobileFlutterSdk {
  /// Returns the platform version.
  Future<String?> getPlatformVersion() {
    return LlamaMobileFlutterSdkPlatform.instance.getPlatformVersion();
  }

  /// Loads a model with the specified configuration.
  Future<bool> loadModel(ModelConfig config) {
    return LlamaMobileFlutterSdkPlatform.instance.loadModel(config);
  }

  /// Generates text completion based on the given prompt and configuration.
  Future<String> generateCompletion(GenerationConfig config) {
    return LlamaMobileFlutterSdkPlatform.instance.generateCompletion(config);
  }

  /// Releases the loaded model and frees resources.
  Future<void> release() {
    return LlamaMobileFlutterSdkPlatform.instance.release();
  }
}
