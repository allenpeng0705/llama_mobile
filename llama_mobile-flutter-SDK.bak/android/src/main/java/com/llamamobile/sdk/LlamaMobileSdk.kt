package com.llamamobile.sdk

import android.content.Context
import com.llamamobile.LlamaMobile
import java.util.concurrent.Executors

/**
 * LlamaMobile Android SDK
 *
 * This class provides a higher-level, more convenient API wrapper around the LlamaMobile native library.
 * It handles threading, error management, and provides a more Kotlin-friendly interface.
 */
class LlamaMobileSdk {

    /**
     * Model configuration data class
     */
    data class ModelConfig(
        val modelPath: String,
        val chatTemplate: String? = null,
        val systemPrompt: String? = null,
        val contextSize: Int = 2048,
        val batchSize: Int = 512,
        val microBatchSize: Int = 512,
        val gpuLayerCount: Int = 0,
        val threadCount: Int = 4,
        val useMmap: Boolean = true,
        val useMlock: Boolean = false,
        val enableEmbeddings: Boolean = false,
        val poolingType: Int = 0,
        val embeddingNormalize: Int = 0,
        val useFlashAttention: Boolean = false,
        val cacheTypeK: String? = null,
        val cacheTypeV: String? = null,
        val useMemoryCache: Boolean = true
    )

    /**
     * Generation configuration data class
     */
    data class GenerationConfig(
        val prompt: String,
        val maxTokens: Int = 128,
        val threadCount: Int = 4,
        val seed: Int = -1,
        val temperature: Double = 0.8,
        val topK: Int = 40,
        val topP: Double = 0.9,
        val minP: Double = 0.05,
        val typicalP: Double = 1.0,
        val penaltyLastN: Int = 64,
        val penaltyRepeat: Double = 1.1,
        val penaltyFreq: Double = 0.0,
        val penaltyPresent: Double = 0.0,
        val mirostat: Int = 0,
        val mirostatTau: Double = 5.0,
        val mirostatEta: Double = 0.1,
        val ignoreEos: Boolean = false,
        val nProbs: Int = 0,
        val stopSequences: List<String> = emptyList(),
        val grammar: String? = null
    )

    /**
     * Result callback interface
     */
    interface ResultCallback<T> {
        fun onSuccess(result: T)
        fun onError(error: Throwable)
    }

    /**
     * Listener interface for generation events
     */
    interface GenerationListener {
        fun onGenerationStart(prompt: String)
        
        /**
         * Called when a new token is generated during streaming
         * 
         * @param token Generated token string
         * @return true to continue generation, false to stop
         */
        fun onToken(token: String): Boolean = true
        
        fun onGenerationComplete(result: LlamaMobile.CompletionResult)
        fun onError(error: Throwable)
    }

    // Expose the GrammarName enum for convenience
    val GrammarName = LlamaMobile.GrammarName
    
    // Private fields
    private var contextHandle: Long = 0
    private val executorService = Executors.newSingleThreadExecutor()

    /**
     * Loads a model with the specified configuration
     *
     * @param config Model configuration
     * @param callback Result callback for model loading
     */
    fun loadModel(config: ModelConfig, callback: ResultCallback<Boolean>) {
        executorService.execute {
            try {
                val cacheType = if (config.useMemoryCache) LlamaMobile.CacheType.MEMORY else LlamaMobile.CacheType.NONE
                val initParams = LlamaMobile.InitParams(
                    modelPath = config.modelPath,
                    chatTemplate = config.chatTemplate,
                    systemPrompt = config.systemPrompt,
                    nCtx = config.contextSize,
                    nBatch = config.batchSize,
                    nUbatch = config.microBatchSize,
                    nGpuLayers = config.gpuLayerCount,
                    nThreads = config.threadCount,
                    useMmap = config.useMmap,
                    useMlock = config.useMlock,
                    embedding = config.enableEmbeddings,
                    poolingType = config.poolingType,
                    embdNormalize = config.embeddingNormalize,
                    flashAttn = config.useFlashAttention,
                    cacheTypeK = config.cacheTypeK,
                    cacheTypeV = config.cacheTypeV,
                    cacheType = cacheType
                )

                contextHandle = LlamaMobile.initContext(initParams)
                val success = contextHandle != 0L
                callback.onSuccess(success)
            } catch (e: Exception) {
                callback.onError(e)
            }
        }
    }

    /**
     * Generates text completion based on the given prompt and configuration
     *
     * @param config Generation configuration
     * @param listener Generation listener for events
     */
    fun generate(config: GenerationConfig, listener: GenerationListener) {
        executorService.execute {
            try {
                if (contextHandle == 0L) {
                    throw IllegalStateException("Model not loaded. Call loadModel() first.")
                }

                listener.onGenerationStart(config.prompt)

                val completionParams = LlamaMobile.CompletionParams(
                    prompt = config.prompt,
                    nPredict = config.maxTokens,
                    nThreads = config.threadCount,
                    seed = config.seed,
                    temperature = config.temperature,
                    topK = config.topK,
                    topP = config.topP,
                    minP = config.minP,
                    typicalP = config.typicalP,
                    penaltyLastN = config.penaltyLastN,
                    penaltyRepeat = config.penaltyRepeat,
                    penaltyFreq = config.penaltyFreq,
                    penaltyPresent = config.penaltyPresent,
                    mirostat = config.mirostat,
                    mirostatTau = config.mirostatTau,
                    mirostatEta = config.mirostatEta,
                    ignoreEos = config.ignoreEos,
                    nProbs = config.nProbs,
                    grammar = config.grammar,
                    stopSequences = config.stopSequences,
                    tokenCallback = LlamaMobile.TokenCallback {
                        token -> token?.let { listener.onToken(it) } ?: true
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
                if (result != null) {
                    listener.onGenerationComplete(result)
                } else {
                    throw RuntimeException("Generation failed")
                }
            } catch (e: Exception) {
                listener.onError(e)
            }
        }
    }

    /**
     * Returns the content of a built-in grammar file
     * 
     * @param context Application context to access assets
     * @param name The name of the grammar file
     * @return The content of the grammar file, or null if not found or an error occurred
     */
    fun getGrammarContent(context: Context, name: GrammarName): String? {
        return LlamaMobile.grammarContent(context, name)
    }
    
    /**
     * Releases the loaded model and frees resources
     */
    fun release() {
        executorService.execute {
            if (contextHandle != 0L) {
                LlamaMobile.releaseContext(contextHandle)
                contextHandle = 0
            }
        }
        executorService.shutdown()
    }
}