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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<bool> loadModel(ModelConfig config) async {
    final success = await methodChannel.invokeMethod<bool>('loadModel', config.toJson());
    return success ?? false;
  }

  @override
  Future<String> generateCompletion(GenerationConfig config) async {
    final result = await methodChannel.invokeMethod<String>('generateCompletion', config.toJson());
    return result ?? '';
  }

  @override
  Future<void> release() async {
    await methodChannel.invokeMethod<void>('release');
  }
}
