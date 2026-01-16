package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentTtsTestBinding

class TTSTestFragment : Fragment() {

    private lateinit var binding: FragmentTtsTestBinding
    private lateinit var appState: AppState
    private var isProcessing = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentTtsTestBinding.inflate(inflater, container, false)
        // Access appState safely during fragment creation
        try {
            appState = (activity as MainActivity).appState
        } catch (e: Exception) {
            // Log but don't crash - appState will be set later in onViewCreated if needed
            e.printStackTrace()
        }
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        try {
            // Set default text
            binding.ttsTextEditText.setText("Hello, this is a test of the text-to-speech functionality.")

            // Set up play TTS button click listener
            binding.playTTSButton.setOnClickListener {
                handlePlayTTS()
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

    private fun handlePlayTTS() {
        val text = binding.ttsTextEditText.text.toString().trim()
        if (text.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()
        binding.ttsStatusTextView.text = "Generating speech..."

        // Generate TTS in a background thread
        Thread {
            try {
                // Call the TTS method
                val audioSamples = LlamaMobile.generateAudioFromText(
                    contextHandle = appState.contextHandle,
                    text = text,
                    speakerJson = "{\"speaker\": \"default\"}"
                )
                val success = audioSamples != null && audioSamples.isNotEmpty()
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    binding.ttsStatusTextView.text = if (success) "Speech completed" else "Speech generation failed"
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "TTS error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                    binding.ttsStatusTextView.text = "Error generating speech"
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.playTTSButton.isEnabled = modelLoaded && !isProcessing

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "TTS ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        binding.playTTSButton.isEnabled = appState.isModelLoaded && !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}