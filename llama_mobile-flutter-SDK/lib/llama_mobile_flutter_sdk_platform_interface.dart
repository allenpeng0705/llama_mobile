import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'llama_mobile_flutter_sdk_method_channel.dart';

abstract class LlamaMobileFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a LlamaMobileFlutterSdkPlatform.
  LlamaMobileFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static LlamaMobileFlutterSdkPlatform _instance =
      MethodChannelLlamaMobileFlutterSdk();

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

  // Static methods
  Future<void> setLogLevel(int level) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  // Core initialization methods
  Future<Map<String, dynamic>?> initContext(Map<String, dynamic> params) {
    throw UnimplementedError('initContext() has not been implemented.');
  }

  Future<bool> freeContext(int contextHandle) {
    throw UnimplementedError('freeContext() has not been implemented.');
  }

  // Completion methods
  Future<Map<String, dynamic>?> generateCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) {
    throw UnimplementedError('generateCompletion() has not been implemented.');
  }

  Future<Map<String, dynamic>?> generateMultimodalCompletion(
    int contextHandle,
    Map<String, dynamic> params,
    List<String> mediaPaths,
  ) {
    throw UnimplementedError(
      'generateMultimodalCompletion() has not been implemented.',
    );
  }

  // Chat methods
  Future<Map<String, dynamic>?> generateConversation(
    int contextHandle,
    Map<String, dynamic> params,
    List<Map<String, String?>> chatMessages,
  ) {
    throw UnimplementedError(
      'generateConversation() has not been implemented.',
    );
  }

  Future<String?> formatChatMessages(
    int contextHandle,
    List<Map<String, String?>> messages,
    String? chatTemplate,
  ) {
    throw UnimplementedError('formatChatMessages() has not been implemented.');
  }

  // TTS methods
  Future<Map<String, dynamic>?> loadTTSModel(
    int contextHandle,
    String modelPath,
    Map<String, dynamic> params,
  ) {
    throw UnimplementedError('loadTTSModel() has not been implemented.');
  }

  Future<Map<String, dynamic>?> generateAudio(int contextHandle, String text) {
    throw UnimplementedError('generateAudio() has not been implemented.');
  }

  Future<bool> freeTTSModel(int contextHandle) {
    throw UnimplementedError('freeTTSModel() has not been implemented.');
  }

  /// Save audio samples to WAV file
  Future<bool> saveAudioToWav(
    int contextHandle,
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) {
    throw UnimplementedError('saveAudioToWav() has not been implemented.');
  }

  // Multimodal methods
  Future<bool> initMultimodal(
    int contextHandle,
    String mmprojPath,
    bool useGpu,
  ) {
    throw UnimplementedError('initMultimodal() has not been implemented.');
  }

  Future<void> releaseMultimodal(int contextHandle) {
    throw UnimplementedError('releaseMultimodal() has not been implemented.');
  }

  // Vocoder methods
  Future<bool> initVocoder(int contextHandle, String vocoderModelPath) {
    throw UnimplementedError('initVocoder() has not been implemented.');
  }

  Future<void> releaseVocoder(int contextHandle) {
    throw UnimplementedError('releaseVocoder() has not been implemented.');
  }

  // Embedding methods
  /// Generate embedding for text
  Future<List<double>?> generateEmbedding(
    int contextHandle,
    String text,
    Map<String, dynamic> params,
  ) {
    throw UnimplementedError('generateEmbedding() has not been implemented.');
  }

  /// Tokenize text into token IDs
  Future<List<int>?> tokenize(int contextHandle, String text) {
    throw UnimplementedError('tokenize() has not been implemented.');
  }

  /// Detokenize token IDs back to text
  Future<String?> detokenize(int contextHandle, List<int> tokens) {
    throw UnimplementedError('detokenize() has not been implemented.');
  }

  // Conversation methods
  Future<void> clearConversation(int contextHandle) {
    throw UnimplementedError('clearConversation() has not been implemented.');
  }

  Future<bool> isConversationActive(int contextHandle) {
    throw UnimplementedError(
      'isConversationActive() has not been implemented.',
    );
  }

  // LoRA methods
  Future<bool> loadLoraAdapter(
    int contextHandle,
    String adapterPath,
    double scale,
  ) {
    throw UnimplementedError('loadLoraAdapter() has not been implemented.');
  }

  Future<bool> freeLoraAdapter(int contextHandle) {
    throw UnimplementedError('freeLoraAdapter() has not been implemented.');
  }

  Future<void> removeLoraAdapters(int contextHandle) {
    throw UnimplementedError('removeLoraAdapters() has not been implemented.');
  }

  // TTS methods
  Future<List<double>?> generateAudioFromText(
    int contextHandle,
    String text,
    String speakerJson,
  ) {
    throw UnimplementedError(
      'generateAudioFromText() has not been implemented.',
    );
  }

  Future<String?> getFormattedAudioCompletion(
    int contextHandle,
    String speakerJson,
    String textToSpeak,
  ) {
    throw UnimplementedError(
      'getFormattedAudioCompletion() has not been implemented.',
    );
  }

  Future<List<int>?> getAudioGuideTokens(
    int contextHandle,
    String textToSpeak,
  ) {
    throw UnimplementedError('getAudioGuideTokens() has not been implemented.');
  }

  Future<void> setGuideTokens(int contextHandle, List<int> tokens) {
    throw UnimplementedError('setGuideTokens() has not been implemented.');
  }

  Future<List<double>?> decodeAudioTokens(int contextHandle, List<int> tokens) {
    throw UnimplementedError('decodeAudioTokens() has not been implemented.');
  }

  // Utility methods
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> loadGrammar(int contextHandle, String grammarPath) {
    throw UnimplementedError('loadGrammar() has not been implemented.');
  }

  // Streaming methods
  Stream<String> get onTokenStream {
    throw UnimplementedError('onTokenStream has not been implemented.');
  }

  Stream<double> get onProgressStream {
    throw UnimplementedError('onProgressStream has not been implemented.');
  }

  Future<Map<String, dynamic>?> generateStreamingCompletion(
    int contextHandle,
    Map<String, dynamic> params,
  ) {
    throw UnimplementedError(
      'generateStreamingCompletion() has not been implemented.',
    );
  }

  Future<Map<String, dynamic>?> generateStreamingOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) {
    throw UnimplementedError(
      'generateStreamingOpenAICompletion() has not been implemented.',
    );
  }

  Future<bool> stopCompletion(int contextHandle) {
    throw UnimplementedError('stopCompletion() has not been implemented.');
  }

  // LoRA methods
  Future<List<Map<String, dynamic>>?> getLoadedLoraAdapters(int contextHandle) {
    throw UnimplementedError(
      'getLoadedLoraAdapters() has not been implemented.',
    );
  }

  // Model info methods
  Future<int?> getContextWindowSize(int contextHandle) {
    throw UnimplementedError(
      'getContextWindowSize() has not been implemented.',
    );
  }

  Future<int?> getEmbeddingDimension(int contextHandle) {
    throw UnimplementedError(
      'getEmbeddingDimension() has not been implemented.',
    );
  }

  Future<String?> getModelDescription(int contextHandle) {
    throw UnimplementedError('getModelDescription() has not been implemented.');
  }

  Future<int?> getModelSize(int contextHandle) {
    throw UnimplementedError('getModelSize() has not been implemented.');
  }

  Future<int?> getModelParametersCount(int contextHandle) {
    throw UnimplementedError(
      'getModelParametersCount() has not been implemented.',
    );
  }

  // Download methods
  Future<Map<String, dynamic>?> downloadModel(Map<String, dynamic> params) {
    throw UnimplementedError('downloadModel() has not been implemented.');
  }

  // Hugging Face download methods
  Future<Map<String, dynamic>?> downloadHfFile(Map<String, dynamic> params) {
    throw UnimplementedError('downloadHfFile() has not been implemented.');
  }

  // OpenAI completion methods
  Future<Map<String, dynamic>?> generateOpenAICompletion(
    int contextHandle,
    String openAIJSON,
    String? grammar,
  ) {
    throw UnimplementedError(
      'generateOpenAICompletion() has not been implemented.',
    );
  }

  // Multimodal methods
  Future<bool> isMultimodalEnabled(int contextHandle) {
    throw UnimplementedError('isMultimodalEnabled() has not been implemented.');
  }

  Future<bool> supportsVision(int contextHandle) {
    throw UnimplementedError('supportsVision() has not been implemented.');
  }

  Future<bool> supportsAudio(int contextHandle) {
    throw UnimplementedError('supportsAudio() has not been implemented.');
  }

  // TTS methods
  Future<bool> isVocoderEnabled(int contextHandle) {
    throw UnimplementedError('isVocoderEnabled() has not been implemented.');
  }

  Future<int?> getTTSType(int contextHandle) {
    throw UnimplementedError('getTTSType() has not been implemented.');
  }
}
