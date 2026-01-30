package com.llamamobile

import android.util.Log
import kotlin.jvm.JvmStatic

/**
 * LlamaMobile Android Library
 * 
 * This class provides a Kotlin wrapper around the llama_mobile C library, 
 * allowing Android applications to interact with llama models.
 */
object LlamaMobile {
    
    /**
     * Error types for LlamaMobile operations
     */
    enum class ErrorType {
        CONTEXT_NOT_INITIALIZED,
        INVALID_PARAMETER,
        OPERATION_FAILED,
        VOCODER_NOT_INITIALIZED,
        MULTIMODAL_NOT_INITIALIZED,
        MEDIA_PROCESSING_FAILED,
        TOKENIZATION_FAILED,
        DETOKENIZATION_FAILED,
        EMBEDDING_GENERATION_FAILED,
        AUDIO_GENERATION_FAILED,
        CONVERSATION_FAILED
    }
    
    /**
     * Text-to-Speech model types
     */
    enum class TTSModelType {
        UNKNOWN,
        OUT_ETTS_V02,
        OUT_ETTS_V03;
        
        companion object {
            fun fromInt(value: Int): TTSModelType {
                return when (value) {
                    1 -> OUT_ETTS_V02
                    2 -> OUT_ETTS_V03
                    else -> UNKNOWN
                }
            }
        }
    }
    
    /**
     * Method used for TTS generation
     */
    enum class TTSMethod {
        BUILT_IN,
        CUSTOM_WORKFLOW
    }
    
    /**
     * TTS configuration options
     */
    data class TTSOptions(
        val sampleRate: Int = 24000,
        val voice: String? = null,
        val speed: Float = 1.0f,
        val saveToFile: Boolean = false,
        val outputFilePath: String? = null
    ) {
        companion object {
            @JvmStatic
            fun create(): TTSOptions = TTSOptions()
        }
    }
    
    /**
     * Result of successful speech generation
     */
    data class SpeechResult(
        val audioSamples: ShortArray,
        val sampleRate: Int,
        val duration: Double,
        val outputFilePath: String?,
        val methodUsed: TTSMethod
    ) {
        override fun equals(other: Any?): Boolean {
            if (this === other) return true
            if (javaClass != other?.javaClass) return false

            other as SpeechResult

            if (!audioSamples.contentEquals(other.audioSamples)) return false
            if (sampleRate != other.sampleRate) return false
            if (duration != other.duration) return false
            if (outputFilePath != other.outputFilePath) return false
            if (methodUsed != other.methodUsed) return false

            return true
        }

        override fun hashCode(): Int {
            var result = audioSamples.contentHashCode()
            result = 31 * result + sampleRate
            result = 31 * result + duration.hashCode()
            result = 31 * result + (outputFilePath?.hashCode() ?: 0)
            result = 31 * result + methodUsed.hashCode()
            return result
        }
    }
    
    /**
     * Error types for TTS operations
     */
    class TTSError private constructor(message: String) : Exception(message) {
        companion object {
            @JvmStatic
            fun noModelLoaded(): TTSError = TTSError("No model loaded")
            
            @JvmStatic
            fun noVocoderEnabled(): TTSError = TTSError("No vocoder enabled")
            
            @JvmStatic
            fun invalidText(): TTSError = TTSError("Invalid text")
            
            @JvmStatic
            fun generationFailed(): TTSError = TTSError("Generation failed")
            
            @JvmStatic
            fun formattingFailed(): TTSError = TTSError("Formatting failed")
            
            @JvmStatic
            fun tokenizationFailed(): TTSError = TTSError("Tokenization failed")
            
            @JvmStatic
            fun audioDecodingFailed(): TTSError = TTSError("Audio decoding failed")
            
            @JvmStatic
            fun fileSaveFailed(): TTSError = TTSError("File save failed")
            
            @JvmStatic
            fun unknownError(message: String): TTSError = TTSError(message)
        }
    }

    /**
     * Result class for operations that can fail
     */
    data class Result<S, E>(
        private val value: S?,
        private val error: E?,
        private val isSuccess: Boolean
    ) {
        companion object {
            @JvmStatic
            fun <S, E> success(value: S): Result<S, E> {
                return Result(value, null, true)
            }
            
            @JvmStatic
            fun <S, E> failure(error: E): Result<S, E> {
                return Result(null, error, false)
            }
        }
        
        fun isSuccess(): Boolean = isSuccess
        
        fun isFailure(): Boolean = !isSuccess
        
        fun getValue(): S? = value
        
        fun getError(): E? = error
        
        fun getOrThrow(): S {
            if (isSuccess) {
                return value!!
            } else {
                throw error as Throwable
            }
        }
        
        fun exceptionOrNull(): E? = error
    }
    
    /**
     * Grammar name enum for structured output
     */
    enum class GrammarName {
        ARITHMETIC,
        C,
        CHESS,
        ENGLISH,
        JAPANESE,
        JSON,
        JSON_ARR,
        LIST
    }
    
    /**
     * Chat message structure for structured input
     * 
     * @property role Role of the message sender (e.g., "system", "user", "assistant")
     * @property content Content of the message
     * @property reasoningContent Reasoning/thinking content for advanced models (optional)
     * @property toolName Tool call name for function calling (optional)
     * @property toolCallId Tool call ID for function calling (optional)
     */
    data class ChatMessage(
        val role: String,
        val content: String,
        val reasoningContent: String? = null,
        val toolName: String? = null,
        val toolCallId: String? = null
    )

    /**
     * Initialization parameters for creating a llama context
     * 
     * @property modelPath Path to the llama model file
     * @property nCtx Size of the context window (default: 2048)
     * @property chatTemplate Chat template to use (optional)
     * @property systemPrompt System prompt for chat models (optional)
     * @property nBatch Batch size for processing (default: 512)
     * @property nUBatch Unbounded batch size (default: 512)
     * @property nGpuLayers Number of layers to offload to GPU (default: 0)
     * @property nThreads Number of CPU threads to use (default: 4)
     * @property useMmap Whether to use memory mapping (default: true)
     * @property useMlock Whether to lock memory (default: false)
     * @property embedding Whether to enable embedding generation (default: false)
     * @property poolingType Pooling type for embeddings (default: 0)
     * @property embdNormalize Embedding normalization flag (default: 0)
     * @property flashAttention Whether to use flash attention (default: false)
     * @property cacheTypeK Cache type for K values (optional)
     * @property cacheTypeV Cache type for V values (optional)
     */
    data class InitParams(
        val modelPath: String,
        val nCtx: Int = 2048,
        val chatTemplate: String? = null,
        val systemPrompt: String? = null,
        val nBatch: Int = 512,
        val nUBatch: Int = 512,
        val nGpuLayers: Int = 0,
        val nThreads: Int = 4,
        val useMmap: Boolean = true,
        val useMlock: Boolean = false,
        val embedding: Boolean = false,
        val poolingType: Int = 0,
        val embdNormalize: Int = 0,
        val flashAttention: Boolean = false,
        val cacheTypeK: String? = null,
        val cacheTypeV: String? = null,
        val enableChatTemplate: Boolean = true,
        val progressCallback: ((Float) -> Unit)? = null
    ) {
        companion object {
            /**
             * Convenience factory for GPU-accelerated inference
             */
            @JvmStatic
            fun gpu(modelPath: String, nGpuLayers: Int, nCtx: Int = 2048): InitParams = InitParams(
                modelPath = modelPath,
                nCtx = nCtx,
                nGpuLayers = nGpuLayers
            )
            
            /**
             * Convenience factory for embedding generation
             */
            @JvmStatic
            fun embedding(modelPath: String, poolingType: Int = 0): InitParams = InitParams(
                modelPath = modelPath,
                embedding = true,
                poolingType = poolingType
            )
        }
    }
    
    /**
     * Completion parameters for generating text
     * 
     * @property prompt Input prompt for text generation
     * @property maxTokens Maximum number of tokens to generate (default: 128)
     * @property temperature Temperature for sampling (default: 0.8)
     * @property topK Top-K sampling parameter (default: 40)
     * @property topP Top-P sampling parameter (default: 0.95)
     * @property minP Min-P sampling parameter (default: 0.05)
     * @property typicalP Typical-P sampling parameter (default: 1.0)
     * @property penaltyLastN Penalty window size (default: 64)
     * @property penaltyRepeat Repetition penalty (default: 1.1)
     * @property penaltyFreq Frequency penalty (default: 0.0)
     * @property penaltyPresent Presence penalty (default: 0.0)
     * @property mirostat Mirostat sampling parameter (default: 0)
     * @property mirostatTau Mirostat tau parameter (default: 5.0)
     * @property mirostatEta Mirostat eta parameter (default: 0.1)
     * @property ignoreEos Whether to ignore EOS token (default: false)
     * @property stopSequences List of stop sequences (default: empty)
     * @property grammar Grammar string for constrained generation (optional)
     * @property mediaPaths List of media paths for multimodal input (default: empty)
     */
    data class CompletionParams(
        val prompt: String,
        val maxTokens: Int = 1024,
        val nThreads: Int? = null,
        val seed: Int = -1,
        val temperature: Float = 0.8f,
        val topK: Int = 40,
        val topP: Float = 0.95f,
        val minP: Float = 0.05f,
        val typicalP: Float = 1.0f,
        val penaltyLastN: Int = 64,
        val penaltyRepeat: Float = 1.1f,
        val penaltyFreq: Float = 0.0f,
        val penaltyPresent: Float = 0.0f,
        val mirostat: Int = 0,
        val mirostatTau: Float = 5.0f,
        val mirostatEta: Float = 0.1f,
        val ignoreEos: Boolean = false,
        val stopSequences: List<String> = emptyList(),
        val grammar: String? = null,
        val mediaPaths: List<String> = emptyList(),
        val chatMessages: List<ChatMessage> = emptyList(),
        val useJsonResponse: Boolean = true,
        val nProbs: Int = 0,
        val jsonSchema: String? = null,
        val tools: String? = null,
        val parallelToolCalls: Boolean = false,
        val toolChoice: String? = null,
        val tokenCallback: ((String) -> Boolean)? = null
    ) {
        /**
         * Initializer that accepts OpenAI format JSON
         * Example JSON format:
         * {"messages": [{"role": "system", "content": "You are a helpful assistant"}, {"role": "user", "content": "Hello"}]}
         */
        @Throws(Error::class)
        constructor(openAIJSON: String) : this(
            prompt = "",
            maxTokens = 256,
            temperature = 0.7f,
            topP = 0.95f,
            topK = 40,
            penaltyRepeat = 1.0f,
            penaltyFreq = 0.0f,
            penaltyPresent = 0.0f,
            penaltyLastN = 64,
            useJsonResponse = true,
            mediaPaths = parseMediaPaths(openAIJSON),
            chatMessages = parseChatMessages(openAIJSON),
            nThreads = null,
            seed = -1,
            minP = 0.05f,
            typicalP = 1.0f,
            mirostat = 0,
            mirostatTau = 5.0f,
            mirostatEta = 0.1f,
            ignoreEos = false,
            stopSequences = emptyList(),
            grammar = null,
            nProbs = 0,
            jsonSchema = null,
            tools = null,
            parallelToolCalls = false,
            toolChoice = null,
            tokenCallback = null
        )
        
        companion object {
            /**
             * Parse chat messages from OpenAI JSON
             */
            @Throws(Error::class)
            private fun parseChatMessages(openAIJSON: String): List<ChatMessage> {
                val chatMessages = mutableListOf<ChatMessage>()
                val jsonObject = try {
                    org.json.JSONObject(openAIJSON)
                } catch (e: Exception) {
                    throw IllegalArgumentException("Invalid JSON format")
                }
                
                val messages = jsonObject.optJSONArray("messages") ?: throw IllegalArgumentException("Missing or invalid 'messages' field")
                
                for (i in 0 until messages.length()) {
                    val message = messages.optJSONObject(i) ?: continue
                    val role = message.optString("role").takeIf { it.isNotEmpty() } ?: throw IllegalArgumentException("Missing or empty 'role' field")
                    
                    var textContent = ""
                    
                    // Check if content is an array (multimodal format)
                    val content = message.opt("content")
                    if (content is org.json.JSONArray) {
                        for (j in 0 until content.length()) {
                            val contentItem = content.optJSONObject(j) ?: continue
                            val type = contentItem.optString("type")
                            
                            if (type == "text") {
                                textContent += contentItem.optString("text") + " "
                            }
                        }
                    } else if (content is String) {
                        // Legacy string format
                        textContent = content
                    } else {
                        throw IllegalArgumentException("Invalid content format")
                    }
                    
                    // Extract additional fields if present
                    val reasoningContent = message.optString("reasoning_content").takeIf { it.isNotEmpty() }
                    val toolName = message.optString("tool_name").takeIf { it.isNotEmpty() }
                    val toolCallId = message.optString("tool_call_id").takeIf { it.isNotEmpty() }
                    
                    // Add the text content to chat messages
                    chatMessages.add(ChatMessage(
                        role = role,
                        content = textContent.trim(),
                        reasoningContent = reasoningContent,
                        toolName = toolName,
                        toolCallId = toolCallId
                    ))
                }
                
                return chatMessages
            }
            
            /**
             * Parse media paths from OpenAI JSON
             */
            @Throws(Error::class)
            private fun parseMediaPaths(openAIJSON: String): List<String> {
                val mediaPaths = mutableListOf<String>()
                val jsonObject = try {
                    org.json.JSONObject(openAIJSON)
                } catch (e: Exception) {
                    throw IllegalArgumentException("Invalid JSON format")
                }
                
                val messages = jsonObject.optJSONArray("messages") ?: return emptyList()
                
                for (i in 0 until messages.length()) {
                    val message = messages.optJSONObject(i) ?: continue
                    
                    // Check if content is an array (multimodal format)
                    val content = message.opt("content")
                    if (content is org.json.JSONArray) {
                        for (j in 0 until content.length()) {
                            val contentItem = content.optJSONObject(j) ?: continue
                            val type = contentItem.optString("type")
                            
                            if (type == "image_url") {
                                val imageUrlDict = contentItem.optJSONObject("image_url")
                                val urlString = imageUrlDict?.optString("url") ?: continue
                                // For local files, extract path from URL
                                if (urlString.startsWith("file://")) {
                                    mediaPaths.add(urlString.substring(7))
                                } else {
                                    // For remote URLs, add as-is
                                    mediaPaths.add(urlString)
                                }
                            }
                        }
                    }
                }
                
                return mediaPaths
            }
            
            /**
             * Convenience factory for creative writing
             */
            @JvmStatic
            fun creative(prompt: String, maxTokens: Int = 1024): CompletionParams = CompletionParams(
                prompt = prompt,
                maxTokens = maxTokens,
                temperature = 1.0f,
                topP = 0.98f,
                topK = 100
            )
            
            /**
             * Convenience factory for factual/accurate outputs
             */
            @JvmStatic
            fun factual(prompt: String): CompletionParams = CompletionParams(
                prompt = prompt,
                temperature = 0.1f,
                topP = 0.9f,
                topK = 20
            )
            
            /**
             * Convenience factory for chat conversations using structured messages
             */
            @JvmStatic
            fun chat(messages: List<ChatMessage>, maxTokens: Int = 1024): CompletionParams = CompletionParams(
                prompt = "",
                chatMessages = messages,
                maxTokens = maxTokens,
                temperature = 0.7f,
                topP = 0.95f,
                topK = 40,
                penaltyRepeat = 1.2f
            )
            
            /**
             * Convenience factory for chat-like responses using raw prompt
             */
            @JvmStatic
            fun chat(prompt: String, maxTokens: Int = 1024): CompletionParams = CompletionParams(
                prompt = prompt,
                maxTokens = maxTokens,
                temperature = 0.7f,
                topP = 0.95f,
                topK = 40,
                penaltyRepeat = 1.2f
            )
            
            /**
             * Convenience factory for multimodal inputs
             */
            @JvmStatic
            fun multimodal(prompt: String, mediaPaths: List<String>, maxTokens: Int = 1024): CompletionParams = CompletionParams(
                prompt = prompt,
                maxTokens = maxTokens,
                mediaPaths = mediaPaths
            )
        }
    }
    
    /**
     * Result of a text completion generation
     * 
     * @property text Generated text
     * @property tokensGenerated Number of tokens generated
     * @property tokensEvaluated Number of tokens evaluated
     * @property truncated Whether the generation was truncated
     * @property stoppedEos Whether generation stopped due to EOS token
     * @property stoppedWord Whether generation stopped due to stop sequence
     * @property stoppedLimit Whether generation stopped due to token limit
     */
    data class CompletionResult(
        val text: String,
        val tokensGenerated: Int,
        val tokensEvaluated: Int,
        val truncated: Boolean,
        val stoppedEos: Boolean,
        val stoppedWord: Boolean,
        val stoppedLimit: Boolean,
        val stoppingWord: String? = null
    )
    
    /**
     * LoRA adapter configuration
     * 
     * @property path Path to the LoRA adapter file
     * @property scale LoRA adapter scale (default: 1.0)
     */
    data class LoraAdapter(
        val path: String,
        val scale: Float = 1.0f
    )
    
    /**
     * Result of a conversation generation
     * 
     * @property text Generated response text
     * @property timeToFirstToken Time to generate first token in milliseconds
     * @property totalTime Total generation time in milliseconds
     * @property tokensGenerated Number of tokens generated
     */
    data class ConversationResult(
        val text: String,
        val timeToFirstToken: Long,
        val totalTime: Long,
        val tokensGenerated: Int
    )
    
    /**
     * Parameters for downloading models or files
     * 
     * @property url Hugging Face repository ID (e.g., "meta-llama/Llama-2-7B-Chat-GGUF")
     * @property localPath Local path to save the file
     * @property username Username for authentication (optional)
     * @property password Bearer token for authentication (optional, for private repositories)
     * @property headers Additional HTTP headers (optional)
     * @property progressCallback Callback for download progress (0.0 to 1.0)
     */
    data class DownloadParams(
        val url: String,
        val localPath: String,
        val username: String? = null,
        val password: String? = null,
        val headers: Map<String, String>? = null,
        val progressCallback: ((Float) -> Unit)? = null
    )
    
    /**
     * Result of a download operation
     * 
     * @property success Whether the download was successful
     * @property localPath Local path where the file was saved
     * @property errorMessage Error message if download failed (optional)
     */
    data class DownloadResult(
        val success: Boolean,
        val localPath: String,
        val errorMessage: String? = null
    )
    
    /**
     * Loads the native libraries
     */
    init {
        // Load C++ shared library first - explicitly handle potential errors
        try {
            System.loadLibrary("c++_shared")
            // Then load our native library
            System.loadLibrary("llama_mobile")
            // Load JNI wrapper library
            System.loadLibrary("llama_mobile_jni")
        } catch (e: UnsatisfiedLinkError) {
            e.printStackTrace()
            // Try alternative loading approach if primary fails
            try {
                System.loadLibrary("c++_shared")
                System.loadLibrary("llama_mobile")
                System.loadLibrary("llama_mobile_jni")
            } catch (e2: UnsatisfiedLinkError) {
                e2.printStackTrace()
                throw e2
            }
        }
    }
    
    /**
     * Initializes a new llama context
     * 
     * @param params Initialization parameters
     * @return Context handle, or 0 if initialization failed
     */
    external fun initContext(params: InitParams): Long
    
    /**
     * Generates a completion for the given prompt
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param params Completion parameters
     * @return Completion result containing generated text and metadata, or null if an error occurred
     */
    fun generateCompletion(contextHandle: Long, params: CompletionParams): CompletionResult? {
        return nativeGenerateCompletion(contextHandle, params)
    }
    
    /**
     * Native implementation of generateCompletion
     */
    private external fun nativeGenerateCompletion(contextHandle: Long, params: CompletionParams): CompletionResult?
    
    /**
     * Generates text completion with simplified parameters
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param prompt Input prompt text
     * @param maxTokens Maximum number of tokens to generate (default: 128)
     * @param temperature Sampling temperature (default: 0.8)
     * @return Completion result, or null if generation failed
     */
    fun generateCompletion(contextHandle: Long, prompt: String, maxTokens: Int = 128, temperature: Float = 0.8f): CompletionResult? {
        val params = CompletionParams(prompt = prompt, maxTokens = maxTokens, temperature = temperature)
        return generateCompletion(contextHandle, params)
    }
    
    /**
     * Generates a completion using OpenAI format JSON
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param openAIJSON OpenAI format JSON string
     * @param grammar Optional grammar content to constrain generation
     * @return Completion result in OpenAI format, or null if generation failed
     */
    fun generateOpenAICompletion(contextHandle: Long, openAIJSON: String, grammar: String? = null): CompletionResult? {
        try {
            // Create completion params from OpenAI JSON
            var params = CompletionParams(openAIJSON = openAIJSON)
            
            // Set grammar if provided
            if (grammar != null) {
                params = params.copy(grammar = grammar)
            }
            
            // Use JSON response format for OpenAI compatibility unless a custom grammar is provided
            // This avoids conflicts between built-in JSON formatting and custom JSON grammar
            params = params.copy(useJsonResponse = grammar == null)
            
            // Generate completion using the standard method
            return generateCompletion(contextHandle, params)
        } catch (e: Exception) {
            return null
        }
    }
    
    /**
     * Stops an ongoing completion generation
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun stopCompletion(contextHandle: Long)
    
    /**
     * Tokenizes a text string into token IDs
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text string to tokenize
     * @return Array of token IDs, or null if tokenization failed
     */
    external fun tokenize(contextHandle: Long, text: String): IntArray?
    
    /**
     * Detokenizes an array of token IDs back to a text string
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Array of token IDs to detokenize
     * @return Detokenized text string, or null if detokenization failed
     */
    external fun detokenize(contextHandle: Long, tokens: IntArray): String?
    
    /**
     * Generates embeddings for a text string
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text string to generate embeddings for
     * @return Array of floating-point embeddings, or null if embedding generation failed
     */
    external fun generateEmbeddings(contextHandle: Long, text: String): FloatArray?
    
    /**
     * Initializes multimodal support (vision/audio)
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param mmprojPath Path to the multimodal projection file
     * @param useGpu Whether to use GPU acceleration for multimodal processing (default: true)
     * @return true on success, false on failure
     */
    external fun initMultimodal(contextHandle: Long, mmprojPath: String, useGpu: Boolean = true): Boolean
    
    /**
     * Checks if multimodal support is enabled
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if enabled, false otherwise
     */
    external fun isMultimodalEnabled(contextHandle: Long): Boolean
    
    /**
     * Checks if the model supports vision input
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if vision is supported, false otherwise
     */
    external fun supportsVision(contextHandle: Long): Boolean
    
    /**
     * Checks if the model supports audio input
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if audio is supported, false otherwise
     */
    external fun supportsAudio(contextHandle: Long): Boolean
    
    /**
     * Releases multimodal resources
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseMultimodal(contextHandle: Long)
    
    /**
     * Initializes the vocoder for text-to-speech functionality
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param vocoderModelPath Path to the vocoder model file
     * @return true on success, false on failure
     */
    external fun initVocoder(contextHandle: Long, vocoderModelPath: String): Boolean
    
    /**
     * Checks if vocoder (TTS) support is enabled
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if enabled, false otherwise
     */
    external fun isVocoderEnabled(contextHandle: Long): Boolean
    
    /**
     * Gets the type of TTS model currently loaded
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return TTS model type
     */
    external fun getTTSType(contextHandle: Long): TTSModelType
    
    /**
     * Formats text for audio completion with speaker information
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param speakerJson JSON string with speaker configuration
     * @param textToSpeak Text to convert to speech
     * @return Formatted audio completion string, or null if an error occurred
     */
    external fun getFormattedAudioCompletion(contextHandle: Long, speakerJson: String, textToSpeak: String): String?
    
    /**
     * Gets guide tokens for audio completion
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param textToSpeak Text to convert to speech
     * @return Array of guide tokens for audio generation, or null if an error occurred
     */
    external fun getAudioGuideTokens(contextHandle: Long, textToSpeak: String): IntArray?
    
    /**
     * Decodes audio tokens into raw audio data
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Audio tokens to decode
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    external fun decodeAudioTokens(contextHandle: Long, tokens: IntArray): FloatArray?
    
    /**
     * Sets guide tokens for audio generation
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param tokens Guide tokens to set for audio generation
     */
    external fun setGuideTokens(contextHandle: Long, tokens: IntArray)
    
    /**
     * Saves audio samples to WAV file
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param filePath Path to save the WAV file
     * @param audioData Array of floating-point audio samples
     * @param sampleRate Sample rate for the audio (e.g., 48000)
     * @return true on success, false on failure
     */
    external fun saveAudioToWav(contextHandle: Long, filePath: String, audioData: FloatArray, sampleRate: Int): Boolean
    
    /**
     * Releases vocoder (TTS) resources
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseVocoder(contextHandle: Long)
    
    /**
     * Generates audio samples from text using TTS
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param speakerJson JSON string with speaker configuration (optional, defaults to default speaker)
     * @return Array of floating-point audio samples, or null if an error occurred
     */
    fun generateAudioFromText(contextHandle: Long, text: String, speakerJson: String = "{\"speaker\": \"default\"}"): FloatArray? {
        if (!isVocoderEnabled(contextHandle)) {
            return null
        }
        
        // Get formatted audio completion
        val formattedPrompt = getFormattedAudioCompletion(contextHandle, speakerJson, text) ?: return null
        
        // Generate audio tokens
        val audioTokens = getAudioGuideTokens(contextHandle, formattedPrompt) ?: return null
        
        // Decode audio tokens to samples
        return decodeAudioTokens(contextHandle, audioTokens)
    }
    
    /**
     * Generates speech from text using the best available method
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @return Result containing the generated audio samples and metadata
     */
    @JvmStatic
    fun generateSpeech(
        contextHandle: Long,
        text: String,
        options: TTSOptions = TTSOptions(),
        progressHandler: ((Float) -> Unit)? = null
    ): Result<SpeechResult, TTSError> {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded())
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled())
        }
        
        progressHandler?.invoke(0.1f) // Initial progress
        
        // Check TTS model type
        val ttsType = getTTSType(contextHandle)
        val isKnownTTSModel = ttsType != TTSModelType.UNKNOWN
        
        progressHandler?.invoke(0.2f) // Model check completed
        
        var audioSamples: FloatArray?
        var methodUsed: TTSMethod = TTSMethod.BUILT_IN
        
        if (isKnownTTSModel) {
            // Try Path 1: Built-in TTS method
            progressHandler?.invoke(0.3f) // Starting built-in method
            audioSamples = generateAudioFromText(contextHandle, text)
            methodUsed = TTSMethod.BUILT_IN
            
            progressHandler?.invoke(0.6f) // Built-in method completed
        } else {
            // Try Path 2: Custom TTS workflow
            progressHandler?.invoke(0.4f) // Starting custom workflow
            audioSamples = generateAudioFromText(contextHandle, text)
            methodUsed = TTSMethod.CUSTOM_WORKFLOW
        }
        
        audioSamples ?: return Result.failure(TTSError.generationFailed())
        
        progressHandler?.invoke(0.8f) // Audio generation completed
        
        // Calculate duration
        val duration = audioSamples.size.toDouble() / options.sampleRate
        
        // Convert FloatArray to ShortArray
        val shortSamples = ShortArray(audioSamples.size) {
            ((audioSamples[it] * Short.MAX_VALUE).toInt()).toShort()
        }
        
        // Save to file if requested
        var savedFilePath: String? = null
        if (options.saveToFile && options.outputFilePath != null) {
            val saveSuccess = saveAudioToWav(contextHandle, options.outputFilePath, audioSamples, options.sampleRate)
            if (saveSuccess) {
                savedFilePath = options.outputFilePath
            } else {
                return Result.failure(TTSError.fileSaveFailed())
            }
        }
        
        progressHandler?.invoke(1.0f) // Completed
        
        // Create speech result
        val speechResult = SpeechResult(
            audioSamples = shortSamples,
            sampleRate = options.sampleRate,
            duration = duration,
            outputFilePath = savedFilePath,
            methodUsed = methodUsed
        )
        
        return Result.success(speechResult)
    }
    
    /**
     * Applies LoRA adapters to the model
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param adapters Array of LoRA adapter configurations
     * @return true on success, false on failure
     */
    external fun applyLoraAdapters(contextHandle: Long, adapters: Array<LoraAdapter>): Boolean
    
    /**
     * Removes all loaded LoRA adapters
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun removeLoraAdapters(contextHandle: Long)
    
    /**
     * Gets the currently loaded LoRA adapters
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Array of loaded LoRA adapter configurations, or null if an error occurred
     */
    external fun getLoadedLoraAdapters(contextHandle: Long): Array<LoraAdapter>?
    
    /**
     * Generates a response to a user message in a conversation
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param userMessage User's message
     * @param maxTokens Maximum number of tokens to generate
     * @return Conversation result, or null if an error occurred
     */
    external fun generateResponse(contextHandle: Long, userMessage: String, maxTokens: Int = 128): ConversationResult?
    
    /**
     * Clears the current conversation context
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun clearConversation(contextHandle: Long)
    
    /**
     * Checks if a conversation is currently active
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return true if active, false otherwise
     */
    external fun isConversationActive(contextHandle: Long): Boolean
    
    /**
     * Gets the size of the context window
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Size of the context window in tokens
     */
    external fun getContextWindowSize(contextHandle: Long): Int
    
    /**
     * Gets the dimension of the model's embeddings
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Dimension of the model's embeddings
     */
    external fun getEmbeddingDimension(contextHandle: Long): Int
    
    /**
     * Gets a description of the loaded model
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Model description string, or null if an error occurred
     */
    external fun getModelDescription(contextHandle: Long): String?
    
    /**
     * Gets the size of the loaded model
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Model size in bytes
     */
    external fun getModelSize(contextHandle: Long): Long
    
    /**
     * Gets the number of parameters in the loaded model
     * 
     * @param contextHandle Context handle obtained from initContext
     * @return Number of model parameters
     */
    external fun getModelParametersCount(contextHandle: Long): Long
    
    /**
     * Downloads a model from Hugging Face repository
     * 
     * @param params Download parameters
     * @param progressCallback Callback for download progress updates
     * @return Download result
     */
    external fun downloadModel(params: DownloadParams, progressCallback: ((Float) -> Unit)? = null): DownloadResult?
    
    /**
     * Downloads a specific file from Hugging Face repository
     * 
     * @param repoId Hugging Face repository ID
     * @param filename Name of the file to download
     * @param destinationPath Local path to save the file
     * @param bearerToken Bearer token for authentication (optional)
     * @param offline Whether to use offline mode
     * @param progressCallback Callback for download progress updates
     * @return Download result
     */
    external fun downloadHfFile(
        repoId: String,
        filename: String,
        destinationPath: String,
        bearerToken: String? = null,
        offline: Boolean = false,
        progressCallback: ((Float) -> Unit)? = null
    ): DownloadResult?
    
    /**
     * Convenience method for downloading models, matching the iOS API signature
     * 
     * @param params Download parameters
     * @return Download result
     */
    fun download(params: DownloadParams): DownloadResult? {
        return downloadModel(params, params.progressCallback)
    }
    
    /**
     * Gets the content of a grammar file from assets
     * 
     * @param context Application context to access assets
     * @param grammarName Grammar name to retrieve
     * @return Grammar content as string, or null if not found
     */
    external fun grammarContent(context: android.content.Context, grammarName: GrammarName): String?
    
    /**
     * Convenience method to get JSON grammar content
     * 
     * @param context Application context to access assets
     * @return JSON grammar content as string
     */
    fun getJsonGrammar(context: android.content.Context): String? {
        return grammarContent(context, GrammarName.JSON)
    }
    

    
    /**
     * Generates speech from text using the best available method (synchronous)
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @return Result containing the generated audio samples and metadata
     */
    @JvmStatic
    fun generateSpeechSync(
        contextHandle: Long,
        text: String,
        options: TTSOptions = TTSOptions()
    ): Result<SpeechResult, TTSError> {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded())
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled())
        }
        
        // Check TTS model type
        val ttsType = getTTSType(contextHandle)
        val isKnownTTSModel = ttsType != TTSModelType.UNKNOWN
        
        var audioSamples: FloatArray?
        var methodUsed: TTSMethod = TTSMethod.BUILT_IN
        
        if (isKnownTTSModel) {
            // Try Path 1: Built-in TTS method
            audioSamples = generateAudioFromText(contextHandle, text)
            methodUsed = TTSMethod.BUILT_IN
        } else {
            // Try Path 2: Custom TTS workflow
            audioSamples = generateAudioFromText(contextHandle, text)
            methodUsed = TTSMethod.CUSTOM_WORKFLOW
        }
        
        audioSamples ?: return Result.failure(TTSError.generationFailed())
        
        // Calculate duration
        val duration = audioSamples.size.toDouble() / options.sampleRate
        
        // Convert FloatArray to ShortArray
        val shortSamples = ShortArray(audioSamples.size) {
            ((audioSamples[it] * Short.MAX_VALUE).toInt()).toShort()
        }
        
        // Save to file if requested
        var savedFilePath: String? = null
        if (options.saveToFile && options.outputFilePath != null) {
            val saveSuccess = saveAudioToWav(contextHandle, options.outputFilePath, audioSamples, options.sampleRate)
            if (saveSuccess) {
                savedFilePath = options.outputFilePath
            } else {
                return Result.failure(TTSError.fileSaveFailed())
            }
        }
        
        // Create speech result
        val speechResult = SpeechResult(
            audioSamples = shortSamples,
            sampleRate = options.sampleRate,
            duration = duration,
            outputFilePath = savedFilePath,
            methodUsed = methodUsed
        )
        
        return Result.success(speechResult)
    }

    /**
     * Metadata for speech generation (used in streaming)
     */
    data class SpeechMetadata(
        val sampleRate: Int,
        val duration: Double,
        val methodUsed: TTSMethod,
        val outputFilePath: String?
    )

    /**
     * Audio chunk callback interface for streaming TTS
     */
    fun interface AudioChunkCallback {
        fun onAudioChunk(audioChunk: ShortArray)
    }

    /**
     * Generates speech from text with streaming support (simplified implementation)
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param audioChunkHandler Callback for receiving audio chunks
     * @return Result containing metadata about the generated speech
     */
    @JvmStatic
    fun generateSpeechStream(
        contextHandle: Long,
        text: String,
        options: TTSOptions = TTSOptions(),
        progressHandler: ((Float) -> Unit)? = null,
        audioChunkHandler: AudioChunkCallback
    ): Result<SpeechMetadata, TTSError> {
        // Generate full audio first (simplified streaming)
        val result = generateSpeech(contextHandle, text, options, progressHandler)
        
        if (result.isFailure()) {
            return Result.failure(result.exceptionOrNull() as TTSError)
        }
        
        val speechResult = result.getOrThrow()
        
        // Send the entire audio as a single chunk
        audioChunkHandler.onAudioChunk(speechResult.audioSamples)
        
        // Create metadata
        val metadata = SpeechMetadata(
            sampleRate = speechResult.sampleRate,
            duration = speechResult.duration,
            methodUsed = speechResult.methodUsed,
            outputFilePath = speechResult.outputFilePath
        )
        
        return Result.success(metadata)
    }

    /**
     * Generates speech from long text with real streaming capabilities
     * 
     * @param contextHandle Context handle obtained from initContext
     * @param text Long text to convert to speech
     * @param options TTS configuration options
     * @param progressHandler Optional callback for progress updates
     * @param audioChunkHandler Callback for receiving audio chunks as they're generated
     * @return Result containing metadata about the generated speech
     */
    @JvmStatic
    fun generateSpeechStreamForLongText(
        contextHandle: Long,
        text: String,
        options: TTSOptions = TTSOptions(),
        progressHandler: ((Float) -> Unit)? = null,
        audioChunkHandler: AudioChunkCallback
    ): Result<SpeechMetadata, TTSError> {
        // Check if context is valid
        if (contextHandle == 0L) {
            return Result.failure(TTSError.noModelLoaded())
        }
        
        // Check if vocoder is enabled
        if (!isVocoderEnabled(contextHandle)) {
            return Result.failure(TTSError.noVocoderEnabled())
        }
        
        // Split long text into sentences
        val sentences = text.split("[.!?]+\\s*")
        val totalSentences = sentences.size
        
        var totalDuration = 0.0
        var methodUsed: TTSMethod = TTSMethod.BUILT_IN
        var outputFilePath: String? = null
        
        for (i in sentences.indices) {
            val sentence = sentences[i].trim()
            if (sentence.isEmpty()) continue
            
            // Update progress
            progressHandler?.invoke(0.1f + ((i + 1).toFloat() / totalSentences) * 0.8f) // 0.1 to 0.9
            
            // Generate speech for this sentence
            val sentenceResult = generateSpeechSync(contextHandle, sentence, options)
            
            if (sentenceResult.isFailure()) {
                return Result.failure(sentenceResult.exceptionOrNull() as TTSError)
            }
            
            val speechResult = sentenceResult.getOrThrow()
            
            // Send audio chunk
            audioChunkHandler.onAudioChunk(speechResult.audioSamples)
            
            // Accumulate metadata
            totalDuration += speechResult.duration
            methodUsed = speechResult.methodUsed
            if (outputFilePath == null) {
                outputFilePath = speechResult.outputFilePath
            }
        }
        
        progressHandler?.invoke(1.0f) // Completed
        
        // Create metadata
        val metadata = SpeechMetadata(
            sampleRate = options.sampleRate,
            duration = totalDuration,
            methodUsed = methodUsed,
            outputFilePath = outputFilePath
        )
        
        return Result.success(metadata)
    }

    /**
     * Releases a llama context
     * 
     * @param contextHandle Context handle obtained from initContext
     */
    external fun releaseContext(contextHandle: Long)
}

