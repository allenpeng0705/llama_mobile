import 'dart:convert';
import 'llama_mobile_flutter_sdk_platform_interface.dart';

/// Main entry point for the LlamaMobile Flutter SDK.
///
/// This class provides methods to initialize contexts, download models, and interact with
/// the LlamaMobile platform implementation.
class LlamaMobile {
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
  }) async {
    final params = {
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
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance.initContext(
      params,
    );
    if (result != null && result.containsKey('contextHandle')) {
      final contextHandle = result['contextHandle'] as int;
      return LlamaContext._internal(contextHandle, this);
    }
    return null;
  }

  /// Downloads a model from a URL
  Future<DownloadResult?> downloadModel({
    required String url,
    required String localPath,
    String? username,
    String? password,
    Map<String, String>? headers,
  }) async {
    final params = {
      'url': url,
      'localPath': localPath,
      'username': username,
      'password': password,
      'headers': headers,
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance.downloadModel(
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
}

/// Represents a LlamaMobile context
class LlamaContext {
  final int _contextHandle;
  final LlamaMobile _parent;

  LlamaContext._internal(this._contextHandle, this._parent);

  /// Gets the context handle
  int get handle => _contextHandle;

  /// Frees the context
  Future<bool> free() async {
    return await LlamaMobileFlutterSdkPlatform.instance.freeContext(
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

  /// Sets the chat template
  Future<bool> setChatTemplate(String? template) async {
    return await LlamaMobileFlutterSdkPlatform.instance.setChatTemplate(
      _contextHandle,
      template,
    );
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
  /// - [chatTemplate]: Custom chat template for this completion.
  Future<CompletionResult?> generateCompletion({
    required String prompt,
    int maxTokens = 128,
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
    bool useJsonResponse = false,
    String? chatTemplate,
  }) async {
    final params = {
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
      'chatTemplate': chatTemplate,
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateCompletion(_contextHandle, params);
    if (result != null) {
      return CompletionResult.fromMap(result);
    }
    return null;
  }

  /// Generates a multimodal completion
  Future<CompletionResult?> generateMultimodalCompletion({
    required String prompt,
    required List<String> mediaPaths,
    int maxTokens = 128,
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
    bool useJsonResponse = false,
    String? chatTemplate,
  }) async {
    final params = {
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
      'chatTemplate': chatTemplate,
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateMultimodalCompletion(_contextHandle, params, mediaPaths);
    if (result != null) {
      return CompletionResult.fromMap(result);
    }
    return null;
  }

  /// Generates a conversation response based on the given chat history.
  ///
  /// Parameters:
  /// - [chatMessages]: List of chat messages representing the conversation history.
  /// - [maxTokens]: Maximum number of tokens to generate in the response.
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
  /// - [chatTemplate]: Custom chat template for formatting the conversation.
  Future<ConversationResult?> generateConversation({
    required List<ChatMessage> chatMessages,
    int maxTokens = 256,
    int? nThreads,
    int seed = -1,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    double minP = 0.05,
    double typicalP = 1.0,
    int penaltyLastN = 64,
    double penaltyRepeat = 1.2,
    double penaltyFreq = 0.0,
    double penaltyPresent = 0.0,
    int mirostat = 0,
    double mirostatTau = 5.0,
    double mirostatEta = 0.1,
    bool ignoreEos = false,
    List<String> stopSequences = const [],
    String? grammar,
    bool useJsonResponse = false,
    String? chatTemplate,
  }) async {
    final messagesJson = chatMessages.map((msg) => msg.toMap()).toList();
    final params = {
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
      'chatTemplate': chatTemplate,
    };

    final result = await LlamaMobileFlutterSdkPlatform.instance
        .generateConversation(_contextHandle, params, messagesJson);
    if (result != null) {
      return ConversationResult.fromMap(result);
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

  /// Loads a built-in grammar file to constrain model output to specific formats.
  ///
  /// Available grammar files:
  /// - `json` - Valid JSON objects and values
  /// - `json_arr` - Valid JSON arrays
  /// - `arithmetic` - Arithmetic expressions
  /// - `c` - C programming language syntax
  /// - `chess` - Chess moves notation
  /// - `english` - English language bias
  /// - `japanese` - Japanese language bias
  /// - `list` - Structured lists
  ///
  /// Parameters:
  /// - [grammarName]: Name of the grammar file (without extension).
  Future<String?> loadGrammar(String grammarName) async {
    return await LlamaMobileFlutterSdkPlatform.instance.loadGrammar(
      _contextHandle,
      grammarName,
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
  Future<AudioResult?> generateAudio(String text) async {
    print(
      "[DEBUG] Dart LlamaContext: generateAudio called - text: $text, contextHandle: $_contextHandle",
    );

    try {
      final result = await LlamaMobileFlutterSdkPlatform.instance.generateAudio(
        _contextHandle,
        text,
      );

      print(
        "[DEBUG] Dart LlamaContext: generateAudio result received: $result",
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
      print("[DEBUG] Dart LlamaContext: Error in generateAudio: $e");
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
}

/// Represents a chat message
class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  /// Converts to a map for platform channel communication
  Map<String, String> toMap() {
    return {'role': role, 'content': content};
  }

  /// Converts from a map
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      content: map['content'] as String,
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
