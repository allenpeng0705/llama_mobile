package com.llamamobile

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import org.json.JSONArray
import org.json.JSONObject

/** LlamaMobileFlutterSdkPlugin */
class LlamaMobileFlutterSdkPlugin :
    FlutterPlugin,
    MethodCallHandler,
    StreamHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    // Event channels for streaming
    private lateinit var tokenChannel: EventChannel
    private lateinit var progressChannel: EventChannel
    // Context for accessing resources
    private lateinit var context: Context
    // Map to store context handles
    private val contexts = mutableMapOf<Int, Long>()
    // Counter for generating unique handles
    private var nextHandle = 1
    // Event sinks for streaming
    private var tokenEventSink: EventSink? = null
    private var progressEventSink: EventSink? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk")
        channel.setMethodCallHandler(this)
        
        // Register event channels for streaming
        tokenChannel = EventChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk/token")
        tokenChannel.setStreamHandler(this)
        
        progressChannel = EventChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk/progress")
        progressChannel.setStreamHandler(this)
        
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        try {
            when (call.method) {
                "initContext" -> handleInitContext(call, result)
                "initContextAsync" -> handleInitContextAsync(call, result)
                "freeContext" -> handleFreeContext(call, result)
                "freeContextAsync" -> handleFreeContextAsync(call, result)
                "generateCompletion" -> handleGenerateCompletion(call, result)
                "generateCompletionAsync" -> handleGenerateCompletionAsync(call, result)
                "generateMultimodalCompletion" -> handleGenerateMultimodalCompletion(call, result)
                "generateMultimodalCompletionAsync" -> handleGenerateMultimodalCompletionAsync(call, result)
                "generateStreamingCompletion" -> handleGenerateStreamingCompletion(call, result)
                "generateStreamingCompletionAsync" -> handleGenerateStreamingCompletionAsync(call, result)
                "generateStreamingOpenAICompletion" -> handleGenerateStreamingOpenAICompletion(call, result)
                "generateStreamingOpenAICompletionAsync" -> handleGenerateStreamingOpenAICompletionAsync(call, result)
                "stopCompletion" -> handleStopCompletion(call, result)
                "formatChatMessages" -> handleFormatChatMessages(call, result)
                "formatChatMessagesAsync" -> handleFormatChatMessagesAsync(call, result)

                "loadGrammar" -> handleLoadGrammar(call, result)
                "generateEmbedding" -> handleGenerateEmbedding(call, result)
                "generateEmbeddingAsync" -> handleGenerateEmbeddingAsync(call, result)
                "tokenize" -> handleTokenize(call, result)
                "detokenize" -> handleDetokenize(call, result)
                "loadLoraAdapter" -> handleLoadLoraAdapter(call, result)
                "loadLoraAdapterAsync" -> handleLoadLoraAdapterAsync(call, result)
                "freeLoraAdapter" -> handleFreeLoraAdapter(call, result)
                "freeLoraAdapterAsync" -> handleFreeLoraAdapterAsync(call, result)
                "loadTTSModel" -> handleLoadTTSModel(call, result)
                "loadTTSModelAsync" -> handleLoadTTSModelAsync(call, result)
                "generateAudio" -> handleGenerateAudio(call, result)
                "freeTTSModel" -> handleFreeTTSModel(call, result)
                "freeTTSModelAsync" -> handleFreeTTSModelAsync(call, result)
                "saveAudioToWav" -> handleSaveAudioToWav(call, result)
                "saveAudioToWavAsync" -> handleSaveAudioToWavAsync(call, result)
                "initMultimodal" -> handleInitMultimodal(call, result)
                "initMultimodalAsync" -> handleInitMultimodalAsync(call, result)
                "releaseMultimodal" -> handleReleaseMultimodal(call, result)
                "releaseMultimodalAsync" -> handleReleaseMultimodalAsync(call, result)
                "initVocoder" -> handleInitVocoder(call, result)
                "initVocoderAsync" -> handleInitVocoderAsync(call, result)
                "releaseVocoder" -> handleReleaseVocoder(call, result)
                "releaseVocoderAsync" -> handleReleaseVocoderAsync(call, result)
                "clearConversation" -> handleClearConversation(call, result)
                "isConversationActive" -> handleIsConversationActive(call, result)
                "removeLoraAdapters" -> handleRemoveLoraAdapters(call, result)
                "removeLoraAdaptersAsync" -> handleRemoveLoraAdaptersAsync(call, result)
                "generateAudioFromText" -> handleGenerateAudioFromText(call, result)
                "getFormattedAudioCompletion" -> handleGetFormattedAudioCompletion(call, result)
                "getAudioGuideTokens" -> handleGetAudioGuideTokens(call, result)
                "setGuideTokens" -> handleSetGuideTokens(call, result)
                "decodeAudioTokens" -> handleDecodeAudioTokens(call, result)
                "generateSpeechSync" -> handleGenerateSpeechSync(call, result)
                "generateSpeech" -> handleGenerateSpeech(call, result)
                "generateSpeechAsync" -> handleGenerateSpeechAsync(call, result)
                "generateSpeechStream" -> handleGenerateSpeechStream(call, result)
                "generateSpeechStreamAsync" -> handleGenerateSpeechStreamAsync(call, result)
                "generateSpeechStreamForLongText" -> handleGenerateSpeechStreamForLongText(call, result)
                "generateSpeechStreamForLongTextAsync" -> handleGenerateSpeechStreamForLongTextAsync(call, result)
                "setLogLevel" -> handleSetLogLevel(call, result)
                "downloadModel" -> handleDownloadModel(call, result)
                "downloadModelAsync" -> handleDownloadModelAsync(call, result)
                "downloadHfFile" -> handleDownloadHfFile(call, result)
                "downloadHfFileAsync" -> handleDownloadHfFileAsync(call, result)
                "generateOpenAICompletion" -> handleGenerateOpenAICompletion(call, result)
                "generateOpenAICompletionAsync" -> handleGenerateOpenAICompletionAsync(call, result)
                "getContextWindowSize" -> handleGetContextWindowSize(call, result)
                "getEmbeddingDimension" -> handleGetEmbeddingDimension(call, result)
                "getModelDescription" -> handleGetModelDescription(call, result)
                "getModelSize" -> handleGetModelSize(call, result)
                "getModelParametersCount" -> handleGetModelParametersCount(call, result)
                "getLoadedLoraAdapters" -> handleGetLoadedLoraAdapters(call, result)
                "isMultimodalEnabled" -> handleIsMultimodalEnabled(call, result)
                "supportsVision" -> handleSupportsVision(call, result)
                "supportsAudio" -> handleSupportsAudio(call, result)
                "isVocoderEnabled" -> handleIsVocoderEnabled(call, result)
                "getTTSType" -> handleGetTTSType(call, result)
                "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ANDROID_ERROR", e.message, e.stackTraceToString())
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        tokenChannel.setStreamHandler(null)
        progressChannel.setStreamHandler(null)
        // Free all contexts when detaching
        contexts.values.forEach { LlamaMobile.releaseContext(it) }
        contexts.clear()
        // Clear event sinks
        tokenEventSink = null
        progressEventSink = null
    }

    // MARK: - StreamHandler Methods
    override fun onListen(arguments: Any?, events: EventSink) {
        if (arguments is String) {
            when (arguments) {
                "token" -> tokenEventSink = events
                "progress" -> progressEventSink = events
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        if (arguments is String) {
            when (arguments) {
                "token" -> tokenEventSink = null
                "progress" -> progressEventSink = null
            }
        }
    }

    // MARK: - Context Management
    private fun handleInitContext(call: MethodCall, result: Result) {
        val modelPath = call.argument<String>("modelPath") ?: throw IllegalArgumentException("modelPath is required")
        val chatTemplate = call.argument<String>("chatTemplate")
        val systemPrompt = call.argument<String>("systemPrompt")
        val nCtx = call.argument<Int>("nCtx") ?: 2048
        val nBatch = call.argument<Int>("nBatch") ?: 512
        val nUBatch = call.argument<Int>("nUBatch") ?: 512
        val nGpuLayers = call.argument<Int>("nGpuLayers") ?: 0
        val nThreads = call.argument<Int>("nThreads") ?: 4
        val useMmap = call.argument<Boolean>("useMmap") ?: true
        val useMlock = call.argument<Boolean>("useMlock") ?: false
        val embedding = call.argument<Boolean>("embedding") ?: false
        val poolingType = call.argument<Int>("poolingType") ?: 0
        val embdNormalize = call.argument<Int>("embdNormalize") ?: 0
        val flashAttention = call.argument<Boolean>("flashAttention") ?: false
        val cacheTypeK = call.argument<String>("cacheTypeK")
        val cacheTypeV = call.argument<String>("cacheTypeV")

        val initParams = LlamaMobile.InitParams(
            modelPath,
            nCtx,
            chatTemplate,
            systemPrompt,
            nBatch,
            nUBatch,
            nGpuLayers,
            nThreads,
            useMmap,
            useMlock,
            embedding,
            poolingType,
            embdNormalize,
            flashAttention,
            cacheTypeK,
            cacheTypeV,
            true, // enableChatTemplate
            null // progressCallback
        )

        val contextHandle = LlamaMobile.initContext(initParams)

        if (contextHandle != 0L) {
            val handle = nextHandle++
            contexts[handle] = contextHandle
            result.success(mapOf("contextHandle" to handle))
        } else {
            result.error("INIT_FAILED", "Failed to initialize context", null)
        }
    }

    private fun handleFreeContext(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts.remove(handle)
        if (contextHandle != null) {
            LlamaMobile.releaseContext(contextHandle)
            result.success(true)
        } else {
            result.success(false)
        }
    }

    // MARK: - Completion Methods
    private fun handleGenerateCompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val maxTokens = params["maxTokens"] as? Int ?: 128
        val nThreads = params["nThreads"] as? Int
        val seed = params["seed"] as? Int ?: -1
        val temperature = (params["temperature"] as? Double ?: 0.8).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.1).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false
        val nProbs = params["nProbs"] as? Int ?: 0
        val jsonSchema = params["jsonSchema"] as? String
        val tools = params["tools"] as? String
        val parallelToolCalls = params["parallelToolCalls"] as? Boolean ?: false
        val toolChoice = params["toolChoice"] as? String

        val completionParams = if (params.containsKey("chatMessages")) {
            val chatMessages = params["chatMessages"] as? List<Map<String, String?>>
            if (!chatMessages.isNullOrEmpty()) {
                val messages = chatMessages.map { msg ->
                    LlamaMobile.ChatMessage(
                        msg["role"] ?: "",
                        msg["content"] ?: "",
                        msg["reasoning_content"],
                        msg["tool_name"],
                        msg["tool_call_id"]
                    )
                }
                // For chat messages, use the full constructor with chatMessages parameter
                LlamaMobile.CompletionParams(
                    "", // prompt
                    temperature,
                    maxTokens,
                    nThreads,
                    seed,
                    topK,
                    topP.toDouble(),
                    minP.toDouble(),
                    typicalP.toDouble(),
                    penaltyLastN,
                    penaltyRepeat.toDouble(),
                    penaltyFreq.toDouble(),
                    penaltyPresent.toDouble(),
                    mirostat,
                    mirostatTau.toDouble(),
                    mirostatEta.toDouble(),
                    ignoreEos,
                    nProbs,
                    grammar,
                    stopSequences,
                    emptyList(), // mediaPaths
                    null, // tokenCallback
                    messages, // chatMessages
                    useJsonResponse,
                    jsonSchema,
                    tools,
                    parallelToolCalls,
                    toolChoice
                )
            } else {
                val prompt = params["prompt"] as? String ?: ""
                LlamaMobile.CompletionParams(prompt)
            }
        } else {
            val prompt = params["prompt"] as? String ?: ""
            LlamaMobile.CompletionParams(prompt)
        }

        val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

        if (completion != null) {
            result.success(mapOf(
                "text" to completion.getText(),
                "tokensGenerated" to completion.getTokensGenerated(),
                "tokensEvaluated" to completion.getTokensEvaluated(),
                "truncated" to completion.isTruncated(),
                "stoppedEos" to completion.isStoppedEos(),
                "stoppedWord" to completion.isStoppedWord(),
                "stoppedLimit" to false,
                "stoppingWord" to ""
            ))
        } else {
            result.error("COMPLETION_FAILED", "Failed to generate completion", null)
        }
    }

    private fun handleGenerateMultimodalCompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val mediaPaths = call.argument<List<String>>("mediaPaths") ?: throw IllegalArgumentException("mediaPaths is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val maxTokens = params["maxTokens"] as? Int ?: 128
        val nThreads = params["nThreads"] as? Int
        val seed = params["seed"] as? Int ?: -1
        val temperature = (params["temperature"] as? Double ?: 0.8).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.1).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false
        val nProbs = params["nProbs"] as? Int ?: 0
        val jsonSchema = params["jsonSchema"] as? String
        val tools = params["tools"] as? String
        val parallelToolCalls = params["parallelToolCalls"] as? Boolean ?: false
        val toolChoice = params["toolChoice"] as? String

        val completionParams = if (params.containsKey("chatMessages")) {
            val chatMessages = params["chatMessages"] as? List<Map<String, String?>>
            if (!chatMessages.isNullOrEmpty()) {
                val messages = chatMessages.map { msg ->
                    LlamaMobile.ChatMessage(
                        msg["role"] ?: "",
                        msg["content"] ?: "",
                        msg["reasoning_content"],
                        msg["tool_name"],
                        msg["tool_call_id"]
                    )
                }
                // For chat messages, use the full constructor with chatMessages parameter
                LlamaMobile.CompletionParams(
                    "", // prompt
                    temperature,
                    maxTokens,
                    nThreads,
                    seed,
                    topK,
                    topP.toDouble(),
                    minP.toDouble(),
                    typicalP.toDouble(),
                    penaltyLastN,
                    penaltyRepeat.toDouble(),
                    penaltyFreq.toDouble(),
                    penaltyPresent.toDouble(),
                    mirostat,
                    mirostatTau.toDouble(),
                    mirostatEta.toDouble(),
                    ignoreEos,
                    nProbs,
                    grammar,
                    stopSequences,
                    emptyList(), // mediaPaths
                    null, // tokenCallback
                    messages, // chatMessages
                    useJsonResponse,
                    jsonSchema,
                    tools,
                    parallelToolCalls,
                    toolChoice
                )
            } else {
                val prompt = params["prompt"] as? String ?: ""
                LlamaMobile.CompletionParams(prompt)
            }
        } else {
            val prompt = params["prompt"] as? String ?: ""
            LlamaMobile.CompletionParams(prompt)
        }

        val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

        if (completion != null) {
            result.success(mapOf(
                "text" to completion.getText(),
                "tokensGenerated" to completion.getTokensGenerated(),
                "tokensEvaluated" to completion.getTokensEvaluated(),
                "truncated" to completion.isTruncated(),
                "stoppedEos" to completion.isStoppedEos(),
                "stoppedWord" to completion.isStoppedWord(),
                "stoppedLimit" to false,
                "stoppingWord" to ""
            ))
        } else {
            result.error("COMPLETION_FAILED", "Failed to generate multimodal completion", null)
        }
    }

    private fun handleFormatChatMessages(call: MethodCall, result: Result) {
        val messages = call.argument<List<Map<String, String>>>("messages") ?: throw IllegalArgumentException("messages is required")
        val chatTemplate = call.argument<String>("chatTemplate") ?: throw IllegalArgumentException("chatTemplate is required")

        if (chatTemplate != null) {
            var formattedPrompt = StringBuilder()
            
            for (message in messages) {
                val role = message["role"] ?: continue
                val content = message["content"] ?: continue
                
                var messageTemplate = chatTemplate
                messageTemplate = messageTemplate.replace("{{role}}", role)
                messageTemplate = messageTemplate.replace("{{content}}", content)
                formattedPrompt.append(messageTemplate)
            }
            
            var assistantTurnTemplate = chatTemplate
            assistantTurnTemplate = assistantTurnTemplate.replace("{{role}}", "assistant")
            
            val contentPlaceholderIndex = assistantTurnTemplate.indexOf("{{content}}")
            if (contentPlaceholderIndex >= 0) {
                assistantTurnTemplate = assistantTurnTemplate.substring(0, contentPlaceholderIndex)
            }
            
            assistantTurnTemplate = assistantTurnTemplate.trim()
            formattedPrompt.append(assistantTurnTemplate).append("\n")
            
            result.success(formattedPrompt.toString())
        } else {
            result.error("TEMPLATE_MISSING", "No chat template provided", null)
        }
    }

    // MARK: - Utility Methods
    private fun handleLoadGrammar(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val grammarPath = call.argument<String>("grammarPath") ?: throw IllegalArgumentException("grammarPath is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Read grammar file content directly
        try {
            val grammarFile = java.io.File(grammarPath)
            if (!grammarFile.exists()) {
                result.error("GRAMMAR_FILE_NOT_FOUND", "Grammar file not found: $grammarPath", null)
                return
            }
            val grammarContent = grammarFile.readText()
            result.success(grammarContent)
        } catch (e: Exception) {
            result.error("GRAMMAR_LOAD_FAILED", "Failed to load grammar from path: $grammarPath, error: ${e.message}", null)
        }
    }

    // MARK: - Embedding Methods
    private fun handleGenerateEmbedding(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val embedding = LlamaMobile.generateEmbeddings(contextHandle, text)
        if (embedding != null) {
            result.success(embedding.toList())
        } else {
            result.error("EMBEDDING_FAILED", "Failed to generate embedding", null)
        }
    }

    // MARK: - Tokenization Methods
    private fun handleTokenize(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val tokens = LlamaMobile.tokenize(contextHandle, text)
        if (tokens != null) {
            result.success(tokens.toList())
        } else {
            result.error("TOKENIZE_FAILED", "Failed to tokenize text", null)
        }
    }

    private fun handleDetokenize(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val tokens = call.argument<List<Int>>("tokens") ?: throw IllegalArgumentException("tokens is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val text = LlamaMobile.detokenize(contextHandle, tokens.toIntArray())
        if (text != null) {
            result.success(text)
        } else {
            result.error("DETOKENIZE_FAILED", "Failed to detokenize tokens", null)
        }
    }

    // MARK: - LoRA Methods
    private fun handleLoadLoraAdapter(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val adapterPath = call.argument<String>("adapterPath") ?: throw IllegalArgumentException("adapterPath is required")
        val scale = (call.argument<Double>("scale") ?: 1.0).toFloat()
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Create a LoraAdapter and apply it
        val adapter = LlamaMobile.LoraAdapter(adapterPath, scale)
        val success = LlamaMobile.applyLoraAdapters(contextHandle, arrayOf(adapter))
        result.success(success)
    }

    private fun handleFreeLoraAdapter(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.removeLoraAdapters(contextHandle)
        result.success(true)
    }

    // MARK: - TTS Methods
    private fun handleLoadTTSModel(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val modelPath = call.argument<String>("modelPath") ?: throw IllegalArgumentException("modelPath is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // In Android SDK, we use initVocoder instead of loadTTSModel
        val success = LlamaMobile.initVocoder(contextHandle, modelPath)
        if (success) {
            val ttsType = LlamaMobile.getTTSType(contextHandle)
            result.success(mapOf(
                "success" to true,
                "modelType" to ttsType.ordinal
            ))
        } else {
            result.success(mapOf(
                "success" to false,
                "modelType" to -1
            ))
        }
    }

    private fun handleGenerateAudio(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")

        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Check if vocoder is initialized
        if (!LlamaMobile.isVocoderEnabled(contextHandle)) {
            result.error("VOCODER_NOT_INITIALIZED", "TTS model not loaded", null)
            return
        }

        // Get TTS model type for debugging
        val ttsType = LlamaMobile.getTTSType(contextHandle)
        print("TTS Model Type: $ttsType")

        val speakerJson = "{\"speaker\": \"default\"}"

        // Step 1: Format the text to get the proper prompt
        val formattedPrompt = LlamaMobile.getFormattedAudioCompletion(contextHandle, speakerJson, text)
        if (formattedPrompt == null) {
            result.error("FORMAT_FAILED", "Failed to format text for TTS", null)
            return
        }

        print("Formatted prompt: $formattedPrompt")

        // Step 2: Generate audio content using text completion
        val completionParams = LlamaMobile.CompletionParams(
            formattedPrompt,
            0.0f, // temperature - Deterministic output
            200 // maxTokens - Generate appropriate audio content
        )

        val completionResult = LlamaMobile.generateCompletion(contextHandle, completionParams)
        if (completionResult == null) {
            result.error("COMPLETION_FAILED", "Failed to generate audio content", null)
            return
        }

        print("Completion result: ${completionResult.text}")

        // Check if prompt contains template markers
        val useOnlyCompletion = formattedPrompt.contains("<|audio_start|") || formattedPrompt.contains("<|text_start|")
        print("Use only completion: $useOnlyCompletion")

        // Combine prompt and completion for full audio tokens - or just use completion if prompt contains template markers
        val contentToTokenize = if (useOnlyCompletion) {
            // If prompt contains template markers, only use the completion result (prevents audio from template)
            print("Using only completion result for tokenization")
            completionResult.text
        } else {
            // Otherwise combine both
            print("Combining prompt and completion for tokenization")
            formattedPrompt + completionResult.text
        }

        print("Content to tokenize: $contentToTokenize")

        // Step 3: Tokenize the audio content
        val tokens = LlamaMobile.tokenize(contextHandle, contentToTokenize)
        if (tokens == null) {
            result.error("TOKENIZATION_FAILED", "Failed to tokenize audio content", null)
            return
        }

        print("Total tokens: ${tokens.size}")
        print("First 10 tokens: ${tokens.take(10)}")
        print("Last 10 tokens: ${tokens.takeLast(10)}")

        // Step 4: Filter audio tokens (151672-155772)
        val audioStartToken = 151672
        val audioEndToken = 155772
        val audioTokens = mutableListOf<Int>()
        var nonAudioTokens = 0

        for (token in tokens) {
            // Check if token is in audio range
            if (token >= audioStartToken && token <= audioEndToken) {
                audioTokens.add(token)
            } else {
                nonAudioTokens++
            }
        }

        print("Filtered audio tokens: ${audioTokens.size}")
        print("Non-audio tokens: $nonAudioTokens")
        print("First 10 audio tokens: ${audioTokens.take(10)}")

        // Step 5: Decode the audio tokens
        if (audioTokens.isEmpty()) {
            result.error("NO_AUDIO_TOKENS", "No audio tokens generated", null)
            return
        }

        val decodedAudioData = LlamaMobile.decodeAudioTokens(contextHandle, audioTokens.toIntArray())
        if (decodedAudioData == null) {
            result.error("DECODE_FAILED", "Failed to decode audio tokens", null)
            return
        }

        print("Decoded audio data count: ${decodedAudioData.size}")

        // Convert to int audio data
        val intAudioData = decodedAudioData.map { (it * Short.MAX_VALUE).toInt() }
        result.success(mapOf(
            "audioData" to intAudioData
        ))
    }

    private fun handleFreeTTSModel(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.releaseVocoder(contextHandle)
        result.success(true)
    }

    private fun handleInitMultimodal(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val mmprojPath = call.argument<String>("mmprojPath") ?: throw IllegalArgumentException("mmprojPath is required")
        val useGpu = call.argument<Boolean>("useGpu") ?: false
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val success = LlamaMobile.initMultimodal(contextHandle, mmprojPath, useGpu)
        result.success(success)
    }

    private fun handleReleaseMultimodal(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.releaseMultimodal(contextHandle)
        result.success(null)
    }

    private fun handleInitVocoder(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val vocoderModelPath = call.argument<String>("vocoderModelPath") ?: throw IllegalArgumentException("vocoderModelPath is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val success = LlamaMobile.initVocoder(contextHandle, vocoderModelPath)
        result.success(success)
    }

    private fun handleReleaseVocoder(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.releaseVocoder(contextHandle)
        result.success(null)
    }

    private fun handleClearConversation(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.clearConversation(contextHandle)
        result.success(null)
    }

    private fun handleIsConversationActive(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val isActive = LlamaMobile.isConversationActive(contextHandle)
        result.success(isActive)
    }

    private fun handleRemoveLoraAdapters(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        LlamaMobile.removeLoraAdapters(contextHandle)
        result.success(null)
    }

    private fun handleGenerateAudioFromText(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val speakerJson = call.argument<String>("speakerJson") ?: throw IllegalArgumentException("speakerJson is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val audioSamples = LlamaMobile.generateAudioFromText(contextHandle, text, speakerJson)
        if (audioSamples != null) {
            result.success(audioSamples.toList())
        } else {
            result.error("AUDIO_GENERATION_FAILED", "Failed to generate audio from text", null)
        }
    }

    private fun handleGetFormattedAudioCompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val speakerJson = call.argument<String>("speakerJson") ?: throw IllegalArgumentException("speakerJson is required")
        val textToSpeak = call.argument<String>("textToSpeak") ?: throw IllegalArgumentException("textToSpeak is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val formattedCompletion = LlamaMobile.getFormattedAudioCompletion(contextHandle, speakerJson, textToSpeak)
        result.success(formattedCompletion)
    }

    private fun handleGetAudioGuideTokens(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val textToSpeak = call.argument<String>("textToSpeak") ?: throw IllegalArgumentException("textToSpeak is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val guideTokens = LlamaMobile.getAudioGuideTokens(contextHandle, textToSpeak)
        if (guideTokens != null) {
            result.success(guideTokens.toList())
        } else {
            result.error("GET_GUIDE_TOKENS_FAILED", "Failed to get audio guide tokens", null)
        }
    }

    private fun handleSetGuideTokens(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val tokens = call.argument<List<Int>>("tokens") ?: throw IllegalArgumentException("tokens is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val intArray = tokens.toIntArray()
        LlamaMobile.setGuideTokens(contextHandle, intArray)
        result.success(null)
    }

    private fun handleDecodeAudioTokens(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val tokens = call.argument<List<Int>>("tokens") ?: throw IllegalArgumentException("tokens is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val intArray = tokens.toIntArray()
        val audioSamples = LlamaMobile.decodeAudioTokens(contextHandle, intArray)
        if (audioSamples != null) {
            result.success(audioSamples.toList())
        } else {
            result.error("DECODE_AUDIO_TOKENS_FAILED", "Failed to decode audio tokens", null)
        }
    }

    private fun handleGenerateSpeechSync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)
        val speechResult = LlamaMobile.generateSpeechSync(contextHandle, text, options)

        if (speechResult != null && speechResult.isSuccess()) {
            val speech = speechResult.value
            // Convert short[] to List<Int> for Flutter compatibility
            val audioSamplesList = speech.getAudioSamples()?.map { it.toInt() } ?: emptyList()
            result.success(mapOf(
                "audioSamples" to audioSamplesList,
                "sampleRate" to speech.getSampleRate(),
                "duration" to speech.getDuration(),
                "outputFilePath" to (speech.getOutputFilePath() ?: null),
                "methodUsed" to speech.getMethodUsed().ordinal
            ))
        } else {
            val error = speechResult?.error
            result.error("SPEECH_GENERATION_FAILED", error?.toString() ?: "Failed to generate speech", null)
        }
    }

    private fun handleGenerateSpeech(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            val speechResult = LlamaMobile.generateSpeech(contextHandle, text, options, null)

            if (speechResult != null && speechResult.isSuccess()) {
                val speech = speechResult.value
                // Convert short[] to List<Int> for Flutter compatibility
                val audioSamplesList = speech.getAudioSamples()?.map { it.toInt() } ?: emptyList()
                result.success(mapOf(
                    "audioSamples" to audioSamplesList,
                    "sampleRate" to speech.getSampleRate(),
                    "duration" to speech.getDuration(),
                    "outputFilePath" to (speech.getOutputFilePath() ?: null),
                    "methodUsed" to speech.getMethodUsed().ordinal
                ))
            } else {
                val error = speechResult?.error
                result.error("SPEECH_GENERATION_FAILED", error?.toString() ?: "Failed to generate speech", null)
            }
        }.start()
    }

    private fun handleGenerateSpeechStream(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            val speechResult = LlamaMobile.generateSpeechStream(
                contextHandle,
                text,
                options,
                null,
                null
            )

            if (speechResult != null && speechResult.isSuccess()) {
                val metadata = speechResult.value
                result.success(mapOf(
                    "sampleRate" to metadata.getSampleRate(),
                    "duration" to metadata.getDuration(),
                    "outputFilePath" to (metadata.getOutputFilePath() ?: null),
                    "methodUsed" to metadata.getMethodUsed().ordinal
                ))
            } else {
                val error = speechResult?.error
                result.error("SPEECH_STREAM_FAILED", error?.toString() ?: "Failed to generate speech stream", null)
            }
        }.start()
    }

    private fun handleGenerateSpeechStreamForLongText(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            val speechResult = LlamaMobile.generateSpeechStreamForLongText(
                contextHandle,
                text,
                options,
                null,
                null
            )

            if (speechResult != null && speechResult.isSuccess()) {
                val metadata = speechResult.value
                result.success(mapOf(
                    "sampleRate" to metadata.getSampleRate(),
                    "duration" to metadata.getDuration(),
                    "outputFilePath" to (metadata.getOutputFilePath() ?: null),
                    "methodUsed" to metadata.getMethodUsed().ordinal
                ))
            } else {
                val error = speechResult?.error
                result.error("SPEECH_STREAM_FAILED", error?.toString() ?: "Failed to generate speech stream", null)
            }
        }.start()
    }

    private fun parseTTSOptions(optionsMap: Map<String, Any>?): LlamaMobile.TTSOptions {
        if (optionsMap == null) {
            return LlamaMobile.TTSOptions.Builder().build()
        }

        val builder = LlamaMobile.TTSOptions.Builder()
        builder.sampleRate((optionsMap["sampleRate"] as? Int) ?: 24000)
        builder.voice(optionsMap["voice"] as? String)
        builder.speed(((optionsMap["speed"] as? Double) ?: 1.0).toFloat())
        builder.saveToFile((optionsMap["saveToFile"] as? Boolean) ?: false)
        builder.outputFilePath(optionsMap["outputFilePath"] as? String)
        return builder.build()
    }

    private fun handleSetLogLevel(call: MethodCall, result: Result) {
        val level = call.argument<Int>("level") ?: throw IllegalArgumentException("level is required")

        result.success(null)
    }

    private fun handleSaveAudioToWav(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val filePath = call.argument<String>("filePath") ?: throw IllegalArgumentException("filePath is required")
        val audioData = call.argument<List<Int>>("audioData") ?: throw IllegalArgumentException("audioData is required")
        val sampleRate = call.argument<Int>("sampleRate") ?: throw IllegalArgumentException("sampleRate is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Convert List<Int> to FloatArray (assuming 16-bit PCM)
        val floatAudioData = FloatArray(audioData.size) {
            audioData[it].toFloat() / 32768.0f // Normalize 16-bit to [-1, 1]
        }

        val success = LlamaMobile.saveAudioToWav(contextHandle, filePath, floatAudioData, sampleRate)
        result.success(success)
    }

    private fun handleSaveAudioToWavAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val filePath = call.argument<String>("filePath") ?: throw IllegalArgumentException("filePath is required")
        val audioData = call.argument<List<Int>>("audioData") ?: throw IllegalArgumentException("audioData is required")
        val sampleRate = call.argument<Int>("sampleRate") ?: throw IllegalArgumentException("sampleRate is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                // Convert List<Int> to FloatArray (assuming 16-bit PCM)
                val floatAudioData = FloatArray(audioData.size) {
                    audioData[it].toFloat() / 32768.0f // Normalize 16-bit to [-1, 1]
                }

                val success = LlamaMobile.saveAudioToWav(contextHandle, filePath, floatAudioData, sampleRate)
                result.success(success)
            } catch (e: Exception) {
                result.error("SAVE_AUDIO_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateOpenAICompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val openAIJSON = call.argument<String>("openAIJSON") ?: throw IllegalArgumentException("openAIJSON is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val completionResult = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON)
        if (completionResult != null) {
            result.success(mapOf(
                "text" to completionResult.getText(),
                "tokensGenerated" to completionResult.getTokensGenerated(),
                "tokensEvaluated" to completionResult.getTokensEvaluated(),
                "truncated" to completionResult.isTruncated(),
                "stoppedEos" to completionResult.isStoppedEos(),
                "stoppedWord" to completionResult.isStoppedWord(),
                "stoppedLimit" to false,
                "stoppingWord" to ""
            ))
        } else {
            result.error("COMPLETION_FAILED", "Failed to generate completion", null)
        }
    }

    // MARK: - Streaming Methods
    private fun handleGenerateStreamingCompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val prompt = params["prompt"] as? String ?: throw IllegalArgumentException("prompt is required")
        val maxTokens = params["maxTokens"] as? Int ?: 128
        val nThreads = params["nThreads"] as? Int
        val seed = params["seed"] as? Int ?: -1
        val temperature = (params["temperature"] as? Double ?: 0.8).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.1).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false

        val completionParams = LlamaMobile.CompletionParams(
            prompt,
            temperature,
            maxTokens,
            null, // nThreads
            -1, // seed
            topK,
            topP.toDouble(),
            minP.toDouble(),
            typicalP.toDouble(),
            penaltyLastN,
            penaltyRepeat.toDouble(),
            penaltyFreq.toDouble(),
            penaltyPresent.toDouble(),
            mirostat,
            mirostatTau.toDouble(),
            mirostatEta.toDouble(),
            ignoreEos,
            0, // nProbs
            grammar,
            stopSequences,
            emptyList(), // mediaPaths
            { token ->
                // Send token to Flutter
                Handler(Looper.getMainLooper()).post {
                    tokenEventSink?.success(token)
                }
                true
            } // tokenCallback
        )

        // Run generation in background thread
        Thread {
            try {
                val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("COMPLETION_FAILED", "Failed to generate completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleGenerateStreamingOpenAICompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val openAIJSON = call.argument<String>("openAIJSON") ?: throw IllegalArgumentException("openAIJSON is required")
        val grammar = call.argument<String>("grammar")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Run generation in background thread
        Thread {
            try {
                val completion = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("OPENAI_COMPLETION_FAILED", "Failed to generate OpenAI completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleGenerateStreamingOpenAICompletionAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val openAIJSON = call.argument<String>("openAIJSON") ?: throw IllegalArgumentException("openAIJSON is required")
        val grammar = call.argument<String>("grammar")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Run generation in background thread
        Thread {
            try {
                val completion = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("OPENAI_COMPLETION_FAILED", "Failed to generate OpenAI completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleStopCompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val success = LlamaMobile.stopCompletion(contextHandle)
        result.success(success)
    }

    // MARK: - Model Info Methods
    private fun handleGetContextWindowSize(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val windowSize = LlamaMobile.getContextWindowSize(contextHandle)
        result.success(windowSize)
    }

    private fun handleGetEmbeddingDimension(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val dimension = LlamaMobile.getEmbeddingDimension(contextHandle)
        result.success(dimension)
    }

    private fun handleGetModelDescription(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val description = LlamaMobile.getModelDescription(contextHandle)
        result.success(description)
    }

    private fun handleGetModelSize(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val size = LlamaMobile.getModelSize(contextHandle)
        result.success(size)
    }

    private fun handleGetModelParametersCount(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val count = LlamaMobile.getModelParametersCount(contextHandle)
        result.success(count)
    }

    // MARK: - LoRA Methods
    private fun handleGetLoadedLoraAdapters(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val adapters = LlamaMobile.getLoadedLoraAdapters(contextHandle)
        result.success(adapters)
    }

    // MARK: - Download Methods
    private fun handleDownloadHfFile(call: MethodCall, result: Result) {
        val repoId = call.argument<String>("repoId") ?: throw IllegalArgumentException("repoId is required")
        val filename = call.argument<String>("filename") ?: throw IllegalArgumentException("filename is required")
        val localPath = call.argument<String>("localPath") ?: throw IllegalArgumentException("localPath is required")
        val bearerToken = call.argument<String>("bearerToken")
        val offline = call.argument<Boolean>("offline") ?: false

        // Run download in background thread
        Thread {
            try {
                val resultObj = LlamaMobile.downloadHfFile(
                    repoId,
                    filename,
                    localPath,
                    bearerToken,
                    offline
                ) { progress, status, downloadedBytes, totalBytes ->
                    progressEventSink?.success(progress)
                }
                result.success(mapOf(
                    "success" to (resultObj?.isSuccess() ?: false),
                    "localPath" to (resultObj?.getLocalPath() ?: ""),
                    "errorMessage" to (resultObj?.getErrorMessage() ?: "")
                ))
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleDownloadModel(call: MethodCall, result: Result) {
        val url = call.argument<String>("url") ?: throw IllegalArgumentException("url is required")
        val localPath = call.argument<String>("localPath") ?: throw IllegalArgumentException("localPath is required")

        // Create download parameters using builder pattern
        val downloadParamsBuilder = LlamaMobile.DownloadParams.Builder(url, "", localPath)
        val downloadParams = downloadParamsBuilder.build()

        // Run download in background thread
        Thread {
            try {
                val resultObj = LlamaMobile.downloadModel(downloadParams) { progress, status, downloadedBytes, totalBytes ->
                    progressEventSink?.success(progress)
                }

                result.success(mapOf(
                    "success" to (resultObj?.isSuccess() ?: false),
                    "localPath" to (resultObj?.getLocalPath() ?: ""),
                    "errorMessage" to (resultObj?.getErrorMessage() ?: "")
                ))
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    // MARK: - Multimodal Methods
    private fun handleIsMultimodalEnabled(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val enabled = LlamaMobile.isMultimodalEnabled(contextHandle)
        result.success(enabled)
    }

    private fun handleSupportsVision(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val supported = LlamaMobile.supportsVision(contextHandle)
        result.success(supported)
    }

    private fun handleSupportsAudio(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val supported = LlamaMobile.supportsAudio(contextHandle)
        result.success(supported)
    }

    // MARK: - TTS Methods
    private fun handleIsVocoderEnabled(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val enabled = LlamaMobile.isVocoderEnabled(contextHandle)
        result.success(enabled)
    }

    private fun handleGetTTSType(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val ttsType = LlamaMobile.getTTSType(contextHandle)
        result.success(ttsType.ordinal)
    }

    // MARK: - Async Methods

    private fun handleInitContextAsync(call: MethodCall, result: Result) {
        val modelPath = call.argument<String>("modelPath") ?: throw IllegalArgumentException("modelPath is required")
        val chatTemplate = call.argument<String>("chatTemplate")
        val systemPrompt = call.argument<String>("systemPrompt")
        val nCtx = call.argument<Int>("nCtx") ?: 2048
        val nBatch = call.argument<Int>("nBatch") ?: 512
        val nUBatch = call.argument<Int>("nUBatch") ?: 512
        val nGpuLayers = call.argument<Int>("nGpuLayers") ?: 0
        val nThreads = call.argument<Int>("nThreads") ?: 4
        val useMmap = call.argument<Boolean>("useMmap") ?: true
        val useMlock = call.argument<Boolean>("useMlock") ?: false
        val embedding = call.argument<Boolean>("embedding") ?: false
        val poolingType = call.argument<Int>("poolingType") ?: 0
        val embdNormalize = call.argument<Int>("embdNormalize") ?: 0
        val flashAttention = call.argument<Boolean>("flashAttention") ?: false
        val cacheTypeK = call.argument<String>("cacheTypeK")
        val cacheTypeV = call.argument<String>("cacheTypeV")

        Thread {
            try {
                val initParams = LlamaMobile.InitParams(
                    modelPath,
                    nCtx,
                    chatTemplate,
                    systemPrompt,
                    nBatch,
                    nUBatch,
                    nGpuLayers,
                    nThreads,
                    useMmap,
                    useMlock,
                    embedding,
                    poolingType,
                    embdNormalize,
                    flashAttention,
                    cacheTypeK,
                    cacheTypeV,
                    true, // enableChatTemplate
                    null // progressCallback
                )

                val contextHandle = LlamaMobile.initContext(initParams)

                if (contextHandle != 0L) {
                    val handle = nextHandle++
                    contexts[handle] = contextHandle
                    result.success(mapOf("contextHandle" to handle))
                } else {
                    result.error("INIT_FAILED", "Failed to initialize context", null)
                }
            } catch (e: Exception) {
                result.error("INIT_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleFreeContextAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")

        Thread {
            try {
                val contextHandle = contexts.remove(handle)
                if (contextHandle != null) {
                    LlamaMobile.releaseContext(contextHandle)
                    result.success(true)
                } else {
                    result.success(false)
                }
            } catch (e: Exception) {
                result.error("FREE_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateCompletionAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val prompt = params["prompt"] as? String ?: throw IllegalArgumentException("prompt is required")
        val maxTokens = params["maxTokens"] as? Int ?: 128
        val nThreads = params["nThreads"] as? Int
        val seed = params["seed"] as? Int ?: -1
        val temperature = (params["temperature"] as? Double ?: 0.8).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.1).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false
        val chatTemplate = params["chatTemplate"] as? String
        val chatMessages = params["chatMessages"] as? List<Map<String, String>> ?: emptyList()

        Thread {
            try {
                if (chatMessages.isNotEmpty()) {
                    // Handle chat messages using generateConversation
                    val completionParams = LlamaMobile.CompletionParams(
                        "",
                        temperature,
                        maxTokens,
                        nThreads,
                        seed,
                        topK,
                        topP.toDouble(),
                        minP.toDouble(),
                        typicalP.toDouble(),
                        penaltyLastN,
                        penaltyRepeat.toDouble(),
                        penaltyFreq.toDouble(),
                        penaltyPresent.toDouble(),
                        mirostat,
                        mirostatTau.toDouble(),
                        mirostatEta.toDouble(),
                        ignoreEos,
                        0, // nProbs
                        grammar,
                        stopSequences,
                        emptyList(), // mediaPaths
                        null // tokenCallback
                    )

                    val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

                    if (completion != null) {
                        result.success(mapOf(
                            "text" to completion.getText(),
                            "tokensGenerated" to completion.getTokensGenerated(),
                            "tokensEvaluated" to completion.getTokensEvaluated(),
                            "truncated" to completion.isTruncated(),
                            "stoppedEos" to completion.isStoppedEos(),
                            "stoppedWord" to completion.isStoppedWord(),
                            "stoppedLimit" to false,
                            "stoppingWord" to ""
                        ))
                    } else {
                        result.error("COMPLETION_FAILED", "Failed to generate completion", null)
                    }
                } else {
                    // Regular completion without chat messages
                    val completionParams = LlamaMobile.CompletionParams(
                        prompt,
                        temperature,
                        maxTokens,
                        nThreads,
                        seed,
                        topK,
                        topP.toDouble(),
                        minP.toDouble(),
                        typicalP.toDouble(),
                        penaltyLastN,
                        penaltyRepeat.toDouble(),
                        penaltyFreq.toDouble(),
                        penaltyPresent.toDouble(),
                        mirostat,
                        mirostatTau.toDouble(),
                        mirostatEta.toDouble(),
                        ignoreEos,
                        0, // nProbs
                        grammar,
                        stopSequences,
                        emptyList(), // mediaPaths
                        null // tokenCallback
                    )

                    val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

                    if (completion != null) {
                        result.success(mapOf(
                            "text" to completion.getText(),
                            "tokensGenerated" to completion.getTokensGenerated(),
                            "tokensEvaluated" to completion.getTokensEvaluated(),
                            "truncated" to completion.isTruncated(),
                            "stoppedEos" to completion.isStoppedEos(),
                            "stoppedWord" to completion.isStoppedWord(),
                            "stoppedLimit" to false,
                            "stoppingWord" to ""
                        ))
                    } else {
                        result.error("COMPLETION_FAILED", "Failed to generate completion", null)
                    }
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateMultimodalCompletionAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val mediaPaths = call.argument<List<String>>("mediaPaths") ?: throw IllegalArgumentException("mediaPaths is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val prompt = params["prompt"] as? String ?: throw IllegalArgumentException("prompt is required")
        val maxTokens = params["maxTokens"] as? Int ?: 128
        val temperature = (params["temperature"] as? Double ?: 0.8).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.1).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String

        Thread {
            try {
                val completionParams = LlamaMobile.CompletionParams(
                    "$prompt\n",
                    temperature,
                    maxTokens,
                    null, // nThreads
                    -1, // seed
                    topK,
                    topP.toDouble(),
                    minP.toDouble(),
                    typicalP.toDouble(),
                    penaltyLastN,
                    penaltyRepeat.toDouble(),
                    penaltyFreq.toDouble(),
                    penaltyPresent.toDouble(),
                    mirostat,
                    mirostatTau.toDouble(),
                    mirostatEta.toDouble(),
                    ignoreEos,
                    0, // nProbs
                    grammar,
                    stopSequences,
                    mediaPaths,
                    null // tokenCallback
                )

                val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("COMPLETION_FAILED", "Failed to generate multimodal completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateStreamingCompletionAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val prompt = params["prompt"] as? String ?: throw IllegalArgumentException("prompt is required")
        val maxTokens = params["maxTokens"] as? Int ?: 128
        
        Thread {
            try {
                val completionParams = LlamaMobile.CompletionParams(prompt)

                val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("COMPLETION_FAILED", "Failed to generate streaming completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleFormatChatMessagesAsync(call: MethodCall, result: Result) {
        val messages = call.argument<List<Map<String, String>>>("messages") ?: throw IllegalArgumentException("messages is required")
        val chatTemplate = call.argument<String>("chatTemplate") ?: throw IllegalArgumentException("chatTemplate is required")

        Thread {
            try {
                if (chatTemplate != null) {
                    var formattedPrompt = StringBuilder()
                    
                    for (message in messages) {
                        val role = message["role"] ?: continue
                        val content = message["content"] ?: continue
                        
                        var messageTemplate = chatTemplate
                        messageTemplate = messageTemplate.replace("{{role}}", role)
                        messageTemplate = messageTemplate.replace("{{content}}", content)
                        formattedPrompt.append(messageTemplate)
                    }
                    
                    var assistantTurnTemplate = chatTemplate
                    assistantTurnTemplate = assistantTurnTemplate.replace("{{role}}", "assistant")
                    
                    val contentPlaceholderIndex = assistantTurnTemplate.indexOf("{{content}}")
                    if (contentPlaceholderIndex >= 0) {
                        assistantTurnTemplate = assistantTurnTemplate.substring(0, contentPlaceholderIndex)
                    }
                    
                    assistantTurnTemplate = assistantTurnTemplate.trim()
                    formattedPrompt.append(assistantTurnTemplate).append("\n")
                    
                    result.success(formattedPrompt.toString())
                } else {
                    result.error("TEMPLATE_MISSING", "No chat template provided", null)
                }
            } catch (e: Exception) {
                result.error("FORMAT_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateEmbeddingAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val params = call.argument<Map<String, Any>>("params") ?: emptyMap()
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                val embedding = LlamaMobile.generateEmbeddings(contextHandle, text)
                result.success(embedding?.toList())
            } catch (e: Exception) {
                result.error("EMBEDDING_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleLoadLoraAdapterAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val adapterPath = call.argument<String>("adapterPath") ?: throw IllegalArgumentException("adapterPath is required")
        val scale = call.argument<Double>("scale") ?: 1.0
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                val adapter = LlamaMobile.LoraAdapter(adapterPath, scale.toFloat())
                val success = LlamaMobile.applyLoraAdapters(contextHandle, arrayOf(adapter))
                result.success(success)
            } catch (e: Exception) {
                result.error("LORA_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleFreeLoraAdapterAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                LlamaMobile.removeLoraAdapters(contextHandle)
                result.success(true)
            } catch (e: Exception) {
                result.error("LORA_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleLoadTTSModelAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val modelPath = call.argument<String>("modelPath") ?: throw IllegalArgumentException("modelPath is required")
        val params = call.argument<Map<String, Any>>("params") ?: emptyMap()
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val sampleRate = params["sampleRate"] as? Int ?: 24000
        val voice = params["voice"] as? String
        val speed = params["speed"] as? Double ?: 1.0

        Thread {
            try {
                val ttsOptions = LlamaMobile.TTSOptions.Builder()
                    .sampleRate(sampleRate)
                    .voice(voice)
                    .speed(speed.toFloat())
                    .build()

                val success = LlamaMobile.initVocoder(contextHandle, modelPath)
                if (success) {
                    val ttsType = LlamaMobile.getTTSType(contextHandle)
                    result.success(mapOf(
                        "success" to true,
                        "modelType" to ttsType.ordinal
                    ))
                } else {
                    result.success(mapOf(
                        "success" to false,
                        "modelType" to -1
                    ))
                }
            } catch (e: Exception) {
                result.error("TTS_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleFreeTTSModelAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                LlamaMobile.releaseVocoder(contextHandle)
                result.success(true)
            } catch (e: Exception) {
                result.error("TTS_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleInitMultimodalAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val mmprojPath = call.argument<String>("mmprojPath") ?: throw IllegalArgumentException("mmprojPath is required")
        val useGpu = call.argument<Boolean>("useGpu") ?: false
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                val success = LlamaMobile.initMultimodal(contextHandle, mmprojPath, useGpu)
                result.success(success)
            } catch (e: Exception) {
                result.error("MULTIMODAL_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleReleaseMultimodalAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                LlamaMobile.releaseMultimodal(contextHandle)
                result.success(null)
            } catch (e: Exception) {
                result.error("MULTIMODAL_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleInitVocoderAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val vocoderModelPath = call.argument<String>("vocoderModelPath") ?: throw IllegalArgumentException("vocoderModelPath is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                val success = LlamaMobile.initVocoder(contextHandle, vocoderModelPath)
                result.success(success)
            } catch (e: Exception) {
                result.error("VOCODER_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleReleaseVocoderAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                LlamaMobile.releaseVocoder(contextHandle)
                result.success(null)
            } catch (e: Exception) {
                result.error("VOCODER_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleRemoveLoraAdaptersAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                LlamaMobile.removeLoraAdapters(contextHandle)
                result.success(null)
            } catch (e: Exception) {
                result.error("LORA_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateSpeechAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            try {
                val speechResult = LlamaMobile.generateSpeech(contextHandle, text, options, null)

                if (speechResult != null && speechResult.isSuccess()) {
                    val speech = speechResult.value
                    // Convert short[] to List<Int> for Flutter compatibility
                    val audioSamplesList = speech.getAudioSamples()?.map { it.toInt() } ?: emptyList()
                    result.success(mapOf(
                        "audioSamples" to audioSamplesList,
                        "sampleRate" to speech.getSampleRate(),
                        "duration" to speech.getDuration(),
                        "outputFilePath" to (speech.getOutputFilePath() ?: null),
                        "methodUsed" to speech.getMethodUsed().ordinal
                    ))
                } else {
                    val error = speechResult?.error
                    result.error("SPEECH_GENERATION_FAILED", error?.toString() ?: "Failed to generate speech", null)
                }
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateSpeechStreamAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            try {
                val speechResult = LlamaMobile.generateSpeechStream(contextHandle, text, options, null, null)

                if (speechResult != null && speechResult.isSuccess()) {
                    val metadata = speechResult.value
                    result.success(mapOf(
                        "sampleRate" to metadata.getSampleRate(),
                        "duration" to metadata.getDuration(),
                        "outputFilePath" to (metadata.getOutputFilePath() ?: null),
                        "methodUsed" to metadata.getMethodUsed().ordinal
                    ))
                } else {
                    val error = speechResult?.error
                    result.error("SPEECH_GENERATION_FAILED", error?.toString() ?: "Failed to generate speech", null)
                }
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleGenerateSpeechStreamForLongTextAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val text = call.argument<String>("text") ?: throw IllegalArgumentException("text is required")
        val optionsMap = call.argument<Map<String, Any>>("options")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val options = parseTTSOptions(optionsMap)

        Thread {
            try {
                val speechResult = LlamaMobile.generateSpeechStreamForLongText(contextHandle, text, options, null, null)

                if (speechResult != null && speechResult.isSuccess()) {
                    val metadata = speechResult.value
                    result.success(mapOf(
                        "sampleRate" to metadata.getSampleRate(),
                        "duration" to metadata.getDuration(),
                        "outputFilePath" to (metadata.getOutputFilePath() ?: null),
                        "methodUsed" to metadata.getMethodUsed().ordinal
                    ))
                } else {
                    val error = speechResult?.error
                    result.error("SPEECH_GENERATION_FAILED", error?.toString() ?: "Failed to generate speech", null)
                }
            } catch (e: Exception) {
                result.error("SPEECH_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }

    private fun handleDownloadModelAsync(call: MethodCall, result: Result) {
        val url = call.argument<String>("url") ?: throw IllegalArgumentException("url is required")
        val localPath = call.argument<String>("localPath") ?: throw IllegalArgumentException("localPath is required")

        Thread {
            try {
                val downloadParamsBuilder = LlamaMobile.DownloadParams.Builder(url, "", localPath)
                val downloadParams = downloadParamsBuilder.build()

                val resultObj = LlamaMobile.downloadModel(downloadParams) { progress, status, downloadedBytes, totalBytes ->
                    progressEventSink?.success(progress)
                }

                result.success(mapOf(
                    "success" to (resultObj?.isSuccess() ?: false),
                    "localPath" to (resultObj?.getLocalPath() ?: ""),
                    "errorMessage" to (resultObj?.getErrorMessage() ?: "")
                ))
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleDownloadHfFileAsync(call: MethodCall, result: Result) {
        val repoId = call.argument<String>("repoId") ?: throw IllegalArgumentException("repoId is required")
        val filename = call.argument<String>("filename") ?: throw IllegalArgumentException("filename is required")
        val localPath = call.argument<String>("localPath") ?: throw IllegalArgumentException("localPath is required")
        val bearerToken = call.argument<String>("bearerToken")
        val offline = call.argument<Boolean>("offline") ?: false

        Thread {
            try {
                val resultObj = LlamaMobile.downloadHfFile(repoId, filename, localPath, bearerToken, offline) { progress, status, downloadedBytes, totalBytes ->
                    progressEventSink?.success(progress)
                }

                result.success(mapOf(
                    "success" to (resultObj?.isSuccess() ?: false),
                    "localPath" to (resultObj?.getLocalPath() ?: ""),
                    "errorMessage" to (resultObj?.getErrorMessage() ?: "")
                ))
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", "An error occurred: ${e.message}", null)
            }
        }.start()
    }

    private fun handleGenerateOpenAICompletionAsync(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val openAIJSON = call.argument<String>("openAIJSON") ?: throw IllegalArgumentException("openAIJSON is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        Thread {
            try {
                val completion = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON)

                if (completion != null) {
                    result.success(mapOf(
                        "text" to completion.getText(),
                        "tokensGenerated" to completion.getTokensGenerated(),
                        "tokensEvaluated" to completion.getTokensEvaluated(),
                        "truncated" to completion.isTruncated(),
                        "stoppedEos" to completion.isStoppedEos(),
                        "stoppedWord" to completion.isStoppedWord(),
                        "stoppedLimit" to false,
                        "stoppingWord" to ""
                    ))
                } else {
                    result.error("COMPLETION_FAILED", "Failed to generate OpenAI completion", null)
                }
            } catch (e: Exception) {
                result.error("COMPLETION_ERROR", e.message, e.stackTraceToString())
            }
        }.start()
    }
}