package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.LlamaMobile
import com.llamamobile.LlamaMobile.LoraAdapter
import com.llamamobile.sdkexample.databinding.FragmentLoraBinding

class LoRAFragment : Fragment() {

    private lateinit var binding: FragmentLoraBinding
    private lateinit var appState: AppState
    private var isProcessing = false
    private var isLoraApplied = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        binding = FragmentLoraBinding.inflate(inflater, container, false)
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
            // Set default values from AppState
            binding.loraPathEditText.setText(appState.loraModelPath)
            binding.loraPathEditText.isEnabled = false // Read-only since we select from settings
            binding.loraScaleEditText.setText("1.0")

            // Set up button click listeners
            binding.applyLoraButton.setOnClickListener {
                handleApplyLora()
            }

            binding.removeLoraButton.setOnClickListener {
                handleRemoveLora()
            }

            // Update UI based on model loading status
            updateModelLoadedUI()
            updateLoraStatusUI()
        } catch (e: Exception) {
            // Log but don't crash if there's an issue with LoRA fragment initialization
            e.printStackTrace()
        }
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
        updateLoraStatusUI()
    }

    private fun handleApplyLora() {
        val loraPath = appState.loraModelPath.trim()
        val loraScaleText = binding.loraScaleEditText.text.toString().trim()
        
        if (loraPath.isEmpty() || loraScaleText.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        val loraScale = try {
            loraScaleText.toFloat()
        } catch (e: NumberFormatException) {
            Toast.makeText(requireContext(), "Please enter a valid scale value", Toast.LENGTH_SHORT).show()
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Apply LoRA adapter in a background thread
        Thread {
            try {
                // Create LoRA adapter
                val loraAdapter = LoraAdapter(path = loraPath, scale = loraScale)
                
                // Call the new LlamaMobile applyLoRAAdapters method
                val result = LlamaMobile.applyLoraAdapters(appState.contextHandle, arrayOf(loraAdapter))
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    if (result) {
                        isLoraApplied = true
                        updateLoraStatusUI()
                        Toast.makeText(requireContext(), "LoRA adapter applied successfully", Toast.LENGTH_SHORT).show()
                    } else {
                        Toast.makeText(requireContext(), "Failed to apply LoRA adapter", Toast.LENGTH_SHORT).show()
                    }
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "LoRA error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun handleRemoveLora() {
        if (!appState.isModelLoaded || isProcessing) {
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Remove LoRA adapter in a background thread
        Thread {
            try {
                // Call the new LlamaMobile removeLoraAdapters method
                LlamaMobile.removeLoraAdapters(appState.contextHandle)
                
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    isLoraApplied = false
                    updateLoraStatusUI()
                    Toast.makeText(requireContext(), "LoRA adapter removed successfully", Toast.LENGTH_SHORT).show()
                }
            } catch (e: Exception) {
                requireActivity().runOnUiThread {
                    isProcessing = false
                    updateProcessingUI()
                    Toast.makeText(requireContext(), "LoRA removal error: ${e.localizedMessage}", Toast.LENGTH_SHORT).show()
                }
            }
        }.start()
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.applyLoraButton.isEnabled = modelLoaded && !isProcessing
        binding.removeLoraButton.isEnabled = modelLoaded && !isProcessing && isLoraApplied

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else {
            binding.statusTextView.text = "Model loaded and LoRA ready"
            binding.statusTextView.setTextColor(android.graphics.Color.GREEN)
        }
    }

    private fun updateLoraStatusUI() {
        if (isLoraApplied) {
            binding.loraStatusTextView.text = "✅ LoRA adapter applied"
            binding.loraStatusTextView.setTextColor(android.graphics.Color.GREEN)
        } else {
            binding.loraStatusTextView.text = "❌ No LoRA adapter applied"
            binding.loraStatusTextView.setTextColor(android.graphics.Color.RED)
        }
    }

    private fun updateProcessingUI() {
        binding.applyLoraButton.isEnabled = appState.isModelLoaded && !isProcessing
        binding.removeLoraButton.isEnabled = appState.isModelLoaded && !isProcessing && isLoraApplied
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}
