package com.llamamobile.sdkexample

import android.content.Context
import android.content.res.AssetManager
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.llamamobile.LlamaMobile
import com.llamamobile.sdk.LlamaMobileSdk
import java.io.File
import java.io.FileOutputStream

class AppState {
    companion object {
        private const val TAG = "AppState"
        private const val MODELS_ASSET_DIR = "models"
        private const val EXTERNAL_MODELS_DIR = "LlamaMobile/models"
        private const val GRAMMARS_ASSET_DIR = "grammars"
        private const val JSON_GRAMMAR_FILE = "json.gbnf"
    }

    var isModelLoaded = false
    var modelPath = ""
    var availableModels: List<Pair<String, String>> = emptyList()
    var errorMessage: String? = null

    // Feature flags
    var enableChatting = true
    var enableEmbedding = false
    var enableMultimodal = false
    var enableTTS = false
    var enableTokenization = true
    var enableLoRA = true

    // Chat configuration
    var systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone."

    // Model configuration
    var nGpuLayers = 4
    var nThreads = 4
    var nCtx = 2048

    // JSON grammar content
    var jsonGrammar: String? = null

    // LlamaMobile SDK instance
    val llamaMobileSdk = LlamaMobileSdk()

    // Handler for UI updates
    private val uiHandler = Handler(Looper.getMainLooper())

    fun init(context: Context) {
        // Extract models from assets to local storage
        extractModelsFromAssets(context)
        
        // Extract and load JSON grammar
        jsonGrammar = loadGrammarFromAssets(context, JSON_GRAMMAR_FILE)
    }

    fun extractModelsFromAssets(context: Context) {
        val assetManager = context.assets
        val localModelsDir = File(context.filesDir, MODELS_ASSET_DIR)
        val models = mutableListOf<Pair<String, String>>()

        // Create local models directory if it doesn't exist
        if (!localModelsDir.exists()) {
            localModelsDir.mkdirs()
        }

        try {
            // 1. Extract models from assets/models directory
            val assetFiles = assetManager.list(MODELS_ASSET_DIR)
            
            if (assetFiles != null && assetFiles.isNotEmpty()) {
                val ggufFiles = assetFiles.filter { it.endsWith(".gguf") }
                
                // Extract each GGUF file to local storage
                val assetModels = ggufFiles.map { fileName ->
                    val localFile = File(localModelsDir, fileName)
                    
                    // Extract file if it doesn't exist locally
                    if (!localFile.exists() || localFile.length() == 0L) {
                        extractAssetFile(assetManager, "$MODELS_ASSET_DIR/$fileName", localFile)
                    }
                    
                    Pair(fileName, localFile.absolutePath)
                }
                models.addAll(assetModels)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting models from assets: ${e.message}")
        }

        try {
            // 2. Scan external storage for models
            val externalDir = File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), EXTERNAL_MODELS_DIR)
            if (externalDir.exists() && externalDir.isDirectory) {
                val ggufFiles = externalDir.listFiles()?.filter { it.isFile && it.name.endsWith(".gguf") } ?: emptyList()
                
                val externalModels = ggufFiles.map { file ->
                    Pair(file.name, file.absolutePath)
                }
                models.addAll(externalModels)
            } else {
                // Create external models directory if it doesn't exist
                externalDir.mkdirs()
                Log.i(TAG, "Created external models directory: ${externalDir.absolutePath}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error scanning external storage for models: ${e.message}")
        }

        // Remove duplicates by file name (keep the first occurrence)
        val seenFileNames = mutableSetOf<String>()
        availableModels = models.filter { pair ->
            val isNew = !seenFileNames.contains(pair.first)
            if (isNew) seenFileNames.add(pair.first)
            isNew
        }

        // Set default model path if any models are found
        if (availableModels.isNotEmpty()) {
            // Check if current model path is still valid
            val currentModelValid = availableModels.any { it.second == modelPath }
            if (!currentModelValid) {
                modelPath = availableModels.first().second
            }
        }
    }

    private fun loadGrammarFromAssets(context: Context, grammarFileName: String): String? {
        val assetManager = context.assets
        val localGrammarDir = File(context.filesDir, GRAMMARS_ASSET_DIR)

        // Create local grammar directory if it doesn't exist
        if (!localGrammarDir.exists()) {
            localGrammarDir.mkdirs()
        }

        try {
            val localFile = File(localGrammarDir, grammarFileName)
            
            // Extract file if it doesn't exist locally
            if (!localFile.exists() || localFile.length() == 0L) {
                extractAssetFile(assetManager, "$GRAMMARS_ASSET_DIR/$grammarFileName", localFile)
            }
            
            // Return grammar content
            return localFile.readText()
        } catch (e: Exception) {
            Log.e(TAG, "Error loading grammar from assets: ${e.message}")
        }
        
        return null
    }

    private fun extractAssetFile(assetManager: AssetManager, assetPath: String, localFile: File) {
        try {
            assetManager.open(assetPath).use { inputStream ->
                FileOutputStream(localFile).use { outputStream ->
                    val buffer = ByteArray(4096)
                    var read: Int
                    while (inputStream.read(buffer).also { read = it } != -1) {
                        outputStream.write(buffer, 0, read)
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting asset file $assetPath: ${e.message}")
            // Clean up if extraction fails
            if (localFile.exists()) {
                localFile.delete()
            }
        }
    }

    fun loadModel(callback: (Boolean) -> Unit) {
        if (modelPath.isEmpty()) {
            errorMessage = "Please select a valid model"
            callback(false)
            return
        }

        errorMessage = null

        val config = LlamaMobileSdk.ModelConfig(
            modelPath = modelPath,
            systemPrompt = systemPrompt,
            contextSize = nCtx,
            gpuLayers = nGpuLayers,
            threads = nThreads,
            useMemoryCache = true,
            enableEmbedding = enableEmbedding
        )

        llamaMobileSdk.loadModel(config, object : LlamaMobileSdk.ResultCallback<Boolean> {
            override fun onSuccess(result: Boolean) {
                uiHandler.post {
                    isModelLoaded = result
                    errorMessage = null
                    callback(result)
                }
            }

            override fun onError(error: Throwable) {
                uiHandler.post {
                    isModelLoaded = false
                    errorMessage = error.localizedMessage ?: "Failed to load model"
                    callback(false)
                }
            }
        })
    }

    fun unloadModel() {
        llamaMobileSdk.release()
        isModelLoaded = false
        errorMessage = null
    }
}
