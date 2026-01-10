import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'llama_mobile_flutter_sdk_method_channel.dart';

/// Cache type enum
enum CacheType { none, memory }

/// Grammar name enum for built-in grammars
enum GrammarName {
  arithmetic,
  c,
  chess,
  english,
  japanese,
  json,
  jsonArr,
  list,
}

/// Text-to-Speech model types
enum TTSModelType { unknown, outETTSv02, outETTSv03 }

/// Stop conditions for text generation
enum StopType { full, partial }

/// Data class for model initialization parameters
class InitParams {
  /// Path to the GGUF model file
  final String modelPath;

  /// Size of the context window
  final int nCtx;

  /// Number of layers to offload to GPU (0 = no GPU acceleration)
  final int nGpuLayers;

  /// Number of CPU threads to use
  final int nThreads;

  /// Batch size for processing input tokens
  final int nBatch;

  /// Micro-batch size for processing input tokens
  final int nUbatch;

  /// Whether to use memory-mapped files for model loading
  final bool useMmap;

  /// Whether to lock model memory in RAM
  final bool useMlock;

  /// Name of the chat template to use
  final String? chatTemplate;

  /// System prompt to guide the model's behavior
  final String? systemPrompt;

  /// Whether to enable embedding generation
  final bool embedding;

  /// Pooling type for embeddings (0 = no pooling, 1 = mean pooling, 2 = max pooling)
  final int poolingType;

  /// Whether to normalize embeddings
  final bool embdNormalize;

  /// Whether to enable flash attention optimization
  final bool flashAttn;

  /// Cache type for key tensors
  final String? cacheTypeK;

  /// Cache type for value tensors
  final String? cacheTypeV;

  InitParams({
    required this.modelPath,
    this.nCtx = 2048,
    this.nGpuLayers = 0,
    this.nThreads = 4,
    this.nBatch = 512,
    this.nUbatch = 512,
    this.useMmap = true,
    this.useMlock = false,
    this.chatTemplate,
    this.systemPrompt,
    this.embedding = false,
    this.poolingType = 0,
    this.embdNormalize = false,
    this.flashAttn = false,
    this.cacheTypeK,
    this.cacheTypeV,
  });

  Map<String, dynamic> toJson() => {
    'modelPath': modelPath,
    'nCtx': nCtx,
    'nGpuLayers': nGpuLayers,
    'nThreads': nThreads,
    'nBatch': nBatch,
    'nUbatch': nUbatch,
    'useMmap': useMmap,
    'useMlock': useMlock,
    'chatTemplate': chatTemplate,
    'systemPrompt': systemPrompt,
    'embedding': embedding,
    'poolingType': poolingType,
    'embdNormalize': embdNormalize,
    'flashAttn': flashAttn,
    'cacheTypeK': cacheTypeK,
    'cacheTypeV': cacheTypeV,
  };
}

/// Data class for completion generation parameters
class CompletionParams {
  /// The text prompt to generate a completion for
  final String prompt;

  /// Maximum number of tokens to generate
  final int maxTokens;

  /// Temperature for sampling (higher values = more random output)
  final double temperature;

  /// Top-K sampling parameter (0 = disable)
  final int topK;

  /// Top-P sampling parameter (nucleus sampling)
  final double topP;

  /// Minimum probability for sampling
  final double minP;

  /// Typical-P sampling parameter
  final double typicalP;

  /// Random seed for generation (use -1 for random seed)
  final int seed;

  /// Number of CPU threads to use for generation
  final int nThreads;

  /// Number of tokens to consider for repetition penalty
  final int penaltyLastN;

  /// Penalty for repeated tokens
  final double penaltyRepeat;

  /// Frequency penalty for tokens
  final double penaltyFreq;

  /// Present penalty for tokens
  final double penaltyPresent;

  /// Mirostat sampling mode (0 = disable, 1 = Mirostat, 2 = Mirostat 2.0)
  final int mirostat;

  /// Mirostat target entropy
  final double mirostatTau;

  /// Mirostat learning rate
  final double mirostatEta;

  /// Whether to ignore the end-of-sequence token
  final bool ignoreEos;

  /// Sequences that will stop generation when encountered
  final List<String> stopSequences;

  /// Grammar for constrained generation (using GBNF format)
  final String? grammar;

  CompletionParams({
    required this.prompt,
    this.maxTokens = 100,
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.minP = 0.05,
    this.typicalP = 1.0,
    this.seed = -1,
    this.nThreads = 4,
    this.penaltyLastN = 64,
    this.penaltyRepeat = 1.1,
    this.penaltyFreq = 0.0,
    this.penaltyPresent = 0.0,
    this.mirostat = 0,
    this.mirostatTau = 5.0,
    this.mirostatEta = 0.1,
    this.ignoreEos = false,
    this.stopSequences = const [],
    this.grammar,
  });

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'maxTokens': maxTokens,
    'temperature': temperature,
    'topK': topK,
    'topP': topP,
    'minP': minP,
    'typicalP': typicalP,
    'seed': seed,
    'nThreads': nThreads,
    'penaltyLastN': penaltyLastN,
    'penaltyRepeat': penaltyRepeat,
    'penaltyFreq': penaltyFreq,
    'penaltyPresent': penaltyPresent,
    'mirostat': mirostat,
    'mirostatTau': mirostatTau,
    'mirostatEta': mirostatEta,
    'ignoreEos': ignoreEos,
    'stopSequences': stopSequences,
    'grammar': grammar,
  };
}

/// Legacy model configuration for backward compatibility
class ModelConfig {
  final String modelPath;
  final int contextSize;
  final bool useMemoryCache;

  ModelConfig({
    required this.modelPath,
    this.contextSize = 1024,
    this.useMemoryCache = true,
  });

  Map<String, dynamic> toJson() => {
    'modelPath': modelPath,
    'contextSize': contextSize,
    'useMemoryCache': useMemoryCache,
  };
}

/// Legacy generation configuration for backward compatibility
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

/// Result of a text completion generation
class CompletionResult {
  final String text;
  final int tokensGenerated;
  final int tokensEvaluated;
  final bool truncated;
  final bool stoppedEos;
  final bool stoppedWord;
  final bool stoppedLimit;

  CompletionResult({
    required this.text,
    required this.tokensGenerated,
    required this.tokensEvaluated,
    required this.truncated,
    required this.stoppedEos,
    required this.stoppedWord,
    required this.stoppedLimit,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'tokensGenerated': tokensGenerated,
    'tokensEvaluated': tokensEvaluated,
    'truncated': truncated,
    'stoppedEos': stoppedEos,
    'stoppedWord': stoppedWord,
    'stoppedLimit': stoppedLimit,
  };
}

/// LoRA adapter configuration
class LoraAdapter {
  final String path;
  final double scale;

  LoraAdapter({required this.path, required this.scale});

  Map<String, dynamic> toJson() => {'path': path, 'scale': scale};
}

/// Text-to-Speech parameters
class TTSParams {
  final String text;
  final String voice;
  final double speed;
  final double pitch;

  TTSParams({
    required this.text,
    required this.voice,
    this.speed = 1.0,
    this.pitch = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'voice': voice,
    'speed': speed,
    'pitch': pitch,
  };
}

/// Conversation parameters
class ConversationParams {
  final String systemPrompt;
  final String chatTemplate;

  ConversationParams({required this.systemPrompt, required this.chatTemplate});

  Map<String, dynamic> toJson() => {
    'systemPrompt': systemPrompt,
    'chatTemplate': chatTemplate,
  };
}

/// Download parameters
class DownloadParams {
  final String url;
  final String destinationPath;
  final double expectedSizeMb;
  final bool unzip;

  DownloadParams({
    required this.url,
    required this.destinationPath,
    required this.expectedSizeMb,
    this.unzip = true,
  });

  Map<String, dynamic> toJson() => {
    'url': url,
    'destinationPath': destinationPath,
    'expectedSizeMb': expectedSizeMb,
    'unzip': unzip,
  };
}

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Legacy method for backward compatibility
  Future<bool> loadModel(ModelConfig config) {
    throw UnimplementedError('loadModel() has not been implemented.');
  }

  /// Initialize the model with the specified parameters
  Future<bool> initialize(InitParams params) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Legacy method for backward compatibility
  Future<String> generateCompletion(GenerationConfig config) {
    throw UnimplementedError('generateCompletion() has not been implemented.');
  }

  /// Generate text completion with the specified parameters
  Future<String> generate(CompletionParams params) {
    throw UnimplementedError('generate() has not been implemented.');
  }

  /// Get the content of a built-in grammar
  Future<String?> getGrammarContent(GrammarName grammarName) {
    throw UnimplementedError('getGrammarContent() has not been implemented.');
  }

  /// Release the loaded model and free resources
  Future<void> release() {
    throw UnimplementedError('release() has not been implemented.');
  }

  /// Generate text completion and return detailed result
  Future<CompletionResult> generateResponse(CompletionParams params) {
    throw UnimplementedError('generateResponse() has not been implemented.');
  }

  /// Stream text completion with token callbacks
  Future<String> streamCompletion(
    CompletionParams params,
    Function(String) onToken,
  ) {
    throw UnimplementedError('streamCompletion() has not been implemented.');
  }

  /// Stop an ongoing completion generation
  Future<void> stopCompletion() {
    throw UnimplementedError('stopCompletion() has not been implemented.');
  }

  /// Tokenize text into token IDs
  Future<List<int>> tokenize(String text) {
    throw UnimplementedError('tokenize() has not been implemented.');
  }

  /// Detokenize token IDs into text
  Future<String> detokenize(List<int> tokens) {
    throw UnimplementedError('detokenize() has not been implemented.');
  }

  /// Generate embeddings for the current context
  Future<List<double>> generateEmbeddings() {
    throw UnimplementedError('generateEmbeddings() has not been implemented.');
  }

  /// Generate embeddings for a specific prompt
  Future<List<double>> generateEmbeddingsForPrompt(String prompt) {
    throw UnimplementedError(
      'generateEmbeddingsForPrompt() has not been implemented.',
    );
  }

  /// Initialize multimodal support
  Future<bool> initMultimodal() {
    throw UnimplementedError('initMultimodal() has not been implemented.');
  }

  /// Initialize text-to-speech
  Future<bool> initTTS(String ttsPath, TTSModelType modelType) {
    throw UnimplementedError('initTTS() has not been implemented.');
  }

  /// Generate audio from text
  Future<String> generateAudio(TTSParams params) {
    throw UnimplementedError('generateAudio() has not been implemented.');
  }

  /// Apply LoRA adapters
  Future<bool> applyLoraAdapters(List<LoraAdapter> adapters) {
    throw UnimplementedError('applyLoraAdapters() has not been implemented.');
  }

  /// Create a new conversation
  Future<String> createConversation(ConversationParams params) {
    throw UnimplementedError('createConversation() has not been implemented.');
  }

  /// Generate a conversation response
  Future<String> generateConversationResponse(
    String conversationId,
    CompletionParams params,
  ) {
    throw UnimplementedError(
      'generateConversationResponse() has not been implemented.',
    );
  }

  /// Stream a conversation response
  Future<String> streamConversationResponse(
    String conversationId,
    CompletionParams params,
    Function(String) onToken,
  ) {
    throw UnimplementedError(
      'streamConversationResponse() has not been implemented.',
    );
  }

  /// Get conversation history
  Future<List<Map<String, dynamic>>> getConversationHistory(
    String conversationId,
  ) {
    throw UnimplementedError(
      'getConversationHistory() has not been implemented.',
    );
  }

  /// Clear conversation history
  Future<void> clearConversation(String conversationId) {
    throw UnimplementedError('clearConversation() has not been implemented.');
  }

  /// Download a model from URL
  Future<bool> downloadModel(
    DownloadParams params,
    Function(double) onProgress,
  ) {
    throw UnimplementedError('downloadModel() has not been implemented.');
  }

  /// Get the SDK version
  Future<String> getVersion() {
    throw UnimplementedError('getVersion() has not been implemented.');
  }
}
