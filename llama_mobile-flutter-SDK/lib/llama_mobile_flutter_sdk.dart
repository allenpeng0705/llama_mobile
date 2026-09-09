// llama_mobile_flutter_sdk.dart — llama_mobile v2 Flutter wrapper (M6)
//
// Threading contract (docs/api-contract-v2.md §8): Dart is async-first, so the
// API below never blocks the UI isolate; every call is a Future. The native
// side enforces one active generation per engine (single-flight); a second
// concurrent generate throws LlamaException.alreadyRunning. `abort()` is
// thread-safe on the platform side and stops the running generation
// (result.stopReason == LlamaStopReason.aborted).
//
// The v1 Dart surface was removed with the rest of the v1 API on the v2 branch
// (see docs/v1-purge-workplan.md). This file talks to the platform plugins over
// the method channel `llama_mobile_flutter_sdk/v2`.

import 'package:flutter/services.dart';

/// v2 status codes (mirrors llama_mobile_status_t).
enum LlamaStatus {
  ok(0),
  invalidArgument(-1),
  samplerInit(-2),
  generation(-3),
  modelLoad(-4),
  modelNotFound(-5),
  io(-6),
  unsupported(-7),
  outOfMemory(-8),
  contextFull(-9),
  aborted(-10),
  notInitialized(-11),
  network(-12),
  checksum(-13),
  alreadyRunning(-14);

  final int code;
  const LlamaStatus(this.code);

  static LlamaStatus fromCode(int code) {
    for (final s in LlamaStatus.values) {
      if (s.code == code) return s;
    }
    return LlamaStatus.generation;
  }
}

class LlamaException implements Exception {
  final LlamaStatus status;
  final String message;
  LlamaException(this.status, this.message);

  factory LlamaException.fromNative(int code, String context) =>
      LlamaException(LlamaStatus.fromCode(code), '$context (status $code)');

  @override
  String toString() => 'LlamaException(${status.name}): $message';
}

/// Sampling options (defaults match llama_mobile_sampling_init).
class LlamaSampling {
  int seed = -1;
  double temperature = 0.8;
  int topK = 40;
  double topP = 0.95;
  double minP = 0.05;
  double typicalP = 1.0;
  double penaltyRepeat = 1.1;
  int penaltyLastN = 64;
  double penaltyFreq = 0;
  double penaltyPresent = 0;
  int mirostat = 0;
  double mirostatTau = 5.0;
  double mirostatEta = 0.1;
  bool ignoreEos = false;

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
        'minP': minP,
        'typicalP': typicalP,
        'penaltyRepeat': penaltyRepeat,
        'penaltyLastN': penaltyLastN,
        'penaltyFreq': penaltyFreq,
        'penaltyPresent': penaltyPresent,
        'mirostat': mirostat,
        'mirostatTau': mirostatTau,
        'mirostatEta': mirostatEta,
        'ignoreEos': ignoreEos,
      };
}

class LlamaChatMessage {
  final String role;
  final String content;
  const LlamaChatMessage(this.role, this.content);
}

/// One generation request: exactly one of [prompt] or [messages] is used.
class LlamaGenerationRequest {
  String? prompt;
  List<LlamaChatMessage> messages;
  List<String> mediaPaths;
  LlamaSampling sampling;
  int maxTokens;
  List<String> stopSequences;
  String? grammar;
  String? jsonSchema;

  LlamaGenerationRequest({
    this.prompt,
    List<LlamaChatMessage>? messages,
    List<String>? mediaPaths,
    LlamaSampling? sampling,
    this.maxTokens = 128,
    List<String>? stopSequences,
    this.grammar,
    this.jsonSchema,
  })  : messages = messages ?? const [],
        mediaPaths = mediaPaths ?? const [],
        sampling = sampling ?? LlamaSampling(),
        stopSequences = stopSequences ?? const [];

  Map<String, dynamic> toJson() => {
        if (prompt != null && prompt!.isNotEmpty) 'prompt': prompt,
        'roles': messages.map((m) => m.role).toList(),
        'contents': messages.map((m) => m.content).toList(),
        'mediaPaths': mediaPaths,
        'sampling': sampling.toJson(),
        'maxTokens': maxTokens,
        'stopSequences': stopSequences,
        'grammar': grammar,
        'jsonSchema': jsonSchema,
      };
}

/// stopReason values mirror llama_mobile_stop_reason_t.
enum LlamaStopReason {
  eos(0),
  word(1),
  length(2),
  aborted(3),
  error(4);

  final int value;
  const LlamaStopReason(this.value);
}

LlamaStopReason _stopFrom(int v) {
  for (final r in LlamaStopReason.values) {
    if (r.value == v) return r;
  }
  return LlamaStopReason.error;
}

class LlamaUsage {
  final int promptTokens;
  final int generatedTokens;
  final int timeToFirstTokenMs;
  final int totalMs;
  const LlamaUsage(this.promptTokens, this.generatedTokens,
      this.timeToFirstTokenMs, this.totalMs);
}

class LlamaGenerationResult {
  final String text;
  final LlamaStopReason stopReason;
  final LlamaUsage usage;
  const LlamaGenerationResult(this.text, this.stopReason, this.usage);
}

class LlamaModelInfo {
  final int nCtx;
  final int nEmbd;
  final int modelSizeBytes;
  final int nParams;
  final String description;
  const LlamaModelInfo(this.nCtx, this.nEmbd, this.modelSizeBytes, this.nParams,
      this.description);
}

/// Configuration for [LlamaEngine.open] / [LlamaEngine.openAsync].
class LlamaEngineConfig {
  String modelPath;
  int engine = 0; // 0=AUTO 1=CPU 2=METAL 3=VULKAN 4=OPENCL
  int nGpuLayers = 0;
  int nCtx = 2048;
  int nBatch = 512;
  int nUBatch = 512;
  int nThreads = 0;
  bool useMmap = true;
  bool useMlock = false;
  bool embedding = false;
  bool flashAttention = false;
  bool chat = true;
  String? kvCacheTypeK;
  String? kvCacheTypeV;
  String? chatTemplate;
  String? systemPrompt;

  LlamaEngineConfig({required this.modelPath});

  Map<String, dynamic> toJson() => {
        'modelPath': modelPath,
        'engine': engine,
        'nGpuLayers': nGpuLayers,
        'nCtx': nCtx,
        'nBatch': nBatch,
        'nUBatch': nUBatch,
        'nThreads': nThreads,
        'useMmap': useMmap,
        'useMlock': useMlock,
        'embedding': embedding,
        'flashAttention': flashAttention,
        'chat': chat,
        'kvCacheTypeK': kvCacheTypeK,
        'kvCacheTypeV': kvCacheTypeV,
        'chatTemplate': chatTemplate,
        'systemPrompt': systemPrompt,
      };
}

/// v2 engine: one native context (one model). Generation is single-flight.
class LlamaEngine {
  final int _handle;
  LlamaEngine._(this._handle);


  static const MethodChannel _channel =
      MethodChannel('llama_mobile_flutter_sdk/v2');

  static Future<dynamic> _invoke(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<dynamic>(method, args);
    } on PlatformException catch (e) {
      throw LlamaException.fromNative(int.tryParse(e.code) ?? -3,
          e.message ?? method);
    }
  }

  /// Library version reported by the native side.
  static Future<String> libraryVersion() async {
    final String? v = await _channel.invokeMethod<String>('version');
    return v ?? '';
  }

  /// Opens (loads) a model context. This is an async platform call and never
  /// blocks the UI isolate, but model loading can take seconds.
  static Future<LlamaEngine> open(LlamaEngineConfig config) async {
    final handle = await _invoke('open', config.toJson()) as int?;
    if (handle == null || handle == 0) {
      throw LlamaException(LlamaStatus.modelLoad, 'model load failed');
    }
    return LlamaEngine._(handle);
  }

  /// Sync-style alias kept for parity with the other wrappers: on Dart this is
  /// the same async call (Dart is async-only per §8).
  static Future<LlamaEngine> openAsync(LlamaEngineConfig config) => open(config);

  /// One generation. Never blocks the UI isolate. Throws
  /// [LlamaException.alreadyRunning] if another generation is active.
  Future<LlamaGenerationResult> generate(LlamaGenerationRequest request) async {
    final res = (await _invoke('generate', {
      'handle': _handle,
      'request': request.toJson(),
    })) as Map<dynamic, dynamic>?;
    if (res == null) {
      throw LlamaException(LlamaStatus.generation, 'generate failed');
    }
    return LlamaGenerationResult(
      (res['text'] as String?) ?? '',
      _stopFrom((res['stopReason'] as num?)?.toInt() ?? 4),
      LlamaUsage(
        (res['promptTokens'] as num?)?.toInt() ?? 0,
        (res['generatedTokens'] as num?)?.toInt() ?? 0,
        0,
        0,
      ),
    );
  }

  /// Tokenizes text with the model's vocabulary (no special tokens).
  Future<List<int>> tokenize(String text) async {
    final raw = (await _invoke('tokenize', {
      'handle': _handle,
      'text': text,
    })) as List?;
    return raw?.map((e) => (e as num).toInt()).toList() ?? const [];
  }

  /// Decodes token ids back to text.
  Future<String> detokenize(List<int> tokens) async =>
      (await _invoke('detokenize', {
        'handle': _handle,
        'tokens': tokens,
      })) as String? ?? '';

  /// Batch embeddings (one row per text). Requires opening the context with
  /// `embedding = true`.
  Future<List<List<double>>> embed(List<String> texts) async {
    final raw = (await _invoke('embed', {
      'handle': _handle,
      'texts': texts,
    })) as List?;
    return raw?.map((row) => (row as List)
            .map((v) => (v as num).toDouble())
            .toList())
        .toList() ??
        const [];
  }

  /// Attaches a multimodal projector (mmproj) so later generations can include
  /// image paths in `LlamaGenerationRequest.mediaPaths`.
  Future<bool> initMultimodal(String mmprojPath) async {
    final ok = await _invoke('initMultimodal', {
      'handle': _handle,
      'mmprojPath': mmprojPath,
    }) as bool?;
    return ok == true;
  }

  /// Thread-safe: stops the currently running generation on the native side.
  Future<bool> abort() async {
    final bool? ok = await _channel.invokeMethod<bool>('abort', {'handle': _handle});
    return ok == true;
  }

  Future<LlamaModelInfo> modelInfo() async {
    final res = (await _invoke('modelInfo', {'handle': _handle}))
        as Map<dynamic, dynamic>?;
    if (res == null) {
      throw LlamaException(LlamaStatus.notInitialized, 'modelInfo failed');
    }
    return LlamaModelInfo(
      (res['nCtx'] as num?)?.toInt() ?? 0,
      (res['nEmbd'] as num?)?.toInt() ?? 0,
      (res['modelSizeBytes'] as num?)?.toInt() ?? 0,
      (res['nParams'] as num?)?.toInt() ?? 0,
      (res['description'] as String?) ?? '',
    );
  }

  Future<void> close() async {
    await _channel.invokeMethod<void>('close', {'handle': _handle});
  }

  /// Detaches the multimodal projector (mmproj).
  Future<bool> releaseMultimodal() async =>
      (await _invoke('releaseMultimodal', {'handle': _handle})) as bool? ?? false;

  Future<bool> multimodalEnabled() async =>
      (await _invoke('multimodalEnabled', {'handle': _handle})) as bool? ?? false;

  Future<bool> supportsVision() async =>
      (await _invoke('supportsVision', {'handle': _handle})) as bool? ?? false;

  Future<bool> supportsAudio() async =>
      (await _invoke('supportsAudio', {'handle': _handle})) as bool? ?? false;

  /// Attaches a vocoder so [ttsSpeak] can synthesize audio.
  Future<bool> ttsInit(String vocoderPath) async =>
      (await _invoke('ttsInit', {'handle': _handle, 'vocoderPath': vocoderPath})) as bool? ?? false;

  Future<bool> ttsEnabled() async =>
      (await _invoke('ttsEnabled', {'handle': _handle})) as bool? ?? false;

  /// Full-text synthesis -> 16-bit PCM samples (as a List<int>).
  Future<List<int>> ttsSpeak(
    String text, {
    int sampleRate = 24000,
    double speed = 1.0,
  }) async {
    final raw = (await _invoke('ttsSpeak', {
      'handle': _handle,
      'text': text,
      'sampleRate': sampleRate,
      'speed': speed,
    })) as List?;
    return raw?.map((e) => (e as num).toInt()).toList() ?? const [];
  }

  Future<bool> ttsRelease() async =>
      (await _invoke('ttsRelease', {'handle': _handle})) as bool? ?? false;
}
