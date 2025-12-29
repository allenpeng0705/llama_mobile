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
  Future<bool> loadModel(ModelConfig config) => Future.value(true);

  @override
  Future<String> generateCompletion(GenerationConfig config) => Future.value('Mock completion');

  @override
  Future<void> release() => Future.value();
}

void main() {
  final LlamaMobileFlutterSdkPlatform initialPlatform = LlamaMobileFlutterSdkPlatform.instance;

  test('$MethodChannelLlamaMobileFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLlamaMobileFlutterSdk>());
  });

  test('getPlatformVersion', () async {
    LlamaMobileFlutterSdk llamaMobileFlutterSdkPlugin = LlamaMobileFlutterSdk();
    MockLlamaMobileFlutterSdkPlatform fakePlatform = MockLlamaMobileFlutterSdkPlatform();
    LlamaMobileFlutterSdkPlatform.instance = fakePlatform;

    expect(await llamaMobileFlutterSdkPlugin.getPlatformVersion(), '42');
  });
}
