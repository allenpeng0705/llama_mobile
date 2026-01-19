package com.llamamobile.sdkexample

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import android.os.Bundle
import android.os.Environment
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentTtsTestBinding
import java.io.File

class TTSTestFragment : Fragment() {

    private var _binding: FragmentTtsTestBinding? = null
    private val binding get() = _binding!!
    private var appState: AppState? = null
    private var isProcessing = false
    private var isPlaying = false
    private var audioSamples: FloatArray? = null
    private var audioTrack: AudioTrack? = null
    private val sampleRate = 24000 // Default sample rate for TTS models

    override fun onAttach(context: Context) {
        super.onAttach(context)
        // Access appState when the fragment is properly attached to the activity
        appState = (context as? MainActivity)?.appState
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentTtsTestBinding.inflate(inflater, container, false)
        return _binding!!.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            
            // Set default text
            binding.ttsTextEditText.setText("Hello, this is a test of the text-to-speech functionality.")

            // Set up button click listeners
            binding.backButton.setOnClickListener {
                // Navigate back to the previous fragment
                requireActivity().supportFragmentManager.popBackStack()
            }
            binding.generateSpeechButton.setOnClickListener {
                generateSpeech()
            }
            binding.playAudioButton.setOnClickListener {
                playAudio()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with TTS fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }

    private fun updateModelLoadedUI() {
        Log.d("TTSTestFragment", "updateModelLoadedUI called")
        val modelLoaded = appState?.isModelLoaded ?: false
        val currentAppState = appState
        val contextHandle = currentAppState?.contextHandle ?: 0L
        
        Log.d("TTSTestFragment", "- Model loaded: $modelLoaded")
        Log.d("TTSTestFragment", "- Context handle: $contextHandle")
        
        // Log vocoder status but don't store it since we don't use it for button state
        if (modelLoaded && contextHandle != 0L) {
            val vocoderEnabled = LlamaMobile.isVocoderEnabled(contextHandle)
            Log.d("TTSTestFragment", "- Vocoder enabled: $vocoderEnabled")
        } else {
            Log.d("TTSTestFragment", "- Vocoder enabled: false (no model/context)")
        }
        
        // Update vocoder status
        val actualVocoderEnabled = if (modelLoaded && contextHandle != 0L) LlamaMobile.isVocoderEnabled(contextHandle) else false
        if (actualVocoderEnabled) {
            binding.vocoderStatusTextView.text = "Vocoder enabled"
            binding.vocoderStatusTextView.setTextColor(android.graphics.Color.GREEN)
        } else {
            binding.vocoderStatusTextView.text = "Vocoder not enabled"
            binding.vocoderStatusTextView.setTextColor(android.graphics.Color.RED)
        }

        // Update TTS model type
        if (modelLoaded && contextHandle != 0L) {
            val ttsType = LlamaMobile.getTTSType(contextHandle)
            Log.d("TTSTestFragment", "- TTS Model Type: $ttsType")
            binding.ttsModelTypeTextView.text = "TTS Model Type: $ttsType"
        } else {
            Log.d("TTSTestFragment", "- TTS Model Type: Unknown (no model/context)")
            binding.ttsModelTypeTextView.text = "TTS Model Type: Unknown"
        }

        // Update vocoder model info
        if (currentAppState?.vocoderModelPath?.isNotEmpty() == true) {
            val vocoderFileName = currentAppState.vocoderModelPath.substringAfterLast(File.separator)
            Log.d("TTSTestFragment", "- Vocoder model path: ${currentAppState.vocoderModelPath}")
            binding.vocoderModelTextView.text = "Vocoder model loaded: $vocoderFileName"
            binding.vocoderModelTextView.setTextColor(android.graphics.Color.GREEN)
        } else {
            Log.d("TTSTestFragment", "- No vocoder model path available")
            binding.vocoderModelTextView.text = "No vocoder files found for TTS"
            binding.vocoderModelTextView.setTextColor(android.graphics.Color.DKGRAY)
        }

        // Update generate button state
        // Enable generate button if model is loaded, even if vocoder isn't explicitly enabled yet
        // Some TTS models might work without explicit vocoder initialization or handle it internally
        val generateEnabled = modelLoaded && !isProcessing
        Log.d("TTSTestFragment", "- Generate button enabled: $generateEnabled")
        binding.generateSpeechButton.isEnabled = generateEnabled

        // Update status text
        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "TTS ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        val modelLoaded = appState?.isModelLoaded ?: false
        val currentAppState = appState
        val vocoderEnabled = if (modelLoaded && currentAppState != null) LlamaMobile.isVocoderEnabled(currentAppState.contextHandle) else false
        binding.generateSpeechButton.isEnabled = modelLoaded && vocoderEnabled && !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }

    private fun generateSpeech() {
        Log.d("TTSTestFragment", "generateSpeech called")
        val text = binding.ttsTextEditText.text.toString().trim()
        
        Log.d("TTSTestFragment", "- Input text: $text")
        Log.d("TTSTestFragment", "- Is processing: $isProcessing")
        
        if (text.isEmpty() || isProcessing) {
            Log.d("TTSTestFragment", "- Returning early (empty text or already processing)")
            return
        }

        val currentAppState = appState ?: run {
            Log.e("TTSTestFragment", "- App state not initialized")
            activity?.let { Toast.makeText(it, "App state not initialized", Toast.LENGTH_SHORT).show()}
            return
        }

        Log.d("TTSTestFragment", "- App state: $currentAppState")
        Log.d("TTSTestFragment", "- Model loaded: ${currentAppState.isModelLoaded}")
        Log.d("TTSTestFragment", "- Context handle: ${currentAppState.contextHandle}")

        if (!currentAppState.isModelLoaded) {
            Log.e("TTSTestFragment", "- Model not loaded")
            activity?.let { Toast.makeText(it, "Please load a model first", Toast.LENGTH_SHORT).show()}
            return
        }

        val vocoderEnabled = LlamaMobile.isVocoderEnabled(currentAppState.contextHandle)
        Log.d("TTSTestFragment", "- Vocoder enabled: $vocoderEnabled")
        
        if (!vocoderEnabled) {
            Log.e("TTSTestFragment", "- Vocoder not enabled")
            activity?.let { Toast.makeText(it, "Vocoder is not enabled", Toast.LENGTH_SHORT).show()}
            return
        }

        isProcessing = true
        updateProcessingUI()
        binding.ttsStatusTextView.text = "Generating audio from text..."

        // Generate TTS in a background thread
        Thread {
            try {
                Log.d("TTSTestFragment", "- Starting TTS generation in background thread")
                performTTS(text, currentAppState)
            } catch (e: Exception) {
                Log.e("TTSTestFragment", "- TTS error during generation", e)
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    activity?.let { Toast.makeText(it, "TTS error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
                    binding.ttsStatusTextView.text = "Error generating speech"
                }
            }
        }.start()
    }

    private fun performTTS(text: String, currentAppState: AppState) {
        Log.d("TTSTestFragment", "performTTS called")
        Log.d("TTSTestFragment", "- Text: $text")
        Log.d("TTSTestFragment", "- Context handle: ${currentAppState.contextHandle}")
        
        // Check TTS model type
        val ttsType = LlamaMobile.getTTSType(currentAppState.contextHandle)
        val isKnownTTSModel = ttsType != LlamaMobile.TTSModelType.UNKNOWN
        
        Log.d("TTSTestFragment", "- TTS Type: $ttsType")
        Log.d("TTSTestFragment", "- Is known TTS model: $isKnownTTSModel")
        
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "TTS Model Info: Type - $ttsType, Known - $isKnownTTSModel"
        }
        
        // Try built-in TTS method first if we have a proper TTS model
        if (isKnownTTSModel) {
            Log.d("TTSTestFragment", "- Using built-in generateAudioFromText method")
            activity?.runOnUiThread {
                binding.ttsStatusTextView.text = "Step 1: Using built-in generateAudioFromText method..."
            }
            
            // Try the built-in TTS method
            val samples = LlamaMobile.generateAudioFromText(
                contextHandle = currentAppState.contextHandle,
                text = text,
                speakerJson = "{\"speaker\": \"default\"}"
            )
            
            Log.d("TTSTestFragment", "- Built-in TTS result: ${samples?.size ?: 0} samples")
            
            if (samples != null && samples.isNotEmpty()) {
                Log.d("TTSTestFragment", "- Built-in TTS successful, handling success")
                handleSuccess(samples, "built-in TTS", currentAppState)
                return
            }
            Log.d("TTSTestFragment", "- Built-in TTS failed or returned empty samples")
        }
        
        // If built-in method fails, implement custom workflow
        Log.d("TTSTestFragment", "- Using custom TTS workflow")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Using custom TTS workflow: formatting + completion..."
        }
        
        // Format text for TTS
        Log.d("TTSTestFragment", "- Step 2: Formatting text for TTS")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Step 2: Formatting text for TTS..."
        }
        
        val formattedPrompt = LlamaMobile.getFormattedAudioCompletion(
            contextHandle = currentAppState.contextHandle,
            speakerJson = "{\"speaker\": \"default\"}",
            textToSpeak = text
        )
        
        Log.d("TTSTestFragment", "- Formatted prompt: ${formattedPrompt?.take(50) ?: "null"}${if (formattedPrompt?.length ?: 0 > 50) "..." else ""}")
        
        if (formattedPrompt == null) {
            Log.e("TTSTestFragment", "- Failed at Step 2: Cannot format text for TTS")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ Failed at Step 2: Cannot format text for TTS. Check if your model supports TTS formatting."
            }
            return
        }
        
        // Debug: Check what's in the formatted prompt
        Log.d("TTSTestFragment", "Formatted Prompt: $formattedPrompt")
        Log.d("TTSTestFragment", "Formatted Prompt Length: ${formattedPrompt.length}")
        
        // If formatted prompt contains audio template markers, we should only tokenize the completion result
        val useOnlyCompletion = formattedPrompt.contains("<|audio_start|") || formattedPrompt.contains("<|text_start|")
        Log.d("TTSTestFragment", "- useOnlyCompletion: $useOnlyCompletion")
        
        // Get guide tokens
        Log.d("TTSTestFragment", "- Step 3: Getting audio guide tokens")
        val guideTokens = LlamaMobile.getAudioGuideTokens(
            contextHandle = currentAppState.contextHandle,
            textToSpeak = formattedPrompt
        )
        
        Log.d("TTSTestFragment", "- Guide tokens: ${guideTokens?.size ?: 0} tokens")
        
        if (guideTokens != null && guideTokens.isNotEmpty()) {
            Log.d("TTSTestFragment", "- Setting guide tokens")
            LlamaMobile.setGuideTokens(currentAppState.contextHandle, guideTokens)
        } else {
            Log.d("TTSTestFragment", "- Failed to get guide tokens, proceeding without")
        }
        
        // Generate audio content using text completion
        Log.d("TTSTestFragment", "- Step 4: Generating audio content using text completion")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Step 3: Generating audio content using text completion..."
        }
        
        // Create completion parameters
        val completionParams = LlamaMobile.CompletionParams(
            prompt = formattedPrompt,
            maxTokens = 200,
            temperature = 0.0f,
            ignoreEos = true,
            grammar = currentAppState.selectedGrammar
        )
        
        Log.d("TTSTestFragment", "- Completion params: prompt length=${formattedPrompt.length}, maxTokens=200")
        val completionResult = LlamaMobile.generateCompletion(currentAppState.contextHandle, completionParams)
        
        Log.d("TTSTestFragment", "- Completion result: ${completionResult?.take(50) ?: "null"}${if (completionResult?.length ?: 0 > 50) "..." else ""}")
        
        if (completionResult == null || completionResult.isEmpty()) {
            Log.e("TTSTestFragment", "- Failed at Step 4: Cannot generate audio content via text completion")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ Failed at Step 3: Cannot generate audio content via text completion."
            }
            return
        }
        
        // Debug: Print actual text content
        Log.d("TTSTestFragment", "Completion Result Content: \"$completionResult\"")
        
        // Combine prompt and completion for full audio tokens - or just use completion if prompt contains template markers
        val contentToTokenize = if (useOnlyCompletion) {
            // If prompt contains template markers, only use the completion result (prevents audio from template)
            completionResult
        } else {
            // Otherwise combine both
            formattedPrompt + completionResult
        }
        
        Log.d("TTSTestFragment", "Final Content to Tokenize: \"$contentToTokenize\"")
        
        // Try to generate audio from the combined content
        Log.d("TTSTestFragment", "- Step 5: Generating audio from content")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Step 4: Generating audio from content..."
        }
        
        // Use the iOS approach: tokenize, filter, then decode
        Log.d("TTSTestFragment", "- Step 5.1: Tokenizing content")
        val tokens = LlamaMobile.tokenize(currentAppState.contextHandle, contentToTokenize)
        
        if (tokens == null) {
            Log.e("TTSTestFragment", "- Failed to tokenize content")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ Failed at Step 4.1: Cannot tokenize audio content."
            }
            return
        }
        
        Log.d("TTSTestFragment", "- Generated ${tokens.size} tokens")
        
        // Debug step 5.2: Filter audio tokens (following iOS example)
        Log.d("TTSTestFragment", "- Step 5.2: Filtering audio tokens")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Step 4.2: Filtering audio tokens..."
        }
        
        // Filter tokens to only include audio tokens (151672-155772) and look for end token
        val audioTokens = mutableListOf<Int>()
        val audioEndToken = 151668 // <|audio_end|>
        
        var nonAudioTokens = 0
        
        for (token in tokens) {
            // Check if token is in audio range
            if (token >= 151672 && token <= 155772) {
                audioTokens.add(token)
            } else {
                nonAudioTokens++
            }
            
            // Check for end token
            if (token == audioEndToken) {
                Log.d("TTSTestFragment", "- Found audio end token")
                break
            }
        }
        
        Log.d("TTSTestFragment", "- Filtered to ${audioTokens.size} audio tokens (skipped non-audio: $nonAudioTokens)")
        
        if (audioTokens.isEmpty()) {
            Log.e("TTSTestFragment", "- No audio tokens found")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ No audio tokens found in generated content."
            }
            return
        }
        
        // Debug step 5.3: Decode audio tokens
        Log.d("TTSTestFragment", "- Step 5.3: Decoding audio tokens")
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Step 4.3: Decoding audio tokens..."
        }
        
        // Convert to IntArray and decode
        val audioTokensArray = audioTokens.toIntArray()
        val audioSamples = LlamaMobile.decodeAudioTokens(currentAppState.contextHandle, audioTokensArray)
        
        Log.d("TTSTestFragment", "- Audio samples after decoding: ${audioSamples?.size ?: 0} samples")
        
        if (audioSamples == null || audioSamples.isEmpty()) {
            Log.e("TTSTestFragment", "- Failed to decode audio tokens")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ Failed at Step 4.3: Cannot decode audio tokens."
            }
            return
        }
        
        handleSuccess(audioSamples, "custom workflow with token filtering", currentAppState)
    }

    private fun handleSuccess(audioSamples: FloatArray, method: String, currentAppState: AppState) {
        // Save audio to WAV file
        val tempDir = context?.filesDir
        val tempFileName = "tts_output_latest.wav"
        val tempFilePath = File(tempDir, tempFileName).absolutePath
        
        val saveSuccess = LlamaMobile.saveAudioToWav(
            contextHandle = currentAppState.contextHandle,
            filePath = tempFilePath,
            audioData = audioSamples,
            sampleRate = sampleRate
        )
        
        this.audioSamples = audioSamples
        
        activity?.runOnUiThread {
            isProcessing = false
            updateProcessingUI()
            
            // Enable play button when audio is available
            binding.playAudioButton.isEnabled = true
            
            if (saveSuccess) {
                binding.ttsStatusTextView.text = "✅ TTS generation completed successfully using $method.\n" +
                        "   - Generated ${audioSamples.size} audio samples at $sampleRate Hz\n" +
                        "   - Audio saved to: $tempFilePath"
            } else {
                binding.ttsStatusTextView.text = "⚠️ TTS generation completed but failed to save audio to file.\n" +
                        "   - Generated ${audioSamples.size} audio samples at $sampleRate Hz"
            }
        }
    }

    private fun playAudio() {
        val samples = this.audioSamples ?: return
        
        isPlaying = true
        binding.playAudioButton.isEnabled = false
        binding.playAudioButton.text = "Playing..."
        
        // Play audio in a background thread
        Thread {
            try {
                // Set up AudioTrack
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .build()
                
                val audioFormat = AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
                
                val bufferSize = AudioTrack.getMinBufferSize(sampleRate, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT)
                
                val audioTrack = AudioTrack.Builder()
                    .setAudioAttributes(audioAttributes)
                    .setAudioFormat(audioFormat)
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .build()
                
                this.audioTrack = audioTrack
                audioTrack.play()
                
                // Write audio data directly as floats (no byte conversion needed for PCM_FLOAT)
                var offset = 0
                
                while (offset < samples.size && isPlaying) {
                    val samplesToWrite = Math.min(bufferSize / 4, samples.size - offset) // 4 bytes per float
                    
                    // Use AudioTrack's float write method for PCM_FLOAT encoding
                    val framesWritten = audioTrack.write(samples, offset, samplesToWrite, AudioTrack.WRITE_BLOCKING)
                    
                    if (framesWritten > 0) {
                        offset += framesWritten
                    } else {
                        break // Error occurred
                    }
                }
                
                audioTrack.stop()
                audioTrack.release()
                
            } catch (e: Exception) {
                Log.e("TTSTestFragment", "Error playing audio", e)
                activity?.runOnUiThread {
                    activity?.let { Toast.makeText(it, "Error playing audio: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()}
                }
            } finally {
                isPlaying = false
                activity?.runOnUiThread {
                    binding.playAudioButton.isEnabled = true
                    binding.playAudioButton.text = "Play Audio"
                    this.audioTrack = null
                }
            }
        }.start()
    }
}