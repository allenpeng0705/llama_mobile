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
        
        // Use the public generateSpeech API
        activity?.runOnUiThread {
            binding.ttsStatusTextView.text = "Generating speech using public API..."
        }
        
        // Create TTS options
        val options = LlamaMobile.TTSOptions.Builder()
            .setSampleRate(24000)
            .setSaveToFile(false)
            .build()
        
        // Generate speech using the public API
        val result = LlamaMobile.generateSpeech(currentAppState.contextHandle, text, options)
        
        Log.d("TTSTestFragment", "- Speech generation result: ${if (result.isSuccess) "Success" else "Failure"}")
        
        if (result.isSuccess) {
            val speechResult = result.value
            Log.d("TTSTestFragment", "- Speech result: $speechResult")
            
            if (speechResult != null) {
                val audioSamples = speechResult.audioSamples
                Log.d("TTSTestFragment", "- Audio samples: ${audioSamples?.size ?: 0}")
                
                if (audioSamples != null && audioSamples.isNotEmpty()) {
                    handleSuccess(audioSamples, "public API", currentAppState)
                } else {
                    activity?.runOnUiThread {
                        isProcessing = false
                        updateProcessingUI()
                        binding.ttsStatusTextView.text = "❌ Failed: No audio samples generated"
                    }
                }
            } else {
                activity?.runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    binding.ttsStatusTextView.text = "❌ Failed: No speech result"
                }
            }
        } else {
            val error = result.error
            Log.e("TTSTestFragment", "- Speech generation failed: $error")
            activity?.runOnUiThread {
                isProcessing = false
                updateProcessingUI()
                binding.ttsStatusTextView.text = "❌ Failed: ${error?.message ?: "Unknown error"}"
            }
        }
    }
    private fun handleSuccess(audioSamples: FloatArray, method: String, currentAppState: AppState) {
        // Save audio to WAV file
        val tempDir = context?.filesDir
        val tempFileName = "tts_output_latest.wav"
        val tempFilePath = File(tempDir, tempFileName).absolutePath
        
        val saveSuccess = LlamaMobile.saveAudioToWav(
            currentAppState.contextHandle,
            tempFilePath,
            audioSamples,
            sampleRate
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