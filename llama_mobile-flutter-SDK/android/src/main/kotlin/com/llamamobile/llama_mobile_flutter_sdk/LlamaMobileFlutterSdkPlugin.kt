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

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "llama_mobile_flutter_sdk")
        channel.setMethodCallHandler(this)
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
            "generateCompletion" -> {
                handleGenerateCompletion(call, result)
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
    
    private fun handleGenerateCompletion(call: MethodCall, result: Result) {
        try {
            val arguments = call.arguments as Map<*, *>
            val prompt = arguments["prompt"] as String
            val temperature = arguments["temperature"] as Double? ?: 0.8
            val maxTokens = arguments["maxTokens"] as Int? ?: 100
            
            val config = LlamaMobileSdk.GenerationConfig(
                prompt = prompt,
                temperature = temperature.toFloat(),
                maxTokens = maxTokens
            )
            
            llamaMobileSdk?.generate(config, object : LlamaMobileSdk.GenerationListener {
                override fun onGenerationStart(prompt: String) {
                    // Not used in current implementation
                }
                
                override fun onGenerationComplete(completionResult: String) {
                    result.success(completionResult)
                }
                
                override fun onError(error: Throwable) {
                    result.error("GENERATION_ERROR", "Failed to generate completion: ${error.message}", null)
                }
            })
        } catch (e: Exception) {
            result.error("INVALID_ARGS", "Invalid arguments for generateCompletion: ${e.message}", null)
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

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        llamaMobileSdk?.release()
        llamaMobileSdk = null
        channel.setMethodCallHandler(null)
    }
}
