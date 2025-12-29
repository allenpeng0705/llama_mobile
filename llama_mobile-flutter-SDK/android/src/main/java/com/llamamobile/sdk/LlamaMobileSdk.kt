package com.llamamobile.sdk

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
        val contextSize: Int = 1024,
        val useMemoryCache: Boolean = true
    )

    /**
     * Generation configuration data class
     */
    data class GenerationConfig(
        val prompt: String,
        val temperature: Float = 0.8f,
        val maxTokens: Int = 100
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
        fun onGenerationComplete(result: String)
        fun onError(error: Throwable)
    }

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
                    nCtx = config.contextSize,
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
                    temperature = config.temperature,
                    maxTokens = config.maxTokens
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