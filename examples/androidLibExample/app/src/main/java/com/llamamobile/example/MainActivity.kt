package com.llamamobile.example

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.util.Log
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.CacheType
import com.llamamobile.example.databinding.ActivityMainBinding
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlin.math.minOf
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.nio.ByteBuffer
import java.util.concurrent.locks.ReentrantLock
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack

class MainActivity : AppCompatActivity(), AdapterView.OnItemSelectedListener {

    private lateinit var binding: ActivityMainBinding
    private var contextHandle: Long = 0

    // Model data structures
    private val modelPaths = mutableMapOf<String, String>()
    private val vocoderModelPaths = mutableMapOf<String, String>()
    private val projectionFilePaths = mutableMapOf<String, String>()

    // UI state
    private var isGenerating = false
    private var isPlayingAudio = false
    private var selectedImage: Uri? = null
    private val debugLogLock = ReentrantLock()
    private var generatedAudioData: FloatArray? = null
    private var audioPlaybackOffset: Int = 0 // For pause/resume functionality

    // Request codes
    private val REQUEST_IMAGE_PICKER = 1001
    private val REQUEST_STORAGE_PERMISSION = 1002

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Request storage permissions
        requestStoragePermissions()

        // Initialize UI components
        setupUIComponents()

        // Scan for model files
        scanForModelFiles()
        scanForVocoderModelFiles()
        scanForProjectionFiles()

        // Set up event listeners
        setupEventListeners()
    }

    private fun requestStoragePermissions() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {

            ActivityCompat.requestPermissions(this, arrayOf(
                android.Manifest.permission.READ_EXTERNAL_STORAGE,
                android.Manifest.permission.WRITE_EXTERNAL_STORAGE
            ), REQUEST_STORAGE_PERMISSION)
        }
    }

    private fun setupUIComponents() {
        // Set up model spinners
        binding.modelSpinner.onItemSelectedListener = this
        binding.vocoderModelSpinner.onItemSelectedListener = this
        binding.projectionFileSpinner.onItemSelectedListener = this

        // Initialize debug log
        updateDebugLog("Debug log initialized")
    }

    private fun setupEventListeners() {
        // Initialize button
        binding.initializeButton.setOnClickListener {
            initializeModel()
        }

        // Generate button
        binding.generateButton.setOnClickListener {
            generateCompletion()
        }

        // Conversation button
        binding.conversationButton.setOnClickListener {
            startConversation()
        }

        // Embedding button
        binding.embeddingButton.setOnClickListener {
            generateEmbedding()
        }

        // Complete button
        binding.completeButton.setOnClickListener {
            completePrompt()
        }

        // Multimodal button
        binding.multimodalButton.setOnClickListener {
            performMultimodal()
        }

        // TTS button
        binding.ttsButton.setOnClickListener {
            generateTTS()
        }

        // Image picker button
        binding.imagePickerButton.setOnClickListener {
            pickImage()
        }

        // Audio playback buttons
        binding.playAudioButton.setOnClickListener {
            playAudio()
        }

        binding.stopAudioButton.setOnClickListener {
            stopAudio()
        }

        // Clear button
        binding.clearButton.setOnClickListener {
            clearAll()
        }
    }

    private fun scanForModelFiles() {
        val directoriesToScan = mutableListOf<File>()

        // Add internal storage directories
        directoriesToScan.add(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: File("/sdcard/Download"))
        directoriesToScan.add(File("/sdcard/Documents"))
        directoriesToScan.add(File("/storage/emulated/0/Download"))
        directoriesToScan.add(File("/storage/emulated/0/Documents"))

        // Add app-specific directories
        directoriesToScan.add(File(filesDir, "models"))
        directoriesToScan.add(File(getExternalFilesDir(null), "models"))

        GlobalScope.launch(Dispatchers.IO) {
            modelPaths.clear()

            for (directory in directoriesToScan) {
                if (directory.exists() && directory.isDirectory) {
                    scanDirectoryForModels(directory, false)
                }
            }

            withContext(Dispatchers.Main) {
                updateModelSpinner()
                updateDebugLog("Found ${modelPaths.size} model files")
            }
        }
    }

    private fun scanForVocoderModelFiles() {
        val directoriesToScan = mutableListOf<File>()

        // Add internal storage directories
        directoriesToScan.add(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: File("/sdcard/Download"))
        directoriesToScan.add(File("/sdcard/Documents"))
        directoriesToScan.add(File("/storage/emulated/0/Download"))
        directoriesToScan.add(File("/storage/emulated/0/Documents"))

        // Add app-specific directories
        directoriesToScan.add(File(filesDir, "models"))
        directoriesToScan.add(File(getExternalFilesDir(null), "models"))

        GlobalScope.launch(Dispatchers.IO) {
            vocoderModelPaths.clear()

            for (directory in directoriesToScan) {
                if (directory.exists() && directory.isDirectory) {
                    scanDirectoryForModels(directory, true)
                }
            }

            withContext(Dispatchers.Main) {
                updateVocoderModelSpinner()
                updateDebugLog("Found ${vocoderModelPaths.size} vocoder model files")
            }
        }
    }

    private fun scanForProjectionFiles() {
        val directoriesToScan = mutableListOf<File>()

        // Add internal storage directories
        directoriesToScan.add(getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS) ?: File("/sdcard/Download"))
        directoriesToScan.add(File("/sdcard/Documents"))
        directoriesToScan.add(File("/storage/emulated/0/Download"))
        directoriesToScan.add(File("/storage/emulated/0/Documents"))

        // Add app-specific directories
        directoriesToScan.add(File(filesDir, "models"))
        directoriesToScan.add(File(getExternalFilesDir(null), "models"))

        GlobalScope.launch(Dispatchers.IO) {
            projectionFilePaths.clear()

            for (directory in directoriesToScan) {
                if (directory.exists() && directory.isDirectory) {
                    scanDirectoryForProjectionFiles(directory)
                }
            }

            withContext(Dispatchers.Main) {
                updateProjectionFileSpinner()
                updateDebugLog("Found ${projectionFilePaths.size} projection files")
            }
        }
    }

    private fun scanDirectoryForModels(directory: File, isVocoder: Boolean) {
        val files = directory.listFiles() ?: return

        for (file in files) {
            if (file.isFile) {
                val fileName = file.name
                if (fileName.lowercase().endsWith(".gguf")) {
                    val modelName = fileName.substringBeforeLast(".")
                    val filePath = file.absolutePath

                    if (isVocoder) {
                        vocoderModelPaths[modelName] = filePath
                    } else {
                        // Skip mmproj files when scanning for regular models
                        if (!fileName.lowercase().contains("mmproj")) {
                            modelPaths[modelName] = filePath
                        }
                    }
                }
            } else if (file.isDirectory) {
                // Recursively scan subdirectories
                scanDirectoryForModels(file, isVocoder)
            }
        }
    }

    private fun scanDirectoryForProjectionFiles(directory: File) {
        val files = directory.listFiles() ?: return

        for (file in files) {
            if (file.isFile) {
                val fileName = file.name
                if (fileName.lowercase().endsWith(".gguf") && fileName.lowercase().contains("mmproj")) {
                    val projectionFileName = fileName.substringBeforeLast(".")
                    projectionFilePaths[projectionFileName] = file.absolutePath
                }
            } else if (file.isDirectory) {
                // Recursively scan subdirectories
                scanDirectoryForProjectionFiles(file)
            }
        }
    }

    private fun updateModelSpinner() {
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, modelPaths.keys.toList())
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.modelSpinner.adapter = adapter
    }

    private fun updateVocoderModelSpinner() {
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, vocoderModelPaths.keys.toList())
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.vocoderModelSpinner.adapter = adapter
    }

    private fun updateProjectionFileSpinner() {
        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, projectionFilePaths.keys.toList())
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.projectionFileSpinner.adapter = adapter
    }

    private fun initializeModel() {
        val selectedModelName = binding.modelSpinner.selectedItem?.toString()
        val modelPath = modelPaths[selectedModelName] ?: return

        showLoading(true)
        updateDebugLog("Initializing model: $selectedModelName")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                val initParams = LlamaMobile.InitParams(
                    modelPath = modelPath,
                    nCtx = 2048,
                    cacheType = CacheType.MEMORY
                )

                contextHandle = LlamaMobile.initContext(initParams)

                withContext(Dispatchers.Main) {
                    if (contextHandle != 0L) {
                        Toast.makeText(this@MainActivity, "Model initialized successfully", Toast.LENGTH_SHORT).show()
                        enableButtons(true)
                        updateDebugLog("Model initialized successfully")
                    } else {
                        Toast.makeText(this@MainActivity, "Failed to initialize model", Toast.LENGTH_SHORT).show()
                        updateDebugLog("Failed to initialize model")
                    }
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    Toast.makeText(this@MainActivity, "Error initializing model: ${e.message}", Toast.LENGTH_LONG).show()
                    updateDebugLog("Error initializing model: ${e.message}")
                    showLoading(false)
                }
            }
        }
    }

    private fun generateCompletion() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        isGenerating = true
        binding.outputTextView.text = ""
        updateDebugLog("Generating completion...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = prompt,
                    temperature = 0.8f,
                    maxTokens = 200,
                    tokenCallback = object : LlamaMobile.TokenCallback {
                        override fun onToken(token: String?): Boolean {
                            if (!isGenerating) return false
                            
                            if (token != null) {
                                GlobalScope.launch(Dispatchers.Main) {
                                    binding.outputTextView.append(token)
                                }
                            }
                            return true
                        }
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)

                withContext(Dispatchers.Main) {
                    if (result != null) {
                        updateDebugLog("Completion generated successfully")
                    } else {
                        if (binding.outputTextView.text.isEmpty()) {
                            binding.outputTextView.text = "Failed to generate completion"
                        }
                        updateDebugLog("Failed to generate completion")
                    }
                    isGenerating = false
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error generating completion: ${e.message}"
                    updateDebugLog("Error generating completion: ${e.message}")
                    isGenerating = false
                    showLoading(false)
                }
            }
        }
    }

    private fun startConversation() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        isGenerating = true
        binding.outputTextView.text = ""
        updateDebugLog("Starting conversation...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                // For conversation, we need to enable context tracking
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = prompt,
                    temperature = 0.8f,
                    maxTokens = 250,
                    stopSequences = listOf("\nUser:", "\nAssistant:"),
                    tokenCallback = object : LlamaMobile.TokenCallback {
                        override fun onToken(token: String?): Boolean {
                            if (!isGenerating) return false
                            
                            if (token != null) {
                                GlobalScope.launch(Dispatchers.Main) {
                                    binding.outputTextView.append(token)
                                }
                            }
                            return true
                        }
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)

                withContext(Dispatchers.Main) {
                    if (result != null) {
                        updateDebugLog("Conversation completed successfully")
                    } else {
                        if (binding.outputTextView.text.isEmpty()) {
                            binding.outputTextView.text = "Failed to start conversation"
                        }
                        updateDebugLog("Failed to start conversation")
                    }
                    isGenerating = false
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error starting conversation: ${e.message}"
                    updateDebugLog("Error starting conversation: ${e.message}")
                    isGenerating = false
                    showLoading(false)
                }
            }
        }
    }

    private fun generateEmbedding() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        updateDebugLog("Generating embedding...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                // To generate embeddings, we need to reinitialize the model with embedding enabled
                val selectedModelName = binding.modelSpinner.selectedItem?.toString()
                val modelPath = modelPaths[selectedModelName] ?: return@launch

                // Create a new context with embedding enabled
                val embeddingContextHandle = LlamaMobile.initContext(
                    LlamaMobile.InitParams(
                        modelPath = modelPath,
                        nCtx = 2048,
                        embedding = true
                    )
                )

                if (embeddingContextHandle == 0L) {
                    throw RuntimeException("Failed to initialize embedding context")
                }

                // Generate completion with embedding
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = prompt,
                    maxTokens = 0 // Don't generate any tokens, just get embedding
                )

                val result = LlamaMobile.generateCompletion(embeddingContextHandle, completionParams)

                withContext(Dispatchers.Main) {
                    if (result != null) {
                        binding.outputTextView.text = "Embedding generated successfully for prompt.\n\n" +
                                "Tokens evaluated: ${result.tokensEvaluated}"
                        updateDebugLog("Embedding generated successfully")
                    } else {
                        binding.outputTextView.text = "Failed to generate embedding"
                        updateDebugLog("Failed to generate embedding")
                    }
                    // Release the temporary embedding context
                    LlamaMobile.releaseContext(embeddingContextHandle)
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error generating embedding: ${e.message}"
                    updateDebugLog("Error generating embedding: ${e.message}")
                    showLoading(false)
                }
            }
        }
    }

    private fun completePrompt() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        isGenerating = true
        binding.outputTextView.text = ""
        updateDebugLog("Completing prompt...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = prompt,
                    temperature = 0.7f,
                    maxTokens = 200,
                    topP = 0.9f,
                    topK = 30,
                    tokenCallback = object : LlamaMobile.TokenCallback {
                        override fun onToken(token: String?): Boolean {
                            if (!isGenerating) return false
                            
                            if (token != null) {
                                GlobalScope.launch(Dispatchers.Main) {
                                    binding.outputTextView.append(token)
                                }
                            }
                            return true
                        }
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)

                withContext(Dispatchers.Main) {
                    if (result != null) {
                        updateDebugLog("Prompt completed successfully")
                    } else {
                        if (binding.outputTextView.text.isEmpty()) {
                            binding.outputTextView.text = "Failed to complete prompt"
                        }
                        updateDebugLog("Failed to complete prompt")
                    }
                    isGenerating = false
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error completing prompt: ${e.message}"
                    updateDebugLog("Error completing prompt: ${e.message}")
                    isGenerating = false
                    showLoading(false)
                }
            }
        }
    }

    private fun performMultimodal() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        if (selectedImage == null) {
            Toast.makeText(this, "Please select an image first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter a prompt", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        isGenerating = true
        binding.outputTextView.text = ""
        updateDebugLog("Performing multimodal analysis...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                // For multimodal, we need to use the selected image and prompt
                val multimodalPrompt = "Describe the image: $prompt"
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = multimodalPrompt,
                    temperature = 0.8f,
                    maxTokens = 300,
                    tokenCallback = object : LlamaMobile.TokenCallback {
                        override fun onToken(token: String?): Boolean {
                            if (!isGenerating) return false
                            
                            if (token != null) {
                                GlobalScope.launch(Dispatchers.Main) {
                                    binding.outputTextView.append(token)
                                }
                            }
                            return true
                        }
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)

                withContext(Dispatchers.Main) {
                    if (result != null) {
                        updateDebugLog("Multimodal analysis completed successfully")
                    } else {
                        if (binding.outputTextView.text.isEmpty()) {
                            binding.outputTextView.text = "Failed to perform multimodal analysis"
                        }
                        updateDebugLog("Failed to perform multimodal analysis")
                    }
                    isGenerating = false
                    showLoading(false)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error performing multimodal analysis: ${e.message}"
                    updateDebugLog("Error performing multimodal analysis: ${e.message}")
                    isGenerating = false
                    showLoading(false)
                }
            }
        }
    }

    private fun generateTTS() {
        if (contextHandle == 0L) {
            Toast.makeText(this, "Please initialize a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val prompt = binding.promptEditText.text.toString().trim()
        if (prompt.isEmpty()) {
            Toast.makeText(this, "Please enter text for TTS", Toast.LENGTH_SHORT).show()
            return
        }

        showLoading(true)
        updateDebugLog("Generating TTS...")

        GlobalScope.launch(Dispatchers.IO) {
            try {
                // Initialize vocoder if a model is selected
                val selectedVocoderModel = binding.vocoderModelSpinner.selectedItem?.toString()
                if (selectedVocoderModel != null) {
                    val vocoderModelPath = vocoderModelPaths[selectedVocoderModel]
                    if (vocoderModelPath != null) {
                        val initResult = LlamaMobile.initVocoder(contextHandle, vocoderModelPath)
                        if (initResult != 0) {
                            throw RuntimeException("Failed to initialize vocoder: $initResult")
                        }
                        updateDebugLog("Vocoder initialized successfully")
                    }
                }

                // Check if TTS is supported by the current model
                val ttsType = LlamaMobile.getTtsType(contextHandle)
                updateDebugLog("TTS Type: $ttsType")

                // Get formatted audio completion
                val formattedPrompt = LlamaMobile.getFormattedAudioCompletion(contextHandle, "{}", prompt)
                if (formattedPrompt == null) {
                    throw RuntimeException("Failed to get formatted audio completion")
                }
                updateDebugLog("Formatted prompt: $formattedPrompt")

                // Generate audio tokens
                val completionParams = LlamaMobile.CompletionParams(
                    prompt = formattedPrompt,
                    temperature = 0.0f, // Deterministic output for TTS
                    maxTokens = 500,
                    tokenCallback = object : LlamaMobile.TokenCallback {
                        override fun onToken(token: String?): Boolean {
                            if (token != null) {
                                GlobalScope.launch(Dispatchers.Main) {
                                    binding.outputTextView.append(token)
                                }
                            }
                            return true
                        }
                    }
                )

                val result = LlamaMobile.generateCompletion(contextHandle, completionParams)
                val generatedText = result?.text ?: binding.outputTextView.text.toString()

                // Extract audio tokens from the generated text
                updateDebugLog("Extracting audio tokens...")
                val audioTokens = LlamaMobile.getAudioGuideTokens(contextHandle, prompt)
                if (audioTokens == null) {
                    throw RuntimeException("Failed to get audio tokens")
                }
                updateDebugLog("Got ${audioTokens.size} audio tokens")

                // Decode audio tokens to float audio data
                updateDebugLog("Decoding audio tokens...")
                val audioData = LlamaMobile.decodeAudioTokens(contextHandle, audioTokens)
                if (audioData == null || audioData.isEmpty()) {
                    throw RuntimeException("Failed to decode audio tokens")
                }
                updateDebugLog("Decoded ${audioData.size} float samples")

                // Store the generated audio data
                withContext(Dispatchers.Main) {
                    generatedAudioData = audioData
                    binding.playAudioButton.isEnabled = true
                    binding.stopAudioButton.isEnabled = true
                    updateDebugLog("Audio data stored, playback controls enabled")
                }

                // Play the audio automatically
                withContext(Dispatchers.Main) {
                    updateDebugLog("Playing audio...")
                    playGeneratedAudio(audioData)
                }

                withContext(Dispatchers.Main) {
                    updateDebugLog("TTS generation and playback completed successfully")
                    Toast.makeText(this@MainActivity, "TTS generation and playback completed", Toast.LENGTH_LONG).show()
                }

            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    binding.outputTextView.text = "Error generating TTS: ${e.message}"
                    updateDebugLog("Error generating TTS: ${e.message}")
                    e.printStackTrace()
                }
            } finally {
                withContext(Dispatchers.Main) {
                    showLoading(false)
                }
            }
        }
    }

    private fun pickImage() {
        val intent = Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
        startActivityForResult(intent, REQUEST_IMAGE_PICKER)
    }

    private var audioTrack: AudioTrack? = null

    private fun playAudio() {
        if (isPlayingAudio) {
            // If audio is playing, toggle to pause
            pauseAudio()
            return
        }

        val audioData = generatedAudioData
        if (audioData == null || audioData.isEmpty()) {
            Toast.makeText(this, "No audio data available", Toast.LENGTH_SHORT).show()
            return
        }

        updateDebugLog("Playing audio...")
        playGeneratedAudio(audioData)
    }

    private fun playGeneratedAudio(audioData: FloatArray) {
        if (isPlayingAudio) {
            stopAudio()
        }

        GlobalScope.launch(Dispatchers.Main) {
            val sampleRate = 24000 // Default sample rate for TTS
            val channelConfig = AudioFormat.CHANNEL_OUT_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_FLOAT
            val bufferSize = AudioTrack.getMinBufferSize(sampleRate, channelConfig, audioFormat)

            try {
                updateDebugLog("AudioTrack configuration: sampleRate=$sampleRate, bufferSize=$bufferSize")

                // Create audio track
                audioTrack = AudioTrack(
                    AudioManager.STREAM_MUSIC,
                    sampleRate,
                    channelConfig,
                    audioFormat,
                    bufferSize * 2,
                    AudioTrack.MODE_STREAM
                )

                if (audioTrack?.state != AudioTrack.STATE_INITIALIZED) {
                    throw RuntimeException("AudioTrack initialization failed")
                }

                // Start playback
                audioTrack?.play()
                isPlayingAudio = true
                binding.playAudioButton.text = "Pause"

                // Convert float array to ByteBuffer
                val byteBuffer = ByteBuffer.allocate(audioData.size * 4)
                for (value in audioData) {
                    byteBuffer.putFloat(value)
                }
                byteBuffer.rewind()

                // Write audio data in chunks, checking for pause/stop conditions
                val chunkSize = bufferSize
                val byteArray = ByteArray(chunkSize)

                while (audioPlaybackOffset < byteBuffer.limit() && isPlayingAudio) {
                    val bytesToWrite = minOf(chunkSize, byteBuffer.limit() - audioPlaybackOffset)
                    byteBuffer.position(audioPlaybackOffset)
                    byteBuffer.get(byteArray, 0, bytesToWrite)
                    
                    val bytesWritten = audioTrack?.write(byteArray, 0, bytesToWrite) ?: 0
                    if (bytesWritten < bytesToWrite) {
                        updateDebugLog("Warning: Could not write all audio data")
                    }
                    
                    audioPlaybackOffset += bytesToWrite
                    
                    // Small delay to allow UI interaction
                    delay(10)
                }

                // Handle completion or pause
                if (audioPlaybackOffset >= byteBuffer.limit()) {
                    // Playback completed
                    updateDebugLog("Audio playback completed")
                    Toast.makeText(this@MainActivity, "Audio playback completed", Toast.LENGTH_SHORT).show()
                    stopAudio()
                } else if (!isPlayingAudio) {
                    // Paused
                    updateDebugLog("Audio playback paused")
                }
            } catch (e: Exception) {
                updateDebugLog("Error playing audio: ${e.message}")
                e.printStackTrace()
                Toast.makeText(this@MainActivity, "Error playing audio: ${e.message}", Toast.LENGTH_SHORT).show()
                stopAudio()
            }
        }
    }

    private fun pauseAudio() {
        if (!isPlayingAudio) return

        audioTrack?.pause()
        isPlayingAudio = false
        binding.playAudioButton.text = "Resume"
        updateDebugLog("Audio playback paused")
    }

    private fun stopAudio() {
        if (!isPlayingAudio) {
            return
        }

        updateDebugLog("Stopping audio playback")
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
        isPlayingAudio = false
        audioPlaybackOffset = 0 // Reset offset when stopping
        binding.playAudioButton.text = "Play"
        Toast.makeText(this, "Audio playback stopped", Toast.LENGTH_SHORT).show()
    }

    private fun clearAll() {
        binding.promptEditText.text.clear()
        binding.outputTextView.text = ""
        updateDebugLog("All cleared")
    }

    private fun showLoading(loading: Boolean) {
        binding.activityIndicator.visibility = if (loading) View.VISIBLE else View.GONE
        binding.initializeButton.isEnabled = !loading
        binding.generateButton.isEnabled = !loading && contextHandle != 0L
    }

    private fun enableButtons(enabled: Boolean) {
        binding.generateButton.isEnabled = enabled
        binding.conversationButton.isEnabled = enabled
        binding.embeddingButton.isEnabled = enabled
        binding.completeButton.isEnabled = enabled
        binding.multimodalButton.isEnabled = enabled
        binding.ttsButton.isEnabled = enabled
        binding.imagePickerButton.isEnabled = enabled
    }

    private fun updateDebugLog(message: String) {
        debugLogLock.lock()
        try {
            val timestamp = System.currentTimeMillis()
            val logEntry = "[$timestamp] $message\n"
            binding.debugLogTextView.append(logEntry)
        } finally {
            debugLogLock.unlock()
        }
    }

    override fun onItemSelected(parent: AdapterView<*>, view: View, position: Int, id: Long) {
        // Handle spinner selections
    }

    override fun onNothingSelected(parent: AdapterView<*>) {
        // Handle no selection
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQUEST_IMAGE_PICKER && resultCode == RESULT_OK && data != null) {
            selectedImage = data.data
            selectedImage?.let {
                binding.selectedImageView.setImageURI(it)
                updateDebugLog("Image selected")
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == REQUEST_STORAGE_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                // Permissions granted, rescan for models
                scanForModelFiles()
                scanForVocoderModelFiles()
                scanForProjectionFiles()
            } else {
                Toast.makeText(this, "Storage permissions are required to scan for model files", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Release context when activity is destroyed
        if (contextHandle != 0L) {
            LlamaMobile.releaseContext(contextHandle)
            contextHandle = 0
        }
    }
}
