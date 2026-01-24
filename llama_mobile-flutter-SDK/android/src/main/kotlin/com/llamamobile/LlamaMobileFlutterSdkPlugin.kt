package com.llamamobile

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.json.JSONArray
import org.json.JSONObject

/** LlamaMobileFlutterSdkPlugin */
class LlamaMobileFlutterSdkPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    // Context for accessing resources
    private lateinit var context: Context
    // Map to store context handles
    private val contexts = mutableMapOf<Int, Long>()
    // Counter for generating unique handles
    private var nextHandle = 1

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        try {
            when (call.method) {
                "initContext" -> handleInitContext(call, result)
                "freeContext" -> handleFreeContext(call, result)
                "generateCompletion" -> handleGenerateCompletion(call, result)
                "generateMultimodalCompletion" -> handleGenerateMultimodalCompletion(call, result)
                "generateConversation" -> handleGenerateConversation(call, result)
                "formatChatMessages" -> handleFormatChatMessages(call, result)
                "setChatTemplate" -> handleSetChatTemplate(call, result)
                "loadGrammar" -> handleLoadGrammar(call, result)
                "generateEmbedding" -> handleGenerateEmbedding(call, result)
                "tokenize" -> handleTokenize(call, result)
                "detokenize" -> handleDetokenize(call, result)
                "loadLoraAdapter" -> handleLoadLoraAdapter(call, result)
                "freeLoraAdapter" -> handleFreeLoraAdapter(call, result)
                "loadTTSModel" -> handleLoadTTSModel(call, result)
                "generateAudio" -> handleGenerateAudio(call, result)
                "freeTTSModel" -> handleFreeTTSModel(call, result)
                "saveAudioToWav" -> handleSaveAudioToWav(call, result)
                "initMultimodal" -> handleInitMultimodal(call, result)
                "downloadModel" -> handleDownloadModel(call, result)
                "generateOpenAICompletion" -> handleGenerateOpenAICompletion(call, result)
                "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("ANDROID_ERROR", e.message, e.stackTraceToString())
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        // Free all contexts when detaching
        contexts.values.forEach { LlamaMobile.releaseContext(it) }
        contexts.clear()
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
            modelPath = modelPath,
            nCtx = nCtx,
            chatTemplate = chatTemplate,
            systemPrompt = systemPrompt,
            nBatch = nBatch,
            nUBatch = nUBatch,
            nGpuLayers = nGpuLayers,
            embedding = embedding
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

        val completionParams = LlamaMobile.CompletionParams(
            prompt = prompt,
            maxTokens = maxTokens,
            temperature = temperature,
            topK = topK,
            topP = topP,
            minP = minP,
            typicalP = typicalP,
            penaltyLastN = penaltyLastN,
            penaltyRepeat = penaltyRepeat,
            penaltyFreq = penaltyFreq,
            penaltyPresent = penaltyPresent,
            mirostat = mirostat,
            mirostatTau = mirostatTau,
            mirostatEta = mirostatEta,
            ignoreEos = ignoreEos,
            stopSequences = stopSequences,
            grammar = grammar,
            useJsonResponse = useJsonResponse
        )

        val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

        if (completion != null) {
            result.success(mapOf(
                "text" to completion.text,
                "tokensGenerated" to completion.tokensGenerated,
                "tokensEvaluated" to completion.tokensEvaluated,
                "truncated" to completion.truncated,
                "stoppedEos" to completion.stoppedEos,
                "stoppedWord" to completion.stoppedWord,
                "stoppedLimit" to completion.stoppedLimit,
                "stoppingWord" to completion.stoppingWord
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
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false

        // Initialize multimodal if not already enabled
        if (!LlamaMobile.isMultimodalEnabled(contextHandle)) {
            // We'd need the mmprojPath for this, but it's not provided in the current API
            // For now, let's just check if it's supported
            if (!LlamaMobile.supportsVision(contextHandle)) {
                result.error("MULTIMODAL_NOT_SUPPORTED", "This model does not support vision", null)
                return
            }
        }

        val completionParams = LlamaMobile.CompletionParams(
            prompt = "$prompt\n",
            maxTokens = maxTokens,
            temperature = temperature,
            topK = topK,
            topP = topP,
            minP = minP,
            typicalP = typicalP,
            penaltyLastN = penaltyLastN,
            penaltyRepeat = penaltyRepeat,
            penaltyFreq = penaltyFreq,
            penaltyPresent = penaltyPresent,
            mirostat = mirostat,
            mirostatTau = mirostatTau,
            mirostatEta = mirostatEta,
            ignoreEos = ignoreEos,
            stopSequences = stopSequences,
            grammar = grammar,
            useJsonResponse = useJsonResponse,
            mediaPaths = mediaPaths
        )

        val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

        if (completion != null) {
            result.success(mapOf(
                "text" to completion.text,
                "tokensGenerated" to completion.tokensGenerated,
                "tokensEvaluated" to completion.tokensEvaluated,
                "truncated" to completion.truncated,
                "stoppedEos" to completion.stoppedEos,
                "stoppedWord" to completion.stoppedWord,
                "stoppedLimit" to completion.stoppedLimit,
                "stoppingWord" to completion.stoppingWord
            ))
        } else {
            result.error("COMPLETION_FAILED", "Failed to generate multimodal completion", null)
        }
    }

    private fun handleGenerateConversation(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val params = call.argument<Map<String, Any>>("params") ?: throw IllegalArgumentException("params is required")
        val chatMessages = call.argument<List<Map<String, String>>>("chatMessages") ?: throw IllegalArgumentException("chatMessages is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val maxTokens = params["maxTokens"] as? Int ?: 256
        val temperature = (params["temperature"] as? Double ?: 0.7).toFloat()
        val topK = params["topK"] as? Int ?: 40
        val topP = (params["topP"] as? Double ?: 0.95).toFloat()
        val minP = (params["minP"] as? Double ?: 0.05).toFloat()
        val typicalP = (params["typicalP"] as? Double ?: 1.0).toFloat()
        val penaltyLastN = params["penaltyLastN"] as? Int ?: 64
        val penaltyRepeat = (params["penaltyRepeat"] as? Double ?: 1.2).toFloat()
        val penaltyFreq = (params["penaltyFreq"] as? Double ?: 0.0).toFloat()
        val penaltyPresent = (params["penaltyPresent"] as? Double ?: 0.0).toFloat()
        val mirostat = params["mirostat"] as? Int ?: 0
        val mirostatTau = (params["mirostatTau"] as? Double ?: 5.0).toFloat()
        val mirostatEta = (params["mirostatEta"] as? Double ?: 0.1).toFloat()
        val ignoreEos = params["ignoreEos"] as? Boolean ?: false
        val stopSequences = params["stopSequences"] as? List<String> ?: emptyList()
        val grammar = params["grammar"] as? String
        val useJsonResponse = params["useJsonResponse"] as? Boolean ?: false

        // Convert Flutter messages to LlamaMobile ChatMessage objects
        val messages = chatMessages.mapNotNull { msg ->
            val role = msg["role"] ?: return@mapNotNull null
            val content = msg["content"] ?: return@mapNotNull null
            LlamaMobile.ChatMessage(role, content)
        }

        // Create completion params for conversation
        val completionParams = LlamaMobile.CompletionParams(
            prompt = "",
            maxTokens = maxTokens,
            temperature = temperature,
            topK = topK,
            topP = topP,
            minP = minP,
            typicalP = typicalP,
            penaltyLastN = penaltyLastN,
            penaltyRepeat = penaltyRepeat,
            penaltyFreq = penaltyFreq,
            penaltyPresent = penaltyPresent,
            mirostat = mirostat,
            mirostatTau = mirostatTau,
            mirostatEta = mirostatEta,
            ignoreEos = ignoreEos,
            stopSequences = stopSequences,
            grammar = grammar,
            useJsonResponse = useJsonResponse,
            chatMessages = messages
        )

        // Use generateCompletion with chatMessages for conversation
        val completion = LlamaMobile.generateCompletion(contextHandle, completionParams)

        if (completion != null) {
            // For conversation result, we can use the completion data
            // If we need conversation-specific metrics, we might need to use generateResponse
            result.success(mapOf(
                "text" to completion.text,
                "timeToFirstToken" to -1, // Not available from completion
                "totalTime" to -1, // Not available from completion
                "tokensGenerated" to completion.tokensGenerated
            ))
        } else {
            result.error("CONVERSATION_FAILED", "Failed to generate conversation", null)
        }
    }

    // MARK: - Chat Methods
    private fun handleFormatChatMessages(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val messages = call.argument<List<Map<String, String>>>("messages") ?: throw IllegalArgumentException("messages is required")
        val chatTemplate = call.argument<String>("chatTemplate")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Convert messages to JSON string
        val messagesArray = JSONArray()
        messages.forEach { msg ->
            val msgObj = JSONObject()
            msgObj.put("role", msg["role"])
            msgObj.put("content", msg["content"])
            messagesArray.put(msgObj)
        }
        val messagesJson = messagesArray.toString()

        val formatted = LlamaMobile.formatChatMessages(contextHandle, messagesJson, chatTemplate)
        result.success(formatted)
    }

    private fun handleSetChatTemplate(call: MethodCall, result: Result) {
        val template = call.argument<String>("template")
        LlamaMobile.setChatTemplate(template)
        result.success(true)
    }

    // MARK: - Utility Methods
    private fun handleLoadGrammar(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val grammarName = call.argument<String>("grammarName") ?: throw IllegalArgumentException("grammarName is required")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        // Convert string to GrammarName enum
        val grammarEnum = try {
            LlamaMobile.GrammarName.valueOf(grammarName.uppercase())
        } catch (e: IllegalArgumentException) {
            result.error("INVALID_GRAMMAR", "Unknown grammar name: $grammarName", null)
            return
        }

        // Load grammar content from Android assets
        val grammarContent = try {
            val inputStream = context.assets.open("grammars/${grammarEnum.name.lowercase()}.gbnf")
            inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            result.error("GRAMMAR_LOAD_FAILED", "Failed to load grammar file: ${e.message}", null)
            return
        }

        result.success(grammarContent)
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
        val adapter = LlamaMobile.LoraAdapter(path = adapterPath, scale = scale)
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
            prompt = formattedPrompt,
            maxTokens = 200, // Generate appropriate audio content
            temperature = 0.0f, // Deterministic output
            ignoreEos = true // Don't stop at end-of-sequence
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

    private fun handleGenerateOpenAICompletion(call: MethodCall, result: Result) {
        val handle = call.argument<Int>("contextHandle") ?: throw IllegalArgumentException("contextHandle is required")
        val openAIJSON = call.argument<String>("openAIJSON") ?: throw IllegalArgumentException("openAIJSON is required")
        val grammar = call.argument<String>("grammar")
        val contextHandle = contexts[handle] ?: throw IllegalArgumentException("Invalid context handle")

        val completionResult = LlamaMobile.generateOpenAICompletion(contextHandle, openAIJSON, grammar)
        if (completionResult != null) {
            result.success(mapOf(
                "text" to completionResult.text,
                "tokensGenerated" to completionResult.tokensGenerated,
                "tokensEvaluated" to completionResult.tokensEvaluated,
                "truncated" to completionResult.truncated,
                "stoppedEos" to completionResult.stoppedEos,
                "stoppedWord" to completionResult.stoppedWord,
                "stoppedLimit" to completionResult.stoppedLimit,
                "stoppingWord" to completionResult.stoppingWord
            ))
        } else {
            result.error("COMPLETION_FAILED", "Failed to generate completion", null)
        }
    }

    // MARK: - Download Methods
    private fun handleDownloadModel(call: MethodCall, result: Result) {
        val url = call.argument<String>("url") ?: throw IllegalArgumentException("url is required")
        val localPath = call.argument<String>("localPath") ?: throw IllegalArgumentException("localPath is required")
        val username = call.argument<String>("username")
        val password = call.argument<String>("password")
        val headers = call.argument<Map<String, String>>("headers")

        // Create download parameters
        val downloadParams = LlamaMobile.DownloadParams(
            url = url,
            localPath = localPath,
            password = password ?: "", // Use empty string if null
            headers = headers
        )

        // Run download in background thread
        Thread {
            try {
                val resultObj = LlamaMobile.downloadModel(downloadParams) { progress ->
                    // Send progress updates to Flutter
                    // TODO: Implement progress callback if needed
                }

                if (resultObj != null) {
                    result.success(mapOf(
                        "success" to resultObj.success,
                        "localPath" to resultObj.localPath,
                        "errorMessage" to resultObj.errorMessage
                    ))
                } else {
                    result.error("DOWNLOAD_FAILED", "Download completed with unknown result", null)
                }
            } catch (e: Exception) {
                result.error("DOWNLOAD_ERROR", "An error occurred during download: ${e.message}", null)
            }
        }.start()
    }
}
