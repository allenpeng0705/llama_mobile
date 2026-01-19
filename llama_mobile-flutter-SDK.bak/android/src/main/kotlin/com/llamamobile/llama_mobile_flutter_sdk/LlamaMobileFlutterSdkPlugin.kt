package com.llamamobile.llama_mobile_flutter_sdk

import com.llamamobile.sdk.LlamaMobileSdk
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** LlamaMobileFlutterSdkPlugin */
class LlamaMobileFlutterSdkPlugin :
    FlutterPlugin,
    MethodCallHandler {
    // The MethodChannel that will the communication between Flutter and native Android
    private lateinit var channel: MethodChannel
    
    // Instance of the Android SDK
    private var llamaMobileSdk: LlamaMobileSdk? = null
    
    // Application context needed for accessing assets
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk")
        channel.setMethodCallHandler(this)
        this.flutterPluginBinding = flutterPluginBinding
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "loadModel" -> {
                handleLoadModel(call, result)
            }
            "initialize" -> {
                handleInitialize(call, result)
            }
            "generateCompletion" -> {
                handleGenerateCompletion(call, result)
            }
            "generate" -> {
                handleGenerate(call, result)
            }
            "generateResponse" -> {
                handleGenerateResponse(call, result)
            }
            "streamCompletion" -> {
                handleStreamCompletion(call, result)
            }
            "stopCompletion" -> {
                handleStopCompletion(call, result)
            }
            "tokenize" -> {
                handleTokenize(call, result)
            }
            "detokenize" -> {
                handleDetokenize(call, result)
            }
            "generateEmbeddings" -> {
                handleGenerateEmbeddings(call, result)
            }
            "generateEmbeddingsForPrompt" -> {
                handleGenerateEmbeddingsForPrompt(call, result)
            }
            "initMultimodal" -> {
                handleInitMultimodal(call, result)
            }
            "initTTS" -> {
                handleInitTTS(call, result)
            }
            "generateAudio" -> {
                handleGenerateAudio(call, result)
            }
            "applyLoraAdapters" -> {
                handleApplyLoraAdapters(call, result)
            }
            "createConversation" -> {
                handleCreateConversation(call, result)
            }
            "generateConversationResponse" -> {
                handleGenerateConversationResponse(call, result)
            }
            "streamConversationResponse" -> {
                handleStreamConversationResponse(call, result)
            }
            "getConversationHistory" -> {
                handleGetConversationHistory(call, result)
            }
            "clearConversation" -> {
                handleClearConversation(call, result)
            }
            "downloadModel" -> {
                handleDownloadModel(call, result)
            }
            "getVersion" -> {
                handleGetVersion(call, result)
            }
            "getGrammarContent" -> {
                handleGetGrammarContent(call, result)
            }
            "release" -> {
                handleRelease(call, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
    
    private fun handleLoadModel(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val modelPath = arguments["modelPath"] as String
            val contextSize = arguments["contextSize"] as Int? ?: 1024
            val useMemoryCache = arguments["useMemoryCache"] as Boolean? ?: true
            
            if (llamaMobileSdk == null) {
                llamaMobileSdk = LlamaMobileSdk()
            }
            
            val config = LlamaMobileSdk.ModelConfig(
                modelPath = modelPath,
                contextSize = contextSize,
                useMemoryCache = useMemoryCache
            )
            
            llamaMobileSdk?.loadModel(config, object : LlamaMobileSdk.ResultCallback<Boolean> {
                override fun onSuccess(success: Boolean) {
                    result.success(success)
                }
                
                override fun onError(error: Throwable) {
                    result.error("LOAD_MODEL_ERROR", "Failed to load model: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for loadModel: ${e.message}", null)
        }
    }
    
    private fun handleInitialize(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val modelPath = arguments["modelPath"] as String
            val nCtx = arguments["nCtx"] as Int? ?: 2048
            val nGpuLayers = arguments["nGpuLayers"] as Int? ?: 0
            val nThreads = arguments["nThreads"] as Int? ?: 4
            val nBatch = arguments["nBatch"] as Int? ?: 512
            val nUbatch = arguments["nUbatch"] as Int? ?: 512
            val useMmap = arguments["useMmap"] as Boolean? ?: true
            val useMlock = arguments["useMlock"] as Boolean? ?: false
            val chatTemplate = arguments["chatTemplate"] as String?
            val systemPrompt = arguments["systemPrompt"] as String?
            val embedding = arguments["embedding"] as Boolean? ?: false
            val poolingType = arguments["poolingType"] as Int? ?: 0
            val embdNormalize = arguments["embdNormalize"] as Boolean? ?: false
            val flashAttn = arguments["flashAttn"] as Boolean? ?: false
            val cacheTypeK = arguments["cacheTypeK"] as String?
            val cacheTypeV = arguments["cacheTypeV"] as String?
            
            if (llamaMobileSdk == null) {
                llamaMobileSdk = LlamaMobileSdk()
            }
            
            val config = LlamaMobileSdk.ModelConfig(
                modelPath = modelPath,
                chatTemplate = chatTemplate,
                systemPrompt = systemPrompt,
                contextSize = nCtx,
                batchSize = nBatch,
                microBatchSize = nUbatch,
                gpuLayerCount = nGpuLayers,
                threadCount = nThreads,
                useMmap = useMmap,
                useMlock = useMlock,
                enableEmbeddings = embedding,
                poolingType = poolingType,
                embeddingNormalize = if (embdNormalize) 1 else 0,
                useFlashAttention = flashAttn,
                cacheTypeK = cacheTypeK,
                cacheTypeV = cacheTypeV,
                useMemoryCache = true
            )
            
            llamaMobileSdk?.loadModel(config, object : LlamaMobileSdk.ResultCallback<Boolean> {
                override fun onSuccess(success: Boolean) {
                    result.success(success)
                }
                
                override fun onError(error: Throwable) {
                    result.error("INITIALIZE_ERROR", "Failed to initialize model: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for initialize: ${e.message}", null)
        }
    }
    
    private fun handleGenerateCompletion(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String
            val temperature = arguments["temperature"] as Double? ?: 0.8
            val maxTokens = arguments["maxTokens"] as Int? ?: 100
            
            val config = LlamaMobileSdk.GenerationConfig(
                prompt = prompt,
                temperature = temperature,
                maxTokens = maxTokens
            )
            
            llamaMobileSdk?.generate(config, object : LlamaMobileSdk.GenerationListener {
                override fun onGenerationStart(prompt: String) {
                    // Not used in current implementation
                }
                
                override fun onToken(token: String): Boolean {
                    // Not used in current implementation
                    return true
                }
                
                override fun onGenerationComplete(completionResult: com.llamamobile.LlamaMobile.CompletionResult) {
                    result.success(completionResult.text)
                }
                
                override fun onError(error: Throwable) {
                    result.error("GENERATION_ERROR", "Failed to generate completion: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generateCompletion: ${e.message}", null)
        }
    }
    
    private fun handleGenerate(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String
            val maxTokens = arguments["maxTokens"] as Int? ?: 100
            val temperature = arguments["temperature"] as Double? ?: 0.8
            val topK = arguments["topK"] as Int? ?: 40
            val topP = arguments["topP"] as Double? ?: 0.95
            val minP = arguments["minP"] as Double? ?: 0.05
            val typicalP = arguments["typicalP"] as Double? ?: 1.0
            val seed = arguments["seed"] as Int? ?: -1
            val nThreads = arguments["nThreads"] as Int? ?: 4
            val penaltyLastN = arguments["penaltyLastN"] as Int? ?: 64
            val penaltyRepeat = arguments["penaltyRepeat"] as Double? ?: 1.1
            val penaltyFreq = arguments["penaltyFreq"] as Double? ?: 0.0
            val penaltyPresent = arguments["penaltyPresent"] as Double? ?: 0.0
            val mirostat = arguments["mirostat"] as Int? ?: 0
            val mirostatTau = arguments["mirostatTau"] as Double? ?: 5.0
            val mirostatEta = arguments["mirostatEta"] as Double? ?: 0.1
            val ignoreEos = arguments["ignoreEos"] as Boolean? ?: false
            val stopSequences = arguments["stopSequences"] as List<String>? ?: emptyList()
            val grammar = arguments["grammar"] as String?
            
            val config = LlamaMobileSdk.GenerationConfig(
                prompt = prompt,
                maxTokens = maxTokens,
                threadCount = nThreads,
                seed = seed,
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
                grammar = grammar
            )
            
            llamaMobileSdk?.generate(config, object : LlamaMobileSdk.GenerationListener {
                override fun onGenerationStart(prompt: String) {
                    // Not used in current implementation
                }
                
                override fun onToken(token: String): Boolean {
                    // Not used in current implementation
                    return true
                }
                
                override fun onGenerationComplete(completionResult: com.llamamobile.LlamaMobile.CompletionResult) {
                    result.success(completionResult.text)
                }
                
                override fun onError(error: Throwable) {
                    result.error("GENERATION_ERROR", "Failed to generate: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generate: ${e.message}", null)
        }
    }
    
    private fun handleGetGrammarContent(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val grammarNameStr = arguments["grammarName"] as String
            
            if (llamaMobileSdk == null) {
                llamaMobileSdk = LlamaMobileSdk()
            }
            
            // Get grammar content from Android SDK
            val grammarContent = llamaMobileSdk?.getGrammarContent(
                flutterPluginBinding.applicationContext,
                when (grammarNameStr) {
                    "arithmetic" -> LlamaMobileSdk.GrammarName.ARITHMETIC
                    "c" -> LlamaMobileSdk.GrammarName.C
                    "chess" -> LlamaMobileSdk.GrammarName.CHESS
                    "english" -> LlamaMobileSdk.GrammarName.ENGLISH
                    "japanese" -> LlamaMobileSdk.GrammarName.JAPANESE
                    "json" -> LlamaMobileSdk.GrammarName.JSON
                    "json_arr" -> LlamaMobileSdk.GrammarName.JSON_ARR
                    "list" -> LlamaMobileSdk.GrammarName.LIST
                    else -> null
                }
            )
            
            result.success(grammarContent)
        } catch (e: Exception) {
            result.error("GET_GRAMMAR_CONTENT_ERROR", "Failed to get grammar content: ${e.message}", null)
        }
    }
    
    private fun handleRelease(call: MethodCall, result: Result) {
        try {
            llamaMobileSdk?.release()
            llamaMobileSdk = null
            result.success(null)
        } catch (e: Exception) {
            result.error("RELEASE_ERROR", "Failed to release resources: ${e.message}", null)
        }
    }

    private fun handleGenerateResponse(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String
            val maxTokens = arguments["maxTokens"] as Int? ?: 100
            val temperature = arguments["temperature"] as Double? ?: 0.8
            val topK = arguments["topK"] as Int? ?: 40
            val topP = arguments["topP"] as Double? ?: 0.95
            val minP = arguments["minP"] as Double? ?: 0.05
            val typicalP = arguments["typicalP"] as Double? ?: 1.0
            val seed = arguments["seed"] as Int? ?: -1
            val nThreads = arguments["nThreads"] as Int? ?: 4
            val penaltyLastN = arguments["penaltyLastN"] as Int? ?: 64
            val penaltyRepeat = arguments["penaltyRepeat"] as Double? ?: 1.1
            val penaltyFreq = arguments["penaltyFreq"] as Double? ?: 0.0
            val penaltyPresent = arguments["penaltyPresent"] as Double? ?: 0.0
            val mirostat = arguments["mirostat"] as Int? ?: 0
            val mirostatTau = arguments["mirostatTau"] as Double? ?: 5.0
            val mirostatEta = arguments["mirostatEta"] as Double? ?: 0.1
            val ignoreEos = arguments["ignoreEos"] as Boolean? ?: false
            val stopSequences = arguments["stopSequences"] as List<String>? ?: emptyList()
            val grammar = arguments["grammar"] as String?

            val config = LlamaMobileSdk.GenerationConfig(
                prompt = prompt,
                maxTokens = maxTokens,
                threadCount = nThreads,
                seed = seed,
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
                grammar = grammar
            )

            llamaMobileSdk?.generate(config, object : LlamaMobileSdk.GenerationListener {
                override fun onGenerationStart(prompt: String) {
                    // Not used in current implementation
                }

                override fun onToken(token: String): Boolean {
                    // Not used in current implementation
                    return true
                }

                override fun onGenerationComplete(completionResult: com.llamamobile.LlamaMobile.CompletionResult) {
                    // Return detailed completion result
                    val resultMap = mapOf(
                        "text" to completionResult.text,
                        "tokensGenerated" to completionResult.tokensGenerated,
                        "tokensEvaluated" to completionResult.tokensEvaluated,
                        "truncated" to completionResult.truncated,
                        "stoppedEos" to completionResult.stoppedEos,
                        "stoppedWord" to completionResult.stoppedWord,
                        "stoppedLimit" to completionResult.stoppedLimit
                    )
                    result.success(resultMap)
                }

                override fun onError(error: Throwable) {
                    result.error("GENERATION_ERROR", "Failed to generate response: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generateResponse: ${e.message}", null)
        }
    }

    private fun handleStreamCompletion(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String
            val maxTokens = arguments["maxTokens"] as Int? ?: 100
            val temperature = arguments["temperature"] as Double? ?: 0.8
            val topK = arguments["topK"] as Int? ?: 40
            val topP = arguments["topP"] as Double? ?: 0.95
            val minP = arguments["minP"] as Double? ?: 0.05
            val typicalP = arguments["typicalP"] as Double? ?: 1.0
            val seed = arguments["seed"] as Int? ?: -1
            val nThreads = arguments["nThreads"] as Int? ?: 4
            val penaltyLastN = arguments["penaltyLastN"] as Int? ?: 64
            val penaltyRepeat = arguments["penaltyRepeat"] as Double? ?: 1.1
            val penaltyFreq = arguments["penaltyFreq"] as Double? ?: 0.0
            val penaltyPresent = arguments["penaltyPresent"] as Double? ?: 0.0
            val mirostat = arguments["mirostat"] as Int? ?: 0
            val mirostatTau = arguments["mirostatTau"] as Double? ?: 5.0
            val mirostatEta = arguments["mirostatEta"] as Double? ?: 0.1
            val ignoreEos = arguments["ignoreEos"] as Boolean? ?: false
            val stopSequences = arguments["stopSequences"] as List<String>? ?: emptyList()
            val grammar = arguments["grammar"] as String?

            val config = LlamaMobileSdk.GenerationConfig(
                prompt = prompt,
                maxTokens = maxTokens,
                threadCount = nThreads,
                seed = seed,
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
                grammar = grammar
            )

            llamaMobileSdk?.generate(config, object : LlamaMobileSdk.GenerationListener {
                override fun onGenerationStart(prompt: String) {
                    // Not used in current implementation
                }

                override fun onToken(token: String): Boolean {
                    // Send token to Flutter
                    result.success(token)
                    return true
                }

                override fun onGenerationComplete(completionResult: com.llamamobile.LlamaMobile.CompletionResult) {
                    // Generation completed
                    result.success(completionResult.text)
                }

                override fun onError(error: Throwable) {
                    result.error("STREAM_ERROR", "Failed to stream completion: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for streamCompletion: ${e.message}", null)
        }
    }

    private fun handleStopCompletion(call: MethodCall, result: Result) {
        try {
            llamaMobileSdk?.stop()
            result.success(null)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop completion: ${e.message}", null)
        }
    }

    private fun handleTokenize(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val text = arguments["text"] as String

            llamaMobileSdk?.tokenize(text, object : LlamaMobileSdk.ResultCallback<List<Int>> {
                override fun onSuccess(tokens: List<Int>) {
                    result.success(tokens)
                }

                override fun onError(error: Throwable) {
                    result.error("TOKENIZE_ERROR", "Failed to tokenize text: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for tokenize: ${e.message}", null)
        }
    }

    private fun handleDetokenize(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val tokens = arguments["tokens"] as List<Int>

            llamaMobileSdk?.detokenize(tokens, object : LlamaMobileSdk.ResultCallback<String> {
                override fun onSuccess(text: String) {
                    result.success(text)
                }

                override fun onError(error: Throwable) {
                    result.error("DETOKENIZE_ERROR", "Failed to detokenize tokens: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for detokenize: ${e.message}", null)
        }
    }

    private fun handleGenerateEmbeddings(call: MethodCall, result: Result) {
        try {
            llamaMobileSdk?.generateEmbeddings(object : LlamaMobileSdk.ResultCallback<List<Double>> {
                override fun onSuccess(embeddings: List<Double>) {
                    result.success(embeddings)
                }

                override fun onError(error: Throwable) {
                    result.error("EMBEDDINGS_ERROR", "Failed to generate embeddings: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("EMBEDDINGS_ERROR", "Failed to generate embeddings: ${e.message}", null)
        }
    }

    private fun handleGenerateEmbeddingsForPrompt(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String

            llamaMobileSdk?.generateEmbeddings(prompt, object : LlamaMobileSdk.ResultCallback<List<Double>> {
                override fun onSuccess(embeddings: List<Double>) {
                    result.success(embeddings)
                }

                override fun onError(error: Throwable) {
                    result.error("EMBEDDINGS_ERROR", "Failed to generate embeddings for prompt: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generateEmbeddingsForPrompt: ${e.message}", null)
        }
    }

    private fun handleInitMultimodal(call: MethodCall, result: Result) {
        try {
            llamaMobileSdk?.initMultimodal(object : LlamaMobileSdk.ResultCallback<Boolean> {
                override fun onSuccess(success: Boolean) {
                    result.success(success)
                }

                override fun onError(error: Throwable) {
                    result.error("MULTIMODAL_ERROR", "Failed to initialize multimodal: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("MULTIMODAL_ERROR", "Failed to initialize multimodal: ${e.message}", null)
        }
    }

    private fun handleInitTTS(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val ttsPath = arguments["ttsPath"] as String
            val modelTypeInt = arguments["modelType"] as Int

            val modelType = when (modelTypeInt) {
                1 -> LlamaMobileSdk.TTSModelType.OUT_ETTS_V02
                2 -> LlamaMobileSdk.TTSModelType.OUT_ETTS_V03
                else -> LlamaMobileSdk.TTSModelType.UNKNOWN
            }

            llamaMobileSdk?.initTTS(ttsPath, modelType, object : LlamaMobileSdk.ResultCallback<Boolean> {
                override fun onSuccess(success: Boolean) {
                    result.success(success)
                }

                override fun onError(error: Throwable) {
                    result.error("TTS_ERROR", "Failed to initialize TTS: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for initTTS: ${e.message}", null)
        }
    }

    private fun handleGenerateAudio(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val text = arguments["text"] as String
            val voice = arguments["voice"] as String
            val speed = arguments["speed"] as Double? ?: 1.0
            val pitch = arguments["pitch"] as Double? ?: 1.0

            val params = LlamaMobileSdk.TTSParams(
                text = text,
                voice = voice,
                speed = speed,
                pitch = pitch
            )

            llamaMobileSdk?.generateAudio(params, object : LlamaMobileSdk.ResultCallback<String> {
                override fun onSuccess(audioPath: String) {
                    result.success(audioPath)
                }

                override fun onError(error: Throwable) {
                    result.error("AUDIO_ERROR", "Failed to generate audio: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generateAudio: ${e.message}", null)
        }
    }

    private fun handleApplyLoraAdapters(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val adaptersData = arguments["adapters"] as List<Map<*, *>>

            val adapters = adaptersData.mapNotNull { adapterData ->
                val path = adapterData["path"] as? String ?: return@mapNotNull null
                val scale = adapterData["scale"] as? Double ?: return@mapNotNull null
                LlamaMobileSdk.LoraAdapter(path = path, scale = scale)
            }

            llamaMobileSdk?.applyLoraAdapters(adapters, object : LlamaMobileSdk.ResultCallback<Boolean> {
                override fun onSuccess(success: Boolean) {
                    result.success(success)
                }

                override fun onError(error: Throwable) {
                    result.error("LORA_ERROR", "Failed to apply LoRA adapters: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for applyLoraAdapters: ${e.message}", null)
        }
    }

    // Conversation-related methods will be implemented in the future
    private fun handleCreateConversation(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun handleGenerateConversationResponse(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun handleStreamConversationResponse(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun handleGetConversationHistory(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun handleClearConversation(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    // Download-related methods will be implemented in the future
    private fun handleDownloadModel(call: MethodCall, result: Result) {
        result.notImplemented()
    }

    private fun handleGetVersion(call: MethodCall, result: Result) {
        try {
            llamaMobileSdk?.version(object : LlamaMobileSdk.ResultCallback<String> {
                override fun onSuccess(version: String) {
                    result.success(version)
                }

                override fun onError(error: Throwable) {
                    result.error("VERSION_ERROR", "Failed to get version: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("VERSION_ERROR", "Failed to get version: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        llamaMobileSdk?.release()
        llamaMobileSdk = null
        channel.setMethodCallHandler(null)
    }
}
