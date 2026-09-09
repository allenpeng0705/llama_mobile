// LlamaEngine.kt — llama_mobile v2 Android wrapper (M5)
//
// Threading contract (docs/api-contract-v2.md §8):
//   * Every heavy operation has a documented sync form (blocks the calling
//     thread — never call from the main/UI thread) and an async form that never
//     blocks the caller (CompletableFuture / coroutine helpers).
//   * One engine = one active generation; a second concurrent call fails with
//     LlamaException.ALREADY_RUNNING (-14).
//   * `abort()` is thread-safe and stops the running generation
//     (result stopReason == ABORTED).
//
// The v1 public API (LlamaMobile.java/Kt + v1 *_c ABI) was fully removed on the
// v2 branch (see docs/v1-purge-workplan.md). The JNI layer speaks only
// llama_mobile_v2.h.

package com.llamamobile

import java.util.concurrent.CompletableFuture
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.suspendCancellableCoroutine

/** v2 status codes (mirrors llama_mobile_status_t in llama_mobile_v2.h). */
enum class LlamaStatus(val code: Int) {
    OK(0),
    INVALID_ARGUMENT(-1),
    SAMPLER_INIT(-2),
    GENERATION(-3),
    MODEL_LOAD(-4),
    MODEL_NOT_FOUND(-5),
    IO(-6),
    UNSUPPORTED(-7),
    OUT_OF_MEMORY(-8),
    CONTEXT_FULL(-9),
    ABORTED(-10),
    NOT_INITIALIZED(-11),
    NETWORK(-12),
    CHECKSUM(-13),
    ALREADY_RUNNING(-14);

    companion object {
        fun from(code: Int): LlamaStatus =
            entries.firstOrNull { it.code == code } ?: GENERATION
    }
}

class LlamaException(val status: LlamaStatus, message: String?) : Exception(message ?: status.name) {
    val code: Int get() = status.code
    companion object {
        fun fromNative(statusCode: Int, context: String): LlamaException =
            LlamaException(LlamaStatus.from(statusCode), "$context (status $statusCode)")
    }
}

/** Called from the generation thread for each decoded token; return false to abort. */
fun interface TokenCallback {
    fun onToken(token: String): Boolean
}

/** Sampling options (defaults match llama_mobile_sampling_init). */
data class LlamaSampling(
    var seed: Long = -1,
    var temperature: Float = 0.8f,
    var topK: Int = 40,
    var topP: Float = 0.95f,
    var minP: Float = 0.05f,
    var typicalP: Float = 1.0f,
    var penaltyRepeat: Float = 1.1f,
    var penaltyLastN: Int = 64,
    var penaltyFreq: Float = 0f,
    var penaltyPresent: Float = 0f,
    var mirostat: Int = 0,
    var mirostatTau: Float = 5.0f,
    var mirostatEta: Float = 0.1f,
    var ignoreEos: Boolean = false,
)

data class LlamaChatMessage(val role: String, val content: String)

/** One generation request: exactly one of `prompt` or `messages` is used. */
data class LlamaGenerationRequest(
    var prompt: String? = null,
    var messages: List<LlamaChatMessage> = emptyList(),
    var mediaPaths: List<String> = emptyList(),
    var sampling: LlamaSampling = LlamaSampling(),
    var maxTokens: Int = 128,
    var stopSequences: List<String> = emptyList(),
    var grammar: String? = null,
    var jsonSchema: String? = null,
)

data class LlamaUsage(
    val promptTokens: Int,
    val generatedTokens: Int,
    val timeToFirstTokenMs: Long,
    val totalMs: Long,
)

data class LlamaTtsResult(
    val pcm: IntArray,
    val usage: LlamaUsage,
)

/** stopReason values mirror llama_mobile_stop_reason_t. */
enum class LlamaStopReason(val value: Int) {
    EOS(0), WORD(1), LENGTH(2), ABORTED(3), ERROR(4);
    companion object {
        fun from(v: Int): LlamaStopReason = entries.firstOrNull { it.value == v } ?: ERROR
    }
}

data class LlamaGenerationResult(
    val text: String,
    val stopReason: LlamaStopReason,
    val usage: LlamaUsage,
)

data class LlamaModelInfo(
    val nCtx: Int,
    val nEmbd: Int,
    val modelSizeBytes: Long,
    val nParams: Long,
    val description: String,
)

/**
 * v2 engine: one native context (one model). Modules (multimodal/TTS/LoRA) are
 * separate init calls on the same context (D4) and are exposed as they land in
 * the core; generation is single-flight per engine (§8).
 */
class LlamaEngine private constructor(private val handle: Long) : AutoCloseable {

    private val genExecutor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "llama-engine-v2").apply { isDaemon = true }
    }
    private val closed = AtomicBoolean(false)
    @Volatile private var lastRequestId: Long = 0

    val isOpen: Boolean get() = !closed.get() && handle != 0L

    // ------------------------------------------------------------------ config

    class Config {
        var modelPath: String = ""
        var engine: Int = 0            // 0=AUTO 1=CPU 2=METAL 3=VULKAN 4=OPENCL
        var nGpuLayers: Int = 0        // -1 = all, 0 = CPU
        var nCtx: Int = 2048           // 0 = model default
        var nBatch: Int = 512
        var nUBatch: Int = 512
        var nThreads: Int = 0          // 0 = auto
        var useMmap: Boolean = true
        var useMlock: Boolean = false
        var embedding: Boolean = false
        var flashAttention: Boolean = false
        var chat: Boolean = true       // enable chat template
        var kvCacheTypeK: String? = null
        var kvCacheTypeV: String? = null
        var chatTemplate: String? = null
        var systemPrompt: String? = null
        var imageMinTokens: Int = -1
    }

    companion object {
        /** Sync open — blocking model load; never call from the main thread. */
        @JvmStatic
        fun open(config: Config): LlamaEngine {
            require(config.modelPath.isNotEmpty()) { "modelPath is required" }
            val h = Native.create(
                config.modelPath, config.chatTemplate, config.systemPrompt,
                config.nCtx, config.nBatch, config.nUBatch, config.nThreads,
                config.nGpuLayers, config.useMmap, config.useMlock,
                config.embedding, config.flashAttention, config.chat,
                config.kvCacheTypeK, config.kvCacheTypeV, config.imageMinTokens,
            )
            if (h == 0L) throw LlamaException.fromNative(Native.lastError(), "model load failed")
            return LlamaEngine(h)
        }

        /** Async open — never blocks the caller. */
        @JvmStatic
        fun openAsync(config: Config): CompletableFuture<LlamaEngine> =
            CompletableFuture.supplyAsync { open(config) }

        @JvmStatic
        fun libraryVersion(): String = Native.version()
    }

    // ------------------------------------------------------------------ generate

    /**
     * Sync generate — blocks the calling thread; never call from the main
     * thread. `tokenCallback` (optional) is invoked on the calling thread per
     * token; returning false aborts the generation.
     */
    fun generate(request: LlamaGenerationRequest, tokenCallback: TokenCallback? = null): LlamaGenerationResult {
        ensureOpen()
        val prompt = request.prompt
        val roles = request.messages.map { it.role }.toTypedArray()
        val contents = request.messages.map { it.content }.toTypedArray()
        val s = request.sampling
        val meta = LongArray(4) // [requestId, stopReason, promptTokens, generatedTokens]
        val text = Native.generate(
            handle,
            prompt, roles, contents,
            s.seed, s.temperature, s.topK, s.topP, s.minP, s.typicalP,
            s.penaltyRepeat, s.penaltyLastN, s.penaltyFreq, s.penaltyPresent,
            s.mirostat, s.mirostatTau, s.mirostatEta, s.ignoreEos,
            request.maxTokens,
            request.stopSequences.toTypedArray(), request.grammar, request.jsonSchema,
            request.mediaPaths.toTypedArray(),
            tokenCallback, meta,
        )
        if (text == null) throw LlamaException.fromNative(Native.lastError(), "generate failed")
        lastRequestId = meta[0]
        return LlamaGenerationResult(
            text = text,
            stopReason = LlamaStopReason.from(meta[1].toInt()),
            usage = LlamaUsage(meta[2].toInt(), meta[3].toInt(), 0L, 0L),
        )
    }

    /** Async generate — never blocks the caller (engine-internal executor). */
    fun generateAsync(
        request: LlamaGenerationRequest,
        tokenCallback: TokenCallback? = null,
    ): CompletableFuture<LlamaGenerationResult> =
        CompletableFuture.supplyAsync({ generate(request, tokenCallback) }, genExecutor)

    /** Coroutine form: suspends without blocking the calling thread. */
    suspend fun generateSuspend(
        request: LlamaGenerationRequest,
        tokenCallback: TokenCallback? = null,
    ): LlamaGenerationResult = suspendCancellableCoroutine { cont ->
        val f = generateAsync(request, tokenCallback)
        f.whenComplete { r, e ->
            if (e != null) cont.resumeWithException(e)
            else cont.resume(r)
        }
        cont.invokeOnCancellation { f.cancel(true) }
    }

    /** Attaches a multimodal projector (mmproj) to this engine. */
    fun initMultimodal(mmprojPath: String): Boolean {
        ensureOpen()
        return Native.initMultimodal(handle, mmprojPath)
    }

    /** Detaches the multimodal projector. */
    fun releaseMultimodal(): Boolean {
        if (!ensureOpenSafe()) return false
        return Native.releaseMultimodal(handle)
    }

    fun multimodalEnabled(): Boolean =
        ensureOpenSafe() && Native.multimodalEnabled(handle)

    fun supportsVision(): Boolean =
        ensureOpenSafe() && Native.supportsVision(handle)

    fun supportsAudio(): Boolean =
        ensureOpenSafe() && Native.supportsAudio(handle)

    /** Attaches a vocoder so [ttsSpeak] can synthesize audio. */
    fun ttsInit(vocoderPath: String): Boolean {
        if (!ensureOpenSafe()) return false
        return Native.ttsInit(handle, vocoderPath)
    }

    fun ttsEnabled(): Boolean =
        ensureOpenSafe() && Native.ttsEnabled(handle)

    /** Full-text synthesis -> 16-bit PCM samples (caller-owned copy). */
    fun ttsSpeak(
        text: String,
        sampleRate: Int = 24000,
        speed: Float = 1.0f,
        speaker: String? = null,
    ): LlamaTtsResult {
        ensureOpen()
        val meta = LongArray(4)
        val pcm = Native.ttsSpeak(handle, text, sampleRate, speed, speaker, meta)
            ?: throw LlamaException.fromNative(Native.lastError(), "tts speak failed")
        return LlamaTtsResult(
            pcm = pcm,
            usage = LlamaUsage(meta[0].toInt(), meta[1].toInt(), meta[2], meta[3]),
        )
    }

    fun ttsRelease(): Boolean {
        if (!ensureOpenSafe()) return false
        return Native.ttsRelease(handle)
    }

    /** Thread-safe abort of the currently running generation. */
    fun abort(): Boolean {
        if (closed.get() || handle == 0L) return false
        return Native.abort(handle)
    }

    /** Id of the most recently finished generation (0 = none yet). */
    fun lastRequestId(): Long = lastRequestId

    // ------------------------------------------------------------------ info / tokens

    fun modelInfo(): LlamaModelInfo {
        ensureOpen()
        val arr = Native.modelInfo(handle) ?: return LlamaModelInfo(0, 0, 0, 0, "")
        val desc = Native.modelDesc(handle) ?: ""
        return LlamaModelInfo(
            nCtx = arr[0].toInt(), nEmbd = arr[1].toInt(),
            modelSizeBytes = arr[2], nParams = arr[3], description = desc,
        )
    }

    fun tokenize(text: String): IntArray {
        ensureOpen()
        return Native.tokenize(handle, text) ?: IntArray(0)
    }

    fun detokenize(tokens: IntArray): String {
        ensureOpen()
        return Native.detokenize(handle, tokens) ?: ""
    }

    /** Batch embeddings; requires the context to be opened with `embedding = true`. */
    fun embed(texts: List<String>): List<FloatArray> {
        ensureOpen()
        val rows = Native.embed(handle, texts.toTypedArray()) ?: return emptyList()
        return rows.toList()
    }

    // ------------------------------------------------------------------ lifecycle

    override fun close() {
        if (closed.compareAndSet(false, true)) {
            genExecutor.shutdownNow()
            if (handle != 0L) Native.destroy(handle)
        }
    }

    private fun ensureOpen() {
        check(isOpen) { "engine is closed" }
    }

    private fun ensureOpenSafe(): Boolean = isOpen
}

/** JNI bridge to the v2 C API (llama_mobile_v2.h). Loads libllama_mobile_jni. */
private object Native {
    init {
        System.loadLibrary("llama_mobile_jni")
    }

    external fun version(): String
    external fun lastError(): Int
    external fun create(
        modelPath: String?, chatTemplate: String?, systemPrompt: String?,
        nCtx: Int, nBatch: Int, nUBatch: Int, nThreads: Int, nGpuLayers: Int,
        useMmap: Boolean, useMlock: Boolean, embedding: Boolean,
        flashAttention: Boolean, chat: Boolean,
        cacheTypeK: String?, cacheTypeV: String?, imageMinTokens: Int,
    ): Long
    external fun destroy(ctx: Long)
    external fun modelInfo(ctx: Long): LongArray?
    external fun modelDesc(ctx: Long): String?
    external fun initMultimodal(ctx: Long, mmprojPath: String): Boolean
    external fun generate(
        ctx: Long,
        prompt: String?, roles: Array<String>?, contents: Array<String>?,
        seed: Long, temperature: Float, topK: Int, topP: Float, minP: Float,
        typicalP: Float, penaltyRepeat: Float, penaltyLastN: Int,
        penaltyFreq: Float, penaltyPresent: Float,
        mirostat: Int, mirostatTau: Float, mirostatEta: Float, ignoreEos: Boolean,
        maxTokens: Int,
        stopSequences: Array<String>?, grammar: String?, jsonSchema: String?,
        mediaPaths: Array<String>?,
        tokenCallback: TokenCallback?, meta: LongArray,
    ): String?
    external fun abort(ctx: Long): Boolean
    external fun tokenize(ctx: Long, text: String): IntArray?
    external fun detokenize(ctx: Long, tokens: IntArray): String?
    external fun embed(ctx: Long, texts: Array<String>): Array<FloatArray>?
    external fun releaseMultimodal(ctx: Long): Boolean
    external fun multimodalEnabled(ctx: Long): Boolean
    external fun supportsVision(ctx: Long): Boolean
    external fun supportsAudio(ctx: Long): Boolean
    external fun ttsInit(ctx: Long, vocoderPath: String): Boolean
    external fun ttsRelease(ctx: Long): Boolean
    external fun ttsEnabled(ctx: Long): Boolean
    external fun ttsSpeak(
        ctx: Long, text: String, sampleRate: Int, speed: Float,
        speaker: String?, meta: LongArray,
    ): IntArray?
}
