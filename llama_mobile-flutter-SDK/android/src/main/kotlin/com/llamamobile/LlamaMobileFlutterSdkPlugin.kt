// LlamaMobileFlutterSdkPlugin.kt — Flutter Android plugin (v2, M6)
//
// Implements the `llama_mobile_flutter_sdk/v2` method channel verbs used by the
// Dart LlamaEngine wrapper. All heavy operations (open/generate/modelInfo) run
// on a background executor and answer on the platform thread; abort() is
// thread-safe and may be called while a generation is running (§8).

package com.llamamobile

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class LlamaMobileFlutterSdkPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val main = Handler(Looper.getMainLooper())
    private val bg = Executors.newSingleThreadExecutor { r ->
        Thread(r, "llama-flutter-engine").apply { isDaemon = true }
    }

    private val engines = mutableMapOf<Int, LlamaEngine>()
    private var nextHandle = 1

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "llama_mobile_flutter_sdk/v2")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        engines.values.forEach { it.close() }
        engines.clear()
        bg.shutdownNow()
    }

    private fun onMain(run: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) run() else main.post { run() }
    }

    private fun fail(result: Result, status: LlamaStatus, message: String) {
        onMain { result.error(status.code.toString(), message, null) }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "version" -> {
                onMain { result.success(LlamaEngine.libraryVersion()) }
            }
            "open" -> handleOpen(call, result)
            "generate" -> handleGenerate(call, result)
            "initMultimodal" -> handleInitMultimodal(call, result)
            "tokenize" -> handleTokenize(call, result)
            "detokenize" -> handleDetokenize(call, result)
            "embed" -> handleEmbed(call, result)
            "abort" -> handleAbort(call, result)
            "modelInfo" -> handleModelInfo(call, result)
            "close" -> handleClose(call, result)
            else -> fail(result, LlamaStatus.UNSUPPORTED, "Unknown method ${call.method}")
        }
    }

    // --------------------------------------------------------------- open

    private fun handleOpen(call: MethodCall, result: Result) {
        val cfg = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "config map required"); return
        }
        val config = LlamaEngine.Config().apply {
            modelPath = cfg["modelPath"] as? String ?: ""
            engine = (cfg["engine"] as? Number)?.toInt() ?: 0
            nGpuLayers = (cfg["nGpuLayers"] as? Number)?.toInt() ?: 0
            nCtx = (cfg["nCtx"] as? Number)?.toInt() ?: 2048
            nBatch = (cfg["nBatch"] as? Number)?.toInt() ?: 512
            nUBatch = (cfg["nUBatch"] as? Number)?.toInt() ?: 512
            nThreads = (cfg["nThreads"] as? Number)?.toInt() ?: 0
            useMmap = cfg["useMmap"] as? Boolean ?: true
            useMlock = cfg["useMlock"] as? Boolean ?: false
            embedding = cfg["embedding"] as? Boolean ?: false
            flashAttention = cfg["flashAttention"] as? Boolean ?: false
            chat = cfg["chat"] as? Boolean ?: true
            kvCacheTypeK = cfg["kvCacheTypeK"] as? String
            kvCacheTypeV = cfg["kvCacheTypeV"] as? String
            chatTemplate = cfg["chatTemplate"] as? String
            systemPrompt = cfg["systemPrompt"] as? String
        }
        bg.execute {
            try {
                val engine = LlamaEngine.open(config)
                val handle: Int
                synchronized(engines) {
                    handle = nextHandle++
                    engines[handle] = engine
                }
                onMain { result.success(handle) }
            } catch (e: LlamaException) {
                fail(result, e.status, e.message ?: "open failed")
            } catch (e: Throwable) {
                fail(result, LlamaStatus.MODEL_LOAD, e.message ?: "open failed")
            }
        }
    }

    // ------------------------------------------------------------ generate

    private fun handleGenerate(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "handle required"); return
        }
        val reqMap = args["request"] as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "request required"); return
        }
        val engine = synchronized(engines) { engines[handle] } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }

        val request = parseRequest(reqMap)
        bg.execute {
            try {
                val res = engine.generate(request)
                onMain {
                    result.success(
                        mapOf(
                            "text" to res.text,
                            "stopReason" to res.stopReason.value,
                            "promptTokens" to res.usage.promptTokens,
                            "generatedTokens" to res.usage.generatedTokens,
                        ),
                    )
                }
            } catch (e: LlamaException) {
                fail(result, e.status, e.message ?: "generate failed")
            } catch (e: Throwable) {
                fail(result, LlamaStatus.GENERATION, e.message ?: "generate failed")
            }
        }
    }

    private fun parseRequest(m: Map<*, *>): LlamaGenerationRequest {
        val sampling = (m["sampling"] as? Map<*, *>) ?: emptyMap<Any?, Any?>()
        val req = LlamaGenerationRequest(
            prompt = m["prompt"] as? String,
            maxTokens = (m["maxTokens"] as? Number)?.toInt() ?: 128,
            grammar = m["grammar"] as? String,
            jsonSchema = m["jsonSchema"] as? String,
        )
        val roles = m["roles"] as? List<*> ?: emptyList<Any?>()
        val contents = m["contents"] as? List<*> ?: emptyList<Any?>()
        if (roles.isNotEmpty() && roles.size == contents.size) {
            req.messages = roles.indices.map { i ->
                LlamaChatMessage(roles[i] as? String ?: "", contents[i] as? String ?: "")
            }
        }
        req.stopSequences = (m["stopSequences"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
        req.mediaPaths = (m["mediaPaths"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
        req.sampling = LlamaSampling(
            seed = (sampling["seed"] as? Number)?.toLong() ?: -1,
            temperature = (sampling["temperature"] as? Number)?.toFloat() ?: 0.8f,
            topK = (sampling["topK"] as? Number)?.toInt() ?: 40,
            topP = (sampling["topP"] as? Number)?.toFloat() ?: 0.95f,
            minP = (sampling["minP"] as? Number)?.toFloat() ?: 0.05f,
            typicalP = (sampling["typicalP"] as? Number)?.toFloat() ?: 1.0f,
            penaltyRepeat = (sampling["penaltyRepeat"] as? Number)?.toFloat() ?: 1.1f,
            penaltyLastN = (sampling["penaltyLastN"] as? Number)?.toInt() ?: 64,
            penaltyFreq = (sampling["penaltyFreq"] as? Number)?.toFloat() ?: 0f,
            penaltyPresent = (sampling["penaltyPresent"] as? Number)?.toFloat() ?: 0f,
            mirostat = (sampling["mirostat"] as? Number)?.toInt() ?: 0,
            mirostatTau = (sampling["mirostatTau"] as? Number)?.toFloat() ?: 5.0f,
            mirostatEta = (sampling["mirostatEta"] as? Number)?.toFloat() ?: 0.1f,
            ignoreEos = sampling["ignoreEos"] as? Boolean ?: false,
        )
        return req
    }


    // ------------------------------------------------------------ multimodal

    private fun handleInitMultimodal(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "handle required"); return
        }
        val mmproj = args["mmprojPath"] as? String ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "mmprojPath required"); return
        }
        val engine = synchronized(engines) { engines[handle] } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }
        bg.execute {
            try {
                val ok = engine.initMultimodal(mmproj)
                onMain { result.success(ok) }
            } catch (e: Throwable) {
                fail(result, LlamaStatus.MODEL_LOAD, e.message ?: "initMultimodal failed")
            }
        }
    }

    // -------------------------------------------------- tokenize/detokenize/embed

    private fun handleTokenize(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "handle required"); return
        }
        val text = args["text"] as? String ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "text required"); return
        }
        val engine = synchronized(engines) { engines[handle] } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }
        bg.execute {
            try {
                val tokens = engine.tokenize(text)
                onMain { result.success(tokens.toList()) }
            } catch (e: Throwable) {
                fail(result, LlamaStatus.GENERATION, e.message ?: "tokenize failed")
            }
        }
    }

    private fun handleDetokenize(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "handle required"); return
        }
        val tokens = (args["tokens"] as? List<*>)?.mapNotNull { (it as? Number)?.toInt() } ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "tokens required"); return
        }
        val engine = synchronized(engines) { engines[handle] } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }
        bg.execute {
            try {
                val text = engine.detokenize(tokens.toIntArray())
                onMain { result.success(text) }
            } catch (e: Throwable) {
                fail(result, LlamaStatus.GENERATION, e.message ?: "detokenize failed")
            }
        }
    }

    private fun handleEmbed(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "handle required"); return
        }
        val texts = (args["texts"] as? List<*>)?.filterIsInstance<String>() ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "texts required"); return
        }
        val engine = synchronized(engines) { engines[handle] } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }
        bg.execute {
            try {
                val rows = engine.embed(texts).map { row -> row.map { it.toDouble() } }
                onMain { result.success(rows) }
            } catch (e: Throwable) {
                fail(result, LlamaStatus.GENERATION, e.message ?: "embed failed")
            }
        }
    }

    // ------------------------------------------------------------- abort/info

    private fun handleAbort(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt()
        val engine = handle?.let { synchronized(engines) { engines[it] } }
        if (engine == null) {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle")
            return
        }
        // abort() must be answered promptly; the native side is thread-safe.
        bg.execute { onMain { result.success(engine.abort()) } }
    }

    private fun handleModelInfo(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *> ?: run {
            fail(result, LlamaStatus.INVALID_ARGUMENT, "arguments required"); return
        }
        val handle = (args["handle"] as? Number)?.toInt()
        val engine = handle?.let { synchronized(engines) { engines[it] } } ?: run {
            fail(result, LlamaStatus.NOT_INITIALIZED, "no engine for handle $handle"); return
        }
        bg.execute {
            try {
                val info = engine.modelInfo()
                onMain {
                    result.success(
                        mapOf(
                            "nCtx" to info.nCtx,
                            "nEmbd" to info.nEmbd,
                            "modelSizeBytes" to info.modelSizeBytes,
                            "nParams" to info.nParams,
                            "description" to info.description,
                        ),
                    )
                }
            } catch (e: Throwable) {
                fail(result, LlamaStatus.NOT_INITIALIZED, e.message ?: "modelInfo failed")
            }
        }
    }

    private fun handleClose(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<*, *>
        val handle = (args?.get("handle") as? Number)?.toInt()
        val engine = handle?.let { synchronized(engines) { engines.remove(it) } }
        bg.execute {
            engine?.close()
            onMain { result.success(null) }
        }
    }
}
