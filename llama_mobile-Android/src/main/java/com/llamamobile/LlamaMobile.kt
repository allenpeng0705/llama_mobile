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

    /**
     * Initializes a vocoder model for TTS
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param vocoderModelPath Path to the vocoder model file
     * @return 0 if successful, non-zero otherwise
     */
    external fun initVocoder(contextHandle: Long, vocoderModelPath: String): Int

    /**
     * Checks if the vocoder is enabled
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if vocoder is enabled, false otherwise
     */
    external fun isVocoderEnabled(contextHandle: Long): Boolean

    /**
     * Gets the TTS type
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return TTS type identifier
     */
    external fun getTtsType(contextHandle: Long): Int

    /**
     * Gets formatted audio completion for TTS
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param speakerJsonStr JSON string with speaker configuration
     * @param textToSpeak Text to convert to speech
     * @return Formatted audio completion string, or null if failed
     */
    external fun getFormattedAudioCompletion(contextHandle: Long, speakerJsonStr: String, textToSpeak: String): String?

    /**
     * Gets audio guide tokens for TTS
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param textToSpeak Text to convert to speech
     * @return Array of audio guide tokens
     */
    external fun getAudioGuideTokens(contextHandle: Long, textToSpeak: String): IntArray?

    /**
     * Decodes audio tokens to float audio data
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Audio tokens to decode
     * @return Decoded float audio data, or null if failed
     */
    external fun decodeAudioTokens(contextHandle: Long, tokens: IntArray): FloatArray?

    /**
     * Releases the vocoder resources
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseVocoder(contextHandle: Long)
}
