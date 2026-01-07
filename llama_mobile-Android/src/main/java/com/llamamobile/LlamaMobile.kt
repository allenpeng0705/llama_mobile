package com.llamamobile

import android.content.Context
import android.content.res.AssetManager
import java.io.IOException
import java.io.InputStream

/**
 * LlamaMobile Android Library
 * 
 * This class provides a Kotlin wrapper around the llama_mobile C library, 
 * allowing Android applications to interact with llama models.
 */
object LlamaMobile {
    
    /**
     * Available built-in grammar file names
     */
    enum class GrammarName {
        arithmetic,
        c,
        chess,
        english,
        japanese,
        json,
        json_arr,
        list
    }
    
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
     * @property chatTemplate Chat template to use (optional)
     * @property systemPrompt System prompt to guide the model's behavior (optional)
     * @property nCtx Size of the context window (default: 2048)
     * @property nBatch Batch size for processing input tokens (default: 512)
     * @property nUbatch Micro-batch size for processing input tokens (default: 512)
     * @property nGpuLayers Number of layers to offload to GPU (0 = no GPU acceleration)
     * @property nThreads Number of CPU threads to use for inference (default: 4)
     * @property useMmap Whether to use memory-mapped files for model loading (default: true)
     * @property useMlock Whether to lock model memory in RAM (prevents swapping, default: false)
     * @property embedding Whether to enable embedding generation (default: false)
     * @property poolingType Pooling type for embeddings (0 = no pooling, 1 = mean pooling, 2 = max pooling)
     * @property embdNormalize Whether to normalize embeddings (default: 0)
     * @property flashAttn Whether to enable flash attention optimization (default: false)
     * @property cacheTypeK Cache type for key tensors (e.g., "f16", "q4_0", optional)
     * @property cacheTypeV Cache type for value tensors (e.g., "f16", "q4_0", optional)
     */
    data class InitParams(
        val modelPath: String,
        val chatTemplate: String? = null,
        val systemPrompt: String? = null,
        val nCtx: Int = 2048,
        val nBatch: Int = 512,
        val nUbatch: Int = 512,
        val nGpuLayers: Int = 0,
        val nThreads: Int = 4,
        val useMmap: Boolean = true,
        val useMlock: Boolean = false,
        val embedding: Boolean = false,
        val poolingType: Int = 0,
        val embdNormalize: Int = 0,
        val flashAttn: Boolean = false,
        val cacheTypeK: String? = null,
        val cacheTypeV: String? = null
    )
    
    /**
     * Callback type for token streaming during completion generation
     */
    fun interface TokenCallback {
        /**
         * Called when a new token is generated
         * 
         * @param token The generated token string, or null to indicate end of generation
         * @return true to continue generation, false to stop
         */
        fun onToken(token: String?): Boolean
    }
    
    /**
     * Result structure for text completion generation
     * 
     * @property text Generated text completion
     * @property tokensPredicted Number of tokens predicted in the completion
     * @property tokensEvaluated Number of tokens evaluated from the prompt
     * @property truncated Whether the output was truncated due to context limits
     * @property stoppedEos Whether generation stopped at the end-of-sequence token
     * @property stoppedWord Whether generation stopped at a stop sequence
     * @property stoppedLimit Whether generation stopped due to reaching maximum tokens limit
     * @property stoppingWord The stop sequence that caused generation to stop (if any)
     */
    data class CompletionResult(
        val text: String,
        val tokensPredicted: Int,
        val tokensEvaluated: Int,
        val truncated: Boolean,
        val stoppedEos: Boolean,
        val stoppedWord: Boolean,
        val stoppedLimit: Boolean,
        val stoppingWord: String?
    )

    /**
     * Completion parameters for generating text
     * 
     * @property prompt Input prompt for text generation
     * @property nPredict Maximum number of tokens to generate (default: 128)
     * @property nThreads Number of CPU threads to use for generation (default: 4)
     * @property seed Random seed for generation (use -1 for random seed, default: -1)
     * @property temperature Temperature for sampling (higher values = more random output, default: 0.8)
     * @property topK Top-K sampling parameter (0 = disable, default: 40)
     * @property topP Top-P sampling parameter (nucleus sampling, default: 0.9)
     * @property minP Minimum probability for sampling (default: 0.05)
     * @property typicalP Typical-P sampling parameter (default: 1.0)
     * @property penaltyLastN Number of tokens to consider for repetition penalty (default: 64)
     * @property penaltyRepeat Penalty for repeated tokens (default: 1.1)
     * @property penaltyFreq Frequency penalty for tokens (default: 0.0)
     * @property penaltyPresent Present penalty for tokens (default: 0.0)
     * @property mirostat Mirostat sampling mode (0 = disable, 1 = Mirostat, 2 = Mirostat 2.0, default: 0)
     * @property mirostatTau Mirostat target entropy (default: 5.0)
     * @property mirostatEta Mirostat learning rate (default: 0.1)
     * @property ignoreEos Whether to ignore the end-of-sequence token (default: false)
     * @property nProbs Number of top probabilities to return per token (0 = disable, default: 0)
     * @property stopSequences Sequences that will stop generation when encountered (default: empty)
     * @property grammar Grammar for constrained generation (using GBNF format, optional)
     * @property tokenCallback Callback for streaming token generation (optional)
     */
    data class CompletionParams(
        val prompt: String,
        val nPredict: Int = 128,
        val nThreads: Int = 4,
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
        val grammar: String? = null,
        val tokenCallback: TokenCallback? = null
    )
    
    /**
     * Returns the content of a built-in grammar file
     * 
     * @param context Application context to access assets
     * @param name The name of the grammar file without extension
     * @return The content of the grammar file, or null if not found or an error occurred
     */
    fun grammarContent(context: Context, name: GrammarName): String? {
        val assetManager: AssetManager = context.assets
        val fileName = "grammars/${name.name}.gbnf"
        
        return try {
            val inputStream: InputStream = assetManager.open(fileName)
            inputStream.bufferedReader().use { it.readText() }
        } catch (e: IOException) {
            e.printStackTrace()
            null
        }
    }
    
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
     * @return Generated text and metadata, or null if generation failed
     */
    external fun generateCompletion(contextHandle: Long, params: CompletionParams): CompletionResult?
    
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
