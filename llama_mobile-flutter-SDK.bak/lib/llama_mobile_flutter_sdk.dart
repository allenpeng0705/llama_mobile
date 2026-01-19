import 'llama_mobile_flutter_sdk_platform_interface.dart';

export 'llama_mobile_flutter_sdk_platform_interface.dart'
    show
        GrammarName,
        InitParams,
        CompletionParams,
        CompletionResult,
        LoraAdapter,
        TTSParams,
        ConversationParams,
        DownloadParams,
        TTSModelType,
        StopType;

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

  /// Generate text completion and return detailed result
  Future<CompletionResult> generateResponse(CompletionParams params) {
    return LlamaMobileFlutterSdkPlatform.instance.generateResponse(params);
  }

  /// Stream text completion with token callbacks
  Future<String> streamCompletion(
    CompletionParams params,
    Function(String) onToken,
  ) {
    return LlamaMobileFlutterSdkPlatform.instance.streamCompletion(
      params,
      onToken,
    );
  }

  /// Stop an ongoing completion generation
  Future<void> stopCompletion() {
    return LlamaMobileFlutterSdkPlatform.instance.stopCompletion();
  }

  /// Tokenize text into token IDs
  Future<List<int>> tokenize(String text) {
    return LlamaMobileFlutterSdkPlatform.instance.tokenize(text);
  }

  /// Detokenize token IDs into text
  Future<String> detokenize(List<int> tokens) {
    return LlamaMobileFlutterSdkPlatform.instance.detokenize(tokens);
  }

  /// Generate embeddings for the current context
  Future<List<double>> generateEmbeddings() {
    return LlamaMobileFlutterSdkPlatform.instance.generateEmbeddings();
  }

  /// Generate embeddings for a specific prompt
  Future<List<double>> generateEmbeddingsForPrompt(String prompt) {
    return LlamaMobileFlutterSdkPlatform.instance.generateEmbeddingsForPrompt(
      prompt,
    );
  }

  /// Initialize multimodal support
  Future<bool> initMultimodal() {
    return LlamaMobileFlutterSdkPlatform.instance.initMultimodal();
  }

  /// Initialize text-to-speech
  Future<bool> initTTS(String ttsPath, TTSModelType modelType) {
    return LlamaMobileFlutterSdkPlatform.instance.initTTS(ttsPath, modelType);
  }

  /// Generate audio from text
  Future<String> generateAudio(TTSParams params) {
    return LlamaMobileFlutterSdkPlatform.instance.generateAudio(params);
  }

  /// Apply LoRA adapters
  Future<bool> applyLoraAdapters(List<LoraAdapter> adapters) {
    return LlamaMobileFlutterSdkPlatform.instance.applyLoraAdapters(adapters);
  }

  /// Create a new conversation
  Future<String> createConversation(ConversationParams params) {
    return LlamaMobileFlutterSdkPlatform.instance.createConversation(params);
  }

  /// Generate a conversation response
  Future<String> generateConversationResponse(
    String conversationId,
    CompletionParams params,
  ) {
    return LlamaMobileFlutterSdkPlatform.instance.generateConversationResponse(
      conversationId,
      params,
    );
  }

  /// Stream a conversation response
  Future<String> streamConversationResponse(
    String conversationId,
    CompletionParams params,
    Function(String) onToken,
  ) {
    return LlamaMobileFlutterSdkPlatform.instance.streamConversationResponse(
      conversationId,
      params,
      onToken,
    );
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory(
    String conversationId,
  ) {
    return LlamaMobileFlutterSdkPlatform.instance.getConversationHistory(
      conversationId,
    );
  }

  /// Clear conversation history
  Future<void> clearConversation(String conversationId) {
    return LlamaMobileFlutterSdkPlatform.instance.clearConversation(
      conversationId,
    );
  }

  /// Download a model from URL
  Future<bool> downloadModel(
    DownloadParams params,
    Function(double) onProgress,
  ) {
    return LlamaMobileFlutterSdkPlatform.instance.downloadModel(
      params,
      onProgress,
    );
  }

  /// Get the SDK version
  Future<String> getVersion() {
    return LlamaMobileFlutterSdkPlatform.instance.getVersion();
  }

  /// Get the content of a built-in grammar
  Future<String?> getGrammarContent(GrammarName grammarName) {
    return LlamaMobileFlutterSdkPlatform.instance.getGrammarContent(
      grammarName,
    );
  }

  /// Releases the loaded model and frees resources.
  Future<void> release() {
    return LlamaMobileFlutterSdkPlatform.instance.release();
  }
}
