package com.llamamobile.sdkexample

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import com.llamamobile.sdk.LlamaMobileSdk
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
        appState = (activity as MainActivity).appState
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        // Set default values
        binding.loraPathEditText.setText("/path/to/your/lora.adapter")
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
    }

    override fun onResume() {
        super.onResume()
        // Check model status when fragment resumes
        updateModelLoadedUI()
        updateLoraStatusUI()
    }

    private fun handleApplyLora() {
        val loraPath = binding.loraPathEditText.text.toString().trim()
        val loraScaleText = binding.loraScaleEditText.text.toString().trim()
        
        if (loraPath.isEmpty() || loraScaleText.isEmpty() || isProcessing) {
            return
        }

        if (!appState.isModelLoaded) {
            Toast.makeText(requireContext(), "Please load a model first", Toast.LENGTH_SHORT).show()
            return
        }

        if (!appState.enableLoRA) {
            Toast.makeText(requireContext(), "LoRA is not enabled. Please enable it in Settings.", Toast.LENGTH_SHORT).show()
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

        // Apply LoRA adapter
        appState.llamaMobileSdk.applyLoRA(loraPath, loraScale, object : LlamaMobileSdk.ResultCallback<Boolean> {
            override fun onSuccess(result: Boolean) {
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

            override fun onError(error: String) {
                isProcessing = false
                updateProcessingUI()
                Toast.makeText(requireContext(), "LoRA error: $error", Toast.LENGTH_SHORT).show()
            }
        })
    }

    private fun handleRemoveLora() {
        if (!appState.isModelLoaded || isProcessing) {
            return
        }

        isProcessing = true
        updateProcessingUI()

        // Remove LoRA adapter
        appState.llamaMobileSdk.removeLoRA(object : LlamaMobileSdk.ResultCallback<Boolean> {
            override fun onSuccess(result: Boolean) {
                isProcessing = false
                updateProcessingUI()
                if (result) {
                    isLoraApplied = false
                    updateLoraStatusUI()
                    Toast.makeText(requireContext(), "LoRA adapter removed successfully", Toast.LENGTH_SHORT).show()
                } else {
                    Toast.makeText(requireContext(), "Failed to remove LoRA adapter", Toast.LENGTH_SHORT).show()
                }
            }

            override fun onError(error: String) {
                isProcessing = false
                updateProcessingUI()
                Toast.makeText(requireContext(), "LoRA removal error: $error", Toast.LENGTH_SHORT).show()
            }
        })
    }

    private fun updateModelLoadedUI() {
        val modelLoaded = appState.isModelLoaded
        binding.applyLoraButton.isEnabled = modelLoaded && !isProcessing && appState.enableLoRA
        binding.removeLoraButton.isEnabled = modelLoaded && !isProcessing && isLoraApplied

        if (!modelLoaded) {
            binding.statusTextView.text = "Model not loaded"
            binding.statusTextView.setTextColor(android.graphics.Color.RED)
        } else if (!appState.enableLoRA) {
            binding.statusTextView.text = "LoRA is disabled. Enable in Settings."
            binding.statusTextView.setTextColor(android.graphics.Color.YELLOW)
        } else {
            binding.statusTextView.text = "Model loaded and LoRA enabled"
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
        binding.applyLoraButton.isEnabled = appState.isModelLoaded && !isProcessing && appState.enableLoRA
        binding.removeLoraButton.isEnabled = appState.isModelLoaded && !isProcessing && isLoraApplied
        binding.progressBar.visibility = if (isProcessing) View.VISIBLE else View.GONE
    }
}
