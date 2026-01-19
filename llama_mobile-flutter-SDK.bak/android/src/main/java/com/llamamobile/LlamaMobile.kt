package com.llamamobile

/**
 * LlamaMobile Android Library
 * 
 * This class provides a Kotlin wrapper around the llama_mobile C library, 
 * allowing Android applications to interact with llama models.
 */
object LlamaMobile {
    
    /**
     * Cache type enum
     */
    enum class CacheType {
        NONE,
        MEMORY
    }
    
    /**
     * Initialization parameters for creating a llama context
     * 
     * @property modelPath Path to the llama model file
     * @property nCtx Size of the context window (default: 512)
     * @property chatTemplate Chat template to use (optional)
     * @property cacheType Cache type to use (default: MEMORY)
     */
    data class InitParams(
        val modelPath: String,
        val nCtx: Int = 512,
        val chatTemplate: String? = null,
        val cacheType: CacheType = CacheType.MEMORY
    )
    
    /**
     * Completion parameters for generating text
     * 
     * @property prompt Input prompt for text generation
     * @property temperature Temperature for sampling (default: 0.8)
     * @property maxTokens Maximum number of tokens to generate (default: 100)
     */
    data class CompletionParams(
        val prompt: String,
        val temperature: Float = 0.8f,
        val maxTokens: Int = 100
    )
    
    /**
     * Loads the native libraries
     */
    init {
        System.loadLibrary("llama_mobile")
        System.loadLibrary("llama_mobile_jni")
    }
    
    /**
     * Initializes a new llama context
     * 
     * @param params Initialization parameters
     * @return Context handle, or 0 if initialization failed
     */
    external fun initContext(params: InitParams): Long
    
    /**
     * Generates text completion
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param params Completion parameters
     * @return Generated text, or null if generation failed
     */
    external fun generateCompletion(contextHandle: Long, params: CompletionParams): String?
    
    /**
     * Releases a llama context
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseContext(contextHandle: Long)
}
