package com.llamamobile.sdkexample

import android.content.Context
import android.content.res.AssetManager
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.llamamobile.LlamaMobile
import java.io.File
import java.io.FileOutputStream

class AppState {
    companion object {
        private const val TAG = "AppState"
        private const val MODELS_ASSET_DIR = "models"
        private const val EXTERNAL_MODELS_DIR = "models"
        private const val EXTERNAL_MODELS_ALT_DIR = "LlamaMobile/models"
        private const val GRAMMARS_ASSET_DIR = "grammars"
        private const val JSON_GRAMMAR_FILE = "json.gbnf"
    }

    var isModelLoaded = false
    var modelPath = ""
    var availableModels: List<Pair<String, String>> = emptyList()
    var errorMessage: String? = null
    
    // Additional model paths for multimodal and TTS
    var mmprojModelPath = ""
    var availableMmprojModels: List<Pair<String, String>> = emptyList()
    var vocoderModelPath = ""
    var availableVocoderModels: List<Pair<String, String>> = emptyList()
    var loraModelPath = ""
    var availableLoRAModels: List<Pair<String, String>> = emptyList()

    // Feature flags
    var enableEmbedding = false

    // Chat configuration
    var systemPrompt = "You are a local AI assistant. Please respond to user queries in a polite, helpful, and clear manner. Focus on providing accurate information and maintaining a friendly tone."

    // Model configuration
    var nGpuLayers = 4
    var nThreads = 4
    var nCtx = 2048

    // JSON grammar content
    var jsonGrammar: String? = null

    // Model context handle
    var contextHandle: Long = 0

    // Handler for UI updates
    private val uiHandler = Handler(Looper.getMainLooper())

    fun init(context: Context) {
        // Run directly on UI thread for simplicity in example app
        // Extract models from assets to local storage
        extractModelsFromAssets(context)
        
        // Extract and load JSON grammar
        jsonGrammar = loadGrammarFromAssets(context, JSON_GRAMMAR_FILE)
    }

    fun extractModelsFromAssets(context: Context) {
        // Run directly on UI thread for simplicity in example app
        try {
            val assetManager = context.assets
            val localModelsDir = File(context.filesDir, MODELS_ASSET_DIR)
            val models = mutableListOf<Pair<String, String>>()
            val mmprojModels = mutableListOf<Pair<String, String>>()
            val vocoderModels = mutableListOf<Pair<String, String>>()
            val loraModels = mutableListOf<Pair<String, String>>()

            // Debug: Show all possible model directories
            Log.i(TAG, "=== Model Directory Debug ===")
            Log.i(TAG, "Context filesDir: ${context.filesDir.absolutePath}")
            Log.i(TAG, "Local models dir: ${localModelsDir.absolutePath}")
            Log.i(TAG, "External files dir: ${context.getExternalFilesDir(null)?.absolutePath}")
            Log.i(TAG, "External models dir: ${File(context.getExternalFilesDir(null), EXTERNAL_MODELS_DIR).absolutePath}")
            Log.i(TAG, "Legacy external models dir: ${File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), EXTERNAL_MODELS_ALT_DIR).absolutePath}")
            
            // Create local models directory if it doesn't exist
            if (!localModelsDir.exists()) {
                localModelsDir.mkdirs()
            }

            try {
                // 1. Extract models from assets/models directory
                val assetFiles = assetManager.list(MODELS_ASSET_DIR)
                
                if (assetFiles != null && assetFiles.isNotEmpty()) {
                    // Extract GGUF models
                    val ggufFiles = assetFiles.filter { it.endsWith(".gguf") }
                    val assetModels = ggufFiles.mapNotNull { fileName ->
                        try {
                            val localFile = File(localModelsDir, fileName)
                            
                            // Extract file if it doesn't exist locally
                            if (!localFile.exists() || localFile.length() == 0L) {
                                extractAssetFile(assetManager, "$MODELS_ASSET_DIR/$fileName", localFile)
                            }
                            
                            Pair(fileName, localFile.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error extracting asset file $fileName: ${e.message}")
                            null
                        }
                    }
                    models.addAll(assetModels)
                    
                    // Extract mmproj models
                    val mmprojFiles = assetFiles.filter { it.contains(".mmproj") }
                    val assetMmprojModels = mmprojFiles.mapNotNull { fileName ->
                        try {
                            val localFile = File(localModelsDir, fileName)
                            
                            // Extract file if it doesn't exist locally
                            if (!localFile.exists() || localFile.length() == 0L) {
                                extractAssetFile(assetManager, "$MODELS_ASSET_DIR/$fileName", localFile)
                            }
                            
                            Pair(fileName, localFile.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error extracting asset file $fileName: ${e.message}")
                            null
                        }
                    }
                    mmprojModels.addAll(assetMmprojModels)
                    
                    // Extract vocoder models
                    val vocoderFiles = assetFiles.filter { it.contains("vocoder") || it.contains("voco") || it.endsWith(".bin") && !it.endsWith(".mmproj") }
                    val assetVocoderModels = vocoderFiles.mapNotNull { fileName ->
                        try {
                            val localFile = File(localModelsDir, fileName)
                            
                            // Extract file if it doesn't exist locally
                            if (!localFile.exists() || localFile.length() == 0L) {
                                extractAssetFile(assetManager, "$MODELS_ASSET_DIR/$fileName", localFile)
                            }
                            
                            Pair(fileName, localFile.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error extracting asset file $fileName: ${e.message}")
                            null
                        }
                    }
                    vocoderModels.addAll(assetVocoderModels)
                    
                    // Extract LoRA models - show all models (no filtering)
                    val assetLoRAModels = assetFiles.mapNotNull { fileName ->
                        try {
                            val localFile = File(localModelsDir, fileName)
                            
                            // Extract file if it doesn't exist locally
                            if (!localFile.exists() || localFile.length() == 0L) {
                                extractAssetFile(assetManager, "$MODELS_ASSET_DIR/$fileName", localFile)
                            }
                            
                            Pair(fileName, localFile.absolutePath)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error extracting asset file $fileName: ${e.message}")
                            null
                        }
                    }
                    loraModels.addAll(assetLoRAModels)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error extracting models from assets: ${e.message}")
            }

            try {
                // 2.1 Scan direct models directory in external files dir (for compatibility with tests)
                val directExternalDir = File(context.getExternalFilesDir(null), EXTERNAL_MODELS_DIR)
                Log.i(TAG, "Checking direct external dir: ${directExternalDir.absolutePath}")
                Log.i(TAG, "Exists: ${directExternalDir.exists()}, Is directory: ${directExternalDir.isDirectory}")
                
                if (directExternalDir.exists() && directExternalDir.isDirectory) {
                    val allFiles = directExternalDir.listFiles()?.toList() ?: emptyList()
                    Log.i(TAG, "Files found in direct external dir: ${allFiles.map { it.name }}")
                    
                    // Add external models
                    val ggufFiles = allFiles.filter { it.isFile && it.name.endsWith(".gguf") }
                    Log.i(TAG, "GGUF files found: ${ggufFiles.map { it.name }}")
                    val externalModels = ggufFiles.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    models.addAll(externalModels)
                    
                    // Add LoRA models - show all models (no filtering)
                    val externalLoRAModels = allFiles.filter { it.isFile }.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    loraModels.addAll(externalLoRAModels)
                    
                    // Add mmproj models - show all models (no filtering)
                    val externalMmprojModels = allFiles.filter { it.isFile }.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    mmprojModels.addAll(externalMmprojModels)
                    
                    // Add vocoder models - show all models (no filtering)
                    val externalVocoderModels = allFiles.filter { it.isFile }.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    vocoderModels.addAll(externalVocoderModels)
                } else {
                    Log.i(TAG, "Direct external models directory not found: ${directExternalDir.absolutePath}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning direct external storage for models: ${e.message}")
                e.printStackTrace()
            }

            try {
                // 2.2 Scan legacy LlamaMobile/models directory (original SDK example path)
                val legacyExternalDir = File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), EXTERNAL_MODELS_ALT_DIR)
                Log.i(TAG, "Checking legacy external dir: ${legacyExternalDir.absolutePath}")
                Log.i(TAG, "Exists: ${legacyExternalDir.exists()}, Is directory: ${legacyExternalDir.isDirectory}")
                
                if (legacyExternalDir.exists() && legacyExternalDir.isDirectory) {
                    val allFiles = legacyExternalDir.listFiles()?.toList() ?: emptyList()
                    Log.i(TAG, "Files found in legacy external dir: ${allFiles.map { it.name }}")
                    
                    // Add GGUF models
                    val ggufFiles = allFiles.filter { it.isFile && it.name.endsWith(".gguf") }
                    Log.i(TAG, "GGUF files found: ${ggufFiles.map { it.name }}")
                    val externalModels = ggufFiles.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    models.addAll(externalModels)
                    
                    // Add mmproj models - show all models (no filtering)
                    val externalMmprojModels = allFiles.filter { it.isFile }.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    mmprojModels.addAll(externalMmprojModels)
                    
                    // Add vocoder models - show all models (no filtering)
                    val externalVocoderModels = allFiles.filter { it.isFile }.map { file ->
                        Pair(file.name, file.absolutePath)
                    }
                    vocoderModels.addAll(externalVocoderModels)
                } else {
                    // Create legacy directory if it doesn't exist
                    legacyExternalDir.mkdirs()
                    Log.i(TAG, "Created legacy external models directory: ${legacyExternalDir.absolutePath}")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error scanning legacy external storage for models: ${e.message}")
                e.printStackTrace()
            }

            // Remove duplicates by file name (keep the first occurrence)
            val seenFileNames = mutableSetOf<String>()
            availableModels = models.filter { pair ->
                val isNew = !seenFileNames.contains(pair.first)
                if (isNew) seenFileNames.add(pair.first)
                isNew
            }
            
            // Remove duplicates for mmproj models
            val seenMmprojNames = mutableSetOf<String>()
            availableMmprojModels = mmprojModels.filter { pair ->
                val isNew = !seenMmprojNames.contains(pair.first)
                if (isNew) seenMmprojNames.add(pair.first)
                isNew
            }
            
            // Remove duplicates for vocoder models
            val seenVocoderNames = mutableSetOf<String>()
            availableVocoderModels = vocoderModels.filter { pair ->
                val isNew = !seenVocoderNames.contains(pair.first)
                if (isNew) seenVocoderNames.add(pair.first)
                isNew
            }
            
            // Remove duplicates for LoRA models
            val seenLoRANames = mutableSetOf<String>()
            availableLoRAModels = loraModels.filter { pair ->
                val isNew = !seenLoRANames.contains(pair.first)
                if (isNew) seenLoRANames.add(pair.first)
                isNew
            }
            
            // Debug: Show final available models
            Log.i(TAG, "=== Final Available Models ===")
            Log.i(TAG, "Total GGUF models found: ${availableModels.size}")
            availableModels.forEachIndexed { index, (name, path) ->
                Log.i(TAG, "Model $index: $name at $path")
            }
            
            Log.i(TAG, "=== Final Available MMProj Models ===")
            Log.i(TAG, "Total mmproj models found: ${availableMmprojModels.size}")
            availableMmprojModels.forEachIndexed { index, (name, path) ->
                Log.i(TAG, "MMProj Model $index: $name at $path")
            }
            
            Log.i(TAG, "=== Final Available Vocoder Models ===")
            Log.i(TAG, "Total vocoder models found: ${availableVocoderModels.size}")
            availableVocoderModels.forEachIndexed { index, (name, path) ->
                Log.i(TAG, "Vocoder Model $index: $name at $path")
            }
            
            Log.i(TAG, "=== Final Available LoRA Models ===")
            Log.i(TAG, "Total LoRA models found: ${availableLoRAModels.size}")
            availableLoRAModels.forEachIndexed { index, (name, path) ->
                Log.i(TAG, "LoRA Model $index: $name at $path")
            }

            // Set default model path if any models are found
            if (availableModels.isNotEmpty()) {
                // Check if current model path is still valid
                val currentModelValid = availableModels.any { it.second == modelPath }
                if (!currentModelValid) {
                    modelPath = availableModels.first().second
                    Log.i(TAG, "Set default model path: $modelPath")
                }
            } else {
                Log.i(TAG, "No models found. Model path remains: $modelPath")
            }
            
            // Set default mmproj model path if any are found
            if (availableMmprojModels.isNotEmpty()) {
                // Check if current mmproj model path is still valid
                val currentMmprojValid = availableMmprojModels.any { it.second == mmprojModelPath }
                if (!currentMmprojValid) {
                    mmprojModelPath = availableMmprojModels.first().second
                    Log.i(TAG, "Set default mmproj model path: $mmprojModelPath")
                }
            } else {
                Log.i(TAG, "No mmproj models found. MMProj path remains: $mmprojModelPath")
            }
            
            // Set default vocoder model path if any are found
            if (availableVocoderModels.isNotEmpty()) {
                // Check if current vocoder model path is still valid
                val currentVocoderValid = availableVocoderModels.any { it.second == vocoderModelPath }
                if (!currentVocoderValid) {
                    vocoderModelPath = availableVocoderModels.first().second
                    Log.i(TAG, "Set default vocoder model path: $vocoderModelPath")
                }
            } else {
                Log.i(TAG, "No vocoder models found. Vocoder path remains: $vocoderModelPath")
            }
            
            // Set default LoRA model path if any are found
            if (availableLoRAModels.isNotEmpty()) {
                // Check if current LoRA model path is still valid
                val currentLoRAValid = availableLoRAModels.any { it.second == loraModelPath }
                if (!currentLoRAValid) {
                    loraModelPath = availableLoRAModels.first().second
                    Log.i(TAG, "Set default LoRA model path: $loraModelPath")
                }
            } else {
                Log.i(TAG, "No LoRA models found. LoRA path remains: $loraModelPath")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Unexpected error in extractModelsFromAssets: ${e.message}", e)
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

        // Run directly on UI thread for simplicity in example app
        try {
            // Add null safety checks for all parameters
            val safeModelPath = modelPath.takeIf { it.isNotEmpty() } ?: run {
                isModelLoaded = false
                errorMessage = "Invalid model path"
                callback(false)
                return
            }
            
            val safeSystemPrompt = systemPrompt.takeIf { it.isNotEmpty() } ?: ""
            val safeNGpuLayers = nGpuLayers.coerceAtLeast(0)
            val safeNThreads = nThreads.coerceAtLeast(1)
            val safeNCtx = nCtx.coerceIn(256, 8192)

            Log.i(TAG, "Loading model with params:")
            Log.i(TAG, "- Model path: $safeModelPath")
            Log.i(TAG, "- Context size: $safeNCtx")
            Log.i(TAG, "- GPU layers: $safeNGpuLayers")
            Log.i(TAG, "- Threads: $safeNThreads")
            Log.i(TAG, "- System prompt: $safeSystemPrompt")

            val params = LlamaMobile.InitParams(
                modelPath = safeModelPath,
                nCtx = safeNCtx,
                systemPrompt = safeSystemPrompt.takeIf { it.isNotEmpty() },  // Use null for empty string
                chatTemplate = null,  // Use null for optional parameter
                nBatch = 512,
                nUBatch = 512,
                nGpuLayers = safeNGpuLayers,
                nThreads = safeNThreads,
                useMmap = true,
                useMlock = false,
                embedding = enableEmbedding,
                poolingType = 0,
                embdNormalize = 0,
                flashAttention = false,
                cacheTypeK = null,  // Use null for optional parameter
                cacheTypeV = null  // Use null for optional parameter
            )

            // Initialize the context handle directly on UI thread with extensive safety checks
            val modelFile = File(params.modelPath)
            
            // Extra validation before calling native method
            try {
                // Check model file validity
                if (!modelFile.exists()) {
                    Log.e(TAG, "Model file does not exist: ${params.modelPath}")
                    errorMessage = "Model file not found: ${params.modelPath}"
                    callback(false)
                    return
                }
                
                if (!modelFile.isFile) {
                    Log.e(TAG, "Path is not a file: ${params.modelPath}")
                    errorMessage = "Path is not a file: ${params.modelPath}"
                    callback(false)
                    return
                }
                
                if (!modelFile.canRead()) {
                    Log.e(TAG, "Cannot read model file: ${params.modelPath}")
                    errorMessage = "Cannot read model file: ${params.modelPath}"
                    callback(false)
                    return
                }
                
                if (modelFile.length() < 1000000) { // Less than 1MB
                    Log.e(TAG, "Model file too small (${modelFile.length()} bytes) - might be corrupted")
                    errorMessage = "Model file is too small - might be corrupted"
                    callback(false)
                    return
                }
                
                // Log comprehensive information
                Log.i(TAG, "=== Model Loading Debug Info ===")
                Log.i(TAG, "About to call LlamaMobile.initContext() with:")
                // Check if getVersion method exists before calling
                // LlamaMobile.getVersion() might not be available
                Log.i(TAG, "- Model path: ${params.modelPath}")
                Log.i(TAG, "- Model file exists: ${modelFile.exists()}")
                Log.i(TAG, "- Model file readable: ${modelFile.canRead()}")
                Log.i(TAG, "- Model file size: ${modelFile.length()} bytes")
                Log.i(TAG, "- Context size: ${params.nCtx}")
                Log.i(TAG, "- GPU layers: ${params.nGpuLayers}")
                Log.i(TAG, "- Threads: ${params.nThreads}")
                Log.i(TAG, "- Embedding enabled: ${params.embedding}")
                Log.i(TAG, "- System prompt length: ${params.systemPrompt?.length ?: 0} characters")
            } catch (e: Exception) {
                Log.e(TAG, "Error during pre-validation:", e)
                errorMessage = "Validation error: ${e.message}"
                callback(false)
                return
            }
            
            // Now call the native method with maximum error handling
            try {
                Log.i(TAG, "Calling LlamaMobile.initContext()...")
                contextHandle = LlamaMobile.initContext(params)
                Log.i(TAG, "initContext returned handle: $contextHandle")
            } catch (t: Throwable) {
                // Catch all throwables, including native exceptions and errors
                Log.e(TAG, "=== FATAL: Native exception during initContext ===")
                Log.e(TAG, "Exception type: ${t.javaClass.name}")
                Log.e(TAG, "Exception message: ${t.message}")
                
                // Log stack trace
                val stackTrace = t.stackTrace.joinToString("\n") {
                    "  at ${it.className}.${it.methodName}(${it.fileName}:${it.lineNumber})"
                }
                Log.e(TAG, "Stack trace:\n$stackTrace")
                
                // Log thread info
                val currentThread = Thread.currentThread()
                Log.e(TAG, "Current thread: ${currentThread.name} (ID: ${currentThread.id})")
                Log.e(TAG, "Thread state: ${currentThread.state}")
                
                isModelLoaded = false
                errorMessage = "Native crash: ${t.javaClass.simpleName}: ${t.message}"
                callback(false)
                return
            }

            if (contextHandle != 0L) {
                isModelLoaded = true
                errorMessage = null
                Log.i(TAG, "Model loaded successfully with handle: $contextHandle")
                
                // Initialize multimodal if mmproj path is provided
                if (mmprojModelPath.isNotEmpty()) {
                    try {
                        val mmprojFile = File(mmprojModelPath)
                        if (mmprojFile.exists() && mmprojFile.isFile && mmprojFile.canRead()) {
                            Log.i(TAG, "Initializing multimodal with mmproj path: $mmprojModelPath")
                            // Assuming LlamaMobile has an initMultimodal method
                            val multimodalSuccess = LlamaMobile.initMultimodal(contextHandle, mmprojModelPath, nGpuLayers > 0)
                            Log.i(TAG, "Multimodal initialization: $multimodalSuccess")
                        } else {
                            Log.e(TAG, "Invalid mmproj model path: $mmprojModelPath")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error initializing multimodal: ${e.message}")
                    }
                }
                
                // Initialize vocoder if vocoder path is provided
                if (vocoderModelPath.isNotEmpty()) {
                    try {
                        val vocoderFile = File(vocoderModelPath)
                        if (vocoderFile.exists() && vocoderFile.isFile && vocoderFile.canRead()) {
                            Log.i(TAG, "Initializing vocoder with path: $vocoderModelPath")
                            // Assuming LlamaMobile has an initVocoder method
                            val vocoderSuccess = LlamaMobile.initVocoder(contextHandle, vocoderModelPath)
                            Log.i(TAG, "Vocoder initialization: $vocoderSuccess")
                        } else {
                            Log.e(TAG, "Invalid vocoder model path: $vocoderModelPath")
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Error initializing vocoder: ${e.message}")
                    }
                }
                
                callback(true)
            } else {
                isModelLoaded = false
                errorMessage = "Failed to load model: context handle is zero"
                Log.e(TAG, errorMessage ?: "Unknown error")
                callback(false)
            }
        } catch (e: Exception) {
            val errorMsg = "Failed to load model: ${e.message}"
            Log.e(TAG, errorMsg, e)
            isModelLoaded = false
            errorMessage = errorMsg
            callback(false)
        }
    }

    fun unloadModel() {
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = 0
        }
        isModelLoaded = false
        errorMessage = null
    }
}
