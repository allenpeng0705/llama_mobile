import 'llama_mobile_flutter_sdk_platform_interface.dart';

/// Log levels for the SDK
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  none(4);

  final int value;
  const LogLevel(this.value);

  int get rawValue => value;

  factory LogLevel.fromRawValue(int value) {
    switch (value) {
      case 0:
        return debug;
      case 1:
        return info;
      case 2:
        return warning;
      case 3:
        return error;
      case 4:
        return none;
      default:
        return info;
    }
  }
}

/// Method used for TTS generation
enum TTSMethod {
  builtIn,
  customWorkflow;

  int get rawValue {
    switch (this) {
      case builtIn:
        return 0;
      case customWorkflow:
        return 1;
    }
  }

  factory TTSMethod.fromRawValue(int value) {
    switch (value) {
      case 0:
        return builtIn;
      case 1:
        return customWorkflow;
      default:
        return builtIn;
    }
  }
}

/// Error types for TTS operations
enum TTSError {
  noModelLoaded,
  noVocoderEnabled,
  invalidText,
  generationFailed,
  formattingFailed,
  tokenizationFailed,
  audioDecodingFailed,
  fileSaveFailed,
  unknownError;

  String get message {
    switch (this) {
      case noModelLoaded:
        return 'No model loaded';
      case noVocoderEnabled:
        return 'No vocoder enabled';
      case invalidText:
        return 'Invalid text';
      case generationFailed:
        return 'Generation failed';
      case formattingFailed:
        return 'Formatting failed';
      case tokenizationFailed:
        return 'Tokenization failed';
      case audioDecodingFailed:
        return 'Audio decoding failed';
      case fileSaveFailed:
        return 'File save failed';
      case unknownError:
        return 'Unknown error';
    }
  }
}

/// Parameters for initializing a LlamaMobile context
class InitParams {
  final String modelPath;
  final String? chatTemplate;
  final String? systemPrompt;
  final int nCtx;
  final int nBatch;
  final int nUBatch;
  final int nGpuLayers;
  final int nThreads;
  final bool useMmap;
  final bool useMlock;
  final bool embedding;
  final int poolingType;
  final int embdNormalize;
  final bool flashAttention;
  final String? cacheTypeK;
  final String? cacheTypeV;
  final bool enableChatTemplate;

  InitParams({
    required this.modelPath,
    this.chatTemplate,
    this.systemPrompt,
    this.nCtx = 2048,
    this.nBatch = 512,
    this.nUBatch = 512,
    this.nGpuLayers = 0,
    this.nThreads = 4,
    this.useMmap = true,
    this.useMlock = false,
    this.embedding = false,
    this.poolingType = 0,
    this.embdNormalize = 0,
    this.flashAttention = false,
    this.cacheTypeK,
    this.cacheTypeV,
    this.enableChatTemplate = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'modelPath': modelPath,
      'chatTemplate': chatTemplate,
      'systemPrompt': systemPrompt,
      'nCtx': nCtx,
      'nBatch': nBatch,
      'nUBatch': nUBatch,
      'nGpuLayers': nGpuLayers,
      'nThreads': nThreads,
      'useMmap': useMmap,
      'useMlock': useMlock,
      'embedding': embedding,
      'poolingType': poolingType,
      'embdNormalize': embdNormalize,
      'flashAttention': flashAttention,
      'cacheTypeK': cacheTypeK,
      'cacheTypeV': cacheTypeV,
      'enableChatTemplate': enableChatTemplate,
    };
  }
}

/// Parameters for text completion
class CompletionParams {
  final String prompt;
  final int maxTokens;
  final int? nThreads;
  final int seed;
  final double temperature;
  final int topK;
  final double topP;
  final double minP;
  final double typicalP;
  final int penaltyLastN;
  final double penaltyRepeat;
  final double penaltyFreq;
  final double penaltyPresent;
  final int mirostat;
  final double mirostatTau;
  final double mirostatEta;
  final bool ignoreEos;
  final List<String> stopSequences;
  final String? grammar;
  final bool useJsonResponse;
  final int nProbs;
  final String? jsonSchema;
  final String? tools;
  final bool parallelToolCalls;
  final String? toolChoice;
  final List<String> mediaPaths;
  final List<ChatMessage> chatMessages;

  CompletionParams({
    required this.prompt,
    this.maxTokens = 1024,
    this.nThreads,
    this.seed = -1,
    this.temperature = 0.8,
    this.topK = 40,
    this.topP = 0.95,
    this.minP = 0.05,
    this.typicalP = 1.0,
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
    this.useJsonResponse = true,
    this.nProbs = 0,
    this.jsonSchema,
    this.tools,
    this.parallelToolCalls = false,
    this.toolChoice,
    this.mediaPaths = const [],
    this.chatMessages = const [],
  });

  CompletionParams.forChat({
    required List<ChatMessage> chatMessages,
    this.maxTokens = 1024,
    this.nThreads,
    this.seed = -1,
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.95,
    this.minP = 0.05,
    this.typicalP = 1.0,
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
    this.useJsonResponse = true,
    this.nProbs = 0,
    this.jsonSchema,
    this.tools,
    this.parallelToolCalls = false,
    this.toolChoice,
    this.mediaPaths = const [],
  }) : prompt = '',
       chatMessages = chatMessages;

  Map<String, dynamic> toMap() {
    return {
      'prompt': prompt,
      'maxTokens': maxTokens,
      'nThreads': nThreads,
      'seed': seed,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
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
      'useJsonResponse': useJsonResponse,
      'nProbs': nProbs,
      'jsonSchema': jsonSchema,
      'tools': tools,
      'parallelToolCalls': parallelToolCalls,
      'toolChoice': toolChoice,
      'mediaPaths': mediaPaths,
      'chatMessages': chatMessages.map((m) => m.toMap()).toList(),
    };
  }

  factory CompletionParams.fromPrompt(String prompt) {
    return CompletionParams(prompt: prompt);
  }

  factory CompletionParams.fromChatMessages(List<ChatMessage> chatMessages) {
    return CompletionParams(
      prompt: '',
      chatMessages: chatMessages,
      maxTokens: 1024,
      temperature: 0.7,
      topP: 0.95,
      topK: 40,
      penaltyRepeat: 1.2,
    );
  }

  factory CompletionParams.fromCreativePrompt(
    String creativePrompt, {
    int maxTokens = 1024,
  }) {
    return CompletionParams(
      prompt: creativePrompt,
      maxTokens: maxTokens,
      temperature: 1.0,
      topP: 0.98,
      topK: 100,
    );
  }

  factory CompletionParams.fromFactualPrompt(String factualPrompt) {
    return CompletionParams(
      prompt: factualPrompt,
      temperature: 0.1,
      topP: 0.9,
      topK: 20,
    );
  }

  factory CompletionParams.fromChatPrompt(
    String chatPrompt, {
    int maxTokens = 1024,
  }) {
    return CompletionParams(
      prompt: chatPrompt,
      maxTokens: maxTokens,
      temperature: 0.7,
      topP: 0.95,
      topK: 40,
      penaltyRepeat: 1.2,
    );
  }

  factory CompletionParams.fromMultimodalPrompt(
    String multimodalPrompt,
    List<String> mediaPaths, {
    int maxTokens = 1024,
  }) {
    return CompletionParams(
      prompt: multimodalPrompt,
      maxTokens: maxTokens,
      mediaPaths: mediaPaths,
    );
  }
}

/// Parameters for downloading files
class DownloadParams {
  final String url;
  final String localPath;
  final String? username;
  final String? password;
  final Map<String, String>? headers;

  DownloadParams({
    required this.url,
    required this.localPath,
    this.username,
    this.password,
    this.headers,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'localPath': localPath,
      'username': username,
      'password': password,
      'headers': headers,
    };
  }
}

/// Parameters for downloading Hugging Face files
class HuggingFaceDownloadParams {
  final String repoId;
  final String filename;
  final String localPath;
  final String? bearerToken;
  final bool offline;

  HuggingFaceDownloadParams({
    required this.repoId,
    required this.filename,
    required this.localPath,
    this.bearerToken,
    this.offline = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'repoId': repoId,
      'filename': filename,
      'localPath': localPath,
      'bearerToken': bearerToken,
      'offline': offline,
    };
  }
}

/// Options for TTS generation
class TTSOptions {
  final int sampleRate;
  final String? voice;
  final double speed;
  final bool saveToFile;
  final String? outputFilePath;

  TTSOptions({
    this.sampleRate = 24000,
    this.voice,
    this.speed = 1.0,
    this.saveToFile = false,
    this.outputFilePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'sampleRate': sampleRate,
      'voice': voice,
      'speed': speed,
      'saveToFile': saveToFile,
      'outputFilePath': outputFilePath,
    };
  }
}

/// Result of TTS speech generation
class SpeechResult {
  final List<int> audioSamples;
  final int sampleRate;
  final double duration;
  final String? outputFilePath;
  final TTSMethod methodUsed;

  SpeechResult({
    required this.audioSamples,
    required this.sampleRate,
    required this.duration,
    this.outputFilePath,
    required this.methodUsed,
  });

  factory SpeechResult.fromMap(Map<String, dynamic> map) {
    return SpeechResult(
      audioSamples: List<int>.from(map['audioSamples'] as List),
      sampleRate: map['sampleRate'] as int,
      duration: map['duration'] as double,
      outputFilePath: map['outputFilePath'] as String?,
      methodUsed: TTSMethod.fromRawValue(map['methodUsed'] as int),
    );
  }
}

/// Metadata for streaming TTS generation
class SpeechMetadata {
  final int sampleRate;
  final double duration;
  final TTSMethod methodUsed;
  final String? outputFilePath;

  SpeechMetadata({
    required this.sampleRate,
    required this.duration,
    required this.methodUsed,
    this.outputFilePath,
  });

  factory SpeechMetadata.fromMap(Map<String, dynamic> map) {
    return SpeechMetadata(
      sampleRate: map['sampleRate'] as int,
      duration: map['duration'] as double,
      methodUsed: TTSMethod.fromRawValue(map['methodUsed'] as int),
      outputFilePath: map['outputFilePath'] as String?,
    );
  }
}

/// LoRA adapter configuration
class LoraAdapter {
  final String adapterPath;
  final double scale;

  LoraAdapter({required this.adapterPath, required this.scale});

  Map<String, dynamic> toMap() {
    return {'adapterPath': adapterPath, 'scale': scale};
  }

  factory LoraAdapter.fromMap(Map<String, dynamic> map) {
    return LoraAdapter(
      adapterPath: map['adapterPath'] as String,
      scale: map['scale'] as double,
    );
  }
}

/// Main entry point for the LlamaMobile Flutter SDK.
///
/// This class provides methods to initialize contexts, download models, and interact with
/// the LlamaMobile platform implementation.
class LlamaMobile {
  /// Sets the log level for the SDK.
  ///
  /// Parameters:
  /// - [level]: Log level to set (0 = debug, 1 = info, 2 = warning, 3 = error).
  static Future<void> setLogLevel(LogLevel level) async {
    await LlamaMobileFlutterSdkPlatform.instance.setLogLevel(level.rawValue);
  }

  /// Sets the log level for the SDK using raw integer value.
  ///
  /// Parameters:
  /// - [level]: Log level to set (0 = debug, 1 = info, 2 = warning, 3 = error).
  static Future<void> setLogLevelRaw(int level) async {
    await LlamaMobileFlutterSdkPlatform.instance.setLogLevel(level);
  }

  /// Initializes a new LlamaMobile context with the specified model.
  ///
  /// Parameters:
  /// - [params]: Initialization parameters.
  Future<LlamaContext?> initContextWithParams(InitParams params) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance.initContext(
      params.toMap(),
    );
    if (result != null && result.containsKey('contextHandle')) {
      final contextHandle = result['contextHandle'] as int;
      return LlamaContext._internal(contextHandle);
    }
    return null;
  }

  /// Initializes a new LlamaMobile context with specified parameters asynchronously.
  ///
  /// Parameters:
  /// - [params]: InitParams object containing all initialization parameters.
  Future<LlamaContext?> initContextWithParamsAsync(InitParams params) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .initContextAsync(params.toMap());
    if (result != null && result.containsKey('contextHandle')) {
      final contextHandle = result['contextHandle'] as int;
      return LlamaContext._internal(contextHandle);
    }
    return null;
  }

  /// Initializes a new LlamaMobile context with the specified model.
  ///
  /// Parameters:
  /// - [modelPath]: Path to the GGUF model file.
  /// - [chatTemplate]: Custom chat template for formatting conversations.
  /// - [systemPrompt]: System prompt to guide the model's behavior.
  /// - [nCtx]: Context window size (maximum tokens to process in one pass).
  /// - [nBatch]: Batch size for processing prompts.
  /// - [nUBatch]: Micro-batch size for processing.
  /// - [nGpuLayers]: Number of layers to offload to GPU.
  /// - [nThreads]: Number of CPU threads to use.
  /// - [useMmap]: Whether to use memory mapping for the model.
  /// - [useMlock]: Whether to lock model memory in RAM.
  /// - [embedding]: Whether to enable embedding generation.
  /// - [poolingType]: Embedding pooling type (0 = no pooling, 1 = mean, 2 = max, 3 = last token).
  /// - [embdNormalize]: Whether to normalize embeddings.
  /// - [flashAttention]: Whether to use flash attention optimization.
  /// - [cacheTypeK]: Cache type for key tensors.
  /// - [cacheTypeV]: Cache type for value tensors.
  /// - [enableChatTemplate]: Whether to enable chat template processing.
  Future<LlamaContext?> initContext({
    required String modelPath,
    String? chatTemplate,
    String? systemPrompt,
    int nCtx = 2048,
    int nBatch = 512,
    int nUBatch = 512,
    int nGpuLayers = 0,
    int nThreads = 4,
    bool useMmap = true,
    bool useMlock = false,
    bool embedding = false,
    int poolingType = 0,
    int embdNormalize = 0,
    bool flashAttention = false,
    String? cacheTypeK,
    String? cacheTypeV,
    bool enableChatTemplate = true,
  }) async {
    final params = InitParams(
      modelPath: modelPath,
      chatTemplate: chatTemplate,
      systemPrompt: systemPrompt,
      nCtx: nCtx,
      nBatch: nBatch,
      nUBatch: nUBatch,
      nGpuLayers: nGpuLayers,
      nThreads: nThreads,
      useMmap: useMmap,
      useMlock: useMlock,
      embedding: embedding,
      poolingType: poolingType,
      embdNormalize: embdNormalize,
      flashAttention: flashAttention,
      cacheTypeK: cacheTypeK,
      cacheTypeV: cacheTypeV,
      enableChatTemplate: enableChatTemplate,
    );
    return initContextWithParams(params);
  }

  /// Downloads a model from a URL
  Future<DownloadResult?> downloadModel({
    required String url,
    required String localPath,
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    final params = DownloadParams(
      url: url,
      localPath: localPath,
      username: username,
      password: password,
      headers: headers,
    );
    return downloadModelWithParams(params);
  }

  /// Downloads a model from a URL using DownloadParams.
  ///
  /// Parameters:
  /// - [params]: Download parameters.
  Future<DownloadResult?> downloadModelWithParams(DownloadParams params) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance.downloadModel(
      params.toMap(),
    );
    if (result != null) {
      return DownloadResult(
        success: result['success'] as bool,
        localPath: result['localPath'] as String,
        errorMessage: result['errorMessage'] as String?,
      );
    }
    return null;
  }

  /// Downloads a file from Hugging Face
  Future<DownloadResult?> downloadHfFile({
    required String repoId,
    required String filename,
    required String localPath,
    String? bearerToken,
    bool? offline,
  }) async {
    final params = HuggingFaceDownloadParams(
      repoId: repoId,
      filename: filename,
      localPath: localPath,
      bearerToken: bearerToken,
      offline: offline ?? false,
    );
    return downloadHfFileWithParams(params);
  }

  /// Downloads a file from Hugging Face using HuggingFaceDownloadParams.
  ///
  /// Parameters:
  /// - [params]: Hugging Face download parameters.
  Future<DownloadResult?> downloadHfFileWithParams(
    HuggingFaceDownloadParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance.downloadHfFile(
      params.toMap(),
    );
    if (result != null) {
      return DownloadResult(
        success: result['success'] as bool,
        localPath: result['localPath'] as String,
        errorMessage: result['errorMessage'] as String?,
      );
    }
    return null;
  }

  /// Initializes a context asynchronously (runs in background thread)
  Future<LlamaContext?> initContextAsync({
    required String modelPath,
    String? chatTemplate,
    String? systemPrompt,
    int nCtx = 2048,
    int nBatch = 512,
    int nUBatch = 512,
    int nGpuLayers = 0,
    int nThreads = 4,
    bool useMmap = true,
    bool useMlock = false,
    bool embedding = false,
    int poolingType = 0,
    int embdNormalize = 0,
    bool flashAttention = false,
    String? cacheTypeK,
    String? cacheTypeV,
    bool enableChatTemplate = true,
  }) async {
    final params = InitParams(
      modelPath: modelPath,
      chatTemplate: chatTemplate,
      systemPrompt: systemPrompt,
      nCtx: nCtx,
      nBatch: nBatch,
      nUBatch: nUBatch,
      nGpuLayers: nGpuLayers,
      nThreads: nThreads,
      useMmap: useMmap,
      useMlock: useMlock,
      embedding: embedding,
      poolingType: poolingType,
      embdNormalize: embdNormalize,
      flashAttention: flashAttention,
      cacheTypeK: cacheTypeK,
      cacheTypeV: cacheTypeV,
      enableChatTemplate: enableChatTemplate,
    );
    return initContextWithParamsAsync(params);
  }

  /// Downloads a model from a URL asynchronously
  Future<DownloadResult?> downloadModelAsync({
    required String url,
    required String localPath,
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    final params = DownloadParams(
      url: url,
      localPath: localPath,
      username: username,
      password: password,
      headers: headers,
    );
    return downloadModelWithParamsAsync(params);
  }

  /// Downloads a model from a URL using DownloadParams asynchronously.
  ///
  /// Parameters:
  /// - [params]: Download parameters.
  Future<DownloadResult?> downloadModelWithParamsAsync(
    DownloadParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .downloadModelAsync(params.toMap());
    if (result != null) {
      return DownloadResult(
        success: result['success'] as bool,
        localPath: result['localPath'] as String,
        errorMessage: result['errorMessage'] as String?,
      );
    }
    return null;
  }

  /// Downloads a file from Hugging Face asynchronously
  Future<DownloadResult?> downloadHfFileAsync({
    required String repoId,
    required String filename,
    required String localPath,
    String? bearerToken,
    bool? offline,
  }) async {
    final params = HuggingFaceDownloadParams(
      repoId: repoId,
      filename: filename,
      localPath: localPath,
      bearerToken: bearerToken,
      offline: offline ?? false,
    );
    return downloadHfFileWithParamsAsync(params);
  }

  /// Downloads a file from Hugging Face using HuggingFaceDownloadParams asynchronously.
  ///
  /// Parameters:
  /// - [params]: Hugging Face download parameters.
  Future<DownloadResult?> downloadHfFileWithParamsAsync(
    HuggingFaceDownloadParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .downloadHfFileAsync(params.toMap());
    if (result != null) {
      return DownloadResult(
        success: result['success'] as bool,
        localPath: result['localPath'] as String,
        errorMessage: result['errorMessage'] as String?,
      );
    }
    return null;
  }
}

/// Represents a LlamaMobile context
class LlamaContext {
  final int _contextHandle;

  LlamaContext._internal(this._contextHandle);

  /// Gets the context handle
  int get handle => _contextHandle;

  /// Stream of tokens as they are generated
  Stream<String> get onTokenStream {
    return LlamaMobileFlutterSdkPlatform.instance.onTokenStream;
  }

  /// Stream of progress values during generation
  Stream<double> get onProgressStream {
    return LlamaMobileFlutterSdkPlatform.instance.onProgressStream;
  }

  /// Frees the context
  Future<bool> free() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeContext(
      _contextHandle,
    );
  }

  /// Frees the context asynchronously
  Future<bool> freeAsync() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeContextAsync(
      _contextHandle,
    );
  }

  /// Generates a completion using OpenAI-compatible JSON format
  Future<CompletionResult?> generateOpenAICompletion({
    required String openAIJSON,
    String? grammar,
  }) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateOpenAICompletion(_contextHandle, openAIJSON, grammar);
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Generates a completion using OpenAI-compatible JSON format asynchronously
  Future<CompletionResult?> generateOpenAICompletionAsync({
    required String openAIJSON,
    String? grammar,
  }) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateOpenAICompletionAsync(_contextHandle, openAIJSON, grammar);
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Generates a streaming completion using OpenAI-compatible JSON format
  Future<CompletionResult?> generateStreamingOpenAICompletion({
    required String openAIJSON,
    String? grammar,
  }) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateStreamingOpenAICompletion(_contextHandle, openAIJSON, grammar);
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Generates a streaming completion from the given prompt.
  Future<CompletionResult?> generateStreamingCompletion({
    required String prompt,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    List<String> stopSequences = const [],
    String? grammar,
    bool useJsonResponse = true,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar,
      useJsonResponse: useJsonResponse,
    );
    return generateStreamingCompletionWithParams(params);
  }

  /// Generates a streaming completion using CompletionParams.
  ///
  /// Parameters:
  /// - [params]: Completion parameters.
  Future<CompletionResult?> generateStreamingCompletionWithParams(
    CompletionParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateStreamingCompletion(_contextHandle, params.toMap());
    if (result != null) {
      return CompletionResult.fromMap(result);
    }
    return null;
  }

  /// Stops the current completion generation
  Future<bool> stopCompletion() async {
    return await LlamaMobileFlutterSdkPlatform.instance.stopCompletion(
      _contextHandle,
    );
  }

  /// Gets the list of loaded LoRA adapters
  Future<List<Map<String, dynamic>>?> getLoadedLoraAdapters() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getLoadedLoraAdapters(
      _contextHandle,
    );
  }

  /// Gets the context window size
  Future<int?> getContextWindowSize() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getContextWindowSize(
      _contextHandle,
    );
  }

  /// Gets the embedding dimension
  Future<int?> getEmbeddingDimension() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getEmbeddingDimension(
      _contextHandle,
    );
  }

  /// Gets the model description
  Future<String?> getModelDescription() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getModelDescription(
      _contextHandle,
    );
  }

  /// Gets the model size in bytes
  Future<int?> getModelSize() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getModelSize(
      _contextHandle,
    );
  }

  /// Gets the model parameters count
  Future<int?> getModelParametersCount() async {
    return await LlamaMobileFlutterSdkPlatform.instance.getModelParametersCount(
      _contextHandle,
    );
  }

  /// Downloads a file from Hugging Face
  Future<DownloadResult?> downloadHfFile({
    required String repoId,
    required String filename,
    required String localPath,
    String? bearerToken,
    bool? offline,
  }) async {
    final params = {
      'repoId': repoId,
      'filename': filename,
      'localPath': localPath,
      'bearerToken': bearerToken,
      'offline': offline,
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance.downloadHfFile(
      params,
    );
    if (result != null) {
      return DownloadResult(
        success: result['success'] as bool,
        localPath: result['localPath'] as String,
        errorMessage: result['errorMessage'] as String?,
      );
    }
    return null;
  }

  /// Checks if multimodal is enabled
  Future<bool> isMultimodalEnabled() async {
    return await LlamaMobileFlutterSdkPlatform.instance.isMultimodalEnabled(
      _contextHandle,
    );
  }

  /// Checks if vision is supported
  Future<bool> supportsVision() async {
    return await LlamaMobileFlutterSdkPlatform.instance.supportsVision(
      _contextHandle,
    );
  }

  /// Checks if audio is supported
  Future<bool> supportsAudio() async {
    return await LlamaMobileFlutterSdkPlatform.instance.supportsAudio(
      _contextHandle,
    );
  }

  /// Checks if vocoder is enabled
  Future<bool> isVocoderEnabled() async {
    return await LlamaMobileFlutterSdkPlatform.instance.isVocoderEnabled(
      _contextHandle,
    );
  }

  /// Gets the TTS type
  Future<TTSModelType> getTTSType() async {
    final result = await LlamaMobileFlutterSdkPlatform.instance.getTTSType(
      _contextHandle,
    );
    return TTSModelType.fromRawValue(result ?? -1);
  }

  /// Generates a text completion from the given prompt.
  ///
  /// Parameters:
  /// - [prompt]: Input text to generate completion from.
  /// - [maxTokens]: Maximum number of tokens to generate.
  /// - [nThreads]: Number of CPU threads to use (overrides context setting).
  /// - [seed]: Random seed for generation (-1 = random).
  /// - [temperature]: Sampling temperature (higher = more creative, lower = more deterministic).
  /// - [topK]: Top-k sampling parameter (consider only top k tokens).
  /// - [topP]: Top-p sampling parameter (consider only top tokens with cumulative probability p).
  /// - [minP]: Minimum probability for top-p filtering.
  /// - [typicalP]: Typical sampling parameter for locally typical sampling.
  /// - [penaltyLastN]: Number of last tokens to consider for repetition penalty.
  /// - [penaltyRepeat]: Penalty for repeated tokens (higher = more penalty).
  /// - [penaltyFreq]: Frequency penalty (higher = penalize frequent tokens more).
  /// - [penaltyPresent]: Penalty for tokens present in the prompt.
  /// - [mirostat]: Mirostat sampling method (0 = disabled, 1 = v1, 2 = v2).
  /// - [mirostatTau]: Mirostat target entropy.
  /// - [mirostatEta]: Mirostat learning rate.
  /// - [ignoreEos]: Whether to ignore end-of-sequence tokens.
  /// - [stopSequences]: List of sequences to stop generation at.
  /// - [grammar]: Grammar string to constrain output to a specific format.
  /// - [useJsonResponse]: Whether to format response as JSON.
  Future<CompletionResult?> generateCompletion({
    required String prompt,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    List<String> stopSequences = const [],
    String? grammar,
    bool useJsonResponse = true,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar,
      useJsonResponse: useJsonResponse,
    );
    return generateCompletionWithParams(params);
  }

  /// Generates a text completion using CompletionParams.
  ///
  /// Parameters:
  /// - [params]: Completion parameters.
  Future<CompletionResult?> generateCompletionWithParams(
    CompletionParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateCompletion(_contextHandle, params.toMap());
    if (result != null) {
      return CompletionResult.fromMap(result);
    }
    return null;
  }

  /// Generates a multimodal completion
  Future<CompletionResult?> generateMultimodalCompletion({
    required String prompt,
    required List<String> mediaPaths,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    List<String> stopSequences = const [],
    String? grammar,
    bool useJsonResponse = true,
    String? chatTemplate,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar,
      useJsonResponse: useJsonResponse,
    );
    return generateMultimodalCompletionWithParams(params, mediaPaths);
  }

  /// Generates a multimodal completion using CompletionParams.
  ///
  /// Parameters:
  /// - [params]: Completion parameters.
  /// - [mediaPaths]: Paths to media files for multimodal generation (images/audio).
  Future<CompletionResult?> generateMultimodalCompletionWithParams(
    CompletionParams params,
    List<String> mediaPaths,
  ) async {
    final paramsWithMedia = CompletionParams(
      prompt: params.prompt,
      maxTokens: params.maxTokens,
      nThreads: params.nThreads,
      seed: params.seed,
      temperature: params.temperature,
      topK: params.topK,
      topP: params.topP,
      minP: params.minP,
      typicalP: params.typicalP,
      penaltyLastN: params.penaltyLastN,
      penaltyRepeat: params.penaltyRepeat,
      penaltyFreq: params.penaltyFreq,
      penaltyPresent: params.penaltyPresent,
      mirostat: params.mirostat,
      mirostatTau: params.mirostatTau,
      mirostatEta: params.mirostatEta,
      ignoreEos: params.ignoreEos,
      stopSequences: params.stopSequences,
      grammar: params.grammar,
      useJsonResponse: params.useJsonResponse,
      nProbs: params.nProbs,
      jsonSchema: params.jsonSchema,
      tools: params.tools,
      parallelToolCalls: params.parallelToolCalls,
      toolChoice: params.toolChoice,
      mediaPaths: mediaPaths,
      chatMessages: params.chatMessages,
    );
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateMultimodalCompletion(
          _contextHandle,
          paramsWithMedia.toMap(),
          mediaPaths,
        );
    if (result != null) {
      return CompletionResult.fromMap(result);
    }
    return null;
  }

  /// Formats chat messages using the chat template
  Future<String?> formatChatMessages(
    List<ChatMessage> messages,
    String? chatTemplate,
  ) async {
    final messagesJson = messages.map((msg) => msg.toMap()).toList();
    return await LlamaMobileFlutterSdkPlatform.instance.formatChatMessages(
      _contextHandle,
      messagesJson,
      chatTemplate,
    );
  }

  /// Loads a grammar from a file path.
  ///
  /// Parameters:
  /// - [grammarPath]: Path to the grammar file.
  ///
  /// Returns:
  /// The loaded grammar string, or null if loading failed.
  Future<String?> loadGrammar(String grammarPath) async {
    return await LlamaMobileFlutterSdkPlatform.instance.loadGrammar(
      _contextHandle,
      grammarPath,
    );
  }

  /// Generates a vector embedding for the given text.
  ///
  /// Note: The context must have been initialized with `embedding: true`.
  ///
  /// Parameters:
  /// - [text]: Input text to generate embedding for.
  ///
  /// Returns:
  /// A list of doubles representing the embedding vector, or null if generation failed.
  Future<List<double>?> generateEmbedding(String text) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateEmbedding(
      _contextHandle,
      text,
      {},
    );
  }

  /// Generates a vector embedding for the given text asynchronously (runs in background thread).
  ///
  /// Note: The context must have been initialized with `embedding: true`.
  ///
  /// Parameters:
  /// - [text]: Input text to generate embedding for.
  ///
  /// Returns:
  /// A list of doubles representing the embedding vector, or null if generation failed.
  Future<List<double>?> generateEmbeddingAsync(String text) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateEmbeddingAsync(
      _contextHandle,
      text,
      {},
    );
  }

  /// Tokenizes a text string into token IDs.
  ///
  /// Parameters:
  /// - [text]: Text string to tokenize.
  ///
  /// Returns:
  /// A list of integers representing token IDs, or null if tokenization failed.
  Future<List<int>?> tokenize(String text) async {
    return await LlamaMobileFlutterSdkPlatform.instance.tokenize(
      _contextHandle,
      text,
    );
  }

  /// Detokenizes an array of token IDs back to a text string.
  ///
  /// Parameters:
  /// - [tokens]: Array of token IDs to detokenize.
  ///
  /// Returns:
  /// Detokenized text string, or null if detokenization failed.
  Future<String?> detokenize(List<int> tokens) async {
    return await LlamaMobileFlutterSdkPlatform.instance.detokenize(
      _contextHandle,
      tokens,
    );
  }

  /// Loads a LoRA adapter
  Future<bool> loadLoraAdapter(String adapterPath, double scale) async {
    return await LlamaMobileFlutterSdkPlatform.instance.loadLoraAdapter(
      _contextHandle,
      adapterPath,
      scale,
    );
  }

  /// Frees the LoRA adapter
  Future<bool> freeLoraAdapter() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeLoraAdapter(
      _contextHandle,
    );
  }

  /// Loads a Text-to-Speech (TTS) model.
  ///
  /// Parameters:
  /// - [modelPath]: Path to the TTS model file.
  /// - [modelType]: Type of TTS model to load (e.g., `TTSModelType.outETTSv02`).
  ///
  /// Returns:
  /// `true` if the model was loaded successfully, `false` otherwise.
  Future<bool> loadTTSModel(String modelPath, TTSModelType modelType) async {
    final params = {'modelType': modelType.rawValue};
    final result = await LlamaMobileFlutterSdkPlatform.instance.loadTTSModel(
      _contextHandle,
      modelPath,
      params,
    );
    return result?['success'] ?? false;
  }

  /// Generates audio from text using the loaded TTS model.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [speed]: Speech speed (0.5 = half speed, 2.0 = double speed).
  /// - [pitch]: Speech pitch (0.5 = lower pitch, 2.0 = higher pitch).
  /// - [volume]: Speech volume (0.0 = silent, 2.0 = double volume).
  /// - [sampleRate]: Output audio sample rate (default: 24000 Hz).
  ///
  /// Returns:
  /// An [AudioResult] object containing the generated audio data and format information.
  Future<AudioResult?> _generateAudio(String text) async {
    print(
      "[DEBUG] Dart LlamaContext: _generateAudio called - text: $text, contextHandle: $_contextHandle",
    );

    try {
      final result = await LlamaMobileFlutterSdkPlatform.instance.generateAudio(
        _contextHandle,
        text,
      );

      print(
        "[DEBUG] Dart LlamaContext: _generateAudio result received: $result",
      );

      if (result != null) {
        print("[DEBUG] Dart LlamaContext: TTS Audio Generated successfully");
        // Convert List<Object?> to List<int>
        final dynamic audioDataDynamic = result['audioData'];
        List<int> audioData = [];
        if (audioDataDynamic is List) {
          audioData = audioDataDynamic
              .map((e) => e is int ? e : (e is double ? e.toInt() : 0))
              .toList();
          print(
            "[DEBUG] Dart LlamaContext: Audio data converted successfully, length: ${audioData.length}",
          );
        }
        return AudioResult(audioData: audioData);
      }
      print("[DEBUG] Dart LlamaContext: TTS Audio Generated NULL");
      return null;
    } catch (e) {
      print("[DEBUG] Dart LlamaContext: Error in _generateAudio: $e");
      rethrow;
    }
  }

  /// Frees the TTS model
  Future<bool> freeTTSModel() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeTTSModel(
      _contextHandle,
    );
  }

  /// Save audio samples to WAV file
  /// - Parameters:
  ///   - filePath: Path to save the WAV file
  ///   - audioData: Array of 16-bit integer audio samples
  ///   - sampleRate: Sample rate for the audio (default: 24000 Hz)
  /// - Returns: Boolean indicating whether the audio was saved successfully
  Future<bool> saveAudioToWav(
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) async {
    return await LlamaMobileFlutterSdkPlatform.instance.saveAudioToWav(
      _contextHandle,
      filePath,
      audioData,
      sampleRate,
    );
  }

  /// Save audio samples to WAV file asynchronously (runs in background thread)
  /// - Parameters:
  ///   - filePath: Path to save the WAV file
  ///   - audioData: Array of 16-bit integer audio samples
  ///   - sampleRate: Sample rate for the audio (default: 24000 Hz)
  /// - Returns: Boolean indicating whether the audio was saved successfully
  Future<bool> saveAudioToWavAsync(
    String filePath,
    List<int> audioData,
    int sampleRate,
  ) async {
    return await LlamaMobileFlutterSdkPlatform.instance.saveAudioToWavAsync(
      _contextHandle,
      filePath,
      audioData,
      sampleRate,
    );
  }

  /// Initializes multimodal support with the specified mmproj model
  ///
  /// Parameters:
  /// - [mmprojPath]: Path to the multimodal projection file
  /// - [useGpu]: Whether to use GPU acceleration for multimodal processing
  ///
  /// Returns:
  /// `true` if multimodal support was initialized successfully, `false` otherwise
  Future<bool> initMultimodal(String mmprojPath, bool useGpu) async {
    return await LlamaMobileFlutterSdkPlatform.instance.initMultimodal(
      _contextHandle,
      mmprojPath,
      useGpu,
    );
  }

  /// Releases multimodal resources
  Future<void> releaseMultimodal() async {
    await LlamaMobileFlutterSdkPlatform.instance.releaseMultimodal(
      _contextHandle,
    );
  }

  /// Initializes the vocoder for text-to-speech functionality
  ///
  /// Parameters:
  /// - [vocoderModelPath]: Path to the vocoder model file
  ///
  /// Returns:
  /// `true` if vocoder was initialized successfully, `false` otherwise
  Future<bool> initVocoder(String vocoderModelPath) async {
    return await LlamaMobileFlutterSdkPlatform.instance.initVocoder(
      _contextHandle,
      vocoderModelPath,
    );
  }

  /// Releases vocoder resources
  Future<void> releaseVocoder() async {
    await LlamaMobileFlutterSdkPlatform.instance.releaseVocoder(_contextHandle);
  }

  /// Clears the conversation history
  Future<void> clearConversation() async {
    await LlamaMobileFlutterSdkPlatform.instance.clearConversation(
      _contextHandle,
    );
  }

  /// Checks if a conversation is currently active
  ///
  /// Returns:
  /// `true` if a conversation is active, `false` otherwise
  Future<bool> isConversationActive() async {
    return await LlamaMobileFlutterSdkPlatform.instance.isConversationActive(
      _contextHandle,
    );
  }

  /// Removes all loaded LoRA adapters
  Future<void> removeLoraAdapters() async {
    await LlamaMobileFlutterSdkPlatform.instance.removeLoraAdapters(
      _contextHandle,
    );
  }

  /// Generates audio from text using the loaded TTS model.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [speakerJson]: JSON string with speaker configuration (optional, defaults to default speaker).
  ///
  /// Returns:
  /// A list of floating-point audio samples, or null if an error occurred.
  Future<List<double>?> _generateAudioFromText(
    String text, {
    String speakerJson = '{"speaker": "default"}',
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateAudioFromText(
      _contextHandle,
      text,
      speakerJson,
    );
  }

  /// Gets the formatted audio completion for TTS.
  ///
  /// Parameters:
  /// - [speakerJson]: JSON string with speaker configuration.
  /// - [textToSpeak]: Text to convert to speech.
  ///
  /// Returns:
  /// The formatted audio completion string, or null if an error occurred.
  Future<String?> _getFormattedAudioCompletion(
    String speakerJson,
    String textToSpeak,
  ) async {
    return await LlamaMobileFlutterSdkPlatform.instance
        .getFormattedAudioCompletion(_contextHandle, speakerJson, textToSpeak);
  }

  /// Gets audio guide tokens for TTS.
  ///
  /// Parameters:
  /// - [textToSpeak]: Text to convert to speech.
  ///
  /// Returns:
  /// A list of guide tokens, or null if an error occurred.
  Future<List<int>?> _getAudioGuideTokens(String textToSpeak) async {
    return await LlamaMobileFlutterSdkPlatform.instance.getAudioGuideTokens(
      _contextHandle,
      textToSpeak,
    );
  }

  /// Sets guide tokens for audio generation.
  ///
  /// Parameters:
  /// - [tokens]: Guide tokens to set for audio generation.
  Future<void> _setGuideTokens(List<int> tokens) async {
    await LlamaMobileFlutterSdkPlatform.instance.setGuideTokens(
      _contextHandle,
      tokens,
    );
  }

  /// Decodes audio tokens into raw audio data.
  ///
  /// Parameters:
  /// - [tokens]: Audio tokens to decode.
  ///
  /// Returns:
  /// A list of floating-point audio samples, or null if an error occurred.
  Future<List<double>?> _decodeAudioTokens(List<int> tokens) async {
    return await LlamaMobileFlutterSdkPlatform.instance.decodeAudioTokens(
      _contextHandle,
      tokens,
    );
  }

  /// Generates speech synchronously from text.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [options]: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath).
  ///
  /// Returns:
  /// A map containing audio data and metadata, or null if an error occurred.
  Future<Map<String, dynamic>?> generateSpeechSync(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateSpeechSync(
      _contextHandle,
      text,
      options,
    );
  }

  /// Generates speech asynchronously from text.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [options]: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath).
  ///
  /// Returns:
  /// A map containing audio data and metadata, or null if an error occurred.
  Future<Map<String, dynamic>?> generateSpeech(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateSpeech(
      _contextHandle,
      text,
      options,
    );
  }

  /// Generates speech as a stream from text.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [options]: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath).
  ///
  /// Returns:
  /// A map containing stream metadata, or null if an error occurred.
  Future<Map<String, dynamic>?> generateSpeechStream(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateSpeechStream(
      _contextHandle,
      text,
      options,
    );
  }

  /// Generates speech as a stream for long text.
  ///
  /// Parameters:
  /// - [text]: Text to convert to speech.
  /// - [options]: Optional TTS options (sampleRate, voice, speed, saveToFile, outputFilePath).
  ///
  /// Returns:
  /// A map containing stream metadata, or null if an error occurred.
  Future<Map<String, dynamic>?> generateSpeechStreamForLongText(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance
        .generateSpeechStreamForLongText(_contextHandle, text, options);
  }

  /// Generates a completion asynchronously (runs in background thread)
  Future<CompletionResult?> generateCompletionAsync({
    required String prompt,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    List<String> stopSequences = const [],
    String? grammar,
    bool useJsonResponse = true,
    List<String>? mediaPaths,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      stopSequences: stopSequences,
      grammar: grammar,
      useJsonResponse: useJsonResponse,
      mediaPaths: mediaPaths ?? [],
    );
    return generateCompletionWithParamsAsync(params);
  }

  /// Generates a completion with CompletionParams asynchronously
  Future<CompletionResult?> generateCompletionWithParamsAsync(
    CompletionParams params,
  ) async {
    Map<String, dynamic>? result;
    if (params.mediaPaths.isNotEmpty) {
      // Use multimodal completion for media
      result = await LlamaMobileFlutterSdkPlatform.instance
          .generateMultimodalCompletionAsync(
            _contextHandle,
            params.toMap(),
            params.mediaPaths,
          );
    } else {
      // Use regular completion
      result = await LlamaMobileFlutterSdkPlatform.instance
          .generateCompletionAsync(_contextHandle, params.toMap());
    }
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Generates a multimodal completion asynchronously (runs in background thread)
  Future<CompletionResult?> generateMultimodalCompletionAsync({
    required String prompt,
    required List<String> mediaPaths,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    String? grammar,
    List<String>? stopSequences,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      grammar: grammar,
      stopSequences: stopSequences ?? [],
      mediaPaths: mediaPaths,
    );
    return generateMultimodalCompletionWithParamsAsync(params);
  }

  /// Generates a multimodal completion with CompletionParams asynchronously
  Future<CompletionResult?> generateMultimodalCompletionWithParamsAsync(
    CompletionParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateMultimodalCompletionAsync(
          _contextHandle,
          params.toMap(),
          params.mediaPaths ?? [],
        );
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Formats chat messages asynchronously (runs in background thread)
  Future<String?> formatChatMessagesAsync(
    List<ChatMessage> messages,
    String? chatTemplate,
  ) async {
    final messagesMap = messages.map((msg) => msg.toMap()).toList();
    return await LlamaMobileFlutterSdkPlatform.instance.formatChatMessagesAsync(
      _contextHandle,
      messagesMap,
      chatTemplate,
    );
  }

  /// Loads a TTS model asynchronously (runs in background thread)
  Future<bool> loadTTSModelAsync(
    String modelPath,
    TTSModelType modelType,
  ) async {
    final params = <String, dynamic>{
      'modelPath': modelPath,
      'modelType': modelType.rawValue,
    };
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .loadTTSModelAsync(_contextHandle, modelPath, params);
    return result?['success'] as bool? ?? false;
  }

  /// Frees the TTS model asynchronously (runs in background thread)
  Future<bool> freeTTSModelAsync() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeTTSModelAsync(
      _contextHandle,
    );
  }

  /// Loads a LoRA adapter asynchronously (runs in background thread)
  Future<bool> loadLoraAdapterAsync(String adapterPath, double scale) async {
    return await LlamaMobileFlutterSdkPlatform.instance.loadLoraAdapterAsync(
      _contextHandle,
      adapterPath,
      scale,
    );
  }

  /// Frees a LoRA adapter asynchronously (runs in background thread)
  Future<bool> freeLoraAdapterAsync() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeLoraAdapterAsync(
      _contextHandle,
    );
  }

  /// Removes all LoRA adapters asynchronously (runs in background thread)
  Future<void> removeLoraAdaptersAsync() async {
    await LlamaMobileFlutterSdkPlatform.instance.removeLoraAdaptersAsync(
      _contextHandle,
    );
  }

  /// Generates a streaming completion asynchronously (runs in background thread)
  Future<CompletionResult?> generateStreamingCompletionAsync({
    required String prompt,
    int maxTokens = 1024,
    int? nThreads,
    int seed = -1,
    double temperature = 0.8,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.1,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    String? grammar,
    List<String>? stopSequences,
  }) async {
    final params = CompletionParams(
      prompt: prompt,
      maxTokens: maxTokens,
      nThreads: nThreads,
      seed: seed,
      temperature: temperature,
      topK: topK,
      topP: topP,
      minP: minP,
      typicalP: typicalP,
      penaltyLastN: penaltyLastN,
      penaltyRepeat: penaltyRepeat,
      penaltyFreq: penaltyFreq,
      penaltyPresent: penaltyPresent,
      mirostat: mirostat,
      mirostatTau: mirostatTau,
      mirostatEta: mirostatEta,
      ignoreEos: ignoreEos,
      grammar: grammar,
      stopSequences: stopSequences ?? [],
    );
    return generateStreamingCompletionWithParamsAsync(params);
  }

  /// Generates a streaming completion with CompletionParams asynchronously
  Future<CompletionResult?> generateStreamingCompletionWithParamsAsync(
    CompletionParams params,
  ) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateStreamingCompletionAsync(_contextHandle, params.toMap());
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Generates a streaming OpenAI completion asynchronously (runs in background thread)
  Future<CompletionResult?> generateStreamingOpenAICompletionAsync({
    required String openAIJSON,
    String? grammar,
  }) async {
    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateStreamingOpenAICompletionAsync(
          _contextHandle,
          openAIJSON,
          grammar,
        );
    if (result != null) {
      return CompletionResult(
        text: result['text'] as String,
        tokensGenerated: result['tokensGenerated'] as int,
        tokensEvaluated: result['tokensEvaluated'] as int,
        truncated: result['truncated'] as bool,
        stoppedEos: result['stoppedEos'] as bool,
        stoppedWord: result['stoppedWord'] as bool,
        stoppedLimit: result['stoppedLimit'] as bool,
        stoppingWord: result['stoppingWord'] as String?,
      );
    }
    return null;
  }

  /// Initializes multimodal asynchronously (runs in background thread)
  Future<bool> initMultimodalAsync(String mmprojPath, bool useGpu) async {
    return await LlamaMobileFlutterSdkPlatform.instance.initMultimodalAsync(
      _contextHandle,
      mmprojPath,
      useGpu,
    );
  }

  /// Releases multimodal asynchronously (runs in background thread)
  Future<void> releaseMultimodalAsync() async {
    await LlamaMobileFlutterSdkPlatform.instance.releaseMultimodalAsync(
      _contextHandle,
    );
  }

  /// Initializes vocoder asynchronously (runs in background thread)
  Future<bool> initVocoderAsync(String vocoderModelPath) async {
    return await LlamaMobileFlutterSdkPlatform.instance.initVocoderAsync(
      _contextHandle,
      vocoderModelPath,
    );
  }

  /// Releases vocoder asynchronously (runs in background thread)
  Future<void> releaseVocoderAsync() async {
    await LlamaMobileFlutterSdkPlatform.instance.releaseVocoderAsync(
      _contextHandle,
    );
  }

  /// Generates speech asynchronously (runs in background thread)
  Future<Map<String, dynamic>?> generateSpeechAsync(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance.generateSpeechAsync(
      _contextHandle,
      text,
      options,
    );
  }

  /// Generates speech as a stream asynchronously (runs in background thread)
  Future<Map<String, dynamic>?> generateSpeechStreamAsync(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance
        .generateSpeechStreamAsync(_contextHandle, text, options);
  }

  /// Generates speech as a stream for long text asynchronously (runs in background thread)
  Future<Map<String, dynamic>?> generateSpeechStreamForLongTextAsync(
    String text, {
    Map<String, dynamic>? options,
  }) async {
    return await LlamaMobileFlutterSdkPlatform.instance
        .generateSpeechStreamForLongTextAsync(_contextHandle, text, options);
  }
}

/// Represents a chat message
class ChatMessage {
  final String role;
  final String content;
  final String? reasoningContent;
  final String? toolName;
  final String? toolCallId;

  ChatMessage({
    required this.role,
    required this.content,
    this.reasoningContent,
    this.toolName,
    this.toolCallId,
  });

  /// Converts to a map for platform channel communication
  Map<String, String?> toMap() {
    return {
      'role': role,
      'content': content,
      'reasoning_content': reasoningContent,
      'tool_name': toolName,
      'tool_call_id': toolCallId,
    };
  }

  /// Converts from a map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      content: map['content'] as String,
      reasoningContent: map['reasoning_content'] as String?,
      toolName: map['tool_name'] as String?,
      toolCallId: map['tool_call_id'] as String?,
    );
  }
}

/// TTS model types
enum TTSModelType {
  unknown,
  outETTSv02,
  outETTSv03;

  int get rawValue {
    switch (this) {
      case unknown:
        return -1;
      case outETTSv02:
        return 1;
      case outETTSv03:
        return 2;
    }
  }

  factory TTSModelType.fromRawValue(int value) {
    switch (value) {
      case 1:
        return outETTSv02;
      case 2:
        return outETTSv03;
      default:
        return unknown;
    }
  }
}

/// Result of a text completion
class CompletionResult {
  final String text;
  final int tokensGenerated;
  final int tokensEvaluated;
  final bool truncated;
  final bool stoppedEos;
  final bool stoppedWord;
  final bool stoppedLimit;
  final String? stoppingWord;

  CompletionResult({
    required this.text,
    required this.tokensGenerated,
    required this.tokensEvaluated,
    required this.truncated,
    required this.stoppedEos,
    required this.stoppedWord,
    required this.stoppedLimit,
    this.stoppingWord,
  });

  /// Creates from a map
  factory CompletionResult.fromMap(Map<String, dynamic> map) {
    return CompletionResult(
      text: map['text'] as String,
      tokensGenerated: map['tokensGenerated'] as int,
      tokensEvaluated: map['tokensEvaluated'] as int,
      truncated: map['truncated'] as bool,
      stoppedEos: map['stoppedEos'] as bool,
      stoppedWord: map['stoppedWord'] as bool,
      stoppedLimit: map['stoppedLimit'] as bool,
      stoppingWord: map['stoppingWord'] as String?,
    );
  }
}

/// Result of a conversation
class ConversationResult {
  final String text;
  final int timeToFirstToken;
  final int totalTime;
  final int tokensGenerated;

  ConversationResult({
    required this.text,
    required this.timeToFirstToken,
    required this.totalTime,
    required this.tokensGenerated,
  });

  /// Creates from a map
  factory ConversationResult.fromMap(Map<String, dynamic> map) {
    return ConversationResult(
      text: map['text'] as String,
      timeToFirstToken: map['timeToFirstToken'] as int,
      totalTime: map['totalTime'] as int,
      tokensGenerated: map['tokensGenerated'] as int,
    );
  }
}

/// Result of a download operation
class DownloadResult {
  final bool success;
  final String localPath;
  final String? errorMessage;

  DownloadResult({
    required this.success,
    required this.localPath,
    this.errorMessage,
  });
}

/// Result of an audio generation operation
class AudioResult {
  final List<int> audioData;

  AudioResult({required this.audioData});
}
