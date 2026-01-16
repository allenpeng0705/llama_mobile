package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.sdkexample.databinding.FragmentMultimodalTestBinding

class MultimodalTestFragment : Fragment() {

    private lateinit var binding: FragmentMultimodalTestBinding
    private lateinit var appState: AppState
    private var isProcessing = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentMultimodalTestBinding.inflate(inflater, container, false)
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
            // Set default prompt
            binding.multimodalPromptEditText.setText("Describe the image")

            // Set up generate response button click listener
            binding.generateResponseButton.setOnClickListener {
                handleGenerateResponse()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with multimodal fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
    }

    private fun handleGenerateResponse() {
        val prompt = binding.multimodalPromptEditText.text.toString().trim()
        if (prompt.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Generate response in a background thread
        Thread {
            try {
                // Create prompt with system message and user input
                val fullPrompt = appState.systemPrompt + "\n\n" + prompt + "\n"
                
                // Call the generateCompletion method
                val result = LlamaMobile.generateCompletion(
                    contextHandle = appState.contextHandle,
                    prompt = fullPrompt,
                    maxTokens = 2048, // Default value
                    temperature = 0.8f // Default value
                )
                val response = result?.text ?: ""
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    binding.responseTextView.text = response
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "Multimodal error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.generateResponseButton.isEnabled = modelLoaded && !isProcessing

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Multimodal ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateProcessingUI() {
        binding.generateResponseButton.isEnabled = appState.isModelLoaded && !isProcessing
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}